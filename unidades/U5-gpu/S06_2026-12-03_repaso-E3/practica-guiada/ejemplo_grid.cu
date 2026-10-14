/* ejemplo_grid.cu — Ejemplo resuelto (parte B): cómo se encuentra y corrige un error en un kernel.
 *
 * y = 0.5·x con x[i] = (i % 7) + 1 y n = 1000. El kernel tiene guardia. El error está en el ANFITRIÓN:
 * el número de bloques se calcula con división entera (n / block) y los últimos n % block elementos
 * nunca se procesan. Referencia: ./caza_cpu grid 1000 → checksum=1998.5
 *   nvcc -O2 -arch=sm_75 ejemplo_grid.cu -o ejemplo_grid && ./ejemplo_grid 1000 256
 *   nvcc -O2 -arch=sm_75 -DCORREGIDO ejemplo_grid.cu -o ejemplo_grid_ok && ./ejemplo_grid_ok 1000 256
 * Sin GPU: NUMBA_ENABLE_CUDASIM=1 python3 ejemplo_grid_numba.py 1000 256 [--corregido]
 */
#include <cstdio>
#include <cstdlib>
#include <cmath>
#include <cuda_runtime.h>

#define CUDA_CHECK(call)                                                                   \
    do {                                                                                   \
        cudaError_t e_ = (call);                                                           \
        if (e_ != cudaSuccess) {                                                           \
            fprintf(stderr, "error CUDA en %s:%d: %s\n", __FILE__, __LINE__, cudaGetErrorString(e_)); \
            exit(1);                                                                       \
        }                                                                                  \
    } while (0)

__global__ void scale(const float *x, float *y, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) y[i] = 0.5f * x[i];                   /* guardia presente: este kernel está bien */
}

int main(int argc, char **argv) {
    int n = argc > 1 ? atoi(argv[1]) : 1000;
    int block = argc > 2 ? atoi(argv[2]) : 256;
    if (n <= 0 || block <= 0 || block > 1024) {
        fprintf(stderr, "uso: %s [n>0] [block 1..1024]\n", argv[0]);
        return 1;
    }
#ifdef CORREGIDO
    int grid = (n + block - 1) / block;              /* redondeo hacia arriba: cubre los n elementos */
#else
    int grid = n / block;                            /* división entera: ¿cuántos elementos quedan sin hilo? */
#endif
    float *h_x = (float *) malloc(n * sizeof(float));
    float *h_y = (float *) malloc(n * sizeof(float));
    for (int i = 0; i < n; i++) { h_x[i] = (float) (i % 7) + 1.0f; h_y[i] = 0.0f; }

    float *d_x, *d_y;
    CUDA_CHECK(cudaMalloc(&d_x, n * sizeof(float)));
    CUDA_CHECK(cudaMalloc(&d_y, n * sizeof(float)));
    CUDA_CHECK(cudaMemcpy(d_x, h_x, n * sizeof(float), cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_y, h_y, n * sizeof(float), cudaMemcpyHostToDevice));

    scale<<<grid, block>>>(d_x, d_y, n);
    cudaError_t launch_err = cudaGetLastError();
    cudaError_t exec_err = cudaDeviceSynchronize();
    CUDA_CHECK(cudaMemcpy(h_y, d_y, n * sizeof(float), cudaMemcpyDeviceToHost));

    int unprocessed = 0, wrong = 0;
    double checksum = 0.0;
    for (int i = 0; i < n; i++) {
        float ref = 0.5f * h_x[i];                   /* ref >= 0.5: un 0 en y significa "nadie lo tocó" */
        if (h_y[i] == 0.0f) unprocessed++;
        else if (fabsf(h_y[i] - ref) > 1e-5f) wrong++;
        checksum += h_y[i];
    }
    int ok = (unprocessed == 0 && wrong == 0 && launch_err == cudaSuccess && exec_err == cudaSuccess);
    printf("ejemplo_grid: n=%d block=%d grid=%d hilos_lanzados=%d\n", n, block, grid, grid * block);
    printf("cudaGetLastError=%s cudaDeviceSynchronize=%s\n",
           cudaGetErrorString(launch_err), cudaGetErrorString(exec_err));
    printf("checksum=%.1f elementos_incorrectos=%d elementos_sin_procesar=%d\n", checksum, wrong, unprocessed);
    printf("verificacion=%s\n", ok ? "OK" : "FALLA");

    CUDA_CHECK(cudaFree(d_x));
    CUDA_CHECK(cudaFree(d_y));
    free(h_x);
    free(h_y);
    return ok ? 0 : 2;
}
