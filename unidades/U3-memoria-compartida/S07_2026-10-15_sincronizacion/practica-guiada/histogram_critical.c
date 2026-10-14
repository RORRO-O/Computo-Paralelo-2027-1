/*
 * histogram_critical.c — correccion con `critical`.
 *
 * Solo un hilo a la vez ejecuta la region critica, asi que hist[bin]++ ya no
 * se traslapa. Es CORRECTO pero serializa TODAS las actualizaciones, incluso
 * las de bins distintos: los hilos pasan casi todo el tiempo esperando.
 *
 * Uso: ./histogram_critical [n] [nbins]
 */
#include "common.h"

static void histogram_critical(const float *x, long n, int nbins, long *hist)
{
    for (int b = 0; b < nbins; b++) hist[b] = 0;

    #pragma omp parallel for
    for (long i = 0; i < n; i++) {
        int bin = bin_of(x[i], nbins);      /* fuera de la region critica: trabajo privado */
        #pragma omp critical
        hist[bin]++;                        /* un hilo a la vez, para CUALQUIER bin */
    }
}

int main(int argc, char **argv)
{
    long n; int nbins; long *hist_ref; double t_seq;
    float *x = setup_histogram(argc, argv, "critical", &n, &nbins, &hist_ref, &t_seq);
    int wrong = run_histogram_benchmark("critical", histogram_critical, x, n, nbins, hist_ref, t_seq);
    free(x); free(hist_ref);
    return wrong ? 1 : 0;
}
