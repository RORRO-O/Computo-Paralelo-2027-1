/*
 * nowait_buggy.c — Carrera de datos introducida A PROPÓSITO.
 *
 * Dos ciclos 'omp for' dentro de la misma región paralela, separados por
 * 'nowait'. El segundo ciclo lee a[i] que escribió el primero (misma i).
 *
 *   - Con schedule(static) en AMBOS ciclos (mismo n, mismo chunk) la
 *     especificación de OpenMP garantiza que la iteración i la ejecuta el
 *     mismo hilo en los dos ciclos, así que el 'nowait' es seguro.
 *   - Con schedule(dynamic) no hay tal garantía: un hilo que termina antes
 *     entra al segundo ciclo y puede leer a[i] antes de que otro hilo la
 *     escriba. Resultado: b[i] incorrecto A VECES. Que una corrida salga bien
 *     no demuestra nada (idea errónea 7 del Anexo A).
 *
 * Uso: ./nowait_buggy [n] [static|dynamic]     (por defecto 2000 dynamic)
 * Imprime cuántas b[i] quedaron mal y termina con 1 si hubo alguna.
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra -fopenmp nowait_buggy.c -o nowait_buggy
 * Con ThreadSanitizer: gcc -std=c11 -O1 -g -fopenmp -fsanitize=thread nowait_buggy.c -o nowait_tsan
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>

static void spin_us(double us)
{
    double t_end = omp_get_wtime() + us * 1e-6;
    while (omp_get_wtime() < t_end) { /* ocupado */ }
}

int main(int argc, char **argv)
{
    int n = (argc > 1) ? atoi(argv[1]) : 2000;
    int use_dynamic = 1;
    if (argc > 2) {
        if (strcmp(argv[2], "static") == 0)       use_dynamic = 0;
        else if (strcmp(argv[2], "dynamic") == 0) use_dynamic = 1;
        else { fprintf(stderr, "política: static | dynamic\n"); return 2; }
    }
    if (n < 1 || n > 1000000) { fprintf(stderr, "n fuera de rango\n"); return 2; }

    int *a = malloc((size_t)n * sizeof *a);
    int *b = malloc((size_t)n * sizeof *b);
    if (!a || !b) { fprintf(stderr, "sin memoria\n"); return 2; }
    for (int i = 0; i < n; i++) { a[i] = -1; b[i] = -1; }

    if (use_dynamic) {
        #pragma omp parallel
        {
            /* Ciclo 1: las últimas iteraciones son las más caras (i microsegundos). */
            #pragma omp for schedule(dynamic) nowait
            for (int i = 0; i < n; i++) {
                spin_us((double)(i % 1000));
                a[i] = i;
            }
            /* Ciclo 2: sin barrera antes. ¿Ya está escrita a[i]? Nadie lo garantiza. */
            #pragma omp for schedule(dynamic)
            for (int i = 0; i < n; i++)
                b[i] = 2 * a[i];
        }
    } else {
        #pragma omp parallel
        {
            #pragma omp for schedule(static) nowait
            for (int i = 0; i < n; i++) {
                spin_us((double)(i % 1000));
                a[i] = i;
            }
            /* Mismo schedule(static), mismo n: la iteración i cae en el mismo hilo. */
            #pragma omp for schedule(static)
            for (int i = 0; i < n; i++)
                b[i] = 2 * a[i];
        }
    }

    int wrong = 0;
    for (int i = 0; i < n; i++)
        if (b[i] != 2 * i) wrong++;

    printf("n=%d hilos=%d política=%s -> b[i] incorrectas: %d de %d\n",
           n, omp_get_max_threads(), use_dynamic ? "dynamic" : "static", wrong, n);
    free(a);
    free(b);
    return wrong ? 1 : 0;
}
