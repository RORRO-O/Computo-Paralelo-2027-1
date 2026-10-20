#!/usr/bin/env python3
"""graficar.py — Gráficas y tabla de la Parte D a partir del CSV del curso (esquema de common.cuh / S04).

Uso:
    python3 graficar.py resultados/resultados_P6.csv [otro.csv ...] [-o carpeta_salida]

Lee uno o varios CSV (se concatenan), y escribe en la carpeta de salida (por defecto la del primer CSV):
    tiempo_vs_bloque.png   tiempo del kernel vs. hilos por bloque (filas con experimento = "bloque"), un panel
                           por kernel; marca el mejor bloque y muestra el total con copias en línea discontinua
    speedup_vs_n.png       speedup vs. n (filas "umbral"; si el CSV no trae ninguna, un kernel con >= 3 tamaños al
                           mismo bloque):
                           solo kernel (continua) y con copias (discontinua); la línea S = 1 es el empate con la CPU.
                           Si el CSV trae la columna opcional t_omp4_ms (V2 OpenMP con 4 hilos), agrega esa curva
    transferencias.png     para el n más grande de cada kernel: qué porcentaje del total es H2D / kernel / D2H, y
                           el total en ms al final de cada barra
Imprime además la tabla en Markdown (para pegar en REPORTE.md) y un resumen: mejor bloque por kernel, primer n
con speedup > 1 sin y con copias, y porcentaje de copias. El título dice si los datos son medidos (origen=gpu,
con el modelo de GPU) o ilustrativos/de prueba. Solo usa la biblioteca estándar + matplotlib.
"""
import argparse
import csv
import os
import sys

import matplotlib

matplotlib.use("Agg")  # siempre a archivo: funciona sin pantalla y dentro de Colab
import matplotlib.pyplot as plt  # noqa: E402

# Paleta categórica validada (orden fijo, nunca cíclico) + marcador distinto por serie (codificación secundaria).
PALETTE = ["#2a78d6", "#eb6834", "#1baf7a", "#eda100", "#e87ba4", "#6250d6", "#008300", "#e34948"]
MARKERS = ["o", "s", "^", "D", "v", "P", "X", "*"]
INK, MUTED, GRID = "#0b0b0b", "#52514e", "#e5e4df"
NUMERIC = ("t_h2d_ms", "t_kernel_ms", "t_d2h_ms", "t_total_ms", "t_cpu_ms", "speedup_kernel", "speedup_total",
           "ancho_banda_gbs", "ocupacion_pct")


def read_rows(paths):
    rows = []
    for path in paths:
        with open(path, newline="", encoding="utf-8") as f:
            for r in csv.DictReader(f):
                try:
                    for key in ("n", "block", "grid"):
                        r[key] = int(float(r[key]))
                    for key in NUMERIC:
                        r[key] = float(r[key])
                    omp = r.get("t_omp4_ms", "")
                    r["t_omp4_ms"] = float(omp) if omp not in ("", None) else None
                except (KeyError, ValueError) as exc:
                    sys.exit(f"{path}: fila inválida ({exc}): {r}")
                rows.append(r)
    return rows


def style_map(rows):
    """Color y marcador por kernel, en orden de primera aparición: el color sigue a la entidad, no a su rango.
    Con más de 8 kernels (Partes A, B y C juntas) los colores se repiten solo a partir del noveno; en
    tiempo_vs_bloque.png cada kernel tiene su propio panel y en speedup_vs_n.png solo entran los del barrido "umbral",
    así que nunca se confunden dos series en la misma gráfica. Ningún kernel se omite."""
    kernels = []
    for r in rows:
        if r["kernel"] not in kernels:
            kernels.append(r["kernel"])
    return {k: (PALETTE[i % len(PALETTE)], MARKERS[i % len(MARKERS)]) for i, k in enumerate(kernels)}


def source_note(rows):
    origins = {r["origen"] for r in rows}
    if origins == {"gpu"}:
        return "medido en " + ", ".join(sorted({r["dispositivo"] for r in rows}))
    return "DATOS NO MEDIDOS (origen: " + ", ".join(sorted(origins)) + ")"


def tidy(ax):
    ax.grid(axis="y", color=GRID, linewidth=0.8)
    ax.spines[["top", "right"]].set_visible(False)
    ax.tick_params(colors=MUTED)
    for s in ("left", "bottom"):
        ax.spines[s].set_color(GRID)


def fmt_n(n):
    return f"{n:,}".replace(",", " ")


def plot_block_sweep(rows, out_path, styles, note):
    rows = [r for r in rows if r["experimento"] == "bloque"]
    if not rows:
        print("Sin filas con experimento=bloque: no se genera tiempo_vs_bloque.png")
        return
    kernels = [k for k in styles if any(r["kernel"] == k for r in rows)]
    ncols = min(3, len(kernels))  # paneles en filas de 3: legibles en el reporte y en pantalla
    nrows = (len(kernels) + ncols - 1) // ncols
    fig, axes = plt.subplots(nrows, ncols, figsize=(4.6 * ncols, 3.9 * nrows + 0.4), squeeze=False)
    flat = [ax for row_axes in axes for ax in row_axes]
    for ax in flat[len(kernels):]:
        ax.set_visible(False)  # huecos de la última fila
    for ax, kernel in zip(flat, kernels):
        sub = [r for r in rows if r["kernel"] == kernel]
        n_big = max(r["n"] for r in sub)  # si hay varios n, se grafica el mayor (el del protocolo)
        pts = sorted((r["block"], r["t_kernel_ms"], r["t_total_ms"]) for r in sub if r["n"] == n_big)
        color, marker = styles[kernel]
        xs = list(range(len(pts)))
        ax.plot(xs, [p[1] for p in pts], "-", marker=marker, markersize=7, linewidth=2, color=color,
                label="solo kernel")
        ax.plot(xs, [p[2] for p in pts], "--", marker=marker, markersize=5, linewidth=1.5, color=color,
                alpha=0.75, label="con copias (total)")
        best = min(pts, key=lambda p: p[1])
        ax.annotate(f"mejor: {best[0]} hilos\n{best[1]:.3f} ms", (xs[pts.index(best)], best[1]),
                    textcoords="offset points", xytext=(0, 12), ha="center", fontsize=8, color=MUTED)
        ax.set_xticks(xs)
        ax.set_xticklabels([str(p[0]) for p in pts])
        ax.set_xlabel("hilos por bloque")
        ax.set_ylabel("tiempo (ms)")
        ax.set_yscale("log")
        ax.set_title(f"{kernel} · n = {fmt_n(n_big)}", fontsize=10, color=INK)
        ax.legend(frameon=False, fontsize=8)
        tidy(ax)
    fig.suptitle(f"Tiempo vs. tamaño de bloque · {note}", fontsize=11, color=INK)
    fig.tight_layout()
    fig.savefig(out_path, dpi=130)
    plt.close(fig)
    print(f"Gráfica escrita: {out_path}")


def threshold_rows(rows, kernel):
    """Filas 'umbral' del kernel. Solo si el CSV no trae ningún barrido 'umbral' (p. ej. un CSV con tu Parte C sola),
    se usan las del bloque más frecuente cuando hay >= 3 tamaños distintos: así no se mezclan en el mismo eje un n que
    es el lado de una matriz con un n que es número de elementos. Las filas 'uno' (configuraciones sueltas, como las
    formas rectangulares de la Parte B) nunca forman un barrido."""
    sub = [r for r in rows if r["kernel"] == kernel and r["experimento"] == "umbral"]
    if not sub and not any(r["experimento"] == "umbral" for r in rows):
        cand = [r for r in rows if r["kernel"] == kernel and r["experimento"] != "uno"]
        if not cand:
            return []
        blocks = {}
        for r in cand:
            blocks[r["block"]] = blocks.get(r["block"], 0) + 1
        block = max(blocks, key=blocks.get)
        sub = [r for r in cand if r["block"] == block]
        if len({r["n"] for r in sub}) < 3:
            return []
    sub.sort(key=lambda r: r["n"])
    return sub


def plot_threshold(rows, out_path, styles, note):
    series = {k: threshold_rows(rows, k) for k in styles}
    series = {k: v for k, v in series.items() if v}
    if not series:
        print("Sin kernels con >= 3 tamaños de n: no se genera speedup_vs_n.png")
        return
    fig, ax = plt.subplots(figsize=(7.4, 4.8))
    for kernel, sub in series.items():
        color, marker = styles[kernel]
        ns = [r["n"] for r in sub]
        ax.plot(ns, [r["speedup_kernel"] for r in sub], "-", marker=marker, markersize=7, linewidth=2,
                color=color, label=f"{kernel}: solo kernel")
        ax.plot(ns, [r["speedup_total"] for r in sub], "--", marker=marker, markersize=5, linewidth=1.5,
                color=color, alpha=0.8, label=f"{kernel}: con copias")
        if all(r["t_omp4_ms"] is not None for r in sub):
            ax.plot(ns, [r["t_omp4_ms"] / r["t_total_ms"] for r in sub], ":", marker=marker, markersize=5,
                    linewidth=1.5, color=color, alpha=0.8, label=f"{kernel}: con copias vs. OpenMP 4 hilos")
    ax.axhline(1.0, color=MUTED, linewidth=1)
    ax.text(min(min(r["n"] for r in s) for s in series.values()), 1.0, " S = 1 (empate con la CPU)",
            va="bottom", fontsize=8, color=MUTED)
    ax.set_xscale("log", base=2)
    ax.set_yscale("log")
    ax.set_xlabel("n (elementos)")
    ax.set_ylabel("speedup = T_cpu / T_gpu")
    ax.set_title(f"¿A partir de qué n gana la GPU? · {note}", fontsize=11, color=INK)
    ax.legend(frameon=False, fontsize=8, ncol=2)
    tidy(ax)
    ax.grid(axis="x", color=GRID, linewidth=0.8)
    fig.tight_layout()
    fig.savefig(out_path, dpi=130)
    plt.close(fig)
    print(f"Gráfica escrita: {out_path}")


def largest_rows(rows, styles):
    out = []
    for kernel in styles:
        sub = [r for r in rows if r["kernel"] == kernel]
        if sub:
            n_big = max(r["n"] for r in sub)
            out.append(min((r for r in sub if r["n"] == n_big), key=lambda r: r["t_kernel_ms"]))
    return out


def plot_transfers(rows, out_path, styles, note):
    """Una barra por kernel (su n mayor): qué fracción del tiempo total es H2D, kernel y D2H. Se grafican
    proporciones porque los totales de distintos kernels difieren en órdenes de magnitud; el total va en ms al final."""
    rows = largest_rows(rows, styles)
    if not rows:
        return
    fig, ax = plt.subplots(figsize=(7.8, 1.2 + 0.62 * len(rows)))
    labels = [f"{r['kernel']}\nn = {fmt_n(r['n'])}, bloque {r['block']}" for r in rows]
    parts = (("t_h2d_ms", "H2D", "#8a8984"), ("t_kernel_ms", "kernel", "#2a78d6"), ("t_d2h_ms", "D2H", "#c3c2b7"))
    left = [0.0] * len(rows)
    for key, name, color in parts:
        pcts = [100.0 * r[key] / r["t_total_ms"] for r in rows]
        ax.barh(labels, pcts, left=left, color=color, label=name, height=0.6, edgecolor="white", linewidth=1.5)
        for i, pct in enumerate(pcts):
            if pct >= 12:  # solo se rotula el tramo que tiene espacio; el resto se lee en la tabla impresa
                ax.text(left[i] + pct / 2, i, f"{pct:.0f} %", ha="center", va="center", fontsize=8,
                        color="white" if key == "t_kernel_ms" else INK)
        left = [a + b for a, b in zip(left, pcts)]
    for i, r in enumerate(rows):
        ax.text(101.5, i, f"{r['t_total_ms']:.2f} ms", va="center", fontsize=8, color=MUTED)
    ax.set_xlim(0, 118)
    ax.set_xticks([0, 25, 50, 75, 100])
    ax.set_xlabel("% del tiempo total con copias (mediana de 5); a la derecha, el total en ms")
    ax.set_title(f"¿Cuánto pesan las copias? · {note}", fontsize=11, color=INK)
    ax.legend(frameon=False, fontsize=8, ncol=3, loc="upper center", bbox_to_anchor=(0.43, -0.12 - 0.3 / len(rows)))
    ax.invert_yaxis()
    tidy(ax)
    ax.grid(axis="y", visible=False)
    ax.grid(axis="x", color=GRID, linewidth=0.8)
    fig.tight_layout()
    fig.savefig(out_path, dpi=130)
    plt.close(fig)
    print(f"Gráfica escrita: {out_path}")


def first_crossing(sub, key):
    for r in sub:
        if r[key] > 1.0:
            return r["n"]
    return None


def print_summary(rows, styles):
    print("\n## Tabla (ms, mediana de 5 tras 1 calentamiento)\n")
    print("| experimento | kernel | n | bloque | H2D | kernel | D2H | total | CPU | S_kernel | S_total | copias % | verif |")
    print("|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|")
    for r in sorted(rows, key=lambda r: (r["experimento"], r["kernel"], r["n"], r["block"])):
        copies = 100.0 * (r["t_h2d_ms"] + r["t_d2h_ms"]) / r["t_total_ms"]
        verif = r.get("verificacion", "")  # columna opcional
        print(f"| {r['experimento']} | {r['kernel']} | {r['n']} | {r['block']} | {r['t_h2d_ms']:.4f} | "
              f"{r['t_kernel_ms']:.4f} | {r['t_d2h_ms']:.4f} | {r['t_total_ms']:.4f} | {r['t_cpu_ms']:.4f} | "
              f"{r['speedup_kernel']:.2f} | {r['speedup_total']:.2f} | {copies:.0f} | {verif} |")
    print("\n## Resumen\n")
    block_rows = [r for r in rows if r["experimento"] == "bloque"]
    for kernel in styles:
        sub = [r for r in block_rows if r["kernel"] == kernel]
        if sub:
            n_big = max(r["n"] for r in sub)
            sub = [r for r in sub if r["n"] == n_big]
            best, worst = min(sub, key=lambda r: r["t_kernel_ms"]), max(sub, key=lambda r: r["t_kernel_ms"])
            print(f"- {kernel} (n={n_big}): mejor bloque {best['block']} ({best['t_kernel_ms']:.4f} ms), peor "
                  f"{worst['block']} ({worst['t_kernel_ms']:.4f} ms), peor/mejor = "
                  f"{worst['t_kernel_ms'] / best['t_kernel_ms']:.2f}x; ocupación del mejor {best['ocupacion_pct']:.0f} %")
    for kernel in styles:
        sub = threshold_rows(rows, kernel)
        if sub:
            fmt = lambda v: f"n >= {v}" if v else "no cruza en el rango medido"
            print(f"- {kernel}: la GPU gana solo kernel desde {fmt(first_crossing(sub, 'speedup_kernel'))}; "
                  f"con copias desde {fmt(first_crossing(sub, 'speedup_total'))}")
    for r in largest_rows(rows, styles):
        copies = 100.0 * (r["t_h2d_ms"] + r["t_d2h_ms"]) / r["t_total_ms"]
        print(f"- {r['kernel']} (n={r['n']}, bloque {r['block']}): copias = {copies:.0f} % del total; "
              f"{r['ancho_banda_gbs']:.1f} GB/s útiles en el kernel")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("csv", nargs="+", help="uno o más CSV con el esquema del curso")
    ap.add_argument("-o", "--salida", help="carpeta de salida (por defecto, la del primer CSV)")
    args = ap.parse_args()
    out_dir = args.salida or (os.path.dirname(args.csv[0]) or ".")
    os.makedirs(out_dir, exist_ok=True)
    rows = read_rows(args.csv)
    if not rows:
        sys.exit("El CSV no tiene filas")
    styles = style_map(rows)
    note = source_note(rows)
    print(f"{len(rows)} filas leídas · {note}")
    plot_block_sweep(rows, os.path.join(out_dir, "tiempo_vs_bloque.png"), styles, note)
    plot_threshold(rows, os.path.join(out_dir, "speedup_vs_n.png"), styles, note)
    plot_transfers(rows, os.path.join(out_dir, "transferencias.png"), styles, note)
    print_summary(rows, styles)


if __name__ == "__main__":
    main()
