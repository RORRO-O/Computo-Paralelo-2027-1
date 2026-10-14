/*
 * matvec_collectives.c — y = A·x distribuido por filas con CUATRO colectivas.
 *
 *   1. MPI_Scatter : el rango 0 reparte bloques de n/p filas de A a cada rango.
 *   2. MPI_Bcast   : el rango 0 manda el vector x COMPLETO a todos.
 *   3. cómputo local: cada rango calcula sus n/p entradas de y.
 *   4. MPI_Gather  : el rango 0 junta los bloques de y en orden de rango.
 *   (y una MPI_Reduce con MPI_MAX para reportar el tiempo de cómputo más lento.)
 *
 * Regla de oro: las colectivas las llaman TODOS los procesos del comunicador, con
 * argumentos compatibles. Fíjate en que ninguna llamada MPI está dentro de un if (rank == ...).
 *
 * Uso: mpirun -np p ./matvec_collectives [n] [reps] [filas]
 *      n debe ser múltiplo de p (MPI_Scatter reparte bloques IGUALES); para n arbitrario
 *      ve matvec_scatterv.c. 'filas' hace que cada rango imprima su primera fila local.
 */
#include <mpi.h>
#include "matvec_data.h"

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    long long n;
    int reps;
    if (parse_args(argc, argv, &n, &reps) != 0) { MPI_Finalize(); return 1; }
    int show_rows = (argc > 3); /* tercer argumento (cualquiera): imprimir filas locales */

    if (n % size != 0) {
        if (rank == 0)
            printf("n = %lld no es multiplo de p = %d: MPI_Scatter reparte bloques iguales. "
                   "Usa n multiplo de p, o matvec_scatterv para el caso general.\n", n, size);
        MPI_Finalize();
        return 1;
    }
    long long local_n = n / size; /* filas que le tocan a cada rango */

    /* Memoria: el rango 0 tiene A completa y el y completo; TODOS tienen x completo
     * (lo necesitan entero para multiplicar sus filas) y su bloque local de A y de y. */
    double *A = NULL, *y = NULL;
    if (rank == 0) {
        A = alloc_doubles(n * n);
        y = alloc_doubles(n);
        fill_rows(A, 0, n, n);
    }
    double *x = alloc_doubles(n); /* en los rangos != 0 queda en 0.0 hasta el Bcast */
    if (rank == 0) fill_vector(x, n);
    double *A_local = alloc_doubles(local_n * n);
    double *y_local = alloc_doubles(local_n);

    MPI_Barrier(MPI_COMM_WORLD); /* alinea el arranque del cronómetro */
    double t0 = MPI_Wtime();

    /* 1. Repartir filas: el bloque k (filas k·local_n .. (k+1)·local_n − 1) va al rango k.
     *    sendcount y recvcount son POR RANGO: local_n filas × n columnas. */
    MPI_Scatter(A, (int)(local_n * n), MPI_DOUBLE,
                A_local, (int)(local_n * n), MPI_DOUBLE, 0, MPI_COMM_WORLD);
    double t1 = MPI_Wtime();

    /* 2. x completo a todos. La llaman TODOS: en el rango 0 'x' es la fuente; en los
     *    demás es el destino. Mismo búfer, misma cuenta, mismo tipo, misma raíz. */
    MPI_Bcast(x, (int)n, MPI_DOUBLE, 0, MPI_COMM_WORLD);
    double t2 = MPI_Wtime();

    if (show_rows)
        printf("[rango %d] filas globales %lld..%lld; primera fila local empieza: %.0f %.0f %.0f ...; x[0] = %.0f\n",
               rank, rank * local_n, (rank + 1) * local_n - 1,
               A_local[0], A_local[1], A_local[2], x[0]);

    /* 3. Cómputo local, sin comunicación. */
    for (int r = 0; r < reps; r++)
        local_matvec(A_local, x, y_local, local_n, n);
    double t3 = MPI_Wtime();

    /* 4. Juntar y: el bloque del rango k cae en y[k·local_n ..]. Solo el rango 0 recibe. */
    MPI_Gather(y_local, (int)local_n, MPI_DOUBLE,
               y, (int)local_n, MPI_DOUBLE, 0, MPI_COMM_WORLD);
    double t4 = MPI_Wtime();

    /* Tiempo de cómputo del rango más lento: una reducción con MPI_MAX. */
    double t_compute = t3 - t2, t_compute_max = 0.0;
    MPI_Reduce(&t_compute, &t_compute_max, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        printf("n = %lld, p = %d, filas por rango = %lld, reps = %d\n", n, size, local_n, reps);
        print_vector_if_small(y, n);
        printf("checksum = %.6f\n", vector_sum(y, n));
        printf("tiempos (s): scatter = %.6f, bcast = %.6f, calcular = %.6f (max entre rangos), "
               "gather = %.6f, total = %.6f\n",
               t1 - t0, t2 - t1, t_compute_max, t4 - t3, t4 - t0);
    }

    free(A); free(y); free(x); free(A_local); free(y_local);
    MPI_Finalize();
    return 0;
}
