/*
 * matvec_p2p.c — El MISMO producto matriz-vector por filas, pero solo con MPI_Send/MPI_Recv
 * (estilo de S01/S02). Sirve para comparar con matvec_collectives.c en líneas de código
 * y en tiempo: hace exactamente las mismas tres etapas de comunicación "a mano".
 *
 *   1. Repartir filas : el rango 0 hace p−1 MPI_Send (uno por rango) con su bloque de filas.
 *   2. Mandar x       : el rango 0 hace otros p−1 MPI_Send con x completo.
 *   3. Cómputo local.
 *   4. Juntar y       : cada rango != 0 hace MPI_Send de su bloque; el 0 hace p−1 MPI_Recv.
 *
 * Es seguro (el 0 solo envía mientras los demás solo reciben, y luego al revés), pero el
 * rango 0 serializa todo: p−1 envíos uno tras otro en cada etapa.
 *
 * Uso: mpirun -np p ./matvec_p2p [n] [reps]      (n múltiplo de p, como en matvec_collectives)
 */
#include <mpi.h>
#include <string.h>
#include "matvec_data.h"

enum { TAG_ROWS = 1, TAG_X = 2, TAG_Y = 3 };

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

    MPI_Barrier(MPI_COMM_WORLD);
    double t0 = MPI_Wtime();

    /* ---- 1 y 2. Repartir filas y x: lo que Scatter + Bcast hacen en dos líneas ---- */
    if (rank == 0) {
        memcpy(A_local, A, (size_t)(local_n * n) * sizeof(double)); /* mi propio bloque */
        for (int dest = 1; dest < size; dest++) {
            MPI_Send(A + dest * local_n * n, (int)(local_n * n), MPI_DOUBLE,
                     dest, TAG_ROWS, MPI_COMM_WORLD);
            MPI_Send(x, (int)n, MPI_DOUBLE, dest, TAG_X, MPI_COMM_WORLD);
        }
    } else {
        MPI_Recv(A_local, (int)(local_n * n), MPI_DOUBLE, 0, TAG_ROWS,
                 MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        MPI_Recv(x, (int)n, MPI_DOUBLE, 0, TAG_X, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    }
    double t1 = MPI_Wtime();

    /* ---- 3. Cómputo local, idéntico al de la versión con colectivas ---- */
    for (int r = 0; r < reps; r++)
        local_matvec(A_local, x, y_local, local_n, n);
    double t2 = MPI_Wtime();

    /* ---- 4. Juntar y: lo que Gather hace en una línea ---- */
    if (rank == 0) {
        memcpy(y, y_local, (size_t)local_n * sizeof(double));
        for (int src = 1; src < size; src++)
            MPI_Recv(y + src * local_n, (int)local_n, MPI_DOUBLE, src, TAG_Y,
                     MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    } else {
        MPI_Send(y_local, (int)local_n, MPI_DOUBLE, 0, TAG_Y, MPI_COMM_WORLD);
    }
    double t3 = MPI_Wtime();

    if (rank == 0) {
        printf("n = %lld, p = %d, filas por rango = %lld, reps = %d (punto a punto)\n",
               n, size, local_n, reps);
        print_vector_if_small(y, n);
        printf("checksum = %.6f\n", vector_sum(y, n));
        printf("tiempos (s): repartir = %.6f, calcular = %.6f (rango 0), juntar = %.6f, total = %.6f\n",
               t1 - t0, t2 - t1, t3 - t2, t3 - t0);
    }

    free(A); free(y); free(x); free(A_local); free(y_local);
    MPI_Finalize();
    return 0;
}
