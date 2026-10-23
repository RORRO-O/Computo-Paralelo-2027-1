/* mergesort_tasks.c — Ordenamiento por mezcla (mergesort) con tareas de OpenMP y corte (cutoff).
 * Práctica guiada S09 · Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1
 *
 * Uso:  ./mergesort_tasks [n] [cutoff]
 *   n       elementos a ordenar (por defecto 2000000)
 *   cutoff  tamaño de subarreglo por debajo del cual NO se crean tareas (por defecto 4096)
 * Entorno: OMP_NUM_THREADS (hilos); REPS (repeticiones cronometradas, por defecto 5; siempre 1 calentamiento).
 * Con n <= 32: una sola corrida, sin calentamiento, y se imprime la traza de cada tarea.
 *
 * Idea: cada llamada con más de `cutoff` elementos crea DOS tareas (una por mitad), espera a las dos con
 * taskwait y después mezcla. Por debajo del corte se ordena de forma secuencial, sin crear tareas.
 */
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_THREADS 64
#define MAX_REPS    32
#define TRACE_MAX   32   /* con n <= TRACE_MAX se imprime cada tarea */
#define SMALL_SORT  32   /* por debajo de este tamaño, inserción (más rápida que mezclar) */

static long task_count;                    /* tareas ejecutadas; se incrementa con atomic */
static long tasks_by_thread[MAX_THREADS];  /* cuántas ejecutó cada hilo */
static int  trace;                         /* 1 si n <= TRACE_MAX */

/* Se llama al INICIO del cuerpo de cada tarea: la ejecuta el hilo que TOMÓ la tarea, no el que la creó. */
static void task_begin(long lo, long hi)
{
    int tid = omp_get_thread_num();
    #pragma omp atomic
    task_count++;
    #pragma omp atomic
    tasks_by_thread[tid]++;
    if (trace)
        printf("  tarea [%2ld,%2ld)  n=%2ld  ejecutada por el hilo %d\n", lo, hi, hi - lo, tid);
}

static void insertion_sort(int *a, long lo, long hi)
{
    for (long i = lo + 1; i < hi; i++) {
        int v = a[i];
        long j = i - 1;
        while (j >= lo && a[j] > v) {
            a[j + 1] = a[j];
            j--;
        }
        a[j + 1] = v;
    }
}

/* Mezcla a[lo,mid) y a[mid,hi), ambos ya ordenados, usando tmp[lo,hi) como auxiliar. */
static void merge(int *a, int *tmp, long lo, long mid, long hi)
{
    long i = lo, j = mid, k = lo;
    while (i < mid && j < hi)
        tmp[k++] = (a[i] <= a[j]) ? a[i++] : a[j++];
    while (i < mid)
        tmp[k++] = a[i++];
    while (j < hi)
        tmp[k++] = a[j++];
    memcpy(a + lo, tmp + lo, (size_t)(hi - lo) * sizeof(int));
}

/* Versión secuencial: la referencia T(1) del speedup (protocolo de medición, §3). */
static void merge_sort_seq(int *a, int *tmp, long lo, long hi)
{
    if (hi - lo <= SMALL_SORT) {
        insertion_sort(a, lo, hi);
        return;
    }
    long mid = lo + (hi - lo) / 2;
    merge_sort_seq(a, tmp, lo, mid);
    merge_sort_seq(a, tmp, mid, hi);
    merge(a, tmp, lo, mid, hi);
}

/* Versión con tareas. Se llama desde dentro de una región parallel, por UN solo hilo (single). */
static void merge_sort_tasks(int *a, int *tmp, long lo, long hi, long cutoff)
{
    long n = hi - lo;
    if (n <= cutoff || n < 2) {        /* corte: por debajo de cutoff, secuencial y sin tareas */
        merge_sort_seq(a, tmp, lo, hi);
        return;
    }
    long mid = lo + n / 2;

    /* Sin cláusulas: a, tmp, lo, mid y cutoff son firstprivate implícitas. La tarea recibe una COPIA de
     * los punteros y de los índices con el valor que tienen ahora. El arreglo al que apuntan sigue siendo
     * uno solo, compartido; cada tarea escribe en un tramo distinto, así que no hay carrera. */
    #pragma omp task
    {
        task_begin(lo, mid);
        merge_sort_tasks(a, tmp, lo, mid, cutoff);
    }
    #pragma omp task
    {
        task_begin(mid, hi);
        merge_sort_tasks(a, tmp, mid, hi, cutoff);
    }
    #pragma omp taskwait               /* espera a las DOS hijas directas; sin esto se mezclaría basura */
    merge(a, tmp, lo, mid, hi);
}

static int is_sorted(const int *a, long n)
{
    for (long i = 1; i < n; i++)
        if (a[i - 1] > a[i])
            return 0;
    return 1;
}

/* Generador propio (congruencial lineal) para que la entrada sea idéntica en toda máquina. */
static void fill_random(int *a, long n, unsigned seed)
{
    unsigned s = seed;
    for (long i = 0; i < n; i++) {
        s = s * 1664525u + 1013904223u;
        a[i] = (int)((s >> 8) % 1000000u);
    }
}

static int cmp_double(const void *x, const void *y)
{
    double a = *(const double *)x, b = *(const double *)y;
    return (a > b) - (a < b);
}

static void print_array(const char *label, const int *a, long n)
{
    printf("%s", label);
    for (long i = 0; i < n; i++)
        printf(" %d", a[i]);
    printf("\n");
}

static int read_reps(void)
{
    const char *s = getenv("REPS");
    int r = s ? atoi(s) : 5;
    if (r < 1) r = 1;
    if (r > MAX_REPS) r = MAX_REPS;
    return r;
}

int main(int argc, char **argv)
{
    long n = (argc > 1) ? atol(argv[1]) : 2000000L;
    long cutoff = (argc > 2) ? atol(argv[2]) : 4096L;
    if (n < 1) n = 1;
    if (cutoff < 1) cutoff = 1;
    int reps = read_reps();
    int threads = omp_get_max_threads();
    if (threads > MAX_THREADS) {
        fprintf(stderr, "demasiados hilos (%d > %d)\n", threads, MAX_THREADS);
        return 2;
    }
    trace = (n <= TRACE_MAX);
    if (trace)
        reps = 1;                      /* una corrida, sin calentamiento: la traza se imprime una sola vez */

    int *orig = malloc((size_t)n * sizeof(int));
    int *a    = malloc((size_t)n * sizeof(int));
    int *tmp  = malloc((size_t)n * sizeof(int));
    int *ref  = malloc((size_t)n * sizeof(int));
    if (!orig || !a || !tmp || !ref) {
        fprintf(stderr, "sin memoria para n=%ld\n", n);
        return 2;
    }
    fill_random(orig, n, 12345u);
    if (trace)
        print_array("entrada:", orig, n);

    /* --- Secuencial: 1 calentamiento (si no hay traza) + reps repeticiones, mediana --- */
    double t_seq[MAX_REPS];
    for (int r = trace ? 0 : -1; r < reps; r++) {
        memcpy(a, orig, (size_t)n * sizeof(int));
        double t0 = omp_get_wtime();
        merge_sort_seq(a, tmp, 0, n);
        double t = omp_get_wtime() - t0;
        if (r >= 0)
            t_seq[r] = t;
    }
    memcpy(ref, a, (size_t)n * sizeof(int));   /* salida de referencia */

    /* --- Tareas: el mismo protocolo. Un hilo (single) arranca la recursión; los demás toman tareas. --- */
    double t_par[MAX_REPS];
    for (int r = trace ? 0 : -1; r < reps; r++) {
        memcpy(a, orig, (size_t)n * sizeof(int));
        task_count = 0;
        memset(tasks_by_thread, 0, sizeof tasks_by_thread);
        double t0 = omp_get_wtime();
        #pragma omp parallel
        #pragma omp single
        merge_sort_tasks(a, tmp, 0, n, cutoff);
        /* barrera implícita del single y de parallel: aquí ya terminaron TODAS las tareas */
        double t = omp_get_wtime() - t0;
        if (r >= 0)
            t_par[r] = t;
    }
    int ok = is_sorted(a, n) && memcmp(a, ref, (size_t)n * sizeof(int)) == 0;
    if (trace)
        print_array("salida: ", a, n);

    qsort(t_seq, (size_t)reps, sizeof t_seq[0], cmp_double);
    qsort(t_par, (size_t)reps, sizeof t_par[0], cmp_double);
    double m_seq = t_seq[reps / 2], m_par = t_par[reps / 2];
    double speedup = m_par > 0.0 ? m_seq / m_par : 0.0;

    printf("n=%ld cutoff=%ld hilos=%d reps=%d (mediana%s)\n", n, cutoff, threads, reps,
           trace ? "" : " tras 1 calentamiento");
    printf("secuencial : mediana %.4f s  (min %.4f  max %.4f)\n", m_seq, t_seq[0], t_seq[reps - 1]);
    printf("tareas     : mediana %.4f s  (min %.4f  max %.4f)  speedup %.2f  eficiencia %.2f\n",
           m_par, t_par[0], t_par[reps - 1], speedup, speedup / threads);
    printf("tareas creadas = %ld   ejecutadas por hilo:", task_count);
    for (int t = 0; t < threads; t++)
        printf(" %ld", tasks_by_thread[t]);
    printf("\n");
    printf("verificacion: %s\n", ok ? "OK" : "FALLA");
    /* Línea compacta para tablas (make cutoffs): */
    printf("resumen: n=%ld cutoff=%ld hilos=%d t_seq=%.4f t_tareas=%.4f speedup=%.2f tareas=%ld\n",
           n, cutoff, threads, m_seq, m_par, speedup, task_count);

    free(orig);
    free(a);
    free(tmp);
    free(ref);
    return ok ? 0 : 1;
}
