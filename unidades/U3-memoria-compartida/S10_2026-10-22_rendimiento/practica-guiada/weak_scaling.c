/*
 * weak_scaling.c — Escalabilidad fuerte y débil con el mismo núcleo de cómputo.
 *
 *   fuerte: el tamaño total n queda FIJO y crecen los hilos.        S(p) = T(1,n) / T(p,n)
 *   débil:  el tamaño POR HILO queda fijo: n_total = p * n.          E_w(p) = T(1,n) / T(p, p*n)
 *           El "speedup escalado" (Gustafson) es S_w = p * E_w.
 *
 * El núcleo es independiente por elemento y limitado por cómputo (ITERS pasos de un
 * mapa logístico), así que la escalabilidad débil debería ser casi perfecta; lo que la
 * degrada es la sobrecarga de hilos y la competencia por el procesador.
 *
 * Uso: ./weak_scaling [n_por_hilo] [archivo.csv]     (por defecto 1 000 000)
 *      En el CSV: config=fuerte lleva n fijo; config=debil lleva n = p*n_por_hilo, speedup = S_w
 *      y eficiencia = E_w. El protocolo exige DECLARAR que n cambia: por eso va en la columna n.
 */
#include "common.h"

#define DEFAULT_N 1000000L
#define ITERS 64

__attribute__((noinline)) static double work(long i)
{
    double v = (double)(i % 1000 + 1) / 1001.0;
    for (int k = 0; k < ITERS; k++) v = 3.7 * v * (1.0 - v);
    return v;
}

static double kernel_seq(double *out, long n)
{
    double acc = 0.0;
    for (long i = 0; i < n; i++) { out[i] = work(i); acc += out[i]; }
    return acc;
}

static double kernel_par(double *out, long n)
{
    double acc = 0.0;
    #pragma omp parallel for schedule(static) reduction(+:acc)
    for (long i = 0; i < n; i++) { out[i] = work(i); acc += out[i]; }
    return acc;
}

int main(int argc, char **argv)
{
    long n = argc > 1 ? atol(argv[1]) : DEFAULT_N;
    const char *csv = argc > 2 ? argv[2] : NULL;
    if (n <= 0) { fprintf(stderr, "Uso: %s [n_por_hilo > 0] [archivo.csv]\n", argv[0]); return 2; }
    int p = omp_get_max_threads();
    long n_total = n * p;
    double *out = malloc((size_t)n_total * sizeof(double));
    if (!out) { fprintf(stderr, "Sin memoria\n"); return 1; }
    double times[N_REPS];

    /* T(1, n): secuencial con el tamaño de un hilo. */
    double ref_n = 0.0;
    for (int r = -1; r < N_REPS; r++) {
        double t0 = now();
        ref_n = kernel_seq(out, n);
        double t = now() - t0;
        if (r >= 0) times[r] = t;
    }
    double t1n = median_of(times, N_REPS);
    printf("== escalabilidad: n_por_hilo=%ld hilos=%d  ->  fuerte: n=%ld fijo;  debil: n_total=%ld\n", n, p, n, n_total);
    printf("  %-12s hilos=1  n=%ld  mediana=%.4f s\n", "secuencial", n, t1n);
    if (p == 1) csv_append(csv, "secuencial", 1, n, times, t1n, t1n);

    /* Fuerte: T(p, n). */
    double got = 0.0;
    for (int r = -1; r < N_REPS; r++) {
        double t0 = now();
        got = kernel_par(out, n);
        double t = now() - t0;
        if (r >= 0) times[r] = t;
    }
    int ok_strong = close_enough(ref_n, got, 1e-9);
    report_row("fuerte", p, n, times, t1n, ok_strong);
    csv_append(csv, "fuerte", p, n, times, median_of(times, N_REPS), t1n);

    /* Débil: T(p, p*n). La referencia secuencial del tamaño grande se calcula UNA vez, solo para verificar. */
    double ref_total = kernel_seq(out, n_total);
    for (int r = -1; r < N_REPS; r++) {
        double t0 = now();
        got = kernel_par(out, n_total);
        double t = now() - t0;
        if (r >= 0) times[r] = t;
    }
    int ok_weak = close_enough(ref_total, got, 1e-9);
    double tpn = median_of(times, N_REPS);
    double e_weak = t1n / tpn;
    printf("  %-12s hilos=%d  n=%ld  mediana=%.4f s  eficiencia debil E_w=T(1,n)/T(p,pn)=%.2f  speedup escalado=%.2f  %s\n",
           "debil", p, n_total, tpn, e_weak, p * e_weak, ok_weak ? "ok" : "INCORRECTO");
    printf("RESULT config=debil threads=%d n=%ld t_ref=%.6f mediana=%.6f speedup=%.3f eficiencia=%.3f status=%s\n",
           p, n_total, t1n, tpn, p * e_weak, e_weak, ok_weak ? "OK" : "INCORRECTO");
    /* Para que las columnas del CSV signifiquen lo mismo: speedup = S_w = p*T(1,n)/T(p,pn), eficiencia = E_w. */
    csv_append(csv, "debil", p, n_total, times, tpn, p * t1n);

    free(out);
    return (ok_strong && ok_weak) ? 0 : 1;
}
