/* caza1_bcast_buggy.c — Cazador de errores 1 (MPI): media de un arreglo repartido.
 *
 * Qué hace cuando funciona: el rango 0 toma n de la línea de comandos y lo anuncia a todos;
 * genera x[i] = (i % 7) + 0.5; reparte bloques con MPI_Scatterv (reparto con residuo de U4 S04);
 * cada rango suma su bloque; MPI_Reduce junta las sumas y el rango 0 imprime la media.
 * Referencia: ./caza_cpu media 1000  →  media=3.497000
 *
 * Contiene UN error a propósito. Escribe tu predicción antes de correrlo:
 *   timeout 5 mpirun --oversubscribe -np 4 ./caza1_bcast_buggy 1000 ; echo "codigo: $?"
 *   (código 124 = timeout lo mató = interbloqueo)
 *   timeout 5 mpirun --oversubscribe -np 1 ./caza1_bcast_buggy 1000
 * Cuando lo corrijas: make cazar
 */
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>

/* Reparto por bloques con residuo: los primeros n % p rangos reciben una celda más. */
static void block_partition(int n, int p, int *counts, int *displs) {
    int offset = 0;
    for (int r = 0; r < p; r++) {
        counts[r] = n / p + (r < n % p ? 1 : 0);
        displs[r] = offset;
        offset += counts[r];
    }
}

int main(int argc, char **argv) {
    int rank, size, n = 0;
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    /* 1. Solo el rango 0 conoce n: hay que anunciarlo a los demás. */
    if (rank == 0) {
        n = (argc > 1) ? atoi(argv[1]) : 1000;
        if (n <= 0) {
            fprintf(stderr, "uso: %s [n>0]\n", argv[0]);
            MPI_Abort(MPI_COMM_WORLD, 1);
        }
        MPI_Bcast(&n, 1, MPI_INT, 0, MPI_COMM_WORLD);                        /* la raíz difunde n   */
    } else {
        MPI_Recv(&n, 1, MPI_INT, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);   /* los demás lo reciben */
    }

    /* 2. Reparto de x entre los procesos. */
    int *counts = malloc(size * sizeof(int));
    int *displs = malloc(size * sizeof(int));
    block_partition(n, size, counts, displs);
    double *x = NULL;
    if (rank == 0) {
        x = malloc(n * sizeof(double));
        for (int i = 0; i < n; i++) x[i] = (i % 7) + 0.5;
    }
    double *local = malloc(counts[rank] * sizeof(double));
    MPI_Scatterv(x, counts, displs, MPI_DOUBLE, local, counts[rank], MPI_DOUBLE, 0, MPI_COMM_WORLD);

    /* 3. Suma local y reducción en la raíz. */
    double local_sum = 0.0, total = 0.0;
    for (int i = 0; i < counts[rank]; i++) local_sum += local[i];
    MPI_Reduce(&local_sum, &total, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

    if (rank == 0) printf("caza1: n=%d procesos=%d media=%.6f\n", n, size, total / n);

    free(local);
    free(x);
    free(counts);
    free(displs);
    MPI_Finalize();
    return 0;
}
