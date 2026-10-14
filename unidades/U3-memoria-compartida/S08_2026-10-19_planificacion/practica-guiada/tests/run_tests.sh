#!/usr/bin/env bash
# Pruebas de la práctica guiada S08 · Planificación y balance de carga.
# Compila sin warnings, comprueba los mapas de asignación que la especificación
# de OpenMP fija (static y static,chunk), la cobertura de los mapas dinámicos,
# y que cada política produce el mismo resultado que la versión secuencial.
# Termina con 0 solo si todo pasa. Tamaños pequeños: todo corre en pocos segundos.

set -u
cd "$(dirname "$0")/.."

CFLAGS="-std=c11 -O2 -Wall -Wextra -fopenmp"
export OMP_NUM_THREADS=4
export REPS=1
pass=0
fail=0

ok()   { echo "PASS  $1"; pass=$((pass + 1)); }
bad()  { echo "FAIL  $1"; fail=$((fail + 1)); }
check() { if [ "$1" -eq 0 ]; then ok "$2"; else bad "$2"; fi; }

# --- 1. Compilación sin warnings -------------------------------------------
for src in schedule_map collapse_map unbalanced nowait_buggy; do
    out=$(gcc $CFLAGS "$src.c" -o "$src" -lm 2>&1)
    if [ $? -ne 0 ] || [ -n "$out" ]; then
        bad "compila sin warnings: $src.c"
        echo "$out" | head -5
    else
        ok "compila sin warnings: $src.c"
    fi
done

# Extrae la línea de un mapa y deja solo la secuencia owner[i] (16 números).
map_of() {   # $1 = etiqueta, resto = argumentos de schedule_map
    local label="$1"; shift
    ./schedule_map "$@" | grep "^$label " | cut -d'|' -f2 | tr -s ' ' | sed 's/^ //; s/ $//'
}

# --- 2. static sin chunk: bloques contiguos, tamaños que difieren en ≤ 1 -----
m=$(map_of "static" 16 static 0 uniform)
check "$([ "$m" = "0 0 0 0 1 1 1 1 2 2 2 2 3 3 3 3" ]; echo $?)" "static n=16, 4 hilos -> bloques de 4 contiguos"

m=$(map_of "static" 18 static 0 uniform)
# 18 iteraciones: la especificación pide trozos "aproximadamente iguales", uno por hilo.
contiguous=$(echo "$m" | tr ' ' '\n' | uniq | tr '\n' ' ' | sed 's/ $//')
counts=$(echo "$m" | tr ' ' '\n' | sort | uniq -c | awk '{print $1}' | sort -n | tr '\n' ' ')
check "$([ "$contiguous" = "0 1 2 3" ] && [ "$counts" = "4 4 5 5 " ]; echo $?)" "static n=18 -> 4 bloques contiguos de 5,5,4,4"

# --- 3. static,chunk: reparto cíclico fijado por la especificación -----------
m=$(map_of "static,2" 16 static 2 uniform)
check "$([ "$m" = "0 0 1 1 2 2 3 3 0 0 1 1 2 2 3 3" ]; echo $?)" "static,2 n=16 -> cíclico por bloques de 2"

m=$(map_of "static,1" 16 static 1 uniform)
check "$([ "$m" = "0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3" ]; echo $?)" "static,1 n=16 -> cíclico de 1 en 1"

m=$(map_of "static,5" 16 static 5 uniform)
check "$([ "$m" = "0 0 0 0 0 1 1 1 1 1 2 2 2 2 2 3" ]; echo $?)" "static,5 n=16 -> 5,5,5,1"

# --- 4. dynamic / guided / runtime: cada iteración exactamente una vez, hilo válido
for pol in "dynamic 0" "dynamic 3" "guided 0" "guided 2"; do
    set -- $pol
    m=$(./schedule_map 16 $1 $2 uniform | tail -1 | cut -d'|' -f2 | tr -s ' ' | sed 's/^ //; s/ $//')
    n_items=$(echo "$m" | wc -w)
    invalid=$(echo "$m" | tr ' ' '\n' | grep -vc '^[0-3]$')
    check "$([ "$n_items" -eq 16 ] && [ "$invalid" -eq 0 ]; echo $?)" "$1,$2: 16 iteraciones asignadas a hilos 0..3"
done

# runtime obedece a OMP_SCHEDULE (static,4 es determinista)
m=$(OMP_SCHEDULE="static,4" ./schedule_map 16 runtime | tail -1 | cut -d'|' -f2 | tr -s ' ' | sed 's/^ //; s/ $//')
check "$([ "$m" = "0 0 0 0 1 1 1 1 2 2 2 2 3 3 3 3" ]; echo $?)" "runtime con OMP_SCHEDULE=static,4 -> bloques de 4"
lbl=$(OMP_SCHEDULE="guided,3" ./schedule_map 16 runtime | tail -1 | cut -d'|' -f1 | tr -d ' ')
check "$([ "$lbl" = "runtime=guided,3" ]; echo $?)" "runtime reporta la política de OMP_SCHEDULE (guided,3)"

# --- 5. collapse: sin collapse un hilo ocioso con 3 filas; con collapse ninguno
out=$(./collapse_map 3 6)
idle_a=$(echo "$out" | sed -n '/^A)/,/^B)/p' | grep -o 'hilos sin trabajo: [0-9]*' | grep -o '[0-9]*$')
idle_b=$(echo "$out" | sed -n '/^B)/,/^C)/p' | grep -o 'hilos sin trabajo: [0-9]*' | grep -o '[0-9]*$')
cells_b=$(echo "$out" | sed -n '/^B)/,/^C)/p' | grep 'celdas por hilo' | sed 's/.*hilo: //; s/ *(.*//')
check "$([ "$idle_a" = "1" ] && [ "$idle_b" = "0" ] && [ "$cells_b" = "5 5 4 4" ]; echo $?)" "collapse(2) 3x6: sin collapse 1 hilo ocioso; con collapse 5,5,4,4 celdas"

# --- 6. unbalanced: todas las políticas coinciden con la secuencial -----------
run_unbal() {  # $1 = nombre, resto = args
    local name="$1"; shift
    out=$(./unbalanced "$@" 2>&1); rc=$?
    n_ok=$(echo "$out" | grep -c '| OK ')
    n_fail=$(echo "$out" | grep -c '| FAIL')
    check "$([ $rc -eq 0 ] && [ "$n_fail" -eq 0 ] && [ "$n_ok" -ge 1 ]; echo $?)" "$name: $n_ok políticas verificadas contra la secuencial"
}
run_unbal "uniform"    uniform    200000 static static,1 dynamic dynamic,64 guided auto
run_unbal "triangular" triangular 3000   static static,1 dynamic,16 guided,16
run_unbal "collatz"    collatz    100000 static dynamic,128 guided,32
run_unbal "mandelbrot" mandelbrot 120    static static,1 dynamic,4 guided,4
out=$(OMP_SCHEDULE="dynamic,8" ./unbalanced triangular 2000 runtime); rc=$?
check "$([ $rc -eq 0 ] && echo "$out" | grep -q 'runtime(dynamic,8)'; echo $?)" "unbalanced runtime usa OMP_SCHEDULE=dynamic,8"

# --- 7. nowait_buggy con static: la especificación garantiza el resultado ----
out=$(./nowait_buggy 400 static); rc=$?
check "$([ $rc -eq 0 ] && echo "$out" | grep -q 'incorrectas: 0 de 400'; echo $?)" "nowait + static idéntico en ambos ciclos -> 0 errores"
# (La variante dynamic es una carrera a propósito: no se prueba, se observa con make tsan.)

echo
echo "Resumen: $pass PASS, $fail FAIL"
[ "$fail" -eq 0 ]
