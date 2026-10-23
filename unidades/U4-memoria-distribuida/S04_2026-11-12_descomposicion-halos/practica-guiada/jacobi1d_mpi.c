/*
 * jacobi1d_mpi.c — Jacobi 1D con descomposición de dominio en MPI.
 *
 * Cada proceso (rango) recibe un BLOQUE CONTIGUO de celdas:
 *     local_n = n / p, más una celda para los primeros (n % p) rangos.
 * Su arreglo local tiene local_n + 2 posiciones. u[1..local_n] son sus celdas;
 * u[0] y u[local_n+1] son las CELDAS FANTASMA (halos): copias de la última celda del vecino
 * izquierdo y de la primera del vecino derecho. En los extremos del dominio no hay vecino
 * (MPI_PROC_NULL) y el halo guarda la frontera física fija (T_LEFT o T_RIGHT).
 *
 * Cada iteración hace tres cosas, en este orden:
 *   1. intercambio de halos:  MPI_Sendrecv  (--exchange sendrecv, por defecto)
 *                              o MPI_Isend / MPI_Irecv / MPI_Waitall  (--exchange isend, con TODO)
 *   2. paso de Jacobi sobre las celdas locales (doble búfer)
 *   3. MPI_Allreduce(MPI_MAX) de la diferencia local: TODOS obtienen el mismo máximo global y
 *      TODOS toman la misma decisión de parar. Si solo uno decidiera, los demás se colgarían.
 * Al final, MPI_Gatherv reconstruye el vector completo en el rango 0 para imprimirlo y
 * compararlo con jacobi1d_seq.
 *
 * Uso:  mpirun -np P ./jacobi1d_mpi [n] [tol] [max_iter] [--print] [--trace K] [--exchange sendrecv|isend]
 *       --print     imprime todas las celdas (índice global, valor), igual que la secuencial
 *       --trace K   en las primeras K iteraciones, cada rango reporta qué envió y qué recibió
 * Compila: mpicc -std=c11 -O2 -Wall -Wextra -o jacobi1d_mpi jacobi1d_mpi.c -lm
 */
#include <math.h>
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define T_LEFT  100.0   /* frontera izquierda fija (celda global 0)   */
#define T_RIGHT   0.0   /* frontera derecha fija (celda global n+1)   */

#define TAG_TO_RIGHT 10 /* mensaje que viaja hacia la derecha: mi última celda → halo izq. del vecino derecho */
#define TAG_TO_LEFT  20 /* mensaje que viaja hacia la izquierda: mi primera celda → halo der. del vecino izquierdo */

#define LINE_LEN 1024   /* tamaño fijo de cada línea de traza (para juntarlas con MPI_Gather) */

enum exchange_mode { EXCHANGE_SENDRECV, EXCHANGE_ISEND };

/* Reparto por bloques con residuo. Devuelve cuántas celdas le tocan al rango y el índice
 * global (base 0, solo interior) de su primera celda. Los primeros (n % p) rangos reciben
 * una celda extra: la diferencia de carga entre rangos nunca pasa de una celda. */
static void block_partition(int n, int p, int rank, int *local_n, int *offset) {
    int base = n / p, rem = n % p;
    *local_n = base + (rank < rem ? 1 : 0);
    *offset  = rank * base + (rank < rem ? rank : rem);
}

/* Intercambio de halos con MPI_Sendrecv: cada llamada envía y recibe a la vez, así que no hay
 * dos envíos "cruzados" esperándose. Con MPI_PROC_NULL como vecino, el envío se descarta y la
 * recepción regresa sin tocar el búfer: por eso el halo de los extremos conserva la frontera. */
static void exchange_halos_sendrecv(double *u, int local_n, int left, int right) {
    /* Paso 1: mi última celda viaja a la derecha; recibo del vecino izquierdo en mi halo izquierdo. */
    MPI_Sendrecv(&u[local_n], 1, MPI_DOUBLE, right, TAG_TO_RIGHT,
                 &u[0],       1, MPI_DOUBLE, left,  TAG_TO_RIGHT,
                 MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    /* Paso 2: mi primera celda viaja a la izquierda; recibo del vecino derecho en mi halo derecho. */
    MPI_Sendrecv(&u[1],           1, MPI_DOUBLE, left,  TAG_TO_LEFT,
                 &u[local_n + 1], 1, MPI_DOUBLE, right, TAG_TO_LEFT,
                 MPI_COMM_WORLD, MPI_STATUS_IGNORE);
}

/* Intercambio de halos sin bloqueo (fase MODIFICAR de la práctica guiada).
 * Patrón: publicar primero las recepciones, luego los envíos, y esperar las cuatro operaciones
 * con MPI_Waitall. Devuelve 1 cuando está implementado; 0 mientras queden TODO. */
static int exchange_halos_isend(double *u, int local_n, int left, int right) {
    MPI_Request reqs[4];
    int done = 0;   /* TODO(4): cambia a 1 cuando los TODO(1)-(3) estén completos */

    /* TODO(1): publica las dos recepciones con MPI_Irecv.
     *   reqs[0]: 1 MPI_DOUBLE en &u[0]           desde left,  etiqueta TAG_TO_RIGHT
     *   reqs[1]: 1 MPI_DOUBLE en &u[local_n + 1] desde right, etiqueta TAG_TO_LEFT  */

    /* TODO(2): publica los dos envíos con MPI_Isend.
     *   reqs[2]: &u[local_n] hacia right con TAG_TO_RIGHT
     *   reqs[3]: &u[1]       hacia left  con TAG_TO_LEFT   */

    /* TODO(3): espera las cuatro operaciones: MPI_Waitall(4, reqs, MPI_STATUSES_IGNORE).
     *   Hasta que Waitall regresa, NO se puede leer u[0] ni u[local_n+1] ni modificar u[1] ni u[local_n]. */

    (void)u; (void)local_n; (void)left; (void)right; (void)reqs;   /* evita warnings mientras haya TODO; borra esta línea al terminar */
    return done;
}

/* Describe a un vecino para la traza. */
static const char *neighbor_name(int r, char *buf, size_t len) {
    if (r == MPI_PROC_NULL) return "nadie (MPI_PROC_NULL)";
    snprintf(buf, len, "rango %d", r);
    return buf;
}

/* Cada rango arma una línea con lo que envió y recibió; el rango 0 las junta con MPI_Gather
 * y las imprime en orden de rango (así la salida es determinista, cosa que printf desde cada
 * proceso no garantiza). */
static void trace_iteration(int iter, int rank, int p, const double *u, int local_n, int offset,
                            int left, int right) {
    char line[LINE_LEN], lb[32], rb[32];
    int  g_first = offset + 1, g_last = offset + local_n;    /* índices globales 1..n */
    snprintf(line, sizeof line,
             "[it %d] rango %d: celdas %d..%d | envia u[%d] a %s y u[%d] a %s | "
             "recibe halo izq u[%d]=%.4f, halo der u[%d]=%.4f\n",
             iter, rank, g_first, g_last,
             g_first, neighbor_name(left, lb, sizeof lb),
             g_last,  neighbor_name(right, rb, sizeof rb),
             g_first - 1, u[0], g_last + 1, u[local_n + 1]);
    char *all = NULL;
    if (rank == 0) all = malloc((size_t)p * LINE_LEN);
    MPI_Gather(line, LINE_LEN, MPI_CHAR, all, LINE_LEN, MPI_CHAR, 0, MPI_COMM_WORLD);
    if (rank == 0) {
        for (int r = 0; r < p; r++) fputs(all + (size_t)r * LINE_LEN, stdout);
        fflush(stdout);
        free(all);
    }
}

int main(int argc, char **argv) {
    MPI_Init(&argc, &argv);
    int rank, p;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &p);

    /* Todos los rangos reciben los mismos argv (SPMD): cada uno los analiza por su cuenta. */
    int    n = 1000000, max_iter = 1000, print = 0, trace = 0;
    double tol = 1e-6;
    enum exchange_mode mode = EXCHANGE_SENDRECV;
    int pos = 0;
    for (int a = 1; a < argc; a++) {
        if (strcmp(argv[a], "--print") == 0) { print = 1; continue; }
        if (strcmp(argv[a], "--trace") == 0 && a + 1 < argc) { trace = (int)strtol(argv[++a], NULL, 10); continue; }
        if (strcmp(argv[a], "--exchange") == 0 && a + 1 < argc) {
            a++;
            if (strcmp(argv[a], "isend") == 0)         mode = EXCHANGE_ISEND;
            else if (strcmp(argv[a], "sendrecv") == 0) mode = EXCHANGE_SENDRECV;
            else { if (rank == 0) fprintf(stderr, "--exchange debe ser sendrecv o isend\n"); MPI_Finalize(); return 1; }
            continue;
        }
        if (pos == 0)      n        = (int)strtol(argv[a], NULL, 10);
        else if (pos == 1) tol      = strtod(argv[a], NULL);
        else if (pos == 2) max_iter = (int)strtol(argv[a], NULL, 10);
        pos++;
    }
    if (n < p || tol <= 0.0 || max_iter < 1) {
        if (rank == 0) fprintf(stderr, "uso: mpirun -np P %s [n>=P] [tol>0] [max_iter>=1] [--print] [--trace K] [--exchange sendrecv|isend]\n", argv[0]);
        MPI_Finalize();
        return 1;
    }

    /* 1. Reparto del dominio y vecinos. */
    int local_n, offset;
    block_partition(n, p, rank, &local_n, &offset);
    int left  = (rank > 0)     ? rank - 1 : MPI_PROC_NULL;
    int right = (rank < p - 1) ? rank + 1 : MPI_PROC_NULL;

    /* 2. Arreglos locales con sus dos halos. calloc deja todo en 0. */
    double *u     = calloc((size_t)local_n + 2, sizeof *u);
    double *u_new = calloc((size_t)local_n + 2, sizeof *u_new);
    if (!u || !u_new) { fprintf(stderr, "rango %d: sin memoria\n", rank); MPI_Abort(MPI_COMM_WORLD, 1); }
    /* Solo los rangos de los extremos tienen frontera física; va en ambos arreglos. */
    if (left  == MPI_PROC_NULL) u[0] = u_new[0] = T_LEFT;
    if (right == MPI_PROC_NULL) u[local_n + 1] = u_new[local_n + 1] = T_RIGHT;

    if (trace > 0) {
        char line[LINE_LEN], lb[32], rb[32];
        snprintf(line, sizeof line, "reparto: rango %d tiene local_n=%d (celdas globales %d..%d); vecino izq: %s; vecino der: %s\n",
                 rank, local_n, offset + 1, offset + local_n,
                 neighbor_name(left, lb, sizeof lb), neighbor_name(right, rb, sizeof rb));
        char *all = (rank == 0) ? malloc((size_t)p * LINE_LEN) : NULL;
        MPI_Gather(line, LINE_LEN, MPI_CHAR, all, LINE_LEN, MPI_CHAR, 0, MPI_COMM_WORLD);
        if (rank == 0) { for (int r = 0; r < p; r++) fputs(all + (size_t)r * LINE_LEN, stdout); free(all); }
    }

    /* 3. Iteración de Jacobi distribuida. */
    MPI_Barrier(MPI_COMM_WORLD);              /* arranque común: el tiempo mide solo el ciclo */
    double t0 = MPI_Wtime();
    int    iter = 0, converged = 0;
    double global_diff = 0.0;
    for (iter = 1; iter <= max_iter; iter++) {
        /* 3a. Halos: sin esto, u[0] y u[local_n+1] serían valores viejos. */
        if (mode == EXCHANGE_SENDRECV) {
            exchange_halos_sendrecv(u, local_n, left, right);
        } else if (!exchange_halos_isend(u, local_n, left, right)) {
            if (rank == 0) printf("TODO pendiente: completa exchange_halos_isend (TODO(1)-(4)) en jacobi1d_mpi.c\n");
            free(u); free(u_new);
            MPI_Finalize();
            return 0;
        }
        if (iter <= trace) trace_iteration(iter, rank, p, u, local_n, offset, left, right);

        /* 3b. Paso de Jacobi local: exactamente la misma expresión que la versión secuencial. */
        double local_diff = 0.0;
        for (int i = 1; i <= local_n; i++) {
            u_new[i] = 0.5 * (u[i - 1] + u[i + 1]);
            double d = fabs(u_new[i] - u[i]);
            if (d > local_diff) local_diff = d;
        }
        double *tmp = u; u = u_new; u_new = tmp;

        /* 3c. Convergencia GLOBAL: la llaman todos; todos reciben el mismo máximo. */
        MPI_Allreduce(&local_diff, &global_diff, 1, MPI_DOUBLE, MPI_MAX, MPI_COMM_WORLD);
        if (global_diff < tol) { converged = 1; break; }
    }
    if (!converged) iter = max_iter;
    double elapsed = MPI_Wtime() - t0;

    /* 4. Reconstrucción en el rango 0 con MPI_Gatherv (bloques de tamaño distinto). */
    int    *counts = NULL, *displs = NULL;
    double *u_all  = NULL;
    if (rank == 0) {
        counts = malloc((size_t)p * sizeof *counts);
        displs = malloc((size_t)p * sizeof *displs);
        u_all  = malloc((size_t)n * sizeof *u_all);
        if (!counts || !displs || !u_all) { fprintf(stderr, "rango 0: sin memoria\n"); MPI_Abort(MPI_COMM_WORLD, 1); }
        for (int r = 0; r < p; r++) block_partition(n, p, r, &counts[r], &displs[r]);
    }
    MPI_Gatherv(&u[1], local_n, MPI_DOUBLE, u_all, counts, displs, MPI_DOUBLE, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        double checksum = 0.0;
        for (int i = 0; i < n; i++) checksum += u_all[i];
        printf("n=%d tol=%.3e max_iter=%d p=%d\n", n, tol, max_iter, p);
        printf("iteraciones=%d convergio=%d\n", iter, converged);
        printf("diff_final=%.6e\n", global_diff);
        printf("checksum=%.12e\n", checksum);
        printf("tiempo_s=%.6f\n", elapsed);
        if (print)
            for (int i = 0; i < n; i++) printf("%d %.15e\n", i + 1, u_all[i]);
        free(counts); free(displs); free(u_all);
    }

    free(u);
    free(u_new);
    MPI_Finalize();
    return 0;
}
