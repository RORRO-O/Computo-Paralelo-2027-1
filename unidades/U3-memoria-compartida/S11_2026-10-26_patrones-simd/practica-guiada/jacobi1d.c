/* jacobi1d.c — Stencil 1D de Jacobi (ecuación de calor estacionaria) con doble búfer.
 *
 * Uso: ./jacobi1d [n] [max_iter] [tol] [modo] [hilos] [reps] [check_every]
 *   modo: seq | par | simd      (el programa SIEMPRE corre seq como referencia y luego el modo pedido)
 *   check_every: cada cuántas iteraciones se calcula el cambio máximo (1 = en todas, el valor por defecto)
 *
 * Problema: barra de n puntos; u[0] = 100 (extremo caliente), u[n-1] = 0 (extremo frío), interior
 * inicial 0. En cada iteración cada punto interior toma el promedio de sus vecinos:
 *       u_new[i] = 0.5 * (u[i-1] + u[i+1])
 * y se mide el cambio máximo |u_new[i] - u[i]|. Se detiene cuando el cambio máximo < tol o al llegar a
 * max_iter. La solución exacta es la recta de 100 a 0.
 *
 * Doble búfer: se lee de `u` y se escribe en `u_new`; al final de la iteración se intercambian los
 * PUNTEROS (no se copian los datos). Así ninguna iteración lee un valor ya actualizado.
 *
 * Cada función step_* tiene dos ciclos: uno que solo actualiza (iteraciones en las que no toca revisar la
 * convergencia) y otro que actualiza y calcula el cambio máximo con una reducción max. Con check_every = 1
 * siempre se usa el segundo; con check_every = 10 el primero corre 9 de cada 10 iteraciones.
 *
 * Reporta, para el modo seq y para el modo pedido: iteraciones, cambio máximo final, mediana de
 * `reps` repeticiones (más 1 calentamiento), la diferencia máxima entre ambos resultados y el speedup.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <omp.h>

typedef enum { MODE_SEQ, MODE_PAR, MODE_SIMD } mode_t_;

static int cmp_double(const void *p, const void *q)
{
    double a = *(const double *)p, b = *(const double *)q;
    return (a > b) - (a < b);
}

static void init(double *u, double *u_new, long n)
{
    for (long i = 0; i < n; i++) u[i] = u_new[i] = 0.0;
    u[0] = u_new[0] = 100.0;          /* las fronteras no cambian: van en ambos búferes */
    u[n - 1] = u_new[n - 1] = 0.0;
}

/* Una iteración secuencial. Regresa el cambio máximo (o INFINITY si no tocaba calcularlo). */
static double step_seq(const double *restrict u, double *restrict u_new, long n, int check)
{
    if (!check) {                                   /* solo actualizar */
        for (long i = 1; i < n - 1; i++)
            u_new[i] = 0.5 * (u[i - 1] + u[i + 1]);
        return INFINITY;
    }
    double max_diff = 0.0;
    for (long i = 1; i < n - 1; i++) {              /* actualizar y medir el cambio */
        u_new[i] = 0.5 * (u[i - 1] + u[i + 1]);
        double d = fabs(u_new[i] - u[i]);
        if (d > max_diff) max_diff = d;
    }
    return max_diff;
}

/* Una iteración paralela: cada hilo recibe un bloque de puntos; el cambio máximo se combina con
 * reduction(max:...). El máximo no depende del orden: el resultado es idéntico al secuencial. */
static double step_par(const double *restrict u, double *restrict u_new, long n, int check)
{
    if (!check) {
        #pragma omp parallel for
        for (long i = 1; i < n - 1; i++)
            u_new[i] = 0.5 * (u[i - 1] + u[i + 1]);
        return INFINITY;
    }
    double max_diff = 0.0;
    #pragma omp parallel for reduction(max:max_diff)
    for (long i = 1; i < n - 1; i++) {
        u_new[i] = 0.5 * (u[i - 1] + u[i + 1]);
        double d = fabs(u_new[i] - u[i]);
        if (d > max_diff) max_diff = d;
    }
    return max_diff;
}

/* Una iteración paralela Y vectorizada (modo simd). */
static double step_simd(const double *restrict u, double *restrict u_new, long n, int check)
{
    /* TODO(1): en las DOS directivas de esta función, pide además vectorizar el ciclo (conserva la
     * cláusula de reducción max en la segunda). Después borra las dos líneas marcadas con "quitar" para
     * que el programa deje de avisar que el TODO está pendiente.
     * Verifica con `make report`: deben aparecer dos "loop vectorized" en los ciclos de esta función. */
    static int pending = 1;                                                                    /* quitar */
    if (pending) { printf("TODO pendiente: TODO(1) en step_simd (jacobi1d.c)\n"); pending = 0; } /* quitar */
    if (!check) {
        #pragma omp parallel for
        for (long i = 1; i < n - 1; i++)
            u_new[i] = 0.5 * (u[i - 1] + u[i + 1]);
        return INFINITY;
    }
    double max_diff = 0.0;
    #pragma omp parallel for reduction(max:max_diff)
    for (long i = 1; i < n - 1; i++) {
        u_new[i] = 0.5 * (u[i - 1] + u[i + 1]);
        double d = fabs(u_new[i] - u[i]);
        if (d > max_diff) max_diff = d;
    }
    return max_diff;
}

/* Corre Jacobi completo. Regresa el número de iteraciones; deja el resultado en *out. */
static long jacobi(double *u, double *u_new, long n, long max_iter, double tol, mode_t_ mode,
                   int check_every, double *final_diff, double **out)
{
    init(u, u_new, n);
    long iter = 0;
    double diff = INFINITY;
    while (iter < max_iter && diff >= tol) {
        /* Se revisa la convergencia cada check_every iteraciones y siempre en la última. */
        int check = ((iter + 1) % check_every == 0) || (iter + 1 == max_iter);
        if (mode == MODE_SEQ)       diff = step_seq(u, u_new, n, check);
        else if (mode == MODE_PAR)  diff = step_par(u, u_new, n, check);
        else                        diff = step_simd(u, u_new, n, check);
        double *tmp = u; u = u_new; u_new = tmp;     /* intercambio de punteros: O(1) */
        iter++;
    }
    *final_diff = diff;
    *out = u;                                        /* el último escrito quedó en `u` tras el swap */
    return iter;
}

static double run_timed(double *u, double *u_new, long n, long max_iter, double tol, mode_t_ mode,
                        int check_every, int reps, long *iters, double *final_diff, double **out,
                        double *t_min, double *t_max)
{
    double *t = malloc((size_t)reps * sizeof *t);
    if (!t) { fprintf(stderr, "sin memoria\n"); exit(1); }
    jacobi(u, u_new, n, max_iter, tol, mode, check_every, final_diff, out);   /* calentamiento */
    for (int r = 0; r < reps; r++) {
        double t0 = omp_get_wtime();
        *iters = jacobi(u, u_new, n, max_iter, tol, mode, check_every, final_diff, out);
        t[r] = omp_get_wtime() - t0;
    }
    qsort(t, (size_t)reps, sizeof t[0], cmp_double);
    *t_min = t[0]; *t_max = t[reps - 1];
    double med = t[reps / 2];
    free(t);
    return med;
}

int main(int argc, char **argv)
{
    long n = (argc > 1) ? atol(argv[1]) : 100000L;
    long max_iter = (argc > 2) ? atol(argv[2]) : 2000L;
    double tol = (argc > 3) ? atof(argv[3]) : 1e-6;
    const char *mode_name = (argc > 4) ? argv[4] : "par";
    int n_threads = (argc > 5) ? atoi(argv[5]) : omp_get_max_threads();
    int reps = (argc > 6) ? atoi(argv[6]) : 5;
    int check_every = (argc > 7) ? atoi(argv[7]) : 1;
    if (n < 3 || max_iter < 1 || n_threads < 1 || reps < 1 || check_every < 1) {
        fprintf(stderr, "argumentos invalidos\n"); return 2;
    }

    mode_t_ mode;
    if (strcmp(mode_name, "seq") == 0) mode = MODE_SEQ;
    else if (strcmp(mode_name, "par") == 0) mode = MODE_PAR;
    else if (strcmp(mode_name, "simd") == 0) mode = MODE_SIMD;
    else { fprintf(stderr, "modo invalido: %s (usa seq | par | simd)\n", mode_name); return 2; }
    omp_set_num_threads(n_threads);

    double *a = malloc((size_t)n * sizeof *a), *b = malloc((size_t)n * sizeof *b);
    double *c = malloc((size_t)n * sizeof *c), *d = malloc((size_t)n * sizeof *d);
    if (!a || !b || !c || !d) { fprintf(stderr, "sin memoria\n"); return 1; }

    printf("jacobi1d: n=%ld max_iter=%ld tol=%.1e modo=%s hilos=%d reps=%d check_every=%d\n",
           n, max_iter, tol, mode_name, n_threads, reps, check_every);

    long it_seq, it_mode;
    double df_seq, df_mode, *u_seq, *u_mode, mn, mx;
    double t_seq = run_timed(a, b, n, max_iter, tol, MODE_SEQ, check_every, reps,
                             &it_seq, &df_seq, &u_seq, &mn, &mx);
    printf("  %-5s iteraciones=%-8ld cambio_max=%.3e  u[n/2]=%.6f  mediana=%.4f s (min %.4f, max %.4f)\n",
           "seq", it_seq, df_seq, u_seq[n / 2], t_seq, mn, mx);
    double t_mode = run_timed(c, d, n, max_iter, tol, mode, check_every, reps,
                              &it_mode, &df_mode, &u_mode, &mn, &mx);
    printf("  %-5s iteraciones=%-8ld cambio_max=%.3e  u[n/2]=%.6f  mediana=%.4f s (min %.4f, max %.4f)\n",
           mode_name, it_mode, df_mode, u_mode[n / 2], t_mode, mn, mx);

    double max_abs_diff = 0.0;
    for (long i = 0; i < n; i++) {
        double e = fabs(u_mode[i] - u_seq[i]);
        if (e > max_abs_diff) max_abs_diff = e;
    }
    int ok = (it_seq == it_mode) && (max_abs_diff <= 1e-12 * 100.0);
    printf("  convergio=%s  max|u_%s - u_seq|=%.1e  speedup=%.2f\n",
           it_mode < max_iter ? "si" : "no (llego a max_iter)", mode_name, max_abs_diff, t_seq / t_mode);
    printf(ok ? "CHECK OK\n" : "CHECK FAIL (iteraciones distintas o resultado distinto)\n");

    free(a); free(b); free(c); free(d);
    return ok ? 0 : 1;
}
