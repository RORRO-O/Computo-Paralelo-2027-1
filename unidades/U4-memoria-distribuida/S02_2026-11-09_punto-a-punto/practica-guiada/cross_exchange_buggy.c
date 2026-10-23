/*
 * cross_exchange_buggy.c — Intercambio cruzado INSEGURO (el defecto es
 * intencional; por eso el archivo termina en _buggy).
 *
 * Cada rango envía n enteros a su pareja (rank ^ 1: 0<->1, 2<->3, ...) y
 * después recibe los n enteros de ella. LOS DOS hacen MPI_Send primero.
 *
 * El estándar MPI dice que MPI_Send regresa cuando el búfer de envío se puede
 * reutilizar. Eso puede ocurrir ANTES de que exista el MPI_Recv del otro lado
 * (si la implementación copió el mensaje a un búfer interno) o DESPUÉS (si
 * decidió no copiarlo y espera al receptor). El programa es correcto solo si
 * funciona en ambos casos; este no: depende de que haya copia.
 *
 * En Open MPI, con los dos procesos en la misma máquina, los mensajes de pocos
 * bytes se copian (protocolo "eager") y los grandes no ("rendezvous"):
 *   mpirun -np 2 ./cross_exchange_buggy 10        -> termina
 *   mpirun -np 2 ./cross_exchange_buggy 1000000   -> se cuelga (interbloqueo)
 * El cuelgue es el síntoma esperado. En tests/run_tests.sh se ejecuta con
 * "timeout 10" para que la prueba termine.
 *
 * Uso: mpirun -np 2 ./cross_exchange_buggy [n]     (n enteros; por defecto 10)
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
            fprintf(stderr, "Uso: mpirun -np N ./cross_exchange_buggy [n]  con N par\n");
        MPI_Finalize();
        return 1;
    }

    int n = (argc > 1) ? atoi(argv[1]) : 10;
    if (n < 1) n = 1;
    int partner = rank ^ 1; /* 0<->1, 2<->3, ... */

    int *send_buf = malloc((size_t)n * sizeof(int));
    int *recv_buf = malloc((size_t)n * sizeof(int));
    if (send_buf == NULL || recv_buf == NULL) {
        fprintf(stderr, "rango %d: sin memoria para n=%d\n", rank, n);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }
    for (int i = 0; i < n; i++) send_buf[i] = rank + i; /* patrón verificable */

    MPI_Status status;

    /* ---- Zona insegura: los dos lados envían primero ---------------------- */
    MPI_Send(send_buf, n, MPI_INT, partner, TAG_DATA, MPI_COMM_WORLD);
    MPI_Recv(recv_buf, n, MPI_INT, partner, TAG_DATA, MPI_COMM_WORLD, &status);
    /* ----------------------------------------------------------------------- */

    /* Verificación: lo recibido debe ser el patrón de la pareja. */
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
