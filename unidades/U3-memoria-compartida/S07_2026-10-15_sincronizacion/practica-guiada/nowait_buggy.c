/*
 * nowait_buggy.c — CARRERA A PROPOSITO: `nowait` donde SI hacia falta la barrera.
 *
 * Idea erronea 12: "al final de `omp for` no hay barrera". Si la hay, y este
 * programa muestra que pasa cuando se quita con `nowait` y el siguiente ciclo
 * lee datos que escribio OTRO hilo:
 *   ciclo 1: a[i] = f(i)             (con nowait)
 *   ciclo 2: b[i] = a[i] + a[n-1-i]  (a[n-1-i] lo escribe otro hilo)
 * f(i) cuesta mas cuando i es grande, asi que los hilos de indices bajos terminan
 * primero, entran al ciclo 2 y leen a[n-1-i] antes de que exista: b[] sale mal.
 * El numero de errores cambia entre corridas. Con la barrera (sin nowait) es 0.
 *
 * Uso: ./nowait_buggy [n]      (n por defecto: 2 000 000)
 */
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

/* Trabajo artificial: mas caro conforme crece i (desbalancea a los hilos). */
static long f(long i, long n)
{
    long reps = 1 + 64 * i / n;     /* entre 1 y 64 vueltas */
    long v = i;
    for (long k = 0; k < reps; k++) v = (v * 31 + 7) % 1000003;
    return v;
}

int main(int argc, char **argv)
{
    long n = (argc > 1) ? atol(argv[1]) : 2000000L;
    if (n <= 0) { fprintf(stderr, "Uso: %s [n > 0]\n", argv[0]); return 2; }

    long *a = calloc((size_t)n, sizeof(long));
    long *b = malloc((size_t)n * sizeof(long));
    long *ref = malloc((size_t)n * sizeof(long));
    if (!a || !b || !ref) { fprintf(stderr, "Sin memoria\n"); return 1; }

    /* Referencia secuencial. */
    for (long i = 0; i < n; i++) ref[i] = f(i, n);
    for (long i = 0; i < n; i++) ref[i] = ref[i] + ref[n - 1 - i];
    /* (ref[i] ya contiene a[i]+a[n-1-i] solo para i < n/2; recalculamos limpio) */
    for (long i = 0; i < n; i++) a[i] = f(i, n);
    for (long i = 0; i < n; i++) ref[i] = a[i] + a[n - 1 - i];
    for (long i = 0; i < n; i++) a[i] = 0;

    #pragma omp parallel
    {
        #pragma omp for nowait            /* CARRERA: quita la barrera que el ciclo 2 necesita */
        for (long i = 0; i < n; i++) a[i] = f(i, n);

        #pragma omp for
        for (long i = 0; i < n; i++) b[i] = a[i] + a[n - 1 - i];   /* lee lo de otro hilo */
    }

    long errors = 0;
    for (long i = 0; i < n; i++) if (b[i] != ref[i]) errors++;
    printf("hilos=%d n=%ld  elementos incorrectos en b[] = %ld de %ld  %s\n",
           omp_get_max_threads(), n, errors, n,
           errors == 0 ? "(coincide esta vez; la carrera sigue ahi)" : "INCORRECTO");
    free(a); free(b); free(ref);
    return 0;
}
