/*
 * suma_distribuida.c — Suma de un arreglo repartido entre procesos MPI.
 *
 * No hay un arreglo compartido: cada proceso calcula los elementos de SU
 * parte con element(i), los suma, y el rango 0 combina las sumas parciales
 * recibiéndolas una por una (forma mínima de MPI_Send / MPI_Recv; el
 * detalle de la comunicación punto a punto se ve en la sesión S02).
 *
 * Uso:  mpirun -np P ./suma_distribuida [n] [bloques|ciclico]
 *       n por defecto: 10.  Reparto por defecto: bloques.
 *
 * Reparto por bloques con residuo (q = n / p, r = n % p): los primeros r
 * rangos toman q+1 elementos contiguos y los demás q.
 * Reparto cíclico: el rango k toma k, k+p, k+2p, ...   -> TODO(1)
 */
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Valor del elemento i. Determinista y calculable por cualquier proceso sin
 * comunicación. Valores en [0.0, 99.9]. */
static double element(long long i)
{
    return (double)((i * 7919LL + 13LL) % 1000LL) / 10.0;
}

/* Reparto por bloques: intervalo [start, end) que le toca a 'rank'. */
static void block_range(long long n, int rank, int size,
                        long long *start, long long *end)
{
    long long q = n / size; /* tamaño base del bloque */
    long long r = n % size; /* residuo: un elemento extra a cada uno de los primeros r rangos */
    long long count = q + (rank < r ? 1 : 0);
    /* Los rangos < r empezaron cada uno un elemento "más tarde" que sin residuo */
    *start = (long long)rank * q + (rank < r ? rank : r);
    *end = *start + count;
}

/* Describe los índices propios: la lista completa si son pocos, si no el rango. */
static void describe_indices(char *buf, size_t len, long long first, long long last,
                             long long step, long long count)
{
    if (count == 0) {
        snprintf(buf, len, "{}");
    } else if (count <= 10) {
        size_t used = (size_t)snprintf(buf, len, "{");
        for (long long i = first, k = 0; k < count; i += step, k++)
            used += (size_t)snprintf(buf + used, len - used, "%s%lld", k ? ", " : "", i);
        snprintf(buf + used, len - used, "}");
    } else {
        snprintf(buf, len, "%lld..%lld paso %lld", first, last, step);
    }
}

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    /* Todos los procesos reciben los mismos argumentos de línea de comandos. */
    long long n = (argc > 1) ? atoll(argv[1]) : 10;
    const char *mode = (argc > 2) ? argv[2] : "bloques";
    int cyclic = (strcmp(mode, "ciclico") == 0);
    if (n <= 0 || (!cyclic && strcmp(mode, "bloques") != 0)) {
        if (rank == 0)
            fprintf(stderr, "Uso: %s [n > 0] [bloques|ciclico]\n", argv[0]);
        MPI_Finalize();
        return 1;
    }

    /* Todos arrancan el cronómetro "a la vez": la barrera alinea el inicio. */
    MPI_Barrier(MPI_COMM_WORLD);
    double t_start = MPI_Wtime();

    double local_sum = 0.0;  /* suma de MI parte (cada proceso tiene la suya) */
    long long local_count = 0;
    long long first = 0, last = 0, step = 1;

    if (!cyclic) {
        long long start, end;
        block_range(n, rank, size, &start, &end);
        for (long long i = start; i < end; i++)
            local_sum += element(i);
        local_count = end - start;
        first = start;
        last = end - 1;
    } else {
        /* TODO(1): reparto cíclico. El rango 'rank' debe sumar los elementos
         * rank, rank+size, rank+2*size, ... mientras el índice sea < n.
         * Calcula local_sum y local_count; deja first = rank, step = size y
         * last = el último índice que sí tomaste. Borra las tres líneas
         * siguientes cuando termines. */
        if (rank == 0) printf("TODO pendiente: reparto ciclico (TODO(1))\n");
        MPI_Finalize();
        return 0;
    }

    char indices[128];
    describe_indices(indices, sizeof indices, first, last, step, local_count);
    printf("[rango %d] %s: %lld elementos %s, suma parcial = %.3f\n",
           rank, mode, local_count, indices, local_sum);

    /* Combinación en el rango 0. En los demás rangos 'total' solo vale su parcial. */
    double total = local_sum;
    if (rank != 0) {
        /* Forma mínima: envío 1 double al rango 0 con etiqueta 0. */
        MPI_Send(&local_sum, 1, MPI_DOUBLE, 0, 0, MPI_COMM_WORLD);
    } else {
        for (int src = 1; src < size; src++) {
            double partial;
            /* Recibo 1 double del rango 'src' con etiqueta 0, en orden 1, 2, ... */
            MPI_Recv(&partial, 1, MPI_DOUBLE, src, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            total += partial;
        }
    }
    double t_end = MPI_Wtime();

    if (rank == 0) {
        printf("suma total = %.3f (n = %lld, p = %d, reparto = %s)\n", total, n, size, mode);
        printf("tiempo = %.6f s\n", t_end - t_start);
    }

    MPI_Finalize();
    return 0;
}
