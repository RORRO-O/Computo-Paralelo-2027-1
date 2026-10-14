/*
 * histogram.cu — Histograma de n valores en [0, BINS) en la GPU (Unidad V, S03; conecta con la Práctica 4).
 *
 *   global   cada hilo hace atomicAdd(&hist[v[i]], 1) sobre el histograma en memoria GLOBAL:
 *            n atómicas que compiten por las mismas BINS direcciones (contención alta si los datos
 *            están sesgados: aquí ≈ 30 % cae en el bin 0: 25 % forzado por i % 4 == 0 más lo que
 *            el hash reparte en ese bin).
 *   shared   TODO(1) (fase Crear): histograma PRIVADO por bloque en memoria compartida con atómicas
 *            baratas, y al final un volcado de BINS atómicas por bloque al histograma global.
 *            Es la misma idea que los histogramas privados por hilo + reducción de la Práctica 4.
 *            Mientras no esté completo, el kernel no escribe nada y el programa imprime "TODO pendiente".
 *
 * Uso:  ./histogram [version: global|shared|all] [n] [block] [archivo.csv]     (por defecto all 1048576 256)
 * Datos (iguales en histogram_cpu.c y histogram_numba.py):
 *   v[i] = 0                                        si i % 4 == 0        (sesgo: contención en el bin 0)
 *   v[i] = (((uint32_t)i * 2654435761u) >> 24) % BINS  en otro caso     (hash multiplicativo, pseudoaleatorio)
 * Verificación: los conteos son enteros y deben coincidir EXACTAMENTE con la CPU (aquí no hay redondeo).
 *
 * Compilar y correr (GPU): nvcc -O2 -arch=sm_75 histogram.cu -o histogram && ./histogram
 * Sin GPU: nvcc -c -arch=sm_75 histogram.cu -o histogram.o        (solo comprueba que compila)
 * Otro número de bins (p. ej. bytes): nvcc -O2 -arch=sm_75 -DBINS=256 histogram.cu -o histogram256
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <cuda_runtime.h>

#ifndef BINS
#define BINS 16
#endif
#define REPS 5

#define CUDA_CHECK(call)                                                           \
    do {                                                                           \
        cudaError_t err__ = (call);                                                \
        if (err__ != cudaSuccess) {                                                \
            fprintf(stderr, "Error de CUDA en %s:%d: %s\n", __FILE__, __LINE__,   \
                    cudaGetErrorString(err__));                                    \
            exit(EXIT_FAILURE);                                                    \
        }                                                                          \
    } while (0)

/* ---------- Código de dispositivo ---------- */

/* Versión global: correcta; todos los hilos de todos los bloques golpean las mismas BINS direcciones. */
__global__ void hist_global_atomic(const unsigned char *v, unsigned int *hist, int n)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n)
        atomicAdd(&hist[v[i]], 1u);
}

/* TODO(1): histograma privado por bloque en memoria compartida.
 * Objetivo: mismo resultado que hist_global_atomic con BINS * gridDim.x atómicas globales en lugar de n.
 * Pistas en practica-guiada/README.md, sección "Crear". Supón BINS <= blockDim.x.
 * Mientras el cuerpo esté vacío, el anfitrión detecta el histograma en ceros e imprime "TODO pendiente". */
__global__ void hist_shared_atomic(const unsigned char *v, unsigned int *hist, int n)
{
    (void)v;
    (void)hist;
    (void)n;
}

/* ---------- Código de anfitrión ---------- */

static void init_data(unsigned char *v, int n)
{
    for (int i = 0; i < n; i++) {
        uint32_t h = ((uint32_t)i * 2654435761u) >> 24;   /* hash multiplicativo de Knuth; 0..255 */
        v[i] = (i % 4 == 0) ? 0 : (unsigned char)(h % BINS);
    }
}

static void histogram_cpu(const unsigned char *v, unsigned int *hist, int n)
{
    memset(hist, 0, BINS * sizeof(unsigned int));
    for (int i = 0; i < n; i++)
        hist[v[i]]++;
}

static int cmp_float(const void *a, const void *b)
{
    float fa = *(const float *)a, fb = *(const float *)b;
    return (fa > fb) - (fa < fb);
}

static float median_ms(float *t, int k)
{
    qsort(t, (size_t)k, sizeof(float), cmp_float);
    return t[k / 2];
}

static void print_hist(const char *label, const unsigned int *hist)
{
    printf("%s=[", label);
    for (int b = 0; b < BINS; b++)
        printf("%u%s", hist[b], (b + 1 < BINS) ? "," : "");
    printf("]\n");
}

/* Regresa 1 si la versión pasa (o si está pendiente), 0 si está mal. */
static int run_version(const char *version, const unsigned char *d_v, unsigned int *d_hist, int n, int block,
                       int grid, const unsigned int *h_ref, const char *gpu_name, const char *csv_path)
{
    int is_global = strcmp(version, "global") == 0;
    unsigned int h_hist[BINS];
    cudaEvent_t start, stop;
    CUDA_CHECK(cudaEventCreate(&start));
    CUDA_CHECK(cudaEventCreate(&stop));

    float t_kernel[REPS];
    for (int r = -1; r < REPS; r++) {           /* r = -1: calentamiento */
        CUDA_CHECK(cudaMemset(d_hist, 0, BINS * sizeof(unsigned int)));
        CUDA_CHECK(cudaEventRecord(start));
        if (is_global)
            hist_global_atomic<<<grid, block>>>(d_v, d_hist, n);
        else
            hist_shared_atomic<<<grid, block>>>(d_v, d_hist, n);
        CUDA_CHECK(cudaEventRecord(stop));
        CUDA_CHECK(cudaGetLastError());
        CUDA_CHECK(cudaEventSynchronize(stop));
        if (r >= 0)
            CUDA_CHECK(cudaEventElapsedTime(&t_kernel[r], start, stop));
    }
    CUDA_CHECK(cudaMemcpy(h_hist, d_hist, BINS * sizeof(unsigned int), cudaMemcpyDeviceToHost));

    unsigned long long total = 0;
    for (int b = 0; b < BINS; b++)
        total += h_hist[b];
    int exact = memcmp(h_hist, h_ref, BINS * sizeof(unsigned int)) == 0;
    int pending = (total == 0);
    long long atomics_global = is_global ? n : (long long)BINS * grid;
    long long atomics_shared = is_global ? 0 : n;

    float k_med = median_ms(t_kernel, REPS);
    printf("version=%-7s atomicas_globales=%-8lld atomicas_compartidas=%-8lld kernel_mediana_ms=%.4f (min %.4f, max %.4f)\n",
           version, atomics_global, atomics_shared, k_med, t_kernel[0], t_kernel[REPS - 1]);
    print_hist("   hist_gpu", h_hist);
    if (pending)
        printf("   total=0 -> TODO pendiente: hist_shared_atomic no escribe nada todavía (TODO(1))\n");
    else
        printf("   total=%llu verificacion=%s\n", total, exact ? "OK" : "FALLA");

    if (csv_path && !pending) {
        FILE *f = fopen(csv_path, "a");
        if (f) {
            fseek(f, 0, SEEK_END);
            if (ftell(f) == 0)
                fprintf(f, "gpu,version,bins,n,block,grid,atomicas_globales,atomicas_compartidas,"
                           "kernel_mediana_ms,kernel_min_ms,kernel_max_ms,verificacion\n");
            fprintf(f, "\"%s\",%s,%d,%d,%d,%d,%lld,%lld,%.4f,%.4f,%.4f,%s\n", gpu_name, version, BINS, n, block, grid,
                    atomics_global, atomics_shared, k_med, t_kernel[0], t_kernel[REPS - 1], exact ? "OK" : "FALLA");
            fclose(f);
        }
    }
    CUDA_CHECK(cudaEventDestroy(start));
    CUDA_CHECK(cudaEventDestroy(stop));
    return pending || exact;
}

int main(int argc, char **argv)
{
    const char *version = (argc > 1) ? argv[1] : "all";
    int n = (argc > 2) ? atoi(argv[2]) : (1 << 20);
    int block = (argc > 3) ? atoi(argv[3]) : 256;
    const char *csv_path = (argc > 4) ? argv[4] : NULL;
    int run_global = strcmp(version, "all") == 0 || strcmp(version, "global") == 0;
    int run_shared = strcmp(version, "all") == 0 || strcmp(version, "shared") == 0;

    if ((!run_global && !run_shared) || n <= 0 || block < BINS || block > 1024) {
        fprintf(stderr, "uso: %s [global|shared|all] [n>0] [block %d..1024] [archivo.csv]\n", argv[0], BINS);
        return 1;
    }
    int grid = (n + block - 1) / block;

    unsigned char *h_v = (unsigned char *)malloc((size_t)n);
    if (!h_v) {
        fprintf(stderr, "Sin memoria en el anfitrión para n=%d\n", n);
        return 1;
    }
    init_data(h_v, n);
    unsigned int h_ref[BINS];
    histogram_cpu(h_v, h_ref, n);

    cudaDeviceProp prop;
    CUDA_CHECK(cudaGetDeviceProperties(&prop, 0));
    printf("histogram (CUDA C): n=%d bins=%d block=%d grid=%d gpu=\"%s\" (SMs=%d, cc %d.%d)\n", n, BINS, block, grid,
           prop.name, prop.multiProcessorCount, prop.major, prop.minor);
    print_hist("hist_cpu", h_ref);

    unsigned char *d_v = NULL;
    unsigned int *d_hist = NULL;
    CUDA_CHECK(cudaMalloc((void **)&d_v, (size_t)n));
    CUDA_CHECK(cudaMalloc((void **)&d_hist, BINS * sizeof(unsigned int)));
    CUDA_CHECK(cudaMemcpy(d_v, h_v, (size_t)n, cudaMemcpyHostToDevice));

    int all_ok = 1;
    if (run_global)
        all_ok &= run_version("global", d_v, d_hist, n, block, grid, h_ref, prop.name, csv_path);
    if (run_shared)
        all_ok &= run_version("shared", d_v, d_hist, n, block, grid, h_ref, prop.name, csv_path);

    CUDA_CHECK(cudaFree(d_v));
    CUDA_CHECK(cudaFree(d_hist));
    free(h_v);
    return all_ok ? 0 : 2;
}
