/*
 * unbalanced.c — Tiempo por política de planificación en ciclos con carga
 * uniforme y desbalanceada.
 *
 * Todos los ciclos paralelos usan schedule(runtime). La política se fija con
 * omp_set_schedule() a partir de los argumentos, o con OMP_SCHEDULE si se pide
 * "runtime". Se mide con el protocolo del curso: 1 calentamiento + REPS
 * repeticiones (5 por omisión), se reporta la mediana, el mínimo y el máximo,
 * y cada resultado paralelo se verifica contra la versión secuencial.
 *
 * Núcleos (kernels):
 *   uniform     n iteraciones de costo idéntico              (carga uniforme)
 *   triangular  for i<n: for j<i  (la iteración i cuesta ~i) (carga creciente)
 *   collatz     longitud de la secuencia de Collatz de 1..n  (carga irregular)
 *   mandelbrot  conjunto de Mandelbrot de n x n por filas     (carga concentrada
 *                                                            en las filas centrales)
 *
 * Uso:  ./unbalanced <kernel> [n] [politica ...]
 *   politica: static | static,C | dynamic | dynamic,C | guided | guided,C | auto | runtime
 *   Si no se da ninguna política se usan: static static,1 dynamic,16 guided,16
 *   Variable de entorno REPS: repeticiones cronometradas (por omisión 5).
 *
 * Ejemplos:
 *   OMP_NUM_THREADS=4 ./unbalanced triangular 20000 static static,1 dynamic,16 guided,16
 *   OMP_NUM_THREADS=4 OMP_SCHEDULE="dynamic,64" ./unbalanced collatz 2000000 runtime
 *
 * Código de salida: 0 si todas las verificaciones pasan, 1 si alguna falla.
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra -fopenmp unbalanced.c -o unbalanced
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <omp.h>

#define MAX_REPS   32
#define MANDEL_MAX_ITER 500

enum kernel_id { K_UNIFORM, K_TRIANGULAR, K_COLLATZ, K_MANDELBROT };

/* ------------------------------------------------------------------ */
/* Trabajo de una iteración (idéntico en la versión secuencial y la paralela) */

/* Carga uniforme: 32 rondas de un generador xorshift de 32 bits. */
static inline double uniform_item(long i)
{
    unsigned x = (unsigned)i * 2654435761u + 1u;
    for (int r = 0; r < 32; r++) {
        x ^= x << 13;
        x ^= x >> 17;
        x ^= x << 5;
    }
    return (double)(x & 0xFFu);
}

/* Carga triangular: la iteración i hace i divisiones. */
static inline double triangular_item(long i)
{
    double s = 0.0;
    for (long j = 0; j < i; j++)
        s += 1.0 / (1.0 + (double)i * (double)j);
    return s;
}

/* Carga irregular: pasos para llegar a 1 desde i (conjetura de Collatz). */
static inline double collatz_item(long i)
{
    unsigned long long x = (unsigned long long)i;
    long steps = 0;
    while (x != 1ULL) {
        x = (x & 1ULL) ? 3ULL * x + 1ULL : x >> 1;
        steps++;
    }
    return (double)steps;
}

/* Carga concentrada: puntos de la fila 'row' que pertenecen al conjunto. */
static inline double mandelbrot_row(long row, long n)
{
    const double x_min = -2.0, x_max = 1.0, y_min = -1.5, y_max = 1.5;
    double dx = (x_max - x_min) / (double)n;
    double dy = (y_max - y_min) / (double)n;
    double cy = y_min + ((double)row + 0.5) * dy;
    long inside = 0;
    for (long col = 0; col < n; col++) {
        double cx = x_min + ((double)col + 0.5) * dx;
        double zx = 0.0, zy = 0.0;
        int iter = 0;
        while (zx * zx + zy * zy <= 4.0 && iter < MANDEL_MAX_ITER) {
            double tmp = zx * zx - zy * zy + cx;
            zy = 2.0 * zx * zy + cy;
            zx = tmp;
            iter++;
        }
        if (iter == MANDEL_MAX_ITER) inside++;
    }
    return (double)inside;
}

/* Despacho por núcleo. */
static inline double item(enum kernel_id k, long i, long n)
{
    switch (k) {
    case K_UNIFORM:    return uniform_item(i);
    case K_TRIANGULAR: return triangular_item(i);
    case K_COLLATZ:    return collatz_item(i + 1);     /* Collatz empieza en 1 */
    case K_MANDELBROT: return mandelbrot_row(i, n);
    }
    return 0.0;
}

/* ------------------------------------------------------------------ */
/* Versión secuencial (referencia) y versión paralela con schedule(runtime) */

static double run_seq(enum kernel_id k, long n)
{
    double acc = 0.0;
    for (long i = 0; i < n; i++)
        acc += item(k, i, n);
    return acc;
}

static double run_par(enum kernel_id k, long n)
{
    double acc = 0.0;
    #pragma omp parallel for schedule(runtime) reduction(+ : acc)
    for (long i = 0; i < n; i++)
        acc += item(k, i, n);
    return acc;
}

/* ------------------------------------------------------------------ */
/* Medición: calentamiento + REPS repeticiones; mediana, mínimo y máximo */

static int cmp_double(const void *a, const void *b)
{
    double x = *(const double *)a, y = *(const double *)b;
    return (x > y) - (x < y);
}

/* El puntero a función es 'volatile' a propósito: run_seq no tiene efectos
 * secundarios y GCC, al detectarlo, reutilizaría el resultado de la primera
 * llamada en lugar de repetirla (y mediría 0 s). Con volatile cada llamada
 * se hace de verdad. Es un error de medición clásico: anótalo. */
static double timed(double (*volatile fn)(enum kernel_id, long), enum kernel_id k, long n,
                    int reps, double *t_min, double *t_max, double *result)
{
    double times[MAX_REPS];
    *result = fn(k, n);                         /* calentamiento, no cuenta */
    for (int r = 0; r < reps; r++) {
        double t0 = omp_get_wtime();
        *result = fn(k, n);
        times[r] = omp_get_wtime() - t0;
    }
    qsort(times, (size_t)reps, sizeof times[0], cmp_double);
    *t_min = times[0];
    *t_max = times[reps - 1];
    return times[reps / 2];
}

/* ------------------------------------------------------------------ */
/* Políticas */

struct policy {
    char        name[32];
    omp_sched_t kind;
    int         chunk;
    int         is_runtime;   /* 1: no tocar run-sched-var, usar OMP_SCHEDULE */
};

static int parse_policy(const char *text, struct policy *p)
{
    char buf[32];
    snprintf(buf, sizeof buf, "%s", text);
    snprintf(p->name, sizeof p->name, "%s", text);
    p->chunk = 0;
    p->is_runtime = 0;

    char *comma = strchr(buf, ',');
    if (comma) {
        *comma = '\0';
        p->chunk = atoi(comma + 1);
        if (p->chunk <= 0) return 0;
    }
    if      (strcmp(buf, "static")  == 0) p->kind = omp_sched_static;
    else if (strcmp(buf, "dynamic") == 0) p->kind = omp_sched_dynamic;
    else if (strcmp(buf, "guided")  == 0) p->kind = omp_sched_guided;
    else if (strcmp(buf, "auto")    == 0) p->kind = omp_sched_auto;
    else if (strcmp(buf, "runtime") == 0 && !comma) { p->is_runtime = 1; p->kind = omp_sched_static; }
    else return 0;
    return 1;
}

static void describe_current(char *buf, size_t len)
{
    omp_sched_t kind;
    int chunk;
    omp_get_schedule(&kind, &chunk);
    int base = (int)kind & 0xFF;
    const char *name = base == omp_sched_static  ? "static"
                     : base == omp_sched_dynamic ? "dynamic"
                     : base == omp_sched_guided  ? "guided"
                     : base == omp_sched_auto    ? "auto" : "?";
    snprintf(buf, len, "runtime(%s,%d)", name, chunk);
}

/* ------------------------------------------------------------------ */

static void usage(const char *prog)
{
    fprintf(stderr,
            "Uso: %s <uniform|triangular|collatz|mandelbrot> [n] [politica ...]\n"
            "  politica: static | static,C | dynamic | dynamic,C | guided | guided,C | auto | runtime\n",
            prog);
}

int main(int argc, char **argv)
{
    if (argc < 2) { usage(argv[0]); return 2; }

    enum kernel_id k;
    long n;
    if      (strcmp(argv[1], "uniform")    == 0) { k = K_UNIFORM;    n = 4000000; }
    else if (strcmp(argv[1], "triangular") == 0) { k = K_TRIANGULAR; n = 20000;   }
    else if (strcmp(argv[1], "collatz")    == 0) { k = K_COLLATZ;    n = 1000000; }
    else if (strcmp(argv[1], "mandelbrot") == 0) { k = K_MANDELBROT; n = 800;     }
    else { usage(argv[0]); return 2; }

    if (argc > 2) {
        n = atol(argv[2]);
        if (n < 1) { fprintf(stderr, "n debe ser >= 1\n"); return 2; }
    }

    int reps = 5;
    const char *reps_env = getenv("REPS");
    if (reps_env) reps = atoi(reps_env);
    if (reps < 1) reps = 1;
    if (reps > MAX_REPS) reps = MAX_REPS;

    /* Lista de políticas a medir */
    static const char *default_policies[] = { "static", "static,1", "dynamic,16", "guided,16" };
    int n_pol = 0;
    struct policy pol[32];
    if (argc > 3) {
        for (int a = 3; a < argc && n_pol < 32; a++) {
            if (!parse_policy(argv[a], &pol[n_pol])) {
                fprintf(stderr, "Política inválida: %s\n", argv[a]);
                return 2;
            }
            n_pol++;
        }
    } else {
        for (int a = 0; a < 4; a++) parse_policy(default_policies[a], &pol[n_pol++]);
    }

    int n_threads = omp_get_max_threads();
    printf("# kernel=%s n=%ld hilos=%d reps=%d (mediana de %d, tras 1 calentamiento)\n",
           argv[1], n, n_threads, reps, reps);

    /* Referencia secuencial */
    double seq_min, seq_max, seq_val;
    double seq_med = timed(run_seq, k, n, reps, &seq_min, &seq_max, &seq_val);
    printf("# secuencial: mediana=%.4f s  min=%.4f  max=%.4f  resultado=%.10g\n",
           seq_med, seq_min, seq_max, seq_val);

    printf("| %-20s | %9s | %8s | %8s | %7s | %-6s |\n",
           "política", "mediana_s", "min_s", "max_s", "speedup", "verif");
    printf("|%s|%s|%s|%s|%s|%s|\n", "----------------------", "-----------", "----------",
           "----------", "---------", "--------");

    int failures = 0;
    for (int p = 0; p < n_pol; p++) {
        char runtime_label[48];
        const char *label = pol[p].name;
        if (pol[p].is_runtime) {
            describe_current(runtime_label, sizeof runtime_label); /* lo que diga OMP_SCHEDULE */
            label = runtime_label;
        } else {
            omp_set_schedule(pol[p].kind, pol[p].chunk); /* chunk 0 = valor por omisión */
        }
        double p_min, p_max, p_val;
        double p_med = timed(run_par, k, n, reps, &p_min, &p_max, &p_val);

        /* Verificación contra la secuencial con tolerancia relativa
         * (la reducción en punto flotante cambia el orden de las sumas). */
        double scale = fabs(seq_val) > 1.0 ? fabs(seq_val) : 1.0;
        int ok = fabs(p_val - seq_val) <= 1e-9 * scale;
        if (!ok) failures++;

        printf("| %-20s | %9.4f | %8.4f | %8.4f | %7.2f | %-6s |\n",
               label, p_med, p_min, p_max, seq_med / p_med, ok ? "OK" : "FAIL");
    }
    return failures ? 1 : 0;
}
