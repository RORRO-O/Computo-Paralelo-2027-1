/* caza2_bcast_solo_raiz_buggy.c — Cazador de errores 2 · repartir un vector y sumarlo
 *
 * Qué debería hacer: el rango 0 genera x[i] = i para i = 0..n-1 y reparte el vector completo a
 * todos. Cada proceso suma los elementos que le tocan (reparto cíclico: i = rango, rango + p, ...)
 * y las sumas parciales se reducen en el rango 0, que compara con la fórmula n(n-1)/2.
 *
 * Este archivo contiene UN error a propósito y no está marcado. Predice el síntoma antes de
 * correrlo (README, fase Predecir). Corrígelo en una copia llamada caza2_bcast_solo_raiz.c;
 * `make listo` la prueba con n = 1 048 576.
 *
 * Uso: mpirun -np 4 ./caza2_bcast_solo_raiz_buggy [n]     (n por defecto 1 048 576 = 8 MB)
 */
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    long n = (argc > 1) ? atol(argv[1]) : (1L << 20);     /* todos conocen n: viene de argv */
    if (n <= 0 || n > 100000000L) {
        if (rank == 0) fprintf(stderr, "Uso: mpirun -np p %s [1 <= n <= 1e8]\n", argv[0]);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    double *x = calloc((size_t)n, sizeof(double));    /* en ceros en todos los procesos */

    if (rank == 0) {
        for (long i = 0; i < n; i++) x[i] = (double)i;
        /* La raíz reparte el vector a todos los procesos. */
        MPI_Bcast(x, (int)n, MPI_DOUBLE, 0, MPI_COMM_WORLD);
    }

    /* Suma parcial con reparto cíclico. */
    double local_sum = 0.0;
    for (long i = rank; i < n; i += size) local_sum += x[i];

    double total = 0.0;
    MPI_Reduce(&local_sum, &total, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        double expected = (double)n * (double)(n - 1) / 2.0;
        printf("caza2: n=%ld, %d procesos, suma=%.0f, esperada=%.0f\nVERIFICACION %s\n",
               n, size, total, expected, (total == expected) ? "OK" : "FAIL");
    }

    free(x);
    MPI_Finalize();
    return 0;
}
