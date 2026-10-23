#!/usr/bin/env bash
# run_tests.sh — Pruebas de la práctica guiada S03 (colectivas y producto matriz-vector).
#
# Compila con make, ejecuta cada programa con tamaños fijos y compara el checksum (suma de y)
# contra matvec_seq, la versión secuencial, con tolerancia relativa 1e-9.
# Imprime PASS / FAIL / SKIP por caso y termina con código 0 solo si no hay FAIL.
#   SKIP = el archivo todavía tiene su TODO sin completar (imprime "TODO pendiente"), o el
#          programa de la fase Crear (norma_allreduce.c) todavía no existe.
#
# matvec_bcast_buggy se ejecuta con "timeout 10": el error (Bcast que no llaman todos) tiene
# DOS síntomas válidos y los dos cuentan como PASS: cuelgue (código 124 de timeout, o 137 si tuvo que matar a mpirun con KILL) o
# resultado incorrecto (checksum distinto). Lo que sería FAIL es que diera el resultado correcto.
#
# Variables: MPIRUN (por defecto mpirun), MPIRUN_FLAGS (por defecto --oversubscribe).
# Si tu MPI no acepta --oversubscribe: MPIRUN_FLAGS="" bash tests/run_tests.sh

set -u
cd "$(dirname "$0")/.." || exit 2

# Open MPI se niega a correr como root salvo que se declare explícitamente.
if [ "$(id -u)" -eq 0 ]; then
    export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
fi

MPIRUN="${MPIRUN:-mpirun}"
MPIRUN_FLAGS="${MPIRUN_FLAGS:---oversubscribe}"
TIMEOUT_HANG=10   # para el programa que puede colgarse a propósito
TIMEOUT_OK=20     # para los que deben terminar

pass=0; fail=0; skip=0
out="$(mktemp)"
trap 'rm -f "$out"' EXIT

report() { # estado nombre detalle
    printf '%-4s %-46s %s\n' "$1" "$2" "$3"
    case "$1" in PASS) pass=$((pass+1));; FAIL) fail=$((fail+1));; SKIP) skip=$((skip+1));; esac
}

# run NP PROG ARGS... -> ejecuta con timeout normal; deja la salida en $out y el código en $rc
run() {
    local np="$1"; shift
    # shellcheck disable=SC2086
    timeout -k 2 "$TIMEOUT_OK" "$MPIRUN" $MPIRUN_FLAGS -np "$np" "$@" >"$out" 2>&1
    rc=$?; [ $rc -eq 137 ] && rc=124   # KILL tras el TERM de timeout: también es cuelgue
}

# value KEY [archivo] -> número que sigue a "KEY = " en la última línea que lo contenga
value() { sed -n "s/.*$1 = \([-0-9.eE+]*\).*/\1/p" "${2:-$out}" | tail -n 1; }

# close A B -> 0 si |A-B| <= 1e-9 * max(1,|B|)
close() { awk -v a="$1" -v b="$2" 'BEGIN { d = a - b; if (d < 0) d = -d; m = (b < 0 ? -b : b); if (m < 1) m = 1; exit !(d <= 1e-9 * m) }'; }

echo "== Compilando =="
if ! make -s all; then
    echo "FAIL compilacion"; exit 1
fi
echo "== Ejecutando pruebas (MPIRUN_FLAGS='$MPIRUN_FLAGS') =="

# ---------- 0. Referencia secuencial: valores conocidos con n = 8 y checksums para los demás casos
./matvec_seq 8 >"$out" 2>&1
if [ $? -eq 0 ] && grep -q '^y\[3\] = 276.0$' "$out" && grep -q '^y\[7\] = 420.0$' "$out" \
   && close "$(value checksum)" 2352; then
    report PASS "matvec_seq n=8" "y[3] = 276, y[7] = 420, checksum = 2352"
else
    report FAIL "matvec_seq n=8" "$(tr '\n' '|' <"$out" | cut -c1-200)"
fi
declare -A REF_SUM REF_NORM
for n in 3 8 10 12 1024; do
    ./matvec_seq "$n" >"$out" 2>&1
    REF_SUM[$n]=$(value checksum); REF_NORM[$n]=$(value norma)
done

# ---------- 1. matvec_collectives: 1, 2 y 4 procesos con n = 8; 4 procesos con n = 1024
check_matvec() { # prog np n etiqueta
    local prog="$1" np="$2" n="$3" label="$4"
    run "$np" "./$prog" "$n"
    local got; got=$(value checksum)
    if [ $rc -eq 0 ] && [ -n "$got" ] && close "$got" "${REF_SUM[$n]}"; then
        report PASS "$label" "checksum = $got (= secuencial)"
    else
        report FAIL "$label" "rc=$rc checksum='$got' esperado=${REF_SUM[$n]}; $(tr '\n' '|' <"$out" | cut -c1-160)"
    fi
}
for np in 1 2 4; do check_matvec matvec_collectives "$np" 8 "matvec_collectives -np $np n=8"; done
check_matvec matvec_collectives 4 1024 "matvec_collectives -np 4 n=1024"

# n no múltiplo de p: debe explicarlo y terminar con código distinto de 0 (no colgarse ni dar basura)
run 3 ./matvec_collectives 8
if [ $rc -ne 0 ] && [ $rc -ne 124 ] && grep -q 'no es multiplo de p' "$out"; then
    report PASS "matvec_collectives -np 3 n=8 (n % p != 0)" "rechaza con mensaje; rc=$rc"
else
    report FAIL "matvec_collectives -np 3 n=8 (n % p != 0)" "rc=$rc; $(tr '\n' '|' <"$out" | cut -c1-160)"
fi

# ---------- 2. matvec_p2p: misma salida que la versión con colectivas
check_matvec matvec_p2p 4 8    "matvec_p2p -np 4 n=8"
check_matvec matvec_p2p 4 1024 "matvec_p2p -np 4 n=1024"

# ---------- 3. matvec_scatterv: n NO múltiplo de p, y n < p
check_matvec matvec_scatterv 4 10 "matvec_scatterv -np 4 n=10"
check_matvec matvec_scatterv 3 8  "matvec_scatterv -np 3 n=8"
check_matvec matvec_scatterv 4 3  "matvec_scatterv -np 4 n=3 (un rango sin filas)"
run 4 ./matvec_scatterv 10
if grep -q 'filas por rango: 3 3 2 2' "$out"; then
    report PASS "matvec_scatterv -np 4 n=10 reparto" "filas por rango: 3 3 2 2"
else
    report FAIL "matvec_scatterv -np 4 n=10 reparto" "$(grep 'filas por rango' "$out")"
fi

# ---------- 4. colectivas_demo: cada colectiva deja el dato donde debe (y solo ahí)
run 4 ./colectivas_demo
if [ $rc -eq 0 ] \
   && [ "$(grep -c 'Bcast: n = 42' "$out")" -eq 4 ] \
   && grep -q '\[rango 2\] Scatter: mi bloque = {5, 6}' "$out" \
   && grep -q '\[rango 0\] Gather: squares = {1, 4, 9, 16}' "$out" \
   && [ "$(grep -c 'Gather: squares = {-1, -1, -1, -1}' "$out")" -eq 3 ] \
   && grep -q '\[rango 0\] Reduce: sum = 10, max = 4' "$out" \
   && [ "$(grep -c 'Reduce: sum = -1, max = -1' "$out")" -eq 3 ] \
   && [ "$(grep -c 'Allreduce: sum = 10' "$out")" -eq 4 ] \
   && [ "$(grep -c 'Allgather: squares = {1, 4, 9, 16}' "$out")" -eq 4 ] \
   && [ "$(grep -c 'Barrier: todos llegaron' "$out")" -eq 4 ]; then
    report PASS "colectivas_demo -np 4" "Bcast/Scatter/Gather/Reduce/Allreduce/Allgather/Barrier correctos"
else
    report FAIL "colectivas_demo -np 4" "rc=$rc; $(tr '\n' '|' <"$out" | cut -c1-300)"
fi

# ---------- 5. matvec_bcast_buggy: Bcast solo en el rango 0. Cuelgue o resultado incorrecto = PASS
for n in 8 1024; do
    # shellcheck disable=SC2086
    timeout -k 2 "$TIMEOUT_HANG" "$MPIRUN" $MPIRUN_FLAGS -np 4 ./matvec_bcast_buggy "$n" >"$out" 2>&1
    rc=$?; [ $rc -eq 137 ] && rc=124   # KILL tras el TERM de timeout: también es cuelgue
    got=$(value checksum)
    if [ $rc -eq 124 ]; then
        report PASS "matvec_bcast_buggy -np 4 n=$n (timeout $TIMEOUT_HANG)" "se colgo (sintoma esperado: el rango 0 espera dentro de Bcast)"
    elif [ -n "$got" ] && ! close "$got" "${REF_SUM[$n]}"; then
        report PASS "matvec_bcast_buggy -np 4 n=$n (timeout $TIMEOUT_HANG)" "termino con resultado INCORRECTO: checksum $got != ${REF_SUM[$n]} (sintoma esperado)"
    else
        report FAIL "matvec_bcast_buggy -np 4 n=$n (timeout $TIMEOUT_HANG)" "dio el resultado correcto o fallo de otra forma: rc=$rc checksum='$got'"
    fi
done

# ---------- 6. matvec_allgather (TODO(1)): SKIP si sigue pendiente; si no, todos los rangos con y completo
for np in 2 4; do
    run "$np" ./matvec_allgather 8
    if grep -q 'TODO pendiente' "$out"; then
        report SKIP "matvec_allgather -np $np n=8" "TODO(1) sin completar"
    elif [ $rc -eq 0 ] && [ "$(grep -c 'y completo: y\[0\] = 168.0, y\[7\] = 420.0, checksum = 2352.000000' "$out")" -eq "$np" ]; then
        report PASS "matvec_allgather -np $np n=8" "$np rangos con y completo y checksum 2352"
    elif [ $rc -eq 124 ]; then
        report FAIL "matvec_allgather -np $np n=8" "se colgo: ¿todos los rangos llaman a la misma colectiva?"
    else
        report FAIL "matvec_allgather -np $np n=8" "rc=$rc; $(tr '\n' '|' <"$out" | cut -c1-200)"
    fi
done

# ---------- 7. norma_allreduce (fase Crear): SKIP si el archivo no existe
if [ ! -f norma_allreduce.c ]; then
    report SKIP "norma_allreduce" "norma_allreduce.c no existe todavia (fase Crear)"
else
    for case in "4 8" "3 12" "4 1024"; do
        set -- $case; np=$1; n=$2
        run "$np" ./norma_allreduce "$n"
        count=0
        while read -r val; do close "$val" "${REF_NORM[$n]}" && count=$((count+1)); done < <(sed -n 's/.*norma = \([-0-9.eE+]*\).*/\1/p' "$out")
        if grep -q 'TODO pendiente' "$out"; then
            report SKIP "norma_allreduce -np $np n=$n" "TODO sin completar"
        elif [ $rc -eq 0 ] && [ "$count" -eq "$np" ]; then
            report PASS "norma_allreduce -np $np n=$n" "$np rangos imprimen norma = ${REF_NORM[$n]}"
        else
            report FAIL "norma_allreduce -np $np n=$n" "rc=$rc; rangos con la norma correcta: $count de $np (esperada ${REF_NORM[$n]}); $(tr '\n' '|' <"$out" | cut -c1-160)"
        fi
    done
fi

echo "== Resumen: $pass PASS, $fail FAIL, $skip SKIP =="
[ "$fail" -eq 0 ]
