/*
 * c_primes_mpi.c — Parte C (alternativa): conteo de primos distribuido (ESQUELETO: tú diseñas la parte MPI).
 *
 * Lo que ya está escrito: lectura de argumentos, prueba de primalidad (la misma de c_primes_seq.c),
 * medición con el protocolo (Barrier + Wtime; el tiempo de la corrida va hasta tener el total, máximo
 * entre rangos; el desbalance usa solo el tiempo de TU cómputo local, Reduce MAX y MIN, y el cociente es
 * la mediana de las repeticiones), verificación con --verify, impresión y línea RESULT.
 * Lo que escribes tú: count_primes_local() (reparto de los candidatos entre los rangos, cíclico y por
 * bloques, según `cyclic`) y combine_counts() (combinación del conteo con una colectiva). Restricciones
 * (README, Parte C): el total debe coincidir con c_primes_seq para cualquier [a, b] y cualquier p; el modo
 * "ciclico" debe repartir TRABAJO, no números (cuidado con la paridad: con p par, k = a + rank + j·p le da
 * a la mitad de los rangos puros pares, que cuestan nada; revísalo con --trace); el modo "bloques" debe
 * mostrar el desbalance.
 *
 * Uso:  mpirun -np P ./c_primes_mpi [a] [b] [ciclico|bloques] [reps] [--verify] [--trace]   (2 3000000 ciclico 3)
 * Compilar: mpicc -std=c11 -O2 -Wall -Wextra -o c_primes_mpi c_primes_mpi.c -lm
 */
#include <mpi.h>
#include "common.h"

/* Primalidad de un candidato IMPAR k >= 3 (igual que en c_primes_seq.c). */
static int is_prime_odd(long long k)
{
    for (long long d = 3; d * d <= k; d += 2)
        if (k % d == 0) return 0;
    return 1;
}

/* Primer candidato impar >= max(a, 3). El 2 es el único primo par: cuéntalo aparte (en un solo rango). */
static long long first_odd_candidate(long long a)
{
    return a < 3 ? 3 : (a | 1);
}

/*
 * ===== TU DISEÑO EMPIEZA AQUÍ =====
 * Contrato (no cambies las firmas; main cronometra count_primes_local SOLA, antes de combinar, para que el
 * tiempo de cada rango mida SU trabajo y no la espera en la colectiva):
 *
 * count_primes_local: reparte los candidatos impares k0, k0+2, k0+4, ... (k0 = first_odd_candidate(a)) entre
 *   los `size` rangos, cíclicamente si cyclic != 0 o por bloques contiguos si no (block_partition sobre el
 *   número de candidatos), y cuenta los primos que le tocan a ESTE rango (el 2, si está en [a, b], lo cuenta
 *   un solo rango). Deja en *my_n cuántos candidatos probó. Sin comunicación. Devuelve el conteo local, o -1
 *   mientras no esté implementada: main imprime "TODO pendiente" y termina sin calcular.
 *
 * combine_counts: combina los conteos locales con UNA colectiva (no Send/Recv) y devuelve el total (al menos
 *   en el rango 0; en los demás puede devolver 0). Devuelve -1 mientras no esté implementada.
 */
static long long count_primes_local(long long a, long long b, int cyclic, int rank, int size, long long *my_n)
{
    /* TODO(C1): sustituye este cuerpo por tu reparto. */
    (void)a; (void)b; (void)cyclic; (void)rank; (void)size;
    *my_n = 0;
    return -1;
}

static long long combine_counts(long long local_count, int rank, int size)
{
    /* TODO(C2): sustituye este cuerpo por la combinación (una colectiva). */
    (void)local_count; (void)rank; (void)size;
    return -1;
}
/* ===== TU DISEÑO TERMINA AQUÍ ===== */

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    long long a = p5_arg_ll(argc, argv, 0, 2);
    long long b = p5_arg_ll(argc, argv, 1, 3000000LL);
    const char *mode = p5_positional(argc, argv, 2);
    int reps = p5_clamp_reps(p5_arg_ll(argc, argv, 3, 3));
    int verify = p5_has_flag(argc, argv, "--verify"), trace = p5_has_flag(argc, argv, "--trace");
    if (!mode) mode = "ciclico";
    int cyclic = (strcmp(mode, "ciclico") == 0);
    if (a < 0 || b < a || (!cyclic && strcmp(mode, "bloques") != 0)) {
        if (rank == 0) fprintf(stderr, "Uso: %s [a >= 0] [b >= a] [ciclico|bloques] [reps] [--verify] [--trace]\n", argv[0]);
        MPI_Finalize();
        return 1;
    }

    long long total = 0, local_count = 0, my_n = 0;
    double t_max[P5_MAX_REPS], ratio[P5_MAX_REPS], t_min_last = 0.0, t_max_last = 0.0;
    for (int r = -1; r < reps; r++) { /* r = -1: calentamiento */
        MPI_Barrier(MPI_COMM_WORLD);
        double t0 = MPI_Wtime();
        local_count = count_primes_local(a, b, cyclic, rank, size, &my_n);
        double elapsed = MPI_Wtime() - t0;   /* SOLO el cómputo local de este rango (desbalance) */
        total = combine_counts(local_count, rank, size);
        double t_all = MPI_Wtime() - t0;     /* hasta tener el total: región de interés del protocolo */
        /* ¿Falta implementar algo? Decide la raíz (en los demás rangos `total` puede valer cualquier cosa) y
         * lo comunica, para que todos salgan del ciclo juntos y nadie se quede esperando en una colectiva. */
        int pending = (local_count < 0 || total < 0);
        MPI_Bcast(&pending, 1, MPI_INT, 0, MPI_COMM_WORLD);
        if (pending) break;
        double slowest = 0.0, fastest = 0.0, t_run = 0.0;
        MPI_Reduce(&t_all, &t_run, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
        MPI_Reduce(&elapsed, &slowest, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
        MPI_Reduce(&elapsed, &fastest, 1, MPI_DOUBLE, MPI_MIN, 0, MPI_COMM_WORLD);
        if (r >= 0) {
            t_max[r] = t_run;
            ratio[r] = fastest > 0 ? slowest / fastest : 0.0;
            t_max_last = slowest;
            t_min_last = fastest;
        }
        if (trace && r == 0)
            printf("[rango %d] reparto=%s: %lld candidatos impares, %lld primos, %.4f s\n", rank, mode, my_n, local_count, elapsed);
    }
    int pending = (local_count < 0 || total < 0);
    MPI_Bcast(&pending, 1, MPI_INT, 0, MPI_COMM_WORLD);
    if (pending) {
        if (rank == 0) printf("TODO pendiente: %s (Parte C, alternativa) no esta implementada todavia\n",
                              local_count < 0 ? "count_primes_local" : "combine_counts");
        MPI_Finalize();
        return 0;
    }

    int ok = 1;
    if (rank == 0) {
        p5_stats s = p5_time_stats(t_max, reps);
        double imbalance = p5_time_stats(ratio, reps).median;
        printf("c_primes_mpi: a=%lld b=%lld p=%d reparto=%s reps=%d\n", a, b, size, mode, reps);
        printf("primos=%lld\n", total);
        printf("desbalance: cociente lento/rapido = %.2f (mediana de %d repeticiones; ultima: rango mas lento %.4f s, "
               "mas rapido %.4f s)\n", imbalance, reps, t_max_last, t_min_last);
        const char *verdict = "SIN_VERIFICAR";
        if (verify) {
            long long ref = (a <= 2 && 2 <= b) ? 1 : 0;
            for (long long k = first_odd_candidate(a); k <= b; k += 2) ref += is_prime_odd(k);
            ok = (ref == total);
            verdict = ok ? "OK" : "FALLA";
            printf("verificacion contra conteo secuencial (rango 0): %s (seq=%lld mpi=%lld)\n", verdict, ref, total);
        }
        p5_print_time_human("conteo + combinacion, max entre rangos", t_max, reps);
        p5_print_time_line(t_max, reps);
        printf("RESULT,c_primes_mpi,%d,%lld,%lld,%lld,%.6f,%s,%.2f,%s\n", size, a, b, total, s.median, mode,
               imbalance, verdict);
    }

    /* Todos los rangos terminan con el mismo código (el veredicto lo tiene la raíz). */
    MPI_Bcast(&ok, 1, MPI_INT, 0, MPI_COMM_WORLD);
    MPI_Finalize();
    return ok ? 0 : 1;
}
