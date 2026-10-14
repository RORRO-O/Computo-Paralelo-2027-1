/*
 * plantilla_main.c — Esqueleto de programa medible para el proyecto integrador.
 * Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1
 *
 * Qué muestra este archivo:
 *   1. El tamaño del problema llega por línea de comandos (último argumento) y tiene un valor por defecto.
 *   2. Solo se cronometra la región de interés: ni la preparación de datos ni la impresión.
 *   3. El programa imprime una línea "TIEMPO_S <segundos>"; run_all.sh la lee para llenar el CSV.
 *   4. El resultado se imprime en una línea "RESULTADO <valor>" para que `make test` lo compare.
 *
 * Cómo adaptarlo a tu proyecto:
 *   - Sustituye `region_de_interes()` por tu algoritmo. En V1 no hay pragmas; en V2 agregas OpenMP.
 *   - Conserva el formato de las líneas RESULTADO y TIEMPO_S (una por línea, separadas por un espacio).
 *   - En V3 (GPU) imprime además "TIEMPO_KERNEL_S <segundos>": el tiempo sin transferencias.
 *   - El calentamiento no va aquí: run_all.sh ejecuta el programa una vez más y descarta esa corrida.
 *
 * Compilar:  gcc -std=c11 -O2 -Wall -Wextra -fopenmp plantilla_main.c -o plantilla_main.out
 * Ejecutar:  ./plantilla_main.out 200000000
 * Salida esperada (los tiempos cambian con la máquina):
 *   n 200000000
 *   hilos 4
 *   RESULTADO 3.141592653590
 *   TIEMPO_S 0.112345
 */
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#ifdef _OPENMP
#include <omp.h>
#endif

/* Reloj de pared. Con -fopenmp usa omp_get_wtime(); en una V1 compilada sin OpenMP usa CLOCK_MONOTONIC.
 * Nunca clock(): suma el tiempo de CPU de todos los hilos y hace que un programa paralelo parezca lento. */
static double wall_seconds(void)
{
#ifdef _OPENMP
    return omp_get_wtime();
#else
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + 1e-9 * (double)ts.tv_nsec;
#endif
}

static int max_threads(void)
{
#ifdef _OPENMP
    return omp_get_max_threads();
#else
    return 1;
#endif
}

/* Región de interés de ejemplo: integra 4/(1+x^2) en [0,1] por punto medio (converge a pi).
 * Sustitúyela por el núcleo de cómputo de tu problema. */
static double region_de_interes(long n)
{
    const double h = 1.0 / (double)n;
    double sum = 0.0;
#pragma omp parallel for reduction(+ : sum) schedule(static)
    for (long i = 0; i < n; i++) {
        double x = h * ((double)i + 0.5);
        sum += 4.0 / (1.0 + x * x);
    }
    return h * sum;
}

int main(int argc, char *argv[])
{
    long n = 200000000L; /* tamaño por defecto: ~1 s con un hilo en una laptop reciente */
    if (argc > 1) {
        char *end = NULL;
        n = strtol(argv[argc - 1], &end, 10);
        if (end == argv[argc - 1] || *end != '\0' || n <= 0) {
            fprintf(stderr, "Uso: %s [N]   (N entero positivo; recibido: '%s')\n", argv[0], argv[argc - 1]);
            return 2;
        }
    }

    /* Aquí iría la preparación de datos (lectura de archivos, reservas, inicialización): NO se cronometra. */

    double t0 = wall_seconds();
    double resultado = region_de_interes(n);
    double t1 = wall_seconds();

    /* La impresión tampoco se cronometra. */
    printf("n %ld\n", n);
    printf("hilos %d\n", max_threads());
    printf("RESULTADO %.12f\n", resultado);
    printf("TIEMPO_S %.6f\n", t1 - t0);
    return 0;
}
