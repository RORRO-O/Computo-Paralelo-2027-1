/*
 * a_vectores_cpu.c — Referencia secuencial de la Parte A: suma de vectores y SAXPY.
 *
 * Uso:      ./a_vectores_cpu [n=16777216] [vector_add|saxpy|ambos]
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra a_vectores_cpu.c -o a_vectores_cpu
 *
 * Misma inicialización y misma aritmética que a_vectores.cu y a_vectores_numba.py, por lo que el
 * checksum coincide entre los tres programas para el mismo n. Es el T(1) del protocolo cuando la
 * CPU de Colab/Kaggle es la que se compara (el .cu ya lo mide internamente; este programa sirve
 * para verificar sin GPU y para medir T(1) en tu laptop).
 * Protocolo: 1 calentamiento + 5 repeticiones, mediana; se reportan también mínimo y máximo.
 */
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>

#define REPS 5
static const float ALPHA = 2.0f;

static double now_s(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}

/* Los ciclos que la GPU reparte entre miles de hilos: aquí los hace un solo núcleo. */
static void vector_add_cpu(const float *a, const float *b, float *c, int n)
{
    for (int i = 0; i < n; i++)
        c[i] = a[i] + b[i];
}

static void saxpy_cpu(float alpha, const float *x, const float *y, float *out, int n)
{
    for (int i = 0; i < n; i++)
        out[i] = alpha * x[i] + y[i];
}

static int cmp_double(const void *x, const void *y)
{
    double dx = *(const double *)x, dy = *(const double *)y;
    return (dx > dy) - (dx < dy);
}

/* Corre un kernel de CPU con el protocolo y verifica contra la fórmula cerrada. Regresa 1 si OK. */
static int run_kernel(int which, const float *a, const float *b, float *c, int n)
{
    const char *name = which == 0 ? "vector_add" : "saxpy";
    double t[REPS];
    for (int r = -1; r < REPS; r++) {
        double t0 = now_s();
        if (which == 0)
            vector_add_cpu(a, b, c, n);
        else
            saxpy_cpu(ALPHA, a, b, c, n);
        double dt = now_s() - t0;
        if (r >= 0)
            t[r] = dt;
    }
    qsort(t, REPS, sizeof(double), cmp_double);
    double t_med = t[REPS / 2];

    double checksum = 0.0, max_abs_err = 0.0;
    for (int i = 0; i < n; i++) {
        double expected = (which == 0) ? (double)(i % 7) + (double)(i % 13)
                                       : (double)ALPHA * (double)(i % 7) + (double)(i % 13);
        double diff = fabs((double)c[i] - expected);
        if (diff > max_abs_err)
            max_abs_err = diff;
        checksum += c[i];
    }
    int ok = (max_abs_err <= 1e-5);
    double bw = (3.0 * (double)n * sizeof(float) / 1e9) / (t_med > 0 ? t_med : 1e-12);
    printf("kernel=%s n=%d t_cpu_ms=%.4f (min %.4f, max %.4f) ancho_banda_GB_s=%.1f "
           "checksum=%.1f max_abs_err=%.3g verificacion=%s\n",
           name, n, t_med * 1e3, t[0] * 1e3, t[REPS - 1] * 1e3, bw, checksum, max_abs_err,
           ok ? "OK" : "FALLA");
    return ok;
}

int main(int argc, char **argv)
{
    int n = (argc > 1) ? atoi(argv[1]) : (1 << 24);
    const char *which = (argc > 2) ? argv[2] : "ambos";
    if (n <= 0) {
        fprintf(stderr, "uso: %s [n>0] [vector_add|saxpy|ambos]\n", argv[0]);
        return 1;
    }
    size_t bytes = (size_t)n * sizeof(float);
    float *a = malloc(bytes), *b = malloc(bytes), *c = malloc(bytes);
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

    printf("a_vectores_cpu: n=%d reps=%d (1 calentamiento + %d, mediana)\n", n, REPS, REPS);
    int ok = 1;
    if (strcmp(which, "saxpy") != 0)
        ok &= run_kernel(0, a, b, c, n);
    if (strcmp(which, "vector_add") != 0)
        ok &= run_kernel(1, a, b, c, n);

    free(a);
    free(b);
    free(c);
    return ok ? 0 : 2;
}
