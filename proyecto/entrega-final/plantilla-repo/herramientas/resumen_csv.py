#!/usr/bin/env python3
"""
herramientas/resumen_csv.py · Resume las mediciones del protocolo del curso (plantilla)

Uso:
    python3 herramientas/resumen_csv.py resultados/mediciones.csv [--v3 resultados/mediciones_v3.csv]
                                        [--png resultados/speedup.png] [--md resultados/tabla.md]
                                        [--titulo "Mi problema, n=4e6"]

Qué hace:
    1. Lee el CSV con la cabecera del protocolo (config,hilos,n,rep1..repK,mediana_s,speedup,eficiencia).
    2. NO confía en las columnas calculadas: recalcula mediana, mínimo, máximo, speedup S(p)=T1/T(p),
       eficiencia E(p)=S/p y fracción secuencial de Karp–Flatt f=(1/S-1/p)/(1-1/p) a partir de las
       repeticiones. T1 es la fila `config=v1` (el mejor secuencial), no la V2 con un hilo.
    3. Si se pasa --v3, agrega las filas de GPU (config v3_kernel y v3_total) con su speedup
       respecto a la V1 medida EN LA MISMA MÁQUINA (el CSV de V3 debe traer su propia fila v1).
    4. Imprime una tabla Markdown lista para pegar en el reporte (y la guarda con --md).
    5. Con --png dibuja speedup vs hilos con la línea ideal S=p y, si hay V3, líneas horizontales
       con el speedup de GPU con y sin transferencias.
Código de salida: 0 si todo bien; 1 si falta la fila v1, hay menos de 5 repeticiones o una
    fila no es numérica (eso es un error del CSV, no de este script).
Ejemplo:
    python3 herramientas/resumen_csv.py resultados/mediciones.csv --png resultados/speedup.png
"""
import argparse
import csv
import statistics
import sys


def leer_csv(ruta):
    """Devuelve (filas, k) donde filas es una lista de dict y k el número de repeticiones."""
    with open(ruta, newline="", encoding="utf-8") as f:
        lector = csv.DictReader(f)
        columnas = lector.fieldnames or []
        reps = [c for c in columnas if c.startswith("rep")]
        obligatorias = {"config", "hilos", "n"}
        if not obligatorias.issubset(columnas):
            sys.exit(f"error: {ruta} no tiene las columnas {sorted(obligatorias)}; cabecera: {columnas}")
        if len(reps) < 5:
            sys.exit(f"error: {ruta} tiene {len(reps)} repeticiones; el protocolo exige al menos 5")
        filas = []
        for num, fila in enumerate(lector, start=2):
            try:
                tiempos = [float(fila[c]) for c in reps if fila[c] not in ("", None)]
                if len(tiempos) < 5:
                    sys.exit(f"error: {ruta} línea {num}: menos de 5 repeticiones con valor")
                filas.append({
                    "config": fila["config"].strip(),
                    "hilos": int(float(fila["hilos"])),
                    "n": int(float(fila["n"])),
                    "tiempos": tiempos,
                })
            except ValueError as exc:
                sys.exit(f"error: {ruta} línea {num}: valor no numérico ({exc})")
    return filas, len(reps)


def resumir(filas, t1):
    """Agrega mediana/min/max/speedup/eficiencia/karp_flatt a cada fila (en sitio)."""
    for fila in filas:
        med = statistics.median(fila["tiempos"])
        fila["mediana"] = med
        fila["min"] = min(fila["tiempos"])
        fila["max"] = max(fila["tiempos"])
        fila["speedup"] = t1 / med if med > 0 else float("nan")
        p = fila["hilos"]
        if p >= 1 and fila["config"].startswith("v2"):
            fila["eficiencia"] = fila["speedup"] / p
            if p > 1 and fila["speedup"] > 0:
                fila["karp_flatt"] = (1.0 / fila["speedup"] - 1.0 / p) / (1.0 - 1.0 / p)
            else:
                fila["karp_flatt"] = None
        else:
            fila["eficiencia"] = None
            fila["karp_flatt"] = None


def fila_v1(filas, ruta):
    v1 = [f for f in filas if f["config"] == "v1"]
    if not v1:
        sys.exit(f"error: {ruta} no tiene una fila con config=v1 (la referencia secuencial)")
    if len(v1) > 1:
        print(f"aviso: {ruta} tiene {len(v1)} filas v1; se usa la primera", file=sys.stderr)
    return v1[0]


def fmt(x, dec=3):
    if x is None:
        return "—"
    return f"{x:.{dec}f}"


def tabla_markdown(filas_cpu, filas_gpu, t1_cpu, t1_gpu):
    lineas = []
    lineas.append("| Config | Hilos | n | Mediana (s) | Mín (s) | Máx (s) | Speedup | Eficiencia | Karp–Flatt f |")
    lineas.append("|---|---:|---:|---:|---:|---:|---:|---:|---:|")
    for f in filas_cpu:
        lineas.append(
            f"| {f['config']} | {f['hilos']} | {f['n']} | {fmt(f['mediana'], 4)} | {fmt(f['min'], 4)} | "
            f"{fmt(f['max'], 4)} | {fmt(f['speedup'])} | {fmt(f['eficiencia'])} | {fmt(f['karp_flatt'])} |"
        )
    lineas.append("")
    lineas.append(f"T(1) de referencia en CPU: {t1_cpu:.4f} s (config v1).")
    if filas_gpu:
        lineas.append("")
        lineas.append("| Config GPU | n | Mediana (s) | Mín (s) | Máx (s) | Speedup vs V1 (misma máquina) |")
        lineas.append("|---|---:|---:|---:|---:|---:|")
        for f in filas_gpu:
            lineas.append(
                f"| {f['config']} | {f['n']} | {fmt(f['mediana'], 5)} | {fmt(f['min'], 5)} | "
                f"{fmt(f['max'], 5)} | {fmt(f['speedup'])} |"
            )
        lineas.append("")
        lineas.append(f"T(1) de referencia en la máquina de la GPU: {t1_gpu:.4f} s (fila v1 del CSV de V3).")
    return "\n".join(lineas) + "\n"


def graficar(filas_cpu, filas_gpu, ruta_png, titulo):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    v2 = sorted([f for f in filas_cpu if f["config"].startswith("v2")], key=lambda f: f["hilos"])
    if not v2:
        print("aviso: no hay filas v2; no se dibuja la curva de speedup", file=sys.stderr)
    hilos = [f["hilos"] for f in v2]
    sp = [f["speedup"] for f in v2]
    # barras de error: speedup calculado con el máximo y el mínimo de las repeticiones
    t1 = None
    for f in filas_cpu:
        if f["config"] == "v1":
            t1 = f["mediana"]
            break
    err_lo = [f["speedup"] - t1 / f["max"] for f in v2]
    err_hi = [t1 / f["min"] - f["speedup"] for f in v2]

    fig, ax = plt.subplots(figsize=(6.4, 4.2), dpi=150)
    p_max = max(hilos) if hilos else 1
    ax.plot([1, p_max], [1, p_max], linestyle="--", linewidth=1, color="#888888", label="Ideal S = p")
    if v2:
        ax.errorbar(hilos, sp, yerr=[err_lo, err_hi], marker="o", linewidth=1.5, capsize=3,
                    color="#1f5fbf", label="V2 OpenMP (mediana; barras: mín–máx)")
    colores = {"v3_kernel": "#b8471b", "v3_total": "#2a8a4a"}
    etiquetas = {"v3_kernel": "V3 GPU sin transferencias", "v3_total": "V3 GPU con transferencias"}
    for f in filas_gpu:
        if f["config"] in colores:
            ax.axhline(f["speedup"], linestyle=":", linewidth=1.5, color=colores[f["config"]],
                       label=f"{etiquetas[f['config']]} (S = {f['speedup']:.1f})")
    ax.set_xlabel("Hilos (p)")
    ax.set_ylabel("Speedup S(p) = T(1) / T(p)")
    ax.set_title(titulo)
    ax.set_xticks(hilos if hilos else [1])
    ax.grid(True, linewidth=0.4, alpha=0.5)
    ax.legend(fontsize=8, loc="upper left")
    fig.tight_layout()
    fig.savefig(ruta_png)
    plt.close(fig)


def main():
    ap = argparse.ArgumentParser(description="Resume mediciones del protocolo del curso.")
    ap.add_argument("csv", help="CSV de CPU (filas v1 y v2)")
    ap.add_argument("--v3", help="CSV de GPU (filas v1, v3_kernel, v3_total medidas en Colab/Kaggle)")
    ap.add_argument("--png", help="ruta de la gráfica speedup vs hilos")
    ap.add_argument("--md", help="ruta donde guardar la tabla Markdown")
    ap.add_argument("--titulo", default="Speedup vs hilos", help="título de la gráfica")
    args = ap.parse_args()

    filas_cpu, _ = leer_csv(args.csv)
    t1_cpu = statistics.median(fila_v1(filas_cpu, args.csv)["tiempos"])
    resumir(filas_cpu, t1_cpu)

    filas_gpu = []
    t1_gpu = None
    if args.v3:
        filas_v3, _ = leer_csv(args.v3)
        t1_gpu = statistics.median(fila_v1(filas_v3, args.v3)["tiempos"])
        resumir(filas_v3, t1_gpu)
        filas_gpu = [f for f in filas_v3 if f["config"].startswith("v3")]
        if not filas_gpu:
            sys.exit(f"error: {args.v3} no tiene filas v3_kernel/v3_total")

    tabla = tabla_markdown(filas_cpu, filas_gpu, t1_cpu, t1_gpu)
    print(tabla, end="")
    if args.md:
        with open(args.md, "w", encoding="utf-8") as f:
            f.write(tabla)
        print(f"tabla -> {args.md}")
    if args.png:
        graficar(filas_cpu, filas_gpu, args.png, args.titulo)
        print(f"gráfica -> {args.png}")

    if t1_cpu < 1.0:
        print(f"aviso: T(1) = {t1_cpu:.3f} s < 1 s; la medición no es válida para el reporte (protocolo §2)",
              file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
