/*
 * common.h — arnés de medición de la sesión S10 (protocolo del curso).
 *
 * Qué hay aquí:
 *   - now():            reloj de pared con omp_get_wtime().
 *   - median_of() etc.: estadísticos de las repeticiones.
 *   - lcg_next():       generador determinista (misma semilla => mismos datos).
 *   - csv_append():     escribe UNA fila con el formato del protocolo
 *                       (herramientas/protocolo-medicion.md, §4):
 *                       config,hilos,n,rep1..rep5,mediana_s,speedup,eficiencia
 *   - report_row():     imprime la fila legible y la línea RESULT que leen las pruebas.
 *
 * El patrón de medición que usan todos los programas de la carpeta es visible
 * en cada .c y es siempre el mismo:
 *
 *     for (int r = -1; r < N_REPS; r++) {     // r = -1 es el calentamiento
 *         double t0 = now();
 *         kernel(...);
 *         double t = now() - t0;
 *         if (r >= 0) times[r] = t;           // el calentamiento no se cuenta
 *     }
 *     double med = median_of(times, N_REPS);  // se reporta la mediana
 *
 * Todo es `static inline` para incluirlo en varios .c sin warnings.
 */
#ifndef COMMON_H
#define COMMON_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <omp.h>

#define N_REPS 5                 /* repeticiones medidas (además de 1 calentamiento) */
#define CACHE_LINE 64            /* bytes por línea de caché en x86-64 (getconf LEVEL1_DCACHE_LINESIZE) */

static inline double now(void) { return omp_get_wtime(); }

/* Mediana de k tiempos (ordena una copia; k es pequeño). */
static inline double median_of(const double *t, int k)
{
    double c[64];
    if (k > 64) k = 64;
    memcpy(c, t, (size_t)k * sizeof(double));
    for (int i = 1; i < k; i++) {
        double v = c[i];
        int j = i - 1;
        while (j >= 0 && c[j] > v) { c[j + 1] = c[j]; j--; }
        c[j + 1] = v;
    }
    return (k % 2) ? c[k / 2] : 0.5 * (c[k / 2 - 1] + c[k / 2]);
}

static inline double min_of(const double *t, int k)
{
    double m = t[0];
    for (int i = 1; i < k; i++) if (t[i] < m) m = t[i];
    return m;
}

static inline double max_of(const double *t, int k)
{
    double m = t[0];
    for (int i = 1; i < k; i++) if (t[i] > m) m = t[i];
    return m;
}

/* Generador congruencial lineal: devuelve un valor en [0, 1) y avanza el estado. */
static inline double lcg_next(unsigned *state)
{
    *state = *state * 1103515245u + 12345u;
    return (double)((*state >> 8) & 0xFFFFFFu) / (double)0x1000000u;
}

/* Comparación con tolerancia relativa (las sumas en double cambian de orden al paralelizar). */
static inline int close_enough(double a, double b, double rel_tol)
{
    double scale = fabs(a) > fabs(b) ? fabs(a) : fabs(b);
    if (scale < 1e-300) return 1;
    return fabs(a - b) <= rel_tol * scale;
}

/* Fracción secuencial estimada de Karp–Flatt: f = (1/S - 1/p) / (1 - 1/p). Para p = 1 no está definida. */
static inline double karp_flatt(double speedup, int p)
{
    if (p <= 1 || speedup <= 0.0) return NAN;
    return (1.0 / speedup - 1.0 / p) / (1.0 - 1.0 / p);
}

/* Agrega una fila al CSV del protocolo. Crea el archivo (con encabezado) si no existe.
 * t_ref es la mediana de la MEJOR versión secuencial: speedup = t_ref / mediana. */
static inline void csv_append(const char *path, const char *config, int threads, long n,
                              const double *times, double median, double t_ref)
{
    if (path == NULL) return;
    FILE *f = fopen(path, "r");
    int need_header = (f == NULL);
    if (f) fclose(f);
    f = fopen(path, "a");
    if (!f) { perror(path); return; }
    if (need_header)
        fprintf(f, "config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia\n");
    double s = t_ref / median;
    fprintf(f, "%s,%d,%ld", config, threads, n);
    for (int r = 0; r < N_REPS; r++) fprintf(f, ",%.6f", times[r]);
    fprintf(f, ",%.6f,%.3f,%.3f\n", median, s, s / threads);
    fclose(f);
}

/* Imprime una fila legible + la línea RESULT (status=OK si el resultado coincide con la referencia). */
static inline void report_row(const char *config, int threads, long n, const double *times,
                              double t_ref, int correct)
{
    double med = median_of(times, N_REPS);
    double s = t_ref / med;
    printf("  %-12s hilos=%d  mediana=%.4f s  (min %.4f, max %.4f)  speedup=%.2f  eficiencia=%.2f  %s\n",
           config, threads, med, min_of(times, N_REPS), max_of(times, N_REPS), s, s / threads,
           correct ? "ok" : "INCORRECTO");
    printf("RESULT config=%s threads=%d n=%ld t_ref=%.6f mediana=%.6f speedup=%.3f eficiencia=%.3f status=%s\n",
           config, threads, n, t_ref, med, s, s / threads, correct ? "OK" : "INCORRECTO");
}

#endif /* COMMON_H */
