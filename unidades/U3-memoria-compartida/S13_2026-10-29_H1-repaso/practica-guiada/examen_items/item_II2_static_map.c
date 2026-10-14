/* item_II2_static_map.c — Examen de práctica U3, sección II, ítem 2 (predecir la salida).
 * Compilado y ejecutado para fijar la clave. num_threads(4) fija el equipo como dice el enunciado.
 *   gcc -std=c11 -O2 -Wall -Wextra -fopenmp item_II2_static_map.c -o item_II2_static_map
 *   ./item_II2_static_map
 */
#include <stdio.h>
#include <omp.h>

int main(void)
{
    int owner[12];
    #pragma omp parallel num_threads(4)
    {
        #pragma omp for schedule(static, 2)
        for (int i = 0; i < 12; i++)
            owner[i] = omp_get_thread_num();

        #pragma omp single
        printf("single ejecutado por el hilo %d\n", omp_get_thread_num());
    }
    printf("owner=");
    for (int i = 0; i < 12; i++) printf("%d ", owner[i]);
    printf("\n");
    return 0;
}
