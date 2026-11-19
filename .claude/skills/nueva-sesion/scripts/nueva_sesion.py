#!/usr/bin/env python3
"""nueva_sesion.py — Crea el andamio de una sesión Sxx_AAAA-MM-DD_tema-corto/ (skill /nueva-sesion).

Genera exactamente los 8 elementos de docs/CONVENCIONES.md §1 (7 archivos .md y practica-guiada/), cada uno con
el encabezado de metadatos de §2, y una práctica guiada cuyo código compila sin warnings y pasa `make test`.
Lo que el autor debe escribir queda marcado con `[PENDIENTE: ...]`: el andamio NO es material terminado.

Uso:
    nueva_sesion.py UNIDAD SESION TEMA-CORTO [opciones]
        UNIDAD      U5, 5 o V
        SESION      S07 o 7
        TEMA-CORTO  minúsculas, dígitos y guiones: sincronizacion-reduccion

Fecha, hora, tipo y tema se toman de planeacion/calendario-*.md. Las opciones los sustituyen o los completan
cuando la sesión todavía no está en el calendario:
    --fecha AAAA-MM-DD     fecha de la sesión (si contradice el calendario, se rechaza salvo con --forzar)
    --hora HH:MM-HH:MM     por defecto según el día: lunes y jueves 10:30-12:00, martes 08:30-10:00
    --lugar TEXTO          por defecto "Salón 3208"; "Lab LS4" si el tipo es Laboratorio
    --tipo TEXTO           Contenido | Laboratorio | Repaso | Taller | ... (por defecto, el del calendario)
    --titulo TEXTO         título de la sesión (por defecto, el tema del calendario)
    --tec openmp|mpi|gpu   tecnología de la práctica guiada (por defecto: U3 openmp, U4 mpi, U5 gpu)
    --raiz DIR             raíz del repositorio (por defecto, la que contiene este script)
    --destino DIR          carpeta donde crear la sesión (por defecto, unidades/U<k>-*/ de la raíz)
    --forzar               acepta una fecha distinta de la del calendario (queda un [PENDIENTE] en plan-sesion.md)
    --seco                 solo muestra qué se crearía

Código de salida: 0 si creó la carpeta; 2 si los argumentos no sirven; 3 si la carpeta ya existe (no se sobrescribe).
"""
import argparse
import datetime as dt
import re
import shutil
import stat
import sys
from pathlib import Path

CURSO_POR_DEFECTO = "Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1"
DIAS = ["lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"]
DIAS_ABREV = {"lun": 0, "mar": 1, "mié": 2, "mie": 2, "jue": 3, "vie": 4, "sáb": 5, "sab": 5, "dom": 6}
MESES = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre",
         "noviembre", "diciembre"]
MESES_ABREV = {m[:3]: i + 1 for i, m in enumerate(MESES)}
ROMANOS = {1: "I", 2: "II", 3: "III", 4: "IV", 5: "V", 6: "VI", 7: "VII", 8: "VIII"}
HORA_POR_DIA = {0: "10:30–12:00", 1: "08:30–10:00", 3: "10:30–12:00"}
TEC_POR_UNIDAD = {3: "openmp", 4: "mpi", 5: "gpu"}
PEND = "[PENDIENTE: {}]"


def error(msg, codigo=2):
    print(f"nueva_sesion.py: {msg}", file=sys.stderr)
    sys.exit(codigo)


def fecha_larga(d):
    return f"{DIAS[d.weekday()]} {d.day} de {MESES[d.month - 1]} de {d.year}"


def leer_unidad(texto):
    t = texto.strip().upper().lstrip("U")
    if t.isdigit():
        return int(t)
    for k, r in ROMANOS.items():
        if t == r:
            return k
    error(f"unidad no reconocida: '{texto}' (usa U5, 5 o V)")


def leer_sesion(texto):
    m = re.fullmatch(r"[sS]?(\d{1,2})", texto.strip())
    if not m:
        error(f"sesión no reconocida: '{texto}' (usa S07 o 7)")
    return int(m.group(1))


def leer_calendario(raiz):
    """Devuelve (curso, filas). Cada fila: dict(unidad, id, fecha, hora_inicio, tipo, tema, entregas)."""
    candidatos = sorted((raiz / "planeacion").glob("calendario-*.md"))
    if not candidatos:
        return None, [], None
    ruta = candidatos[-1]
    texto = ruta.read_text(encoding="utf-8")
    curso = None
    m = re.search(r"^>\s*\*\*(.+?)\*\*", texto, re.M)
    if m:
        curso = m.group(1).strip()
    anio = None
    m = re.search(r"^#\s.*\b(20\d{2})\b", texto, re.M)
    if m:
        anio = int(m.group(1))
    filas, unidad = [], None
    for linea in texto.splitlines():
        m = re.match(r"^##\s+Unidad\s+([IVX]+)\b", linea)
        if m:
            unidad = next((k for k, r in ROMANOS.items() if r == m.group(1)), None)
            continue
        if linea.startswith("## "):
            unidad = None
            continue
        if not linea.startswith("|"):
            continue
        celdas = [c.strip() for c in linea.strip().strip("|").split("|")]
        if len(celdas) < 4:
            continue
        m = re.match(r"^(\w{3})\s+(\d{1,2})\s+(\w{3})(?:\s+(\d{1,2}:\d{2}))?$", celdas[1])
        if not m or m.group(3).lower() not in MESES_ABREV or anio is None:
            continue
        try:
            fecha = dt.date(anio, MESES_ABREV[m.group(3).lower()], int(m.group(2)))
        except ValueError:
            continue
        filas.append({
            "unidad": unidad, "id": celdas[0], "fecha": fecha, "hora_inicio": m.group(4),
            "dia_abrev": m.group(1).lower(), "tipo": re.sub(r"\*", "", celdas[2]),
            "tema": celdas[3], "entregas": celdas[4] if len(celdas) > 4 else "",
        })
    return curso, filas, ruta


def hora_fin(inicio):
    h, m = (int(x) for x in inicio.split(":"))
    fin = dt.datetime(2000, 1, 1, h, m) + dt.timedelta(minutes=90)
    return f"{inicio}–{fin:%H:%M}"


def render(texto, datos):
    for clave, valor in datos.items():
        texto = texto.replace("{{" + clave + "}}", str(valor))
    faltan = re.findall(r"\{\{(\w+)\}\}", texto)
    if faltan:
        error(f"plantilla con variables sin valor: {sorted(set(faltan))}", 1)
    return "\n".join(linea.rstrip() for linea in texto.split("\n"))


# ---------------------------------------------------------------------------------------------------------
# Plantillas Markdown. {{ENC}} es el encabezado de metadatos (CONVENCIONES §2).
# ---------------------------------------------------------------------------------------------------------
PLAN = """{{ENC}}

# {{SID}} · {{TITULO}}

**Tipo:** {{TIPO}} ({{VARIANTE}}). {{NOTA_FECHA}}

## Objetivos (al terminar, el estudiante podrá…)
1. [PENDIENTE: verbo observable + contenido + condición (nivel: comprender / aplicar / analizar / evaluar)]
2. [PENDIENTE: segundo objetivo; cada objetivo se evalúa en `exit-ticket.md`]
3. [PENDIENTE: tercer objetivo]

## Prerrequisitos y vínculo
- Viene de: {{ANTERIOR}}
- Va hacia: {{SIGUIENTE}}
- Idea(s) errónea(s) que esta sesión ataca: [PENDIENTE: al menos 2 números del Anexo A de `docs/metodo/01-marco-pedagogico.md`]
- Nivel de andamiaje: [PENDIENTE: completo / por completar / con pistas, según `docs/metodo/07-guia-de-autoria.md` §A.5]

## Materiales
- Archivos de esta carpeta; proyector; cronómetro; tarjetas de lista; {{EQUIPO}}.
- Plan B de `docs/metodo/02-plantilla-sesion.md` §2.7.

## Guion minuto a minuto
### 0–5 Recuperación
[PENDIENTE: qué proyectar de `retrieval-inicio.md`; respuesta esperada; qué hacer si menos de 60 % acierta la pregunta 1]
### 5–10 Objetivos y anclaje
[PENDIENTE: frase exacta que conecta con el exit ticket anterior y con el proyecto; autocalificación de la tarea espaciada anterior (2 min)]
### 10–35 Instrucción explícita I
[PENDIENTE: pasos de `ejemplo-resuelto.md`; qué decir en cada pausa; ConcepTest 1: pregunta, % esperado, guion de discusión]
### 35–65 Práctica guiada PRIMM
[PENDIENTE: instrucciones de arranque; lista de errores esperados con la pregunta socrática ante cada uno; cambio de roles a los 15 min]
### 65–75 Puesta en común
[PENDIENTE: los 2–3 hallazgos que se muestran (sin nombres ni números de lista); ConcepTest 2; regla general en una frase]
### 75–85 Transferencia
[PENDIENTE: reto (fase Crear); criterio de "listo"; extensión para quien termina; apoyo para quien no arranca]
### 85–90 Cierre
[PENDIENTE: exit ticket; anuncio de la tarea espaciada, que vence {{VENCE}}]

## Diferenciación
- Apoyo (quien no arranca): [PENDIENTE: el mismo ejemplo resuelto con un hueco menos o una pista sellada en `<details>`]
- Ampliación (quien termina): [PENDIENTE: el problema sin ejemplo, o la variante Crear con una restricción más]

## Evaluación formativa de la sesión
- [PENDIENTE: qué mira el profesor para saber si se cumplió cada objetivo]

## Notas post-sesión
- (se llenan después) qué falló, qué cambiar, error más frecuente del exit ticket.
"""

RETRIEVAL = """{{ENC}}

# {{SID}} · Recuperación de inicio (5 minutos, individual, sin apuntes ni dispositivos)

Responde por escrito. A los 4 minutos se muestran las respuestas; levanta la mano por cada pregunta que hayas
acertado. [PENDIENTE: si la recuperación tiene peso en este parcial, citarlo desde `planeacion/mapa-evaluacion.md`]

## Preguntas

**1. ({{ANTERIOR_CORTO}})** [PENDIENTE: pregunta de la sesión anterior, contestable en menos de 1 min]

**2. ({{ANTERIOR_CORTO}})** [PENDIENTE: segunda pregunta de la sesión anterior]

**3. (Unidad previa)** [PENDIENTE: pregunta de una unidad anterior]

**4. (Unidad previa)** [PENDIENTE: pregunta de otra unidad anterior, u omitir si se dejan 4 preguntas]

**5. (Anticipa el tema de hoy)** [PENDIENTE: pregunta que el estudiante todavía no sabe contestar bien y que la sesión resuelve]

## Respuestas

<details><summary>Ver respuestas (ábrelas después de contestar)</summary>

1. [PENDIENTE: respuesta 1]
2. [PENDIENTE: respuesta 2]
3. [PENDIENTE: respuesta 3]
4. [PENDIENTE: respuesta 4]
5. [PENDIENTE: respuesta 5; se retoma en el minuto 10]

</details>

## Para el profesor

[PENDIENTE: qué hacer según el porcentaje de acierto de cada pregunta]
"""

NOTAS = """{{ENC}}

# {{SID}} · {{TITULO}}

Palabras clave: [PENDIENTE: 4–6 términos; cada término técnico en español con el inglés entre paréntesis la primera vez]

## 1. El concepto
[PENDIENTE: lectura breve; el archivo completo cabe en 2 páginas. Frases cortas, una idea por párrafo]

## 2. Ejemplo resuelto comentado
[PENDIENTE: un ejemplo corto con código de `practica-guiada/` y su salida REAL, copiada de una ejecución]

## 3. Errores frecuentes
- [PENDIENTE: error 1, con el número de la idea errónea del Anexo A]
- [PENDIENTE: error 2]
- [PENDIENTE: error 3]

## 4. Para saber más
- [PENDIENTE: fuente oficial (especificación de OpenMP, estándar MPI, guía de CUDA) con sección]
"""

EJEMPLO = """{{ENC}}

# {{SID}} · Ejemplo resuelto: [PENDIENTE: nombre del problema]

Lee el código con las pausas. En cada pausa contesta por escrito **antes** de abrir la respuesta.

## Problema
[PENDIENTE: enunciado en 3–4 líneas]

## Plan (3 líneas)
[PENDIENTE: qué se paraleliza, qué se comparte, cómo se verifica]

## Código comentado
[PENDIENTE: fragmentos del programa de `practica-guiada/`, no código suelto que no compile]

### Pausa 1 · [PENDIENTE: ¿por qué este paso?]

<details><summary>Respuesta</summary>

[PENDIENTE: respuesta de la pausa 1]

</details>

## Salida
[PENDIENTE: salida REAL del programa con el comando exacto que la produjo; nunca una salida imaginada]

### Pausa 2 · [PENDIENTE: pregunta sobre la salida]

<details><summary>Respuesta</summary>

[PENDIENTE: respuesta de la pausa 2]

</details>

## Variante que falla
[PENDIENTE: el cambio pequeño que rompe el programa y cómo se nota]

### Pausa 3 · [PENDIENTE: ¿qué idea errónea explica el fallo?]

<details><summary>Respuesta</summary>

[PENDIENTE: respuesta de la pausa 3]

</details>

## Qué te llevas
- [PENDIENTE: la regla general en una frase]
"""

CONCEPTESTS = """{{ENC}}

# {{SID}} · ConcepTests (instrucción entre pares)

Secuencia fija: voto individual (1 min) → discusión en parejas (2 min) → revoto → explicación del profesor. Si el
primer voto supera 80 % de aciertos, se salta la discusión; si queda por debajo de 30 %, se vuelve a explicar antes
de discutir. Se vota con tarjetas A/B/C/D o con los dedos.

---

## ConcepTest 1 · [PENDIENTE: título] (minuto ~28, después del ejemplo resuelto)

[PENDIENTE: enunciado, con código si aplica]

- **A.** [PENDIENTE: opción]
- **B.** [PENDIENTE: opción]
- **C.** [PENDIENTE: opción]
- **D.** [PENDIENTE: opción]

<details><summary>Respuesta y origen de los distractores</summary>

**Respuesta: [PENDIENTE: letra].** Acierto esperado en el primer voto: [PENDIENTE: porcentaje].

| Opción | Origen |
|---|---|
| A | [PENDIENTE: número de la idea errónea del Anexo A de la que nace, o "correcta"] |
| B | [PENDIENTE: ídem] |
| C | [PENDIENTE: ídem] |
| D | [PENDIENTE: ídem] |

**Qué decir en la discusión:** [PENDIENTE: guion de 3–4 líneas]

</details>

## ConcepTest 2 · [PENDIENTE: título] (minuto ~68, puesta en común)

[PENDIENTE: enunciado]

- **A.** [PENDIENTE: opción]
- **B.** [PENDIENTE: opción]
- **C.** [PENDIENTE: opción]
- **D.** [PENDIENTE: opción]

<details><summary>Respuesta y origen de los distractores</summary>

**Respuesta: [PENDIENTE: letra].** Acierto esperado en el primer voto: [PENDIENTE: porcentaje].

| Opción | Origen |
|---|---|
| A | [PENDIENTE: idea errónea del Anexo A o "correcta"] |
| B | [PENDIENTE: ídem] |
| C | [PENDIENTE: ídem] |
| D | [PENDIENTE: ídem] |

**Qué decir en la discusión:** [PENDIENTE: guion de 3–4 líneas]

</details>

## Registro del profesor (llenar durante la sesión)

| ConcepTest | % primer voto | % revoto | Nota |
|---|---|---|---|
| 1 | | | |
| 2 | | | |
"""

EXIT = """{{ENC}}

# {{SID}} · Exit ticket (5 minutos, individual)

Responde en media hoja y entrégala al salir. [PENDIENTE: si cuenta la entrega, citarlo desde `planeacion/mapa-evaluacion.md`]

## 1. Conceptual
[PENDIENTE: pregunta que evalúa el objetivo 1]

## 2. Aplicación corta
[PENDIENTE: pregunta que evalúa el objetivo 2, contestable en 2 minutos]

## 3. Confianza y duda
Del 1 (nada seguro) al 4 (muy seguro): ¿qué tan seguro estás de tus dos respuestas? Escribe una duda que te llevas.

<details><summary>Clave (para clasificar cada ticket en bien / parcial / mal en 20 segundos)</summary>

1. [PENDIENTE: clave literal de la pregunta 1: qué debe decir para "bien", qué para "parcial"]
2. [PENDIENTE: clave literal de la pregunta 2]

</details>
"""

TAREA = """{{ENC}}

# {{SID}} · Tarea espaciada (20–40 minutos)

**Entrega.** Individual, en el repositorio del equipo: `tareas/<usuario-github>/U{{K}}-{{SID}}.md` (y, si hay
código, en `tareas/<usuario-github>/U{{K}}-{{SID}}/`). Vence {{VENCE}}. Se autocalifica con su clave en los minutos
5–10 de esa sesión. [PENDIENTE: peso o uso de la tarea, citado desde `planeacion/mapa-evaluacion.md`]

## 1. Del tema de hoy (15 min)
[PENDIENTE: ejercicio del tema; si en clase se recortó Transferencia, aquí va íntegra la fase Crear de PRIMM]

## 2. Intercalado · [PENDIENTE: unidad previa] (10 min)
[PENDIENTE: ejercicio de una unidad anterior]

## 3. Preparación de la siguiente sesión (5–10 min)
[PENDIENTE: lectura o predicción para {{SIGUIENTE}}]

<details><summary>Clave para autocalificar</summary>

1. [PENDIENTE: clave del ejercicio 1]
2. [PENDIENTE: clave del ejercicio 2]
3. [PENDIENTE: qué debe traer preparado]

</details>
"""

PRIMM = """{{ENC}}

# {{SID}} · Práctica guiada PRIMM: [PENDIENTE: título]

Trabajo en parejas: **conductor** (teclado) y **navegante** (lee, predice, anota). Se cambian los roles a los 15
minutos. Todo lo que predigas se escribe **antes** de ejecutar; después se compara.

## Archivos

| Archivo | Qué es | Fase |
|---|---|---|
{{TABLA_ARCHIVOS}}
| `Makefile`, `tests/run_tests.sh` | `make`, `make run`, `make test`, `make clean` | — |

### Compilar y correr

```bash
{{COMANDOS}}
```

## Fase 1 · Predecir (8 min, sin ejecutar nada)
[PENDIENTE: 2–3 preguntas concretas sobre el código: qué imprime, cuántas veces, en qué orden, cuánto tarda]

## Fase 2 · Ejecutar (5 min)
[PENDIENTE: comandos exactos y qué comparar con la predicción]

## Fase 3 · Investigar (10 min)
[PENDIENTE: preguntas I1–I3 que obligan a leer el código y a cambiar un parámetro]

## Fase 4 · Modificar (7 min)
[PENDIENTE: cambios pequeños con objetivo verificable por `make test`; lo que el estudiante completa va en `/* TODO(n): ... */`]

## Fase 5 · Crear (10 min en clase; si no alcanza, pasa íntegra a `tarea-espaciada.md`)
[PENDIENTE: problema nuevo que usa el constructo de hoy; criterio de "listo"]

## Uso de IA en esta práctica

[PENDIENTE: un ejemplo 🟢, uno 🟡 y uno 🔴 propios de esta práctica, según `docs/metodo/05-politica-ia.md`]
"""

TEC = {
    "openmp": {
        "equipo": "una laptop por pareja con `gcc -fopenmp` verificado",
        "tabla": "| `main.c` | Programa base (C + OpenMP); sin `-fopenmp` es la referencia secuencial | "
                 "[PENDIENTE: fase] |",
        "comandos": "make                                # gcc -std=c11 -O2 -Wall -Wextra -fopenmp, sin warnings\n"
                    "make test                           # paralelo contra secuencial con tolerancia\n"
                    "OMP_NUM_THREADS=4 ./programa 20000000\n"
                    "make clean",
        "gitignore": "# Binarios generados por el Makefile de esta práctica (no se versionan)\n"
                     "programa\nprograma_seq\n*.o\n*_tsan\nresultados/\n",
    },
    "mpi": {
        "equipo": "una laptop por pareja con `mpicc` y `mpirun` verificados",
        "tabla": "| `main_mpi.c` | Programa base (C + MPI) | [PENDIENTE: fase] |\n"
                 "| `main_seq.c` | Referencia secuencial de las pruebas | — |",
        "comandos": "make                                # mpicc -std=c11 -O2 -Wall -Wextra, sin warnings\n"
                    "make test                           # MPI contra secuencial con tolerancia\n"
                    "mpirun $MPIRUN_FLAGS -np 4 ./programa_mpi 20000000\n"
                    "make clean",
        "gitignore": "# Binarios generados por el Makefile de esta práctica (no se versionan)\n"
                     "programa_mpi\nprograma_seq\n*.o\nresultados/\n",
    },
    "gpu": {
        "equipo": "Colab o Kaggle con GPU comprobada ese día; sin GPU, el espejo Numba con `NUMBA_ENABLE_CUDASIM=1`",
        "tabla": "| `main_numba.py` | Kernel en Numba CUDA (corre en GPU o en el simulador) | [PENDIENTE: fase] |\n"
                 "| `main_cpu.c` | Referencia en CPU de las pruebas | — |",
        "comandos": "make                                # compila la referencia en CPU\n"
                    "make test                           # sin GPU: Numba en el simulador contra la CPU\n"
                    "make sim                            # el kernel en el simulador (solo correctitud)\n"
                    "make run                            # REQUIERE GPU (Colab/Kaggle)\n"
                    "make clean",
        "gitignore": "# Generados por el Makefile de esta práctica (no se versionan)\nmain_cpu\n*.o\n__pycache__/\n"
                     "tests/out/\n",
    },
}


def variante(tipo):
    t = tipo.lower()
    if "laboratorio" in t:
        return "variante de laboratorio de `docs/metodo/02-plantilla-sesion.md` §2.1; ajusta los bloques del guion"
    if "repaso" in t and "hito" in t or "+ hito" in t:
        return "sesión con hito de `docs/metodo/02-plantilla-sesion.md` §2.5; ajusta los bloques del guion"
    if "repaso" in t:
        return ("repaso previo a examen de `docs/metodo/02-plantilla-sesion.md` §2.2; agrega `examen-practica-*.md` y "
                "ajusta los bloques del guion")
    if "taller" in t:
        return "taller de proyecto de `docs/metodo/02-plantilla-sesion.md` §2.4; ajusta los bloques del guion"
    return "estructura base de 90 min de `docs/metodo/02-plantilla-sesion.md` §1"


def copiar_practica(tec, destino, raiz, plantillas, datos):
    pg = destino / "practica-guiada"
    (pg / "tests").mkdir(parents=True)
    herr = raiz / "herramientas"
    if tec in ("openmp", "mpi"):
        mk_src = herr / f"Makefile.{tec}"
        rt_src = herr / "plantilla-run_tests.sh"
        for f in (mk_src, rt_src):
            if not f.is_file():
                error(f"falta {f}: la práctica guiada de {tec} se arma con las plantillas de herramientas/", 1)
        try:
            rel = Path("..") / Path(*[".."] * len(pg.resolve().relative_to(raiz.resolve()).parts[:-1])) / "herramientas"
        except ValueError:  # --destino fuera del repositorio: ruta absoluta a herramientas/
            rel = herr.resolve()
        mk = mk_src.read_text(encoding="utf-8")
        mk = re.sub(r"^(MEDIR\s+\?=\s+).*$", rf"\g<1>{rel}/medir.sh", mk, flags=re.M)
        mk = re.sub(r"^(GRAFICAR\s+\?=\s+).*$", rf"\g<1>{rel}/graficar_speedup.py", mk, flags=re.M)
        mk = (f"# Práctica guiada {datos['SID']} (Unidad {datos['ROMANO']}) · copia de herramientas/Makefile.{tec} "
              f"hecha por /nueva-sesion.\n") + mk
        (pg / "Makefile").write_text(mk, encoding="utf-8")
        shutil.copyfile(rt_src, pg / "tests" / "run_tests.sh")
        for fuente in sorted((plantillas / tec).glob("*.c")):
            shutil.copyfile(fuente, pg / fuente.name)
    else:
        base = plantillas / "gpu"
        for nombre in ("Makefile", "main_cpu.c", "main_numba.py"):
            shutil.copyfile(base / nombre, pg / nombre)
        shutil.copyfile(base / "tests" / "run_tests.sh", pg / "tests" / "run_tests.sh")
    rt = pg / "tests" / "run_tests.sh"
    rt.chmod(rt.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    (pg / ".gitignore").write_text(TEC[tec]["gitignore"], encoding="utf-8")
    readme = render(PRIMM, {**datos, "TABLA_ARCHIVOS": TEC[tec]["tabla"], "COMANDOS": TEC[tec]["comandos"]})
    (pg / "README.md").write_text(readme, encoding="utf-8")


def main():
    ap = argparse.ArgumentParser(description="Crea el andamio de una sesión del curso (skill /nueva-sesion).")
    ap.add_argument("unidad")
    ap.add_argument("sesion")
    ap.add_argument("tema")
    ap.add_argument("--fecha")
    ap.add_argument("--hora")
    ap.add_argument("--lugar")
    ap.add_argument("--tipo")
    ap.add_argument("--titulo")
    ap.add_argument("--tec", choices=sorted(TEC))
    ap.add_argument("--raiz")
    ap.add_argument("--destino")
    ap.add_argument("--forzar", action="store_true")
    ap.add_argument("--seco", action="store_true")
    a = ap.parse_args()

    script = Path(__file__).resolve()
    plantillas = script.parent.parent / "plantillas"
    raiz = Path(a.raiz).resolve() if a.raiz else script.parents[4]
    k = leer_unidad(a.unidad)
    num = leer_sesion(a.sesion)
    sid = f"S{num:02d}"
    if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", a.tema):
        error(f"tema corto no válido: '{a.tema}' (minúsculas sin acentos, dígitos y guiones: planificacion-carga)")

    curso, filas, ruta_cal = leer_calendario(raiz)
    curso = curso or CURSO_POR_DEFECTO
    idx = next((i for i, f in enumerate(filas) if f["unidad"] == k and f["id"] == sid), None)
    fila = filas[idx] if idx is not None else None

    fecha = None
    if a.fecha:
        try:
            fecha = dt.date.fromisoformat(a.fecha)
        except ValueError:
            error(f"fecha no válida: '{a.fecha}' (formato AAAA-MM-DD)")
    nota_fecha = ""
    if fila:
        if fecha and fecha != fila["fecha"]:
            if not a.forzar:
                error(f"--fecha {fecha} contradice {ruta_cal.relative_to(raiz)}, que fija U{k} {sid} el "
                      f"{fecha_larga(fila['fecha'])}. Corrige el calendario primero o usa --forzar.")
            nota_fecha = PEND.format(f"la fecha difiere del calendario ({fecha_larga(fila['fecha'])}); "
                                     f"actualiza {ruta_cal.relative_to(raiz)}")
        fecha = fecha or fila["fecha"]
        if DIAS_ABREV.get(fila["dia_abrev"]) not in (None, fila["fecha"].weekday()):
            error(f"{ruta_cal.relative_to(raiz)} dice '{fila['dia_abrev']}' para U{k} {sid}, pero el "
                  f"{fila['fecha'].isoformat()} es {DIAS[fila['fecha'].weekday()]}. Corrige el calendario.", 1)
    elif fecha is None:
        error(f"U{k} {sid} no está en el calendario ({ruta_cal.relative_to(raiz) if ruta_cal else 'no hay'}); "
              f"da --fecha AAAA-MM-DD.")
    else:
        nota_fecha = PEND.format("esta sesión no está en planeacion/calendario; agrégala antes de publicar")

    tipo = a.tipo or (fila["tipo"] if fila else "Contenido")
    titulo = a.titulo or (fila["tema"] if fila else PEND.format("título de la sesión"))
    if a.hora:
        hora = a.hora.replace("-", "–")
    elif fila and fila["hora_inicio"]:
        hora = hora_fin(fila["hora_inicio"])
    elif fecha.weekday() in HORA_POR_DIA:
        hora = HORA_POR_DIA[fecha.weekday()]
    else:
        error(f"el {fecha_larga(fecha)} no es día de clase del grupo (lunes, martes, jueves); da --hora HH:MM-HH:MM.")
    lugar = a.lugar or ("Lab LS4" if "laboratorio" in tipo.lower() else "Salón 3208")
    tec = a.tec or TEC_POR_UNIDAD.get(k)
    if tec is None:
        error(f"no hay tecnología por defecto para la Unidad {ROMANOS.get(k, k)}; da --tec openmp|mpi|gpu.")

    def describir(f):
        if f is None:
            return None
        ini = f", {f['hora_inicio']}" if f["hora_inicio"] else ""
        u = f"U{f['unidad']}·" if f["unidad"] and f["unidad"] != k else ""
        return f"{u}{f['id']} ({fecha_larga(f['fecha'])}{ini})"

    con_clase = [f for f in filas if f["hora_inicio"] and "sin clase" not in f["tipo"].lower()]
    antes = [f for f in con_clase if f["fecha"] < fecha]
    despues = [f for f in con_clase if f["fecha"] > fecha]
    ant, sig = (antes[-1] if antes else None), (despues[0] if despues else None)
    anterior = describir(ant) or PEND.format("sesión anterior")
    siguiente = describir(sig) or PEND.format("siguiente sesión, con fecha y hora")
    if sig:
        vence = (f"al inicio de {sig['id']}: **{fecha_larga(sig['fecha'])}, {sig['hora_inicio']}**")
        if not re.fullmatch(r"S\d+", sig["id"]):
            vence += " " + PEND.format(f"{sig['id']} no es una sesión ordinaria; confirma la fecha de entrega")
    else:
        vence = PEND.format("fecha con día de la semana y hora de inicio de la siguiente sesión")

    romano = ROMANOS.get(k, str(k))
    enc = f"> **{curso}** · Unidad {romano} · Sesión {sid} · {fecha_larga(fecha)} · {hora} · {lugar}"
    datos = {
        "ENC": enc, "SID": sid, "K": k, "ROMANO": romano, "TITULO": titulo, "TIPO": tipo,
        "VARIANTE": variante(tipo), "NOTA_FECHA": nota_fecha, "ANTERIOR": anterior, "SIGUIENTE": siguiente,
        "ANTERIOR_CORTO": ant["id"] if ant else "sesión anterior", "VENCE": vence, "EQUIPO": TEC[tec]["equipo"],
    }

    if a.destino:
        base = Path(a.destino).resolve()
    else:
        unidades = sorted((raiz / "unidades").glob(f"U{k}-*"))
        if len(unidades) != 1:
            error(f"no encuentro una única carpeta unidades/U{k}-*/ en {raiz}; créala o da --destino.")
        base = unidades[0]
    destino = base / f"{sid}_{fecha.isoformat()}_{a.tema}"
    choque = sorted(base.glob(f"{sid}_*")) if base.is_dir() else []
    if destino.exists() or choque:
        error(f"ya existe {choque[0] if choque else destino}; no se sobrescribe una sesión.", 3)

    archivos = {"plan-sesion.md": PLAN, "retrieval-inicio.md": RETRIEVAL, "notas-estudiante.md": NOTAS,
                "ejemplo-resuelto.md": EJEMPLO, "conceptests.md": CONCEPTESTS, "exit-ticket.md": EXIT,
                "tarea-espaciada.md": TAREA}
    print(f"sesion={destino}")
    print(f"encabezado={enc}")
    print(f"tecnologia={tec}")
    if a.seco:
        print("seco=1 (no se creó nada)")
        return 0
    destino.mkdir(parents=True)
    for nombre, plantilla in archivos.items():
        (destino / nombre).write_text(render(plantilla, datos), encoding="utf-8")
    copiar_practica(tec, destino, raiz, plantillas, datos)
    pendientes = sum(p.read_text(encoding="utf-8").count("[PENDIENTE:") for p in destino.rglob("*.md"))
    print(f"pendientes={pendientes}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
