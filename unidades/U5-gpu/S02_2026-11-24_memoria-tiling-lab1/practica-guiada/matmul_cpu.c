/* matmul_cpu.c — referencia secuencial de C = A·B (n×n, float, por filas) y calculadora del
 * modelo de lecturas a memoria global de las dos versiones CUDA (ingenua y por mosaicos).
 * Sirve para: (a) tener una salida real sin GPU, (b) comparar la suma de comprobación con la
 * de la GPU o del simulador de Numba, (c) contrastar la predicción de lecturas de PRIMM.
 *
 * Compilar:  gcc -std=c11 -O2 -Wall -Wextra matmul_cpu.c -o matmul_cpu
 * Ejecutar:  ./matmul_cpu [n] [tile]      (por defecto n=512, tile=16)
 */
#define _POSIX_C_SOURCE 199309L
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

/* Misma inicialización que common.cuh y matmul_numba.py (checksums comparables). */
static void init_matrices(float *A, float *B, int n) {
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            A[(size_t)i * n + j] = (float)((3 * i + 7 * j) % 11) / 11.0f;
            B[(size_t)i * n + j] = (float)((5 * i + 2 * j) % 13) / 13.0f;
        }
    }
}

/* Orden i-k-j: el ciclo interno recorre B y C por filas (amigable con la caché). */
static void matmul_cpu(const float *A, const float *B, float *C, int n) {
    for (size_t idx = 0; idx < (size_t)n * n; ++idx) C[idx] = 0.0f;
    for (int i = 0; i < n; ++i) {
        for (int k = 0; k < n; ++k) {
            float a = A[(size_t)i * n + k];
            for (int j = 0; j < n; ++j) {
                C[(size_t)i * n + j] += a * B[(size_t)k * n + j];
            }
        }
    }
}

static double now_s(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + 1e-9 * (double)ts.tv_nsec;
}

int main(int argc, char **argv) {
    int n = (argc > 1) ? atoi(argv[1]) : 512;
    int tile = (argc > 2) ? atoi(argv[2]) : 16;
    if (n <= 0 || tile <= 0) {
        fprintf(stderr, "Uso: %s [n] [tile]   (ambos > 0)\n", argv[0]);
        return 1;
    }
    size_t count = (size_t)n * n;
    float *A = malloc(count * sizeof(float));
    float *B = malloc(count * sizeof(float));
    float *C = malloc(count * sizeof(float));
    if (!A || !B || !C) { fprintf(stderr, "Sin memoria\n"); return 1; }
    init_matrices(A, B, n);

    double t0 = now_s();
    matmul_cpu(A, B, C, n);
    double t1 = now_s();

    /* Suma de comprobación en doble precisión (misma en matmul_numba.py). */
    double checksum = 0.0;
    for (size_t idx = 0; idx < count; ++idx) checksum += (double)C[idx];

    /* Modelo de lecturas a memoria global (instrucciones de carga, sin contar cachés):
     *   ingenua:  cada hilo lee n elementos de A y n de B → 2n por hilo, n² hilos → 2n³
     *   mosaicos: cada hilo lee 2 elementos por fase, ceil(n/tile) fases → 2·n²·ceil(n/tile)
     */
    int n_tiles = (n + tile - 1) / tile;
    unsigned long long reads_naive = 2ULL * (unsigned long long)n * n * n;
    unsigned long long reads_tiled = 2ULL * (unsigned long long)n * n * n_tiles;

    printf("matmul_cpu  n=%d  tiempo %.4f s  checksum %.6f\n", n, t1 - t0, checksum);
    printf("  modelo de lecturas a memoria global con TILE=%d (fases=%d):\n", tile, n_tiles);
    printf("    ingenua : %llu   (cada elemento de A se lee %d veces)\n", reads_naive, n);
    printf("    mosaicos: %llu   (cada elemento de A se lee %d veces)\n", reads_tiled, n_tiles);
    printf("    cociente ingenua/mosaicos: %.2f\n", (double)reads_naive / (double)reads_tiled);
    printf("  C[0][0]=%.6f  C[n-1][n-1]=%.6f\n", C[0], C[count - 1]);
    printf("csv,cpu,%d,%d,%.4f,%.6f\n", n, tile, (t1 - t0) * 1e3, checksum);

    free(A); free(B); free(C);
    return 0;
}
