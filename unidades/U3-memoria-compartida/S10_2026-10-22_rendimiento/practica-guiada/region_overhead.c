/*
 * region_overhead.c — Sobrecarga de abrir una región paralela dentro de un ciclo
 * frente a abrir UNA región y repartir el ciclo interno con `omp for`.
 *
 * El trabajo es un suavizado repetido k veces sobre un arreglo de n elementos:
 *     y[i] = a*y[i] + b      (cada elemento es independiente de los demás)
 *
 * Cuatro versiones con el MISMO resultado:
 *   secuencial   dos ciclos anidados, sin OpenMP
 *   regiones     `parallel for` dentro del ciclo externo: k regiones paralelas
 *   una-region   una región; el ciclo externo lo recorren todos los hilos; `omp for` reparte el interno:
 *                1 región, k barreras implícitas
 *   sin-barrera  igual, con `schedule(static) nowait`: 1 región, 0 barreras. Es correcto porque con
 *                schedule(static) (mismo n, mismo chunk, mismos hilos) cada hilo recibe las MISMAS
 *                iteraciones en cada pasada, así que nadie lee lo que otro escribió (OpenMP 5.2,
 *                worksharing-loop construct, garantía de schedule(static)).
 *
 * Uso: ./region_overhead [n] [k]    (por defecto n = 2000, k = 20000: trabajo pequeño por región)
 *      Con n grande y k pequeño (p. ej. 2000000 20) el panorama cambia: compara ambos.
 */
#include "common.h"

#define DEFAULT_N 2000L
#define DEFAULT_K 20000
#define A_COEF 0.999
#define B_COEF 0.001

static void init(double *y, long n) { for (long i = 0; i < n; i++) y[i] = (double)(i % 97) / 97.0; }

static void seq(double *y, long n, int k)
{
    for (int it = 0; it < k; it++)
        for (long i = 0; i < n; i++) y[i] = A_COEF * y[i] + B_COEF;
}

static void regions(double *y, long n, int k)
{
    for (int it = 0; it < k; it++) {
        #pragma omp parallel for            /* abre y cierra una región en cada vuelta */
        for (long i = 0; i < n; i++) y[i] = A_COEF * y[i] + B_COEF;
    }
}

static void one_region(double *y, long n, int k)
{
    #pragma omp parallel                    /* una sola región */
    for (int it = 0; it < k; it++) {        /* todos los hilos recorren el ciclo externo */
        #pragma omp for                     /* reparto del interno + barrera implícita */
        for (long i = 0; i < n; i++) y[i] = A_COEF * y[i] + B_COEF;
    }
}

static void no_barrier(double *y, long n, int k)
{
    #pragma omp parallel
    for (int it = 0; it < k; it++) {
        #pragma omp for schedule(static) nowait   /* mismas iteraciones para cada hilo en cada vuelta */
        for (long i = 0; i < n; i++) y[i] = A_COEF * y[i] + B_COEF;
    }
}

static int same(const double *a, const double *b, long n)
{
    for (long i = 0; i < n; i++) if (!close_enough(a[i], b[i], 1e-12)) return 0;
    return 1;
}

int main(int argc, char **argv)
{
    long n = argc > 1 ? atol(argv[1]) : DEFAULT_N;
    int k = argc > 2 ? atoi(argv[2]) : DEFAULT_K;
    if (n <= 0 || k <= 0) { fprintf(stderr, "Uso: %s [n > 0] [k > 0]\n", argv[0]); return 2; }

    double *y = malloc((size_t)n * sizeof(double));
    double *ref = malloc((size_t)n * sizeof(double));
    if (!y || !ref) { fprintf(stderr, "Sin memoria\n"); return 1; }
    int p = omp_get_max_threads();
    double times[N_REPS], med[4];
    const char *names[4] = {"secuencial", "regiones", "una-region", "sin-barrera"};
    int all_ok = 1;

    printf("== sobrecarga de regiones: n=%ld elementos, k=%d pasadas, hilos=%d  (%ld operaciones en total)\n",
           n, k, p, n * (long)k);
    for (int v = 0; v < 4; v++) {
        for (int r = -1; r < N_REPS; r++) {
            init(y, n);                             /* mismo punto de partida en cada repetición */
            double t0 = now();
            if (v == 0) seq(y, n, k);
            else if (v == 1) regions(y, n, k);
            else if (v == 2) one_region(y, n, k);
            else no_barrier(y, n, k);
            double t = now() - t0;
            if (r >= 0) times[r] = t;
        }
        med[v] = median_of(times, N_REPS);
        if (v == 0) {
            memcpy(ref, y, (size_t)n * sizeof(double));
            printf("  %-12s hilos=1  mediana=%.4f s  (min %.4f, max %.4f)\n", names[0], med[0],
                   min_of(times, N_REPS), max_of(times, N_REPS));
        } else {
            int ok = same(ref, y, n);
            all_ok = all_ok && ok;
            report_row(names[v], p, n, times, med[0], ok);
        }
    }
    /* Estimación del costo unitario: la diferencia entre versiones dividida entre las k pasadas.
     * Solo tiene sentido con muchas pasadas cortas; con k pequeño el ruido de una pasada domina. */
    if (k >= 1000)
        printf("  costo estimado por pasada: region paralela ~ %.1f us, barrera ~ %.1f us  "
               "(diferencias contra sin-barrera, entre k=%d)\n",
               1e6 * (med[1] - med[3]) / k, 1e6 * (med[2] - med[3]) / k, k);
    else
        printf("  (estimacion por pasada omitida: con k=%d el ruido de una pasada domina; usa k >= 1000)\n", k);
    free(y); free(ref);
    return all_ok ? 0 : 1;
}
