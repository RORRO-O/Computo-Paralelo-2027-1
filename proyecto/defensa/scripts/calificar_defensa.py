#!/usr/bin/env python3
"""calificar_defensa.py — Calcula la defensa (15 puntos) por integrante y el ajuste individual del proyecto.

Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · Proyecto integrador · Defensa oral · aplica rubrica-defensa.md

Uso:
    python3 calificar_defensa.py registro.csv [--salida calificaciones.csv] [--sin-tabla]

    registro.csv  CSV con encabezado, una fila por integrante (usuario de GitHub, nunca el nombre). El registro real
                  contiene calificaciones: vive en docente/ (fuera del repositorio público), no en esta carpeta.
    --salida      Escribe además un CSV con el resultado (crea la carpeta si no existe).
    --sin-tabla   No imprime la tabla en Markdown.

Entrada:
    equipo,integrante,D1,D2,D3,P1,P2[,h2,repo,reporte]
    D1 D2 D3  nivel del EQUIPO en cada criterio: E (Ejemplar) C (Competente) D (En desarrollo) I (Insuficiente)
              A (criterio ausente = 0).
    P1        pregunta 1 del integrante (línea de la parte que firmó): E C D I. "No respondió" es I.
              A solo si el integrante faltó a la defensa SIN justificante (entonces P2 también es A o "-").
              Con justificante, la fila se captura después de su defensa individual del martes 15 de diciembre,
              con los niveles reales.
    P2        pregunta 2: si P1 es I, es la de RESCATE sobre otra línea (05-politica-ia.md); si no, la del tema
              sorteado. "-" cuando no se hizo (opción c: la segunda pregunta solo existe como rescate).
    h2 repo reporte  (opcionales) puntos ya calificados de H2 (/15), repositorio (/40, con C6 ya asignado por
              integrante) y reporte (/30). Si faltan, solo se calcula la defensa.

Cálculo (rubrica-defensa.md §2–§4):
    factor de nivel: E 1.00 · C 0.80 · D 0.55 · I 0.20 · A 0.00
    rúbrica = 25·f(D1) + 25·f(D2) + 20·f(D3) + D4,  D4 = 30·promedio(f(P1), f(P2))  (o 30·f(P1) si P2 = "-")
    defensa (/15) = rúbrica × 0.15
    ajuste individual (§4.1): −10 % por cada respuesta en I entre P1 y P2, máximo dos →
        factor 1.00 (ninguna) · 0.90 (una) · 0.80 (dos). A (ausente sin justificante) cuenta como dos I
        (§4.2, 04-evaluacion.md §3.2): faltar nunca conviene más que presentarse.
    C6 por la defensa (§4.2, prueba de propiedad: cuenta la mejor de las dos líneas): "sí" cuando P1 = I y el
        rescate P2 = I, es decir, no explicó ninguna de las dos líneas, o cuando P1 = A. El script no cambia
        "repo": avisa para que el profesor asigne C6 Insuficiente en rubrica-codigo.md antes de capturar "repo".
    proyecto individual = (h2 + repo + reporte + defensa) × factor, con el tope de §4.1: nunca más de 20 puntos
        por debajo de la referencia del equipo (= máximo de h2+repo+reporte entre los integrantes con esos datos
        + puntos de D1–D3 + máximo D4 del equipo, en puntos del proyecto).
    Redondeo a dos decimales (medio hacia arriba) solo al imprimir.

Salida: tabla en Markdown (stdout) y, con --salida, CSV con las columnas
    equipo,integrante,D4_rubrica,rubrica_100,defensa_15,insuficientes,factor,c6_insuficiente,suma_100,
    proyecto_ajustado,referencia_equipo,tope_aplicado,proyecto_final
Código de salida: 0 si todo se calculó; 1 si el archivo no existe o el CSV tiene una columna, un nivel o un número
inválido, un integrante vacío o repetido en su equipo (se indica fila y columna). El número de equipo se normaliza a
dos dígitos ("7" = "07"). Acepta CSV con marca BOM (exportado desde una hoja de cálculo).

Ejemplo ejecutable (desde esta carpeta; lo corre `make run`):
    python3 calificar_defensa.py ejemplo/registro-defensa.csv --salida salida/calificaciones.csv
"""
import argparse
import csv
import os
import sys
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP

FACTOR = {"E": Decimal("1.00"), "C": Decimal("0.80"), "D": Decimal("0.55"),
          "I": Decimal("0.20"), "A": Decimal("0.00")}
PESOS = {"D1": Decimal(25), "D2": Decimal(25), "D3": Decimal(20)}
PESO_D4 = Decimal(30)
A_PROYECTO = Decimal("0.15")
AJUSTE_POR_INSUFICIENTE = Decimal("0.10")
TOPE_PUNTOS = Decimal(20)
MAXIMOS = {"h2": Decimal(15), "repo": Decimal(40), "reporte": Decimal(30)}


def falla(mensaje):
    print(f"calificar_defensa.py: {mensaje}", file=sys.stderr)
    sys.exit(1)


def r2(x):
    return x.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def nivel(valor, fila, col, permitir_guion=False):
    v = (valor or "").strip().upper()
    if permitir_guion and v in ("-", "—", ""):
        return None
    if v not in FACTOR:
        falla(f"fila {fila}, columna {col}: nivel inválido {valor!r} (se esperaba E, C, D, I o A)")
    return v


def numero(valor, fila, col):
    v = (valor or "").strip()
    if v == "":
        return None
    try:
        x = Decimal(v)
    except InvalidOperation:
        falla(f"fila {fila}, columna {col}: número inválido {valor!r}")
    if not Decimal(0) <= x <= MAXIMOS[col]:
        falla(f"fila {fila}, columna {col}: {valor} fuera de rango (0 a {MAXIMOS[col]})")
    return x


def factor_ajuste(p1, p2):
    """rubrica-defensa.md §4.1: −10 % por cada respuesta Insuficiente (P1 y P2, rescate incluido), máximo dos.
    §4.2: faltar sin justificante (P1 = A) cuenta como las dos Insuficientes."""
    n_insuf = 2 if p1 == "A" else sum(1 for p in (p1, p2) if p == "I")
    return n_insuf, Decimal(1) - AJUSTE_POR_INSUFICIENTE * n_insuf


def leer_registro(ruta):
    if not os.path.isfile(ruta):
        falla(f"no existe el archivo {ruta!r}")
    filas = []
    vistos = {}
    # utf-8-sig: acepta también el CSV que exportan las hojas de cálculo con marca BOM al inicio.
    with open(ruta, newline="", encoding="utf-8-sig") as fh:
        lector = csv.DictReader(fh)
        req = {"equipo", "integrante", "D1", "D2", "D3", "P1", "P2"}
        if not lector.fieldnames or not req.issubset(set(lector.fieldnames)):
            falla(f"el CSV debe tener las columnas {sorted(req)}; tiene {lector.fieldnames}")
        for i, fila in enumerate(lector, start=2):
            equipo = (fila.get("equipo") or "").strip()
            if not equipo:
                continue
            if equipo.isdigit():
                equipo = f"{int(equipo):02d}"  # "7" y "07" son el mismo cp-6bm1-equipo07
            integrante = (fila.get("integrante") or "").strip()
            if not integrante:
                falla(f"fila {i}, columna integrante: vacía (usuario de GitHub)")
            if (equipo, integrante) in vistos:
                falla(f"fila {i}: {integrante} del equipo {equipo} ya aparece en la fila {vistos[(equipo, integrante)]}")
            vistos[(equipo, integrante)] = i
            d = {c: nivel(fila[c], i, c) for c in ("D1", "D2", "D3")}
            p1 = nivel(fila["P1"], i, "P1")
            p2 = nivel(fila["P2"], i, "P2", permitir_guion=True)
            if p1 == "I" and p2 is None:
                falla(f"fila {i}: P1 es I pero no hay P2 (debe haber pregunta de rescate; si no respondió, es I)")
            if p1 == "A" and p2 not in (None, "A"):
                falla(f"fila {i}: P1 es A (ausente) pero P2 es {p2}; A es para el integrante que faltó")
            if p1 != "A" and p2 == "A":
                falla(f"fila {i}: P2 es A pero P1 no; una pregunta sin respuesta es I, A es solo para ausencia")
            h2 = numero(fila.get("h2"), i, "h2")
            repo = numero(fila.get("repo"), i, "repo")
            rep = numero(fila.get("reporte"), i, "reporte")
            equipo_pts = sum(PESOS[c] * FACTOR[d[c]] for c in PESOS)
            if p2 is None:
                d4 = PESO_D4 * FACTOR[p1]
            else:
                d4 = PESO_D4 * (FACTOR[p1] + FACTOR[p2]) / Decimal(2)
            rubrica = equipo_pts + d4
            n_insuf, fac = factor_ajuste(p1, p2)
            filas.append({
                "fila": i, "equipo": equipo, "integrante": integrante,
                "D1": d["D1"], "D2": d["D2"], "D3": d["D3"], "P1": p1, "P2": p2 or "-",
                "equipo_pts": equipo_pts, "D4": d4, "rubrica": rubrica, "defensa": rubrica * A_PROYECTO,
                "insuf": n_insuf, "factor": fac, "c6": "sí" if (p1 == "I" and p2 == "I") or p1 == "A" else "no",
                "h2": h2, "repo": repo, "reporte": rep,
            })
    return filas


def aplicar_tope(filas):
    """Referencia del equipo y tope de 20 puntos (rubrica-defensa.md §4.1)."""
    por_equipo = {}
    for f in filas:
        por_equipo.setdefault(f["equipo"], []).append(f)
    for eq, lista in por_equipo.items():
        if len({f["equipo_pts"] for f in lista}) != 1:
            falla(f"equipo {eq}: D1–D3 son del equipo y deben ser iguales en todas sus filas "
                  f"(filas {', '.join(str(f['fila']) for f in lista)})")
        completos = [f for f in lista if None not in (f["h2"], f["repo"], f["reporte"])]
        if completos:
            base_max = max(f["h2"] + f["repo"] + f["reporte"] for f in completos)
            d4_max = max(f["D4"] for f in lista)
            ref = base_max + (lista[0]["equipo_pts"] + d4_max) * A_PROYECTO
        else:
            ref = None
        for f in lista:
            f["referencia"] = ref
            if ref is not None and None not in (f["h2"], f["repo"], f["reporte"]):
                suma = f["h2"] + f["repo"] + f["reporte"] + f["defensa"]
                ajustado = suma * f["factor"]
                piso = ref - TOPE_PUNTOS
                final, tope_ap = (piso, "sí") if ajustado < piso else (ajustado, "no")
                f.update(suma=suma, ajustado=ajustado, final=final, tope_ap=tope_ap)
            else:
                f.update(suma=None, ajustado=None, final=None, tope_ap="n/a")


def main():
    ap = argparse.ArgumentParser(description="Calificación de la defensa por integrante (rubrica-defensa.md)")
    ap.add_argument("registro", help="CSV equipo,integrante,D1,D2,D3,P1,P2[,h2,repo,reporte]")
    ap.add_argument("--salida", default=None, help="CSV de salida")
    ap.add_argument("--sin-tabla", action="store_true", help="no imprimir la tabla en Markdown")
    args = ap.parse_args()

    filas = leer_registro(args.registro)
    aplicar_tope(filas)

    def celda(x, vacio=""):
        return vacio if x is None else str(r2(x))

    if not args.sin_tabla:
        print("| Equipo | Integrante | D1 D2 D3 | P1 | P2 | D4 (/30) | Rúbrica (/100) | Defensa (/15) | Insuf. | "
              "Factor | C6 Insuf. | Suma (/100) | Ajustado | Ref. equipo | Tope | **Proyecto (/100)** |")
        print("|---|---|---|---|---|---:|---:|---:|---:|---:|---|---:|---:|---:|---|---:|")
        for f in filas:
            print(f"| {f['equipo']} | {f['integrante']} | {f['D1']} {f['D2']} {f['D3']} | {f['P1']} | {f['P2']} | "
                  f"{r2(f['D4'])} | {r2(f['rubrica'])} | {r2(f['defensa'])} | {f['insuf']} | {r2(f['factor'])} | "
                  f"{f['c6']} | {celda(f['suma'], '—')} | {celda(f['ajustado'], '—')} | "
                  f"{celda(f['referencia'], '—')} | {f['tope_ap']} | **{celda(f['final'], '—')}** |")
    if args.salida:
        os.makedirs(os.path.dirname(os.path.abspath(args.salida)), exist_ok=True)
        with open(args.salida, "w", newline="", encoding="utf-8") as fh:
            w = csv.writer(fh)
            w.writerow(["equipo", "integrante", "D4_rubrica", "rubrica_100", "defensa_15", "insuficientes",
                        "factor", "c6_insuficiente", "suma_100", "proyecto_ajustado", "referencia_equipo",
                        "tope_aplicado", "proyecto_final"])
            for f in filas:
                w.writerow([f["equipo"], f["integrante"], r2(f["D4"]), r2(f["rubrica"]), r2(f["defensa"]),
                            f["insuf"], r2(f["factor"]), f["c6"], celda(f["suma"]), celda(f["ajustado"]),
                            celda(f["referencia"]), f["tope_ap"], celda(f["final"])])
        print(f"\nCSV escrito en {args.salida}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
