/*
 * soluciones/caza3_private_fixed.c — Corrección del cazador 3 (S13). Ábrelo DESPUÉS de la fase Modificar.
 *
 * El error: `private(shift, scale)`. `private` crea en cada hilo una copia NUEVA y SIN INICIALIZAR;
 * no copia el valor que la variable tenía afuera (Anexo A, idea 9). Cada hilo estandariza con basura
 * (en la máquina de autoría salieron ceros y números del orden de 1e-310). No es una carrera: nadie
 * escribe memoria ajena; por eso ThreadSanitizer no dice nada útil y `make test` es lo que lo delata.
 * gcc tampoco avisa con el ayudante `noipa`; con `make warn` (ayudante inline) sí: "'shift' may be
 * used uninitialized".
 *
 * Correcciones válidas (elige la más barata que sea correcta):
 *   (a) ninguna cláusula: shift y scale solo se LEEN dentro de la región; una variable compartida que
 *       nadie escribe no tiene carrera y no cuesta nada. Es la que se usa aquí.
 *   (b) `firstprivate(shift, scale)`: copia inicializada por hilo. Correcta; cuesta dos copias por hilo
 *       y solo haría falta si cada hilo fuera a MODIFICAR su copia.
 *   `private` nunca es correcta aquí, porque el valor se necesita.
 */
#include "common.h"

#ifdef INLINE_HELPER
static inline double standardize(double v, const double *shift, const double *scale)
#else
__attribute__((noipa)) static double standardize(double v, const double *shift, const double *scale)
#endif
{
    return (v - *shift) * *scale;
}

static void mean_and_scale(const double *x, long n, double *shift, double *scale)
{
    double sum = 0.0, sumsq = 0.0;
    for (long i = 0; i < n; i++) {
        sum   += x[i];
        sumsq += x[i] * x[i];
    }
    double mean = sum / (double)n;
    double var  = sumsq / (double)n - mean * mean;
    *shift = mean;
    *scale = 1.0 / sqrt(var);
}

static void standardize_seq(const double *x, double *y, long n, double shift, double scale)
{
    for (long i = 0; i < n; i++)
        y[i] = standardize(x[i], &shift, &scale);
}

static void standardize_par(const double *x, double *y, long n, double shift, double scale)
{
    #pragma omp parallel for               /* CORRECCIÓN (a): shift y scale compartidas, solo lectura */
    for (long i = 0; i < n; i++)
        y[i] = standardize(x[i], &shift, &scale);
}

int main(int argc, char **argv)
{
    long n = parse_n(argc, argv, DEFAULT_N);
    double *x = alloc_doubles(n), *y_ref = alloc_doubles(n), *y = alloc_doubles(n);
    generate_data(x, n, 2026u);

    double shift, scale;
    mean_and_scale(x, n, &shift, &scale);
    standardize_seq(x, y_ref, n, shift, scale);
    printf("caza3 (corregido): n=%ld hilos=%d  shift=%.6f scale=%.6f  referencia: y[0]=%.6f y[1]=%.6f y[n-1]=%.6f\n",
           n, omp_get_max_threads(), shift, scale, y_ref[0], y_ref[1], y_ref[n - 1]);

    int wrong = 0;
    for (int r = 0; r < N_REPS; r++) {
        memset(y, 0, (size_t)n * sizeof(double));
        standardize_par(x, y, n, shift, scale);
        long bad = 0;
        for (long i = 0; i < n; i++)
            if (y[i] != y_ref[i]) bad++;
        if (bad) wrong++;
        printf("  rep %d: y[0]=%.6f y[1]=%.6f y[n-1]=%.6f  elementos distintos=%ld  %s\n",
               r + 1, y[0], y[1], y[n - 1], bad, bad == 0 ? "ok" : "INCORRECTO");
    }
    print_result("caza3", n, wrong, N_REPS);
    free(x);
    free(y_ref);
    free(y);
    return wrong ? 1 : 0;
}
