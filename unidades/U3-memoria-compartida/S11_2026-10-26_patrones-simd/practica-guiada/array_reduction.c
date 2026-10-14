/* array_reduction.c — Reducción sobre un ARREGLO: histograma de n valores en nbins casillas.
 *
 * Uso: ./array_reduction [n] [nbins] [hilos]
 *
 * Tres versiones que deben dar exactamente el mismo histograma (los conteos son enteros):
 *   seq    : ciclo secuencial.
 *   redarr : `reduction(+:hist[:nbins])` (sección de arreglo, OpenMP 4.5+). Cada hilo recibe una
 *            copia privada del arreglo inicializada en 0 y al final OpenMP suma las copias.
 *   local  : acumuladores locales "a mano": cada hilo llena su propio arreglo y lo vuelca al
 *            compartido dentro de una región `critical` (una sola vez por hilo, no por elemento).
 *            Es lo que se hace cuando el compilador no soporta secciones de arreglo (o en CUDA).
 * La versión INCORRECTA (hist[bin]++ compartido sin proteger) es una carrera: se vio en S07.
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <omp.h>

#define REPS 5

/* Generador determinista (xorshift64*): la misma semilla da los mismos datos en cualquier máquina. */
static uint64_t rng_state = 0x9E3779B97F4A7C15ULL;
static double next_uniform(void)
{
    rng_state ^= rng_state >> 12;
    rng_state ^= rng_state << 25;
    rng_state ^= rng_state >> 27;
    uint64_t z = rng_state * 0x2545F4914F6CDD1DULL;
    return (double)(z >> 11) * (1.0 / 9007199254740992.0);   /* [0, 1) */
}

static int cmp_double(const void *p, const void *q)
{
    double a = *(const double *)p, b = *(const double *)q;
    return (a > b) - (a < b);
}

static void hist_seq(const double *v, long n, long *hist, int nbins)
{
    for (int b = 0; b < nbins; b++) hist[b] = 0;
    for (long i = 0; i < n; i++) {
        int bin = (int)(v[i] * nbins);         /* v en [0,1) → bin en [0, nbins) */
        hist[bin]++;
    }
}

static void hist_redarr(const double *v, long n, long *hist, int nbins)
{
    for (int b = 0; b < nbins; b++) hist[b] = 0;
    /* hist[:nbins] es una sección de arreglo: "desde el inicio, nbins elementos". */
    #pragma omp parallel for reduction(+:hist[:nbins])
    for (long i = 0; i < n; i++) {
        int bin = (int)(v[i] * nbins);
        hist[bin]++;                           /* escribe en la copia privada del hilo */
    }
}

static void hist_local(const double *v, long n, long *hist, int nbins)
{
    for (int b = 0; b < nbins; b++) hist[b] = 0;
    #pragma omp parallel
    {
        long *local = calloc((size_t)nbins, sizeof *local);   /* privado: lo declara el hilo */
        #pragma omp for
        for (long i = 0; i < n; i++) {
            int bin = (int)(v[i] * nbins);
            local[bin]++;
        }
        #pragma omp critical
        for (int b = 0; b < nbins; b++)        /* nbins sumas por hilo, no una por elemento */
            hist[b] += local[b];
        free(local);
    }
}

typedef void (*hist_fn)(const double *, long, long *, int);

static double time_hist(hist_fn fn, const double *v, long n, long *hist, int nbins)
{
    double t[REPS];
    fn(v, n, hist, nbins);                     /* calentamiento */
    for (int r = 0; r < REPS; r++) {
        double t0 = omp_get_wtime();
        fn(v, n, hist, nbins);
        t[r] = omp_get_wtime() - t0;
    }
    qsort(t, REPS, sizeof t[0], cmp_double);
    return t[REPS / 2];
}

int main(int argc, char **argv)
{
    long n = (argc > 1) ? atol(argv[1]) : 20000000L;
    int nbins = (argc > 2) ? atoi(argv[2]) : 16;
    int n_threads = (argc > 3) ? atoi(argv[3]) : omp_get_max_threads();
    if (n < 1 || nbins < 1 || n_threads < 1) { fprintf(stderr, "argumentos invalidos\n"); return 2; }
    omp_set_num_threads(n_threads);

    double *v = malloc((size_t)n * sizeof *v);
    long *h_seq = malloc((size_t)nbins * sizeof *h_seq);
    long *h_red = malloc((size_t)nbins * sizeof *h_red);
    long *h_loc = malloc((size_t)nbins * sizeof *h_loc);
    if (!v || !h_seq || !h_red || !h_loc) { fprintf(stderr, "sin memoria\n"); return 1; }
    for (long i = 0; i < n; i++) v[i] = next_uniform();

    printf("array_reduction: n=%ld nbins=%d hilos=%d\n", n, nbins, n_threads);
    double t_seq = time_hist(hist_seq, v, n, h_seq, nbins);
    double t_red = time_hist(hist_redarr, v, n, h_red, nbins);
    double t_loc = time_hist(hist_local, v, n, h_loc, nbins);

    int ok = memcmp(h_seq, h_red, (size_t)nbins * sizeof *h_seq) == 0 &&
             memcmp(h_seq, h_loc, (size_t)nbins * sizeof *h_seq) == 0;

    printf("  primeras casillas (seq): ");
    for (int b = 0; b < nbins && b < 4; b++) printf("%ld ", h_seq[b]);
    printf("...\n");
    printf("  %-8s mediana=%.4f s\n", "seq", t_seq);
    printf("  %-8s mediana=%.4f s  speedup=%.2f\n", "redarr", t_red, t_seq / t_red);
    printf("  %-8s mediana=%.4f s  speedup=%.2f\n", "local", t_loc, t_seq / t_loc);
    printf("  histogramas identicos: %s\n", ok ? "si" : "NO");
    printf(ok ? "CHECK OK\n" : "CHECK FAIL\n");

    free(v); free(h_seq); free(h_red); free(h_loc);
    return ok ? 0 : 1;
}
