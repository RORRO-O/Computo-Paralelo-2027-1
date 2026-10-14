/*
 * private_buggy.c — ERROR A PROPOSITO: `private` no copia el valor inicial.
 *
 * Idea erronea 9: "private(x) copia el valor que x tenia antes de la region".
 * Falso: la copia privada de cada hilo queda SIN INICIALIZAR (leerla es
 * comportamiento indefinido; en la practica sale basura o cero).
 * Para copiar el valor inicial se usa firstprivate(x).
 *
 * El programa calcula out[i] = i + offset con offset = 100 de tres formas:
 *   A) shared (por omision): correcto porque solo se LEE offset.
 *   B) private(offset):      INCORRECTO: offset indefinido dentro de la region.
 *   C) firstprivate(offset): correcto: cada hilo recibe una copia con 100.
 */
#include <stdio.h>
#include <omp.h>

#define N 8

static int check(const int *out, int offset)
{
    int bad = 0;
    for (int i = 0; i < N; i++) if (out[i] != i + offset) bad++;
    return bad;
}

int main(void)
{
    int out[N];
    int offset = 100;

    /* A) offset compartida: todos los hilos leen la misma variable, nadie la escribe. */
    #pragma omp parallel for
    for (int i = 0; i < N; i++) out[i] = i + offset;
    printf("A) shared        : out = {");
    for (int i = 0; i < N; i++) printf("%d%s", out[i], i < N - 1 ? ", " : "");
    printf("}  errores=%d\n", check(out, offset));

    /* B) private: cada hilo tiene SU offset, con valor indefinido. */
    #pragma omp parallel for private(offset)
    for (int i = 0; i < N; i++) out[i] = i + offset;   /* lee una variable sin inicializar */
    printf("B) private       : out = {");
    for (int i = 0; i < N; i++) printf("%d%s", out[i], i < N - 1 ? ", " : "");
    printf("}  errores=%d   <- indefinido (basura o 0, varia)\n", check(out, 100));

    /* C) firstprivate: cada hilo recibe una copia inicializada con 100. */
    #pragma omp parallel for firstprivate(offset)
    for (int i = 0; i < N; i++) out[i] = i + offset;
    printf("C) firstprivate  : out = {");
    for (int i = 0; i < N; i++) printf("%d%s", out[i], i < N - 1 ? ", " : "");
    printf("}  errores=%d\n", check(out, 100));

    printf("offset despues de las tres regiones = %d (las copias privadas no lo tocan)\n", offset);
    return 0;
}
