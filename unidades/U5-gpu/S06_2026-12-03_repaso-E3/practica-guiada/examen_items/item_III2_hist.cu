/* item_III2_hist.cu — Examen de práctica U4–U5, sección III, ítem 2 (encontrar y corregir el error).
 *
 * Histograma de 8 bins: v[i] = i % 8, así que cada bin debe valer exactamente n / 8. El kernel tiene
 * índice global y guardia correctos; el error está en cómo se actualiza el contador compartido.
 *   nvcc -O2 -arch=sm_75 item_III2_hist.cu -o item_III2_hist && ./item_III2_hist 1048576
 *   nvcc -O2 -arch=sm_75 -DCORREGIDO item_III2_hist.cu -o item_III2_hist_ok && ./item_III2_hist_ok 1048576
 * Sin GPU: NUMBA_ENABLE_CUDASIM=1 python3 item_III2_hist_numba.py 1000 [--corregido]
 */
#include <cstdio>
#include <cstdlib>
#include <cuda_runtime.h>

#define BINS 8

#define CUDA_CHECK(call)                                                                   \
    do {                                                                                   \
        cudaError_t e_ = (call);                                                           \
        if (e_ != cudaSuccess) {                                                           \
            fprintf(stderr, "error CUDA en %s:%d: %s\n", __FILE__, __LINE__, cudaGetErrorString(e_)); \
            exit(1);                                                                       \
        }                                                                                  \
    } while (0)

__global__ void hist8(const unsigned char *v, unsigned int *hist, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) {
#ifdef CORREGIDO
        atomicAdd(&hist[v[i]], 1u);         /* lectura-suma-escritura indivisible */
#else
        hist[v[i]] += 1;                    /* lectura, suma y escritura por separado: otros hilos se cuelan */
#endif
    }
}

int main(int argc, char **argv) {
    int n = argc > 1 ? atoi(argv[1]) : (1 << 20);
    int block = 256;
    if (n <= 0) { fprintf(stderr, "uso: %s [n>0]\n", argv[0]); return 1; }
    int grid = (n + block - 1) / block;

    unsigned char *h_v = (unsigned char *) malloc(n);
    unsigned int h_hist[BINS] = {0}, ref[BINS] = {0};
    for (int i = 0; i < n; i++) { h_v[i] = (unsigned char) (i % BINS); ref[h_v[i]]++; }

    unsigned char *d_v;
    unsigned int *d_hist;
    CUDA_CHECK(cudaMalloc(&d_v, n));
    CUDA_CHECK(cudaMalloc(&d_hist, BINS * sizeof(unsigned int)));
    CUDA_CHECK(cudaMemcpy(d_v, h_v, n, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemset(d_hist, 0, BINS * sizeof(unsigned int)));

    hist8<<<grid, block>>>(d_v, d_hist, n);
    cudaError_t launch_err = cudaGetLastError();
    cudaError_t exec_err = cudaDeviceSynchronize();
    CUDA_CHECK(cudaMemcpy(h_hist, d_hist, BINS * sizeof(unsigned int), cudaMemcpyDeviceToHost));

    unsigned long total = 0;
    int wrong = 0;
    printf("hist_gpu=[");
    for (int b = 0; b < BINS; b++) {
        printf("%u%s", h_hist[b], b < BINS - 1 ? "," : "]\n");
        total += h_hist[b];
        if (h_hist[b] != ref[b]) wrong++;
    }
    printf("hist_cpu=[");
    for (int b = 0; b < BINS; b++) printf("%u%s", ref[b], b < BINS - 1 ? "," : "]\n");
    printf("cudaGetLastError=%s cudaDeviceSynchronize=%s\n",
           cudaGetErrorString(launch_err), cudaGetErrorString(exec_err));
    int ok = (wrong == 0 && launch_err == cudaSuccess && exec_err == cudaSuccess);
    printf("n=%d total_gpu=%lu bins_incorrectos=%d verificacion=%s\n", n, total, wrong, ok ? "OK" : "FALLA");

    CUDA_CHECK(cudaFree(d_v));
    CUDA_CHECK(cudaFree(d_hist));
    free(h_v);
    return ok ? 0 : 2;
}
