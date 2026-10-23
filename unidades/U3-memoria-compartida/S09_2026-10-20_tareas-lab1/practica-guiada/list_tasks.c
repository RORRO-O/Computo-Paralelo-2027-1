/* list_tasks.c — Una tarea por nodo de una lista enlazada: el patrón parallel + single + task.
 * Ejemplo resuelto S09 · Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1
 *
 * Un `parallel for` no puede repartir una lista enlazada (no hay índices). Con tareas sí: UN hilo recorre
 * la lista y crea una tarea por nodo; los demás hilos las toman de la cola conforme se desocupan.
 *
 * Uso: ./list_tasks [n_nodos]   (por defecto 8; con n <= 16 imprime qué hilo procesó cada nodo)
 */
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>

#define WORK_ITERS 20000   /* ~decenas de microsegundos por nodo: vale la pena repartirlo */

typedef struct node {
    long id;
    long result;
    struct node *next;
} node;

/* Trabajo por nodo; depende solo de id, así se puede verificar contra la versión secuencial. */
static long work(long id)
{
    long s = 0;
    for (long i = 1; i <= WORK_ITERS; i++)
        s += (id * i) % 7;
    return s;
}

int main(int argc, char **argv)
{
    long n = (argc > 1) ? atol(argv[1]) : 8;
    if (n < 1) n = 1;
    int verbose = (n <= 16);

    /* Lista 0 -> 1 -> ... -> n-1 */
    node *head = NULL, *tail = NULL;
    for (long i = 0; i < n; i++) {
        node *p = malloc(sizeof *p);
        if (!p) {
            fprintf(stderr, "sin memoria\n");
            return 2;
        }
        p->id = i;
        p->result = 0;
        p->next = NULL;
        if (tail) tail->next = p; else head = p;
        tail = p;
    }

    /* Secuencial: la referencia. */
    double t0 = omp_get_wtime();
    long expected = 0;
    for (node *p = head; p != NULL; p = p->next)
        expected += work(p->id);
    double t_seq = omp_get_wtime() - t0;

    /* Con tareas. */
    t0 = omp_get_wtime();
    #pragma omp parallel
    #pragma omp single
    {
        for (node *p = head; p != NULL; p = p->next) {
            /* p está declarada dentro de la región paralela: es privada del hilo que recorre la lista.
             * Para la tarea es firstprivate IMPLÍCITA: la tarea guarda SU copia del puntero con el valor
             * que tenía al crearse. Por eso cada tarea procesa un nodo distinto aunque p siga avanzando. */
            #pragma omp task
            {
                p->result = work(p->id);
                if (verbose)
                    printf("  nodo %ld procesado por el hilo %d\n", p->id, omp_get_thread_num());
            }
        }
        if (verbose)
            printf("  fin del recorrido (hilo %d): %ld tareas creadas, no necesariamente ejecutadas\n",
                   omp_get_thread_num(), n);
    }   /* barrera implícita del single: aquí ya terminaron todas las tareas */
    double t_par = omp_get_wtime() - t0;

    long total = 0;
    for (node *p = head; p != NULL; p = p->next)
        total += p->result;
    int ok = (total == expected);

    printf("n=%ld hilos=%d  secuencial %.4f s  tareas %.4f s  speedup %.2f  verificacion: %s\n",
           n, omp_get_max_threads(), t_seq, t_par, t_par > 0 ? t_seq / t_par : 0.0, ok ? "OK" : "FALLA");

    while (head) {
        node *next = head->next;
        free(head);
        head = next;
    }
    return ok ? 0 : 1;
}
