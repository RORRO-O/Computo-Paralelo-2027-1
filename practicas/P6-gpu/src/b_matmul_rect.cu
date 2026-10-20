// b_matmul_rect.cu — Práctica 6 · Parte B (semi-guiada): multiplicación por mosaicos con matrices
// RECTANGULARES. C = A·B con A de M×K, B de K×N y C de M×N (float, guardadas por filas).
//   matmul_rect_naive  COMPLETA: un hilo por elemento de C, lee de memoria global. Úsala como referencia
//                      de índices: ahí está cómo se recorre cada matriz con su número de columnas.
//   matmul_rect_tiled  la versión por mosaicos de la Parte A (a_matmul_tiled.cu) con n cambiado por M en
//                      todos lados: está "generalizada a medias". Las cuatro líneas marcadas TODO(1)–TODO(4)
//                      son correctas cuando M = K = N y están mal cuando las matrices son rectangulares.
//                      La memoria compartida, las dos __syncthreads() y el ciclo de productos YA están
//                      escritos y no cambian: son los que leíste y rastreaste en la Parte A.
//
// Compilar (GPU):     nvcc -O2 -arch=sm_75 b_matmul_rect.cu -o b_matmul_rect        (-DTILE=8|16|32)
// Verificar sin GPU:  nvcc -c -arch=sm_75 b_matmul_rect.cu -o b_matmul_rect.o
//                     y el espejo: NUMBA_ENABLE_CUDASIM=1 python3 b_matmul_rect_numba.py 20 40 12 16
// Uso:                ./b_matmul_rect [M=1000] [K=600] [N=700] [salida.csv]
//
// Tu trabajo: corrige TODO(1)–TODO(4) (aquí y en b_matmul_rect_numba.py) y pon TODO_LISTO en 1. Mientras
// TODO_LISTO valga 0 el programa imprime "TODO pendiente" y termina con código 3 sin lanzar el kernel por
// mosaicos (la ingenua y la CPU sí corren). Si pones TODO_LISTO en 1 sin corregir nada, la prueba con
// M = K = N = 32 PASA y la de 20×40×12 FALLA: una prueba que pasa no demuestra que el código sea correcto
// (ideas erróneas 27 y 34). Verificación: con tolerancia 1e-4·K por elemento. Medición: 1 calentamiento +
// 5 repeticiones de H2D + kernel + D2H, mediana de cada tramo. CSV: experimento "uno", n = M·N (elementos de C).
#include "common.cuh"

#ifndef TILE
#define TILE 16
#endif

// Pon 1 cuando hayas corregido TODO(1)–TODO(4). Mientras valga 0, el programa imprime "TODO pendiente"
// y no lanza el kernel por mosaicos (la ingenua y la CPU sí corren).
#define TODO_LISTO 0

// ---------- Kernel ingenuo rectangular (completo) ----------
__global__ void matmul_rect_naive(const float *A, const float *B, float *C, int M, int K, int N) {
    int row = blockIdx.y * blockDim.y + threadIdx.y;  // fila de C: 0 .. M-1
    int col = blockIdx.x * blockDim.x + threadIdx.x;  // columna de C: 0 .. N-1
    if (row < M && col < N) {  // sin barreras en este kernel: la guardia puede envolver todo
        float acc = 0.0f;
        for (int k = 0; k < K; ++k) acc += A[row * K + k] * B[k * N + col];  // A tiene K columnas; B, N
        C[row * N + col] = acc;
    }
}

// TODO(1): regresa mat[r][c] de una matriz de rows×cols guardada por filas, o 0.0f si (r, c) cae fuera
//          (r >= rows o c >= cols). Dos cosas de esta línea solo valen para matrices cuadradas: ¿cuántos
//          elementos tiene una FILA de la matriz? ¿contra qué se compara la columna c?
__device__ float load_or_zero(const float *mat, int r, int c, int rows, int cols) {
    return (r < rows && c < rows) ? mat[r * rows + c] : 0.0f; /* <- TODO(1) */
}

// ---------- Kernel por mosaicos rectangular: corrige TODO(2)–TODO(4) ----------
__global__ void matmul_rect_tiled(const float *A, const float *B, float *C, int M, int K, int N) {
    __shared__ float s_A[TILE][TILE];  // mosaico de A: TILE filas de C × TILE posiciones de k
    __shared__ float s_B[TILE][TILE];  // mosaico de B: TILE posiciones de k × TILE columnas de C

    int tx = threadIdx.x, ty = threadIdx.y;
    int row = blockIdx.y * TILE + ty;  // fila de C (y de A) que calcula este hilo
    int col = blockIdx.x * TILE + tx;  // columna de C (y de B) que calcula este hilo
    float acc = 0.0f;

    // TODO(2): ¿a lo largo de qué dimensión avanzan las fases? En C[row][col] = Σ_k A[row][k]·B[k][col],
    //          ¿hasta dónde llega k?
    int n_tiles = (M + TILE - 1) / TILE; /* <- TODO(2) */
    for (int t = 0; t < n_tiles; ++t) {
        // TODO(3): los índices (fila, columna) que trae cada hilo son los de la Parte A; lo que falta es el
        //          tamaño (filas, columnas) de cada matriz en los dos últimos argumentos.
        s_A[ty][tx] = load_or_zero(A, row, t * TILE + tx, M, M); /* <- TODO(3) */
        s_B[ty][tx] = load_or_zero(B, t * TILE + ty, col, M, M); /* <- TODO(3) */
        __syncthreads();  // (dado) el mosaico completo está en memoria compartida antes de leerlo
        for (int k = 0; k < TILE; ++k) acc += s_A[ty][k] * s_B[k][tx];
        __syncthreads();  // (dado) nadie sobreescribe el mosaico mientras otro hilo todavía lo lee
    }
    // TODO(4): esta línea tiene dos defectos que con matrices cuadradas no se notan.
    if (row < M && col < M) C[row * M + col] = acc; /* <- TODO(4) */
}

// ---------- Anfitrión ----------

// Inicialización determinista: la de la Parte A con otras formas (igual en b_matmul_rect_cpu.c y el espejo).
static void init_matrices(float *A, float *B, int M, int K, int N) {
    for (int i = 0; i < M; ++i)
        for (int j = 0; j < K; ++j) A[(size_t)i * K + j] = (float)((3 * i + 7 * j) % 11) / 11.0f;
    for (int i = 0; i < K; ++i)
        for (int j = 0; j < N; ++j) B[(size_t)i * N + j] = (float)((5 * i + 2 * j) % 13) / 13.0f;
}

static void matmul_rect_cpu(const float *A, const float *B, float *C, int M, int K, int N) {
    for (size_t idx = 0; idx < (size_t)M * N; ++idx) C[idx] = 0.0f;
    for (int i = 0; i < M; ++i)
        for (int k = 0; k < K; ++k) {
            float a = A[(size_t)i * K + k];
            for (int j = 0; j < N; ++j) C[(size_t)i * N + j] += a * B[(size_t)k * N + j];
        }
}

// Cada C[i][j] suma K productos en [0,1): vale ~0.2·K. Un elemento sin calcular (error ~0.2·K) se detecta.
static float tolerance(int K) { return 1e-4f * (float)K; }

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
static GpuTimes measure(int tiled, int M, int K, int N, dim3 grid, dim3 block, const float *h_A,
                        const float *h_B, float *h_C) {
    size_t bytes_A = (size_t)M * K * sizeof(float), bytes_B = (size_t)K * N * sizeof(float);
    size_t bytes_C = (size_t)M * N * sizeof(float);
    float *d_A, *d_B, *d_C;
    CUDA_CHECK(cudaMalloc(&d_A, bytes_A));
    CUDA_CHECK(cudaMalloc(&d_B, bytes_B));
    CUDA_CHECK(cudaMalloc(&d_C, bytes_C));
    CUDA_CHECK(cudaMemset(d_C, 0, bytes_C));  // un elemento que nadie escribe queda en 0 y la verificación lo ve
    cudaEvent_t ev[4];
    for (int i = 0; i < 4; ++i) CUDA_CHECK(cudaEventCreate(&ev[i]));
    double h2d[REPS], ker[REPS], d2h[REPS];
    for (int r = -1; r < REPS; ++r) {  // r = -1 es el calentamiento (no se cuenta)
        CUDA_CHECK(cudaEventRecord(ev[0], 0));
        CUDA_CHECK(cudaMemcpy(d_A, h_A, bytes_A, cudaMemcpyHostToDevice));
        CUDA_CHECK(cudaMemcpy(d_B, h_B, bytes_B, cudaMemcpyHostToDevice));
        CUDA_CHECK(cudaEventRecord(ev[1], 0));
        if (tiled) matmul_rect_tiled<<<grid, block>>>(d_A, d_B, d_C, M, K, N);
        else matmul_rect_naive<<<grid, block>>>(d_A, d_B, d_C, M, K, N);
        CUDA_CHECK(cudaEventRecord(ev[2], 0));
        CUDA_CHECK(cudaMemcpy(h_C, d_C, bytes_C, cudaMemcpyDeviceToHost));
        CUDA_CHECK(cudaEventRecord(ev[3], 0));
        CUDA_CHECK(cudaEventSynchronize(ev[3]));
        CUDA_CHECK(cudaGetLastError());  // errores de lanzamiento (p. ej. -DTILE=64: 4096 hilos por bloque)
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
    int M = (argc > 1) ? atoi(argv[1]) : 1000;
    int K = (argc > 2) ? atoi(argv[2]) : 600;
    int N = (argc > 3) ? atoi(argv[3]) : 700;
    const char *csv_path = (argc > 4) ? argv[4] : NULL;
    if (M <= 0 || K <= 0 || N <= 0) {
        fprintf(stderr, "Uso: %s [M>0] [K>0] [N>0] [salida.csv]   (TILE=%d; cambia con -DTILE=8|16|32)\n",
                argv[0], TILE);
        return 1;
    }
    size_t count_C = (size_t)M * N;
    float *h_A = (float *)malloc((size_t)M * K * sizeof(float));
    float *h_B = (float *)malloc((size_t)K * N * sizeof(float));
    float *h_C = (float *)malloc(count_C * sizeof(float)), *h_ref = (float *)malloc(count_C * sizeof(float));
    if (!h_A || !h_B || !h_C || !h_ref) { fprintf(stderr, "Sin memoria en el anfitrión\n"); return 1; }
    init_matrices(h_A, h_B, M, K, N);

    cudaDeviceProp prop;
    char device[256];
    describe_device(&prop, device, sizeof device);

    // ---- T(1): referencia secuencial (5 repeticiones hasta M·K·N = 2^30; más allá, una) ----
    int cpu_reps = ((double)M * K * N <= 1073741824.0) ? REPS : 1;
    double t_cpu[REPS];
    matmul_rect_cpu(h_A, h_B, h_ref, M, K, N);  // calentamiento
    for (int r = 0; r < cpu_reps; ++r) {
        double t0 = cpu_seconds();
        matmul_rect_cpu(h_A, h_B, h_ref, M, K, N);
        t_cpu[r] = (cpu_seconds() - t0) * 1e3;
    }
    double cpu_ms = median_of(t_cpu, cpu_reps);
    printf("matmul_rect M=%d K=%d N=%d TILE=%d · CPU (i-k-j, -O2): mediana %.3f ms de %d · checksum=%.6f\n", M,
           K, N, TILE, cpu_ms, cpu_reps, checksum_of(h_ref, count_C));

    // (Dado) Malla 2D para C (M×N): x recorre las N columnas, y recorre las M filas; redondeo hacia arriba.
    dim3 block(TILE, TILE), grid((N + TILE - 1) / TILE, (M + TILE - 1) / TILE);
    long n_blocks = (long)grid.x * grid.y;
    double useful_bytes = 4.0 * ((double)M * K + (double)K * N + (double)M * N);  // A, B y C una vez
    double flops = 2.0 * (double)M * K * N;

    FILE *csv = open_csv(csv_path);
    print_table_header();
    int failures = 0;
    const char *names[2] = {"matmul_rect_naive", "matmul_rect_tiled"};
    for (int tiled = 0; tiled <= 1; ++tiled) {
#if !TODO_LISTO
        if (tiled) {
            printf("TODO pendiente: corrige TODO(1)-TODO(4) en b_matmul_rect.cu y pon TODO_LISTO en 1\n");
            if (csv) fclose(csv);
            free(h_A); free(h_B); free(h_C); free(h_ref);
            return 3;
        }
#endif
        GpuTimes t = measure(tiled, M, K, N, grid, block, h_A, h_B, h_C);
        float err = max_abs_diff(h_C, h_ref, count_C);
        int ok = (err <= tolerance(K));
        failures += !ok;
        double occ = tiled ? occupancy_pct(matmul_rect_tiled, TILE * TILE, 0, &prop)
                           : occupancy_pct(matmul_rect_naive, TILE * TILE, 0, &prop);
        emit_row(csv, "uno", names[tiled], (long)count_C, TILE * TILE, n_blocks, occ, "pageable", t, cpu_ms,
                 useful_bytes, ok, device);
        printf("    %s: %.1f GFLOP/s · error máximo %.2e (tolerancia %.2e) · checksum=%.6f\n", names[tiled],
               flops / (t.kernel_ms * 1e-3) / 1e9, err, tolerance(K), checksum_of(h_C, count_C));
    }

    if (csv) fclose(csv);
    printf("Verificación contra la CPU: %s\n", failures ? "FALLA" : "OK");
    free(h_A); free(h_B); free(h_C); free(h_ref);
    CUDA_CHECK(cudaDeviceReset());
    return failures ? 2 : 0;
}
