/*
 * ping_pong.c — Estimación de latencia y ancho de banda entre dos procesos.
 *
 * El rango 0 envía un mensaje de m bytes al rango 1 y el rango 1 lo devuelve
 * (una "ida y vuelta"). Se mide el tiempo de muchas idas y vueltas y se
 * divide entre su número. Protocolo de medición del curso: una pasada de
 * calentamiento que no cuenta, 5 repeticiones, se reporta la MEDIANA (y
 * también el mínimo y el máximo).
 *
 *   latencia (ida)       = rtt_mediana / 2
 *   ancho de banda (MB/s) = 2 * m / rtt_mediana   (m bytes viajan dos veces)
 *
 * Uso: mpirun -np 2 ./ping_pong [max_bytes] [repeticiones]
 *   max_bytes     tamaño máximo de mensaje a probar (por defecto 4194304 = 4 MiB)
 *   repeticiones  por defecto 5 (mínimo 1, máximo 50)
 *
 * Los números dependen de la máquina y de si los dos procesos están en el
 * mismo nodo (memoria compartida) o en nodos distintos (red). En red, la
 * latencia sube uno o dos órdenes de magnitud.
 */
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TAG_PING 10
#define DEFAULT_MAX_BYTES 4194304UL
#define MAX_REPS 50

/* Comparador para ordenar double con qsort (para la mediana). */
static int cmp_double(const void *a, const void *b)
{
    double x = *(const double *)a, y = *(const double *)b;
    return (x > y) - (x < y);
}

/* Número de idas y vueltas por repetición: muchas para mensajes chicos
 * (tiempos de microsegundos), pocas para mensajes grandes. */
static int roundtrips_for(size_t bytes)
{
    if (bytes <= 64) return 20000;
    if (bytes <= 4096) return 5000;
    if (bytes <= 65536) return 1000;
    if (bytes <= 1048576) return 100;
    return 20;
}

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    if (size != 2) {
        if (rank == 0)
            fprintf(stderr, "Uso: mpirun -np 2 ./ping_pong [max_bytes] [repeticiones]\n");
        MPI_Finalize();
        return 1;
    }

    size_t max_bytes = (argc > 1) ? strtoul(argv[1], NULL, 10) : DEFAULT_MAX_BYTES;
    int reps = (argc > 2) ? atoi(argv[2]) : 5;
    if (reps < 1) reps = 1;
    if (reps > MAX_REPS) reps = MAX_REPS;

    const size_t sizes[] = {0, 1, 8, 64, 512, 4096, 32768, 262144,
                            1048576, 4194304, 16777216};
    const int n_sizes = (int)(sizeof(sizes) / sizeof(sizes[0]));

    /* Un solo búfer para enviar y recibir: el contenido no importa aquí. */
    size_t alloc = (max_bytes > 0) ? max_bytes : 1;
    char *buf = malloc(alloc);
    if (buf == NULL) {
        fprintf(stderr, "rango %d: sin memoria para %zu bytes\n", rank, alloc);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }
    memset(buf, 0, alloc);

    double times[MAX_REPS]; /* segundos por ida y vuelta, una entrada por repetición */
    int peer = 1 - rank;

    if (rank == 0) {
        printf("# ping-pong entre rango 0 y rango 1, repeticiones=%d (mediana), "
               "1 calentamiento\n", reps);
        printf("# %10s %8s %14s %12s %12s %12s %16s\n", "bytes", "viajes",
               "rtt_mediana_us", "rtt_min_us", "rtt_max_us", "latencia_us",
               "ancho_banda_MB_s");
    }

    for (int s = 0; s < n_sizes; s++) {
        size_t bytes = sizes[s];
        if (bytes > max_bytes) break;
        int count = (int)bytes; /* MPI_BYTE: cuenta = bytes */
        int n = roundtrips_for(bytes);

        /* r = -1 es el calentamiento: se ejecuta igual pero no se guarda. */
        for (int r = -1; r < reps; r++) {
            double t0 = MPI_Wtime();
            for (int i = 0; i < n; i++) {
                if (rank == 0) {
                    MPI_Send(buf, count, MPI_BYTE, peer, TAG_PING, MPI_COMM_WORLD);
                    MPI_Recv(buf, count, MPI_BYTE, peer, TAG_PING, MPI_COMM_WORLD,
                             MPI_STATUS_IGNORE);
                } else {
                    MPI_Recv(buf, count, MPI_BYTE, peer, TAG_PING, MPI_COMM_WORLD,
                             MPI_STATUS_IGNORE);
                    MPI_Send(buf, count, MPI_BYTE, peer, TAG_PING, MPI_COMM_WORLD);
                }
            }
            double t1 = MPI_Wtime();
            if (r >= 0) times[r] = (t1 - t0) / n;
        }

        if (rank == 0) {
            qsort(times, (size_t)reps, sizeof(double), cmp_double);
            double median = times[reps / 2];
            if (reps % 2 == 0) median = 0.5 * (times[reps / 2 - 1] + times[reps / 2]);
            double rtt_min = times[0], rtt_max = times[reps - 1];
            double latency_us = 0.5 * median * 1e6;
            double bandwidth = (bytes > 0) ? (2.0 * (double)bytes / median) / 1e6 : 0.0;
            printf("  %10zu %8d %14.2f %12.2f %12.2f %12.2f %16.1f\n", bytes, n,
                   median * 1e6, rtt_min * 1e6, rtt_max * 1e6, latency_us, bandwidth);
        }
    }

    free(buf);
    MPI_Finalize();
    return 0;
}
