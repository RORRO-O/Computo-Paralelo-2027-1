/*
 * profile_amdahl.c — Perfilado por secciones con omp_get_wtime() y Amdahl con
 * la fracción secuencial MEDIDA (no contada en líneas de código).
 *
 * El programa tiene tres secciones:
 *   A  generar datos        secuencial: es una recurrencia (cada valor depende del anterior)
 *   B  transformar          paralelizable: cada elemento es independiente (parallel for)
 *   C  suavizar y sumar     secuencial: filtro y[i] = 0.9*y[i-1] + 0.1*z[i] (dependencia acarreada)
 *
 * Mide cada sección por separado (calentamiento + 5 repeticiones, mediana), calcula
 * f = (T_A + T_C) / T_total con la versión secuencial, predice el speedup de Amdahl
 * para el número de hilos actual y lo compara con el speedup medido y con la
 * fracción secuencial de Karp–Flatt. También imprime clock() junto a omp_get_wtime()
 * para que se vea por qué clock() no sirve para medir speedup.
 *
 * Uso: ./profile_amdahl [n] [iters] [archivo.csv]    (por defecto n = 2 000 000, iters = 64)
 *      `iters` es el trabajo por elemento de la sección B: subirlo baja f; bajarlo la sube.
 */
#include <time.h>
#include "common.h"

#define DEFAULT_N     2000000L
#define DEFAULT_ITERS 64

/* A — generación secuencial: recurrencia LCG + una transformación con log y sqrt. */
static void generate(double *x, long n)
{
    unsigned state = 2026u;
    for (long i = 0; i < n; i++) {
        double u = lcg_next(&state);             /* depende del estado anterior: no se reparte */
        x[i] = sqrt(-2.0 * log(1.0 - u));        /* magnitud tipo Box–Muller, en (0, ~6) */
    }
}

/* Trabajo por elemento de B: `iters` pasos del mapa logístico (cadena dependiente).
 * `noinline` hace que la versión secuencial y la paralela ejecuten exactamente el mismo
 * código por elemento; así la comparación mide el reparto, no diferencias del compilador. */
__attribute__((noinline)) static double transform_one(double v, int iters)
{
    v = v / 8.0;                                 /* lleva v a (0, 1) */
    for (int k = 0; k < iters; k++) v = 3.7 * v * (1.0 - v);
    return v;
}

/* B — versión secuencial (sin OpenMP) y versión paralela: el mismo cuerpo. */
static void transform_seq(const double *x, double *z, long n, int iters)
{
    for (long i = 0; i < n; i++) z[i] = transform_one(x[i], iters);
}

static void transform_par(const double *x, double *z, long n, int iters)
{
    #pragma omp parallel for schedule(static)
    for (long i = 0; i < n; i++) z[i] = transform_one(x[i], iters);
}

/* C — suavizado secuencial (y[i] depende de y[i-1]) y suma de control. */
static double smooth_and_sum(const double *z, double *y, long n)
{
    double acc = 0.0;
    y[0] = z[0];
    for (long i = 1; i < n; i++) {
        y[i] = 0.9 * y[i - 1] + 0.1 * z[i];
        acc += y[i];
    }
    return acc;
}

/* Corre A, B y C una vez; devuelve los tiempos de cada sección y la suma de control. */
static double run_pipeline(double *x, double *z, double *y, long n, int iters, int parallel, double t[3])
{
    double t0 = now();
    generate(x, n);
    t[0] = now() - t0;

    t0 = now();
    if (parallel) transform_par(x, z, n, iters); else transform_seq(x, z, n, iters);
    t[1] = now() - t0;

    t0 = now();
    double s = smooth_and_sum(z, y, n);
    t[2] = now() - t0;
    return s;
}

int main(int argc, char **argv)
{
    long n = argc > 1 ? atol(argv[1]) : DEFAULT_N;
    int iters = argc > 2 ? atoi(argv[2]) : DEFAULT_ITERS;
    const char *csv = argc > 3 ? argv[3] : NULL;
    if (n < 2 || iters < 1) { fprintf(stderr, "Uso: %s [n >= 2] [iters >= 1] [archivo.csv]\n", argv[0]); return 2; }

    double *x = malloc((size_t)n * sizeof(double));
    double *z = malloc((size_t)n * sizeof(double));
    double *y = malloc((size_t)n * sizeof(double));
    if (!x || !z || !y) { fprintf(stderr, "Sin memoria\n"); return 1; }

    int p = omp_get_max_threads();
    const char *name[3] = {"A generar (secuencial)", "B transformar", "C suavizar+sumar (secuencial)"};
    double sec[N_REPS][3], par[N_REPS][3], tot_seq[N_REPS], tot_par[N_REPS], t[3];
    double sum_seq = 0.0, sum_par = 0.0;

    /* 1) Perfil secuencial: cada sección por separado, protocolo completo. */
    for (int r = -1; r < N_REPS; r++) {
        sum_seq = run_pipeline(x, z, y, n, iters, 0, t);
        if (r >= 0) { for (int s = 0; s < 3; s++) sec[r][s] = t[s]; tot_seq[r] = t[0] + t[1] + t[2]; }
    }
    double med_sec[3], med_tot_seq = median_of(tot_seq, N_REPS);
    for (int s = 0; s < 3; s++) {
        double col[N_REPS];
        for (int r = 0; r < N_REPS; r++) col[r] = sec[r][s];
        med_sec[s] = median_of(col, N_REPS);
    }
    double f_measured = (med_sec[0] + med_sec[2]) / med_tot_seq;

    printf("== perfil secuencial: n=%ld iters=%d  (mediana de %d repeticiones tras 1 calentamiento)\n",
           n, iters, N_REPS);
    printf("  %-32s %10s %8s\n", "seccion", "tiempo (s)", "fraccion");
    for (int s = 0; s < 3; s++)
        printf("  %-32s %10.4f %7.1f%%\n", name[s], med_sec[s], 100.0 * med_sec[s] / med_tot_seq);
    printf("  %-32s %10.4f %7.1f%%\n", "total", med_tot_seq, 100.0);
    printf("  fraccion secuencial medida f = (A + C) / total = %.3f\n", f_measured);
    printf("  Amdahl con f medida: S(2)=%.2f  S(4)=%.2f  S(8)=%.2f  S(inf)=%.2f\n",
           1.0 / (f_measured + (1.0 - f_measured) / 2), 1.0 / (f_measured + (1.0 - f_measured) / 4),
           1.0 / (f_measured + (1.0 - f_measured) / 8), 1.0 / f_measured);
    if (p == 1) csv_append(csv, "secuencial", 1, n, tot_seq, med_tot_seq, med_tot_seq);

    /* 2) Versión paralela (solo B cambia). clock() se mide aparte para compararlo con el reloj de pared. */
    clock_t c0 = clock();
    double w0 = now();
    for (int r = -1; r < N_REPS; r++) {
        sum_par = run_pipeline(x, z, y, n, iters, 1, t);
        if (r >= 0) { for (int s = 0; s < 3; s++) par[r][s] = t[s]; tot_par[r] = t[0] + t[1] + t[2]; }
    }
    double wall = now() - w0;
    double cpu = (double)(clock() - c0) / CLOCKS_PER_SEC;

    double colB[N_REPS];
    for (int r = 0; r < N_REPS; r++) colB[r] = par[r][1];
    double med_B_par = median_of(colB, N_REPS);
    double med_tot_par = median_of(tot_par, N_REPS);
    double S_total = med_tot_seq / med_tot_par;
    double S_B = med_sec[1] / med_B_par;
    int ok = close_enough(sum_seq, sum_par, 1e-9);

    printf("\n== con %d hilos (solo la seccion B es paralela)\n", p);
    printf("  B transformar: %.4f s -> %.4f s   speedup de B = %.2f  eficiencia de B = %.2f\n",
           med_sec[1], med_B_par, S_B, S_B / p);
    printf("  total:         %.4f s -> %.4f s   speedup total = %.2f  eficiencia total = %.2f\n",
           med_tot_seq, med_tot_par, S_total, S_total / p);
    printf("  Amdahl predijo S(%d) = %.2f con f = %.3f;  Karp-Flatt con el speedup total medido: f = %.3f\n",
           p, 1.0 / (f_measured + (1.0 - f_measured) / p), f_measured, karp_flatt(S_total, p));
    printf("  reloj de pared (omp_get_wtime) de las %d corridas paralelas: %.3f s;  clock() en el mismo lapso: %.3f s"
           "  (clock() suma la CPU de los %d hilos)\n", N_REPS + 1, wall, cpu, p);
    printf("  suma de control: secuencial=%.6f paralela=%.6f  %s\n", sum_seq, sum_par, ok ? "coinciden" : "DIFIEREN");
    report_row("total", p, n, tot_par, med_tot_seq, ok);
    report_row("seccionB", p, n, colB, med_sec[1], ok);
    csv_append(csv, "total", p, n, tot_par, med_tot_par, med_tot_seq);
    csv_append(csv, "seccionB", p, n, colB, med_B_par, med_sec[1]);

    free(x); free(z); free(y);
    return ok ? 0 : 1;
}
