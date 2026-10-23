/* a_histogram.c — Parte A: histograma paralelo correcto con cinco mecanismos y el mismo arnés de medición.
 * Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · Práctica 4
 *
 * Uso:  ./a_histogram [modo] [n] [nbins] [cutoff]
 *   modo    todos (por defecto) | rapidas (todas menos critical) | seq | critical | atomic | local |
 *           reduction | tareas | ver
 *   n       muestras (por defecto 1 000 000); nbins intervalos (por defecto 64)
 *   cutoff  solo para tareas: tamaño máximo de una hoja (por defecto 16 384)
 *   "ver"   imprime el histograma como barras (comprobación visual de la campana) y termina.
 * Entorno: OMP_NUM_THREADS (hilos); REPS (repeticiones cronometradas, 5; siempre 1 calentamiento).
 *
 * Todas las versiones calculan lo mismo que hist_seq (a_hist.h): la secuencial es la referencia T(1) del
 * speedup y la verdad contra la que se compara (conteos enteros: igualdad exacta). Las paralelas difieren
 * solo en CÓMO evitan la carrera en hist[b]++. La versión con carrera está aparte, en a_histogram_buggy.c
 * (convención del curso: solo los *_buggy.c tienen carreras, y a propósito).
 */
#include "a_hist.h"

/* 1) critical: un hilo a la vez en la actualización. Correcto; cada muestra paga entrar y salir de la región. */
static void hist_critical(const float *u, long n, int nbins, long *hist)
{
    for (int b = 0; b < nbins; b++) hist[b] = 0;
    #pragma omp parallel for
    for (long i = 0; i < n; i++) {
        int b = hist_bin(u, i, nbins);     /* trabajo privado: FUERA de la región crítica */
        #pragma omp critical
        hist[b]++;
    }
}

/* 2) atomic: una instrucción atómica del procesador por actualización. Solo cubre x++, x += e, x = x op e... */
static void hist_atomic(const float *u, long n, int nbins, long *hist)
{
    for (int b = 0; b < nbins; b++) hist[b] = 0;
    #pragma omp parallel for
    for (long i = 0; i < n; i++) {
        int b = hist_bin(u, i, nbins);
        #pragma omp atomic
        hist[b]++;
    }
}

/* 3) local: cada hilo cuenta en su propio arreglo (privado por alcance) y combina UNA vez al final:
 *    nbins actualizaciones protegidas por hilo, en lugar de n. */
static void hist_local(const float *u, long n, int nbins, long *hist)
{
    for (int b = 0; b < nbins; b++) hist[b] = 0;
    #pragma omp parallel
    {
        long *local = calloc((size_t)nbins, sizeof(long));   /* declarado adentro: uno por hilo */
        if (!local) { fprintf(stderr, "sin memoria\n"); exit(1); }
        #pragma omp for nowait                                /* después del ciclo nadie lee datos ajenos */
        for (long i = 0; i < n; i++)
            local[hist_bin(u, i, nbins)]++;                   /* memoria privada: sin carrera */
        #pragma omp critical                                  /* combinación: nbins sumas por hilo */
        for (int b = 0; b < nbins; b++) hist[b] += local[b];
        free(local);
    }
}

/* 4) reduction sobre un arreglo (OpenMP 4.5): OpenMP crea la copia privada de hist[0..nbins) en cada hilo,
 *    la inicializa en 0 y la combina con + al final. Es el patrón 3 hecho por el compilador. */
static void hist_reduction(const float *u, long n, int nbins, long *hist)
{
    for (int b = 0; b < nbins; b++) hist[b] = 0;
    #pragma omp parallel for reduction(+:hist[:nbins])
    for (long i = 0; i < n; i++)
        hist[hist_bin(u, i, nbins)]++;
}

/* 5) tareas (constructo nuevo de S09): el rango [lo, hi) se parte en dos mitades, una tarea por mitad,
 *    hasta llegar al corte; cada hoja cuenta su tramo en su propio arreglo; el padre espera a sus dos
 *    hijas (taskwait) y suma los dos histogramas: una REDUCCIÓN EN ÁRBOL hecha con tareas.
 *    Es el mismo esqueleto del mergesort de la Parte B: partir, dos tareas, taskwait, combinar. */
static long hist_cutoff = HIST_DEFAULT_CUTOFF;   /* lo fija main con el 4.º argumento */
static long hist_task_count;                     /* tareas creadas en la última llamada */

static void hist_tasks_rec(const float *u, long lo, long hi, int nbins, long *out, long cutoff)
{
    long n = hi - lo;
    if (n <= cutoff) {                           /* corte: hoja secuencial, sin crear tareas */
        for (int b = 0; b < nbins; b++) out[b] = 0;
        for (long i = lo; i < hi; i++) out[hist_bin(u, i, nbins)]++;
        return;
    }
    long mid = lo + n / 2;
    long *right = malloc((size_t)nbins * sizeof(long));   /* conteos de la mitad derecha */
    if (!right) { fprintf(stderr, "sin memoria\n"); exit(1); }
    #pragma omp atomic
    hist_task_count += 2;
    /* Sin cláusulas: u, lo, mid, hi, nbins, out, right y cutoff entran como firstprivate (copias del valor
     * de este momento). Se copian los PUNTEROS, no los arreglos: la hija escribe en el mismo out[] o
     * right[] que después lee el padre. Cada hija escribe un arreglo distinto: no hay carrera. */
    #pragma omp task
    hist_tasks_rec(u, lo, mid, nbins, out, cutoff);
    #pragma omp task
    hist_tasks_rec(u, mid, hi, nbins, right, cutoff);
    #pragma omp taskwait                         /* las DOS hijas terminaron: out y right están completos */
    for (int b = 0; b < nbins; b++) out[b] += right[b];
    free(right);
}

static void hist_tasks(const float *u, long n, int nbins, long *hist)
{
    hist_task_count = 0;
    #pragma omp parallel                         /* el equipo de hilos que ejecutará las tareas */
    #pragma omp single                           /* UN hilo arranca la recursión; los demás toman tareas */
    hist_tasks_rec(u, 0, n, nbins, hist, hist_cutoff);
    /* barrera implícita del single y de parallel: aquí ya terminaron TODAS las tareas */
}

/* Modo "ver": barras de asteriscos proporcionales a cada conteo (la campana de Gauss). */
static void print_bars(const long *hist, int nbins)
{
    long mx = 1;
    for (int b = 0; b < nbins; b++) if (hist[b] > mx) mx = hist[b];
    for (int b = 0; b < nbins; b++) {
        double lo = HIST_Z_MIN + b * HIST_Z_RANGE / nbins;
        int stars = (int)(60.0 * (double)hist[b] / (double)mx + 0.5);
        printf("[%+5.2f, %+5.2f) %9ld ", lo, lo + HIST_Z_RANGE / nbins, hist[b]);
        for (int s = 0; s < stars; s++) putchar('*');
        putchar('\n');
    }
}

static const struct { const char *name; hist_fn fn; } MODES[] = {
    { "critical", hist_critical }, { "atomic", hist_atomic }, { "local", hist_local },
    { "reduction", hist_reduction }, { "tareas", hist_tasks },
};
#define N_MODES ((int)(sizeof MODES / sizeof MODES[0]))

int main(int argc, char **argv)
{
    const char *mode = (argc > 1) ? argv[1] : "todos";
    if (argc > 4) hist_cutoff = atol(argv[4]);
    if (hist_cutoff < 1) hist_cutoff = 1;
    int reps = p4_reps();
    long n; int nbins; long *ref; double t_seq, t_seq_reps[P4_MAX_REPS];
    float *u = hist_setup(argc, argv, 2, &n, &nbins, &ref, &t_seq, t_seq_reps, reps);
    int threads = omp_get_max_threads();
    int all = strcmp(mode, "todos") == 0, fast = strcmp(mode, "rapidas") == 0, wrong = 0, found = 0;

    if (strcmp(mode, "ver") == 0) {
        print_bars(ref, nbins);
        printf("total=%ld (esperado %ld)\n", hist_total(ref, nbins), n);
        free(u); free(ref);
        return 0;
    }
    printf("a_histogram: n=%ld nbins=%d hilos=%d reps=%d modo=%s corte_tareas=%ld\n",
           n, nbins, threads, reps, mode, hist_cutoff);
    printf("n=%ld\n", n);
    double mn, mx;
    p4_median(t_seq_reps, reps, &mn, &mx);
    printf("%-10s mediana %.4f s (min %.4f max %.4f) %7.1f ns/elemento  (referencia T(1))\n",
           "seq", t_seq, mn, mx, t_seq * 1e9 / (double)n);
    if (strcmp(mode, "seq") == 0) {
        printf("RESULT,a_histogram,seq,1,%ld,%d,%.6f,%.6f,1.000,0,OK\n", n, nbins, t_seq, t_seq);
        p4_print_times(t_seq_reps, reps);
        found = 1;
    }
    for (int k = 0; k < N_MODES; k++) {
        if (all || (fast && MODES[k].fn != hist_critical) || strcmp(mode, MODES[k].name) == 0) {
            wrong += hist_benchmark(MODES[k].name, MODES[k].fn, u, n, nbins, ref, t_seq, reps, !(all || fast));
            if (MODES[k].fn == hist_tasks)
                printf("tareas creadas = %ld (corte = %ld)\n", hist_task_count, hist_cutoff);
            found = 1;
        }
    }
    if (!found) {
        fprintf(stderr, "modo desconocido: %s (todos | rapidas | seq | critical | atomic | local | reduction | "
                        "tareas | ver)\n", mode);
        return 2;
    }
    printf("verificacion contra la secuencial: %s\n", wrong ? "FALLA" : "OK");
    free(u); free(ref);
    return wrong ? 1 : 0;
}
