/* tree_sum_tasks.c — Fase Crear de la práctica guiada S09: suma sobre un árbol binario con tareas.
 * Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1
 *
 * Compila y corre tal cual: la versión secuencial funciona; la paralela imprime "TODO pendiente" hasta que
 * completes TODO(1) y TODO(2). TODO(3) es opcional.
 *
 * Problema: cada nodo guarda un entero v; el "peso" del nodo es la longitud de su secuencia de Collatz
 * (pasos hasta llegar a 1). Hay que sumar los pesos de todos los nodos. El árbol NO está balanceado y el
 * peso de cada nodo es irregular: un parallel for no sirve (no hay índices) y el trabajo por rama varía.
 *
 * Uso: ./tree_sum_tasks [n_nodos] [cutoff_profundidad]   (por defecto 1000000 y 8)
 *   Por debajo de la profundidad de corte NO se crean tareas: la suma de ese subárbol es secuencial.
 * Entorno: OMP_NUM_THREADS, REPS (5).
 *
 * Criterio de "listo" (README, fase 5): compila sin warnings; imprime "verificacion: OK" con n=1000000;
 * el speedup con 4 hilos es > 1 para algún cutoff; `make test` termina en 0 FAIL.
 */
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>

#define MAX_REPS 32

typedef struct node {
    long value;
    struct node *left, *right;
} node;

static long next_value;                   /* valores 0, 1, 2, ... en orden de construcción */
static unsigned rng_state = 20261020u;    /* semilla fija: el mismo árbol en toda máquina */

static unsigned rng(void)
{
    rng_state = rng_state * 1664525u + 1013904223u;
    return rng_state;
}

/* Árbol de n nodos con forma aleatoria (no balanceado): el tamaño del subárbol izquierdo se sortea. */
static node *build_tree(long n)
{
    if (n == 0)
        return NULL;
    node *t = malloc(sizeof *t);
    if (!t) {
        fprintf(stderr, "sin memoria\n");
        exit(2);
    }
    t->value = next_value++;
    long left_n = (long)(rng() % (unsigned long)n);   /* 0 .. n-1 */
    t->left = build_tree(left_n);
    t->right = build_tree(n - 1 - left_n);
    return t;
}

static void free_tree(node *t)
{
    if (!t)
        return;
    free_tree(t->left);
    free_tree(t->right);
    free(t);
}

static int tree_depth(const node *t)
{
    if (!t)
        return 0;
    int l = tree_depth(t->left), r = tree_depth(t->right);
    return 1 + (l > r ? l : r);
}

/* Peso del nodo: pasos de la secuencia de Collatz de v (0 y 1 pesan 0). Trabajo irregular. */
static long collatz_steps(long v)
{
    long steps = 0;
    while (v > 1) {
        v = (v & 1) ? 3 * v + 1 : v / 2;
        steps++;
    }
    return steps;
}

/* Versión secuencial: la referencia T(1). */
static long tree_sum_seq(const node *t)
{
    if (!t)
        return 0;
    return collatz_steps(t->value) + tree_sum_seq(t->left) + tree_sum_seq(t->right);
}

/* TODO(1): suma con tareas. Esquema:
 *   - si t == NULL, devuelve 0;
 *   - si depth >= cutoff_depth, devuelve tree_sum_seq(t)   (corte: de aquí hacia abajo, sin tareas);
 *   - si no: crea UNA tarea por subárbol; la variable donde cada tarea deja su suma debe ser shared
 *     (si queda firstprivate, el padre lee su propia copia: ver fib_buggy.c); espera con taskwait;
 *     devuelve collatz_steps(t->value) + suma_izquierda + suma_derecha.
 * Mientras no esté implementada devuelve -1 y main imprime "TODO pendiente". */
static long tree_sum_tasks(const node *t, int depth, int cutoff_depth)
{
    (void)t;
    (void)depth;
    (void)cutoff_depth;
    return -1;
}

/* TODO(2): envuelve la llamada de abajo en una región parallel con un single, para que UN hilo arranque
 * la recursión y los demás tomen tareas. Sin región paralela no hay equipo: las tareas que crees en
 * TODO(1) se ejecutarían de inmediato, en serie, en el hilo principal (resultado correcto, speedup 1). */
static long tree_sum_par(const node *root, int cutoff_depth)
{
    long total;
    total = tree_sum_tasks(root, 0, cutoff_depth);
    return total;
}

/* TODO(3) (opcional): agrega un contador atómico de tareas como task_begin() en mergesort_tasks.c,
 * imprímelo y compáralo con la cota 2·(2^cutoff_depth − 1). ¿Por qué suele quedar por debajo? */

static int cmp_double(const void *p, const void *q)
{
    double a = *(const double *)p, b = *(const double *)q;
    return (a > b) - (a < b);
}

int main(int argc, char **argv)
{
    long n = (argc > 1) ? atol(argv[1]) : 1000000L;
    int cutoff_depth = (argc > 2) ? atoi(argv[2]) : 8;
    if (n < 1) n = 1;
    if (cutoff_depth < 0) cutoff_depth = 0;
    const char *env = getenv("REPS");
    int reps = env ? atoi(env) : 5;
    if (reps < 1) reps = 1;
    if (reps > MAX_REPS) reps = MAX_REPS;
    int threads = omp_get_max_threads();

    node *root = build_tree(n);
    printf("n=%ld nodos  profundidad=%d  cutoff_profundidad=%d  hilos=%d  reps=%d\n",
           n, tree_depth(root), cutoff_depth, threads, reps);

    /* Secuencial: 1 calentamiento + reps, mediana. */
    double t_seq[MAX_REPS];
    long expected = 0;
    for (int r = -1; r < reps; r++) {
        double t0 = omp_get_wtime();
        expected = tree_sum_seq(root);
        double t = omp_get_wtime() - t0;
        if (r >= 0)
            t_seq[r] = t;
    }
    qsort(t_seq, (size_t)reps, sizeof t_seq[0], cmp_double);
    printf("secuencial : suma = %ld   mediana %.4f s  (min %.4f  max %.4f)\n",
           expected, t_seq[reps / 2], t_seq[0], t_seq[reps - 1]);

    /* Paralela. */
    long got = tree_sum_par(root, cutoff_depth);   /* calentamiento (y detección del TODO) */
    if (got == -1) {
        printf("tareas     : TODO pendiente (completa TODO(1) y TODO(2) en tree_sum_tasks.c)\n");
        free_tree(root);
        return 0;
    }
    double t_par[MAX_REPS];
    for (int r = 0; r < reps; r++) {
        double t0 = omp_get_wtime();
        got = tree_sum_par(root, cutoff_depth);
        t_par[r] = omp_get_wtime() - t0;
    }
    qsort(t_par, (size_t)reps, sizeof t_par[0], cmp_double);
    double speedup = t_par[reps / 2] > 0 ? t_seq[reps / 2] / t_par[reps / 2] : 0.0;
    int ok = (got == expected);
    printf("tareas     : suma = %ld   mediana %.4f s  (min %.4f  max %.4f)  speedup %.2f  eficiencia %.2f\n",
           got, t_par[reps / 2], t_par[0], t_par[reps - 1], speedup, speedup / threads);
    printf("verificacion: %s\n", ok ? "OK" : "FALLA");
    free_tree(root);
    return ok ? 0 : 1;
}
