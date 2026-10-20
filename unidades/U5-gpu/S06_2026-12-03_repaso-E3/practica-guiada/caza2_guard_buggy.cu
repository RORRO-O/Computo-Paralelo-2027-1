/* caza2_guard_buggy.cu — Cazador de errores 2 (CUDA): y = a·x + b, un hilo por elemento.
 *
 * Qué hace cuando funciona: y[i] = 2·x[i] + 1 para i < n, con x[i] = i % 7.
 * Referencia: ./caza_cpu axpb 1000  →  checksum=6994.0
 *
 * Detector incluido: el programa reserva cap = grid·block elementos (múltiplo del bloque) y pone
 * y[n..cap) = -1 (centinelas). Si un hilo sobrante escribe ahí, se nota. En un programa real NO hay
 * centinelas: ese hilo escribe sobre otro arreglo o fuera de la reserva (a veces "illegal memory
 * access", a veces nada visible).
 *
 * Contiene UN error a propósito. Escribe tu predicción antes de correr:
 *   ./caza2_guard_buggy 1000 256     ¿cuántos hilos se lanzan? ¿cuántos sobran? ¿qué hacen?
 *   ./caza2_guard_buggy 1024 256     ¿y ahora?
 * Sin GPU: NUMBA_ENABLE_CUDASIM=1 python3 caza2_guard_numba.py 1000 256
 * Cuando lo corrijas (aquí y en el espejo Numba): make cazar
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

__global__ void axpb(const float *x, float *y, float a, float b, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;   /* índice global del hilo */
    y[i] = a * x[i] + b;                             /* un elemento por hilo */
}

static int cmp_float(const void *p, const void *q) {
    float a = *(const float *) p, b = *(const float *) q;
    return (a > b) - (a < b);
}

int main(int argc, char **argv) {
    int n = argc > 1 ? atoi(argv[1]) : 1000;
    int block = argc > 2 ? atoi(argv[2]) : 256;
    if (n <= 0 || block <= 0 || block > 1024) {
        fprintf(stderr, "uso: %s [n>0] [block 1..1024]\n", argv[0]);
        return 1;
    }
    const float a = 2.0f, b = 1.0f;
    int grid = (n + block - 1) / block;              /* bloques: redondeo hacia arriba */
    int cap = grid * block;                          /* hilos lanzados = elementos reservados */

    /* Anfitrión: x válido en [0, n); relleno 0 en [n, cap). y arranca en -1 (centinela) en todo cap. */
    float *h_x = (float *) malloc(cap * sizeof(float));
    float *h_y = (float *) malloc(cap * sizeof(float));
    for (int i = 0; i < cap; i++) {
        h_x[i] = (i < n) ? (float) (i % 7) : 0.0f;
        h_y[i] = -1.0f;
    }

    float *d_x, *d_y;
    CUDA_CHECK(cudaMalloc(&d_x, cap * sizeof(float)));
    CUDA_CHECK(cudaMalloc(&d_y, cap * sizeof(float)));
    CUDA_CHECK(cudaMemcpy(d_x, h_x, cap * sizeof(float), cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_y, h_y, cap * sizeof(float), cudaMemcpyHostToDevice));

    /* Protocolo: 1 calentamiento + 5 repeticiones, eventos, mediana. Solo el kernel. */
    cudaEvent_t t0, t1;
    CUDA_CHECK(cudaEventCreate(&t0));
    CUDA_CHECK(cudaEventCreate(&t1));
    float times[5];
    for (int r = -1; r < 5; r++) {
        CUDA_CHECK(cudaEventRecord(t0));
        axpb<<<grid, block>>>(d_x, d_y, a, b, n);
        CUDA_CHECK(cudaEventRecord(t1));
        CUDA_CHECK(cudaEventSynchronize(t1));
        if (r >= 0) CUDA_CHECK(cudaEventElapsedTime(&times[r], t0, t1));
    }
    cudaError_t launch_err = cudaGetLastError();        /* error de lanzamiento, si lo hubo */
    cudaError_t exec_err = cudaDeviceSynchronize();     /* error de ejecución (p. ej. acceso ilegal) */
    CUDA_CHECK(cudaMemcpy(h_y, d_y, cap * sizeof(float), cudaMemcpyDeviceToHost));

    /* Verificación: (1) los n válidos contra la CPU; (2) los centinelas siguen en -1. */
    int wrong = 0, altered = 0;
    double checksum = 0.0;
    for (int i = 0; i < n; i++) {
        float ref = a * h_x[i] + b;
        if (fabsf(h_y[i] - ref) > 1e-5f) wrong++;
        checksum += h_y[i];
    }
    for (int i = n; i < cap; i++)
        if (h_y[i] != -1.0f) altered++;
    qsort(times, 5, sizeof(float), cmp_float);

    printf("caza2: n=%d block=%d grid=%d hilos_lanzados=%d sobrantes=%d\n", n, block, grid, cap, cap - n);
    printf("cudaGetLastError=%s cudaDeviceSynchronize=%s\n",
           cudaGetErrorString(launch_err), cudaGetErrorString(exec_err));
    printf("checksum=%.1f elementos_incorrectos=%d centinelas_alterados=%d (de %d)\n",
           checksum, wrong, altered, cap - n);
    printf("t_kernel_ms=%.4f (mediana de 5, solo kernel)\n", times[2]);
    int ok = (wrong == 0 && altered == 0 && launch_err == cudaSuccess && exec_err == cudaSuccess);
    printf("verificacion=%s\n", ok ? "OK" : "FALLA");

    CUDA_CHECK(cudaEventDestroy(t0));
    CUDA_CHECK(cudaEventDestroy(t1));
    CUDA_CHECK(cudaFree(d_x));
    CUDA_CHECK(cudaFree(d_y));
    free(h_x);
    free(h_y);
    return ok ? 0 : 2;
}
