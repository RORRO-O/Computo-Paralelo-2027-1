#!/usr/bin/env bash
# run_tests.sh — verificación SIN GPU de la práctica guiada S02 (Unidad V).
# Comprueba: (1) los .cu compilan con nvcc -c para sm_75 y sm_60, también con TILE=8/32;
# (2) la referencia CPU compila sin warnings con -Wall -Wextra y corre; (3) los espejos Numba
# pasan en el simulador (NUMBA_ENABLE_CUDASIM=1), incluidos n no múltiplo de TILE y los dos
# experimentos que deben FALLAR sin lanzar error de CUDA; (4) el checksum de la CPU coincide con
# el del simulador; (5) el notebook es válido y está sincronizado con los fuentes.
# Imprime PASS/FAIL por caso y termina con 0 solo si todo pasa. Duración típica: 25–40 s.
set -u
cd "$(dirname "$0")/.."
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
pass=0; fail=0
ok()   { echo "PASS  $1"; pass=$((pass+1)); }
bad()  { echo "FAIL  $1"; fail=$((fail+1)); }
export NUMBA_ENABLE_CUDASIM=1
export PYTHONDONTWRITEBYTECODE=1

echo "== (1) Compilación CUDA (nvcc -c, sin GPU) =="
if ! command -v nvcc >/dev/null 2>&1; then
    echo "SKIP  nvcc no encontrado: se omite la compilación CUDA (en Colab sí está)"
else
    for src in matmul_naive matmul_tiled transpose; do
        for arch in sm_75 sm_60; do
            if nvcc -c -arch=$arch "$src.cu" -o "$TMP/$src.$arch.o" >"$TMP/log" 2>&1; then
                ok "nvcc -c -arch=$arch $src.cu"
            else
                bad "nvcc -c -arch=$arch $src.cu"; cat "$TMP/log"
            fi
        done
    done
    for t in 8 32; do
        if nvcc -c -arch=sm_75 -DTILE=$t matmul_tiled.cu -o "$TMP/t$t.o" >"$TMP/log" 2>&1; then
            ok "nvcc -c -DTILE=$t matmul_tiled.cu"
        else
            bad "nvcc -c -DTILE=$t matmul_tiled.cu"; cat "$TMP/log"
        fi
    done
    if nvcc -c -arch=sm_75 -DSIN_SYNC1 -DGRID_TRUNCADO matmul_tiled.cu -o "$TMP/tx.o" >"$TMP/log" 2>&1; then
        ok "nvcc -c -DSIN_SYNC1 -DGRID_TRUNCADO matmul_tiled.cu (experimentos de Investigar)"
    else
        bad "nvcc -c -DSIN_SYNC1 -DGRID_TRUNCADO matmul_tiled.cu"; cat "$TMP/log"
    fi
fi

echo "== (2) Referencia CPU (gcc -Wall -Wextra, sin warnings) =="
if gcc -std=c11 -O2 -Wall -Wextra matmul_cpu.c -o "$TMP/matmul_cpu" >"$TMP/log" 2>&1 && [ ! -s "$TMP/log" ]; then
    ok "gcc matmul_cpu.c sin warnings"
else
    bad "gcc matmul_cpu.c (errores o warnings)"; cat "$TMP/log"
fi
if [ -x "$TMP/matmul_cpu" ]; then
    "$TMP/matmul_cpu" 64 16 >"$TMP/cpu64.txt" 2>&1
    if grep -q "ingenua : 524288" "$TMP/cpu64.txt" && grep -q "mosaicos: 32768" "$TMP/cpu64.txt"; then
        ok "matmul_cpu 64 16: modelo de lecturas 524288 vs 32768"
    else
        bad "matmul_cpu 64 16: modelo de lecturas"; cat "$TMP/cpu64.txt"
    fi
    if "$TMP/matmul_cpu" 100 16 | grep -q "fases=7"; then
        ok "matmul_cpu 100 16: ceil(100/16) = 7 fases"
    else
        bad "matmul_cpu 100 16: fases"
    fi
fi

echo "== (3) Espejos Numba en el simulador (NUMBA_ENABLE_CUDASIM=1) =="
run_numba() {  # nombre, código de salida esperado, patrón obligatorio en la salida, args...
    local name="$1" want="$2" pattern="$3"; shift 3
    python3 matmul_numba.py "$@" >"$TMP/out.txt" 2>&1; local rc=$?
    if [ "$rc" -eq "$want" ] && grep -q -- "$pattern" "$TMP/out.txt"; then
        ok "$name"
    else
        bad "$name (código $rc, esperado $want)"; cat "$TMP/out.txt"
    fi
}
run_numba "matmul_numba n=64 tile=16 (ingenua y mosaicos PASS)"            0 "csv,numba,64,16,sim,.*,PASS" --n 64 --tile 16
cp "$TMP/out.txt" "$TMP/numba64.txt"
run_numba "matmul_numba n=24 tile=8  (n multiplo, tile pequeño)"           0 ",PASS" --n 24 --tile 8
run_numba "matmul_numba n=20 tile=16 (n NO multiplo: un mosaico parcial)"  0 ",PASS" --n 20 --tile 16
run_numba "matmul_numba n=20 --grid-truncado FALLA sin error de CUDA"      1 "FAIL"  --n 20 --tile 16 --grid-truncado
run_numba "matmul_numba n=32 --sin-sync1 FALLA sin error de CUDA"          1 "FAIL"  --n 32 --tile 16 --sin-sync1 --solo mosaicos
if python3 transpose_numba.py --n 20 --tile 8 >"$TMP/out.txt" 2>&1 && grep -q "transpose_naive.*PASS" "$TMP/out.txt"; then
    ok "transpose_numba n=20 tile=8 (ingenua PASS; TODO(1) pendiente o PASS)"
else
    bad "transpose_numba n=20 tile=8"; cat "$TMP/out.txt"
fi

echo "== (4) Checksum CPU (C) vs simulador (Numba), n=64 =="
if [ -s "$TMP/cpu64.txt" ] && [ -s "$TMP/numba64.txt" ]; then
    c_sum=$(grep '^csv,cpu' "$TMP/cpu64.txt" | cut -d, -f6)
    p_sum=$(grep '^csv,numba' "$TMP/numba64.txt" | cut -d, -f6)
    if python3 -c "import sys; a,b=float(sys.argv[1]),float(sys.argv[2]); sys.exit(0 if abs(a-b)<=1e-3*max(1,abs(a)) else 1)" "$c_sum" "$p_sum"; then
        ok "checksum C=$c_sum vs Numba=$p_sum (tolerancia relativa 1e-3)"
    else
        bad "checksum C=$c_sum vs Numba=$p_sum"
    fi
else
    bad "checksum: faltan salidas previas"
fi

echo "== (5) Notebook de Colab =="
if python3 tests/check_notebook.py >"$TMP/out.txt" 2>&1; then
    ok "notebook_colab.ipynb válido (nbformat) y sincronizado con los fuentes"
else
    bad "notebook_colab.ipynb"; cat "$TMP/out.txt"
fi

echo "== Resumen: $pass PASS, $fail FAIL =="
[ "$fail" -eq 0 ]
