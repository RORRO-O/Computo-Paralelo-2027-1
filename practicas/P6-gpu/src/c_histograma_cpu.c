/*
 * c_histograma_cpu.c — Referencia secuencial de la Parte C, opción 1: histograma de 256 clases y
 * reducción (suma) sobre n bytes pseudoaleatorios.
 *
 * Uso:      ./c_histograma_cpu [n=16777216] [--volcar hist.txt]
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra c_histograma_cpu.c -o c_histograma_cpu
 *
 * ENTRADA (la misma que debe usar tu kernel; el generador está también en common.cuh):
 *   data[i] = ((i * 2654435761) mod 2^32) >> 24          (byte en 0..255, hash multiplicativo de Knuth)
 * SALIDA que tu programa de GPU debe reproducir EXACTAMENTE (son enteros: aquí no hay tolerancia):
 *   suma            = Σ data[i]                            (la reducción)
 *   hist_checksum   = Σ_b (b + 1) · hist[b]                 (resume las 256 cuentas en un número)
 *   bin_max, cuenta_max                                     (clase más poblada y su cuenta)
 *   con --volcar se escriben las 256 cuentas (una por línea: "b,cuenta") para comparar completo.
 * T(1): 1 calentamiento + 5 repeticiones de (histograma + suma), mediana.
 */
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define REPS 5
#define BINS 256

static double now_s(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}

/* Idéntico a init_histogram_data() de common.cuh. */
static void init_data(unsigned char *data, long n)
{
    for (long i = 0; i < n; ++i) {
        unsigned int x = (unsigned int)i * 2654435761u; /* desborda a propósito (mod 2^32) */
        data[i] = (unsigned char)((x >> 24) & 0xFFu);
    }
}

static void histogram_cpu(const unsigned char *data, long n, unsigned int *hist)
{
    memset(hist, 0, BINS * sizeof(unsigned int));
    for (long i = 0; i < n; ++i)
        hist[data[i]]++;
}

static unsigned long long sum_cpu(const unsigned char *data, long n)
{
    unsigned long long s = 0;
    for (long i = 0; i < n; ++i)
        s += data[i];
    return s;
}

static int cmp_double(const void *x, const void *y)
{
    double dx = *(const double *)x, dy = *(const double *)y;
    return (dx > dy) - (dx < dy);
}

int main(int argc, char **argv)
{
    long n = (argc > 1 && argv[1][0] != '-') ? atol(argv[1]) : (1L << 24);
    const char *dump = NULL;
    for (int i = 1; i < argc - 1; ++i)
        if (strcmp(argv[i], "--volcar") == 0)
            dump = argv[i + 1];
    if (n <= 0) {
        fprintf(stderr, "uso: %s [n>0] [--volcar hist.txt]\n", argv[0]);
        return 1;
    }
    unsigned char *data = malloc((size_t)n);
    if (!data) {
        fprintf(stderr, "Sin memoria para n=%ld\n", n);
        return 1;
    }
    init_data(data, n);

    unsigned int hist[BINS];
    unsigned long long sum = 0;
    double t[REPS];
    for (int r = -1; r < REPS; ++r) {
        double t0 = now_s();
        histogram_cpu(data, n, hist);
        sum = sum_cpu(data, n);
        double dt = now_s() - t0;
        if (r >= 0)
            t[r] = dt;
    }
    qsort(t, REPS, sizeof(double), cmp_double);

    unsigned long long checksum = 0, total = 0;
    int bin_max = 0;
    for (int b = 0; b < BINS; ++b) {
        checksum += (unsigned long long)(b + 1) * hist[b];
        total += hist[b];
        if (hist[b] > hist[bin_max])
            bin_max = b;
    }
    printf("c_histograma_cpu: n=%ld bins=%d t_cpu_ms=%.3f (mediana de %d; min %.3f, max %.3f)\n",
           n, BINS, t[REPS / 2] * 1e3, REPS, t[0] * 1e3, t[REPS - 1] * 1e3);
    printf("  suma=%llu hist_checksum=%llu bin_max=%d cuenta_max=%u total_cuentas=%llu (%s n)\n",
           sum, checksum, bin_max, hist[bin_max], total, total == (unsigned long long)n ? "==" : "!=");
    printf("  hist[0..7]=%u %u %u %u %u %u %u %u\n", hist[0], hist[1], hist[2], hist[3], hist[4], hist[5],
           hist[6], hist[7]);
    if (dump) {
        FILE *f = fopen(dump, "w");
        if (!f) {
            fprintf(stderr, "No se pudo escribir %s\n", dump);
            return 1;
        }
        for (int b = 0; b < BINS; ++b)
            fprintf(f, "%d,%u\n", b, hist[b]);
        fclose(f);
        printf("  256 cuentas escritas en %s\n", dump);
    }
    free(data);
    return total == (unsigned long long)n ? 0 : 2;
}
