/*
 * v2/main.c · V2 memoria compartida (OpenMP) · Plantilla del proyecto integrador
 *
 * Uso:     ./v2 [n] [semilla] [hilos]
 *          hilos   número de hilos OpenMP; si se omite se usa OMP_NUM_THREADS o el
 *                  valor por defecto del sistema.
 * Salida:  clave=valor, mismos campos que V1 (version=v2, hilos=<hilos reales>).
 * Código:  0 si todo bien; 2 si los argumentos son inválidos; 1 si falla la memoria.
 * Ejemplo: ./v2 1000000 7 4        o bien        OMP_NUM_THREADS=4 ./v2 1000000 7
 *
 * Qué se cronometra: SOLO la región paralela (protocolo §2). Reloj: omp_get_wtime().
 * La V2 se compara contra la V1 con la misma semilla (tests/run_tests.sh); si tu
 * problema usa reduction en punto flotante, el checksum difiere en los últimos dígitos:
 * por eso la prueba usa tolerancia relativa.
 *
 * PLANTILLA: sustituye el ciclo marcado por tu versión paralela. Justifica en el reporte
 * el schedule, el alcance de las variables y cualquier sincronización.
 */
#include <errno.h>
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>

#include "problema.h"

static int parse_uint(const char *s, unsigned long *out) {
    char *end = NULL;
    errno = 0;
    unsigned long v = strtoul(s, &end, 10);
    if (errno != 0 || end == s || *end != '\0') {
        return 0;
    }
    *out = v;
    return 1;
}

int main(int argc, char **argv) {
    unsigned long n = N_DEFAULT;
    unsigned long seed = SEED_DEFAULT;
    unsigned long threads = 0;

    if (argc > 1 && !parse_uint(argv[1], &n)) {
        fprintf(stderr, "error: n inválido: %s\n", argv[1]);
        return 2;
    }
    if (argc > 2 && !parse_uint(argv[2], &seed)) {
        fprintf(stderr, "error: semilla inválida: %s\n", argv[2]);
        return 2;
    }
    if (argc > 3 && (!parse_uint(argv[3], &threads) || threads == 0)) {
        fprintf(stderr, "error: hilos inválido: %s\n", argv[3]);
        return 2;
    }
    if (n == 0) {
        fprintf(stderr, "error: n debe ser mayor que 0\n");
        return 2;
    }
    if (threads > 0) {
        omp_set_num_threads((int)threads);
    }

    double *in = (double *)malloc(n * sizeof(double));
    double *out = (double *)malloc(n * sizeof(double));
    if (in == NULL || out == NULL) {
        fprintf(stderr, "error: sin memoria para n=%lu\n", n);
        free(in);
        free(out);
        return 1;
    }
    init_input(in, n, (uint32_t)seed);

    int used_threads = 1;

    /* Calentamiento del equipo de hilos, FUERA del cronómetro: la primera región paralela
     * crea los hilos (protocolo §2, "calentamiento"). De paso se lee cuántos hay. */
#pragma omp parallel default(none) shared(used_threads)
    {
#pragma omp single
        used_threads = omp_get_num_threads();
    }

    /* ---- región de interés: empieza el cronómetro ---- */
    double t0 = omp_get_wtime();
    /* PLANTILLA: aquí va tu cómputo paralelo. schedule(static) porque las iteraciones
     * del marcador de posición son uniformes; cámbialo si las tuyas no lo son y dilo. */
#pragma omp parallel for default(none) shared(in, out, n) schedule(static)
    for (size_t i = 0; i < n; ++i) {
        out[i] = elemento(in[i], ITER_DEFAULT);
    }
    double t1 = omp_get_wtime();
    /* ---- región de interés: termina el cronómetro ---- */

    double cs = checksum(out, n);

    printf("version=v2\n");
    printf("n=%lu\n", n);
    printf("semilla=%lu\n", seed);
    printf("hilos=%d\n", used_threads);
    printf("tiempo_s=%.6f\n", t1 - t0);
    printf("checksum=%.12e\n", cs);

    free(in);
    free(out);
    return 0;
}
