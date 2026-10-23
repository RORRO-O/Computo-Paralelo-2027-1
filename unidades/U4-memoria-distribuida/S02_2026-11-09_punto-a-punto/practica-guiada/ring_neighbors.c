/*
 * ring_neighbors.c — Fase CREAR de la práctica guiada S02: intercambio con
 * los dos vecinos del anillo, en ambas direcciones.
 *
 * Cada rango tiene un arreglo send_buf de n enteros, todos iguales a su rango.
 * Debe:
 *   1. enviar send_buf a su vecino derecho  right = (rank + 1) % size
 *      y recibir en from_left el arreglo del vecino izquierdo left;
 *   2. enviar send_buf a su vecino izquierdo left = (rank - 1 + size) % size
 *      y recibir en from_right el arreglo del vecino derecho right.
 * Al final verifica que from_left contiene el valor 'left' y from_right el
 * valor 'right', e imprime una línea por rango.
 *
 * Restricciones:
 *   - Debe terminar con n = 1 000 000 y con -np 2, 3, 4 y 5 (sin cuelgue).
 *   - Solo comunicación punto a punto (las colectivas son mañana).
 *   - Sin búferes adicionales ni copias intermedias.
 * Pistas: MPI_Sendrecv una vez por dirección, con una etiqueta distinta por
 * dirección; o bien el orden por paridad (cuidado con -np impar: ahí la
 * paridad no alcanza y MPI_Sendrecv es más simple).
 *
 * Criterio de "listo": `make test` marca PASS en los tres casos ring_neighbors.
 *
 * Uso: mpirun -np N ./ring_neighbors [n]   (n por defecto 1000000)
 */
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>

#define TAG_RIGHT 20 /* mensajes que viajan hacia la derecha  */
#define TAG_LEFT 21  /* mensajes que viajan hacia la izquierda */

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    int n = (argc > 1) ? atoi(argv[1]) : 1000000;
    if (n < 1) n = 1;
    int right = (rank + 1) % size;
    int left = (rank - 1 + size) % size;

    if (size == 1) {
        printf("rango 0: soy el unico proceso, no tengo vecinos\n");
        MPI_Finalize();
        return 0;
    }

    int *send_buf = malloc((size_t)n * sizeof(int));
    int *from_left = malloc((size_t)n * sizeof(int));
    int *from_right = malloc((size_t)n * sizeof(int));
    if (send_buf == NULL || from_left == NULL || from_right == NULL) {
        fprintf(stderr, "rango %d: sin memoria para n=%d\n", rank, n);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }
    for (int i = 0; i < n; i++) {
        send_buf[i] = rank;
        from_left[i] = -1;
        from_right[i] = -1;
    }

    int todo_pending = 1; /* ponlo en 0 cuando completes TODO(2) y TODO(3) */
    if (todo_pending) {
        if (rank == 0)
            printf("TODO pendiente: completa TODO(2) y TODO(3) en ring_neighbors.c\n");
        free(send_buf);
        free(from_left);
        free(from_right);
        MPI_Finalize();
        return 0;
    }

    /* TODO(2): intercambio hacia la DERECHA.
     * Envía send_buf (n enteros, TAG_RIGHT) a right y recibe en from_left
     * (n enteros, TAG_RIGHT) lo que envía left.                              */

    /* TODO(3): intercambio hacia la IZQUIERDA.
     * Envía send_buf (n enteros, TAG_LEFT) a left y recibe en from_right
     * (n enteros, TAG_LEFT) lo que envía right.                              */

    /* Verificación (no la modifiques). */
    int errors = 0;
    for (int i = 0; i < n && !errors; i++)
        if (from_left[i] != left || from_right[i] != right) errors = 1;

    if (errors)
        printf("rango %d: ERROR izq=%d der=%d (recibi %d y %d)\n", rank, left, right,
               from_left[0], from_right[0]);
    else
        printf("rango %d: vecinos correctos izq=%d der=%d (n=%d)\n", rank, left, right, n);

    free(send_buf);
    free(from_left);
    free(from_right);
    MPI_Finalize();
    return errors;
}
