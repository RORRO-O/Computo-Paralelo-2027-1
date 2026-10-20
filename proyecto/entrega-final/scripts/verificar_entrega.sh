#!/usr/bin/env bash
# scripts/verificar_entrega.sh · Verificación automática de la entrega final del proyecto integrador
# Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1
#
# Uso:  bash verificar_entrega.sh RUTA_AL_REPO [--sin-ejecutar] [--sin-red]
#       RUTA_AL_REPO    raíz de un clon del repositorio del equipo (cp-6bm1-equipoNN)
#       --sin-ejecutar  solo revisa archivos y git: no corre make, make test ni run_all.sh
#       --sin-red       no consulta GitHub (git ls-remote) para confirmar la etiqueta
#       -h, --help      muestra esta ayuda
#       LIMITE_EPOCH    (variable de entorno, opcional) fecha límite en segundos Unix para el aviso de entrega
#                       tardía del ítem 24; por defecto 1796661000 = lunes 7 dic 2026 10:30 en la Ciudad de México.
#                       El aviso usa la hora del commit etiquetado; la que vale es la de GitHub al subir la etiqueta.
# Quién lo usa: el equipo, antes de etiquetar (lista-cotejo-entrega.md, columna "Auto"), y el
#       profesor, en los primeros minutos de la revisión (reproducibilidad.md §1).
# Qué revisa: los ítems 1–24 de lista-cotejo-entrega.md que una máquina puede comprobar y las
#       líneas "P" (restos de la plantilla sin sustituir). El ítem 25 lo imprime como MANUAL.
#       make, make test y ./run_all.sh --rapido se ejecutan en una COPIA temporal del repositorio:
#       no tocan los binarios ni las mediciones del equipo.
# Estructuras aceptadas (README.md §3 de la entrega final, columna "Variantes"):
#   - la de proyecto/README.md §4, que implementa plantilla-repo/: v1/ v2/ v3/, bitacora.md,
#     declaración de IA en el README §7 o en declaracion-ia.md, CSV con config v1, v2, v3_kernel,
#     v3_total (resultados/mediciones.csv y resultados/mediciones_v3.csv);
#   - variantes de un repositorio que no parte de la plantilla: versiones bajo src/ (src/v1 src/v2
#     src/v3), bitácora como bitacora-errores.md, CSV escritos por herramientas/medir_proyecto.sh
#     (proyecto/plantillas/run_all.sh: config V1, V2, V3, V3-kernel y columnas extra min_s,max_s;
#     p. ej. resultados/mediciones-colab.csv).
#   En todas se exigen Makefile raíz (all/run/test/clean) y ./run_all.sh --rapido (reproducibilidad.md §2).
# Salida: una línea por comprobación: PASS / FAIL / AVISO / MANUAL, con el número de ítem; resumen.
# Código de salida: 0 si no hay ningún FAIL; 1 si hay al menos uno; 2 si el uso es incorrecto.
# Requisitos: bash, make, gcc, git, awk, python3; opcionales: pdfinfo, file, timeout.
# Ejemplos: bash proyecto/entrega-final/scripts/verificar_entrega.sh ../cp-6bm1-equipo07
#           bash proyecto/entrega-final/scripts/verificar_entrega.sh ../cp-6bm1-equipo07 --sin-ejecutar --sin-red
set -u

# Fecha límite: lunes 7 de diciembre de 2026, 10:30 en la Ciudad de México (UTC-6) = 16:30 UTC.
LIMITE_EPOCH="${LIMITE_EPOCH:-1796661000}"
LIMITE_TEXTO="lunes 7 de diciembre de 2026, 10:30"

ayuda() { sed -n '2,/^set -u$/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; }

REPO=""
EJECUTAR=1
RED=1
for arg in "$@"; do
    case "$arg" in
        --sin-ejecutar) EJECUTAR=0 ;;
        --sin-red) RED=0 ;;
        -h|--help) ayuda; exit 0 ;;
        -*) echo "opción desconocida: $arg (usa --help)" >&2; exit 2 ;;
        *) if [ -z "$REPO" ]; then REPO="$arg"; else echo "sobra el argumento: $arg (usa --help)" >&2; exit 2; fi ;;
    esac
done
if [ -z "$REPO" ] || [ ! -d "$REPO" ]; then
    echo "uso: bash $0 RUTA_AL_REPO [--sin-ejecutar] [--sin-red]   (--help para la ayuda)" >&2
    exit 2
fi
cd "$REPO" || exit 2
REPO="$(pwd -P)"

pass=0; fail=0; aviso=0; manual=0
PASS()   { printf 'PASS   %-3s %s\n' "$1" "$2"; pass=$((pass + 1)); }
FAIL()   { printf 'FAIL   %-3s %s\n' "$1" "$2"; fail=$((fail + 1)); }
AVISO()  { printf 'AVISO  %-3s %s\n' "$1" "$2"; aviso=$((aviso + 1)); }
MANUAL() { printf 'MANUAL %-3s %s\n' "$1" "$2"; manual=$((manual + 1)); }
detalle() { sed 's/^/           /'; }
con_limite() { local s="$1"; shift; if command -v timeout > /dev/null 2>&1; then timeout "$s" "$@"; else "$@"; fi; }
HAY_PY=0; command -v python3 > /dev/null 2>&1 && HAY_PY=1

# Lee líneas "ESTADO<TAB>ÍTEM<TAB>mensaje" del ayudante de Python y las cuenta aquí.
despachar() {
    local st it msg
    while IFS=$'\t' read -r st it msg; do
        case "$st" in
            PASS) PASS "$it" "$msg" ;;
            FAIL) FAIL "$it" "$msg" ;;
            AVISO) AVISO "$it" "$msg" ;;
            MANUAL) MANUAL "$it" "$msg" ;;
            DET) printf '%s\n' "$msg" | detalle ;;
        esac
    done
}

# Ayudante de Python: análisis de CSV, notebook, bitácora, declaración de IA, restos de plantilla y PDF.
read -r -d '' PY_AYUDANTE << 'FIN_PY'
import csv, glob, json, os, re, sys

modo = sys.argv[1]

def emit(st, it, msg):
    print(f"{st}\t{it}\t{msg}")

def leer_texto(ruta):
    with open(ruta, encoding="utf-8", errors="replace") as f:
        return f.read()

def carpetas_version(k):
    return sorted(d for d in glob.glob(f"v{k}*") + glob.glob(f"src/v{k}*") if os.path.isdir(d))

ALIAS = {"v3": "v3_total", "v3-kernel": "v3_kernel", "v3-total": "v3_total"}
def norm(c):
    c = c.strip().lower()
    return ALIAS.get(c, c)

def leer_csv(ruta):
    with open(ruta, newline="", encoding="utf-8-sig") as f:
        return [[c.strip() for c in fila] for fila in csv.reader(f) if fila]

def num(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return None

def analizar_cabecera(cab):
    """(ok, K, indice_mediana). Protocolo: config,hilos,n,rep1..repK,mediana_s,speedup,eficiencia[,min_s,max_s]."""
    if cab[:3] != ["config", "hilos", "n"] or "mediana_s" in cab[:3]:
        return False, 0, None
    k = 0
    while 3 + k < len(cab) and cab[3 + k] == f"rep{k + 1}":
        k += 1
    m = 3 + k
    cola = cab[m:]
    ok = k >= 1 and cola[:3] == ["mediana_s", "speedup", "eficiencia"] and cola[3:] in ([], ["min_s", "max_s"])
    return ok, k, (m if ok else None)

if modo == "csv":
    cpu = "resultados/mediciones.csv"
    if not os.path.isfile(cpu):
        emit("FAIL", "9", "falta resultados/mediciones.csv (lo escribe ./run_all.sh)")
        emit("FAIL", "10", "sin CSV no hay filas v1/v2")
        emit("FAIL", "11", "sin CSV no hay T(1)")
    else:
        filas = leer_csv(cpu)
        cab = filas[0] if filas else []
        ok, k, im = analizar_cabecera(cab)
        if ok and k >= 5:
            emit("PASS", "9", f"mediciones.csv con la cabecera del protocolo ({k} repeticiones)")
        else:
            emit("FAIL", "9", f"mediciones.csv: cabecera distinta del protocolo o < 5 repeticiones: {','.join(cab)}")
        datos = filas[1:]
        v1 = [f for f in datos if f and norm(f[0]) == "v1"]
        hilos_v2 = {f[1] for f in datos if f and norm(f[0]) == "v2" and len(f) > 1}
        if v1 and len(hilos_v2) >= 3:
            emit("PASS", "10", f"mediciones.csv tiene fila v1 y v2 con {len(hilos_v2)} valores de hilos: {' '.join(sorted(hilos_v2, key=lambda h: num(h) or 0))}")
        else:
            emit("FAIL", "10", f"mediciones.csv necesita una fila v1 y v2 con >= 3 valores de hilos (hay {len(v1)} v1 y {len(hilos_v2)} valores de hilos en v2)")
        t1 = num(v1[0][im]) if (v1 and im is not None and len(v1[0]) > im) else None
        rapido = False
        if os.path.isfile("resultados/entorno.txt"):
            rapido = re.search(r"^modo_rapido=1\s*$", leer_texto("resultados/entorno.txt"), re.M) is not None
        if rapido:
            emit("FAIL", "11", "resultados/entorno.txt dice modo_rapido=1: las mediciones entregadas son de --rapido")
        elif t1 is not None and t1 >= 1.0:
            emit("PASS", "11", f"T(1) = {t1:g} s >= 1 s (fila v1, columna mediana_s)")
        else:
            emit("FAIL", "11", f"T(1) = {t1} s: falta o es < 1 s; el CSV es de --rapido o el tamaño es muy chico (protocolo §2)")
        ns = {f[2] for f in datos if len(f) > 2 and norm(f[0]) in ("v1", "v2")}
        if len(ns) > 1:
            emit("AVISO", "11", f"mediciones.csv mezcla tamaños n = {' '.join(sorted(ns))}: cada tabla del reporte declara su n (protocolo §5)")
    encontrado = None
    for ruta in sorted(glob.glob("resultados/*.csv")):
        try:
            filas = leer_csv(ruta)
        except (OSError, UnicodeDecodeError, csv.Error):
            continue
        configs = {norm(f[0]) for f in filas[1:] if f}
        if {"v1", "v3_kernel", "v3_total"} <= configs:
            encontrado = (ruta, filas)
            break
    if encontrado:
        ruta, filas = encontrado
        ok, k, _ = analizar_cabecera(filas[0])
        emit("PASS", "12", f"{ruta} tiene filas v1, v3_kernel (sin transferencias) y v3_total (con transferencias)")
        if not ok or k < 5:
            emit("AVISO", "12", f"{ruta}: cabecera distinta del protocolo o < 5 repeticiones")
    else:
        emit("FAIL", "12", "no hay CSV en resultados/ con filas v1, v3_kernel y v3_total (o V1, V3-kernel y V3) de la misma sesión de GPU")

elif modo == "notebook":
    cands = []
    for d in carpetas_version(3):
        cands += sorted(glob.glob(os.path.join(d, "*.ipynb")))
    if not cands:
        cands = sorted(p for p in glob.glob("**/*.ipynb", recursive=True) if ".ipynb_checkpoints" not in p)
    if not cands:
        emit("FAIL", "16", "no hay notebook .ipynb de la V3 (se busca en v3*/, src/v3*/ y el resto del repositorio)")
        emit("FAIL", "17", "sin notebook no hay verificación de V3 contra V1")
        sys.exit(0)
    cands.sort(key=lambda p: (0 if "colab" in p.lower() else 1, p))
    nb_ruta = cands[0]
    try:
        nb = json.loads(leer_texto(nb_ruta))
    except ValueError as exc:
        emit("FAIL", "16", f"{nb_ruta} no es JSON válido ({exc})")
        emit("FAIL", "17", "notebook ilegible")
        sys.exit(0)
    def unir(x):
        return "".join(x) if isinstance(x, list) else (x or "")
    celdas = [c for c in nb.get("cells", []) if c.get("cell_type") == "code"]
    con_salida = sum(1 for c in celdas if c.get("outputs"))
    fuente = "\n".join(unir(c.get("source")) for c in celdas)
    salidas, errores = [], 0
    for c in celdas:
        for o in c.get("outputs", []):
            if o.get("output_type") == "error":
                errores += 1
                salidas.append("\n".join(o.get("traceback", [])))
            t = o.get("text")
            if t is None:
                t = (o.get("data") or {}).get("text/plain", "")
            salidas.append(unir(t))
    salidas = "\n".join(salidas)
    smi_src = "nvidia-smi" in fuente
    smi_out = "NVIDIA-SMI" in salidas
    if con_salida > 0 and smi_src and smi_out:
        emit("PASS", "16", f"{nb_ruta}: {con_salida} celdas con salida; incluye nvidia-smi y su salida")
    else:
        emit("FAIL", "16", f"{nb_ruta}: celdas con salida={con_salida}, nvidia-smi en el código={smi_src}, salida de nvidia-smi visible={smi_out}: súbelo EJECUTADO")
    if errores:
        emit("AVISO", "16", f"{nb_ruta}: {errores} celda(s) terminaron con error")
    # Las celdas %%writefile deben ser copias exactas del repositorio (reproducibilidad.md §4).
    revisadas, distintas, sin_par = 0, [], []
    for c in celdas:
        src = unir(c.get("source"))
        if not src.startswith("%%writefile"):
            continue
        primera, _, cuerpo = src.partition("\n")
        partes = primera.split()
        if len(partes) < 2:
            continue
        nombre = os.path.basename(partes[-1])
        if nombre == "main_v1.c":
            pares = [os.path.join(d, "main.c") for d in carpetas_version(1)]
        else:
            pares = [p for p in glob.glob(f"**/{nombre}", recursive=True) if not p.startswith(".git/")]
        pares = [p for p in pares if os.path.isfile(p)]
        if not pares:
            sin_par.append(nombre)
            continue
        revisadas += 1
        if not any(leer_texto(p).rstrip("\n") == cuerpo.rstrip("\n") for p in pares):
            distintas.append(f"{nombre} (repositorio: {pares[0]})")
    if distintas:
        emit("FAIL", "16", "el notebook no coincide con el repositorio en: " + "; ".join(distintas) +
             ". Regenera con herramientas/generar_notebook_v3.py y vuelve a ejecutarlo (reproducibilidad.md §4)")
    elif revisadas:
        emit("PASS", "16", f"las {revisadas} celdas %%writefile coinciden con los archivos del repositorio")
    if sin_par:
        emit("AVISO", "16", "celdas %%writefile sin archivo correspondiente en el repositorio: " + ", ".join(sin_par))
    if "PASS v3 == v1" in salidas:
        emit("PASS", "17", "el notebook muestra 'PASS v3 == v1'")
    elif re.search(r"\bPASS\b", salidas) and not re.search(r"\bFAIL\b", salidas):
        emit("AVISO", "17", "el notebook muestra PASS, pero no la línea 'PASS v3 == v1': confirma a mano que es la comparación contra V1")
    else:
        emit("FAIL", "17", "el notebook no muestra la verificación 'PASS v3 == v1' (o muestra FAIL)")

elif modo == "bitacora":
    ruta = next((p for p in ("bitacora.md", "bitacora-errores.md") if os.path.isfile(p)), None)
    if ruta is None:
        emit("FAIL", "19", "falta la bitácora en la raíz (bitacora.md o bitacora-errores.md)")
        sys.exit(0)
    fecha = re.compile(r"^[*`_ ]*(\d{4}-\d{2}-\d{2})")
    cuenta = {"errores": 0, "descartadas": 0, "predicciones": 0, "otras": 0}
    seccion, reconocidas = "otras", False
    for linea in leer_texto(ruta).splitlines():
        if linea.startswith("#"):
            t = linea.lower()
            if "descart" in t:
                seccion = "descartadas"
            elif "predic" in t:
                seccion = "predicciones"
            elif "error" in t or "entrada" in t:
                seccion = "errores"
            else:
                seccion = "otras"
            reconocidas = reconocidas or seccion != "otras"
            continue
        if not linea.lstrip().startswith("|"):
            continue
        celdas = [c.strip() for c in linea.strip().strip("|").split("|")]
        if any(fecha.match(c) for c in celdas[:2]):
            cuenta[seccion] += 1
    errores = cuenta["errores"] if reconocidas else sum(cuenta.values())
    if errores >= 3:
        emit("PASS", "19", f"{ruta}: {errores} entradas de errores fechadas (AAAA-MM-DD)")
        if errores < 5:
            emit("AVISO", "19", "C6 Ejemplar pide >= 5 entradas de errores en la bitácora")
    else:
        emit("FAIL", "19", f"{ruta}: {errores} entradas de errores fechadas (filas de tabla con fecha AAAA-MM-DD); se piden >= 3")
    if reconocidas and cuenta["descartadas"] == 0:
        emit("AVISO", "19", "la bitácora no tiene ninguna medición descartada fechada (C6 Ejemplar pide >= 1)")
    if reconocidas and cuenta["predicciones"] == 0:
        emit("AVISO", "19", "la bitácora no tiene una predicción comparada con el resultado (C6 Ejemplar; protocolo §1.3)")

elif modo == "ia":
    archivos = [p for p in ("README.md", "declaracion-ia.md", "bitacora.md", "bitacora-errores.md") if os.path.isfile(p)]
    llenas, vacias, sin_ia, con_decl = [], [], [], []
    for p in archivos:
        texto = leer_texto(p)
        if p == "declaracion-ia.md":
            m = re.search(r"^#+ .*entrega final.*$", texto, re.I | re.M)
            if m:
                texto = texto[m.end():]
        if re.search(r"uso de ia", texto, re.I):
            con_decl.append(p)
        if re.search(r"^[\s>*`-]*No usamos IA en esta entrega", texto, re.M):
            sin_ia.append(p)
        for linea in texto.splitlines():
            if re.search(r"result[oó] estar mal", linea, re.I):
                valor = linea.split(":", 1)[1] if ":" in linea else ""
                valor = re.sub(r"←.*", "", valor).strip(" `*_-\t")
                if valor and "«" not in valor and valor not in ("…", "..."):
                    llenas.append(p)
                else:
                    vacias.append(p)
    if llenas:
        emit("PASS", "20", f"declaración de IA con la línea 'qué nos dijo la IA que resultó estar mal' llena ({', '.join(sorted(set(llenas)))})")
    elif sin_ia:
        emit("PASS", "20", f"declaración 'No usamos IA' ({', '.join(sin_ia)}); debe estar firmada por todos en el PDF §12")
    elif vacias:
        emit("FAIL", "20", f"la línea 'qué nos dijo la IA que resultó estar mal' sigue vacía o con «…» en {', '.join(sorted(set(vacias)))}")
    elif con_decl:
        emit("FAIL", "20", f"hay 'Uso de IA' en {', '.join(con_decl)} pero falta la línea 'qué nos dijo la IA que resultó estar mal'")
    else:
        emit("FAIL", "20", "no encuentro la declaración de uso de IA en README.md ni en declaracion-ia.md")

elif modo == "plantilla":
    fuentes = []
    for k in (1, 2, 3):
        for d in carpetas_version(k):
            fuentes += glob.glob(os.path.join(d, "**", "*.*"), recursive=True)
    fuentes += glob.glob("comun/**/*.*", recursive=True)
    marcador = "sin(y) + cos(0.5 * y) * 0.25"
    con_marcador = sorted({p for p in fuentes if p.endswith((".c", ".h", ".cu", ".py")) and marcador in leer_texto(p)})
    if con_marcador:
        emit("FAIL", "P", "el cómputo de la plantilla (elemento(): " + marcador + ") sigue en " + ", ".join(con_marcador) +
             ": entregarlo tal cual vale 0 en C1")
    else:
        emit("PASS", "P", "no queda el cómputo de marcador de posición de la plantilla")
    for p in ("README.md", "bitacora.md", "bitacora-errores.md"):
        if os.path.isfile(p):
            n = leer_texto(p).count("«")
            if n:
                emit("AVISO", "P", f"{p} conserva {n} marcador(es) «…» de la plantilla sin llenar")

elif modo == "paginas":
    ruta = sys.argv[2]
    try:
        import pypdf
        print(len(pypdf.PdfReader(ruta).pages))
    except Exception:
        with open(ruta, "rb") as f:
            n = len(re.findall(rb"/Type\s*/Page(?![a-zA-Z])", f.read()))
        print(n if n > 0 else "")
FIN_PY

py() { python3 -c "$PY_AYUDANTE" "$@"; }
# correr_py ÍTEM MODO: corre un modo del ayudante; si Python falla, lo dice como FAIL (no se pierde en silencio).
correr_py() {
    local item="$1" out codigo
    shift
    out="$(py "$@")"; codigo=$?
    [ -n "$out" ] && despachar <<< "$out"
    [ "$codigo" -eq 0 ] || FAIL "$item" "error interno del verificador (modo '$1'); la traza está arriba"
}

echo "== Verificación de la entrega final · $REPO =="
echo "== $(date -u +%Y-%m-%dT%H:%M:%SZ) · ejecutar=$EJECUTAR · red=$RED =="

# ---------- A. Estructura ----------
if [ -f README.md ]; then
    PASS 1 "README.md existe"
    for sec in "compil" "run_all" "semilla" "hardware|entorno" "integrante|reparto" "uso de ia"; do
        etiqueta=${sec//|/ ni }
        grep -qiE -- "$sec" README.md || AVISO 1 "README.md no menciona '$etiqueta'"
    done
else
    FAIL 1 "falta README.md en la raíz"
fi

if [ -f Makefile ]; then
    faltan=""
    for t in all run test clean; do
        grep -qE "^([A-Za-z0-9_.-]+[[:space:]]+)*${t}([[:space:]]+[A-Za-z0-9_.-]+)*[[:space:]]*:([^=]|$)" Makefile || faltan="$faltan $t"
    done
    if [ -z "$faltan" ]; then PASS 2 "Makefile en la raíz con all, run, test y clean"; else FAIL 2 "Makefile sin objetivo(s):$faltan"; fi
else
    FAIL 2 "falta Makefile en la raíz (all/run/test/clean; reproducibilidad.md §2.1)"
fi

if [ -f run_all.sh ]; then
    if [ -x run_all.sh ]; then PASS 3 "run_all.sh existe y es ejecutable"; else FAIL 3 "run_all.sh no es ejecutable (chmod +x run_all.sh y commit)"; fi
    grep -q -- "--rapido" run_all.sh || AVISO 3 "run_all.sh no menciona --rapido (reproducibilidad.md §2.2)"
else
    FAIL 3 "falta run_all.sh en la raíz"
fi

dir_version() {
    local d
    for d in v"$1"* src/v"$1"*; do
        if [ -d "$d" ]; then printf '%s\n' "$d"; return 0; fi
    done
    return 1
}
d1="$(dir_version 1)"; d2="$(dir_version 2)"; d3="$(dir_version 3)"
if [ -n "$d1" ] && [ -n "$d2" ] && [ -n "$d3" ]; then
    PASS 4 "carpetas de las tres versiones: $d1 $d2 $d3"
    [ -f "$d1/Makefile" ] || FAIL 4 "$d1 no tiene Makefile"
    [ -f "$d2/Makefile" ] || FAIL 4 "$d2 no tiene Makefile"
    if [ ! -f "$d3/Makefile" ] && [ ! -f "$d3/run_colab.sh" ]; then
        AVISO 4 "$d3 no tiene Makefile ni run_colab.sh: el README debe decir cómo compilar y correr la V3"
    fi
else
    FAIL 4 "faltan carpetas de versión (se buscan v1*/ v2*/ v3*/ en la raíz o en src/; hay: '$d1' '$d2' '$d3')"
fi

pruebas=""
for p in tests/run_tests.sh "$d1/tests/run_tests.sh" "$d2/tests/run_tests.sh"; do
    if [ -f "$p" ]; then pruebas="$p"; break; fi
done
if [ -n "$pruebas" ]; then
    PASS 5 "pruebas automáticas: $pruebas"
    if grep -qE '^[[:space:]]*#[ -]*Casos del equipo' "$pruebas"; then
        # Líneas de código (no comentarios ni vacías) entre el marcador y el siguiente "fi" o "# N." de columna 0.
        casos="$(awk '/^[ \t]*#[ -]*Casos del equipo/ {dentro = 1; c = 0; next}
                      dentro && ($0 ~ /^fi/ || $0 ~ /^# *[0-9]+[.] /) {exit}
                      dentro && $0 !~ /^[ \t]*#/ && $0 !~ /^[ \t]*$/ {c++}
                      END {print c + 0}' "$pruebas")"
        if [ "$casos" -ge 2 ]; then
            PASS 5 "la sección 'Casos del equipo' tiene $casos líneas de prueba (revisa que cada una diga por qué importa)"
        else
            AVISO 5 "la sección 'Casos del equipo' de $pruebas tiene $casos caso(s); C1 Ejemplar pide >= 2 comentados"
        fi
    else
        AVISO 5 "no encuentro la sección 'Casos del equipo' en $pruebas: revisa a mano que haya >= 2 casos propios comentados"
    fi
else
    FAIL 5 "falta tests/run_tests.sh (o src/v*/tests/run_tests.sh)"
fi

# ---------- B. Compila, prueba y corre (en una copia temporal) ----------
if [ "$EJECUTAR" -eq 1 ] && [ -f Makefile ]; then
    TMP="$(mktemp -d "${TMPDIR:-/tmp}/verificar_entrega.XXXXXX")"
    trap 'rm -rf "$TMP"' EXIT
    T="$TMP/repo"; LOG="$TMP/log"
    mkdir -p "$T" && cp -a "$REPO/." "$T/"
    salida="$(make -C "$T" clean > /dev/null 2>&1; make -C "$T" all 2>&1)"; codigo=$?
    if [ "$codigo" -ne 0 ]; then
        FAIL 6 "make all falla (código $codigo):"; printf '%s\n' "$salida" | tail -5 | detalle
    elif printf '%s\n' "$salida" | grep -qi "warning"; then
        FAIL 6 "make all compila pero con warnings:"; printf '%s\n' "$salida" | grep -i warning | head -5 | detalle
    else
        PASS 6 "make all compila sin warnings"
    fi
    if make -C "$T" test > "$LOG" 2>&1; then
        PASS 7 "make test termina con código 0 ($(grep -c '^PASS' "$LOG") líneas PASS)"
    else
        FAIL 7 "make test falla:"; { grep -E '^FAIL|rror' "$LOG" || tail -5 "$LOG"; } | head -5 | detalle
    fi
    if [ -x "$T/run_all.sh" ]; then
        huella() { if [ -f "$1" ]; then cksum < "$1"; else echo ninguno; fi; }
        antes="$(huella "$T/resultados/mediciones.csv")"
        inicio=$(date +%s)
        if (cd "$T" && con_limite 600 ./run_all.sh --rapido > "$LOG" 2>&1); then
            dur=$(( $(date +%s) - inicio ))
            if [ "$dur" -le 180 ]; then
                PASS 8 "./run_all.sh --rapido termina bien en $dur s (en una copia temporal)"
            else
                AVISO 8 "./run_all.sh --rapido terminó, pero tardó $dur s; en la revisión tiene 3 min (reproducibilidad.md §1)"
            fi
        else
            FAIL 8 "./run_all.sh --rapido falla o excede 10 min:"; tail -5 "$LOG" | detalle
        fi
        despues="$(huella "$T/resultados/mediciones.csv")"
        if [ "$antes" != "$despues" ]; then
            AVISO 8 "--rapido sobrescribió resultados/mediciones.csv: si haces commit después, entregas mediciones de --rapido (ítem 11). Escribe en resultados/rapido/"
        fi
    else
        FAIL 8 "no hay ./run_all.sh ejecutable que correr"
    fi
else
    MANUAL 6 "compilación sin warnings (make all): no se ejecutó"
    MANUAL 7 "make test con código 0: no se ejecutó"
    MANUAL 8 "./run_all.sh --rapido: no se ejecutó"
fi

# ---------- C. Mediciones ----------
if [ "$HAY_PY" -eq 1 ]; then
    correr_py 9 csv
else
    FAIL 9 "falta python3 para revisar los CSV"; FAIL 10 "falta python3"; FAIL 11 "falta python3"; FAIL 12 "falta python3"
fi

if [ -s resultados/entorno.txt ]; then
    if grep -qiE 'cpu|model name' resultados/entorno.txt && grep -qiE 'gcc|clang|compilador' resultados/entorno.txt; then
        PASS 13 "resultados/entorno.txt describe CPU y compilador"
        grep -qiE 'nucleos|n[uú]cleos|core\(s\)|cpu\(s\)' resultados/entorno.txt || AVISO 13 "entorno.txt no dice cuántos núcleos físicos y lógicos hay"
        grep -qiE 'ram|memtotal' resultados/entorno.txt || AVISO 13 "entorno.txt no dice la RAM"
        grep -qiE 'bandera|flags|-O2' resultados/entorno.txt || AVISO 13 "entorno.txt no dice las banderas de compilación"
    else
        FAIL 13 "resultados/entorno.txt no describe la CPU o el compilador"
    fi
else
    FAIL 13 "falta resultados/entorno.txt (lo escribe ./run_all.sh)"
fi

gpu_txt=""
for f in resultados/entorno_gpu.txt resultados/*gpu*.txt resultados/*colab*.txt resultados/*kaggle*.txt resultados/entorno*.txt; do
    [ -s "$f" ] || continue
    if grep -qiwE 'tesla|nvidia|t4|p100|l4|a100|v100|h100|rtx|quadro' "$f" && grep -qiE 'fecha|20[0-9]{2}-[0-9]{2}-[0-9]{2}' "$f"; then
        gpu_txt="$f"; break
    fi
done
if [ -n "$gpu_txt" ]; then
    PASS 14 "$gpu_txt tiene modelo de GPU y fecha"
    grep -qiE 'driver|[0-9]{3}\.[0-9]+' "$gpu_txt" || AVISO 14 "$gpu_txt no tiene la versión del driver"
    grep -qiE 'MiB|memory|memoria' "$gpu_txt" || AVISO 14 "$gpu_txt no tiene la memoria de la GPU"
else
    FAIL 14 "no encuentro en resultados/ un archivo de entorno con el modelo de GPU y la fecha (entorno_gpu.txt, celda 1 del notebook)"
fi

if ls resultados/*.png > /dev/null 2>&1; then
    PASS 15 "hay gráficas PNG en resultados/ ($(ls resultados/*.png | wc -l)); revisa que la de speedup tenga la línea ideal S = p"
else
    FAIL 15 "no hay ninguna gráfica .png en resultados/"
fi

# ---------- D. Notebook de la V3 ----------
if [ "$HAY_PY" -eq 1 ]; then
    correr_py 16 notebook
else
    FAIL 16 "falta python3 para leer el notebook"; FAIL 17 "falta python3"
fi

# ---------- E. Reporte, bitácora y proceso ----------
PDF=""
for c in reporte/reporte.pdf reporte/*.pdf reporte*.pdf; do
    if [ -f "$c" ]; then PDF="$c"; break; fi
done
if [ -n "$PDF" ] && [ -s "$PDF" ]; then
    paginas=""
    if command -v pdfinfo > /dev/null 2>&1; then
        paginas="$(pdfinfo "$PDF" 2>/dev/null | awk '/^Pages:/ {print $2}')"
    fi
    if [ -z "$paginas" ] && [ "$HAY_PY" -eq 1 ]; then paginas="$(py paginas "$PDF")"; fi
    if [ -z "$paginas" ]; then
        AVISO 18 "$PDF existe, pero no pude contar sus páginas (instala pdfinfo o pypdf); deben ser 8–12"
    elif [ "$paginas" -ge 8 ] && [ "$paginas" -le 12 ]; then
        PASS 18 "$PDF tiene $paginas páginas (8–12)"
    else
        FAIL 18 "$PDF tiene $paginas páginas; la extensión obligatoria es 8–12 (plantilla-reporte.md §1)"
    fi
else
    FAIL 18 "falta el reporte PDF (reporte/reporte.pdf)"
fi

if [ "$HAY_PY" -eq 1 ]; then
    correr_py 19 bitacora
    correr_py 20 ia
else
    FAIL 19 "falta python3 para leer la bitácora"; FAIL 20 "falta python3 para leer la declaración de IA"
fi

top="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -n "$top" ] && [ "$(cd "$top" && pwd -P)" = "$REPO" ] && git rev-parse -q --verify HEAD > /dev/null; then
    autores="$(git shortlog -sne HEAD 2>/dev/null)"
    nautores="$(printf '%s\n' "$autores" | grep -c .)"
    if [ "$nautores" -ge 2 ]; then
        PASS 21 "historial de HEAD con $nautores autores (commits, nombre <correo>):"
    else
        FAIL 21 "solo $nautores autor(es) en el historial; se exigen commits de todos los integrantes:"
    fi
    printf '%s\n' "$autores" | detalle
    # Por autor: commits y semanas ISO distintas con commits (C6 se asigna por integrante). Cuenta
    # todos los commits; si son "con cambios de código" lo decide quien califica (git log --stat).
    echo "           por correo de autor (commits · semanas ISO distintas):"
    while read -r correo commits semanas; do
        printf '%s: %s commit(s) en %s semana(s)\n' "$correo" "$commits" "$semanas" | detalle
        if [ "$commits" -lt 3 ] || [ "$semanas" -lt 3 ]; then
            AVISO 21 "$correo: $commits commit(s) en $semanas semana(s); C6 Ejemplar pide >= 3 commits con código en >= 3 semanas"
        fi
    done < <(git log --format='%ae %ad' --date=format:%G-%V HEAD | awk '{c[$1]++; if (!v[$1 " " $2]++) s[$1]++} END {for (a in c) print a, c[a], s[a]}' | sort)

    if command -v file > /dev/null 2>&1; then
        bins="$(git ls-files -z | xargs -0 -r file -N 2>/dev/null | grep -E ':.*(ELF|Mach-O|PE32)' | cut -d: -f1)"
    else
        bins="$(git ls-files | grep -E '(\.o|\.out|\.exe|\.so|/v[123])$')"
    fi
    grandes="$(git ls-files -z | xargs -0 -r ls -ln 2>/dev/null | awk '$5 > 10485760 {print $NF}')"
    if [ -z "$bins" ] && [ -z "$grandes" ]; then
        PASS 22 "no hay binarios ni archivos > 10 MB versionados"
    else
        [ -z "$bins" ] || FAIL 22 "binarios en git (agrégalos a .gitignore y git rm --cached): $(printf '%s' "$bins" | tr '\n' ' ')"
        [ -z "$grandes" ] || FAIL 22 "archivos > 10 MB en git (usa un script de descarga con SHA-256): $(printf '%s' "$grandes" | tr '\n' ' ')"
    fi
    [ -z "$(git ls-files resultados/rapido)" ] || AVISO 22 "resultados/rapido/ está versionada: son corridas de comprobación, no mediciones (agrégala a .gitignore)"

    if [ -z "$(git status --porcelain)" ]; then
        PASS 23 "árbol de trabajo limpio (todo está en commits)"
    else
        AVISO 23 "hay cambios sin commit; el profesor revisa GitHub, no tu disco:"; git status --porcelain | head -5 | detalle
    fi
    if arriba="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)"; then
        sin_subir="$(git rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)"
        [ "$sin_subir" -eq 0 ] || AVISO 23 "hay $sin_subir commit(s) sin subir a $arriba (git push)"
    fi

    if git rev-parse -q --verify refs/tags/entrega-final > /dev/null; then
        c_tag="$(git rev-list -n 1 entrega-final)"; c_head="$(git rev-parse HEAD)"
        fecha_tag="$(git log -1 --format=%cd --date=iso entrega-final)"
        if [ "$c_tag" = "$c_head" ]; then
            PASS 24 "etiqueta entrega-final en HEAD (${c_tag:0:7}, commit del $fecha_tag)"
        else
            AVISO 24 "la etiqueta entrega-final apunta a ${c_tag:0:7} y HEAD es ${c_head:0:7}: el profesor califica la etiqueta"
        fi
        if [ "$(git log -1 --format=%ct entrega-final)" -gt "$LIMITE_EPOCH" ]; then
            AVISO 24 "el commit etiquetado es posterior al $LIMITE_TEXTO (hora del commit; el profesor usa la de GitHub): entrega tardía, máximo 80 %"
        fi
        if [ "$RED" -eq 1 ] && git remote get-url origin > /dev/null 2>&1; then
            if remoto="$(con_limite 20 git ls-remote --tags origin refs/tags/entrega-final 2>/dev/null)"; then
                if [ -n "$remoto" ]; then PASS 24 "la etiqueta está en origin"; else AVISO 24 "la etiqueta no está en origin: git push origin entrega-final"; fi
            else
                AVISO 24 "no pude consultar origin (sin red o sin permisos); --sin-red omite esta consulta"
            fi
        fi
    else
        AVISO 24 "falta la etiqueta: git tag entrega-final && git push origin entrega-final"
    fi
else
    if [ -n "$top" ]; then
        FAIL 21 "$REPO no es la raíz de un repositorio git (la raíz es $top): verifica un clon de tu repositorio"
    else
        FAIL 21 "no es un repositorio git (o no tiene commits)"
    fi
    MANUAL 22 "binarios y archivos grandes: no se pudo revisar"
    MANUAL 23 "árbol limpio: no se pudo revisar"
    MANUAL 24 "etiqueta entrega-final: no se pudo revisar"
fi

# ---------- Restos de la plantilla ----------
if [ "$HAY_PY" -eq 1 ]; then correr_py P plantilla; fi

# ---------- Lo que una máquina no puede revisar ----------
MANUAL 25 "las tablas y gráficas del PDF coinciden número a número con resultados/*.csv (misma n, misma semilla, misma fecha de GPU)"
echo "Recordatorios (lista-cotejo-entrega.md):"
echo "  - cada caso de 'Casos del equipo' dice por qué importa (ítem 5); make test cubre 1, 2, 4 y 8 hilos con >= 3 corridas"
echo "    y los tres tipos de caso de V1 (ítem 7); la gráfica de speedup tiene la línea ideal (ítem 15);"
echo "  - la declaración de IA también está en el PDF §12 (ítem 20); cualquier integrante explica cualquier línea (defensa)."

echo "----"
echo "Resumen: $pass PASS, $fail FAIL, $aviso AVISO, $manual MANUAL. Código de salida 0 solo si no hay FAIL."
[ "$fail" -eq 0 ]
