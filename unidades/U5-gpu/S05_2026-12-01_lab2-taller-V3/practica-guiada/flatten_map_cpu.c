/* flatten_map_cpu.c — Referencia secuencial del mini PRIMM "aplanar y mapear".
 * Es la "V1" de este problema: el mismo paso de Jacobi 2D sobre la malla aplanada por filas,
 * con la misma aritmética en float que el kernel. Sirve para verificar la GPU y para T(1).
 *
 * Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · Unidad V · Sesión S05 (martes 1 de diciembre de 2026)
 *
 * Compila: gcc -std=c11 -O2 -Wall -Wextra flatten_map_cpu.c -o flatten_map_cpu
 * Uso:     ./flatten_map_cpu [alto] [ancho] [iteraciones] [fila_objetivo] [col_objetivo]
 * Por defecto: 1024 1024 100 3 5
 */
#define _POSIX_C_SOURCE 199309L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define REPS 5                 /* repeticiones medidas (protocolo del curso) */
static const float TOP_VALUE = 100.0f;

/* Índice lineal de (fila r, columna c) en una malla de ancho w guardada por filas. */
static int lin(int r, int c, int w) { return r * w + c; }

static double now_s(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}

static void init_grid(float *g, int h, int w)
{
    for (int r = 0; r < h; r++)
        for (int c = 0; c < w; c++)
            g[lin(r, c, w)] = (r == 0) ? TOP_VALUE : 0.0f;
}

/* `iters` pasos de Jacobi con dos arreglos (ping-pong). Deja el resultado en `out`. */
static void jacobi_cpu(const float *init, float *out, float *tmp, int h, int w, int iters)
{
    float *cur = out, *nxt = tmp;
    memcpy(cur, init, (size_t)h * w * sizeof(float));
    memcpy(nxt, init, (size_t)h * w * sizeof(float));   /* frontera copiada en ambos */
    for (int it = 0; it < iters; it++) {
        for (int r = 1; r < h - 1; r++)
            for (int c = 1; c < w - 1; c++) {
                int idx = lin(r, c, w);
                nxt[idx] = 0.25f * (cur[idx - w] + cur[idx + w] + cur[idx - 1] + cur[idx + 1]);
            }
        float *swap = cur; cur = nxt; nxt = swap;
    }
    if (cur != out) memcpy(out, cur, (size_t)h * w * sizeof(float));
}

static int cmp_double(const void *a, const void *b)
{
    double x = *(const double *)a, y = *(const double *)b;
    return (x > y) - (x < y);
}

static double median(double *v, int n)
{
    qsort(v, (size_t)n, sizeof(double), cmp_double);
    return (n % 2) ? v[n / 2] : 0.5 * (v[n / 2 - 1] + v[n / 2]);
}

int main(int argc, char **argv)
{
    int h = 1024, w = 1024, iters = 100, target_r = 3, target_c = 5;
    if (argc > 1) h        = atoi(argv[1]);
    if (argc > 2) w        = atoi(argv[2]);
    if (argc > 3) iters    = atoi(argv[3]);
    if (argc > 4) target_r = atoi(argv[4]);
    if (argc > 5) target_c = atoi(argv[5]);
    if (h < 3 || w < 3 || iters < 1) {
        fprintf(stderr, "Parámetros inválidos: alto y ancho >= 3, iteraciones >= 1\n");
        return 1;
    }
    if (target_r < 0 || target_r >= h || target_c < 0 || target_c >= w) {
        fprintf(stderr, "La celda objetivo (%d,%d) está fuera de la malla %dx%d\n", target_r, target_c, h, w);
        return 1;
    }

    size_t n = (size_t)h * w;
    float *init = malloc(n * sizeof(float));
    float *out  = malloc(n * sizeof(float));
    float *tmp  = malloc(n * sizeof(float));
    if (!init || !out || !tmp) { fprintf(stderr, "Sin memoria\n"); return 1; }
    init_grid(init, h, w);

    printf("# flatten_map_cpu · alto=%d ancho=%d iteraciones=%d (referencia secuencial)\n", h, w, iters);
    printf("indice lineal de (fila %d, col %d) con ancho %d: %d\n", target_r, target_c, w, lin(target_r, target_c, w));

    jacobi_cpu(init, out, tmp, h, w, iters);              /* calentamiento, no se cuenta */
    double t[REPS];
    for (int rep = 0; rep < REPS; rep++) {
        double t0 = now_s();
        jacobi_cpu(init, out, tmp, h, w, iters);
        t[rep] = now_s() - t0;
    }
    double t_med = median(t, REPS);

    double sum = 0.0;
    for (size_t i = 0; i < n; i++) sum += out[i];
    printf("checksum = %.6f\n", sum);
    printf("t_cpu (mediana de %d, s) = %.6f   min = %.6f   max = %.6f\n", REPS, t_med, t[0], t[REPS - 1]);
    printf("CSV,cpu,1,1,%d,%d,%d,0,%.6f,,,1.00,1.00,REF\n", h, w, iters, t_med);

    free(init); free(out); free(tmp);
    return 0;
}
