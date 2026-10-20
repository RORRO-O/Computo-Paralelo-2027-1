/*
 * comun/problema.h · Plantilla del proyecto integrador (Cómputo Paralelo · 6BM1 · 27/1)
 *
 * Qué contiene: lo que comparten V1 (secuencial), V2 (OpenMP) y V3 (GPU): generación
 * determinista de datos a partir de una semilla, suma de verificación (checksum) y el
 * cómputo por elemento. `elemento()` se compila para el anfitrión y para la GPU (CP_HD):
 * el kernel de v3/kernel.cu llama a la MISMA función que la V1, así que `make test` en una
 * máquina sin GPU ya verifica el cómputo por elemento de la V3 ("espejo en CPU",
 * proyecto/README.md §2). En Colab solo falta verificar el mapeo hilo→dato y las copias.
 *
 * QUÉ DEBES CAMBIAR (marcado con "PLANTILLA"):
 *   - El tipo de dato y la generación de entrada si tu problema no es un arreglo de double.
 *   - La función `elemento()`: es un marcador de posición compute-bound. Entregarla tal
 *     cual vale 0 en "Correctitud" de la rúbrica; es solo para que la infraestructura
 *     (Makefile, pruebas, run_all.sh, CSV) funcione desde el primer commit.
 * QUÉ NO DEBES CAMBIAR:
 *   - La firma `checksum()` ni el generador: las pruebas comparan V2 y V3 contra V1
 *     con los mismos datos en cualquier máquina (rand() NO sirve: depende de la libc).
 *
 * Compila como C11 (gcc) y como C++ (nvcc): no uses conversiones implícitas de void*.
 */
#ifndef PROBLEMA_H
#define PROBLEMA_H

#include <math.h>
#include <stddef.h>
#include <stdint.h>

/* Con nvcc, CP_HD = __host__ __device__ (la función existe en CPU y en GPU); con gcc no hace nada. */
#ifdef __CUDACC__
#define CP_HD __host__ __device__
#else
#define CP_HD
#endif

/* Tamaño por defecto: la V1 debe correr en < 5 s en una laptop de 4 núcleos y en >= 1 s
 * para que la medición sea válida (protocolo §2). Ajusta N_DEFAULT a tu problema.
 * Con el marcador de posición, N_DEFAULT e ITER_DEFAULT dan T(1) ≈ 1.3 s en un Xeon de
 * 2.1 GHz (gcc 13, -O2); comprueba el tuyo con ./v1/v1 antes de medir. */
#define N_DEFAULT    4000000u
#define SEED_DEFAULT 12345u
/* PLANTILLA: iteraciones del marcador de posición; sube/baja para calibrar el tiempo. */
#define ITER_DEFAULT 16

/* Generador congruencial lineal de 32 bits (constantes de Numerical Recipes).
 * Devuelve un double en [0, 1). Determinista en cualquier plataforma. */
static inline uint32_t lcg_next(uint32_t *state) {
    *state = (*state) * 1664525u + 1013904223u;
    return *state;
}

static inline double lcg_uniform(uint32_t *state) {
    return (double)lcg_next(state) / 4294967296.0; /* 2^32 */
}

/* Llena a[0..n) con la misma secuencia para la misma semilla. */
static inline void init_input(double *a, size_t n, uint32_t seed) {
    uint32_t state = seed;
    for (size_t i = 0; i < n; ++i) {
        a[i] = lcg_uniform(&state);
    }
}

/* PLANTILLA: cómputo por elemento, deliberadamente costoso (compute-bound) para que el
 * speedup sea visible. Sustitúyelo por tu problema. Si tu problema no es "por elemento"
 * (stencil, matriz, grafo...), reemplaza también los ciclos de v1/main.c, v2/main.c y
 * v3/kernel.cu conservando la salida clave=valor. Conserva CP_HD en lo que use el kernel. */
static inline CP_HD double elemento(double x, int iter) {
    double y = x;
    for (int k = 0; k < iter; ++k) {
        y = sin(y) + cos(0.5 * y) * 0.25;
    }
    return y;
}

/* Suma de verificación. En V2/V3 el orden de la suma cambia el redondeo: por eso las
 * pruebas comparan con tolerancia relativa (tests/run_tests.sh, TOL). */
static inline double checksum(const double *x, size_t n) {
    double s = 0.0;
    for (size_t i = 0; i < n; ++i) {
        s += x[i];
    }
    return s;
}

#endif /* PROBLEMA_H */
