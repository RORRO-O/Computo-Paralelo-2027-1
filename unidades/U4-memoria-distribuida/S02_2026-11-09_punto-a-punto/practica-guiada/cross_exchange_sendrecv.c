/*
 * cross_exchange_sendrecv.c — Fase MODIFICAR de la práctica guiada S02.
 *
 * Es una copia de cross_exchange_buggy.c. Tu trabajo: sustituir el par
 * MPI_Send + MPI_Recv (inseguro) por UNA llamada a MPI_Sendrecv, que envía y
 * recibe "a la vez" y por eso no puede interbloquearse con su pareja.
 *
 * Prototipo (MPI Standard, sección Send-Receive):
 *   int MPI_Sendrecv(const void *sendbuf, int sendcount, MPI_Datatype sendtype,
 *                    int dest, int sendtag,
 *                    void *recvbuf, int recvcount, MPI_Datatype recvtype,
 *                    int source, int recvtag,
 *                    MPI_Comm comm, MPI_Status *status);
 *
 * Criterio de "listo":
 *   mpirun -np 2 ./cross_exchange_sendrecv 1000000   termina e imprime
 *   "intercambio correcto" en los dos rangos, y `make test` marca PASS
 *   en el caso cross_exchange_sendrecv.
 *
 * Uso: mpirun -np N ./cross_exchange_sendrecv [n]   (N par; n por defecto 1000000)
 */
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>

#define TAG_DATA 5

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    if (size % 2 != 0) {
        if (rank == 0)
            fprintf(stderr, "Uso: mpirun -np N ./cross_exchange_sendrecv [n]  con N par\n");
        MPI_Finalize();
        return 1;
    }

    int n = (argc > 1) ? atoi(argv[1]) : 1000000;
    if (n < 1) n = 1;
    int partner = rank ^ 1;

    int *send_buf = malloc((size_t)n * sizeof(int));
    int *recv_buf = malloc((size_t)n * sizeof(int));
    if (send_buf == NULL || recv_buf == NULL) {
        fprintf(stderr, "rango %d: sin memoria para n=%d\n", rank, n);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }
    for (int i = 0; i < n; i++) send_buf[i] = rank + i;

    MPI_Status status;

    /* TODO(1): sustituye las DOS llamadas marcadas abajo por UNA llamada a
     * MPI_Sendrecv que envíe send_buf (n enteros, TAG_DATA) a partner y reciba
     * recv_buf (n enteros, TAG_DATA) de partner, dejando el estado en status.
     * Cuando lo hagas, cambia todo_pending a 0 (o borra esa bandera).        */
    int todo_pending = 1;
    if (todo_pending) {
        if (rank == 0)
            printf("TODO pendiente: completa TODO(1) en cross_exchange_sendrecv.c\n");
        free(send_buf);
        free(recv_buf);
        MPI_Finalize();
        return 0;
    }

    /* >>> reemplaza estas dos llamadas por MPI_Sendrecv <<< */
    MPI_Send(send_buf, n, MPI_INT, partner, TAG_DATA, MPI_COMM_WORLD);
    MPI_Recv(recv_buf, n, MPI_INT, partner, TAG_DATA, MPI_COMM_WORLD, &status);
    /* >>> fin de la zona a reemplazar <<< */

    int received;
    MPI_Get_count(&status, MPI_INT, &received);
    int errors = (received != n);
    for (int i = 0; i < n && !errors; i++)
        if (recv_buf[i] != partner + i) errors = 1;

    if (errors)
        printf("rango %d: ERROR en el intercambio con rango %d (n=%d, recibidos=%d)\n",
               rank, partner, n, received);
    else
        printf("rango %d: intercambio correcto con rango %d (n=%d, recibidos=%d)\n",
               rank, partner, n, received);

    free(send_buf);
    free(recv_buf);
    MPI_Finalize();
    return errors;
}
