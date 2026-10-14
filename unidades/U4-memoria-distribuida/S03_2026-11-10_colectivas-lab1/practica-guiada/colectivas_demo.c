/*
 * colectivas_demo.c — Las siete colectivas de la sesión en un solo programa, con enteros
 * chicos para poder predecir cada salida a mano. Pensado para -np 4; funciona con cualquier p.
 *
 *   MPI_Bcast      raíz → todos, el mismo dato
 *   MPI_Scatter    raíz → todos, un bloque DISTINTO a cada uno
 *   MPI_Gather     todos → raíz, un bloque de cada uno, en orden de rango
 *   MPI_Reduce     todos → raíz, combinados con una operación (SUM, MAX, ...)
 *   MPI_Allreduce  como Reduce, pero el resultado queda en TODOS
 *   MPI_Allgather  como Gather, pero el resultado queda en TODOS
 *   MPI_Barrier    nadie sale hasta que todos llegaron
 *
 * Regla de oro: todas las llaman TODOS los procesos del comunicador. Aquí ninguna llamada
 * MPI está dentro de un if (rank == ...). El orden de las líneas entre rangos no está
 * garantizado (cada proceso imprime cuando el sistema lo programa).
 *
 * Uso: mpirun -np 4 ./colectivas_demo
 */
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>

/* Escribe {a, b, c, ...} en buf (para imprimir arreglos chicos). */
static void format_ints(char *buf, size_t cap, const int *v, int count)
{
    size_t used = (size_t)snprintf(buf, cap, "{");
    for (int i = 0; i < count && used < cap; i++)
        used += (size_t)snprintf(buf + used, cap - used, i ? ", %d" : "%d", v[i]);
    if (used < cap) snprintf(buf + used, cap - used, "}");
}

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    char text[256];

    /* ---- Bcast: solo el rango 0 tiene el valor; después lo tienen todos ---- */
    int n = (rank == 0) ? 42 : -1;
    MPI_Bcast(&n, 1, MPI_INT, 0, MPI_COMM_WORLD);
    printf("[rango %d] Bcast: n = %d\n", rank, n);

    /* ---- Scatter: el rango 0 tiene 2p enteros (1..2p); cada rango recibe 2 ---- */
    int *data = NULL;
    if (rank == 0) {
        data = malloc((size_t)(2 * size) * sizeof(int));
        if (!data) MPI_Abort(MPI_COMM_WORLD, 2);
        for (int i = 0; i < 2 * size; i++) data[i] = i + 1;
    }
    int chunk[2] = {-1, -1};
    MPI_Scatter(data, 2, MPI_INT, chunk, 2, MPI_INT, 0, MPI_COMM_WORLD);
    printf("[rango %d] Scatter: mi bloque = {%d, %d}\n", rank, chunk[0], chunk[1]);

    /* ---- Gather: cada rango aporta v² (v = rango + 1); SOLO el rango 0 recibe el arreglo ---- */
    int v = rank + 1, sq = v * v;
    int *squares = malloc((size_t)size * sizeof(int));
    if (!squares) MPI_Abort(MPI_COMM_WORLD, 2);
    for (int i = 0; i < size; i++) squares[i] = -1; /* para ver quién lo llena y quién no */
    MPI_Gather(&sq, 1, MPI_INT, squares, 1, MPI_INT, 0, MPI_COMM_WORLD);
    format_ints(text, sizeof text, squares, size);
    printf("[rango %d] Gather: squares = %s\n", rank, text);

    /* ---- Reduce: SUM y MAX de v; SOLO el rango 0 recibe el resultado ---- */
    int sum = -1, max = -1;
    MPI_Reduce(&v, &sum, 1, MPI_INT, MPI_SUM, 0, MPI_COMM_WORLD);
    MPI_Reduce(&v, &max, 1, MPI_INT, MPI_MAX, 0, MPI_COMM_WORLD);
    printf("[rango %d] Reduce: sum = %d, max = %d\n", rank, sum, max);

    /* ---- Allreduce: lo mismo, pero el resultado queda en TODOS ---- */
    int all_sum = -1;
    MPI_Allreduce(&v, &all_sum, 1, MPI_INT, MPI_SUM, MPI_COMM_WORLD);
    printf("[rango %d] Allreduce: sum = %d\n", rank, all_sum);

    /* ---- Allgather: como Gather, pero el arreglo queda en TODOS ---- */
    for (int i = 0; i < size; i++) squares[i] = -1;
    MPI_Allgather(&sq, 1, MPI_INT, squares, 1, MPI_INT, MPI_COMM_WORLD);
    format_ints(text, sizeof text, squares, size);
    printf("[rango %d] Allgather: squares = %s\n", rank, text);

    /* ---- Barrier: sincroniza el AVANCE (nadie pasa hasta que todos llegan); no ordena la salida ---- */
    MPI_Barrier(MPI_COMM_WORLD);
    printf("[rango %d] Barrier: todos llegaron, sigo\n", rank);

    free(data);
    free(squares);
    MPI_Finalize();
    return 0;
}
