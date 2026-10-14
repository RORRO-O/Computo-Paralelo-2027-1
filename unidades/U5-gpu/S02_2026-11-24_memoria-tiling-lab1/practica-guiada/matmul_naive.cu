// matmul_naive.cu — multiplicación de matrices C = A·B (n×n, float, por filas) en CUDA.
// Versión INGENUA: un hilo por elemento de C; cada hilo lee una fila completa de A y una
// columna completa de B directamente desde memoria GLOBAL.
//
// Compilar (GPU):        nvcc -O2 -arch=sm_75 matmul_naive.cu -o matmul_naive
// Verificar sin GPU:     nvcc -c -arch=sm_75 matmul_naive.cu -o matmul_naive.o
// Ejecutar:              ./matmul_naive [n]        (n por defecto: 512)
// Tamaño de bloque:      -DBLOCK=8 | 16 | 32       (por defecto 16 → bloques de 16×16 = 256 hilos)
#include "common.cuh"

#ifndef BLOCK
#define BLOCK 16
#endif

// Un hilo calcula C[row][col]. Las lecturas de A[row][k] las comparten los n hilos de la
// misma fila; las de B[k][col], los n hilos de la misma columna. Ningún dato se reutiliza
// dentro del bloque: cada elemento de A y de B se lee n veces desde memoria global.
__global__ void matmul_naive(const float *A, const float *B, float *C, int n) {
    int col = blockIdx.x * blockDim.x + threadIdx.x;   // x recorre columnas (direcciones consecutivas)
    int row = blockIdx.y * blockDim.y + threadIdx.y;   // y recorre filas
    if (row < n && col < n) {                           // guardia: la malla puede sobrar
        float acc = 0.0f;
        for (int k = 0; k < n; ++k) {
            acc += A[row * n + k] * B[k * n + col];     // 2 lecturas globales por iteración
        }
        C[row * n + col] = acc;
    }
}

int main(int argc, char **argv) {
    int n = parse_n(argc, argv, 512);
    size_t bytes = (size_t)n * n * sizeof(float);

    // --- Anfitrión: reservar e inicializar ---
    float *h_A = (float *)malloc(bytes);
    float *h_B = (float *)malloc(bytes);
    float *h_C = (float *)malloc(bytes);
    if (!h_A || !h_B || !h_C) { fprintf(stderr, "Sin memoria en el anfitrión\n"); return 1; }
    init_matrices(h_A, h_B, n);

    // --- Dispositivo: reservar ---
    float *d_A, *d_B, *d_C;
    CUDA_CHECK(cudaMalloc(&d_A, bytes));
    CUDA_CHECK(cudaMalloc(&d_B, bytes));
    CUDA_CHECK(cudaMalloc(&d_C, bytes));

    cudaEvent_t e_start, e_stop;
    CUDA_CHECK(cudaEventCreate(&e_start));
    CUDA_CHECK(cudaEventCreate(&e_stop));

    // --- Copias anfitrión → dispositivo (se cronometran: las copias cuentan) ---
    CUDA_CHECK(cudaEventRecord(e_start));
    CUDA_CHECK(cudaMemcpy(d_A, h_A, bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_B, h_B, bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaEventRecord(e_stop));
    CUDA_CHECK(cudaEventSynchronize(e_stop));
    float h2d_ms = 0.0f;
    CUDA_CHECK(cudaEventElapsedTime(&h2d_ms, e_start, e_stop));

    // C en ceros: si algún hilo no escribe su elemento, la verificación lo detecta.
    CUDA_CHECK(cudaMemset(d_C, 0, bytes));

    // --- Configuración de lanzamiento: malla 2D de bloques 2D ---
    dim3 block(BLOCK, BLOCK);
    dim3 grid((n + BLOCK - 1) / BLOCK, (n + BLOCK - 1) / BLOCK);   // redondeo hacia arriba

    // Calentamiento (no se cuenta) + revisión de errores de lanzamiento y de ejecución.
    matmul_naive<<<grid, block>>>(d_A, d_B, d_C, n);
    CUDA_CHECK(cudaGetLastError());          // errores de configuración (p. ej. bloque demasiado grande)
    CUDA_CHECK(cudaDeviceSynchronize());     // errores ocurridos durante la ejecución del kernel

    // --- Medición: REPS repeticiones, se reporta la mediana ---
    float t_ms[REPS];
    for (int r = 0; r < REPS; ++r) {
        CUDA_CHECK(cudaEventRecord(e_start));
        matmul_naive<<<grid, block>>>(d_A, d_B, d_C, n);
        CUDA_CHECK(cudaEventRecord(e_stop));
        CUDA_CHECK(cudaEventSynchronize(e_stop));
        CUDA_CHECK(cudaGetLastError());
        CUDA_CHECK(cudaEventElapsedTime(&t_ms[r], e_start, e_stop));
    }

    // --- Copia dispositivo → anfitrión ---
    CUDA_CHECK(cudaEventRecord(e_start));
    CUDA_CHECK(cudaMemcpy(h_C, d_C, bytes, cudaMemcpyDeviceToHost));
    CUDA_CHECK(cudaEventRecord(e_stop));
    CUDA_CHECK(cudaEventSynchronize(e_stop));
    float d2h_ms = 0.0f;
    CUDA_CHECK(cudaEventElapsedTime(&d2h_ms, e_start, e_stop));

    // --- Verificación contra la CPU: "no dio error" no significa "está bien" ---
    float max_err = 0.0f;
    long checked = verify_matmul(h_A, h_B, h_C, n, &max_err);
    int ok = (max_err <= tolerance(n));

    // --- Reporte ---
    float med = median_of(t_ms, REPS);        // ordena t_ms; min/max se toman después
    float mn = min_of(t_ms, REPS), mx = max_of(t_ms, REPS);
    double gflops = 2.0 * (double)n * n * n / (med * 1e-3) / 1e9;
    unsigned long long reads = 2ULL * (unsigned long long)n * n * n;   // 2·n por hilo, n² hilos

    printf("matmul_naive  n=%d  bloque=%dx%d  malla=%dx%d  (%d hilos por bloque)\n",
           n, BLOCK, BLOCK, grid.x, grid.y, BLOCK * BLOCK);
    printf("  lecturas a memoria global (modelo): %llu   (cada elemento de A se lee %d veces)\n",
           reads, n);
    printf("  kernel: mediana %.3f ms (min %.3f, max %.3f) de %d repeticiones -> %.1f GFLOP/s\n",
           med, mn, mx, REPS, gflops);
    printf("  copias: H2D %.3f ms, D2H %.3f ms\n", h2d_ms, d2h_ms);
    printf("  verificacion vs CPU (%ld elementos): error maximo %.2e -> %s\n",
           checked, max_err, ok ? "OK" : "FALLA");
    // Línea para el CSV del notebook: version,n,tile,kernel_med_ms,min,max,h2d_ms,d2h_ms,gflops,max_err,estado
    printf("csv,naive,%d,%d,%.4f,%.4f,%.4f,%.4f,%.4f,%.2f,%.3e,%s\n",
           n, BLOCK, med, mn, mx, h2d_ms, d2h_ms, gflops, max_err, ok ? "OK" : "FALLA");

    CUDA_CHECK(cudaEventDestroy(e_start));
    CUDA_CHECK(cudaEventDestroy(e_stop));
    CUDA_CHECK(cudaFree(d_A)); CUDA_CHECK(cudaFree(d_B)); CUDA_CHECK(cudaFree(d_C));
    free(h_A); free(h_B); free(h_C);
    return ok ? 0 : 1;
}
