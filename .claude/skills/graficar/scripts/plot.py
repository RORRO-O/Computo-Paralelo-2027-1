#!/usr/bin/env python3
"""plot.py — Respaldo de herramientas/graficar_speedup.py: mismo CSV del protocolo, mismas salidas.

Uso: python3 plot.py resultados/mediciones.csv [--salida CARPETA] [--titulo TEXTO] [--n N] [--base CONFIG]
                                                 [--recalcular] [--prefijo P] [--amdahl] [--nproc K]
Entrada: config,hilos,n,rep1..repR,mediana_s,speedup,eficiencia (las columnas extra se ignoran).
Salida: <prefijo>speedup.png y <prefijo>eficiencia.png en CARPETA (por defecto la del CSV) y la tabla Markdown en
pantalla con mediana, mín, máx, speedup, eficiencia y f de Karp–Flatt. Código 0 si generó las dos imágenes; 1 si no.
Speedup y eficiencia: se usan las columnas del CSV si son numéricas; si están en NA o se pasa --recalcular, se
calculan con T(1) = mediana de la fila hilos=1 de --base CONFIG (o la primera fila hilos=1 de ese n) y E = S/p.
"""
import argparse
import csv
import os
import re
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

PALETA = ["#2a78d6", "#eb6834", "#1baf7a", "#eda100", "#e87ba4", "#008300", "#6250d6", "#e34948"]
MARCAS = ["o", "s", "D", "^", "v", "P", "X", "*"]


def num(x):
    try:
        v = float(str(x).strip())
    except (TypeError, ValueError):
        return None
    return v if v == v else None


def leer(ruta):
    with open(ruta, newline="", encoding="utf-8") as fh:
        lector = csv.DictReader(fh)
        cols = [c.strip() for c in (lector.fieldnames or [])]
        faltan = [c for c in ("config", "hilos", "n", "mediana_s") if c not in cols]
        if faltan:
            sys.exit(f"{ruta}: faltan las columnas {faltan}; encabezado esperado: config,hilos,n,rep1..repR,mediana_s,speedup,eficiencia")
        reps = sorted((c for c in cols if re.fullmatch(r"rep\d+", c)), key=lambda c: int(c[3:]))
        filas = []
        for k, f in enumerate(lector, start=2):
            f = {(a or "").strip(): (b or "").strip() for a, b in f.items() if a is not None}
            med = num(f.get("mediana_s"))
            if med is None or med <= 0:
                print(f"AVISO: fila {k} sin mediana_s válida; se omite.", file=sys.stderr); continue
            try:
                n = int(float(f.get("n", "")))
            except ValueError:
                print(f"AVISO: fila {k} sin n numérico; se omite.", file=sys.stderr); continue
            h = f.get("hilos", "")
            rs = [v for v in (num(f.get(c)) for c in reps) if v is not None]
            filas.append({"config": f.get("config") or "sin-nombre", "hilos": h,
                          "p": int(h) if h.isdigit() and int(h) >= 1 else None, "n": n, "med": med,
                          "min": min(rs) if rs else None, "max": max(rs) if rs else None,
                          "S_csv": num(f.get("speedup")), "E_csv": num(f.get("eficiencia"))})
    if not filas:
        sys.exit(f"{ruta}: sin filas válidas.")
    return filas, len(reps)


def fmt(x, d=3):
    return "—" if x is None else f"{x:.{d}f}"


def amdahl(ps, ss):
    """f paralela por mínimos cuadrados de 1/S - 1 = f (1/p - 1), solo p > 1."""
    xs = [1 / p - 1 for p, s in zip(ps, ss) if p > 1 and s]
    ys = [1 / s - 1 for p, s in zip(ps, ss) if p > 1 and s]
    if not xs:
        return None
    f = sum(x * y for x, y in zip(xs, ys)) / sum(x * x for x in xs)
    return min(max(f, 0.0), 1.0)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("csv")
    ap.add_argument("--salida"); ap.add_argument("--titulo", default=""); ap.add_argument("--n", type=int)
    ap.add_argument("--base"); ap.add_argument("--recalcular", action="store_true"); ap.add_argument("--prefijo", default="")
    ap.add_argument("--amdahl", action="store_true", help="dibuja la curva de Amdahl ajustada por config")
    ap.add_argument("--nproc", type=int, default=os.cpu_count(), help="núcleos para marcar la sobre-suscripción")
    a = ap.parse_args()

    filas, nreps = leer(a.csv)
    con_base = sorted({f["n"] for f in filas if f["p"] == 1}); todos = sorted({f["n"] for f in filas})
    if a.n is not None:
        if a.n not in todos:
            sys.exit(f"No hay filas con n={a.n}; disponibles: {todos}")
        n = a.n
    else:
        cand = con_base or todos
        if len(cand) > 1:
            print(f"AVISO: varios n {cand}; se grafica n={cand[-1]} (usa --n para otro).", file=sys.stderr)
        n = cand[-1]
    sel = [f for f in filas if f["n"] == n]
    base = [f for f in sel if f["p"] == 1 and (not a.base or f["config"] == a.base)]
    if a.base and not base:
        sys.exit(f"No hay fila con config={a.base} e hilos=1 para n={n}.")
    t1, base_nombre = (base[0]["med"], base[0]["config"]) if base else (None, None)
    for f in sel:
        s = None if a.recalcular else f["S_csv"]
        if s is None and t1:
            s = t1 / f["med"]
        e = None if a.recalcular else f["E_csv"]
        if e is None and s and f["p"]:
            e = s / f["p"]
        f["S"], f["E"] = s, e
        f["kf"] = (1 / s - 1 / f["p"]) / (1 - 1 / f["p"]) if s and f["p"] and f["p"] > 1 else None

    configs = []
    for f in sel:
        if f["config"] not in configs:
            configs.append(f["config"])
    series = {c: sorted([f for f in sel if f["config"] == c and f["p"] and f["S"]], key=lambda f: f["p"]) for c in configs}
    series = {c: v for c, v in series.items() if v}
    if not series:
        sys.exit("No hay speedup que graficar: falta la fila hilos=1 (línea base) o las columnas speedup están en NA.")
    pmax = max(f["p"] for v in series.values() for f in v)
    ps_all = sorted({f["p"] for v in series.values() for f in v})
    out = a.salida or os.path.dirname(os.path.abspath(a.csv)); os.makedirs(out, exist_ok=True)
    plt.rcParams.update({"font.size": 10, "axes.grid": True, "grid.alpha": 0.3, "figure.dpi": 150})
    sub = f"n = {n}, {nreps} repeticiones" + (f", T(1) de {base_nombre}" if base_nombre else "")

    fig, ax = plt.subplots(figsize=(6.4, 4.2))
    ax.plot([1, pmax], [1, pmax], "--", color="gray", label="Ideal S = p")
    for i, (c, v) in enumerate(series.items()):
        ps = [f["p"] for f in v]; ss = [f["S"] for f in v]
        ax.plot(ps, ss, marker=MARCAS[i % 8], color=PALETA[i % 8], label=c)
        if a.amdahl:
            fa = amdahl(ps, ss)
            if fa is not None:
                xs = [1 + k * (pmax - 1) / 99 for k in range(100)]
                ax.plot(xs, [1 / ((1 - fa) + fa / x) for x in xs], ":", color=PALETA[i % 8], alpha=0.8, label=f"Amdahl {c} (f≈{fa:.3f})")
    if a.nproc and a.nproc < pmax:
        ax.axvline(a.nproc, color="gray", alpha=0.4, lw=1); ax.text(a.nproc, 1.0, f" {a.nproc} núcleos", color="gray", fontsize=8)
    ax.set_xlabel("Hilos o procesos (p)"); ax.set_ylabel("Speedup S(p) = T(1)/T(p)"); ax.set_xticks(ps_all)
    ax.set_title((a.titulo + " — " if a.titulo else "") + "Speedup\n" + sub, fontsize=10); ax.legend(fontsize=8); fig.tight_layout()
    fig.savefig(os.path.join(out, f"{a.prefijo}speedup.png")); plt.close(fig)

    fig, ax = plt.subplots(figsize=(6.4, 4.2))
    ax.axhline(1.0, ls="--", color="gray", label="E = 1"); ax.axhline(0.5, ls=":", color="gray", label="E = 0.5")
    for i, (c, v) in enumerate(series.items()):
        ax.plot([f["p"] for f in v], [f["E"] for f in v], marker=MARCAS[i % 8], color=PALETA[i % 8], label=c)
    if a.nproc and a.nproc < pmax:
        ax.axvline(a.nproc, color="gray", alpha=0.4, lw=1); ax.text(a.nproc, 0.05, f" {a.nproc} núcleos: sobre-suscripción →", color="gray", fontsize=8)
    emax = max(f["E"] for v in series.values() for f in v if f["E"])
    ax.set_ylim(0, max(1.1, emax * 1.05))
    ax.set_xlabel("Hilos o procesos (p)"); ax.set_ylabel("Eficiencia E(p) = S(p)/p"); ax.set_xticks(ps_all)
    ax.set_title((a.titulo + " — " if a.titulo else "") + "Eficiencia\n" + sub, fontsize=10); ax.legend(fontsize=8); fig.tight_layout()
    fig.savefig(os.path.join(out, f"{a.prefijo}eficiencia.png")); plt.close(fig)

    print(f"Tamaño del problema n = {n}; {nreps} repeticiones por fila; " + (f"T(1) = {t1:.6f} s (config {base_nombre}, hilos=1)." if t1 else "speedup tomado del CSV."))
    print()
    print("| Config | Hilos | Mediana (s) | Mín (s) | Máx (s) | Speedup | Eficiencia | f Karp–Flatt |")
    print("|---|---|---|---|---|---|---|---|")
    for f in sorted(sel, key=lambda f: (f["config"], f["p"] or 10**9)):
        print(f"| {f['config']} | {f['hilos']} | {f['med']:.6f} | {fmt(f['min'], 6)} | {fmt(f['max'], 6)} | {fmt(f['S'], 2)} | {fmt(f['E'], 2)} | {fmt(f['kf'], 3)} |")
    print(f"\nGenerado: {os.path.join(out, a.prefijo + 'speedup.png')}, {os.path.join(out, a.prefijo + 'eficiencia.png')}")
    if a.nproc and pmax > a.nproc:
        print(f"Nota: p={pmax} > {a.nproc} núcleos: sobre-suscripción; decláralo en el reporte.")


if __name__ == "__main__":
    main()
