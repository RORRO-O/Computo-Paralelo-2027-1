/* item_II1_mpi.c — Examen de práctica U4–U5, sección II, ítem 1 (predecir la salida).
 * Se ejecuta con: mpirun --oversubscribe -np 4 ./item_II1_mpi   (y con -np 1 para el inciso d)
 */
#include <mpi.h>
#include <stdio.h>

int main(int argc, char **argv) {
    int rank, size, value, total = 0, from_left = -1, max_root = 0;
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    value = rank + 1;
    int right = (rank + 1) % size, left = (rank + size - 1) % size;
    MPI_Allreduce(&value, &total, 1, MPI_INT, MPI_SUM, MPI_COMM_WORLD);
    MPI_Sendrecv(&value, 1, MPI_INT, right, 7, &from_left, 1, MPI_INT, left, 7,
                 MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    MPI_Reduce(&from_left, &max_root, 1, MPI_INT, MPI_MAX, 0, MPI_COMM_WORLD);
    printf("rango %d: value=%d total=%d from_left=%d max_root=%d\n", rank, value, total, from_left, max_root);
    MPI_Finalize();
    return 0;
}
