// a_vectores.cu — Práctica 6 · Parte A: suma de vectores (c = a + b) y SAXPY (y = α·x + y) en CUDA C,
// con medición por separado de las copias H2D, el kernel y la copia D2H usando cudaEvent_t.
//
// Compilar (Colab/Kaggle con GPU):   nvcc -O2 -arch=sm_75 a_vectores.cu -o a_vectores     (sm_60 en P100)
// Verificar que compila sin GPU:     nvcc -c -arch=sm_75 a_vectores.cu -o a_vectores.o
//
// Uso:
//   ./a_vectores uno    <n> <block> [salida.csv] [pinned]   una configuración, los dos kernels (Lab 1)
//   ./a_vectores umbral [block=256] [salida.csv] [pinned]   n = 2^10, 2^12, ..., 2^26 con bloque fijo
//   ./a_vectores bloque [n=2^24]    [salida.csv] [pinned]   bloque = 32, 64, ..., 1024 con n fijo (Parte D)
//
// Cada configuración: 1 calentamiento + 5 repeticiones; se reporta la mediana de H2D, kernel y D2H.
// T(1) es la versión secuencial en C compilada en este mismo programa (mediana de 5 también).
// Todo se verifica contra la CPU: "sin error de CUDA" no significa "correcto" (idea errónea 27).
// Las filas se AGREGAN al CSV con el esquema del curso (ver common.cuh); varias corridas se juntan.
#include "common.cuh"

static const float ALPHA = 2.0f;
static const int BLOCK_SIZES[] = {32, 64, 128, 256, 512, 1024};
static const int N_BLOCK_SIZES = (int)(sizeof(BLOCK_SIZES) / sizeof(BLOCK_SIZES[0]));
static const int LOG2_N_MIN = 10, LOG2_N_MAX = 26, LOG2_N_STEP = 2;

typedef enum { K_VECTOR_ADD = 0, K_SAXPY = 1 } KernelId;
static const char *KERNEL_NAMES[] = {"vector_add", "saxpy"};

// ---------- Código de dispositivo: un hilo por elemento ----------

// Cada hilo calcula UN elemento. El índice global se arma con la posición del bloque en la malla,
// el tamaño del bloque y la posición del hilo dentro del bloque.
__global__ void vector_add_kernel(const float *a, const float *b, float *c, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) c[i] = a[i] + b[i];  // guardia: los hilos sobrantes del último bloque no tocan memoria
}

// SAXPY: 2 FLOP por 12 bytes movidos (intensidad aritmética ≈ 0.17 FLOP/byte: memory-bound).
__global__ void saxpy_kernel(float alpha, const float *x, const float *y, float *out, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) out[i] = alpha * x[i] + y[i];
}

// ---------- Código de anfitrión ----------

// Referencias secuenciales: el "mejor programa secuencial" contra el que se calcula el speedup.
static void vector_add_cpu(const float *a, const float *b, float *c, int n) {
    for (int i = 0; i < n; ++i) c[i] = a[i] + b[i];
}

static void saxpy_cpu(float alpha, const float *x, const float *y, float *out, int n) {
    for (int i = 0; i < n; ++i) out[i] = alpha * x[i] + y[i];
}

// Misma inicialización que a_vectores_cpu.c y a_vectores_numba.py: enteros pequeños, por lo que la
// aritmética en float es exacta y el checksum es reproducible entre los tres programas.
static void init_inputs(float *a, float *b, int n) {
    for (int i = 0; i < n; ++i) {
        a[i] = (float)(i % 7);
        b[i] = (float)(i % 13);
    }
}

static double max_abs_error(const float *got, const float *ref, int n, double *checksum) {
    double max_err = 0.0, sum = 0.0;
    for (int i = 0; i < n; ++i) {
        double err = fabs((double)got[i] - (double)ref[i]);
        if (err > max_err) max_err = err;
        sum += got[i];
    }
    *checksum = sum;
    return max_err;
}

// Mediana del tiempo secuencial (1 calentamiento + REPS). Deja el resultado de referencia en c.
static double measure_cpu_ms(KernelId k, int n, const float *a, const float *b, float *c) {
    double t[REPS];
    for (int r = -1; r < REPS; ++r) {
        double t0 = cpu_seconds();
        if (k == K_VECTOR_ADD) vector_add_cpu(a, b, c, n);
        else saxpy_cpu(ALPHA, a, b, c, n);
        double dt = (cpu_seconds() - t0) * 1e3;
        if (r >= 0) t[r] = dt;
    }
    return median_of(t, REPS);
}

// Mide H2D, kernel y D2H por separado con cuatro eventos en el stream 0. Un evento es una marca
// que la GPU "completa" cuando llega a ella; cudaEventElapsedTime da los ms entre dos marcas.
// Deja la salida de la última repetición en h_c para verificarla.
static GpuTimes measure_gpu(KernelId k, int n, int block, const float *h_a, const float *h_b, float *h_c) {
    size_t bytes = (size_t)n * sizeof(float);
    float *d_a = NULL, *d_b = NULL, *d_c = NULL;
    CUDA_CHECK(cudaMalloc((void **)&d_a, bytes));
    CUDA_CHECK(cudaMalloc((void **)&d_b, bytes));
    CUDA_CHECK(cudaMalloc((void **)&d_c, bytes));

    cudaEvent_t ev[4];
    for (int i = 0; i < 4; ++i) CUDA_CHECK(cudaEventCreate(&ev[i]));

    int grid = (n + block - 1) / block;  // redondeo hacia arriba: cubre todo n
    double h2d[REPS], ker[REPS], d2h[REPS];

    for (int r = -1; r < REPS; ++r) {  // r = -1 es el calentamiento (no se cuenta)
        CUDA_CHECK(cudaEventRecord(ev[0], 0));
        CUDA_CHECK(cudaMemcpy(d_a, h_a, bytes, cudaMemcpyHostToDevice));
        CUDA_CHECK(cudaMemcpy(d_b, h_b, bytes, cudaMemcpyHostToDevice));
        CUDA_CHECK(cudaEventRecord(ev[1], 0));
        if (k == K_VECTOR_ADD) vector_add_kernel<<<grid, block>>>(d_a, d_b, d_c, n);
        else saxpy_kernel<<<grid, block>>>(ALPHA, d_a, d_b, d_c, n);
        CUDA_CHECK(cudaEventRecord(ev[2], 0));
        CUDA_CHECK(cudaMemcpy(h_c, d_c, bytes, cudaMemcpyDeviceToHost));
        CUDA_CHECK(cudaEventRecord(ev[3], 0));
        CUDA_CHECK(cudaEventSynchronize(ev[3]));  // sin esto se mide el encolado, no el trabajo
        CUDA_CHECK(cudaGetLastError());           // ¿falló el lanzamiento? (p. ej. bloque > 1024)
        if (r >= 0) {
            float ms;
            CUDA_CHECK(cudaEventElapsedTime(&ms, ev[0], ev[1])); h2d[r] = ms;
            CUDA_CHECK(cudaEventElapsedTime(&ms, ev[1], ev[2])); ker[r] = ms;
            CUDA_CHECK(cudaEventElapsedTime(&ms, ev[2], ev[3])); d2h[r] = ms;
        }
    }

    GpuTimes t;
    t.h2d_ms = median_of(h2d, REPS);
    t.kernel_ms = median_of(ker, REPS);
    t.d2h_ms = median_of(d2h, REPS);

    for (int i = 0; i < 4; ++i) CUDA_CHECK(cudaEventDestroy(ev[i]));
    CUDA_CHECK(cudaFree(d_a));
    CUDA_CHECK(cudaFree(d_b));
    CUDA_CHECK(cudaFree(d_c));
    return t;
}

static double occupancy_of(KernelId k, int block, const cudaDeviceProp *prop) {
    return (k == K_VECTOR_ADD) ? occupancy_pct(vector_add_kernel, block, 0, prop)
                               : occupancy_pct(saxpy_kernel, block, 0, prop);
}

// Una configuración (n, block) para los dos kernels: mide CPU, mide GPU, verifica, imprime y guarda.
// Regresa el número de verificaciones que fallaron.
static int run_config(const char *experiment, int n, int block, int pinned, FILE *csv,
                      const cudaDeviceProp *prop, const char *device, int verbose_checksum) {
    size_t bytes = (size_t)n * sizeof(float);
    float *h_a = (float *)host_alloc(bytes, pinned), *h_b = (float *)host_alloc(bytes, pinned);
    float *h_c = (float *)host_alloc(bytes, pinned), *h_ref = (float *)malloc(bytes);
    if (!h_ref) exit(EXIT_FAILURE);
    init_inputs(h_a, h_b, n);
    int failures = 0;
    for (int k = 0; k < 2; ++k) {
        double cpu_ms = measure_cpu_ms((KernelId)k, n, h_a, h_b, h_ref);
        GpuTimes t = measure_gpu((KernelId)k, n, block, h_a, h_b, h_c);
        double checksum = 0.0;
        double err = max_abs_error(h_c, h_ref, n, &checksum);
        int ok = (err <= 1e-5);
        if (!ok) ++failures;
        long grid = (n + block - 1) / block;
        emit_row(csv, experiment, KERNEL_NAMES[k], n, block, grid, occupancy_of((KernelId)k, block, prop),
                 pinned ? "pinned" : "pageable", t, cpu_ms, 3.0 * (double)bytes, ok, device);
        if (verbose_checksum)
            printf("    %s: checksum=%.1f max_abs_err=%.3g (compara con a_vectores_cpu %d y el espejo Numba)\n",
                   KERNEL_NAMES[k], checksum, err, n);
    }
    host_free(h_a, pinned);
    host_free(h_b, pinned);
    host_free(h_c, pinned);
    free(h_ref);
    return failures;
}

static void usage(const char *prog) {
    fprintf(stderr,
            "Uso:\n"
            "  %s uno    <n> <block> [salida.csv] [pinned]\n"
            "  %s umbral [block=256] [salida.csv] [pinned]\n"
            "  %s bloque [n=16777216] [salida.csv] [pinned]\n",
            prog, prog, prog);
    exit(EXIT_FAILURE);
}

int main(int argc, char **argv) {
    if (argc < 2) usage(argv[0]);
    const char *mode = argv[1];
    // "pinned" puede ir en cualquier posición; lo demás son argumentos posicionales.
    int pinned = 0;
    const char *pos[4] = {NULL, NULL, NULL, NULL};
    int n_pos = 0;
    for (int i = 2; i < argc; ++i) {
        if (strcmp(argv[i], "pinned") == 0) pinned = 1;
        else if (n_pos < 4) pos[n_pos++] = argv[i];
    }

    cudaDeviceProp prop;
    char device[256];
    describe_device(&prop, device, sizeof device);
    printf("memoria del anfitrión: %s · protocolo: 1 calentamiento + %d repeticiones, mediana\n",
           pinned ? "pinned" : "pageable", REPS);

    int failures = 0;
    if (strcmp(mode, "uno") == 0) {
        if (n_pos < 2) usage(argv[0]);
        int n = atoi(pos[0]), block = atoi(pos[1]);
        if (n <= 0 || block <= 0) usage(argv[0]);
        // No se limita block a 1024 a propósito: con 2048 el lanzamiento falla y CUDA_CHECK lo reporta.
        FILE *csv = open_csv(pos[2]);
        printf("Experimento 'uno': n = %d (%.2f MB por vector), bloque = %d\n", n,
               (double)n * sizeof(float) / 1048576.0, block);
        print_table_header();
        failures += run_config("uno", n, block, pinned, csv, &prop, device, 1);
        if (csv) fclose(csv);
    } else if (strcmp(mode, "umbral") == 0) {
        int block = pos[0] ? atoi(pos[0]) : 256;
        if (block < 1 || block > 1024) usage(argv[0]);
        if (block % 32 != 0)
            printf("Aviso: %d no es múltiplo de 32; el último warp de cada bloque va incompleto\n", block);
        FILE *csv = open_csv(pos[1]);
        printf("Experimento 'umbral': bloque = %d, n = 2^%d .. 2^%d\n", block, LOG2_N_MIN, LOG2_N_MAX);
        print_table_header();
        for (int log2n = LOG2_N_MIN; log2n <= LOG2_N_MAX; log2n += LOG2_N_STEP)
            failures += run_config("umbral", 1 << log2n, block, pinned, csv, &prop, device, 0);
        if (csv) fclose(csv);
    } else if (strcmp(mode, "bloque") == 0) {
        int n = pos[0] ? atoi(pos[0]) : (1 << 24);
        if (n <= 0 || n > (1 << 27)) usage(argv[0]);
        FILE *csv = open_csv(pos[1]);
        printf("Experimento 'bloque': n = %d (%.1f MB por vector), bloques de %d a %d\n", n,
               (double)n * sizeof(float) / 1048576.0, BLOCK_SIZES[0], BLOCK_SIZES[N_BLOCK_SIZES - 1]);
        print_table_header();
        for (int i = 0; i < N_BLOCK_SIZES; ++i)
            failures += run_config("bloque", n, BLOCK_SIZES[i], pinned, csv, &prop, device, 0);
        if (csv) fclose(csv);
    } else {
        usage(argv[0]);
    }

    printf("Verificación contra la CPU: %s%s\n", failures ? "FALLA" : "OK",
           pos[2] || (strcmp(mode, "uno") != 0 && pos[1]) ? " · filas agregadas al CSV" : "");
    CUDA_CHECK(cudaDeviceReset());
    return failures ? 2 : 0;
}
