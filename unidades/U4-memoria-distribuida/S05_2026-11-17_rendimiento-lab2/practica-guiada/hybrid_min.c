/*
 * hybrid_min.c — Mínimo MPI + OpenMP (panorama de S05).
 *
 * Dos niveles de paralelismo:
 *   - entre nodos/procesos: MPI reparte el arreglo por bloques (S01);
 *   - dentro de cada proceso: OpenMP reparte el bloque entre hilos (U3).
 * Suma los enteros 0..n-1 (como doubles; el resultado n(n-1)/2 es exacto en
 * double mientras n < 2^26, así que la prueba compara con igualdad).
 *
 * MPI_Init_thread pide un nivel de soporte de hilos; aquí FUNNELED: varios
 * hilos existen, pero solo el hilo principal llama a MPI. Es el nivel que
 * necesita el patrón "OpenMP adentro, MPI afuera" que usamos.
 *
 * Uso: OMP_NUM_THREADS=2 mpirun -np 2 ./hybrid_min [n]
 * Compilar: mpicc -std=c11 -O2 -Wall -Wextra -fopenmp -o hybrid_min hybrid_min.c
 */
#include <mpi.h>
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>

static const char *thread_level_name(int level)
{
    switch (level) {
    case MPI_THREAD_SINGLE:     return "MPI_THREAD_SINGLE";
    case MPI_THREAD_FUNNELED:   return "MPI_THREAD_FUNNELED";
    case MPI_THREAD_SERIALIZED: return "MPI_THREAD_SERIALIZED";
    case MPI_THREAD_MULTIPLE:   return "MPI_THREAD_MULTIPLE";
    default:                    return "desconocido";
    }
}

int main(int argc, char **argv)
{
    int provided;
    MPI_Init_thread(&argc, &argv, MPI_THREAD_FUNNELED, &provided);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    long n = (argc > 1) ? atol(argv[1]) : 16777216L; /* 2^24 */
    if (n < 1 || n >= (1L << 26)) {
        if (rank == 0) fprintf(stderr, "uso: %s [1 <= n < 2^26]\n", argv[0]);
        MPI_Finalize();
        return 1;
    }

    /* Bloque de este proceso: [first, first + n_local). */
    long base = n / size, rem = n % size;
    long n_local = base + (rank < rem ? 1 : 0);
    long first = rank * base + (rank < rem ? rank : rem);

    /* Nivel 2: hilos OpenMP dentro del proceso. */
    int n_threads = 1;
    double local_sum = 0.0;
    #pragma omp parallel reduction(+ : local_sum)
    {
        #pragma omp single
        n_threads = omp_get_num_threads(); /* se lee dentro de la región: es el valor real */
        #pragma omp for
        for (long i = first; i < first + n_local; i++)
            local_sum += (double)i;
    }

    /* Nivel 1: los procesos combinan sus sumas parciales (solo el hilo principal llama a MPI). */
    double total = 0.0;
    MPI_Reduce(&local_sum, &total, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

    /* Reporte ordenado: el rango 0 reúne los hilos de cada proceso y el nombre del nodo. */
    char host[MPI_MAX_PROCESSOR_NAME];
    int host_len;
    MPI_Get_processor_name(host, &host_len);
    int *threads_all = NULL;
    char *hosts_all = NULL;
    if (rank == 0) {
        threads_all = malloc((size_t)size * sizeof(int));
        hosts_all = malloc((size_t)size * MPI_MAX_PROCESSOR_NAME);
    }
    MPI_Gather(&n_threads, 1, MPI_INT, threads_all, 1, MPI_INT, 0, MPI_COMM_WORLD);
    MPI_Gather(host, MPI_MAX_PROCESSOR_NAME, MPI_CHAR, hosts_all, MPI_MAX_PROCESSOR_NAME, MPI_CHAR, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        printf("Nivel de hilos pedido: %s; provisto: %s\n",
               thread_level_name(MPI_THREAD_FUNNELED), thread_level_name(provided));
        int total_threads = 0;
        for (int r = 0; r < size; r++) {
            printf("rango %d de %d en %s: %d hilos OpenMP\n", r, size,
                   hosts_all + (size_t)r * MPI_MAX_PROCESSOR_NAME, threads_all[r]);
            total_threads += threads_all[r];
        }
        double expected = 0.5 * (double)n * (double)(n - 1);
        printf("n=%ld  suma=%.1f  esperada=%.1f  %s  (%d procesos x hilos = %d unidades de ejecución)\n",
               n, total, expected, (total == expected) ? "OK" : "ERROR", size, total_threads);
        free(threads_all);
        free(hosts_all);
    }

    MPI_Finalize();
    return 0;
}
