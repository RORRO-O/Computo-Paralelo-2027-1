/*
 * b_matmul_rect_cpu.c — Referencia secuencial de la Parte B: C = A·B con matrices RECTANGULARES
 * (A es M×K, B es K×N, C es M×N; float; todas guardadas por filas).
 *
 * Uso:      ./b_matmul_rect_cpu [M=1000] [K=600] [N=700] [tile=16]
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra b_matmul_rect_cpu.c -o b_matmul_rect_cpu
 *
 * Misma inicialización que b_matmul_rect.cu y b_matmul_rect_numba.py (y que la Parte A cuando
 * M = K = N): el checksum (suma de C en double) sirve para comparar los tres programas.
 * Además imprime la geometría que debe tener la versión por mosaicos para ese tamaño: malla (x recorre
 * las N columnas de C, y recorre las M filas), fases a lo largo de K e hilos que no escriben en C.
 * Protocolo: 1 calentamiento + 5 repeticiones (mediana) hasta M·K·N = 2^30; más allá una sola (y se dice).
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

/* A[i][j] con i < M, j < K y B[i][j] con i < K, j < N: las fórmulas de la Parte A con otras formas. */
static void init_matrices(float *A, float *B, int M, int K, int N)
{
    for (int i = 0; i < M; ++i)
        for (int j = 0; j < K; ++j)
            A[(size_t)i * K + j] = (float)((3 * i + 7 * j) % 11) / 11.0f;
    for (int i = 0; i < K; ++i)
        for (int j = 0; j < N; ++j)
            B[(size_t)i * N + j] = (float)((5 * i + 2 * j) % 13) / 13.0f;
}

/* Orden i-k-j: el ciclo interno recorre una fila de B y una de C (contiguas en memoria). */
static void matmul_rect_cpu(const float *A, const float *B, float *C, int M, int K, int N)
{
    for (size_t idx = 0; idx < (size_t)M * N; ++idx)
        C[idx] = 0.0f;
    for (int i = 0; i < M; ++i)
        for (int k = 0; k < K; ++k) {
            float a = A[(size_t)i * K + k];
            for (int j = 0; j < N; ++j)
                C[(size_t)i * N + j] += a * B[(size_t)k * N + j];
        }
}

static int cmp_double(const void *x, const void *y)
{
    double dx = *(const double *)x, dy = *(const double *)y;
    return (dx > dy) - (dx < dy);
}

int main(int argc, char **argv)
{
    int M = (argc > 1) ? atoi(argv[1]) : 1000;
    int K = (argc > 2) ? atoi(argv[2]) : 600;
    int N = (argc > 3) ? atoi(argv[3]) : 700;
    int tile = (argc > 4) ? atoi(argv[4]) : 16;
    if (M <= 0 || K <= 0 || N <= 0 || tile <= 0) {
        fprintf(stderr, "uso: %s [M>0] [K>0] [N>0] [tile>0]\n", argv[0]);
        return 1;
    }
    float *A = malloc((size_t)M * K * sizeof(float));
    float *B = malloc((size_t)K * N * sizeof(float));
    float *C = malloc((size_t)M * N * sizeof(float));
    if (!A || !B || !C) {
        fprintf(stderr, "Sin memoria para M=%d K=%d N=%d\n", M, K, N);
        return 1;
    }
    init_matrices(A, B, M, K, N);

    double work = (double)M * K * N;
    int reps = (work <= 1073741824.0) ? REPS : 1;
    double t[REPS];
    matmul_rect_cpu(A, B, C, M, K, N); /* calentamiento */
    for (int r = 0; r < reps; ++r) {
        double t0 = now_s();
        matmul_rect_cpu(A, B, C, M, K, N);
        t[r] = now_s() - t0;
    }
    qsort(t, (size_t)reps, sizeof(double), cmp_double);
    double t_med = t[reps / 2];

    double checksum = 0.0;
    for (size_t i = 0; i < (size_t)M * N; ++i)
        checksum += C[i];

    int grid_x = (N + tile - 1) / tile, grid_y = (M + tile - 1) / tile, phases = (K + tile - 1) / tile;
    long long launched = (long long)grid_x * grid_y * tile * tile;
    printf("b_matmul_rect_cpu: M=%d K=%d N=%d tile=%d t_cpu_ms=%.3f (mediana de %d; min %.3f, max %.3f) "
           "%.2f GFLOP/s\n",
           M, K, N, tile, t_med * 1e3, reps, t[0] * 1e3, t[reps - 1] * 1e3, 2.0 * work / t_med / 1e9);
    printf("  geometria por mosaicos: malla=%dx%d (x: columnas N, y: filas M) fases=%d (a lo largo de K) "
           "hilos=%lld sin_escritura=%lld\n",
           grid_x, grid_y, phases, launched, launched - (long long)M * N);
    printf("  C[0][0]=%.6f C[M-1][N-1]=%.6f checksum=%.6f\n", C[0], C[(size_t)M * N - 1], checksum);

    free(A);
    free(B);
    free(C);
    return 0;
}
