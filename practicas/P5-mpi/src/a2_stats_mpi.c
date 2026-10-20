/*
 * a2_stats_mpi.c — Parte A.2: estadísticos de un arreglo repartido entre P procesos.
 *
 * El rango 0 genera los n datos (es el único que los tiene completos) y los reparte:
 *   - con MPI_Scatter   si n es múltiplo de p (bloques IGUALES de n/p),
 *   - con MPI_Scatterv  en cualquier caso (bloques distintos: reparto con residuo de common.h).
 * Luego cada rango calcula sobre SU bloque y los resultados se combinan con colectivas:
 *   suma    -> MPI_Reduce (MPI_SUM)   : solo la raíz tiene el total
 *   promedio-> MPI_Bcast              : la raíz lo calcula y lo manda a todos
 *   varianza-> MPI_Allreduce (MPI_SUM): todos terminan con el total
 *   máximo  -> MPI_Allreduce (MPI_MAX): todos terminan con el máximo global
 * Al final el rango 0 recorre el arreglo completo con los mismos ciclos que a2_stats_seq y compara.
 *
 * Uso:  mpirun -np P ./a2_stats_mpi [n] [auto|scatter|scatterv] [reps] [--trace]
 *       n por defecto 10 000 003 (no múltiplo de 2 ni de 4: obliga a Scatterv); modo por defecto auto.
 *       "scatter" FORZADO con n % p != 0 reparte solo p*(n/p) elementos: la verificación lo detecta
 *       (sirve para ver qué se pierde; el programa avisa y termina con código 1).
 *       --trace: cada rango imprime qué recibió y qué valor tiene tras cada colectiva.
 * Compilar: mpicc -std=c11 -O2 -Wall -Wextra -o a2_stats_mpi a2_stats_mpi.c
 */
#include <mpi.h>
#include "common.h"

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    long long n = p5_arg_ll(argc, argv, 0, 10000003LL);
    const char *mode_arg = p5_positional(argc, argv, 1);
    int reps = p5_clamp_reps(p5_arg_ll(argc, argv, 2, 3));
    int trace = p5_has_flag(argc, argv, "--trace");
    if (!mode_arg) mode_arg = "auto";
    int use_scatter;
    if (strcmp(mode_arg, "scatter") == 0) use_scatter = 1;
    else if (strcmp(mode_arg, "scatterv") == 0) use_scatter = 0;
    else if (strcmp(mode_arg, "auto") == 0) use_scatter = (n % size == 0);
    else { n = 0; }
    if (n <= 0) {
        if (rank == 0) fprintf(stderr, "Uso: %s [n > 0] [auto|scatter|scatterv] [reps] [--trace]\n", argv[0]);
        MPI_Finalize();
        return 1;
    }

    /* Reparto: TODOS calculan las cuentas y los desplazamientos de TODOS (son p enteros; cuesta
     * nada y evita mandarlos). Scatterv/Gatherv solo los leen en la raíz, pero tenerlos en todos
     * permite que cada rango sepa qué índices globales le tocaron. */
    int *counts = malloc((size_t)size * sizeof(int));
    int *displs = malloc((size_t)size * sizeof(int));
    if (!counts || !displs) MPI_Abort(MPI_COMM_WORLD, 2);
    for (int k = 0; k < size; k++) {
        long long c, f;
        block_partition(n, size, k, &c, &f);
        counts[k] = (int)c;
        displs[k] = (int)f;
    }
    long long my_count = counts[rank], my_first = displs[rank];
    if (use_scatter) {                 /* MPI_Scatter: bloques iguales de n/p; el residuo NO viaja */
        my_count = n / size;
        my_first = (long long)rank * my_count;
    }
    long long n_used = use_scatter ? (long long)size * (n / size) : n;

    double *data = NULL;
    if (rank == 0) {
        data = p5_alloc(n);
        for (long long i = 0; i < n; i++) data[i] = p5_value(i);
    }
    double *local = p5_alloc(my_count);

    double global_sum = -1.0, mean = -1.0, global_sq = -1.0, global_max = -1.0;
    double t_max[P5_MAX_REPS];
    for (int r = -1; r < reps; r++) { /* r = -1: calentamiento */
        MPI_Barrier(MPI_COMM_WORLD);  /* todos arrancan el cronómetro alineados */
        double t0 = MPI_Wtime();

        /* 1. Repartir. Las dos llamadas las ejecutan TODOS los rangos; en la raíz 'data' es la fuente,
         *    en los demás el argumento 'data' (NULL) se ignora. */
        if (use_scatter)
            MPI_Scatter(data, (int)my_count, MPI_DOUBLE, local, (int)my_count, MPI_DOUBLE, 0, MPI_COMM_WORLD);
        else
            MPI_Scatterv(data, counts, displs, MPI_DOUBLE, local, (int)my_count, MPI_DOUBLE, 0, MPI_COMM_WORLD);

        /* 2. Cómputo local sobre MI bloque (un rango con 0 elementos deja -HUGE_VAL en el máximo local). */
        double local_sum = 0.0, local_max = -HUGE_VAL;
        for (long long i = 0; i < my_count; i++) {
            local_sum += local[i];
            if (local[i] > local_max) local_max = local[i];
        }

        /* 3. Suma total SOLO en la raíz (Reduce). En los demás rangos global_sum no cambia. */
        global_sum = -1.0;
        MPI_Reduce(&local_sum, &global_sum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

        /* 4. El promedio lo calcula la raíz y lo necesitan todos para la varianza: Bcast. */
        if (rank == 0) mean = global_sum / (double)n;
        MPI_Bcast(&mean, 1, MPI_DOUBLE, 0, MPI_COMM_WORLD);

        /* 5. Suma de cuadrados en TODOS (Allreduce) y máximo global en TODOS (Allreduce con MAX). */
        double local_sq = 0.0;
        for (long long i = 0; i < my_count; i++) {
            double d = local[i] - mean;
            local_sq += d * d;
        }
        MPI_Allreduce(&local_sq, &global_sq, 1, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);
        MPI_Allreduce(&local_max, &global_max, 1, MPI_DOUBLE, MPI_MAX, MPI_COMM_WORLD);

        double elapsed = MPI_Wtime() - t0;
        /* El tiempo de la corrida es el del proceso MÁS LENTO: Reduce con MPI_MAX. */
        double slowest = 0.0;
        MPI_Reduce(&elapsed, &slowest, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
        if (r >= 0) t_max[r] = slowest;

        if (trace && r == 0) {
            printf("[rango %d] recibio %lld elementos (indices globales %lld..%lld); suma_local=%.6f max_local=%.6f | "
                   "tras Reduce: suma=%.6f | tras Bcast: promedio=%.6e | tras Allreduce: varianza=%.6e max=%.6f\n",
                   rank, my_count, my_first, my_first + my_count - 1, local_sum, local_max,
                   global_sum, mean, global_sq / (double)n, global_max);
        }
    }

    int ok = 1;
    if (rank == 0) {
        double var = global_sq / (double)n;
        printf("a2_stats_mpi: n=%lld p=%d reparto=%s (n %% p = %lld; elementos por rango:", n, size,
               use_scatter ? "scatter" : "scatterv", n % size);
        if (use_scatter) printf(" %lld x %d", my_count, size);
        else for (int k = 0; k < size; k++) printf(" %d", counts[k]);
        printf(") reps=%d\n", reps);
        if (use_scatter && n_used != n)
            printf("ADVERTENCIA: Scatter forzado con n %% p = %lld: solo viajaron %lld de %lld elementos; "
                   "los ultimos %lld no se contaron\n", n % size, n_used, n, n - n_used);
        printf("global: suma=%.12e max=%.12e promedio=%.12e varianza=%.12e\n", global_sum, global_max, mean, var);

        /* Verificación: mismos ciclos que a2_stats_seq sobre el arreglo completo (la raíz lo tiene). */
        double ref_sum = data[0], ref_max = data[0];
        for (long long i = 1; i < n; i++) {
            ref_sum += data[i];
            if (data[i] > ref_max) ref_max = data[i];
        }
        double ref_mean = ref_sum / (double)n, ref_sq = 0.0;
        for (long long i = 0; i < n; i++) {
            double d = data[i] - ref_mean;
            ref_sq += d * d;
        }
        double ref_var = ref_sq / (double)n;
        ok = p5_close(global_sum, ref_sum, 1e-9) && p5_close(global_max, ref_max, 1e-12)
             && p5_close(mean, ref_mean, 1e-9) && p5_close(var, ref_var, 1e-9);
        double rel = (global_sum - ref_sum) / (ref_sum == 0.0 ? 1.0 : ref_sum);
        printf("verificacion (rango 0 recorre el arreglo completo): %s; dif. rel. suma=%.1e; max %s; "
               "dif. rel. varianza=%.1e\n", ok ? "OK" : "FALLA", fabs(rel),
               global_max == ref_max ? "igual" : "DISTINTO", fabs(var - ref_var) / (ref_var > 0.0 ? ref_var : 1.0));
        printf("nota: la suma distribuida y la secuencial suman en distinto orden; por eso se compara con tolerancia\n");
        p5_print_time_human("Scatter+computo+Reduce+Bcast+Allreduce, max entre rangos", t_max, reps);
        p5_print_time_line(t_max, reps);
        printf("RESULT,a2_stats_mpi,%d,%lld,%s,%.12e,%.12e,%.12e,%.12e,%.6f,%s\n", size, n,
               use_scatter ? "scatter" : "scatterv", global_sum, global_max, mean, var,
               p5_time_stats(t_max, reps).median, ok ? "OK" : "FALLA");
    }

    /* Todos los rangos terminan con el mismo código (el veredicto lo tiene la raíz). */
    MPI_Bcast(&ok, 1, MPI_INT, 0, MPI_COMM_WORLD);
    free(data);
    free(local);
    free(counts);
    free(displs);
    MPI_Finalize();
    return ok ? 0 : 1;
}
