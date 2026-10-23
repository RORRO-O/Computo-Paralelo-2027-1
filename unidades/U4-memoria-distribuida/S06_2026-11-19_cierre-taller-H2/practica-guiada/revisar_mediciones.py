#!/usr/bin/env python3
"""revisar_mediciones.py — Revisa un CSV de mediciones contra el protocolo del curso.

Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · Práctica guiada S06 (taller hacia H2)

Uso:
    python3 revisar_mediciones.py resultados/mediciones.csv [--nucleos 4] [--png speedup.png]

Lee las columnas del protocolo (herramientas/protocolo-medicion.md §4):
    config,hilos,n,rep1,...,repK,mediana_s,speedup,eficiencia[,min_s,max_s]
Recalcula mediana, mínimo, máximo, speedup = T(1) / mediana, eficiencia = speedup / p y la fracción
secuencial de Karp–Flatt f(p) = (1/S − 1/p) / (1 − 1/p) tomando como T(1) la fila V1 con 1 hilo.
Imprime la tabla en Markdown (para pegar en reporte/H2.md) y una lista de hallazgos:

    ERROR  Ex  invalida la medición según el protocolo §5 (hay que rehacerla)
    AVISO  Ax  hay que declararlo o explicarlo en el reporte

Código de salida: 0 si no hay errores (puede haber avisos); 1 si hay al menos un error; 2 si el CSV no sirve.

Lo que este revisor NO puede ver (eso lo hace tu pareja de revisión con la lista de cotejo): si T(1) es
de verdad el mejor secuencial que tienen, si el texto explica dónde deja de escalar y por qué, y si la
predicción se escribió antes de medir.

Requiere python3 (biblioteca estándar). La gráfica (--png) usa matplotlib si está instalado.
"""
import argparse
import csv
import statistics
import sys

TOL = 0.02  # tolerancia relativa para comparar lo reportado con lo recalculado (2 %)


class Row:
    """Una fila del CSV ya convertida a números."""

    def __init__(self, d, rep_cols):
        self.config = (d.get("config") or "").strip()
        h = (d.get("hilos") or "").strip()
        self.hilos = int(h) if h.isdigit() else h          # 'gpu' u otra etiqueta se deja como texto
        self.n = (d.get("n") or "").strip()
        self.reps = []
        for c in rep_cols:
            v = _num(d.get(c))
            if v is not None:
                self.reps.append(v)
        self.mediana_rep = _num(d.get("mediana_s"))
        self.speedup_rep = _num(d.get("speedup"))
        self.eficiencia_rep = _num(d.get("eficiencia"))

    @property
    def label(self):
        return f"{self.config},{self.hilos}"

    @property
    def mediana(self):
        return statistics.median(self.reps) if self.reps else self.mediana_rep


def _num(s):
    try:
        return float(s)
    except (TypeError, ValueError):
        return None


def _close(a, b, tol=TOL):
    return a is not None and b is not None and b != 0 and abs(a - b) / abs(b) <= tol


def karp_flatt(speedup, p):
    return (1.0 / speedup - 1.0 / p) / (1.0 - 1.0 / p)


def read_rows(path):
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        if reader.fieldnames is None:
            raise ValueError("CSV vacío")
        cols = [c.strip() for c in reader.fieldnames]
        for required in ("config", "hilos", "n", "mediana_s"):
            if required not in cols:
                raise ValueError(f"falta la columna '{required}' (encabezado del protocolo: "
                                 "config,hilos,n,rep1..rep5,mediana_s,speedup,eficiencia)")
        rep_cols = sorted((c for c in cols if c.startswith("rep") and c[3:].isdigit()),
                          key=lambda c: int(c[3:]))
        if not rep_cols:
            raise ValueError("no hay columnas rep1..repK: el protocolo exige las repeticiones, no solo la mediana")
        rows = [Row({k.strip(): v for k, v in d.items() if k}, rep_cols) for d in reader]
    rows = [r for r in rows if r.config]
    if not rows:
        raise ValueError("el CSV no tiene filas de datos")
    return rows


def revisar(rows, nucleos=None):
    errors, warnings = [], []
    err = lambda code, msg: errors.append(f"ERROR {code}  {msg}")
    warn = lambda code, msg: warnings.append(f"AVISO {code}  {msg}")

    # --- E1: la línea base es V1 con 1 hilo -------------------------------------------------
    base_rows = [r for r in rows if r.config.upper() == "V1" and r.hilos == 1]
    t1 = None
    base_label = None
    if base_rows:
        t1 = base_rows[0].mediana
        base_label = base_rows[0].label
        if len(base_rows) > 1:
            warn("A0", "hay más de una fila V1,1: se usa la primera como T(1); si son máquinas o n distintos, sepáralas")
    else:
        err("E1", "no hay fila V1 con 1 hilo: T(1) debe ser el MEJOR PROGRAMA SECUENCIAL, no la versión "
                  "paralela con un hilo (protocolo §3 y §5)")
        one = [r for r in rows if r.hilos == 1]
        if one and one[0].speedup_rep is not None and _close(one[0].speedup_rep, 1.0):
            err("E6", f"la fila {one[0].label} tiene speedup 1.000: la tabla se normalizó contra la versión "
                      "paralela con 1 hilo; recalcula todo contra V1")
        if one:
            t1_provisional = one[0].mediana
            base_label = one[0].label + " (provisional, a falta de V1)"
        else:
            t1_provisional = None
    t1_check = t1 if t1 is not None else (t1_provisional if base_label else None)

    # --- E2: repeticiones; E3: la mediana es la mediana ----------------------------------------
    for r in rows:
        if len(r.reps) < 5:
            err("E2", f"fila {r.label}: solo {len(r.reps)} repeticiones; el protocolo exige ≥ 5 (más 1 de calentamiento)")
        if r.reps and r.mediana_rep is not None and not _close(r.mediana_rep, statistics.median(r.reps)):
            med = statistics.median(r.reps)
            mean = statistics.mean(r.reps)
            if _close(r.mediana_rep, mean):
                err("E3", f"fila {r.label}: mediana_s = {r.mediana_rep:.4g} es el PROMEDIO de las repeticiones; "
                          f"la mediana es {med:.4g} (un pico de {max(r.reps):.4g} s está arrastrando el promedio)")
            else:
                err("E3", f"fila {r.label}: mediana_s = {r.mediana_rep:.4g} no coincide con la mediana de las "
                          f"repeticiones ({med:.4g})")

    # --- E4: tamaño del problema ----------------------------------------------------------------
    if t1_check is not None:
        if t1_check < 0.1:
            err("E4", f"T(1) = {t1_check:.3g} s < 0.1 s en {base_label}: problema demasiado pequeño, mides la "
                      "sobrecarga y no el trabajo (protocolo §5)")
        elif t1_check < 1.0:
            warn("A4", f"T(1) = {t1_check:.3g} s en {base_label}: el protocolo pide que la versión secuencial tarde "
                       "≥ 1 s; aumenta n o declara por qué no se puede")

    # --- E5: n fijo en toda la tabla ------------------------------------------------------------
    ns = sorted({r.n for r in rows})
    if len(ns) > 1:
        err("E5", f"n cambia entre filas ({', '.join(ns)}): en escalabilidad fuerte n es fijo; si crece con los "
                  "hilos es escalabilidad débil y va en una tabla aparte, declarada (Anexo A, 6)")

    # --- E6/E7: speedup y eficiencia reportados vs recalculados; A1, A2, A3 ----------------------
    for r in rows:
        if not isinstance(r.hilos, int) or r.mediana is None:
            continue
        p = r.hilos
        if t1 is not None:
            s_calc = t1 / r.mediana
            if r.speedup_rep is not None and not _close(r.speedup_rep, s_calc):
                err("E6", f"fila {r.label}: speedup reportado {r.speedup_rep:.3f}, recalculado T(1)/mediana = {s_calc:.3f}")
            if r.eficiencia_rep is not None and not _close(r.eficiencia_rep, s_calc / p):
                warn("A7", f"fila {r.label}: eficiencia reportada {r.eficiencia_rep:.3f}, recalculada {s_calc / p:.3f}")
            if s_calc > p * (1 + TOL):
                warn("A3", f"fila {r.label}: speedup {s_calc:.2f} > p = {p} (superlineal): verifica correctitud con "
                           "esos hilos y explícalo (caché); no se reporta sin explicación (Anexo A, 4)")
        if nucleos is not None and p > nucleos:
            warn("A1", f"fila {r.label}: {p} hilos en una máquina de {nucleos} núcleos físicos: márcala como "
                       "sobre-suscripción / hyper-threading en la tabla y no la uses para concluir escalabilidad")
        if r.reps:
            spread = (max(r.reps) - min(r.reps)) / r.mediana
            if spread > 0.20:
                warn("A2", f"fila {r.label}: (máx − mín)/mediana = {spread:.0%} > 20 %: repite la configuración con "
                           "la máquina sin otras cargas y anota la corrida descartada en la bitácora")

    # --- A5: lista de hilos; A6: f de Karp–Flatt creciente --------------------------------------
    for config in sorted({r.config for r in rows}):
        hs = sorted(r.hilos for r in rows if r.config == config and isinstance(r.hilos, int))
        if config.upper() != "V1" and hs and not {1, 2, 4}.issubset(hs):
            warn("A5", f"{config}: hilos medidos {hs}; el protocolo pide 1, 2, 4, … hasta los núcleos físicos y uno más allá")
        if t1 is not None:
            fs = []
            for r in sorted((r for r in rows if r.config == config and isinstance(r.hilos, int) and r.hilos > 1),
                            key=lambda r: r.hilos):
                if nucleos is not None and r.hilos > nucleos:
                    continue
                s = t1 / r.mediana
                if s > 0:
                    fs.append((r.hilos, karp_flatt(s, r.hilos)))
            for (p0, f0), (p1, f1) in zip(fs, fs[1:]):
                if f1 > f0 * 1.25 and f1 - f0 > 0.02:
                    warn("A6", f"{config}: f de Karp–Flatt crece de {f0:.3f} (p={p0}) a {f1:.3f} (p={p1}): hay sobrecarga "
                               "que crece con los hilos (sincronización, falso compartido, ancho de banda); "
                               "di cuál y qué experimento lo muestra")
    return errors, warnings, t1


def tabla_markdown(rows, t1):
    out = []
    n_txt = ", ".join(sorted({r.n for r in rows}))
    base = f"{t1:.4g} s" if t1 is not None else "no disponible (falta la fila V1,1)"
    out.append(f"Tamaño del problema n = {n_txt}; línea base T(1) = V1 = {base}.")
    out.append("")
    out.append("| Versión | Hilos | Mediana (s) | Mín (s) | Máx (s) | Speedup | Eficiencia | f Karp–Flatt |")
    out.append("|---|---|---|---|---|---|---|---|")
    for r in rows:
        med = r.mediana
        if med is None:
            continue
        mn = f"{min(r.reps):.4g}" if r.reps else "—"
        mx = f"{max(r.reps):.4g}" if r.reps else "—"
        if t1 is not None and isinstance(r.hilos, int):
            s = t1 / med
            e = s / r.hilos
            f = f"{karp_flatt(s, r.hilos):.3f}" if r.hilos > 1 else "—"
            out.append(f"| {r.config} | {r.hilos} | {med:.4g} | {mn} | {mx} | {s:.3f} | {e:.3f} | {f} |")
        else:
            out.append(f"| {r.config} | {r.hilos} | {med:.4g} | {mn} | {mx} | — | — | — |")
    return "\n".join(out)


def graficar(rows, t1, path):
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        print(f"(sin matplotlib: no se generó {path})")
        return False
    if t1 is None:
        print(f"(sin fila V1,1 no hay speedup que graficar: no se generó {path})")
        return False
    fig, ax = plt.subplots(figsize=(5.5, 4))
    pmax = 1
    for config in sorted({r.config for r in rows}):
        pts = sorted((r.hilos, t1 / r.mediana) for r in rows
                     if r.config == config and isinstance(r.hilos, int) and r.mediana)
        if not pts:
            continue
        xs, ys = zip(*pts)
        pmax = max(pmax, max(xs))
        ax.plot(xs, ys, marker="o", label=config)
        ax.annotate(f"{ys[-1]:.2f}", (xs[-1], ys[-1]), textcoords="offset points", xytext=(5, 0))
    ax.plot([1, pmax], [1, pmax], linestyle="--", color="gray", label="ideal S = p")
    ax.set_xlabel("hilos")
    ax.set_ylabel("speedup = T(1) / T(p)")
    ax.set_xticks(sorted({r.hilos for r in rows if isinstance(r.hilos, int)}))
    ax.set_ylim(bottom=0)
    ax.set_title(f"Speedup (n = {', '.join(sorted({r.n for r in rows}))})", fontsize=10)
    ax.grid(alpha=0.3)
    ax.legend()
    fig.tight_layout()
    fig.savefig(path, dpi=120)
    print(f"Gráfica guardada en {path}")
    return True


def main():
    ap = argparse.ArgumentParser(description="Revisa un CSV de mediciones contra el protocolo del curso.")
    ap.add_argument("csv", help="archivo con las columnas del protocolo")
    ap.add_argument("--nucleos", type=int, default=None,
                    help="núcleos físicos de la máquina (para avisar sobre-suscripción)")
    ap.add_argument("--png", default=None, help="guardar la gráfica speedup vs hilos en este archivo")
    args = ap.parse_args()

    try:
        rows = read_rows(args.csv)
    except (OSError, ValueError) as e:
        print(f"No se pudo leer {args.csv}: {e}")
        return 2

    errors, warnings, t1 = revisar(rows, args.nucleos)

    print(f"== Revisión de {args.csv} ==")
    print(tabla_markdown(rows, t1))
    print()
    for line in errors + warnings:
        print(line)
    if not errors and not warnings:
        print("Sin hallazgos automáticos. Falta la revisión humana: ¿T(1) es su mejor secuencial? ¿dónde deja de escalar y por qué?")
    print()
    print(f"Resumen: {len(errors)} errores, {len(warnings)} avisos")
    if args.png:
        graficar(rows, t1, args.png)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
