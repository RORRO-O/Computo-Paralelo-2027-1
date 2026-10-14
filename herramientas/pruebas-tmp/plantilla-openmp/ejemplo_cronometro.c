/* ejemplo_cronometro.c — Ejemplo de uso de cronometro.h: medir una región, repetir, mediana y fila CSV.
 * Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · herramientas/
 *
 * Problema de juguete: pi por la regla del punto medio sobre 4/(1+x^2) con n rectángulos. Con -fopenmp el
 * ciclo se reparte entre OMP_NUM_THREADS hilos (reduction); sin -fopenmp el mismo archivo es la versión
 * secuencial de referencia (así lo compila el Makefile: ejemplo_cronometro_seq.out).
 *
 * Uso:
 *   ./ejemplo_cronometro.out [n] [reps] [archivo.csv] [t1_s]
 *     n            rectángulos (por defecto 20000000; con 4 núcleos la versión secuencial tarda < 0.1 s)
 *     reps         repeticiones cronometradas dentro del programa (por defecto 1). Con reps >= 2 se hace
 *                  además una corrida de calentamiento que no se cuenta. Con reps = 1 no hay calentamiento
 *                  interno: medir.sh ya lo hace ejecutando el programa una vez más.
 *     archivo.csv  si se da, agrega una fila del protocolo (config "ejemplo") al CSV; crea el encabezado
 *                  si el archivo no existe.
 *     t1_s         tiempo de la mejor versión secuencial, para calcular speedup y eficiencia en la fila;
 *                  si se omite, esas columnas quedan en NA.
 *
 * Salida (clave=valor, una por línea): n=, hilos=, reps=, resultado=, tiempo_s= (mediana de las reps),
 * y con reps >= 2 también tiempo_min_s= y tiempo_max_s=. Código de salida 0; 2 si los argumentos no sirven.
 *
 * Ejemplos ejecutables (después de `make`):
 *   ./ejemplo_cronometro.out                              # una corrida con el tamaño por defecto
 *   OMP_NUM_THREADS=4 ./ejemplo_cronometro.out 100000000 5 pruebas.csv 0.95
 *   ./medir.sh -c openmp -t "1 2 4" -n 100000000 -o mediciones.csv -- ./ejemplo_cronometro.out
 */
#include "cronometro.h" /* primero: define _POSIX_C_SOURCE para clock_gettime sin -fopenmp */

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef _OPENMP
#include <omp.h>
#endif

#define N_POR_DEFECTO 20000000L

/* Región de interés: es lo único que se cronometra. El #ifdef evita el aviso -Wunknown-pragmas cuando el
 * mismo archivo se compila sin -fopenmp como versión secuencial de referencia. */
static double calcular_pi(long n)
{
    const double h = 1.0 / (double)n;
    double sum = 0.0;
    long i;
#ifdef _OPENMP
#pragma omp parallel for reduction(+ : sum) schedule(static)
#endif
    for (i = 0; i < n; i++) {
        double x = ((double)i + 0.5) * h;
        sum += 4.0 / (1.0 + x * x);
    }
    return sum * h;
}

static int leer_long(const char *texto, long minimo, long *valor)
{
    char *fin = NULL;
    errno = 0;
    long v = strtol(texto, &fin, 10);
    if (errno != 0 || fin == texto || *fin != '\0' || v < minimo)
        return 1;
    *valor = v;
    return 0;
}

int main(int argc, char **argv)
{
    long n = N_POR_DEFECTO;
    long reps = 1;
    const char *ruta_csv = NULL;
    double t1 = 0.0;

    if (argc > 1 && leer_long(argv[1], 1, &n) != 0) {
        fprintf(stderr, "n debe ser un entero >= 1 (recibí '%s')\n", argv[1]);
        return 2;
    }
    if (argc > 2 && leer_long(argv[2], 1, &reps) != 0) {
        fprintf(stderr, "reps debe ser un entero >= 1 (recibí '%s')\n", argv[2]);
        return 2;
    }
    if (argc > 3)
        ruta_csv = argv[3];
    if (argc > 4) {
        char *fin = NULL;
        t1 = strtod(argv[4], &fin);
        if (fin == argv[4] || *fin != '\0' || t1 <= 0.0) {
            fprintf(stderr, "t1_s debe ser un número > 0 (recibí '%s')\n", argv[4]);
            return 2;
        }
    }

    int hilos = 1;
#ifdef _OPENMP
    hilos = omp_get_max_threads();
#endif

    double *tiempos = (double *)calloc((size_t)reps, sizeof(double));
    if (tiempos == NULL) {
        fprintf(stderr, "sin memoria para %ld repeticiones\n", reps);
        return 2;
    }

    double pi = 0.0;
    if (reps >= 2)
        pi = calcular_pi(n); /* calentamiento: cachés, creación de hilos; no se cuenta */

    for (long r = 0; r < reps; r++) {
        double t0 = cron_ahora();
        pi = calcular_pi(n);
        tiempos[r] = cron_ahora() - t0;
    }

    double mediana = cron_mediana(tiempos, (size_t)reps);
    printf("n=%ld\n", n);
    printf("hilos=%d\n", hilos);
    printf("reps=%ld\n", reps);
    printf("resultado=%.12f\n", pi);
    cron_imprimir_tiempo(mediana);
    if (reps >= 2) {
        printf("tiempo_min_s=%.6f\n", cron_minimo(tiempos, (size_t)reps));
        printf("tiempo_max_s=%.6f\n", cron_maximo(tiempos, (size_t)reps));
    }

    if (ruta_csv != NULL) {
        FILE *f = NULL;
        if (cron_csv_abrir(ruta_csv, (size_t)reps, &f) != 0) {
            fprintf(stderr, "no pude abrir %s para escribir\n", ruta_csv);
            free(tiempos);
            return 2;
        }
        cron_csv_fila(f, "ejemplo", hilos, n, tiempos, (size_t)reps, t1);
        fclose(f);
        printf("csv=%s\n", ruta_csv);
    }

    free(tiempos);
    return 0;
}
