// common.cuh — utilidades de anfitrión compartidas por los programas CUDA de la Práctica 6.
// Nada de aquí corre en la GPU. Contiene: revisión de errores (CUDA_CHECK), reloj de CPU,
// mediana, memoria del anfitrión (paginable o fija), información del dispositivo, ocupación,
// el ESQUEMA DEL CSV del curso (el mismo de la sesión S04) y los generadores de datos de la
// Parte C, que son idénticos a los de las referencias en C (c_histograma_cpu.c, c_jacobi_cpu.c)
// para que los resultados sean comparables entre programas.
#pragma once
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cmath>
#include <ctime>
#include <cuda_runtime.h>

// Toda llamada a la API de CUDA se envuelve en CUDA_CHECK. Si falla, imprime archivo, línea y
// mensaje, y termina. Sin esto un error pasa en silencio y el programa "parece" funcionar.
#define CUDA_CHECK(call)                                                          \
    do {                                                                          \
        cudaError_t err__ = (call);                                               \
        if (err__ != cudaSuccess) {                                               \
            fprintf(stderr, "Error CUDA en %s:%d: %s\n", __FILE__, __LINE__,      \
                    cudaGetErrorString(err__));                                   \
            exit(EXIT_FAILURE);                                                   \
        }                                                                         \
    } while (0)

// Protocolo de medición del curso: 1 calentamiento (no se cuenta) + REPS repeticiones, mediana.
#define REPS 5

// Tiempos de GPU de una configuración: medianas de REPS repeticiones, en milisegundos.
typedef struct {
    double h2d_ms;     // copias anfitrión -> dispositivo
    double kernel_ms;  // solo el (los) kernel(s)
    double d2h_ms;     // copia dispositivo -> anfitrión
} GpuTimes;

static inline double cpu_seconds(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + 1e-9 * (double)ts.tv_nsec;
}

static inline int compare_double(const void *a, const void *b) {
    double da = *(const double *)a, db = *(const double *)b;
    return (da > db) - (da < db);
}

// Ordena v en su lugar y regresa la mediana (REPS es impar). Tras llamarla, v[0] es el mínimo
// y v[k-1] el máximo.
static inline double median_of(double *v, int k) {
    qsort(v, (size_t)k, sizeof(double), compare_double);
    return v[k / 2];
}

// Memoria del anfitrión: paginable (malloc) o fija (cudaMallocHost). La fija permite copias
// por DMA sin paso intermedio y copias asíncronas de verdad; se usa en la extensión opcional.
static inline void *host_alloc(size_t bytes, int pinned) {
    void *p = NULL;
    if (pinned) {
        CUDA_CHECK(cudaMallocHost(&p, bytes));
    } else {
        p = malloc(bytes);
        if (!p) {
            fprintf(stderr, "Sin memoria en el anfitrión (%zu bytes)\n", bytes);
            exit(EXIT_FAILURE);
        }
    }
    return p;
}

static inline void host_free(void *p, int pinned) {
    if (pinned) CUDA_CHECK(cudaFreeHost(p));
    else free(p);
}

// Nombre de la GPU sin comas (va dentro de un CSV) y resumen del dispositivo (protocolo §1.4).
static inline void describe_device(cudaDeviceProp *prop, char *name_out, size_t cap) {
    int dev = 0;
    CUDA_CHECK(cudaGetDevice(&dev));
    CUDA_CHECK(cudaGetDeviceProperties(prop, dev));
    snprintf(name_out, cap, "%s", prop->name);
    for (char *p = name_out; *p; ++p)
        if (*p == ',') *p = ' ';
    int mem_clock_khz = 0, bus_width_bits = 0;
    CUDA_CHECK(cudaDeviceGetAttribute(&mem_clock_khz, cudaDevAttrMemoryClockRate, dev));
    CUDA_CHECK(cudaDeviceGetAttribute(&bus_width_bits, cudaDevAttrGlobalMemoryBusWidth, dev));
    double peak_gbs = 2.0 * mem_clock_khz * 1e3 * (bus_width_bits / 8.0) / 1e9;  // DDR: 2 por ciclo
    printf("GPU: %s · %d SM · %d hilos/SM · cc %d.%d · ancho de banda teórico %.0f GB/s\n", name_out,
           prop->multiProcessorCount, prop->maxThreadsPerMultiProcessor, prop->major, prop->minor,
           peak_gbs);
}

// Ocupación teórica (%) de un kernel con un tamaño de bloque: warps residentes por SM que el
// kernel permite, entre el máximo de warps del SM. Es plantilla porque recibe el kernel mismo.
template <typename KernelT>
static inline double occupancy_pct(KernelT kernel, int block, size_t dyn_smem,
                                   const cudaDeviceProp *prop) {
    int blocks_per_sm = 0;
    CUDA_CHECK(cudaOccupancyMaxActiveBlocksPerMultiprocessor(&blocks_per_sm, kernel, block, dyn_smem));
    int warps_per_block = (block + 31) / 32;  // un bloque de 48 hilos ocupa 2 warps, uno a medias
    int max_warps = prop->maxThreadsPerMultiProcessor / 32;
    return 100.0 * blocks_per_sm * warps_per_block / max_warps;
}

// ---------------------------------------------------------------------------------------------
// Esquema del CSV del curso (sesión S04). TODO programa de la práctica (Partes A, B y C) agrega
// filas con este encabezado; graficar.py y resultados/README.md lo documentan.
//   t_* son medianas de REPS repeticiones en ms; t_total = t_h2d + t_kernel + t_d2h;
//   speedup_kernel = t_cpu / t_kernel; speedup_total = t_cpu / t_total;
//   ancho_banda_gbs = bytes útiles movidos por el kernel (entradas + salidas) / t_kernel.
// ---------------------------------------------------------------------------------------------
static const char *CSV_HEADER =
    "experimento,kernel,n,block,grid,ocupacion_pct,memoria,t_h2d_ms,t_kernel_ms,t_d2h_ms,t_total_ms,"
    "t_cpu_ms,speedup_kernel,speedup_total,ancho_banda_gbs,origen,dispositivo\n";

// Abre el CSV en modo "agregar" y escribe el encabezado solo si el archivo está vacío.
static inline FILE *open_csv(const char *path) {
    if (!path) return NULL;
    FILE *f = fopen(path, "a");
    if (!f) {
        fprintf(stderr, "No se pudo abrir %s\n", path);
        exit(EXIT_FAILURE);
    }
    fseek(f, 0, SEEK_END);
    if (ftell(f) == 0) fputs(CSV_HEADER, f);
    return f;
}

static inline void print_table_header(void) {
    printf("%-18s %10s %6s %8s %6s %9s %10s %9s %10s %10s %8s %8s %7s  %s\n", "kernel", "n", "bloque",
           "malla", "ocup%", "H2D ms", "kernel ms", "D2H ms", "total ms", "CPU ms", "S_kern", "S_total",
           "GB/s", "verif");
}

// Imprime una fila de la tabla en pantalla y, si csv != NULL, la fila equivalente del CSV.
static inline void emit_row(FILE *csv, const char *experiment, const char *kernel_name, long n, int block,
                            long grid, double occ, const char *memory, GpuTimes t, double cpu_ms,
                            double useful_bytes, int ok, const char *device) {
    double total = t.h2d_ms + t.kernel_ms + t.d2h_ms;
    double gbs = useful_bytes / (t.kernel_ms * 1e-3) / 1e9;
    double s_kernel = cpu_ms / t.kernel_ms, s_total = cpu_ms / total;
    printf("%-18s %10ld %6d %8ld %6.0f %9.4f %10.4f %9.4f %10.4f %10.4f %8.2f %8.2f %7.1f  %s\n",
           kernel_name, n, block, grid, occ, t.h2d_ms, t.kernel_ms, t.d2h_ms, total, cpu_ms, s_kernel,
           s_total, gbs, ok ? "OK" : "FALLA");
    if (csv)
        fprintf(csv, "%s,%s,%ld,%d,%ld,%.1f,%s,%.6f,%.6f,%.6f,%.6f,%.6f,%.4f,%.4f,%.2f,gpu,%s\n",
                experiment, kernel_name, n, block, grid, occ, memory, t.h2d_ms, t.kernel_ms, t.d2h_ms,
                total, cpu_ms, s_kernel, s_total, gbs, device);
}

// ---------------------------------------------------------------------------------------------
// Generadores de datos de la Parte C. Son EXACTAMENTE los mismos que usan c_histograma_cpu.c y
// c_jacobi_cpu.c: tu kernel debe consumir estos datos para que la comparación tenga sentido.
// ---------------------------------------------------------------------------------------------

// Opción 1 · histograma/reducción: n bytes pseudoaleatorios (hash multiplicativo de Knuth).
static inline void init_histogram_data(unsigned char *data, long n) {
    for (long i = 0; i < n; ++i) {
        unsigned int x = (unsigned int)i * 2654435761u;  // la multiplicación desborda a propósito (mod 2^32)
        data[i] = (unsigned char)((x >> 24) & 0xFFu);
    }
}

// Opción 2 · Jacobi 2D: malla alto×ancho aplanada por filas; la fila 0 vale 100, el resto 0.
// La frontera (fila 0, última fila, columnas 0 y ancho-1) no cambia durante la iteración.
static inline void init_jacobi_grid(float *grid, int height, int width) {
    for (int r = 0; r < height; ++r)
        for (int c = 0; c < width; ++c) grid[(size_t)r * width + c] = (r == 0) ? 100.0f : 0.0f;
}
