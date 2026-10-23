#!/usr/bin/env python3
"""graficar.py — Gráficas de escalabilidad fuerte y débil a partir de los CSV
que produce escalado.sh (formato del protocolo de medición del curso).

Uso: python3 graficar.py resultados/fuerte.csv resultados/debil.csv resultados/
Produce: fuerte.png (speedup vs procesos, con la línea ideal S = p)
         debil.png  (eficiencia débil vs procesos, con la línea ideal E = 1)
Los puntos sobre-suscritos (config = mpi_oversub) se dibujan huecos y anotados.
"""
import csv
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

COLOR_MEASURED = "#2a78d6"   # azul: serie medida
COLOR_OVERSUB = "#eb6834"    # naranja: punto sobre-suscrito (se declara aparte)
COLOR_IDEAL = "#8a8985"      # gris: referencia ideal
COLOR_TEXT = "#0b0b0b"


def read_rows(path):
    with open(path, newline="") as f:
        return [r for r in csv.DictReader(f) if r["config"] != "seq"]


def style(ax, xlabel, ylabel, title):
    ax.set_xlabel(xlabel, color=COLOR_TEXT)
    ax.set_ylabel(ylabel, color=COLOR_TEXT)
    ax.set_title(title, color=COLOR_TEXT, loc="left", fontsize=11)
    ax.grid(True, color="#e3e2de", linewidth=0.8)
    for side in ("top", "right"):
        ax.spines[side].set_visible(False)
    ax.set_facecolor("#fcfcfb")


def plot_series(ax, rows, ycol, ideal_fn, ylabel, title, label_fmt):
    ps = [int(r["hilos"]) for r in rows]
    ys = [float(r[ycol]) for r in rows]
    oversub = [r["config"] == "mpi_oversub" for r in rows]
    pmax = max(ps)
    ideal_x = sorted(set(ps))
    ax.plot(ideal_x, [ideal_fn(p) for p in ideal_x], "--", color=COLOR_IDEAL, linewidth=1.5, label="ideal")
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
    ax.set_xticks(sorted(set(ps)))
    ax.set_xlim(0.5, pmax + 0.8)
    style(ax, "procesos MPI (p)", ylabel, title)
    handles, labels = ax.get_legend_handles_labels()
    uniq = dict(zip(labels, handles))
    ax.legend(uniq.values(), uniq.keys(), frameon=False, fontsize=8)


def main():
    if len(sys.argv) != 4:
        print(__doc__)
        sys.exit(1)
    strong_csv, weak_csv, out_dir = sys.argv[1:4]
    out_dir = out_dir.rstrip("/")

    strong = read_rows(strong_csv)
    n_strong = strong[0]["n"] if strong else "?"
    fig, ax = plt.subplots(figsize=(5.2, 3.6), dpi=130)
    plot_series(ax, strong, "speedup", lambda p: p, "speedup S(p) = T_seq / T(p)",
                f"Escalabilidad fuerte · Jacobi 1D · n = {int(n_strong):,}", "{:.2f}")
    ax.set_ylim(0, max(4.5, max(float(r["speedup"]) for r in strong) + 0.5))
    fig.tight_layout()
    fig.savefig(f"{out_dir}/fuerte.png")
    plt.close(fig)

    weak = read_rows(weak_csv)
    n_local = int(weak[0]["n"]) // int(weak[0]["hilos"]) if weak else 0
    fig, ax = plt.subplots(figsize=(5.2, 3.6), dpi=130)
    plot_series(ax, weak, "eficiencia", lambda p: 1.0, "eficiencia débil T(1,n) / T(p, p·n)",
                f"Escalabilidad débil · Jacobi 1D · n/p = {n_local:,}", "{:.2f}")
    ax.set_ylim(0, 1.15)
    fig.tight_layout()
    fig.savefig(f"{out_dir}/debil.png")
    plt.close(fig)
    print(f"gráficas: {out_dir}/fuerte.png, {out_dir}/debil.png")


if __name__ == "__main__":
    main()
