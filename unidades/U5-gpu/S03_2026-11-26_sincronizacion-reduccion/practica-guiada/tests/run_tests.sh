#!/usr/bin/env bash
# tests/run_tests.sh — Verificación SIN GPU de la práctica guiada S03 (Unidad V). Dura menos de 60 s.
#
# Casos:
#   1. reduce_sum.cu e histogram.cu compilan con nvcc -c para sm_75 (T4) y sm_60 (P100), sin warnings,
#      incluidas las variantes -DSIN_SYNC (Investigar) y -DBINS=256.
#   2. Las referencias CPU compilan sin warnings (-Wall -Wextra -Werror) y se autoverifican; la referencia
#      de la suma da ref_double=1457.600012 (n=1000) y 1520442.012500 (n=2^20) y el máximo 9.5 en i=n-1.
#   3. Espejo Numba de la reducción bajo CUDASIM: las tres versiones dan la referencia con n=1000/256
#      (n no potencia de 2, último bloque parcial), n=37/8 y block=128 con etapa 2 atómica; los parciales
#      del árbol coinciden bit a bit con la emulación en CPU; la suma coincide con la referencia en C.
#   4. Con block=96 (no potencia de 2) el árbol DEBE marcar FALLA sin error de CUDA (idea errónea 27).
#   5. Sin __syncthreads entre niveles (--sin-sync) el programa termina y reporta verificacion= (el resultado
#      concreto es no determinista; se imprime como información: "a veces sale bien").
#   6. Espejo Numba del histograma bajo CUDASIM: la versión global coincide EXACTAMENTE con la CPU
#      (n=4096/256 y n=2000/128, 16 y 256 bins); la versión shared imprime "TODO pendiente" (fase Crear) o,
#      si ya se completó, verificacion=OK. FALLA si imprime FALLA.
#   7. notebook_colab.ipynb existe y es válido (nbformat), con las celdas obligatorias.
#   8. Opcionales (fase Modificar): si existen reduce_max.cu / reduce_max_numba.py, se compilan o se corren bajo
#      CUDASIM y deben imprimir max=9.500000 y verificacion=OK.
# Imprime PASS/FAIL/SKIP/INFO por caso y termina con 0 solo si no hay FAIL.
set -u
cd "$(dirname "$0")/.." || exit 1

pass=0; fail=0; skip=0
ok() { echo "PASS  $1"; pass=$((pass + 1)); }
ko() { echo "FAIL  $1"; fail=$((fail + 1)); }
sk() { echo "SKIP  $1"; skip=$((skip + 1)); }

export NUMBA_ENABLE_CUDASIM=1
export PYTHONDONTWRITEBYTECODE=1
PY=${PY:-python3}
NVCC=${NVCC:-nvcc}
CC=${CC:-gcc}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

same_float() {  # same_float a b [tol_rel]
    $PY -c "import sys; a=float(sys.argv[1]); b=float(sys.argv[2]); t=float(sys.argv[3]) if len(sys.argv)>3 else 1e-9; sys.exit(0 if abs(a-b) <= t*max(1.0,abs(b)) else 1)" "$1" "$2" "${3:-1e-9}"
}

# ---------- 1. Compilación de los .cu ----------
if command -v "$NVCC" >/dev/null 2>&1; then
    for arch in sm_75 sm_60; do
        all_ok=1
        for src in reduce_sum.cu histogram.cu; do
            "$NVCC" -O2 -arch=$arch -Xcompiler -Wall,-Wextra -c "$src" -o "$TMP/${src%.cu}_$arch.o" >"$TMP/nvcc.log" 2>&1 || all_ok=0
            grep -qi "warning" "$TMP/nvcc.log" && all_ok=0
            [ $all_ok -eq 0 ] && cat "$TMP/nvcc.log"
        done
        [ $all_ok -eq 1 ] && ok "nvcc -c -arch=$arch reduce_sum.cu histogram.cu (sin errores ni warnings)" || ko "nvcc -c -arch=$arch"
    done
    if "$NVCC" -O2 -arch=sm_75 -DSIN_SYNC -c reduce_sum.cu -o "$TMP/ss.o" >"$TMP/nvcc.log" 2>&1 &&
       "$NVCC" -O2 -arch=sm_75 -DBINS=256 -c histogram.cu -o "$TMP/h256.o" >>"$TMP/nvcc.log" 2>&1; then
        ok "nvcc -c variantes: -DSIN_SYNC reduce_sum.cu, -DBINS=256 histogram.cu"
    else
        cat "$TMP/nvcc.log"; ko "nvcc -c variantes -DSIN_SYNC / -DBINS=256"
    fi
else
    sk "nvcc no está instalado: no se verifica la compilación de los .cu"
fi

# ---------- 2. Referencias CPU ----------
if "$CC" -std=c11 -O2 -Wall -Wextra -Werror reduce_sum_cpu.c -o "$TMP/reduce_sum_cpu" -lm 2>"$TMP/gcc.log" &&
   "$CC" -std=c11 -O2 -Wall -Wextra -Werror histogram_cpu.c -o "$TMP/histogram_cpu" 2>>"$TMP/gcc.log" &&
   "$CC" -std=c11 -O2 -Wall -Wextra -Werror -DBINS=256 histogram_cpu.c -o "$TMP/histogram_cpu256" 2>>"$TMP/gcc.log"; then
    ok "gcc -Wall -Wextra -Werror reduce_sum_cpu.c, histogram_cpu.c (16 y 256 bins): sin warnings"
else
    cat "$TMP/gcc.log"; ko "gcc referencias CPU"
fi

out=$("$TMP/reduce_sum_cpu" 1000 256 2>&1)
ref1000=$(echo "$out" | sed -n 's/^ref_double *=\([0-9.]*\).*/\1/p')
if echo "$out" | grep -q "verificacion=OK" && same_float "$ref1000" 1457.600012 1e-8 && echo "$out" | grep -q "max=9.500000 en i=999"; then
    ok "reduce_sum_cpu 1000 256 -> ref_double=$ref1000, max=9.5 en i=999, verificacion=OK"
else
    echo "$out"; ko "reduce_sum_cpu 1000 256"
fi
out=$("$TMP/reduce_sum_cpu" 1048576 256 2>&1)
ref1m=$(echo "$out" | sed -n 's/^ref_double *=\([0-9.]*\).*/\1/p')
if echo "$out" | grep -q "verificacion=OK" && same_float "$ref1m" 1520442.0125 1e-9 && echo "$out" | grep -q "atomic=1048576 .*atomic: 4096"; then
    ok "reduce_sum_cpu 2^20 256 -> ref_double=$ref1m, atómicas 1048576 / 0 / 4096, verificacion=OK"
else
    echo "$out"; ko "reduce_sum_cpu 2^20 256"
fi
out=$("$TMP/histogram_cpu" 4096 256 2>&1)
hist4096=$(echo "$out" | sed -n 's/^hist_cpu=\(.*\)$/\1/p')
if echo "$out" | grep -q "verificacion=OK" && [ "$hist4096" = "[1213,191,192,189,196,188,196,189,194,192,191,194,188,196,190,197]" ]; then
    ok "histogram_cpu 4096 256 -> hist_cpu=$hist4096"
else
    echo "$out"; ko "histogram_cpu 4096 256"
fi

# ---------- 3. Espejo Numba de la reducción bajo CUDASIM ----------
out=$($PY reduce_sum_numba.py all 1000 256 2>&1); rc=$?
n_ok=$(echo "$out" | grep -c "verificacion=OK")
n_bit=$(echo "$out" | grep -c "parciales_bit_a_bit_igual_a_emulacion_cpu=si")
sum_tree=$(echo "$out" | awk '/version=tree_nodiv/{getline; print}' | sed -n 's/.*suma=\([0-9.]*\).*/\1/p')
if [ $rc -eq 0 ] && [ "$n_ok" -eq 3 ] && [ "$n_bit" -eq 2 ] && same_float "$sum_tree" "$ref1000" 1e-4; then
    ok "CUDASIM reduce_sum_numba all 1000 256 -> 3 versiones OK; árboles bit a bit = emulación; suma=$sum_tree ≈ ref C $ref1000"
else
    echo "$out"; ko "CUDASIM reduce_sum_numba all 1000 256 (rc=$rc, OK=$n_ok, bit=$n_bit)"
fi
out=$($PY reduce_sum_numba.py all 37 8 2>&1); rc=$?
if [ $rc -eq 0 ] && [ "$(echo "$out" | grep -c 'verificacion=OK')" -eq 3 ] && echo "$out" | grep -q "referencia_cpu_double=60.500000"; then
    ok "CUDASIM reduce_sum_numba all 37 8 -> 5 bloques, último parcial, ref=60.5, 3 versiones OK"
else
    echo "$out"; ko "CUDASIM reduce_sum_numba all 37 8"
fi
out=$($PY reduce_sum_numba.py tree_nodiv 1000 128 --etapa2 atomic 2>&1); rc=$?
if [ $rc -eq 0 ] && echo "$out" | grep -q "atomicas_globales=8 " && echo "$out" | grep -q "verificacion=OK"; then
    ok "CUDASIM reduce_sum_numba tree_nodiv 1000 128 --etapa2 atomic -> 8 atómicas (una por bloque), OK"
else
    echo "$out"; ko "CUDASIM reduce_sum_numba tree_nodiv 1000 128 --etapa2 atomic"
fi

# ---------- 4. block no potencia de 2: el árbol pierde sumandos y la verificación lo detecta ----------
out=$($PY reduce_sum_numba.py tree_nodiv 1000 96 2>&1); rc=$?
if [ $rc -ne 0 ] && echo "$out" | grep -q "verificacion=FALLA" && echo "$out" | grep -q "aviso: el árbol supone block potencia de 2"; then
    ok "CUDASIM tree_nodiv 1000 96 -> verificacion=FALLA sin error de CUDA (la comparación con la CPU sí lo detecta)"
else
    echo "$out"; ko "CUDASIM tree_nodiv 1000 96 debía marcar FALLA"
fi

# ---------- 5. Sin __syncthreads entre niveles: carrera deliberada (resultado no determinista) ----------
out=$($PY reduce_sum_numba.py tree_div 1000 256 --sin-sync 2>&1); rc=$?
line=$(echo "$out" | grep -o "suma=[0-9.]* err_rel=[0-9.e+-]* verificacion=[A-Z]*")
if [ -n "$line" ] && { [ $rc -eq 0 ] || [ $rc -eq 2 ]; }; then
    ok "CUDASIM tree_div 1000 256 --sin-sync termina y reporta: $line"
    echo "INFO  (en el simulador casi siempre FALLA; en la GPU con block=32 'a veces sale bien': por eso es peligroso)"
else
    echo "$out"; ko "CUDASIM tree_div --sin-sync no terminó correctamente (rc=$rc)"
fi

# ---------- 6. Espejo Numba del histograma bajo CUDASIM ----------
for cfg in "4096 256" "2000 128"; do
    set -- $cfg
    ref=$("$TMP/histogram_cpu" "$1" "$2" | sed -n 's/^hist_cpu=\(.*\)$/\1/p')
    out=$($PY histogram_numba.py global "$1" "$2" 2>&1); rc=$?
    got=$(echo "$out" | sed -n 's/^ *hist_gpu=\(.*\)$/\1/p')
    if [ $rc -eq 0 ] && echo "$out" | grep -q "verificacion=OK" && [ "$got" = "$ref" ]; then
        ok "CUDASIM histogram_numba global $1 $2 -> idéntico a histogram_cpu ($ref)"
    else
        echo "$out"; ko "CUDASIM histogram_numba global $1 $2 (gpu=$got, cpu=$ref)"
    fi
done
ref=$("$TMP/histogram_cpu256" 4096 256 | sed -n 's/^hist_cpu=\(.*\)$/\1/p')
out=$($PY histogram_numba.py global 4096 256 --bins 256 2>&1); rc=$?
got=$(echo "$out" | sed -n 's/^ *hist_gpu=\(.*\)$/\1/p')
if [ $rc -eq 0 ] && [ "$got" = "$ref" ]; then
    ok "CUDASIM histogram_numba global 4096 256 --bins 256 -> idéntico a histogram_cpu -DBINS=256"
else
    echo "$out" | head -3; ko "CUDASIM histogram_numba --bins 256"
fi
out=$($PY histogram_numba.py shared 4096 256 2>&1); rc=$?
if echo "$out" | grep -q "TODO pendiente"; then
    ok "CUDASIM histogram_numba shared 4096 256 -> TODO pendiente (fase Crear sin completar; no es error)"
elif [ $rc -eq 0 ] && echo "$out" | grep -q "verificacion=OK"; then
    ok "CUDASIM histogram_numba shared 4096 256 -> verificacion=OK (TODO(1) completado)"
else
    echo "$out"; ko "CUDASIM histogram_numba shared 4096 256 -> FALLA (el TODO(1) está mal)"
fi

# ---------- 7. Notebook válido ----------
if [ -f notebook_colab.ipynb ]; then
    if $PY - <<'PYEOF'
import nbformat, sys
nb = nbformat.read("notebook_colab.ipynb", as_version=4)
nbformat.validate(nb)
src = "\n".join(c.source for c in nb.cells)
need = ["nvidia-smi", "%%writefile reduce_sum.cu", "%%writefile histogram.cu", "%%writefile reduce_sum_numba.py",
        "nvcc -O2 -arch=sm_75", "./reduce_sum", "./histogram", "-DSIN_SYNC", "csv"]
missing = [s for s in need if s not in src]
if missing:
    print("faltan en el notebook:", missing); sys.exit(1)
PYEOF
    then ok "notebook_colab.ipynb válido (nbformat) y con celdas nvidia-smi / %%writefile / nvcc / ejecución / medición / CSV"
    else ko "notebook_colab.ipynb inválido o incompleto"; fi
else
    ko "notebook_colab.ipynb no existe (genera con: make notebook)"
fi

# ---------- 8. Opcional: fase Modificar (reducción max) ----------
if [ -f reduce_max.cu ]; then
    if command -v "$NVCC" >/dev/null 2>&1; then
        "$NVCC" -O2 -arch=sm_75 -c reduce_max.cu -o "$TMP/reduce_max.o" >"$TMP/nvcc.log" 2>&1 && ok "opcional: nvcc -c reduce_max.cu" || { cat "$TMP/nvcc.log"; ko "opcional: nvcc -c reduce_max.cu"; }
    else
        sk "opcional: reduce_max.cu existe pero no hay nvcc"
    fi
else
    sk "opcional: reduce_max.cu no existe (fase Modificar)"
fi
if [ -f reduce_max_numba.py ]; then
    out=$($PY reduce_max_numba.py tree_nodiv 1000 256 2>&1)
    echo "$out" | grep -q "max=9.500000" && echo "$out" | grep -q "verificacion=OK" && ok "opcional: CUDASIM reduce_max_numba.py 1000 256 -> max=9.5 OK" || { echo "$out" | tail -5; ko "opcional: CUDASIM reduce_max_numba.py"; }
else
    sk "opcional: reduce_max_numba.py no existe (fase Modificar)"
fi

echo "------------------------------------------------------------"
echo "Resumen: PASS=$pass FAIL=$fail SKIP=$skip"
[ $fail -eq 0 ] && { echo "RESULTADO: PASS"; exit 0; } || { echo "RESULTADO: FAIL"; exit 1; }
