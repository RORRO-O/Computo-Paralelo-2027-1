/* main_cpu.c — Referencia en CPU de la práctica guiada de GPU (C). PUNTO DE PARTIDA de /nueva-sesion.
 * Sustituye calcular() por el problema de la sesión; el kernel (main_numba.py y, en Colab/Kaggle, el .cu
 * que agregues) debe dar el mismo resultado con tolerancia.
 *
 * Problema de relleno: SAXPY y[i] = a*x[i] + y[i] con x[i] = i mod 7, y[i] = 1, a = 2; se reporta la suma de y.
 *
 * Uso:    ./main_cpu [n]            (n por defecto: 4000000)
 * Salida: n=<valor>  resultado=<valor>  tiempo_s=<segundos>   (una clave por línea)
 * Código de salida: 0; 2 si n no es un entero positivo; 1 si no hay memoria.
 */
#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define DEFAULT_N 4000000L

static double wall_time(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + 1e-9 * (double)ts.tv_nsec;
}

static void calcular(long n, float a, const float *x, float *y)
{
    for (long i = 0; i < n; i++) {
        y[i] = a * x[i] + y[i];
    }
}

int main(int argc, char **argv)
{
    long n = DEFAULT_N;
    if (argc > 1) {
        char *end = NULL;
        errno = 0;
        n = strtol(argv[argc - 1], &end, 10);
        if (errno != 0 || end == argv[argc - 1] || *end != '\0' || n <= 0) {
            fprintf(stderr, "uso: %s [n]   (n entero positivo)\n", argv[0]);
            return 2;
        }
    }
    float *x = malloc((size_t)n * sizeof *x);
    float *y = malloc((size_t)n * sizeof *y);
    if (x == NULL || y == NULL) {
        fprintf(stderr, "sin memoria para n=%ld\n", n);
        free(x);
        free(y);
        return 1;
    }
    for (long i = 0; i < n; i++) {
        x[i] = (float)(i % 7);
        y[i] = 1.0f;
    }

    double t0 = wall_time();
    calcular(n, 2.0f, x, y);
    double elapsed = wall_time() - t0;

    double checksum = 0.0;
    for (long i = 0; i < n; i++) {
        checksum += (double)y[i];
    }
    printf("n=%ld\n", n);
    printf("resultado=%.1f\n", checksum);
    printf("tiempo_s=%.6f\n", elapsed);
    free(x);
    free(y);
    return 0;
}
