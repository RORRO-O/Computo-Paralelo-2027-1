/*
 * common.h — utilidades compartidas por los programas de la sesión S13 (cazador de errores,
 * ejemplo resuelto e ítems del examen de práctica).
 *
 * Contiene: generación determinista de datos, mediana, lectura de argumentos, comparación con
 * tolerancia relativa y la línea RESULT que leen las pruebas. Todo es `static inline` para poder
 * incluirlo en varios .c sin warnings.
 */
#ifndef COMMON_H
#define COMMON_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <omp.h>

#define DEFAULT_N  4000000L   /* 4e6 doubles = 32 MB por arreglo; cada corrida tarda < 0.1 s */
#define N_REPS     3          /* repeticiones de la versión paralela que se comparan con la referencia */
#define REL_TOL    1e-9       /* tolerancia relativa para sumas en punto flotante (idea errónea 10) */

/* Genera n valores en [0, 1) con un generador congruencial lineal. Misma semilla => mismos datos. */
static inline void generate_data(double *x, long n, unsigned seed)
{
    unsigned s = seed;
    for (long i = 0; i < n; i++) {
        s = s * 1103515245u + 12345u;
        x[i] = (double)((s >> 8) & 0xFFFFFFu) / (double)0x1000000u;   /* 24 bits -> [0,1) */
    }
}

/* Mediana de k tiempos (ordena una copia por inserción; k es pequeño). */
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

/* Lee n de la línea de comandos: ./programa [n]. Los hilos se fijan con OMP_NUM_THREADS. */
static inline long parse_n(int argc, char **argv, long default_n)
{
    long n = default_n;
    if (argc > 1) n = atol(argv[1]);
    if (n <= 0) {
        fprintf(stderr, "Uso: %s [n > 0]   (hilos: OMP_NUM_THREADS)\n", argv[0]);
        exit(2);
    }
    return n;
}

/* 1 si a y b coinciden con tolerancia relativa tol (respecto al mayor en valor absoluto). */
static inline int close_rel(double a, double b, double tol)
{
    double scale = fabs(a) > fabs(b) ? fabs(a) : fabs(b);
    if (scale < 1e-300) return fabs(a - b) <= tol;
    return fabs(a - b) <= tol * scale;
}

/* Reserva memoria o termina con mensaje (evita comprobar NULL en cada programa). */
static inline double *alloc_doubles(long n)
{
    double *p = malloc((size_t)n * sizeof(double));
    if (p == NULL) { fprintf(stderr, "error: sin memoria para %ld doubles\n", n); exit(1); }
    return p;
}

/* Línea RESULT que leen tests/run_tests.sh y make cazar. wrong = repeticiones incorrectas. */
static inline void print_result(const char *program, long n, int wrong, int reps)
{
    printf("RESULT program=%s threads=%d n=%ld reps_incorrectas=%d/%d status=%s\n",
           program, omp_get_max_threads(), n, wrong, reps, wrong == 0 ? "OK" : "INCORRECTO");
}

#endif /* COMMON_H */
