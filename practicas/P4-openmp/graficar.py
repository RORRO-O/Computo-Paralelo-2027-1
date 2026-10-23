#!/usr/bin/env python3
"""graficar.py — Speedup y eficiencia vs. hilos a partir del CSV del protocolo (Práctica 4, Parte D).

Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · Práctica 4 (versión local y corta de
herramientas/graficar_speedup.py; solo necesita python3 y matplotlib).

Uso:
    python3 graficar.py resultados/p4.csv [--salida DIR] [--titulo "texto"] [--nucleos N]
    python3 graficar.py --pgm resultados/mandelbrot.pgm      (convierte la imagen de la Parte C a PNG)

Entrada: columnas  config,hilos,n,rep1..repR,mediana_s,speedup,eficiencia  (las escribe medir.sh).
  - Cada valor de `config` es una serie (p. ej. C-dynamic1, C-static, B-tareas).
  - Las configs que terminan en "-seq" son las referencias T(1): entran en la tabla, no en la gráfica.
  - Si una pareja config/hilos se repite, vale la última fila.
  - Los puntos con más hilos que núcleos (--nucleos; por defecto los de esta máquina) se dibujan huecos y se
    rotulan "sobre-suscripción": no son escalabilidad, son el costo de compartir núcleos.

Salida (en DIR, por defecto la carpeta del CSV):
    <nombre>_speedup.png      speedup vs. hilos, con la línea ideal S = p
    <nombre>_eficiencia.png   eficiencia vs. hilos, con las referencias E = 1 y E = 0.5
  y en pantalla la tabla Markdown (mediana, mín, máx, speedup, eficiencia, f de Karp–Flatt) para el reporte.
Con --pgm escribe <imagen>.png junto al PGM (para pegarlo en el reporte).
Código de salida 0 si generó las imágenes; 1 si el CSV o el PGM no sirven.
"""
import argparse
import csv
import os
import re
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

# Paleta categórica del curso (validada para daltonismo); el color sigue al orden de aparición de la config.
PALETA = ["#2a78d6", "#eb6834", "#1baf7a", "#eda100", "#e87ba4", "#6250d6"]
MARCADORES = ["o", "s", "D", "^", "v", "P"]          # segunda codificación: no depender solo del color
INK, INK2, MUTED, GRID, SURFACE = "#0b0b0b", "#52514e", "#898781", "#e1e0d9", "#fcfcfb"


def a_float(texto):
    try:
        v = float(texto)
    except (TypeError, ValueError):
        return None
    return v if v == v else None


def leer(ruta):
    """Devuelve (orden de configs, {config: {hilos: fila}}) con valores numéricos ya convertidos."""
    series, orden = {}, []
    with open(ruta, newline="", encoding="utf-8") as fh:
        lector = csv.DictReader(fh)
        cols = lector.fieldnames or []
        necesarias = {"config", "hilos", "n", "mediana_s", "speedup", "eficiencia"}
        if not necesarias.issubset(cols):
            sys.exit(f"graficar.py: el CSV debe tener las columnas {sorted(necesarias)}")
        reps = [c for c in cols if re.fullmatch(r"rep\d+", c)]
        for fila in lector:
            try:
                p = int(fila["hilos"])
                med = float(fila["mediana_s"])
            except (TypeError, ValueError):
                continue
            tiempos = [a_float(fila[c]) for c in reps]
            tiempos = [t for t in tiempos if t is not None]
            fila["_p"], fila["_med"] = p, med
            fila["_min"] = min(tiempos) if tiempos else None
            fila["_max"] = max(tiempos) if tiempos else None
            fila["_s"], fila["_e"] = a_float(fila["speedup"]), a_float(fila["eficiencia"])
            c = fila["config"]
            if c not in series:
                series[c] = {}
                orden.append(c)
            series[c][p] = fila
    if not series:
        sys.exit(f"graficar.py: {ruta} no tiene filas válidas")
    return orden, series, len(reps)


def karp_flatt(s, p):
    if s is None or s <= 0 or p <= 1:
        return None
    return (1.0 / s - 1.0 / p) / (1.0 - 1.0 / p)


def fmt(x, d):
    return "—" if x is None else f"{x:.{d}f}"


def tabla(orden, series, nreps):
    print(f"Mediana de {nreps} repeticiones tras 1 calentamiento; speedup = T(1) / mediana con T(1) = la "
          "fila *-seq indicada a medir.sh.\n")
    print("| config | hilos | n | mediana (s) | mín (s) | máx (s) | speedup | eficiencia | Karp–Flatt f |")
    print("|---|---|---|---|---|---|---|---|---|")
    for c in orden:
        for p in sorted(series[c]):
            f = series[c][p]
            print(f"| {c} | {p} | {f['n']} | {f['_med']:.4f} | {fmt(f['_min'], 4)} | {fmt(f['_max'], 4)} | "
                  f"{fmt(f['_s'], 2)} | {fmt(f['_e'], 2)} | {fmt(karp_flatt(f['_s'], p), 3)} |")
    print()


def figura(titulo, subtitulo):
    fig, ax = plt.subplots(figsize=(7.2, 4.6), dpi=130)
    fig.patch.set_facecolor(SURFACE)
    ax.set_facecolor(SURFACE)
    fig.suptitle(titulo, x=0.012, ha="left", fontsize=12, color=INK, fontweight="bold")
    ax.set_title(subtitulo, loc="left", fontsize=9, color=INK2)
    for lado in ("top", "right"):
        ax.spines[lado].set_visible(False)
    for lado in ("left", "bottom"):
        ax.spines[lado].set_color(GRID)
    ax.tick_params(colors=INK2)
    ax.grid(True, color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    return fig, ax


def dibujar(ax, graficables, clave, nucleos):
    """Una línea por config; puntos huecos donde hilos > nucleos; etiqueta directa al final de cada serie."""
    finales = []
    for k, (nombre, puntos) in enumerate(graficables.items()):
        color, marca = PALETA[k % len(PALETA)], MARCADORES[k % len(MARCADORES)]
        xs = [p for p in sorted(puntos) if puntos[p][clave] is not None]
        ys = [puntos[p][clave] for p in xs]
        if not xs:
            continue
        ax.plot(xs, ys, color=color, linewidth=2, zorder=3)
        ax.plot([], [], color=color, linewidth=2, marker=marca, markersize=7, markeredgecolor=SURFACE,
                label=nombre)                       # entrada de la leyenda con color Y marcador
        for x, y in zip(xs, ys):
            hueco = nucleos is not None and x > nucleos
            ax.plot([x], [y], marker=marca, markersize=8, zorder=4, linestyle="none",
                    markerfacecolor=SURFACE if hueco else color, markeredgecolor=color if hueco else SURFACE,
                    markeredgewidth=2 if hueco else 1.5)
        finales.append([ys[-1], xs[-1], f"{nombre} {ys[-1]:.2f}"])
    return finales


def rotular(ax, finales, y_max):
    finales.sort()
    gap = 0.045 * y_max
    for i in range(1, len(finales)):
        if finales[i][0] - finales[i - 1][0] < gap:
            finales[i][0] = finales[i - 1][0] + gap
    for y, x, texto in finales:
        ax.annotate(texto, (x, y), textcoords="offset points", xytext=(9, 0), va="center", fontsize=9,
                    color=INK2)


def pgm_a_png(ruta):
    """Lee un PGM binario (P5, 8 bits) como el que escribe c_mandel.h y lo guarda como PNG en escala de grises."""
    with open(ruta, "rb") as fh:
        datos = fh.read()
    campos, pos = [], 0
    while len(campos) < 4:                        # "P5", ancho, alto, máximo; separados por espacios
        while datos[pos:pos + 1].isspace():
            pos += 1
        fin = pos
        while not datos[fin:fin + 1].isspace():
            fin += 1
        campos.append(datos[pos:fin].decode("ascii"))
        pos = fin
    if campos[0] != "P5" or int(campos[3]) > 255:
        sys.exit(f"graficar.py: {ruta} no es un PGM P5 de 8 bits")
    ancho, alto = int(campos[1]), int(campos[2])
    pixeles = datos[pos + 1:pos + 1 + ancho * alto]
    if len(pixeles) != ancho * alto:
        sys.exit(f"graficar.py: {ruta} está incompleto")
    filas = [list(pixeles[r * ancho:(r + 1) * ancho]) for r in range(alto)]
    salida = os.path.splitext(ruta)[0] + ".png"
    plt.imsave(salida, filas, cmap="gray", vmin=0, vmax=255)
    print(f"imagen escrita: {salida} ({ancho}x{alto})")
    return 0


def main():
    ap = argparse.ArgumentParser(description="speedup y eficiencia vs. hilos (CSV del protocolo)")
    ap.add_argument("csv", nargs="?")
    ap.add_argument("--pgm", help="convierte este PGM a PNG y termina")
    ap.add_argument("--salida", help="carpeta de salida (por defecto, la del CSV)")
    ap.add_argument("--titulo", default="Práctica 4")
    ap.add_argument("--nucleos", type=int, default=os.cpu_count(),
                    help="núcleos de la máquina de medición (más hilos = sobre-suscripción)")
    args = ap.parse_args()
    if args.pgm:
        return pgm_a_png(args.pgm)
    if not args.csv:
        ap.error("falta el CSV (o --pgm IMAGEN)")

    orden, series, nreps = leer(args.csv)
    tabla(orden, series, nreps)
    graficables = {c: series[c] for c in orden if not c.endswith("-seq")}
    graficables = {c: {p: {"s": f["_s"], "e": f["_e"]} for p, f in v.items()} for c, v in graficables.items()}
    if not any(f["s"] is not None for v in graficables.values() for f in v.values()):
        sys.exit("graficar.py: no hay series paralelas con speedup numérico (¿faltó --base en medir.sh?)")
    salida = args.salida or os.path.dirname(os.path.abspath(args.csv))
    os.makedirs(salida, exist_ok=True)
    base = os.path.splitext(os.path.basename(args.csv))[0]
    hilos = sorted({p for v in graficables.values() for p in v})
    max_p = max(hilos)
    nota = (f"{nreps} repeticiones por punto, mediana · puntos huecos: más hilos que núcleos "
            f"({args.nucleos}), sobre-suscripción")

    # --- speedup ---
    fig, ax = figura(f"{args.titulo}: speedup", nota)
    ax.plot([1, max_p], [1, max_p], linestyle="--", linewidth=1.5, color=MUTED, zorder=1, label="ideal S = p")
    finales = dibujar(ax, {c: {p: {"y": f["s"]} for p, f in v.items()} for c, v in graficables.items()},
                      "y", args.nucleos)
    y_max = max([max_p] + [f[0] for f in finales]) * 1.12
    rotular(ax, finales, y_max)
    ax.set_xlabel("hilos (OMP_NUM_THREADS)", color=INK2)
    ax.set_ylabel("speedup  S(p) = T(1) / T(p)", color=INK2)
    ax.set_xticks(hilos)
    ax.set_xlim(0.7, max_p * 1.32)
    ax.set_ylim(0, y_max)
    ax.legend(frameon=False, loc="upper left", fontsize=9)
    fig.tight_layout()
    ruta_s = os.path.join(salida, f"{base}_speedup.png")
    fig.savefig(ruta_s, facecolor=SURFACE)
    plt.close(fig)

    # --- eficiencia ---
    fig, ax = figura(f"{args.titulo}: eficiencia", nota)
    ax.axhline(1.0, linestyle="--", linewidth=1.5, color=MUTED, zorder=1, label="ideal E = 1")
    ax.axhline(0.5, linestyle=":", linewidth=1.5, color=MUTED, zorder=1, label="E = 0.5")
    finales = dibujar(ax, {c: {p: {"y": f["e"]} for p, f in v.items()} for c, v in graficables.items()},
                      "y", args.nucleos)
    y_top = max([1.0] + [f[0] for f in finales]) * 1.15
    rotular(ax, finales, y_top)
    ax.set_xlabel("hilos (OMP_NUM_THREADS)", color=INK2)
    ax.set_ylabel("eficiencia  E(p) = S(p) / p", color=INK2)
    ax.set_xticks(hilos)
    ax.set_xlim(0.7, max_p * 1.32)
    ax.set_ylim(0, y_top)
    ax.legend(frameon=False, loc="lower left", fontsize=9)
    fig.tight_layout()
    ruta_e = os.path.join(salida, f"{base}_eficiencia.png")
    fig.savefig(ruta_e, facecolor=SURFACE)
    plt.close(fig)
    print(f"gráficas escritas: {ruta_s} y {ruta_e}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
