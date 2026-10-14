#!/usr/bin/env python3
"""graficar_speedup.py — Gráficas de speedup y eficiencia a partir del CSV del protocolo de medición.

Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · herramientas/

Uso:
    python3 graficar_speedup.py resultados.csv [--salida CARPETA] [--titulo "texto"] [--n N]
                                               [--base CONFIG] [--recalcular]

Entrada: un CSV con las columnas del protocolo (herramientas/protocolo-medicion.md §4):
    config,hilos,n,rep1,...,repR,mediana_s,speedup,eficiencia
  - El número de columnas rep es libre (rep1..rep3, rep1..rep5, rep1..rep10...). Se aceptan columnas extra
    (p. ej. min_s,max_s de run_all.sh) y se ignoran.
  - Cada valor distinto de `config` es una serie (secuencial, openmp, openmp-dynamic, mpi, V2...).
  - Filas con `hilos` no numérico (p. ej. gpu) no entran en las gráficas de líneas; se avisa.
  - Si hay varios tamaños n, se grafica el mayor que tenga una fila con hilos=1 (o el que indiques con --n).

Speedup y eficiencia: se usan las columnas del CSV cuando son numéricas. Si están vacías o en NA, o si pasas
--recalcular, se calculan como S(p) = T(1) / mediana_s, con T(1) = la mediana de la primera fila con hilos=1 y
ese n (o de la fila hilos=1 de la config que indiques con --base, p. ej. --base secuencial), y E(p) = S(p)/p.

Salida (en CARPETA, por defecto la carpeta del CSV):
    speedup.png      speedup vs hilos por config, con la línea ideal S = p
    eficiencia.png   eficiencia vs hilos por config, con la referencia E = 1
También imprime en pantalla la tabla en Markdown (mediana, speedup, eficiencia, f de Karp–Flatt) para pegarla
en el reporte. Código de salida 0 si generó las dos imágenes; 1 si el CSV no sirve.

Ejemplo ejecutable (desde herramientas/):
    python3 graficar_speedup.py ejemplo_resultados.csv --titulo "pi por rectángulos" --salida pruebas-tmp

Requiere: python3 y matplotlib (sin pandas).
"""
import argparse
import csv
import os
import re
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

# Paleta categórica del curso (misma que proyecto/plantillas/graficar_proyecto.py): el color sigue a la
# config, no a su posición. Nombres conocidos tienen color fijo; el resto toma el siguiente libre en orden.
COLORES_FIJOS = {
    "secuencial": "#2a78d6", "v1": "#2a78d6", "seq": "#2a78d6",
    "openmp": "#eb6834", "v2": "#eb6834", "omp": "#eb6834",
    "mpi": "#1baf7a", "v3": "#1baf7a", "gpu": "#1baf7a",
}
PALETA = ["#2a78d6", "#eb6834", "#1baf7a", "#eda100", "#e87ba4", "#008300", "#6250d6", "#e34948"]
INK, INK2, MUTED, GRID, SURFACE = "#0b0b0b", "#52514e", "#898781", "#e1e0d9", "#fcfcfb"
MARCADORES = ["o", "s", "D", "^", "v", "P", "X", "*"]  # segunda codificación: la identidad no depende solo del color


def a_float(texto):
    try:
        v = float(str(texto).strip())
    except (TypeError, ValueError):
        return None
    return v if v == v else None  # descarta NaN


def leer_csv(ruta):
    with open(ruta, newline="", encoding="utf-8") as fh:
        lector = csv.DictReader(fh)
        columnas = [c.strip() for c in (lector.fieldnames or [])]
        requeridas = ["config", "hilos", "n", "mediana_s"]
        faltan = [c for c in requeridas if c not in columnas]
        if faltan:
            sys.exit(f"El CSV {ruta} no tiene las columnas {faltan}. Encabezado esperado: "
                     "config,hilos,n,rep1..repR,mediana_s,speedup,eficiencia")
        reps_cols = sorted((c for c in columnas if re.fullmatch(r"rep\d+", c)), key=lambda c: int(c[3:]))
        filas = []
        for num, fila in enumerate(lector, start=2):
            fila = {(k or "").strip(): (v or "").strip() for k, v in fila.items() if k is not None}
            mediana = a_float(fila.get("mediana_s"))
            if mediana is None or mediana <= 0:
                print(f"AVISO: fila {num} sin mediana_s válida; se omite.", file=sys.stderr)
                continue
            try:
                n = int(float(fila.get("n", "")))
            except ValueError:
                print(f"AVISO: fila {num} sin n numérico; se omite.", file=sys.stderr)
                continue
            hilos = fila.get("hilos", "")
            reps = [a_float(fila.get(c)) for c in reps_cols]
            reps = [r for r in reps if r is not None]
            filas.append({
                "config": fila.get("config", "") or "sin-nombre",
                "hilos": hilos,
                "p": int(hilos) if hilos.isdigit() and int(hilos) >= 1 else None,
                "n": n,
                "mediana": mediana,
                "min": min(reps) if reps else None,
                "max": max(reps) if reps else None,
                "speedup_csv": a_float(fila.get("speedup")),
                "eficiencia_csv": a_float(fila.get("eficiencia")),
            })
    if not filas:
        sys.exit(f"El CSV {ruta} no tiene filas válidas.")
    return filas, len(reps_cols)


def elegir_n(filas, n_pedido):
    con_base = sorted({f["n"] for f in filas if f["p"] == 1})
    todos = sorted({f["n"] for f in filas})
    if n_pedido is not None:
        if n_pedido not in todos:
            sys.exit(f"No hay filas con n={n_pedido}. Valores disponibles: {todos}")
        return n_pedido
    candidatos = con_base or todos
    if len(candidatos) > 1:
        print(f"AVISO: hay varios n ({candidatos}); se grafica n={candidatos[-1]}. Usa --n para elegir otro.",
              file=sys.stderr)
    return candidatos[-1]


def linea_base(sel, base_config):
    """Mediana de la fila hilos=1 que sirve de T(1); None si no existe."""
    candidatas = [f for f in sel if f["p"] == 1]
    if base_config:
        candidatas = [f for f in candidatas if f["config"] == base_config]
        if not candidatas:
            sys.exit(f"No hay fila con config={base_config} e hilos=1 para este n (--base).")
    if not candidatas:
        return None, None
    return candidatas[0]["mediana"], candidatas[0]["config"]


def calcular(sel, t1, recalcular):
    sin_dato = 0
    for f in sel:
        s = None if recalcular else f["speedup_csv"]
        if s is None and t1 is not None:
            s = t1 / f["mediana"]
        f["speedup"] = s
        e = None if recalcular else f["eficiencia_csv"]
        if e is None and s is not None and f["p"]:
            e = s / f["p"]
        f["eficiencia"] = e
        f["kf"] = (1 / s - 1 / f["p"]) / (1 - 1 / f["p"]) if s and f["p"] and f["p"] > 1 else None
        if s is None:
            sin_dato += 1
    return sin_dato


def fmt(x, dec=3):
    return "—" if x is None else f"{x:.{dec}f}"


def tabla_markdown(sel, n, t1, base_nombre, nreps):
    origen = f"T(1) = {t1:.6f} s (config {base_nombre}, hilos=1)" if t1 else "speedup tomado del CSV"
    lineas = [
        f"Tamaño del problema n = {n}; {nreps} repeticiones por fila; {origen}.",
        "",
        "| Config | Hilos | Mediana (s) | Mín (s) | Máx (s) | Speedup | Eficiencia | f Karp–Flatt |",
        "|---|---|---|---|---|---|---|---|",
    ]
    for f in sorted(sel, key=lambda f: (f["config"], f["p"] or 10**9)):
        lineas.append(
            f"| {f['config']} | {f['hilos']} | {f['mediana']:.6f} | {fmt(f['min'], 6)} | {fmt(f['max'], 6)} "
            f"| {fmt(f['speedup'], 2)} | {fmt(f['eficiencia'], 2)} | {fmt(f['kf'], 3)} |"
        )
    return "\n".join(lineas) + "\n"


def series_numericas(sel, clave):
    """{config: [(p, valor), ...]} solo con hilos numéricos y valor disponible, ordenado por p."""
    series = {}
    for f in sel:
        if f["p"] is None or f.get(clave) is None:
            continue
        series.setdefault(f["config"], []).append((f["p"], f[clave]))
    return {k: sorted(v) for k, v in series.items()}


def asignar_colores(configs):
    colores, usados = {}, set()
    for c in configs:
        fijo = COLORES_FIJOS.get(c.lower().split("-")[0])
        if fijo and fijo not in usados:
            colores[c] = fijo
            usados.add(fijo)
    for c in configs:
        if c not in colores:
            libre = next((h for h in PALETA if h not in usados), PALETA[len(usados) % len(PALETA)])
            colores[c] = libre
            usados.add(libre)
    return colores


def nueva_figura(titulo, subtitulo):
    fig, ax = plt.subplots(figsize=(7, 4.4), dpi=150)
    fig.patch.set_facecolor(SURFACE)
    fig.suptitle(titulo, x=0.01, ha="left", fontsize=12, color=INK, fontweight="bold")
    ax.set_title(subtitulo, loc="left", fontsize=9, color=INK2)
    ax.set_facecolor(SURFACE)
    for lado in ("top", "right"):
        ax.spines[lado].set_visible(False)
    for lado in ("left", "bottom"):
        ax.spines[lado].set_color(MUTED)
        ax.spines[lado].set_linewidth(0.8)
    ax.tick_params(colors=INK2, labelsize=9)
    ax.grid(True, color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    return fig, ax


def dibujar(series, colores, ax):
    for i, (config, pts) in enumerate(series.items()):
        xs = [p for p, _ in pts]
        ys = [v for _, v in pts]
        solo_un_punto = len(pts) == 1
        ax.plot(xs, ys, marker=MARCADORES[i % len(MARCADORES)], markersize=7, linewidth=2,
                color=colores[config], label=config, markeredgecolor=SURFACE, markeredgewidth=1,
                zorder=3 if solo_un_punto else 2)
        # Etiqueta directa solo en el último punto; una serie de un solo punto (la secuencial) se etiqueta
        # arriba a la izquierda para no chocar con las demás series en p = 1.
        ax.annotate(f"{ys[-1]:.2f}", (xs[-1], ys[-1]), textcoords="offset points",
                    xytext=(-6, 8) if solo_un_punto else (6, -4), ha="right" if solo_un_punto else "left",
                    fontsize=9, color=INK2)


def graficar_speedup(series, colores, n, carpeta, titulo):
    fig, ax = nueva_figura(titulo or "Speedup", f"n = {n}; mediana de las repeticiones; S(p) = T(1) / T(p)")
    ps = sorted({p for pts in series.values() for p, _ in pts} | {1})
    ax.plot(ps, ps, color=MUTED, linewidth=1.2, linestyle="--", label="Ideal S = p")
    dibujar(series, colores, ax)
    ax.set_xticks(ps)
    ax.set_xlabel("Hilos o procesos (p)", color=INK2)
    ax.set_ylabel("Speedup S(p)", color=INK2)
    ax.set_xlim(left=0.8)
    ax.set_ylim(bottom=0)
    ax.legend(frameon=False, fontsize=9, labelcolor=INK2)
    fig.tight_layout()
    ruta = os.path.join(carpeta, "speedup.png")
    fig.savefig(ruta)
    plt.close(fig)
    return ruta


def graficar_eficiencia(series, colores, n, carpeta, titulo):
    fig, ax = nueva_figura(titulo or "Eficiencia", f"n = {n}; E(p) = S(p) / p")
    ps = sorted({p for pts in series.values() for p, _ in pts} | {1})
    ax.axhline(1.0, color=MUTED, linewidth=1.2, linestyle="--", label="Ideal E = 1")
    dibujar(series, colores, ax)
    tope = max((v for pts in series.values() for _, v in pts), default=1.0)
    ax.set_xticks(ps)
    ax.set_xlabel("Hilos o procesos (p)", color=INK2)
    ax.set_ylabel("Eficiencia E(p)", color=INK2)
    ax.set_xlim(left=0.8)
    ax.set_ylim(0, max(1.15, tope * 1.15))
    ax.legend(frameon=False, fontsize=9, labelcolor=INK2)
    fig.tight_layout()
    ruta = os.path.join(carpeta, "eficiencia.png")
    fig.savefig(ruta)
    plt.close(fig)
    return ruta


def main():
    ap = argparse.ArgumentParser(description="speedup.png y eficiencia.png a partir del CSV del protocolo")
    ap.add_argument("csv", help="CSV con las columnas del protocolo")
    ap.add_argument("--salida", help="carpeta de salida (por defecto la del CSV)")
    ap.add_argument("--titulo", help="título de las gráficas (p. ej. el nombre del problema)")
    ap.add_argument("--n", type=int, help="tamaño del problema a graficar si el CSV tiene varios")
    ap.add_argument("--base", help="config cuya fila hilos=1 es T(1) al (re)calcular, p. ej. secuencial")
    ap.add_argument("--recalcular", action="store_true",
                    help="ignora las columnas speedup/eficiencia del CSV y recalcúlalas desde mediana_s")
    args = ap.parse_args()

    filas, nreps = leer_csv(args.csv)
    n = elegir_n(filas, args.n)
    sel = [f for f in filas if f["n"] == n]
    t1, base_nombre = linea_base(sel, args.base)
    sin_dato = calcular(sel, t1, args.recalcular)
    if sin_dato:
        print(f"AVISO: {sin_dato} fila(s) sin speedup: el CSV no lo trae y no hay fila con hilos=1 para n={n}. "
              "Mide primero la versión secuencial o usa --base.", file=sys.stderr)
    no_numericas = [f for f in sel if f["p"] is None]
    if no_numericas:
        print("AVISO: filas con hilos no numérico fuera de las gráficas de líneas: "
              + ", ".join(f"{f['config']}({f['hilos']})" for f in no_numericas), file=sys.stderr)

    print(tabla_markdown(sel, n, t1, base_nombre, nreps))

    series_s = series_numericas(sel, "speedup")
    series_e = series_numericas(sel, "eficiencia")
    if not series_s:
        sys.exit("No hay ninguna fila con hilos numérico y speedup: no se pueden generar las gráficas.")
    colores = asignar_colores(list(dict.fromkeys(list(series_s) + list(series_e))))
    carpeta = args.salida or os.path.dirname(os.path.abspath(args.csv))
    os.makedirs(carpeta, exist_ok=True)
    generadas = [graficar_speedup(series_s, colores, n, carpeta, args.titulo),
                 graficar_eficiencia(series_e, colores, n, carpeta, args.titulo)]
    print("Archivos generados:", ", ".join(generadas))


if __name__ == "__main__":
    main()
