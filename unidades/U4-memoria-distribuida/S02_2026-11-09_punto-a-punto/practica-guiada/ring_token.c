/*
 * ring_token.c — Anillo de paso de token (práctica guiada S02, Unidad IV).
 *
 * El rango 0 inicia el token con un valor (argumento; por defecto 0) y lo
 * envía al rango 1. Cada rango r >= 1 recibe el token del rango r-1, le suma
 * su propio rango y lo envía al rango (r+1) % size. El último se lo devuelve
 * al rango 0, que imprime el valor final.
 *
 * Orden de operaciones (importa):
 *   rango 0:      Send -> Recv   (rompe la simetría del anillo)
 *   rangos r>=1:  Recv -> Send
 * Si todos los rangos hicieran Recv primero, nadie enviaría nunca: interbloqueo.
 *
 * Uso: mpirun -np N ./ring_token [valor_inicial]
 *
 * Las líneas de distintos rangos pueden salir desordenadas en la terminal:
 * cada proceso escribe en su propia salida y mpirun las mezcla.
 */
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>

#define TAG_TOKEN 1

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    int token = (argc > 1) ? atoi(argv[1]) : 0; /* cada proceso tiene su copia */
    int next = (rank + 1) % size;               /* vecino derecho               */
    int prev = (rank - 1 + size) % size;        /* vecino izquierdo             */

    if (size == 1) {
        printf("rango 0: soy el unico proceso; token final = %d (no hubo mensajes)\n",
               token);
        MPI_Finalize();
        return 0;
    }

    MPI_Status status;

    if (rank == 0) {
        /* El rango 0 inicia: envía primero. Su rango es 0, así que no suma nada. */
        MPI_Send(&token, 1, MPI_INT, next, TAG_TOKEN, MPI_COMM_WORLD);

        int sent = token;
        token = -1; /* el búfer es nuestro otra vez; el rango 1 recibirá 'sent', no -1 */
        printf("rango 0: envie %d al rango %d; mi copia local ahora vale %d\n",
               sent, next, token);

        MPI_Recv(&token, 1, MPI_INT, prev, TAG_TOKEN, MPI_COMM_WORLD, &status);
        printf("rango 0: recibi %d del rango %d -> token final = %d\n",
               token, status.MPI_SOURCE, token);
    } else {
        MPI_Recv(&token, 1, MPI_INT, prev, TAG_TOKEN, MPI_COMM_WORLD, &status);
        int received = token;

        token += rank; /* cada rango suma su número */
        MPI_Send(&token, 1, MPI_INT, next, TAG_TOKEN, MPI_COMM_WORLD);

        printf("rango %d: recibi %d del rango %d, sume %d y envie %d al rango %d\n",
               rank, received, status.MPI_SOURCE, rank, token, next);
    }

    MPI_Finalize();
    return 0;
}
