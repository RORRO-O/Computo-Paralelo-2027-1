/*
 * fases.c — Perfilado por secciones de un programa de tres fases (S12, mini PRIMM).
 *
 *   Fase 1 · carga:   genera n registros como texto y los parsea (simula leer un CSV).   O(n)
 *   Fase 2 · cómputo: por registro integra k pasos de un oscilador no lineal amortiguado
 *                     (Duffing) y acumula la posición final en `sum`.                     O(n·k)
 *   Fase 3 · salida:  histograma de 10 clases de la posición final e impresión.          O(n)
 *
 * Cada fase se cronometra con omp_get_wtime() y se imprime su tiempo y su fracción del total.
 * Con eso se localiza el punto caliente (hot spot) y se estima la fracción paralelizable.
 *
 * Uso:      ./fases [n] [k]            (hilos: variable de entorno OMP_NUM_THREADS)
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra -fopenmp fases.c -o fases
 *
 * Estado: la fase de cómputo está SECUENCIAL. Completar TODO(1) es la fase "Modificar" del PRIMM.
 * Mientras no se complete, el programa corre bien (en secuencial) y avisa "TODO pendiente"
 * cuando se piden más hilos.
 */
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

#define N_BINS   10
#define LINE_LEN 24   /* "0.123456789012345\n" + terminador caben de sobra */

/* Generador congruencial lineal de 64 bits: reproducible en cualquier máquina. */
static unsigned long long lcg_next(unsigned long long *state)
{
    *state = *state * 6364136223846793005ULL + 1442695040888963407ULL;
    return *state;
}

/* Fase 1 · carga. Genera el texto de n registros (uno por línea, 15 decimales) y lo
 * convierte a double con strtod. Simula el costo de leer y parsear un archivo CSV:
 * trabajo secuencial típico de una V1. */
static void load_phase(double *x, long n)
{
    char *text = malloc((size_t)n * LINE_LEN);
    if (text == NULL) { fputs("error: sin memoria para el texto\n", stderr); exit(1); }

    unsigned long long state = 2027ULL;
    for (long i = 0; i < n; i++) {                       /* "escribir el archivo" */
        double value = (double)(lcg_next(&state) >> 11) / 9007199254740992.0; /* [0,1) */
        snprintf(text + i * LINE_LEN, LINE_LEN, "%.15f\n", value);
    }
    for (long i = 0; i < n; i++)                         /* "leer el archivo" */
        x[i] = strtod(text + i * LINE_LEN, NULL);

    free(text);
}

/* Fase 2 · cómputo caliente. Cada registro es una partícula con posición inicial x[i] y
 * velocidad 0; se integran k pasos de un oscilador de Duffing amortiguado (Euler semi-implícito).
 * Los registros son independientes entre sí; `sum` acumula la posición final de todos.
 * `threads_used` registra cuántos hilos ejecutaron el ciclo (1 si sigue secuencial). */
static double compute_phase(const double *x, double *p_out, long n, int k, int *threads_used)
{
    const double k_spring = 4.0;    /* constante del resorte */
    const double beta     = 3.0;    /* término cúbico (no lineal) */
    const double damping  = 0.2;    /* amortiguamiento */
    const double dt       = 0.02;   /* paso de integración */
    double sum = 0.0;

    *threads_used = 1;
    /* TODO(1): paraleliza este ciclo con OpenMP.
     *   Antes de escribir el pragma responde en el README: (a) ¿qué variables escribe cada
     *   iteración? (b) ¿cuál de ellas la escriben TODAS las iteraciones? Esa es una reducción.
     *   (c) ¿cuáles deben ser privadas? (las declaradas dentro del ciclo ya lo son).
     *   Mientras no lo completes, el ciclo corre en secuencial y el programa avisa. */
    for (long i = 0; i < n; i++) {
        if (i == 0) *threads_used = omp_get_num_threads();  /* lo escribe una sola iteración */
        double p = x[i];        /* posición */
        double v = 0.0;         /* velocidad */
        for (int j = 0; j < k; j++) {
            v += dt * (-k_spring * p - beta * p * p * p - damping * v);
            p += dt * v;
        }
        p_out[i] = p;
        sum += p;
    }
    return sum;
}

/* Fase 3 · salida. Histograma de 10 clases de la posición final (reescalada a [0,1))
 * e impresión del resumen. Nota: `hist[bin]++` es una escritura a memoria compartida;
 * si esta fase se paralelizara tal cual, habría una carrera de datos. */
static void output_phase(const double *p, long n, long hist[N_BINS])
{
    for (int b = 0; b < N_BINS; b++) hist[b] = 0;
    for (long i = 0; i < n; i++) {
        int bin = (int)((p[i] + 1.0) * 0.5 * N_BINS);    /* p está en (-1, 1) */
        if (bin < 0) bin = 0;
        if (bin >= N_BINS) bin = N_BINS - 1;
        hist[bin]++;
    }
    printf("histograma=");
    for (int b = 0; b < N_BINS; b++) printf("%ld%s", hist[b], b + 1 < N_BINS ? "," : "\n");
}

int main(int argc, char **argv)
{
    long n = (argc > 1) ? atol(argv[1]) : 500000L;
    int  k = (argc > 2) ? atoi(argv[2]) : 200;
    if (n <= 0 || k <= 0) {
        fprintf(stderr, "uso: %s [n > 0] [k > 0]\n", argv[0]);
        return 1;
    }

    double *x = malloc((size_t)n * sizeof *x);
    double *p = malloc((size_t)n * sizeof *p);
    if (x == NULL || p == NULL) { fputs("error: sin memoria\n", stderr); return 1; }
    long hist[N_BINS];
    int threads_used = 1;

    /* Calentamiento: crea el equipo de hilos antes de medir. El protocolo del curso no
     * cuenta el arranque; así el costo de crear hilos no se carga a la primera fase paralela. */
    #pragma omp parallel
    { (void)omp_get_thread_num(); }

    /* Un reloj entre fase y fase: así cada diferencia es el tiempo de UNA fase. */
    double t0 = omp_get_wtime();
    load_phase(x, n);
    double t1 = omp_get_wtime();
    double sum = compute_phase(x, p, n, k, &threads_used);
    double t2 = omp_get_wtime();
    output_phase(p, n, hist);
    double t3 = omp_get_wtime();

    double t_load = t1 - t0, t_compute = t2 - t1, t_output = t3 - t2, t_total = t3 - t0;

    printf("suma=%.12e\n", sum);
    printf("fases n=%ld k=%d hilos_max=%d hilos_en_computo=%d\n",
           n, k, omp_get_max_threads(), threads_used);
    printf("%-9s %10s %9s\n", "fase", "tiempo_s", "fraccion");
    printf("%-9s %10.4f %9.3f\n", "carga",   t_load,    t_load    / t_total);
    printf("%-9s %10.4f %9.3f\n", "computo", t_compute, t_compute / t_total);
    printf("%-9s %10.4f %9.3f\n", "salida",  t_output,  t_output  / t_total);
    printf("%-9s %10.4f %9.3f\n", "total",   t_total,   1.0);

    if (threads_used == 1 && omp_get_max_threads() > 1)
        printf("TODO pendiente: la fase de computo corrio con 1 hilo; completa TODO(1) en fases.c\n");

    free(x);
    free(p);
    return 0;
}
