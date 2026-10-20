// bench_gpu.cu — Práctica guiada S04: barrido de tamaño de bloque y de tamaño del problema, con los
// tiempos de copia (H2D, D2H) y de kernel medidos por separado con cudaEvent_t.
//
// Compilar en Colab/Kaggle:  nvcc -O2 -arch=sm_75 -o bench_gpu bench_gpu.cu   (sm_60 en una P100)
// Verificar sin GPU:         nvcc -c -arch=sm_75 bench_gpu.cu
//
// Uso:
//   ./bench_gpu bloque <n>      <salida.csv> [pinned]   barrido de bloque {32,64,...,1024} con n fijo
//   ./bench_gpu umbral <bloque> <salida.csv> [pinned]   barrido de n = 2^10, 2^12, ..., 2^26 con bloque fijo
//
// Imprime una tabla y AGREGA filas al CSV (escribe el encabezado si el archivo está vacío), así varias
// corridas se juntan en un solo archivo que lee graficar.py.
// Protocolo del curso: 1 calentamiento + 5 repeticiones; se reporta la mediana. Todo se verifica contra la CPU.
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cmath>
#include <ctime>
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
static const int BLOCK_SIZES[] = {32, 64, 128, 256, 512, 1024};  // Modificar: agrega 48 o 96 y predice antes
static const int N_BLOCK_SIZES = (int)(sizeof(BLOCK_SIZES) / sizeof(BLOCK_SIZES[0]));
static const int LOG2_N_MIN = 10, LOG2_N_MAX = 26, LOG2_N_STEP = 2;
static const float ALPHA = 2.0f;

typedef enum { K_VECTOR_ADD = 0, K_SAXPY = 1 } KernelId;
static const char *KERNEL_NAMES[] = {"vector_add", "saxpy"};

typedef struct {
    double h2d_ms, kernel_ms, d2h_ms;  // medianas de N_REPS repeticiones
} GpuTimes;

// ----- Kernels: un hilo por elemento, dos vectores de entrada y uno de salida (12 bytes por elemento).
__global__ void vector_add_kernel(const float *a, const float *b, float *c, int n)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) c[i] = a[i] + b[i];  // 1 FLOP por 12 bytes: intensidad aritmética 0.083 FLOP/byte
}

__global__ void saxpy_kernel(float alpha, const float *x, const float *y, float *out, int n)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) out[i] = alpha * x[i] + y[i];  // 2 FLOP por 12 bytes: 0.167 FLOP/byte
}

// ----- Referencias en CPU (el "mejor programa secuencial" contra el que se calcula el speedup).
static void vector_add_cpu(const float *a, const float *b, float *c, int n)
{
    for (int i = 0; i < n; ++i) c[i] = a[i] + b[i];
}

static void saxpy_cpu(float alpha, const float *x, const float *y, float *out, int n)
{
    for (int i = 0; i < n; ++i) out[i] = alpha * x[i] + y[i];
}

// ----- Utilidades de medición.
static double cpu_seconds(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + 1e-9 * (double)ts.tv_nsec;
}

static int compare_double(const void *a, const void *b)
{
    double da = *(const double *)a, db = *(const double *)b;
    return (da > db) - (da < db);
}

static double median_of(double *v, int n)
{
    qsort(v, (size_t)n, sizeof(double), compare_double);
    return v[n / 2];
}

static void *host_alloc(size_t bytes, int pinned)
{
    void *p = NULL;
    if (pinned) {
        CUDA_CHECK(cudaMallocHost(&p, bytes));  // memoria fija (pinned): la copia va por DMA sin paso intermedio
    } else {
        p = malloc(bytes);  // memoria paginable: el driver copia primero a un búfer fijo interno
        if (!p) {
            fprintf(stderr, "Sin memoria en el anfitrión (%zu bytes)\n", bytes);
            exit(EXIT_FAILURE);
        }
    }
    return p;
}

static void host_free(void *p, int pinned)
{
    if (pinned) CUDA_CHECK(cudaFreeHost(p));
    else free(p);
}

static void init_inputs(float *a, float *b, int n)
{
    for (int i = 0; i < n; ++i) {
        a[i] = (float)(i % 1000) * 0.001f;
        b[i] = 1.0f + (float)(i % 7);
    }
}

static double max_abs_error(const float *got, const float *ref, int n)
{
    double max_err = 0.0;
    for (int i = 0; i < n; ++i) {
        double err = fabs((double)got[i] - (double)ref[i]);
        if (err > max_err) max_err = err;
    }
    return max_err;
}

// Mediana del tiempo de la versión secuencial (1 calentamiento + N_REPS repeticiones). Deja el resultado en c.
static double measure_cpu_ms(KernelId k, int n, const float *a, const float *b, float *c)
{
    double t[N_REPS];
    for (int r = -1; r < N_REPS; ++r) {
        double t0 = cpu_seconds();
        if (k == K_VECTOR_ADD) vector_add_cpu(a, b, c, n);
        else saxpy_cpu(ALPHA, a, b, c, n);
        double dt = (cpu_seconds() - t0) * 1e3;
        if (r >= 0) t[r] = dt;
    }
    return median_of(t, N_REPS);
}

// Mide H2D, kernel y D2H por separado con cuatro eventos en el stream 0. Deja la salida de la última
// repetición en h_c para verificarla.
static GpuTimes measure_gpu(KernelId k, int n, int block, const float *h_a, const float *h_b, float *h_c)
{
    size_t bytes = (size_t)n * sizeof(float);
    float *d_a = NULL, *d_b = NULL, *d_c = NULL;
    CUDA_CHECK(cudaMalloc((void **)&d_a, bytes));
    CUDA_CHECK(cudaMalloc((void **)&d_b, bytes));
    CUDA_CHECK(cudaMalloc((void **)&d_c, bytes));

    cudaEvent_t ev[4];
    for (int i = 0; i < 4; ++i) CUDA_CHECK(cudaEventCreate(&ev[i]));

    int grid = (n + block - 1) / block;
    double h2d[N_REPS], ker[N_REPS], d2h[N_REPS];

    for (int r = -1; r < N_REPS; ++r) {  // r = -1 es el calentamiento
        // Borra la salida ANTES de medir (fuera de los eventos): si el kernel no corre o las operaciones van en
        // otro orden, la verificación ve ceros y falla, en vez de aprobar el resultado de la repetición anterior.
        CUDA_CHECK(cudaMemset(d_c, 0, bytes));
        CUDA_CHECK(cudaEventRecord(ev[0], 0));
        CUDA_CHECK(cudaMemcpy(d_a, h_a, bytes, cudaMemcpyHostToDevice));
        CUDA_CHECK(cudaMemcpy(d_b, h_b, bytes, cudaMemcpyHostToDevice));
        CUDA_CHECK(cudaEventRecord(ev[1], 0));
        if (k == K_VECTOR_ADD) vector_add_kernel<<<grid, block>>>(d_a, d_b, d_c, n);
        else saxpy_kernel<<<grid, block>>>(ALPHA, d_a, d_b, d_c, n);
        CUDA_CHECK(cudaEventRecord(ev[2], 0));
        CUDA_CHECK(cudaMemcpy(h_c, d_c, bytes, cudaMemcpyDeviceToHost));
        CUDA_CHECK(cudaEventRecord(ev[3], 0));
        CUDA_CHECK(cudaEventSynchronize(ev[3]));
        // Un lanzamiento inválido (bloque > 1024, demasiados registros por hilo) NO hace fallar a cudaMemcpy ni a
        // los eventos: queda anotado y solo cudaGetLastError lo reporta. Por eso esta revisión es obligatoria.
        CUDA_CHECK(cudaGetLastError());

        float ms;
        if (r >= 0) {
            CUDA_CHECK(cudaEventElapsedTime(&ms, ev[0], ev[1]));
            h2d[r] = ms;
            CUDA_CHECK(cudaEventElapsedTime(&ms, ev[1], ev[2]));
            ker[r] = ms;
            CUDA_CHECK(cudaEventElapsedTime(&ms, ev[2], ev[3]));
            d2h[r] = ms;
        }
    }

    GpuTimes t;
    t.h2d_ms = median_of(h2d, N_REPS);
    t.kernel_ms = median_of(ker, N_REPS);
    t.d2h_ms = median_of(d2h, N_REPS);

    for (int i = 0; i < 4; ++i) CUDA_CHECK(cudaEventDestroy(ev[i]));
    CUDA_CHECK(cudaFree(d_a));
    CUDA_CHECK(cudaFree(d_b));
    CUDA_CHECK(cudaFree(d_c));
    return t;
}

// Ocupación teórica: warps residentes por SM que permite este kernel con este bloque, entre el máximo del SM.
static double occupancy_pct(KernelId k, int block, int max_threads_per_sm)
{
    int blocks_per_sm = 0;
    if (k == K_VECTOR_ADD)
        CUDA_CHECK(cudaOccupancyMaxActiveBlocksPerMultiprocessor(&blocks_per_sm, vector_add_kernel, block, 0));
    else
        CUDA_CHECK(cudaOccupancyMaxActiveBlocksPerMultiprocessor(&blocks_per_sm, saxpy_kernel, block, 0));
    int warps_per_block = (block + 31) / 32;  // un bloque de 48 hilos ocupa 2 warps, uno de ellos a medias
    int max_warps = max_threads_per_sm / 32;
    return 100.0 * blocks_per_sm * warps_per_block / max_warps;
}

// ----- Salida: tabla en pantalla y fila CSV.
static const char *CSV_HEADER =
    "experimento,kernel,n,block,grid,ocupacion_pct,memoria,t_h2d_ms,t_kernel_ms,t_d2h_ms,t_total_ms,"
    "t_cpu_ms,speedup_kernel,speedup_total,ancho_banda_gbs,origen,dispositivo\n";

static FILE *open_csv(const char *path)
{
    FILE *f = fopen(path, "a");
    if (!f) {
        fprintf(stderr, "No se pudo abrir %s\n", path);
        exit(EXIT_FAILURE);
    }
    fseek(f, 0, SEEK_END);
    if (ftell(f) == 0) fputs(CSV_HEADER, f);
    return f;
}

static void print_table_header(void)
{
    printf("%-10s %10s %6s %8s %6s %9s %10s %9s %10s %10s %8s %8s %7s\n", "kernel", "n", "bloque",
           "malla", "ocup%", "H2D ms", "kernel ms", "D2H ms", "total ms", "CPU ms", "S_kern", "S_total",
           "GB/s");
}

static void emit_row(FILE *csv, const char *experiment, KernelId k, int n, int block, double occ,
                     const char *memory, GpuTimes t, double cpu_ms, const char *device)
{
    int grid = (n + block - 1) / block;
    double total = t.h2d_ms + t.kernel_ms + t.d2h_ms;
    double bytes_moved = 3.0 * (double)n * sizeof(float);  // 2 lecturas + 1 escritura por elemento
    double gbs = bytes_moved / (t.kernel_ms * 1e-3) / 1e9;
    double s_kernel = cpu_ms / t.kernel_ms, s_total = cpu_ms / total;
    printf("%-10s %10d %6d %8d %6.0f %9.4f %10.4f %9.4f %10.4f %10.4f %8.2f %8.2f %7.1f\n",
           KERNEL_NAMES[k], n, block, grid, occ, t.h2d_ms, t.kernel_ms, t.d2h_ms, total, cpu_ms, s_kernel,
           s_total, gbs);
    fprintf(csv, "%s,%s,%d,%d,%d,%.1f,%s,%.6f,%.6f,%.6f,%.6f,%.6f,%.4f,%.4f,%.2f,gpu,%s\n", experiment,
            KERNEL_NAMES[k], n, block, grid, occ, memory, t.h2d_ms, t.kernel_ms, t.d2h_ms, total, cpu_ms,
            s_kernel, s_total, gbs, device);
}

static void usage(const char *prog)
{
    fprintf(stderr,
            "Uso:\n  %s bloque <n>      <salida.csv> [pinned]\n  %s umbral <bloque> <salida.csv> [pinned]\n",
            prog, prog);
    exit(EXIT_FAILURE);
}

int main(int argc, char **argv)
{
    if (argc < 4) usage(argv[0]);
    const char *mode = argv[1];
    long param = atol(argv[2]);
    const char *csv_path = argv[3];
    int pinned = (argc > 4 && strcmp(argv[4], "pinned") == 0);
    const char *memory = pinned ? "pinned" : "pageable";
    int is_block_sweep = (strcmp(mode, "bloque") == 0);
    if (!is_block_sweep && strcmp(mode, "umbral") != 0) usage(argv[0]);

    // --- Entorno (protocolo §1.4): se anota el dispositivo y su ancho de banda teórico.
    int dev = 0, mem_clock_khz = 0, bus_width_bits = 0;
    cudaDeviceProp prop;
    CUDA_CHECK(cudaGetDevice(&dev));
    CUDA_CHECK(cudaGetDeviceProperties(&prop, dev));
    CUDA_CHECK(cudaDeviceGetAttribute(&mem_clock_khz, cudaDevAttrMemoryClockRate, dev));
    CUDA_CHECK(cudaDeviceGetAttribute(&bus_width_bits, cudaDevAttrGlobalMemoryBusWidth, dev));
    double peak_gbs = 2.0 * mem_clock_khz * 1e3 * (bus_width_bits / 8.0) / 1e9;  // DDR: 2 transferencias/ciclo
    char device[256];  // prop.name mide 256 bytes
    snprintf(device, sizeof device, "%s", prop.name);
    for (char *p = device; *p; ++p)
        if (*p == ',') *p = ' ';  // el nombre va a un CSV
    printf("GPU: %s · %d SM · %d hilos/SM · ancho de banda teórico %.0f GB/s · memoria del anfitrión: %s\n",
           device, prop.multiProcessorCount, prop.maxThreadsPerMultiProcessor, peak_gbs, memory);

    FILE *csv = open_csv(csv_path);
    int failures = 0;

    if (is_block_sweep) {
        int n = (int)param;
        if (n <= 0 || n > (1 << 27)) {
            fprintf(stderr, "n fuera de rango (1 .. 2^27)\n");
            return EXIT_FAILURE;
        }
        size_t bytes = (size_t)n * sizeof(float);
        float *h_a = (float *)host_alloc(bytes, pinned), *h_b = (float *)host_alloc(bytes, pinned);
        float *h_c = (float *)host_alloc(bytes, pinned), *h_ref = (float *)malloc(bytes);
        if (!h_ref) return EXIT_FAILURE;
        init_inputs(h_a, h_b, n);
        printf("Experimento 'bloque': n = %d (%.1f MB por vector), bloques de %d a %d\n", n,
               (double)bytes / 1048576.0, BLOCK_SIZES[0], BLOCK_SIZES[N_BLOCK_SIZES - 1]);
        for (int i = 0; i < N_BLOCK_SIZES; ++i) {
            if (BLOCK_SIZES[i] < 1 || BLOCK_SIZES[i] > 1024) {
                fprintf(stderr, "Bloque %d fuera de 1..1024 en BLOCK_SIZES\n", BLOCK_SIZES[i]);
                return EXIT_FAILURE;
            }
            if (BLOCK_SIZES[i] % 32 != 0)
                printf("Aviso: %d no es múltiplo de 32; el último warp de cada bloque va incompleto (%d de 32 carriles)\n",
                       BLOCK_SIZES[i], BLOCK_SIZES[i] % 32);
        }
        print_table_header();
        for (int k = 0; k < 2; ++k) {
            double cpu_ms = measure_cpu_ms((KernelId)k, n, h_a, h_b, h_ref);
            for (int i = 0; i < N_BLOCK_SIZES; ++i) {
                int block = BLOCK_SIZES[i];
                GpuTimes t = measure_gpu((KernelId)k, n, block, h_a, h_b, h_c);
                double err = max_abs_error(h_c, h_ref, n);
                if (err > 1e-5) {
                    printf("FALLA de verificación: %s bloque %d, error %.2e\n", KERNEL_NAMES[k], block, err);
                    ++failures;
                }
                emit_row(csv, "bloque", (KernelId)k, n, block,
                         occupancy_pct((KernelId)k, block, prop.maxThreadsPerMultiProcessor), memory, t,
                         cpu_ms, device);
            }
        }
        host_free(h_a, pinned);
        host_free(h_b, pinned);
        host_free(h_c, pinned);
        free(h_ref);
    } else {
        int block = (int)param;
        if (block < 1 || block > 1024) {
            fprintf(stderr, "El bloque debe estar entre 1 y 1024\n");
            return EXIT_FAILURE;
        }
        if (block % 32 != 0)
            printf("Aviso: %d no es múltiplo de 32; el último warp de cada bloque va incompleto (%d de 32 carriles)\n",
                   block, block % 32);
        printf("Experimento 'umbral': bloque = %d, n = 2^%d .. 2^%d\n", block, LOG2_N_MIN, LOG2_N_MAX);
        print_table_header();
        for (int log2n = LOG2_N_MIN; log2n <= LOG2_N_MAX; log2n += LOG2_N_STEP) {
            int n = 1 << log2n;
            size_t bytes = (size_t)n * sizeof(float);
            float *h_a = (float *)host_alloc(bytes, pinned), *h_b = (float *)host_alloc(bytes, pinned);
            float *h_c = (float *)host_alloc(bytes, pinned), *h_ref = (float *)malloc(bytes);
            if (!h_ref) return EXIT_FAILURE;
            init_inputs(h_a, h_b, n);
            for (int k = 0; k < 2; ++k) {
                double cpu_ms = measure_cpu_ms((KernelId)k, n, h_a, h_b, h_ref);
                GpuTimes t = measure_gpu((KernelId)k, n, block, h_a, h_b, h_c);
                double err = max_abs_error(h_c, h_ref, n);
                if (err > 1e-5) {
                    printf("FALLA de verificación: %s n %d, error %.2e\n", KERNEL_NAMES[k], n, err);
                    ++failures;
                }
                emit_row(csv, "umbral", (KernelId)k, n, block,
                         occupancy_pct((KernelId)k, block, prop.maxThreadsPerMultiProcessor), memory, t,
                         cpu_ms, device);
            }
            host_free(h_a, pinned);
            host_free(h_b, pinned);
            host_free(h_c, pinned);
            free(h_ref);
        }
    }

    fclose(csv);
    printf("Verificación contra CPU: %s. Filas agregadas a %s\n", failures ? "FALLA" : "OK", csv_path);
    CUDA_CHECK(cudaDeviceReset());
    return failures ? EXIT_FAILURE : EXIT_SUCCESS;
}
