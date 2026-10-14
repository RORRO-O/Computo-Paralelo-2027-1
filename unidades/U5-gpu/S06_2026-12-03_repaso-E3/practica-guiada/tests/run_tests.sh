#!/usr/bin/env bash
# tests/run_tests.sh — Verificación SIN GPU del cazador de errores (S06 · Unidad V · 6BM1 · 27/1).
#
# Uso:  bash tests/run_tests.sh          (= make test)   todo, en menos de 60 s
#       bash tests/run_tests.sh cazar    (= make cazar)  solo tus archivos: pasa cuando los tres errores están corregidos
#
# Modo "todo" (el material tal como se entrega debe pasar):
#   A. Compilación: cada .cu con nvcc -c para sm_75 (T4) y sm_60 (P100) sin errores ni warnings; los .c con
#      gcc/mpicc -std=c11 -O2 -Wall -Wextra -Werror.
#   B. Referencia CPU: caza_cpu imprime los valores de referencia fijados.
#   C. Cazador 1 (MPI): el *_buggy SE INTERBLOQUEA con 4 procesos (timeout, código 124), "funciona" con 1, y la
#      solución da la media correcta con 4 y con 3 procesos (n con residuo).
#   D. Cazador 2 (CUDASIM): el espejo *_buggy altera los 24 centinelas con n=1000, no altera nada con n=1024
#      (error enmascarado), y la solución pasa con n=1000 y con n=37/bloque 8.
#   E. Cazador 3 (CUDASIM): el espejo *_buggy da una suma incorrecta (se ejecuta dos veces) y la solución da la
#      suma exacta con bloques de 256 y de 64.
#   F. Ejemplo resuelto: ejemplo_predict_mpi imprime la salida de ejemplo-resuelto.md; ejemplo_grid_numba deja
#      232 elementos sin procesar y, con --corregido, pasa.
#   G. Ítems del examen de práctica: las salidas coinciden con la clave de examen-practica-U4-U5.md.
#   H. notebook_colab.ipynb es válido (nbformat) y tiene las celdas obligatorias.
# Imprime PASS/FAIL/SKIP por caso; código de salida 0 solo si no hay FAIL.
set -u
cd "$(dirname "$0")/.." || exit 1
MODE=${1:-todo}
OUT=tests/out
rm -rf "$OUT" && mkdir -p "$OUT/soluciones" "$OUT/examen_items"

if [ "$(id -u)" -eq 0 ]; then
    export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
fi
export NUMBA_ENABLE_CUDASIM=1
MPIRUN_FLAGS=${MPIRUN_FLAGS:---oversubscribe}
TIMEOUT=${TIMEOUT:-5}
NVCC=${NVCC:-nvcc}
CC=${CC:-gcc}
MPICC=${MPICC:-mpicc}
PY=${PY:-python3}
CFLAGS="-std=c11 -O2 -Wall -Wextra -Werror"

pass=0; fail=0; skip=0
ok() { echo "PASS  $1"; pass=$((pass + 1)); }
ko() { echo "FAIL  $1${2:+   ($2)}"; fail=$((fail + 1)); }
sk() { echo "SKIP  $1"; skip=$((skip + 1)); }
has_nvcc() { command -v "$NVCC" >/dev/null 2>&1; }

# nvcc_all <arch>: compila todos los .cu a objeto; falla si hay error o cualquier "warning" en el log.
nvcc_all() {
    local arch=$1 rc=0 log="$OUT/nvcc_$arch.log"
    : > "$log"
    for src in caza2_guard_buggy.cu caza3_reduce_buggy.cu ejemplo_grid.cu examen_items/item_II2_reverse.cu \
               soluciones/caza2_guard_fixed.cu soluciones/caza3_reduce_fixed.cu; do
        "$NVCC" -c -arch="$arch" "$src" -o "$OUT/${src%.cu}_$arch.o" >>"$log" 2>&1 || rc=1
    done
    "$NVCC" -c -arch="$arch" -DCORREGIDO ejemplo_grid.cu -o "$OUT/ejemplo_grid_ok_$arch.o" >>"$log" 2>&1 || rc=1
    grep -qi "warning" "$log" && rc=2
    return $rc
}

# mpi_run <np> <timeout> <bin> [args]: ejecuta y deja la salida en $OUT/last.txt; regresa el código de salida.
mpi_run() {
    local np=$1 to=$2; shift 2
    timeout -k 2 "$to" mpirun $MPIRUN_FLAGS -np "$np" "$@" >"$OUT/last.txt" 2>&1
}

# ---------------------------------------------------------------- modo cazar (lo que corrige el estudiante)
if [ "$MODE" = "cazar" ]; then
    echo "== make cazar: tus tres archivos (sin GPU: MPI con timeout, CUDA en CUDASIM)"
    caught=0
    # 1. MPI
    if "$MPICC" $CFLAGS caza1_bcast_buggy.c -o "$OUT/caza1" >"$OUT/mpicc.log" 2>&1; then
        ok "caza1_bcast_buggy.c compila sin warnings"
        c1=1
        if mpi_run 4 "$TIMEOUT" "$OUT/caza1" 1000 && grep -q "media=3.497000" "$OUT/last.txt"; then
            ok "caza1 con 4 procesos termina y da media=3.497000"
        else
            c1=0; ko "caza1 con 4 procesos" "$( [ $? -eq 124 ] && echo 'sigue interbloqueado: ¿quién llama a MPI_Bcast?' || tail -1 "$OUT/last.txt")"
        fi
        if mpi_run 3 "$TIMEOUT" "$OUT/caza1" 10007 && grep -q "media=3.499400" "$OUT/last.txt"; then
            ok "caza1 con 3 procesos y n=10007 (residuo) da media=3.499400"
        else
            c1=0; ko "caza1 con 3 procesos y n=10007" "$(tail -1 "$OUT/last.txt")"
        fi
        caught=$((caught + c1))
    else
        cat "$OUT/mpicc.log"; ko "caza1_bcast_buggy.c compila"
    fi
    # 2. CUDA: guardia
    c2=1
    for cfg in "1000 256" "37 8"; do
        set -- $cfg
        if "$PY" caza2_guard_numba.py "$1" "$2" >"$OUT/last.txt" 2>&1 && grep -q "verificacion=OK" "$OUT/last.txt"; then
            ok "caza2_guard_numba.py $1 $2 en CUDASIM: verificacion=OK"
        else
            c2=0; ko "caza2_guard_numba.py $1 $2 en CUDASIM" "$(grep -E 'centinelas|Error' "$OUT/last.txt" | tail -1)"
        fi
    done
    caught=$((caught + c2))
    # 3. CUDA: reducción (dos veces: una carrera puede salir bien por casualidad)
    c3=1
    for cfg in "1000 256" "1000 256" "1000 64"; do
        set -- $cfg
        if "$PY" caza3_reduce_numba.py "$1" "$2" >"$OUT/last.txt" 2>&1 && grep -q "verificacion=OK" "$OUT/last.txt"; then
            ok "caza3_reduce_numba.py $1 $2 en CUDASIM: verificacion=OK"
        else
            c3=0; ko "caza3_reduce_numba.py $1 $2 en CUDASIM" "$(grep -E 'suma_gpu|Error' "$OUT/last.txt" | tail -1)"
        fi
    done
    caught=$((caught + c3))
    # 4. Los .cu corregidos deben seguir compilando (la verificación de su lógica es el espejo Numba o Colab).
    if has_nvcc; then
        if "$NVCC" -c -arch=sm_75 caza2_guard_buggy.cu -o "$OUT/c2.o" >"$OUT/nvcc.log" 2>&1 \
           && "$NVCC" -c -arch=sm_75 caza3_reduce_buggy.cu -o "$OUT/c3.o" >>"$OUT/nvcc.log" 2>&1; then
            ok "caza2_guard_buggy.cu y caza3_reduce_buggy.cu compilan con nvcc -c"
        else
            cat "$OUT/nvcc.log"; ko "los .cu compilan"
        fi
    else
        sk "nvcc no está instalado: los .cu se verifican en Colab"
    fi
    echo "---- bichos cazados: $caught/3   ($pass PASS, $fail FAIL, $skip SKIP)"
    [ $fail -eq 0 ] && rm -rf "$OUT"
    [ $fail -eq 0 ]
    exit $?
fi

# ---------------------------------------------------------------- modo todo
# A. Compilación
if has_nvcc; then
    for arch in sm_75 sm_60; do
        nvcc_all "$arch"; rc=$?
        if [ $rc -eq 0 ]; then ok "nvcc -c -arch=$arch: 6 archivos .cu + ejemplo_grid -DCORREGIDO (sin warnings)"
        else sed -n 1,10p "$OUT/nvcc_$arch.log"; ko "nvcc -c -arch=$arch" "$( [ $rc -eq 2 ] && echo warnings || echo error)"; fi
    done
else
    sk "nvcc no está instalado: no se verifica la compilación de los .cu"
fi
if "$CC" $CFLAGS caza_cpu.c -o "$OUT/caza_cpu" >"$OUT/gcc.log" 2>&1; then ok "gcc $CFLAGS caza_cpu.c"; else cat "$OUT/gcc.log"; ko "gcc caza_cpu.c"; fi
mpi_ok=1
for src in caza1_bcast_buggy soluciones/caza1_bcast_fixed ejemplo_predict_mpi examen_items/item_II1_mpi examen_items/item_IV_dot_mpi; do
    "$MPICC" $CFLAGS "$src.c" -o "$OUT/$src" >>"$OUT/mpicc.log" 2>&1 || mpi_ok=0
done
if [ $mpi_ok -eq 1 ]; then ok "mpicc $CFLAGS: 5 programas MPI"; else cat "$OUT/mpicc.log"; ko "mpicc: algún programa MPI no compila"; fi

# B. Referencia CPU
"$OUT/caza_cpu" todo 1000 >"$OUT/cpu.txt" 2>&1
if grep -q "media=3.497000" "$OUT/cpu.txt" && grep -q "checksum=6994.0" "$OUT/cpu.txt" \
   && grep -q "suma=5500.0" "$OUT/cpu.txt" && grep -q "checksum=1998.5" "$OUT/cpu.txt"; then
    ok "caza_cpu todo 1000: media=3.497000, checksum=6994.0, suma=5500.0, checksum=1998.5"
else cat "$OUT/cpu.txt"; ko "caza_cpu todo 1000: valores de referencia"; fi

# C. Cazador 1 (MPI)
if [ $mpi_ok -eq 1 ]; then
    mpi_run 4 "$TIMEOUT" "$OUT/caza1_bcast_buggy" 1000; rc=$?
    if [ $rc -eq 124 ]; then ok "caza1_bcast_buggy con 4 procesos: se reproduce el interbloqueo (timeout ${TIMEOUT}s, código 124)"
    else ko "caza1_bcast_buggy con 4 procesos debía interbloquearse" "código $rc: $(tail -1 "$OUT/last.txt")"; fi
    if mpi_run 1 "$TIMEOUT" "$OUT/caza1_bcast_buggy" 1000 && grep -q "media=3.497000" "$OUT/last.txt"; then
        ok "caza1_bcast_buggy con 1 proceso: 'funciona' (media=3.497000) — no es evidencia"
    else ko "caza1_bcast_buggy con 1 proceso" "$(tail -1 "$OUT/last.txt")"; fi
    if mpi_run 4 "$TIMEOUT" "$OUT/soluciones/caza1_bcast_fixed" 1000 && grep -q "procesos=4 media=3.497000" "$OUT/last.txt" \
       && mpi_run 3 "$TIMEOUT" "$OUT/soluciones/caza1_bcast_fixed" 10007 && grep -q "procesos=3 media=3.499400" "$OUT/last.txt"; then
        ok "soluciones/caza1_bcast_fixed: 4 procesos (n=1000) y 3 procesos (n=10007, residuo) correctos"
    else ko "soluciones/caza1_bcast_fixed" "$(tail -1 "$OUT/last.txt")"; fi
fi

# D. Cazador 2 (CUDASIM)
"$PY" caza2_guard_numba.py 1000 256 >"$OUT/c2_buggy.txt" 2>&1; rc=$?
if [ $rc -eq 2 ] && grep -q "centinelas_alterados=24 (de 24)" "$OUT/c2_buggy.txt" && grep -q "verificacion=FALLA" "$OUT/c2_buggy.txt"; then
    ok "caza2_guard_numba (con error) n=1000: 24 centinelas alterados, verificacion=FALLA, código 2"
else cat "$OUT/c2_buggy.txt"; ko "caza2_guard_numba (con error) n=1000 debía fallar" "código $rc"; fi
if "$PY" caza2_guard_numba.py 1024 256 >"$OUT/c2_mask.txt" 2>&1 && grep -q "sobrantes=0" "$OUT/c2_mask.txt" && grep -q "verificacion=OK" "$OUT/c2_mask.txt"; then
    ok "caza2_guard_numba (con error) n=1024: sin sobrantes, 'sale bien' (error enmascarado)"
else cat "$OUT/c2_mask.txt"; ko "caza2_guard_numba n=1024 debía pasar"; fi
if "$PY" soluciones/caza2_guard_fixed_numba.py 1000 256 >"$OUT/c2_fix.txt" 2>&1 && grep -q "checksum=6994.0" "$OUT/c2_fix.txt" && grep -q "verificacion=OK" "$OUT/c2_fix.txt" \
   && "$PY" soluciones/caza2_guard_fixed_numba.py 37 8 >>"$OUT/c2_fix.txt" 2>&1 && grep -q "sobrantes=3" "$OUT/c2_fix.txt"; then
    ok "soluciones/caza2_guard_fixed_numba: n=1000/256 (checksum=6994.0) y n=37/8 correctos"
else cat "$OUT/c2_fix.txt"; ko "soluciones/caza2_guard_fixed_numba"; fi

# E. Cazador 3 (CUDASIM)
falla=0
for i in 1 2; do "$PY" caza3_reduce_numba.py 1000 >"$OUT/c3_buggy_$i.txt" 2>&1; grep -q "verificacion=FALLA" "$OUT/c3_buggy_$i.txt" && falla=$((falla + 1)); done
if [ $falla -ge 1 ]; then ok "caza3_reduce_numba (con error) n=1000: suma incorrecta en $falla de 2 corridas ($(grep -h suma_gpu "$OUT"/c3_buggy_*.txt | cut -d' ' -f1 | tr '\n' ' '))"
else cat "$OUT/c3_buggy_1.txt"; ko "caza3_reduce_numba (con error) debía dar una suma incorrecta"; fi
if "$PY" soluciones/caza3_reduce_fixed_numba.py 1000 >"$OUT/c3_fix.txt" 2>&1 && grep -q "suma_gpu=5500.0 suma_cpu=5500.0" "$OUT/c3_fix.txt" && grep -q "verificacion=OK" "$OUT/c3_fix.txt" \
   && "$PY" soluciones/caza3_reduce_fixed_numba.py 1000 64 >>"$OUT/c3_fix.txt" 2>&1 && grep -q "grid=16" "$OUT/c3_fix.txt"; then
    ok "soluciones/caza3_reduce_fixed_numba: suma=5500.0 con bloques de 256 (grid=4) y de 64 (grid=16)"
else cat "$OUT/c3_fix.txt"; ko "soluciones/caza3_reduce_fixed_numba"; fi

# F. Ejemplo resuelto
if [ $mpi_ok -eq 1 ]; then
    if mpi_run 4 "$TIMEOUT" "$OUT/ejemplo_predict_mpi" && grep -q "^result=0 0 3 4 10 12 21 24$" "$OUT/last.txt" \
       && [ "$(grep -c 'total=36$' "$OUT/last.txt")" = 4 ] && grep -q "rango 2: local_sum=11" "$OUT/last.txt"; then
        ok "ejemplo_predict_mpi: result=0 0 3 4 10 12 21 24; total=36 en los 4 rangos"
    else cat "$OUT/last.txt"; ko "ejemplo_predict_mpi"; fi
fi
if "$PY" ejemplo_grid_numba.py 1000 256 >"$OUT/eg.txt" 2>&1; then ko "ejemplo_grid_numba (grid = n/block) debía fallar"
elif grep -q "elementos_sin_procesar=232" "$OUT/eg.txt" && "$PY" ejemplo_grid_numba.py 1000 256 --corregido >"$OUT/eg_ok.txt" 2>&1 && grep -q "checksum=1998.5" "$OUT/eg_ok.txt"; then
    ok "ejemplo_grid_numba: 232 sin procesar con grid=3; --corregido pasa con checksum=1998.5"
else cat "$OUT/eg.txt" "$OUT/eg_ok.txt" 2>/dev/null; ko "ejemplo_grid_numba"; fi

# G. Ítems del examen de práctica (salidas fijadas en la clave)
if [ $mpi_ok -eq 1 ]; then
    expected=$'rango 0: value=1 total=10 from_left=4 max_root=4\nrango 1: value=2 total=10 from_left=1 max_root=0\nrango 2: value=3 total=10 from_left=2 max_root=0\nrango 3: value=4 total=10 from_left=3 max_root=0'
    mpi_run 4 "$TIMEOUT" "$OUT/examen_items/item_II1_mpi"
    if [ "$(sort "$OUT/last.txt")" = "$expected" ] && mpi_run 1 "$TIMEOUT" "$OUT/examen_items/item_II1_mpi" \
       && grep -q "^rango 0: value=1 total=1 from_left=1 max_root=1$" "$OUT/last.txt"; then
        ok "item II.1 (MPI): las 4 líneas de la clave (en cualquier orden) y la salida con -np 1"
    else cat "$OUT/last.txt"; ko "item II.1 (MPI)"; fi
    if mpi_run 4 "$TIMEOUT" "$OUT/examen_items/item_IV_dot_mpi" && grep -q "^dot=36.000000$" "$OUT/last.txt" \
       && mpi_run 2 "$TIMEOUT" "$OUT/examen_items/item_IV_dot_mpi" && grep -q "^dot=36.000000$" "$OUT/last.txt"; then
        ok "item IV(a) (MPI, huecos llenos): dot=36.000000 con 4 y con 2 procesos"
    else cat "$OUT/last.txt"; ko "item IV(a) (MPI)"; fi
fi
if [ "$("$PY" examen_items/item_II2_reverse_numba.py 2>"$OUT/ii2.err")" = "3 2 1 0 7 6 5 4 8 9" ]; then
    ok "item II.2 (kernel, CUDASIM): 3 2 1 0 7 6 5 4 8 9"
else cat "$OUT/ii2.err"; ko "item II.2 (kernel, CUDASIM)"; fi

# H. Notebook
"$PY" - >"$OUT/nb.log" 2>&1 <<'PYEOF'
import nbformat
nb = nbformat.read("notebook_colab.ipynb", as_version=4)
nbformat.validate(nb)
src = "\n".join(c.source for c in nb.cells if c.cell_type == "code")
for needle in ("!nvidia-smi", "%%writefile caza2_guard_buggy.cu", "%%writefile caza3_reduce_buggy.cu",
               "%%writefile caza_cpu.c", "%%writefile caza1_bcast_buggy.c", "nvcc -O2 -arch=sm_75",
               "./caza2_guard_buggy 1000 256", "./caza2_guard_buggy 1024 256", "./caza3_reduce_buggy 1000",
               "NUMBA_ENABLE_CUDASIM=1", "t_kernel_ms", "resultados_S06_", "csv"):
    assert needle in src, needle
print("notebook OK:", len(nb.cells), "celdas")
PYEOF
if [ $? -eq 0 ]; then ok "notebook_colab.ipynb válido (nbformat) con las celdas obligatorias"; else cat "$OUT/nb.log"; ko "notebook_colab.ipynb"; fi

echo "---- $pass PASS, $fail FAIL, $skip SKIP"
if [ $fail -eq 0 ]; then rm -rf "$OUT"; exit 0; fi
exit 1
