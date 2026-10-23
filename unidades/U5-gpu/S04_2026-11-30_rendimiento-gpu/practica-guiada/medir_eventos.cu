// medir_eventos.cu — Ejemplo resuelto S04: cuatro formas de medir el mismo kernel (saxpy)
//
// Compilar en Colab/Kaggle:  nvcc -O2 -arch=sm_75 -o medir_eventos medir_eventos.cu   (sm_60 en una P100)
// Verificar sin GPU:         nvcc -c -arch=sm_75 medir_eventos.cu
// Uso:                       ./medir_eventos [n]        (por defecto n = 2^24 = 16 777 216)
//
// Protocolo del curso: 1 calentamiento que no cuenta + 5 repeticiones; se reporta la mediana (y mín/máx).
#include <cstdio>
#include <cstdlib>
#include <cmath>
#include <ctime>
#include <cuda_runtime.h>

// Revisa el código de error de cada llamada a la API. Sin esto un fallo pasa en silencio (idea errónea 27).
#define CUDA_CHECK(call)                                                          \
    do {                                                                          \
        cudaError_t err__ = (call);                                               \
        if (err__ != cudaSuccess) {                                               \
            fprintf(stderr, "Error CUDA en %s:%d: %s\n", __FILE__, __LINE__,     \
                    cudaGetErrorString(err__));                                   \
            exit(EXIT_FAILURE);                                                   \
        }                                                                         \
    } while (0)

static const int N_REPS = 5;        // repeticiones medidas (impar: la mediana es el elemento central)
static const int BLOCK_SIZE = 256;  // múltiplo de 32; se estudia en bench_gpu.cu

// y[i] = alpha * x[i] + y[i]. Un hilo por elemento; la guarda i < n protege al último bloque.
__global__ void saxpy_kernel(float alpha, const float *x, float *y, int n)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) y[i] = alpha * x[i] + y[i];
}

// Cronómetro de CPU en segundos. Es el equivalente de omp_get_wtime() / MPI_Wtime().
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

// Ordena en sitio y devuelve la mediana (N_REPS es impar).
static double median_ms(double *v, int n)
{
    qsort(v, (size_t)n, sizeof(double), compare_double);
    return v[n / 2];
}

static void print_row(const char *label, double *v)
{
    double med = median_ms(v, N_REPS);  // deja v ordenado: v[0] es el mínimo, v[N_REPS-1] el máximo
    printf("%-44s %12.4f %10.4f %10.4f\n", label, med, v[0], v[N_REPS - 1]);
}

int main(int argc, char **argv)
{
    int n = (argc > 1) ? atoi(argv[1]) : (1 << 24);
    if (n <= 0) {
        fprintf(stderr, "n debe ser positivo\n");
        return EXIT_FAILURE;
    }
    size_t bytes = (size_t)n * sizeof(float);
    const float alpha = 2.0f;

    float *h_x = (float *)malloc(bytes);
    float *h_y = (float *)malloc(bytes);
    float *h_out = (float *)malloc(bytes);
    if (!h_x || !h_y || !h_out) {
        fprintf(stderr, "Sin memoria en el anfitrión\n");
        return EXIT_FAILURE;
    }
    for (int i = 0; i < n; ++i) {
        h_x[i] = (float)(i % 1000) * 0.001f;
        h_y[i] = 1.0f;
    }

    // --- Arranque frío: la primera llamada a la API crea el contexto CUDA (decenas o cientos de ms).
    double t0 = cpu_seconds();
    CUDA_CHECK(cudaFree(0));  // llamada "vacía" que fuerza la creación del contexto
    double t_context_ms = (cpu_seconds() - t0) * 1e3;

    float *d_x = NULL, *d_y = NULL;
    CUDA_CHECK(cudaMalloc((void **)&d_x, bytes));
    CUDA_CHECK(cudaMalloc((void **)&d_y, bytes));
    CUDA_CHECK(cudaMemcpy(d_x, h_x, bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_y, h_y, bytes, cudaMemcpyHostToDevice));

    int grid = (n + BLOCK_SIZE - 1) / BLOCK_SIZE;
    cudaEvent_t ev_start, ev_stop;
    CUDA_CHECK(cudaEventCreate(&ev_start));
    CUDA_CHECK(cudaEventCreate(&ev_stop));

    // --- Calentamiento: el primer lanzamiento carga el módulo y llena cachés; no se cuenta.
    double t_first = cpu_seconds();
    saxpy_kernel<<<grid, BLOCK_SIZE>>>(alpha, d_x, d_y, n);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaDeviceSynchronize());
    double t_first_ms = (cpu_seconds() - t_first) * 1e3;

    double t_nosync[N_REPS], t_sync[N_REPS], t_event[N_REPS], t_total[N_REPS];
    float ms = 0.0f;

    for (int r = 0; r < N_REPS; ++r) {
        // Forma 1 (INCORRECTA): cronómetro de CPU sin sincronizar. El lanzamiento es asíncrono: la CPU
        // sigue antes de que el kernel termine, así que esto mide solo el costo de encolarlo.
        CUDA_CHECK(cudaMemcpy(d_y, h_y, bytes, cudaMemcpyHostToDevice));  // restaura y (saxpy es en sitio)
        double t = cpu_seconds();
        saxpy_kernel<<<grid, BLOCK_SIZE>>>(alpha, d_x, d_y, n);
        t_nosync[r] = (cpu_seconds() - t) * 1e3;
        CUDA_CHECK(cudaDeviceSynchronize());  // fuera del cronómetro: por eso la medición miente

        // Forma 2: cronómetro de CPU + cudaDeviceSynchronize(). Correcta; incluye la espera de la CPU.
        CUDA_CHECK(cudaMemcpy(d_y, h_y, bytes, cudaMemcpyHostToDevice));
        t = cpu_seconds();
        saxpy_kernel<<<grid, BLOCK_SIZE>>>(alpha, d_x, d_y, n);
        CUDA_CHECK(cudaDeviceSynchronize());
        t_sync[r] = (cpu_seconds() - t) * 1e3;

        // Forma 3: eventos en el stream alrededor del kernel. Se mide con el reloj de la GPU.
        CUDA_CHECK(cudaMemcpy(d_y, h_y, bytes, cudaMemcpyHostToDevice));
        CUDA_CHECK(cudaEventRecord(ev_start, 0));
        saxpy_kernel<<<grid, BLOCK_SIZE>>>(alpha, d_x, d_y, n);
        CUDA_CHECK(cudaEventRecord(ev_stop, 0));
        CUDA_CHECK(cudaEventSynchronize(ev_stop));  // espera a que el evento de fin se complete
        CUDA_CHECK(cudaEventElapsedTime(&ms, ev_start, ev_stop));
        t_event[r] = ms;

        // Forma 4: eventos alrededor de H2D + kernel + D2H. Es lo que paga quien tiene los datos en la CPU.
        CUDA_CHECK(cudaEventRecord(ev_start, 0));
        CUDA_CHECK(cudaMemcpy(d_x, h_x, bytes, cudaMemcpyHostToDevice));
        CUDA_CHECK(cudaMemcpy(d_y, h_y, bytes, cudaMemcpyHostToDevice));
        saxpy_kernel<<<grid, BLOCK_SIZE>>>(alpha, d_x, d_y, n);
        CUDA_CHECK(cudaMemcpy(h_out, d_y, bytes, cudaMemcpyDeviceToHost));
        CUDA_CHECK(cudaEventRecord(ev_stop, 0));
        CUDA_CHECK(cudaEventSynchronize(ev_stop));
        CUDA_CHECK(cudaEventElapsedTime(&ms, ev_start, ev_stop));
        t_total[r] = ms;
    }
    CUDA_CHECK(cudaGetLastError());

    // --- Verificación contra la CPU: siempre, antes de creer cualquier tiempo.
    double max_err = 0.0;
    for (int i = 0; i < n; ++i) {
        double ref = (double)alpha * h_x[i] + h_y[i];
        double err = fabs(ref - h_out[i]);
        if (err > max_err) max_err = err;
    }

    printf("medir_eventos: saxpy con n = %d (%.1f MB por vector), bloque = %d, malla = %d\n",
           n, (double)bytes / 1048576.0, BLOCK_SIZE, grid);
    printf("Primera llamada CUDA (creación del contexto): %.1f ms\n", t_context_ms);
    printf("Primer lanzamiento del kernel (frío):          %.3f ms  <- por eso hay calentamiento\n", t_first_ms);
    printf("\n%-44s %12s %10s %10s\n", "Forma de medir", "mediana ms", "min", "max");
    print_row("1. CPU sin sincronizar (INCORRECTA)", t_nosync);
    print_row("2. CPU + cudaDeviceSynchronize", t_sync);
    print_row("3. cudaEvent alrededor del kernel", t_event);
    print_row("4. cudaEvent H2D + kernel + D2H", t_total);
    double med_kernel = t_event[N_REPS / 2], med_total = t_total[N_REPS / 2];  // ya ordenados
    printf("\nCopias = %.1f %% del total (total %.3f ms, kernel %.3f ms)\n",
           100.0 * (med_total - med_kernel) / med_total, med_total, med_kernel);
    printf("Ancho de banda efectivo del kernel: %.1f GB/s (%zu bytes leídos+escritos)\n",
           3.0 * (double)bytes / (med_kernel * 1e-3) / 1e9, 3 * bytes);
    printf("Verificación contra CPU: %s (error máximo %.2e)\n", max_err < 1e-5 ? "OK" : "FALLA", max_err);

    CUDA_CHECK(cudaEventDestroy(ev_start));
    CUDA_CHECK(cudaEventDestroy(ev_stop));
    CUDA_CHECK(cudaFree(d_x));
    CUDA_CHECK(cudaFree(d_y));
    free(h_x);
    free(h_y);
    free(h_out);
    CUDA_CHECK(cudaDeviceReset());  // vacía los búferes del perfilador (nsys) antes de salir
    return (max_err < 1e-5) ? EXIT_SUCCESS : EXIT_FAILURE;
}
