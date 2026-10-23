#!/usr/bin/env python3
"""graficar.py — Gráficas de escalabilidad fuerte y débil a partir de los CSV de escalado.sh
(formato del protocolo de medición del curso) y tabla Markdown para el REPORTE.md.

Uso:
  python3 graficar.py resultados/fuerte.csv resultados/debil.csv resultados/ [--titulo heat]
         [--modelo ALPHA_US BETA_GBPS TC_NS] [--check-every K]
Produce:
  fuerte.png  speedup S(p) = T_seq / T(p) contra procesos, con la línea ideal S = p
  debil.png   eficiencia débil T(1, n) / T(p, p·n) contra procesos, con la línea ideal E = 1
  y en la terminal las dos tablas en Markdown (pégalas en el reporte).
Los puntos sobre-suscritos (config = mpi_oversub) se dibujan huecos y anotados: se reportan aparte.
--modelo dibuja además el speedup que predice el modelo de costo de la Parte D para calor 1D:
  T_p = (n/p)·t_c + 2(α + 8/β) + [2·log2(p)·α]/K   (K = cada cuántos pasos se hace el Allreduce)
"""
import argparse
import csv
import math

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

COLOR_MEASURED = "#2a78d6"   # azul: serie medida
COLOR_OVERSUB = "#eb6834"    # naranja: punto sobre-suscrito (se declara aparte)
COLOR_IDEAL = "#8a8985"      # gris: referencia ideal
COLOR_MODEL = "#2e9e6b"      # verde: modelo de costo
COLOR_TEXT = "#0b0b0b"


def read_rows(path):
    with open(path, newline="") as f:
        return list(csv.DictReader(f))


def style(ax, xlabel, ylabel, title):
    ax.set_xlabel(xlabel, color=COLOR_TEXT)
    ax.set_ylabel(ylabel, color=COLOR_TEXT)
    ax.set_title(title, color=COLOR_TEXT, loc="left", fontsize=11)
    ax.grid(True, color="#e3e2de", linewidth=0.8)
    for side in ("top", "right"):
        ax.spines[side].set_visible(False)
    ax.set_facecolor("#fcfcfb")


def model_speedup(n, p, alpha_us, beta_gbps, tc_ns, check_every):
    alpha, beta, tc = alpha_us * 1e-6, beta_gbps * 1e9, tc_ns * 1e-9
    if p == 1:
        return 1.0
    halos = 2.0 * (alpha + 8.0 / beta)
    allreduce = (2.0 * math.log2(p) * alpha) / check_every if check_every > 0 else 0.0
    return (n * tc) / ((n / p) * tc + halos + allreduce)


def plot_series(ax, rows, ycol, ideal_fn, ylabel, title, label_fmt, model=None):
    rows = [r for r in rows if r["config"] != "seq"]
    ps = [int(r["hilos"]) for r in rows]
    ys = [float(r[ycol]) for r in rows]
    oversub = [r["config"] == "mpi_oversub" for r in rows]
    xs = sorted(set(ps))
    ax.plot(xs, [ideal_fn(p) for p in xs], "--", color=COLOR_IDEAL, linewidth=1.5, label="ideal")
    if model is not None:
        ax.plot(xs, [model(p) for p in xs], ":", color=COLOR_MODEL, linewidth=2, label="modelo α + m/β")
    normal = [(p, y) for p, y, o in zip(ps, ys, oversub) if not o]
    ax.plot([p for p, _ in normal], [y for _, y in normal], "-o", color=COLOR_MEASURED,
            linewidth=2, markersize=7, label="medido (p ≤ núcleos)")
    for p, y, o in zip(ps, ys, oversub):
        if o:
            ax.plot([p], [y], "o", markerfacecolor="white", markeredgecolor=COLOR_OVERSUB,
                    markeredgewidth=2, markersize=8, label="sobre-suscrito (declarado)")
            ax.annotate("p > núcleos", (p, y), textcoords="offset points", xytext=(-8, 10),
                        ha="right", fontsize=8, color=COLOR_TEXT)
        ax.annotate(label_fmt.format(y), (p, y), textcoords="offset points", xytext=(6, -12),
                    fontsize=8, color=COLOR_TEXT)
    ax.set_xticks(xs)
    ax.set_xlim(0.5, max(xs) + 0.8)
    style(ax, "procesos MPI (p)", ylabel, title)
    handles, labels = ax.get_legend_handles_labels()
    uniq = dict(zip(labels, handles))
    ax.legend(uniq.values(), uniq.keys(), frameon=False, fontsize=8)


def markdown_table(rows, weak):
    head = ("| config | p | n | mediana (s) | mín (s) | máx (s) | "
            + ("S escalado | eficiencia débil |" if weak else "speedup | eficiencia |"))
    lines = [head, "|---|---|---|---|---|---|---|---|"]
    for r in rows:
        reps = [float(r[f"rep{i}"]) for i in range(1, 6)]
        lines.append(f"| {r['config']} | {r['hilos']} | {int(r['n']):,} | {float(r['mediana_s']):.4f} | "
                     f"{min(reps):.4f} | {max(reps):.4f} | {float(r['speedup']):.2f} | {float(r['eficiencia']):.2f} |")
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("fuerte_csv")
    ap.add_argument("debil_csv")
    ap.add_argument("out_dir")
    ap.add_argument("--titulo", default="", help="nombre del programa para el título (heat, matvec, primes)")
    ap.add_argument("--modelo", nargs=3, type=float, metavar=("ALPHA_US", "BETA_GBPS", "TC_NS"),
                    help="dibuja el speedup predicho por el modelo de costo (calor 1D)")
    ap.add_argument("--check-every", type=int, default=1, help="pasos entre Allreduce en el modelo (1)")
    args = ap.parse_args()
    out = args.out_dir.rstrip("/")
    tag = f" · {args.titulo}" if args.titulo else ""

    strong = read_rows(args.fuerte_csv)
    n_strong = int(strong[0]["n"]) if strong else 0
    if not [r for r in strong if r["config"] != "seq"]:
        raise SystemExit(f"{args.fuerte_csv}: no hay filas mpi que graficar (¿escalado.sh terminó? ¿TODO pendiente?)")
    model = None
    if args.modelo:
        a, b, c = args.modelo
        model = lambda p: model_speedup(n_strong, p, a, b, c, args.check_every)  # noqa: E731
    fig, ax = plt.subplots(figsize=(5.2, 3.6), dpi=130)
    plot_series(ax, strong, "speedup", lambda p: p, "speedup S(p) = T_seq / T(p)",
                f"Escalabilidad fuerte{tag} · n = {n_strong:,}", "{:.2f}", model)
    top = max(4.5, max(float(r["speedup"]) for r in strong) + 0.5)
    ax.set_ylim(0, top)
    fig.tight_layout()
    fig.savefig(f"{out}/fuerte.png")
    plt.close(fig)

    weak = read_rows(args.debil_csv)
    n_local = int(weak[0]["n"]) if weak else 0
    fig, ax = plt.subplots(figsize=(5.2, 3.6), dpi=130)
    plot_series(ax, weak, "eficiencia", lambda p: 1.0, "eficiencia débil T(1,n) / T(p, p·n)",
                f"Escalabilidad débil{tag} · n/p = {n_local:,}", "{:.2f}")
    ax.set_ylim(0, 1.15)
    fig.tight_layout()
    fig.savefig(f"{out}/debil.png")
    plt.close(fig)

    print(f"gráficas: {out}/fuerte.png, {out}/debil.png\n")
    print(f"Escalabilidad fuerte (n = {n_strong:,}):\n")
    print(markdown_table(strong, weak=False))
    print(f"\nEscalabilidad débil (n/p = {n_local:,}):\n")
    print(markdown_table(weak, weak=True))
    if model is not None:
        print("\nSpeedup predicho por el modelo (fuerte): "
              + ", ".join(f"p={p}: {model(p):.2f}" for p in sorted({int(r['hilos']) for r in strong})))


if __name__ == "__main__":
    main()
