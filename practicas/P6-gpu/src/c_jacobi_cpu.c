/*
 * c_jacobi_cpu.c — Referencia secuencial de la Parte C, opción 2: stencil 2D de Jacobi con doble
 * búfer y criterio de convergencia por reducción máxima.
 *
 * Uso:      ./c_jacobi_cpu [alto=512] [ancho=512] [tol=1e-3] [max_iter=500] [check_every=10]
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra c_jacobi_cpu.c -o c_jacobi_cpu
 *
 * ENTRADA (la misma que debe usar tu kernel; el generador está también en common.cuh):
 *   malla alto×ancho de float aplanada por filas (idx = fila*ancho + col); fila 0 = 100, resto 0.
 * ALGORITMO (tu GPU debe hacer exactamente esto para que los números coincidan):
 *   repetir: out[r][c] = 0.25*(in[r-1][c] + in[r+1][c] + in[r][c-1] + in[r][c+1]) en el interior;
 *            la frontera se copia sin cambio; se intercambian los punteros (doble búfer).
 *            Cada check_every iteraciones se calcula max_diff = máx |out - in| (reducción máxima) y
 *            se detiene si max_diff < tol. También se detiene al llegar a max_iter.
 * SALIDA que tu programa debe reproducir: iteraciones (exacto), motivo de paro, max_diff final y
 *   checksum = Σ malla final (con tolerancia relativa 1e-4: la GPU redondea distinto).
 * Con mallas grandes Jacobi converge MUY despacio (el error cae como (1 − π²/2N²)^k): con 512×512 y
 * tol = 1e-3 manda max_iter. Es normal; repórtalo. Con 64×64 y tol = 1e-2 sí converge antes.
 * T(1): 1 calentamiento + 5 repeticiones de la ejecución completa, mediana (1 si alto·ancho·max_iter > 3e8).
 */
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>

#define REPS 5

static double now_s(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}

/* Idéntico a init_jacobi_grid() de common.cuh. */
static void init_grid(float *grid, int height, int width)
{
    for (int r = 0; r < height; ++r)
        for (int c = 0; c < width; ++c)
            grid[(size_t)r * width + c] = (r == 0) ? 100.0f : 0.0f;
}

/* Un paso de Jacobi: interior desde in hacia out; la frontera se copia. */
static void jacobi_step(const float *in, float *out, int height, int width)
{
    for (int r = 0; r < height; ++r)
        for (int c = 0; c < width; ++c) {
            size_t idx = (size_t)r * width + c;
            if (r == 0 || r == height - 1 || c == 0 || c == width - 1)
                out[idx] = in[idx];
            else
                out[idx] = 0.25f * (in[idx - width] + in[idx + width] + in[idx - 1] + in[idx + 1]);
        }
}

static float max_abs_diff(const float *a, const float *b, size_t count)
{
    float m = 0.0f;
    for (size_t i = 0; i < count; ++i) {
        float d = fabsf(a[i] - b[i]);
        if (d > m)
            m = d;
    }
    return m;
}

/* Ejecuta Jacobi completo. Regresa iteraciones; deja la malla final en *final y max_diff en *last_diff. */
static int jacobi_run(float *a, float *b, int height, int width, float tol, int max_iter, int check_every,
                      float **final, float *last_diff, int *converged)
{
    size_t count = (size_t)height * width;
    init_grid(a, height, width);
    memcpy(b, a, count * sizeof(float)); /* la frontera de b también debe estar bien */
    float *in = a, *out = b;
    int iter = 0;
    *last_diff = -1.0f;
    *converged = 0;
    while (iter < max_iter) {
        jacobi_step(in, out, height, width);
        ++iter;
        if (iter % check_every == 0) {
            *last_diff = max_abs_diff(out, in, count); /* reducción máxima */
            if (*last_diff < tol) {
                *converged = 1;
                float *tmp = in; in = out; out = tmp;
                break;
            }
        }
        float *tmp = in; in = out; out = tmp; /* doble búfer: intercambio de punteros */
    }
    *final = in;
    return iter;
}

static int cmp_double(const void *x, const void *y)
{
    double dx = *(const double *)x, dy = *(const double *)y;
    return (dx > dy) - (dx < dy);
}

int main(int argc, char **argv)
{
    int height = (argc > 1) ? atoi(argv[1]) : 512;
    int width = (argc > 2) ? atoi(argv[2]) : 512;
    float tol = (argc > 3) ? (float)atof(argv[3]) : 1e-3f;
    int max_iter = (argc > 4) ? atoi(argv[4]) : 500;
    int check_every = (argc > 5) ? atoi(argv[5]) : 10;
    if (height < 3 || width < 3 || tol <= 0 || max_iter <= 0 || check_every <= 0) {
        fprintf(stderr, "uso: %s [alto>=3] [ancho>=3] [tol>0] [max_iter>0] [check_every>0]\n", argv[0]);
        return 1;
    }
    size_t count = (size_t)height * width;
    float *a = malloc(count * sizeof(float)), *b = malloc(count * sizeof(float));
    if (!a || !b) {
        fprintf(stderr, "Sin memoria para %dx%d\n", height, width);
        return 1;
    }
    int reps = ((double)count * max_iter <= 3e8) ? REPS : 1;
    double t[REPS];
    float *final = NULL, last_diff = 0.0f;
    int iters = 0, converged = 0;
    for (int r = -1; r < reps; ++r) {
        double t0 = now_s();
        iters = jacobi_run(a, b, height, width, tol, max_iter, check_every, &final, &last_diff, &converged);
        double dt = now_s() - t0;
        if (r >= 0)
            t[r] = dt;
    }
    qsort(t, (size_t)reps, sizeof(double), cmp_double);

    double checksum = 0.0;
    for (size_t i = 0; i < count; ++i)
        checksum += final[i];

    printf("c_jacobi_cpu: alto=%d ancho=%d tol=%g max_iter=%d check_every=%d t_cpu_ms=%.3f (mediana de %d; "
           "min %.3f, max %.3f)\n",
           height, width, tol, max_iter, check_every, t[reps / 2] * 1e3, reps, t[0] * 1e3, t[reps - 1] * 1e3);
    printf("  iteraciones=%d paro=%s max_diff=%.6e checksum=%.6f centro=%.6f\n", iters,
           converged ? "convergio" : "max_iter", last_diff, checksum, final[(size_t)(height / 2) * width + width / 2]);
    free(a);
    free(b);
    return 0;
}
