/*
 * sum_variants.c — cinco formas CORRECTAS de acumular en paralelo, con medicion.
 *
 * Problema: sumar los n enteros de un arreglo con varios hilos.
 * Versiones: reduction | atomic | critical | lock (omp_lock_t) | local (acumulador
 * por hilo + combinacion final). Todas dan el mismo resultado que la secuencial;
 * difieren en COSTO. Al final se mide tambien una suma en double con reduction
 * para ver que el orden de las operaciones cambia el redondeo (idea erronea 10).
 *
 * Uso: ./sum_variants [n]      (n por defecto: 4 000 000)
 * Protocolo: 1 calentamiento + 5 repeticiones por version; se reporta la mediana.
 * Nota: n es pequeno a proposito (critical y lock tardan ~60 ns por elemento con
 * 4 hilos). Esto compara el COSTO de cada mecanismo, no es una medicion de speedup
 * del protocolo (para eso la version secuencial debe tardar >= 1 s).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>

#define N_REPS 5

typedef long (*sum_fn)(const int *data, long n);

static long sum_seq(const int *data, long n)
{
    long s = 0;
    for (long i = 0; i < n; i++) s += data[i];
    return s;
}

/* 1) reduction: cada hilo acumula en una copia privada; OpenMP combina al final. */
static long sum_reduction(const int *data, long n)
{
    long s = 0;
    #pragma omp parallel for reduction(+:s)
    for (long i = 0; i < n; i++) s += data[i];
    return s;
}

/* 2) atomic: cada actualizacion es una instruccion atomica del procesador. */
static long sum_atomic(const int *data, long n)
{
    long s = 0;
    #pragma omp parallel for
    for (long i = 0; i < n; i++) {
        #pragma omp atomic
        s += data[i];
    }
    return s;
}

/* 3) critical: exclusion mutua de una region arbitraria (aqui, una sola linea). */
static long sum_critical(const int *data, long n)
{
    long s = 0;
    #pragma omp parallel for
    for (long i = 0; i < n; i++) {
        #pragma omp critical
        s += data[i];
    }
    return s;
}

/* 4) candado explicito: igual que critical pero con un objeto que controlamos. */
static long sum_lock(const int *data, long n)
{
    long s = 0;
    omp_lock_t lock;
    omp_init_lock(&lock);
    #pragma omp parallel for
    for (long i = 0; i < n; i++) {
        omp_set_lock(&lock);     /* bloquea hasta obtener el candado */
        s += data[i];
        omp_unset_lock(&lock);   /* libera; si se olvida, el programa se cuelga */
    }
    omp_destroy_lock(&lock);
    return s;
}

/* 5) acumulador local por hilo + una sola combinacion por hilo al final. */
static long sum_local(const int *data, long n)
{
    long s = 0;
    #pragma omp parallel
    {
        long local = 0;          /* privada por alcance: declarada dentro de la region */
        #pragma omp for nowait   /* sin barrera: cada hilo pasa a combinar cuando termina */
        for (long i = 0; i < n; i++) local += data[i];
        #pragma omp atomic       /* una actualizacion compartida por hilo, no por elemento */
        s += local;
    }
    return s;
}

static double median_of(double *t, int k)
{
    for (int i = 1; i < k; i++) {            /* ordenamiento por insercion */
        double v = t[i]; int j = i - 1;
        while (j >= 0 && t[j] > v) { t[j + 1] = t[j]; j--; }
        t[j + 1] = v;
    }
    return (k % 2) ? t[k / 2] : 0.5 * (t[k / 2 - 1] + t[k / 2]);
}

/* Mide una version: calentamiento, N_REPS repeticiones, mediana; verifica el resultado. */
static double measure(const char *name, sum_fn fn, const int *data, long n,
                      long expected, int *ok)
{
    double t[N_REPS];
    long result = fn(data, n);               /* calentamiento (no se cuenta) */
    *ok = 1;
    for (int r = 0; r < N_REPS; r++) {
        double t0 = omp_get_wtime();
        result = fn(data, n);
        t[r] = omp_get_wtime() - t0;
        if (result != expected) *ok = 0;
    }
    double med = median_of(t, N_REPS);
    printf("%-10s %10.4f s   resultado=%ld   %s\n", name, med, result,
           *ok ? "ok" : "INCORRECTO");
    return med;
}

int main(int argc, char **argv)
{
    long n = (argc > 1) ? atol(argv[1]) : 4000000L;
    if (n <= 0) { fprintf(stderr, "Uso: %s [n > 0]\n", argv[0]); return 2; }

    int *data = malloc((size_t)n * sizeof(int));
    if (!data) { fprintf(stderr, "Sin memoria\n"); return 1; }
    unsigned s = 12345u;
    for (long i = 0; i < n; i++) {
        s = s * 1103515245u + 12345u;
        data[i] = (int)((s >> 16) & 1023u);
    }

    int threads = omp_get_max_threads();
    printf("suma de %ld enteros con %d hilos (mediana de %d repeticiones)\n", n, threads, N_REPS);

    int ok, all_ok = 1;
    long expected = sum_seq(data, n);
    double t_seq = measure("secuencial", sum_seq, data, n, expected, &ok);
    const char *names[] = { "reduction", "atomic", "critical", "lock", "local" };
    sum_fn fns[] = { sum_reduction, sum_atomic, sum_critical, sum_lock, sum_local };
    double times[5];
    for (int k = 0; k < 5; k++) {
        times[k] = measure(names[k], fns[k], data, n, expected, &ok);
        all_ok = all_ok && ok;
    }

    printf("\n%-10s %14s %18s\n", "version", "ns/elemento", "tiempo/secuencial");
    printf("%-10s %14.2f %18s\n", "secuencial", 1e9 * t_seq / (double)n, "x1.00");
    for (int k = 0; k < 5; k++)
        printf("%-10s %14.2f %17.2f\n", names[k], 1e9 * times[k] / (double)n, times[k] / t_seq);
    printf("(ns/elemento = tiempo / n: costo medio de cada actualizacion; <1.00 = mas rapido que secuencial)\n");

    /* Suma en punto flotante: mismo conjunto de numeros, distinto orden => distinto redondeo. */
    double dseq = 0.0, dred = 0.0;
    for (long i = 0; i < n; i++) dseq += 1.0 / (double)(i + 1);
    #pragma omp parallel for reduction(+:dred)
    for (long i = 0; i < n; i++) dred += 1.0 / (double)(i + 1);
    double diff = dseq - dred;
    if (diff < 0) diff = -diff;
    int d_ok = diff <= 1e-9 * dseq;          /* tolerancia relativa: asi se compara punto flotante */
    all_ok = all_ok && d_ok;
    printf("\nsuma double secuencial = %.15f\n", dseq);
    printf("suma double reduction  = %.15f\n", dred);
    printf("diferencia absoluta    = %.3e  (%s; tolerancia relativa 1e-9: %s)\n", diff,
           diff == 0.0 ? "identicas esta vez" : "distintas: el orden de suma cambia el redondeo",
           d_ok ? "ok" : "FUERA");

    printf("RESULT sum_variants threads=%d n=%ld status=%s\n", threads, n,
           all_ok ? "OK" : "INCORRECTO");
    free(data);
    return all_ok ? 0 : 1;
}
