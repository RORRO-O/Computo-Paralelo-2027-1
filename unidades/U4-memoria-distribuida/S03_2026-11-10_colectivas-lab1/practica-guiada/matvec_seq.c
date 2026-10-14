/*
 * matvec_seq.c — Producto matriz-vector y = A·x en un solo proceso (sin MPI).
 *
 * Es la REFERENCIA: contra ella comparan las pruebas y con ella se calcula el speedup
 * (T(1) es el mejor programa secuencial, no el MPI con -np 1). El cronómetro cubre
 * solo el cómputo, repetido 'reps' veces para poder hacerlo medible.
 *
 * Compilar:  gcc -std=c11 -O2 -Wall -Wextra -o matvec_seq matvec_seq.c -lm
 * Uso:       ./matvec_seq [n] [reps]        (por defecto n = 8, reps = 1)
 */
#define _POSIX_C_SOURCE 199309L /* clock_gettime con -std=c11 */
#include <math.h>
#include <time.h>
#include "matvec_data.h"

static double wall_seconds(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}

int main(int argc, char **argv)
{
    long long n;
    int reps;
    if (parse_args(argc, argv, &n, &reps) != 0) return 1;

    double *A = alloc_doubles(n * n);
    double *x = alloc_doubles(n);
    double *y = alloc_doubles(n);
    fill_rows(A, 0, n, n); /* las n filas, desde la 0 */
    fill_vector(x, n);

    /* Región cronometrada: SOLO el producto (lo que las versiones MPI reparten). */
    double t0 = wall_seconds();
    for (int r = 0; r < reps; r++)
        local_matvec(A, x, y, n, n);
    double t1 = wall_seconds();

    printf("n = %lld, p = 1 (secuencial), reps = %d\n", n, reps);
    print_vector_if_small(y, n);
    printf("checksum = %.6f\n", vector_sum(y, n));
    printf("norma = %.6f\n", sqrt(vector_sum_squares(y, n))); /* referencia para la fase Crear */
    printf("tiempo calcular = %.6f s\n", t1 - t0);

    free(A); free(x); free(y);
    return 0;
}
