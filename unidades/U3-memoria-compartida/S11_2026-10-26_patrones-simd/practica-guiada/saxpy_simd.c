/* saxpy_simd.c — Mide y = a*x + y con y sin `#pragma omp simd`, compilado a -O2.
 *
 * Uso: ./saxpy_simd [elementos_por_repeticion]
 *
 * Para cada tamaño n de la lista se llama al núcleo `calls` veces, de modo que cada repetición
 * procese el mismo número total de elementos (por defecto 2^25 ≈ 33.5 M). Así los tiempos de
 * tamaños distintos son comparables. Protocolo del curso: 1 calentamiento, 5 repeticiones, mediana.
 * Las tres versiones se miden INTERCALADAS (en cada repetición: plain, restrict, simd) para que los
 * cambios de velocidad de la máquina durante la medición afecten a las tres por igual.
 *
 * Las tres versiones del ciclo están en vec_kernels.c (compílalo con `make report` para ver qué
 * vectorizó el compilador y qué no). plain y restrict generan exactamente el mismo código a -O2
 * (compruébalo con objdump -d): si sus tiempos difieren es por la colocación del código y de los datos
 * en memoria, no por semántica. Por eso S_simd se calcula contra el MEJOR tiempo escalar de los dos.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <omp.h>
#include "vec_kernels.h"

#define N_SIZES 4
#define REPS 5
#define N_VERSIONS 3

typedef void (*saxpy_fn)(float, const float *, float *, long);

static int cmp_double(const void *p, const void *q)
{
    double a = *(const double *)p, b = *(const double *)q;
    return (a > b) - (a < b);
}

/* Tiempo de `calls` llamadas consecutivas al núcleo. */
static double time_calls(saxpy_fn fn, float a, const float *x, float *y, long n, long calls)
{
    double t0 = omp_get_wtime();
    for (long c = 0; c < calls; c++)
        fn(a, x, y, n);
    return omp_get_wtime() - t0;
}

int main(int argc, char **argv)
{
    long work = (argc > 1) ? atol(argv[1]) : (1L << 25);   /* elementos procesados por repetición */
    const long sizes[N_SIZES] = { 1L << 12, 1L << 16, 1L << 20, 1L << 24 };
    const char *where[N_SIZES] = { "L1", "L2", "L2/L3", "RAM" };
    const saxpy_fn fns[N_VERSIONS] = { saxpy_plain, saxpy_restrict, saxpy_simd };
    const float a = 1.0009765625f;   /* 1 + 2^-10: evita que y crezca demasiado rápido */
    int max_bad = 0;

    printf("saxpy: y = a*x + y, float, -O2, un solo hilo; %ld elementos por repeticion, "
           "%d repeticiones intercaladas, mediana\n", work, REPS);
    printf("%10s %8s %6s | %9s %9s %9s | %7s | %6s\n",
           "n", "KB/arr", "nivel", "plain_s", "restr_s", "simd_s", "S_simd", "GB/s");

    for (int s = 0; s < N_SIZES; s++) {
        long n = sizes[s];
        long calls = work / n;
        if (calls < 1) calls = 1;
        size_t bytes = (size_t)n * sizeof(float);

        /* x y las tres copias de y en un solo bloque, separadas por una distancia que no es múltiplo
         * de 4 KB (si lo fuera, cargas y almacenamientos se estorbarían por "4K aliasing"). */
        size_t stride = bytes + 1536;
        char *buf = malloc((N_VERSIONS + 1) * stride);
        if (!buf) { fprintf(stderr, "sin memoria\n"); return 1; }
        float *x = (float *)buf;
        float *y[N_VERSIONS];
        for (int v = 0; v < N_VERSIONS; v++) y[v] = (float *)(buf + (size_t)(v + 1) * stride);
        for (long i = 0; i < n; i++) {
            x[i] = (float)(i % 1000) * 0.001f;
            for (int v = 0; v < N_VERSIONS; v++) y[v][i] = 1.0f;
        }

        double t[N_VERSIONS][REPS], med[N_VERSIONS];
        for (int v = 0; v < N_VERSIONS; v++)                 /* calentamiento (no se cuenta) */
            time_calls(fns[v], a, x, y[v], n, calls);
        for (int r = 0; r < REPS; r++)                       /* repeticiones intercaladas */
            for (int v = 0; v < N_VERSIONS; v++)
                t[v][r] = time_calls(fns[v], a, x, y[v], n, calls);
        for (int v = 0; v < N_VERSIONS; v++) {
            qsort(t[v], REPS, sizeof t[v][0], cmp_double);
            med[v] = t[v][REPS / 2];
        }

        /* Verificación: las tres versiones hicieron la misma aritmética, en el mismo orden,
         * el mismo número de veces. */
        float max_diff = 0.0f;
        for (long i = 0; i < n; i++)
            for (int v = 1; v < N_VERSIONS; v++) {
                float d = fabsf(y[v][i] - y[0][i]);
                if (d > max_diff) max_diff = d;
            }
        if (max_diff > 1e-5f * fabsf(y[0][0])) max_bad = 1;

        /* Bytes movidos por repetición: lee x, lee y, escribe y = 12 bytes por elemento. */
        double gbs = 12.0 * (double)n * (double)calls / med[2] / 1e9;
        double best_scalar = med[0] < med[1] ? med[0] : med[1];
        printf("%10ld %8ld %6s | %9.4f %9.4f %9.4f | %7.2f | %6.1f   max|dif|=%.1e\n",
               n, (long)(bytes / 1024), where[s], med[0], med[1], med[2],
               best_scalar / med[2], gbs, (double)max_diff);
        free(buf);
    }
    printf("S_simd = min(plain_s, restr_s) / simd_s (>1: simd mas rapido que el mejor escalar). GB/s: version simd.\n");
    printf(max_bad ? "CHECK FAIL\n" : "CHECK OK\n");
    return max_bad;
}
