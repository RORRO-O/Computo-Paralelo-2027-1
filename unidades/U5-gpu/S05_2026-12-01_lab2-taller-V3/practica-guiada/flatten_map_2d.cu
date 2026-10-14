// flatten_map_2d.cu — Mini PRIMM "aplanar y mapear"
// Un paso de Jacobi 2D (promedio de los 4 vecinos) sobre una malla alto x ancho que vive
// aplanada en un arreglo 1D (por filas). El kernel 2D usa blockIdx.y/threadIdx.y; la variante
// 1D (modo "1d") tiene un TODO(1) que completa el estudiante en la fase Modificar.
//
// Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · Unidad V · Sesión S05 (martes 1 de diciembre de 2026)
//
// Uso:
//   ./flatten_map_2d [alto] [ancho] [iteraciones] [bloque_x] [bloque_y] [modo 2d|1d]
//                    [copiar_cada_iter 0|1] [fila_objetivo] [col_objetivo]
// Por defecto: 1024 1024 100 16 16 2d 0 3 5
// Variable de entorno CPU_REPS (por defecto 5): repeticiones de la referencia CPU.
//
// Verificación local sin GPU:  nvcc -c -arch=sm_75 flatten_map_2d.cu   (solo compila)
// En Colab/Kaggle:             nvcc -O2 -arch=sm_75 flatten_map_2d.cu -o flatten_map_2d && ./flatten_map_2d
//
// Experimento deliberadamente incorrecto (solo en Colab, fase Investigar):
//   nvcc -O2 -arch=sm_75 -DSIN_GUARDIA flatten_map_2d.cu -o sin_guardia
//   Quita la guardia de rango del kernel 2D: con dimensiones no múltiplos del bloque los hilos
//   sobrantes escriben fuera del arreglo (comportamiento indefinido a propósito).

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cmath>
#include <chrono>
#include <algorithm>
#include <vector>
#include <cuda_runtime.h>

// Toda llamada al API se revisa. Un error silencioso en cudaMalloc o cudaMemcpy produce
// resultados basura que "no dan error" en el kernel (idea errónea 27 del Anexo A).
#define CUDA_CHECK(call)                                                              \
    do {                                                                              \
        cudaError_t err__ = (call);                                                   \
        if (err__ != cudaSuccess) {                                                   \
            fprintf(stderr, "Error CUDA en %s:%d: %s\n", __FILE__, __LINE__,          \
                    cudaGetErrorString(err__));                                       \
            exit(EXIT_FAILURE);                                                       \
        }                                                                             \
    } while (0)

static const int   REPS      = 5;       // repeticiones medidas (protocolo del curso)
static const float TOP_VALUE = 100.0f;  // frontera superior "caliente"; el resto empieza en 0
static const float TOL       = 1e-4f;   // tolerancia absoluta de la verificación vs. CPU

// Índice lineal de (fila r, columna c) en una malla de ancho w guardada por filas.
__host__ __device__ inline int lin(int r, int c, int w) { return r * w + c; }

// ---------------------------------------------------------------------------------------
// Kernel 2D: cada hilo procesa una celda; x recorre columnas (lo contiguo), y recorre filas.
// ---------------------------------------------------------------------------------------
__global__ void jacobi_step_2d(const float *in, float *out, int height, int width,
                               int target_r, int target_c, int *who)
{
    int c = blockIdx.x * blockDim.x + threadIdx.x;   // columna
    int r = blockIdx.y * blockDim.y + threadIdx.y;   // fila
#ifndef SIN_GUARDIA
    // Guardia: cuando alto o ancho no son múltiplos del bloque sobran hilos. Sin esta línea
    // escriben fuera del arreglo.
    if (r >= height || c >= width) return;
#endif
    int idx = lin(r, c, width);

    // Registro de "quién procesó la celda objetivo" (para comparar con tu predicción).
    if (r == target_r && c == target_c) {
        who[0] = blockIdx.x;  who[1] = blockIdx.y;
        who[2] = threadIdx.x; who[3] = threadIdx.y;
        who[4] = idx;
    }

    // La frontera se copia tal cual (condición de Dirichlet fija).
    if (r == 0 || r == height - 1 || c == 0 || c == width - 1) {
        out[idx] = in[idx];
        return;
    }
    // Celda interior: promedio de arriba, abajo, izquierda y derecha (leídos de `in`, nunca de `out`).
    out[idx] = 0.25f * (in[idx - width] + in[idx + width] + in[idx - 1] + in[idx + 1]);
}

// ---------------------------------------------------------------------------------------
// Kernel 1D: cada hilo recibe un índice lineal y debe recuperar (fila, columna).
// ---------------------------------------------------------------------------------------
__global__ void jacobi_step_1d(const float *in, float *out, int height, int width,
                               int target_r, int target_c, int *who)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;   // un índice lineal por hilo
    if (idx >= height * width) return;                 // guardia del último bloque

    /* TODO(1): calcula la fila r y la columna c a partir de idx, sabiendo que idx = r*width + c.
       Mientras r y c valgan -1, la guardia de abajo descarta a todos los hilos y el programa
       imprime "TODO pendiente" en modo 1d. */
    int r = -1;
    int c = -1;
    if (r < 0 || c < 0) return;

    if (r == target_r && c == target_c) {
        who[0] = blockIdx.x;  who[1] = 0;
        who[2] = threadIdx.x; who[3] = 0;
        who[4] = idx;
    }
    if (r == 0 || r == height - 1 || c == 0 || c == width - 1) {
        out[idx] = in[idx];
        return;
    }
    out[idx] = 0.25f * (in[idx - width] + in[idx + width] + in[idx - 1] + in[idx + 1]);
}

// ---------------------------------------------------------------------------------------
// Anfitrión: inicialización, referencia secuencial, utilidades.
// ---------------------------------------------------------------------------------------
static void init_grid(float *g, int h, int w)
{
    for (int r = 0; r < h; r++)
        for (int c = 0; c < w; c++)
            g[lin(r, c, w)] = (r == 0) ? TOP_VALUE : 0.0f;
}

// Referencia secuencial (misma aritmética en float que el kernel). Deja el resultado en `out`.
static void jacobi_cpu(const float *init, float *out, float *tmp, int h, int w, int iters)
{
    float *cur = out, *nxt = tmp;
    memcpy(cur, init, (size_t)h * w * sizeof(float));
    memcpy(nxt, init, (size_t)h * w * sizeof(float));   // la frontera ya queda copiada en ambos
    for (int it = 0; it < iters; it++) {
        for (int r = 1; r < h - 1; r++)
            for (int c = 1; c < w - 1; c++) {
                int idx = lin(r, c, w);
                nxt[idx] = 0.25f * (cur[idx - w] + cur[idx + w] + cur[idx - 1] + cur[idx + 1]);
            }
        std::swap(cur, nxt);
    }
    if (cur != out) memcpy(out, cur, (size_t)h * w * sizeof(float));
}

static double now_s(void)
{
    using namespace std::chrono;
    return duration<double>(steady_clock::now().time_since_epoch()).count();
}

static double median(std::vector<double> v)
{
    std::sort(v.begin(), v.end());
    size_t n = v.size();
    return (n % 2) ? v[n / 2] : 0.5 * (v[n / 2 - 1] + v[n / 2]);
}

static double checksum(const float *g, size_t n)
{
    double s = 0.0;
    for (size_t i = 0; i < n; i++) s += g[i];
    return s;
}

static int ceil_div(int a, int b) { return (a + b - 1) / b; }

struct Config {
    int h, w, iters, bx, by;
    bool mode_2d;
    bool copy_each;
    int target_r, target_c;
};

// Una corrida completa de la "V3": H2D, `iters` pasos de Jacobi y D2H.
// Devuelve el tiempo solo de kernels y el tiempo total (con transferencias), ambos en segundos.
// Si copy_each es verdadero reproduce el error típico de porte: copiar ida y vuelta en cada iteración.
static void run_once(const Config &cfg, const float *h_init, float *h_out, float *h_scratch,
                     float *d_a, float *d_b, int *d_who, dim3 grid, dim3 block,
                     double *t_kernel_s, double *t_total_s)
{
    size_t bytes = (size_t)cfg.h * cfg.w * sizeof(float);
    cudaEvent_t e_total0, e_total1, e_k0, e_k1;
    CUDA_CHECK(cudaEventCreate(&e_total0)); CUDA_CHECK(cudaEventCreate(&e_total1));
    CUDA_CHECK(cudaEventCreate(&e_k0));     CUDA_CHECK(cudaEventCreate(&e_k1));
    float ms = 0.0f, ms_kernel = 0.0f;

    CUDA_CHECK(cudaEventRecord(e_total0));
    if (!cfg.copy_each) {
        // Porte correcto: los datos suben una vez, iteran en la GPU y bajan una vez.
        CUDA_CHECK(cudaMemcpy(d_a, h_init, bytes, cudaMemcpyHostToDevice));
        CUDA_CHECK(cudaMemcpy(d_b, h_init, bytes, cudaMemcpyHostToDevice));  // frontera en ambos
        CUDA_CHECK(cudaEventRecord(e_k0));
        for (int it = 0; it < cfg.iters; it++) {
            if (cfg.mode_2d)
                jacobi_step_2d<<<grid, block>>>(d_a, d_b, cfg.h, cfg.w, cfg.target_r, cfg.target_c, d_who);
            else
                jacobi_step_1d<<<grid, block>>>(d_a, d_b, cfg.h, cfg.w, cfg.target_r, cfg.target_c, d_who);
            CUDA_CHECK(cudaGetLastError());   // errores de lanzamiento (bloque inválido, etc.)
            std::swap(d_a, d_b);              // ping-pong: no hay copias, solo se intercambian punteros
        }
        CUDA_CHECK(cudaEventRecord(e_k1));
        CUDA_CHECK(cudaEventSynchronize(e_k1));   // sin esto se mide el encolado, no la ejecución
        CUDA_CHECK(cudaEventElapsedTime(&ms_kernel, e_k0, e_k1));
        CUDA_CHECK(cudaMemcpy(h_out, d_a, bytes, cudaMemcpyDeviceToHost));
    } else {
        // Porte incorrecto (a propósito): cada iteración sube la malla, lanza y baja el resultado.
        memcpy(h_scratch, h_init, bytes);
        CUDA_CHECK(cudaMemcpy(d_b, h_init, bytes, cudaMemcpyHostToDevice));  // frontera en d_b
        for (int it = 0; it < cfg.iters; it++) {
            CUDA_CHECK(cudaMemcpy(d_a, h_scratch, bytes, cudaMemcpyHostToDevice));
            CUDA_CHECK(cudaEventRecord(e_k0));
            if (cfg.mode_2d)
                jacobi_step_2d<<<grid, block>>>(d_a, d_b, cfg.h, cfg.w, cfg.target_r, cfg.target_c, d_who);
            else
                jacobi_step_1d<<<grid, block>>>(d_a, d_b, cfg.h, cfg.w, cfg.target_r, cfg.target_c, d_who);
            CUDA_CHECK(cudaGetLastError());
            CUDA_CHECK(cudaEventRecord(e_k1));
            CUDA_CHECK(cudaEventSynchronize(e_k1));
            float ms_it = 0.0f;
            CUDA_CHECK(cudaEventElapsedTime(&ms_it, e_k0, e_k1));
            ms_kernel += ms_it;
            CUDA_CHECK(cudaMemcpy(h_scratch, d_b, bytes, cudaMemcpyDeviceToHost));
        }
        memcpy(h_out, h_scratch, bytes);
    }
    CUDA_CHECK(cudaEventRecord(e_total1));
    CUDA_CHECK(cudaEventSynchronize(e_total1));
    CUDA_CHECK(cudaEventElapsedTime(&ms, e_total0, e_total1));

    *t_kernel_s = ms_kernel * 1e-3;
    *t_total_s  = ms * 1e-3;
    CUDA_CHECK(cudaEventDestroy(e_total0)); CUDA_CHECK(cudaEventDestroy(e_total1));
    CUDA_CHECK(cudaEventDestroy(e_k0));     CUDA_CHECK(cudaEventDestroy(e_k1));
}

static void usage(const char *prog)
{
    fprintf(stderr,
        "Uso: %s [alto] [ancho] [iteraciones] [bloque_x] [bloque_y] [modo 2d|1d] "
        "[copiar_cada_iter 0|1] [fila_objetivo] [col_objetivo]\n"
        "Por defecto: 1024 1024 100 16 16 2d 0 3 5\n", prog);
}

int main(int argc, char **argv)
{
    Config cfg = {1024, 1024, 100, 16, 16, true, false, 3, 5};
    if (argc > 1 && (strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0)) {
        usage(argv[0]);
        return 0;
    }
    if (argc > 1) cfg.h     = atoi(argv[1]);
    if (argc > 2) cfg.w     = atoi(argv[2]);
    if (argc > 3) cfg.iters = atoi(argv[3]);
    if (argc > 4) cfg.bx    = atoi(argv[4]);
    if (argc > 5) cfg.by    = atoi(argv[5]);
    if (argc > 6) {
        if (strcmp(argv[6], "2d") == 0)      cfg.mode_2d = true;
        else if (strcmp(argv[6], "1d") == 0) cfg.mode_2d = false;
        else { usage(argv[0]); return 1; }
    }
    if (argc > 7) cfg.copy_each = atoi(argv[7]) != 0;
    if (argc > 8) cfg.target_r  = atoi(argv[8]);
    if (argc > 9) cfg.target_c  = atoi(argv[9]);

    if (cfg.h < 3 || cfg.w < 3 || cfg.iters < 1 || cfg.bx < 1 || cfg.by < 1 || cfg.bx * cfg.by > 1024) {
        fprintf(stderr, "Parámetros inválidos: alto y ancho >= 3, iteraciones >= 1, 1 <= bloque_x*bloque_y <= 1024\n");
        return 1;
    }
    if (cfg.target_r < 0 || cfg.target_r >= cfg.h || cfg.target_c < 0 || cfg.target_c >= cfg.w) {
        fprintf(stderr, "La celda objetivo (%d,%d) está fuera de la malla %dx%d\n",
                cfg.target_r, cfg.target_c, cfg.h, cfg.w);
        return 1;
    }

    const size_t n     = (size_t)cfg.h * cfg.w;
    const size_t bytes = n * sizeof(float);
    int cpu_reps = 5;
    if (const char *env = getenv("CPU_REPS")) cpu_reps = std::max(1, atoi(env));

    printf("# flatten_map_2d · alto=%d ancho=%d iteraciones=%d bloque=%dx%d modo=%s copiar_cada_iter=%d\n",
           cfg.h, cfg.w, cfg.iters, cfg.bx, cfg.by, cfg.mode_2d ? "2d" : "1d", cfg.copy_each ? 1 : 0);
#ifdef SIN_GUARDIA
    printf("# ADVERTENCIA: compilado con -DSIN_GUARDIA; el kernel 2D escribe fuera de rango a propósito.\n");
#endif
    cudaDeviceProp prop;
    CUDA_CHECK(cudaGetDeviceProperties(&prop, 0));
    printf("GPU: %s (%d SMs, %d hilos máx. por bloque)\n", prop.name, prop.multiProcessorCount, prop.maxThreadsPerBlock);

    // --- Anfitrión -----------------------------------------------------------------------
    float *h_init    = (float *)malloc(bytes);
    float *h_ref     = (float *)malloc(bytes);
    float *h_tmp     = (float *)malloc(bytes);
    float *h_out     = (float *)malloc(bytes);
    float *h_scratch = (float *)malloc(bytes);
    if (!h_init || !h_ref || !h_tmp || !h_out || !h_scratch) { fprintf(stderr, "Sin memoria en el anfitrión\n"); return 1; }
    init_grid(h_init, cfg.h, cfg.w);

    // Referencia CPU: 1 calentamiento + cpu_reps repeticiones; se reporta la mediana.
    jacobi_cpu(h_init, h_ref, h_tmp, cfg.h, cfg.w, cfg.iters);
    std::vector<double> t_cpu_v;
    for (int rep = 0; rep < cpu_reps; rep++) {
        double t0 = now_s();
        jacobi_cpu(h_init, h_ref, h_tmp, cfg.h, cfg.w, cfg.iters);
        t_cpu_v.push_back(now_s() - t0);
    }
    double t_cpu = median(t_cpu_v);

    printf("indice lineal de (fila %d, col %d) con ancho %d: %d\n",
           cfg.target_r, cfg.target_c, cfg.w, lin(cfg.target_r, cfg.target_c, cfg.w));

    // --- Dispositivo ---------------------------------------------------------------------
    float *d_a = nullptr, *d_b = nullptr;
    int   *d_who = nullptr;
    CUDA_CHECK(cudaMalloc(&d_a, bytes));
    CUDA_CHECK(cudaMalloc(&d_b, bytes));
    CUDA_CHECK(cudaMalloc(&d_who, 5 * sizeof(int)));
    CUDA_CHECK(cudaMemset(d_a, 0, bytes));
    CUDA_CHECK(cudaMemset(d_b, 0, bytes));
    CUDA_CHECK(cudaMemset(d_who, 0xFF, 5 * sizeof(int)));   // todos los bytes a 1 → cada int vale -1

    dim3 block, grid;
    long threads_launched;
    if (cfg.mode_2d) {
        block = dim3(cfg.bx, cfg.by);
        grid  = dim3(ceil_div(cfg.w, cfg.bx), ceil_div(cfg.h, cfg.by));   // x ↔ columnas, y ↔ filas
        threads_launched = (long)grid.x * grid.y * block.x * block.y;
        printf("malla 2D: bloques=%ux%u hilos/bloque=%ux%u\n", grid.x, grid.y, block.x, block.y);
    } else {
        block = dim3(cfg.bx * cfg.by);
        grid  = dim3(ceil_div((int)n, cfg.bx * cfg.by));
        threads_launched = (long)grid.x * block.x;
        printf("malla 1D: bloques=%u hilos/bloque=%u\n", grid.x, block.x);
    }
    printf("hilos lanzados=%ld celdas=%zu hilos ociosos=%ld (%.1f %%)\n",
           threads_launched, n, threads_launched - (long)n,
           100.0 * (double)(threads_launched - (long)n) / (double)threads_launched);

    // Calentamiento (no se cuenta) + REPS corridas medidas.
    double tk, tt;
    run_once(cfg, h_init, h_out, h_scratch, d_a, d_b, d_who, grid, block, &tk, &tt);
    std::vector<double> t_kernel_v, t_total_v;
    for (int rep = 0; rep < REPS; rep++) {
        run_once(cfg, h_init, h_out, h_scratch, d_a, d_b, d_who, grid, block, &tk, &tt);
        t_kernel_v.push_back(tk);
        t_total_v.push_back(tt);
    }
    CUDA_CHECK(cudaDeviceSynchronize());
    CUDA_CHECK(cudaGetLastError());   // errores de ejecución (acceso ilegal, etc.)

    int who[5];
    CUDA_CHECK(cudaMemcpy(who, d_who, 5 * sizeof(int), cudaMemcpyDeviceToHost));

    const char *verdict = "FAIL";
    int exit_code = 1;
    if (who[4] == -1) {
        if (!cfg.mode_2d) {
            printf("TODO pendiente: el kernel 1D aún no recupera (fila, columna) a partir de idx. "
                   "Completa TODO(1) en jacobi_step_1d.\n");
            verdict = "TODO";
            exit_code = 0;
        } else {
            printf("ningún hilo procesó la celda objetivo: revisa la malla y la guardia\n");
        }
    } else {
        printf("hilo que la proceso: blockIdx=(%d,%d) threadIdx=(%d,%d) idx=%d\n",
               who[0], who[1], who[2], who[3], who[4]);
        // Verificación contra la CPU con tolerancia: el kernel "sin error" no basta.
        float max_diff = 0.0f;
        for (size_t i = 0; i < n; i++) max_diff = std::max(max_diff, fabsf(h_out[i] - h_ref[i]));
        bool ok = max_diff <= TOL;
        verdict = ok ? "PASS" : "FAIL";
        exit_code = ok ? 0 : 1;
        printf("verificacion vs CPU: %s (max |diff| = %.3e, tol = %.1e)\n", verdict, (double)max_diff, (double)TOL);
        printf("checksum = %.6f\n", checksum(h_out, n));
    }

    double t_kernel = median(t_kernel_v), t_total = median(t_total_v);
    printf("t_cpu    (mediana de %d, s) = %.6f\n", cpu_reps, t_cpu);
    printf("t_kernel (mediana de %d, s) = %.6f   <- solo kernels (cudaEvent)\n", REPS, t_kernel);
    printf("t_total  (mediana de %d, s) = %.6f   <- H2D + kernels + D2H\n", REPS, t_total);
    printf("speedup sin transferencias = %.2f\n", t_cpu / t_kernel);
    printf("speedup con transferencias = %.2f\n", t_cpu / t_total);
    printf("CSV,modo,bloque_x,bloque_y,alto,ancho,iteraciones,copiar_cada_iter,t_cpu_s,t_kernel_s,t_total_s,speedup_kernel,speedup_total,verificacion\n");
    printf("CSV,%s,%d,%d,%d,%d,%d,%d,%.6f,%.6f,%.6f,%.2f,%.2f,%s\n",
           cfg.mode_2d ? "2d" : "1d", cfg.bx, cfg.by, cfg.h, cfg.w, cfg.iters, cfg.copy_each ? 1 : 0,
           t_cpu, t_kernel, t_total, t_cpu / t_kernel, t_cpu / t_total, verdict);

    CUDA_CHECK(cudaFree(d_a)); CUDA_CHECK(cudaFree(d_b)); CUDA_CHECK(cudaFree(d_who));
    free(h_init); free(h_ref); free(h_tmp); free(h_out); free(h_scratch);
    return exit_code;
}
