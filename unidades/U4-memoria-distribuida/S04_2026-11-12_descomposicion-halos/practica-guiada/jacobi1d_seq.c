/*
 * jacobi1d_seq.c — Jacobi 1D secuencial para la ecuación de calor estacionaria.
 *
 * Es la VERSIÓN DE REFERENCIA: la versión MPI debe reportar las mismas iteraciones y los
 * mismos valores (con tolerancia de punto flotante).
 *
 * Malla: u[0] = T_LEFT y u[n+1] = T_RIGHT son fronteras fijas (condición de Dirichlet);
 *        u[1..n] son las celdas que se calculan. Valor inicial del interior: 0.
 * Paso de Jacobi: u_new[i] = 0.5 * (u[i-1] + u[i+1])   (doble búfer, como en U3-S11).
 * Paro: max_i |u_new[i] - u[i]| < tol, o bien max_iter iteraciones.
 *
 * Uso:      ./jacobi1d_seq [n] [tol] [max_iter] [--print]
 * Compila:  gcc -std=c11 -O2 -Wall -Wextra -o jacobi1d_seq jacobi1d_seq.c -lm
 */
#define _POSIX_C_SOURCE 200809L   /* clock_gettime con -std=c11 */
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define T_LEFT  100.0   /* temperatura fija en la frontera izquierda (celda 0)   */
#define T_RIGHT   0.0   /* temperatura fija en la frontera derecha (celda n+1)   */

static double wall_time(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + 1e-9 * (double)ts.tv_nsec;
}

int main(int argc, char **argv) {
    /* Valores por defecto: la versión secuencial tarda ~1 s en una laptop de 4 núcleos. */
    int    n        = 1000000;
    double tol      = 1e-6;
    int    max_iter = 1000;
    int    print    = 0;

    /* Argumentos posicionales: n tol max_iter. Bandera: --print (imprime todas las celdas). */
    int pos = 0;
    for (int a = 1; a < argc; a++) {
        if (strcmp(argv[a], "--print") == 0) { print = 1; continue; }
        if (pos == 0)      n        = (int)strtol(argv[a], NULL, 10);
        else if (pos == 1) tol      = strtod(argv[a], NULL);
        else if (pos == 2) max_iter = (int)strtol(argv[a], NULL, 10);
        pos++;
    }
    if (n < 1 || tol <= 0.0 || max_iter < 1) {
        fprintf(stderr, "uso: %s [n>=1] [tol>0] [max_iter>=1] [--print]\n", argv[0]);
        return 1;
    }

    /* n celdas interiores + 2 fronteras. calloc deja el interior en 0. */
    double *u     = calloc((size_t)n + 2, sizeof *u);
    double *u_new = calloc((size_t)n + 2, sizeof *u_new);
    if (!u || !u_new) { fprintf(stderr, "sin memoria\n"); return 1; }

    /* Las fronteras viven en AMBOS arreglos: así el intercambio de punteros no las pierde. */
    u[0] = u_new[0] = T_LEFT;
    u[n + 1] = u_new[n + 1] = T_RIGHT;

    double t0 = wall_time();
    int    iter = 0, converged = 0;
    double diff = 0.0;
    for (iter = 1; iter <= max_iter; iter++) {
        diff = 0.0;
        for (int i = 1; i <= n; i++) {
            u_new[i] = 0.5 * (u[i - 1] + u[i + 1]);
            double d = fabs(u_new[i] - u[i]);
            if (d > diff) diff = d;
        }
        double *tmp = u; u = u_new; u_new = tmp;   /* doble búfer: intercambio de punteros */
        if (diff < tol) { converged = 1; break; }
    }
    if (!converged) iter = max_iter;               /* el for terminó por el límite de iteraciones */
    double elapsed = wall_time() - t0;

    double checksum = 0.0;
    for (int i = 1; i <= n; i++) checksum += u[i];

    printf("n=%d tol=%.3e max_iter=%d p=1\n", n, tol, max_iter);
    printf("iteraciones=%d convergio=%d\n", iter, converged);
    printf("diff_final=%.6e\n", diff);
    printf("checksum=%.12e\n", checksum);
    printf("tiempo_s=%.6f\n", elapsed);
    if (print)
        for (int i = 1; i <= n; i++) printf("%d %.15e\n", i, u[i]);   /* índice global, valor */

    free(u);
    free(u_new);
    return 0;
}
