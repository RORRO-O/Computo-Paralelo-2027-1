/*
 * schedule_map.c — Mapa de asignación de iteraciones por política de planificación.
 *
 * Cada iteración i registra en owner[i] el número del hilo que la ejecutó y
 * después "trabaja" (espera activa) un tiempo proporcional a su costo. Con n
 * pequeño (16) el mapa se lee de un vistazo y permite comparar las políticas
 * static, static,chunk, dynamic,chunk, guided,chunk y runtime (OMP_SCHEDULE).
 *
 * Uso:  ./schedule_map [n] [politica] [chunk] [forma]
 *   n        iteraciones (1..256; por defecto 16)
 *   politica static | dynamic | guided | runtime | all   (por defecto all)
 *   chunk    tamaño de chunk; 0 = no especificar          (por defecto 0)
 *   forma    uniform | triangular: costo de la iteración i (por defecto triangular)
 *            uniform    -> todas cuestan 1 unidad
 *            triangular -> la iteración i cuesta i+1 unidades (como un ciclo j<i)
 *
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra -fopenmp schedule_map.c -o schedule_map
 * Ejemplo:  OMP_NUM_THREADS=4 ./schedule_map 16 all
 *           OMP_NUM_THREADS=4 OMP_SCHEDULE="guided,2" ./schedule_map 16 runtime
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>

#define MAX_N       256
#define MAX_THREADS 64
#define UNIT_US     150.0   /* microsegundos que cuesta una unidad de trabajo */

/* Espera activa de 'us' microsegundos: simula el trabajo de una iteración. */
static void spin_us(double us)
{
    double t_end = omp_get_wtime() + us * 1e-6;
    while (omp_get_wtime() < t_end) {
        /* ocupado a propósito */
    }
}

/* Costo en unidades de la iteración i según la forma de la carga. */
static int cost_units(int i, int triangular)
{
    return triangular ? i + 1 : 1;
}

/* Cuerpo de la iteración: anota quién la ejecuta y consume su costo. */
static void body(int i, int *owner, int triangular)
{
    owner[i] = omp_get_thread_num();
    spin_us(UNIT_US * cost_units(i, triangular));
}

/* --- Un ciclo por política. La cláusula schedule debe escribirse literal,
 *     por eso hay dos versiones (con y sin chunk) de cada una. ---------- */

static void run_static(int n, int chunk, int *owner, int tri)
{
    if (chunk > 0) {
        #pragma omp parallel for schedule(static, chunk)
        for (int i = 0; i < n; i++) body(i, owner, tri);
    } else {
        #pragma omp parallel for schedule(static)
        for (int i = 0; i < n; i++) body(i, owner, tri);
    }
}

static void run_dynamic(int n, int chunk, int *owner, int tri)
{
    if (chunk > 0) {
        #pragma omp parallel for schedule(dynamic, chunk)
        for (int i = 0; i < n; i++) body(i, owner, tri);
    } else {
        #pragma omp parallel for schedule(dynamic)   /* chunk = 1 por omisión */
        for (int i = 0; i < n; i++) body(i, owner, tri);
    }
}

static void run_guided(int n, int chunk, int *owner, int tri)
{
    if (chunk > 0) {
        #pragma omp parallel for schedule(guided, chunk)
        for (int i = 0; i < n; i++) body(i, owner, tri);
    } else {
        #pragma omp parallel for schedule(guided)    /* chunk mínimo = 1 */
        for (int i = 0; i < n; i++) body(i, owner, tri);
    }
}

static void run_runtime(int n, int *owner, int tri)
{
    /* La política la decide la variable de entorno OMP_SCHEDULE
     * (o una llamada previa a omp_set_schedule). */
    #pragma omp parallel for schedule(runtime)
    for (int i = 0; i < n; i++) body(i, owner, tri);
}

/* Nombre legible de la política que hay en run-sched-var (para 'runtime'). */
static void describe_runtime(char *buf, size_t len)
{
    omp_sched_t kind;
    int chunk;
    omp_get_schedule(&kind, &chunk);
    /* Se ignora el modificador monotonic/nonmonotonic (OpenMP 4.5+). */
    int base = (int)kind & 0xFF;
    const char *name = base == omp_sched_static  ? "static"
                     : base == omp_sched_dynamic ? "dynamic"
                     : base == omp_sched_guided  ? "guided"
                     : base == omp_sched_auto    ? "auto" : "?";
    snprintf(buf, len, "runtime=%s,%d", name, chunk);
}

/* Imprime el mapa owner[] y los totales por hilo. */
static void print_map(const char *label, const int *owner, int n, int tri)
{
    int n_threads = omp_get_max_threads();
    if (n_threads > MAX_THREADS) n_threads = MAX_THREADS;
    int count[MAX_THREADS] = {0};
    int work[MAX_THREADS]  = {0};

    for (int i = 0; i < n; i++) {
        int t = owner[i];
        if (t >= 0 && t < n_threads) {
            count[t] += 1;
            work[t]  += cost_units(i, tri);
        }
    }
    printf("%-18s|", label);
    for (int i = 0; i < n; i++) printf(" %d", owner[i]);
    printf(" | iters:");
    for (int t = 0; t < n_threads; t++) printf(" %2d", count[t]);
    printf(" | trabajo:");
    for (int t = 0; t < n_threads; t++) printf(" %3d", work[t]);
    printf("\n");
}

static void run_one(const char *policy, int n, int chunk, int *owner, int tri)
{
    char label[64];
    for (int i = 0; i < n; i++) owner[i] = -1;

    if (strcmp(policy, "static") == 0) {
        run_static(n, chunk, owner, tri);
        if (chunk > 0) snprintf(label, sizeof label, "static,%d", chunk);
        else           snprintf(label, sizeof label, "static");
    } else if (strcmp(policy, "dynamic") == 0) {
        run_dynamic(n, chunk, owner, tri);
        if (chunk > 0) snprintf(label, sizeof label, "dynamic,%d", chunk);
        else           snprintf(label, sizeof label, "dynamic");
    } else if (strcmp(policy, "guided") == 0) {
        run_guided(n, chunk, owner, tri);
        if (chunk > 0) snprintf(label, sizeof label, "guided,%d", chunk);
        else           snprintf(label, sizeof label, "guided");
    } else if (strcmp(policy, "runtime") == 0) {
        run_runtime(n, owner, tri);
        describe_runtime(label, sizeof label);
    } else {
        fprintf(stderr, "Política desconocida: %s\n", policy);
        exit(2);
    }
    print_map(label, owner, n, tri);
}

int main(int argc, char **argv)
{
    int n = (argc > 1) ? atoi(argv[1]) : 16;
    const char *policy = (argc > 2) ? argv[2] : "all";
    int chunk = (argc > 3) ? atoi(argv[3]) : 0;
    int tri = 1;
    if (argc > 4) {
        if (strcmp(argv[4], "uniform") == 0)         tri = 0;
        else if (strcmp(argv[4], "triangular") == 0) tri = 1;
        else { fprintf(stderr, "Forma desconocida: %s\n", argv[4]); return 2; }
    }
    if (n < 1 || n > MAX_N) { fprintf(stderr, "n debe estar en 1..%d\n", MAX_N); return 2; }
    if (chunk < 0) { fprintf(stderr, "chunk debe ser >= 0\n"); return 2; }

    int owner[MAX_N];

    printf("n=%d hilos=%d forma=%s (costo de la iteración i: %s)\n",
           n, omp_get_max_threads(), tri ? "triangular" : "uniform",
           tri ? "i+1 unidades" : "1 unidad");
    printf("%-18s|", "i =");
    for (int i = 0; i < n; i++) printf(" %d", i % 10);   /* último dígito de i */
    printf("\n");

    if (strcmp(policy, "all") == 0) {
        int c = (chunk > 0) ? chunk : 2;
        run_one("static",  n, 0, owner, tri);
        run_one("static",  n, c, owner, tri);
        run_one("dynamic", n, 0, owner, tri);
        run_one("dynamic", n, c, owner, tri);
        run_one("guided",  n, 0, owner, tri);
        run_one("runtime", n, 0, owner, tri);
    } else {
        run_one(policy, n, chunk, owner, tri);
    }
    return 0;
}
