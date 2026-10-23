/* caza1_orden_send_buggy.c — Cazador de errores 1 · intercambio cruzado entre parejas
 *
 * Qué debería hacer: los procesos forman parejas (0<->1, 2<->3, ...). Cada uno llena un vector
 * de n doubles con su propio rango y lo intercambia con su pareja. Al final, el rango 0 imprime
 * VERIFICACION OK si todos recibieron el vector de su pareja.
 *
 * Este archivo contiene UN error a propósito y no está marcado. Antes de ejecutarlo, escribe
 * tu predicción del síntoma (README, fase Predecir). Corrígelo en una copia llamada
 * caza1_orden_send.c; `make listo` la prueba con n = 1 000 000.
 *
 * Uso: mpirun -np 4 ./caza1_orden_send_buggy [n]     (np par; n por defecto 1 000 000 = 8 MB)
 */
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    long n = (argc > 1) ? atol(argv[1]) : 1000000L;
    if (size % 2 != 0 || n <= 0 || n > 100000000L) {
        if (rank == 0) fprintf(stderr, "Uso: mpirun -np <par> %s [1 <= n <= 1e8]\n", argv[0]);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    int partner = rank ^ 1;                       /* 0<->1, 2<->3, 4<->5, ... */
    double *send_buf = malloc((size_t)n * sizeof(double));
    double *recv_buf = malloc((size_t)n * sizeof(double));
    for (long i = 0; i < n; i++) send_buf[i] = (double)rank;

    /* Intercambio con la pareja: le mando mi vector y recibo el suyo. */
    MPI_Send(send_buf, (int)n, MPI_DOUBLE, partner, 7, MPI_COMM_WORLD);
    MPI_Recv(recv_buf, (int)n, MPI_DOUBLE, partner, 7, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

    /* Verificación local: todo lo recibido debe valer el rango de la pareja. */
    int local_ok = 1;
    for (long i = 0; i < n; i++)
        if (recv_buf[i] != (double)partner) { local_ok = 0; break; }

    int all_ok = 0;
    MPI_Reduce(&local_ok, &all_ok, 1, MPI_INT, MPI_LAND, 0, MPI_COMM_WORLD);
    if (rank == 0)
        printf("caza1: n=%ld doubles (%.1f MB por mensaje), %d procesos\nVERIFICACION %s\n",
               n, n * sizeof(double) / 1e6, size, all_ok ? "OK" : "FAIL");

    free(send_buf);
    free(recv_buf);
    MPI_Finalize();
    return 0;
}
