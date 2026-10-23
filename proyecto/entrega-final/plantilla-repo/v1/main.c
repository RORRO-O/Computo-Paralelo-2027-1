/*
 * v1/main.c · V1 secuencial · Plantilla del proyecto integrador
 *
 * Uso:     ./v1 [n] [semilla]
 *          n       tamaño del problema (por defecto N_DEFAULT)
 *          semilla entero sin signo para generar los datos (por defecto SEED_DEFAULT)
 * Salida:  una línea por campo, formato clave=valor (lo leen tests/ y run_all.sh):
 *          version=v1  n=...  semilla=...  hilos=1  tiempo_s=...  checksum=...
 * Código:  0 si todo bien; 2 si los argumentos son inválidos; 1 si falla la memoria.
 * Ejemplo: ./v1 1000000 7
 *
 * Qué se cronometra: SOLO la región de interés (el cómputo). Ni la generación de datos ni
 * la impresión (protocolo §2). Reloj: clock_gettime(CLOCK_MONOTONIC); no uses clock().
 *
 * PLANTILLA: sustituye el ciclo marcado por tu problema. Conserva la salida clave=valor.
 */
#define _POSIX_C_SOURCE 200809L
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "problema.h"

static double wall_seconds(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}

/* Convierte un argumento a entero sin signo; devuelve 0 si no es válido. */
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

    if (argc > 1 && !parse_uint(argv[1], &n)) {
        fprintf(stderr, "error: n inválido: %s\n", argv[1]);
        return 2;
    }
    if (argc > 2 && !parse_uint(argv[2], &seed)) {
        fprintf(stderr, "error: semilla inválida: %s\n", argv[2]);
        return 2;
    }
    if (n == 0) {
        fprintf(stderr, "error: n debe ser mayor que 0\n");
        return 2;
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

    /* ---- región de interés: empieza el cronómetro ---- */
    double t0 = wall_seconds();
    /* PLANTILLA: aquí va tu cómputo secuencial. */
    for (size_t i = 0; i < n; ++i) {
        out[i] = elemento(in[i], ITER_DEFAULT);
    }
    double t1 = wall_seconds();
    /* ---- región de interés: termina el cronómetro ---- */

    double cs = checksum(out, n);

    printf("version=v1\n");
    printf("n=%lu\n", n);
    printf("semilla=%lu\n", seed);
    printf("hilos=1\n");
    printf("tiempo_s=%.6f\n", t1 - t0);
    printf("checksum=%.12e\n", cs);

    free(in);
    free(out);
    return 0;
}
