#!/usr/bin/env bash
# run_tests.sh — Pruebas de la práctica guiada S06 (cazador de errores MPI + revisor de mediciones).
#
# Cuatro grupos:
#   1. Compilación sin warnings y ejemplo resuelto (-np 4 y -np 6; la variante --sin-commit DEBE fallar).
#   2. Síntomas de los tres programas con error, bajo `timeout 10`: el síntoma documentado es lo
#      esperado y cuenta como PASS (así el material se verifica a sí mismo).
#   3. Correcciones del estudiante: caza1_orden_send.c, caza2_bcast_solo_raiz.c, caza3_recv_corto.c
#      (y caza4*.c de la fase Crear). Si el archivo no existe -> SKIP. Con STRICT=1 (`make listo`) un
#      SKIP cuenta como FAIL: ese objetivo pasa solo cuando los errores están corregidos.
#   4. Revisor de mediciones: el CSV correcto no da errores; el CSV con errores plantados da exactamente esos.
#
# Imprime PASS / FAIL / SKIP por caso y termina con código 0 solo si no hay FAIL.
# Variables: MPIRUN (mpirun), MPIRUN_FLAGS (--oversubscribe), PYTHON (python3), STRICT (0).
# Si tu MPI no acepta --oversubscribe: MPIRUN_FLAGS="" bash tests/run_tests.sh

set -u
cd "$(dirname "$0")/.." || exit 2

# Open MPI se niega a correr como root salvo que se declare explícitamente.
if [ "$(id -u)" -eq 0 ]; then
    export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
fi

MPIRUN="${MPIRUN:-mpirun}"
MPIRUN_FLAGS="${MPIRUN_FLAGS:---oversubscribe}"
PYTHON="${PYTHON:-python3}"
STRICT="${STRICT:-0}"
CFLAGS="-std=c11 -O2 -Wall -Wextra"
T_HANG=10     # programas que pueden colgarse (regla del curso: timeout 10)
T_OK=15       # programas que deben terminar

pass=0; fail=0; skip=0
out="$(mktemp)"
trap 'rm -f "$out"' EXIT

report() { # estado nombre detalle
    printf '%-4s %-52s %s\n' "$1" "$2" "$3"
    case "$1" in PASS) pass=$((pass+1));; FAIL) fail=$((fail+1));; SKIP) skip=$((skip+1));; esac
}

run() { # NP TIMEOUT PROG ARGS...  -> salida en $out, código en $rc
    local np="$1" t="$2"; shift 2
    # shellcheck disable=SC2086
    timeout --foreground -k 2 "$t" "$MPIRUN" $MPIRUN_FLAGS -np "$np" "$@" >"$out" 2>&1
    rc=$?
}

hung() { [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ]; }          # timeout lo mató (TERM o KILL)
said_ok() { grep -q 'VERIFICACION OK' "$out"; }

compile() { # nombre -> PASS/FAIL "compila sin warnings"
    local w
    w=$(mpicc $CFLAGS -o "$1" "$1.c" 2>&1); local c=$?
    if [ $c -ne 0 ] || [ -n "$w" ]; then
        report FAIL "compila sin warnings: $1.c" "$(echo "$w" | head -3 | tr '\n' '|')"
        return 1
    fi
    report PASS "compila sin warnings: $1.c" ""
    return 0
}

echo "== 1. Compilación y ejemplo resuelto (MPIRUN_FLAGS='$MPIRUN_FLAGS') =="
for src in ejemplo_columna_split caza1_orden_send_buggy caza2_bcast_solo_raiz_buggy caza3_recv_corto_buggy; do
    compile "$src" || true
done

run 4 $T_OK ./ejemplo_columna_split
if [ $rc -eq 0 ] && said_ok && grep -q '\[ 2 12 22 32 \]' "$out" \
   && grep -q 'rango 3 -> fila 1, rango en la fila 1 de 2, suma de rangos de la fila = 5' "$out"; then
    report PASS "ejemplo -np 4: columna [2 12 22 32], filas 0+1=1 y 2+3=5" ""
else
    report FAIL "ejemplo -np 4" "rc=$rc; $(tail -3 "$out" | tr '\n' '|')"
fi

run 6 $T_OK ./ejemplo_columna_split
if [ $rc -eq 0 ] && said_ok && grep -q 'suma de rangos de la fila = 12' "$out"; then
    report PASS "ejemplo -np 6: malla 2x3, fila 1 suma 3+4+5=12" ""
else
    report FAIL "ejemplo -np 6" "rc=$rc; $(tail -3 "$out" | tr '\n' '|')"
fi

run 4 $T_HANG ./ejemplo_columna_split --sin-commit
if [ $rc -ne 0 ] && ! said_ok; then
    report PASS "ejemplo --sin-commit falla (variante que falla)" "$(grep -o 'MPI_ERR_TYPE[^*]*' "$out" | head -1)"
else
    report FAIL "ejemplo --sin-commit debía fallar" "rc=$rc"
fi

run 3 $T_OK ./ejemplo_columna_split
if [ $rc -ne 0 ] && grep -q 'Uso:' "$out"; then
    report PASS "ejemplo -np 3 rechaza una malla imposible (verifica p)" ""
else
    report FAIL "ejemplo -np 3 debía rechazar p impar" "rc=$rc"
fi

echo "== 2. Síntomas de los programas con error (lo esperado es el síntoma) =="
run 4 $T_HANG ./caza1_orden_send_buggy 1000000
if hung; then report PASS "caza1 buggy n=1e6: se cuelga (interbloqueo)" "rc=$rc tras $T_HANG s"
else report FAIL "caza1 buggy n=1e6 debía colgarse" "rc=$rc; $(tail -2 "$out" | tr '\n' '|')"; fi

run 4 $T_OK ./caza1_orden_send_buggy 100
if [ $rc -eq 0 ] && said_ok; then report PASS "caza1 buggy n=100: termina 'por suerte' (eager)" ""
else report FAIL "caza1 buggy n=100 debía terminar" "rc=$rc"; fi

run 4 $T_HANG ./caza2_bcast_solo_raiz_buggy 1048576
if hung; then report PASS "caza2 buggy n=2^20: se cuelga" "rc=$rc tras $T_HANG s"
else report FAIL "caza2 buggy n=2^20 debía colgarse" "rc=$rc; $(tail -2 "$out" | tr '\n' '|')"; fi

run 4 $T_OK ./caza2_bcast_solo_raiz_buggy 100
if [ $rc -eq 0 ] && grep -q 'VERIFICACION FAIL' "$out"; then
    report PASS "caza2 buggy n=100: termina con resultado incorrecto" "$(grep -o 'suma=[0-9]*, esperada=[0-9]*' "$out")"
else report FAIL "caza2 buggy n=100 debía dar VERIFICACION FAIL" "rc=$rc; $(tail -2 "$out" | tr '\n' '|')"; fi

run 4 $T_HANG ./caza3_recv_corto_buggy 10
if [ $rc -ne 0 ] && ! said_ok; then
    if grep -q 'MPI_ERR_TRUNCATE' "$out"; then det="MPI_ERR_TRUNCATE"; else det="rc=$rc (mpirun no alcanzó a imprimir el error)"; fi
    report PASS "caza3 buggy n=10 -np 4: aborta" "$det"
else report FAIL "caza3 buggy n=10 debía abortar" "rc=$rc"; fi

run 4 $T_OK ./caza3_recv_corto_buggy 8
if [ $rc -eq 0 ] && said_ok; then report PASS "caza3 buggy n=8 -np 4: funciona 'por suerte' (n divisible)" ""
else report FAIL "caza3 buggy n=8 debía terminar bien" "rc=$rc"; fi

echo "== 3. Correcciones del estudiante (SKIP si no existen; con STRICT=1 cuentan como FAIL) =="
check_fixed() { # nombre "np n" "np n" ...
    local name="$1"; shift
    if [ ! -f "$name.c" ]; then
        if [ "$STRICT" = "1" ]; then report FAIL "$name.c no existe" "copia ${name}_buggy.c y corrige el error"
        else report SKIP "$name.c no existe todavía" "cuando lo tengas, make listo"; fi
        return
    fi
    compile "$name" || return
    local c np n
    for c in "$@"; do
        set -- $c; np="$1"; n="$2"
        run "$np" $T_HANG "./$name" "$n"
        if [ $rc -eq 0 ] && said_ok; then report PASS "$name -np $np n=$n: VERIFICACION OK" ""
        else report FAIL "$name -np $np n=$n" "rc=$rc; $(tail -2 "$out" | tr '\n' '|')"; fi
    done
}
check_fixed caza1_orden_send     "4 1000000" "2 1000000"
check_fixed caza2_bcast_solo_raiz "4 1048576" "3 1000"
check_fixed caza3_recv_corto     "4 10" "4 7" "4 8" "3 7"

# Fase Crear: caza4*_buggy.c debe compilar y mostrar un síntoma; caza4*.c (corregido) debe decir OK.
found4=0
for f in caza4*_buggy.c; do
    [ -f "$f" ] || continue
    found4=1
    name="${f%.c}"
    compile "$name" || continue
    run 4 $T_HANG "./$name"
    if ! { [ $rc -eq 0 ] && said_ok; }; then report PASS "$name: muestra un síntoma (rc=$rc)" ""
    else report FAIL "$name: no se ve ningún síntoma" "un error que no se nota no sirve para cazar"; fi
    fixed="${name%_buggy}"
    if [ -f "$fixed.c" ]; then
        compile "$fixed" && { run 4 $T_HANG "./$fixed"; if [ $rc -eq 0 ] && said_ok; then report PASS "$fixed: VERIFICACION OK" ""; else report FAIL "$fixed" "rc=$rc"; fi; }
    else
        if [ "$STRICT" = "1" ]; then report FAIL "$fixed.c no existe" "tu pareja debe corregir tu programa"
        else report SKIP "$fixed.c no existe todavía" ""; fi
    fi
done
if [ $found4 -eq 0 ]; then
    if [ "$STRICT" = "1" ]; then report FAIL "caza4_*_buggy.c no existe" "fase Crear pendiente"
    else report SKIP "caza4_*_buggy.c (fase Crear) no existe todavía" ""; fi
fi

echo "== 4. Revisor de mediciones =="
"$PYTHON" revisar_mediciones.py ejemplo_mediciones_ok.csv --nucleos 4 >"$out" 2>&1; rc=$?
if [ $rc -eq 0 ] && grep -q 'Resumen: 0 errores' "$out" && grep -q 'AVISO A1' "$out" \
   && grep -q '| V2 | 4 | 0.712 | 0.705 | 0.731 | 3.378 | 0.844 | 0.061 |' "$out"; then
    report PASS "revisor: CSV correcto -> 0 errores, aviso de sobre-suscripción, f(4)=0.061" ""
else
    report FAIL "revisor: CSV correcto" "rc=$rc; $(grep -E 'ERROR|Resumen' "$out" | tr '\n' '|')"
fi

"$PYTHON" revisar_mediciones.py ejemplo_mediciones_mal.csv --nucleos 4 >"$out" 2>&1; rc=$?
if [ $rc -eq 1 ]; then
    for code in E1 E2 E3 E5 E6; do
        if grep -q "ERROR $code" "$out"; then msg="$(grep "ERROR $code" "$out" | head -1 | cut -d' ' -f3-)"; report PASS "revisor: CSV con errores detecta $code" "${msg:0:60}…"
        else report FAIL "revisor: CSV con errores no detecta $code" ""; fi
    done
    grep -q 'AVISO A4' "$out" && report PASS "revisor: avisa T(1) < 1 s" "" || report FAIL "revisor: debía avisar T(1) < 1 s" ""
else
    report FAIL "revisor: CSV con errores debía salir con código 1" "rc=$rc"
fi

if "$PYTHON" -c 'import matplotlib' 2>/dev/null; then
    rm -f speedup_ejemplo.png
    "$PYTHON" revisar_mediciones.py ejemplo_mediciones_ok.csv --nucleos 4 --png speedup_ejemplo.png >"$out" 2>&1
    if [ -s speedup_ejemplo.png ]; then report PASS "revisor: genera speedup_ejemplo.png" ""
    else report FAIL "revisor: no generó la gráfica" "$(tail -2 "$out" | tr '\n' '|')"; fi
else
    report SKIP "revisor --png (matplotlib no instalado)" ""
fi

echo
echo "Resumen: $pass PASS, $fail FAIL, $skip SKIP"
if [ "$STRICT" = "1" ] && [ $fail -eq 0 ]; then echo "LISTO: los tres errores están corregidos y la fase Crear existe."; fi
[ "$fail" -eq 0 ]
