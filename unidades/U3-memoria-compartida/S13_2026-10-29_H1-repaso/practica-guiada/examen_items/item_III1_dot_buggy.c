/* item_III1_dot_buggy.c — Examen de práctica U3, sección III, ítem 1 (encontrar y corregir el error).
 * Producto punto de dos vectores con 4 hilos. Compila, corre y a veces hasta da bien.
 * La corrección del examen se obtiene con -DCORREGIDO (la clave está en examen-practica-U3.md).
 *   gcc -std=c11 -O2 -Wall -Wextra -fopenmp -I.. item_III1_dot_buggy.c -o item_III1_dot_buggy -lm
 *   OMP_NUM_THREADS=4 ./item_III1_dot_buggy [n]
 */
#include "common.h"

static double dot_seq(const double *x, const double *y, long n)
{
    double dot = 0.0;
    for (long i = 0; i < n; i++) dot += x[i] * y[i];
    return dot;
}

static double dot_par(const double *x, const double *y, long n)
{
    double dot = 0.0;
#ifdef CORREGIDO
    #pragma omp parallel for reduction(+:dot)
#else
    #pragma omp parallel for
#endif
    for (long i = 0; i < n; i++) {
        double p = x[i] * y[i];
        dot += p;
    }
    return dot;
}

int main(int argc, char **argv)
{
    long n = parse_n(argc, argv, 2000000L);
    double *x = alloc_doubles(n), *y = alloc_doubles(n);
    generate_data(x, n, 11u);
    generate_data(y, n, 23u);
    double ref = dot_seq(x, y, n);
    int wrong = 0;
    for (int r = 0; r < N_REPS; r++) {
        double d = dot_par(x, y, n);
        int ok = close_rel(d, ref, REL_TOL);
        if (!ok) wrong++;
        printf("  rep %d: dot=%.9f (secuencial %.9f) %s\n", r + 1, d, ref, ok ? "ok" : "INCORRECTO");
    }
    print_result("item_III1_dot", n, wrong, N_REPS);
    free(x);
    free(y);
    return wrong ? 1 : 0;
}
