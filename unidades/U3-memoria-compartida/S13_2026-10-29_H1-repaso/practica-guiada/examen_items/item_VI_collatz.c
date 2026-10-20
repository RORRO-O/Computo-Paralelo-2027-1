/* item_VI_collatz.c — Examen de práctica U3, sección VI (diseño breve): referencia medida para la clave.
 * Para cada k en 1..N calcula la longitud de la secuencia de Collatz, acumula un histograma de
 * longitudes (NB clases) y el máximo. Compara cuatro estrategias con el protocolo del curso
 * (1 calentamiento + 5 repeticiones, mediana) y verifica que todas dan lo mismo que la secuencial.
 *   gcc -std=c11 -O2 -Wall -Wextra -fopenmp -I.. item_VI_collatz.c -o item_VI_collatz -lm
 *   OMP_NUM_THREADS=4 ./item_VI_collatz [N]      (por defecto N = 2 000 000)
 */
#include "common.h"

#define NB 1000

static int collatz_len(long k)
{
    int len = 0;
    while (k != 1) { k = (k & 1) ? 3 * k + 1 : k / 2; len++; }
    return len > NB - 1 ? NB - 1 : len;
}

static void seq_version(long n, long *hist, int *maxlen)
{
    for (int b = 0; b < NB; b++) hist[b] = 0;
    *maxlen = 0;
    for (long k = 1; k <= n; k++) {
        int len = collatz_len(k);
        hist[len]++;
        if (len > *maxlen) *maxlen = len;
    }
}

/* A: static + reducción sobre arreglo. */
static void par_static_reduction(long n, long *hist, int *maxlen)
{
    for (int b = 0; b < NB; b++) hist[b] = 0;
    int mx = 0;
    #pragma omp parallel for schedule(static) reduction(+:hist[:NB]) reduction(max:mx)
    for (long k = 1; k <= n; k++) {
        int len = collatz_len(k);
        hist[len]++;
        if (len > mx) mx = len;
    }
    *maxlen = mx;
}

/* B: dynamic,1024 + reducción sobre arreglo (la respuesta esperada del ítem VI). */
static void par_dynamic_reduction(long n, long *hist, int *maxlen)
{
    for (int b = 0; b < NB; b++) hist[b] = 0;
    int mx = 0;
    #pragma omp parallel for schedule(dynamic, 1024) reduction(+:hist[:NB]) reduction(max:mx)
    for (long k = 1; k <= n; k++) {
        int len = collatz_len(k);
        hist[len]++;
        if (len > mx) mx = len;
    }
    *maxlen = mx;
}

/* C: dynamic,1024 + atomic por elemento sobre el histograma compartido y critical para el máximo.
 * La lectura rápida de mx fuera del critical es `atomic read` (y la escritura, `atomic write`): sin eso
 * sería una carrera aunque el resultado saliera bien (idea 7). El critical solo se paga cuando len supera
 * el máximo visto, que ocurre pocas veces. */
static void par_dynamic_atomic(long n, long *hist, int *maxlen)
{
    for (int b = 0; b < NB; b++) hist[b] = 0;
    int mx = 0;
    #pragma omp parallel for schedule(dynamic, 1024)
    for (long k = 1; k <= n; k++) {
        int len = collatz_len(k);
        #pragma omp atomic
        hist[len]++;
        int seen;
        #pragma omp atomic read
        seen = mx;
        if (len > seen) {
            #pragma omp critical
            {
                if (len > mx) {
                    #pragma omp atomic write
                    mx = len;
                }
            }
        }
    }
    *maxlen = mx;
}

/* D: dynamic,1 + reducción (el costo del chunk pequeño). */
static void par_dynamic1_reduction(long n, long *hist, int *maxlen)
{
    for (int b = 0; b < NB; b++) hist[b] = 0;
    int mx = 0;
    #pragma omp parallel for schedule(dynamic, 1) reduction(+:hist[:NB]) reduction(max:mx)
    for (long k = 1; k <= n; k++) {
        int len = collatz_len(k);
        hist[len]++;
        if (len > mx) mx = len;
    }
    *maxlen = mx;
}

typedef void (*version_fn)(long, long *, int *);

static double measure(version_fn fn, long n, long *hist, int *maxlen)
{
    double t[5];
    fn(n, hist, maxlen);                                  /* calentamiento */
    for (int r = 0; r < 5; r++) {
        double t0 = omp_get_wtime();
        fn(n, hist, maxlen);
        t[r] = omp_get_wtime() - t0;
    }
    return median_of(t, 5);
}

int main(int argc, char **argv)
{
    long n = parse_n(argc, argv, 2000000L);
    long hist_ref[NB], hist[NB];
    int max_ref, mx;
    const char *names[4] = {"A static+reduction", "B dynamic,1024+reduction", "C dynamic,1024+atomic/critical", "D dynamic,1+reduction"};
    version_fn fns[4] = {par_static_reduction, par_dynamic_reduction, par_dynamic_atomic, par_dynamic1_reduction};

    double t_seq = measure(seq_version, n, hist_ref, &max_ref);
    printf("item_VI collatz: N=%ld hilos=%d  secuencial mediana %.4f s  maxlen=%d\n", n, omp_get_max_threads(), t_seq, max_ref);
    int wrong = 0;
    for (int v = 0; v < 4; v++) {
        double t = measure(fns[v], n, hist, &mx);
        int ok = (mx == max_ref) && memcmp(hist, hist_ref, sizeof hist) == 0;
        if (!ok) wrong++;
        printf("  %-32s mediana %.4f s  speedup %.2f  %s\n", names[v], t, t_seq / t, ok ? "ok" : "INCORRECTO");
    }
    print_result("item_VI_collatz", n, wrong, 4);
    return wrong ? 1 : 0;
}
