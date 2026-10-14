/* vec_kernels.c — Núcleos cortos para leer los reportes del vectorizador de GCC.
 *
 * Compila SOLO este archivo con:
 *   gcc -std=c11 -O2 -Wall -Wextra -fopenmp -fopt-info-vec-optimized -fopt-info-vec-missed -c vec_kernels.c
 * (o `make report`). Cada mensaje trae archivo:línea:columna; compáralo con los ciclos de abajo.
 *
 * A -O2, GCC 13 vectoriza solo con el modelo de costo "very-cheap": no genera comprobaciones de
 * aliasing en tiempo de ejecución ni epílogos para n no múltiplo del ancho del vector. Por eso
 * saxpy_plain y saxpy_restrict NO se vectorizan a -O2 aunque sean vectorizables. `#pragma omp simd`
 * le dice al compilador "yo garantizo que no hay dependencias entre iteraciones": vectoriza sin
 * aplicar el modelo de costo.
 */
#include "vec_kernels.h"

/* Versión 1: punteros sin restrict. El compilador no puede descartar que x e y se traslapen. */
void saxpy_plain(float a, const float *x, float *y, long n)
{
    for (long i = 0; i < n; i++)
        y[i] = a * x[i] + y[i];
}

/* Versión 2: restrict promete que x e y no se traslapan. Sigue sujeta al modelo de costo de -O2. */
void saxpy_restrict(float a, const float *restrict x, float *restrict y, long n)
{
    for (long i = 0; i < n; i++)
        y[i] = a * x[i] + y[i];
}

/* Versión 3: la directiva simd afirma que las iteraciones son independientes. */
void saxpy_simd(float a, const float *x, float *y, long n)
{
    #pragma omp simd
    for (long i = 0; i < n; i++)
        y[i] = a * x[i] + y[i];
}

/* Dependencia acarreada por el ciclo: la iteración i necesita el resultado de la iteración i-1.
 * No se puede vectorizar ni paralelizar tal cual (en scan.c se resuelve con el patrón de dos fases). */
void prefix_dep(double *a, const double *b, long n)
{
    for (long i = 1; i < n; i++)
        a[i] = a[i - 1] + b[i];
}
