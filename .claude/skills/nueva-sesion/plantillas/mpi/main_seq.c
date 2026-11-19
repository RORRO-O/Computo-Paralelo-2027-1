/* main_seq.c — Referencia secuencial de la práctica guiada (C, sin MPI). PUNTO DE PARTIDA de /nueva-sesion.
 * Sustituye calcular() por el problema de la sesión; main_mpi.c debe dar el mismo resultado con tolerancia.
 *
 * Problema de relleno: pi por la regla del punto medio sobre 4/(1+x^2) con n rectángulos.
 *
 * Uso:    ./programa_seq [n]        (n por defecto: 20000000)
 * Salida: n=<valor>  resultado=<valor>  tiempo_s=<segundos>   (una clave por línea)
 * Código de salida: 0; 2 si n no es un entero positivo.
 */
#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define DEFAULT_N 20000000L

static double wall_time(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + 1e-9 * (double)ts.tv_nsec;
}

static double calcular(long n)
{
    const double h = 1.0 / (double)n;
    double sum = 0.0;
    for (long i = 0; i < n; i++) {
        double x = ((double)i + 0.5) * h;
        sum += 4.0 / (1.0 + x * x);
    }
    return sum * h;
}

int main(int argc, char **argv)
{
    long n = DEFAULT_N;
    if (argc > 1) {
        char *end = NULL;
        errno = 0;
        n = strtol(argv[argc - 1], &end, 10);
        if (errno != 0 || end == argv[argc - 1] || *end != '\0' || n <= 0) {
            fprintf(stderr, "uso: %s [n]   (n entero positivo)\n", argv[0]);
            return 2;
        }
    }
    double t0 = wall_time();
    double result = calcular(n);
    double elapsed = wall_time() - t0;

    printf("n=%ld\n", n);
    printf("resultado=%.12f\n", result);
    printf("tiempo_s=%.6f\n", elapsed);
    return 0;
}
