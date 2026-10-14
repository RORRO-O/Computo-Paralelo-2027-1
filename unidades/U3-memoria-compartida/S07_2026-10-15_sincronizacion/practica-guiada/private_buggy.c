/*
 * private_buggy.c — ERROR A PROPOSITO: `private` NO copia el valor inicial.
 *
 * Idea erronea 9: "private(x) copia el valor que x tenia antes de la region".
 * Falso: la copia privada de cada hilo queda SIN INICIALIZAR (leerla es
 * comportamiento indefinido; en la practica sale basura que cambia entre
 * corridas). Para que cada hilo arranque con el valor de afuera se usa
 * firstprivate(x).
 *
 * Caso realista: un generador pseudoaleatorio cuyo estado (`seed`) se
 * inicializa antes de la region y cada hilo lo avanza.
 *   A) secuencial:            referencia.
 *   B) private(seed):         INCORRECTO: cada hilo arranca con basura.
 *   C) firstprivate(seed):    cada hilo arranca con 2026 (todos repiten la
 *                             misma secuencia: correcto segun OpenMP, aunque
 *                             para "azar" por hilo se usaria seed + omp_get_thread_num()).
 *
 * lcg_next esta marcada noinline para imitar una funcion de otro archivo: con
 * ella visible, gcc -Wall avisa "'seed' may be used uninitialized". Ese aviso
 * es un regalo: leelo. En codigo real la funcion vive en otra unidad y no hay aviso.
 */
#include <stdio.h>
#include <omp.h>

#define N 8

/* Avanza el estado del generador y devuelve un valor en [0, 32767]. */
__attribute__((noinline)) static unsigned lcg_next(unsigned *state)
{
    *state = *state * 1103515245u + 12345u;
    return (*state >> 16) & 0x7fffu;
}

static void print_row(const char *label, const unsigned *out)
{
    printf("%-16s", label);
    for (int i = 0; i < N; i++) printf("%3u ", out[i]);
    printf("\n");
}

int main(void)
{
    unsigned out[N];
    unsigned seed = 2026u;

    /* A) Secuencial: la secuencia de referencia a partir de la semilla 2026. */
    for (int i = 0; i < N; i++) out[i] = lcg_next(&seed) % 100;
    print_row("A) secuencial", out);

    /* B) private: cada hilo tiene SU seed, con valor indefinido. */
    seed = 2026u;
    #pragma omp parallel for private(seed)
    for (int i = 0; i < N; i++) {
        out[i] = lcg_next(&seed) % 100;     /* lee seed sin inicializar */
    }
    print_row("B) private", out);

    /* C) firstprivate: cada hilo recibe una copia de seed con el valor 2026. */
    seed = 2026u;
    #pragma omp parallel for firstprivate(seed)
    for (int i = 0; i < N; i++) {
        out[i] = lcg_next(&seed) % 100;
    }
    print_row("C) firstprivate", out);

    printf("seed despues de B y C = %u (las copias privadas no tocan la original)\n", seed);
    printf("hilos=%d; con 4 hilos, cada hilo toma %d iteraciones seguidas\n",
           omp_get_max_threads(), N / 4);
    return 0;
}
