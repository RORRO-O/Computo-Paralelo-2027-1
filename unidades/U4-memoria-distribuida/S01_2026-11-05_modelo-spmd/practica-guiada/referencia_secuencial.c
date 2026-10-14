/*
 * referencia_secuencial.c — Versión secuencial de referencia (sin MPI).
 *
 * Calcula suma, promedio y máximo de los mismos elementos element(i) que usan
 * los programas distribuidos. Contra ESTA versión se comparan las pruebas y se
 * calcula el speedup (T(1) es el mejor programa secuencial, no el MPI con -np 1).
 * El cronómetro cubre solo la suma; el máximo se calcula aparte, sin medir.
 *
 * Compilar:  gcc -std=c11 -O2 -Wall -Wextra -o referencia_secuencial referencia_secuencial.c
 * Uso:       ./referencia_secuencial [n]
 */
#define _POSIX_C_SOURCE 199309L /* clock_gettime con -std=c11 */
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

static double element(long long i)
{
    return (double)((i * 7919LL + 13LL) % 1000LL) / 10.0;
}

static double wall_seconds(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}

int main(int argc, char **argv)
{
    long long n = (argc > 1) ? atoll(argv[1]) : 10;
    if (n <= 0) {
        fprintf(stderr, "Uso: %s [n > 0]\n", argv[0]);
        return 1;
    }

    /* Región cronometrada: SOLO la suma, que es lo que paraleliza suma_distribuida.
     * Así T(1) es el mejor programa secuencial de la suma, sin trabajo extra. */
    double t_start = wall_seconds();
    double sum = 0.0;
    for (long long i = 0; i < n; i++)
        sum += element(i);
    double t_end = wall_seconds();

    /* Máximo fuera del cronómetro: sirve de referencia para la fase Crear. */
    double max = element(0);
    for (long long i = 1; i < n; i++) {
        double x = element(i);
        if (x > max) max = x;
    }

    printf("n = %lld\n", n);
    printf("suma = %.3f\n", sum);
    printf("promedio = %.3f\n", sum / (double)n);
    printf("maximo = %.3f\n", max);
    printf("tiempo = %.6f s (solo la suma)\n", t_end - t_start);
    return 0;
}
