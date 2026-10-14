/* item_III1_mean_buggy.c — Examen de práctica U4–U5, sección III, ítem 1 (encontrar y corregir el error).
 *
 * Qué debe hacer: la raíz reparte x[8] = {1,…,8} en bloques de 2; cada rango resta la MEDIA GLOBAL (4.5)
 * a su bloque e imprime el resultado. Exactamente 4 procesos.
 * Síntoma con el error: compila, no se cuelga, el rango 0 imprime media=4.50 y los rangos 1–3 imprimen
 * media=0.00 (centran su bloque con una media que no es).
 *   mpicc -std=c11 -O2 -Wall -Wextra item_III1_mean_buggy.c -o item_III1_mean_buggy
 *   mpirun --oversubscribe -np 4 ./item_III1_mean_buggy
 * La corrección del examen se obtiene con -DCORREGIDO (la clave está en examen-practica-U4-U5.md).
 */
#include <mpi.h>
#include <stdio.h>

int main(int argc, char **argv) {
    int rank, size;
    const int n = 8;
    double x[8], local[2], local_sum, total = 0.0;
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    if (size != 4) {                              /* el reparto fijo 8 = 4 x 2 exige exactamente 4 procesos */
        if (rank == 0) fprintf(stderr, "este item requiere exactamente 4 procesos (hay %d)\n", size);
        MPI_Finalize();
        return 1;
    }
    if (rank == 0)
        for (int i = 0; i < n; i++) x[i] = i + 1.0;                        /* 1 2 3 4 5 6 7 8 */
    MPI_Scatter(x, 2, MPI_DOUBLE, local, 2, MPI_DOUBLE, 0, MPI_COMM_WORLD); /* rango r: x[2r], x[2r+1] */
    local_sum = local[0] + local[1];
#ifdef CORREGIDO
    MPI_Allreduce(&local_sum, &total, 1, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);   /* total en TODOS */
#else
    MPI_Reduce(&local_sum, &total, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);   /* total solo en la raíz */
#endif
    double mean = total / n;                      /* cada rango usa "su" total */
    local[0] -= mean;
    local[1] -= mean;
    printf("rango %d: media=%.2f centrado=%.2f %.2f\n", rank, mean, local[0], local[1]);
    MPI_Finalize();
    return 0;
}
