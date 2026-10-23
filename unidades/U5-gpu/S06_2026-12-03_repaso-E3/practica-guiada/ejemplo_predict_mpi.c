/* ejemplo_predict_mpi.c — Ejemplo resuelto (parte A): cómo se predice la salida de un programa MPI corto.
 *
 * Exactamente 4 procesos. La raíz reparte data[8] en bloques de 2 (MPI_Scatter), cada rango suma su
 * bloque, multiplica su bloque por su rango, MPI_Allreduce suma las sumas locales en TODOS, y
 * MPI_Gather junta los bloques modificados en la raíz.
 *   mpirun --oversubscribe -np 4 ./ejemplo_predict_mpi
 * Preguntas del ejemplo: ¿qué imprime la raíz como "result"? ¿qué vale total en el rango 2?
 * ¿en qué orden salen las cuatro líneas "rango r"? ¿qué pasaría con -np 2 si no estuviera la comprobación?
 */
#include <mpi.h>
#include <stdio.h>

int main(int argc, char **argv) {
    int rank, size;
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    if (size != 4) {                         /* el reparto fijo de 8 = 4 x 2 exige exactamente 4 procesos */
        if (rank == 0) fprintf(stderr, "este ejemplo requiere exactamente 4 procesos (hay %d)\n", size);
        MPI_Finalize();
        return 1;
    }
    int data[8] = {1, 2, 3, 4, 5, 6, 7, 8};  /* solo la raíz lo usa como fuente */
    int local[2], result[8], local_sum, total;

    MPI_Scatter(data, 2, MPI_INT, local, 2, MPI_INT, 0, MPI_COMM_WORLD);   /* rango r recibe data[2r], data[2r+1] */
    local_sum = local[0] + local[1];
    local[0] *= rank;
    local[1] *= rank;
    MPI_Allreduce(&local_sum, &total, 1, MPI_INT, MPI_SUM, MPI_COMM_WORLD); /* todos obtienen la suma global */
    MPI_Gather(local, 2, MPI_INT, result, 2, MPI_INT, 0, MPI_COMM_WORLD);  /* la raíz junta los bloques */

    printf("rango %d: local_sum=%d total=%d\n", rank, local_sum, total);
    if (rank == 0) {
        printf("result=");
        for (int i = 0; i < 8; i++) printf("%d%s", result[i], i < 7 ? " " : "\n");
    }
    MPI_Finalize();
    return 0;
}
