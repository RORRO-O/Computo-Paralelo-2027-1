#!/usr/bin/env bash
# scripts/verificar_entrega.sh · Verificación automática de la entrega final del proyecto
#
# Uso:  bash proyecto/entrega-final/scripts/verificar_entrega.sh /ruta/al/repo/del/equipo [--sin-ejecutar]
#       --sin-ejecutar   solo revisa archivos y git; no corre make, make test ni run_all.sh
# Quién lo usa: el equipo, antes de entregar (lista-cotejo-entrega.md, columna "auto"), y el
#       profesor, en los primeros minutos de la revisión (reproducibilidad.md).
# Qué revisa: los ítems de la lista de cotejo que una máquina puede comprobar (estructura del
#       repositorio, compilación sin warnings, pruebas, run_all.sh, CSV con el formato del
#       protocolo, evidencia de la GPU, notebook ejecutado, PDF, historial de git, binarios no
#       versionados). Los demás ítems los imprime como "MANUAL" al final.
# Salida: una línea por ítem: PASS / FAIL / AVISO / MANUAL; resumen; código 0 solo si no hay FAIL.
# Requisitos: bash, make, gcc, git; python3 (para leer el notebook); opcional: pdfinfo, file.
# Ejemplo:  bash proyecto/entrega-final/scripts/verificar_entrega.sh ../cp-6bm1-equipo07
#           bash proyecto/entrega-final/scripts/verificar_entrega.sh . --sin-ejecutar
set -u

REPO="${1:-}"
EJECUTAR=1
[ "${2:-}" = "--sin-ejecutar" ] && EJECUTAR=0
if [ -z "$REPO" ] || [ ! -d "$REPO" ]; then
    echo "uso: $0 /ruta/al/repo [--sin-ejecutar]" >&2
    exit 2
fi
cd "$REPO" || exit 2
REPO="$(pwd)"

pass=0; fail=0; aviso=0
PASS()  { printf 'PASS   %-4s %s\n' "$1" "$2"; pass=$((pass + 1)); }
FAIL()  { printf 'FAIL   %-4s %s\n' "$1" "$2"; fail=$((fail + 1)); }
AVISO() { printf 'AVISO  %-4s %s\n' "$1" "$2"; aviso=$((aviso + 1)); }
MANUAL(){ printf 'MANUAL %-4s %s\n' "$1" "$2"; }

echo "== Verificación de entrega final · $REPO =="
echo "== $(date -u +%Y-%m-%dT%H:%M:%SZ) =="

# ---------- Estructura ----------
[ -f README.md ] && PASS 1 "README.md existe" || FAIL 1 "falta README.md en la raíz"
if [ -f README.md ]; then
    for sec in "compil" "run_all" "semilla" "hardware\|entorno" "integrante\|reparto" "Uso de IA"; do
        if grep -qi "$sec" README.md; then :; else AVISO 1 "README.md no menciona '$sec'"; fi
    done
fi
[ -f Makefile ] && PASS 2 "Makefile en la raíz" || FAIL 2 "falta Makefile en la raíz"
if [ -f Makefile ]; then
    for t in all run test clean; do
        grep -qE "^$t[[:space:]]*:" Makefile && : || FAIL 2 "Makefile sin objetivo '$t:'"
    done
fi
if [ -f run_all.sh ]; then
    [ -x run_all.sh ] && PASS 3 "run_all.sh existe y es ejecutable" || FAIL 3 "run_all.sh no es ejecutable (chmod +x run_all.sh)"
else
    FAIL 3 "falta run_all.sh"
fi
d1="$(ls -d v1* 2>/dev/null | head -1)"; d2="$(ls -d v2* 2>/dev/null | head -1)"; d3="$(ls -d v3* 2>/dev/null | head -1)"
[ -n "$d1" ] && [ -n "$d2" ] && [ -n "$d3" ] && PASS 4 "carpetas de las tres versiones: $d1 $d2 $d3" || FAIL 4 "faltan carpetas v1*/v2*/v3* (hay: '$d1' '$d2' '$d3')"
[ -f tests/run_tests.sh ] && PASS 5 "tests/run_tests.sh existe" || FAIL 5 "falta tests/run_tests.sh"

# ---------- Compilación, pruebas, run_all ----------
if [ "$EJECUTAR" -eq 1 ] && [ -f Makefile ]; then
    make clean > /dev/null 2>&1
    salida="$(make all 2>&1)"; codigo=$?
    if [ $codigo -ne 0 ]; then
        FAIL 6 "make all falla (código $codigo)"; printf '%s\n' "$salida" | tail -5 | sed 's/^/       /'
    elif printf '%s\n' "$salida" | grep -qi "warning"; then
        FAIL 6 "make all compila pero con warnings:"; printf '%s\n' "$salida" | grep -i warning | head -5 | sed 's/^/       /'
    else
        PASS 6 "make all compila sin warnings"
    fi
    if make test > /tmp/verificar_test.$$ 2>&1; then
        PASS 7 "make test termina con código 0 ($(grep -c '^PASS' /tmp/verificar_test.$$) casos PASS)"
    else
        FAIL 7 "make test falla:"; grep -E '^FAIL|error' /tmp/verificar_test.$$ | head -5 | sed 's/^/       /'
    fi
    rm -f /tmp/verificar_test.$$
    if [ -x run_all.sh ]; then
        inicio=$(date +%s)
        if timeout 900 ./run_all.sh --rapido > /tmp/verificar_run.$$ 2>&1; then
            PASS 8 "run_all.sh --rapido termina bien en $(( $(date +%s) - inicio )) s"
        else
            FAIL 8 "run_all.sh --rapido falla o excede 15 min:"; tail -5 /tmp/verificar_run.$$ | sed 's/^/       /'
        fi
        rm -f /tmp/verificar_run.$$
    fi
else
    MANUAL 6 "compilación sin warnings (make all) — no ejecutado"
    MANUAL 7 "make test con código 0 — no ejecutado"
    MANUAL 8 "run_all.sh --rapido — no ejecutado"
fi

# ---------- Resultados ----------
CSV=resultados/mediciones.csv
if [ -f "$CSV" ]; then
    cab="$(head -1 "$CSV")"
    nreps="$(printf '%s' "$cab" | tr ',' '\n' | grep -c '^rep[0-9]*$')"
    if printf '%s' "$cab" | grep -q '^config,hilos,n,rep1' && printf '%s' "$cab" | grep -q 'mediana_s,speedup,eficiencia$' && [ "$nreps" -ge 5 ]; then
        PASS 9 "mediciones.csv con la cabecera del protocolo ($nreps repeticiones)"
    else
        FAIL 9 "mediciones.csv: cabecera distinta del protocolo o < 5 repeticiones: $cab"
    fi
    nv1="$(grep -c '^v1,' "$CSV")"; nv2="$(grep -c '^v2,' "$CSV")"
    [ "$nv1" -ge 1 ] && [ "$nv2" -ge 3 ] && PASS 10 "mediciones.csv tiene fila v1 y $nv2 filas v2" || FAIL 10 "mediciones.csv necesita 1 fila v1 y >= 3 filas v2 (hay $nv1 y $nv2)"
    t1="$(awk -F, 'NR>1 && $1=="v1" {print $(NF-2); exit}' "$CSV")"
    if [ -n "$t1" ] && awk -v t="$t1" 'BEGIN { exit !(t >= 1.0) }'; then
        PASS 11 "T(1) = ${t1} s >= 1 s (medición válida)"
    else
        FAIL 11 "T(1) = '${t1}' s < 1 s: el CSV entregado es de --rapido o el tamaño es muy chico (protocolo §2)"
    fi
else
    FAIL 9 "falta resultados/mediciones.csv"; FAIL 10 "sin CSV no hay filas"; FAIL 11 "sin CSV no hay T(1)"
fi
CSV3=resultados/mediciones_v3.csv
if [ -f "$CSV3" ]; then
    grep -q '^v3_kernel,' "$CSV3" && grep -q '^v3_total,' "$CSV3" && grep -q '^v1,' "$CSV3" \
        && PASS 12 "mediciones_v3.csv con filas v1, v3_kernel y v3_total" \
        || FAIL 12 "mediciones_v3.csv debe tener filas v1, v3_kernel (sin copias) y v3_total (con copias)"
else
    FAIL 12 "falta resultados/mediciones_v3.csv (lo produce la celda 5 del notebook)"
fi
[ -s resultados/entorno.txt ] && grep -qi 'cpu' resultados/entorno.txt && PASS 13 "entorno.txt con CPU/compilador" || FAIL 13 "falta resultados/entorno.txt o no describe la CPU"
if [ -s resultados/entorno_gpu.txt ]; then
    grep -qiE 'tesla|nvidia|t4|p100|l4|a100|v100|name' resultados/entorno_gpu.txt && grep -qiE 'fecha|20[0-9][0-9]-' resultados/entorno_gpu.txt \
        && PASS 14 "entorno_gpu.txt con modelo de GPU y fecha" || FAIL 14 "entorno_gpu.txt sin modelo de GPU o sin fecha"
else
    FAIL 14 "falta resultados/entorno_gpu.txt (celda 1 del notebook)"
fi
ls resultados/*.png > /dev/null 2>&1 && PASS 15 "hay gráficas PNG en resultados/ ($(ls resultados/*.png | wc -l))" || FAIL 15 "no hay ninguna gráfica .png en resultados/"

# ---------- Notebook ----------
NB="$(ls v3*/*.ipynb 2>/dev/null | head -1)"
if [ -n "$NB" ] && command -v python3 > /dev/null 2>&1; then
    res="$(python3 - "$NB" <<'EOF'
import json, sys
nb = json.load(open(sys.argv[1], encoding="utf-8"))
celdas = nb.get("cells", [])
con_salida = sum(1 for c in celdas if c.get("cell_type") == "code" and c.get("outputs"))
texto = "\n".join("".join(c.get("source", [])) for c in celdas)
salidas = "\n".join(
    "".join(o.get("text", []) if isinstance(o.get("text", []), list) else [o.get("text", "")])
    for c in celdas if c.get("cell_type") == "code" for o in c.get("outputs", []))
print(con_salida, "nvidia-smi" in texto, ("NVIDIA-SMI" in salidas or "Tesla" in salidas or "GPU" in salidas), "PASS" in salidas)
EOF
)"
    set -- $res
    if [ "${1:-0}" -gt 0 ] && [ "${2:-False}" = "True" ] && [ "${3:-False}" = "True" ]; then
        PASS 16 "$NB tiene $1 celdas con salida, incluye nvidia-smi y su salida"
    else
        FAIL 16 "$NB: celdas con salida=$1, nvidia-smi en código=$2, salida de GPU visible=$3 (debe subirse EJECUTADO)"
    fi
    [ "${4:-False}" = "True" ] && PASS 17 "el notebook muestra PASS en la verificación v3 == v1" || FAIL 17 "el notebook no muestra 'PASS' en la celda de verificación contra V1"
else
    FAIL 16 "no hay notebook .ipynb en v3*/ (o falta python3 para leerlo)"; FAIL 17 "sin notebook no hay verificación de V3"
fi

# ---------- Reporte y bitácora ----------
PDF="$(ls reporte/*.pdf reporte*.pdf 2>/dev/null | head -1)"
if [ -n "$PDF" ] && [ -s "$PDF" ]; then
    paginas=""
    if command -v pdfinfo > /dev/null 2>&1; then
        paginas="$(pdfinfo "$PDF" 2>/dev/null | awk '/^Pages:/ {print $2}')"
    elif python3 -c "import pypdf" 2>/dev/null; then
        paginas="$(python3 -c "import pypdf,sys; print(len(pypdf.PdfReader(sys.argv[1]).pages))" "$PDF")"
    else
        paginas="$(grep -ac '/Type[[:space:]]*/Page[^s]' "$PDF")"
        [ "$paginas" -eq 0 ] && paginas=""
    fi
    if [ -z "$paginas" ]; then
        AVISO 18 "$PDF existe; no pude contar páginas (instala pdfinfo o pypdf); deben ser 8–12"
    elif [ "$paginas" -ge 8 ] && [ "$paginas" -le 12 ]; then
        PASS 18 "$PDF tiene $paginas páginas (8–12)"
    else
        FAIL 18 "$PDF tiene $paginas páginas; la extensión obligatoria es 8–12"
    fi
else
    FAIL 18 "falta el reporte PDF (reporte/*.pdf o reporte*.pdf en la raíz)"
fi
if [ -f bitacora.md ]; then
    entradas="$(grep -cE '^\| *[0-9]{4}-[0-9]{2}-[0-9]{2}' bitacora.md)"
    [ "$entradas" -ge 3 ] && PASS 19 "bitacora.md con $entradas entradas fechadas" || FAIL 19 "bitacora.md tiene $entradas entradas fechadas (formato | AAAA-MM-DD | ...); se piden >= 3"
else
    FAIL 19 "falta bitacora.md en la raíz"
fi
grep -rqi "Uso de IA" README.md bitacora.md 2>/dev/null && PASS 20 "declaración de uso de IA presente (README o bitácora)" || AVISO 20 "no encuentro 'Uso de IA' en README.md/bitacora.md; debe estar al menos en el PDF"

# ---------- Git ----------
if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    autores="$(git shortlog -sne --all 2>/dev/null)"
    nautores="$(printf '%s\n' "$autores" | grep -c .)"
    if [ "$nautores" -ge 2 ]; then
        PASS 21 "historial con $nautores autores distintos:"; printf '%s\n' "$autores" | sed 's/^/       /'
        minimo="$(printf '%s\n' "$autores" | awk '{print $1}' | sort -n | head -1)"
        [ "$minimo" -ge 5 ] || AVISO 21 "hay un integrante con solo $minimo commits; el reparto se revisa en la defensa"
    else
        FAIL 21 "solo $nautores autor(es) en el historial; se exige commits de todos los integrantes"
    fi
    if command -v file > /dev/null 2>&1; then
        bins="$(git ls-files -z | xargs -0 file 2>/dev/null | grep -E 'ELF|Mach-O|PE32' | cut -d: -f1)"
    else
        bins="$(git ls-files | grep -E '(\.o|\.out|\.exe|/v1|/v2|/v3)$')"
    fi
    [ -z "$bins" ] && PASS 22 "no hay binarios versionados" || FAIL 22 "binarios en git (agrégalos a .gitignore y git rm --cached): $(printf '%s' "$bins" | tr '\n' ' ')"
    [ -z "$(git status --porcelain)" ] && PASS 23 "árbol de trabajo limpio (todo está en commits)" || AVISO 23 "hay cambios sin commit; el profesor revisa el commit en GitHub, no tu disco"
    git tag | grep -qx 'entrega-final' && PASS 24 "etiqueta entrega-final presente" || AVISO 24 "falta la etiqueta: git tag entrega-final && git push --tags"
else
    FAIL 21 "no es un repositorio git"; MANUAL 22 "binarios"; MANUAL 23 "árbol limpio"; MANUAL 24 "etiqueta"
fi

# ---------- Lo que una máquina no puede revisar ----------
MANUAL 25 "las tablas y gráficas del PDF coinciden número a número con resultados/*.csv (misma n, misma semilla, misma fecha de GPU)"
echo "Recordatorios sin número (lista-cotejo-entrega.md, columna 'cómo se verifica'):"
echo "  - tests/run_tests.sh tiene >= 2 casos propios del equipo, con comentario de por qué importan (ítem 5)."
echo "  - la gráfica de speedup tiene la línea ideal S = p (ítem 15)."
echo "  - la declaración de IA incluye la línea 'qué nos dijo la IA que resultó estar mal' (ítem 20)."
echo "  - cualquier integrante puede explicar cualquier línea del repositorio (defensa, jueves 10 de diciembre)."

echo "----"
echo "Resumen: $pass PASS, $fail FAIL, $aviso AVISO. Ítems 1–24 automáticos; el 25 se revisa a mano."
[ "$fail" -eq 0 ]
