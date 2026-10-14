/* scan_buggy.c — VERSIÓN INCORRECTA A PROPÓSITO: suma de prefijos con `parallel for` directo.
 *
 * Uso: ./scan_buggy [n] [hilos]
 *
 * El ciclo y[i] = y[i-1] + x[i] tiene una dependencia acarreada por el ciclo: la iteración i lee
 * lo que escribió la iteración i-1. Repartir las iteraciones entre hilos rompe esa cadena: cada
 * hilo arranca su bloque leyendo un y[i-1] que otro hilo todavía no escribió (o escribió a medias).
 * Es una condición de carrera (data race): a veces el resultado "casi" coincide, nunca es confiable.
 *
 * Compila con ThreadSanitizer para verlo: `make tsan` (gcc -fsanitize=thread -g -O1 ...).
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include <omp.h>

static uint64_t rng_state = 0x9E3779B97F4A7C15ULL;
static double next_uniform(void)
{
    rng_state ^= rng_state >> 12;
    rng_state ^= rng_state << 25;
    rng_state ^= rng_state >> 27;
    uint64_t z = rng_state * 0x2545F4914F6CDD1DULL;
    return (double)(z >> 11) * (1.0 / 9007199254740992.0);
}

int main(int argc, char **argv)
{
    long n = (argc > 1) ? atol(argv[1]) : 1000000L;
    int n_threads = (argc > 2) ? atoi(argv[2]) : omp_get_max_threads();
    if (n < 2 || n_threads < 1) { fprintf(stderr, "argumentos invalidos\n"); return 2; }
    omp_set_num_threads(n_threads);

    double *x = malloc((size_t)n * sizeof *x);
    double *y_seq = malloc((size_t)n * sizeof *y_seq);
    double *y_bad = malloc((size_t)n * sizeof *y_bad);
    if (!x || !y_seq || !y_bad) { fprintf(stderr, "sin memoria\n"); return 1; }
    for (long i = 0; i < n; i++) x[i] = next_uniform();

    y_seq[0] = x[0];
    for (long i = 1; i < n; i++) y_seq[i] = y_seq[i - 1] + x[i];

    y_bad[0] = x[0];
    /* INCORRECTO: la iteración i depende de la i-1; `parallel for` las ejecuta en hilos distintos. */
    #pragma omp parallel for
    for (long i = 1; i < n; i++)
        y_bad[i] = y_bad[i - 1] + x[i];

    double max_abs_diff = 0.0;
    for (long i = 0; i < n; i++) {
        double d = fabs(y_bad[i] - y_seq[i]);
        if (d > max_abs_diff) max_abs_diff = d;
    }
    printf("scan_buggy: n=%ld hilos=%d\n", n, n_threads);
    printf("  y_seq[n-1]=%.6f   y_bad[n-1]=%.6f   max|dif|=%.3e\n", y_seq[n - 1], y_bad[n - 1], max_abs_diff);
    printf("  (con 1 hilo coincide; con 2 o mas hilos el resultado es incorrecto y cambia entre corridas)\n");

    free(x); free(y_seq); free(y_bad);
    return 0;
}
