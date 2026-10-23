/*
 * jacobi_mpi.c — Jacobi 1D con descomposición de dominio por bloques e
 * intercambio de halos (S04), instrumentado para medir escalabilidad fuerte
 * y débil y la razón cómputo/comunicación (S05).
 *
 * Problema: n puntos globales; fronteras fijas u(0) = 0.0 (izquierda) y
 * u(n+1) = 1.0 (derecha). Cada proceso guarda n_local puntos más dos celdas
 * fantasma (halos) en las posiciones 0 y n_local+1.
 *
 * Por iteración:
 *   1. intercambio de halos con Isend/Irecv/Waitall (1 double a cada vecino)
 *   2. u_new[i] = 0.5 * (u[i-1] + u[i+1]) para i = 1..n_local
 *   3. doble búfer (intercambio de punteros)
 * Cómputo por iteración ∝ n/p; comunicación por iteración constante (2 mensajes
 * de 8 bytes, no depende de n). Ese contraste es el tema de la sesión.
 *
 * Uso: mpirun -np P ./jacobi_mpi [n] [iters] [reps]   (por defecto 1000000, 500, 5)
 * Salida (rango 0): una línea legible y una línea "RESULT,..." que lee
 * escalado.sh (mismo formato que jacobi_seq):
 *   RESULT,p,n,iters,reps,t1;...;tk,mediana,min,max,tcomp_it,tcomm_it,checksum,u_probe
 * tcomp_it y tcomm_it son el MÁXIMO entre procesos del tiempo medio por
 * iteración dedicado a cómputo y a comunicación.
 *
 * Compilar: mpicc -std=c11 -O2 -Wall -Wextra -o jacobi_mpi jacobi_mpi.c
 */
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_REPS 32
#define TAG_RIGHTWARD 0 /* dato que viaja hacia la derecha: mi último punto -> halo izquierdo del vecino */
#define TAG_LEFTWARD 1  /* dato que viaja hacia la izquierda: mi primer punto -> halo derecho del vecino */

static int cmp_double(const void *a, const void *b)
{
    double x = *(const double *)a, y = *(const double *)b;
    return (x > y) - (x < y);
}

/* Distribución por bloques (S01): los primeros n % p procesos reciben un punto extra. */
static void block_bounds(long n, int p, int rank, long *n_local, long *first)
{
    long base = n / p, rem = n % p;
    *n_local = base + (rank < rem ? 1 : 0);
    *first = rank * base + (rank < rem ? rank : rem); /* índice global (0-based) del primer punto local */
}

/* Estado inicial local: ceros; las fronteras físicas viven en los halos de los extremos. */
static void init_state(double *u, double *u_new, long n_local, int rank, int size)
{
    memset(u, 0, (size_t)(n_local + 2) * sizeof(double));
    memset(u_new, 0, (size_t)(n_local + 2) * sizeof(double));
    if (rank == 0) u[0] = u_new[0] = 0.0;
    if (rank == size - 1) u[n_local + 1] = u_new[n_local + 1] = 1.0;
}

/* iters iteraciones de Jacobi. Acumula el tiempo de comunicación y de cómputo
 * por separado (solo para diagnóstico; el tiempo total se mide afuera). */
static double *jacobi_run(double *u, double *u_new, long n_local, int iters,
                          int left, int right, MPI_Comm comm,
                          double *t_comm, double *t_comp)
{
    MPI_Request reqs[4];
    for (int it = 0; it < iters; it++) {
        double t0 = MPI_Wtime();
        /* Recibo los halos y envío mis extremos. Con MPI_PROC_NULL (en las
         * orillas del dominio) la llamada regresa sin hacer nada. */
        MPI_Irecv(&u[0], 1, MPI_DOUBLE, left, TAG_RIGHTWARD, comm, &reqs[0]);
        MPI_Irecv(&u[n_local + 1], 1, MPI_DOUBLE, right, TAG_LEFTWARD, comm, &reqs[1]);
        MPI_Isend(&u[n_local], 1, MPI_DOUBLE, right, TAG_RIGHTWARD, comm, &reqs[2]);
        MPI_Isend(&u[1], 1, MPI_DOUBLE, left, TAG_LEFTWARD, comm, &reqs[3]);
        MPI_Waitall(4, reqs, MPI_STATUSES_IGNORE);
        double t1 = MPI_Wtime();

        for (long i = 1; i <= n_local; i++)
            u_new[i] = 0.5 * (u[i - 1] + u[i + 1]);
        double t2 = MPI_Wtime();

        *t_comm += t1 - t0;
        *t_comp += t2 - t1;
        double *tmp = u; u = u_new; u_new = tmp; /* doble búfer */
    }
    return u; /* búfer con el estado final */
}

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);
    /* Búfer completo para stdout: la línea RESULT que lee escalado.sh se escribe de una
     * vez al terminar; así el reenvío de salida de mpirun no puede partirla. */
    static char out_buf[1 << 14];
    setvbuf(stdout, out_buf, _IOFBF, sizeof out_buf);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    long n = (argc > 1) ? atol(argv[1]) : 1000000L;
    int iters = (argc > 2) ? atoi(argv[2]) : 500;
    int reps = (argc > 3) ? atoi(argv[3]) : 5;
    if (n < (long)size || iters < 1 || reps < 1 || reps > MAX_REPS) {
        if (rank == 0)
            fprintf(stderr, "uso: mpirun -np P %s [n>=P] [iters>=1] [1<=reps<=%d]\n", argv[0], MAX_REPS);
        MPI_Finalize();
        return 1;
    }

    long n_local, first;
    block_bounds(n, size, rank, &n_local, &first);
    int left = (rank == 0) ? MPI_PROC_NULL : rank - 1;
    int right = (rank == size - 1) ? MPI_PROC_NULL : rank + 1;

    double *buf_a = malloc((size_t)(n_local + 2) * sizeof(double));
    double *buf_b = malloc((size_t)(n_local + 2) * sizeof(double));
    if (!buf_a || !buf_b) {
        fprintf(stderr, "rango %d: sin memoria para n_local=%ld\n", rank, n_local);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    double times[MAX_REPS];
    double t_comm = 0.0, t_comp = 0.0; /* acumulados solo en las reps medidas */
    double *u_final = buf_a;
    for (int r = -1; r < reps; r++) { /* r = -1: calentamiento, no se cuenta */
        init_state(buf_a, buf_b, n_local, rank, size);
        double tc = 0.0, tp = 0.0;
        MPI_Barrier(MPI_COMM_WORLD); /* todos arrancan juntos; se cronometra solo la región de interés */
        double t0 = MPI_Wtime();
        u_final = jacobi_run(buf_a, buf_b, n_local, iters, left, right, MPI_COMM_WORLD, &tc, &tp);
        double t_local = MPI_Wtime() - t0;
        double t_max; /* el tiempo de la corrida es el del proceso más lento */
        MPI_Reduce(&t_local, &t_max, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
        if (r >= 0) {
            times[r] = t_max;
            t_comm += tc;
            t_comp += tp;
        }
    }

    /* Verificación: suma global y valor del punto de sondeo global n-3 (como en jacobi_seq). */
    double local_sum = 0.0, checksum = 0.0;
    for (long i = 1; i <= n_local; i++) local_sum += u_final[i];
    MPI_Reduce(&local_sum, &checksum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

    long probe = (n > 3) ? n - 3 : 1; /* índice global 1-based */
    double u_probe_local = 0.0, u_probe = 0.0;
    if (probe - 1 >= first && probe - 1 < first + n_local) u_probe_local = u_final[probe - first];
    /* solo el dueño aporta un valor distinto de 0; la suma lo lleva al rango 0 */
    MPI_Reduce(&u_probe_local, &u_probe, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

    /* Diagnóstico: tiempo medio por iteración de cómputo y de comunicación (máximo entre procesos). */
    double per_it[2] = { t_comp / ((double)reps * iters), t_comm / ((double)reps * iters) };
    double per_it_max[2];
    MPI_Reduce(per_it, per_it_max, 2, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        double sorted[MAX_REPS];
        memcpy(sorted, times, (size_t)reps * sizeof(double));
        qsort(sorted, (size_t)reps, sizeof(double), cmp_double);
        double median = sorted[reps / 2];
        double ratio = (per_it_max[1] > 0.0) ? per_it_max[0] / per_it_max[1] : 0.0;
        printf("jacobi_mpi: p=%d n=%ld (n_local~%ld) iters=%d reps=%d | mediana=%.4f s (min %.4f, max %.4f) | "
               "por iteración: cómputo %.3e s, comunicación %.3e s, razón cómputo/comunicación %.1f | checksum=%.6e\n",
               size, n, n_local, iters, reps, median, sorted[0], sorted[reps - 1],
               per_it_max[0], per_it_max[1], ratio, checksum);
        printf("RESULT,%d,%ld,%d,%d,", size, n, iters, reps);
        for (int r = 0; r < reps; r++) printf("%s%.6f", r ? ";" : "", times[r]);
        printf(",%.6f,%.6f,%.6f,%.6e,%.6e,%.10e,%.17g\n",
               median, sorted[0], sorted[reps - 1], per_it_max[0], per_it_max[1], checksum, u_probe);
    }

    free(buf_a);
    free(buf_b);
    MPI_Finalize();
    return 0;
}
