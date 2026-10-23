/*
 * histogram_local.c — correccion con histograma LOCAL por hilo + combinacion final.
 *
 * Cada hilo cuenta en su propio arreglo (privado por alcance: se declara dentro
 * de la region paralela). No hay memoria compartida en el ciclo caliente, asi
 * que no hay nada que proteger. Al final, cada hilo suma su arreglo al global
 * dentro de UNA region critica: nbins actualizaciones protegidas por hilo, en
 * lugar de n. Es el mismo patron que usa `reduction`, hecho a mano.
 *
 * Uso: ./histogram_local [n] [nbins]
 */
#include "common.h"

static void histogram_local(const float *x, long n, int nbins, long *hist)
{
    for (int b = 0; b < nbins; b++) hist[b] = 0;

    #pragma omp parallel
    {
        /* Declarada DENTRO de la region: cada hilo tiene la suya (no hace falta private). */
        long *local = calloc((size_t)nbins, sizeof(long));

        #pragma omp for nowait              /* sin barrera: quien termina, combina */
        for (long i = 0; i < n; i++) {
            local[bin_of(x[i], nbins)]++;   /* memoria privada: sin carrera */
        }

        #pragma omp critical                /* combinacion: nbins sumas por hilo */
        for (int b = 0; b < nbins; b++) hist[b] += local[b];

        free(local);
    }
}

int main(int argc, char **argv)
{
    long n; int nbins; long *hist_ref; double t_seq;
    float *x = setup_histogram(argc, argv, "local", &n, &nbins, &hist_ref, &t_seq);
    int wrong = run_histogram_benchmark("local", histogram_local, x, n, nbins, hist_ref, t_seq);
    free(x); free(hist_ref);
    return wrong ? 1 : 0;
}
