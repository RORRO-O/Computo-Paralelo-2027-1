/*
 * b_matvec_mpi.c — Parte B: producto matriz-vector distribuido por filas (versión por completar).
 *
 * Reparto: el rango 0 tiene A (m×n) y x; cada rango recibe un bloque de filas CONTIGUAS de A
 * (reparto con residuo: los primeros m % p rangos llevan una fila más) y calcula su bloque de y.
 *   1. MPI_Scatterv  reparte las filas de A (una vez; cuentas en ELEMENTOS = filas × n)
 *   2. por iteración: MPI_Bcast de x · producto local · MPI_Gatherv de y_local en y (rango 0)
 *   3. MPI_Barrier + MPI_Wtime para medir; MPI_Reduce(MPI_MAX) porque la corrida dura lo que el más lento
 * El rango 0 compara y contra la versión secuencial calculada en su memoria (mismos ciclos).
 *
 * Uso:  mpirun -np P ./b_matvec_mpi [m] [n] [iters] [reps] [--trace]   (por defecto 2000 2000 200 3)
 *       --trace: cada rango imprime qué filas globales recibió.
 * Compilar: mpicc -std=c11 -O2 -Wall -Wextra -o b_matvec_mpi b_matvec_mpi.c -lm
 *
 * ===== Cómo funcionan los TODO =====
 * Hay cinco: TODO(1) reparto con residuo, TODO(2) Scatterv, TODO(3) Bcast, TODO(4) Gatherv, TODO(5) Reduce
 * del tiempo. La máscara `todo_pending` dice cuáles faltan; al terminar cada uno, quita su bandera.
 *   - Con TODO(1) pendiente, el programa imprime "TODO pendiente: ..." y termina sin calcular nada.
 *   - Sin TODO(1) pero con alguno de 2–5 pendiente, imprime la línea "filas por rango: ..." (así verificas
 *     TODO(1) solo, en el Laboratorio 1) y después "TODO pendiente: ..." y termina.
 *   - Con la máscara en 0u corre todo y verifica contra la secuencial.
 * tests/run_tests.sh reporta como PEND lo que depende de un TODO pendiente (FAIL en `make test-b`). Un TODO
 * quitado de la máscara pero mal resuelto hace que su criterio falle: eso es FAIL.
 * Criterio de verificación de cada TODO (`make test-b`, o a mano con los comandos):
 *   TODO(1) -> `mpirun -np 3 ./src/b_matvec_mpi 301 203 3` dice "filas por rango: 101 100 100"; con -np 4,
 *              "76 75 75 75" (los dos primeros casos de la Parte B en make test-b)
 *   TODO(2) -> con --trace, A_local[0] de cada rango es el primer elemento de su primera fila global
 *   TODO(3) -> con --trace, x[0] vale lo mismo en todos los rangos (0.666100 con los datos por defecto)
 *   TODO(4) -> "verificacion ... OK" y el mismo checksum que ./src/b_matvec_seq 301 203 3
 *   TODO(5) -> el tiempo reportado es el del rango más lento, no el de la raíz (imprime `elapsed` por rango
 *              con --trace y compáralo con la mediana que reporta el rango 0)
 */
#include <mpi.h>
#include "common.h"

#define TODO_1 1u
#define TODO_2 2u
#define TODO_3 4u
#define TODO_4 8u
#define TODO_5 16u
/* Máscara de TODO pendientes. Quita cada bandera cuando completes su TODO. Al final debe quedar 0u. */
static const unsigned todo_pending = TODO_1 | TODO_2 | TODO_3 | TODO_4 | TODO_5;

/* Imprime (en el rango 0) qué TODO faltan. */
static void report_pending(int rank)
{
    if (rank != 0) return;
    printf("TODO pendiente:");
    for (int k = 0; k < 5; k++)
        if (todo_pending & (1u << k)) printf(" TODO(%d)", k + 1);
    printf(" (quita cada bandera de todo_pending al terminarlo)\n");
}

/* Igual que en b_matvec_seq.c: el mismo orden de suma en j da el mismo redondeo. */
static void matvec_rows(const double *A, const double *x, double *y, long long rows, long long n)
{
    for (long long i = 0; i < rows; i++) {
        double acc = 0.0;
        const double *row = A + i * n;
        for (long long j = 0; j < n; j++) acc += row[j] * x[j];
        y[i] = acc;
    }
}

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    long long m = p5_arg_ll(argc, argv, 0, 2000);
    long long n = p5_arg_ll(argc, argv, 1, 2000);
    long long iters = p5_arg_ll(argc, argv, 2, 200);
    int reps = p5_clamp_reps(p5_arg_ll(argc, argv, 3, 3));
    int trace = p5_has_flag(argc, argv, "--trace");
    if (m <= 0 || n <= 0 || iters <= 0) {
        if (rank == 0) fprintf(stderr, "Uso: %s [m > 0] [n > 0] [iters > 0] [reps] [--trace]\n", argv[0]);
        MPI_Finalize();
        return 1;
    }
    /* ---------- Reparto de filas: cuentas y desplazamientos de TODOS los rangos ----------
     * row_counts[k]/row_displs[k]: filas que recibe el rango k y en qué fila global empiezan.
     * elem_counts[k]/elem_displs[k]: lo mismo en ELEMENTOS de A (× n), que es lo que Scatterv reparte.
     * Los calcula cada rango (son p enteros); Scatterv/Gatherv solo los leen en la raíz. */
    int *row_counts = calloc((size_t)size, sizeof(int)), *row_displs = calloc((size_t)size, sizeof(int));
    int *elem_counts = calloc((size_t)size, sizeof(int)), *elem_displs = calloc((size_t)size, sizeof(int));
    if (!row_counts || !row_displs || !elem_counts || !elem_displs) MPI_Abort(MPI_COMM_WORLD, 2);
    /* TODO(1): llena los cuatro arreglos con el reparto por bloques con residuo (S01). Para cada rango k:
     *   filas   c = m / p + (k < m % p ? 1 : 0),   primera fila   f = k * (m / p) + min(k, m % p)
     * (es exactamente block_partition(m, size, k, &c, &f) de common.h). Elementos: c * n y f * n.
     * Pista: un ciclo de k = 0..size-1 con dos variables long long y cuatro asignaciones con (int). */

    if (todo_pending & TODO_1) {
        report_pending(rank);
        free(row_counts); free(row_displs); free(elem_counts); free(elem_displs);
        MPI_Finalize();
        return 0;
    }
    if (rank == 0) { /* criterio del TODO(1): lo imprime en cuanto el reparto está hecho */
        printf("b_matvec_mpi: m=%lld n=%lld p=%d iters=%lld reps=%d; filas por rango:", m, n, size, iters, reps);
        for (int k = 0; k < size; k++) printf(" %d", row_counts[k]);
        printf("\n");
    }
    if (todo_pending) { /* TODO(1) listo; faltan otros: se detiene aquí, igual en todos los rangos */
        report_pending(rank);
        free(row_counts); free(row_displs); free(elem_counts); free(elem_displs);
        MPI_Finalize();
        return 0;
    }

    long long my_rows = row_counts[rank], my_first = row_displs[rank];

    /* ---------- Memoria: A, y, y_ref solo en la raíz; x, A_local, y_local en todos ---------- */
    double *A = NULL, *y = NULL, *y_ref = NULL;
    double *x = p5_alloc(n);
    double *A_local = p5_alloc(my_rows * n), *y_local = p5_alloc(my_rows);
    if (rank == 0) {
        A = p5_alloc(m * n);
        y = p5_alloc(m);
        memset(y, 0, (size_t)m * sizeof(double)); /* una fila que nadie reúne se queda en 0 (error común 2) */
        y_ref = p5_alloc(m);
        for (long long i = 0; i < m * n; i++) A[i] = p5_value(i);
        for (long long j = 0; j < n; j++) x[j] = p5_value(-(j + 1));
        matvec_rows(A, x, y_ref, m, n); /* referencia secuencial para la verificación */
    }

    double t_total[P5_MAX_REPS], t_iters[P5_MAX_REPS];
    for (int r = -1; r < reps; r++) { /* r = -1: calentamiento */
        MPI_Barrier(MPI_COMM_WORLD);
        double t0 = MPI_Wtime();

        /* TODO(2): reparte las filas de A con MPI_Scatterv. Firma (estándar MPI):
         *   MPI_Scatterv(sendbuf, sendcounts[], displs[], sendtype, recvbuf, recvcount, recvtype, root, comm)
         * sendbuf = A (solo tiene sentido en la raíz; en los demás es NULL y se ignora), sendcounts y displs
         * en ELEMENTOS, recvbuf = A_local con recvcount = my_rows * n. La llaman TODOS los rangos. */

        double t_dist = MPI_Wtime() - t0;

        for (long long it = 0; it < iters; it++) {
            /* TODO(3): x lo tiene la raíz y lo necesitan todos para multiplicar. Una línea; la llaman todos. */

            matvec_rows(A_local, x, y_local, my_rows, n);

            /* TODO(4): lo inverso del TODO(2): cada rango aporta sus my_rows valores de y_local y la raíz los
             * recibe en y, cada bloque en su posición (cuentas y desplazamientos en FILAS). */

        }

        double elapsed = MPI_Wtime() - t0;
        /* TODO(5): `elapsed` y `t_dist` son los tiempos de ESTE rango. La corrida dura lo que el rango más
         * lento: deja en `slowest` y `slowest_dist` (en la raíz) el máximo entre todos los rangos. */
        double slowest = elapsed, slowest_dist = t_dist;

        if (r >= 0) {
            t_total[r] = slowest;
            t_iters[r] = slowest - slowest_dist;
        }
        if (trace && r == 0)
            printf("[rango %d] filas globales %lld..%lld (%lld filas, %lld elementos de A); A_local[0]=%.6f x[0]=%.6f\n",
                   rank, my_first, my_first + my_rows - 1, my_rows, my_rows * n,
                   my_rows > 0 ? A_local[0] : 0.0, x[0]);
    }

    int ok = 1;
    if (rank == 0) {
        double checksum = 0.0, max_diff = 0.0;
        for (long long i = 0; i < m; i++) {
            checksum += y[i];
            double d = y[i] - y_ref[i];
            if (d < 0) d = -d;
            if (d > max_diff) max_diff = d;
            if (!p5_close(y[i], y_ref[i], 1e-12)) ok = 0;
        }
        p5_stats st = p5_time_stats(t_total, reps), si = p5_time_stats(t_iters, reps);
        printf("checksum=%.12e y[0]=%.12e y[m-1]=%.12e\n", checksum, y[0], y[m - 1]);
        printf("verificacion contra y secuencial (rango 0): %s; max |dif| = %.1e\n", ok ? "OK" : "FALLA", max_diff);
        printf("tiempo del Scatterv de A (una vez, max entre rangos): %.6f s de %.6f s totales (%.1f %%)\n",
               st.median - si.median, st.median, 100.0 * (st.median - si.median) / st.median);
        p5_print_time_human("Scatterv + iters x (Bcast + producto + Gatherv), max entre rangos", t_total, reps);
        p5_print_time_line(t_total, reps);
        printf("RESULT,b_matvec_mpi,%d,%lld,%lld,%lld,%.12e,%.12e,%.12e,%.6f,%.6f,%s\n", size, m, n, iters,
               checksum, y[0], y[m - 1], st.median, si.median, ok ? "OK" : "FALLA");
    }

    /* Todos los rangos terminan con el mismo código (el veredicto lo tiene la raíz). */
    MPI_Bcast(&ok, 1, MPI_INT, 0, MPI_COMM_WORLD);
    free(A); free(y); free(y_ref); free(x); free(A_local); free(y_local);
    free(row_counts); free(row_displs); free(elem_counts); free(elem_displs);
    MPI_Finalize();
    return ok ? 0 : 1;
}
