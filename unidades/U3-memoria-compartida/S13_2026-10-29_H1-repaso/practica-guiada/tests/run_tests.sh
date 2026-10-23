#!/usr/bin/env bash
# tests/run_tests.sh — Verificación del cazador de errores S13 y de los ítems del examen de práctica
# (Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1).
#
# Uso:  bash tests/run_tests.sh          (= make test)   el material tal como se entrega; < 60 s
#       bash tests/run_tests.sh cazar    (= make cazar)  tus archivos: pasa cuando los tres errores están corregidos
#
# Modo "todo":
#   A. Compilación: cada fuente con -std=c11 -O2 -Wall -Wextra -fopenmp -Werror (sin warnings); y que gcc
#      SÍ avise en caza3 cuando puede ver la lectura (-DINLINE_HELPER).
#   B. Síntomas: caza2 se cuelga con 4 hilos (timeout, código 124) y termina con 1; caza1 y caza3 dan
#      INCORRECTO (si por azar salen bien, se reporta INFO: una carrera o un valor indefinido pueden "salir bien").
#   C. Soluciones: cada *_fixed da status=OK con 1, 2 y 4 hilos (3 repeticiones cada vez) y con n no divisible.
#   D. ThreadSanitizer (si está instalado): detecta la carrera de caza1 en las líneas del cuerpo del for.
#   E. Ejemplo resuelto: con 4 hilos y n=16 imprime hits = 8 y los mapas de los dos ciclos coinciden.
#   F. Ítems del examen de práctica: las salidas coinciden con la clave de examen-practica-U3.md.
# Imprime PASS/FAIL/INFO/SKIP por caso; código de salida 0 solo si no hay FAIL.
set -u
cd "$(dirname "$0")/.." || exit 1
MODE=${1:-todo}
OUT=tests/out
rm -rf "$OUT" && mkdir -p "$OUT"
CC=${CC:-gcc}
CFLAGS="-std=c11 -O2 -Wall -Wextra -fopenmp -I. -Werror"
TSANFLAGS="-std=c11 -fsanitize=thread -g -O1 -Wall -Wextra -fopenmp -I."
TIMEOUT=${TIMEOUT:-10}
pass=0; fail=0; skip=0
ok()   { echo "PASS  $1"; pass=$((pass + 1)); }
ko()   { echo "FAIL  $1${2:+   ($2)}"; fail=$((fail + 1)); }
info() { echo "INFO  $1"; }
sk()   { echo "SKIP  $1"; skip=$((skip + 1)); }

# compile <fuente> <binario> [flags extra]: PASS si compila sin warnings (-Werror).
compile() {
    local src=$1 bin=$2; shift 2
    if "$CC" $CFLAGS "$@" "$src" -o "$bin" -lm >"$OUT/cc.log" 2>&1; then
        ok "compila sin warnings: $src $*"
        return 0
    fi
    ko "compila sin warnings: $src $*" "$(head -1 "$OUT/cc.log")"
    return 1
}

# run_ok <nombre> <hilos> <timeout> <bin> [args]: PASS si termina con 0 e imprime status=OK.
run_ok() {
    local name=$1 t=$2 to=$3; shift 3
    if OMP_NUM_THREADS=$t timeout -k 2 "$to" "$@" >"$OUT/last.txt" 2>&1 && grep -q "status=OK" "$OUT/last.txt"; then
        ok "$name"
    else
        ko "$name" "$(grep -E 'RESULT|INCORRECTO' "$OUT/last.txt" | tail -1)"
    fi
}

# ---------------------------------------------------------------- modo cazar (lo que corrige el estudiante)
if [ "$MODE" = "cazar" ]; then
    echo "== make cazar: tus archivos (cada uno con 1, 2 y 4 hilos; caza2 con timeout de $TIMEOUT s)"
    for src in caza1_race_buggy.c caza2_barrier_buggy.c caza3_private_buggy.c $(ls caza4_*_buggy.c 2>/dev/null); do
        bin="$OUT/${src%.c}"
        if compile "$src" "$bin"; then
            for t in 1 2 4; do
                run_ok "${src%.c} con $t hilos: termina y status=OK" "$t" "$TIMEOUT" "$bin"
            done
            run_ok "${src%.c} con 3 hilos y n=1000003 (no divisible)" 3 "$TIMEOUT" "$bin" 1000003
        fi
        case "$src" in caza4_*)
            if grep -q "Sintoma esperado:\|Síntoma esperado:" "$src" && grep -q "Idea erronea:\|Idea errónea:" "$src"; then
                ok "$src declara 'Síntoma esperado' e 'Idea errónea' en el encabezado"
            else
                ko "$src declara 'Síntoma esperado' e 'Idea errónea' en el encabezado"
            fi ;;
        esac
    done
    echo "Resumen: $pass PASS, $fail FAIL"
    if [ "$fail" -eq 0 ]; then echo "Los tres errores están corregidos. Ahora escribe el cuarto (fase Crear)."; fi
    [ "$fail" -eq 0 ]
    exit $?
fi

# ---------------------------------------------------------------- modo todo
echo "== A. Compilación sin warnings (-Werror)"
compile caza1_race_buggy.c            "$OUT/caza1"
compile caza2_barrier_buggy.c         "$OUT/caza2"
compile caza3_private_buggy.c         "$OUT/caza3"
compile soluciones/caza1_race_fixed.c    "$OUT/caza1_fixed"
compile soluciones/caza2_barrier_fixed.c "$OUT/caza2_fixed"
compile soluciones/caza3_private_fixed.c "$OUT/caza3_fixed"
compile ejemplo_revision.c            "$OUT/ejemplo"
compile ejemplo_revision.c            "$OUT/ejemplo_falla" -DVARIANTE_FALLA
compile examen_items/item_II1_firstprivate.c "$OUT/II1"
compile examen_items/item_II2_static_map.c   "$OUT/II2"
compile examen_items/item_III1_dot_buggy.c   "$OUT/III1_buggy"
compile examen_items/item_III1_dot_buggy.c   "$OUT/III1_fixed" -DCORREGIDO
compile examen_items/item_III2_scan_buggy.c  "$OUT/III2_buggy"
compile examen_items/item_III2_scan_buggy.c  "$OUT/III2_fixed" -DCORREGIDO
compile examen_items/item_IV_tasks_sum.c     "$OUT/IV"
compile examen_items/item_VI_collatz.c       "$OUT/VI"
# gcc debe avisar cuando puede ver la lectura de la variable private sin inicializar.
if "$CC" -std=c11 -O2 -Wall -Wextra -fopenmp -I. -DINLINE_HELPER caza3_private_buggy.c -o "$OUT/caza3_warn" -lm 2>"$OUT/warn.log" \
   && grep -q "may be used uninitialized" "$OUT/warn.log"; then
    ok "caza3 con -DINLINE_HELPER: gcc avisa 'may be used uninitialized'"
else
    ko "caza3 con -DINLINE_HELPER: gcc avisa 'may be used uninitialized'"
fi
[ "$fail" -eq 0 ] || { echo "Resumen: $pass PASS, $fail FAIL (no se sigue sin compilar)"; exit 1; }

echo "== B. Los errores se reproducen (material tal como se entrega)"
OMP_NUM_THREADS=4 timeout -k 2 "$TIMEOUT" "$OUT/caza2" 1000000 >"$OUT/last.txt" 2>&1; rc=$?
if [ "$rc" -eq 124 ]; then ok "caza2 con 4 hilos se cuelga (timeout $TIMEOUT s, código 124)"; else ko "caza2 con 4 hilos se cuelga" "código $rc"; fi
run_ok "caza2 con 1 hilo termina y da status=OK (y aun así es incorrecto: idea 7)" 1 "$TIMEOUT" "$OUT/caza2" 1000000
for c in caza1 caza3; do
    if OMP_NUM_THREADS=4 timeout -k 2 "$TIMEOUT" "$OUT/$c" >"$OUT/last.txt" 2>&1; then
        info "$c con 4 hilos dio status=OK en esta corrida (una carrera o un valor indefinido pueden 'salir bien'; no cuenta)"
    elif grep -q "status=INCORRECTO" "$OUT/last.txt"; then
        ok "$c con 4 hilos da status=INCORRECTO: $(grep RESULT "$OUT/last.txt" | sed 's/.*reps_incorrectas=/reps_incorrectas=/')"
    else
        ko "$c con 4 hilos corre hasta el final" "$(tail -1 "$OUT/last.txt")"
    fi
done

echo "== C. Las soluciones pasan"
for c in caza1 caza2 caza3; do
    for t in 1 2 4; do
        run_ok "soluciones/${c}_fixed con $t hilos" "$t" "$TIMEOUT" "$OUT/${c}_fixed"
    done
    run_ok "soluciones/${c}_fixed con 3 hilos y n=1000003 (no divisible)" 3 "$TIMEOUT" "$OUT/${c}_fixed" 1000003
done

echo "== D. ThreadSanitizer"
if "$CC" $TSANFLAGS caza1_race_buggy.c -o "$OUT/caza1_tsan" -lm >"$OUT/tsan_cc.log" 2>&1; then
    OMP_NUM_THREADS=4 TSAN_OPTIONS="halt_on_error=1" timeout -k 2 30 "$OUT/caza1_tsan" 200000 >"$OUT/tsan.txt" 2>&1
    if grep -q "ThreadSanitizer: data race" "$OUT/tsan.txt" && grep -q "caza1_race_buggy.c:3[0-9]" "$OUT/tsan.txt"; then
        ok "TSan detecta la carrera de caza1 en el cuerpo del for (líneas 30-39)"
    else
        ko "TSan detecta la carrera de caza1" "$(grep -m1 SUMMARY "$OUT/tsan.txt")"
    fi
else
    sk "ThreadSanitizer no disponible (gcc -fsanitize=thread no compila aquí)"
fi

echo "== E. Ejemplo resuelto"
OMP_NUM_THREADS=4 "$OUT/ejemplo" 16 >"$OUT/last.txt" 2>&1
if grep -q "^hits = 8  (referencia secuencial 8)  ok" "$OUT/last.txt" && grep -q "mapas iguales en los dos ciclos: si" "$OUT/last.txt"; then
    ok "ejemplo_revision n=16, 4 hilos: hits = 8 y mapas iguales"
else
    ko "ejemplo_revision n=16, 4 hilos: hits = 8 y mapas iguales" "$(grep -E 'hits =|mapas' "$OUT/last.txt" | tr '\n' ' ')"
fi
run_ok "ejemplo_revision medir n=1000000, 4 hilos: resultado correcto en las 6 corridas" 4 "$TIMEOUT" "$OUT/ejemplo" medir 1000000
OMP_NUM_THREADS=4 "$OUT/ejemplo_falla" 64 >"$OUT/last.txt" 2>&1
if grep -q "mapas iguales en los dos ciclos: NO" "$OUT/last.txt"; then
    ok "variante que falla (dynamic,1 en el ciclo 1): los mapas ya no coinciden"
else
    ko "variante que falla: los mapas ya no coinciden"
fi

echo "== F. Ítems del examen de práctica (salidas de la clave)"
OMP_NUM_THREADS=4 "$OUT/II1" >"$OUT/last.txt" 2>&1
if grep -qx "base=10 out=10 11 12 15 14 19 16 23 " "$OUT/last.txt"; then ok "II.1 con 4 hilos: base=10 out=10 11 12 15 14 19 16 23"; else ko "II.1 con 4 hilos" "$(cat "$OUT/last.txt")"; fi
OMP_NUM_THREADS=1 "$OUT/II1" >"$OUT/last.txt" 2>&1
if grep -qx "base=10 out=10 11 13 16 20 25 31 38 " "$OUT/last.txt"; then ok "II.1 con 1 hilo: out=10 11 13 16 20 25 31 38"; else ko "II.1 con 1 hilo" "$(cat "$OUT/last.txt")"; fi
"$OUT/II2" >"$OUT/last.txt" 2>&1
if grep -qx "owner=0 0 1 1 2 2 3 3 0 0 1 1 " "$OUT/last.txt" && [ "$(grep -c "single ejecutado" "$OUT/last.txt")" -eq 1 ]; then
    ok "II.2: owner=0 0 1 1 2 2 3 3 0 0 1 1 y una sola línea del single"
else
    ko "II.2" "$(cat "$OUT/last.txt" | tr '\n' ' ')"
fi
if OMP_NUM_THREADS=4 "$OUT/III1_buggy" >"$OUT/last.txt" 2>&1; then info "III.1 con el error dio OK en esta corrida (no cuenta)"; else ok "III.1 con el error: status=INCORRECTO"; fi
for t in 1 4; do run_ok "III.1 corregido (reduction) con $t hilos" "$t" "$TIMEOUT" "$OUT/III1_fixed"; done
if OMP_NUM_THREADS=4 "$OUT/III2_buggy" >"$OUT/last.txt" 2>&1; then info "III.2 con el error dio OK en esta corrida (no cuenta)"; else ok "III.2 con el error: status=INCORRECTO"; fi
for t in 1 3 4; do run_ok "III.2 corregido (dos fases) con $t hilos" "$t" "$TIMEOUT" "$OUT/III2_fixed"; done
run_ok "III.2 corregido con 4 hilos y n=1000003" 4 "$TIMEOUT" "$OUT/III2_fixed" 1000003
for t in 1 4; do run_ok "IV (tareas, huecos llenos) con $t hilos" "$t" "$TIMEOUT" "$OUT/IV"; done
run_ok "IV con 4 hilos, n=100000 y cutoff=1000" 4 "$TIMEOUT" "$OUT/IV" 100000 1000
python3 examen_items/item_V_numeros.py >"$OUT/last.txt" 2>&1
if grep -q "f_p=0.80" "$OUT/last.txt" && grep -q "S(4)=2.50  S(inf)=5.0" "$OUT/last.txt" && grep -q "S(4)=2.11  E(4)=0.53" "$OUT/last.txt" && grep -q "Karp-Flatt: f=0.30" "$OUT/last.txt"; then
    ok "V: f_p=0.80, S_Amdahl(4)=2.50, S(inf)=5.0, S medido=2.11, E=0.53, Karp-Flatt f=0.30"
else
    ko "V números" "$(tr '\n' ' ' < "$OUT/last.txt")"
fi
run_ok "VI (Collatz) con 4 hilos y N=300000: las cuatro estrategias coinciden con la secuencial" 4 60 "$OUT/VI" 300000

echo "Resumen: $pass PASS, $fail FAIL, $skip SKIP"
[ "$fail" -eq 0 ]
