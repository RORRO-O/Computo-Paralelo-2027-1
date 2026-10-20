#!/usr/bin/env python3
"""seguimiento.py — Los seis indicadores del método (01-marco-pedagogico.md §5) a partir de la hoja de seguimiento.

Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · herramientas/ · herramienta del profesor

Uso:
    python3 herramientas/seguimiento.py docente/seguimiento-grupo.csv [--alertas]

Entrada: la copia llena de herramientas/seguimiento-grupo.csv (columnas y reglas de llenado en
seguimiento-grupo.md). Esa copia vive en docente/, que no se versiona: las filas de estudiante llevan número de lista.

Salida: la tabla de sesiones (Markdown, para pegar en las notas del curso) y los seis indicadores de 01 §5, cada uno
con una línea "ALERTA <indicador>: ..." por umbral cruzado. Con --alertas imprime solo esas líneas (o "Sin
alertas."). La salida solo contiene agregados y claves de equipo (equipoNN): nunca números de lista ni
calificaciones individuales.

Umbrales (01 §5): recuperación < 60 % en una pregunta de la sesión anterior · "mal" > 30 % de los exit tickets ·
entregas a tiempo < 80 % · equipo con < 60 % en un hito · promedio de (postdicción − calificación) > 1.5 sobre 10 ·
mediana del cambio de calificación ≤ 0 en el grupo "refuerzo" (E1 → E2 y E2 → E3).
Predicción, postdicción y calificación de una fila van en la misma escala, la de la columna `escala` (puntos
máximos del examen; vacía = 10); el script las lleva a 0–10 antes de comparar.

Códigos de salida: 0 bien (haya o no alertas) · 1 el CSV no tiene las columnas de la plantilla · 2 argumentos.

Ejemplo ejecutable (desde herramientas/; la plantilla está vacía y el script lo dice):
    python3 seguimiento.py seguimiento-grupo.csv
"""
import argparse
import csv
import statistics
import sys

COLUMNAS = [
    "fecha", "evento", "ambito", "id", "nivel_diagnostico_ago",
    "retrieval_ant1_pct", "retrieval_ant2_pct",
    "ct1_voto_pct", "ct1_revoto_pct", "ct2_voto_pct", "ct2_revoto_pct",
    "exit_bien", "exit_parcial", "exit_mal", "entregas_a_tiempo_pct",
    "hito_pct", "prediccion", "postdiccion", "calificacion", "escala", "notas",
]
PORCENTAJES = ["retrieval_ant1_pct", "retrieval_ant2_pct", "ct1_voto_pct", "ct1_revoto_pct", "ct2_voto_pct",
               "ct2_revoto_pct", "entregas_a_tiempo_pct", "hito_pct"]
CONTEOS = ["exit_bien", "exit_parcial", "exit_mal"]
CALIFICACIONES = ["prediccion", "postdiccion", "calificacion"]
AMBITOS = ("grupo", "equipo", "estudiante")
NIVELES = ("refuerzo", "medio", "alto")
EXAMENES_MEJORA = ("E1", "E2", "E3")

UMBRAL_RETRIEVAL = 60.0
UMBRAL_EXIT_MAL = 30.0
UMBRAL_ENTREGAS = 80.0
UMBRAL_HITO = 60.0
UMBRAL_BRECHA = 1.5


def aviso(texto):
    print(f"AVISO: {texto}", file=sys.stderr)


def numero(fila, columna, linea):
    texto = fila.get(columna, "").strip()
    if texto == "":
        return None
    try:
        valor = float(texto)
    except ValueError:
        aviso(f"fila {linea}: '{texto}' en {columna} no es un número; se ignora")
        return None
    if columna in PORCENTAJES and not 0 <= valor <= 100:
        aviso(f"fila {linea}: {columna} = {texto} fuera de 0–100; se ignora")
        return None
    if columna in CONTEOS and (valor < 0 or valor != int(valor)):
        aviso(f"fila {linea}: {columna} = {texto} no es un conteo entero >= 0; se ignora")
        return None
    return valor


def leer(ruta):
    with open(ruta, newline="", encoding="utf-8") as fh:
        lector = csv.DictReader(fh)
        columnas = [c.strip() for c in (lector.fieldnames or [])]
        faltan = [c for c in COLUMNAS if c not in columnas]
        if faltan:
            print(f"El CSV {ruta} no tiene las columnas {faltan}. Copia el encabezado de "
                  "herramientas/seguimiento-grupo.csv.", file=sys.stderr)
            sys.exit(1)
        extra = [c for c in columnas if c not in COLUMNAS]
        if extra:
            aviso(f"columnas que el script no usa: {extra}")
        filas = []
        for linea, cruda in enumerate(lector, start=2):
            fila = {(k or "").strip(): (v or "").strip() for k, v in cruda.items() if k is not None}
            if not any(fila.values()):
                continue
            ambito = fila["ambito"].lower()
            if ambito not in AMBITOS:
                aviso(f"fila {linea}: ambito '{fila['ambito']}' no es grupo, equipo ni estudiante; se omite")
                continue
            nivel = fila["nivel_diagnostico_ago"].lower()
            if nivel and nivel not in NIVELES:
                aviso(f"fila {linea}: nivel_diagnostico_ago '{nivel}' no es refuerzo, medio ni alto; se ignora")
                nivel = ""
            registro = {"linea": linea, "fecha": fila["fecha"], "evento": fila["evento"].upper(),
                        "ambito": ambito, "id": fila["id"], "nivel": nivel}
            for c in PORCENTAJES + CONTEOS + CALIFICACIONES + ["escala"]:
                registro[c] = numero(fila, c, linea)
            if registro["escala"] is not None and registro["escala"] <= 0:
                aviso(f"fila {linea}: escala debe ser > 0; se usa 10")
                registro["escala"] = None
            if ambito == "estudiante" and not fila["id"]:
                aviso(f"fila {linea}: fila de estudiante sin id (número de lista); se omite")
                continue
            filas.append(registro)
    return filas


def sobre_10(registro, columna):
    valor = registro[columna]
    if valor is None:
        return None
    return valor * 10.0 / (registro["escala"] or 10.0)


def fmt(valor, decimales=0, signo=False):
    if valor is None:
        return "—"
    return f"{valor:+.{decimales}f}" if signo else f"{valor:.{decimales}f}"


def tabla_sesiones(grupo):
    lineas = ["| Fecha | Evento | Recup. ant. 1 (%) | Recup. ant. 2 (%) | CT1 voto→revoto | CT2 voto→revoto "
              "| Exit bien/parcial/mal | Mal (%) | Entregas a tiempo (%) |",
              "|---|---|---|---|---|---|---|---|---|"]
    for r in grupo:
        b, p, m = r["exit_bien"], r["exit_parcial"], r["exit_mal"]
        total = sum(x for x in (b, p, m) if x is not None)
        exit_txt = "—" if total == 0 else f"{fmt(b)}/{fmt(p)}/{fmt(m)}"
        mal = 100.0 * (m or 0) / total if total else None
        lineas.append(
            f"| {r['fecha'] or '—'} | {r['evento'] or '—'} | {fmt(r['retrieval_ant1_pct'])} "
            f"| {fmt(r['retrieval_ant2_pct'])} | {fmt(r['ct1_voto_pct'])}→{fmt(r['ct1_revoto_pct'])} "
            f"| {fmt(r['ct2_voto_pct'])}→{fmt(r['ct2_revoto_pct'])} | {exit_txt} | {fmt(mal)} "
            f"| {fmt(r['entregas_a_tiempo_pct'])} |")
    return lineas


def etiqueta(r):
    return f"{r['evento'] or 'sin evento'} ({r['fecha'] or 'sin fecha'})"


def indicadores(filas):
    """Devuelve [(titulo, [líneas de detalle], [alertas])] para los seis indicadores de 01 §5."""
    grupo = [r for r in filas if r["ambito"] == "grupo"]
    equipos = [r for r in filas if r["ambito"] == "equipo"]
    estudiantes = [r for r in filas if r["ambito"] == "estudiante"]
    salida = []

    # 1. Recuperación de inicio
    detalle, alertas, valores = [], [], []
    for r in grupo:
        for k, col in ((1, "retrieval_ant1_pct"), (2, "retrieval_ant2_pct")):
            v = r[col]
            if v is None:
                continue
            valores.append(v)
            if v < UMBRAL_RETRIEVAL:
                alertas.append(f"ALERTA retrieval: {etiqueta(r)}, ítem ant{k} (de la sesión anterior) = {v:.0f} % "
                               "→ la siguiente recuperación repite ese ítem con pista (01, P10)")
    detalle.append(f"{len(valores)} pregunta(s) con dato; promedio {fmt(statistics.mean(valores)) if valores else '—'} %")
    salida.append(("1. Recuperación de inicio (< 60 % en una pregunta de la sesión anterior)", detalle, alertas))

    # 2. Exit ticket
    detalle, alertas, n = [], [], 0
    for r in grupo:
        conteos = [r[c] for c in CONTEOS]
        total = sum(x for x in conteos if x is not None)
        if total == 0:
            continue
        n += 1
        mal = 100.0 * (r["exit_mal"] or 0) / total
        if mal > UMBRAL_EXIT_MAL:
            alertas.append(f"ALERTA exit: {etiqueta(r)}, 'mal' = {mal:.0f} % de {total:.0f} tickets "
                           "→ la siguiente sesión abre con el error más frecuente y repite el ejemplo con otro caso")
    detalle.append(f"{n} sesión(es) con montones registrados")
    salida.append(('2. Exit ticket (> 30 % en "mal")', detalle, alertas))

    # 3. Entregas a tiempo
    detalle, alertas, n = [], [], 0
    for r in grupo:
        v = r["entregas_a_tiempo_pct"]
        if v is None:
            continue
        n += 1
        if v < UMBRAL_ENTREGAS:
            alertas.append(f"ALERTA entregas: {etiqueta(r)}, {v:.0f} % a tiempo → revisar la carga de esa semana en "
                           "planeacion/calendario-27-1.md antes de añadir nada")
    detalle.append(f"{n} entrega(s) registrada(s)")
    salida.append(("3. Entregas a tiempo (< 80 % del grupo)", detalle, alertas))

    # 4. Avance del proyecto por hito
    detalle, alertas = [], []
    por_hito = {}
    for r in equipos:
        if r["hito_pct"] is not None:
            por_hito.setdefault(r["evento"] or "sin evento", {})[r["id"] or f"fila{r['linea']}"] = r["hito_pct"]
    for hito, valores in por_hito.items():
        bajos = sorted(k for k, v in valores.items() if v < UMBRAL_HITO)
        detalle.append(f"{hito}: {len(valores)} equipo(s), mediana {statistics.median(valores.values()):.0f} %, "
                       f"{len(bajos)} bajo 60 %")
        if bajos:
            alertas.append(f"ALERTA hito: {hito}, {len(bajos)} equipo(s) con < 60 % ({', '.join(bajos)}) "
                           "→ revisión con el equipo antes del siguiente hito")
    if not por_hito:
        detalle.append("sin filas de equipo con hito_pct")
    salida.append(("4. Avance del proyecto por hito (equipo con < 60 %)", detalle, alertas))

    # 5. Brecha de calibración (postdicción − real); la predicción (al recibir) se reporta aparte
    detalle, alertas = [], []
    por_examen = {}
    for r in estudiantes:
        real = sobre_10(r, "calificacion")
        if real is None:
            continue
        d = por_examen.setdefault(r["evento"] or "sin evento", {"post": [], "pred": []})
        post, pred = sobre_10(r, "postdiccion"), sobre_10(r, "prediccion")
        if post is not None:
            d["post"].append(post - real)
        if pred is not None:
            d["pred"].append(pred - real)
    for examen, d in por_examen.items():
        if not d["post"] and not d["pred"]:
            continue
        media_post = statistics.mean(d["post"]) if d["post"] else None
        media_pred = statistics.mean(d["pred"]) if d["pred"] else None
        sobre = sum(1 for x in d["post"] if x > UMBRAL_BRECHA)
        detalle.append(f"{examen}: postdicción − real = {fmt(media_post, 1, True)} sobre 10 (n = {len(d['post'])}; "
                       f"{sobre} sobreestiman por más de 1.5) · predicción − real = {fmt(media_pred, 1, True)} "
                       f"(n = {len(d['pred'])}, aparte)")
        if media_post is not None and media_post > UMBRAL_BRECHA:
            alertas.append(f"ALERTA calibracion: {examen}, el grupo sobreestima {media_post:.1f} puntos sobre 10 al "
                           "entregar → se muestra el promedio al grupo y cada quien recibe su propia brecha (04 §2.3)")
    if not detalle:
        detalle.append("sin filas de estudiante con calificación y postdicción o predicción")
    salida.append(("5. Brecha de calibración (promedio de postdicción − real > 1.5 sobre 10)", detalle, alertas))

    # 6. Mejora de examen 1 → 2 → 3 por nivel del diagnóstico de agosto
    detalle, alertas = [], []
    nivel_de, notas_de = {}, {}
    for r in estudiantes:
        if r["nivel"]:
            previo = nivel_de.setdefault(r["id"], r["nivel"])
            if previo != r["nivel"]:
                aviso(f"fila {r['linea']}: el estudiante {r['id']} tiene dos niveles ({previo}, {r['nivel']}); "
                      "se usa el primero")
        cal = sobre_10(r, "calificacion")
        if r["evento"] in EXAMENES_MEJORA and cal is not None:
            notas_de.setdefault(r["id"], {})[r["evento"]] = cal
    sin_nivel = sorted(i for i in notas_de if i not in nivel_de)
    if sin_nivel:
        aviso(f"{len(sin_nivel)} estudiante(s) con calificaciones y sin nivel_diagnostico_ago: no entran al indicador 6")
    for nivel in NIVELES:
        ids = [i for i, n in nivel_de.items() if n == nivel]
        partes = []
        for a, b in (("E1", "E2"), ("E2", "E3")):
            cambios = [notas_de[i][b] - notas_de[i][a] for i in ids
                       if i in notas_de and a in notas_de[i] and b in notas_de[i]]
            if not cambios:
                partes.append(f"{a}→{b}: sin datos")
                continue
            mediana = statistics.median(cambios)
            suben = sum(1 for c in cambios if c > 0)
            partes.append(f"{a}→{b}: {suben} de {len(cambios)} suben, mediana {mediana:+.1f}")
            if nivel == "refuerzo" and mediana <= 0:
                alertas.append(f"ALERTA mejora: grupo refuerzo sin mejora de {a} a {b} (mediana {mediana:+.1f} sobre "
                               f"10, {suben} de {len(cambios)} suben) → revisar apoyos de la unidad (01, P10)")
        detalle.append(f"{nivel} ({len(ids)}): " + "; ".join(partes))
    salida.append(('6. Mejora de examen 1 → 2 → 3 (sin mejora en el grupo "refuerzo")', detalle, alertas))
    return salida, grupo


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("csv", help="copia llena de herramientas/seguimiento-grupo.csv")
    ap.add_argument("--alertas", action="store_true", help="imprime solo las líneas ALERTA")
    args = ap.parse_args()

    try:
        filas = leer(args.csv)
    except OSError as e:
        print(f"No pude leer {args.csv}: {e}", file=sys.stderr)
        sys.exit(1)
    if not filas:
        print(f"Sin filas en {args.csv}: copia la plantilla a docente/seguimiento-grupo.csv y registra la primera "
              "sesión (seguimiento-grupo.md §2).")
        return

    resultado, grupo = indicadores(filas)
    alertas = [a for _, _, lista in resultado for a in lista]
    if args.alertas:
        print("\n".join(alertas) if alertas else "Sin alertas.")
        return

    cuenta = {a: sum(1 for r in filas if r["ambito"] == a) for a in AMBITOS}
    print(f"Hoja: {args.csv} · {len(filas)} filas (grupo {cuenta['grupo']}, equipo {cuenta['equipo']}, "
          f"estudiante {cuenta['estudiante']}) · {len(alertas)} alerta(s)\n")
    if grupo:
        print("\n".join(tabla_sesiones(grupo)) + "\n")
    for titulo, detalle, lista in resultado:
        estado = f"{len(lista)} alerta(s)" if lista else "sin alertas"
        print(f"{titulo}: {estado}")
        for linea in detalle:
            print(f"   {linea}")
        for linea in lista:
            print(linea)


if __name__ == "__main__":
    main()
