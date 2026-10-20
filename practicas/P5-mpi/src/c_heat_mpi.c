/*
 * c_heat_mpi.c — Parte C: ecuación de calor 1D distribuida (ESQUELETO: tú diseñas la parte MPI).
 *
 * Lo que ya está escrito (no lo cambies: tests/run_tests.sh y escalado.sh dependen de ello):
 *   - lectura de argumentos, reparto por bloques con residuo (block_partition) y condición inicial local;
 *   - medición del tiempo con el protocolo (Barrier + Wtime + Reduce MAX, calentamiento + reps);
 *   - reconstrucción de la malla UNA vez al final con MPI_Gatherv, checksum y sondas;
 *   - verificación contra heat_solve_seq (c_heat_common.h) con --verify; impresión y línea RESULT.
 * Lo que escribes tú: heat_solve_mpi() y las funciones auxiliares que necesites.
 *
 * Restricciones (README, Parte C): halos (celdas fantasma) con MPI_Isend/MPI_Irecv/MPI_Waitall;
 * convergencia GLOBAL con MPI_Allreduce cada check_every pasos (todos deciden con el mismo número);
 * sin Gather de toda la malla en cada paso; mismo número de pasos y mismos valores que c_heat_seq.
 * Se exige n >= p (cada rango tiene al menos una celda).
 *
 * Uso: mpirun -np P ./c_heat_mpi [n] [max_iter] [tol] [check_every] [reps] [--verify] [--print] [--sin-solape] [--trace]
 *      mismos valores por defecto que c_heat_seq (1000000 500 0 1 3). --sin-solape pone use_overlap = 0
 *      (tu diseño decide qué hace con eso: es para medir con y sin solape, restricción 6 del README).
 * Compilar: mpicc -std=c11 -O2 -Wall -Wextra -o c_heat_mpi c_heat_mpi.c -lm
 */
#include <mpi.h>
#include "c_heat_common.h"

/* Interruptor e instrumentación que main ya maneja (puedes usarlos en tu diseño; no los renombres):
 *   use_overlap : 1 por defecto; main lo pone en 0 con --sin-solape. Úsalo para medir con y sin solape.
 *   t_comm_acc, t_comp_acc : segundos de comunicación (publicar, esperar en Waitall, Allreduce) y de cómputo
 *                de ESTE rango. main los pone en 0 antes de cada repetición y, si acumulas en ellos, imprime
 *                "por paso (max entre rangos, ultima repeticion): computo=... us, comunicacion=... us". */
static int use_overlap = 1;
static double t_comm_acc = 0.0, t_comp_acc = 0.0;

/* Estado local: fronteras físicas en los halos de las orillas, condición inicial en el interior.
 * u[0] y u[n_local+1] son las celdas fantasma; u[1..n_local] las propias (índice global first + i - 1). */
static void heat_init_local(double *u, double *u_new, long long n, long long n_local, long long first)
{
    u[0] = u_new[0] = HEAT_T_LEFT;   /* en rangos interiores lo sobrescribe el primer intercambio de halos */
    u[n_local + 1] = u_new[n_local + 1] = HEAT_T_RIGHT;
    for (long long i = 1; i <= n_local; i++) u[i] = u_new[i] = heat_initial(first + i - 1, n);
}

/*
 * ===== TU DISEÑO EMPIEZA AQUÍ =====
 * Contrato de heat_solve_mpi (no cambies la firma):
 *   u, u_new  : arreglos locales de n_local + 2 celdas, ya inicializados por heat_init_local.
 *   n, n_local, first, rank, size : la malla global, tu bloque y tu lugar en el comunicador.
 *   max_iter, tol, check_every    : los mismos que recibe heat_solve_seq.
 *   Al regresar: u[1..n_local] tiene el estado final (si quedó en u_new, cópialo a u, como hace
 *                heat_solve_seq); *converged = 1 si paró por tol; *last_diff = la última diferencia
 *                máxima GLOBAL revisada.
 *   Devuelve el número de pasos ejecutados (debe coincidir con heat_solve_seq para los mismos argumentos)
 *   o -1 mientras no esté implementada: entonces main imprime "TODO pendiente" y termina sin calcular.
 * Piezas que vas a necesitar (en el orden en que conviene escribirlas):
 *   1. vecinos izquierdo y derecho (MPI_PROC_NULL en las orillas: así el mismo código sirve para todos);
 *   2. por paso: publicar las recepciones (halos) y los envíos (tu primera y tu última celda), calcular,
 *      esperar con MPI_Waitall; pregunta de diseño: ¿qué celdas puedes calcular ANTES del Waitall?
 *   3. doble búfer (intercambio de punteros) y heat_step_range de c_heat_common.h para no reescribir el
 *      esquema (así tu resultado es bit a bit igual al secuencial);
 *   4. cada check_every pasos: diferencia máxima local -> MPI_Allreduce(MPI_MAX) -> todos comparan con tol.
 */
static long long heat_solve_mpi(double *u, double *u_new, long long n, long long n_local, long long first,
                                int rank, int size, long long max_iter, double tol, long long check_every,
                                int *converged, double *last_diff)
{
    /* TODO(C): sustituye este cuerpo por tu diseño. */
    (void)u; (void)u_new; (void)n; (void)n_local; (void)first; (void)rank; (void)size;
    (void)max_iter; (void)tol; (void)check_every; (void)converged; (void)last_diff;
    return -1;
}
/* ===== TU DISEÑO TERMINA AQUÍ ===== */

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    long long n = p5_arg_ll(argc, argv, 0, 1000000LL);
    long long max_iter = p5_arg_ll(argc, argv, 1, 500);
    double tol = p5_arg_double(argc, argv, 2, 0.0);
    long long check_every = p5_arg_ll(argc, argv, 3, 1);
    int reps = p5_clamp_reps(p5_arg_ll(argc, argv, 4, 3));
    int verify = p5_has_flag(argc, argv, "--verify"), print = p5_has_flag(argc, argv, "--print");
    int trace = p5_has_flag(argc, argv, "--trace");
    use_overlap = !p5_has_flag(argc, argv, "--sin-solape");
    if (n <= 0 || max_iter <= 0 || tol < 0 || check_every <= 0 || n < size) {
        if (rank == 0) fprintf(stderr, "Uso: %s [n >= p] [max_iter > 0] [tol >= 0] [check_every > 0] [reps] [--verify] [--print] [--sin-solape] [--trace]\n"
                                       "(n = %lld, p = %d: se exige n >= p para que todos tengan al menos una celda)\n", argv[0], n, size);
        MPI_Finalize();
        return 1;
    }

    long long n_local, first;
    block_partition(n, size, rank, &n_local, &first);
    if (trace) printf("[rango %d] celdas globales %lld..%lld (n_local=%lld)\n", rank, first, first + n_local - 1, n_local);

    double *u = p5_alloc(n_local + 2), *u_new = p5_alloc(n_local + 2);
    long long iters = 0;
    int converged = 0;
    double last_diff = 0.0, t_max[P5_MAX_REPS];
    for (int r = -1; r < reps; r++) { /* r = -1: calentamiento */
        heat_init_local(u, u_new, n, n_local, first);
        t_comm_acc = t_comp_acc = 0.0;
        MPI_Barrier(MPI_COMM_WORLD);
        double t0 = MPI_Wtime();
        iters = heat_solve_mpi(u, u_new, n, n_local, first, rank, size, max_iter, tol, check_every, &converged, &last_diff);
        double elapsed = MPI_Wtime() - t0, slowest = 0.0;
        MPI_Reduce(&elapsed, &slowest, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
        if (r >= 0) t_max[r] = slowest;
        if (iters < 0) break;
    }
    if (iters < 0) {
        if (rank == 0) printf("TODO pendiente: heat_solve_mpi (Parte C) no esta implementada todavia\n");
        free(u); free(u_new);
        MPI_Finalize();
        return 0;
    }

    /* Reconstrucción: UNA vez, al final, con Gatherv (cuentas y desplazamientos del mismo reparto). */
    int *counts = malloc((size_t)size * sizeof(int)), *displs = malloc((size_t)size * sizeof(int));
    if (!counts || !displs) MPI_Abort(MPI_COMM_WORLD, 2);
    for (int k = 0; k < size; k++) {
        long long c, f;
        block_partition(n, size, k, &c, &f);
        counts[k] = (int)c;
        displs[k] = (int)f;
    }
    double *u_global = (rank == 0) ? p5_alloc(n) : NULL;
    MPI_Gatherv(u + 1, (int)n_local, MPI_DOUBLE, u_global, counts, displs, MPI_DOUBLE, 0, MPI_COMM_WORLD);

    /* Diagnóstico de la razón cómputo/comunicación (solo informativo): máximo entre rangos de cada uno. */
    double comm_max = 0.0, comp_max = 0.0;
    MPI_Reduce(&t_comm_acc, &comm_max, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
    MPI_Reduce(&t_comp_acc, &comp_max, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);

    int ok = 1;
    if (rank == 0) {
        p5_stats s = p5_time_stats(t_max, reps);
        double checksum = heat_checksum(u_global, n);
        double u_center = u_global[n / 2], u_quarter = u_global[n / 4];
        printf("c_heat_mpi: n=%lld p=%d reparto:", n, size);
        for (int k = 0; k < size; k++) printf(" %d", counts[k]);
        printf(" max_iter=%lld tol=%g check_every=%lld reps=%d %s\n", max_iter, tol, check_every, reps,
               use_overlap ? "(solape permitido)" : "(--sin-solape)");
        printf("iteraciones=%lld convergio=%d diff_final=%.3e\n", iters, converged, last_diff);
        printf("checksum=%.12e u[centro]=%.12e u[n/4]=%.12e (reconstruido con un Gatherv al final)\n",
               checksum, u_center, u_quarter);
        if (comm_max + comp_max > 0.0)
            printf("por paso (max entre rangos, ultima repeticion): computo=%.3f us, comunicacion=%.3f us, razon=%.1f\n",
                   1e6 * comp_max / (double)iters, 1e6 * comm_max / (double)iters,
                   comm_max > 0 ? comp_max / comm_max : 0.0);
        const char *verdict = "SIN_VERIFICAR";
        if (verify) {
            double *ur = p5_alloc(n + 2), *ur_new = p5_alloc(n + 2), ref_diff = 0.0, max_diff = 0.0;
            int ref_conv;
            heat_init_full(ur, ur_new, n);
            long long ref_iters = heat_solve_seq(ur, ur_new, n, max_iter, tol, check_every, &ref_conv, &ref_diff);
            ok = (ref_iters == iters) && heat_verify(u_global, ur + 1, n, 1e-10, &max_diff);
            verdict = ok ? "OK" : "FALLA";
            printf("verificacion contra heat_solve_seq (rango 0): %s; iteraciones seq=%lld mpi=%lld; max |dif| = %.1e\n",
                   verdict, ref_iters, iters, max_diff);
            free(ur);
            free(ur_new);
        }
        p5_print_time_human("pasos de tiempo, max entre rangos", t_max, reps);
        p5_print_time_line(t_max, reps);
        printf("RESULT,c_heat_mpi,%d,%lld,%lld,%lld,%d,%.12e,%.12e,%.12e,%.6f,%s\n", size, n, max_iter, iters,
               converged, checksum, u_center, u_quarter, s.median, verdict);
        if (print) heat_print_profile(u_global, n);
    }

    /* Todos los rangos terminan con el mismo código (el veredicto lo tiene la raíz). */
    MPI_Bcast(&ok, 1, MPI_INT, 0, MPI_COMM_WORLD);
    free(u); free(u_new); free(u_global); free(counts); free(displs);
    MPI_Finalize();
    return ok ? 0 : 1;
}
