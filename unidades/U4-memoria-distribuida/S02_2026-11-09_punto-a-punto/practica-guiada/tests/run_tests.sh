#!/usr/bin/env bash
# run_tests.sh — Pruebas de la práctica guiada S02 (comunicación punto a punto).
#
# Compila con make, ejecuta cada programa con tamaños fijos y verifica la salida.
# Imprime PASS / FAIL / SKIP por caso y termina con código 0 solo si no hay FAIL.
#   SKIP = el archivo todavía tiene su TODO sin completar (imprime "TODO pendiente").
#
# El caso "cross_exchange_buggy n=1000000" se ejecuta con "timeout 10": el
# interbloqueo (código 124 de timeout, o 137 si tuvo que matar a mpirun con KILL) es el síntoma ESPERADO y cuenta como PASS.
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
TIMEOUT_HANG=10   # para el programa que se cuelga a propósito
TIMEOUT_OK=15     # para los que deben terminar

pass=0; fail=0; skip=0
out="$(mktemp)"
trap 'rm -f "$out"' EXIT

report() { # estado nombre detalle
    printf '%-4s %-48s %s\n' "$1" "$2" "$3"
    case "$1" in PASS) pass=$((pass+1));; FAIL) fail=$((fail+1));; SKIP) skip=$((skip+1));; esac
}

# run NP PROG ARGS... -> ejecuta con timeout normal; deja salida en $out y código en $rc
run() {
    local np="$1"; shift
    # shellcheck disable=SC2086
    timeout -k 2 "$TIMEOUT_OK" "$MPIRUN" $MPIRUN_FLAGS -np "$np" "$@" >"$out" 2>&1
    rc=$?; [ $rc -eq 137 ] && rc=124   # KILL tras el TERM de timeout: también es cuelgue
}

echo "== Compilando =="
if ! make -s all; then
    echo "FAIL compilacion"; exit 1
fi
echo "== Ejecutando pruebas (MPIRUN_FLAGS='$MPIRUN_FLAGS') =="

# ---------- 1. status_demo: fuente, etiqueta y cuenta correctas, en cualquier orden
run 3 ./status_demo
if [ $rc -eq 0 ] && grep -q "fuente=1 etiqueta=10 elementos=3 " "$out" \
                 && grep -q "fuente=2 etiqueta=20 elementos=4 " "$out" \
                 && [ "$(grep -c 'rango 0: mensaje' "$out")" -eq 2 ]; then
    report PASS "status_demo -np 3" "2 mensajes con fuente/etiqueta/cuenta correctos"
else
    report FAIL "status_demo -np 3" "rc=$rc; salida: $(tr '\n' '|' <"$out")"
fi

# ---------- 2. ring_token: valor final = inicial + suma de rangos 1..N-1
check_ring() { # np inicial esperado
    local np="$1" init="$2" expected="$3"
    run "$np" ./ring_token "$init"
    if [ $rc -eq 0 ] && grep -q "token final = $expected\b" "$out"; then
        report PASS "ring_token -np $np inicial=$init" "token final = $expected"
    else
        report FAIL "ring_token -np $np inicial=$init" "esperado $expected; rc=$rc; $(grep 'token final' "$out")"
    fi
}
check_ring 5 0 10
check_ring 4 7 13
check_ring 1 0 0

# ---------- 3. ping_pong: formato y números positivos (tamaños chicos para que sea rápido)
run 2 ./ping_pong 4096 3
rows=$(grep -c '^ ' "$out")
if [ $rc -eq 0 ] && [ "$rows" -eq 5 ] && \
   awk '!/^#/ { if ($3 <= 0 || $6 <= 0) bad=1; if ($1 > 0 && $7 <= 0) bad=1 } END { exit bad ? 1 : 0 }' "$out"; then
    report PASS "ping_pong -np 2 max=4096 reps=3" "5 tamaños, rtt y latencia > 0, ancho de banda > 0"
else
    report FAIL "ping_pong -np 2 max=4096 reps=3" "rc=$rc filas=$rows; $(tr '\n' '|' <"$out" | cut -c1-300)"
fi

# ---------- 4. cross_exchange_buggy con n chico: debe terminar bien
run 2 ./cross_exchange_buggy 10
if [ $rc -eq 0 ] && [ "$(grep -c 'intercambio correcto' "$out")" -eq 2 ]; then
    report PASS "cross_exchange_buggy -np 2 n=10" "termina (mensaje chico, hubo buffering)"
else
    report FAIL "cross_exchange_buggy -np 2 n=10" "rc=$rc; $(tr '\n' '|' <"$out" | cut -c1-200)"
fi

# ---------- 5. cross_exchange_buggy con n grande: el cuelgue es el síntoma esperado
# shellcheck disable=SC2086
timeout -k 2 "$TIMEOUT_HANG" "$MPIRUN" $MPIRUN_FLAGS -np 2 ./cross_exchange_buggy 1000000 >"$out" 2>&1
rc=$?; [ $rc -eq 137 ] && rc=124   # KILL tras el TERM de timeout: también es cuelgue
if [ $rc -eq 124 ]; then
    report PASS "cross_exchange_buggy -np 2 n=1000000 (timeout $TIMEOUT_HANG)" "se interbloqueo, como se esperaba"
elif [ $rc -eq 0 ] && [ "$(grep -c 'intercambio correcto' "$out")" -eq 2 ]; then
    report PASS "cross_exchange_buggy -np 2 n=1000000 (timeout $TIMEOUT_HANG)" "AVISO: NO se colgo aqui (esta implementacion hizo buffering); el estandar permite ambas cosas"
else
    report FAIL "cross_exchange_buggy -np 2 n=1000000 (timeout $TIMEOUT_HANG)" "rc=$rc; $(tr '\n' '|' <"$out" | cut -c1-200)"
fi

# ---------- 6. cross_exchange_fixed: paridad y no bloqueante, 4 procesos, n grande
for mode in paridad noblock; do
    run 4 ./cross_exchange_fixed "$mode" 1000000
    if [ $rc -eq 0 ] && [ "$(grep -c 'intercambio correcto' "$out")" -eq 4 ]; then
        report PASS "cross_exchange_fixed $mode -np 4 n=1000000" "4 rangos correctos"
    else
        report FAIL "cross_exchange_fixed $mode -np 4 n=1000000" "rc=$rc; $(tr '\n' '|' <"$out" | cut -c1-200)"
    fi
done

# ---------- 7. cross_exchange_sendrecv (TODO(1)): SKIP si sigue pendiente
run 2 ./cross_exchange_sendrecv 1000000
if grep -q 'TODO pendiente' "$out"; then
    report SKIP "cross_exchange_sendrecv -np 2 n=1000000" "TODO(1) sin completar"
elif [ $rc -eq 0 ] && [ "$(grep -c 'intercambio correcto' "$out")" -eq 2 ]; then
    report PASS "cross_exchange_sendrecv -np 2 n=1000000" "2 rangos correctos con MPI_Sendrecv"
elif [ $rc -eq 124 ]; then
    report FAIL "cross_exchange_sendrecv -np 2 n=1000000" "se colgo: todavia hay un Send que espera a un Recv que no llega"
else
    report FAIL "cross_exchange_sendrecv -np 2 n=1000000" "rc=$rc; $(tr '\n' '|' <"$out" | cut -c1-200)"
fi

# ---------- 8. ring_neighbors (TODO(2), TODO(3)): SKIP si sigue pendiente
for np in 2 4 5; do
    run "$np" ./ring_neighbors 1000000
    if grep -q 'TODO pendiente' "$out"; then
        report SKIP "ring_neighbors -np $np n=1000000" "TODO(2)/TODO(3) sin completar"
    elif [ $rc -eq 0 ] && [ "$(grep -c 'vecinos correctos' "$out")" -eq "$np" ]; then
        report PASS "ring_neighbors -np $np n=1000000" "$np rangos con ambos vecinos correctos"
    elif [ $rc -eq 124 ]; then
        report FAIL "ring_neighbors -np $np n=1000000" "se colgo: revisa el orden Send/Recv o usa MPI_Sendrecv"
    else
        report FAIL "ring_neighbors -np $np n=1000000" "rc=$rc; $(tr '\n' '|' <"$out" | cut -c1-200)"
    fi
done

echo "== Resumen: $pass PASS, $fail FAIL, $skip SKIP =="
[ "$fail" -eq 0 ]
