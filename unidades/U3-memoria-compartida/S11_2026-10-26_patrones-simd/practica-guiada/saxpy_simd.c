/* saxpy_simd.c — Mide y = a*x + y con y sin `#pragma omp simd`, compilado a -O2.
 *
 * Uso: ./saxpy_simd [elementos_por_repeticion]
 *
 * Para cada tamaño n de la lista se llama al núcleo `reps` veces, de modo que cada repetición
 * procese el mismo número total de elementos (por defecto 2^25 ≈ 33.5 M). Así los tiempos de
 * tamaños distintos son comparables. Protocolo del curso: 1 calentamiento, 5 repeticiones, mediana.
 *
 * Las tres versiones del ciclo están en vec_kernels.c (compílalo con `make report` para ver qué
 * vectorizó el compilador y qué no).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <omp.h>
#include "vec_kernels.h"

#define N_SIZES 4
#define REPS 5

typedef void (*saxpy_fn)(float, const float *, float *, long);

static int cmp_double(const void *p, const void *q)
{
    double a = *(const double *)p, b = *(const double *)q;
    return (a > b) - (a < b);
}

/* Cronometra `calls` llamadas consecutivas al núcleo; regresa la mediana de REPS repeticiones. */
static double time_kernel(saxpy_fn fn, float a, const float *x, float *y, long n, long calls,
                          double *t_min, double *t_max)
{
    double t[REPS];
    fn(a, x, y, n);                                   /* calentamiento (no se cuenta) */
    for (int r = 0; r < REPS; r++) {
        double t0 = omp_get_wtime();
        for (long c = 0; c < calls; c++)
            fn(a, x, y, n);
        t[r] = omp_get_wtime() - t0;
    }
    qsort(t, REPS, sizeof t[0], cmp_double);
    *t_min = t[0];
    *t_max = t[REPS - 1];
    return t[REPS / 2];
}

int main(int argc, char **argv)
{
    long work = (argc > 1) ? atol(argv[1]) : (1L << 25);   /* elementos procesados por repetición */
    const long sizes[N_SIZES] = { 1L << 12, 1L << 16, 1L << 20, 1L << 24 };
    const char *where[N_SIZES] = { "L1", "L2", "L2/L3", "RAM" };
    const float a = 1.0009765625f;   /* 1 + 2^-10: evita que y crezca demasiado rápido */
    int max_bad = 0;

    printf("saxpy: y = a*x + y, float, -O2, un solo hilo; %ld elementos por repeticion, "
           "%d repeticiones, mediana\n", work, REPS);
    printf("%10s %8s %6s | %9s %9s %9s | %7s %7s | %6s\n",
           "n", "KB/arr", "nivel", "plain_s", "restr_s", "simd_s", "S_restr", "S_simd", "GB/s");

    for (int s = 0; s < N_SIZES; s++) {
        long n = sizes[s];
        long calls = work / n;
        if (calls < 1) calls = 1;

        float *x = malloc((size_t)n * sizeof *x);
        float *y0 = malloc((size_t)n * sizeof *y0);
        float *y1 = malloc((size_t)n * sizeof *y1);
        float *y2 = malloc((size_t)n * sizeof *y2);
        if (!x || !y0 || !y1 || !y2) { fprintf(stderr, "sin memoria\n"); return 1; }
        for (long i = 0; i < n; i++) {
            x[i] = (float)(i % 1000) * 0.001f;
            y0[i] = y1[i] = y2[i] = 1.0f;
        }

        double mn, mx;
        double t_plain = time_kernel(saxpy_plain, a, x, y0, n, calls, &mn, &mx);
        double t_restr = time_kernel(saxpy_restrict, a, x, y1, n, calls, &mn, &mx);
        double t_simd = time_kernel(saxpy_simd, a, x, y2, n, calls, &mn, &mx);

        /* Verificación: las tres versiones hacen la misma aritmética en el mismo orden. */
        float max_diff = 0.0f;
        for (long i = 0; i < n; i++) {
            float d1 = fabsf(y1[i] - y0[i]), d2 = fabsf(y2[i] - y0[i]);
            if (d1 > max_diff) max_diff = d1;
            if (d2 > max_diff) max_diff = d2;
        }
        if (max_diff > 1e-5f * fabsf(y0[0])) max_bad = 1;

        /* Bytes movidos por repetición: lee x, lee y, escribe y = 12 bytes por elemento. */
        double gbs = 12.0 * (double)n * (double)calls / t_simd / 1e9;
        printf("%10ld %8ld %6s | %9.4f %9.4f %9.4f | %7.2f %7.2f | %6.1f   max|dif|=%.1e\n",
               n, n * (long)sizeof(float) / 1024, where[s], t_plain, t_restr, t_simd,
               t_plain / t_restr, t_plain / t_simd, gbs, (double)max_diff);
        free(x); free(y0); free(y1); free(y2);
    }
    printf("S_restr = t_plain/t_restr; S_simd = t_plain/t_simd (>1: mas rapido). GB/s de la version simd.\n");
    printf(max_bad ? "CHECK FAIL\n" : "CHECK OK\n");
    return max_bad;
}
