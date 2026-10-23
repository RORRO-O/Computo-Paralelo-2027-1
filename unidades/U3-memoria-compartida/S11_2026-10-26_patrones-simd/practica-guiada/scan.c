/* scan.c — Suma de prefijos (scan inclusivo) en paralelo con el patrón de dos fases.
 *
 * Uso: ./scan [n] [hilos]
 *
 * Secuencial:  y[i] = y[i-1] + x[i]   (dependencia acarreada: no se puede repartir tal cual).
 * Paralelo (dos fases más una corrección):
 *   Fase 1  (paralela)   cada hilo t hace el scan de su bloque [lo_t, hi_t) y guarda el total
 *                        del bloque en block_sum[t].
 *   Fase 2  (secuencial) un solo hilo convierte block_sum en desplazamientos: offset[t] = suma de
 *                        los totales de los bloques anteriores. Son p números: cuesta O(p).
 *   Fase 3  (paralela)   cada hilo suma offset[t] a todo su bloque.
 * El resultado se compara contra la versión secuencial con tolerancia: el orden de las sumas cambia
 * y en punto flotante eso cambia el redondeo.
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include <omp.h>

#define REPS 5

static uint64_t rng_state = 0x9E3779B97F4A7C15ULL;
static double next_uniform(void)
{
    rng_state ^= rng_state >> 12;
    rng_state ^= rng_state << 25;
    rng_state ^= rng_state >> 27;
    uint64_t z = rng_state * 0x2545F4914F6CDD1DULL;
    return (double)(z >> 11) * (1.0 / 9007199254740992.0);
}

static int cmp_double(const void *p, const void *q)
{
    double a = *(const double *)p, b = *(const double *)q;
    return (a > b) - (a < b);
}

static void scan_seq(const double *x, double *y, long n)
{
    double acc = 0.0;
    for (long i = 0; i < n; i++) {
        acc += x[i];
        y[i] = acc;
    }
}

static void scan_par(const double *x, double *y, long n, double *block_sum)
{
    #pragma omp parallel
    {
        int tid = omp_get_thread_num();
        int nt = omp_get_num_threads();
        long lo = n * tid / nt;              /* reparto por bloques contiguos */
        long hi = n * (tid + 1) / nt;

        /* Fase 1: scan local del bloque. */
        double acc = 0.0;
        for (long i = lo; i < hi; i++) {
            acc += x[i];
            y[i] = acc;
        }
        block_sum[tid] = acc;
        /* Barrera implícita: la fase 2 necesita TODOS los totales. */
        #pragma omp barrier

        /* Fase 2: un hilo convierte totales en desplazamientos (scan exclusivo de p números). */
        #pragma omp single
        {
            double run = 0.0;
            for (int t = 0; t < nt; t++) {
                double tmp = block_sum[t];
                block_sum[t] = run;          /* ahora block_sum[t] = offset del bloque t */
                run += tmp;
            }
        }   /* barrera implícita al final de single */

        /* Fase 3: cada hilo corrige su bloque con su desplazamiento. */
        double offset = block_sum[tid];
        for (long i = lo; i < hi; i++)
            y[i] += offset;
    }
}

int main(int argc, char **argv)
{
    long n = (argc > 1) ? atol(argv[1]) : (1L << 23);
    int n_threads = (argc > 2) ? atoi(argv[2]) : omp_get_max_threads();
    if (n < 1 || n_threads < 1) { fprintf(stderr, "argumentos invalidos\n"); return 2; }
    omp_set_num_threads(n_threads);

    double *x = malloc((size_t)n * sizeof *x);
    double *y_seq = malloc((size_t)n * sizeof *y_seq);
    double *y_par = malloc((size_t)n * sizeof *y_par);
    double *block_sum = malloc((size_t)n_threads * sizeof *block_sum);
    if (!x || !y_seq || !y_par || !block_sum) { fprintf(stderr, "sin memoria\n"); return 1; }
    for (long i = 0; i < n; i++) x[i] = next_uniform();

    double t[REPS], t_seq, t_par;
    scan_seq(x, y_seq, n);                              /* calentamiento */
    for (int r = 0; r < REPS; r++) {
        double t0 = omp_get_wtime();
        scan_seq(x, y_seq, n);
        t[r] = omp_get_wtime() - t0;
    }
    qsort(t, REPS, sizeof t[0], cmp_double);
    t_seq = t[REPS / 2];

    scan_par(x, y_par, n, block_sum);                   /* calentamiento */
    for (int r = 0; r < REPS; r++) {
        double t0 = omp_get_wtime();
        scan_par(x, y_par, n, block_sum);
        t[r] = omp_get_wtime() - t0;
    }
    qsort(t, REPS, sizeof t[0], cmp_double);
    t_par = t[REPS / 2];

    /* Verificación con tolerancia relativa al valor más grande (la suma total). */
    double max_abs_diff = 0.0;
    long idx_max = 0;
    for (long i = 0; i < n; i++) {
        double d = fabs(y_par[i] - y_seq[i]);
        if (d > max_abs_diff) { max_abs_diff = d; idx_max = i; }
    }
    double scale = fabs(y_seq[n - 1]);
    double rel = max_abs_diff / scale;
    int ok = rel <= 1e-12;

    printf("scan: n=%ld hilos=%d\n", n, n_threads);
    printf("  seq  mediana=%.4f s   y[n-1]=%.6f\n", t_seq, y_seq[n - 1]);
    printf("  par  mediana=%.4f s   y[n-1]=%.6f   speedup=%.2f\n", t_par, y_par[n - 1], t_seq / t_par);
    printf("  max|y_par - y_seq| = %.3e (en i=%ld)   relativo a la suma total = %.3e\n",
           max_abs_diff, idx_max, rel);
    printf("  identicos bit a bit: %s   dentro de tolerancia 1e-12: %s\n",
           max_abs_diff == 0.0 ? "si" : "no", ok ? "si" : "NO");
    printf(ok ? "CHECK OK\n" : "CHECK FAIL\n");

    free(x); free(y_seq); free(y_par); free(block_sum);
    return ok ? 0 : 1;
}
