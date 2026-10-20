/* item_III2_scan_buggy.c — Examen de práctica U3, sección III, ítem 2 (encontrar y corregir el error).
 * Suma de prefijos y[i] = y[i-1] + x[i] "paralelizada" con parallel for. Enteros: la comparación es exacta.
 * La corrección del examen (scan en dos fases, como en S11) se obtiene con -DCORREGIDO.
 *   gcc -std=c11 -O2 -Wall -Wextra -fopenmp -I.. item_III2_scan_buggy.c -o item_III2_scan_buggy -lm
 *   OMP_NUM_THREADS=4 ./item_III2_scan_buggy [n]
 */
#include "common.h"

static void scan_seq(const long *x, long *y, long n)
{
    y[0] = x[0];
    for (long i = 1; i < n; i++) y[i] = y[i - 1] + x[i];
}

#ifndef CORREGIDO
static void scan_par(const long *x, long *y, long n)
{
    y[0] = x[0];
    #pragma omp parallel for
    for (long i = 1; i < n; i++)
        y[i] = y[i - 1] + x[i];
}
#else
/* Corrección: cambiar el algoritmo (dos fases + corrección), no agregar una cláusula. */
static void scan_par(const long *x, long *y, long n)
{
    long block_sum[64] = {0};
    int max_t = omp_get_max_threads() < 64 ? omp_get_max_threads() : 64;   /* block_sum tiene 64 casillas */
    #pragma omp parallel num_threads(max_t)
    {
        int tid = omp_get_thread_num(), nt = omp_get_num_threads();
        long lo = n * tid / nt, hi = n * (tid + 1) / nt;
        long acc = 0;
        for (long i = lo; i < hi; i++) { acc += x[i]; y[i] = acc; }   /* fase 1: scan local */
        block_sum[tid] = acc;
        #pragma omp barrier                                           /* todos los totales listos */
        long offset = 0;
        for (int t = 0; t < tid; t++) offset += block_sum[t];         /* fase 2: desplazamiento propio */
        for (long i = lo; i < hi; i++) y[i] += offset;                /* fase 3: corrección */
    }
}
#endif

int main(int argc, char **argv)
{
    long n = parse_n(argc, argv, 1L << 22);
    long *x = malloc((size_t)n * sizeof(long)), *y_ref = malloc((size_t)n * sizeof(long)), *y = malloc((size_t)n * sizeof(long));
    if (!x || !y_ref || !y) { fprintf(stderr, "sin memoria\n"); return 1; }
    for (long i = 0; i < n; i++) x[i] = (i * 7919L) % 1000L + 1;
    scan_seq(x, y_ref, n);
    int wrong = 0;
    for (int r = 0; r < N_REPS; r++) {
        memset(y, 0, (size_t)n * sizeof(long));
        scan_par(x, y, n);
        long bad = 0;
        for (long i = 0; i < n; i++) if (y[i] != y_ref[i]) bad++;
        if (bad) wrong++;
        printf("  rep %d: y[n-1]=%ld (secuencial %ld)  elementos distintos=%ld  %s\n",
               r + 1, y[n - 1], y_ref[n - 1], bad, bad == 0 ? "ok" : "INCORRECTO");
    }
    print_result("item_III2_scan", n, wrong, N_REPS);
    free(x);
    free(y_ref);
    free(y);
    return wrong ? 1 : 0;
}
