/*
 * ejemplo_revision.c — Ejemplo resuelto S13: leer un programa OpenMP como lo pide el examen
 * (alcance de variables, barreras y nowait, reparto static, combinación, medición).
 *
 * Qué hace: a[i] = 2·x[i] − 0.5 y cuenta cuántos a[i] superan el umbral thr = 0.6, con dos ciclos
 * worksharing dentro de UNA región paralela. Los datos son deterministas y calculables a mano:
 * x[i] = ((7·i) mod 11) / 10.
 *
 * Modos:
 *   ./ejemplo_revision [n]          (por defecto n = 16) imprime x, a, el hilo que ejecutó cada
 *                                   iteración en cada ciclo (owner1/owner2), los hits por hilo, el
 *                                   total y la referencia secuencial.
 *   ./ejemplo_revision medir [n]    (por defecto n = 10 000 000) protocolo del curso: 1 calentamiento
 *                                   + 5 repeticiones, mediana, secuencial vs paralelo con los hilos de
 *                                   OMP_NUM_THREADS; speedup, eficiencia y f de Karp–Flatt.
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra -fopenmp -I. ejemplo_revision.c -o ejemplo_revision -lm
 * Variante que falla: -DVARIANTE_FALLA cambia el ciclo 1 a schedule(dynamic, 1): los mapas de hilos
 * de los dos ciclos dejan de coincidir y el nowait se vuelve una carrera (make ejemplo_revision_falla).
 */
#include "common.h"

#define MAX_THREADS 64

static void fill_data(double *x, long n)
{
    for (long i = 0; i < n; i++)
        x[i] = (double)((7 * i) % 11) / 10.0;
}

static long count_hits_seq(const double *x, double *a, long n, double thr)
{
    long hits = 0;
    for (long i = 0; i < n; i++) {
        a[i] = 2.0 * x[i] - 0.5;
        if (a[i] > thr) hits++;
    }
    return hits;
}

/* owner1/owner2/hits_by_thread pueden ser NULL (modo medir). */
static long count_hits_par(const double *x, double *a, long n, double thr,
                           int *owner1, int *owner2, long *hits_by_thread)
{
    long hits = 0;                                    /* compartida: la escriben todos al final */
    #pragma omp parallel firstprivate(thr)            /* copia inicializada de thr en cada hilo */
    {
        int tid = omp_get_thread_num();
        long my_hits = 0;                             /* declarada adentro: privada por alcance */

#ifdef VARIANTE_FALLA
        #pragma omp for schedule(dynamic, 1) nowait   /* VARIANTE QUE FALLA: otro mapeo en el ciclo 1 */
#else
        #pragma omp for schedule(static) nowait       /* ciclo 1: escribe a[i]; sin barrera al final */
#endif
        for (long i = 0; i < n; i++) {
            a[i] = 2.0 * x[i] - 0.5;
            if (owner1) owner1[i] = tid;
        }

        #pragma omp for schedule(static)              /* ciclo 2: lee a[i]; barrera implícita al final */
        for (long i = 0; i < n; i++) {
            if (owner2) owner2[i] = tid;
            if (a[i] > thr) my_hits++;
        }

        if (hits_by_thread && tid < MAX_THREADS) hits_by_thread[tid] = my_hits;
        #pragma omp atomic                            /* una actualización compartida por hilo */
        hits += my_hits;
    }                                                 /* barrera de fin de región: hits completa */
    return hits;
}

static void show_mode(long n)
{
    if (n > 64) n = 64;                               /* el modo "mostrar" es para leer, no para medir */
    double x[64], a[64];
    int owner1[64], owner2[64];
    long hits_by_thread[MAX_THREADS] = {0};
    int nt = omp_get_max_threads();
    if (nt > MAX_THREADS) nt = MAX_THREADS;
    const double thr = 0.6;

    fill_data(x, n);
    long ref = count_hits_seq(x, a, n, thr);
    long hits = count_hits_par(x, a, n, thr, owner1, owner2, hits_by_thread);

    printf("ejemplo_revision: n=%ld hilos=%d thr=%.1f\n", n, nt, thr);
    printf("  i      :"); for (long i = 0; i < n; i++) printf(" %4ld", i);              printf("\n");
    printf("  x[i]   :"); for (long i = 0; i < n; i++) printf(" %4.1f", x[i]);          printf("\n");
    printf("  a[i]   :"); for (long i = 0; i < n; i++) printf(" %4.1f", a[i]);          printf("\n");
    printf("  a>thr  :"); for (long i = 0; i < n; i++) printf(" %4s", a[i] > thr ? "*" : "."); printf("\n");
    printf("  owner1 :"); for (long i = 0; i < n; i++) printf(" %4d", owner1[i]);       printf("\n");
    printf("  owner2 :"); for (long i = 0; i < n; i++) printf(" %4d", owner2[i]);       printf("\n");
    int same = 1;
    for (long i = 0; i < n; i++) if (owner1[i] != owner2[i]) same = 0;
    printf("  mapas iguales en los dos ciclos: %s\n", same ? "si" : "NO");
    printf("  hits por hilo:");
    for (int t = 0; t < nt; t++) printf(" h%d=%ld", t, hits_by_thread[t]);
    printf("\n");
    printf("hits = %ld  (referencia secuencial %ld)  %s\n", hits, ref, hits == ref ? "ok" : "INCORRECTO");
    printf("RESULT program=ejemplo_revision threads=%d n=%ld status=%s\n", nt, n, hits == ref ? "OK" : "INCORRECTO");
}

static void measure_mode(long n)
{
    double *x = alloc_doubles(n), *a = alloc_doubles(n);
    double t_seq[5], t_par[5];
    const double thr = 0.6;
    int nt = omp_get_max_threads();

    fill_data(x, n);
    long ref = count_hits_seq(x, a, n, thr);                      /* calentamiento secuencial */
    for (int r = 0; r < 5; r++) {
        double t0 = omp_get_wtime();
        long h = count_hits_seq(x, a, n, thr);
        t_seq[r] = omp_get_wtime() - t0;
        if (h != ref) printf("  (secuencial inconsistente: %ld)\n", h);
    }
    long hits = count_hits_par(x, a, n, thr, NULL, NULL, NULL);   /* calentamiento paralelo */
    int wrong = (hits != ref);
    for (int r = 0; r < 5; r++) {
        double t0 = omp_get_wtime();
        hits = count_hits_par(x, a, n, thr, NULL, NULL, NULL);
        t_par[r] = omp_get_wtime() - t0;
        if (hits != ref) wrong++;
    }
    double ms = median_of(t_seq, 5), mp = median_of(t_par, 5);
    double lo_s = t_seq[0], hi_s = t_seq[0], lo_p = t_par[0], hi_p = t_par[0];
    for (int r = 1; r < 5; r++) {
        if (t_seq[r] < lo_s) lo_s = t_seq[r];
        if (t_seq[r] > hi_s) hi_s = t_seq[r];
        if (t_par[r] < lo_p) lo_p = t_par[r];
        if (t_par[r] > hi_p) hi_p = t_par[r];
    }
    double S = ms / mp, E = S / nt;
    printf("ejemplo_revision medir: n=%ld hilos=%d  (1 calentamiento + 5 repeticiones, mediana)\n", n, nt);
    printf("  secuencial: mediana %.4f s (min %.4f max %.4f)\n", ms, lo_s, hi_s);
    printf("  paralelo  : mediana %.4f s (min %.4f max %.4f)  speedup=%.2f  eficiencia=%.2f", mp, lo_p, hi_p, S, E);
    if (nt > 1) printf("  karp_flatt_f=%.3f", (1.0 / S - 1.0 / nt) / (1.0 - 1.0 / nt));
    printf("\n");
    printf("RESULT program=ejemplo_revision threads=%d n=%ld reps_incorrectas=%d/6 status=%s\n",
           nt, n, wrong, wrong == 0 ? "OK" : "INCORRECTO");
    free(x);
    free(a);
}

int main(int argc, char **argv)
{
    if (argc > 1 && strcmp(argv[1], "medir") == 0) {
        long n = (argc > 2) ? atol(argv[2]) : 10000000L;
        if (n <= 0) { fprintf(stderr, "Uso: %s medir [n > 0]\n", argv[0]); return 2; }
        measure_mode(n);
    } else {
        long n = (argc > 1) ? atol(argv[1]) : 16;
        if (n <= 0) { fprintf(stderr, "Uso: %s [n > 0] | %s medir [n]\n", argv[0], argv[0]); return 2; }
        show_mode(n);
    }
    return 0;
}
