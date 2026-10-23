/* item_IV_tasks_sum.c — Examen de práctica U3, sección IV (completar código): suma recursiva de un
 * arreglo con tareas y corte. Este archivo tiene los CUATRO huecos llenos (es la clave); en el examen
 * aparecen como ______.
 *   gcc -std=c11 -O2 -Wall -Wextra -fopenmp -I.. item_IV_tasks_sum.c -o item_IV_tasks_sum -lm
 *   OMP_NUM_THREADS=4 ./item_IV_tasks_sum [n]
 */
#include "common.h"

static long task_count = 0;

static long sum_seq(const long *v, long lo, long hi)
{
    long s = 0;
    for (long i = lo; i < hi; i++) s += v[i];
    return s;
}

static long sum_tasks(const long *v, long lo, long hi, long cutoff)
{
    if (hi - lo <= cutoff)                      /* corte: por debajo, secuencial (sin crear tareas) */
        return sum_seq(v, lo, hi);
    long mid = lo + (hi - lo) / 2;
    long left, right;
    #pragma omp task shared(left)               /* HUECO 1: la hija escribe left y el padre la lee */
    {
        #pragma omp atomic
        task_count++;
        left = sum_tasks(v, lo, mid, cutoff);
    }
    #pragma omp task shared(right)              /* HUECO 2 */
    {
        #pragma omp atomic
        task_count++;
        right = sum_tasks(v, mid, hi, cutoff);
    }
    #pragma omp taskwait                        /* HUECO 3: espera a las dos hijas antes de combinar */
    return left + right;
}

int main(int argc, char **argv)
{
    long n = parse_n(argc, argv, 1L << 20);
    long cutoff = (argc > 2) ? atol(argv[2]) : 4096;
    long *v = malloc((size_t)n * sizeof(long));
    if (!v) { fprintf(stderr, "sin memoria\n"); return 1; }
    for (long i = 0; i < n; i++) v[i] = i % 100 + 1;
    long ref = sum_seq(v, 0, n);

    long total = 0;
    task_count = 0;
    #pragma omp parallel                        /* HUECO 4a: crea el equipo */
    #pragma omp single                          /* HUECO 4b: un solo hilo genera las tareas raíz */
    total = sum_tasks(v, 0, n, cutoff);

    printf("item_IV: n=%ld cutoff=%ld hilos=%d  total=%ld (secuencial %ld)  tareas=%ld\n",
           n, cutoff, omp_get_max_threads(), total, ref, task_count);
    print_result("item_IV_tasks", n, total == ref ? 0 : 1, 1);
    free(v);
    return total == ref ? 0 : 1;
}
