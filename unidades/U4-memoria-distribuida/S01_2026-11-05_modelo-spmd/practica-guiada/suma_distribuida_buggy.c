/*
 * suma_distribuida_buggy.c — Variante QUE FALLA de la suma distribuida.
 *
 * El error: reparte n / p elementos a cada rango y olvida el residuo n % p.
 * Cuando n no es múltiplo de p, los últimos n % p elementos no los suma nadie.
 * Síntoma esperado: con n = 10 y -np 4 la suma sale incorrecta (faltan los
 * índices 8 y 9); con -np 5 o -np 1 sale correcta. "Salió bien una vez" no es
 * evidencia de que el programa esté bien.
 *
 * Uso:  mpirun -np P ./suma_distribuida_buggy [n]
 */
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>

static double element(long long i)
{
    return (double)((i * 7919LL + 13LL) % 1000LL) / 10.0;
}

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    long long n = (argc > 1) ? atoll(argv[1]) : 10;
    if (n <= 0) {
        if (rank == 0) fprintf(stderr, "Uso: %s [n > 0]\n", argv[0]);
        MPI_Finalize();
        return 1;
    }

    /* BUG: bloque de tamaño fijo n / size; el residuo n % size se pierde. */
    long long chunk = n / size;
    long long start = (long long)rank * chunk;
    long long end = start + chunk;

    double local_sum = 0.0;
    for (long long i = start; i < end; i++)
        local_sum += element(i);
    printf("[rango %d] indices %lld..%lld (%lld elementos), suma parcial = %.3f\n",
           rank, start, end - 1, end - start, local_sum);

    double total = local_sum;
    if (rank != 0) {
        MPI_Send(&local_sum, 1, MPI_DOUBLE, 0, 0, MPI_COMM_WORLD);
    } else {
        for (int src = 1; src < size; src++) {
            double partial;
            MPI_Recv(&partial, 1, MPI_DOUBLE, src, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            total += partial;
        }
        printf("suma total = %.3f (n = %lld, p = %d, elementos sumados = %lld)\n",
               total, n, size, chunk * size);
    }

    MPI_Finalize();
    return 0;
}
