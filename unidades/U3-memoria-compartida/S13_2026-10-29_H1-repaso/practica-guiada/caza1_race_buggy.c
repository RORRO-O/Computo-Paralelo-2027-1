/*
 * caza1_race_buggy.c — Cazador de errores S13, programa 1. TIENE EXACTAMENTE UN ERROR A PROPÓSITO.
 *
 * Qué debe hacer: calcular la media y la varianza de x[0..n) con varios hilos y compararlas con la
 * versión secuencial (misma semilla, mismos datos). Imprime una línea por repetición y una línea
 * RESULT con status=OK si las tres repeticiones coinciden (tolerancia relativa 1e-9) o INCORRECTO.
 *
 * Uso:      OMP_NUM_THREADS=4 ./caza1_race_buggy [n]      (por defecto n = 4 000 000)
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra -fopenmp -I. caza1_race_buggy.c -o caza1_race_buggy -lm
 * ThreadSanitizer: make caza1_race_buggy_tsan && OMP_NUM_THREADS=4 ./caza1_race_buggy_tsan 200000
 *
 * PRIMM: predice el síntoma ANTES de correrlo; la explicación y la corrección están en README.md
 * (bloques <details>) y en soluciones/caza1_race_fixed.c. No las abras antes de la fase Modificar.
 */
#include "common.h"

/* Referencia secuencial: media y varianza poblacional en una pasada. */
static void stats_seq(const double *x, long n, double *mean, double *var)
{
    double sum = 0.0, sumsq = 0.0;
    for (long i = 0; i < n; i++) {
        sum   += x[i];
        sumsq += x[i] * x[i];
    }
    *mean = sum / (double)n;
    *var  = sumsq / (double)n - (*mean) * (*mean);
}

/* Versión paralela: mismo cálculo, iteraciones repartidas entre los hilos. */
static void stats_par(const double *x, long n, double *mean, double *var)
{
    double sum = 0.0, sumsq = 0.0;
    #pragma omp parallel for
    for (long i = 0; i < n; i++) {
        sum   += x[i];
        sumsq += x[i] * x[i];
    }
    *mean = sum / (double)n;
    *var  = sumsq / (double)n - (*mean) * (*mean);
}

int main(int argc, char **argv)
{
    long n = parse_n(argc, argv, DEFAULT_N);
    double *x = alloc_doubles(n);
    generate_data(x, n, 2026u);

    double mean_ref, var_ref;
    stats_seq(x, n, &mean_ref, &var_ref);
    printf("caza1: n=%ld hilos=%d  referencia secuencial: media=%.12f varianza=%.12f\n",
           n, omp_get_max_threads(), mean_ref, var_ref);

    int wrong = 0;
    for (int r = 0; r < N_REPS; r++) {
        double mean, var;
        stats_par(x, n, &mean, &var);
        int ok = close_rel(mean, mean_ref, REL_TOL) && close_rel(var, var_ref, REL_TOL);
        if (!ok) wrong++;
        printf("  rep %d: media=%.12f varianza=%.12f  %s\n", r + 1, mean, var, ok ? "ok" : "INCORRECTO");
    }
    print_result("caza1", n, wrong, N_REPS);
    free(x);
    return wrong ? 1 : 0;
}
