#!/usr/bin/env bash
# tests/run_tests.sh — Verificación SIN GPU de la Práctica 6 (termina en < 60 s en una laptop de 4 núcleos).
#
# Uso:   bash tests/run_tests.sh [all|A|B|C|D]        (make test = all · make test-b = B)
#
# Qué comprueba:
#   1. Todos los src/*.cu compilan con nvcc -c para sm_75 (T4) y sm_60 (P100), sin errores ni warnings;
#      a_matmul_tiled.cu y b_matmul_rect.cu también con -DTILE=8 y -DTILE=32. Incluye tu Parte C (src/c_<nombre>.cu).
#   2. Las referencias CPU compilan con gcc -std=c11 -O2 -Wall -Wextra -Werror y dan los valores conocidos.
#   3. Parte A: los espejos Numba bajo NUMBA_ENABLE_CUDASIM=1 pasan su verificación y su checksum coincide con la CPU
#      (vectores con n = 1000 y n = 37; matmul ingenua y por mosaicos con n = 32 y n = 20, no múltiplo de TILE).
#   4. Parte B: el espejo b_matmul_rect_numba.py (mismos TODO que el .cu) con 32×32×32 y 20×40×12 (rectangular, no
#      múltiplo de TILE); su checksum debe coincidir con b_matmul_rect_cpu. Mientras TODO_LISTO sea False el programa
#      imprime "TODO pendiente": esos casos salen PEND y no cuentan como FAIL en `make test`; en `make test-b`
#      (STRICT_B=1) cuentan como FAIL hasta que corrijas TODO(1)–TODO(4). Un TODO mal corregido siempre es FAIL.
#      Si el espejo ya tiene TODO_LISTO = True, el .cu debe tener #define TODO_LISTO 1 (si no, FAIL).
#   5. Parte C: las referencias CPU dan los valores conocidos; si existen espejos src/c_*_numba.py se corren en
#      CUDASIM sin argumentos y deben imprimir verificacion=OK (SKIP si no hay: el espejo de la Parte C es opcional).
#   6. Parte D: graficar.py produce las tres PNG a partir de un CSV de prueba, y de resultados/*.csv si ya existen.
#   7. notebook_colab.ipynb es válido (nbformat) y sus celdas %%writefile coinciden con los fuentes.
# Los espejos Numba y las compilaciones con nvcc se lanzan en paralelo (el simulador es lento); los resultados se
# evalúan en orden. Variables: STRICT_B=1 (PEND cuenta como FAIL), EXTRA=1 (casos extra de calificación; los usa el
# profesor). Imprime PASS/FAIL/PEND/SKIP por caso; código de salida 0 solo si no hay FAIL.
set -u
cd "$(dirname "$0")/.." || exit 1
PART=${1:-all}
STRICT_B=${STRICT_B:-0}
[ "$PART" = "B" ] && STRICT_B=1
EXTRA=${EXTRA:-0}
OUT=tests/out
rm -rf "$OUT" && mkdir -p "$OUT"
export NUMBA_ENABLE_CUDASIM=1 PYTHONDONTWRITEBYTECODE=1 MPLBACKEND=Agg PYTHONWARNINGS=ignore
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
close() { $PY -c "import sys; a,b,t=float(sys.argv[1]),float(sys.argv[2]),float(sys.argv[3]); sys.exit(0 if abs(a-b)<=t*max(1.0,abs(b)) else 1)" "$1" "$2" "$3" 2>/dev/null; }
grab() { sed -n "s/.*$1=\([-0-9.e+]*\).*/\1/p" | head -1; }  # grab clave < archivo
# Trabajo en segundo plano: bg etiqueta comando...  -> salida en $OUT/etiqueta.txt, código en $OUT/etiqueta.rc
bg()    { local tag=$1; shift; ( "$@" >"$OUT/$tag.txt" 2>&1; echo $? >"$OUT/$tag.rc" ) & }
rc_of() { cat "$OUT/$1.rc" 2>/dev/null || echo 99; }
tagof() { echo "$*" | tr ' ' '_'; }

# Casos (públicos y extra). Parte A matmul: "n TILE [naive|tiled|ambos]". Parte B: "M K N TILE".
A_MATMUL=("32 16" "20 16")
B_RECT=("32 32 32 16" "20 40 12 16")
if [ "$EXTRA" = "1" ]; then
    A_MATMUL+=("17 16 tiled" "24 8 tiled")
    B_RECT+=("1 37 3 16" "33 8 17 8" "12 20 30 8" "17 33 5 16")
fi

# ---------- 0. Lanzar en paralelo lo lento: espejos Numba en CUDASIM y compilaciones con nvcc ----------
if want A; then
    for cfg in "1000 256" "37 8"; do set -- $cfg; bg "a_sim_$1_$2" $PY src/a_vectores_numba.py "$1" "$2"; done
    for cfg in "${A_MATMUL[@]}"; do set -- $cfg; bg "a_mm_$1_$2" $PY src/a_matmul_numba.py "$@"; done
    if [ "$EXTRA" = "1" ]; then
        for cfg in "1 1" "1025 1024"; do set -- $cfg; bg "a_sim_x_$1_$2" $PY src/a_vectores_numba.py "$1" "$2"; done
    fi
fi
if want B; then
    bg b_naive $PY src/b_matmul_rect_numba.py 20 40 12 16 naive
    for cfg in "${B_RECT[@]}"; do bg "b_rect_$(tagof $cfg)" $PY src/b_matmul_rect_numba.py $cfg tiled; done
fi
if want C; then
    for f in src/c_*_numba.py; do [ -f "$f" ] && bg "c_$(basename "$f" .py)" $PY "$f"; done
    if [ "$EXTRA" = "1" ] && [ -f src/c_histograma_numba.py ]; then
        for cfg in "1024 256" "1031 64" "1 32"; do set -- $cfg; bg "c_hist_sim_$1_$2" $PY src/c_histograma_numba.py "$1" "$2"; done
    fi
    if [ "$EXTRA" = "1" ] && [ -f src/c_jacobi_numba.py ]; then
        bg c_jac_sim_conv $PY src/c_jacobi_numba.py 9 7 1e-3 1000 5 8 8
    fi
fi
HAVE_NVCC=0
if { want A || want B || want C; } && command -v "$NVCC" >/dev/null 2>&1; then
    HAVE_NVCC=1
    for src in src/*.cu; do
        base=$(basename "$src" .cu)
        for arch in sm_75 sm_60; do bg "nvcc_${base}_$arch" "$NVCC" -c -O2 -arch=$arch "$src" -o "$OUT/${base}_$arch.o"; done
    done
    for base in a_matmul_tiled b_matmul_rect; do
        [ -f "src/$base.cu" ] || continue
        for t in 8 32; do bg "nvcc_${base}_t$t" "$NVCC" -c -O2 -arch=sm_75 -DTILE=$t "src/$base.cu" -o "$OUT/${base}_t$t.o"; done
    done
fi

# ---------- 2 (se evalúa primero porque es rápido). Referencias CPU: sin warnings y con los valores conocidos ----------
cpu_build() {  # cpu_build nombre
    "$CC" -std=c11 -O2 -Wall -Wextra -Werror "src/$1.c" -o "$OUT/$1" -lm >"$OUT/gcc_$1.log" 2>&1
}
cpu_msgs=()
cpu_report() { cpu_msgs+=("$1"); }
if want A; then
    if cpu_build a_vectores_cpu; then
        cpu_report "ok gcc -Wall -Wextra -Werror src/a_vectores_cpu.c"
        "$OUT/a_vectores_cpu" 1000 >"$OUT/a_cpu_1000.txt" 2>&1
        "$OUT/a_vectores_cpu" 37 >"$OUT/a_cpu_37.txt" 2>&1
        a_add=$(grep "kernel=vector_add" "$OUT/a_cpu_1000.txt" | grab checksum); a_sax=$(grep "kernel=saxpy" "$OUT/a_cpu_1000.txt" | grab checksum)
        if [ "$a_add" = "8991.0" ] && [ "$a_sax" = "11988.0" ] && [ "$(grep -c "verificacion=OK" "$OUT/a_cpu_1000.txt")" -eq 2 ]; then
            cpu_report "ok a_vectores_cpu 1000 -> checksums 8991.0 / 11988.0, verificacion=OK"
        else cpu_report "ko a_vectores_cpu 1000 (checksums $a_add / $a_sax)"; fi
    else cpu_report "ko gcc src/a_vectores_cpu.c (ver $OUT/gcc_a_vectores_cpu.log)"; fi
    if cpu_build a_matmul_cpu; then
        cpu_report "ok gcc -Wall -Wextra -Werror src/a_matmul_cpu.c"
        for cfg in "${A_MATMUL[@]}"; do set -- $cfg; "$OUT/a_matmul_cpu" "$1" "$2" >"$OUT/a_mmcpu_$1_$2.txt" 2>&1; done
        s32=$(grab checksum <"$OUT/a_mmcpu_32_16.txt")
        if close "$s32" 6866.126259 1e-9 && grep -q "fases=2" "$OUT/a_mmcpu_32_16.txt"; then cpu_report "ok a_matmul_cpu 32 16 -> checksum=6866.126259, fases=2"
        else cpu_report "ko a_matmul_cpu 32 16 (checksum $s32)"; fi
        if close "$(grab checksum <"$OUT/a_mmcpu_20_16.txt")" 1680.790287 1e-9 && grep -q "fases=2" "$OUT/a_mmcpu_20_16.txt"; then
            cpu_report "ok a_matmul_cpu 20 16 -> checksum=1680.790287, ceil(20/16) = 2 fases"
        else cpu_report "ko a_matmul_cpu 20 16"; fi
    else cpu_report "ko gcc src/a_matmul_cpu.c (ver $OUT/gcc_a_matmul_cpu.log)"; fi
fi
if want B; then
    if cpu_build b_matmul_rect_cpu; then
        cpu_report "ok gcc -Wall -Wextra -Werror src/b_matmul_rect_cpu.c"
        for cfg in "${B_RECT[@]}"; do "$OUT/b_matmul_rect_cpu" $cfg >"$OUT/b_cpu_$(tagof $cfg).txt" 2>&1; done
        if close "$(grab checksum <"$OUT/b_cpu_32_32_32_16.txt")" 6866.126259 1e-9; then
            cpu_report "ok b_matmul_rect_cpu 32 32 32 -> checksum=6866.126259 (igual que la Parte A con n = 32)"
        else cpu_report "ko b_matmul_rect_cpu 32 32 32"; fi
        f="$OUT/b_cpu_20_40_12_16.txt"
        if close "$(grab checksum <"$f")" 2011.881224 1e-9 && grep -q "malla=1x2 .* fases=3 .* sin_escritura=272" "$f"; then
            cpu_report "ok b_matmul_rect_cpu 20 40 12 16 -> checksum=2011.881224, malla=1x2, fases=3, 272 hilos sin escritura"
        else cpu_report "ko b_matmul_rect_cpu 20 40 12 16 (ver $f)"; fi
    else cpu_report "ko gcc src/b_matmul_rect_cpu.c (ver $OUT/gcc_b_matmul_rect_cpu.log)"; fi
fi
if want C; then
    if cpu_build c_histograma_cpu; then
        cpu_report "ok gcc -Wall -Wextra -Werror src/c_histograma_cpu.c"
        "$OUT/c_histograma_cpu" 4096 >"$OUT/c_hist_4096.txt" 2>&1
        if grep -q "suma=522271 hist_checksum=526367" "$OUT/c_hist_4096.txt" && grep -q "total_cuentas=4096 (== n)" "$OUT/c_hist_4096.txt"; then
            cpu_report "ok c_histograma_cpu 4096 -> suma=522271 hist_checksum=526367"
        else cpu_report "ko c_histograma_cpu 4096 (ver $OUT/c_hist_4096.txt)"; fi
    else cpu_report "ko gcc src/c_histograma_cpu.c (ver $OUT/gcc_c_histograma_cpu.log)"; fi
    if cpu_build c_jacobi_cpu; then
        cpu_report "ok gcc -Wall -Wextra -Werror src/c_jacobi_cpu.c"
        "$OUT/c_jacobi_cpu" 10 8 1e-3 50 5 >"$OUT/c_jac_small.txt" 2>&1
        if grep -q "iteraciones=50 paro=max_iter" "$OUT/c_jac_small.txt" && close "$(grab checksum <"$OUT/c_jac_small.txt")" 1751.582337 1e-6; then
            cpu_report "ok c_jacobi_cpu 10 8 1e-3 50 5 -> iteraciones=50, checksum=1751.582337"
        else cpu_report "ko c_jacobi_cpu 10 8 1e-3 50 5 (ver $OUT/c_jac_small.txt)"; fi
    else cpu_report "ko gcc src/c_jacobi_cpu.c (ver $OUT/gcc_c_jacobi_cpu.log)"; fi
fi

wait  # todo lo lanzado en segundo plano terminó

# ---------- 1. Compilación CUDA (sin GPU) ----------
if want A || want B || want C; then
    if [ "$HAVE_NVCC" = "1" ]; then
        for src in src/*.cu; do
            base=$(basename "$src" .cu)
            for arch in sm_75 sm_60; do
                if [ "$(rc_of "nvcc_${base}_$arch")" -eq 0 ] && ! grep -qi "warning" "$OUT/nvcc_${base}_$arch.txt"; then ok "nvcc -c -arch=$arch $src"
                else ko "nvcc -c -arch=$arch $src (ver $OUT/nvcc_${base}_$arch.txt)"; cat "$OUT/nvcc_${base}_$arch.txt"; fi
            done
        done
        for base in a_matmul_tiled b_matmul_rect; do
            [ -f "src/$base.cu" ] || continue
            for t in 8 32; do
                if [ "$(rc_of "nvcc_${base}_t$t")" -eq 0 ] && ! grep -qi "warning" "$OUT/nvcc_${base}_t$t.txt"; then ok "nvcc -c -DTILE=$t src/$base.cu"
                else ko "nvcc -c -DTILE=$t src/$base.cu"; cat "$OUT/nvcc_${base}_t$t.txt"; fi
            done
        done
    else
        sk "nvcc no está instalado: no se verifica la compilación de los .cu (en Colab sí está)"
    fi
fi

# ---------- 2. Referencias CPU (resultados calculados arriba) ----------
for m in "${cpu_msgs[@]}"; do
    case "$m" in ok\ *) ok "${m#ok }" ;; ko\ *) ko "${m#ko }" ;; esac
done

# ---------- 3. Parte A: espejos Numba en CUDASIM vs. CPU ----------
if want A; then
    for cfg in "1000 256" "37 8"; do
        set -- $cfg
        f="$OUT/a_sim_$1_$2.txt"; rc=$(rc_of "a_sim_$1_$2")
        s_add=$(grep -A1 "kernel=vector_add" "$f" | grab checksum); s_sax=$(grep -A1 "kernel=saxpy" "$f" | grab checksum)
        c_add=$(grep "kernel=vector_add" "$OUT/a_cpu_$1.txt" 2>/dev/null | grab checksum); c_sax=$(grep "kernel=saxpy" "$OUT/a_cpu_$1.txt" 2>/dev/null | grab checksum)
        if [ "$rc" -eq 0 ] && [ "$(grep -c "verificacion=OK" "$f")" -eq 2 ] && [ -n "$s_add" ] && [ "$s_add" = "$c_add" ] && [ "$s_sax" = "$c_sax" ]; then
            ok "CUDASIM a_vectores_numba $1 $2 -> OK, checksums $s_add / $s_sax iguales a la CPU"
        else ko "CUDASIM a_vectores_numba $1 $2 (sim $s_add/$s_sax vs cpu $c_add/$c_sax, rc=$rc)"; tail -6 "$f"; fi
    done
    for cfg in "${A_MATMUL[@]}"; do
        set -- $cfg
        f="$OUT/a_mm_$1_$2.txt"; rc=$(rc_of "a_mm_$1_$2"); want_n=$(grep -c "^matmul_" "$f")
        c=$(grab checksum <"$OUT/a_mmcpu_$1_$2.txt"); bad=0
        for s in $(grep -o "checksum=[-0-9.e+]*" "$f" | cut -d= -f2); do close "$s" "$c" 1e-5 || bad=1; done
        if [ "$rc" -eq 0 ] && [ "$want_n" -ge 1 ] && [ "$(grep -c "verificacion=PASS" "$f")" -eq "$want_n" ] && [ $bad -eq 0 ]; then
            ok "CUDASIM a_matmul_numba $1 $2 -> $(grep -o "^matmul_[a-z]*" "$f" | tr '\n' ' ')PASS, checksum igual a la CPU ($c)"
        else ko "CUDASIM a_matmul_numba $1 $2 (rc=$rc)"; tail -6 "$f"; fi
    done
    if [ "$EXTRA" = "1" ]; then
        for cfg in "1 1" "1025 1024"; do
            set -- $cfg
            f="$OUT/a_sim_x_$1_$2.txt"
            if [ "$(rc_of "a_sim_x_$1_$2")" -eq 0 ] && [ "$(grep -c "verificacion=OK" "$f")" -eq 2 ]; then ok "EXTRA CUDASIM a_vectores_numba $1 $2 -> OK"
            else ko "EXTRA CUDASIM a_vectores_numba $1 $2"; tail -4 "$f"; fi
        done
    fi
fi

# ---------- 4. Parte B: espejo rectangular con los TODO ----------
if want B; then
    c_naive=$(grab checksum <"$OUT/b_cpu_20_40_12_16.txt" 2>/dev/null)
    s_naive=$(grab checksum <"$OUT/b_naive.txt")
    if [ "$(rc_of b_naive)" -eq 0 ] && grep -q "verificacion=PASS" "$OUT/b_naive.txt" && close "$s_naive" "$c_naive" 1e-5; then
        ok "CUDASIM b_matmul_rect_numba 20 40 12 16 naive -> PASS, checksum igual a la CPU ($c_naive)"
    else ko "CUDASIM b_matmul_rect_numba 20 40 12 16 naive"; tail -4 "$OUT/b_naive.txt"; fi
    for cfg in "${B_RECT[@]}"; do
        tag=$(tagof $cfg); f="$OUT/b_rect_$tag.txt"; rc=$(rc_of "b_rect_$tag")
        label="CUDASIM b_matmul_rect_numba $cfg tiled"
        if grep -q "TODO pendiente" "$f" && [ "$rc" -eq 3 ]; then pd "$label: TODO(1)-TODO(4) pendientes"; continue; fi
        s=$(grab checksum <"$f"); c=$(grab checksum <"$OUT/b_cpu_$tag.txt")
        if [ "$rc" -eq 0 ] && grep -q "verificacion=PASS" "$f" && close "$s" "$c" 1e-5; then ok "$label -> PASS, checksum $s igual a la CPU"
        else ko "$label (rc=$rc, checksum ${s:-?} vs CPU $c)"; tail -3 "$f"; fi
    done
    # El .cu es lo que corre en la GPU y lo que se califica: si el espejo ya dice True, el .cu también debe decir 1.
    if grep -q "^TODO_LISTO = True" src/b_matmul_rect_numba.py; then
        if grep -q "^#define TODO_LISTO 1" src/b_matmul_rect.cu; then ok "b_matmul_rect.cu con TODO_LISTO 1, igual que su espejo"
        else ko "b_matmul_rect.cu sigue con TODO_LISTO 0 aunque el espejo dice True: corrige TODO(1)-TODO(4) también en el .cu"; fi
    fi
fi

# ---------- 5. Parte C: espejos Numba del equipo (opcionales) y casos extra de la solución ----------
if want C; then
    found=0
    for f in src/c_*_numba.py; do
        [ -f "$f" ] || continue
        found=1
        tag="c_$(basename "$f" .py)"
        if [ "$(rc_of "$tag")" -eq 0 ] && grep -q "verificacion=OK" "$OUT/$tag.txt"; then ok "CUDASIM $f -> verificacion=OK"
        else ko "CUDASIM $f (rc=$(rc_of "$tag"))"; tail -6 "$OUT/$tag.txt"; fi
    done
    [ $found -eq 0 ] && sk "Parte C: no hay src/c_*_numba.py (el espejo Numba de la Parte C es opcional)"
    if [ "$EXTRA" = "1" ] && [ -f src/c_histograma_numba.py ]; then
        for cfg in "1024 256 130400 131424" "1031 64 131432 132463" "1 32 0 1"; do
            set -- $cfg
            f="$OUT/c_hist_sim_$1_$2.txt"
            if [ "$(rc_of "c_hist_sim_$1_$2")" -eq 0 ] && grep -q "suma=$3 " "$f" && grep -q "hist_checksum=$4 " "$f"; then
                ok "EXTRA CUDASIM c_histograma_numba $1 $2 -> suma=$3 hist_checksum=$4 (igual a la CPU)"
            else ko "EXTRA CUDASIM c_histograma_numba $1 $2"; tail -4 "$f"; fi
        done
    fi
    if [ "$EXTRA" = "1" ] && [ -f src/c_jacobi_numba.py ]; then
        f="$OUT/c_jac_sim_conv.txt"
        if [ "$(rc_of c_jac_sim_conv)" -eq 0 ] && grep -q "iteraciones=75 (CPU 75) paro=convergio" "$f" && close "$(grab checksum <"$f")" 1376.600528 1e-6; then
            ok "EXTRA CUDASIM c_jacobi_numba 9 7 1e-3 1000 5 8 8 -> convergio en 75 iteraciones, checksum=1376.600528"
        else ko "EXTRA CUDASIM c_jacobi_numba 9 7 1e-3 1000 5 8 8"; tail -4 "$f"; fi
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
    [ $pend -gt 0 ] && echo "Parte B pendiente: corrige TODO(1)-TODO(4) en b_matmul_rect.cu y en su espejo; 'make test-b' exige que pasen."
    echo "RESULTADO: PASS"; rm -rf "$OUT"; exit 0
fi
echo "RESULTADO: FAIL (detalles en $OUT)"; exit 1
