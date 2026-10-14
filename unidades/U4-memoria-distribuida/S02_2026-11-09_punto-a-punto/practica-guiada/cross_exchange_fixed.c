/*
 * cross_exchange_fixed.c — Dos correcciones del intercambio cruzado inseguro
 * de cross_exchange_buggy.c. (La tercera, MPI_Sendrecv, la escribes tú en
 * cross_exchange_sendrecv.c.)
 *
 *   paridad : los rangos pares envían primero y luego reciben; los impares
 *             reciben primero y luego envían. Siempre hay un receptor listo
 *             para cada emisor, sin importar el tamaño ni el buffering.
 *   noblock : adelanto de la sesión S04. MPI_Irecv y MPI_Isend INICIAN las
 *             operaciones y regresan de inmediato; MPI_Wait espera a que cada
 *             una termine. Como las dos están en curso a la vez, no hay
 *             espera circular.
 *
 * Uso: mpirun -np N ./cross_exchange_fixed <paridad|noblock> [n]   (N par)
 */
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TAG_DATA 5

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    const char *mode = (argc > 1) ? argv[1] : "";
    int use_parity = (strcmp(mode, "paridad") == 0);
    int use_nonblocking = (strcmp(mode, "noblock") == 0);

    if (size % 2 != 0 || (!use_parity && !use_nonblocking)) {
        if (rank == 0)
            fprintf(stderr,
                    "Uso: mpirun -np N ./cross_exchange_fixed <paridad|noblock> [n]  con N par\n");
        MPI_Finalize();
        return 1;
    }

    int n = (argc > 2) ? atoi(argv[2]) : 1000000;
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

    if (use_parity) {
        /* Orden por paridad: par = Send->Recv, impar = Recv->Send. */
        if (rank % 2 == 0) {
            MPI_Send(send_buf, n, MPI_INT, partner, TAG_DATA, MPI_COMM_WORLD);
            MPI_Recv(recv_buf, n, MPI_INT, partner, TAG_DATA, MPI_COMM_WORLD, &status);
        } else {
            MPI_Recv(recv_buf, n, MPI_INT, partner, TAG_DATA, MPI_COMM_WORLD, &status);
            MPI_Send(send_buf, n, MPI_INT, partner, TAG_DATA, MPI_COMM_WORLD);
        }
    } else {
        /* No bloqueante (adelanto de S04): iniciar las dos, esperar las dos.
         * Regla: NO tocar send_buf ni recv_buf entre el I* y su MPI_Wait. */
        MPI_Request recv_req, send_req;
        MPI_Irecv(recv_buf, n, MPI_INT, partner, TAG_DATA, MPI_COMM_WORLD, &recv_req);
        MPI_Isend(send_buf, n, MPI_INT, partner, TAG_DATA, MPI_COMM_WORLD, &send_req);
        MPI_Wait(&recv_req, &status);           /* status de la recepción */
        MPI_Wait(&send_req, MPI_STATUS_IGNORE); /* el envío no trae status útil */
    }

    int received;
    MPI_Get_count(&status, MPI_INT, &received);
    int errors = (received != n);
    for (int i = 0; i < n && !errors; i++)
        if (recv_buf[i] != partner + i) errors = 1;

    if (errors)
        printf("rango %d: ERROR en el intercambio con rango %d (n=%d, recibidos=%d, modo=%s)\n",
               rank, partner, n, received, mode);
    else
        printf("rango %d: intercambio correcto con rango %d (n=%d, recibidos=%d, modo=%s)\n",
               rank, partner, n, received, mode);

    free(send_buf);
    free(recv_buf);
    MPI_Finalize();
    return errors;
}
