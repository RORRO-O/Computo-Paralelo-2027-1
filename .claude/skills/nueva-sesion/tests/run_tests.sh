#!/usr/bin/env bash
# tests/run_tests.sh — Pruebas de la skill /nueva-sesion. Código 0 solo si todo pasa.
# Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · .claude/skills/nueva-sesion/
#
# Genera en una carpeta temporal (fuera del repositorio) una sesión por tecnología y verifica:
#   1. los 8 elementos de docs/CONVENCIONES.md §1, ni más ni menos, y el encabezado de §2 en cada .md
#   2. la práctica guiada compila sin warnings y `make test` pasa (MPI se omite si no hay mpicc)
#   3. fecha, día de la semana y vencimiento de la tarea salen del calendario
#   4. los códigos de error: sesión existente (3), fecha que contradice el calendario (2), tema no válido (2)
set -uo pipefail
export LC_ALL=C.UTF-8
cd "$(dirname "$0")/.." || exit 1
PY=${PY:-python3}
GEN="$PY scripts/nueva_sesion.py"
RAIZ=$(cd ../../.. && pwd)
if [[ $(id -u) == 0 ]]; then export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1; fi
export MPIRUN_FLAGS="${MPIRUN_FLAGS:---oversubscribe}"

PASS=0
FAIL=0
pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1${2:+ — $2}"; FAIL=$((FAIL + 1)); }
check() { if eval "$2" > /dev/null 2>&1; then pass "$1"; else fail "$1"; fi; }

T=$(mktemp -d) || { echo "no pude crear una carpeta temporal"; exit 1; }
trap 'rm -rf "$T"' EXIT

ESPERADOS="conceptests.md ejemplo-resuelto.md exit-ticket.md notas-estudiante.md plan-sesion.md practica-guiada retrieval-inicio.md tarea-espaciada.md"

# La primera sesión de cada unidad en el calendario (así la prueba no depende de un número de sesión fijo).
primera_sesion() { # $1 = romano de la unidad
    awk -v u="$1" -F'|' '
        /^## / { en = ($0 ~ "^## Unidad " u " ") }
        en && $2 ~ /^ *S[0-9]+ *$/ { gsub(/ /, "", $2); print $2; exit }' "$RAIZ"/planeacion/calendario-*.md | head -1
}

for caso in "3 III openmp" "4 IV mpi" "5 V gpu"; do
    read -r k romano tec <<< "$caso"
    sid=$(primera_sesion "$romano")
    if [[ -z $sid ]]; then
        echo "AVISO: la Unidad $romano no está en el calendario; se genera con --fecha"
        sid=S01
        salida=$($GEN "U$k" "$sid" prueba-$tec --tec "$tec" --fecha 2026-11-23 --destino "$T/U$k" 2>&1)
    else
        salida=$($GEN "U$k" "$sid" prueba-$tec --tec "$tec" --destino "$T/U$k" 2>&1)
    fi
    rc=$?
    dir=$(sed -n 's/^sesion=//p' <<< "$salida")
    if [[ $rc -ne 0 || ! -d $dir ]]; then fail "genera U$k $sid ($tec)" "$salida"; continue; fi
    pass "genera U$k $sid ($tec)"

    # shellcheck disable=SC2012
    obtenidos=$(ls "$dir" | sort | tr '\n' ' ' | sed 's/ $//')
    if [[ $obtenidos == "$ESPERADOS" ]]; then pass "U$k: exactamente los 8 elementos de CONVENCIONES §1"
    else fail "U$k: exactamente los 8 elementos de CONVENCIONES §1" "hay: $obtenidos"; fi

    malos=0
    while IFS= read -r md; do
        head -1 "$md" | grep -qE "^> \*\*.+\*\* · Unidad $romano · Sesión $sid · (lunes|martes|miércoles|jueves|viernes|sábado|domingo) [0-9]{1,2} de [a-z]+ de 20[0-9]{2} · [0-9]{2}:[0-9]{2}–[0-9]{2}:[0-9]{2} · .+" || malos=$((malos + 1))
    done < <(find "$dir" -name '*.md')
    if [[ $malos -eq 0 ]]; then pass "U$k: encabezado de metadatos en cada .md"; else fail "U$k: encabezado de metadatos en cada .md" "$malos archivo(s) sin él"; fi

    check "U$k: no quedan variables {{...}} sin sustituir" "! grep -rq '{{' '$dir'"
    check "U$k: lo que falta escribir está marcado con [PENDIENTE: ...]" "grep -q 'PENDIENTE:' '$dir/plan-sesion.md'"
    check "U$k: la tarea vence en una fecha con día de la semana (o queda PENDIENTE)" \
        "grep -Eq 'Vence (al inicio de .+\*\*(lunes|martes|miércoles|jueves|viernes) [0-9]+ de [a-z]+ de 20[0-9]{2}, [0-9:]+\*\*|\[PENDIENTE)' '$dir/tarea-espaciada.md'"
    check "U$k: practica-guiada/ tiene README, Makefile, tests/run_tests.sh ejecutable y .gitignore" \
        "test -f '$dir/practica-guiada/README.md' -a -f '$dir/practica-guiada/Makefile' -a -x '$dir/practica-guiada/tests/run_tests.sh' -a -f '$dir/practica-guiada/.gitignore'"
    check "U$k: el README de la práctica tiene las cinco fases PRIMM" \
        "test \$(grep -cE '^## Fase [1-5] · (Predecir|Ejecutar|Investigar|Modificar|Crear)' '$dir/practica-guiada/README.md') -eq 5"

    if [[ $tec == mpi ]] && ! command -v mpicc > /dev/null 2>&1; then
        echo "AVISO: sin mpicc; no se compila la práctica guiada de MPI"
        continue
    fi
    if [[ $tec == gpu ]] && ! "$PY" -c 'import numba' > /dev/null 2>&1; then
        echo "AVISO: sin numba; no se prueba la práctica guiada de GPU"
        continue
    fi
    log="$T/make-$tec.log"
    if (cd "$dir/practica-guiada" && make clean && make) > "$log" 2>&1 < /dev/null; then
        if grep -qi 'warning:' "$log"; then fail "U$k: make sin warnings" "$(grep -i 'warning:' "$log" | head -2)"; else pass "U$k: make sin warnings"; fi
        if (cd "$dir/practica-guiada" && make test) > "$log" 2>&1 < /dev/null; then pass "U$k: make test pasa ($(tail -1 "$log"))"
        else fail "U$k: make test pasa" "$(tail -3 "$log")"; fi
        (cd "$dir/practica-guiada" && make clean) > /dev/null 2>&1
        # shellcheck disable=SC2012
        check "U$k: make clean no deja binarios" "test -z \"\$(find '$dir/practica-guiada' -type f -perm -u+x ! -name '*.sh' ! -name '*.py')\""
    else
        fail "U$k: make compila" "$(tail -3 "$log")"
    fi

    # Segunda corrida sobre la misma sesión: no se sobrescribe.
    $GEN "U$k" "$sid" otra-vez --tec "$tec" --fecha 2026-11-23 --forzar --destino "$T/U$k" > /dev/null 2>&1
    check "U$k: no sobrescribe una sesión que ya existe (código 3)" "test $? -eq 3"
done

sid5=$(primera_sesion V)
if [[ -n $sid5 ]]; then
    $GEN U5 "$sid5" x --fecha 2001-01-01 --destino "$T/contradice" > /dev/null 2>&1
    check "rechaza una fecha que contradice el calendario (código 2)" "test $? -eq 2"
    check "y no crea nada en ese caso" "test ! -e '$T/contradice'"
fi
$GEN U5 S99 x --destino "$T/sin-fecha" > /dev/null 2>&1
check "sesión fuera del calendario sin --fecha: código 2" "test $? -eq 2"
$GEN U5 S01 "Tema Con Espacios" --seco > /dev/null 2>&1
check "tema corto no válido: código 2" "test $? -eq 2"
salida=$($GEN U5 S99 fuera-del-calendario --fecha 2026-12-14 --destino "$T/fuera" 2>&1)
check "sesión fuera del calendario con --fecha: se crea con lunes 14 de diciembre de 2026 y un PENDIENTE que lo avisa" \
    "grep -q 'lunes 14 de diciembre de 2026' <<< '$salida' && grep -q 'no está en planeacion/calendario' '$T'/fuera/S99_*/plan-sesion.md"
$GEN U5 S98 repaso-prueba --fecha 2026-12-15 --tipo Repaso --destino "$T/repaso" > /dev/null 2>&1
check "una sesión de repaso agrega examen-practica-U5.md con encabezado" \
    "head -1 '$T'/repaso/S98_*/examen-practica-U5.md | grep -q 'Unidad V · Sesión S98 · martes 15 de diciembre de 2026 · 08:30–10:00'"
$GEN U5 S01 x --seco --destino "$T/seco" > /dev/null 2>&1
check "--seco no crea nada" "test ! -e '$T/seco'"

echo "Resultado: $PASS PASS, $FAIL FAIL"
[[ $FAIL -eq 0 ]]
