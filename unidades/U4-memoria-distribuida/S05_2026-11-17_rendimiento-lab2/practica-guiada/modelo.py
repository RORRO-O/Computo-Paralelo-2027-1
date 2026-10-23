#!/usr/bin/env python3
"""modelo.py — Modelo de costo para Jacobi 1D con p procesos.

Modelo de una iteración:
    T_1(n) = n * t_c
    T_p(n) = (n / p) * t_c + T_halo,   T_halo = 2 * (alpha + bytes / beta)
donde t_c es el tiempo por punto, alpha la latencia, beta el ancho de banda
y `bytes` el tamaño de cada mensaje de halo (8 bytes: un double).
Se cuentan los dos mensajes en serie: es una cota superior razonable.

Da la predicción de speedup/eficiencia para un n dado, y los tamaños críticos:
    n*   = T_halo / (t_c * (1 - 1/p))          (punto de equilibrio, S = 1)
    n_E  = E * p * T_halo / (t_c * (1 - E))    (n para alcanzar eficiencia E)

Uso:
    python3 modelo.py --alpha-us 0.5 --beta-gbps 5 --tc-ns 0.9 --p 4 --n 1000000
    python3 modelo.py --alpha-us 0.5 --beta-gbps 5 --tc-ns 0.9 --p 4 --tabla
"""
import argparse


def t_halo(alpha_s, beta_bps, msg_bytes=8, n_msgs=2):
    """Costo de comunicación por iteración (segundos)."""
    return n_msgs * (alpha_s + msg_bytes / beta_bps)


def predict(n, p, tc_s, halo_s):
    """Regresa (T_1, T_p, speedup, eficiencia) por iteración."""
    t1 = n * tc_s
    tp = (n / p) * tc_s + (halo_s if p > 1 else 0.0)
    s = t1 / tp
    return t1, tp, s, s / p


def n_break_even(p, tc_s, halo_s):
    return halo_s / (tc_s * (1.0 - 1.0 / p))


def n_for_efficiency(p, tc_s, halo_s, eff):
    return eff * p * halo_s / (tc_s * (1.0 - eff))


def main():
    ap = argparse.ArgumentParser(description="Modelo de costo latencia + ancho de banda para Jacobi 1D.")
    ap.add_argument("--alpha-us", type=float, required=True, help="latencia alpha en microsegundos (ping-pong)")
    ap.add_argument("--beta-gbps", type=float, required=True, help="ancho de banda beta en GB/s (ping-pong)")
    ap.add_argument("--tc-ns", type=float, required=True, help="tiempo por punto-iteración en ns (jacobi_seq)")
    ap.add_argument("--p", type=int, default=4, help="número de procesos (por defecto 4)")
    ap.add_argument("--n", type=int, default=None, help="tamaño del problema a predecir")
    ap.add_argument("--bytes", type=int, default=8, help="bytes por mensaje de halo (por defecto 8)")
    ap.add_argument("--eff", type=float, default=0.5, help="eficiencia objetivo para n_E (por defecto 0.5)")
    ap.add_argument("--tabla", action="store_true", help="imprime predicción para varios n")
    args = ap.parse_args()

    alpha = args.alpha_us * 1e-6
    beta = args.beta_gbps * 1e9
    tc = args.tc_ns * 1e-9
    halo = t_halo(alpha, beta, args.bytes)

    print(f"T_halo por iteración = 2*(alpha + {args.bytes} B/beta) = {halo*1e6:.3f} us")
    print(f"t_c = {args.tc_ns:.3f} ns por punto;  p = {args.p}")
    nbe = n_break_even(args.p, tc, halo)
    neff = n_for_efficiency(args.p, tc, halo, args.eff)
    print(f"n* (punto de equilibrio, S=1):      {nbe:,.0f} puntos")
    print(f"n_E (eficiencia >= {args.eff:.0%}):            {neff:,.0f} puntos")

    if args.n is not None:
        t1, tp, s, e = predict(args.n, args.p, tc, halo)
        print(f"n = {args.n:,}: T_1 = {t1*1e6:.2f} us/iter, T_{args.p} = {tp*1e6:.2f} us/iter, "
              f"S = {s:.2f}, E = {e:.0%}, razón cómputo/comunicación = {(args.n/args.p)*tc/halo:.1f}")

    if args.tabla:
        print(f"{'n':>12} {'T_1(us)':>10} {'T_p(us)':>10} {'S':>6} {'E':>6} {'comp/comm':>10}")
        for n in (1000, 3000, 10000, 30000, 100000, 300000, 1000000, 3000000):
            t1, tp, s, e = predict(n, args.p, tc, halo)
            print(f"{n:>12,} {t1*1e6:>10.2f} {tp*1e6:>10.2f} {s:>6.2f} {e:>6.0%} {(n/args.p)*tc/halo:>10.1f}")


if __name__ == "__main__":
    main()
