"""graficar.py — Grafica los resultados de bench_gpu.cu (o el CSV de ejemplo de bench_cpu --csv-ejemplo).

Uso: python3 graficar.py resultados.csv [carpeta_salida]

Produce en carpeta_salida (por defecto la del CSV):
  tiempo_vs_bloque.png   tiempo del kernel vs. tamaño de bloque (experimento "bloque"); un panel por n
  speedup_vs_n.png       speedup vs. n (experimento "umbral"): solo kernel (línea continua) y con copias
                         (discontinua = paginable, punteada = pinned); la línea S = 1 marca el cruce
y escribe en pantalla la tabla del experimento "umbral" y un resumen: mejor bloque por kernel y primer n a
partir del cual la GPU gana con y sin copias. Si el CSV viene de un modelo (origen=modelo) lo dice en el título.
Solo usa la biblioteca estándar + matplotlib.
"""
import csv
import os
import sys

import matplotlib

matplotlib.use("Agg")  # siempre a archivo: funciona sin pantalla y dentro de Colab
import matplotlib.pyplot as plt  # noqa: E402

COLORS = {"vector_add": "#2a78d6", "saxpy": "#eb6834"}  # paleta validada para daltonismo (2 series)
MARKERS = {"vector_add": ("o", 9), "saxpy": ("s", 5)}  # círculo grande y cuadrado chico
STYLE_TOTAL = {"pageable": "--", "pinned": ":"}
BLOCK_ORDER = (32, 64, 128, 256, 512, 1024)


def read_rows(path):
    with open(path, newline="") as f:
        rows = list(csv.DictReader(f))
    for r in rows:
        for key in ("n", "block", "grid"):
            r[key] = int(r[key])
        for key in ("t_h2d_ms", "t_kernel_ms", "t_d2h_ms", "t_total_ms", "t_cpu_ms", "speedup_kernel",
                    "speedup_total", "ancho_banda_gbs", "ocupacion_pct"):
            r[key] = float(r[key])
    return rows


def source_note(rows):
    origins = {r["origen"] for r in rows}
    if origins == {"gpu"}:
        devices = sorted({r["dispositivo"] for r in rows})
        return "medido en " + ", ".join(devices)
    return "DATOS DE MODELO (sin GPU), no medidos"


def plot_block_sweep(rows, out_path, note):
    rows = [r for r in rows if r["experimento"] == "bloque"]
    if not rows:
        print("Sin filas del experimento 'bloque': no se genera tiempo_vs_bloque.png")
        return
    sizes = sorted({r["n"] for r in rows}, reverse=True)
    fig, axes = plt.subplots(1, len(sizes), figsize=(5.2 * len(sizes), 4.2), squeeze=False)
    for ax, n in zip(axes[0], sizes):
        for kernel in ("vector_add", "saxpy"):
            pts = sorted((r["block"], r["t_kernel_ms"]) for r in rows if r["n"] == n and r["kernel"] == kernel)
            if not pts:
                continue
            xs = [BLOCK_ORDER.index(b) if b in BLOCK_ORDER else -1 for b, _ in pts]
            # Marcadores distintos por kernel: si los tiempos coinciden, las dos series siguen siendo visibles.
            ax.plot(xs, [t for _, t in pts], marker=MARKERS[kernel][0], markersize=MARKERS[kernel][1],
                    linewidth=2, color=COLORS[kernel], label=kernel)
            best = min(pts, key=lambda p: p[1])
            ax.annotate(f"mejor {kernel}: {best[0]}",
                        (BLOCK_ORDER.index(best[0]) if best[0] in BLOCK_ORDER else -1, best[1]),
                        textcoords="offset points", xytext=(0, -14 if kernel == "vector_add" else 10),
                        ha="center", fontsize=8, color="#52514e")
        ax.set_xticks(range(len(BLOCK_ORDER)))
        ax.set_xticklabels([str(b) for b in BLOCK_ORDER])
        ax.set_xlabel("hilos por bloque")
        ax.set_ylabel("tiempo del kernel (ms)")
        ax.set_ylim(bottom=0)
        ax.set_title(f"n = {n:,}".replace(",", " "), fontsize=10)
        ax.grid(axis="y", color="#e5e4df", linewidth=0.8)
        ax.spines[["top", "right"]].set_visible(False)
        ax.legend(frameon=False)
    fig.suptitle(f"Tiempo del kernel vs. tamaño de bloque · {note}", fontsize=11)
    fig.tight_layout()
    fig.savefig(out_path, dpi=130)
    plt.close(fig)
    print(f"Gráfica escrita: {out_path}")


def plot_threshold(rows, out_path, note):
    rows = [r for r in rows if r["experimento"] == "umbral"]
    if not rows:
        print("Sin filas del experimento 'umbral': no se genera speedup_vs_n.png")
        return
    memories = [m for m in ("pageable", "pinned") if any(r["memoria"] == m for r in rows)]
    fig, ax = plt.subplots(figsize=(7.2, 4.6))
    for kernel in ("vector_add", "saxpy"):
        base = [r for r in rows if r["kernel"] == kernel and r["memoria"] == memories[0]]
        base.sort(key=lambda r: r["n"])
        if base:
            ax.plot([r["n"] for r in base], [r["speedup_kernel"] for r in base], "-", marker="o", markersize=6,
                    linewidth=2, color=COLORS[kernel], label=f"{kernel}: solo kernel")
        for mem in memories:
            sub = sorted((r for r in rows if r["kernel"] == kernel and r["memoria"] == mem), key=lambda r: r["n"])
            if sub:
                ax.plot([r["n"] for r in sub], [r["speedup_total"] for r in sub], STYLE_TOTAL[mem], marker="s",
                        markersize=5, linewidth=2, color=COLORS[kernel], label=f"{kernel}: con copias ({mem})")
    ax.axhline(1.0, color="#52514e", linewidth=1, linestyle="-")
    ax.text(min(r["n"] for r in rows), 1.0, " S = 1 (empate con la CPU)", va="bottom", fontsize=8, color="#52514e")
    ax.set_xscale("log", base=2)
    ax.set_yscale("log")
    ax.set_xlabel("n (elementos por vector)")
    ax.set_ylabel("speedup = T_cpu / T_gpu")
    ax.set_title(f"¿A partir de qué n gana la GPU? · {note}", fontsize=11)
    ax.grid(color="#e5e4df", linewidth=0.8, which="major")
    ax.spines[["top", "right"]].set_visible(False)
    ax.legend(frameon=False, fontsize=8, ncol=2)
    fig.tight_layout()
    fig.savefig(out_path, dpi=130)
    plt.close(fig)
    print(f"Gráfica escrita: {out_path}")


def first_crossing(sub, key):
    """Primer n (ordenado) con speedup > 1, o None."""
    for r in sorted(sub, key=lambda r: r["n"]):
        if r[key] > 1.0:
            return r["n"]
    return None


def print_summary(rows):
    block_rows = [r for r in rows if r["experimento"] == "bloque"]
    if block_rows:
        print("\nResumen 'bloque' (tiempo del kernel):")
        for n in sorted({r["n"] for r in block_rows}, reverse=True):
            for kernel in ("vector_add", "saxpy"):
                sub = [r for r in block_rows if r["n"] == n and r["kernel"] == kernel]
                if not sub:
                    continue
                best = min(sub, key=lambda r: r["t_kernel_ms"])
                worst = max(sub, key=lambda r: r["t_kernel_ms"])
                print(f"  n={n:>10} {kernel:<11} mejor bloque {best['block']:>4} ({best['t_kernel_ms']:.4f} ms), "
                      f"peor {worst['block']:>4} ({worst['t_kernel_ms']:.4f} ms), "
                      f"peor/mejor = {worst['t_kernel_ms'] / best['t_kernel_ms']:.2f}x")
    thr_rows = [r for r in rows if r["experimento"] == "umbral"]
    if thr_rows:
        print("\nTabla 'umbral' (ms; mediana de 5):")
        print("| kernel | memoria | n | H2D | kernel | D2H | total | CPU | S_kernel | S_total | copias % |")
        print("|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|")
        for r in sorted(thr_rows, key=lambda r: (r["kernel"], r["memoria"], r["n"])):
            copies = 100.0 * (r["t_h2d_ms"] + r["t_d2h_ms"]) / r["t_total_ms"]
            print(f"| {r['kernel']} | {r['memoria']} | {r['n']} | {r['t_h2d_ms']:.4f} | {r['t_kernel_ms']:.4f} | "
                  f"{r['t_d2h_ms']:.4f} | {r['t_total_ms']:.4f} | {r['t_cpu_ms']:.4f} | {r['speedup_kernel']:.2f} | "
                  f"{r['speedup_total']:.2f} | {copies:.0f} |")
        print("\nResumen 'umbral' (primer n con speedup > 1):")
        for kernel in ("vector_add", "saxpy"):
            for mem in ("pageable", "pinned"):
                sub = [r for r in thr_rows if r["kernel"] == kernel and r["memoria"] == mem]
                if not sub:
                    continue
                ck = first_crossing(sub, "speedup_kernel")
                ct = first_crossing(sub, "speedup_total")
                fmt = lambda v: f"n >= {v}" if v else "no cruza en el rango medido"
                print(f"  {kernel:<11} {mem:<9} solo kernel: {fmt(ck):<32} con copias: {fmt(ct)}")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    csv_path = sys.argv[1]
    out_dir = sys.argv[2] if len(sys.argv) > 2 else (os.path.dirname(csv_path) or ".")
    os.makedirs(out_dir, exist_ok=True)
    rows = read_rows(csv_path)
    if not rows:
        print("El CSV no tiene filas")
        sys.exit(1)
    note = source_note(rows)
    print(f"{len(rows)} filas leídas de {csv_path} · {note}")
    plot_block_sweep(rows, os.path.join(out_dir, "tiempo_vs_bloque.png"), note)
    plot_threshold(rows, os.path.join(out_dir, "speedup_vs_n.png"), note)
    print_summary(rows)


if __name__ == "__main__":
    main()
