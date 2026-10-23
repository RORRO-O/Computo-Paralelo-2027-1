/* bench_cpu.c — Referencia en CPU de la práctica guiada S04 (se corre sin GPU).
 *
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra bench_cpu.c -o bench_cpu -lm
 * Uso:
 *   ./bench_cpu [log2_n_max]              tabla de tiempos de CPU (vector_add y saxpy) para n = 2^10 .. 2^log2_n_max
 *   ./bench_cpu --csv-ejemplo <salida.csv> [log2_n_max]
 *                                         genera un CSV con el MISMO esquema que bench_gpu.cu. La columna t_cpu_ms
 *                                         está medida aquí; las columnas de GPU salen de un MODELO de costo
 *                                         (origen=modelo). Sirve para ensayar graficar.py antes de ir a Colab.
 *   ./bench_cpu --test                    autoverificación (la usan las pruebas)
 *
 * Protocolo del curso: 1 calentamiento + 5 repeticiones, mediana, -O2, reloj CLOCK_MONOTONIC.
 */
#define _POSIX_C_SOURCE 199309L
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define N_REPS 5
static const int BLOCK_SIZES[] = {32, 64, 128, 256, 512, 1024};
static const int N_BLOCK_SIZES = (int)(sizeof(BLOCK_SIZES) / sizeof(BLOCK_SIZES[0]));
static const int LOG2_N_MIN = 10, LOG2_N_STEP = 2;
static const float ALPHA = 2.0f;

/* ---- Modelo de costo para el CSV de ejemplo. Son órdenes de magnitud de una T4 en Colab, NO mediciones:
 *   t_kernel = L_lanzamiento + bytes / (BW_gpu * f_bloque * f_llenado)
 *   t_copia  = L_copia + bytes / BW_pcie            (BW_pcie: paginable ~4 GB/s, pinned ~11 GB/s)
 *   f_bloque castiga los bloques pequeños (poca ocupación) y, apenas, el de 1024 (menos bloques para repartir).
 *   f_llenado castiga las mallas con menos bloques que 2 por SM (SM ociosos).                              */
static const double MODEL_GPU_BW_GBS = 240.0;       /* ~75 % de los 320 GB/s teóricos de una T4 */
static const double MODEL_LAUNCH_MS = 0.006;        /* lanzar y planificar un kernel: unos microsegundos */
static const double MODEL_COPY_LATENCY_MS = 0.015;  /* costo fijo de cada cudaMemcpy */
static const double MODEL_PCIE_PAGEABLE_GBS = 4.0;
static const double MODEL_PCIE_PINNED_GBS = 11.0;
static const int MODEL_SMS = 40;                    /* una T4 tiene 40 SM de 1024 hilos */
static const double MODEL_BLOCK_FACTOR[] = {0.55, 0.85, 0.97, 1.00, 0.99, 0.96};
static const double MODEL_OCCUPANCY_PCT[] = {50.0, 100.0, 100.0, 100.0, 100.0, 100.0}; /* 16 bloques/SM máx. */

static void vector_add_cpu(const float *a, const float *b, float *c, int n)
{
    for (int i = 0; i < n; ++i) c[i] = a[i] + b[i];
}

static void saxpy_cpu(float alpha, const float *x, const float *y, float *out, int n)
{
    for (int i = 0; i < n; ++i) out[i] = alpha * x[i] + y[i];
}

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

static void init_inputs(float *a, float *b, int n)
{
    for (int i = 0; i < n; ++i) {
        a[i] = (float)(i % 1000) * 0.001f;
        b[i] = 1.0f + (float)(i % 7);
    }
}

/* Mediana en ms de la versión secuencial; k = 0 vector_add, k = 1 saxpy. */
static double measure_cpu_ms(int k, int n, const float *a, const float *b, float *c)
{
    double t[N_REPS];
    for (int r = -1; r < N_REPS; ++r) {
        double t0 = cpu_seconds();
        if (k == 0) vector_add_cpu(a, b, c, n);
        else saxpy_cpu(ALPHA, a, b, c, n);
        double dt = (cpu_seconds() - t0) * 1e3;
        if (r >= 0) t[r] = dt;
    }
    return median_of(t, N_REPS);
}

static double model_kernel_ms(int n, int block_index, int block)
{
    double bytes = 3.0 * n * sizeof(float);
    int grid = (n + block - 1) / block;
    double fill = (double)grid / (2.0 * MODEL_SMS);
    if (fill > 1.0) fill = 1.0;
    return MODEL_LAUNCH_MS + bytes / (MODEL_GPU_BW_GBS * 1e9 * MODEL_BLOCK_FACTOR[block_index] * fill) * 1e3;
}

static double model_copy_ms(double bytes, int pinned)
{
    double bw = pinned ? MODEL_PCIE_PINNED_GBS : MODEL_PCIE_PAGEABLE_GBS;
    return MODEL_COPY_LATENCY_MS + bytes / (bw * 1e9) * 1e3;
}

static int block_index_of(int block)
{
    for (int i = 0; i < N_BLOCK_SIZES; ++i)
        if (BLOCK_SIZES[i] == block) return i;
    return 3; /* bloque fuera de la lista: se trata como 256 */
}

static void emit_model_row(FILE *csv, const char *experiment, const char *kernel, int n, int block, int pinned,
                           double cpu_ms)
{
    int bi = block_index_of(block);
    int grid = (n + block - 1) / block;
    double bytes = (double)n * sizeof(float);
    double h2d = 2.0 * model_copy_ms(bytes, pinned);  /* dos vectores de entrada */
    double ker = model_kernel_ms(n, bi, block);
    double d2h = model_copy_ms(bytes, pinned);
    double total = h2d + ker + d2h;
    double gbs = 3.0 * bytes / (ker * 1e-3) / 1e9;
    fprintf(csv, "%s,%s,%d,%d,%d,%.1f,%s,%.6f,%.6f,%.6f,%.6f,%.6f,%.4f,%.4f,%.2f,modelo,modelo-T4-sin-gpu\n",
            experiment, kernel, n, block, grid, MODEL_OCCUPANCY_PCT[bi], pinned ? "pinned" : "pageable", h2d, ker,
            d2h, total, cpu_ms, cpu_ms / ker, cpu_ms / total, gbs);
}

static float *alloc_or_die(size_t bytes)
{
    float *p = malloc(bytes);
    if (!p) {
        fprintf(stderr, "Sin memoria (%zu bytes)\n", bytes);
        exit(EXIT_FAILURE);
    }
    return p;
}

static int write_example_csv(const char *path, int log2_n_max)
{
    FILE *csv = fopen(path, "w");
    if (!csv) {
        fprintf(stderr, "No se pudo escribir %s\n", path);
        return 1;
    }
    fputs("experimento,kernel,n,block,grid,ocupacion_pct,memoria,t_h2d_ms,t_kernel_ms,t_d2h_ms,t_total_ms,"
          "t_cpu_ms,speedup_kernel,speedup_total,ancho_banda_gbs,origen,dispositivo\n",
          csv);
    const char *names[] = {"vector_add", "saxpy"};

    /* Experimento 'bloque' con n grande (2^log2_n_max) y con n pequeño (4096). */
    int n_block_exp[2] = {1 << log2_n_max, 4096};
    for (int e = 0; e < 2; ++e) {
        int n = n_block_exp[e];
        size_t bytes = (size_t)n * sizeof(float);
        float *a = alloc_or_die(bytes), *b = alloc_or_die(bytes), *c = alloc_or_die(bytes);
        init_inputs(a, b, n);
        for (int k = 0; k < 2; ++k) {
            double cpu_ms = measure_cpu_ms(k, n, a, b, c);
            for (int i = 0; i < N_BLOCK_SIZES; ++i) emit_model_row(csv, "bloque", names[k], n, BLOCK_SIZES[i], 0, cpu_ms);
        }
        free(a);
        free(b);
        free(c);
    }
    /* Experimento 'umbral' con bloque 256, memoria paginable y pinned. */
    for (int log2n = LOG2_N_MIN; log2n <= log2_n_max; log2n += LOG2_N_STEP) {
        int n = 1 << log2n;
        size_t bytes = (size_t)n * sizeof(float);
        float *a = alloc_or_die(bytes), *b = alloc_or_die(bytes), *c = alloc_or_die(bytes);
        init_inputs(a, b, n);
        for (int k = 0; k < 2; ++k) {
            double cpu_ms = measure_cpu_ms(k, n, a, b, c);
            emit_model_row(csv, "umbral", names[k], n, 256, 0, cpu_ms);
            emit_model_row(csv, "umbral", names[k], n, 256, 1, cpu_ms);
        }
        free(a);
        free(b);
        free(c);
    }
    fclose(csv);
    printf("CSV de ejemplo escrito en %s (t_cpu_ms medido aquí; columnas de GPU: modelo, NO medidas)\n", path);
    return 0;
}

static int self_test(void)
{
    const int n = 1000; /* no es múltiplo de ningún bloque: ejercita el último bloque incompleto en los espejos */
    float a[1000], b[1000], c[1000];
    init_inputs(a, b, n);
    int failures = 0;
    vector_add_cpu(a, b, c, n);
    for (int i = 0; i < n; ++i)
        if (fabs((double)c[i] - ((double)a[i] + b[i])) > 1e-6) ++failures;
    saxpy_cpu(ALPHA, a, b, c, n);
    for (int i = 0; i < n; ++i)
        if (fabs((double)c[i] - ((double)ALPHA * a[i] + b[i])) > 1e-6) ++failures;
    double v[N_REPS] = {5.0, 1.0, 4.0, 2.0, 3.0};
    if (median_of(v, N_REPS) != 3.0) ++failures;
    /* El modelo debe crecer con n y castigar al bloque de 32 frente al de 256. */
    if (model_kernel_ms(1 << 20, 3, 256) >= model_kernel_ms(1 << 24, 3, 256)) ++failures;
    if (model_kernel_ms(1 << 24, 0, 32) <= model_kernel_ms(1 << 24, 3, 256)) ++failures;
    if (model_copy_ms(1e8, 1) >= model_copy_ms(1e8, 0)) ++failures;
    printf("bench_cpu --test: %s (%d fallas)\n", failures ? "FALLA" : "OK", failures);
    return failures ? 1 : 0;
}

int main(int argc, char **argv)
{
    if (argc > 1 && strcmp(argv[1], "--test") == 0) return self_test();
    if (argc > 2 && strcmp(argv[1], "--csv-ejemplo") == 0) {
        int log2_n_max = (argc > 3) ? atoi(argv[3]) : 24;
        if (log2_n_max < LOG2_N_MIN || log2_n_max > 26) {
            fprintf(stderr, "log2_n_max debe estar entre %d y 26\n", LOG2_N_MIN);
            return EXIT_FAILURE;
        }
        return write_example_csv(argv[2], log2_n_max);
    }
    int log2_n_max = (argc > 1) ? atoi(argv[1]) : 24;
    if (log2_n_max < LOG2_N_MIN || log2_n_max > 26) {
        fprintf(stderr, "Uso: %s [log2_n_max entre %d y 26] | --csv-ejemplo <salida.csv> [log2_n_max] | --test\n",
                argv[0], LOG2_N_MIN);
        return EXIT_FAILURE;
    }
    printf("Referencia CPU (mediana de %d repeticiones tras 1 calentamiento, -O2)\n", N_REPS);
    printf("%10s %12s %12s %12s %12s\n", "n", "add ms", "add GB/s", "saxpy ms", "saxpy GB/s");
    for (int log2n = LOG2_N_MIN; log2n <= log2_n_max; log2n += LOG2_N_STEP) {
        int n = 1 << log2n;
        size_t bytes = (size_t)n * sizeof(float);
        float *a = alloc_or_die(bytes), *b = alloc_or_die(bytes), *c = alloc_or_die(bytes);
        init_inputs(a, b, n);
        double t_add = measure_cpu_ms(0, n, a, b, c);
        double t_saxpy = measure_cpu_ms(1, n, a, b, c);
        double moved = 3.0 * (double)bytes;
        printf("%10d %12.4f %12.1f %12.4f %12.1f\n", n, t_add, moved / (t_add * 1e-3) / 1e9, t_saxpy,
               moved / (t_saxpy * 1e-3) / 1e9);
        free(a);
        free(b);
        free(c);
    }
    return EXIT_SUCCESS;
}
