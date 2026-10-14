/* ejemplo_gpu.cu — Suma de vectores en CUDA C con medición "con" y "sin" transferencias (protocolo §2).
 * Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · herramientas/ · acompaña a colab-kaggle.md
 *
 * Es el programa mínimo que una V3 o la Práctica 6 deben imitar en su salida:
 *   gpu=<nombre>  n=<n>  bloque=<hilos por bloque>  checksum=<suma>  tiempo_kernel_s=<solo kernel>
 *   tiempo_s=<kernel + copias anfitrión<->dispositivo>
 * medir.sh lee tiempo_s= (fila "con transferencias") y, con --clave tiempo_kernel_s, la fila "sin transferencias".
 *
 * Uso (en Colab/Kaggle, ver colab-kaggle.md):
 *   nvcc -O2 -arch=sm_75 ejemplo_gpu.cu -o ejemplo_gpu && ./ejemplo_gpu [n] [hilos_por_bloque]
 *   (n por defecto 50000000; hilos por bloque por defecto 256, múltiplo de 32)
 * Verificación local sin GPU (solo sintaxis):  nvcc -c -arch=sm_75 ejemplo_gpu.cu
 * Correctitud: checksum = sum(a[i] + b[i]) con a[i] = i mod 7, b[i] = 2*(i mod 5); se compara con el valor calculado
 * en la CPU dentro del mismo programa (imprime ok=1 si coincide con tolerancia relativa 1e-9).
 * Código de salida: 0 bien; 1 error de CUDA; 2 argumentos no válidos.
 */
#include <cuda_runtime.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#define CUDA_OK(llamada)                                                                   \
    do {                                                                                   \
        cudaError_t err__ = (llamada);                                                     \
        if (err__ != cudaSuccess) {                                                        \
            fprintf(stderr, "error CUDA en %s:%d: %s\n", __FILE__, __LINE__,               \
                    cudaGetErrorString(err__));                                            \
            exit(1);                                                                       \
        }                                                                                  \
    } while (0)

__global__ void suma_vectores(const float *a, const float *b, float *c, long n)
{
    long i = (long)blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n)
        c[i] = a[i] + b[i];
}

int main(int argc, char **argv)
{
    long n = 50000000L;
    int bloque = 256;
    if (argc > 1) {
        n = atol(argv[1]);
        if (n < 1) {
            fprintf(stderr, "n debe ser un entero >= 1\n");
            return 2;
        }
    }
    if (argc > 2) {
        bloque = atoi(argv[2]);
        if (bloque < 1 || bloque > 1024 || bloque % 32 != 0) {
            fprintf(stderr, "hilos_por_bloque debe ser múltiplo de 32 entre 32 y 1024\n");
            return 2;
        }
    }

    size_t bytes = (size_t)n * sizeof(float);
    float *h_a = (float *)malloc(bytes), *h_b = (float *)malloc(bytes), *h_c = (float *)malloc(bytes);
    if (h_a == NULL || h_b == NULL || h_c == NULL) {
        fprintf(stderr, "sin memoria en el anfitrión para n=%ld\n", n);
        return 2;
    }
    double esperado = 0.0;
    for (long i = 0; i < n; i++) {
        h_a[i] = (float)(i % 7);
        h_b[i] = (float)(2 * (i % 5));
        esperado += (double)h_a[i] + (double)h_b[i];
    }

    cudaDeviceProp prop;
    CUDA_OK(cudaGetDeviceProperties(&prop, 0));

    float *d_a, *d_b, *d_c;
    CUDA_OK(cudaMalloc(&d_a, bytes));
    CUDA_OK(cudaMalloc(&d_b, bytes));
    CUDA_OK(cudaMalloc(&d_c, bytes));

    cudaEvent_t ini_total, ini_kernel, fin_kernel, fin_total;
    CUDA_OK(cudaEventCreate(&ini_total));
    CUDA_OK(cudaEventCreate(&ini_kernel));
    CUDA_OK(cudaEventCreate(&fin_kernel));
    CUDA_OK(cudaEventCreate(&fin_total));

    int bloques = (int)((n + bloque - 1) / bloque);

    /* Calentamiento: la primera llamada paga la carga del módulo; no se cuenta (protocolo §2). */
    suma_vectores<<<bloques, bloque>>>(d_a, d_b, d_c, n);
    CUDA_OK(cudaGetLastError());
    CUDA_OK(cudaDeviceSynchronize());

    /* Región de interés "con transferencias": H2D + kernel + D2H. */
    CUDA_OK(cudaEventRecord(ini_total));
    CUDA_OK(cudaMemcpy(d_a, h_a, bytes, cudaMemcpyHostToDevice));
    CUDA_OK(cudaMemcpy(d_b, h_b, bytes, cudaMemcpyHostToDevice));
    CUDA_OK(cudaEventRecord(ini_kernel));
    suma_vectores<<<bloques, bloque>>>(d_a, d_b, d_c, n);
    CUDA_OK(cudaGetLastError()); /* errores de lanzamiento (p. ej. arch incorrecta) */
    CUDA_OK(cudaEventRecord(fin_kernel));
    CUDA_OK(cudaMemcpy(h_c, d_c, bytes, cudaMemcpyDeviceToHost));
    CUDA_OK(cudaEventRecord(fin_total));
    CUDA_OK(cudaEventSynchronize(fin_total)); /* sin esto el reloj se detiene antes de que termine la GPU */

    float ms_kernel = 0.0f, ms_total = 0.0f;
    CUDA_OK(cudaEventElapsedTime(&ms_kernel, ini_kernel, fin_kernel));
    CUDA_OK(cudaEventElapsedTime(&ms_total, ini_total, fin_total));

    double checksum = 0.0;
    for (long i = 0; i < n; i++)
        checksum += (double)h_c[i];
    int ok = fabs(checksum - esperado) <= 1e-9 * fabs(esperado);

    printf("gpu=%s\n", prop.name);
    printf("n=%ld\n", n);
    printf("bloque=%d\n", bloque);
    printf("checksum=%.1f\n", checksum);
    printf("ok=%d\n", ok);
    printf("tiempo_kernel_s=%.6f\n", ms_kernel / 1000.0);
    printf("tiempo_s=%.6f\n", ms_total / 1000.0);

    CUDA_OK(cudaFree(d_a));
    CUDA_OK(cudaFree(d_b));
    CUDA_OK(cudaFree(d_c));
    free(h_a);
    free(h_b);
    free(h_c);
    return ok ? 0 : 1;
}
