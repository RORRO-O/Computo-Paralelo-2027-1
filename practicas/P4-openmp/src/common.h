/* common.h — utilidades compartidas por los programas de la Práctica 4 (OpenMP).
 * Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1
 *
 * Contiene:
 *   - p4_reps():        repeticiones cronometradas (variable de entorno REPS; 5 por defecto).
 *   - p4_median():      mediana, mínimo y máximo de k tiempos.
 *   - p4_lcg_next():    generador congruencial lineal (los datos son idénticos en cualquier máquina).
 *   - p4_print_times(): las líneas tiempo_s= (mediana) y tiempos_s= (cada repetición) que lee medir.sh.
 *   - p4_todo():        marca un TODO(n) sin completar; p4_report_todo() imprime "TODO pendiente".
 * Todo es `static inline` para incluirlo en varios .c sin warnings.
 */
#ifndef P4_COMMON_H
#define P4_COMMON_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>

#define P4_MAX_REPS    32
#define P4_MAX_THREADS 256

/* Repeticiones cronometradas: variable de entorno REPS (por defecto 5, el mínimo del protocolo). */
static inline int p4_reps(void)
{
    const char *s = getenv("REPS");
    int r = s ? atoi(s) : 5;
    if (r < 1) r = 1;
    if (r > P4_MAX_REPS) r = P4_MAX_REPS;
    return r;
}

static inline int p4_cmp_double(const void *x, const void *y)
{
    double a = *(const double *)x, b = *(const double *)y;
    return (a > b) - (a < b);
}

/* Mediana (elemento central tras ordenar una copia), mínimo y máximo de k tiempos. */
static inline double p4_median(const double *t, int k, double *tmin, double *tmax)
{
    double c[P4_MAX_REPS];
    if (k > P4_MAX_REPS) k = P4_MAX_REPS;
    memcpy(c, t, (size_t)k * sizeof(double));
    qsort(c, (size_t)k, sizeof c[0], p4_cmp_double);
    if (tmin) *tmin = c[0];
    if (tmax) *tmax = c[k - 1];
    return c[k / 2];
}

/* Generador congruencial lineal (constantes de Numerical Recipes): misma semilla => misma secuencia. */
static inline unsigned p4_lcg_next(unsigned *state)
{
    *state = *state * 1664525u + 1013904223u;
    return *state;
}

/* Líneas que lee medir.sh: la mediana (tiempo_s=) y las repeticiones individuales (tiempos_s=). */
static inline void p4_print_times(const double *t, int k)
{
    printf("tiempo_s=%.6f\n", p4_median(t, k, NULL, NULL));
    printf("tiempos_s=");
    for (int i = 0; i < k; i++)
        printf("%s%.6f", i ? " " : "", t[i]);
    printf("\n");
}

/* --- Marcas de TODO sin completar (convención del curso: el programa imprime "TODO pendiente") ---
 * p4_todo(n) se llama desde el código provisional de un TODO(n). Puede llamarse desde varios hilos a la vez:
 * la lectura y la escritura son atómicas, y después de la primera vez ya solo se lee (sin contención). */
static unsigned p4_todo_mask;

static inline void p4_todo(int n)
{
    unsigned cur;
    #pragma omp atomic read
    cur = p4_todo_mask;
    if (!(cur & (1u << n))) {
        #pragma omp atomic
        p4_todo_mask |= 1u << n;
    }
}

/* Imprime "TODO pendiente: TODO(1) TODO(3)..." si queda alguno; devuelve 1 si hay pendientes. */
static inline int p4_report_todo(void)
{
    if (!p4_todo_mask)
        return 0;
    printf("TODO pendiente:");
    for (int n = 0; n < 32; n++)
        if (p4_todo_mask & (1u << n))
            printf(" TODO(%d)", n);
    printf("\n");
    return 1;
}

#endif /* P4_COMMON_H */
