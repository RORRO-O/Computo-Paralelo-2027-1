/*
 * false_sharing.c — Falso compartido (*false sharing*): contadores por hilo
 * en un arreglo contiguo, con relleno (*padding*) y en variables locales.
 *
 * Problema: cada hilo cuenta cuántos índices de su parte caen en la casilla 0 y
 * cuántos en la casilla 1 (la casilla sale de un hash del índice). No hay
 * condición de carrera en NINGUNA variante: cada hilo escribe solo en SUS casillas.
 * Lo que cambia es dónde viven esas casillas en memoria:
 *
 *   contiguo   counts[tid*2 + bin]   16 bytes por hilo: 4 hilos caben en UNA línea de caché (64 B)
 *   relleno    counts[tid*8 + bin]   64 bytes por hilo: cada hilo tiene su propia línea
 *   local      local[bin] en la pila  y UNA escritura al arreglo compartido al final
 *
 * Uso: ./false_sharing [n] [archivo.csv]     (n por defecto: 100 000 000)
 *      OMP_NUM_THREADS controla los hilos. Si se da el CSV, agrega filas con el
 *      formato del protocolo (config = contiguo | relleno | local).
 */
#include "common.h"

#define NBINS   2                             /* casillas por hilo */
#define DEFAULT_N 100000000L
#define STRIDE_CONTIG  NBINS                  /* 2 long = 16 B: los hilos comparten línea */
#define STRIDE_PADDED  (CACHE_LINE / (int)sizeof(long))   /* 8 long = 64 B: una línea por hilo */

/* Casilla (0 o 1) de un índice: un hash para que el compilador no pueda predecirla
 * (si siempre fuera la misma casilla, el compilador la guardaría en un registro y
 * el experimento no mediría nada). */
static inline int bin_of(long i)
{
    unsigned u = (unsigned)i * 2654435761u;   /* multiplicación de Knuth */
    return (int)(u >> 31);                    /* bit alto: 0 o 1 */
}

/* Referencia secuencial: sin OpenMP. */
static void count_seq(long n, long *out)
{
    long c[NBINS] = {0, 0};
    for (long i = 0; i < n; i++) c[bin_of(i)]++;
    out[0] = c[0];
    out[1] = c[1];
}

/* Variantes contiguo y relleno: el mismo código; solo cambia `stride`
 * (la distancia en long entre las casillas de un hilo y las del siguiente). */
static void count_shared(long n, long *counts, int stride, long *out)
{
    int p = omp_get_max_threads();
    memset(counts, 0, (size_t)p * (size_t)stride * sizeof(long));
    #pragma omp parallel
    {
        long *mine = counts + omp_get_thread_num() * stride;   /* mis dos casillas */
        #pragma omp for
        for (long i = 0; i < n; i++)
            mine[bin_of(i)]++;        /* cada ++ lee y escribe memoria compartida */
    }
    out[0] = out[1] = 0;
    for (int t = 0; t < p; t++) { out[0] += counts[t * stride]; out[1] += counts[t * stride + 1]; }
}

/* Variante local: acumular en la pila del hilo y escribir una sola vez. */
static void count_local(long n, long *counts, long *out)
{
    int p = omp_get_max_threads();
    memset(counts, 0, (size_t)p * STRIDE_PADDED * sizeof(long));
    #pragma omp parallel
    {
        long local[NBINS] = {0, 0};   /* privada por alcance: vive en la pila de este hilo */
        #pragma omp for nowait
        for (long i = 0; i < n; i++)
            local[bin_of(i)]++;
        long *mine = counts + omp_get_thread_num() * STRIDE_PADDED;
        mine[0] = local[0];           /* una escritura compartida por hilo, no por iteración */
        mine[1] = local[1];
    }
    out[0] = out[1] = 0;
    for (int t = 0; t < p; t++) { out[0] += counts[t * STRIDE_PADDED]; out[1] += counts[t * STRIDE_PADDED + 1]; }
}

int main(int argc, char **argv)
{
    long n = argc > 1 ? atol(argv[1]) : DEFAULT_N;
    const char *csv = argc > 2 ? argv[2] : NULL;
    if (n <= 0) { fprintf(stderr, "Uso: %s [n > 0] [archivo.csv]\n", argv[0]); return 2; }

    int p = omp_get_max_threads();
    /* Un bloque alineado a 64 B: así "relleno" garantiza una línea completa por hilo. */
    long *counts = aligned_alloc(CACHE_LINE, (size_t)p * STRIDE_PADDED * sizeof(long));
    if (!counts) { fprintf(stderr, "Sin memoria\n"); return 1; }

    long ref[NBINS], out[NBINS];
    double times[N_REPS];

    /* 1) Referencia secuencial con el protocolo: calentamiento + 5 repeticiones. */
    for (int r = -1; r < N_REPS; r++) {
        double t0 = now();
        count_seq(n, ref);
        double t = now() - t0;
        if (r >= 0) times[r] = t;
    }
    double t_seq = median_of(times, N_REPS);
    printf("== falso compartido: n=%ld hilos=%d  casillas por hilo=%d  linea de cache=%d B\n",
           n, p, NBINS, CACHE_LINE);
    printf("  %-12s hilos=1  mediana=%.4f s  (min %.4f, max %.4f)  cuentas=%ld/%ld\n",
           "secuencial", t_seq, min_of(times, N_REPS), max_of(times, N_REPS), ref[0], ref[1]);
    if (p == 1) csv_append(csv, "secuencial", 1, n, times, t_seq, t_seq);

    /* 2) Las tres variantes paralelas, mismo protocolo. */
    const char *names[3] = {"contiguo", "relleno", "local"};
    int all_ok = 1;
    for (int v = 0; v < 3; v++) {
        for (int r = -1; r < N_REPS; r++) {
            double t0 = now();
            if (v == 0)      count_shared(n, counts, STRIDE_CONTIG, out);
            else if (v == 1) count_shared(n, counts, STRIDE_PADDED, out);
            else             count_local(n, counts, out);
            double t = now() - t0;
            if (r >= 0) times[r] = t;
        }
        int ok = (out[0] == ref[0] && out[1] == ref[1]);   /* conteos enteros: igualdad exacta */
        all_ok = all_ok && ok;
        report_row(names[v], p, n, times, t_seq, ok);
        csv_append(csv, names[v], p, n, times, median_of(times, N_REPS), t_seq);
    }
    printf("  bytes por hilo: contiguo=%zu  relleno=%zu  -> hilos por linea de 64 B: contiguo=%d  relleno=1\n",
           STRIDE_CONTIG * sizeof(long), STRIDE_PADDED * sizeof(long),
           (int)(CACHE_LINE / (STRIDE_CONTIG * sizeof(long))));
    free(counts);
    return all_ok ? 0 : 1;
}
