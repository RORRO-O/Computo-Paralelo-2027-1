/*
 * ejemplo_perfil.c — ¿Dónde está el punto caliente? (código del ejemplo resuelto de S12)
 *
 *   Fase 1 · carga:    n puntos (x, y) pseudoaleatorios en [0,1)².                     O(n)
 *   Fase 2 · cómputo:  por punto, seis rasgos derivados (radio, ángulo, cuadrante,
 *                      distancia al centro, anillo, peso gaussiano).  Muchas líneas.    O(n)
 *   Fase 3 · resumen:  cuenta los pares a distancia < R entre los primeros m puntos
 *                      (una verificación "para el reporte").          Pocas líneas.    O(m²)
 *
 * El programa cronometra cada fase con omp_get_wtime() y permite paralelizar una u otra
 * para comprobar la predicción de Amdahl hecha a partir del perfil.
 *
 * Uso:      ./ejemplo_perfil [n] [m] [modo] [plan]
 *             modo: seq | computo | resumen | ambas    (qué fase corre en paralelo)
 *             plan: dynamic | static                   (planificación del ciclo del resumen)
 *           hilos: variable de entorno OMP_NUM_THREADS
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra -fopenmp ejemplo_perfil.c -o ejemplo_perfil -lm
 */
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>

#define RADIUS 0.01   /* dos puntos son "cercanos" si su distancia es menor que RADIUS */

static unsigned long long lcg_next(unsigned long long *state)
{
    *state = *state * 6364136223846793005ULL + 1442695040888963407ULL;
    return *state;
}

/* Fase 1 · carga: n puntos en el cuadrado unitario. */
static void load_phase(double *px, double *py, long n)
{
    unsigned long long state = 6061ULL;
    for (long i = 0; i < n; i++) {
        px[i] = (double)(lcg_next(&state) >> 11) / 9007199254740992.0;
        py[i] = (double)(lcg_next(&state) >> 11) / 9007199254740992.0;
    }
}

/* Fase 2 · cómputo: seis rasgos por punto. Las iteraciones son independientes salvo por
 * `sum_w`, que es una reducción. `parallel` decide si el ciclo corre en paralelo:
 * la cláusula if(0) crea un equipo de UN hilo, es decir, el ciclo corre como secuencial. */
static double compute_phase(const double *px, const double *py, double *radius, double *angle,
                            double *weight, int *ring, long n, int parallel)
{
    double sum_w = 0.0;
    #pragma omp parallel for if(parallel) reduction(+:sum_w)
    for (long i = 0; i < n; i++) {
        double x = px[i], y = py[i];
        double r = sqrt(x * x + y * y);               /* radio desde el origen */
        double th = atan2(y, x);                      /* ángulo */
        int quadrant = (x >= 0.5 ? 1 : 0) + (y >= 0.5 ? 2 : 0);
        double dx = x - 0.5, dy = y - 0.5;
        double d_center = sqrt(dx * dx + dy * dy);    /* distancia al centro */
        int ring_id = (int)(d_center * 10.0);         /* anillo concéntrico */
        double w = exp(-4.0 * d_center * d_center);   /* peso gaussiano */
        if (quadrant == 3) w *= 0.5;                  /* penaliza el cuadrante superior derecho */
        radius[i] = r;
        angle[i]  = th;
        weight[i] = w;
        ring[i]   = ring_id;
        sum_w += w;
    }
    return sum_w;
}

/* Fase 3 · resumen: pares (i, j) con i < j < m a distancia menor que RADIUS.
 * El ciclo es triangular: la iteración i hace m-i-1 comparaciones, por eso el trabajo es
 * desigual y la planificación importa. schedule(runtime) toma la que fijó omp_set_schedule. */
static long summary_phase(const double *px, const double *py, long m, int parallel)
{
    const double r2 = RADIUS * RADIUS;
    long count = 0;
    #pragma omp parallel for if(parallel) reduction(+:count) schedule(runtime)
    for (long i = 0; i < m; i++) {
        double xi = px[i], yi = py[i];
        for (long j = i + 1; j < m; j++) {
            double dx = px[j] - xi, dy = py[j] - yi;
            if (dx * dx + dy * dy < r2) count++;
        }
    }
    return count;
}

int main(int argc, char **argv)
{
    long n = (argc > 1) ? atol(argv[1]) : 1000000L;
    long m = (argc > 2) ? atol(argv[2]) : 24000L;
    const char *mode = (argc > 3) ? argv[3] : "seq";
    const char *plan = (argc > 4) ? argv[4] : "dynamic";

    if (n <= 0 || m <= 0 || m > n) {
        fprintf(stderr, "uso: %s [n > 0] [0 < m <= n] [seq|computo|resumen|ambas] [dynamic|static]\n", argv[0]);
        return 1;
    }
    int par_compute = (strcmp(mode, "computo") == 0 || strcmp(mode, "ambas") == 0);
    int par_summary = (strcmp(mode, "resumen") == 0 || strcmp(mode, "ambas") == 0);
    if (!par_compute && !par_summary && strcmp(mode, "seq") != 0) {
        fprintf(stderr, "modo desconocido: %s\n", mode);
        return 1;
    }
    if (strcmp(plan, "static") == 0)        omp_set_schedule(omp_sched_static, 0);
    else if (strcmp(plan, "dynamic") == 0)  omp_set_schedule(omp_sched_dynamic, 64);
    else { fprintf(stderr, "plan desconocido: %s\n", plan); return 1; }

    double *px = malloc((size_t)n * sizeof *px), *py = malloc((size_t)n * sizeof *py);
    double *radius = malloc((size_t)n * sizeof *radius), *angle = malloc((size_t)n * sizeof *angle);
    double *weight = malloc((size_t)n * sizeof *weight);
    int *ring = malloc((size_t)n * sizeof *ring);
    if (!px || !py || !radius || !angle || !weight || !ring) { fputs("error: sin memoria\n", stderr); return 1; }

    /* Calentamiento: crea el equipo de hilos antes de arrancar el reloj (protocolo §2). */
    #pragma omp parallel
    { (void)omp_get_thread_num(); }

    double t0 = omp_get_wtime();
    load_phase(px, py, n);
    double t1 = omp_get_wtime();
    double sum_w = compute_phase(px, py, radius, angle, weight, ring, n, par_compute);
    double t2 = omp_get_wtime();
    long close_pairs = summary_phase(px, py, m, par_summary);
    double t3 = omp_get_wtime();

    double t_load = t1 - t0, t_compute = t2 - t1, t_summary = t3 - t2, t_total = t3 - t0;

    printf("suma_pesos=%.12e\n", sum_w);
    printf("pares_cercanos=%ld\n", close_pairs);
    printf("ejemplo_perfil n=%ld m=%ld modo=%s plan=%s hilos_max=%d\n",
           n, m, mode, plan, omp_get_max_threads());
    printf("%-9s %10s %9s\n", "fase", "tiempo_s", "fraccion");
    printf("%-9s %10.4f %9.3f\n", "carga",   t_load,    t_load    / t_total);
    printf("%-9s %10.4f %9.3f\n", "computo", t_compute, t_compute / t_total);
    printf("%-9s %10.4f %9.3f\n", "resumen", t_summary, t_summary / t_total);
    printf("%-9s %10.4f %9.3f\n", "total",   t_total,   1.0);

    free(px); free(py); free(radius); free(angle); free(weight); free(ring);
    return 0;
}
