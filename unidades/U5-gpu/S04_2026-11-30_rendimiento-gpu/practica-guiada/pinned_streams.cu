// pinned_streams.cu — Panorama S04: memoria paginable vs. pinned vs. pinned + streams (solapar copia y cómputo)
//
// Compilar en Colab/Kaggle:  nvcc -O2 -arch=sm_75 -o pinned_streams pinned_streams.cu   (sm_60 en una P100)
// Verificar sin GPU:         nvcc -c -arch=sm_75 pinned_streams.cu
// Uso:                       ./pinned_streams [n] [n_streams]      (por defecto n = 2^24, 4 streams)
//
// Tres maneras de calcular out = alpha*x + y cuando los datos empiezan y terminan en la CPU:
//   A. malloc (memoria paginable) + cudaMemcpy síncrono        H2D -> kernel -> D2H, todo en serie
//   B. cudaMallocHost (memoria pinned) + cudaMemcpy síncrono   la misma serie, pero la copia va por DMA directo
//   C. pinned + cudaMemcpyAsync en varios streams              el trozo k se copia mientras el trozo k-1 se calcula
// Protocolo: 1 calentamiento + 5 repeticiones; mediana. Cada versión se verifica contra la CPU.
#include <cstdio>
#include <cstdlib>
#include <cmath>
#include <cuda_runtime.h>

#define CUDA_CHECK(call)                                                          \
    do {                                                                          \
        cudaError_t err__ = (call);                                               \
        if (err__ != cudaSuccess) {                                               \
            fprintf(stderr, "Error CUDA en %s:%d: %s\n", __FILE__, __LINE__,     \
                    cudaGetErrorString(err__));                                   \
            exit(EXIT_FAILURE);                                                   \
        }                                                                         \
    } while (0)

static const int N_REPS = 5;
static const int BLOCK_SIZE = 256;
static const int MAX_STREAMS = 16;

__global__ void saxpy_kernel(float alpha, const float *x, const float *y, float *out, int n)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) out[i] = alpha * x[i] + y[i];
}

static int compare_double(const void *a, const void *b)
{
    double da = *(const double *)a, db = *(const double *)b;
    return (da > db) - (da < db);
}

typedef struct {
    int n, n_streams;
    float alpha;
    const float *h_x, *h_y;  // entradas (paginables o pinned según la versión)
    float *h_out;            // salida del anfitrión
    float *d_x, *d_y, *d_out;
    cudaStream_t *streams;
} Config;

// Versión A o B: tres operaciones síncronas en el stream 0. Lo único que cambia es de dónde viene h_x/h_y.
static void run_sync(const Config *c)
{
    size_t bytes = (size_t)c->n * sizeof(float);
    int grid = (c->n + BLOCK_SIZE - 1) / BLOCK_SIZE;
    CUDA_CHECK(cudaMemcpy(c->d_x, c->h_x, bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(c->d_y, c->h_y, bytes, cudaMemcpyHostToDevice));
    saxpy_kernel<<<grid, BLOCK_SIZE>>>(c->alpha, c->d_x, c->d_y, c->d_out, c->n);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaMemcpy(c->h_out, c->d_out, bytes, cudaMemcpyDeviceToHost));
}

// Versión C: el vector se parte en n_streams trozos; cada trozo tiene su propia secuencia H2D -> kernel -> D2H
// en su stream. Los motores de copia y los SM trabajan en paralelo sobre trozos distintos.
// Requisito: memoria pinned. Con memoria paginable cudaMemcpyAsync se vuelve síncrona y no hay solape.
static void run_streams(const Config *c)
{
    int chunk = (c->n + c->n_streams - 1) / c->n_streams;
    for (int s = 0; s < c->n_streams; ++s) {
        int offset = s * chunk;
        int len = c->n - offset;
        if (len <= 0) break;
        if (len > chunk) len = chunk;
        size_t bytes = (size_t)len * sizeof(float);
        int grid = (len + BLOCK_SIZE - 1) / BLOCK_SIZE;
        cudaStream_t st = c->streams[s];
        CUDA_CHECK(cudaMemcpyAsync(c->d_x + offset, c->h_x + offset, bytes, cudaMemcpyHostToDevice, st));
        CUDA_CHECK(cudaMemcpyAsync(c->d_y + offset, c->h_y + offset, bytes, cudaMemcpyHostToDevice, st));
        saxpy_kernel<<<grid, BLOCK_SIZE, 0, st>>>(c->alpha, c->d_x + offset, c->d_y + offset,
                                                  c->d_out + offset, len);
        CUDA_CHECK(cudaGetLastError());
        CUDA_CHECK(cudaMemcpyAsync(c->h_out + offset, c->d_out + offset, bytes, cudaMemcpyDeviceToHost, st));
    }
    // No hace falta cudaStreamSynchronize aquí: el evento de fin se graba en el stream 0 (legado), que espera
    // a todos los streams "bloqueantes" creados con cudaStreamCreate.
}

// Mide una versión completa (copias + kernel) con eventos en el stream 0; devuelve la mediana en ms.
static double measure_ms(const Config *c, int use_streams)
{
    cudaEvent_t start, stop;
    CUDA_CHECK(cudaEventCreate(&start));
    CUDA_CHECK(cudaEventCreate(&stop));
    double t[N_REPS];
    for (int r = -1; r < N_REPS; ++r) {
        CUDA_CHECK(cudaEventRecord(start, 0));
        if (use_streams) run_streams(c);
        else run_sync(c);
        CUDA_CHECK(cudaEventRecord(stop, 0));
        CUDA_CHECK(cudaEventSynchronize(stop));
        float ms;
        CUDA_CHECK(cudaEventElapsedTime(&ms, start, stop));
        if (r >= 0) t[r] = ms;
    }
    CUDA_CHECK(cudaEventDestroy(start));
    CUDA_CHECK(cudaEventDestroy(stop));
    qsort(t, N_REPS, sizeof(double), compare_double);
    printf("   (min %.3f ms, max %.3f ms)\n", t[0], t[N_REPS - 1]);
    return t[N_REPS / 2];
}

static int verify(const float *out, const float *x, const float *y, float alpha, int n)
{
    double max_err = 0.0;
    for (int i = 0; i < n; ++i) {
        double err = fabs((double)alpha * x[i] + y[i] - out[i]);
        if (err > max_err) max_err = err;
    }
    return max_err < 1e-5;
}

int main(int argc, char **argv)
{
    int n = (argc > 1) ? atoi(argv[1]) : (1 << 24);
    int n_streams = (argc > 2) ? atoi(argv[2]) : 4;
    if (n <= 0 || n_streams < 1 || n_streams > MAX_STREAMS) {
        fprintf(stderr, "Uso: %s [n > 0] [1 <= n_streams <= %d]\n", argv[0], MAX_STREAMS);
        return EXIT_FAILURE;
    }
    size_t bytes = (size_t)n * sizeof(float);
    const float alpha = 2.0f;

    // Dos juegos de arreglos del anfitrión: paginables (malloc) y fijos (cudaMallocHost).
    float *pg_x = (float *)malloc(bytes), *pg_y = (float *)malloc(bytes), *pg_out = (float *)malloc(bytes);
    float *pn_x = NULL, *pn_y = NULL, *pn_out = NULL;
    if (!pg_x || !pg_y || !pg_out) {
        fprintf(stderr, "Sin memoria en el anfitrión\n");
        return EXIT_FAILURE;
    }
    CUDA_CHECK(cudaMallocHost((void **)&pn_x, bytes));
    CUDA_CHECK(cudaMallocHost((void **)&pn_y, bytes));
    CUDA_CHECK(cudaMallocHost((void **)&pn_out, bytes));
    for (int i = 0; i < n; ++i) {
        pg_x[i] = pn_x[i] = (float)(i % 1000) * 0.001f;
        pg_y[i] = pn_y[i] = 1.0f + (float)(i % 7);
    }

    float *d_x = NULL, *d_y = NULL, *d_out = NULL;
    CUDA_CHECK(cudaMalloc((void **)&d_x, bytes));
    CUDA_CHECK(cudaMalloc((void **)&d_y, bytes));
    CUDA_CHECK(cudaMalloc((void **)&d_out, bytes));

    cudaStream_t streams[MAX_STREAMS];
    for (int s = 0; s < n_streams; ++s) CUDA_CHECK(cudaStreamCreate(&streams[s]));

    cudaDeviceProp prop;
    CUDA_CHECK(cudaGetDeviceProperties(&prop, 0));
    printf("pinned_streams: GPU %s · n = %d (%.1f MB por vector) · %d streams · motores de copia: %d\n", prop.name,
           n, (double)bytes / 1048576.0, n_streams, prop.asyncEngineCount);

    Config a = {n, n_streams, alpha, pg_x, pg_y, pg_out, d_x, d_y, d_out, streams};
    Config b = {n, n_streams, alpha, pn_x, pn_y, pn_out, d_x, d_y, d_out, streams};

    printf("A. paginable, síncrona\n");
    double t_a = measure_ms(&a, 0);
    int ok_a = verify(pg_out, pg_x, pg_y, alpha, n);
    printf("B. pinned (cudaMallocHost), síncrona\n");
    double t_b = measure_ms(&b, 0);
    int ok_b = verify(pn_out, pn_x, pn_y, alpha, n);
    printf("C. pinned + %d streams, asíncrona\n", n_streams);
    double t_c = measure_ms(&b, 1);
    int ok_c = verify(pn_out, pn_x, pn_y, alpha, n);

    printf("\n%-40s %12s %12s\n", "Versión (H2D + kernel + D2H)", "mediana ms", "vs. A");
    printf("%-40s %12.3f %11.2fx\n", "A. paginable, síncrona", t_a, 1.0);
    printf("%-40s %12.3f %11.2fx\n", "B. pinned, síncrona", t_b, t_a / t_b);
    printf("%-40s %12.3f %11.2fx\n", "C. pinned + streams, asíncrona", t_c, t_a / t_c);
    printf("Verificación contra CPU: A %s · B %s · C %s\n", ok_a ? "OK" : "FALLA", ok_b ? "OK" : "FALLA",
           ok_c ? "OK" : "FALLA");

    for (int s = 0; s < n_streams; ++s) CUDA_CHECK(cudaStreamDestroy(streams[s]));
    CUDA_CHECK(cudaFree(d_x));
    CUDA_CHECK(cudaFree(d_y));
    CUDA_CHECK(cudaFree(d_out));
    CUDA_CHECK(cudaFreeHost(pn_x));
    CUDA_CHECK(cudaFreeHost(pn_y));
    CUDA_CHECK(cudaFreeHost(pn_out));
    free(pg_x);
    free(pg_y);
    free(pg_out);
    CUDA_CHECK(cudaDeviceReset());
    return (ok_a && ok_b && ok_c) ? EXIT_SUCCESS : EXIT_FAILURE;
}
