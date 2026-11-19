/* main_mpi.c — Programa base de la práctica guiada (C + MPI). PUNTO DE PARTIDA: lo generó /nueva-sesion.
 * Sustituye el cálculo local por el problema de la sesión y conserva el contrato de salida.
 *
 * Problema de relleno: pi por la regla del punto medio. Cada proceso suma su bloque contiguo de índices
 * (el reparto cubre el caso n % size != 0) y MPI_Reduce junta las sumas en el rango 0.
 *
 * Uso:    mpirun $MPIRUN_FLAGS -np P ./programa_mpi [n]     (n por defecto: 20000000)
 * Salida (solo el rango 0): n=<valor>  procesos=<valor>  resultado=<valor>  tiempo_s=<segundos>
 * tiempo_s es el máximo entre rangos, medido después de MPI_Barrier.
 * Código de salida: 0; 2 si n no es un entero positivo.
 */
#include <errno.h>
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>

#define DEFAULT_N 20000000L

int main(int argc, char **argv)
{
    int rank, size;
    long n = DEFAULT_N;
    int bad_args = 0;

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    /* Todos los procesos reciben argv; cada uno valida igual y todos salen juntos si no sirve. */
    if (argc > 1) {
        char *end = NULL;
        errno = 0;
        n = strtol(argv[argc - 1], &end, 10);
        if (errno != 0 || end == argv[argc - 1] || *end != '\0' || n <= 0) {
            bad_args = 1;
        }
    }
    if (bad_args) {
        if (rank == 0) {
            fprintf(stderr, "uso: mpirun -np P %s [n]   (n entero positivo)\n", argv[0]);
        }
        MPI_Finalize();
        return 2;
    }

    MPI_Barrier(MPI_COMM_WORLD);
    double t0 = MPI_Wtime();

    /* Bloque [first, last) de este rango: los primeros n % size rangos llevan un índice más. */
    long base = n / size, extra = n % size;
    long first = rank * base + (rank < extra ? rank : extra);
    long last = first + base + (rank < extra ? 1 : 0);

    const double h = 1.0 / (double)n;
    double local_sum = 0.0, global_sum = 0.0;
    for (long i = first; i < last; i++) {
        double x = ((double)i + 0.5) * h;
        local_sum += 4.0 / (1.0 + x * x);
    }
    MPI_Reduce(&local_sum, &global_sum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

    double local_elapsed = MPI_Wtime() - t0, elapsed = 0.0;
    MPI_Reduce(&local_elapsed, &elapsed, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        printf("n=%ld\n", n);
        printf("procesos=%d\n", size);
        printf("resultado=%.12f\n", global_sum * h);
        printf("tiempo_s=%.6f\n", elapsed);
    }
    MPI_Finalize();
    return 0;
}
