/*
 * status_demo.c — Ejemplo resuelto de la sesión S02 (Unidad IV).
 *
 * Qué muestra: la firma completa de MPI_Send y MPI_Recv, las etiquetas,
 * los comodines MPI_ANY_SOURCE / MPI_ANY_TAG, la estructura MPI_Status y
 * la función MPI_Get_count.
 *
 * Qué hace: cada rango r >= 1 envía al rango 0 un arreglo de (r + 2) enteros
 * con la etiqueta 10*r. El rango 0 recibe (size - 1) mensajes SIN saber de
 * antemano quién llega primero ni cuántos elementos trae; lo averigua con
 * MPI_Status y MPI_Get_count.
 *
 * Compilar: mpicc -std=c11 -O2 -Wall -Wextra -o status_demo status_demo.c
 * Ejecutar: mpirun -np 3 ./status_demo
 *
 * El orden en que llegan los mensajes al rango 0 NO está garantizado: dos
 * corridas pueden imprimir las líneas en distinto orden.
 */
#include <mpi.h>
#include <stdio.h>

#define CAPACITY 64 /* capacidad del búfer de recepción, en elementos */

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    if (size < 2 || size > CAPACITY - 1) {
        if (rank == 0)
            fprintf(stderr, "Uso: mpirun -np N ./status_demo   con 2 <= N <= %d\n",
                    CAPACITY - 1);
        MPI_Finalize();
        return 1;
    }

    int buf[CAPACITY]; /* cada proceso tiene SU PROPIO buf: no se comparte */

    if (rank != 0) {
        /* --- Emisor: el mensaje son 'count' enteros con etiqueta 'tag' --- */
        int count = rank + 2;  /* cuántos elementos envía este rango        */
        int tag = 10 * rank;   /* etiqueta: entero >= 0 que elige el programa */
        for (int i = 0; i < count; i++)
            buf[i] = rank * 100 + i;

        /* MPI_Send(buffer, cuenta, tipo, destino, etiqueta, comunicador)   */
        MPI_Send(buf, count, MPI_INT, 0, tag, MPI_COMM_WORLD);

        /* Cuando MPI_Send regresa, buf ya se puede reutilizar. Eso NO quiere
         * decir que el rango 0 ya recibió el mensaje: solo que MPI ya no
         * necesita nuestro búfer (lo copió o lo entregó).                  */
        buf[0] = -1; /* no afecta lo que recibe el rango 0 */
    } else {
        /* --- Receptor: no sabe quién ni cuánto; usa comodines y status --- */
        for (int k = 0; k < size - 1; k++) {
            MPI_Status status;
            /* MPI_Recv(buffer, CAPACIDAD, tipo, fuente, etiqueta, comunicador, status)
             * 'CAPACIDAD' es el máximo que cabe, no lo que llega.           */
            MPI_Recv(buf, CAPACITY, MPI_INT, MPI_ANY_SOURCE, MPI_ANY_TAG,
                     MPI_COMM_WORLD, &status);

            int received; /* cuántos elementos llegaron en realidad */
            MPI_Get_count(&status, MPI_INT, &received);

            printf("rango 0: mensaje %d de %d -> fuente=%d etiqueta=%d "
                   "elementos=%d (capacidad=%d) primero=%d ultimo=%d\n",
                   k + 1, size - 1, status.MPI_SOURCE, status.MPI_TAG,
                   received, CAPACITY, buf[0], buf[received - 1]);
        }
    }

    MPI_Finalize();
    return 0;
}
