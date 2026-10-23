/*
 * matvec_bcast_buggy.c — VARIANTE QUE FALLA A PROPÓSITO (idea errónea 18 del Anexo A:
 * "solo el proceso raíz llama a MPI_Bcast").
 *
 * Es matvec_collectives.c con UN cambio: el MPI_Bcast de x está dentro de if (rank == 0).
 * Los rangos 1..p−1 nunca "reciben" x: siguen con x = 0.0 (calloc) hacia el cómputo y
 * el Gather. Lo que pasa después depende de la implementación y del tamaño de x:
 *   - si el rango 0 se queda esperando dentro de Bcast, el programa SE CUELGA;
 *   - si la implementación le dejó salir, el resultado es INCORRECTO (filas con y = 0)
 *     y puede colgarse o abortar más adelante.
 * Las dos cosas son síntomas del mismo error: una colectiva que no llamaron todos.
 * Córrelo SIEMPRE con timeout:   timeout 10 mpirun -np 4 ./matvec_bcast_buggy 8
 */
#include <mpi.h>
#include "matvec_data.h"

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    long long n;
    int reps;
    if (parse_args(argc, argv, &n, &reps) != 0) { MPI_Finalize(); return 1; }
    if (n % size != 0) {
        if (rank == 0) printf("n = %lld no es multiplo de p = %d.\n", n, size);
        MPI_Finalize();
        return 1;
    }
    long long local_n = n / size;

    double *A = NULL, *y = NULL;
    if (rank == 0) {
        A = alloc_doubles(n * n);
        y = alloc_doubles(n);
        fill_rows(A, 0, n, n);
    }
    double *x = alloc_doubles(n);
    if (rank == 0) fill_vector(x, n);
    double *A_local = alloc_doubles(local_n * n);
    double *y_local = alloc_doubles(local_n);

    MPI_Scatter(A, (int)(local_n * n), MPI_DOUBLE,
                A_local, (int)(local_n * n), MPI_DOUBLE, 0, MPI_COMM_WORLD);

    /* ERROR: "el que tiene x es el 0, que la mande él". Una colectiva no es un Send:
     * describe la operación completa y la deben ejecutar TODOS los procesos. */
    if (rank == 0)
        MPI_Bcast(x, (int)n, MPI_DOUBLE, 0, MPI_COMM_WORLD);

    local_matvec(A_local, x, y_local, local_n, n);

    MPI_Gather(y_local, (int)local_n, MPI_DOUBLE,
               y, (int)local_n, MPI_DOUBLE, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        printf("n = %lld, p = %d, filas por rango = %lld (BUGGY: Bcast solo en el rango 0)\n",
               n, size, local_n);
        print_vector_if_small(y, n);
        printf("checksum = %.6f\n", vector_sum(y, n));
    }

    free(A); free(y); free(x); free(A_local); free(y_local);
    MPI_Finalize();
    return 0;
}
