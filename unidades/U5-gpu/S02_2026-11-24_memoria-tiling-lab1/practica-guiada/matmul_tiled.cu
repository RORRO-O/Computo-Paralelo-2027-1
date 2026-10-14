// matmul_tiled.cu — multiplicación de matrices C = A·B (n×n, float, por filas) en CUDA.
// Versión POR MOSAICOS (tiling): cada bloque de TILE×TILE hilos recorre la dimensión k en
// fases; en cada fase copia un mosaico de A y uno de B a memoria COMPARTIDA (__shared__),
// sincroniza, y todos los hilos del bloque reutilizan esos datos TILE veces.
//
// Compilar (GPU):        nvcc -O2 -arch=sm_75 matmul_tiled.cu -o matmul_tiled
// Verificar sin GPU:     nvcc -c -arch=sm_75 matmul_tiled.cu -o matmul_tiled.o
// Ejecutar:              ./matmul_tiled [n]        (n por defecto: 512)
// Tamaño de mosaico:     -DTILE=8 | 16 | 32        (por defecto 16)
// Experimentos (fase Investigar):
//   -DSIN_SYNC1          quita la primera __syncthreads() (carrera sobre el mosaico)
//   -DGRID_TRUNCADO      malla n/TILE en lugar de ceil(n/TILE): elementos sin calcular
#include "common.cuh"

#ifndef TILE
#define TILE 16
#endif

__global__ void matmul_tiled(const float *A, const float *B, float *C, int n) {
    // Memoria compartida del bloque: dos mosaicos de TILE×TILE floats (2·TILE²·4 bytes).
    __shared__ float s_A[TILE][TILE];
    __shared__ float s_B[TILE][TILE];

    int tx = threadIdx.x, ty = threadIdx.y;
    int row = blockIdx.y * TILE + ty;      // fila de C que calcula este hilo
    int col = blockIdx.x * TILE + tx;      // columna de C que calcula este hilo
    float acc = 0.0f;

    int n_tiles = (n + TILE - 1) / TILE;   // fases: una por mosaico a lo largo de k
    for (int t = 0; t < n_tiles; ++t) {
        // (1) Carga cooperativa: cada hilo trae UN elemento de A y UNO de B al mosaico.
        //     Los hilos de un warp (tx consecutivos) leen direcciones consecutivas → coalescido.
        int a_col = t * TILE + tx;         // columna de A que lee este hilo
        int b_row = t * TILE + ty;         // fila de B que lee este hilo
        s_A[ty][tx] = (row < n && a_col < n) ? A[row * n + a_col] : 0.0f;   // fuera de rango → 0
        s_B[ty][tx] = (b_row < n && col < n) ? B[b_row * n + col] : 0.0f;   // (n no múltiplo de TILE)
#ifndef SIN_SYNC1
        __syncthreads();   // (2) Barrera: el mosaico completo está en compartida antes de usarlo.
#endif
        // (3) Producto parcial con datos de memoria compartida: TILE reutilizaciones por carga.
        for (int k = 0; k < TILE; ++k) {
            acc += s_A[ty][k] * s_B[k][tx];
        }
        __syncthreads();   // (4) Barrera: nadie sobreescribe el mosaico mientras otros aún lo leen.
    }
    if (row < n && col < n) {              // guardia de escritura
        C[row * n + col] = acc;
    }
}

int main(int argc, char **argv) {
    int n = parse_n(argc, argv, 512);
    size_t bytes = (size_t)n * n * sizeof(float);

    float *h_A = (float *)malloc(bytes);
    float *h_B = (float *)malloc(bytes);
    float *h_C = (float *)malloc(bytes);
    if (!h_A || !h_B || !h_C) { fprintf(stderr, "Sin memoria en el anfitrión\n"); return 1; }
    init_matrices(h_A, h_B, n);

    float *d_A, *d_B, *d_C;
    CUDA_CHECK(cudaMalloc(&d_A, bytes));
    CUDA_CHECK(cudaMalloc(&d_B, bytes));
    CUDA_CHECK(cudaMalloc(&d_C, bytes));

    cudaEvent_t e_start, e_stop;
    CUDA_CHECK(cudaEventCreate(&e_start));
    CUDA_CHECK(cudaEventCreate(&e_stop));

    CUDA_CHECK(cudaEventRecord(e_start));
    CUDA_CHECK(cudaMemcpy(d_A, h_A, bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_B, h_B, bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaEventRecord(e_stop));
    CUDA_CHECK(cudaEventSynchronize(e_stop));
    float h2d_ms = 0.0f;
    CUDA_CHECK(cudaEventElapsedTime(&h2d_ms, e_start, e_stop));

    CUDA_CHECK(cudaMemset(d_C, 0, bytes));

    dim3 block(TILE, TILE);
#ifdef GRID_TRUNCADO
    int n_blocks = n / TILE;                 // ¡división entera! si n no es múltiplo, faltan bloques
#else
    int n_blocks = (n + TILE - 1) / TILE;    // redondeo hacia arriba: cubre todo n
#endif
    dim3 grid(n_blocks, n_blocks);

    // Calentamiento + revisión de errores. Con TILE=64 el bloque tendría 4096 hilos (> 1024):
    // el lanzamiento falla y SOLO se nota aquí, con cudaGetLastError.
    matmul_tiled<<<grid, block>>>(d_A, d_B, d_C, n);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaDeviceSynchronize());

    float t_ms[REPS];
    for (int r = 0; r < REPS; ++r) {
        CUDA_CHECK(cudaEventRecord(e_start));
        matmul_tiled<<<grid, block>>>(d_A, d_B, d_C, n);
        CUDA_CHECK(cudaEventRecord(e_stop));
        CUDA_CHECK(cudaEventSynchronize(e_stop));
        CUDA_CHECK(cudaGetLastError());
        CUDA_CHECK(cudaEventElapsedTime(&t_ms[r], e_start, e_stop));
    }

    CUDA_CHECK(cudaEventRecord(e_start));
    CUDA_CHECK(cudaMemcpy(h_C, d_C, bytes, cudaMemcpyDeviceToHost));
    CUDA_CHECK(cudaEventRecord(e_stop));
    CUDA_CHECK(cudaEventSynchronize(e_stop));
    float d2h_ms = 0.0f;
    CUDA_CHECK(cudaEventElapsedTime(&d2h_ms, e_start, e_stop));

    float max_err = 0.0f;
    long checked = verify_matmul(h_A, h_B, h_C, n, &max_err);
    int ok = (max_err <= tolerance(n));

    float med = median_of(t_ms, REPS);
    float mn = min_of(t_ms, REPS), mx = max_of(t_ms, REPS);
    double gflops = 2.0 * (double)n * n * n / (med * 1e-3) / 1e9;
    int n_tiles = (n + TILE - 1) / TILE;
    // Modelo: cada hilo lee 2 elementos por fase, n_tiles fases, n² hilos.
    unsigned long long reads = 2ULL * (unsigned long long)n * n * n_tiles;

    printf("matmul_tiled  n=%d  TILE=%d  malla=%dx%d  fases=%d  compartida=%zu bytes por bloque\n",
           n, TILE, grid.x, grid.y, n_tiles, 2 * sizeof(float) * TILE * TILE);
    printf("  lecturas a memoria global (modelo): %llu   (cada elemento de A se lee %d veces)\n",
           reads, n_tiles);
    printf("  kernel: mediana %.3f ms (min %.3f, max %.3f) de %d repeticiones -> %.1f GFLOP/s\n",
           med, mn, mx, REPS, gflops);
    printf("  copias: H2D %.3f ms, D2H %.3f ms\n", h2d_ms, d2h_ms);
    printf("  verificacion vs CPU (%ld elementos): error maximo %.2e -> %s\n",
           checked, max_err, ok ? "OK" : "FALLA");
    printf("csv,tiled,%d,%d,%.4f,%.4f,%.4f,%.4f,%.4f,%.2f,%.3e,%s\n",
           n, TILE, med, mn, mx, h2d_ms, d2h_ms, gflops, max_err, ok ? "OK" : "FALLA");

    CUDA_CHECK(cudaEventDestroy(e_start));
    CUDA_CHECK(cudaEventDestroy(e_stop));
    CUDA_CHECK(cudaFree(d_A)); CUDA_CHECK(cudaFree(d_B)); CUDA_CHECK(cudaFree(d_C));
    free(h_A); free(h_B); free(h_C);
    return ok ? 0 : 1;
}
