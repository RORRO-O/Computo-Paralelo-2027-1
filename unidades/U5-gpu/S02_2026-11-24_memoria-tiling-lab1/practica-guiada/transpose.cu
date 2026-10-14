// transpose.cu — transposición de una matriz n×n (float, por filas): out = inᵀ.
// Fase CREAR de la práctica guiada. Viene completa la versión INGENUA (lee coalescido,
// escribe saltado). Debes escribir transpose_shared: usa un mosaico en memoria compartida
// para que tanto la lectura como la escritura a memoria global sean coalescidas.
//
// Compilar (GPU):        nvcc -O2 -arch=sm_75 transpose.cu -o transpose
// Verificar sin GPU:     nvcc -c -arch=sm_75 transpose.cu -o transpose.o
// Ejecutar:              ./transpose [n]          (n por defecto: 1024)
// Tamaño de mosaico:     -DTILE=8 | 16 | 32       (por defecto 16)
#include "common.cuh"

#ifndef TILE
#define TILE 16
#endif

// Cambia a 1 cuando termines TODO(1) (o compila con -DTODO1_LISTO=1). Mientras valga 0, el
// programa imprime "TODO pendiente" para la versión con compartida y solo ejecuta (y verifica)
// la ingenua.
#ifndef TODO1_LISTO
#define TODO1_LISTO 0
#endif

// Versión ingenua. Lectura: los hilos de un warp (threadIdx.x consecutivos) leen
// in[row*n + col] con col consecutivos → direcciones consecutivas → coalescido.
// Escritura: out[col*n + row] con col consecutivos → direcciones separadas por n*4 bytes
// → cada hilo toca un segmento distinto de memoria → NO coalescido.
__global__ void transpose_naive(const float *in, float *out, int n) {
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    if (row < n && col < n) {
        out[col * n + row] = in[row * n + col];
    }
}

// Versión con memoria compartida (la escribes tú).
// Idea: el bloque (bx, by) lee el mosaico (by, bx) de `in` POR FILAS y lo deja en `tile`;
// después de una barrera, escribe ese mismo mosaico transpuesto en la posición (bx, by) de
// `out`, también POR FILAS. En los DOS accesos a memoria global, threadIdx.x debe recorrer la
// dirección que cambia más rápido. La transposición ocurre al indexar `tile`, no la global.
// El "+1" en la segunda dimensión evita conflictos de banco en la compartida (tema de S04;
// por ahora solo déjalo).
__global__ void transpose_shared(const float *in, float *out, int n) {
    __shared__ float tile[TILE][TILE + 1];
    /* TODO(1): implementa la transposición por mosaicos.
       Criterio de "listo": ./transpose 1000 y ./transpose 1024 reportan OK en ambas versiones
       y, en la GPU, transpose_shared alcanza más GB/s que transpose_naive para n = 4096. */
    if (n < 0) {   // nunca se cumple (n > 0): solo evita avisos del compilador mientras el TODO
        tile[0][0] = in[0];   // está pendiente. Bórralo al implementar.
        out[0] = tile[0][0];
    }
}

// Referencia secuencial.
static void transpose_cpu(const float *in, float *out, int n) {
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            out[(size_t)j * n + i] = in[(size_t)i * n + j];
}

// Mide un kernel de transposición: calentamiento, REPS repeticiones, verificación exacta
// (es una copia: el error debe ser 0). Devuelve 1 si el resultado es correcto.
typedef void (*transpose_kernel_t)(const float *, float *, int);

static int run_and_check(const char *name, transpose_kernel_t kernel, const float *d_in,
                         float *d_out, float *h_out, const float *h_ref, int n) {
    size_t bytes = (size_t)n * n * sizeof(float);
    dim3 block(TILE, TILE);
    dim3 grid((n + TILE - 1) / TILE, (n + TILE - 1) / TILE);
    cudaEvent_t e_start, e_stop;
    CUDA_CHECK(cudaEventCreate(&e_start));
    CUDA_CHECK(cudaEventCreate(&e_stop));

    CUDA_CHECK(cudaMemset(d_out, 0, bytes));
    kernel<<<grid, block>>>(d_in, d_out, n);          // calentamiento
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaDeviceSynchronize());

    float t_ms[REPS];
    for (int r = 0; r < REPS; ++r) {
        CUDA_CHECK(cudaEventRecord(e_start));
        kernel<<<grid, block>>>(d_in, d_out, n);
        CUDA_CHECK(cudaEventRecord(e_stop));
        CUDA_CHECK(cudaEventSynchronize(e_stop));
        CUDA_CHECK(cudaGetLastError());
        CUDA_CHECK(cudaEventElapsedTime(&t_ms[r], e_start, e_stop));
    }
    CUDA_CHECK(cudaMemcpy(h_out, d_out, bytes, cudaMemcpyDeviceToHost));

    float max_err = 0.0f;
    for (size_t idx = 0; idx < (size_t)n * n; ++idx) {
        float e = fabsf(h_out[idx] - h_ref[idx]);
        if (e > max_err) max_err = e;
    }
    int ok = (max_err == 0.0f);
    float med = median_of(t_ms, REPS);
    float mn = min_of(t_ms, REPS), mx = max_of(t_ms, REPS);
    // Ancho de banda efectivo: se leen n² floats y se escriben n² floats.
    double gbps = 2.0 * (double)bytes / (med * 1e-3) / 1e9;

    printf("%-16s n=%d TILE=%d  mediana %.3f ms (min %.3f, max %.3f) -> %.1f GB/s  "
           "error maximo %.1e -> %s\n", name, n, TILE, med, mn, mx, gbps, max_err,
           ok ? "OK" : "FALLA");
    printf("csv,%s,%d,%d,%.4f,%.4f,%.4f,0,0,%.2f,%.1e,%s\n", name, n, TILE, med, mn, mx,
           gbps, max_err, ok ? "OK" : "FALLA");

    CUDA_CHECK(cudaEventDestroy(e_start));
    CUDA_CHECK(cudaEventDestroy(e_stop));
    return ok;
}

int main(int argc, char **argv) {
    int n = parse_n(argc, argv, 1024);
    size_t bytes = (size_t)n * n * sizeof(float);

    float *h_in = (float *)malloc(bytes);
    float *h_out = (float *)malloc(bytes);
    float *h_ref = (float *)malloc(bytes);
    if (!h_in || !h_out || !h_ref) { fprintf(stderr, "Sin memoria en el anfitrión\n"); return 1; }
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            h_in[(size_t)i * n + j] = (float)((7 * i + 3 * j) % 101);   // exacto en float
    transpose_cpu(h_in, h_ref, n);

    float *d_in, *d_out;
    CUDA_CHECK(cudaMalloc(&d_in, bytes));
    CUDA_CHECK(cudaMalloc(&d_out, bytes));
    CUDA_CHECK(cudaMemcpy(d_in, h_in, bytes, cudaMemcpyHostToDevice));

    int ok = run_and_check("transpose_naive", transpose_naive, d_in, d_out, h_out, h_ref, n);
#if TODO1_LISTO
    ok = run_and_check("transpose_shared", transpose_shared, d_in, d_out, h_out, h_ref, n) && ok;
#else
    printf("TODO pendiente: transpose_shared (TODO(1)); solo se ejecuto la version ingenua.\n");
#endif

    CUDA_CHECK(cudaFree(d_in)); CUDA_CHECK(cudaFree(d_out));
    free(h_in); free(h_out); free(h_ref);
    return ok ? 0 : 1;
}
