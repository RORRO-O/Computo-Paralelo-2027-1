/*
 * index_probe.cu — ¿Qué índice global le toca a cada hilo? (fase Investigar de PRIMM)
 *
 * Uso: ./index_probe [n] [block]      (por defecto n = 10, block = 4 -> 3 bloques, 12 hilos, 2 ociosos)
 * Compilar y correr (GPU): nvcc -O2 -arch=sm_75 index_probe.cu -o index_probe && ./index_probe 10 4
 *
 * Hace dos cosas:
 *  1. Cada hilo imprime con printf desde el kernel. El ORDEN de esas líneas no está garantizado:
 *     los bloques (y los warps dentro de ellos) corren en el orden que decida la GPU.
 *  2. Cada hilo con i < n anota en owner_block[i] y owner_thread[i] quién lo atendió; el anfitrión
 *     imprime esa tabla ordenada. Sirve para comprobar que cada índice 0..n-1 tiene exactamente un dueño.
 */
#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

#define CUDA_CHECK(call)                                                           \
    do {                                                                           \
        cudaError_t err__ = (call);                                                \
        if (err__ != cudaSuccess) {                                                \
            fprintf(stderr, "Error de CUDA en %s:%d: %s\n", __FILE__, __LINE__,   \
                    cudaGetErrorString(err__));                                    \
            exit(EXIT_FAILURE);                                                    \
        }                                                                          \
    } while (0)

__global__ void print_index(int n, int *owner_block, int *owner_thread)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) {
        printf("bloque %d, hilo %d -> i = %d\n", blockIdx.x, threadIdx.x, i);
        owner_block[i] = blockIdx.x;
        owner_thread[i] = threadIdx.x;
    } else {
        printf("bloque %d, hilo %d -> i = %d  (i >= n: este hilo NO trabaja)\n", blockIdx.x, threadIdx.x, i);
    }
}

int main(int argc, char **argv)
{
    int n = (argc > 1) ? atoi(argv[1]) : 10;
    int block = (argc > 2) ? atoi(argv[2]) : 4;
    if (n <= 0 || block <= 0 || block > 1024 || n > 4096) {
        fprintf(stderr, "uso: %s [n 1..4096] [block 1..1024]\n", argv[0]);
        return 1;
    }
    int grid = (n + block - 1) / block;
    printf("n=%d block=%d grid=%d  hilos_lanzados=%d  ociosos=%d\n", n, block, grid, grid * block,
           grid * block - n);

    int *d_owner_block = NULL, *d_owner_thread = NULL;
    CUDA_CHECK(cudaMalloc((void **)&d_owner_block, (size_t)n * sizeof(int)));
    CUDA_CHECK(cudaMalloc((void **)&d_owner_thread, (size_t)n * sizeof(int)));
    CUDA_CHECK(cudaMemset(d_owner_block, -1, (size_t)n * sizeof(int)));
    CUDA_CHECK(cudaMemset(d_owner_thread, -1, (size_t)n * sizeof(int)));

    printf("--- printf desde el kernel (orden NO garantizado) ---\n");
    print_index<<<grid, block>>>(n, d_owner_block, d_owner_thread);
    CUDA_CHECK(cudaGetLastError());      /* error de lanzamiento */
    CUDA_CHECK(cudaDeviceSynchronize()); /* espera al kernel y vacía el buffer de printf */

    int *owner_block = (int *)malloc((size_t)n * sizeof(int));
    int *owner_thread = (int *)malloc((size_t)n * sizeof(int));
    CUDA_CHECK(cudaMemcpy(owner_block, d_owner_block, (size_t)n * sizeof(int), cudaMemcpyDeviceToHost));
    CUDA_CHECK(cudaMemcpy(owner_thread, d_owner_thread, (size_t)n * sizeof(int), cudaMemcpyDeviceToHost));

    printf("--- tabla ordenada por índice (la imprime el anfitrión) ---\n");
    int missing = 0;
    for (int i = 0; i < n; i++) {
        if (owner_block[i] < 0)
            missing++;
        printf("i = %d <- bloque %d, hilo %d\n", i, owner_block[i], owner_thread[i]);
    }
    printf("indices_sin_dueno=%d\n", missing);

    free(owner_block);
    free(owner_thread);
    CUDA_CHECK(cudaFree(d_owner_block));
    CUDA_CHECK(cudaFree(d_owner_thread));
    return 0;
}
