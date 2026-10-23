/* taskloop_demo.c — taskloop frente a parallel for: mapa de iteraciones (n pequeño) y tiempo (n grande).
 * Práctica guiada S09 · Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1
 *
 * `taskloop` parte un ciclo en tareas (bloques de iteraciones) que los hilos toman de la cola, como
 * schedule(dynamic) pero dentro del mundo de las tareas: sirve cuando el ciclo vive dentro de una tarea o
 * de un single y no se quiere abrir otra región paralela.
 *
 * Uso: ./taskloop_demo [n] [grainsize]   (por defecto n=16, grainsize=4)
 *   n <= 64 : imprime el mapa owner[i] (qué hilo ejecutó cada iteración) con taskloop y con parallel for.
 *             Cada iteración hace ~0.1 ms de trabajo; si no hiciera nada, el hilo que genera las tareas
 *             las terminaría todas antes de que los demás alcanzaran a tomar una (el mapa saldría de un
 *             solo hilo y no enseñaría nada). El mapa cambia entre corridas: el reparto es dinámico.
 *   n  > 64 : mide el ciclo triangular de S08 con parallel for schedule(dynamic,g) y con taskloop grainsize(g)
 */
#include <math.h>
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>

/* La iteración i cuesta i divisiones (ciclo triangular de S08). */
static double triangular_item(long i)
{
    double s = 0.0;
    for (long j = 0; j < i; j++)
        s += 1.0 / (1.0 + (double)i * (double)j);
    return s;
}

/* Trabajo pequeño pero no nulo para el modo mapa (~0.1 ms); el resultado se descarta vía volatile. */
static void small_work(void)
{
    volatile double sink = 0.0;
    for (int k = 0; k < 20000; k++)
        sink += 1.0 / (1.0 + k);
}

static void print_map(const char *label, const int *owner, long n)
{
    printf("%-26s|", label);
    for (long i = 0; i < n; i++)
        printf(" %d", owner[i]);
    printf("\n");
}

int main(int argc, char **argv)
{
    long n = (argc > 1) ? atol(argv[1]) : 16;
    long g = (argc > 2) ? atol(argv[2]) : 4;
    if (n < 1) n = 1;
    if (g < 1) g = 1;
    int threads = omp_get_max_threads();

    if (n <= 64) {
        int owner[64];
        char label[64];
        printf("n=%ld hilos=%d\n", n, threads);

        /* taskloop: UN hilo (single) genera las tareas; cada tarea cubre ~grainsize iteraciones. */
        #pragma omp parallel
        #pragma omp single
        #pragma omp taskloop grainsize(g)
        for (long i = 0; i < n; i++) {
            small_work();
            owner[i] = omp_get_thread_num();
        }
        snprintf(label, sizeof label, "taskloop grainsize(%ld)", g);
        print_map(label, owner, n);

        /* Comparación: la planificación dinámica de S08 con el mismo tamaño de bloque. */
        #pragma omp parallel for schedule(dynamic, g)
        for (long i = 0; i < n; i++) {
            small_work();
            owner[i] = omp_get_thread_num();
        }
        snprintf(label, sizeof label, "for schedule(dynamic,%ld)", g);
        print_map(label, owner, n);
        return 0;
    }

    /* --- Medición (una corrida de cada una; para el protocolo completo, repite y toma la mediana) --- */
    double t0 = omp_get_wtime();
    double ref = 0.0;
    for (long i = 0; i < n; i++)
        ref += triangular_item(i);
    double t_seq = omp_get_wtime() - t0;

    t0 = omp_get_wtime();
    double acc_for = 0.0;
    #pragma omp parallel for schedule(dynamic, g) reduction(+ : acc_for)
    for (long i = 0; i < n; i++)
        acc_for += triangular_item(i);
    double t_for = omp_get_wtime() - t0;

    t0 = omp_get_wtime();
    double acc_tl = 0.0;
    #pragma omp parallel
    #pragma omp single
    #pragma omp taskloop grainsize(g) reduction(+ : acc_tl)
    for (long i = 0; i < n; i++)
        acc_tl += triangular_item(i);
    double t_tl = omp_get_wtime() - t0;

    /* Tolerancia relativa: el orden de las sumas cambia el redondeo (idea errónea 10). */
    int ok = fabs(acc_for - ref) <= 1e-9 * fabs(ref) && fabs(acc_tl - ref) <= 1e-9 * fabs(ref);
    printf("n=%ld hilos=%d bloque=%ld\n", n, threads, g);
    printf("secuencial                : %.4f s\n", t_seq);
    printf("for schedule(dynamic,%ld)   : %.4f s  speedup %.2f\n", g, t_for, t_for > 0 ? t_seq / t_for : 0.0);
    printf("taskloop grainsize(%ld)     : %.4f s  speedup %.2f\n", g, t_tl, t_tl > 0 ? t_seq / t_tl : 0.0);
    printf("verificacion: %s\n", ok ? "OK" : "FALLA");
    return ok ? 0 : 1;
}
