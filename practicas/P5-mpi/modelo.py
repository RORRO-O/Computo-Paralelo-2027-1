#!/usr/bin/env python3
"""modelo.py — Modelo de costo latencia + ancho de banda para la Parte D (calor 1D con halos).

Un paso de tiempo con p procesos:
    T_1(n) = n · t_c
    T_p(n) = (n / p) · t_c  +  T_halo  +  T_allreduce / K
      T_halo      = 2 · (α + bytes / β)        dos mensajes de `bytes` (8: un double) a los vecinos
      T_allreduce ≈ 2 · log2(p) · α            un Allreduce de 1 double (árbol; cota orientativa)
      K           = cada cuántos pasos se revisa la convergencia (check_every); K = 0: sin Allreduce
De ahí:  speedup S = T_1 / T_p;  eficiencia E = S / p;
    n*  = T_com / (t_c · (1 − 1/p))              tamaño a partir del cual S > 1
    n_E = E · p · T_com / (t_c · (1 − E))        tamaño para alcanzar eficiencia E
α y β salen de d_pingpong (tu máquina); t_c de la línea "t_c=... ns por celda-paso" de c_heat_seq.

Uso:
    python3 modelo.py --alpha-us 0.4 --beta-gbps 5 --tc-ns 1.0 --p 4 --n 1000000
    python3 modelo.py --alpha-us 0.4 --beta-gbps 5 --tc-ns 1.0 --p 4 --tabla
    python3 modelo.py ... --check-every 0      (solo halos, sin Allreduce)
"""
import argparse
import math


def t_com(alpha_s, beta_bps, p, msg_bytes=8, check_every=1):
    """Comunicación por paso (segundos) con p procesos."""
    if p == 1:
        return 0.0
    halo = 2.0 * (alpha_s + msg_bytes / beta_bps)
    allreduce = 2.0 * math.log2(p) * alpha_s / check_every if check_every > 0 else 0.0
    return halo + allreduce


def predict(n, p, tc_s, com_s):
    """(T_1, T_p, speedup, eficiencia) por paso."""
    t1 = n * tc_s
    tp = (n / p) * tc_s + com_s
    return t1, tp, t1 / tp, t1 / tp / p


def main():
    ap = argparse.ArgumentParser(description="Modelo de costo para calor 1D distribuido.")
    ap.add_argument("--alpha-us", type=float, required=True, help="latencia alpha en microsegundos (d_pingpong)")
    ap.add_argument("--beta-gbps", type=float, required=True, help="ancho de banda beta en GB/s (d_pingpong)")
    ap.add_argument("--tc-ns", type=float, required=True, help="t_c en ns por celda-paso (c_heat_seq)")
    ap.add_argument("--p", type=int, default=4, help="procesos (4)")
    ap.add_argument("--n", type=int, default=None, help="tamaño a predecir")
    ap.add_argument("--bytes", type=int, default=8, help="bytes por mensaje de halo (8)")
    ap.add_argument("--check-every", type=int, default=1, help="pasos entre Allreduce; 0 = sin Allreduce (1)")
    ap.add_argument("--eff", type=float, default=0.5, help="eficiencia objetivo para n_E (0.5)")
    ap.add_argument("--tabla", action="store_true", help="predicción para varios n")
    a = ap.parse_args()

    alpha, beta, tc = a.alpha_us * 1e-6, a.beta_gbps * 1e9, a.tc_ns * 1e-9
    com = t_com(alpha, beta, a.p, a.bytes, a.check_every)
    print(f"T_com por paso con p = {a.p}: {com * 1e6:.3f} us  "
          f"(halos 2*(alpha + {a.bytes} B/beta) = {2 * (alpha + a.bytes / beta) * 1e6:.3f} us"
          + (f"; Allreduce ~ 2*log2(p)*alpha/K = {(com - 2 * (alpha + a.bytes / beta)) * 1e6:.3f} us)" if a.p > 1 else ")"))
    print(f"t_c = {a.tc_ns:.3f} ns por celda-paso")
    if a.p > 1:
        n_star = com / (tc * (1.0 - 1.0 / a.p))
        n_eff = a.eff * a.p * com / (tc * (1.0 - a.eff))
        print(f"n* (punto de equilibrio, S = 1): {n_star:,.0f} celdas")
        print(f"n_E (eficiencia >= {a.eff:.0%}):      {n_eff:,.0f} celdas")
    if a.n is not None:
        t1, tp, s, e = predict(a.n, a.p, tc, com)
        print(f"n = {a.n:,}: T_1 = {t1 * 1e6:.2f} us/paso, T_{a.p} = {tp * 1e6:.2f} us/paso, "
              f"S = {s:.2f}, E = {e:.0%}, razon computo/comunicacion = {(a.n / a.p) * tc / com if com > 0 else float('inf'):.1f}")
    if a.tabla:
        print(f"{'n':>12} {'T_1(us)':>10} {'T_p(us)':>10} {'S':>6} {'E':>6} {'comp/com':>9}")
        for n in (1000, 3000, 10000, 30000, 100000, 300000, 1000000, 3000000):
            t1, tp, s, e = predict(n, a.p, tc, com)
            ratio = (n / a.p) * tc / com if com > 0 else float("inf")
            print(f"{n:>12,} {t1 * 1e6:>10.2f} {tp * 1e6:>10.2f} {s:>6.2f} {e:>6.0%} {ratio:>9.1f}")


if __name__ == "__main__":
    main()
