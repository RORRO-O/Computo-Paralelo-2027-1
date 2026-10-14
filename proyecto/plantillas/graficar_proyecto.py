#!/usr/bin/env python3
"""graficar_proyecto.py — Tabla en Markdown y gráficas del proyecto a partir del CSV de run_all.sh.

Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · Plantilla del proyecto integrador

Uso:
    python3 graficar_proyecto.py resultados/mediciones.csv [--salida CARPETA] [--n N] [--titulo "texto"]

Lee un CSV con las columnas del protocolo (config,hilos,n,rep1..repR,mediana_s,speedup,eficiencia[,min_s,max_s]).
Toma como línea base la fila "V1" con hilos=1 y el mismo n (si el CSV tiene varios n, usa --n; sin --n toma
el mayor n que tenga fila V1). Recalcula speedup y eficiencia respecto a esa base, calcula la fracción
secuencial de Karp–Flatt f = (1/S - 1/p) / (1 - 1/p) para las filas con hilos numéricos p > 1, imprime la
tabla en Markdown (para pegar en el reporte) y escribe en CARPETA (por defecto la carpeta del CSV):

    tabla.md          la tabla en Markdown
    speedup.png       speedup vs hilos de cada versión con hilos numéricos, con la línea ideal S = p
    eficiencia.png    eficiencia vs hilos, con la referencia E = 1
    comparacion.png   tiempo (mediana) de V1, del mejor punto de cada versión con hilos y de las filas gpu
                      (p. ej. V3 y V3-kernel); barras con el valor al final

Ejemplo ejecutable (desde esta carpeta, después de los ejemplos de run_all.sh o de `make test`):
    python3 graficar_proyecto.py resultados-prueba/mediciones.csv

Requiere: python3, numpy, matplotlib. Código de salida 0 si generó todo; 1 si el CSV no sirve.
"""
import argparse
import csv
import os
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

# Colores fijos por versión (el color sigue a la entidad, no a su posición en la gráfica).
COLORES = {"V1": "#2a78d6", "V2": "#eb6834", "V3": "#1baf7a"}
EXTRA = ["#eda100", "#e87ba4", "#6250d6", "#e34948"]
INK = "#0b0b0b"
INK2 = "#52514e"
MUTED = "#898781"
GRID = "#e1e0d9"
SURFACE = "#fcfcfb"


def color_de(config, asignados):
    base = config.split("-")[0]
    if base in COLORES:
        return COLORES[base]
    if base not in asignados:
        asignados[base] = EXTRA[len(asignados) % len(EXTRA)]
    return asignados[base]


def leer_csv(ruta):
    with open(ruta, newline="", encoding="utf-8") as fh:
        lector = csv.DictReader(fh)
        requeridas = {"config", "hilos", "n", "mediana_s"}
        if not lector.fieldnames or not requeridas.issubset(lector.fieldnames):
            sys.exit(f"El CSV {ruta} no tiene las columnas {sorted(requeridas)}")
        filas = []
        for fila in lector:
            try:
                mediana = float(fila["mediana_s"])
                n = int(fila["n"])
            except (TypeError, ValueError):
                continue
            if mediana <= 0:
                continue
            hilos = fila["hilos"].strip()
            p = int(hilos) if hilos.isdigit() else None
            filas.append(
                {
                    "config": fila["config"].strip(),
                    "p": p,
                    "hilos": hilos,
                    "n": n,
                    "mediana": mediana,
                    "min": fila.get("min_s", ""),
                    "max": fila.get("max_s", ""),
                }
            )
    if not filas:
        sys.exit(f"El CSV {ruta} no tiene filas válidas")
    return filas


def elegir_n(filas, n_pedido):
    con_v1 = sorted({f["n"] for f in filas if f["config"] == "V1" and f["p"] == 1})
    if not con_v1:
        sys.exit("No hay fila V1 con hilos=1: sin línea base no hay speedup. Mide V1 primero.")
    if n_pedido is None:
        if len(con_v1) > 1:
            print(f"AVISO: hay varios n con V1 ({con_v1}); se usa el mayor. Usa --n para elegir otro.", file=sys.stderr)
        return con_v1[-1]
    if n_pedido not in con_v1:
        sys.exit(f"No hay fila V1 con n={n_pedido}. Valores disponibles: {con_v1}")
    return n_pedido


def fmt(x, dec=3):
    return "—" if x is None else f"{x:.{dec}f}"


def calcular(filas, n):
    sel = [f for f in filas if f["n"] == n]
    base = [f for f in sel if f["config"] == "V1" and f["p"] == 1]
    if len(base) > 1:
        print("AVISO: hay más de una fila V1 con hilos=1; se usa la primera.", file=sys.stderr)
    t1 = base[0]["mediana"]
    for f in sel:
        s = t1 / f["mediana"]
        f["speedup"] = s
        f["eficiencia"] = s / f["p"] if f["p"] else None
        f["kf"] = (1 / s - 1 / f["p"]) / (1 - 1 / f["p"]) if f["p"] and f["p"] > 1 else None
    return sel, t1


def tabla_markdown(sel, n, t1):
    lineas = [
        f"Tamaño del problema n = {n}; línea base T(1) = V1 = {t1:.6f} s (mediana de las repeticiones).",
        "",
        "| Versión | Hilos | Mediana (s) | Mín (s) | Máx (s) | Speedup | Eficiencia | f Karp–Flatt |",
        "|---|---|---|---|---|---|---|---|",
    ]
    for f in sel:
        lineas.append(
            f"| {f['config']} | {f['hilos']} | {f['mediana']:.6f} | {f['min'] or '—'} | {f['max'] or '—'} "
            f"| {fmt(f['speedup'], 2)} | {fmt(f['eficiencia'], 2)} | {fmt(f['kf'], 3)} |"
        )
    return "\n".join(lineas) + "\n"


def estilo(ax):
    ax.set_facecolor(SURFACE)
    for lado in ("top", "right"):
        ax.spines[lado].set_visible(False)
    for lado in ("left", "bottom"):
        ax.spines[lado].set_color(MUTED)
        ax.spines[lado].set_linewidth(0.8)
    ax.tick_params(colors=INK2, labelsize=9)
    ax.grid(True, color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)


def nueva_figura(titulo, subtitulo):
    fig, ax = plt.subplots(figsize=(7, 4.4), dpi=150)
    fig.patch.set_facecolor(SURFACE)
    fig.suptitle(titulo, x=0.01, ha="left", fontsize=12, color=INK, fontweight="bold")
    ax.set_title(subtitulo, loc="left", fontsize=9, color=INK2)
    estilo(ax)
    return fig, ax


def series_con_hilos(sel):
    """{config: [(p, fila), ...]} para configs con hilos numéricos, excluyendo V1 y filas *-kernel."""
    series = {}
    for f in sel:
        if f["p"] is None or f["config"] == "V1":
            continue
        series.setdefault(f["config"], []).append((f["p"], f))
    return {k: sorted(v) for k, v in series.items()}


def graficar_speedup(series, n, carpeta, titulo, asignados):
    fig, ax = nueva_figura(titulo or "Speedup frente a V1", f"n = {n}; mediana de las repeticiones; S(p) = T_V1 / T(p)")
    ps = sorted({p for pts in series.values() for p, _ in pts} | {1})
    ax.plot(ps, ps, color=MUTED, linewidth=1.2, linestyle="--", label="Ideal S = p")
    for config, pts in series.items():
        xs = [p for p, _ in pts]
        ys = [f["speedup"] for _, f in pts]
        ax.plot(xs, ys, marker="o", markersize=7, linewidth=2, color=color_de(config, asignados), label=config)
        ax.annotate(f"{ys[-1]:.2f}", (xs[-1], ys[-1]), textcoords="offset points", xytext=(6, -4), fontsize=9, color=INK2)
    ax.set_xticks(ps)
    ax.set_xlabel("Hilos (p)", color=INK2)
    ax.set_ylabel("Speedup S(p)", color=INK2)
    ax.set_xlim(left=0.8)
    ax.set_ylim(bottom=0)
    ax.legend(frameon=False, fontsize=9, labelcolor=INK2)
    fig.tight_layout()
    fig.savefig(os.path.join(carpeta, "speedup.png"))
    plt.close(fig)


def graficar_eficiencia(series, n, carpeta, titulo, asignados):
    fig, ax = nueva_figura(titulo or "Eficiencia frente a V1", f"n = {n}; E(p) = S(p) / p")
    ps = sorted({p for pts in series.values() for p, _ in pts} | {1})
    ax.axhline(1.0, color=MUTED, linewidth=1.2, linestyle="--", label="Ideal E = 1")
    for config, pts in series.items():
        xs = [p for p, _ in pts]
        ys = [f["eficiencia"] for _, f in pts]
        ax.plot(xs, ys, marker="o", markersize=7, linewidth=2, color=color_de(config, asignados), label=config)
        ax.annotate(f"{ys[-1]:.2f}", (xs[-1], ys[-1]), textcoords="offset points", xytext=(6, -4), fontsize=9, color=INK2)
    ax.set_xticks(ps)
    ax.set_xlabel("Hilos (p)", color=INK2)
    ax.set_ylabel("Eficiencia E(p)", color=INK2)
    ax.set_xlim(left=0.8)
    ax.set_ylim(0, max(1.15, max((f["eficiencia"] for pts in series.values() for _, f in pts), default=1) * 1.15))
    ax.legend(frameon=False, fontsize=9, labelcolor=INK2)
    fig.tight_layout()
    fig.savefig(os.path.join(carpeta, "eficiencia.png"))
    plt.close(fig)


def graficar_comparacion(sel, series, n, carpeta, titulo, asignados):
    barras = []  # (etiqueta, tiempo, color, hatch)
    v1 = next(f for f in sel if f["config"] == "V1" and f["p"] == 1)
    barras.append(("V1 (1 hilo)", v1["mediana"], COLORES["V1"], None))
    for config, pts in series.items():
        p, f = min(pts, key=lambda pf: pf[1]["mediana"])
        barras.append((f"{config} ({p} hilos)", f["mediana"], color_de(config, asignados), None))
    for f in sel:
        if f["p"] is None:
            hatch = "//" if f["config"].endswith("-kernel") else None
            sufijo = "sin transferencias" if hatch else "con transferencias"
            barras.append((f"{f['config']} ({f['hilos']}, {sufijo})", f["mediana"], color_de(f["config"], asignados), hatch))
    if len(barras) < 2:
        return False
    fig, ax = nueva_figura(titulo or "Tiempo por versión", f"n = {n}; mediana de las repeticiones; menor es mejor")
    ys = range(len(barras))
    tiempos = [b[1] for b in barras]
    for y, (etq, t, col, hatch) in zip(ys, barras):
        ax.barh(y, t, height=0.55, color=col, edgecolor=SURFACE, linewidth=1.5, hatch=hatch)
    log = max(tiempos) / min(tiempos) > 50
    if log:
        ax.set_xscale("log")
    for y, t in zip(ys, tiempos):
        ax.annotate(f"{t:.4f} s", (t, y), textcoords="offset points", xytext=(5, 0), va="center", fontsize=9, color=INK)
    ax.set_yticks(list(ys))
    ax.set_yticklabels([b[0] for b in barras], color=INK2)
    ax.invert_yaxis()
    ax.set_xlabel("Tiempo (s)" + (" — escala logarítmica" if log else ""), color=INK2)
    ax.grid(True, axis="x", color=GRID, linewidth=0.8)
    ax.grid(False, axis="y")
    if not log:
        ax.set_xlim(0, max(tiempos) * 1.25)
    fig.tight_layout()
    fig.savefig(os.path.join(carpeta, "comparacion.png"))
    plt.close(fig)
    return True


def main():
    ap = argparse.ArgumentParser(description="Tabla y gráficas del proyecto a partir del CSV de run_all.sh")
    ap.add_argument("csv", help="CSV con las columnas del protocolo")
    ap.add_argument("--salida", help="carpeta de salida (por defecto la del CSV)")
    ap.add_argument("--n", type=int, help="tamaño del problema a graficar si el CSV tiene varios")
    ap.add_argument("--titulo", help="título de las gráficas (p. ej. el nombre del problema)")
    args = ap.parse_args()

    filas = leer_csv(args.csv)
    n = elegir_n(filas, args.n)
    sel, t1 = calcular(filas, n)
    carpeta = args.salida or os.path.dirname(os.path.abspath(args.csv))
    os.makedirs(carpeta, exist_ok=True)

    tabla = tabla_markdown(sel, n, t1)
    with open(os.path.join(carpeta, "tabla.md"), "w", encoding="utf-8") as fh:
        fh.write(tabla)
    print(tabla)

    asignados = {}
    series = series_con_hilos(sel)
    generadas = ["tabla.md"]
    if series:
        graficar_speedup(series, n, carpeta, args.titulo, asignados)
        graficar_eficiencia(series, n, carpeta, args.titulo, asignados)
        generadas += ["speedup.png", "eficiencia.png"]
    else:
        print("AVISO: no hay versiones con hilos numéricos distintas de V1; no se generan speedup/eficiencia.", file=sys.stderr)
    if graficar_comparacion(sel, series, n, carpeta, args.titulo, asignados):
        generadas.append("comparacion.png")
    print("Archivos generados en", carpeta + ":", ", ".join(generadas))


if __name__ == "__main__":
    main()
