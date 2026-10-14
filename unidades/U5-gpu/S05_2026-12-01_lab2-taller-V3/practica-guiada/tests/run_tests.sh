#!/usr/bin/env bash
# run_tests.sh — Pruebas del mini PRIMM "aplanar y mapear" SIN GPU (y con GPU si la hay).
#
#  1. Los .cu compilan con nvcc -c (sm_75 y sm_60) y con -DSIN_GUARDIA.
#  2. La referencia CPU compila sin warnings (-Wall -Wextra) y da el checksum calculado a mano
#     (3x3, 1 iteración: centro = 0.25*(100+0+0+0) = 25 → checksum = 3*100 + 25 = 325).
#  3. El espejo Numba bajo CUDASIM pasa la verificación vs. NumPy, registra el hilo correcto para
#     (fila 3, col 5) con ancho 8 y bloques 16x16, y su checksum coincide con el de la referencia C.
#  4. Dimensiones no múltiplos del bloque (20x19 con 16x16): 2x2 bloques, 1024 hilos, 380 celdas.
#  5. Copiar en cada iteración da el mismo resultado (solo cambia el tiempo).
#  6. Modo 1d: PASS si TODO(1) está resuelto; SKIP si aún imprime "TODO pendiente".
#  7. Si hay GPU (nvidia-smi responde), compila el ejecutable y corre el caso 2d.
# Termina con código 0 solo si ningún caso falla. Duración típica sin GPU: < 30 s.
set -u
cd "$(dirname "$0")/.."

pass=0; fail=0; skip=0
ok()   { echo "PASS  $1"; pass=$((pass + 1)); }
ko()   { echo "FAIL  $1"; fail=$((fail + 1)); }
sk()   { echo "SKIP  $1"; skip=$((skip + 1)); }
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# --- 1. Compilación de los .cu -------------------------------------------------------------
if command -v nvcc >/dev/null 2>&1; then
    for arch in sm_75 sm_60; do
        if nvcc -c -arch=$arch flatten_map_2d.cu -o "$tmp/fm_$arch.o" >"$tmp/nvcc_$arch.log" 2>&1; then
            ok "nvcc -c -arch=$arch flatten_map_2d.cu"
        else
            ko "nvcc -c -arch=$arch flatten_map_2d.cu"; cat "$tmp/nvcc_$arch.log"
        fi
    done
    if nvcc -c -arch=sm_75 -DSIN_GUARDIA flatten_map_2d.cu -o "$tmp/fm_sg.o" >"$tmp/nvcc_sg.log" 2>&1; then
        ok "nvcc -c -DSIN_GUARDIA flatten_map_2d.cu (variante incorrecta a propósito)"
    else
        ko "nvcc -c -DSIN_GUARDIA flatten_map_2d.cu"; cat "$tmp/nvcc_sg.log"
    fi
else
    sk "nvcc no está instalado: la compilación de los .cu se verifica en Colab"
fi

# --- 2. Referencia CPU ---------------------------------------------------------------------
if gcc -std=c11 -O2 -Wall -Wextra flatten_map_cpu.c -o "$tmp/fm_cpu" >"$tmp/gcc.log" 2>&1 && [ ! -s "$tmp/gcc.log" ]; then
    ok "gcc -Wall -Wextra flatten_map_cpu.c sin warnings"
else
    ko "gcc flatten_map_cpu.c (errores o warnings):"; cat "$tmp/gcc.log"
fi
if [ -x "$tmp/fm_cpu" ]; then
    out="$("$tmp/fm_cpu" 3 3 1 1 1)"
    if grep -q "^checksum = 325.000000$" <<<"$out"; then
        ok "referencia CPU 3x3, 1 iteración: checksum 325 (cálculo a mano)"
    else
        ko "referencia CPU 3x3: checksum distinto de 325"; echo "$out"
    fi
    out_c="$("$tmp/fm_cpu" 10 8 3 3 5)"
    if grep -q "indice lineal de (fila 3, col 5) con ancho 8: 29" <<<"$out_c"; then
        ok "referencia CPU: índice lineal de (3,5) con ancho 8 es 29"
    else
        ko "referencia CPU: índice lineal de (3,5)"; echo "$out_c"
    fi
    chk_c="$(sed -n 's/^checksum = //p' <<<"$out_c")"
fi

# --- 3–6. Espejo Numba bajo CUDASIM ---------------------------------------------------------
if python3 -c "import numba, numpy" >/dev/null 2>&1; then
    export NUMBA_ENABLE_CUDASIM=1
    out="$(python3 flatten_map_numba.py 10 8 3 16 16 2d 0 3 5 2>&1)"; rc=$?
    if [ $rc -eq 0 ] && grep -q "verificacion vs CPU: PASS" <<<"$out"; then
        ok "CUDASIM 2d 10x8, 3 iteraciones: verificación vs NumPy"
    else
        ko "CUDASIM 2d 10x8: verificación"; echo "$out"
    fi
    if grep -q "hilo que la proceso: blockIdx=(0,0) threadIdx=(5,3) idx=29" <<<"$out"; then
        ok "CUDASIM 2d: (3,5) la procesa blockIdx=(0,0) threadIdx=(5,3), idx=29"
    else
        ko "CUDASIM 2d: registro del hilo de (3,5)"; echo "$out"
    fi
    chk_py="$(sed -n 's/^checksum = //p' <<<"$out")"
    if [ -n "${chk_c:-}" ] && [ -n "$chk_py" ] && \
       python3 -c "import sys; a=float(sys.argv[1]); b=float(sys.argv[2]); sys.exit(0 if abs(a-b) <= 1e-3*max(1.0,abs(a)) else 1)" "$chk_c" "$chk_py"; then
        ok "checksum CUDASIM ($chk_py) coincide con la referencia C ($chk_c)"
    else
        ko "checksum CUDASIM (${chk_py:-?}) vs referencia C (${chk_c:-?})"
    fi

    out="$(python3 flatten_map_numba.py 20 19 2 16 16 2d 0 3 5 2>&1)"; rc=$?
    if [ $rc -eq 0 ] && grep -q "verificacion vs CPU: PASS" <<<"$out" && \
       grep -q "malla 2D: bloques=2x2" <<<"$out" && grep -q "hilos lanzados=1024 celdas=380 hilos ociosos=644" <<<"$out"; then
        ok "CUDASIM 2d 20x19 (no múltiplo de 16): 2x2 bloques, 644 hilos ociosos, verificación"
    else
        ko "CUDASIM 2d 20x19 (no múltiplo)"; echo "$out"
    fi

    out="$(python3 flatten_map_numba.py 10 8 3 16 16 2d 1 3 5 2>&1)"; rc=$?
    if [ $rc -eq 0 ] && grep -q "verificacion vs CPU: PASS" <<<"$out"; then
        ok "CUDASIM 2d copiando en cada iteración: mismo resultado"
    else
        ko "CUDASIM 2d copiando en cada iteración"; echo "$out"
    fi

    out="$(python3 flatten_map_numba.py 10 8 3 16 16 1d 0 3 5 2>&1)"; rc=$?
    if grep -q "TODO pendiente" <<<"$out"; then
        sk "CUDASIM 1d: TODO(1) pendiente (fase Modificar); se prueba cuando lo completes"
    elif [ $rc -eq 0 ] && grep -q "verificacion vs CPU: PASS" <<<"$out" && \
         grep -q "hilo que la proceso: blockIdx=(0,0) threadIdx=(29,0) idx=29" <<<"$out"; then
        ok "CUDASIM 1d: TODO(1) resuelto, (3,5) la procesa threadIdx=29 del bloque 0, verificación"
    else
        ko "CUDASIM 1d: TODO(1) resuelto pero falla la verificación o el registro"; echo "$out"
    fi
    unset NUMBA_ENABLE_CUDASIM
else
    sk "numba/numpy no disponibles: el espejo Numba se verifica en Colab"
fi

# --- 7. Con GPU (Colab/Kaggle) --------------------------------------------------------------
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1 && command -v nvcc >/dev/null 2>&1; then
    if nvcc -O2 -arch="${ARCH:-sm_75}" flatten_map_2d.cu -o "$tmp/fm_gpu" >"$tmp/nvcc_gpu.log" 2>&1; then
        out="$(CPU_REPS=1 "$tmp/fm_gpu" 37 45 3 16 16 2d 0 3 5 2>&1)"; rc=$?
        if [ $rc -eq 0 ] && grep -q "verificacion vs CPU: PASS" <<<"$out"; then
            ok "GPU 2d 37x45 (no múltiplo): verificación"
        else
            ko "GPU 2d 37x45"; echo "$out"
        fi
        out="$(CPU_REPS=1 "$tmp/fm_gpu" 10 8 3 16 16 1d 0 3 5 2>&1)"; rc=$?
        if grep -q "TODO pendiente" <<<"$out"; then
            sk "GPU 1d: TODO(1) pendiente"
        elif [ $rc -eq 0 ] && grep -q "verificacion vs CPU: PASS" <<<"$out"; then
            ok "GPU 1d: TODO(1) resuelto, verificación"
        else
            ko "GPU 1d"; echo "$out"
        fi
    else
        ko "nvcc -O2 (ejecutable para GPU)"; cat "$tmp/nvcc_gpu.log"
    fi
else
    sk "sin GPU en esta máquina: la ejecución se prueba en Colab/Kaggle (make run)"
fi

echo "----"
echo "Resumen: $pass PASS · $fail FAIL · $skip SKIP"
[ "$fail" -eq 0 ]
