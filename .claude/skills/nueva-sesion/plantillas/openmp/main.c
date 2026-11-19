/* main.c — Programa base de la práctica guiada (C + OpenMP). PUNTO DE PARTIDA: lo generó /nueva-sesion.
 * Sustituye calcular() por el problema de la sesión y conserva el contrato de salida.
 *
 * Problema de relleno: pi por la regla del punto medio sobre 4/(1+x^2) con n rectángulos.
 * El mismo archivo compilado sin -fopenmp es la referencia secuencial (programa_seq).
 *
 * Uso:    ./programa [n]            (n por defecto: 20000000; corre en menos de 1 s en 4 núcleos)
 * Salida: n=<valor>  hilos=<valor>  resultado=<valor>  tiempo_s=<segundos>   (una clave por línea)
 * Código de salida: 0; 2 si n no es un entero positivo.
 */
#define _POSIX_C_SOURCE 200809L /* clock_gettime cuando se compila sin -fopenmp */

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#ifdef _OPENMP
#include <omp.h>
#endif

#define DEFAULT_N 20000000L

/* Reloj de pared: omp_get_wtime() con OpenMP, clock_gettime(CLOCK_MONOTONIC) sin él. Nunca clock(). */
static double wall_time(void)
{
#ifdef _OPENMP
    return omp_get_wtime();
#else
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + 1e-9 * (double)ts.tv_nsec;
#endif
}

/* Región de interés: es lo único que se cronometra. */
static double calcular(long n)
{
    const double h = 1.0 / (double)n;
    double sum = 0.0;
    long i;
#ifdef _OPENMP
#pragma omp parallel for default(none) shared(n, h) reduction(+ : sum) schedule(static)
#endif
    for (i = 0; i < n; i++) {
        double x = ((double)i + 0.5) * h;
        sum += 4.0 / (1.0 + x * x);
    }
    return sum * h;
}

int main(int argc, char **argv)
{
    long n = DEFAULT_N;
    int n_threads = 1;
    if (argc > 1) {
        char *end = NULL;
        errno = 0;
        n = strtol(argv[argc - 1], &end, 10);
        if (errno != 0 || end == argv[argc - 1] || *end != '\0' || n <= 0) {
            fprintf(stderr, "uso: %s [n]   (n entero positivo)\n", argv[0]);
            return 2;
        }
    }
#ifdef _OPENMP
    n_threads = omp_get_max_threads();
#endif
    double t0 = wall_time();
    double result = calcular(n);
    double elapsed = wall_time() - t0;

    printf("n=%ld\n", n);
    printf("hilos=%d\n", n_threads);
    printf("resultado=%.12f\n", result);
    printf("tiempo_s=%.6f\n", elapsed);
    return 0;
}
