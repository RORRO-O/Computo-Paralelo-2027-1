#!/usr/bin/env bash
# Pruebas de la práctica guiada S09 · Paralelismo de tareas (task, taskwait, taskloop, cutoff).
# Compila sin warnings, comprueba el número de tareas que fija la recursión (no depende de los hilos),
# que cada versión con tareas produce el mismo resultado que la secuencial, y que los programas con error
# a propósito muestran el síntoma documentado. Termina con 0 solo si todo pasa. Tamaños pequeños (< 10 s).

set -u
cd "$(dirname "$0")/.."

CFLAGS="-std=c11 -O2 -Wall -Wextra -fopenmp"
export OMP_NUM_THREADS=4
export REPS=1
pass=0
fail=0

ok()    { echo "PASS  $1"; pass=$((pass + 1)); }
bad()   { echo "FAIL  $1"; fail=$((fail + 1)); }
check() { if [ "$1" -eq 0 ]; then ok "$2"; else bad "$2"; fi; }

# --- 1. Compilación sin warnings -------------------------------------------
for src in mergesort_tasks fib_tasks fib_buggy taskwait_buggy list_tasks taskloop_demo tree_sum_tasks; do
    out=$(gcc $CFLAGS "$src.c" -o "$src" -lm 2>&1)
    if [ $? -ne 0 ] || [ -n "$out" ]; then
        bad "compila sin warnings: $src.c"
        echo "$out" | head -5
    else
        ok "compila sin warnings: $src.c"
    fi
done

# --- 2. mergesort: el número de tareas lo fija la recursión, no los hilos ----
tasks_of() { ./mergesort_tasks "$1" "$2" | grep -o 'tareas creadas = [0-9]*' | grep -o '[0-9]*$'; }
check "$([ "$(tasks_of 8 2)" = "6" ]; echo $?)"       "mergesort n=8  cutoff=2  -> 6 tareas"
check "$([ "$(tasks_of 8 1)" = "14" ]; echo $?)"      "mergesort n=8  cutoff=1  -> 14 tareas"
check "$([ "$(tasks_of 8 4)" = "2" ]; echo $?)"       "mergesort n=8  cutoff=4  -> 2 tareas"
check "$([ "$(tasks_of 8 8)" = "0" ]; echo $?)"       "mergesort n=8  cutoff=8  -> 0 tareas"
check "$([ "$(tasks_of 16 2)" = "14" ]; echo $?)"     "mergesort n=16 cutoff=2  -> 14 tareas"
check "$([ "$(tasks_of 1024 1)" = "2046" ]; echo $?)" "mergesort n=1024 cutoff=1 -> 2046 tareas (2n-2)"
check "$([ "$(OMP_NUM_THREADS=1 ./mergesort_tasks 8 2 | grep -o 'tareas creadas = [0-9]*' | grep -o '[0-9]*$')" = "6" ]; echo $?)" \
      "mergesort n=8 cutoff=2 con 1 hilo -> también 6 tareas (las crea el único hilo)"

# traza: con n=8 y cutoff=2 salen exactamente 6 líneas "tarea [" y la salida está ordenada
out=$(./mergesort_tasks 8 2)
n_lines=$(echo "$out" | grep -c '^  tarea \[')
check "$([ "$n_lines" -eq 6 ] && echo "$out" | grep -q 'verificacion: OK'; echo $?)" "traza n=8 cutoff=2: 6 líneas de tarea y verificacion OK"

# --- 3. mergesort: ordena bien con tamaños no potencia de 2 y cutoffs extremos
for args in "100003 1" "100000 1024" "65536 70000" "1 1" "2 1" "33 5" "1000 3"; do
    out=$(./mergesort_tasks $args 2>&1); rc=$?
    check "$([ $rc -eq 0 ] && echo "$out" | grep -q 'verificacion: OK'; echo $?)" "mergesort $args: ordenado e igual a la secuencial"
done
out=$(OMP_NUM_THREADS=1 ./mergesort_tasks 50000 64 2>&1); rc=$?
check "$([ $rc -eq 0 ] && echo "$out" | grep -q 'verificacion: OK'; echo $?)" "mergesort 50000 64 con 1 hilo: correcto"

# --- 4. fib_tasks: resultado y conteo 2*(fib(n-c+3)-1) ------------------------
fib_tasks_count() { ./fib_tasks "$1" "$2" | grep -o 'tareas creadas = [0-9]*' | grep -o '[0-9]*$'; }
out=$(./fib_tasks 25 10); rc=$?
check "$([ $rc -eq 0 ] && echo "$out" | grep -q '^fib(25) = 75025' && echo "$out" | grep -q 'verificacion: OK'; echo $?)" "fib_tasks 25 10: fib(25)=75025 y verificacion OK"
check "$([ "$(fib_tasks_count 25 10)" = "5166" ]; echo $?)" "fib_tasks 25 10 -> 5166 tareas = 2*(fib(18)-1)"
check "$([ "$(fib_tasks_count 20 20)" = "2" ]; echo $?)"    "fib_tasks 20 20 -> 2 tareas (solo la raíz crea)"
check "$([ "$(fib_tasks_count 15 20)" = "0" ]; echo $?)"    "fib_tasks 15 20 -> 0 tareas (todo bajo el corte)"

# --- 5. fib_buggy: sin shared(x) el resultado es 0, siempre ------------------
out=$(./fib_buggy 25 10); rc=$?
check "$([ $rc -eq 0 ] && echo "$out" | grep -q ': 0   esperado 75025   -> INCORRECTO'; echo $?)" "fib_buggy 25 10: devuelve 0 e informa INCORRECTO"

# --- 6. taskwait_buggy: corre; después de la barrera el resultado es correcto -
out=$(./taskwait_buggy 200000); rc=$?
check "$([ $rc -eq 0 ] && echo "$out" | grep -q 'despues de la barrera del single  : 900000  -> correcto'; echo $?)" "taskwait_buggy 200000: tras la barrera 900000 correcto"
# (la lectura prematura es una carrera a propósito: no se prueba su valor, se observa con make tsan)

# --- 7. list_tasks: cada nodo exactamente una vez; suma igual a la secuencial --
out=$(./list_tasks 8); rc=$?
nodes=$(echo "$out" | grep -o 'nodo [0-9]* procesado' | grep -o '[0-9]*' | sort -n | tr '\n' ' ')
check "$([ $rc -eq 0 ] && [ "$nodes" = "0 1 2 3 4 5 6 7 " ] && echo "$out" | grep -q 'verificacion: OK'; echo $?)" "list_tasks 8: nodos 0..7 una vez cada uno, verificacion OK"
out=$(./list_tasks 300); rc=$?
check "$([ $rc -eq 0 ] && echo "$out" | grep -q 'verificacion: OK'; echo $?)" "list_tasks 300: verificacion OK"

# --- 8. taskloop_demo: mapa completo con hilos válidos; suma igual a la secuencial
m=$(./taskloop_demo 16 4 | grep '^taskloop' | cut -d'|' -f2 | tr -s ' ' | sed 's/^ //; s/ $//')
n_items=$(echo "$m" | wc -w)
invalid=$(echo "$m" | tr ' ' '\n' | grep -vc '^[0-3]$')
check "$([ "$n_items" -eq 16 ] && [ "$invalid" -eq 0 ]; echo $?)" "taskloop_demo 16 4: 16 iteraciones asignadas a hilos 0..3"
out=$(./taskloop_demo 20000 64); rc=$?
check "$([ $rc -eq 0 ] && echo "$out" | grep -q 'verificacion: OK'; echo $?)" "taskloop_demo 20000 64: for dinámico y taskloop coinciden con la secuencial"

# --- 9. tree_sum_tasks (fase Crear): base con TODO pendiente o solución correcta
out=$(./tree_sum_tasks 100000 6); rc=$?
if echo "$out" | grep -q 'TODO pendiente'; then
    check "$([ $rc -eq 0 ] && echo "$out" | grep -q 'secuencial : suma = 10753712'; echo $?)" "tree_sum_tasks 100000: base compila y la suma secuencial es 10753712 (TODO pendiente: fase Crear)"
else
    check "$([ $rc -eq 0 ] && echo "$out" | grep -q 'verificacion: OK'; echo $?)" "tree_sum_tasks 100000 6: suma con tareas igual a la secuencial"
fi

echo
echo "Resumen: $pass PASS, $fail FAIL"
[ "$fail" -eq 0 ]
