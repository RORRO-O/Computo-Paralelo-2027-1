/* item_IV_dot_mpi.c — Examen de práctica U4–U5, sección IV(a), con los huecos YA llenos (clave).
 * Producto punto distribuido; n divisible entre el número de procesos.
 *   mpirun --oversubscribe -np 4 ./item_IV_dot_mpi      → dot=36.000000  (x[i] = i+1, y[i] = 1, n = 8)
 */
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
    int rank, size;
    const int n = 8;
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    if (n % size != 0) {
        if (rank == 0) fprintf(stderr, "n=%d debe ser divisible entre %d procesos\n", n, size);
        MPI_Finalize();
        return 1;
    }
    double x[8], y[8];
    if (rank == 0)
        for (int i = 0; i < n; i++) { x[i] = i + 1.0; y[i] = 1.0; }

    int local_n = n / size;
    double *local_x = malloc(local_n * sizeof(double));
    double *local_y = malloc(local_n * sizeof(double));
    /* (1) cuántos elementos recibe CADA proceso: local_n, en el envío y en la recepción */
    MPI_Scatter(x, local_n, MPI_DOUBLE, local_x, local_n, MPI_DOUBLE, 0, MPI_COMM_WORLD);
    MPI_Scatter(y, local_n, MPI_DOUBLE, local_y, local_n, MPI_DOUBLE, 0, MPI_COMM_WORLD);

    double local_dot = 0.0, dot = 0.0;
    for (int i = 0; i < local_n; i++) local_dot += local_x[i] * local_y[i];
    /* (2) la colectiva que junta en la raíz; (3) tipo y operación */
    MPI_Reduce(&local_dot, &dot, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

    if (rank == 0) printf("dot=%f\n", dot);
    free(local_x);
    free(local_y);
    MPI_Finalize();
    return 0;
}
