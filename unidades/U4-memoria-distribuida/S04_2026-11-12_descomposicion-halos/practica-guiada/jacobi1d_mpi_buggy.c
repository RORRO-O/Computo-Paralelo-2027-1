/*
 * jacobi1d_mpi_buggy.c — Jacobi 1D en MPI con un ERROR A PROPÓSITO (fase PREDECIR de la práctica).
 *
 * Es jacobi1d_mpi.c reducido (solo MPI_Sendrecv, sin traza) con UNA diferencia: se omitió el
 * intercambio que llena el HALO IZQUIERDO. El programa compila, corre, no imprime ningún
 * error y termina reportando "convergio=1"... con un resultado incorrecto.
 *
 * Lección: en MPI, un halo que no se actualiza no produce una falla visible. El proceso usa
 * un valor viejo (aquí, el 0 inicial) como si fuera su vecino. Solo la comparación contra la
 * versión secuencial lo revela. Con p = 1 el error es invisible: no hay halos que intercambiar.
 *
 * Uso: mpirun -np P ./jacobi1d_mpi_buggy [n] [tol] [max_iter] [--print]
 */
#include <math.h>
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define T_LEFT  100.0
#define T_RIGHT   0.0
#define TAG_TO_RIGHT 10
#define TAG_TO_LEFT  20

static void block_partition(int n, int p, int rank, int *local_n, int *offset) {
    int base = n / p, rem = n % p;
    *local_n = base + (rank < rem ? 1 : 0);
    *offset  = rank * base + (rank < rem ? rank : rem);
}

/* AQUÍ ESTÁ EL ERROR: falta el Paso 1 (mi última celda hacia la derecha; recibir en u[0]).
 * Compara con exchange_halos_sendrecv de jacobi1d_mpi.c. */
static void exchange_halos_buggy(double *u, int local_n, int left, int right) {
    /* Paso 1 omitido: u[0] nunca se actualiza en los rangos 1..p-1. */

    /* Paso 2: mi primera celda viaja a la izquierda; recibo del vecino derecho en mi halo derecho. */
    MPI_Sendrecv(&u[1],           1, MPI_DOUBLE, left,  TAG_TO_LEFT,
                 &u[local_n + 1], 1, MPI_DOUBLE, right, TAG_TO_LEFT,
                 MPI_COMM_WORLD, MPI_STATUS_IGNORE);
}

int main(int argc, char **argv) {
    MPI_Init(&argc, &argv);
    int rank, p;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &p);

    int    n = 1000000, max_iter = 1000, print = 0, pos = 0;
    double tol = 1e-6;
    for (int a = 1; a < argc; a++) {
        if (strcmp(argv[a], "--print") == 0) { print = 1; continue; }
        if (pos == 0)      n        = (int)strtol(argv[a], NULL, 10);
        else if (pos == 1) tol      = strtod(argv[a], NULL);
        else if (pos == 2) max_iter = (int)strtol(argv[a], NULL, 10);
        pos++;
    }
    if (n < p || tol <= 0.0 || max_iter < 1) {
        if (rank == 0) fprintf(stderr, "uso: mpirun -np P %s [n>=P] [tol>0] [max_iter>=1] [--print]\n", argv[0]);
        MPI_Finalize();
        return 1;
    }

    int local_n, offset;
    block_partition(n, p, rank, &local_n, &offset);
    int left  = (rank > 0)     ? rank - 1 : MPI_PROC_NULL;
    int right = (rank < p - 1) ? rank + 1 : MPI_PROC_NULL;

    double *u     = calloc((size_t)local_n + 2, sizeof *u);
    double *u_new = calloc((size_t)local_n + 2, sizeof *u_new);
    if (!u || !u_new) { fprintf(stderr, "rango %d: sin memoria\n", rank); MPI_Abort(MPI_COMM_WORLD, 1); }
    if (left  == MPI_PROC_NULL) u[0] = u_new[0] = T_LEFT;
    if (right == MPI_PROC_NULL) u[local_n + 1] = u_new[local_n + 1] = T_RIGHT;

    MPI_Barrier(MPI_COMM_WORLD);
    double t0 = MPI_Wtime();
    int    iter = 0, converged = 0;
    double global_diff = 0.0;
    for (iter = 1; iter <= max_iter; iter++) {
        exchange_halos_buggy(u, local_n, left, right);
        double local_diff = 0.0;
        for (int i = 1; i <= local_n; i++) {
            u_new[i] = 0.5 * (u[i - 1] + u[i + 1]);
            double d = fabs(u_new[i] - u[i]);
            if (d > local_diff) local_diff = d;
        }
        double *tmp = u; u = u_new; u_new = tmp;
        MPI_Allreduce(&local_diff, &global_diff, 1, MPI_DOUBLE, MPI_MAX, MPI_COMM_WORLD);
        if (global_diff < tol) { converged = 1; break; }
    }
    if (!converged) iter = max_iter;
    double elapsed = MPI_Wtime() - t0;

    int    *counts = NULL, *displs = NULL;
    double *u_all  = NULL;
    if (rank == 0) {
        counts = malloc((size_t)p * sizeof *counts);
        displs = malloc((size_t)p * sizeof *displs);
        u_all  = malloc((size_t)n * sizeof *u_all);
        if (!counts || !displs || !u_all) { fprintf(stderr, "rango 0: sin memoria\n"); MPI_Abort(MPI_COMM_WORLD, 1); }
        for (int r = 0; r < p; r++) block_partition(n, p, r, &counts[r], &displs[r]);
    }
    MPI_Gatherv(&u[1], local_n, MPI_DOUBLE, u_all, counts, displs, MPI_DOUBLE, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        double checksum = 0.0;
        for (int i = 0; i < n; i++) checksum += u_all[i];
        printf("n=%d tol=%.3e max_iter=%d p=%d\n", n, tol, max_iter, p);
        printf("iteraciones=%d convergio=%d\n", iter, converged);
        printf("diff_final=%.6e\n", global_diff);
        printf("checksum=%.12e\n", checksum);
        printf("tiempo_s=%.6f\n", elapsed);
        if (print)
            for (int i = 0; i < n; i++) printf("%d %.15e\n", i + 1, u_all[i]);
        free(counts); free(displs); free(u_all);
    }
    free(u);
    free(u_new);
    MPI_Finalize();
    return 0;
}
