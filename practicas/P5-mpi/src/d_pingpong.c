/*
 * d_pingpong.c — Parte D: mide latencia (α) y ancho de banda (β) entre dos procesos y los ajusta al
 * modelo de costo de un mensaje  T_com(m) = α + m / β.
 *
 * El rango 0 manda m bytes al rango 1 y el rango 1 los devuelve (ida y vuelta). El tiempo de ida es
 * la mitad. Para cada tamaño: 1 calentamiento + 5 repeticiones de `rounds` idas y vueltas; mediana.
 *   α ≈ tiempo de ida del mensaje de 8 bytes (un double: el halo de la Parte C).
 *   β ≈ m / (T(m) − α) con m = 1 MiB.
 * La columna modelo(us) muestra dónde el modelo de dos parámetros acierta y dónde no.
 *
 * Uso:      mpirun -np 2 ./d_pingpong [factor]    factor multiplica el número de idas y vueltas
 *           (por defecto 1.0; las pruebas usan 0.05 para terminar rápido; para medir usa 1).
 * Salida:   tabla por tamaño + línea RESULT,d_pingpong,alpha_us,<α>,beta_GBps,<β>
 * Compilar: mpicc -std=c11 -O2 -Wall -Wextra -o d_pingpong d_pingpong.c -lm
 */
#include <mpi.h>
#include "common.h"

#define N_SIZES 6
#define PP_REPS 5

/* Tiempo de ida (s) de un mensaje de `bytes` bytes: mediana de PP_REPS medidas de `rounds` idas y vueltas. */
static p5_stats one_way(int rank, char *buf, int bytes, int rounds)
{
    double t[PP_REPS];
    for (int r = -1; r < PP_REPS; r++) { /* r = -1: calentamiento */
        MPI_Barrier(MPI_COMM_WORLD);
        double t0 = MPI_Wtime();
        for (int k = 0; k < rounds; k++) {
            if (rank == 0) {
                MPI_Send(buf, bytes, MPI_BYTE, 1, 7, MPI_COMM_WORLD);
                MPI_Recv(buf, bytes, MPI_BYTE, 1, 7, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            } else {
                MPI_Recv(buf, bytes, MPI_BYTE, 0, 7, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
                MPI_Send(buf, bytes, MPI_BYTE, 0, 7, MPI_COMM_WORLD);
            }
        }
        if (r >= 0) t[r] = (MPI_Wtime() - t0) / (2.0 * rounds);
    }
    return p5_time_stats(t, PP_REPS);
}

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    double factor = p5_arg_double(argc, argv, 0, 1.0);
    if (factor <= 0.0) factor = 1.0;
    if (size != 2) {
        if (rank == 0) fprintf(stderr, "d_pingpong necesita exactamente 2 procesos: mpirun -np 2 ./d_pingpong\n");
        MPI_Finalize();
        return 1;
    }

    const int sizes[N_SIZES] = { 8, 256, 4096, 65536, 1048576, 4194304 };
    const int base_rounds[N_SIZES] = { 4000, 4000, 2000, 500, 100, 30 };
    char *buf = calloc((size_t)sizes[N_SIZES - 1], 1);
    if (!buf) MPI_Abort(MPI_COMM_WORLD, 2);

    p5_stats st[N_SIZES];
    for (int s = 0; s < N_SIZES; s++) {
        int rounds = (int)(base_rounds[s] * factor);
        if (rounds < 2) rounds = 2;
        st[s] = one_way(rank, buf, sizes[s], rounds);
    }

    if (rank == 0) {
        double alpha = st[0].median;                                   /* s */
        double beta = (double)sizes[4] / (st[4].median - alpha);        /* B/s, ajustado con 1 MiB */
        printf("d_pingpong: rango 0 <-> rango 1, mediana de %d repeticiones tras 1 calentamiento (factor %.2f)\n", PP_REPS, factor);
        printf("%10s %12s %12s %12s %12s %12s\n", "bytes", "T_ida(us)", "min(us)", "max(us)", "MB/s", "modelo(us)");
        for (int s = 0; s < N_SIZES; s++)
            printf("%10d %12.3f %12.3f %12.3f %12.1f %12.3f\n", sizes[s], 1e6 * st[s].median, 1e6 * st[s].min,
                   1e6 * st[s].max, (double)sizes[s] / st[s].median / 1e6, 1e6 * (alpha + (double)sizes[s] / beta));
        printf("alpha (latencia) = %.3f us ; beta (ancho de banda) = %.2f GB/s\n", 1e6 * alpha, beta / 1e9);
        printf("modelo: T_com(m) = %.3f us + m / (%.2f GB/s); un halo de 8 B cuesta %.3f us, un Gatherv de 1e6 doubles ~ %.1f us\n",
               1e6 * alpha, beta / 1e9, 1e6 * (alpha + 8.0 / beta), 1e6 * (alpha + 8e6 / beta));
        printf("RESULT,d_pingpong,alpha_us,%.4f,beta_GBps,%.4f\n", 1e6 * alpha, beta / 1e9);
    }

    free(buf);
    MPI_Finalize();
    return 0;
}
