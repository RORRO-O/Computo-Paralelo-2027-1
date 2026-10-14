#!/usr/bin/env python3
"""graficar.py — Speedup vs. hilos (con la línea ideal S = p) a partir de un CSV del protocolo.

Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · S10 · práctica guiada (versión local y corta de
herramientas/graficar_speedup.py; solo necesita matplotlib).

Uso:
    python3 graficar.py resultados/false_sharing.csv [--salida archivo.png] [--titulo "texto"]

Entrada: columnas  config,hilos,n,rep1..rep5,mediana_s,speedup,eficiencia  (una fila por configuración
y número de hilos; si una pareja config/hilos se repite, vale la última). Cada `config` es una serie.
Las filas con config que termina en "-seq" o se llama "secuencial" son la referencia y no se grafican.

Salida: el PNG (por defecto, junto al CSV con el mismo nombre) y, en pantalla, la tabla Markdown con
mediana, speedup, eficiencia y la fracción secuencial de Karp–Flatt f = (1/S − 1/p) / (1 − 1/p).
Código de salida 0 si generó la imagen; 1 si el CSV no sirve.
"""
import argparse
import csv
import os
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

# Paleta categórica del curso: el color sigue al nombre de la serie, no a su posición.
COLORES = {
    "contiguo": "#eb6834", "relleno": "#2a78d6", "local": "#1baf7a",
    "saxpy": "#eb6834", "matmul": "#2a78d6",
    "total": "#eb6834", "seccionB": "#2a78d6",
    "fuerte": "#2a78d6", "debil": "#eb6834",
}
PALETA = ["#2a78d6", "#eb6834", "#1baf7a", "#eda100", "#e87ba4", "#6250d6"]
MARCADORES = ["o", "s", "D", "^", "v", "P"]
INK, INK2, GRID, SURFACE = "#0b0b0b", "#52514e", "#e1e0d9", "#fcfcfb"


def leer(ruta):
    """Devuelve {config: {hilos: fila}} con los valores numéricos ya convertidos."""
    series = {}
    with open(ruta, newline="") as f:
        lector = csv.DictReader(f)
        necesarias = {"config", "hilos", "mediana_s", "speedup", "eficiencia"}
        if not lector.fieldnames or not necesarias.issubset(lector.fieldnames):
            sys.exit(f"graficar.py: el CSV debe tener las columnas {sorted(necesarias)}")
        for fila in lector:
            try:
                p = int(fila["hilos"])
                fila["_mediana"] = float(fila["mediana_s"])
                fila["_speedup"] = float(fila["speedup"])
                fila["_eficiencia"] = float(fila["eficiencia"])
            except (ValueError, TypeError):
                continue                      # filas no numéricas (p. ej. hilos=gpu) no se grafican
            series.setdefault(fila["config"], {})[p] = fila   # la última corrida gana
    return series


def karp_flatt(s, p):
    return float("nan") if p <= 1 or s <= 0 else (1.0 / s - 1.0 / p) / (1.0 - 1.0 / p)


def main():
    ap = argparse.ArgumentParser(description="speedup vs. hilos con la línea ideal")
    ap.add_argument("csv")
    ap.add_argument("--salida", help="PNG de salida (por defecto <csv>.png)")
    ap.add_argument("--titulo", default="")
    args = ap.parse_args()

    series = leer(args.csv)
    graficables = {c: v for c, v in series.items() if c != "secuencial" and not c.endswith("-seq")}
    if not graficables:
        sys.exit("graficar.py: no hay series paralelas que graficar")
    salida = args.salida or os.path.splitext(args.csv)[0] + ".png"

    # --- tabla Markdown (para pegar en el reporte) ---
    print("| config | hilos | n | mediana (s) | speedup | eficiencia | Karp–Flatt f |")
    print("|---|---|---|---|---|---|---|")
    for c in series:
        for p in sorted(series[c]):
            fila = series[c][p]
            f = karp_flatt(fila["_speedup"], p)
            print(f"| {c} | {p} | {fila.get('n', '')} | {fila['_mediana']:.4f} | {fila['_speedup']:.2f} | "
                  f"{fila['_eficiencia']:.2f} | {'—' if f != f else f'{f:.3f}'} |")

    # --- gráfica ---
    fig, ax = plt.subplots(figsize=(7, 4.5), dpi=120)
    fig.patch.set_facecolor(SURFACE)
    ax.set_facecolor(SURFACE)
    max_p = max(p for v in graficables.values() for p in v)
    ax.plot([1, max_p], [1, max_p], linestyle="--", linewidth=1.5, color="#898781", label="ideal S = p", zorder=1)
    libres = [c for c in PALETA]
    y_max = max(max_p, max(y for v in graficables.values() for y in (r["_speedup"] for r in v.values()))) * 1.1
    finales = []                                   # (y del último punto, x, etiqueta) para rotular al final
    for k, (nombre, puntos) in enumerate(graficables.items()):
        color = COLORES.get(nombre) or libres.pop(0)
        xs = sorted(puntos)
        ys = [puntos[p]["_speedup"] for p in xs]
        ax.plot(xs, ys, marker=MARCADORES[k % len(MARCADORES)], markersize=8, linewidth=2,
                color=color, markeredgecolor=SURFACE, markeredgewidth=1.5, label=nombre, zorder=3)
        finales.append([ys[-1], xs[-1], f"{nombre} {ys[-1]:.2f}"])
    # Etiquetas directas al final de cada serie, separadas al menos 4 % del eje para que no se encimen.
    finales.sort()
    gap = 0.04 * y_max
    for i in range(1, len(finales)):
        if finales[i][0] - finales[i - 1][0] < gap:
            finales[i][0] = finales[i - 1][0] + gap
    for y_txt, x_fin, texto in finales:
        ax.annotate(texto, (x_fin, y_txt), textcoords="offset points", xytext=(8, 0), va="center",
                    fontsize=9, color=INK2)
    ax.set_xlabel("hilos", color=INK2)
    ax.set_ylabel("speedup = T(1) / T(p)", color=INK2)
    ax.set_xticks(sorted({p for v in graficables.values() for p in v}))
    ax.set_xlim(0.8, max_p + 1.2)
    ax.set_ylim(0, y_max)
    ax.grid(True, color=GRID, linewidth=0.8)
    for lado in ("top", "right"):
        ax.spines[lado].set_visible(False)
    for lado in ("left", "bottom"):
        ax.spines[lado].set_color(GRID)
    ax.tick_params(colors=INK2)
    ax.set_title(args.titulo or os.path.basename(args.csv), color=INK, loc="left", fontsize=11)
    ax.legend(frameon=False, loc="upper left", fontsize=9)
    fig.tight_layout()
    fig.savefig(salida, facecolor=SURFACE)
    print(f"gráfica escrita en {salida}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
