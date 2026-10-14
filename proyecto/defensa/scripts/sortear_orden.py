#!/usr/bin/env python3
"""sortear_orden.py — Orden de defensa por sorteo con semilla publicada, horario por sesión y temas de la pregunta 2.

Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · Proyecto integrador · Defensa oral (jueves 10 de diciembre de 2026)

Uso:
    python3 sortear_orden.py --semilla SEMILLA --equipos 1-12 [--integrantes 3]
                             [--formato completo|corto|mixto] [--cambio MIN]
                             [--sesiones "AAAA-MM-DD HH:MM DUR" ...] [--apertura 5] [--cierre 5]
                             [--salida orden.md] [--solo-orden | --solo-temas]

    --semilla     Entero o texto publicado antes del sorteo (logistica-defensa.md §4). Mismo valor → mismo orden.
    --equipos     Rango "1-12", lista "1,2,5,7" o archivo CSV con columnas equipo,integrantes (sin encabezado
                  opcional). Los equipos se nombran equipoNN con dos dígitos, como los repositorios cp-6bm1-equipoNN.
    --integrantes Integrantes por equipo cuando --equipos no es un CSV (por defecto 3). Afecta el tiempo de preguntas.
    --formato     completo: 12 min de exposición + 2 preguntas por integrante (40 s c/u) + cambio (1 min)
                  corto:    7 min de exposición + 3 min de preguntas + cambio (1 min)
                  mixto:    2 min de demo + 1 min por integrante (pregunta y posible rescate) + 1 min de margen +
                            cambio (0.5 min, una sola máquina)      [opción c de logistica-defensa.md]
    --cambio      Minutos entre equipos; sustituye el valor del formato.
    --sesiones    Una o más sesiones "fecha hora duración_en_minutos". Por defecto: la del jueves 10 de diciembre
                  de 2026 10:30 (90 min) y las reservas del lunes 14 de diciembre 10:30 (90) y martes 15 de
                  diciembre 08:30 (90). Los equipos se asignan en orden hasta llenar cada sesión.
    --max-por-sesion N  Como mucho N equipos por sesión aunque quepan más (p. ej. 6 y 6 en vez de 7 y 5).
    --apertura    Minutos reservados al inicio de cada sesión (lista, instrucciones), por defecto 5.
    --cierre      Minutos reservados al final (anuncios), por defecto 5.
    --salida      Escribe el informe en Markdown en ese archivo además de imprimirlo.
    --solo-orden  Imprime solo los números de equipo, uno por línea, en el orden sorteado (para verificar).
    --solo-temas  Imprime "NN temaA temaB temaC" por equipo (para verificar).

Método (reproducible por cualquiera, sin este script):
    clave(equipo) = SHA-256 de la cadena "<semilla>-equipoNN" (UTF-8, sin salto de línea); el orden es el orden
    ascendente de las claves en hexadecimal. Verificación a mano:
        printf '%s' '20261210-equipo07' | sha256sum
    Tema de la pregunta 2 para cada posición del equipo (A, B, C): se ordenan los seis temas por
    SHA-256("<semilla>-equipoNN-<tema>") y se toman los tres primeros; así cada integrante recibe un tema distinto.

Salida: informe en Markdown (parámetros, orden con claves, horario por sesión, temas) y resumen por sesión.
Código de salida: 0 si todos los equipos caben en las sesiones dadas; 3 si alguno queda sin horario
(se imprime igual, marcado "SIN HORARIO"); 2 si los argumentos no sirven.

Ejemplo ejecutable (desde esta carpeta):
    python3 sortear_orden.py --semilla 20261210 --equipos 1-12 --formato corto \
        --sesiones "2026-12-10 10:30 90" "2026-12-14 10:30 90"
    python3 sortear_orden.py --semilla 20261210 --equipos ejemplo/equipos.csv --formato completo
"""
import argparse
import csv
import datetime as dt
import hashlib
import os
import sys

TEMAS = ["Foster", "OpenMP", "Medición", "MPI", "CUDA", "Decisiones del equipo"]
DIAS = ["lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"]
MESES = ["", "enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto",
         "septiembre", "octubre", "noviembre", "diciembre"]
SESIONES_POR_DEFECTO = ["2026-12-10 10:30 90", "2026-12-14 10:30 90", "2026-12-15 08:30 90"]


def clave(semilla, texto):
    return hashlib.sha256(f"{semilla}-{texto}".encode("utf-8")).hexdigest()


def leer_equipos(espec, integrantes_defecto):
    """Devuelve lista de (numero, integrantes) a partir de rango, lista o CSV."""
    equipos = []
    if os.path.isfile(espec):
        with open(espec, newline="", encoding="utf-8") as fh:
            for fila in csv.reader(fh):
                if not fila or fila[0].strip().startswith("#"):
                    continue
                if fila[0].strip().lower() == "equipo":
                    continue
                num = int(fila[0])
                integ = int(fila[1]) if len(fila) > 1 and fila[1].strip() else integrantes_defecto
                equipos.append((num, integ))
    elif "-" in espec and "," not in espec:
        a, b = espec.split("-", 1)
        equipos = [(n, integrantes_defecto) for n in range(int(a), int(b) + 1)]
    else:
        equipos = [(int(x), integrantes_defecto) for x in espec.split(",") if x.strip()]
    if not equipos:
        sys.exit("No hay equipos en --equipos")
    if len({n for n, _ in equipos}) != len(equipos):
        sys.exit("Hay números de equipo repetidos en --equipos")
    return equipos


def segundos_por_equipo(formato, integrantes, cambio_min):
    if formato == "completo":
        exposicion, preguntas = 12 * 60, 2 * integrantes * 40
    elif formato == "corto":
        exposicion, preguntas = 7 * 60, 3 * 60
    elif formato == "mixto":
        exposicion, preguntas = 2 * 60, integrantes * 60 + 60
    else:
        sys.exit(f"Formato desconocido: {formato}")
    return exposicion, preguntas, int(round(cambio_min * 60))


def leer_sesiones(lista):
    sesiones = []
    for s in lista:
        partes = s.split()
        if len(partes) != 3:
            sys.exit(f"Sesión mal escrita (se espera 'AAAA-MM-DD HH:MM DUR'): {s!r}")
        inicio = dt.datetime.strptime(partes[0] + " " + partes[1], "%Y-%m-%d %H:%M")
        sesiones.append((inicio, int(partes[2])))
    return sesiones


def nombre_fecha(fecha):
    return f"{DIAS[fecha.weekday()]} {fecha.day} de {MESES[fecha.month]} de {fecha.year}"


def hhmm(t):
    return t.strftime("%H:%M")


def mmss(seg):
    return f"{seg // 60}:{seg % 60:02d}"


def main():
    ap = argparse.ArgumentParser(description="Orden de defensa por semilla publicada", add_help=True)
    ap.add_argument("--semilla", required=True)
    ap.add_argument("--equipos", required=True)
    ap.add_argument("--integrantes", type=int, default=3)
    ap.add_argument("--formato", choices=["completo", "corto", "mixto"], default="completo")
    ap.add_argument("--cambio", type=float, default=None)
    ap.add_argument("--sesiones", nargs="+", default=SESIONES_POR_DEFECTO)
    ap.add_argument("--max-por-sesion", type=int, default=None)
    ap.add_argument("--apertura", type=int, default=5)
    ap.add_argument("--cierre", type=int, default=5)
    ap.add_argument("--salida", default=None)
    ap.add_argument("--solo-orden", action="store_true")
    ap.add_argument("--solo-temas", action="store_true")
    args = ap.parse_args()

    equipos = leer_equipos(args.equipos, args.integrantes)
    cambio = args.cambio if args.cambio is not None else (0.5 if args.formato == "mixto" else 1.0)
    sesiones = leer_sesiones(args.sesiones)

    # Orden: ascendente por clave SHA-256 de "<semilla>-equipoNN".
    orden = sorted(equipos, key=lambda e: clave(args.semilla, f"equipo{e[0]:02d}"))

    if args.solo_orden:
        for num, _ in orden:
            print(f"{num:02d}")
        return 0

    # Temas de la pregunta 2 por posición (A, B, C...): los temas ordenados por su clave.
    temas_por_equipo = {}
    for num, integ in orden:
        ordenados = sorted(TEMAS, key=lambda t: clave(args.semilla, f"equipo{num:02d}-{t}"))
        temas_por_equipo[num] = ordenados[:max(integ, 1)]
    if args.solo_temas:
        for num, _ in orden:
            print(f"{num:02d} " + " ".join(t.replace(" ", "_") for t in temas_por_equipo[num]))
        return 0

    # Horario: se llena cada sesión en orden; lo que no cabe queda SIN HORARIO.
    horario = []
    pendientes = list(orden)
    resumen = []
    for inicio, dur in sesiones:
        util = dur * 60 - (args.apertura + args.cierre) * 60
        t = inicio + dt.timedelta(minutes=args.apertura)
        usado = 0
        asignados = []
        while pendientes:
            num, integ = pendientes[0]
            exp, preg, camb = segundos_por_equipo(args.formato, integ, cambio)
            total = exp + preg + camb
            if usado + total > util:
                break
            if args.max_por_sesion is not None and len(asignados) >= args.max_por_sesion:
                break
            fin_exp = t + dt.timedelta(seconds=exp)
            fin_preg = fin_exp + dt.timedelta(seconds=preg)
            horario.append((num, integ, inicio, t, fin_exp, fin_preg))
            asignados.append(num)
            t = fin_preg + dt.timedelta(seconds=camb)
            usado += total
            pendientes.pop(0)
        resumen.append((inicio, dur, asignados, usado, util))

    lineas = []
    L = lineas.append
    L("# Orden de defensa · sorteo con semilla publicada")
    L("")
    L(f"> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Defensa oral · generado por "
      f"`sortear_orden.py` · semilla `{args.semilla}` · formato `{args.formato}`")
    L("")
    L("## Parámetros")
    L("")
    exp0, preg0, camb0 = segundos_por_equipo(args.formato, args.integrantes, cambio)
    L(f"- Semilla publicada: `{args.semilla}`. Clave de cada equipo = SHA-256 de `\"{args.semilla}-equipoNN\"`; "
      f"orden ascendente por clave. Verificación: `printf '%s' '{args.semilla}-equipo07' | sha256sum`.")
    L(f"- Formato `{args.formato}`: exposición {mmss(exp0)} + preguntas {mmss(preg0)} (equipo de "
      f"{args.integrantes}) + cambio {mmss(camb0)} = {mmss(exp0 + preg0 + camb0)} por equipo.")
    L(f"- Apertura {args.apertura} min y cierre {args.cierre} min por sesión. Equipos: {len(orden)}.")
    L("")
    L("## Orden y horario")
    L("")
    L("| Pos. | Equipo | Clave (12 hex) | Integ. | Sesión | Inicio | Fin exposición | Fin preguntas | "
      "Tema pregunta 2: A | B | C |")
    L("|---|---|---|---|---|---|---|---|---|---|---|")
    asignado = {h[0]: h for h in horario}
    for pos, (num, integ) in enumerate(orden, start=1):
        k = clave(args.semilla, f"equipo{num:02d}")[:12]
        temas = temas_por_equipo[num] + ["—"] * (3 - len(temas_por_equipo[num]))
        if num in asignado:
            _, _, ses, t0, t1, t2 = asignado[num]
            celdas = [nombre_fecha(ses), hhmm(t0), hhmm(t1), hhmm(t2)]
        else:
            celdas = ["**SIN HORARIO**", "—", "—", "—"]
        L(f"| {pos} | cp-6bm1-equipo{num:02d} | `{k}` | {integ} | " + " | ".join(celdas) +
          f" | {temas[0]} | {temas[1]} | {temas[2]} |")
    L("")
    L("## Resumen por sesión")
    L("")
    L("| Sesión | Duración | Útil (sin apertura/cierre) | Equipos | Minutos usados | Sobran |")
    L("|---|---|---|---|---|---|")
    for inicio, dur, asignados, usado, util in resumen:
        eq = ", ".join(f"{n:02d}" for n in asignados) if asignados else "—"
        L(f"| {nombre_fecha(inicio)} {hhmm(inicio)} | {dur} min | {util // 60} min | {len(asignados)} ({eq}) | "
          f"{usado / 60:.1f} | {(util - usado) / 60:.1f} |")
    if pendientes:
        L("")
        L("**AVISO: equipos sin horario** (no caben en las sesiones dadas con este formato): " +
          ", ".join(f"cp-6bm1-equipo{n:02d}" for n, _ in pendientes) +
          ". Opciones: otra sesión de reserva, formato más corto o menos tiempo de cambio.")
    texto = "\n".join(lineas) + "\n"
    print(texto, end="")
    if args.salida:
        os.makedirs(os.path.dirname(os.path.abspath(args.salida)), exist_ok=True)
        with open(args.salida, "w", encoding="utf-8") as fh:
            fh.write(texto)
    return 3 if pendientes else 0


if __name__ == "__main__":
    sys.exit(main())
