/*
 * histogram_cpu.c — Referencia secuencial de histogram.cu (Unidad V, S03).
 *
 * Imprime el histograma exacto (enteros: debe coincidir bit a bit con la GPU), el sesgo de los
 * datos (fracción del bin más poblado: es la contención que sufre la versión con atómicas globales)
 * y cuántas atómicas globales haría cada versión de GPU con ese n y ese block (fase Predecir).
 *
 * Uso:   ./histogram_cpu [n] [block]        (por defecto 1048576 256)
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra histogram_cpu.c -o histogram_cpu
 * Otro número de bins: gcc ... -DBINS=256 histogram_cpu.c -o histogram_cpu256
 */
#define _POSIX_C_SOURCE 199309L   /* clock_gettime con -std=c11 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <time.h>

#ifndef BINS
#define BINS 16
#endif
#define REPS 5

/* Misma fórmula que histogram.cu y histogram_numba.py */
static void init_data(unsigned char *v, int n)
{
    for (int i = 0; i < n; i++) {
        uint32_t h = ((uint32_t)i * 2654435761u) >> 24;
        v[i] = (i % 4 == 0) ? 0 : (unsigned char)(h % BINS);
    }
}

static void histogram(const unsigned char *v, unsigned int *hist, int n)
{
    memset(hist, 0, BINS * sizeof(unsigned int));
    for (int i = 0; i < n; i++)
        hist[v[i]]++;
}

static double now_ms(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec * 1e3 + (double)ts.tv_nsec / 1e6;
}

static int cmp_double(const void *a, const void *b)
{
    double da = *(const double *)a, db = *(const double *)b;
    return (da > db) - (da < db);
}

int main(int argc, char **argv)
{
    int n = (argc > 1) ? atoi(argv[1]) : (1 << 20);
    int block = (argc > 2) ? atoi(argv[2]) : 256;
    if (n <= 0 || block <= 0) {
        fprintf(stderr, "uso: %s [n>0] [block>0]\n", argv[0]);
        return 1;
    }
    int grid = (n + block - 1) / block;

    unsigned char *v = (unsigned char *)malloc((size_t)n);
    if (!v) {
        fprintf(stderr, "Sin memoria para n=%d\n", n);
        return 1;
    }
    init_data(v, n);

    unsigned int hist[BINS];
    double t[REPS];
    histogram(v, hist, n);                      /* calentamiento */
    for (int r = 0; r < REPS; r++) {
        double t0 = now_ms();
        histogram(v, hist, n);
        t[r] = now_ms() - t0;
    }
    qsort(t, REPS, sizeof(double), cmp_double);

    unsigned long long total = 0;
    unsigned int max_count = 0;
    int max_bin = 0;
    for (int b = 0; b < BINS; b++) {
        total += hist[b];
        if (hist[b] > max_count) {
            max_count = hist[b];
            max_bin = b;
        }
    }

    printf("histogram_cpu: n=%d bins=%d block=%d grid=%d  mediana_ms=%.3f de %d (min %.3f, max %.3f)\n", n, BINS,
           block, grid, t[REPS / 2], REPS, t[0], t[REPS - 1]);
    printf("hist_cpu=[");
    for (int b = 0; b < BINS; b++)
        printf("%u%s", hist[b], (b + 1 < BINS) ? "," : "");
    printf("]\n");
    printf("total=%llu  bin_mas_poblado=%d (%.1f %% de los datos: esa es la contención de la versión global)\n",
           total, max_bin, 100.0 * (double)max_count / (double)n);
    printf("atomicas_globales: global=%d  shared=%d (= %d bins x %d bloques; además %d atómicas en compartida)\n", n,
           BINS * grid, BINS, grid, n);
    printf("verificacion=%s\n", (total == (unsigned long long)n) ? "OK" : "FALLA");

    free(v);
    return (total == (unsigned long long)n) ? 0 : 2;
}
