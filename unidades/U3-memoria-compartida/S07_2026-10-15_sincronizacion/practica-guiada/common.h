/*
 * common.h — utilidades compartidas por los programas de la sesión S07.
 *
 * Contiene: generación determinista de datos, histograma secuencial de
 * referencia, comparación de histogramas, mediana y un arnés de medición
 * que sigue el protocolo del curso (1 calentamiento + 5 repeticiones, mediana).
 *
 * Todo es `static inline` para poder incluirlo en varios .c sin warnings.
 */
#ifndef COMMON_H
#define COMMON_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>

#define DEFAULT_N      10000000L   /* 1e7 elementos: ~40 MB en float */
#define DEFAULT_NBINS  64
#define N_REPS         5           /* repeticiones medidas (ademas de 1 calentamiento) */

/* Tipo de una funcion que calcula un histograma: lee x[0..n), escribe hist[0..nbins). */
typedef void (*hist_fn)(const float *x, long n, int nbins, long *hist);

/* Genera n valores en [0, 1) con un generador congruencial lineal.
 * Misma semilla => mismos datos en cualquier maquina (reproducible). */
static inline void generate_data(float *x, long n, unsigned seed)
{
    unsigned s = seed;
    for (long i = 0; i < n; i++) {
        s = s * 1103515245u + 12345u;
        x[i] = (float)((s >> 8) & 0xFFFFFFu) / (float)0x1000000u; /* 24 bits -> [0,1) */
    }
}

/* Indice del bin para un valor en [0,1). El guardia evita bin == nbins por redondeo. */
static inline int bin_of(float v, int nbins)
{
    int bin = (int)(v * (float)nbins);
    if (bin >= nbins) bin = nbins - 1;
    if (bin < 0) bin = 0;
    return bin;
}

/* Histograma secuencial: la referencia contra la que se comparan las versiones paralelas. */
static inline void histogram_seq(const float *x, long n, int nbins, long *hist)
{
    for (int b = 0; b < nbins; b++) hist[b] = 0;
    for (long i = 0; i < n; i++) hist[bin_of(x[i], nbins)]++;
}

/* Numero de bins que difieren entre dos histogramas (0 => identicos). */
static inline int count_diff_bins(const long *a, const long *b, int nbins)
{
    int diff = 0;
    for (int i = 0; i < nbins; i++) if (a[i] != b[i]) diff++;
    return diff;
}

/* Suma de todas las cuentas (debe ser n si no se perdio ninguna actualizacion). */
static inline long hist_total(const long *h, int nbins)
{
    long t = 0;
    for (int i = 0; i < nbins; i++) t += h[i];
    return t;
}

/* Mediana de k tiempos (ordena una copia por insercion; k es pequeno). */
static inline double median_of(const double *t, int k)
{
    double c[64];
    if (k > 64) k = 64;
    memcpy(c, t, (size_t)k * sizeof(double));
    for (int i = 1; i < k; i++) {
        double v = c[i];
        int j = i - 1;
        while (j >= 0 && c[j] > v) { c[j + 1] = c[j]; j--; }
        c[j + 1] = v;
    }
    return (k % 2) ? c[k / 2] : 0.5 * (c[k / 2 - 1] + c[k / 2]);
}

/* Lee n y nbins de la linea de comandos: ./programa [n] [nbins]. */
static inline void parse_args(int argc, char **argv, long *n, int *nbins)
{
    *n = DEFAULT_N;
    *nbins = DEFAULT_NBINS;
    if (argc > 1) *n = atol(argv[1]);
    if (argc > 2) *nbins = atoi(argv[2]);
    if (*n <= 0 || *nbins <= 0 || *nbins > 1000000) {
        fprintf(stderr, "Uso: %s [n > 0] [nbins en 1..1000000]\n", argv[0]);
        exit(2);
    }
}

/* Mide fn con el protocolo del curso y compara cada repeticion contra hist_ref.
 * Imprime una linea por repeticion y una linea RESULT que leen las pruebas.
 * Devuelve el numero de repeticiones con resultado incorrecto. */
static inline int run_histogram_benchmark(const char *version, hist_fn fn,
                                          const float *x, long n, int nbins,
                                          const long *hist_ref, double t_seq)
{
    long *hist = malloc((size_t)nbins * sizeof(long));
    double times[N_REPS];
    int wrong = 0;

    fn(x, n, nbins, hist);                         /* calentamiento: no se cuenta */

    for (int r = 0; r < N_REPS; r++) {
        double t0 = omp_get_wtime();
        fn(x, n, nbins, hist);
        times[r] = omp_get_wtime() - t0;
        int diff = count_diff_bins(hist_ref, hist, nbins);
        long total = hist_total(hist, nbins);
        if (diff != 0) wrong++;
        printf("  rep %d: %.4f s  total=%ld (esperado %ld)  bins distintos=%d  %s\n",
               r + 1, times[r], total, n, diff, diff == 0 ? "ok" : "INCORRECTO");
    }
    double med = median_of(times, N_REPS);
    printf("RESULT version=%s threads=%d n=%ld nbins=%d t_seq=%.4f t_par=%.4f speedup=%.2f "
           "reps_incorrectas=%d status=%s\n",
           version, omp_get_max_threads(), n, nbins, t_seq, med,
           med > 0 ? t_seq / med : 0.0, wrong, wrong == 0 ? "OK" : "INCORRECTO");
    free(hist);
    return wrong;
}

/* Prepara datos y referencia secuencial; imprime encabezado. Devuelve t_seq (mediana). */
static inline float *setup_histogram(int argc, char **argv, const char *version,
                                     long *n, int *nbins, long **hist_ref, double *t_seq)
{
    parse_args(argc, argv, n, nbins);
    float *x = malloc((size_t)*n * sizeof(float));
    *hist_ref = malloc((size_t)*nbins * sizeof(long));
    if (!x || !*hist_ref) { fprintf(stderr, "Sin memoria\n"); exit(1); }
    generate_data(x, *n, 2026u);

    double times[N_REPS];
    histogram_seq(x, *n, *nbins, *hist_ref);       /* calentamiento */
    for (int r = 0; r < N_REPS; r++) {
        double t0 = omp_get_wtime();
        histogram_seq(x, *n, *nbins, *hist_ref);
        times[r] = omp_get_wtime() - t0;
    }
    *t_seq = median_of(times, N_REPS);
    printf("== histograma %s: n=%ld nbins=%d hilos=%d  (secuencial: %.4f s, mediana de %d)\n",
           version, *n, *nbins, omp_get_max_threads(), *t_seq, N_REPS);
    return x;
}

#endif /* COMMON_H */
