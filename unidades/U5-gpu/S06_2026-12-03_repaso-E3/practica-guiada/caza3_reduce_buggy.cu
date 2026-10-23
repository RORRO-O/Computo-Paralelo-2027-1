/* caza3_reduce_buggy.cu — Cazador de errores 3 (CUDA): suma de un arreglo con reducción en árbol.
 *
 * Qué hace cuando funciona: cada bloque suma sus 256 elementos en memoria compartida (árbol de
 * log2(256) = 8 niveles, como en S03), deja una suma parcial por bloque y el anfitrión suma las parciales.
 * x[i] = (i % 10) + 1.  Referencia: ./caza_cpu suma 1000  →  suma=5500.0
 *
 * Contiene UN error a propósito. Escribe tu predicción antes de correr:
 *   ./caza3_reduce_buggy 1000        ¿suma correcta? ¿igual en cada corrida?
 *   for i in 1 2 3 4 5; do ./caza3_reduce_buggy 1000 | grep verificacion; done
 * Sin GPU: NUMBA_ENABLE_CUDASIM=1 python3 caza3_reduce_numba.py 1000
 * Cuando lo corrijas (aquí y en el espejo Numba): make cazar
 */
#include <cstdio>
#include <cstdlib>
#include <cmath>
#include <cuda_runtime.h>

#define BLOCK 256      /* tamaño máximo de bloque: la memoria compartida se reserva con este tamaño */

#define CUDA_CHECK(call)                                                                   \
    do {                                                                                   \
        cudaError_t e_ = (call);                                                           \
        if (e_ != cudaSuccess) {                                                           \
            fprintf(stderr, "error CUDA en %s:%d: %s\n", __FILE__, __LINE__, cudaGetErrorString(e_)); \
            exit(1);                                                                       \
        }                                                                                  \
    } while (0)

__global__ void block_sum(const float *x, float *partial, int n) {
    __shared__ float s[BLOCK];
    int tid = threadIdx.x;
    int i = blockIdx.x * blockDim.x + tid;
    s[tid] = (i < n) ? x[i] : 0.0f;                  /* carga con guardia; los sobrantes aportan 0 */
    __syncthreads();                                 /* todo el bloque terminó de cargar */
    for (int stride = blockDim.x / 2; stride > 0; stride >>= 1) {
        if (tid < stride)
            s[tid] += s[tid + stride];               /* nivel del árbol: la mitad baja suma a la alta */
    }
    if (tid == 0) partial[blockIdx.x] = s[0];        /* suma parcial del bloque */
}

static int cmp_float(const void *p, const void *q) {
    float a = *(const float *) p, b = *(const float *) q;
    return (a > b) - (a < b);
}

int main(int argc, char **argv) {
    int n = argc > 1 ? atoi(argv[1]) : 1000;
    int block = argc > 2 ? atoi(argv[2]) : BLOCK;
    if (n <= 0 || block <= 0 || block > BLOCK || (block & (block - 1)) != 0) {
        fprintf(stderr, "uso: %s [n>0] [block: potencia de 2, <= %d]\n", argv[0], BLOCK);
        return 1;
    }
    int grid = (n + block - 1) / block;

    float *h_x = (float *) malloc(n * sizeof(float));
    float *h_partial = (float *) malloc(grid * sizeof(float));
    double ref = 0.0;
    for (int i = 0; i < n; i++) { h_x[i] = (float) (i % 10) + 1.0f; ref += h_x[i]; }

    float *d_x, *d_partial;
    CUDA_CHECK(cudaMalloc(&d_x, n * sizeof(float)));
    CUDA_CHECK(cudaMalloc(&d_partial, grid * sizeof(float)));
    CUDA_CHECK(cudaMemcpy(d_x, h_x, n * sizeof(float), cudaMemcpyHostToDevice));

    /* Protocolo: 1 calentamiento + 5 repeticiones con eventos; solo el kernel. */
    cudaEvent_t t0, t1;
    CUDA_CHECK(cudaEventCreate(&t0));
    CUDA_CHECK(cudaEventCreate(&t1));
    float times[5];
    for (int r = -1; r < 5; r++) {
        CUDA_CHECK(cudaEventRecord(t0));
        block_sum<<<grid, block>>>(d_x, d_partial, n);
        CUDA_CHECK(cudaEventRecord(t1));
        CUDA_CHECK(cudaEventSynchronize(t1));
        if (r >= 0) CUDA_CHECK(cudaEventElapsedTime(&times[r], t0, t1));
    }
    cudaError_t launch_err = cudaGetLastError();
    cudaError_t exec_err = cudaDeviceSynchronize();
    CUDA_CHECK(cudaMemcpy(h_partial, d_partial, grid * sizeof(float), cudaMemcpyDeviceToHost));

    /* El anfitrión termina la reducción (segunda etapa) y verifica contra la CPU. */
    double sum = 0.0;
    for (int b = 0; b < grid; b++) sum += h_partial[b];
    qsort(times, 5, sizeof(float), cmp_float);
    int ok = (fabs(sum - ref) <= 1e-6 * fabs(ref) && launch_err == cudaSuccess && exec_err == cudaSuccess);

    printf("caza3: n=%d block=%d grid=%d\n", n, block, grid);
    printf("cudaGetLastError=%s cudaDeviceSynchronize=%s\n",
           cudaGetErrorString(launch_err), cudaGetErrorString(exec_err));
    if (grid <= 8) {
        printf("parciales_gpu=");
        for (int b = 0; b < grid; b++) printf("%s%.1f", b ? "," : "", h_partial[b]);
        printf("\n");
    }
    printf("suma_gpu=%.1f suma_cpu=%.1f\n", sum, ref);
    printf("t_kernel_ms=%.4f (mediana de 5, solo kernel)\n", times[2]);
    printf("verificacion=%s\n", ok ? "OK" : "FALLA");

    CUDA_CHECK(cudaEventDestroy(t0));
    CUDA_CHECK(cudaEventDestroy(t1));
    CUDA_CHECK(cudaFree(d_x));
    CUDA_CHECK(cudaFree(d_partial));
    free(h_x);
    free(h_partial);
    return ok ? 0 : 2;
}
