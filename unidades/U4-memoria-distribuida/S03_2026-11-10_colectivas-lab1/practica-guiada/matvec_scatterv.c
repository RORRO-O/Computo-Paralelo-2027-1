/*
 * matvec_scatterv.c — Panorama: el mismo producto cuando n NO es múltiplo de p.
 *
 * MPI_Scatter y MPI_Gather reparten bloques IGUALES. Cuando los bloques son distintos
 * (reparto por bloques con residuo, como block_range de S01) se usan las versiones "v":
 *   MPI_Scatterv(sendbuf, sendcounts[], displs[], type, recvbuf, recvcount, type, root, comm)
 *   MPI_Gatherv (sendbuf, sendcount, type, recvbuf, recvcounts[], displs[], type, root, comm)
 * Los arreglos sendcounts/recvcounts y displs (desplazamientos, en elementos) solo los lee
 * la raíz, pero TODOS los procesos llaman a la colectiva.
 *
 * Uso: mpirun -np p ./matvec_scatterv [n] [reps]      (cualquier n ≥ 1)
 */
#include <mpi.h>
#include "matvec_data.h"

/* Reparto por bloques con residuo (igual que en S01): los primeros r rangos llevan una fila más. */
static void block_rows(long long n, int rank, int size, long long *first, long long *count)
{
    long long q = n / size, r = n % size;
    *count = q + (rank < r ? 1 : 0);
    *first = rank * q + (rank < r ? rank : r);
}

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    long long n;
    int reps;
    if (parse_args(argc, argv, &n, &reps) != 0) { MPI_Finalize(); return 1; }

    long long my_first, my_rows;
    block_rows(n, rank, size, &my_first, &my_rows);

    /* Cuentas y desplazamientos de TODOS los bloques; los calcula cada rango (son baratos)
     * aunque solo la raíz los use dentro de Scatterv/Gatherv. */
    int *row_counts = malloc((size_t)size * sizeof(int));   /* filas por rango           */
    int *row_displs = malloc((size_t)size * sizeof(int));   /* fila inicial por rango    */
    int *elem_counts = malloc((size_t)size * sizeof(int));  /* elementos de A por rango  */
    int *elem_displs = malloc((size_t)size * sizeof(int));  /* elemento inicial por rango */
    if (!row_counts || !row_displs || !elem_counts || !elem_displs) MPI_Abort(MPI_COMM_WORLD, 2);
    for (int k = 0; k < size; k++) {
        long long f, c;
        block_rows(n, k, size, &f, &c);
        row_counts[k] = (int)c;        row_displs[k] = (int)f;
        elem_counts[k] = (int)(c * n); elem_displs[k] = (int)(f * n);
    }

    double *A = NULL, *y = NULL;
    if (rank == 0) {
        A = alloc_doubles(n * n);
        y = alloc_doubles(n);
        fill_rows(A, 0, n, n);
    }
    double *x = alloc_doubles(n);
    if (rank == 0) fill_vector(x, n);
    double *A_local = alloc_doubles((my_rows > 0 ? my_rows : 1) * n);
    double *y_local = alloc_doubles(my_rows > 0 ? my_rows : 1);

    MPI_Barrier(MPI_COMM_WORLD);
    double t0 = MPI_Wtime();

    MPI_Scatterv(A, elem_counts, elem_displs, MPI_DOUBLE,
                 A_local, (int)(my_rows * n), MPI_DOUBLE, 0, MPI_COMM_WORLD);
    MPI_Bcast(x, (int)n, MPI_DOUBLE, 0, MPI_COMM_WORLD);

    for (int r = 0; r < reps; r++)
        local_matvec(A_local, x, y_local, my_rows, n);

    MPI_Gatherv(y_local, (int)my_rows, MPI_DOUBLE,
                y, row_counts, row_displs, MPI_DOUBLE, 0, MPI_COMM_WORLD);
    double t1 = MPI_Wtime();

    if (rank == 0) {
        printf("n = %lld, p = %d, reps = %d (Scatterv/Gatherv); filas por rango:", n, size, reps);
        for (int k = 0; k < size; k++) printf(" %d", row_counts[k]);
        printf("\n");
        print_vector_if_small(y, n);
        printf("checksum = %.6f\n", vector_sum(y, n));
        printf("tiempos (s): total = %.6f\n", t1 - t0);
    }

    free(A); free(y); free(x); free(A_local); free(y_local);
    free(row_counts); free(row_displs); free(elem_counts); free(elem_displs);
    MPI_Finalize();
    return 0;
}
