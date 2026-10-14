/*
 * a1_hello_rank.c — Parte A.1: hola con rangos.
 *
 * Cada proceso imprime su rango, el tamaño del comunicador y la máquina donde corre. Esas líneas
 * salen en el orden en que el sistema operativo las programe (no determinista). Después el rango 0
 * reúne con MPI_Gather el rango y el nombre de máquina de todos y los imprime en orden: así se ve la
 * diferencia entre "cada quien imprime" y "uno junta y ordena".
 *
 * Uso:      mpirun -np P ./a1_hello_rank
 * Compilar: mpicc -std=c11 -O2 -Wall -Wextra -o a1_hello_rank a1_hello_rank.c
 */
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);

    int rank, size, name_len;
    char host[MPI_MAX_PROCESSOR_NAME];
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Get_processor_name(host, &name_len);

    /* 1. Cada proceso habla por sí mismo. Nada garantiza el orden de estas líneas. */
    printf("hola desde el rango %d de %d en %s\n", rank, size, host);

    /* 2. Un dato por proceso viaja al rango 0 con MPI_Gather: en all_ranks[k] queda lo que envió el
     *    rango k (la colectiva ordena por rango, aunque las impresiones de arriba salgan revueltas).
     *    TODOS llaman a MPI_Gather; solo en la raíz el búfer de recepción tiene sentido. */
    int *all_ranks = NULL;
    char *all_hosts = NULL;
    if (rank == 0) {
        all_ranks = malloc((size_t)size * sizeof(int));
        all_hosts = malloc((size_t)size * MPI_MAX_PROCESSOR_NAME);
        if (!all_ranks || !all_hosts) MPI_Abort(MPI_COMM_WORLD, 2);
    }
    MPI_Gather(&rank, 1, MPI_INT, all_ranks, 1, MPI_INT, 0, MPI_COMM_WORLD);
    MPI_Gather(host, MPI_MAX_PROCESSOR_NAME, MPI_CHAR,
               all_hosts, MPI_MAX_PROCESSOR_NAME, MPI_CHAR, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        printf("rango 0 reunio con MPI_Gather %d rangos:", size);
        for (int k = 0; k < size; k++) printf(" %d", all_ranks[k]);
        printf("\n");
        for (int k = 0; k < size; k++)
            printf("  rango %d corre en %s\n", k, all_hosts + (size_t)k * MPI_MAX_PROCESSOR_NAME);
        free(all_ranks);
        free(all_hosts);
    }

    MPI_Finalize();
    return 0;
}
