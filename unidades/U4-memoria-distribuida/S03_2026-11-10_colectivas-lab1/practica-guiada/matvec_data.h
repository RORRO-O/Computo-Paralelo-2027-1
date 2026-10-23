/*
 * matvec_data.h — Datos y rutinas comunes a todos los programas de la práctica guiada S03.
 *
 * Todos los programas (secuencial, punto a punto, colectivas) usan la MISMA matriz y el
 * MISMO vector, para que sus resultados se puedan comparar exactamente:
 *
 *     A[i][j] = i + j          x[j] = j + 1          (enteros guardados como double)
 *
 * Con n = 8:  y[i] = 36·i + 168  →  y = 168, 204, 240, 276, 312, 348, 384, 420
 *             checksum (suma de y) = 2352.
 * Los valores son enteros exactos en double; no hay redondeo que explicar mientras las
 * sumas queden por debajo de 2^53 (n ≤ 30 000 sobra para esta sesión).
 *
 * Las filas de A se identifican a simple vista: la fila i empieza en i, i+1, i+2, ...
 * Eso sirve en la fase Investigar para saber qué fila global recibió cada rango.
 */
#ifndef MATVEC_DATA_H
#define MATVEC_DATA_H

#include <limits.h>
#include <stdio.h>
#include <stdlib.h>

static inline double matrix_entry(long long i, long long j) { return (double)(i + j); }
static inline double vector_entry(long long j) { return (double)(j + 1); }

/* Reserva 'count' doubles inicializados en 0.0; aborta el proceso si no hay memoria. */
static inline double *alloc_doubles(long long count)
{
    double *p = calloc((size_t)count, sizeof(double));
    if (p == NULL) {
        fprintf(stderr, "sin memoria para %lld doubles\n", count);
        exit(2);
    }
    return p;
}

/* Llena 'rows' filas consecutivas de A (n columnas) empezando en la fila global first_row. */
static inline void fill_rows(double *A, long long first_row, long long rows, long long n)
{
    for (long long i = 0; i < rows; i++)
        for (long long j = 0; j < n; j++)
            A[i * n + j] = matrix_entry(first_row + i, j);
}

static inline void fill_vector(double *x, long long n)
{
    for (long long j = 0; j < n; j++)
        x[j] = vector_entry(j);
}

/* y_local[i] = Σ_j A_local[i][j]·x[j] para las 'rows' filas que tiene este proceso. */
static inline void local_matvec(const double *A_local, const double *x, double *y_local,
                                long long rows, long long n)
{
    for (long long i = 0; i < rows; i++) {
        double acc = 0.0;
        for (long long j = 0; j < n; j++)
            acc += A_local[i * n + j] * x[j];
        y_local[i] = acc;
    }
}

static inline double vector_sum(const double *v, long long n)
{
    double s = 0.0;
    for (long long i = 0; i < n; i++) s += v[i];
    return s;
}

static inline double vector_sum_squares(const double *v, long long n)
{
    double s = 0.0;
    for (long long i = 0; i < n; i++) s += v[i] * v[i];
    return s;
}

/* Imprime y completo solo si es chico (n ≤ 16): con n grande basta el checksum. */
static inline void print_vector_if_small(const double *y, long long n)
{
    if (n > 16) return;
    for (long long i = 0; i < n; i++)
        printf("y[%lld] = %.1f\n", i, y[i]);
}

/* Lee n (argv[1]) y reps (argv[2]); regresa 0 si son válidos. */
static inline int parse_args(int argc, char **argv, long long *n, int *reps)
{
    *n = (argc > 1) ? atoll(argv[1]) : 8;
    *reps = (argc > 2) ? atoi(argv[2]) : 1;
    if (*n <= 0 || *n > 30000 || *reps <= 0) {
        fprintf(stderr, "Uso: %s [n en 1..30000] [reps >= 1]\n", argv[0]);
        return 1;
    }
    /* Las cuentas de MPI son int: filas·n debe caber. */
    if (*n * *n > (long long)INT_MAX) return 1;
    return 0;
}

#endif /* MATVEC_DATA_H */
