/*
 * caza3_private_buggy.c — Cazador de errores S13, programa 3. TIENE EXACTAMENTE UN ERROR A PROPÓSITO.
 *
 * Qué debe hacer: estandarizar x[0..n): y[i] = (x[i] - shift) * scale, donde shift es la media y
 * scale = 1 / desviación estándar, ambas calculadas antes (en secuencial). El ciclo de la
 * estandarización se reparte entre los hilos. Compara y[] con la versión secuencial (igualdad
 * exacta: cada elemento hace la misma aritmética) e imprime RESULT (status=OK / INCORRECTO).
 *
 * Uso:      OMP_NUM_THREADS=4 ./caza3_private_buggy [n]    (por defecto n = 4 000 000)
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra -fopenmp -I. caza3_private_buggy.c -o caza3_private_buggy -lm
 * Investigar: make warn   (compila con -DINLINE_HELPER y deja que gcc te diga lo que ve)
 *
 * PRIMM: predice el síntoma ANTES de correrlo. La explicación y la corrección están en README.md
 * (bloques <details>) y en soluciones/caza3_private_fixed.c.
 */
#include "common.h"

/* Estandariza un valor. Recibe los parámetros por puntero. `noipa` impide que gcc analice el cuerpo
 * desde el llamador; con -DINLINE_HELPER (make warn) gcc sí lo ve y avisa lo que encuentra. */
#ifdef INLINE_HELPER
static inline double standardize(double v, const double *shift, const double *scale)
#else
__attribute__((noipa)) static double standardize(double v, const double *shift, const double *scale)
#endif
{
    return (v - *shift) * *scale;
}

static void mean_and_scale(const double *x, long n, double *shift, double *scale)
{
    double sum = 0.0, sumsq = 0.0;
    for (long i = 0; i < n; i++) {
        sum   += x[i];
        sumsq += x[i] * x[i];
    }
    double mean = sum / (double)n;
    double var  = sumsq / (double)n - mean * mean;
    *shift = mean;
    *scale = 1.0 / sqrt(var);
}

static void standardize_seq(const double *x, double *y, long n, double shift, double scale)
{
    for (long i = 0; i < n; i++)
        y[i] = standardize(x[i], &shift, &scale);
}

/* Versión paralela: shift y scale ya están calculados; cada hilo trabaja con su copia. */
static void standardize_par(const double *x, double *y, long n, double shift, double scale)
{
    #pragma omp parallel for private(shift, scale)
    for (long i = 0; i < n; i++)
        y[i] = standardize(x[i], &shift, &scale);
}

int main(int argc, char **argv)
{
    long n = parse_n(argc, argv, DEFAULT_N);
    double *x = alloc_doubles(n), *y_ref = alloc_doubles(n), *y = alloc_doubles(n);
    generate_data(x, n, 2026u);

    double shift, scale;
    mean_and_scale(x, n, &shift, &scale);
    standardize_seq(x, y_ref, n, shift, scale);
    printf("caza3: n=%ld hilos=%d  shift=%.6f scale=%.6f  referencia: y[0]=%.6f y[1]=%.6f y[n-1]=%.6f\n",
           n, omp_get_max_threads(), shift, scale, y_ref[0], y_ref[1], y_ref[n - 1]);

    int wrong = 0;
    for (int r = 0; r < N_REPS; r++) {
        memset(y, 0, (size_t)n * sizeof(double));
        standardize_par(x, y, n, shift, scale);
        long bad = 0;
        for (long i = 0; i < n; i++)
            if (y[i] != y_ref[i]) bad++;
        if (bad) wrong++;
        printf("  rep %d: y[0]=%.6f y[1]=%.6f y[n-1]=%.6f  elementos distintos=%ld  %s\n",
               r + 1, y[0], y[1], y[n - 1], bad, bad == 0 ? "ok" : "INCORRECTO");
    }
    print_result("caza3", n, wrong, N_REPS);
    free(x);
    free(y_ref);
    free(y);
    return wrong ? 1 : 0;
}
