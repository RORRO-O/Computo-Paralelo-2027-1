#define _POSIX_C_SOURCE 200809L /* clock_gettime con -std=c11 (debe ir antes de cualquier include) */
/*
 * b_matvec_seq.c — Parte B: producto matriz-vector y = A·x en UN proceso (referencia secuencial).
 *
 * A es de m filas por n columnas, guardada por filas (A[i*n + j]); x tiene n elementos; y tiene m.
 * El producto se repite `iters` veces con el mismo x (imita un método iterativo donde cada paso
 * necesita un producto; así T(1) llega a ≥ 1 s sin matrices gigantes). Datos deterministas (p5_value).
 *
 * Uso:      ./b_matvec_seq [m] [n] [iters] [reps]     (por defecto 2000 2000 200 3)
 * Salida:   checksum = suma de y, y[0], y[m-1]; líneas TIME,... y RESULT,...
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra -o b_matvec_seq b_matvec_seq.c -lm
 */
#include "common.h"

/* y[i] = sum_j A[i][j] * x[j] para las filas 0..rows-1 (mismo orden de suma en todas las versiones) */
static void matvec_rows(const double *A, const double *x, double *y, long long rows, long long n)
{
    for (long long i = 0; i < rows; i++) {
        double acc = 0.0;
        const double *row = A + i * n;
        for (long long j = 0; j < n; j++) acc += row[j] * x[j];
        y[i] = acc;
    }
}

int main(int argc, char **argv)
{
    long long m = p5_arg_ll(argc, argv, 0, 2000);
    long long n = p5_arg_ll(argc, argv, 1, 2000);
    long long iters = p5_arg_ll(argc, argv, 2, 200);
    int reps = p5_clamp_reps(p5_arg_ll(argc, argv, 3, 3));
    if (m <= 0 || n <= 0 || iters <= 0) {
        fprintf(stderr, "Uso: %s [m > 0] [n > 0] [iters > 0] [reps]\n", argv[0]);
        return 1;
    }

    double *A = p5_alloc(m * n), *x = p5_alloc(n), *y = p5_alloc(m);
    for (long long i = 0; i < m * n; i++) A[i] = p5_value(i);
    for (long long j = 0; j < n; j++) x[j] = p5_value(-(j + 1)); /* índices negativos: otra secuencia */

    double t[P5_MAX_REPS];
    for (int r = -1; r < reps; r++) { /* r = -1: calentamiento */
        double t0 = p5_wtime();
        for (long long it = 0; it < iters; it++) matvec_rows(A, x, y, m, n);
        if (r >= 0) t[r] = p5_wtime() - t0;
    }

    double checksum = 0.0;
    for (long long i = 0; i < m; i++) checksum += y[i];
    p5_stats s = p5_time_stats(t, reps);

    printf("b_matvec_seq: m=%lld n=%lld iters=%lld reps=%d\n", m, n, iters, reps);
    printf("checksum=%.12e y[0]=%.12e y[m-1]=%.12e\n", checksum, y[0], y[m - 1]);
    printf("%.3f ns por elemento de A por producto (%.2f GFLOP/s)\n",
           1e9 * s.median / ((double)m * (double)n * (double)iters),
           2.0 * (double)m * (double)n * (double)iters / s.median / 1e9);
    p5_print_time_human("iters productos", t, reps);
    p5_print_time_line(t, reps);
    printf("RESULT,b_matvec_seq,1,%lld,%lld,%lld,%.12e,%.12e,%.12e,%.6f\n",
           m, n, iters, checksum, y[0], y[m - 1], s.median);

    free(A);
    free(x);
    free(y);
    return 0;
}
