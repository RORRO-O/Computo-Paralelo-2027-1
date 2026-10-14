#!/usr/bin/env bash
# escalado.sh — Corre Jacobi 1D con 1, 2, 4 procesos (y 8 sobre-suscrito, declarado),
# en escalabilidad fuerte (n fijo) y débil (n/p fijo), y escribe CSV con el formato
# del protocolo de medición del curso + gráficas (graficar.py).
#
# Variables de entorno (todas opcionales):
#   N=1000000        puntos del problema fijo (fuerte)
#   ITERS=1200       iteraciones de Jacobi (con N=1000000 la secuencial tarda ~1 s)
#   NLOCAL=250000    puntos por proceso (débil); n = p * NLOCAL
#   PROCS="1 2 4"    procesos dentro del número de núcleos
#   OVERSUB=8        procesos sobre-suscritos (OVERSUB="" para omitir)
#   OUT=resultados   carpeta de salida
#   PLOT=1           0 para no graficar
#   WAIT_IDLE=0      segundos máximos a esperar, antes de CADA corrida, a que la CPU esté >= 90 % ociosa
#                    (útil en máquinas compartidas; 0 = no esperar)
#   MPIRUN_FLAGS="--oversubscribe"
#
# Cada corrida hace 1 calentamiento + 5 repeticiones dentro del programa;
# aquí se calculan speedup y eficiencia contra jacobi_seq (el mejor secuencial).
set -euo pipefail
cd "$(dirname "$0")"

N=${N:-1000000}
ITERS=${ITERS:-1200}
NLOCAL=${NLOCAL:-250000}
PROCS=${PROCS:-"1 2 4"}
OVERSUB=${OVERSUB-8}
OUT=${OUT:-resultados}
PLOT=${PLOT:-1}
WAIT_IDLE=${WAIT_IDLE:-0}
MPIRUN_FLAGS=${MPIRUN_FLAGS:---oversubscribe}
REPS=5

if [ "$(id -u)" -eq 0 ]; then
    export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
fi
CORES=$(nproc)
mkdir -p "$OUT"
make -s all

# Carga del sistema ANTES de medir (protocolo §1.5: "cierra lo demás"). Con p = núcleos,
# cualquier otro proceso activo roba un núcleo a un proceso MPI que hace sondeo activo y
# distorsiona todo; la carga se guarda en entorno.txt para poder explicar una medición rara.
LOAD1=$(cut -d' ' -f1 /proc/loadavg)
if awk -v l="$LOAD1" 'BEGIN { exit !(l > 0.5) }'; then
    echo "== AVISO: carga promedio (1 min) = $LOAD1 antes de medir. Hay otros procesos usando CPU;"
    echo "          las mediciones con p = $CORES saldrán distorsionadas. Cierra lo demás y repite."
fi

HEADER="config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia"
# Nota: la columna se llama "hilos" por el formato fijo del protocolo; en MPI son procesos.

# % de CPU ociosa (todas las CPU) durante 1 s, leído de /proc/stat
cpu_idle_pct() {
    local a b
    a=$(head -1 /proc/stat); sleep 1; b=$(head -1 /proc/stat)
    awk -v a="$a" -v b="$b" 'BEGIN { split(a, x, " "); split(b, y, " "); ta = 0; tb = 0
        for (i = 2; i <= 9; i++) { ta += x[i]; tb += y[i] }
        printf "%d", (tb > ta) ? 100 * (y[5] - x[5]) / (tb - ta) : 0 }'
}
# Espera (hasta WAIT_IDLE s) a que la CPU esté >= 90 % ociosa antes de una corrida
wait_idle() {
    [ "$WAIT_IDLE" -le 0 ] && return 0
    local waited=0 idle
    while [ "$waited" -lt "$WAIT_IDLE" ]; do
        idle=$(cpu_idle_pct); waited=$((waited + 1))
        [ "$idle" -ge 90 ] && return 0
    done
    echo "== AVISO: tras $WAIT_IDLE s la CPU sigue ocupada (${idle}% ociosa); se mide con carga ajena."
}

# Extrae de la línea RESULT los campos que van al CSV: "rep1,...,rep5,mediana"
reps_and_median() { # $1 = línea RESULT
    echo "$1" | awk -F, '{ gsub(";", ",", $6); print $6 "," $7 }'
}
median_of() { echo "$1" | awk -F, '{ print $7 }'; }

run_seq() { wait_idle; ./jacobi_seq "$1" "$ITERS" "$REPS" | grep '^RESULT'; }
run_mpi() { # $1 = p, $2 = n
    wait_idle
    mpirun $MPIRUN_FLAGS -np "$1" ./jacobi_mpi "$2" "$ITERS" "$REPS" | grep '^RESULT'
}
label_for() { if [ "$1" -gt "$CORES" ]; then echo mpi_oversub; else echo mpi; fi; }

echo "== Entorno: $CORES núcleos; ITERS=$ITERS; REPS=$REPS (+1 calentamiento); MPIRUN_FLAGS='$MPIRUN_FLAGS'"
{
    echo "fecha: $(date -Is)"
    echo "cpu: $(lscpu | awk -F: '/Model name/ {gsub(/^ +/, "", $2); print $2}')"
    echo "nucleos: $CORES  (hilos por núcleo: $(lscpu | awk -F: '/Thread\(s\) per core/ {gsub(/ /, "", $2); print $2}'))"
    echo "compilador: $(mpicc --version | head -1)"
    echo "mpi: $(mpirun --version | head -1)"
    echo "flags: -std=c11 -O2 -Wall -Wextra ; mpirun $MPIRUN_FLAGS"
    echo "carga_promedio_1min_antes_de_medir: $LOAD1  (debe ser cercana a 0)"
    echo "wait_idle_s: $WAIT_IDLE"
    echo "fuerte: N=$N ITERS=$ITERS ; debil: NLOCAL=$NLOCAL ITERS=$ITERS ; PROCS='$PROCS' OVERSUB='$OVERSUB'"
} > "$OUT/entorno.txt"

# ---------- Escalabilidad fuerte: n fijo ----------
echo "== Escalabilidad fuerte: n=$N"
echo "$HEADER" > "$OUT/fuerte.csv"
line=$(run_seq "$N")
T_SEQ=$(median_of "$line")
echo "seq,1,$N,$(reps_and_median "$line"),1.0000,1.0000" >> "$OUT/fuerte.csv"
printf "%-12s %3s %10s %10s %8s %8s\n" config p n mediana_s speedup efic
printf "%-12s %3s %10s %10s %8s %8s\n" seq 1 "$N" "$T_SEQ" 1.0000 1.0000
for p in $PROCS $OVERSUB; do
    label=$(label_for "$p")
    line=$(run_mpi "$p" "$N")
    T=$(median_of "$line")
    read -r S E < <(awk -v t1="$T_SEQ" -v t="$T" -v p="$p" 'BEGIN { s = t1 / t; printf "%.4f %.4f\n", s, s / p }')
    echo "$label,$p,$N,$(reps_and_median "$line"),$S,$E" >> "$OUT/fuerte.csv"
    printf "%-12s %3s %10s %10s %8s %8s\n" "$label" "$p" "$N" "$T" "$S" "$E"
done

# ---------- Escalabilidad débil: n/p fijo ----------
echo "== Escalabilidad débil: n/p=$NLOCAL"
echo "$HEADER" > "$OUT/debil.csv"
line=$(run_seq "$NLOCAL")
T_W1=$(median_of "$line")
echo "seq,1,$NLOCAL,$(reps_and_median "$line"),1.0000,1.0000" >> "$OUT/debil.csv"
printf "%-12s %3s %10s %10s %8s %8s\n" config p n mediana_s S_escal efic_debil
printf "%-12s %3s %10s %10s %8s %8s\n" seq 1 "$NLOCAL" "$T_W1" 1.0000 1.0000
for p in $PROCS $OVERSUB; do
    label=$(label_for "$p")
    n=$((p * NLOCAL))
    line=$(run_mpi "$p" "$n")
    T=$(median_of "$line")
    # eficiencia débil E = T(1,n)/T(p,p·n); "speedup" = speedup escalado p·E (Gustafson)
    read -r S E < <(awk -v t1="$T_W1" -v t="$T" -v p="$p" 'BEGIN { e = t1 / t; printf "%.4f %.4f\n", p * e, e }')
    echo "$label,$p,$n,$(reps_and_median "$line"),$S,$E" >> "$OUT/debil.csv"
    printf "%-12s %3s %10s %10s %8s %8s\n" "$label" "$p" "$n" "$T" "$S" "$E"
done

if [ -n "$OVERSUB" ]; then
    echo "== Aviso: p=$OVERSUB > $CORES núcleos -> sobre-suscrito; etiquetado mpi_oversub, se reporta aparte."
fi
echo "== CSV: $OUT/fuerte.csv, $OUT/debil.csv ; entorno: $OUT/entorno.txt"

if [ "$PLOT" = "1" ]; then
    python3 graficar.py "$OUT/fuerte.csv" "$OUT/debil.csv" "$OUT"
fi
