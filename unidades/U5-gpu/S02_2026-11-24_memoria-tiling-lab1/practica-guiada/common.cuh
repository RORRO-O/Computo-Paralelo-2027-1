// common.cuh — utilidades compartidas por matmul_naive.cu, matmul_tiled.cu y transpose.cu.
// Contiene: verificación de errores de CUDA, inicialización determinista de matrices,
// referencia secuencial en CPU, comparación con tolerancia, mediana y lectura de argumentos.
// Nada de aquí corre en la GPU: todo es código de anfitrión (host).
#pragma once
#include <cstdio>
#include <cstdlib>
#include <cmath>
#include <cuda_runtime.h>

// Toda llamada a la API de CUDA se envuelve en CUDA_CHECK. Si falla, imprime archivo, línea
// y mensaje, y termina. Sin esto, un error pasa en silencio y el programa "parece" funcionar.
#define CUDA_CHECK(call)                                                          \
    do {                                                                          \
        cudaError_t err__ = (call);                                               \
        if (err__ != cudaSuccess) {                                               \
            fprintf(stderr, "Error CUDA en %s:%d: %s\n", __FILE__, __LINE__,      \
                    cudaGetErrorString(err__));                                   \
            exit(EXIT_FAILURE);                                                   \
        }                                                                         \
    } while (0)

// Número de repeticiones cronometradas (protocolo de medición: calentamiento + 5, mediana).
#define REPS 5

// Inicialización determinista. La MISMA fórmula está en matmul_cpu.c y matmul_numba.py,
// para que las sumas de comprobación (checksum) sean comparables entre programas.
static void init_matrices(float *A, float *B, int n) {
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            A[(size_t)i * n + j] = (float)((3 * i + 7 * j) % 11) / 11.0f;
            B[(size_t)i * n + j] = (float)((5 * i + 2 * j) % 13) / 13.0f;
        }
    }
}

// Referencia secuencial. Orden i-k-j: el ciclo interno recorre B y C por filas (amigable con
// la caché de la CPU). Para cada C[i][j] la suma sobre k va en orden creciente, igual que en
// los kernels, así que la diferencia con la GPU es solo redondeo (FMA, orden de operaciones).
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

// Tolerancia de comparación. Los sumandos están en [0, 1); con n términos en float el error de
// redondeo acumulado crece de forma proporcional a n. 1e-5 * n es holgado y detecta cualquier
// elemento no calculado (que valdría 0 cuando debería valer ~n/4).
static float tolerance(int n) { return 1e-5f * (float)n; }

// Verifica C contra la CPU. Para n <= 1024 compara TODOS los elementos. Para n mayor, la
// referencia completa tardaría demasiado en el anfitrión, así que compara una muestra
// determinista de 4096 elementos (cada uno recalculado con su propio producto punto).
// Devuelve cuántos elementos comparó y deja el error máximo en *max_err.
static long verify_matmul(const float *A, const float *B, const float *C, int n,
                          float *max_err) {
    *max_err = 0.0f;
    if (n <= 1024) {
        float *ref = (float *)malloc((size_t)n * n * sizeof(float));
        if (ref == NULL) { fprintf(stderr, "Sin memoria para la referencia\n"); exit(EXIT_FAILURE); }
        matmul_cpu(A, B, ref, n);
        for (size_t idx = 0; idx < (size_t)n * n; ++idx) {
            float e = fabsf(ref[idx] - C[idx]);
            if (e > *max_err) *max_err = e;
        }
        free(ref);
        return (long)n * n;
    }
    const int samples = 4096;
    unsigned long long state = 12345ULL;   // generador congruencial: misma muestra siempre
    for (int s = 0; s < samples; ++s) {
        state = state * 6364136223846793005ULL + 1442695040888963407ULL;
        int i = (int)((state >> 33) % (unsigned long long)n);
        state = state * 6364136223846793005ULL + 1442695040888963407ULL;
        int j = (int)((state >> 33) % (unsigned long long)n);
        float acc = 0.0f;
        for (int k = 0; k < n; ++k) acc += A[(size_t)i * n + k] * B[(size_t)k * n + j];
        float e = fabsf(acc - C[(size_t)i * n + j]);
        if (e > *max_err) *max_err = e;
    }
    return samples;
}

// Mediana de k valores (k pequeño): ordenamiento por inserción y elemento central.
static float median_of(float *v, int k) {
    for (int i = 1; i < k; ++i) {
        float x = v[i];
        int j = i - 1;
        while (j >= 0 && v[j] > x) { v[j + 1] = v[j]; --j; }
        v[j + 1] = x;
    }
    return v[k / 2];
}

static float min_of(const float *v, int k) {
    float m = v[0];
    for (int i = 1; i < k; ++i) if (v[i] < m) m = v[i];
    return m;
}

static float max_of(const float *v, int k) {
    float m = v[0];
    for (int i = 1; i < k; ++i) if (v[i] > m) m = v[i];
    return m;
}

// Tamaño del problema por línea de comandos, con valor por defecto.
static int parse_n(int argc, char **argv, int default_n) {
    int n = default_n;
    if (argc > 1) n = atoi(argv[1]);
    if (n <= 0) {
        fprintf(stderr, "Uso: %s [n]   (n > 0; por defecto %d)\n", argv[0], default_n);
        exit(EXIT_FAILURE);
    }
    return n;
}
