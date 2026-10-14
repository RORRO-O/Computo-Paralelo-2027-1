#!/usr/bin/env python3
"""calificar_defensa.py — Calcula la defensa (15 puntos) por integrante y el ajuste individual del proyecto.

Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · Proyecto integrador · Defensa oral · aplica rubrica-defensa.md

Uso:
    python3 calificar_defensa.py registro.csv [--salida calificaciones.csv] [--sin-tabla]

Entrada: CSV con encabezado y una fila por integrante (sin nombres: usuario de GitHub o letra).
    equipo,integrante,D1,D2,D3,P1,P2[,h2,repo,reporte]
    D1 D2 D3  nivel del EQUIPO en cada criterio: E (Ejemplar) C (Competente) D (En desarrollo) I (Insuficiente)
              A (ausente = 0).
    P1        nivel de la pregunta 1 del integrante (línea de la parte firmada): E C D I, o A (no respondió / faltó).
    P2        nivel de la pregunta 2: si P1 es I, P2 es la pregunta de RESCATE sobre otra línea; si no, es la de
              tema. "-" cuando no se hizo (opción c sin rescate): entonces D4 = 30 × factor(P1).
    h2 repo reporte  (opcionales) puntos ya calificados de H2 (/15), repositorio (/40, con C6 ya asignado por
              integrante) y reporte (/30). Si faltan, solo se calcula la defensa.

Cálculo (rubrica-defensa.md §2–§4):
    factor de nivel: E 1.00 · C 0.80 · D 0.55 · I 0.20 · A 0.00
    rúbrica = 25·f(D1) + 25·f(D2) + 20·f(D3) + D4,  D4 = 30·promedio(f(P1), f(P2))  (o 30·f(P1) si P2 = "-")
    defensa (/15) = rúbrica × 0.15
    ajuste individual (prueba de propiedad, 05-politica-ia.md: cuenta la mejor de las dos líneas):
        P1 ≥ D → factor 1.00 · P1 = I y rescate ≥ C → 1.00 · P1 = I y rescate = D → 0.90 · P1 = I y rescate I/A → 0.80
    proyecto individual = (h2 + repo + reporte + defensa) × factor, con el tope de 04-evaluacion.md §3.2:
        nunca más de 20 puntos por debajo de la referencia del equipo (= máximo de h2+repo+reporte entre los
        integrantes + puntos de D1–D3 + máximo D4 del equipo, en puntos del proyecto).
    Redondeo a dos decimales (medio hacia arriba) solo al imprimir.

Salida: tabla en Markdown (stdout) y, con --salida, CSV con las columnas
    equipo,integrante,D4_rubrica,rubrica_100,defensa_15,factor,suma_100,proyecto_ajustado,referencia_equipo,tope_aplicado,proyecto_final
Código de salida: 0 si todo se calculó; 1 si el CSV tiene un nivel o un número inválido (se indica fila y columna).

Ejemplo ejecutable (desde esta carpeta):
    python3 calificar_defensa.py ejemplo/registro-defensa.csv --salida salida/calificaciones.csv
"""
import argparse
import csv
import os
import sys
from decimal import Decimal, ROUND_HALF_UP

FACTOR = {"E": Decimal("1.00"), "C": Decimal("0.80"), "D": Decimal("0.55"),
          "I": Decimal("0.20"), "A": Decimal("0.00")}
PESOS = {"D1": Decimal(25), "D2": Decimal(25), "D3": Decimal(20)}
VEINTE = Decimal(20)


def r2(x):
    return x.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def nivel(valor, fila, col, permitir_guion=False):
    v = (valor or "").strip().upper()
    if permitir_guion and v in ("-", "—", ""):
        return None
    if v not in FACTOR:
        sys.exit(f"Fila {fila}, columna {col}: nivel inválido {valor!r} (se esperaba E, C, D, I o A)")
    return v


def numero(valor, fila, col):
    v = (valor or "").strip()
    if v == "":
        return None
    try:
        return Decimal(v)
    except Exception:
        sys.exit(f"Fila {fila}, columna {col}: número inválido {valor!r}")


def factor_ajuste(p1, p2):
    """Prueba de propiedad: P1 sobre la parte firmada; si falla, P2 es el rescate y cuenta la mejor."""
    if p1 != "I":
        return Decimal("1.00")
    if p2 in ("E", "C"):
        return Decimal("1.00")
    if p2 == "D":
        return Decimal("0.90")
    return Decimal("0.80")


def main():
    ap = argparse.ArgumentParser(description="Calificación de la defensa por integrante")
    ap.add_argument("registro")
    ap.add_argument("--salida", default=None)
    ap.add_argument("--sin-tabla", action="store_true")
    args = ap.parse_args()

    filas = []
    with open(args.registro, newline="", encoding="utf-8") as fh:
        lector = csv.DictReader(fh)
        req = {"equipo", "integrante", "D1", "D2", "D3", "P1", "P2"}
        if not lector.fieldnames or not req.issubset(set(lector.fieldnames)):
            sys.exit(f"El CSV debe tener las columnas {sorted(req)}; tiene {lector.fieldnames}")
        for i, fila in enumerate(lector, start=2):
            if not (fila.get("equipo") or "").strip():
                continue
            d = {c: nivel(fila[c], i, c) for c in ("D1", "D2", "D3")}
            p1 = nivel(fila["P1"], i, "P1")
            p2 = nivel(fila["P2"], i, "P2", permitir_guion=True)
            if p1 == "I" and p2 is None:
                sys.exit(f"Fila {i}: P1 es I pero no hay P2 (debe haber pregunta de rescate; usa A si no respondió)")
            h2 = numero(fila.get("h2"), i, "h2")
            repo = numero(fila.get("repo"), i, "repo")
            rep = numero(fila.get("reporte"), i, "reporte")
            equipo_pts = sum(PESOS[c] * FACTOR[d[c]] for c in PESOS)
            if p2 is None:
                d4 = Decimal(30) * FACTOR[p1]
            else:
                d4 = Decimal(30) * (FACTOR[p1] + FACTOR[p2]) / Decimal(2)
            rubrica = equipo_pts + d4
            defensa = rubrica * Decimal("0.15")
            fac = factor_ajuste(p1, p2)
            filas.append({
                "equipo": fila["equipo"].strip(), "integrante": fila["integrante"].strip(),
                "D1": d["D1"], "D2": d["D2"], "D3": d["D3"], "P1": p1, "P2": p2 or "-",
                "equipo_pts": equipo_pts, "D4": d4, "rubrica": rubrica, "defensa": defensa, "factor": fac,
                "h2": h2, "repo": repo, "reporte": rep,
            })

    # Referencia del equipo para el tope de ±20 (04-evaluacion.md §3.2).
    por_equipo = {}
    for f in filas:
        por_equipo.setdefault(f["equipo"], []).append(f)
    for eq, lista in por_equipo.items():
        completos = [f for f in lista if None not in (f["h2"], f["repo"], f["reporte"])]
        if completos:
            base_max = max(f["h2"] + f["repo"] + f["reporte"] for f in completos)
            d4_max = max(f["D4"] for f in lista)
            ref = base_max + (lista[0]["equipo_pts"] + d4_max) * Decimal("0.15")
        else:
            ref = None
        for f in lista:
            f["referencia"] = ref
            if ref is not None and None not in (f["h2"], f["repo"], f["reporte"]):
                suma = f["h2"] + f["repo"] + f["reporte"] + f["defensa"]
                ajustado = suma * f["factor"]
                tope = ref - VEINTE
                if ajustado < tope:
                    final, tope_ap = tope, "sí"
                else:
                    final, tope_ap = ajustado, "no"
                f.update(suma=suma, ajustado=ajustado, final=final, tope_ap=tope_ap)
            else:
                f.update(suma=None, ajustado=None, final=None, tope_ap="n/a")

    cab = ["equipo", "integrante", "D4_rubrica", "rubrica_100", "defensa_15", "factor", "suma_100",
           "proyecto_ajustado", "referencia_equipo", "tope_aplicado", "proyecto_final"]

    def celda(x, vacio=""):
        return vacio if x is None else str(r2(x))

    if not args.sin_tabla:
        print("| Equipo | Integrante | D1 D2 D3 | P1 | P2 | D4 (/30) | Rúbrica (/100) | Defensa (/15) | Factor | "
              "Suma (/100) | Ajustado | Ref. equipo | Tope | **Proyecto (/100)** |")
        print("|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---|---:|")
        for f in filas:
            print(f"| {f['equipo']} | {f['integrante']} | {f['D1']} {f['D2']} {f['D3']} | {f['P1']} | {f['P2']} | "
                  f"{r2(f['D4'])} | {r2(f['rubrica'])} | {r2(f['defensa'])} | {f['factor']} | "
                  f"{celda(f['suma'], '—')} | {celda(f['ajustado'], '—')} | {celda(f['referencia'], '—')} | "
                  f"{f['tope_ap']} | **{celda(f['final'], '—')}** |")
    if args.salida:
        os.makedirs(os.path.dirname(os.path.abspath(args.salida)), exist_ok=True)
        with open(args.salida, "w", newline="", encoding="utf-8") as fh:
            w = csv.writer(fh)
            w.writerow(cab)
            for f in filas:
                w.writerow([f["equipo"], f["integrante"], r2(f["D4"]), r2(f["rubrica"]), r2(f["defensa"]),
                            f["factor"], celda(f["suma"]), celda(f["ajustado"]), celda(f["referencia"]),
                            f["tope_ap"], celda(f["final"])])
        print(f"\nCSV escrito en {args.salida}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
