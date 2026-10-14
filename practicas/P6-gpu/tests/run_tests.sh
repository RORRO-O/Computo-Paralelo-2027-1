#!/usr/bin/env bash
# tests/run_tests.sh — Verificación SIN GPU de la Práctica 6 (termina en < 60 s).
#
# Uso:   bash tests/run_tests.sh [all|A|B|C|D]        (make test = all · make test-b = B)
#
# Qué comprueba:
#   1. Todos los src/*.cu compilan con nvcc -c para sm_75 (T4) y sm_60 (P100), sin errores ni warnings;
#      b_matmul_tiled.cu también con -DTILE=8 y -DTILE=32.
#   2. Las referencias CPU compilan con gcc -std=c11 -O2 -Wall -Wextra -Werror y dan los valores conocidos.
#   3. Parte A: el espejo Numba bajo NUMBA_ENABLE_CUDASIM=1 pasa su verificación y su checksum coincide con la CPU.
#   4. Parte B: el espejo Numba (mismos TODO que el .cu) pasa para n=32 y n=20 (no múltiplo de TILE) y su
#      checksum coincide con b_matmul_cpu. Mientras los TODO estén pendientes el programa imprime "TODO pendiente":
#      esos casos se reportan como PEND y no cuentan como FAIL en `make test`; en `make test-b` (STRICT_B=1) cuentan
#      como FAIL hasta que completes TODO(1)–TODO(4). Un TODO mal resuelto siempre es FAIL.
#   5. Parte C: las referencias CPU dan los valores conocidos; si existen espejos src/c_*_numba.py se corren en
#      CUDASIM y deben imprimir verificacion=OK (SKIP si no hay: la Parte C es diseño propio).
#   6. Parte D: graficar.py produce las tres PNG a partir de un CSV de prueba, y de resultados/*.csv si ya existen.
#   7. notebook_colab.ipynb es válido (nbformat) y sus celdas %%writefile coinciden con los fuentes.
# Variables: STRICT_B=1 (PEND cuenta como FAIL), EXTRA=1 (casos extra de calificación; los usa el profesor).
# Imprime PASS/FAIL/PEND/SKIP por caso; código de salida 0 solo si no hay FAIL.
set -u
cd "$(dirname "$0")/.." || exit 1
PART=${1:-all}
STRICT_B=${STRICT_B:-0}
[ "$PART" = "B" ] && STRICT_B=1
EXTRA=${EXTRA:-0}
OUT=tests/out
rm -rf "$OUT" && mkdir -p "$OUT"
export NUMBA_ENABLE_CUDASIM=1 PYTHONDONTWRITEBYTECODE=1 MPLBACKEND=Agg
PY=${PY:-python3}
NVCC=${NVCC:-nvcc}
CC=${CC:-gcc}
pass=0; fail=0; pend=0; skip=0
ok()   { echo "PASS  $1"; pass=$((pass + 1)); }
ko()   { echo "FAIL  $1"; fail=$((fail + 1)); }
pd()   { if [ "$STRICT_B" = "1" ]; then echo "FAIL  $1 (TODO pendiente; STRICT_B=1)"; fail=$((fail + 1)); else echo "PEND  $1"; pend=$((pend + 1)); fi; }
sk()   { echo "SKIP  $1"; skip=$((skip + 1)); }
want() { case "$PART" in all) return 0 ;; *) [ "$PART" = "$1" ] ;; esac; }
# Compara dos números con tolerancia relativa: close a b tol
close() { $PY -c "import sys; a,b,t=float(sys.argv[1]),float(sys.argv[2]),float(sys.argv[3]); sys.exit(0 if abs(a-b)<=t*max(1.0,abs(b)) else 1)" "$1" "$2" "$3"; }
grab() { sed -n "s/.*$1=\([-0-9.e+]*\).*/\1/p" | head -1; }  # grab clave < archivo

# ---------- 1. Compilación CUDA (sin GPU): todos los .cu, dos arquitecturas, en paralelo ----------
if want A || want B || want C; then
    if command -v "$NVCC" >/dev/null 2>&1; then
        for src in src/*.cu; do
            base=$(basename "$src" .cu)
            for arch in sm_75 sm_60; do
                ( "$NVCC" -c -O2 -arch=$arch "$src" -o "$OUT/${base}_$arch.o" >"$OUT/nvcc_${base}_$arch.log" 2>&1; echo $? >"$OUT/nvcc_${base}_$arch.rc" ) &
            done
        done
        ( "$NVCC" -c -O2 -arch=sm_75 -DTILE=8  src/b_matmul_tiled.cu -o "$OUT/t8.o"  >"$OUT/nvcc_t8.log"  2>&1; echo $? >"$OUT/nvcc_t8.rc" ) &
        ( "$NVCC" -c -O2 -arch=sm_75 -DTILE=32 src/b_matmul_tiled.cu -o "$OUT/t32.o" >"$OUT/nvcc_t32.log" 2>&1; echo $? >"$OUT/nvcc_t32.rc" ) &
        wait
        for src in src/*.cu; do
            base=$(basename "$src" .cu)
            for arch in sm_75 sm_60; do
                rc=$(cat "$OUT/nvcc_${base}_$arch.rc")
                if [ "$rc" -eq 0 ] && ! grep -qi "warning" "$OUT/nvcc_${base}_$arch.log"; then ok "nvcc -c -arch=$arch $src"
                else ko "nvcc -c -arch=$arch $src (ver $OUT/nvcc_${base}_$arch.log)"; cat "$OUT/nvcc_${base}_$arch.log"; fi
            done
        done
        for t in 8 32; do
            if [ "$(cat "$OUT/nvcc_t$t.rc")" -eq 0 ] && ! grep -qi "warning" "$OUT/nvcc_t$t.log"; then ok "nvcc -c -DTILE=$t src/b_matmul_tiled.cu"
            else ko "nvcc -c -DTILE=$t src/b_matmul_tiled.cu"; cat "$OUT/nvcc_t$t.log"; fi
        done
    else
        sk "nvcc no está instalado: no se verifica la compilación de los .cu (en Colab sí está)"
    fi
fi

# ---------- 2. Referencias CPU: sin warnings y con los valores conocidos ----------
cpu_build() {  # cpu_build nombre
    if "$CC" -std=c11 -O2 -Wall -Wextra -Werror "src/$1.c" -o "$OUT/$1" -lm >"$OUT/gcc_$1.log" 2>&1; then ok "gcc -Wall -Wextra -Werror src/$1.c"
    else ko "gcc src/$1.c"; cat "$OUT/gcc_$1.log"; return 1; fi
}
if want A; then
    if cpu_build a_vectores_cpu; then
        "$OUT/a_vectores_cpu" 1000 >"$OUT/a_cpu_1000.txt" 2>&1
        a_add=$(grep "kernel=vector_add" "$OUT/a_cpu_1000.txt" | grab checksum); a_sax=$(grep "kernel=saxpy" "$OUT/a_cpu_1000.txt" | grab checksum)
        if [ "$a_add" = "8991.0" ] && [ "$a_sax" = "11988.0" ] && [ "$(grep -c "verificacion=OK" "$OUT/a_cpu_1000.txt")" -eq 2 ]; then
            ok "a_vectores_cpu 1000 -> checksums 8991.0 / 11988.0, verificacion=OK"
        else ko "a_vectores_cpu 1000 (checksums $a_add / $a_sax)"; cat "$OUT/a_cpu_1000.txt"; fi
    fi
fi
if want B; then
    if cpu_build b_matmul_cpu; then
        "$OUT/b_matmul_cpu" 32 16 >"$OUT/b_cpu_32.txt" 2>&1
        b_sum=$(grab checksum <"$OUT/b_cpu_32.txt")
        if close "$b_sum" 6866.126259 1e-6 && grep -q "fases=2" "$OUT/b_cpu_32.txt"; then ok "b_matmul_cpu 32 16 -> checksum=6866.126259, fases=2"
        else ko "b_matmul_cpu 32 16 (checksum $b_sum)"; cat "$OUT/b_cpu_32.txt"; fi
        "$OUT/b_matmul_cpu" 20 16 | grep -q "fases=2" && ok "b_matmul_cpu 20 16 -> ceil(20/16) = 2 fases" || ko "b_matmul_cpu 20 16: fases"
    fi
fi
if want C; then
    if cpu_build c_histograma_cpu; then
        "$OUT/c_histograma_cpu" 4096 >"$OUT/c_hist_4096.txt" 2>&1
        if grep -q "suma=522271 hist_checksum=526367" "$OUT/c_hist_4096.txt" && grep -q "total_cuentas=4096 (== n)" "$OUT/c_hist_4096.txt"; then
            ok "c_histograma_cpu 4096 -> suma=522271 hist_checksum=526367"
        else ko "c_histograma_cpu 4096"; cat "$OUT/c_hist_4096.txt"; fi
    fi
    if cpu_build c_jacobi_cpu; then
        "$OUT/c_jacobi_cpu" 10 8 1e-3 50 5 >"$OUT/c_jac_small.txt" 2>&1
        if grep -q "iteraciones=50 paro=max_iter" "$OUT/c_jac_small.txt" && close "$(grab checksum <"$OUT/c_jac_small.txt")" 1751.582337 1e-6; then
            ok "c_jacobi_cpu 10 8 1e-3 50 5 -> iteraciones=50, checksum=1751.582337"
        else ko "c_jacobi_cpu 10 8 1e-3 50 5"; cat "$OUT/c_jac_small.txt"; fi
    fi
fi

# ---------- 3. Parte A: espejo Numba en CUDASIM vs. CPU ----------
if want A; then
    for cfg in "1000 256" "37 8"; do
        set -- $cfg
        $PY src/a_vectores_numba.py "$1" "$2" >"$OUT/a_sim_$1.txt" 2>&1; rc=$?
        s_add=$(grep -A1 "kernel=vector_add" "$OUT/a_sim_$1.txt" | grab checksum); s_sax=$(grep -A1 "kernel=saxpy" "$OUT/a_sim_$1.txt" | grab checksum)
        [ -x "$OUT/a_vectores_cpu" ] && "$OUT/a_vectores_cpu" "$1" >"$OUT/a_cpu_$1.txt" 2>&1
        c_add=$(grep "kernel=vector_add" "$OUT/a_cpu_$1.txt" 2>/dev/null | grab checksum); c_sax=$(grep "kernel=saxpy" "$OUT/a_cpu_$1.txt" 2>/dev/null | grab checksum)
        if [ $rc -eq 0 ] && [ "$(grep -c "verificacion=OK" "$OUT/a_sim_$1.txt")" -eq 2 ] && [ "$s_add" = "$c_add" ] && [ "$s_sax" = "$c_sax" ]; then
            ok "CUDASIM a_vectores_numba $1 $2 -> OK, checksums $s_add / $s_sax iguales a la CPU"
        else ko "CUDASIM a_vectores_numba $1 $2 (sim $s_add/$s_sax vs cpu $c_add/$c_sax, rc=$rc)"; tail -6 "$OUT/a_sim_$1.txt"; fi
    done
    if [ "$EXTRA" = "1" ]; then
        for cfg in "1 1" "1025 1024"; do
            set -- $cfg
            $PY src/a_vectores_numba.py "$1" "$2" >"$OUT/a_sim_x_$1.txt" 2>&1 && [ "$(grep -c "verificacion=OK" "$OUT/a_sim_x_$1.txt")" -eq 2 ] \
                && ok "EXTRA CUDASIM a_vectores_numba $1 $2 -> OK" || { ko "EXTRA CUDASIM a_vectores_numba $1 $2"; tail -4 "$OUT/a_sim_x_$1.txt"; }
        done
    fi
fi

# ---------- 4. Parte B: espejo Numba con los TODO ----------
if want B; then
    $PY src/b_matmul_numba.py 32 16 naive >"$OUT/b_naive.txt" 2>&1 && grep -q "matmul_naive.*" "$OUT/b_naive.txt" && grep -q "verificacion=PASS" "$OUT/b_naive.txt" \
        && ok "CUDASIM b_matmul_numba 32 16 naive -> PASS" || { ko "CUDASIM b_matmul_numba 32 16 naive"; tail -4 "$OUT/b_naive.txt"; }
    tiled_case() {  # tiled_case n tile [checksum_cpu]
        $PY src/b_matmul_numba.py "$1" "$2" tiled >"$OUT/b_tiled_$1_$2.txt" 2>&1; rc=$?
        if grep -q "TODO pendiente" "$OUT/b_tiled_$1_$2.txt" && [ $rc -eq 3 ]; then pd "CUDASIM b_matmul_numba $1 $2 tiled: TODO(1)-TODO(4) pendientes"; return; fi
        s=$(grab checksum <"$OUT/b_tiled_$1_$2.txt")
        if [ $rc -eq 0 ] && grep -q "verificacion=PASS" "$OUT/b_tiled_$1_$2.txt" && { [ -z "${3:-}" ] || close "$s" "$3" 1e-4; }; then
            ok "CUDASIM b_matmul_numba $1 $2 tiled -> PASS${3:+, checksum $s igual a la CPU}"
        else ko "CUDASIM b_matmul_numba $1 $2 tiled (rc=$rc, checksum $s)"; tail -6 "$OUT/b_tiled_$1_$2.txt"; fi
    }
    tiled_case 32 16 6866.126259
    tiled_case 20 16          # n no múltiplo de TILE: sin TODO(1)/(2)/(4) correctos falla o lanza IndexError
    if [ "$EXTRA" = "1" ]; then
        tiled_case 17 16; tiled_case 48 16; tiled_case 20 8
    fi
fi

# ---------- 5. Parte C: espejos Numba del equipo (opcionales) ----------
if want C; then
    found=0
    for f in src/c_*_numba.py; do
        [ -f "$f" ] || continue
        found=1
        $PY "$f" >"$OUT/$(basename "$f" .py).txt" 2>&1; rc=$?
        if [ $rc -eq 0 ] && grep -q "verificacion=OK" "$OUT/$(basename "$f" .py).txt"; then ok "CUDASIM $f -> verificacion=OK"
        else ko "CUDASIM $f (rc=$rc)"; tail -6 "$OUT/$(basename "$f" .py).txt"; fi
    done
    [ $found -eq 0 ] && sk "Parte C: no hay src/c_*_numba.py (el espejo Numba de la Parte C es opcional)"
    if [ "$EXTRA" = "1" ] && [ -f src/c_histograma_numba.py ]; then
        for cfg in "4096 256 522271 526367" "4097 64 522390 526487" "1 32 0 1"; do
            set -- $cfg
            $PY src/c_histograma_numba.py "$1" "$2" >"$OUT/c_hist_sim_$1.txt" 2>&1 && grep -q "suma=$3 " "$OUT/c_hist_sim_$1.txt" && grep -q "hist_checksum=$4 " "$OUT/c_hist_sim_$1.txt" \
                && ok "EXTRA CUDASIM c_histograma_numba $1 $2 -> suma=$3 hist_checksum=$4 (igual a la CPU)" || { ko "EXTRA CUDASIM c_histograma_numba $1 $2"; tail -4 "$OUT/c_hist_sim_$1.txt"; }
        done
    fi
fi

# ---------- 6. Parte D: graficar.py ----------
if want D; then
    GRAFICAR=graficar.py; [ -f "$GRAFICAR" ] || GRAFICAR=../../../practicas/P6-gpu/graficar.py
    $PY - "$OUT/csv_prueba.csv" <<'PYEOF'
import sys
hdr = "experimento,kernel,n,block,grid,ocupacion_pct,memoria,t_h2d_ms,t_kernel_ms,t_d2h_ms,t_total_ms,t_cpu_ms,speedup_kernel,speedup_total,ancho_banda_gbs,origen,dispositivo\n"
rows = []
for kernel, cpu_gbs in (("vector_add", 12.0), ("saxpy", 11.0)):
    for block in (32, 64, 128, 256, 512, 1024):
        n = 1 << 20; k = 12 * n / 200e9 * 1e3 * (1.6 if block == 32 else 1.0); h = 8 * n / 6e9 * 1e3; d = 4 * n / 6e9 * 1e3; c = 12 * n / (cpu_gbs * 1e9) * 1e3
        rows.append(f"bloque,{kernel},{n},{block},{(n+block-1)//block},100,pageable,{h:.6f},{k:.6f},{d:.6f},{h+k+d:.6f},{c:.6f},{c/k:.4f},{c/(h+k+d):.4f},{12*n/(k*1e-3)/1e9:.2f},prueba,prueba")
    for e in range(10, 23, 4):
        n = 1 << e; k = 0.008 + 12 * n / 200e9 * 1e3; h = 0.02 + 8 * n / 6e9 * 1e3; d = 0.01 + 4 * n / 6e9 * 1e3; c = 12 * n / (cpu_gbs * 1e9) * 1e3
        rows.append(f"umbral,{kernel},{n},256,{(n+255)//256},100,pageable,{h:.6f},{k:.6f},{d:.6f},{h+k+d:.6f},{c:.6f},{c/k:.4f},{c/(h+k+d):.4f},{12*n/(k*1e-3)/1e9:.2f},prueba,prueba")
open(sys.argv[1], "w").write(hdr + "\n".join(rows) + "\n")
PYEOF
    if $PY "$GRAFICAR" "$OUT/csv_prueba.csv" -o "$OUT/graf" >"$OUT/graficar.log" 2>&1 && [ -s "$OUT/graf/tiempo_vs_bloque.png" ] && [ -s "$OUT/graf/speedup_vs_n.png" ] && [ -s "$OUT/graf/transferencias.png" ]; then
        ok "graficar.py sobre un CSV de prueba -> tiempo_vs_bloque.png, speedup_vs_n.png, transferencias.png"
    else ko "graficar.py sobre el CSV de prueba"; tail -10 "$OUT/graficar.log"; fi
    real=$(ls resultados/*.csv 2>/dev/null | head -5)
    if [ -n "$real" ]; then
        # shellcheck disable=SC2086
        if $PY "$GRAFICAR" $real -o "$OUT/graf_real" >"$OUT/graficar_real.log" 2>&1; then ok "graficar.py sobre resultados/*.csv (tus datos)"
        else ko "graficar.py sobre resultados/*.csv"; tail -10 "$OUT/graficar_real.log"; fi
    else
        sk "resultados/*.csv todavía no existe (se produce en Colab/Kaggle)"
    fi
fi

# ---------- 7. Notebook ----------
if [ "$PART" = "all" ]; then
    if $PY tests/check_notebook.py >"$OUT/notebook.log" 2>&1; then ok "notebook_colab.ipynb válido (nbformat) y sincronizado con src/"
    else ko "notebook_colab.ipynb"; cat "$OUT/notebook.log"; fi
fi

echo "------------------------------------------------------------"
echo "Resumen: PASS=$pass FAIL=$fail PEND=$pend SKIP=$skip   (parte: $PART, STRICT_B=$STRICT_B, EXTRA=$EXTRA)"
if [ $fail -eq 0 ]; then
    [ $pend -gt 0 ] && echo "Parte B pendiente: completa TODO(1)-TODO(4); 'make test-b' exige que pasen."
    echo "RESULTADO: PASS"; rm -rf "$OUT"; exit 0
fi
echo "RESULTADO: FAIL (detalles en $OUT)"; exit 1
