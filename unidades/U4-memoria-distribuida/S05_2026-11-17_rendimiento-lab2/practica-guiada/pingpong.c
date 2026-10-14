/*
 * pingpong.c — Mide latencia (α) y ancho de banda (β) entre dos procesos y
 * los ajusta al modelo T_com(m) = α + m/β (S02 → S05).
 *
 * El rango 0 envía m bytes al rango 1, que los devuelve. Un viaje de ida
 * vale la mitad del tiempo de ida y vuelta. Para cada tamaño: calentamiento,
 * 5 repeticiones de `rounds` viajes redondos y se reporta la mediana.
 *
 *   α ≈ tiempo de ida del mensaje más pequeño (8 bytes).
 *   β ≈ m_grande / (T(m_grande) − α), con m_grande = 1 MiB.
 *
 * Uso: mpirun -np 2 ./pingpong
 * Compilar: mpicc -std=c11 -O2 -Wall -Wextra -o pingpong pingpong.c
 */
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define REPS 5
#define N_SIZES 5

static int cmp_double(const void *a, const void *b)
{
    double x = *(const double *)a, y = *(const double *)b;
    return (x > y) - (x < y);
}

/* Tiempo de ida (segundos) de un mensaje de `bytes` bytes: mediana de REPS medidas. */
static double one_way_time(int rank, char *buf, int bytes, int rounds, double *tmin, double *tmax)
{
    double t[REPS];
    for (int r = -1; r < REPS; r++) { /* r = -1: calentamiento */
        MPI_Barrier(MPI_COMM_WORLD);
        double t0 = MPI_Wtime();
        for (int k = 0; k < rounds; k++) {
            if (rank == 0) {
                MPI_Send(buf, bytes, MPI_BYTE, 1, 0, MPI_COMM_WORLD);
                MPI_Recv(buf, bytes, MPI_BYTE, 1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            } else {
                MPI_Recv(buf, bytes, MPI_BYTE, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
                MPI_Send(buf, bytes, MPI_BYTE, 0, 0, MPI_COMM_WORLD);
            }
        }
        double elapsed = MPI_Wtime() - t0;
        if (r >= 0) t[r] = elapsed / (2.0 * rounds); /* ida y vuelta -> ida */
    }
    qsort(t, REPS, sizeof(double), cmp_double);
    *tmin = t[0];
    *tmax = t[REPS - 1];
    return t[REPS / 2];
}

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    if (size != 2) {
        if (rank == 0) fprintf(stderr, "pingpong necesita exactamente 2 procesos (mpirun -np 2)\n");
        MPI_Finalize();
        return 1;
    }

    const int sizes[N_SIZES] = { 8, 1024, 65536, 1048576, 4194304 };
    const int rounds[N_SIZES] = { 2000, 2000, 500, 200, 50 };
    char *buf = calloc((size_t)sizes[N_SIZES - 1], 1);
    if (!buf) MPI_Abort(MPI_COMM_WORLD, 1);

    double t_med[N_SIZES], t_min[N_SIZES], t_max[N_SIZES];
    for (int s = 0; s < N_SIZES; s++)
        t_med[s] = one_way_time(rank, buf, sizes[s], rounds[s], &t_min[s], &t_max[s]);

    if (rank == 0) {
        double alpha = t_med[0];                                   /* s */
        double beta = (double)sizes[3] / (t_med[3] - alpha);        /* bytes/s, ajustado con 1 MiB */
        printf("ping-pong entre rangos 0 y 1 (mediana de %d repeticiones, tras calentamiento)\n", REPS);
        printf("%10s %12s %12s %12s %12s %12s\n", "bytes", "T_ida(us)", "min(us)", "max(us)", "MB/s", "modelo(us)");
        for (int s = 0; s < N_SIZES; s++) {
            double model = alpha + (double)sizes[s] / beta;
            printf("%10d %12.3f %12.3f %12.3f %12.1f %12.3f\n", sizes[s], 1e6 * t_med[s], 1e6 * t_min[s],
                   1e6 * t_max[s], (double)sizes[s] / t_med[s] / 1e6, 1e6 * model);
        }
        printf("alpha (latencia) ~ %.3f us ; beta (ancho de banda) ~ %.2f GB/s\n", 1e6 * alpha, beta / 1e9);
        printf("modelo: T_com(m) = %.3f us + m / (%.2f GB/s)\n", 1e6 * alpha, beta / 1e9);
        printf("RESULT,alpha_us,%.4f,beta_GBps,%.4f\n", 1e6 * alpha, beta / 1e9);
    }

    free(buf);
    MPI_Finalize();
    return 0;
}
