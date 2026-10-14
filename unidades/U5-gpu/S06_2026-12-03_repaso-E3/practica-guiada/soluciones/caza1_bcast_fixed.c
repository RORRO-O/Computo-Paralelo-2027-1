/* caza1_bcast_fixed.c — Solución del cazador 1. No lo abras antes de terminar la fase Modificar.
 *
 * El error: MPI_Bcast es una colectiva y la llaman TODOS los procesos del comunicador (idea errónea 18).
 * En la versión con error, la raíz llamaba a MPI_Bcast y los demás a MPI_Recv. Un MPI_Recv nunca
 * empareja el mensaje interno de una colectiva: los rangos 1..p-1 esperan para siempre; la raíz sale del
 * Bcast (mensaje pequeño, envío inmediato) y se queda esperando en MPI_Scatterv a procesos que nunca
 * llegan. Con -np 1 "funciona": no hay nadie a quien esperar. Eso no es evidencia de correctitud.
 * La corrección: decidir n en la raíz y después llamar a MPI_Bcast desde todos, con los mismos argumentos.
 */
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>

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

    /* 1. La raíz decide n; TODOS llaman a MPI_Bcast (la raíz envía, los demás reciben). */
    if (rank == 0) {
        n = (argc > 1) ? atoi(argv[1]) : 1000;
        if (n <= 0) {
            fprintf(stderr, "uso: %s [n>0]\n", argv[0]);
            MPI_Abort(MPI_COMM_WORLD, 1);
        }
    }
    MPI_Bcast(&n, 1, MPI_INT, 0, MPI_COMM_WORLD);   /* ← fuera del if: la llaman todos */

    /* 2. Reparto. */
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

    /* 3. Suma local y reducción. */
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
