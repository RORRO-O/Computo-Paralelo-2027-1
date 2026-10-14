/* cronometro.h — Cronómetro, mediana y filas CSV para el protocolo de medición del curso.
 * Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · herramientas/
 *
 * Qué ofrece (todas las funciones son `static inline`: basta incluir el archivo, no hay .c que enlazar):
 *
 *   double cron_ahora(void);                       Segundos desde un origen arbitrario (reloj monotónico).
 *                                                  Con -fopenmp usa omp_get_wtime(); sin -fopenmp usa
 *                                                  clock_gettime(CLOCK_MONOTONIC). En MPI puedes usar
 *                                                  MPI_Wtime() directamente; cron_ahora() también sirve.
 *   void   cron_imprimir_tiempo(double segundos);  Imprime "tiempo_s=<valor>" (la línea que lee medir.sh).
 *   double cron_mediana(const double *v, size_t n); Mediana de n doubles (no modifica el arreglo).
 *   double cron_minimo(const double *v, size_t n);
 *   double cron_maximo(const double *v, size_t n);
 *   double cron_karp_flatt(double speedup, int p); Fracción secuencial estimada f = (1/S - 1/p) / (1 - 1/p).
 *   void   cron_csv_encabezado(FILE *f, size_t nreps);
 *                                                  Escribe "config,hilos,n,rep1..repR,mediana_s,speedup,eficiencia".
 *   int    cron_csv_abrir(const char *ruta, size_t nreps, FILE **out);
 *                                                  Abre en modo "append"; si el archivo es nuevo o está
 *                                                  vacío escribe el encabezado. Devuelve 0 si pudo abrir.
 *   void   cron_csv_fila(FILE *f, const char *config, int hilos, long n,
 *                        const double *reps, size_t nreps, double t1);
 *                                                  Escribe una fila del protocolo. speedup = t1 / mediana si
 *                                                  t1 > 0, si no "NA". eficiencia = speedup / hilos si
 *                                                  hilos >= 1; con hilos <= 0 la columna hilos dice "gpu" y
 *                                                  la eficiencia "NA".
 *
 * Uso mínimo (lo que medir.sh necesita):
 *
 *     #include "cronometro.h"            // PRIMERO, antes de <stdio.h> y <time.h> (ver nota)
 *     ...
 *     double t0 = cron_ahora();
 *     calcular(n);                       // solo la región de interés: no la lectura ni la impresión
 *     double t = cron_ahora() - t0;
 *     printf("resultado=%.12f\n", r);
 *     cron_imprimir_tiempo(t);           // tiempo_s=0.123456
 *
 * Uso con repeticiones dentro del programa (ver ejemplo_cronometro.c):
 *
 *     double reps[5];
 *     calcular(n);                                   // calentamiento, no se cuenta
 *     for (int r = 0; r < 5; r++) { t0 = cron_ahora(); calcular(n); reps[r] = cron_ahora() - t0; }
 *     FILE *f; if (cron_csv_abrir("resultados/mediciones.csv", 5, &f) == 0) {
 *         cron_csv_fila(f, "openmp", 4, n, reps, 5, t1_secuencial); fclose(f); }
 *
 * Nota sobre el orden de inclusión: sin -fopenmp, clock_gettime() exige _POSIX_C_SOURCE >= 199309L
 * cuando se compila con -std=c11. Este encabezado lo define si nadie lo hizo antes, pero solo surte
 * efecto si se incluye antes que cualquier encabezado del sistema. Si lo incluyes tarde, obtienes un
 * #error con esta explicación en lugar de una advertencia críptica.
 *
 * Compila sin advertencias con:  gcc -std=c11 -O2 -Wall -Wextra [-fopenmp] programa.c
 * Ejemplo ejecutable: ver ejemplo_cronometro.c y el Makefile de esta carpeta (`make && make test`).
 */
#ifndef CRONOMETRO_H
#define CRONOMETRO_H

#if !defined(_OPENMP) && !defined(_POSIX_C_SOURCE)
#define _POSIX_C_SOURCE 200809L
#endif

#include <math.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#ifdef _OPENMP
#include <omp.h>
#else
#ifndef CLOCK_MONOTONIC
#error "cronometro.h: incluye este archivo ANTES que <stdio.h>/<time.h>, o compila con -fopenmp (clock_gettime necesita _POSIX_C_SOURCE)."
#endif
#endif

/* Número máximo de repeticiones que cron_mediana ordena sin pedir memoria dinámica. */
#ifndef CRON_MAX_REPS
#define CRON_MAX_REPS 64
#endif

/* Segundos desde un origen arbitrario. Solo tienen sentido las diferencias entre dos llamadas. */
static inline double cron_ahora(void)
{
#ifdef _OPENMP
    return omp_get_wtime();
#else
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
#endif
}

/* Línea que leen medir.sh y run_all.sh: clave=valor, seis decimales. */
static inline void cron_imprimir_tiempo(double segundos)
{
    printf("tiempo_s=%.6f\n", segundos);
}

static inline int cron_cmp_double_(const void *a, const void *b)
{
    double x = *(const double *)a, y = *(const double *)b;
    return (x > y) - (x < y);
}

/* Mediana de v[0..n-1]. Con n par, promedio de los dos centrales. Devuelve NAN si n == 0. */
static inline double cron_mediana(const double *v, size_t n)
{
    double buffer[CRON_MAX_REPS];
    double *copia = buffer;
    double mediana;
    if (n == 0)
        return NAN;
    if (n > CRON_MAX_REPS) {
        copia = (double *)malloc(n * sizeof(double));
        if (copia == NULL)
            return NAN;
    }
    for (size_t i = 0; i < n; i++)
        copia[i] = v[i];
    qsort(copia, n, sizeof(double), cron_cmp_double_);
    if (n % 2 == 1)
        mediana = copia[n / 2];
    else
        mediana = 0.5 * (copia[n / 2 - 1] + copia[n / 2]);
    if (copia != buffer)
        free(copia);
    return mediana;
}

static inline double cron_minimo(const double *v, size_t n)
{
    if (n == 0)
        return NAN;
    double m = v[0];
    for (size_t i = 1; i < n; i++)
        if (v[i] < m)
            m = v[i];
    return m;
}

static inline double cron_maximo(const double *v, size_t n)
{
    if (n == 0)
        return NAN;
    double m = v[0];
    for (size_t i = 1; i < n; i++)
        if (v[i] > m)
            m = v[i];
    return m;
}

/* Fracción secuencial estimada (Karp–Flatt). Requiere p >= 2 y speedup > 0; si no, NAN. */
static inline double cron_karp_flatt(double speedup, int p)
{
    if (p < 2 || speedup <= 0.0)
        return NAN;
    return (1.0 / speedup - 1.0 / (double)p) / (1.0 - 1.0 / (double)p);
}

/* Encabezado del CSV del protocolo (herramientas/protocolo-medicion.md §4). */
static inline void cron_csv_encabezado(FILE *f, size_t nreps)
{
    fputs("config,hilos,n", f);
    for (size_t i = 1; i <= nreps; i++)
        fprintf(f, ",rep%zu", i);
    fputs(",mediana_s,speedup,eficiencia\n", f);
}

/* Abre `ruta` para agregar filas. Escribe el encabezado si el archivo no existía o está vacío.
 * Devuelve 0 si *out quedó listo; 1 si no se pudo abrir (y *out = NULL). */
static inline int cron_csv_abrir(const char *ruta, size_t nreps, FILE **out)
{
    FILE *f = fopen(ruta, "a+");
    *out = NULL;
    if (f == NULL)
        return 1;
    if (fseek(f, 0, SEEK_END) == 0 && ftell(f) == 0L)
        cron_csv_encabezado(f, nreps);
    *out = f;
    return 0;
}

/* Una fila del protocolo. `config` no debe contener comas. */
static inline void cron_csv_fila(FILE *f, const char *config, int hilos, long n,
                                 const double *reps, size_t nreps, double t1)
{
    double mediana = cron_mediana(reps, nreps);
    if (hilos >= 1)
        fprintf(f, "%s,%d,%ld", config, hilos, n);
    else
        fprintf(f, "%s,gpu,%ld", config, n);
    for (size_t i = 0; i < nreps; i++)
        fprintf(f, ",%.6f", reps[i]);
    fprintf(f, ",%.6f", mediana);
    if (t1 > 0.0 && mediana > 0.0) {
        double speedup = t1 / mediana;
        fprintf(f, ",%.3f", speedup);
        if (hilos >= 1)
            fprintf(f, ",%.3f\n", speedup / (double)hilos);
        else
            fputs(",NA\n", f);
    } else {
        fputs(",NA,NA\n", f);
    }
    fflush(f);
}

#endif /* CRONOMETRO_H */
