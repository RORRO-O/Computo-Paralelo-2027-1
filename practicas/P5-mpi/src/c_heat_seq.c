#define _POSIX_C_SOURCE 200809L /* clock_gettime con -std=c11 (debe ir antes de cualquier include) */
/*
 * c_heat_seq.c — Parte C: ecuación de calor 1D en UN proceso (referencia secuencial).
 *
 * El problema, el esquema y el criterio de paro están en c_heat_common.h (los comparte con la
 * versión MPI). Este programa es el T(1) del protocolo y la referencia de correctitud.
 *
 * Uso: ./c_heat_seq [n] [max_iter] [tol] [check_every] [reps] [--print]
 *      por defecto n = 1 000 000, max_iter = 500, tol = 0 (corre exactamente max_iter pasos),
 *      check_every = 1, reps = 3. --print imprime el perfil final (úsalo con n pequeño).
 * Salida: iteraciones, convergio, checksum, dos sondas (u en el centro y en n/4), t_c en ns por
 *         celda-paso (lo usa el modelo de costo de la Parte D), líneas TIME,... y RESULT,...
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra -o c_heat_seq c_heat_seq.c -lm
 */
#include "c_heat_common.h"

int main(int argc, char **argv)
{
    long long n = p5_arg_ll(argc, argv, 0, 1000000LL);
    long long max_iter = p5_arg_ll(argc, argv, 1, 500);
    double tol = p5_arg_double(argc, argv, 2, 0.0);
    long long check_every = p5_arg_ll(argc, argv, 3, 1);
    int reps = p5_clamp_reps(p5_arg_ll(argc, argv, 4, 3));
    int print = p5_has_flag(argc, argv, "--print");
    if (n <= 0 || max_iter <= 0 || tol < 0 || check_every <= 0) {
        fprintf(stderr, "Uso: %s [n > 0] [max_iter > 0] [tol >= 0] [check_every > 0] [reps] [--print]\n", argv[0]);
        return 1;
    }

    double *u = p5_alloc(n + 2), *u_new = p5_alloc(n + 2);
    long long iters = 0;
    int converged = 0;
    double last_diff = 0.0, t[P5_MAX_REPS];
    for (int r = -1; r < reps; r++) { /* r = -1: calentamiento */
        heat_init_full(u, u_new, n);   /* la condición inicial se repone en cada repetición */
        double t0 = p5_wtime();
        iters = heat_solve_seq(u, u_new, n, max_iter, tol, check_every, &converged, &last_diff);
        if (r >= 0) t[r] = p5_wtime() - t0;
    }

    p5_stats s = p5_time_stats(t, reps);
    double checksum = heat_checksum(u + 1, n);
    double u_center = u[1 + n / 2], u_quarter = u[1 + n / 4];
    printf("c_heat_seq: n=%lld max_iter=%lld tol=%g check_every=%lld reps=%d\n", n, max_iter, tol, check_every, reps);
    printf("iteraciones=%lld convergio=%d diff_final=%.3e\n", iters, converged, last_diff);
    printf("checksum=%.12e u[centro]=%.12e u[n/4]=%.12e\n", checksum, u_center, u_quarter);
    printf("t_c=%.3f ns por celda-paso\n", 1e9 * s.median / ((double)n * (double)iters));
    p5_print_time_human("pasos de tiempo", t, reps);
    p5_print_time_line(t, reps);
    printf("RESULT,c_heat_seq,1,%lld,%lld,%lld,%d,%.12e,%.12e,%.12e,%.6f\n",
           n, max_iter, iters, converged, checksum, u_center, u_quarter, s.median);
    if (print) heat_print_profile(u + 1, n);

    free(u);
    free(u_new);
    return 0;
}
