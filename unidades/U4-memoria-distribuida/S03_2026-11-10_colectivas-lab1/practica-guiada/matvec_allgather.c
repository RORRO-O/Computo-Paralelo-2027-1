/*
 * matvec_allgather.c — Fase MODIFICAR de la práctica guiada: que TODOS los rangos terminen
 * con el vector y completo (no solo el 0), usando MPI_Allgather en lugar de MPI_Gather.
 *
 * ¿Para qué? En un método iterativo (potencias, Jacobi, gradiente conjugado) el y de esta
 * iteración es el x de la siguiente, y x lo necesitan TODOS: con Gather habría que hacer
 * Gather + Bcast; Allgather lo hace en una sola colectiva.
 *
 * Firma:  int MPI_Allgather(const void *sendbuf, int sendcount, MPI_Datatype sendtype,
 *                           void *recvbuf, int recvcount, MPI_Datatype recvtype, MPI_Comm comm);
 *         (como Gather, pero sin 'root': el resultado queda en el recvbuf de todos.)
 *
 * Uso: mpirun -np p ./matvec_allgather [n] [reps]      (n múltiplo de p)
 * Hasta que completes el TODO(1) el programa imprime "TODO pendiente" y termina.
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

    double *A = NULL;
    if (rank == 0) {
        A = alloc_doubles(n * n);
        fill_rows(A, 0, n, n);
    }
    double *x = alloc_doubles(n);
    if (rank == 0) fill_vector(x, n);
    double *A_local = alloc_doubles(local_n * n);
    double *y_local = alloc_doubles(local_n);
    double *y = alloc_doubles(n); /* AHORA lo reservan todos: todos van a tener y completo */

    MPI_Scatter(A, (int)(local_n * n), MPI_DOUBLE,
                A_local, (int)(local_n * n), MPI_DOUBLE, 0, MPI_COMM_WORLD);
    MPI_Bcast(x, (int)n, MPI_DOUBLE, 0, MPI_COMM_WORLD);

    for (int r = 0; r < reps; r++)
        local_matvec(A_local, x, y_local, local_n, n);

    int todo_pending = 1;
    /* TODO(1): sustituye el Gather por una sola llamada a MPI_Allgather que deje el y
     * completo en el arreglo 'y' de TODOS los rangos. Después pon todo_pending = 0.
     * Pista: los seis primeros argumentos son los mismos que en Gather; no hay 'root'. */
    MPI_Gather(y_local, (int)local_n, MPI_DOUBLE,
               y, (int)local_n, MPI_DOUBLE, 0, MPI_COMM_WORLD);

    if (todo_pending) {
        if (rank == 0) printf("TODO pendiente: TODO(1) en matvec_allgather.c\n");
        free(A); free(x); free(A_local); free(y_local); free(y);
        MPI_Finalize();
        return 0;
    }

    /* Cada rango verifica por su cuenta que tiene el vector completo. */
    printf("[rango %d] y completo: y[0] = %.1f, y[%lld] = %.1f, checksum = %.6f\n",
           rank, y[0], n - 1, y[n - 1], vector_sum(y, n));

    free(A); free(x); free(A_local); free(y_local); free(y);
    MPI_Finalize();
    return 0;
}
