/* a_histogram_buggy.c — Parte A: el histograma CON CARRERA, para observarla (no para usarla).
 * Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · Práctica 4
 *
 * Uso:  ./a_histogram_buggy [n] [nbins]      (OMP_NUM_THREADS y REPS como en a_histogram)
 *
 * hist[b]++ sobre el arreglo compartido sin protección: leer, sumar 1, escribir; otro hilo puede meterse
 * entre los tres pasos. El total queda por DEBAJO de n (se pierden actualizaciones) y cambia entre
 * repeticiones. Con el trabajo de Box–Muller entre actualización y actualización los choques son menos
 * frecuentes que en S07, así que a veces sale bien: eso no la hace correcta (idea errónea 7). Es
 * comportamiento indefinido en C; existe solo para verla con ThreadSanitizer (make tsan) y compararla.
 */
#include "a_hist.h"

static void hist_buggy(const float *u, long n, int nbins, long *hist)
{
    for (int b = 0; b < nbins; b++) hist[b] = 0;
    #pragma omp parallel for
    for (long i = 0; i < n; i++)
        hist[hist_bin(u, i, nbins)]++;     /* CARRERA: leer-modificar-escribir sobre memoria compartida */
}

int main(int argc, char **argv)
{
    int reps = p4_reps();
    long n; int nbins; long *ref; double t_seq, t_seq_reps[P4_MAX_REPS];
    float *u = hist_setup(argc, argv, 1, &n, &nbins, &ref, &t_seq, t_seq_reps, reps);
    printf("a_histogram_buggy: n=%ld nbins=%d hilos=%d reps=%d  (secuencial: %.4f s)\n",
           n, nbins, omp_get_max_threads(), reps, t_seq);
    int wrong = hist_benchmark("buggy", hist_buggy, u, n, nbins, ref, t_seq, reps, 1);
    printf("repeticiones incorrectas: %d de %d%s\n", wrong, reps,
           wrong ? "" : "  (0 no demuestra nada: la carrera sigue ahi; compruebalo con make tsan)");
    free(u); free(ref);
    return wrong ? 1 : 0;
}
