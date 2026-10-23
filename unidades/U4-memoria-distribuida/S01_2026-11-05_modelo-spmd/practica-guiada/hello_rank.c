/*
 * hello_rank.c — "Hola" desde cada proceso MPI.
 *
 * Objetivo didáctico: ver el modelo SPMD (un programa, muchos procesos),
 * las ramas por rango y que cada proceso tiene SU PROPIA memoria.
 *
 * Compilar:  mpicc -std=c11 -O2 -Wall -Wextra -o hello_rank hello_rank.c
 * Ejecutar:  mpirun -np 4 ./hello_rank
 */
#define _POSIX_C_SOURCE 200809L /* habilita getpid() con -std=c11 */
#include <mpi.h>
#include <stdio.h>
#include <unistd.h>

/* Variable global. Si la memoria fuera compartida, cada proceso vería lo que
 * sumaron los demás. No lo es: cada proceso tiene su propia copia de counter. */
static int counter = 0;

int main(int argc, char **argv)
{
    /* Arranca el entorno MPI. Antes de esta línea no existen rangos. */
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank); /* ¿quién soy?   0 .. size-1 */
    MPI_Comm_size(MPI_COMM_WORLD, &size); /* ¿cuántos somos? */

    char host[MPI_MAX_PROCESSOR_NAME];
    int host_len;
    MPI_Get_processor_name(host, &host_len);

    /* Todos los procesos ejecutan esta línea: salen 'size' líneas, en un
     * orden que NO está garantizado (cada corrida puede cambiar). */
    printf("Hola desde el proceso %d de %d (pid %d, nodo %s)\n",
           rank, size, (int)getpid(), host);

    /* Cada proceso suma sobre SU copia de counter. */
    counter += rank + 1;
    printf("[rango %d] counter = %d\n", rank, counter);

    /* Ramas por rango: el mismo programa hace cosas distintas según quién
     * lo ejecuta. Ningún rango es "especial" por sí mismo. */
    if (rank == 0)
        printf("[rango %d] soy el rango 0; nada me obliga a ser el \"maestro\"\n", rank);
    if (rank == size - 1)
        printf("[rango %d] soy el ultimo rango; tambien puedo hacer trabajo especial\n", rank);

    /* Cierra el entorno MPI. Después de esta línea no se llama a MPI. */
    MPI_Finalize();
    return 0;
}
