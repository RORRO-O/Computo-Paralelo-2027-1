// a_matmul_tiled.cu — Práctica 6 · Parte A (código COMPLETO para leer, predecir, ejecutar y medir):
// multiplicación de matrices C = A·B (n×n, float, guardadas por filas) en dos versiones.
//   matmul_naive  un hilo por elemento de C; lee una fila de A y una columna de B de memoria GLOBAL
//                 (2n lecturas globales por hilo).
//   matmul_tiled  por mosaicos (tiling): cada bloque de TILE×TILE hilos recorre la dimensión k en fases;
//                 en cada fase copia un mosaico de A y uno de B a memoria COMPARTIDA (__shared__),
//                 sincroniza, y todos los hilos del bloque reutilizan esos datos TILE veces
//                 (2·⌈n/TILE⌉ lecturas globales por hilo).
// Es el mismo kernel que rastreaste en la práctica guiada de la sesión S02 (martes 24 de noviembre), ahora
// con la medición del curso: H2D, kernel y D2H por separado con cudaEvent_t y filas en el CSV.
//
// Compilar (GPU):     nvcc -O2 -arch=sm_75 a_matmul_tiled.cu -o a_matmul_tiled        (-DTILE=8|16|32)
// Verificar sin GPU:  nvcc -c -arch=sm_75 a_matmul_tiled.cu -o a_matmul_tiled.o
// Uso:                ./a_matmul_tiled [n=512] [salida.csv]
//
// Verificación contra la CPU con tolerancia (nunca con ==: la GPU usa FMA y el orden de suma cambia el
// redondeo). Medición: 1 calentamiento + 5 repeticiones de H2D + kernel + D2H, mediana de cada tramo.
// En el CSV, block = TILE·TILE (hilos del bloque), grid = bloques totales y ancho_banda_gbs usa los
// 12·n² bytes útiles (A, B y C una vez); la tabla imprime además GFLOP/s.
#include "common.cuh"

#ifndef TILE
#define TILE 16
#endif

// ---------- Kernel ingenuo: 2n lecturas de memoria global por hilo ----------
__global__ void matmul_naive(const float *A, const float *B, float *C, int n) {
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    if (row < n && col < n) {  // aquí la guardia puede envolver todo: este kernel no tiene barreras
        float acc = 0.0f;
        for (int k = 0; k < n; ++k) acc += A[row * n + k] * B[k * n + col];
        C[row * n + col] = acc;
    }
}

// ---------- Kernel por mosaicos: 2·⌈n/TILE⌉ lecturas de memoria global por hilo ----------
__global__ void matmul_tiled(const float *A, const float *B, float *C, int n) {
    // Memoria compartida del bloque: dos mosaicos de TILE×TILE floats (2·TILE²·4 bytes; 2 KB con TILE = 16).
    // La ven todos los hilos del bloque y solo ellos; vive lo que vive el bloque.
    __shared__ float s_A[TILE][TILE];
    __shared__ float s_B[TILE][TILE];

    int tx = threadIdx.x, ty = threadIdx.y;
    int row = blockIdx.y * TILE + ty;  // fila de C que calcula este hilo
    int col = blockIdx.x * TILE + tx;  // columna de C que calcula este hilo
    float acc = 0.0f;                  // acumulador en un registro: privado de este hilo

    int n_tiles = (n + TILE - 1) / TILE;  // fases: una por mosaico a lo largo de k (redondeo hacia arriba)
    for (int t = 0; t < n_tiles; ++t) {
        // (1) Carga cooperativa: cada hilo trae UN elemento de A y UNO de B. Los hilos de un warp (tx
        //     consecutivos) leen direcciones consecutivas de A y de B: lecturas coalescidas.
        //     Fuera de la matriz (n no múltiplo de TILE) se carga 0.0f: ese producto parcial vale 0 y no hay
        //     que tratar los bordes aparte en el ciclo de productos.
        int a_col = t * TILE + tx;
        s_A[ty][tx] = (row < n && a_col < n) ? A[row * n + a_col] : 0.0f;
        int b_row = t * TILE + ty;
        s_B[ty][tx] = (b_row < n && col < n) ? B[b_row * n + col] : 0.0f;

        // (2) Primera barrera: nadie lee el mosaico hasta que TODOS los hilos del bloque terminaron de cargarlo
        //     (s_A[ty][k] lo trajo otro hilo). Sincroniza solo este bloque, no toda la GPU (idea errónea 25).
        __syncthreads();

        // (3) TILE productos con datos de memoria compartida: cada elemento cargado se usa TILE veces.
        for (int k = 0; k < TILE; ++k) acc += s_A[ty][k] * s_B[k][tx];

        // (4) Segunda barrera: nadie sobreescribe el mosaico (fase t+1) mientras otro hilo todavía lo lee.
        __syncthreads();
    }
    // (5) Guardia de escritura DESPUÉS del ciclo. No puede ser un "return" al inicio: los hilos fuera de rango
    //     también deben llegar a cada __syncthreads() y cargar sus ceros (ideas erróneas 32 y 34).
    if (row < n && col < n) C[row * n + col] = acc;
}

// ---------- Anfitrión ----------

// Inicialización determinista: la MISMA fórmula está en a_matmul_cpu.c, a_matmul_numba.py y en la Parte B.
static void init_matrices(float *A, float *B, int n) {
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j) {
            A[(size_t)i * n + j] = (float)((3 * i + 7 * j) % 11) / 11.0f;
            B[(size_t)i * n + j] = (float)((5 * i + 2 * j) % 13) / 13.0f;
        }
}

// Referencia secuencial, orden i-k-j (el ciclo interno recorre B y C por filas: amigable con la caché).
static void matmul_cpu(const float *A, const float *B, float *C, int n) {
    for (size_t idx = 0; idx < (size_t)n * n; ++idx) C[idx] = 0.0f;
    for (int i = 0; i < n; ++i)
        for (int k = 0; k < n; ++k) {
            float a = A[(size_t)i * n + k];
            for (int j = 0; j < n; ++j) C[(size_t)i * n + j] += a * B[(size_t)k * n + j];
        }
}

// Tolerancia: los sumandos están en [0,1) y cada C[i][j] vale ~0.2·n; el error de redondeo en float
// crece con n y queda muy por debajo de 1e-4·n. Un elemento sin calcular (error ~0.2·n) se detecta.
static float tolerance(int n) { return 1e-4f * (float)n; }

static double checksum_of(const float *x, size_t count) {
    double sum = 0.0;
    for (size_t i = 0; i < count; ++i) sum += x[i];
    return sum;
}

static float max_abs_diff(const float *x, const float *y, size_t count) {
    float m = 0.0f;
    for (size_t i = 0; i < count; ++i) {
        float e = fabsf(x[i] - y[i]);
        if (e > m) m = e;
    }
    return m;
}

// Mide H2D (A y B), kernel y D2H (C) con cuatro eventos; 1 calentamiento + REPS. Deja C en h_C.
static GpuTimes measure(int tiled, int n, dim3 grid, dim3 block, const float *h_A, const float *h_B,
                        float *h_C) {
    size_t bytes = (size_t)n * n * sizeof(float);
    float *d_A, *d_B, *d_C;
    CUDA_CHECK(cudaMalloc(&d_A, bytes));
    CUDA_CHECK(cudaMalloc(&d_B, bytes));
    CUDA_CHECK(cudaMalloc(&d_C, bytes));
    CUDA_CHECK(cudaMemset(d_C, 0, bytes));
    cudaEvent_t ev[4];
    for (int i = 0; i < 4; ++i) CUDA_CHECK(cudaEventCreate(&ev[i]));
    double h2d[REPS], ker[REPS], d2h[REPS];
    for (int r = -1; r < REPS; ++r) {  // r = -1 es el calentamiento (no se cuenta)
        CUDA_CHECK(cudaEventRecord(ev[0], 0));
        CUDA_CHECK(cudaMemcpy(d_A, h_A, bytes, cudaMemcpyHostToDevice));
        CUDA_CHECK(cudaMemcpy(d_B, h_B, bytes, cudaMemcpyHostToDevice));
        CUDA_CHECK(cudaEventRecord(ev[1], 0));
        if (tiled) matmul_tiled<<<grid, block>>>(d_A, d_B, d_C, n);
        else matmul_naive<<<grid, block>>>(d_A, d_B, d_C, n);
        CUDA_CHECK(cudaEventRecord(ev[2], 0));
        CUDA_CHECK(cudaMemcpy(h_C, d_C, bytes, cudaMemcpyDeviceToHost));
        CUDA_CHECK(cudaEventRecord(ev[3], 0));
        CUDA_CHECK(cudaEventSynchronize(ev[3]));  // sin esto se mide el encolado, no el trabajo (idea 33)
        // Con -DTILE=64 el bloque tendría 4096 hilos (> 1024): el lanzamiento falla y SOLO se nota aquí.
        CUDA_CHECK(cudaGetLastError());
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
    CUDA_CHECK(cudaFree(d_A));
    CUDA_CHECK(cudaFree(d_B));
    CUDA_CHECK(cudaFree(d_C));
    return t;
}

int main(int argc, char **argv) {
    int n = (argc > 1) ? atoi(argv[1]) : 512;
    const char *csv_path = (argc > 2) ? argv[2] : NULL;
    if (n <= 0) {
        fprintf(stderr, "Uso: %s [n>0] [salida.csv]   (TILE=%d; cambia con -DTILE=8|16|32)\n", argv[0], TILE);
        return 1;
    }
    size_t count = (size_t)n * n, bytes = count * sizeof(float);
    float *h_A = (float *)malloc(bytes), *h_B = (float *)malloc(bytes);
    float *h_C = (float *)malloc(bytes), *h_ref = (float *)malloc(bytes);
    if (!h_A || !h_B || !h_C || !h_ref) { fprintf(stderr, "Sin memoria en el anfitrión\n"); return 1; }
    init_matrices(h_A, h_B, n);

    cudaDeviceProp prop;
    char device[256];
    describe_device(&prop, device, sizeof device);

    // ---- T(1): referencia secuencial. 5 repeticiones hasta n = 1024; más allá tardaría minutos ----
    int cpu_reps = (n <= 1024) ? REPS : 1;
    double t_cpu[REPS];
    matmul_cpu(h_A, h_B, h_ref, n);  // calentamiento
    for (int r = 0; r < cpu_reps; ++r) {
        double t0 = cpu_seconds();
        matmul_cpu(h_A, h_B, h_ref, n);
        t_cpu[r] = (cpu_seconds() - t0) * 1e3;
    }
    double cpu_ms = median_of(t_cpu, cpu_reps);
    printf("matmul n=%d TILE=%d · CPU (i-k-j, -O2): mediana %.3f ms de %d repeticiones · checksum=%.6f\n",
           n, TILE, cpu_ms, cpu_reps, checksum_of(h_ref, count));

    FILE *csv = open_csv(csv_path);
    print_table_header();
    int failures = 0;
    double useful_bytes = 3.0 * (double)bytes;  // A, B y C una vez
    double flops = 2.0 * (double)n * n * n;

    // Malla 2D con redondeo hacia arriba en cada dimensión: x recorre columnas de C, y recorre filas.
    // Las dos versiones usan bloques de TILE×TILE hilos para que la comparación sea justa.
    int n_blocks = (n + TILE - 1) / TILE;
    dim3 block(TILE, TILE), grid(n_blocks, n_blocks);
    const char *names[2] = {"matmul_naive", "matmul_tiled"};
    for (int tiled = 0; tiled <= 1; ++tiled) {
        GpuTimes t = measure(tiled, n, grid, block, h_A, h_B, h_C);
        float err = max_abs_diff(h_C, h_ref, count);
        int ok = (err <= tolerance(n));
        failures += !ok;
        double occ = tiled ? occupancy_pct(matmul_tiled, TILE * TILE, 0, &prop)
                           : occupancy_pct(matmul_naive, TILE * TILE, 0, &prop);
        emit_row(csv, "bloque", names[tiled], n, TILE * TILE, (long)n_blocks * n_blocks, occ, "pageable", t,
                 cpu_ms, useful_bytes, ok, device);
        printf("    %s: %.1f GFLOP/s · error máximo %.2e (tolerancia %.2e) · checksum=%.6f", names[tiled],
               flops / (t.kernel_ms * 1e-3) / 1e9, err, tolerance(n), checksum_of(h_C, count));
        if (tiled) printf(" · fases=%d · compartida=%zu B/bloque", n_blocks, 2 * sizeof(float) * TILE * TILE);
        printf("\n");
    }

    if (csv) fclose(csv);
    printf("Verificación contra la CPU: %s\n", failures ? "FALLA" : "OK");
    free(h_A); free(h_B); free(h_C); free(h_ref);
    CUDA_CHECK(cudaDeviceReset());
    return failures ? 2 : 0;
}
