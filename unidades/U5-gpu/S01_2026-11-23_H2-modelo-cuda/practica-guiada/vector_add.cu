/*
 * vector_add.cu — Suma de vectores c = a + b en CUDA C (Unidad V, S01).
 *
 * Uso:  ./vector_add [n] [block] [grid] [archivo.csv]
 *   n        elementos por vector (por defecto 16 777 216 = 2^24, 64 MB por vector)
 *   block    hilos por bloque (por defecto 256)
 *   grid     bloques a lanzar; 0 = calcular (n + block - 1) / block.
 *            Otro valor fuerza el lanzamiento (sirve para experimentar en la fase Investigar).
 *   csv      si se da, agrega una línea con la medición (lo usa el notebook)
 *
 * Compilar y correr (Colab/Kaggle con GPU):
 *   nvcc -O2 -arch=sm_75 vector_add.cu -o vector_add && ./vector_add
 * Verificar que compila sin GPU (entorno sin tarjeta):
 *   nvcc -c -arch=sm_75 vector_add.cu -o vector_add.o
 * Variante deliberadamente incorrecta (fase Investigar: ¿qué pasa sin la guardia?):
 *   nvcc -O2 -arch=sm_75 -DSIN_GUARDIA vector_add.cu -o vector_add_sin_guardia
 *
 * Medición: protocolo del curso (calentamiento + 5 repeticiones, mediana) con cudaEvent_t.
 * Se reporta el tiempo del kernel solo y el tiempo con las copias anfitrión<->dispositivo.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <cuda_runtime.h>

#define REPS 5

/* Toda llamada a la API de CUDA regresa un cudaError_t. Esta macro lo revisa y
 * detiene el programa con el archivo y la línea donde falló. */
#define CUDA_CHECK(call)                                                           \
    do {                                                                           \
        cudaError_t err__ = (call);                                                \
        if (err__ != cudaSuccess) {                                                \
            fprintf(stderr, "Error de CUDA en %s:%d: %s\n", __FILE__, __LINE__,   \
                    cudaGetErrorString(err__));                                    \
            exit(EXIT_FAILURE);                                                    \
        }                                                                          \
    } while (0)

/* ---------- Código de dispositivo (corre en la GPU) ---------- */

/* Cada hilo calcula UN elemento. El índice global se arma con la posición del
 * bloque en la malla (blockIdx.x), el tamaño del bloque (blockDim.x) y la
 * posición del hilo dentro del bloque (threadIdx.x). */
__global__ void vector_add(const float *a, const float *b, float *c, int n)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
#ifndef SIN_GUARDIA
    if (i < n) /* guardia: los hilos sobrantes del último bloque no tocan memoria */
#endif
        c[i] = a[i] + b[i];
}

/* ---------- Código de anfitrión (corre en la CPU) ---------- */

/* Referencia secuencial: misma aritmética, mismo orden. Contra esto se verifica. */
static void vector_add_cpu(const float *a, const float *b, float *c, int n)
{
    for (int i = 0; i < n; i++)
        c[i] = a[i] + b[i];
}

static int cmp_float(const void *x, const void *y)
{
    float fx = *(const float *)x, fy = *(const float *)y;
    return (fx > fy) - (fx < fy);
}

/* Ordena en su lugar y regresa la mediana (REPS es impar). */
static float median_ms(float *v, int k)
{
    qsort(v, (size_t)k, sizeof(float), cmp_float);
    return v[k / 2];
}

int main(int argc, char **argv)
{
    int n = (argc > 1) ? atoi(argv[1]) : (1 << 24);
    int block = (argc > 2) ? atoi(argv[2]) : 256;
    int grid = (argc > 3) ? atoi(argv[3]) : 0;
    const char *csv_path = (argc > 4) ? argv[4] : NULL;

    if (n <= 0 || block <= 0 || block > 1024) {
        fprintf(stderr, "uso: %s [n>0] [block 1..1024] [grid; 0=auto] [archivo.csv]\n", argv[0]);
        return 1;
    }
    if (grid <= 0)
        grid = (n + block - 1) / block; /* división entera redondeada hacia arriba */

    size_t bytes = (size_t)n * sizeof(float);

    /* Memoria del anfitrión */
    float *h_a = (float *)malloc(bytes);
    float *h_b = (float *)malloc(bytes);
    float *h_c = (float *)malloc(bytes);
    float *h_ref = (float *)malloc(bytes);
    if (!h_a || !h_b || !h_c || !h_ref) {
        fprintf(stderr, "Sin memoria en el anfitrión para n=%d\n", n);
        return 1;
    }
    /* Valores enteros pequeños: la suma en float es exacta y el checksum es reproducible. */
    for (int i = 0; i < n; i++) {
        h_a[i] = (float)(i % 7);
        h_b[i] = (float)(i % 13);
    }
    memset(h_c, 0, bytes);

    cudaDeviceProp prop;
    CUDA_CHECK(cudaGetDeviceProperties(&prop, 0));
    printf("vector_add (CUDA C): n=%d block=%d grid=%d hilos_lanzados=%lld gpu=\"%s\" (SMs=%d, cc %d.%d)\n",
           n, block, grid, (long long)grid * block, prop.name, prop.multiProcessorCount,
           prop.major, prop.minor);

    /* Memoria del dispositivo */
    float *d_a = NULL, *d_b = NULL, *d_c = NULL;
    CUDA_CHECK(cudaMalloc((void **)&d_a, bytes));
    CUDA_CHECK(cudaMalloc((void **)&d_b, bytes));
    CUDA_CHECK(cudaMalloc((void **)&d_c, bytes));
    CUDA_CHECK(cudaMemset(d_c, 0, bytes));

    cudaEvent_t start, stop;
    CUDA_CHECK(cudaEventCreate(&start));
    CUDA_CHECK(cudaEventCreate(&stop));

    /* ---- Medición 1: solo el kernel ---- */
    CUDA_CHECK(cudaMemcpy(d_a, h_a, bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_b, h_b, bytes, cudaMemcpyHostToDevice));

    vector_add<<<grid, block>>>(d_a, d_b, d_c, n); /* calentamiento (no se cuenta) */
    CUDA_CHECK(cudaGetLastError());      /* ¿falló el LANZAMIENTO? (configuración inválida) */
    CUDA_CHECK(cudaDeviceSynchronize()); /* ¿falló la EJECUCIÓN? (p. ej. acceso ilegal a memoria) */

    float t_kernel[REPS];
    for (int r = 0; r < REPS; r++) {
        CUDA_CHECK(cudaEventRecord(start));
        vector_add<<<grid, block>>>(d_a, d_b, d_c, n);
        CUDA_CHECK(cudaEventRecord(stop));
        CUDA_CHECK(cudaEventSynchronize(stop));
        CUDA_CHECK(cudaEventElapsedTime(&t_kernel[r], start, stop)); /* milisegundos */
    }
    CUDA_CHECK(cudaGetLastError());

    /* ---- Medición 2: copias H2D + kernel + copia D2H ---- */
    float t_total[REPS];
    for (int r = 0; r < REPS; r++) {
        CUDA_CHECK(cudaEventRecord(start));
        CUDA_CHECK(cudaMemcpy(d_a, h_a, bytes, cudaMemcpyHostToDevice));
        CUDA_CHECK(cudaMemcpy(d_b, h_b, bytes, cudaMemcpyHostToDevice));
        vector_add<<<grid, block>>>(d_a, d_b, d_c, n);
        CUDA_CHECK(cudaMemcpy(h_c, d_c, bytes, cudaMemcpyDeviceToHost));
        CUDA_CHECK(cudaEventRecord(stop));
        CUDA_CHECK(cudaEventSynchronize(stop));
        CUDA_CHECK(cudaEventElapsedTime(&t_total[r], start, stop));
    }
    CUDA_CHECK(cudaGetLastError());

    /* ---- Verificación contra la CPU: "sin error" no significa "correcto" ---- */
    vector_add_cpu(h_a, h_b, h_ref, n);
    double max_abs_err = 0.0, checksum = 0.0;
    for (int i = 0; i < n; i++) {
        double diff = fabs((double)h_c[i] - (double)h_ref[i]);
        if (diff > max_abs_err)
            max_abs_err = diff;
        checksum += h_c[i];
    }
    int ok = (max_abs_err <= 1e-5);

    float k_med = median_ms(t_kernel, REPS), k_min = t_kernel[0], k_max = t_kernel[REPS - 1];
    float t_med = median_ms(t_total, REPS), t_min = t_total[0], t_max = t_total[REPS - 1];
    double gb_moved = 3.0 * (double)bytes / 1e9; /* lee a y b, escribe c */
    double bw = gb_moved / (k_med / 1e3);

    printf("kernel_mediana_ms=%.4f (min %.4f, max %.4f)  con_copias_mediana_ms=%.3f (min %.3f, max %.3f)  "
           "ancho_banda_efectivo_GB_s=%.1f\n",
           k_med, k_min, k_max, t_med, t_min, t_max, bw);
    printf("checksum=%.1f max_abs_err=%.3g verificacion=%s\n", checksum, max_abs_err, ok ? "OK" : "FALLA");

    if (csv_path) {
        FILE *f = fopen(csv_path, "a");
        if (f) {
            fseek(f, 0, SEEK_END);
            if (ftell(f) == 0)
                fprintf(f, "gpu,n,block,grid,kernel_mediana_ms,kernel_min_ms,kernel_max_ms,"
                           "con_copias_mediana_ms,ancho_banda_GB_s,verificacion\n");
            fprintf(f, "\"%s\",%d,%d,%d,%.4f,%.4f,%.4f,%.3f,%.1f,%s\n", prop.name, n, block, grid,
                    k_med, k_min, k_max, t_med, bw, ok ? "OK" : "FALLA");
            fclose(f);
        }
    }

    CUDA_CHECK(cudaEventDestroy(start));
    CUDA_CHECK(cudaEventDestroy(stop));
    CUDA_CHECK(cudaFree(d_a));
    CUDA_CHECK(cudaFree(d_b));
    CUDA_CHECK(cudaFree(d_c));
    free(h_a);
    free(h_b);
    free(h_c);
    free(h_ref);
    return ok ? 0 : 2;
}
