/*
 * soluciones/caza1_race_fixed.c — Corrección del cazador 1 (S13). Ábrelo DESPUÉS de la fase Modificar.
 *
 * El error: `sum` y `sumsq` están declaradas fuera de la región paralela, así que son COMPARTIDAS, y
 * todas las iteraciones las escriben (`sum += x[i]`): leer-modificar-escribir sin nada que lo ordene.
 * Es una condición de carrera (Anexo A, idea 7: "si salió bien una vez no hay carrera").
 *
 * Síntoma observado: media y varianza distintas de la referencia (en la máquina de autoría, cerca de
 * la mitad) y distintas entre repeticiones. ThreadSanitizer lo señala en las dos líneas del cuerpo.
 *
 * Corrección más barata que sea correcta: `reduction(+:sum, sumsq)`. Cada hilo acumula en una copia
 * privada y OpenMP combina al final (una operación compartida por hilo, no por elemento).
 *   - `atomic` en cada línea también es correcto, pero paga una operación atómica por elemento
 *     (en S07 costó 5x más que reduction).
 *   - `critical` serializa el ciclo entero: correcto y más lento que la secuencial.
 * El resultado con reduction difiere de la secuencial en los últimos dígitos (otro orden de suma);
 * por eso la comparación es con tolerancia relativa 1e-9 (idea 10).
 */
#include "common.h"

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

static void stats_par(const double *x, long n, double *mean, double *var)
{
    double sum = 0.0, sumsq = 0.0;
    #pragma omp parallel for reduction(+:sum, sumsq)   /* CORRECCIÓN: copia privada por hilo + combinación */
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
    printf("caza1 (corregido): n=%ld hilos=%d  referencia secuencial: media=%.12f varianza=%.12f\n",
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
