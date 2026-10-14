/* fib_buggy.c — ERROR A PROPÓSITO: falta shared(x) y shared(y) en las tareas.
 * Ejemplo resuelto S09 (variante que falla) · Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1
 *
 * x e y son variables locales de la función. Para una tarea creada dentro de la función son firstprivate
 * IMPLÍCITAS: cada tarea hija recibe una copia y escribe su resultado en SU copia. El padre lee sus propias
 * x e y, que nadie tocó. No hay carrera de datos (nadie comparte nada): el resultado es simplemente 0,
 * siempre, para todo n >= cutoff. Compara con fib_tasks.c, que lleva shared(x) y shared(y).
 *
 * Uso: ./fib_buggy [n] [cutoff]   (por defecto n=30, cutoff=20)
 */
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>

static long fib_linear(int n)
{
    long a = 0, b = 1;
    for (int i = 0; i < n; i++) {
        long t = a + b;
        a = b;
        b = t;
    }
    return a;
}

static long fib_seq(int n)
{
    return n < 2 ? n : fib_seq(n - 1) + fib_seq(n - 2);
}

static long fib_noshared(int n, int cutoff)
{
    if (n < cutoff)
        return fib_seq(n);
    long x = 0, y = 0;              /* inicializadas para que la lectura del padre esté definida */
    #pragma omp task                /* FALTA shared(x): la tarea escribe en una COPIA de x */
    x = fib_noshared(n - 1, cutoff);
    #pragma omp task                /* FALTA shared(y) */
    y = fib_noshared(n - 2, cutoff);
    #pragma omp taskwait
    return x + y;                   /* el padre suma sus propias x e y: 0 + 0 */
}

int main(int argc, char **argv)
{
    int n = (argc > 1) ? atoi(argv[1]) : 30;
    int cutoff = (argc > 2) ? atoi(argv[2]) : 20;
    if (n < 0) n = 0;
    if (n > 40) n = 40;
    if (cutoff < 2) cutoff = 2;

    long expected = fib_linear(n);
    long got = -1;
    #pragma omp parallel
    #pragma omp single
    got = fib_noshared(n, cutoff);

    printf("fib_buggy(%d) con cutoff=%d e hilos=%d: %ld   esperado %ld   -> %s\n",
           n, cutoff, omp_get_max_threads(), got, expected,
           got == expected ? "correcto" : "INCORRECTO (las hijas escribieron en copias firstprivate)");
    return 0;
}
