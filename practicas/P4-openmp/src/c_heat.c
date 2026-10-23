/* c_heat.c — Parte C (alternativa): ecuación de calor 1D con criterio de convergencia, OpenMP.
 * Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · Práctica 4 · ESQUELETO (E/S, medición y checksums)
 *
 * Uso:  ./c_heat [n] [max_iter] [tol] [check_every] [modo] [--verificar]
 *   n            celdas (por defecto 500 000; mínimo 3)
 *   max_iter     pasos máximos (por defecto 500); tol umbral de paro (por defecto 0 = correr max_iter pasos)
 *   check_every  cada cuántos pasos se revisa la convergencia (por defecto 1)
 *   modo         seq | omp (por defecto omp); --verificar corre además la secuencial y compara
 * Entorno: OMP_NUM_THREADS; REPS (repeticiones cronometradas, 5; siempre 1 calentamiento).
 *
 * Contrato (c_heat.h fija problema, condición inicial, heat_point, heat_is_check_step y checksum):
 * heat_solve_* recibe los dos búferes ya inicializados, avanza hasta converger o hasta max_iter, deja en
 * *iters los pasos dados y en *final_diff el último cambio máximo revisado, y devuelve el puntero al búfer
 * con el estado final (puede ser u o u_new: con intercambio de punteros no se sabe de antemano).
 *
 * Lo que diseñas tú (TODO(6) y TODO(7)) y justificas con datos en REPORTE.md: cómo se reparte cada paso
 * entre los hilos, cómo se calcula el cambio máximo en paralelo sin critical en el ciclo de celdas
 * (restricción de la Parte C), qué pasa con los búferes al final de cada paso y cuánto cuesta revisar la
 * convergencia en cada paso frente a hacerlo cada check_every pasos. Mientras TODO(6) o TODO(7) estén
 * pendientes el programa imprime "TODO pendiente" y las pruebas de la opción calor fallan.
 */
#include "c_heat.h"

/* Versión secuencial: la referencia T(1) y la verdad contra la que se compara (--verificar). */
static double *heat_solve_seq(double *u, double *u_new, long n, long max_iter, double tol, long check_every,
                              long *iters, double *final_diff)
{
    /* TODO(6): mientras queden pasos (it < max_iter) y no haya convergido (diff >= tol, con diff = INFINITY
     * al inicio): calcula u_new[i] = heat_point(u, i) para 1 <= i <= n-2; si heat_is_check_step(it + 1, ...)
     * dice que toca revisar, calcula también diff = max |u_new[i] - u[i]|; después intercambia los
     * apuntadores u y u_new y cuenta el paso. Deja *iters y *final_diff y devuelve el búfer con el estado
     * final. Borra p4_todo(6) y la línea (void). */
    p4_todo(6);
    (void)u_new; (void)n; (void)max_iter; (void)tol; (void)check_every;
    *iters = 0;
    *final_diff = INFINITY;
    return u;
}

/* Versión paralela: mismos pasos y mismos bits que heat_solve_seq. */
static double *heat_solve_omp(double *u, double *u_new, long n, long max_iter, double tol, long check_every,
                              long *iters, double *final_diff)
{
    /* TODO(7): tu diseño. Contrato: mismo número de pasos que la secuencial y estado final igual (tolerancia
     * 1e-10). Restricción: sin critical en el ciclo de celdas. Borra p4_todo(7) y la línea (void). */
    p4_todo(7);
    (void)u_new; (void)n; (void)max_iter; (void)tol; (void)check_every;
    *iters = 0;
    *final_diff = INFINITY;
    return u;
}

/* ======================= Desde aquí: E/S, medición y checksum (código base) ======================= */

int main(int argc, char **argv)
{
    long n = 500000, max_iter = 500, check_every = 1;
    double tol = 0.0;
    const char *mode = "omp";
    int verify = 0, argn = 0;
    const char *pos[5] = { 0 };
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--verificar") == 0) verify = 1;
        else if (argn < 5) pos[argn++] = argv[i];
    }
    if (pos[0]) n = atol(pos[0]);
    if (pos[1]) max_iter = atol(pos[1]);
    if (pos[2]) tol = atof(pos[2]);
    if (pos[3]) check_every = atol(pos[3]);
    if (pos[4]) mode = pos[4];
    if (n < 3 || max_iter < 1 || tol < 0 || check_every < 1
        || (strcmp(mode, "seq") != 0 && strcmp(mode, "omp") != 0)) {
        fprintf(stderr, "uso: %s [n>=3] [max_iter>=1] [tol>=0] [check_every>=1] [seq|omp] [--verificar]\n",
                argv[0]);
        return 2;
    }
    int is_omp = strcmp(mode, "omp") == 0;
    int threads = is_omp ? omp_get_max_threads() : 1;
    int reps = p4_reps();
    double *a = malloc((size_t)n * sizeof(double)), *b = malloc((size_t)n * sizeof(double));
    double t[P4_MAX_REPS] = { 0 };
    if (!a || !b) { fprintf(stderr, "sin memoria para n=%ld\n", n); return 2; }

    printf("c_heat: n=%ld max_iter=%ld tol=%.1e check_every=%ld modo=%s hilos=%d reps=%d\n",
           n, max_iter, tol, check_every, mode, threads, reps);
    printf("n=%ld\n", n);
    long iters = 0;
    double final_diff = 0.0, *res = a;
    for (int r = -1; r < reps; r++) {            /* r = -1: calentamiento (no se cuenta) */
        heat_init(a, b, n);                       /* fuera del cronómetro */
        double t0 = omp_get_wtime();
        res = is_omp ? heat_solve_omp(a, b, n, max_iter, tol, check_every, &iters, &final_diff)
                     : heat_solve_seq(a, b, n, max_iter, tol, check_every, &iters, &final_diff);
        double el = omp_get_wtime() - t0;
        if (r >= 0) t[r] = el;
    }
    double cs = heat_checksum(res, n), cs2 = heat_checksum2(res, n);
    double mn, mx, med = p4_median(t, reps, &mn, &mx);
    printf("iteraciones=%ld convergio=%s cambio_max=%.3e\n", iters,
           (tol > 0 && final_diff < tol) ? "si" : "no", final_diff);
    printf("checksum=%.12e checksum2=%.12e u[n/2]=%.12e\n", cs, cs2, res[n / 2]);
    printf("mediana %.4f s (min %.4f max %.4f)  %.2f ns por celda-paso\n", med, mn, mx,
           iters > 0 ? med * 1e9 / ((double)(n - 2) * (double)iters) : 0.0);

    const char *status = (iters > 0) ? "OK" : "FALLA";
    if (verify && is_omp) {
        double *c = malloc((size_t)n * sizeof(double)), *d = malloc((size_t)n * sizeof(double));
        long it2;
        double df2;
        if (!c || !d) { fprintf(stderr, "sin memoria\n"); return 2; }
        heat_init(c, d, n);
        double *ref = heat_solve_seq(c, d, n, max_iter, tol, check_every, &it2, &df2);
        double maxdiff = 0.0;
        for (long i = 0; i < n; i++) {
            double e = fabs(ref[i] - res[i]);
            if (e > maxdiff) maxdiff = e;
        }
        int same = (it2 == iters && maxdiff <= 1e-10);
        if (!same) status = "FALLA";
        printf("verificacion contra la secuencial: %s (iteraciones %ld vs %ld, max|dif| = %.1e)\n",
               p4_todo_mask ? "NO APLICA (TODO pendiente)" : (same ? "OK" : "FALLA"), iters, it2, maxdiff);
        free(c); free(d);
    }
    if (p4_report_todo()) status = "TODO";
    p4_print_times(t, reps);
    printf("RESULT,c_heat,%s,%d,%ld,%ld,%g,%ld,%ld,%.12e,%.12e,%.6f,%s\n", mode, threads, n, max_iter, tol,
           check_every, iters, cs, cs2, med, status);
    free(a); free(b);
    return strcmp(status, "OK") == 0 ? 0 : 1;
}
