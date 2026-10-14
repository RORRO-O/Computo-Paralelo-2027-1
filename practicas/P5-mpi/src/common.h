/*
 * common.h — Utilidades compartidas por los programas de la Práctica 5 (MPI).
 *
 *  - p5_value(i): dato determinista del elemento i, idéntico en cualquier máquina y en cualquier
 *    proceso; por eso la versión secuencial y la distribuida ven exactamente los mismos números.
 *  - block_partition: reparto por bloques con residuo (S01): los primeros n % p rangos llevan un
 *    elemento más. Es la única función de reparto de la práctica; Scatterv/Gatherv la usan tal cual.
 *  - p5_time_stats / p5_print_time_line: protocolo de medición del curso (1 calentamiento fuera de
 *    estas funciones + reps repeticiones; mediana, mín y máx). La línea "TIME,..." la lee escalado.sh.
 *  - p5_positional / p5_has_flag: argumentos posicionales con banderas opcionales ("--trace").
 *
 * No depende de MPI: la incluyen tanto los programas secuenciales (gcc) como los distribuidos (mpicc).
 */
#ifndef P5_COMMON_H
#define P5_COMMON_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define P5_MAX_REPS 32

/* Reloj de pared para los programas SECUENCIALES (los MPI usan MPI_Wtime). Requiere que el .c defina
 * _POSIX_C_SOURCE 200809L en su primera línea (con -std=c11 estricto, si no, clock_gettime no existe). */
#if defined(_POSIX_C_SOURCE) && _POSIX_C_SOURCE >= 199309L
#include <time.h>
static inline double p5_wtime(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + 1e-9 * (double)ts.tv_nsec;
}
#endif

/* Valor determinista en [-1, 1) para el índice i (mezcla de bits tipo SplitMix64). */
static inline double p5_value(long long i)
{
    unsigned long long z = (unsigned long long)i * 0x9E3779B97F4A7C15ULL + 0xD1B54A32D192ED03ULL;
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ULL;
    z = (z ^ (z >> 27)) * 0x94D049BB133111EBULL;
    z ^= z >> 31;
    return (double)(z >> 11) * (2.0 / 9007199254740992.0) - 1.0;
}

/* Reparto por bloques con residuo: cuántos elementos (count) y desde cuál (first) le tocan a rank. */
static inline void block_partition(long long n, int p, int rank, long long *count, long long *first)
{
    long long base = n / p, rem = n % p;
    *count = base + (rank < rem ? 1 : 0);
    *first = (long long)rank * base + (rank < rem ? rank : rem);
}

static inline int p5_cmp_double(const void *a, const void *b)
{
    double x = *(const double *)a, y = *(const double *)b;
    return (x > y) - (x < y);
}

typedef struct {
    double median, min, max;
} p5_stats;

/* Mediana, mínimo y máximo de reps tiempos (ordena una copia; el arreglo original no cambia). */
static inline p5_stats p5_time_stats(const double *t, int reps)
{
    double copy[P5_MAX_REPS];
    p5_stats s;
    memcpy(copy, t, (size_t)reps * sizeof(double));
    qsort(copy, (size_t)reps, sizeof(double), p5_cmp_double);
    s.min = copy[0];
    s.max = copy[reps - 1];
    s.median = (reps % 2) ? copy[reps / 2] : 0.5 * (copy[reps / 2 - 1] + copy[reps / 2]);
    return s;
}

/* Línea legible del protocolo: "tiempo: mediana=... s (min ..., max ...) de k repeticiones tras 1 calentamiento" */
static inline void p5_print_time_human(const char *region, const double *t, int reps)
{
    p5_stats s = p5_time_stats(t, reps);
    printf("tiempo (%s): mediana=%.6f s (min %.6f, max %.6f) de %d repeticiones tras 1 calentamiento\n",
           region, s.median, s.min, s.max, reps);
}

/* Línea para máquinas (escalado.sh): TIME,t1;t2;...;tk,mediana,min,max */
static inline void p5_print_time_line(const double *t, int reps)
{
    p5_stats s = p5_time_stats(t, reps);
    printf("TIME,");
    for (int r = 0; r < reps; r++) printf("%s%.6f", r ? ";" : "", t[r]);
    printf(",%.6f,%.6f,%.6f\n", s.median, s.min, s.max);
}

/* k-ésimo argumento posicional (k desde 0) ignorando banderas "--algo"; NULL si no existe. */
static inline const char *p5_positional(int argc, char **argv, int k)
{
    int seen = 0;
    for (int i = 1; i < argc; i++) {
        if (strncmp(argv[i], "--", 2) == 0) continue;
        if (seen == k) return argv[i];
        seen++;
    }
    return NULL;
}

static inline int p5_has_flag(int argc, char **argv, const char *flag)
{
    for (int i = 1; i < argc; i++)
        if (strcmp(argv[i], flag) == 0) return 1;
    return 0;
}

static inline long long p5_arg_ll(int argc, char **argv, int k, long long def)
{
    const char *s = p5_positional(argc, argv, k);
    return s ? atoll(s) : def;
}

static inline double p5_arg_double(int argc, char **argv, int k, double def)
{
    const char *s = p5_positional(argc, argv, k);
    return s ? atof(s) : def;
}

/* Número de repeticiones acotado a [1, P5_MAX_REPS]. */
static inline int p5_clamp_reps(long long reps)
{
    if (reps < 1) return 1;
    if (reps > P5_MAX_REPS) return P5_MAX_REPS;
    return (int)reps;
}

static inline double *p5_alloc(long long count)
{
    double *p = malloc((size_t)(count > 0 ? count : 1) * sizeof(double));
    if (!p) {
        fprintf(stderr, "sin memoria para %lld doubles\n", count);
        exit(2);
    }
    return p;
}

/* |a - b| <= tol * max(1, |b|) */
static inline int p5_close(double a, double b, double tol)
{
    double d = a - b, m = b < 0 ? -b : b;
    if (d < 0) d = -d;
    if (m < 1.0) m = 1.0;
    return d <= tol * m;
}

#endif /* P5_COMMON_H */
