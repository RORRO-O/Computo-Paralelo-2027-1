/*
 * v3/kernel.cu · V3 GPU (CUDA C) · Plantilla del proyecto integrador
 *
 * Uso:     ./v3 [n] [semilla] [hilos_por_bloque]
 * Salida:  clave=valor:
 *          version=v3  n=...  semilla=...  gpu=<nombre>  hilos_por_bloque=...
 *          tiempo_kernel_s=...   (SOLO el kernel: sin copias anfitrión<->dispositivo)
 *          tiempo_total_s=...    (H2D + kernel + D2H; protocolo §2: se reportan ambos)
 *          checksum=...
 * Código:  0 si todo bien; 2 argumentos inválidos; 1 error de CUDA o de memoria.
 * Ejemplo (Colab, GPU T4):  nvcc -O2 -arch=sm_75 -Xcompiler -Wall,-Wextra -I. -o v3 kernel.cu && ./v3 4000000 12345
 * Verificación local sin GPU: make check  (solo compila: nvcc -c -arch=sm_75)
 *
 * Correctitud: el checksum debe coincidir con el de ./v1 n semilla (tolerancia relativa).
 * La celda de verificación del notebook lo comprueba en la misma sesión de Colab.
 *
 * PLANTILLA: sustituye el kernel y, si hace falta, el patrón de lanzamiento. Conserva la
 * salida clave=valor y las DOS mediciones (con y sin transferencias).
 */
#include <cuda_runtime.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>

#include "problema.h"

/* Revisa el código de retorno de cada llamada a la API. "El kernel no dio error" no es
 * evidencia de correctitud (Anexo A, idea errónea 27): además se compara con la CPU. */
#define CUDA_CHECK(call)                                                            \
    do {                                                                            \
        cudaError_t err__ = (call);                                                 \
        if (err__ != cudaSuccess) {                                                 \
            fprintf(stderr, "error CUDA en %s:%d: %s\n", __FILE__, __LINE__,       \
                    cudaGetErrorString(err__));                                     \
            return 1;                                                               \
        }                                                                           \
    } while (0)

/* PLANTILLA: mismo cómputo por elemento que comun/problema.h, en versión de dispositivo.
 * Si cambias `elemento()` en la cabecera, cambia también esta función. */
__device__ static double elemento_dev(double x, int iter) {
    double y = x;
    for (int k = 0; k < iter; ++k) {
        y = sin(y) + cos(0.5 * y) * 0.25;
    }
    return y;
}

__global__ void kernel_elemento(const double *in, double *out, size_t n, int iter) {
    size_t i = (size_t)blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) {
        out[i] = elemento_dev(in[i], iter);
    }
}

static int parse_uint(const char *s, unsigned long *out) {
    char *end = NULL;
    errno = 0;
    unsigned long v = strtoul(s, &end, 10);
    if (errno != 0 || end == s || *end != '\0') {
        return 0;
    }
    *out = v;
    return 1;
}

int main(int argc, char **argv) {
    unsigned long n = N_DEFAULT;
    unsigned long seed = SEED_DEFAULT;
    unsigned long block = 256;

    if (argc > 1 && !parse_uint(argv[1], &n)) {
        fprintf(stderr, "error: n inválido: %s\n", argv[1]);
        return 2;
    }
    if (argc > 2 && !parse_uint(argv[2], &seed)) {
        fprintf(stderr, "error: semilla inválida: %s\n", argv[2]);
        return 2;
    }
    if (argc > 3 && (!parse_uint(argv[3], &block) || block == 0 || block > 1024 ||
                     block % 32 != 0)) {
        fprintf(stderr, "error: hilos_por_bloque debe ser múltiplo de 32 en [32, 1024]: %s\n",
                argv[3]);
        return 2;
    }
    if (n == 0) {
        fprintf(stderr, "error: n debe ser mayor que 0\n");
        return 2;
    }

    size_t bytes = (size_t)n * sizeof(double);
    double *h_in = (double *)malloc(bytes);
    double *h_out = (double *)malloc(bytes);
    if (h_in == NULL || h_out == NULL) {
        fprintf(stderr, "error: sin memoria en el anfitrión para n=%lu\n", n);
        free(h_in);
        free(h_out);
        return 1;
    }
    init_input(h_in, (size_t)n, (uint32_t)seed);

    cudaDeviceProp prop;
    CUDA_CHECK(cudaGetDeviceProperties(&prop, 0));

    double *d_in = NULL;
    double *d_out = NULL;
    CUDA_CHECK(cudaMalloc((void **)&d_in, bytes));
    CUDA_CHECK(cudaMalloc((void **)&d_out, bytes));

    cudaEvent_t ev_total0, ev_k0, ev_k1, ev_total1;
    CUDA_CHECK(cudaEventCreate(&ev_total0));
    CUDA_CHECK(cudaEventCreate(&ev_k0));
    CUDA_CHECK(cudaEventCreate(&ev_k1));
    CUDA_CHECK(cudaEventCreate(&ev_total1));

    unsigned int grid = (unsigned int)((n + block - 1) / block);

    /* ---- región de interés con transferencias ---- */
    CUDA_CHECK(cudaEventRecord(ev_total0, 0));
    CUDA_CHECK(cudaMemcpy(d_in, h_in, bytes, cudaMemcpyHostToDevice));

    /* ---- región de interés sin transferencias (solo kernel) ---- */
    CUDA_CHECK(cudaEventRecord(ev_k0, 0));
    kernel_elemento<<<grid, (unsigned int)block>>>(d_in, d_out, (size_t)n, ITER_DEFAULT);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaEventRecord(ev_k1, 0));

    CUDA_CHECK(cudaMemcpy(h_out, d_out, bytes, cudaMemcpyDeviceToHost));
    CUDA_CHECK(cudaEventRecord(ev_total1, 0));
    CUDA_CHECK(cudaEventSynchronize(ev_total1));

    float ms_kernel = 0.0f;
    float ms_total = 0.0f;
    CUDA_CHECK(cudaEventElapsedTime(&ms_kernel, ev_k0, ev_k1));
    CUDA_CHECK(cudaEventElapsedTime(&ms_total, ev_total0, ev_total1));

    double cs = checksum(h_out, (size_t)n);

    printf("version=v3\n");
    printf("n=%lu\n", n);
    printf("semilla=%lu\n", seed);
    printf("gpu=%s\n", prop.name);
    printf("hilos_por_bloque=%lu\n", block);
    printf("tiempo_kernel_s=%.6f\n", (double)ms_kernel / 1000.0);
    printf("tiempo_total_s=%.6f\n", (double)ms_total / 1000.0);
    printf("checksum=%.12e\n", cs);

    CUDA_CHECK(cudaEventDestroy(ev_total0));
    CUDA_CHECK(cudaEventDestroy(ev_k0));
    CUDA_CHECK(cudaEventDestroy(ev_k1));
    CUDA_CHECK(cudaEventDestroy(ev_total1));
    CUDA_CHECK(cudaFree(d_in));
    CUDA_CHECK(cudaFree(d_out));
    free(h_in);
    free(h_out);
    return 0;
}
