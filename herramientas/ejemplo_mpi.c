/* ejemplo_mpi.c — "Hola MPI" medible: sirve para probar medir.sh --mpi y el Makefile.mpi.
 * Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · herramientas/
 *
 * Cada proceso saluda, calcula su parte de pi (regla del punto medio, mismo resultado que
 * ejemplo_cronometro.c) y el rango 0 reduce la suma. El tiempo reportado es el MÁXIMO entre procesos de la
 * región de interés (reparto + cómputo + reducción), medido con MPI_Wtime(): es el tiempo que percibe quien
 * espera el resultado.
 *
 * Uso:
 *   mpirun [--oversubscribe] -np P ./ejemplo_mpi.out [n]      (n por defecto 20000000)
 * Salida del rango 0 (clave=valor): procesos=, n=, resultado=, tiempo_s=. Los demás rangos solo saludan.
 * Código de salida 0; 2 si n no es un entero >= 1.
 *
 * Ejemplos ejecutables (desde herramientas/, después de `make`; resultados/ la borra `make clean`):
 *   mpirun --oversubscribe -np 4 ./ejemplo_mpi.out 50000000
 *   ./medir.sh -c secuencial -t 1 -n 100000000 -o resultados/mpi.csv -- ./ejemplo_cronometro_seq.out   # T(1)
 *   MPIRUN_FLAGS="--oversubscribe" ./medir.sh --mpi -c mpi -t "1 2 4" -n 100000000 -o resultados/mpi.csv -- ./ejemplo_mpi.out
 */
#include <errno.h>
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>

#define N_POR_DEFECTO 20000000L

int main(int argc, char **argv)
{
    int rank, size;
    long n = N_POR_DEFECTO;

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    if (argc > 1) {
        char *fin = NULL;
        errno = 0;
        long v = strtol(argv[1], &fin, 10);
        if (errno != 0 || fin == argv[1] || *fin != '\0' || v < 1) {
            if (rank == 0)
                fprintf(stderr, "n debe ser un entero >= 1 (recibí '%s')\n", argv[1]);
            MPI_Finalize();
            return 2;
        }
        n = v;
    }

    printf("hola desde el proceso %d de %d\n", rank, size);

    /* Región de interés: reparto por bloques contiguos + cómputo local + reducción. */
    MPI_Barrier(MPI_COMM_WORLD); /* para que todos arranquen el cronómetro casi a la vez */
    double t0 = MPI_Wtime();

    const double h = 1.0 / (double)n;
    long base = n / size, resto = n % size;
    long inicio = rank * base + (rank < resto ? rank : resto);
    long fin = inicio + base + (rank < resto ? 1 : 0);
    double parcial = 0.0;
    for (long i = inicio; i < fin; i++) {
        double x = ((double)i + 0.5) * h;
        parcial += 4.0 / (1.0 + x * x);
    }
    double suma = 0.0;
    MPI_Reduce(&parcial, &suma, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

    double local = MPI_Wtime() - t0, maximo = 0.0;
    MPI_Reduce(&local, &maximo, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        printf("procesos=%d\n", size);
        printf("n=%ld\n", n);
        printf("resultado=%.12f\n", suma * h);
        printf("tiempo_s=%.6f\n", maximo);
    }

    MPI_Finalize();
    return 0;
}
