/*
 * b_matmul_cpu.c — Referencia secuencial de la Parte B (C = A·B, n×n, float) y calculadora del
 * modelo de lecturas a memoria global de las dos versiones de GPU.
 *
 * Uso:      ./b_matmul_cpu [n=512] [tile=16]
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra b_matmul_cpu.c -o b_matmul_cpu
 *
 * Misma inicialización que b_matmul_tiled.cu y b_matmul_numba.py: el checksum (suma de C en double)
 * sirve para comparar los tres programas. Protocolo: 1 calentamiento + 5 repeticiones (mediana) hasta
 * n = 1024; con n mayor una sola repetición (y se dice).
 */
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define REPS 5

static double now_s(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}

static void init_matrices(float *A, float *B, int n)
{
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j) {
            A[(size_t)i * n + j] = (float)((3 * i + 7 * j) % 11) / 11.0f;
            B[(size_t)i * n + j] = (float)((5 * i + 2 * j) % 13) / 13.0f;
        }
}

/* Orden i-k-j: el ciclo interno recorre B y C por filas (amigable con la caché de la CPU). */
static void matmul_cpu(const float *A, const float *B, float *C, int n)
{
    for (size_t idx = 0; idx < (size_t)n * n; ++idx)
        C[idx] = 0.0f;
    for (int i = 0; i < n; ++i)
        for (int k = 0; k < n; ++k) {
            float a = A[(size_t)i * n + k];
            for (int j = 0; j < n; ++j)
                C[(size_t)i * n + j] += a * B[(size_t)k * n + j];
        }
}

static int cmp_double(const void *x, const void *y)
{
    double dx = *(const double *)x, dy = *(const double *)y;
    return (dx > dy) - (dx < dy);
}

int main(int argc, char **argv)
{
    int n = (argc > 1) ? atoi(argv[1]) : 512;
    int tile = (argc > 2) ? atoi(argv[2]) : 16;
    if (n <= 0 || tile <= 0) {
        fprintf(stderr, "uso: %s [n>0] [tile>0]\n", argv[0]);
        return 1;
    }
    size_t count = (size_t)n * n, bytes = count * sizeof(float);
    float *A = malloc(bytes), *B = malloc(bytes), *C = malloc(bytes);
    if (!A || !B || !C) {
        fprintf(stderr, "Sin memoria para n=%d\n", n);
        return 1;
    }
    init_matrices(A, B, n);

    int reps = (n <= 1024) ? REPS : 1;
    double t[REPS];
    matmul_cpu(A, B, C, n); /* calentamiento */
    for (int r = 0; r < reps; ++r) {
        double t0 = now_s();
        matmul_cpu(A, B, C, n);
        t[r] = now_s() - t0;
    }
    qsort(t, (size_t)reps, sizeof(double), cmp_double);
    double t_med = t[reps / 2];

    double checksum = 0.0;
    for (size_t i = 0; i < count; ++i)
        checksum += C[i];

    int phases = (n + tile - 1) / tile;
    unsigned long long reads_naive = 2ULL * (unsigned long long)n * n * n;
    unsigned long long reads_tiled = 2ULL * (unsigned long long)n * n * (unsigned long long)phases;
    double gflops = 2.0 * (double)n * n * n / t_med / 1e9;

    printf("b_matmul_cpu: n=%d tile=%d t_cpu_ms=%.3f (mediana de %d; min %.3f, max %.3f) %.2f GFLOP/s\n",
           n, tile, t_med * 1e3, reps, t[0] * 1e3, t[reps - 1] * 1e3, gflops);
    printf("  modelo de lecturas a memoria global: ingenua=%llu (cada elemento de A: %d veces) "
           "mosaicos=%llu (cada elemento de A: %d veces) cociente=%.2f fases=%d\n",
           reads_naive, n, reads_tiled, phases, (double)reads_naive / (double)reads_tiled, phases);
    printf("  C[0][0]=%.6f C[n-1][n-1]=%.6f checksum=%.6f\n", C[0], C[count - 1], checksum);

    free(A);
    free(B);
    free(C);
    return 0;
}
