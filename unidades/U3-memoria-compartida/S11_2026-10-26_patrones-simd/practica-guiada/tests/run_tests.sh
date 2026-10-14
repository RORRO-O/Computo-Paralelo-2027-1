#!/usr/bin/env bash
# run_tests.sh — Verificación automática de la práctica guiada S11.
# Cada programa compara su versión paralela contra la secuencial e imprime "CHECK OK" si coincide
# (exacto para enteros y para max; con tolerancia para sumas en punto flotante).
# Tamaños pequeños: cada caso tarda menos de 1 s. Termina con código 0 solo si todos pasan.
set -u
cd "$(dirname "$0")/.." || exit 1

pass=0; fail=0; skip=0

run_case() {   # nombre, comando...
    local name="$1"; shift
    local out
    out="$("$@" 2>&1)"
    local code=$?
    if [ "$name" = "jacobi simd 4 hilos" ] && grep -q "TODO pendiente" <<<"$out"; then
        echo "SKIP  $name  (TODO(1) sin completar: el modo simd aun ejecuta el codigo de par)"
        skip=$((skip+1)); return
    fi
    if [ $code -eq 0 ] && grep -q "CHECK OK" <<<"$out"; then
        echo "PASS  $name"; pass=$((pass+1))
    else
        echo "FAIL  $name (codigo $code)"; echo "$out" | sed 's/^/      /'; fail=$((fail+1))
    fi
}

make -s all || { echo "FAIL  compilacion"; exit 1; }

run_case "histograma 4 hilos, 16 casillas"      ./array_reduction 2000000 16 4
run_case "histograma 3 hilos, 7 casillas"       ./array_reduction 1000003 7 3
run_case "scan 4 hilos, n potencia de 2"        ./scan 1048576 4
run_case "scan 3 hilos, n impar"                ./scan 1000001 3
run_case "scan 1 hilo"                          ./scan 100000 1
run_case "saxpy tres versiones identicas"       ./saxpy_simd 4194304
run_case "jacobi par 4 hilos converge"          ./jacobi1d 64 100000 1e-6 par 4 1
run_case "jacobi par 3 hilos, max_iter"         ./jacobi1d 1001 500 1e-9 par 3 1
run_case "jacobi simd 4 hilos"                  ./jacobi1d 1001 500 1e-9 simd 4 1

echo "----"
echo "PASS=$pass FAIL=$fail SKIP=$skip"
[ $fail -eq 0 ]
