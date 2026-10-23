/*
 * saxpy_vs_matmul.c — Dos núcleos que escalan distinto con los mismos hilos:
 *
 *   saxpy    y[i] = a*x[i] + y[i]        2 flop por 24 bytes movidos: limitado por MEMORIA
 *   matmul   C = A*B (orden i-k-j)        2n^3 flop sobre 3n^2 doubles: limitado por CÓMPUTO
 *
 * Mide ambos con el protocolo (calentamiento + 5 repeticiones, mediana), con la
 * referencia secuencial en el mismo proceso, e imprime speedup, eficiencia y el
 * rendimiento alcanzado (GB/s para saxpy, GFLOP/s para matmul).
 *
 * Uso: ./saxpy_vs_matmul [n_saxpy] [n_matmul] [archivo.csv]
 *      (por defecto 10 000 000 elementos y matrices de 640 x 640)
 *      saxpy hace varias pasadas completas dentro de la región cronometrada (100 000 000 / n,
 *      para que el trabajo total no dependa de n); con n = 10 000 000 los arreglos (2 x 80 MB)
 *      exceden la caché de una laptop. Si tu máquina tiene una L3 muy grande, sube n.
 */
#include "common.h"

#define DEFAULT_N_SAXPY 10000000L
#define DEFAULT_N_MATMUL 640L
#define WORK_SAXPY 100000000L      /* elementos procesados por repeticion: pasadas = WORK_SAXPY / n */
#define ALPHA 1.0000001

static int passes_for(long n) { long p = WORK_SAXPY / n; return p < 1 ? 1 : (int)p; }

/* --- saxpy ------------------------------------------------------------------ */
static void saxpy_seq(const double *x, double *y, long n, int passes)
{
    for (int pass = 0; pass < passes; pass++)
        for (long i = 0; i < n; i++) y[i] = ALPHA * x[i] + y[i];
}

static void saxpy_par(const double *x, double *y, long n, int passes)
{
    for (int pass = 0; pass < passes; pass++) {
        #pragma omp parallel for schedule(static)
        for (long i = 0; i < n; i++) y[i] = ALPHA * x[i] + y[i];
    }
}

/* --- matmul (i-k-j: el ciclo interno recorre filas contiguas de B y C) ----------- */
static void matmul_seq(const double *A, const double *B, double *C, long n)
{
    for (long i = 0; i < n; i++) {
        for (long j = 0; j < n; j++) C[i * n + j] = 0.0;
        for (long k = 0; k < n; k++) {
            double aik = A[i * n + k];
            for (long j = 0; j < n; j++) C[i * n + j] += aik * B[k * n + j];
        }
    }
}

static void matmul_par(const double *A, const double *B, double *C, long n)
{
    #pragma omp parallel for schedule(static)      /* cada hilo calcula filas completas de C */
    for (long i = 0; i < n; i++) {
        for (long j = 0; j < n; j++) C[i * n + j] = 0.0;
        for (long k = 0; k < n; k++) {
            double aik = A[i * n + k];
            for (long j = 0; j < n; j++) C[i * n + j] += aik * B[k * n + j];
        }
    }
}

static int same(const double *a, const double *b, long n)
{
    for (long i = 0; i < n; i++) if (!close_enough(a[i], b[i], 1e-9)) return 0;
    return 1;
}

int main(int argc, char **argv)
{
    long ns = argc > 1 ? atol(argv[1]) : DEFAULT_N_SAXPY;
    long nm = argc > 2 ? atol(argv[2]) : DEFAULT_N_MATMUL;
    const char *csv = argc > 3 ? argv[3] : NULL;
    if (ns <= 0 || nm <= 0) { fprintf(stderr, "Uso: %s [n_saxpy > 0] [n_matmul > 0] [archivo.csv]\n", argv[0]); return 2; }
    int p = omp_get_max_threads();
    double times[N_REPS];
    int all_ok = 1;

    /* ---------- saxpy ---------- */
    double *x = malloc((size_t)ns * sizeof(double));
    double *y0 = malloc((size_t)ns * sizeof(double));
    double *y = malloc((size_t)ns * sizeof(double));
    double *yref = malloc((size_t)ns * sizeof(double));
    if (!x || !y0 || !y || !yref) { fprintf(stderr, "Sin memoria\n"); return 1; }
    unsigned st = 7u;
    for (long i = 0; i < ns; i++) { x[i] = lcg_next(&st); y0[i] = lcg_next(&st); }
    int passes = passes_for(ns);

    for (int r = -1; r < N_REPS; r++) {
        memcpy(y, y0, (size_t)ns * sizeof(double));   /* fuera del cronómetro */
        double t0 = now();
        saxpy_seq(x, y, ns, passes);
        double t = now() - t0;
        if (r >= 0) times[r] = t;
    }
    memcpy(yref, y, (size_t)ns * sizeof(double));
    double t_saxpy_seq = median_of(times, N_REPS);
    double bytes = 24.0 * (double)ns * passes;     /* por elemento y pasada: lee x, lee y, escribe y */
    printf("== saxpy: n=%ld (%d pasadas, %.0f MB por arreglo)  hilos=%d\n", ns, passes,
           (double)ns * sizeof(double) / 1e6, p);
    printf("  %-12s hilos=1  mediana=%.4f s  -> %.1f GB/s\n", "secuencial", t_saxpy_seq, bytes / t_saxpy_seq / 1e9);
    if (p == 1) csv_append(csv, "saxpy-seq", 1, ns, times, t_saxpy_seq, t_saxpy_seq);

    for (int r = -1; r < N_REPS; r++) {
        memcpy(y, y0, (size_t)ns * sizeof(double));
        double t0 = now();
        saxpy_par(x, y, ns, passes);
        double t = now() - t0;
        if (r >= 0) times[r] = t;
    }
    int ok = same(yref, y, ns);
    all_ok = all_ok && ok;
    double t_saxpy_par = median_of(times, N_REPS);
    report_row("saxpy", p, ns, times, t_saxpy_seq, ok);
    printf("  ancho de banda alcanzado con %d hilos: %.1f GB/s  (intensidad aritmetica: %.3f flop/byte)\n",
           p, bytes / t_saxpy_par / 1e9, 2.0 / 24.0);
    csv_append(csv, "saxpy", p, ns, times, t_saxpy_par, t_saxpy_seq);
    free(x); free(y0); free(y); free(yref);

    /* ---------- matmul ---------- */
    double *A = malloc((size_t)(nm * nm) * sizeof(double));
    double *B = malloc((size_t)(nm * nm) * sizeof(double));
    double *C = malloc((size_t)(nm * nm) * sizeof(double));
    double *Cref = malloc((size_t)(nm * nm) * sizeof(double));
    if (!A || !B || !C || !Cref) { fprintf(stderr, "Sin memoria\n"); return 1; }
    for (long i = 0; i < nm * nm; i++) { A[i] = lcg_next(&st); B[i] = lcg_next(&st); }

    for (int r = -1; r < N_REPS; r++) {
        double t0 = now();
        matmul_seq(A, B, C, nm);
        double t = now() - t0;
        if (r >= 0) times[r] = t;
    }
    memcpy(Cref, C, (size_t)(nm * nm) * sizeof(double));
    double t_mm_seq = median_of(times, N_REPS);
    double flops = 2.0 * (double)nm * (double)nm * (double)nm;
    printf("== matmul: %ld x %ld (%.0f Mflop, %.1f MB las tres matrices)  hilos=%d\n", nm, nm, flops / 1e6,
           3.0 * (double)(nm * nm) * sizeof(double) / 1e6, p);
    printf("  %-12s hilos=1  mediana=%.4f s  -> %.2f GFLOP/s\n", "secuencial", t_mm_seq, flops / t_mm_seq / 1e9);
    if (p == 1) csv_append(csv, "matmul-seq", 1, nm, times, t_mm_seq, t_mm_seq);

    for (int r = -1; r < N_REPS; r++) {
        double t0 = now();
        matmul_par(A, B, C, nm);
        double t = now() - t0;
        if (r >= 0) times[r] = t;
    }
    ok = same(Cref, C, nm * nm);
    all_ok = all_ok && ok;
    double t_mm_par = median_of(times, N_REPS);
    report_row("matmul", p, nm, times, t_mm_seq, ok);
    printf("  rendimiento con %d hilos: %.2f GFLOP/s  (intensidad aritmetica sobre los datos: %.1f flop/byte)\n",
           p, flops / t_mm_par / 1e9, flops / (3.0 * (double)(nm * nm) * sizeof(double)));
    csv_append(csv, "matmul", p, nm, times, t_mm_par, t_mm_seq);
    free(A); free(B); free(C); free(Cref);
    return all_ok ? 0 : 1;
}
