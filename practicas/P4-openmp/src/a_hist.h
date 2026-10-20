/* a_hist.h — Parte A: datos, trabajo por elemento, referencia secuencial y arnés de medición del histograma.
 * Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · Práctica 4
 *
 * Problema: n lecturas de un sensor con ruido. Cada lectura cruda es un PAR de números uniformes en (0, 1]
 * (u[2i], u[2i+1]) que se convierte en una muestra normal estándar con la transformación de Box–Muller:
 *     z = sqrt(-2 ln u1) * cos(2 pi u2)
 * y se cuenta en uno de nbins intervalos iguales de [-4.5, 4.5) (las colas se acumulan en los extremos).
 * El histograma resultante tiene forma de campana: los intervalos centrales reciben muchas más cuentas.
 *
 * Diferencia con S07: allá el trabajo por elemento era ~1.5 ns (solo leer y contar); aquí la transformación
 * cuesta ~20–30 ns por elemento. Ese cociente trabajo/sincronización es lo que esta parte mide.
 *
 * Los datos se generan con semilla fija (20261015): dos corridas con el mismo n ven los mismos valores.
 * La referencia es el histograma secuencial; los conteos son enteros, así que la comparación es EXACTA.
 * Lo incluyen a_histogram.c (versiones correctas) y a_histogram_buggy.c (carrera a propósito).
 */
#ifndef P4_A_HIST_H
#define P4_A_HIST_H

#include <math.h>
#include "common.h"

#define HIST_DEFAULT_N      1000000L   /* 10^6 muestras = 2·10^6 float = 8 MB */
#define HIST_DEFAULT_NBINS  64
#define HIST_DEFAULT_CUTOFF 16384L     /* versión con tareas: hojas de a lo más 16 384 muestras */
#define HIST_SEED           20261015u
#define HIST_Z_MIN          (-4.5)
#define HIST_Z_RANGE        9.0        /* [-4.5, 4.5) */
#define HIST_TWO_PI         6.283185307179586

typedef void (*hist_fn)(const float *u, long n, int nbins, long *hist);

/* 2n valores en (0, 1]: 24 bits del generador + 1, así ln(u) nunca es ln(0) y el float es exacto. */
static inline void hist_generate(float *u, long n, unsigned seed)
{
    unsigned s = seed;
    for (long i = 0; i < 2 * n; i++) {
        unsigned r = p4_lcg_next(&s);
        u[i] = (float)(((r >> 8) & 0xFFFFFFu) + 1u) / (float)0x1000000u;
    }
}

/* Trabajo de UNA muestra: Box–Muller + índice del intervalo. Es privado del hilo que lo calcula
 * (solo lee u[]); lo único que se comparte en el histograma es la actualización hist[b]++. */
static inline int hist_bin(const float *u, long i, int nbins)
{
    double r = sqrt(-2.0 * log((double)u[2 * i]));
    double z = r * cos(HIST_TWO_PI * (double)u[2 * i + 1]);
    double t = (z - HIST_Z_MIN) * ((double)nbins / HIST_Z_RANGE);
    int b = (t < 0.0) ? 0 : (int)t;            /* cola izquierda -> intervalo 0 */
    if (b >= nbins) b = nbins - 1;             /* cola derecha -> último intervalo */
    return b;
}

/* Referencia secuencial: T(1) del speedup y la verdad contra la que se compara. */
static inline void hist_seq(const float *u, long n, int nbins, long *hist)
{
    for (int b = 0; b < nbins; b++) hist[b] = 0;
    for (long i = 0; i < n; i++) hist[hist_bin(u, i, nbins)]++;
}

static inline int hist_diff_bins(const long *a, const long *b, int nbins)
{
    int d = 0;
    for (int i = 0; i < nbins; i++) if (a[i] != b[i]) d++;
    return d;
}

static inline long hist_total(const long *h, int nbins)
{
    long t = 0;
    for (int i = 0; i < nbins; i++) t += h[i];
    return t;
}

/* Mide fn con el protocolo: 1 calentamiento + reps repeticiones; cada repetición se compara contra ref
 * (igualdad exacta). Con verbose imprime una línea por repetición (útil para ver la carrera) y las líneas
 * tiempo_s= / tiempos_s= de medir.sh. Siempre imprime la línea resumen y la línea RESULT de las pruebas.
 * Devuelve el número de repeticiones incorrectas. */
static inline int hist_benchmark(const char *mode, hist_fn fn, const float *u, long n, int nbins,
                                 const long *ref, double t_seq, int reps, int verbose)
{
    long *hist = malloc((size_t)nbins * sizeof(long));
    double t[P4_MAX_REPS] = { 0 };
    int wrong = 0;
    if (!hist) { fprintf(stderr, "sin memoria\n"); exit(1); }

    fn(u, n, nbins, hist);                              /* calentamiento: no se cuenta */
    for (int r = 0; r < reps; r++) {
        double t0 = omp_get_wtime();
        fn(u, n, nbins, hist);                          /* región de interés: solo el histograma */
        t[r] = omp_get_wtime() - t0;
        int diff = hist_diff_bins(ref, hist, nbins);
        if (diff) wrong++;
        if (verbose)
            printf("  rep %d: %.4f s  total=%ld (esperado %ld)  intervalos distintos=%d  %s\n",
                   r + 1, t[r], hist_total(hist, nbins), n, diff, diff ? "INCORRECTO" : "ok");
    }
    int threads = omp_get_max_threads();
    double mn, mx, med = p4_median(t, reps, &mn, &mx);
    double speedup = med > 0 ? t_seq / med : 0.0;
    printf("%-10s mediana %.4f s (min %.4f max %.4f) %7.1f ns/elemento  speedup %5.2f  eficiencia %4.2f  %s\n",
           mode, med, mn, mx, med * 1e9 / (double)n, speedup, speedup / threads,
           wrong ? "INCORRECTO" : "correcto");
    printf("RESULT,a_histogram,%s,%d,%ld,%d,%.6f,%.6f,%.3f,%d,%s\n", mode, threads, n, nbins,
           t_seq, med, speedup, wrong, wrong ? "INCORRECTO" : "OK");
    if (verbose) p4_print_times(t, reps);
    free(hist);
    return wrong;
}

/* Lee [n] [nbins] desde argv[first], genera los datos, calcula la referencia y mide la secuencial con el
 * protocolo (t_seq_reps recibe las reps repeticiones; devuelve la mediana en *t_seq). */
static inline float *hist_setup(int argc, char **argv, int first, long *n, int *nbins, long **ref,
                                double *t_seq, double *t_seq_reps, int reps)
{
    *n = HIST_DEFAULT_N;
    *nbins = HIST_DEFAULT_NBINS;
    if (argc > first) *n = atol(argv[first]);
    if (argc > first + 1) *nbins = atoi(argv[first + 1]);
    if (*n <= 0 || *nbins <= 0 || *nbins > 1000000) {
        fprintf(stderr, "uso: %s ... [n > 0] [nbins en 1..1000000]\n", argv[0]);
        exit(2);
    }
    float *u = malloc((size_t)(2 * *n) * sizeof(float));
    *ref = malloc((size_t)*nbins * sizeof(long));
    if (!u || !*ref) { fprintf(stderr, "sin memoria para n=%ld\n", *n); exit(1); }
    hist_generate(u, *n, HIST_SEED);

    hist_seq(u, *n, *nbins, *ref);                      /* calentamiento */
    for (int r = 0; r < reps; r++) {
        double t0 = omp_get_wtime();
        hist_seq(u, *n, *nbins, *ref);
        t_seq_reps[r] = omp_get_wtime() - t0;
    }
    *t_seq = p4_median(t_seq_reps, reps, NULL, NULL);
    return u;
}

#endif /* P4_A_HIST_H */
