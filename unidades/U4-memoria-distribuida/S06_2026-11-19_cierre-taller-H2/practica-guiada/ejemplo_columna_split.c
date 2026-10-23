/* ejemplo_columna_split.c — Ejemplo resuelto S06 (Unidad IV, cierre)
 *
 * Dos herramientas de MPI que no caben en un solo tipo básico ni en MPI_COMM_WORLD:
 *
 *   Parte A · Tipo derivado. Una matriz N x N guardada por filas (como en C) tiene sus
 *             columnas "salteadas" en memoria. MPI_Type_vector describe esa forma y permite
 *             enviar una columna con UNA llamada, sin copiarla a un arreglo auxiliar.
 *   Parte B · Comunicador. Los procesos se ven como una malla de ROWS filas; MPI_Comm_split
 *             crea un comunicador por fila para hacer colectivas solo entre los de la misma fila.
 *
 * Todo lo que se imprime sale del rango 0 y en orden fijo: los demás le mandan sus datos.
 *
 * Uso:  mpirun -np 4 ./ejemplo_columna_split            (np par >= 2: malla de 2 x np/2)
 *       mpirun -np 4 ./ejemplo_columna_split --sin-commit   (variante que falla, a propósito)
 */
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define N    4      /* la matriz es N x N */
#define ROWS 2      /* filas de la malla de procesos; columnas = np / ROWS */
#define COL  2      /* columna de la matriz que se envía */

int main(int argc, char **argv) {
    int skip_commit = (argc > 1 && strcmp(argv[1], "--sin-commit") == 0);

    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    /* Error clásico que SÍ verificamos: usar el rango como coordenada sin revisar p. */
    if (size < 2 || size % ROWS != 0) {
        if (rank == 0)
            fprintf(stderr, "Uso: mpirun -np <par >= 2> %s [--sin-commit]\n", argv[0]);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }
    const int cols = size / ROWS;

    /* ================= Parte A: la columna COL viaja del rango 0 al rango 1 ================= */

    /* N bloques de 1 double, separados por N doubles (una fila completa): eso es una columna. */
    MPI_Datatype col_t;
    MPI_Type_vector(N, 1, N, MPI_DOUBLE, &col_t);
    if (!skip_commit)
        MPI_Type_commit(&col_t);          /* sin esto el tipo no se puede usar en una comunicación */

    double col[N];                        /* lo que el rango 1 recibe como 4 doubles contiguos */
    double b[N][N];                       /* lo que el rango 1 recibe colocado como columna 1   */
    int part_a_ok = 1;

    if (rank == 0) {
        double a[N][N];
        for (int i = 0; i < N; i++)
            for (int j = 0; j < N; j++)
                a[i][j] = 10.0 * i + j;   /* a[i][j] = "ij": la columna 2 es 2, 12, 22, 32 */

        /* Se envía 1 elemento de tipo "columna" que empieza en a[0][COL]. */
        MPI_Send(&a[0][COL], 1, col_t, 1, 100, MPI_COMM_WORLD);
        MPI_Send(&a[0][COL], 1, col_t, 1, 101, MPI_COMM_WORLD);

        /* El rango 1 devuelve lo que recibió para imprimirlo desde aquí, en orden. */
        MPI_Recv(col, N, MPI_DOUBLE, 1, 102, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        MPI_Recv(&b[0][0], N * N, MPI_DOUBLE, 1, 103, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

        printf("Parte A · columna %d de una matriz %dx%d enviada con MPI_Type_vector(%d, 1, %d, MPI_DOUBLE)\n",
               COL, N, N, N, N);
        printf("  recibida en el rango 1 como %d MPI_DOUBLE contiguos: [", N);
        for (int i = 0; i < N; i++) printf(" %g", col[i]);
        printf(" ]\n");
        printf("  recibida en el rango 1 con el mismo tipo, colocada en la columna 1 de una matriz en ceros:\n");
        for (int i = 0; i < N; i++) {
            printf("   ");
            for (int j = 0; j < N; j++) printf(" %4g", b[i][j]);
            printf("\n");
        }
    } else if (rank == 1) {
        MPI_Status st;
        int count;
        /* Misma firma de tipo (N doubles), distinto acomodo en memoria: contiguo. */
        MPI_Recv(col, N, MPI_DOUBLE, 0, 100, MPI_COMM_WORLD, &st);
        MPI_Get_count(&st, MPI_DOUBLE, &count);
        if (count != N) part_a_ok = 0;

        /* Ahora con el tipo columna: los N doubles caen en b[0][1], b[1][1], b[2][1], b[3][1]. */
        memset(b, 0, sizeof b);
        MPI_Recv(&b[0][1], 1, col_t, 0, 101, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

        for (int i = 0; i < N; i++) {
            if (col[i] != 10.0 * i + COL) part_a_ok = 0;
            for (int j = 0; j < N; j++)
                if (b[i][j] != ((j == 1) ? 10.0 * i + COL : 0.0)) part_a_ok = 0;
        }
        MPI_Send(col, N, MPI_DOUBLE, 0, 102, MPI_COMM_WORLD);
        MPI_Send(&b[0][0], N * N, MPI_DOUBLE, 0, 103, MPI_COMM_WORLD);
    }
    MPI_Type_free(&col_t);                /* el tipo ya no se necesita; liberar es parte del contrato */

    /* ================= Parte B: un comunicador por fila de la malla ================= */

    /* color = fila (los de igual color quedan juntos); key = orden dentro del nuevo comunicador. */
    int color = rank / cols;
    int key   = rank % cols;
    MPI_Comm row_comm;
    MPI_Comm_split(MPI_COMM_WORLD, color, key, &row_comm);

    int row_rank, row_size;
    MPI_Comm_rank(row_comm, &row_rank);
    MPI_Comm_size(row_comm, &row_size);

    /* Colectiva SOLO entre los procesos de mi fila: suma de los rangos mundiales de la fila. */
    int row_sum;
    MPI_Allreduce(&rank, &row_sum, 1, MPI_INT, MPI_SUM, row_comm);

    /* Reunir todo en el rango 0 para imprimir en orden (nada de printf desde cada rango). */
    int info[4] = { rank, color, row_rank, row_sum };
    int *all = (rank == 0) ? malloc(4 * (size_t)size * sizeof(int)) : NULL;
    MPI_Gather(info, 4, MPI_INT, all, 4, MPI_INT, 0, MPI_COMM_WORLD);

    int all_ok = 0;
    MPI_Reduce(&part_a_ok, &all_ok, 1, MPI_INT, MPI_LAND, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        printf("Parte B · malla de %d x %d procesos; MPI_Comm_split(color = rango / %d, key = rango %% %d)\n",
               ROWS, cols, cols, cols);
        for (int r = 0; r < size; r++) {
            int *q = &all[4 * r];
            int first = q[1] * cols;                                   /* primer rango de esa fila */
            int expected = cols * first + cols * (cols - 1) / 2;       /* suma aritmética de la fila */
            printf("  rango %d -> fila %d, rango en la fila %d de %d, suma de rangos de la fila = %d\n",
                   q[0], q[1], q[2], row_size, q[3]);
            if (q[2] != q[0] % cols || q[3] != expected) all_ok = 0;
        }
        printf("VERIFICACION %s\n", all_ok ? "OK" : "FAIL");
        free(all);
    }

    MPI_Comm_free(&row_comm);
    MPI_Finalize();
    return 0;
}
