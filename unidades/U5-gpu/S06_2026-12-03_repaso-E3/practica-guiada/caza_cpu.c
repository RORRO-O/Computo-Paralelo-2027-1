/* caza_cpu.c — Referencia secuencial de los cálculos del cazador de errores y del ejemplo resuelto.
 *
 * Uso:  ./caza_cpu media [n]   media de x[i] = (i % 7) + 0.5          (caza1, MPI)
 *       ./caza_cpu axpb  [n]   checksum de y = 2·x + 1, x[i] = i % 7  (caza2, CUDA)
 *       ./caza_cpu suma  [n]   suma de x[i] = (i % 10) + 1            (caza3, CUDA)
 *       ./caza_cpu grid  [n]   checksum de y = 0.5·x, x[i] = (i%7)+1  (ejemplo resuelto)
 *       ./caza_cpu todo  [n]   las cuatro
 * Imprime el valor de referencia y el tiempo (mediana de 5 repeticiones tras 1 calentamiento),
 * que sirve como T(1) para el speedup del kernel en la celda de medición del notebook.
 * Compila con: gcc -std=c11 -O2 -Wall -Wextra caza_cpu.c -o caza_cpu
 */
#define _POSIX_C_SOURCE 199309L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define REPS 5

static double now_s(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec * 1e-9;
}

static double median5(double *t) {              /* ordena 5 valores y regresa el del centro */
    for (int i = 1; i < REPS; i++)
        for (int j = i; j > 0 && t[j - 1] > t[j]; j--) {
            double tmp = t[j]; t[j] = t[j - 1]; t[j - 1] = tmp;
        }
    return t[REPS / 2];
}

/* Cada cálculo recibe un arreglo de trabajo ya reservado y regresa su resultado escalar. */
static double calc_media(const float *x, float *y, int n) {
    (void) y;
    double s = 0.0;
    for (int i = 0; i < n; i++) s += x[i];
    return s / n;
}
static double calc_axpb(const float *x, float *y, int n) {
    double s = 0.0;
    for (int i = 0; i < n; i++) { y[i] = 2.0f * x[i] + 1.0f; s += y[i]; }
    return s;
}
static double calc_suma(const float *x, float *y, int n) {
    (void) y;
    double s = 0.0;
    for (int i = 0; i < n; i++) s += x[i];
    return s;
}
static double calc_grid(const float *x, float *y, int n) {
    double s = 0.0;
    for (int i = 0; i < n; i++) { y[i] = 0.5f * x[i]; s += y[i]; }
    return s;
}

typedef struct {
    const char *name;
    const char *label;      /* etiqueta del resultado en la salida */
    int decimals;
    float (*init)(int i);
    double (*calc)(const float *, float *, int);
} job_t;

static float init_media(int i) { return (float) (i % 7) + 0.5f; }
static float init_axpb(int i)  { return (float) (i % 7); }
static float init_suma(int i)  { return (float) (i % 10) + 1.0f; }
static float init_grid(int i)  { return (float) (i % 7) + 1.0f; }

static const job_t JOBS[] = {
    { "media", "media",    6, init_media, calc_media },
    { "axpb",  "checksum", 1, init_axpb,  calc_axpb  },
    { "suma",  "suma",     1, init_suma,  calc_suma  },
    { "grid",  "checksum", 1, init_grid,  calc_grid  },
};
#define NJOBS ((int) (sizeof JOBS / sizeof JOBS[0]))

static void run_job(const job_t *job, int n) {
    float *x = malloc(n * sizeof(float));
    float *y = malloc(n * sizeof(float));
    if (!x || !y) { fprintf(stderr, "sin memoria para n=%d\n", n); exit(1); }
    for (int i = 0; i < n; i++) x[i] = job->init(i);

    double result = 0.0, times[REPS];
    for (int r = -1; r < REPS; r++) {            /* r = -1: calentamiento, no se cuenta */
        double t0 = now_s();
        result = job->calc(x, y, n);
        double t1 = now_s();
        if (r >= 0) times[r] = t1 - t0;
    }
    printf("caza_cpu %s: n=%d %s=%.*f t_cpu_ms=%.4f (mediana de %d)\n",
           job->name, n, job->label, job->decimals, result, median5(times) * 1e3, REPS);
    free(x);
    free(y);
}

int main(int argc, char **argv) {
    const char *what = argc > 1 ? argv[1] : "todo";
    int n = argc > 2 ? atoi(argv[2]) : 1000;
    if (n <= 0) { fprintf(stderr, "uso: %s media|axpb|suma|grid|todo [n>0]\n", argv[0]); return 1; }
    int done = 0;
    for (int j = 0; j < NJOBS; j++) {
        if (strcmp(what, "todo") == 0 || strcmp(what, JOBS[j].name) == 0) { run_job(&JOBS[j], n); done++; }
    }
    if (!done) { fprintf(stderr, "uso: %s media|axpb|suma|grid|todo [n>0]\n", argv[0]); return 1; }
    return 0;
}
