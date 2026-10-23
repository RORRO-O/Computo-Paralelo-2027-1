/* taskwait_buggy.c — CARRERA DE DATOS A PROPÓSITO: falta el taskwait entre crear dos tareas y leer su resultado.
 * Ejemplo resuelto S09 (variante que falla) · Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1
 *
 * Quien cree que una tarea se ejecuta en el momento en que se crea (idea errónea 13) espera que la suma
 * dentro del single salga bien. No: `task` ENCOLA la tarea; el hilo creador sigue de largo y lee left + right
 * antes de que las tareas terminen (o empiecen). La barrera implícita al final del single sí espera a todas
 * las tareas, por eso la segunda lectura es correcta. ThreadSanitizer (make tsan) reporta la carrera entre la
 * escritura de left/right dentro de la tarea y la lectura prematura.
 *
 * Uso: ./taskwait_buggy [n]   (por defecto 20000000)
 */
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>

static long sum_range(const int *a, long lo, long hi)
{
    long s = 0;
    for (long i = lo; i < hi; i++)
        s += a[i];
    return s;
}

int main(int argc, char **argv)
{
    long n = (argc > 1) ? atol(argv[1]) : 20000000L;
    if (n < 2) n = 2;
    int *a = malloc((size_t)n * sizeof(int));
    if (!a) {
        fprintf(stderr, "sin memoria\n");
        return 2;
    }
    for (long i = 0; i < n; i++)
        a[i] = (int)(i % 10);
    long expected = sum_range(a, 0, n);

    long left = 0, right = 0, premature = -1;
    #pragma omp parallel
    #pragma omp single
    {
        #pragma omp task shared(left)
        left = sum_range(a, 0, n / 2);
        #pragma omp task shared(right)
        right = sum_range(a, n / 2, n);
        /* FALTA AQUÍ:  #pragma omp taskwait  */
        premature = left + right;        /* lectura prematura: las tareas apenas se encolaron */
    }   /* barrera implícita al final del single: aquí ya terminaron TODAS las tareas */
    long after = left + right;

    printf("n=%ld hilos=%d esperado=%ld\n", n, omp_get_max_threads(), expected);
    printf("dentro del single, sin taskwait   : %ld  -> %s\n", premature,
           premature == expected ? "correcto (esta vez; sigue siendo una carrera)" : "INCORRECTO");
    printf("despues de la barrera del single  : %ld  -> %s\n", after,
           after == expected ? "correcto" : "INCORRECTO");
    free(a);
    return 0;
}
