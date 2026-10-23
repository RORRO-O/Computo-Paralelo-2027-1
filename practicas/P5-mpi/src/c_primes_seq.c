#define _POSIX_C_SOURCE 200809L /* clock_gettime con -std=c11 (debe ir antes de cualquier include) */
/*
 * c_primes_seq.c — Parte C (alternativa): cuenta los primos en [a, b] en UN proceso (referencia).
 *
 * Prueba de primalidad por división (impares hasta la raíz). Solo se prueban los CANDIDATOS impares
 * (el 2 se cuenta aparte): probar pares es trabajo nulo y, repartido, solo estorba. El costo por
 * candidato NO es uniforme: los compuestos salen pronto, los primos recorren hasta sqrt(k), y sqrt(k)
 * crece con k. Por eso un reparto por bloques contiguos desbalancea la carga y el cíclico la empareja.
 *
 * Uso:      ./c_primes_seq [a] [b] [reps]       (por defecto 2 3000000 3)
 * Salida:   primos=<conteo>, líneas TIME,... y RESULT,...
 * Compilar: gcc -std=c11 -O2 -Wall -Wextra -o c_primes_seq c_primes_seq.c -lm
 */
#include "common.h"

/* Primalidad de un candidato IMPAR k >= 3 (división por impares hasta la raíz). */
static int is_prime_odd(long long k)
{
    for (long long d = 3; d * d <= k; d += 2)
        if (k % d == 0) return 0;
    return 1;
}

/* Primer candidato impar >= max(a, 3). */
static long long first_odd_candidate(long long a)
{
    return a < 3 ? 3 : (a | 1);
}

int main(int argc, char **argv)
{
    long long a = p5_arg_ll(argc, argv, 0, 2);
    long long b = p5_arg_ll(argc, argv, 1, 3000000LL);
    int reps = p5_clamp_reps(p5_arg_ll(argc, argv, 2, 3));
    if (a < 0 || b < a) {
        fprintf(stderr, "Uso: %s [a >= 0] [b >= a] [reps]\n", argv[0]);
        return 1;
    }

    long long count = 0, k0 = first_odd_candidate(a);
    double t[P5_MAX_REPS];
    for (int r = -1; r < reps; r++) { /* r = -1: calentamiento */
        double t0 = p5_wtime();
        count = (a <= 2 && 2 <= b) ? 1 : 0;         /* el único primo par */
        for (long long k = k0; k <= b; k += 2) count += is_prime_odd(k);
        if (r >= 0) t[r] = p5_wtime() - t0;
    }

    p5_stats s = p5_time_stats(t, reps);
    printf("c_primes_seq: a=%lld b=%lld (%lld numeros) reps=%d\n", a, b, b - a + 1, reps);
    printf("primos=%lld\n", count);
    printf("%.1f ns por numero del intervalo (%.1f ns por candidato impar)\n", 1e9 * s.median / (double)(b - a + 1),
           b >= k0 ? 1e9 * s.median / (double)((b - k0) / 2 + 1) : 0.0);
    p5_print_time_human("conteo", t, reps);
    p5_print_time_line(t, reps);
    printf("RESULT,c_primes_seq,1,%lld,%lld,%lld,%.6f\n", a, b, count, s.median);
    return 0;
}
