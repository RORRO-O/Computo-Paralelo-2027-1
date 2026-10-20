#!/usr/bin/env bash
# run_tests.sh — Verificación automática de la Práctica 4 (OpenMP).
# Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1
#
# Uso (desde la carpeta de la práctica):   bash tests/run_tests.sh       (o:  make test)
#   PARTES="A B"     corre solo esas partes (por defecto "A B C")
#   PARTE_C=mandelbrot | calor | ambas    fuerza la opción de la Parte C (por defecto se detecta: la opción
#                    cuyo programa ya no imprime "TODO pendiente"; si las dos están completas, se prueban ambas)
#   REPS_TEST=2      repeticiones por corrida en las pruebas (correctitud, no medición)
#
# Qué hace: compila cada programa con  gcc -std=c11 -O2 -Wall -Wextra -fopenmp  (un warning cuenta como FAIL),
# ejecuta cada caso con un tamaño fijo y compara contra la versión secuencial o contra un valor de referencia
# obtenido con el contrato (c_mandel.h, c_heat.h). Imprime PASS/FAIL por caso y termina con código 0 solo si
# no hubo ningún FAIL. Las comparaciones de enteros (histograma, ordenamiento, Mandelbrot) son exactas; la de
# calor usa tolerancia 1e-10 (la hace el programa con --verificar).
#
# Un TODO(n) sin completar hace que el programa imprima "TODO pendiente" y que las pruebas de su parte
# fallen: es lo esperado mientras trabajas. En la Parte B cada caso dice qué TODO comprueba y pasa en cuanto
# ese TODO está bien, aunque falten otros; el caso "B  sin TODO pendiente" solo pasa cuando están los tres. Las salidas de cada caso quedan en tests/out/ (se borran con
# make clean). Todas las pruebas juntas tardan menos de 60 s en 4 núcleos.
set -u
export LC_ALL=C
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SRC=$ROOT/src
BIN=$ROOT/bin
OUT=$ROOT/tests/out
mkdir -p "$BIN" "$OUT"
CC=${CC:-gcc}
CFLAGS="-std=c11 -O2 -Wall -Wextra -fopenmp"
PARTES=${PARTES:-"A B C"}
export REPS=${REPS_TEST:-2}
LIMIT=${TIMEOUT_S:-60}
pass=0
fail=0

ok()   { printf 'PASS  %s\n' "$*"; pass=$((pass + 1)); }
ko()   { printf 'FAIL  %s\n' "$*"; fail=$((fail + 1)); }
info() { printf 'INFO  %s\n' "$*"; }
want() { [[ " $PARTES " == *" $1 "* ]]; }

# run NOMBRE HILOS programa args...  -> salida en $last (tests/out/NOMBRE.txt), código de salida en $rc
run() {
    local name=$1 th=$2
    shift 2
    last="$OUT/$name.txt"
    OMP_NUM_THREADS=$th timeout "$LIMIT" "$@" > "$last" 2>&1
    rc=$?
    if [[ $rc == 124 ]]; then echo "(se detuvo tras $LIMIT s: ¿interbloqueo o tamaño enorme?)" >> "$last"; fi
}
has()   { grep -q -- "$1" "$last"; }
count() { grep -c -- "$1" "$last"; }
todo_line() { grep -m1 'TODO pendiente' "$last" || true; }
why() { if has 'TODO pendiente'; then echo "($(todo_line))"; else echo "(código $rc; ver tests/out/$(basename "$last"))"; fi; }

# compile PROGRAMA -> 0 si hay binario utilizable
compile() {
    local p=$1 log="$OUT/cc_$1.log"
    if $CC $CFLAGS "$SRC/$p.c" -o "$BIN/$p" -lm 2> "$log"; then
        if [[ -s $log ]]; then ko "compila sin warnings: $p.c (ver tests/out/cc_$p.log)"; else ok "compila sin warnings: $p.c"; fi
        return 0
    fi
    ko "compila: $p.c (ver tests/out/cc_$p.log)"
    return 1
}

# ============================== Parte A · histograma (código completo) ==============================
if want A; then
    echo "== Parte A · histograma paralelo"
    if compile a_histogram; then
        for th in 1 2 3 4; do
            run a_todos_$th $th "$BIN/a_histogram" todos 200000 64
            k=$(count '^RESULT,a_histogram,.*,OK$')
            if [[ $rc == 0 && $k == 5 ]]; then ok "A  hilos=$th n=200000 nbins=64: critical, atomic, local, reduction y tareas = secuencial"
            else ko "A  hilos=$th n=200000 nbins=64: $k de 5 versiones iguales a la secuencial $(why)"; fi
        done
        for m in atomic critical; do
            run a_bins1_$m 4 "$BIN/a_histogram" $m 50000 1
            if [[ $rc == 0 ]] && has "^RESULT,a_histogram,$m,.*,OK$"; then ok "A  $m con nbins=1 (máxima contención)"
            else ko "A  $m con nbins=1 $(why)"; fi
        done
        run a_small 4 "$BIN/a_histogram" todos 7 3
        if [[ $rc == 0 && $(count '^RESULT,a_histogram,.*,OK$') == 5 ]]; then ok "A  n=7 nbins=3 con 4 hilos (menos datos que hilos)"
        else ko "A  n=7 nbins=3 con 4 hilos $(why)"; fi
        run a_4096 4 "$BIN/a_histogram" todos 100000 4096
        if [[ $rc == 0 && $(count '^RESULT,a_histogram,.*,OK$') == 5 ]]; then ok "A  nbins=4096 (combinación larga) con 4 hilos"
        else ko "A  nbins=4096 con 4 hilos $(why)"; fi
        run a_t8 4 "$BIN/a_histogram" tareas 8 4 2
        if [[ $rc == 0 ]] && has 'tareas creadas = 6 '; then ok "A  tareas n=8 corte=2 -> 6 tareas (2 + 4)"
        else ko "A  tareas n=8 corte=2: esperaba 6 tareas $(why)"; fi
        run a_t8_1 1 "$BIN/a_histogram" tareas 8 4 2
        if [[ $rc == 0 ]] && has 'tareas creadas = 6 '; then ok "A  tareas n=8 corte=2 con 1 hilo -> también 6 (las crea la recursión, no los hilos)"
        else ko "A  tareas con 1 hilo: esperaba 6 tareas $(why)"; fi
        run a_t100k 3 "$BIN/a_histogram" tareas 100000 64 1000
        if [[ $rc == 0 ]] && has 'tareas creadas = 254 ' && has '^RESULT,a_histogram,tareas,.*,OK$'; then
            ok "A  tareas n=100000 corte=1000 -> 254 tareas (128 hojas) y conteo exacto"
        else ko "A  tareas n=100000 corte=1000: esperaba 254 tareas y OK $(why)"; fi
        run a_tcut 2 "$BIN/a_histogram" tareas 1000 16 1000
        if [[ $rc == 0 ]] && has 'tareas creadas = 0 '; then ok "A  tareas n=1000 corte=1000 -> 0 tareas (n <= corte)"
        else ko "A  tareas n=corte: esperaba 0 tareas $(why)"; fi
    fi
    if compile a_histogram_buggy; then
        run a_buggy 4 "$BIN/a_histogram_buggy" 1000000 16
        info "a_histogram_buggy hilos=4 n=1000000 nbins=16 (no cuenta para PASS/FAIL): $(grep -m1 'repeticiones incorrectas' "$last" || echo 'sin salida')"
    fi
fi

# ============================== Parte B · mergesort estable con tareas ==============================
if want B; then
    echo "== Parte B · ordenamiento estable con tareas y corte"
    if compile b_mergesort; then
        run b_todo 2 "$BIN/b_mergesort" 1000 64
        if has 'TODO pendiente'; then ko "B  sin TODO pendiente: $(todo_line)"; else ok "B  sin TODO pendiente"; fi
        run b_seq 1 "$BIN/b_mergesort" 100000 1024 seq
        if has 'mergesort seq .*verificacion: OK'; then ok "B  TODO(1) mezcla estable: seq n=100000 = qsort por (clave, id)"
        else ko "B  TODO(1) seq n=100000: $(grep -m1 'mergesort seq' "$last" || true) $(why)"; fi
        run b_t8 4 "$BIN/b_mergesort" 8 2 omp
        if has 'tareas creadas = 6 '; then ok "B  TODO(2) corte: n=8 cutoff=2 -> 6 tareas"
        else ko "B  TODO(2) n=8 cutoff=2: esperaba 6 tareas, $(grep -m1 'tareas creadas' "$last" || echo 'sin línea de tareas') $(why)"; fi
        run b_t1000 4 "$BIN/b_mergesort" 1000 1000 omp
        if has 'tareas creadas = 0 '; then ok "B  TODO(2) corte: n=1000 cutoff=1000 -> 0 tareas"
        else ko "B  TODO(2) n=cutoff: esperaba 0 tareas $(why)"; fi
        for th in 1 2 4; do
            run b_omp_$th $th "$BIN/b_mergesort" 100003 1000 omp
            if has 'mergesort tareas .*verificacion: OK'; then ok "B  tareas hilos=$th n=100003 (no potencia de 2) = qsort, estable"
            else ko "B  tareas hilos=$th n=100003: $(grep -m1 'mergesort tareas' "$last" || true) $(why)"; fi
        done
        run b_stable 4 "$BIN/b_mergesort" 50000 64 omp
        if has 'mergesort tareas .*verificacion: OK'; then ok "B  tareas n=50000 cutoff=64 (muchos empates): estable"
        else ko "B  tareas n=50000 cutoff=64: $(grep -m1 'mergesort tareas' "$last" || true) $(why)"; fi
        for nn in 1 2 33; do
            run b_n$nn 2 "$BIN/b_mergesort" $nn 1 ambos
            if has 'mergesort seq .*verificacion: OK' && has 'mergesort tareas .*verificacion: OK'; then
                ok "B  n=$nn cutoff=1 (casos límite) en los tres ordenamientos"
            else ko "B  n=$nn cutoff=1 $(why)"; fi
        done
        REPS=3 run b_reps 2 "$BIN/b_mergesort" 200000 4096 ambos
        ts=$(awk -F= '$1 == "tiempos_s" { print $2 }' "$last")
        nz=$(awk -v s="$ts" 'BEGIN { n = split(s, a, " "); c = 0; for (i = 1; i <= n; i++) if (a[i] + 0 > 0) c++; print n " " c }')
        if [[ $nz == "3 3" ]]; then ok "B  TODO(3) arnés: con REPS=3, tiempos_s= trae 3 tiempos > 0"
        else ko "B  TODO(3) arnés: con REPS=3 esperaba 3 tiempos > 0 en tiempos_s= (hay: '$ts') $(why)"; fi
    fi
fi

# ============================== Parte C · diseño propio ==============================
if want C; then
    echo "== Parte C · diseño propio (Mandelbrot por filas o calor 1D)"
    m_ok=0 h_ok=0
    compile c_mandelbrot && m_ok=1
    compile c_heat && h_ok=1
    m_pend=1 h_pend=1
    if [[ $m_ok == 1 ]]; then run c_m_probe 2 "$BIN/c_mandelbrot" 13 12 50 omp static 0 - --verificar; has 'TODO pendiente' || m_pend=0; fi
    if [[ $h_ok == 1 ]]; then run c_h_probe 2 "$BIN/c_heat" 50 5 0 1 omp --verificar; has 'TODO pendiente' || h_pend=0; fi
    opcion=${PARTE_C:-}
    if [[ -z $opcion ]]; then
        if [[ $m_pend == 0 && $h_pend == 0 ]]; then opcion=ambas
        elif [[ $m_pend == 0 ]]; then opcion=mandelbrot
        elif [[ $h_pend == 0 ]]; then opcion=calor
        else opcion=ninguna; fi
    fi
    case $opcion in
        ninguna) ko "C  ninguna opción completa: c_mandelbrot.c y c_heat.c siguen con TODO pendiente (completa una)" ;;
        mandelbrot) info "Parte C: se prueba la opción Mandelbrot (c_heat.c no se evalúa)" ;;
        calor) info "Parte C: se prueba la opción calor 1D (c_mandelbrot.c no se evalúa)" ;;
        ambas) info "Parte C: se prueban las dos opciones" ;;
        *) ko "C  PARTE_C='$opcion' no válida (mandelbrot | calor | ambas)"; opcion=ninguna ;;
    esac

    if [[ $opcion == mandelbrot || $opcion == ambas ]] && [[ $m_ok == 1 ]]; then
        M="$BIN/c_mandelbrot"
        run c_m_seq 1 "$M" 260 240 200 seq
        if [[ $rc == 0 ]] && has '^checksum=3361872 checksum2=106967741260$'; then ok "C  Mandelbrot seq 260x240 max_iter=200: checksums del contrato"
        else ko "C  Mandelbrot seq 260x240: esperaba checksum=3361872 checksum2=106967741260, hay '$(grep -m1 '^checksum=' "$last")' $(why)"; fi
        for sc in "static 0" "dynamic 1" "guided 4"; do
            for th in 1 2 3 4; do
                run "c_m_${sc// /_}_$th" $th "$M" 260 240 200 omp $sc - --verificar
                if [[ $rc == 0 ]] && has '^checksum=3361872 checksum2=106967741260$' && has 'pixel a pixel y checksums): OK'; then
                    ok "C  Mandelbrot omp schedule=${sc% *},${sc#* } hilos=$th = secuencial píxel a píxel"
                else ko "C  Mandelbrot omp schedule=${sc% *},${sc#* } hilos=$th $(why)"; fi
            done
        done
        for dims in "7 5 100" "1 1 10" "3 97 300"; do
            run "c_m_odd_${dims// /x}" 4 "$M" $dims omp dynamic 1 - --verificar
            if [[ $rc == 0 ]] && has 'pixel a pixel y checksums): OK'; then ok "C  Mandelbrot ${dims% *} (max_iter ${dims##* }) con 4 hilos: tamaños raros"
            else ko "C  Mandelbrot $dims con 4 hilos $(why)"; fi
        done
        run c_m_pgm 2 "$M" 13 12 50 omp static 0 "$OUT/prueba.pgm"
        if [[ $rc == 0 && -f $OUT/prueba.pgm ]] && [[ $(head -c 13 "$OUT/prueba.pgm" | tr '\n' ' ') == "P5 13 12 255 " ]] \
            && [[ $(wc -c < "$OUT/prueba.pgm") -eq 169 ]]; then ok "C  Mandelbrot escribe PGM P5 13x12 (169 bytes)"
        else ko "C  Mandelbrot PGM: archivo, encabezado 'P5 13 12 255' o tamaño incorrecto $(why)"; fi
        k=$(grep -cE 'pragma +omp +(critical|atomic)' "$SRC/c_mandelbrot.c")
        info "c_mandelbrot.c tiene $k líneas con 'omp critical' u 'omp atomic'; la restricción prohíbe usarlos por píxel (se revisa en la mini-defensa)"
    fi

    if [[ $opcion == calor || $opcion == ambas ]] && [[ $h_ok == 1 ]]; then
        H="$BIN/c_heat"
        run c_h_seq 1 "$H" 1000 100 0 1 seq
        if [[ $rc == 0 ]] && has '^checksum=3.330000000000e+04 checksum2=3.250261396072e+06 ' && has 'iteraciones=100 '; then
            ok "C  calor seq n=1000, 100 pasos: checksums del contrato"
        else ko "C  calor seq n=1000: esperaba checksum2=3.250261396072e+06, hay '$(grep -m1 '^checksum=' "$last")' $(why)"; fi
        for th in 1 2 3 4; do
            run c_h_omp_$th $th "$H" 1000 100 0 1 omp --verificar
            if [[ $rc == 0 ]] && has 'verificacion contra la secuencial: OK'; then ok "C  calor omp hilos=$th n=1000, 100 pasos = secuencial"
            else ko "C  calor omp hilos=$th n=1000 $(why)"; fi
        done
        run c_h_n3 4 "$H" 3 10 0 1 omp --verificar
        if [[ $rc == 0 ]] && has 'verificacion contra la secuencial: OK'; then ok "C  calor n=3 (una celda interior) con 4 hilos"
        else ko "C  calor n=3 con 4 hilos $(why)"; fi
        run c_h_conv 4 "$H" 3000 2000000 1e-3 10 omp --verificar
        if [[ $rc == 0 ]] && has 'iteraciones=12100 convergio=si' && has 'verificacion contra la secuencial: OK'; then
            ok "C  calor converge: n=3000 tol=1e-3 revisando cada 10 pasos -> 12100 pasos, igual que la secuencial"
        else ko "C  calor convergencia n=3000 tol=1e-3: esperaba 12100 pasos, hay '$(grep -m1 '^iteraciones=' "$last")' $(why)"; fi
        run c_h_ce 3 "$H" 1001 1234 1e-9 100 omp --verificar
        if [[ $rc == 0 ]] && has 'iteraciones=1234 ' && has 'verificacion contra la secuencial: OK'; then
            ok "C  calor check_every=100 que no divide a max_iter=1234: 1234 pasos, igual que la secuencial"
        else ko "C  calor check_every=100, max_iter=1234 $(why)"; fi
        k=$(grep -cE 'pragma +omp +critical' "$SRC/c_heat.c")
        info "c_heat.c tiene $k líneas con 'omp critical'; la restricción lo prohíbe en el ciclo de celdas (se revisa en la mini-defensa)"
    fi
fi


echo
echo "Resumen: $pass PASS, $fail FAIL"
[[ $fail == 0 ]]
