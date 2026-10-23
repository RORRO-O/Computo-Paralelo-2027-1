#define _POSIX_C_SOURCE 200809L /* clock_gettime con -std=c11 (debe ir antes de cualquier include) */
/*
 * a2_stats_seq.c — Parte A.2: estadísticos de un arreglo en UN proceso (referencia secuencial).
 *
 * Calcula suma, máximo, promedio y varianza de n datos deterministas (p5_value). Es el T(1) del
 * protocolo y la referencia de correctitud contra la que se compara a2_stats_mpi.
 *
 * Uso:      ./a2_stats_seq [n] [reps]          (por defecto n = 10 000 003, reps = 3)
 * Salida:   líneas legibles + una línea TIME,... (tiempos) + una línea RESULT,... (valores) para tests/.
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra -o a2_stats_seq a2_stats_seq.c -lm
 */
#include "common.h"

int main(int argc, char **argv)
{
    long long n = p5_arg_ll(argc, argv, 0, 10000003LL);
    int reps = p5_clamp_reps(p5_arg_ll(argc, argv, 1, 3));
    if (n <= 0) {
        fprintf(stderr, "Uso: %s [n > 0] [reps]\n", argv[0]);
        return 1;
    }

    double *data = p5_alloc(n);
    for (long long i = 0; i < n; i++) data[i] = p5_value(i);

    double sum = 0.0, max = 0.0, mean = 0.0, var = 0.0, t[P5_MAX_REPS];
    for (int r = -1; r < reps; r++) { /* r = -1: calentamiento, no se cuenta */
        double t0 = p5_wtime();

        /* Pasada 1: suma y máximo. El orden de la suma es i = 0, 1, 2, ... */
        sum = data[0];
        max = data[0];
        for (long long i = 1; i < n; i++) {
            sum += data[i];
            if (data[i] > max) max = data[i];
        }
        mean = sum / (double)n;
        /* Pasada 2: varianza poblacional alrededor del promedio. */
        double sq = 0.0;
        for (long long i = 0; i < n; i++) {
            double d = data[i] - mean;
            sq += d * d;
        }
        var = sq / (double)n;

        if (r >= 0) t[r] = p5_wtime() - t0;
    }

    printf("a2_stats_seq: n=%lld reps=%d\n", n, reps);
    printf("suma=%.12e max=%.12e promedio=%.12e varianza=%.12e\n", sum, max, mean, var);
    p5_print_time_human("dos pasadas sobre el arreglo", t, reps);
    p5_print_time_line(t, reps);
    printf("RESULT,a2_stats_seq,1,%lld,seq,%.12e,%.12e,%.12e,%.12e,%.6f\n",
           n, sum, max, mean, var, p5_time_stats(t, reps).median);

    free(data);
    return 0;
}
