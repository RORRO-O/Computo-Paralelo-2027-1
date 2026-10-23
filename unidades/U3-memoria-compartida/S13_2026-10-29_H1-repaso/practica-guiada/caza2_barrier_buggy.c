/*
 * caza2_barrier_buggy.c — Cazador de errores S13, programa 2. TIENE EXACTAMENTE UN ERROR A PROPÓSITO.
 *
 * Qué debe hacer: calcular a[i] = transform(x[i]) repartiendo el ciclo entre los hilos y, cuando
 * TODO a[] esté listo, que el hilo 0 lo sume y compare la suma con la referencia secuencial.
 * Imprime una línea por repetición y una línea RESULT (status=OK / INCORRECTO).
 *
 * Uso:      OMP_NUM_THREADS=4 timeout 10 ./caza2_barrier_buggy [n]   (por defecto n = 4 000 000)
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra -fopenmp -I. caza2_barrier_buggy.c -o caza2_barrier_buggy -lm
 *
 * PRIMM: predice el síntoma ANTES de correrlo (pista honesta: usa `timeout 10`). La explicación y la
 * corrección están en README.md (bloques <details>) y en soluciones/caza2_barrier_fixed.c.
 */
#include "common.h"

/* Transformación por elemento: barata, sin dependencias entre iteraciones. */
static inline double transform(double v)
{
    return 1.5 * sqrt(v) + 0.25;
}

static double sum_transformed_seq(const double *x, double *a, long n)
{
    double s = 0.0;
    for (long i = 0; i < n; i++) {
        a[i] = transform(x[i]);
        s += a[i];
    }
    return s;
}

/* Versión paralela: los hilos llenan a[] y el hilo 0 suma al final. */
static double sum_transformed_par(const double *x, double *a, long n)
{
    double total = 0.0;
    #pragma omp parallel
    {
        int tid = omp_get_thread_num();

        #pragma omp for nowait
        for (long i = 0; i < n; i++)
            a[i] = transform(x[i]);

        if (tid == 0) {
            #pragma omp barrier            /* el hilo 0 espera a que los demás terminen a[] */
            double s = 0.0;
            for (long i = 0; i < n; i++)
                s += a[i];
            total = s;
        }
    }
    return total;
}

int main(int argc, char **argv)
{
    long n = parse_n(argc, argv, DEFAULT_N);
    double *x = alloc_doubles(n), *a = alloc_doubles(n);
    generate_data(x, n, 2026u);

    double ref = sum_transformed_seq(x, a, n);
    printf("caza2: n=%ld hilos=%d  referencia secuencial: suma=%.6f\n", n, omp_get_max_threads(), ref);
    fflush(stdout);

    int wrong = 0;
    for (int r = 0; r < N_REPS; r++) {
        memset(a, 0, (size_t)n * sizeof(double));          /* borra a[] para no heredar la rep anterior */
        double s = sum_transformed_par(x, a, n);
        int ok = close_rel(s, ref, REL_TOL);
        if (!ok) wrong++;
        printf("  rep %d: suma=%.6f  %s\n", r + 1, s, ok ? "ok" : "INCORRECTO");
        fflush(stdout);
    }
    print_result("caza2", n, wrong, N_REPS);
    free(x);
    free(a);
    return wrong ? 1 : 0;
}
