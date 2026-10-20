/*
 * plantilla_main.c — Esqueleto de programa medible para el proyecto integrador.
 * Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1
 *
 * Qué muestra este archivo (es el contrato de los programas de la entrega final,
 * proyecto/entrega-final/README.md §3, el mismo desde H1):
 *   1. Argumentos [n] [semilla] [hilos], todos opcionales y en ese orden; n tiene un valor por defecto.
 *   2. Solo se cronometra la región de interés: ni la preparación de datos, ni la creación del equipo
 *      de hilos, ni la impresión.
 *   3. Salida clave=valor, una por línea: version, n, semilla, hilos, tiempo_s, checksum.
 *      El run_all.sh de la raíz y herramientas/medir_proyecto.sh leen tiempo_s=; las pruebas comparan
 *      checksum= contra la V1 con tolerancia.
 *   4. Código 0 si todo bien; 2 si un argumento no es válido.
 *
 * El mismo archivo compila como V1 (sin -fopenmp) y como V2 (con -fopenmp) sin avisos: el #pragma va
 * dentro de #ifdef _OPENMP. En tu proyecto, v1/main.c no lleva pragmas y v2/main.c sí.
 *
 * Cómo adaptarlo a tu proyecto:
 *   - Sustituye region_de_interes() por tu algoritmo y checksum por tu valor de verificación.
 *   - Si tu problema genera datos, usa la semilla con un generador determinista (el LCG de
 *     proyecto/entrega-final/plantilla-repo/comun/problema.h), nunca rand(): depende de la libc.
 *     Este ejemplo no genera datos: la semilla se acepta y se reporta para cumplir el contrato.
 *   - En V3 (GPU) imprime además tiempo_kernel_s= (sin transferencias) y tiempo_total_s= (con ellas).
 *   - El calentamiento entre procesos lo hacen los scripts de medición (una corrida que no se cuenta).
 *
 * Compilar:  gcc -std=c11 -O2 -Wall -Wextra -fopenmp plantilla_main.c -o plantilla_main.out   (V2)
 *            gcc -std=c11 -O2 -Wall -Wextra plantilla_main.c -o plantilla_sec.out             (V1)
 * Ejecutar:  ./plantilla_main.out 200000000 12345 4
 * Salida (los tiempos cambian con la máquina; esta es de la máquina de autoría, 4 núcleos):
 *   version=plantilla
 *   n=200000000
 *   semilla=12345
 *   hilos=4
 *   tiempo_s=0.086051
 *   checksum=3.141592653590e+00
 */
#define _POSIX_C_SOURCE 200809L
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#ifdef _OPENMP
#include <omp.h>
#endif

/* Reloj de pared. Con -fopenmp usa omp_get_wtime(); compilado sin OpenMP usa CLOCK_MONOTONIC.
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

/* Convierte un argumento a entero sin signo (>= minimo); devuelve 0 si no es válido. */
static int parse_uint(const char *s, unsigned long minimo, unsigned long *out)
{
    char *end = NULL;
    errno = 0;
    unsigned long v = strtoul(s, &end, 10);
    if (errno != 0 || end == s || *end != '\0' || s[0] == '-' || v < minimo) {
        return 0;
    }
    *out = v;
    return 1;
}

/* Región de interés de ejemplo: integra 4/(1+x^2) en [0,1] por punto medio (converge a pi).
 * Sustitúyela por el núcleo de cómputo de tu problema. */
static double region_de_interes(long n)
{
    const double h = 1.0 / (double)n;
    double sum = 0.0;
#ifdef _OPENMP
#pragma omp parallel for default(none) shared(n, h) reduction(+ : sum) schedule(static)
#endif
    for (long i = 0; i < n; i++) {
        double x = h * ((double)i + 0.5);
        sum += 4.0 / (1.0 + x * x);
    }
    return h * sum;
}

int main(int argc, char *argv[])
{
    /* Tamaño por defecto: 0.25 s con un hilo en la máquina de autoría (corre en < 5 s). Para medir, tu
     * tamaño declarado debe dar T(1) >= 1 s (protocolo §2). */
    unsigned long n = 200000000UL;
    unsigned long seed = 12345UL;
    unsigned long threads = 0; /* 0: usa OMP_NUM_THREADS o el valor por defecto del sistema */

    if (argc > 1 && !parse_uint(argv[1], 1, &n)) {
        fprintf(stderr, "error: n inválido: '%s' (entero positivo). Uso: %s [n] [semilla] [hilos]\n", argv[1], argv[0]);
        return 2;
    }
    if (argc > 2 && !parse_uint(argv[2], 0, &seed)) {
        fprintf(stderr, "error: semilla inválida: '%s' (entero sin signo)\n", argv[2]);
        return 2;
    }
    if (argc > 3 && !parse_uint(argv[3], 1, &threads)) {
        fprintf(stderr, "error: hilos inválido: '%s' (entero positivo)\n", argv[3]);
        return 2;
    }

    int used_threads = 1;
#ifdef _OPENMP
    if (threads > 0) {
        omp_set_num_threads((int)threads);
    }
    /* Calentamiento del equipo de hilos FUERA del cronómetro: la primera región paralela crea los hilos
     * (protocolo §2, "calentamiento"). De paso se lee cuántos hay de verdad. */
#pragma omp parallel default(none) shared(used_threads)
    {
#pragma omp single
        used_threads = omp_get_num_threads();
    }
#else
    (void)threads; /* la V1 siempre usa un hilo */
#endif

    /* Aquí iría la preparación de datos (lectura de archivos, reservas, inicialización): NO se cronometra. */

    double t0 = wall_seconds();
    double resultado = region_de_interes((long)n);
    double t1 = wall_seconds();

    /* La impresión tampoco se cronometra. */
    printf("version=plantilla\n");
    printf("n=%lu\n", n);
    printf("semilla=%lu\n", seed);
    printf("hilos=%d\n", used_threads);
    printf("tiempo_s=%.6f\n", t1 - t0);
    printf("checksum=%.12e\n", resultado);
    return 0;
}
