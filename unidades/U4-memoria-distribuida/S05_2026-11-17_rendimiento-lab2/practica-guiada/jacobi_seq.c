/*
 * jacobi_seq.c — Jacobi 1D secuencial. Es la referencia T(1) del protocolo
 * de medición ("el mejor programa secuencial disponible") y la referencia de
 * correctitud de las pruebas.
 *
 * Problema: n puntos u[1..n]; fronteras fijas u[0] = 0.0 y u[n+1] = 1.0.
 * Cada iteración: u_new[i] = 0.5 * (u[i-1] + u[i+1]). Doble búfer (como en S11).
 *
 * Uso: ./jacobi_seq [n] [iters] [reps]
 *   n      puntos del dominio (por defecto 1000000)
 *   iters  iteraciones de Jacobi (por defecto 500)
 *   reps   repeticiones medidas tras 1 de calentamiento (por defecto 5)
 *
 * Salida: una línea legible y una línea "RESULT,..." que lee escalado.sh:
 *   RESULT,p,n,iters,reps,t1;t2;...;tk,mediana,min,max,tcomp_it,tcomm_it,checksum,u_probe
 * u_probe es el valor del punto global n-3 (cerca de la frontera caliente; el
 * centro del dominio sigue en 0 si iters < n/2, porque el calor avanza una
 * celda por iteración).
 * (p = 1 y tcomm_it = 0 porque no hay comunicación).
 *
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra -o jacobi_seq jacobi_seq.c
 */
#define _POSIX_C_SOURCE 200809L /* para clock_gettime con -std=c11 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define MAX_REPS 32

/* Reloj monotónico en segundos (equivalente a MPI_Wtime sin MPI). */
static double now_s(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + 1e-9 * (double)ts.tv_nsec;
}

static int cmp_double(const void *a, const void *b)
{
    double x = *(const double *)a, y = *(const double *)b;
    return (x > y) - (x < y);
}

/* Estado inicial: todo en cero, fronteras en las celdas 0 y n+1. */
static void init_state(double *u, double *u_new, long n)
{
    memset(u, 0, (size_t)(n + 2) * sizeof(double));
    memset(u_new, 0, (size_t)(n + 2) * sizeof(double));
    u[0] = u_new[0] = 0.0;
    u[n + 1] = u_new[n + 1] = 1.0;
}

int main(int argc, char **argv)
{
    /* Búfer completo para stdout: toda la salida (incluida la línea RESULT que lee
     * escalado.sh) se escribe de una vez al terminar y no puede llegar partida. */
    static char out_buf[1 << 14];
    setvbuf(stdout, out_buf, _IOFBF, sizeof out_buf);
    long n = (argc > 1) ? atol(argv[1]) : 1000000L;
    int iters = (argc > 2) ? atoi(argv[2]) : 500;
    int reps = (argc > 3) ? atoi(argv[3]) : 5;
    if (n < 1 || iters < 1 || reps < 1 || reps > MAX_REPS) {
        fprintf(stderr, "uso: %s [n>=1] [iters>=1] [1<=reps<=%d]\n", argv[0], MAX_REPS);
        return 1;
    }

    double *u = malloc((size_t)(n + 2) * sizeof(double));
    double *u_new = malloc((size_t)(n + 2) * sizeof(double));
    if (!u || !u_new) {
        fprintf(stderr, "sin memoria para n=%ld\n", n);
        return 1;
    }

    double times[MAX_REPS];
    /* r = -1 es el calentamiento: no se cuenta (protocolo §2). */
    for (int r = -1; r < reps; r++) {
        init_state(u, u_new, n);
        double t0 = now_s();
        for (int it = 0; it < iters; it++) {
            for (long i = 1; i <= n; i++)
                u_new[i] = 0.5 * (u[i - 1] + u[i + 1]);
            double *tmp = u; u = u_new; u_new = tmp; /* doble búfer */
        }
        double t1 = now_s();
        if (r >= 0) times[r] = t1 - t0;
    }

    /* Verificación: suma de todos los puntos y valor de un punto de sondeo. */
    double checksum = 0.0;
    for (long i = 1; i <= n; i++) checksum += u[i];
    long probe = (n > 3) ? n - 3 : 1; /* índice 1-based */
    double u_probe = u[probe];

    double sorted[MAX_REPS];
    memcpy(sorted, times, (size_t)reps * sizeof(double));
    qsort(sorted, (size_t)reps, sizeof(double), cmp_double);
    double median = sorted[reps / 2];
    double t_comp_it = median / iters; /* tiempo de cómputo por iteración */

    printf("jacobi_seq: n=%ld iters=%d reps=%d | mediana=%.4f s (min %.4f, max %.4f) | "
           "%.3e s/iter | %.3f ns por punto-iteración | checksum=%.6e\n",
           n, iters, reps, median, sorted[0], sorted[reps - 1], t_comp_it,
           1e9 * t_comp_it / (double)n, checksum);
    printf("RESULT,1,%ld,%d,%d,", n, iters, reps);
    for (int r = 0; r < reps; r++) printf("%s%.6f", r ? ";" : "", times[r]);
    printf(",%.6f,%.6f,%.6f,%.6e,%.6e,%.10e,%.17g\n",
           median, sorted[0], sorted[reps - 1], t_comp_it, 0.0, checksum, u_probe);

    free(u);
    free(u_new);
    return 0;
}
