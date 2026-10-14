/*
 * soluciones/caza2_barrier_fixed.c — Corrección del cazador 2 (S13). Ábrelo DESPUÉS de la fase Modificar.
 *
 * El error: `#pragma omp barrier` dentro de `if (tid == 0)`. Una barrera la deben encontrar TODOS los
 * hilos del equipo (OpenMP API 5.2, "barrier Construct"); aquí solo la encuentra el hilo 0. Los otros
 * tres siguen hasta la barrera implícita del final de la región y el hilo 0 se queda esperando en una
 * barrera a la que nadie más llega: interbloqueo (Anexo A, idea 32). Con 1 hilo "funciona", lo cual no
 * lo hace correcto (idea 7). El `nowait` no es el error en sí: quitó la barrera implícita del `for`, y
 * el autor intentó reponerla solo para un hilo.
 *
 * Síntoma observado: imprime la referencia y se cuelga (timeout lo mata, código 124) con 2 o 4 hilos.
 *
 * Correcciones válidas (elige la más barata que sea correcta):
 *   (a) quitar `nowait`: la barrera implícita del `for` ya garantiza que a[] está completo; es la que
 *       se usa aquí porque no agrega ninguna sincronización nueva;
 *   (b) dejar `nowait` y poner `#pragma omp barrier` FUERA del `if`, para que la alcancen todos;
 *   (c) sustituir el `if (tid == 0)` por `#pragma omp single` precedido de una barrera (la del `single`
 *       está al final, no al principio: por sí sola no sirve).
 */
#include "common.h"

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

static double sum_transformed_par(const double *x, double *a, long n)
{
    double total = 0.0;
    #pragma omp parallel
    {
        int tid = omp_get_thread_num();

        #pragma omp for                    /* CORRECCIÓN (a): barrera implícita al final del for */
        for (long i = 0; i < n; i++)
            a[i] = transform(x[i]);

        if (tid == 0) {                    /* aquí ya TODO a[] está escrito: la lectura es segura */
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
    printf("caza2 (corregido): n=%ld hilos=%d  referencia secuencial: suma=%.6f\n", n, omp_get_max_threads(), ref);

    int wrong = 0;
    for (int r = 0; r < N_REPS; r++) {
        memset(a, 0, (size_t)n * sizeof(double));
        double s = sum_transformed_par(x, a, n);
        int ok = close_rel(s, ref, REL_TOL);
        if (!ok) wrong++;
        printf("  rep %d: suma=%.6f  %s\n", r + 1, s, ok ? "ok" : "INCORRECTO");
    }
    print_result("caza2", n, wrong, N_REPS);
    free(x);
    free(a);
    return wrong ? 1 : 0;
}
