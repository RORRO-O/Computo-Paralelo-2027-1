/*
 * counter_buggy.c — CONDICION DE CARRERA A PROPOSITO (no copiar este patron).
 *
 * Dos ciclos paralelos actualizan una variable compartida sin proteccion:
 *   (1) count++            (contador)
 *   (2) sum += data[i]     (suma de un arreglo)
 * Ambos son leer-modificar-escribir sobre memoria compartida: una carrera de datos
 * (data race). El resultado es no determinista: cambia entre corridas, entre
 * numeros de hilos y entre niveles de optimizacion (-O0 vs -O2).
 *
 * Uso: ./counter_buggy [n]      (n por defecto: 10 000 000)
 * Diagnostico: make tsan   (ThreadSanitizer senala la linea exacta)
 */
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

int main(int argc, char **argv)
{
    long n = (argc > 1) ? atol(argv[1]) : 10000000L;
    if (n <= 0) { fprintf(stderr, "Uso: %s [n > 0]\n", argv[0]); return 2; }

    /* Datos deterministas: enteros pequenos en [0, 1023]. */
    int *data = malloc((size_t)n * sizeof(int));
    if (!data) { fprintf(stderr, "Sin memoria\n"); return 1; }
    unsigned s = 12345u;
    for (long i = 0; i < n; i++) {
        s = s * 1103515245u + 12345u;
        data[i] = (int)((s >> 16) & 1023u);
    }
    long expected_sum = 0;
    for (long i = 0; i < n; i++) expected_sum += data[i];

    /* (1) Contador compartido sin proteccion. */
    long count = 0;
    #pragma omp parallel for
    for (long i = 0; i < n; i++) {
        count++;                 /* CARRERA: leer count, sumar 1, escribir count */
    }

    /* (2) Suma compartida sin proteccion. */
    long sum = 0;
    #pragma omp parallel for
    for (long i = 0; i < n; i++) {
        sum += data[i];          /* CARRERA: misma secuencia leer-modificar-escribir */
    }

    printf("hilos=%d n=%ld\n", omp_get_max_threads(), n);
    printf("count = %ld  (esperado %ld)  %s\n", count, n,
           count == n ? "coincide (¡no significa que no haya carrera!)" : "INCORRECTO");
    printf("sum   = %ld  (esperado %ld)  %s\n", sum, expected_sum,
           sum == expected_sum ? "coincide (¡no significa que no haya carrera!)" : "INCORRECTO");
    free(data);
    return 0;
}
