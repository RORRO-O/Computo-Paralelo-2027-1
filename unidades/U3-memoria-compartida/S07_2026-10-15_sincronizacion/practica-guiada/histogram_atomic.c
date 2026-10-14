/*
 * histogram_atomic.c — correccion con `atomic`.
 *
 * `atomic` protege UNA operacion simple sobre UNA posicion de memoria usando
 * instrucciones atomicas del procesador (p. ej. lock add en x86). Dos hilos en
 * bins distintos no se estorban; en el mismo bin, el hardware serializa.
 * Mas barato que critical, pero cada actualizacion sigue pasando por la
 * coherencia de cache entre nucleos.
 *
 * Uso: ./histogram_atomic [n] [nbins]
 */
#include "common.h"

static void histogram_atomic(const float *x, long n, int nbins, long *hist)
{
    for (int b = 0; b < nbins; b++) hist[b] = 0;

    #pragma omp parallel for
    for (long i = 0; i < n; i++) {
        int bin = bin_of(x[i], nbins);
        #pragma omp atomic
        hist[bin]++;                        /* actualizacion atomica de una sola posicion */
    }
}

int main(int argc, char **argv)
{
    long n; int nbins; long *hist_ref; double t_seq;
    float *x = setup_histogram(argc, argv, "atomic", &n, &nbins, &hist_ref, &t_seq);
    int wrong = run_histogram_benchmark("atomic", histogram_atomic, x, n, nbins, hist_ref, t_seq);
    free(x); free(hist_ref);
    return wrong ? 1 : 0;
}
