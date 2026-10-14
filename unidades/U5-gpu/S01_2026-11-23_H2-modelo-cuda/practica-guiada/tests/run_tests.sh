#!/usr/bin/env bash
# tests/run_tests.sh — Verificación SIN GPU de la práctica guiada S01 (Unidad V).
#
# Casos:
#   1. Los .cu compilan con nvcc -c para sm_75 (T4) y sm_60 (P100), incluida la variante -DSIN_GUARDIA.
#   2. La referencia CPU compila sin warnings (-Wall -Wextra -Werror) y se autoverifica.
#   3. El espejo Numba bajo CUDASIM da el mismo checksum que la CPU para n=1000/256, n=37/8 y n=1024/256.
#   4. Con grid insuficiente (3 bloques para n=1000) la verificación DEBE marcar FALLA.
#   5. Sin guardia, CUDASIM detecta el acceso fuera de rango (IndexError).
#   6. index_probe_numba bajo CUDASIM: cada índice 0..n-1 tiene exactamente un dueño; ociosos correctos.
#   7. notebook_colab.ipynb existe y es válido (nbformat).
#   8. Opcionales (fases Modificar/Crear): si existen saxpy.cu / saxpy_numba.py / dot_partial.cu /
#      dot_partial_numba.py, se compilan o se corren bajo CUDASIM y deben imprimir verificacion=OK.
# Imprime PASS/FAIL/SKIP por caso y termina con 0 solo si no hay FAIL.
set -u
cd "$(dirname "$0")/.." || exit 1

pass=0; fail=0; skip=0
ok() { echo "PASS  $1"; pass=$((pass + 1)); }
ko() { echo "FAIL  $1"; fail=$((fail + 1)); }
sk() { echo "SKIP  $1"; skip=$((skip + 1)); }

export NUMBA_ENABLE_CUDASIM=1
PY=${PY:-python3}
NVCC=${NVCC:-nvcc}
CC=${CC:-gcc}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ---------- 1. Compilación de los .cu ----------
if command -v "$NVCC" >/dev/null 2>&1; then
    for arch in sm_75 sm_60; do
        all_ok=1
        for src in vector_add.cu index_probe.cu; do
            "$NVCC" -O2 -arch=$arch -c "$src" -o "$TMP/${src%.cu}_$arch.o" >"$TMP/nvcc.log" 2>&1 || { all_ok=0; cat "$TMP/nvcc.log"; }
        done
        "$NVCC" -O2 -arch=$arch -DSIN_GUARDIA -c vector_add.cu -o "$TMP/sg_$arch.o" >"$TMP/nvcc.log" 2>&1 || { all_ok=0; cat "$TMP/nvcc.log"; }
        [ $all_ok -eq 1 ] && ok "nvcc -c -arch=$arch: vector_add.cu, index_probe.cu, -DSIN_GUARDIA" || ko "nvcc -c -arch=$arch"
    done
else
    sk "nvcc no está instalado: no se verifica la compilación de los .cu"
fi

# ---------- 2. Referencia CPU ----------
if "$CC" -std=c11 -O2 -Wall -Wextra -Werror vector_add_cpu.c -o "$TMP/vector_add_cpu" -lm 2>"$TMP/gcc.log"; then
    ok "gcc -Wall -Wextra -Werror vector_add_cpu.c (sin warnings)"
else
    cat "$TMP/gcc.log"; ko "gcc vector_add_cpu.c"
fi

cpu_checksum() { "$TMP/vector_add_cpu" "$1" | sed -n 's/.*checksum=\([0-9.]*\).*/\1/p'; }

out=$("$TMP/vector_add_cpu" 1000)
echo "$out" | grep -q "verificacion=OK" && ok "vector_add_cpu 1000 -> verificacion=OK" || ko "vector_add_cpu 1000"

# ---------- 3. Espejo Numba bajo CUDASIM vs. CPU ----------
for cfg in "1000 256" "37 8" "1024 256"; do
    set -- $cfg
    ref=$(cpu_checksum "$1")
    out=$($PY vector_add_numba.py "$1" "$2" 2>&1)
    sim=$(echo "$out" | sed -n 's/.*checksum=\([0-9.]*\).*/\1/p')
    if echo "$out" | grep -q "verificacion=OK" && $PY -c "import sys; a=float(sys.argv[1]); b=float(sys.argv[2]); sys.exit(0 if abs(a-b) <= 1e-6*max(1.0,abs(b)) else 1)" "$sim" "$ref"; then
        ok "CUDASIM vector_add_numba n=$1 block=$2 -> checksum=$sim igual a CPU ($ref)"
    else
        echo "$out"; ko "CUDASIM vector_add_numba n=$1 block=$2 (checksum sim=$sim, cpu=$ref)"
    fi
done

# ---------- 4. Grid insuficiente debe FALLAR la verificación ----------
out=$($PY vector_add_numba.py 1000 256 3 2>&1); rc=$?
if [ $rc -ne 0 ] && echo "$out" | grep -q "verificacion=FALLA"; then
    ok "CUDASIM grid=3 para n=1000 -> verificacion=FALLA (la verificación sí detecta elementos sin calcular)"
else
    echo "$out"; ko "CUDASIM grid=3 para n=1000 debía marcar FALLA"
fi

# ---------- 5. Sin guardia: el simulador detecta el acceso fuera de rango ----------
out=$($PY vector_add_numba.py 1000 256 0 --sin-guardia 2>&1); rc=$?
if [ $rc -ne 0 ] && echo "$out" | grep -q "IndexError"; then
    ok "CUDASIM --sin-guardia -> IndexError (acceso fuera del arreglo detectado)"
else
    echo "$out" | tail -5; ko "CUDASIM --sin-guardia debía terminar con IndexError"
fi

# ---------- 6. Sonda de índices ----------
for cfg in "10 4" "1000 256"; do
    set -- $cfg
    n=$1; block=$2; grid=$(( (n + block - 1) / block )); idle=$(( grid * block - n ))
    out=$($PY index_probe_numba.py "$n" "$block" 2>&1)
    owners=$(echo "$out" | grep -c '^i = [0-9]* <- bloque [0-9]*, hilo [0-9]*$')
    if [ "$owners" -eq "$n" ] && echo "$out" | grep -q "indices_sin_dueno=0" && echo "$out" | grep -q "grid=$grid " && echo "$out" | grep -q "ociosos=$idle"; then
        ok "CUDASIM index_probe n=$n block=$block -> $n índices con un dueño, grid=$grid, ociosos=$idle"
    else
        echo "$out" | tail -8; ko "CUDASIM index_probe n=$n block=$block"
    fi
done

# ---------- 7. Notebook válido ----------
if [ -f notebook_colab.ipynb ]; then
    if $PY - <<'PYEOF'
import nbformat, sys
nb = nbformat.read("notebook_colab.ipynb", as_version=4)
nbformat.validate(nb)
src = "\n".join(c.source for c in nb.cells)
need = ["nvidia-smi", "%%writefile vector_add.cu", "nvcc -O2 -arch=sm_75", "csv"]
missing = [s for s in need if s not in src]
if missing:
    print("faltan en el notebook:", missing); sys.exit(1)
PYEOF
    then ok "notebook_colab.ipynb válido (nbformat) y con celdas nvidia-smi / %%writefile / nvcc / CSV"
    else ko "notebook_colab.ipynb inválido o incompleto"; fi
else
    ko "notebook_colab.ipynb no existe (genera con: make notebook)"
fi

# ---------- 8. Opcionales: fases Modificar y Crear ----------
for base in saxpy dot_partial; do
    if [ -f "$base.cu" ]; then
        if command -v "$NVCC" >/dev/null 2>&1; then
            "$NVCC" -O2 -arch=sm_75 -c "$base.cu" -o "$TMP/$base.o" >"$TMP/nvcc.log" 2>&1 && ok "opcional: nvcc -c $base.cu" || { cat "$TMP/nvcc.log"; ko "opcional: nvcc -c $base.cu"; }
        else
            sk "opcional: $base.cu existe pero no hay nvcc"
        fi
    else
        sk "opcional: $base.cu no existe (fase Modificar/Crear)"
    fi
    if [ -f "${base}_numba.py" ]; then
        out=$($PY "${base}_numba.py" 1000 256 2>&1)
        echo "$out" | grep -q "verificacion=OK" && ok "opcional: CUDASIM ${base}_numba.py 1000 256 -> OK" || { echo "$out" | tail -5; ko "opcional: CUDASIM ${base}_numba.py"; }
    else
        sk "opcional: ${base}_numba.py no existe (fase Modificar/Crear)"
    fi
done

echo "------------------------------------------------------------"
echo "Resumen: PASS=$pass FAIL=$fail SKIP=$skip"
[ $fail -eq 0 ] && { echo "RESULTADO: PASS"; exit 0; } || { echo "RESULTADO: FAIL"; exit 1; }
