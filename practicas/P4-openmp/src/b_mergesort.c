/* b_mergesort.c — Parte B: ordenamiento ESTABLE de registros por mezcla (mergesort) con tareas y corte.
 * Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · Práctica 4 · CÓDIGO BASE (completa TODO(1), TODO(2) y TODO(3))
 *
 * Uso:  ./b_mergesort [n] [cutoff] [modo]
 *   n       registros a ordenar (por defecto 2 000 000)
 *   cutoff  tamaño de tramo por debajo del cual NO se crean tareas (por defecto 4 096)
 *   modo    ambos (por defecto: qsort + secuencial + tareas, con speedup) | seq | omp
 * Entorno: OMP_NUM_THREADS (hilos); REPS (repeticiones cronometradas, 5; siempre 1 calentamiento).
 *
 * Qué cambia respecto a mergesort_tasks.c de S09: se ordenan REGISTROS (clave float + identificador), hay
 * muchas claves repetidas (4 096 valores distintos) y el orden debe ser ESTABLE: entre registros con la
 * misma clave se conserva el orden original. La verificación compara, registro por registro, contra
 * qsort(3) con el criterio (clave, id); como id es la posición original, un mergesort estable produce
 * exactamente ese orden. Además, T(1) es el MEJOR secuencial disponible: el menor entre qsort y
 * merge_sort_seq (protocolo de medición, §3).
 *
 * Esqueleto (el mismo de S09 y de la versión con tareas del histograma de la Parte A): cada llamada con
 * más de `cutoff` registros crea DOS tareas, una por mitad, espera a las dos con taskwait y después mezcla.
 * Las líneas de tareas (parallel + single, task, taskwait) vienen COMPLETAS: las leíste en S09 y en la
 * Parte A. Lo que completas es la mezcla estable, el corte y el arnés de medición. Mientras quede un TODO
 * sin resolver, el programa imprime "TODO pendiente" y las pruebas de la Parte B fallan.
 */
#include "common.h"

#define SMALL_SORT 32         /* por debajo de este tamaño, inserción (más rápida que mezclar) */
#define KEY_VALUES 4096u      /* claves distintas: con n grande hay muchos empates */
#define B_SEED     20261020u

typedef struct {
    float key;                /* lo que se ordena */
    int id;                   /* posición original: sirve para verificar la estabilidad */
} record;

static long task_count;       /* tareas creadas; se incrementa con atomic */

static int cmp_key_id(const void *x, const void *y)
{
    const record *a = x, *b = y;
    if (a->key != b->key) return (a->key > b->key) - (a->key < b->key);
    return (a->id > b->id) - (a->id < b->id);
}

/* Inserción estable: solo se desplaza un registro si su clave es ESTRICTAMENTE mayor. */
static void insertion_sort(record *a, long lo, long hi)
{
    for (long i = lo + 1; i < hi; i++) {
        record v = a[i];
        long j = i - 1;
        while (j >= lo && a[j].key > v.key) {
            a[j + 1] = a[j];
            j--;
        }
        a[j + 1] = v;
    }
}

/* Mezcla ESTABLE de a[lo,mid) y a[mid,hi), ambos ya ordenados por clave, usando tmp[lo,hi) como auxiliar.
 * Al terminar, a[lo,hi) queda ordenado por clave y, entre claves iguales, en el orden en que estaban. */
static void merge(record *a, record *tmp, long lo, long mid, long hi)
{
    /* TODO(1): la mezcla. Plan (pseudocódigo):
     *     i = lo; j = mid; k = lo
     *     mientras i < mid y j < hi:
     *         si a[i].key <= a[j].key: tmp[k++] = a[i++]     <- ante un EMPATE gana el de la izquierda
     *         si no:                   tmp[k++] = a[j++]
     *     copia lo que quede de a[i..mid) y luego de a[j..hi) a tmp[k..]
     *     copia tmp[lo,hi) de regreso a a[lo,hi) (memcpy)
     * Criterio de "listo": `./b_mergesort 100000 1024 seq` imprime "verificacion: OK" (no "NO estable").
     * Después cambia el <= por < y corre con n = 20 y con n = 200: ¿en cuál lo detecta la verificación?
     * Borra la línea p4_todo(1) y la línea (void) cuando termines. */
    p4_todo(1);
    (void)a; (void)tmp; (void)lo; (void)mid; (void)hi;
}

/* Versión secuencial: candidata a T(1) y la misma que corre por debajo del corte. */
static void merge_sort_seq(record *a, record *tmp, long lo, long hi)
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

/* Versión con tareas. Se llama dentro de una región parallel, por UN solo hilo (single). Las líneas de
 * task y taskwait son las de S09 y vienen completas en el código base. */
static void merge_sort_tasks(record *a, record *tmp, long lo, long hi, long cutoff)
{
    long n = hi - lo;
    /* TODO(2): el corte (cutoff). Si el tramo tiene a lo más `cutoff` registros (o menos de 2), ordénalo con
     * la versión secuencial y regresa SIN crear tareas. Pista: es la misma condición que viste en la hoja de
     * hist_tasks_rec (Parte A) y en mergesort_tasks.c de S09; aquí la llamada secuencial es merge_sort_seq.
     * Criterio: `./b_mergesort 8 2 omp` reporta 6 tareas creadas; `./b_mergesort 1000 1000 omp`, 0 tareas.
     * Mientras falte, no hay corte: se parte hasta tramos de 1 registro (2n - 2 tareas). Borra p4_todo(2). */
    p4_todo(2);
    if (n < 2) return;                 /* provisional: sin corte */
    long mid = lo + n / 2;
    #pragma omp atomic
    task_count += 2;
    /* Sin cláusulas: a, tmp, lo, mid, hi y cutoff entran como firstprivate (copias de los PUNTEROS y de
     * los índices). El arreglo es uno solo, compartido; cada tarea escribe un tramo distinto: sin carrera. */
    #pragma omp task
    merge_sort_tasks(a, tmp, lo, mid, cutoff);
    #pragma omp task
    merge_sort_tasks(a, tmp, mid, hi, cutoff);
    #pragma omp taskwait          /* las DOS hijas terminaron; sin esto se mezclarían tramos sin ordenar */
    merge(a, tmp, lo, mid, hi);
}

/* Datos con semilla fija: clave en {0, 1/4096, ..., 4095/4096}; id = posición original. */
static void fill_records(record *a, long n, unsigned seed)
{
    unsigned s = seed;
    for (long i = 0; i < n; i++) {
        a[i].key = (float)((p4_lcg_next(&s) >> 8) % KEY_VALUES) / (float)KEY_VALUES;
        a[i].id = (int)i;
    }
}

enum { SORT_QSORT, SORT_SEQ, SORT_TASKS };

/* Una corrida del ordenamiento pedido sobre a (ya copiado de la entrada). */
static void run_sort(int kind, record *a, record *tmp, long n, long cutoff)
{
    if (kind == SORT_QSORT) {
        qsort(a, (size_t)n, sizeof(record), cmp_key_id);
    } else if (kind == SORT_SEQ) {
        merge_sort_seq(a, tmp, 0, n);
    } else {
        task_count = 0;
        #pragma omp parallel
        #pragma omp single
        merge_sort_tasks(a, tmp, 0, n, cutoff);
        /* barrera implícita del single y de parallel: aquí ya terminaron TODAS las tareas */
    }
}

/* Arnés de medición con el protocolo del curso (herramientas/protocolo-medicion.md, §2). */
static void time_sort(int kind, record *a, const record *orig, record *tmp, long n, long cutoff,
                      int reps, double *t)
{
    /* TODO(3): 1 corrida de calentamiento que NO se cuenta + `reps` corridas cronometradas con
     * omp_get_wtime(); t[r] recibe el tiempo de la corrida r. Cada corrida parte de la entrada desordenada
     * (copia orig en a) y ordena con run_sort(kind, a, tmp, n, cutoff). Decide qué queda DENTRO del
     * cronómetro y qué FUERA. Al terminar, a debe tener el resultado de la última corrida.
     * Criterio: la línea tiempos_s= trae `reps` valores distintos de 0 y ninguno incluye la copia.
     * Borra p4_todo(3) y el código provisional. */
    p4_todo(3);
    memcpy(a, orig, (size_t)n * sizeof(record));   /* provisional: una corrida, sin cronómetro */
    run_sort(kind, a, tmp, n, cutoff);
    for (int r = 0; r < reps; r++) t[r] = 0.0;
}

/* 0 = igual a qsort; 1 = no ordenado por clave; 2 = ordenado pero NO estable; 3 = registros perdidos. */
static int check_sorted(const record *a, const record *ref, long n)
{
    for (long i = 1; i < n; i++)
        if (a[i - 1].key > a[i].key) return 1;
    for (long i = 0; i < n; i++)
        if (a[i].key != ref[i].key) return 3;
    for (long i = 0; i < n; i++)
        if (a[i].id != ref[i].id) return 2;
    return 0;
}

static const char *CHECK_MSG[] = { "OK", "FALLA (no ordenado por clave)",
                                   "FALLA (ordenado pero NO estable)", "FALLA (registros perdidos o duplicados)" };

int main(int argc, char **argv)
{
    long n = (argc > 1) ? atol(argv[1]) : 2000000L;
    long cutoff = (argc > 2) ? atol(argv[2]) : 4096L;
    const char *mode = (argc > 3) ? argv[3] : "ambos";
    int do_seq = strcmp(mode, "ambos") == 0 || strcmp(mode, "seq") == 0;
    int do_omp = strcmp(mode, "ambos") == 0 || strcmp(mode, "omp") == 0;
    if (n < 1 || cutoff < 1 || (!do_seq && !do_omp)) {
        fprintf(stderr, "uso: %s [n >= 1] [cutoff >= 1] [ambos | seq | omp]\n", argv[0]);
        return 2;
    }
    int reps = p4_reps();
    int threads = omp_get_max_threads();
    record *orig = malloc((size_t)n * sizeof(record)), *a = malloc((size_t)n * sizeof(record));
    record *tmp = malloc((size_t)n * sizeof(record)), *ref = malloc((size_t)n * sizeof(record));
    if (!orig || !a || !tmp || !ref) { fprintf(stderr, "sin memoria para n=%ld\n", n); return 2; }
    fill_records(orig, n, B_SEED);

    printf("b_mergesort: n=%ld cutoff=%ld hilos=%d reps=%d modo=%s\n", n, cutoff, threads, reps, mode);
    printf("n=%ld\n", n);

    /* Comprobación del corte con un arreglo chico: con n <= cutoff NO debe crearse ninguna tarea. */
    {
        record probe[64], probe_tmp[64];
        for (int i = 0; i < 64; i++) { probe[i].key = (float)(63 - i); probe[i].id = i; }
        run_sort(SORT_TASKS, probe, probe_tmp, 64, 64);
        if (task_count != 0)
            printf("corte: con n = cutoff = 64 se crearon %ld tareas (deben ser 0)\n", task_count);
    }
    int cutoff_pending = (p4_todo_mask & (1u << 2)) != 0;

    /* Referencia de correctitud: qsort con (clave, id). En seq/ambos también se cronometra (candidata a T(1)). */
    double t_qs[P4_MAX_REPS] = { 0 }, t_sq[P4_MAX_REPS] = { 0 }, t_tk[P4_MAX_REPS] = { 0 };
    double m_qs = 0.0, m_sq = 0.0, m_tk = 0.0, mn, mx;
    if (do_seq) {
        time_sort(SORT_QSORT, ref, orig, tmp, n, cutoff, reps, t_qs);
        m_qs = p4_median(t_qs, reps, &mn, &mx);
        printf("qsort            : mediana %.4f s  (min %.4f  max %.4f)\n", m_qs, mn, mx);
    } else {
        memcpy(ref, orig, (size_t)n * sizeof(record));
        qsort(ref, (size_t)n, sizeof(record), cmp_key_id);
        printf("qsort            : una corrida, solo como referencia de correctitud\n");
    }

    int st_seq = 0, st_tk = 0;
    if (do_seq) {
        time_sort(SORT_SEQ, a, orig, tmp, n, cutoff, reps, t_sq);
        st_seq = check_sorted(a, ref, n);
        m_sq = p4_median(t_sq, reps, &mn, &mx);
        printf("mergesort seq    : mediana %.4f s  (min %.4f  max %.4f)  verificacion: %s\n", m_sq, mn, mx,
               CHECK_MSG[st_seq]);
    }
    double t1 = 0.0;
    const char *t1_name = "-";
    if (do_seq) {                                /* T(1) = el MEJOR secuencial disponible (protocolo §3) */
        t1 = (m_sq > 0.0 && m_sq < m_qs) ? m_sq : m_qs;
        t1_name = (m_sq > 0.0 && m_sq < m_qs) ? "mergesort seq" : "qsort";
    }
    if (do_omp && cutoff_pending && n > 200000) {
        printf("mergesort tareas : NO SE CORRE con n=%ld mientras TODO(2) siga pendiente (sin corte serian "
               "%ld tareas); prueba con n <= 200000\n", n, 2 * n - 2);
        do_omp = 0;
        st_tk = 1;
    }
    if (do_omp) {
        time_sort(SORT_TASKS, a, orig, tmp, n, cutoff, reps, t_tk);
        st_tk = check_sorted(a, ref, n);
        m_tk = p4_median(t_tk, reps, &mn, &mx);
        printf("mergesort tareas : mediana %.4f s  (min %.4f  max %.4f)  verificacion: %s\n", m_tk, mn, mx,
               CHECK_MSG[st_tk]);
        printf("tareas creadas = %ld (cutoff = %ld)\n", task_count, cutoff);
    }
    double speedup = (do_seq && do_omp && m_tk > 0.0) ? t1 / m_tk : 0.0;
    if (do_seq && do_omp)
        printf("T(1) = %s, %.4f s (el mejor secuencial)   speedup %.2f   eficiencia %.2f\n", t1_name, t1,
               speedup, speedup / threads);
    if (do_seq && do_omp)
        printf("resumen: n=%ld cutoff=%ld hilos=%d t_seq=%.4f t_tareas=%.4f speedup=%.2f tareas=%ld\n",
               n, cutoff, threads, t1, m_tk, speedup, task_count);

    int ok = (st_seq == 0) && (st_tk == 0);
    if (p4_report_todo()) ok = 0;
    printf("verificacion contra qsort: %s\n", ok ? "OK" : "FALLA");
    /* Líneas para medir.sh: en modo seq, las del mergesort secuencial; en omp/ambos, las de las tareas. */
    if (do_omp) p4_print_times(t_tk, reps);
    else if (do_seq) p4_print_times(t_sq, reps);
    printf("RESULT,b_mergesort,%s,%d,%ld,%ld,%.6f,%.6f,%.6f,%.3f,%ld,%s\n", mode, threads, n, cutoff,
           m_qs, m_sq, m_tk, speedup, task_count, ok ? "OK" : "FALLA");
    free(orig); free(a); free(tmp); free(ref);
    return ok ? 0 : 1;
}
