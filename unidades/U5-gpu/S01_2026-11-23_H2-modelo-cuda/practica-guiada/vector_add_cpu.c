/*
 * vector_add_cpu.c — Referencia secuencial de la suma de vectores c = a + b.
 *
 * Uso: ./vector_add_cpu [n]      (por defecto n = 16 777 216 = 2^24)
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra vector_add_cpu.c -o vector_add_cpu
 *
 * Imprime el mismo checksum que vector_add.cu y vector_add_numba.py para el mismo n:
 * así se comparan las tres versiones aunque corran en máquinas distintas.
 * Medición: calentamiento + 5 repeticiones, mediana (protocolo del curso).
 */
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>

#define REPS 5

static double now_s(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}

/* El ciclo que la GPU reparte entre miles de hilos: aquí lo hace un solo núcleo. */
static void vector_add_cpu(const float *a, const float *b, float *c, int n)
{
    for (int i = 0; i < n; i++)
        c[i] = a[i] + b[i];
}

static int cmp_double(const void *x, const void *y)
{
    double dx = *(const double *)x, dy = *(const double *)y;
    return (dx > dy) - (dx < dy);
}

int main(int argc, char **argv)
{
    int n = (argc > 1) ? atoi(argv[1]) : (1 << 24);
    if (n <= 0) {
        fprintf(stderr, "uso: %s [n>0]\n", argv[0]);
        return 1;
    }
    size_t bytes = (size_t)n * sizeof(float);
    float *a = (float *)malloc(bytes);
    float *b = (float *)malloc(bytes);
    float *c = (float *)malloc(bytes);
    if (!a || !b || !c) {
        fprintf(stderr, "Sin memoria para n=%d\n", n);
        return 1;
    }
    /* Misma inicialización que las versiones CUDA y Numba. */
    for (int i = 0; i < n; i++) {
        a[i] = (float)(i % 7);
        b[i] = (float)(i % 13);
    }
    memset(c, 0, bytes);

    vector_add_cpu(a, b, c, n); /* calentamiento (no se cuenta) */

    double t[REPS];
    for (int r = 0; r < REPS; r++) {
        double t0 = now_s();
        vector_add_cpu(a, b, c, n);
        t[r] = now_s() - t0;
    }
    qsort(t, REPS, sizeof(double), cmp_double);
    double t_med = t[REPS / 2];

    /* Autoverificación contra la fórmula cerrada y checksum reproducible. */
    double checksum = 0.0, max_abs_err = 0.0;
    for (int i = 0; i < n; i++) {
        double expected = (double)(i % 7) + (double)(i % 13);
        double diff = fabs((double)c[i] - expected);
        if (diff > max_abs_err)
            max_abs_err = diff;
        checksum += c[i];
    }
    int ok = (max_abs_err <= 1e-5);
    double bw = (3.0 * (double)bytes / 1e9) / (t_med > 0 ? t_med : 1e-12);

    printf("vector_add_cpu: n=%d reps=%d mediana_ms=%.4f (min %.4f, max %.4f)  ancho_banda_efectivo_GB_s=%.1f\n",
           n, REPS, t_med * 1e3, t[0] * 1e3, t[REPS - 1] * 1e3, bw);
    printf("checksum=%.1f max_abs_err=%.3g verificacion=%s\n", checksum, max_abs_err, ok ? "OK" : "FALLA");

    free(a);
    free(b);
    free(c);
    return ok ? 0 : 2;
}
