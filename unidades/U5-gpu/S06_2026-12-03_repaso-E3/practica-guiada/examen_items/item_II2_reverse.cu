/* item_II2_reverse.cu — Examen de práctica U4–U5, sección II, ítem 2 (predecir la salida de un kernel).
 *   nvcc -O2 -arch=sm_75 item_II2_reverse.cu -o item_II2_reverse && ./item_II2_reverse
 * Sin GPU: NUMBA_ENABLE_CUDASIM=1 python3 item_II2_reverse_numba.py
 */
#include <cstdio>
#include <cstdlib>
#include <cuda_runtime.h>

#define CUDA_CHECK(call)                                                                   \
    do {                                                                                   \
        cudaError_t e_ = (call);                                                           \
        if (e_ != cudaSuccess) {                                                           \
            fprintf(stderr, "error CUDA en %s:%d: %s\n", __FILE__, __LINE__, cudaGetErrorString(e_)); \
            exit(1);                                                                       \
        }                                                                                  \
    } while (0)

__global__ void reverse_in_block(int *data, int n) {
    __shared__ int s[4];
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) s[threadIdx.x] = data[i];
    __syncthreads();
    int j = blockDim.x - 1 - threadIdx.x;            /* posición espejo dentro del bloque */
    int src = blockIdx.x * blockDim.x + j;           /* índice global de esa posición */
    if (i < n && src < n) data[i] = s[j];
}

int main(void) {
    const int n = 10;
    int h[n];
    for (int i = 0; i < n; i++) h[i] = i;
    int *d;
    CUDA_CHECK(cudaMalloc(&d, n * sizeof(int)));
    CUDA_CHECK(cudaMemcpy(d, h, n * sizeof(int), cudaMemcpyHostToDevice));
    reverse_in_block<<<3, 4>>>(d, n);
    CUDA_CHECK(cudaGetLastError());                  /* lanzamiento válido */
    CUDA_CHECK(cudaDeviceSynchronize());             /* ejecución sin error */
    CUDA_CHECK(cudaMemcpy(h, d, n * sizeof(int), cudaMemcpyDeviceToHost));
    for (int i = 0; i < n; i++) printf("%d%s", h[i], i < n - 1 ? " " : "\n");
    CUDA_CHECK(cudaFree(d));
    return 0;
}
