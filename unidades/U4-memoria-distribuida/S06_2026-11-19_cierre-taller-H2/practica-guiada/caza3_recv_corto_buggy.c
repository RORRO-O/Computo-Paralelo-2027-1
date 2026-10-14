/* caza3_recv_corto_buggy.c — Cazador de errores 3 · reunir bloques en el rango 0
 *
 * Qué debería hacer: el arreglo a[i] = i + 1 (i = 0..n-1) está repartido por bloques contiguos
 * balanceados: los primeros n % p procesos tienen un elemento más que los demás (como en S01).
 * Cada proceso genera su bloque y se lo manda al rango 0, que los junta en orden en un arreglo
 * completo y verifica que la suma sea n(n+1)/2.
 *
 * Este archivo contiene UN error a propósito y no está marcado. Predice el síntoma antes de
 * correrlo (README, fase Predecir). Corrígelo en una copia llamada caza3_recv_corto.c;
 * `make listo` la prueba con 4 procesos y n = 10, n = 7 y n = 8.
 *
 * Uso: mpirun -np 4 ./caza3_recv_corto_buggy [n]     (n por defecto 10)
 */
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>

/* Tamaño del bloque del proceso r cuando n elementos se reparten entre p procesos. */
static int block_size(long n, int p, int r) {
    return (int)(n / p) + (r < n % p ? 1 : 0);
}

/* Primer índice global del bloque del proceso r. */
static long block_start(long n, int p, int r) {
    long start = 0;
    for (int q = 0; q < r; q++) start += block_size(n, p, q);
    return start;
}

int main(int argc, char **argv) {
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    long n = (argc > 1) ? atol(argv[1]) : 10L;
    if (n <= 0 || n > 100000000L) {
        if (rank == 0) fprintf(stderr, "Uso: mpirun -np p %s [1 <= n <= 1e8]\n", argv[0]);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    /* Cada proceso genera su bloque: a[i] = i + 1 para los i que le tocan. */
    int  local_n = block_size(n, size, rank);
    long start   = block_start(n, size, rank);
    int *block   = malloc((size_t)(local_n > 0 ? local_n : 1) * sizeof(int));
    for (int i = 0; i < local_n; i++) block[i] = (int)(start + i) + 1;

    if (rank != 0) {
        MPI_Send(block, local_n, MPI_INT, 0, 0, MPI_COMM_WORLD);
    } else {
        int *a = malloc((size_t)n * sizeof(int));
        for (int i = 0; i < local_n; i++) a[i] = block[i];          /* mi propio bloque */

        /* Recibir el bloque de cada proceso y colocarlo en su lugar. */
        long offset = local_n;
        for (int r = 1; r < size; r++) {
            int count = (int)(n / size);                             /* la parte de n de cada proceso */
            MPI_Recv(a + offset, count, MPI_INT, r, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            offset += count;
        }

        long total = 0;
        for (long i = 0; i < offset; i++) total += a[i];
        long expected = n * (n + 1) / 2;
        printf("caza3: n=%ld, %d procesos, elementos reunidos=%ld, suma=%ld, esperada=%ld\nVERIFICACION %s\n",
               n, size, offset, total, expected, (offset == n && total == expected) ? "OK" : "FAIL");
        free(a);
    }

    free(block);
    MPI_Finalize();
    return 0;
}
