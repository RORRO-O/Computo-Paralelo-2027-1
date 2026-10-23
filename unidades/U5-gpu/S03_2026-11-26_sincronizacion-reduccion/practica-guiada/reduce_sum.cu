/*
 * reduce_sum.cu — Reducción (suma) de n floats en la GPU en tres versiones (Unidad V, S03).
 *
 *   atomic      cada hilo hace atomicAdd(out, x[i]) sobre UN float en memoria global:
 *               n operaciones atómicas que compiten por la misma dirección (contención).
 *   tree_div    reducción en árbol por bloque en memoria compartida, stride CRECIENTE y la
 *               condición  if (tid % (2*stride) == 0): los hilos activos quedan intercalados
 *               dentro de cada warp -> DIVERGENCIA en todos los warps en los primeros niveles.
 *   tree_nodiv  árbol con stride DECRECIENTE y  if (tid < stride): los hilos activos son
 *               consecutivos; warps enteros se apagan y solo diverge el warp 0 cuando stride < 32.
 *
 *   Las versiones de árbol dejan UNA suma parcial por bloque. Segunda etapa:
 *     etapa2=cpu     el anfitrión copia los gridDim parciales y los suma en double (0 atómicas)
 *     etapa2=atomic  el hilo 0 de cada bloque hace atomicAdd(out, parcial)     (gridDim atómicas)
 *
 * Uso:  ./reduce_sum [version] [n] [block] [etapa2] [archivo.csv]
 *   version  atomic | tree_div | tree_nodiv | all        (por defecto all)
 *   n        elementos (por defecto 1 048 576 = 2^20, 4 MB)
 *   block    hilos por bloque, potencia de 2 <= 1024      (por defecto 256)
 *   etapa2   cpu | atomic                                 (por defecto cpu)
 *   csv      si se da, agrega una línea por versión (lo usa el notebook)
 *
 * Datos (iguales en reduce_sum_cpu.c y reduce_sum_numba.py):
 *   x[i] = 1.0f + (i % 10) * 0.1f   y   x[n-1] = 9.5f  (un máximo único al final, para la fase Modificar)
 *   Referencia: suma secuencial en double. Como 0.1 no es exacto en float y el orden de las sumas
 *   cambia entre versiones, la comparación se hace con tolerancia relativa (TOL_REL).
 *
 * Compilar y correr (Colab/Kaggle con GPU):   nvcc -O2 -arch=sm_75 reduce_sum.cu -o reduce_sum && ./reduce_sum
 * Verificar que compila sin GPU:              nvcc -c -arch=sm_75 reduce_sum.cu -o reduce_sum.o
 * Experimento de la fase Investigar (carrera entre niveles del árbol):
 *   nvcc -O2 -arch=sm_75 -DSIN_SYNC reduce_sum.cu -o reduce_sum_sin_sync
 *
 * Medición: protocolo del curso (calentamiento + 5 repeticiones, mediana) con cudaEvent_t.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <cuda_runtime.h>

#define REPS 5
#define MAX_BLOCK 1024          /* máximo de hilos por bloque en cualquier GPU actual */
#define TOL_REL 1e-4            /* tolerancia relativa: ver README, sección "Tolerancia" */

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

/* Versión 1: atómica ingenua. Correcta, pero las n sumas se serializan sobre una dirección. */
__global__ void reduce_atomic(const float *x, float *out, int n)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n)
        atomicAdd(out, x[i]);   /* lectura-suma-escritura indivisible; el orden de llegada es arbitrario */
}

/* Versión 2: árbol CON divergencia. Nivel 1 activa los hilos pares, nivel 2 los múltiplos de 4...
 * En cada warp de 32 hilos quedan activos 16, 8, 4, 2, 1: el warp ejecuta el if con lanes apagados. */
__global__ void reduce_tree_div(const float *x, float *partial, float *out, int n, int atomic_stage2)
{
    __shared__ float s[MAX_BLOCK];          /* memoria compartida: visible solo dentro del bloque */
    int tid = threadIdx.x;
    int i = blockIdx.x * blockDim.x + tid;

    s[tid] = (i < n) ? x[i] : 0.0f;         /* carga cooperativa; fuera de rango carga el neutro 0 */
    __syncthreads();                        /* (A) nadie suma hasta que TODO el bloque cargó */

    for (int stride = 1; stride < blockDim.x; stride *= 2) {
        if (tid % (2 * stride) == 0)        /* activos: 0, 2s, 4s, ... intercalados en cada warp */
            s[tid] += s[tid + stride];
#ifndef SIN_SYNC
        __syncthreads();                    /* (B) el nivel completo termina antes del siguiente */
#endif
    }
    if (tid == 0) {                         /* s[0] tiene la suma del bloque */
        if (atomic_stage2)
            atomicAdd(out, s[0]);           /* etapa 2 en GPU: una atómica por bloque */
        else
            partial[blockIdx.x] = s[0];     /* etapa 2 en CPU: el anfitrión suma los parciales */
    }
}

/* Versión 3: árbol SIN divergencia (hasta stride < 32). Nivel 1 activa los hilos 0..127 (warps 0-3
 * completos; warps 4-7 completos pero apagados), nivel 2 los hilos 0..63, etc. */
__global__ void reduce_tree_nodiv(const float *x, float *partial, float *out, int n, int atomic_stage2)
{
    __shared__ float s[MAX_BLOCK];
    int tid = threadIdx.x;
    int i = blockIdx.x * blockDim.x + tid;

    s[tid] = (i < n) ? x[i] : 0.0f;
    __syncthreads();                        /* (A) */

    for (int stride = blockDim.x / 2; stride > 0; stride >>= 1) {
        if (tid < stride)                   /* activos: 0..stride-1, consecutivos */
            s[tid] += s[tid + stride];
#ifndef SIN_SYNC
        __syncthreads();                    /* (B) */
#endif
    }
    if (tid == 0) {
        if (atomic_stage2)
            atomicAdd(out, s[0]);
        else
            partial[blockIdx.x] = s[0];
    }
}

/* ---------- Código de anfitrión ---------- */

static void init_data(float *x, int n)
{
    for (int i = 0; i < n; i++)
        x[i] = 1.0f + (float)(i % 10) * 0.1f;
    x[n - 1] = 9.5f;                        /* máximo único al final: la fase Modificar lo usa */
}

/* Referencia: suma secuencial en double (sin pérdida apreciable para n <= 2^24). */
static double sum_double(const float *x, int n)
{
    double acc = 0.0;
    for (int i = 0; i < n; i++)
        acc += x[i];
    return acc;
}

/* Emulación en CPU, en float, del MISMO orden de sumas que cada kernel en árbol. Si el kernel
 * está bien, su parcial por bloque coincide bit a bit con esta emulación (misma aritmética IEEE,
 * mismo orden). Sirve para ver que la diferencia con la referencia es solo el orden, no un error. */
static void tree_emulation_cpu(const float *x, int n, int block, int divergent, float *partial_out)
{
    static float s[MAX_BLOCK];
    int grid = (n + block - 1) / block;
    for (int b = 0; b < grid; b++) {
        for (int tid = 0; tid < block; tid++) {
            int i = b * block + tid;
            s[tid] = (i < n) ? x[i] : 0.0f;
        }
        if (divergent) {
            for (int stride = 1; stride < block; stride *= 2)
                for (int tid = 0; tid < block; tid++)
                    if (tid % (2 * stride) == 0)
                        s[tid] += s[tid + stride];
        } else {
            for (int stride = block / 2; stride > 0; stride >>= 1)
                for (int tid = 0; tid < stride; tid++)
                    s[tid] += s[tid + stride];
        }
        partial_out[b] = s[0];
    }
}

static int cmp_float(const void *a, const void *b)
{
    float fa = *(const float *)a, fb = *(const float *)b;
    return (fa > fb) - (fa < fb);
}

static float median_ms(float *v, int k)
{
    qsort(v, (size_t)k, sizeof(float), cmp_float);
    return v[k / 2];
}

static double now_ms(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec * 1e3 + (double)ts.tv_nsec / 1e6;
}

static int is_power_of_two(int v)
{
    return v > 0 && (v & (v - 1)) == 0;
}

/* Ejecuta una versión con el protocolo de medición y la verifica. Regresa 1 si pasa. */
static int run_version(const char *version, const float *d_x, float *d_partial, float *d_out,
                       const float *h_x, int n, int block, int grid, int atomic_stage2,
                       double ref, const char *gpu_name, const char *csv_path)
{
    int is_atomic = strcmp(version, "atomic") == 0;
    int is_div = strcmp(version, "tree_div") == 0;
    float *h_partial = (float *)malloc((size_t)grid * sizeof(float));
    float *h_emul = (float *)malloc((size_t)grid * sizeof(float));
    if (!h_partial || !h_emul) {
        fprintf(stderr, "Sin memoria en el anfitrión\n");
        exit(EXIT_FAILURE);
    }

    cudaEvent_t start, stop;
    CUDA_CHECK(cudaEventCreate(&start));
    CUDA_CHECK(cudaEventCreate(&stop));

    float t_kernel[REPS];
    double sum = 0.0, t_stage2_ms = 0.0;
    long long n_atomics = is_atomic ? n : (atomic_stage2 ? grid : 0);

    /* Calentamiento + REPS repeticiones. En cada una se reinicia el acumulador. */
    for (int r = -1; r < REPS; r++) {
        CUDA_CHECK(cudaMemset(d_out, 0, sizeof(float)));
        CUDA_CHECK(cudaEventRecord(start));
        if (is_atomic)
            reduce_atomic<<<grid, block>>>(d_x, d_out, n);
        else if (is_div)
            reduce_tree_div<<<grid, block>>>(d_x, d_partial, d_out, n, atomic_stage2);
        else
            reduce_tree_nodiv<<<grid, block>>>(d_x, d_partial, d_out, n, atomic_stage2);
        CUDA_CHECK(cudaEventRecord(stop));
        CUDA_CHECK(cudaGetLastError());          /* ¿falló el lanzamiento? */
        CUDA_CHECK(cudaEventSynchronize(stop));  /* espera; aquí aparecen los errores de ejecución */
        if (r >= 0)
            CUDA_CHECK(cudaEventElapsedTime(&t_kernel[r], start, stop));
    }

    /* Resultado final de la última repetición */
    if (is_atomic || atomic_stage2) {
        float h_out = 0.0f;
        CUDA_CHECK(cudaMemcpy(&h_out, d_out, sizeof(float), cudaMemcpyDeviceToHost));
        sum = (double)h_out;
    } else {
        double t0 = now_ms();
        CUDA_CHECK(cudaMemcpy(h_partial, d_partial, (size_t)grid * sizeof(float), cudaMemcpyDeviceToHost));
        for (int b = 0; b < grid; b++)           /* etapa 2 en CPU, en double */
            sum += h_partial[b];
        t_stage2_ms = now_ms() - t0;
    }

    /* Verificación contra la CPU con tolerancia relativa */
    double err_rel = fabs(sum - ref) / fabs(ref);
    int ok = (err_rel <= TOL_REL);

    /* Para los árboles con etapa 2 en CPU: ¿coinciden los parciales bit a bit con la emulación? */
    int bitwise = -1;
    if (!is_atomic && !atomic_stage2) {
        tree_emulation_cpu(h_x, n, block, is_div, h_emul);
        bitwise = (memcmp(h_partial, h_emul, (size_t)grid * sizeof(float)) == 0);
    }

    float k_med = median_ms(t_kernel, REPS), k_min = t_kernel[0], k_max = t_kernel[REPS - 1];
    printf("version=%-10s etapa2=%-6s atomicas_globales=%-8lld kernel_mediana_ms=%.4f (min %.4f, max %.4f)",
           version, is_atomic ? "-" : (atomic_stage2 ? "atomic" : "cpu"), n_atomics, k_med, k_min, k_max);
    if (!is_atomic && !atomic_stage2)
        printf(" etapa2_cpu_ms=%.4f", t_stage2_ms);
    printf("\n   suma=%.6f err_rel=%.2e verificacion=%s", sum, err_rel, ok ? "OK" : "FALLA");
    if (bitwise >= 0)
        printf(" parciales_bit_a_bit_igual_a_emulacion_cpu=%s", bitwise ? "si" : "no");
    printf("\n");

    if (csv_path) {
        FILE *f = fopen(csv_path, "a");
        if (f) {
            fseek(f, 0, SEEK_END);
            if (ftell(f) == 0)
                fprintf(f, "gpu,version,etapa2,n,block,grid,atomicas_globales,kernel_mediana_ms,"
                           "kernel_min_ms,kernel_max_ms,etapa2_cpu_ms,suma,ref_double,err_rel,verificacion\n");
            fprintf(f, "\"%s\",%s,%s,%d,%d,%d,%lld,%.4f,%.4f,%.4f,%.4f,%.6f,%.6f,%.3e,%s\n", gpu_name, version,
                    is_atomic ? "-" : (atomic_stage2 ? "atomic" : "cpu"), n, block, grid, n_atomics, k_med, k_min,
                    k_max, t_stage2_ms, sum, ref, err_rel, ok ? "OK" : "FALLA");
            fclose(f);
        }
    }

    CUDA_CHECK(cudaEventDestroy(start));
    CUDA_CHECK(cudaEventDestroy(stop));
    free(h_partial);
    free(h_emul);
    return ok;
}

int main(int argc, char **argv)
{
    const char *version = (argc > 1) ? argv[1] : "all";
    int n = (argc > 2) ? atoi(argv[2]) : (1 << 20);
    int block = (argc > 3) ? atoi(argv[3]) : 256;
    const char *stage2 = (argc > 4) ? argv[4] : "cpu";
    const char *csv_path = (argc > 5) ? argv[5] : NULL;

    int run_atomic = strcmp(version, "all") == 0 || strcmp(version, "atomic") == 0;
    int run_div = strcmp(version, "all") == 0 || strcmp(version, "tree_div") == 0;
    int run_nodiv = strcmp(version, "all") == 0 || strcmp(version, "tree_nodiv") == 0;
    int atomic_stage2 = strcmp(stage2, "atomic") == 0;

    if ((!run_atomic && !run_div && !run_nodiv) || n <= 0 || block <= 0 || block > MAX_BLOCK ||
        (strcmp(stage2, "cpu") != 0 && !atomic_stage2)) {
        fprintf(stderr, "uso: %s [atomic|tree_div|tree_nodiv|all] [n>0] [block 1..%d] [cpu|atomic] [archivo.csv]\n",
                argv[0], MAX_BLOCK);
        return 1;
    }
    if (run_div && !is_power_of_two(block)) {
        /* tree_div leería s[tid + stride] más allá de blockDim.x (p. ej., s[96] con block = 96): memoria
         * compartida sin inicializar. El experimento de block no potencia de 2 se hace con tree_nodiv. */
        fprintf(stderr, "aviso: tree_div con block=%d leería fuera del bloque; se omite (usa tree_nodiv)\n", block);
        run_div = 0;
        if (!run_atomic && !run_nodiv)
            return 1;
    }
    if (run_nodiv && !is_power_of_two(block))
        fprintf(stderr, "aviso: el árbol supone block potencia de 2; con block=%d se pierden sumandos "
                        "(experimento de la fase Investigar)\n", block);

    int grid = (n + block - 1) / block;
    size_t bytes = (size_t)n * sizeof(float);

    float *h_x = (float *)malloc(bytes);
    if (!h_x) {
        fprintf(stderr, "Sin memoria en el anfitrión para n=%d\n", n);
        return 1;
    }
    init_data(h_x, n);
    double ref = sum_double(h_x, n);

    cudaDeviceProp prop;
    CUDA_CHECK(cudaGetDeviceProperties(&prop, 0));
    printf("reduce_sum (CUDA C): n=%d block=%d grid=%d gpu=\"%s\" (SMs=%d, cc %d.%d, warp=%d)\n", n, block, grid,
           prop.name, prop.multiProcessorCount, prop.major, prop.minor, prop.warpSize);
    printf("referencia_cpu_double=%.6f  tolerancia_relativa=%.0e\n", ref, TOL_REL);
#ifdef SIN_SYNC
    printf("AVISO: compilado con -DSIN_SYNC: el árbol NO sincroniza entre niveles (carrera deliberada)\n");
#endif

    float *d_x = NULL, *d_partial = NULL, *d_out = NULL;
    CUDA_CHECK(cudaMalloc((void **)&d_x, bytes));
    CUDA_CHECK(cudaMalloc((void **)&d_partial, (size_t)grid * sizeof(float)));
    CUDA_CHECK(cudaMalloc((void **)&d_out, sizeof(float)));
    CUDA_CHECK(cudaMemcpy(d_x, h_x, bytes, cudaMemcpyHostToDevice));

    int all_ok = 1;
    if (run_atomic)
        all_ok &= run_version("atomic", d_x, d_partial, d_out, h_x, n, block, grid, 0, ref, prop.name, csv_path);
    if (run_div)
        all_ok &= run_version("tree_div", d_x, d_partial, d_out, h_x, n, block, grid, atomic_stage2, ref,
                              prop.name, csv_path);
    if (run_nodiv)
        all_ok &= run_version("tree_nodiv", d_x, d_partial, d_out, h_x, n, block, grid, atomic_stage2, ref,
                              prop.name, csv_path);

    CUDA_CHECK(cudaFree(d_x));
    CUDA_CHECK(cudaFree(d_partial));
    CUDA_CHECK(cudaFree(d_out));
    free(h_x);
    return all_ok ? 0 : 2;
}
