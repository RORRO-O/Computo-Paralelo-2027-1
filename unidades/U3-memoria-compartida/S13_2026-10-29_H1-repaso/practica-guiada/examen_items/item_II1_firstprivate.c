/* item_II1_firstprivate.c — Examen de práctica U3, sección II, ítem 1 (predecir la salida).
 * Compilado y ejecutado para fijar la clave (examen-practica-U3.md). Se pregunta con 4 hilos y con 1.
 *   gcc -std=c11 -O2 -Wall -Wextra -fopenmp item_II1_firstprivate.c -o item_II1_firstprivate
 *   OMP_NUM_THREADS=4 ./item_II1_firstprivate
 */
#include <stdio.h>
#include <omp.h>

int main(void)
{
    int base = 10;
    int out[8];
    #pragma omp parallel for firstprivate(base) schedule(static)
    for (int i = 0; i < 8; i++) {
        base += i;
        out[i] = base;
    }
    printf("base=%d out=", base);
    for (int i = 0; i < 8; i++) printf("%d ", out[i]);
    printf("\n");
    return 0;
}
