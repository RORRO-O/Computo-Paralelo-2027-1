/*
 * histogram_buggy.c — CONDICION DE CARRERA A PROPOSITO.
 *
 * Histograma de n valores en [0,1) repartidos en nbins. Varios hilos hacen
 * hist[bin]++ sobre el MISMO arreglo compartido sin proteccion. Dos hilos que
 * caen en el mismo bin pueden leer el mismo valor viejo y escribir el mismo
 * valor nuevo: se pierde una cuenta. El total queda por debajo de n y cambia
 * entre repeticiones y entre corridas.
 *
 * Uso: ./histogram_buggy [n] [nbins]      (por defecto 10 000 000 y 64)
 */
#include "common.h"

static void histogram_buggy(const float *x, long n, int nbins, long *hist)
{
    for (int b = 0; b < nbins; b++) hist[b] = 0;

    #pragma omp parallel for
    for (long i = 0; i < n; i++) {
        int bin = bin_of(x[i], nbins);
        hist[bin]++;             /* CARRERA: leer-modificar-escribir sobre memoria compartida */
    }
}

int main(int argc, char **argv)
{
    long n; int nbins; long *hist_ref; double t_seq;
    float *x = setup_histogram(argc, argv, "buggy", &n, &nbins, &hist_ref, &t_seq);
    run_histogram_benchmark("buggy", histogram_buggy, x, n, nbins, hist_ref, t_seq);
    free(x); free(hist_ref);
    return 0;   /* el programa "termina bien" aunque el resultado este mal: por eso hay que verificar */
}
