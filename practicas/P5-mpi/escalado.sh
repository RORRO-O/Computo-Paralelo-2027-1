#!/usr/bin/env bash
# escalado.sh — Parte D de la Práctica 5: escalabilidad FUERTE (tamaño fijo) y DÉBIL (tamaño por
# proceso fijo) con 1, 2 y 4 procesos, más 8 sobre-suscrito (declarado y etiquetado aparte).
#
# Produce, con el formato del protocolo de medición del curso (herramientas/protocolo-medicion.md):
#   $OUT/fuerte.csv   config,hilos,n,rep1..rep5,mediana_s,speedup,eficiencia   (speedup = T_seq / T(p))
#   $OUT/debil.csv    misma cabecera; aquí eficiencia = eficiencia débil T_seq(n_local)/T(p, p·n_local)
#                     y speedup = p × eficiencia (speedup escalado, Gustafson)
#   $OUT/entorno.txt  CPU, núcleos físicos, compilador, MPI, banderas, CPU ociosa antes de medir
#   $OUT/fuerte.png, $OUT/debil.png (graficar.py; PLOT=0 para omitir)
# La columna se llama "hilos" por el formato fijo del protocolo; en MPI son procesos.
#
# Qué programa se mide (PROG) y sus tamaños (variables de entorno, todas opcionales):
#   PROG=heat    (por defecto)  N=1000000 ITERS=1200 NLOCAL=250000 CHECK_EVERY=1   -> c_heat_seq / c_heat_mpi (tol = 0)
#   PROG=matvec                 M=2000 NCOLS=2000 ITERS=200 MLOCAL=500            -> b_matvec_seq / b_matvec_mpi (M filas)
#   PROG=primes                 A=2 B=3000000 LEN=750000 MODO=ciclico             -> c_primes_seq / c_primes_mpi
#   PROCS="1 2 4"  OVERSUB=8 (OVERSUB="" para omitirlo)  OUT=resultados  PLOT=1  MPIRUN_FLAGS="--oversubscribe"
#   WAIT_IDLE=0    segundos máximos a esperar antes de CADA corrida a que la CPU esté >= 90 % ociosa
# Cada programa hace 1 calentamiento + 5 repeticiones y reporta la mediana (línea TIME,...).
# Regla del protocolo que más importa aquí: CIERRA LO DEMÁS. Con p = núcleos, cualquier otro proceso
# activo le roba un núcleo a un rango MPI que hace sondeo activo y distorsiona todo.
set -euo pipefail
cd "$(dirname "$0")"

PROG=${PROG:-heat}
PROCS=${PROCS:-"1 2 4"}
OVERSUB=${OVERSUB-8}
OUT=${OUT:-resultados}
PLOT=${PLOT:-1}
WAIT_IDLE=${WAIT_IDLE:-0}
MPIRUN_FLAGS=${MPIRUN_FLAGS:---oversubscribe}
REPS=5
N=${N:-1000000};      ITERS_HEAT=${ITERS:-1200};   NLOCAL=${NLOCAL:-250000}; CHECK_EVERY=${CHECK_EVERY:-1}
M=${M:-2000};         NCOLS=${NCOLS:-2000};       ITERS_MV=${ITERS:-200};   MLOCAL=${MLOCAL:-500}
A=${A:-2};            B=${B:-3000000};            LEN=${LEN:-750000};       MODO=${MODO:-ciclico}

if [ "$(id -u)" -eq 0 ]; then
    export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
fi
CORES=$(lscpu -p=CORE,SOCKET 2>/dev/null | grep -v '^#' | sort -u | wc -l)   # núcleos FÍSICOS
[ "${CORES:-0}" -ge 1 ] || CORES=$(nproc)
LOGICAL=$(nproc)
mkdir -p "$OUT"
make -s all

case "$PROG" in
    heat)   SEQ=./src/c_heat_seq;   MPI=./src/c_heat_mpi;   STRONG=$N;            LOCAL=$NLOCAL; DESC="calor 1D: N=$N ITERS=$ITERS_HEAT CHECK_EVERY=$CHECK_EVERY; debil NLOCAL=$NLOCAL" ;;
    matvec) SEQ=./src/b_matvec_seq; MPI=./src/b_matvec_mpi; STRONG=$M;            LOCAL=$MLOCAL; DESC="matriz-vector: M=$M NCOLS=$NCOLS ITERS=$ITERS_MV; debil MLOCAL=$MLOCAL" ;;
    primes) SEQ=./src/c_primes_seq; MPI=./src/c_primes_mpi; STRONG=$((B - A + 1)); LOCAL=$LEN;  DESC="primos: [$A,$B] MODO=$MODO; debil LEN=$LEN" ;;
    *) echo "PROG debe ser heat, matvec o primes (es '$PROG')" >&2; exit 2 ;;
esac

# Argumentos de cada programa según PROG; $1 = tamaño (n, filas o longitud del intervalo)
seq_args() { case "$PROG" in heat) echo "$1 $ITERS_HEAT 0 $CHECK_EVERY $REPS" ;; matvec) echo "$1 $NCOLS $ITERS_MV $REPS" ;; primes) echo "$A $((A + $1 - 1)) $REPS" ;; esac; }
mpi_args() { case "$PROG" in heat) echo "$1 $ITERS_HEAT 0 $CHECK_EVERY $REPS" ;; matvec) echo "$1 $NCOLS $ITERS_MV $REPS" ;; primes) echo "$A $((A + $1 - 1)) $MODO $REPS" ;; esac; }

HEADER="config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia"

# % de CPU ociosa durante 1 s (todas las CPU), leído de /proc/stat
cpu_idle_pct() {
    local a b
    a=$(head -1 /proc/stat); sleep 1; b=$(head -1 /proc/stat)
    awk -v a="$a" -v b="$b" 'BEGIN { split(a, x, " "); split(b, y, " "); ta = 0; tb = 0
        for (i = 2; i <= 9; i++) { ta += x[i]; tb += y[i] }
        printf "%d", (tb > ta) ? 100 * (y[5] - x[5]) / (tb - ta) : 0 }'
}
wait_idle() {
    [ "$WAIT_IDLE" -le 0 ] && return 0
    local waited=0 idle=0
    while [ "$waited" -lt "$WAIT_IDLE" ]; do
        idle=$(cpu_idle_pct); waited=$((waited + 1))
        [ "$idle" -ge 90 ] && return 0
    done
    echo "== AVISO: tras $WAIT_IDLE s la CPU sigue ocupada (${idle}% ociosa); se mide con carga ajena." >&2
}
IDLE0=$(cpu_idle_pct)
LOAD1=$(cut -d' ' -f1 /proc/loadavg)
if [ "$IDLE0" -lt 85 ]; then
    echo "== AVISO: solo ${IDLE0}% de CPU ociosa antes de medir (carga 1 min = $LOAD1). Hay otros procesos usando CPU;"
    echo "          las mediciones con p = $CORES saldrán distorsionadas. Cierra lo demás y repite."
fi

# Línea TIME,t1;...;t5,mediana,min,max -> "t1,...,t5,mediana"
time_line() { grep '^TIME,' | tail -1; }
reps_and_median() { echo "$1" | awk -F, '{ gsub(";", ",", $2); print $2 "," $3 }'; }
median_of() { echo "$1" | awk -F, '{ print $3 }'; }
valid() { [ "$(echo "${1:-}" | awk -F, '{ print NF }')" = 5 ] && [ "$(echo "$1" | awk -F, '{ print split($2, a, ";") }')" = "$REPS" ]; }
run_seq() { # $1 = tamaño
    local line attempt
    for attempt in 1 2; do
        wait_idle
        # shellcheck disable=SC2046
        line=$("$SEQ" $(seq_args "$1") | time_line || true)
        if valid "$line"; then echo "$line"; return 0; fi
        echo "== AVISO: $SEQ (tamaño $1) no dio una línea TIME válida (intento $attempt); se repite." >&2
    done
    echo "== ERROR: $SEQ falló dos veces." >&2; return 1
}
run_mpi() { # $1 = p, $2 = tamaño
    local line attempt
    for attempt in 1 2; do
        wait_idle
        # shellcheck disable=SC2046,SC2086
        line=$(mpirun $MPIRUN_FLAGS -np "$1" "$MPI" $(mpi_args "$2") | time_line || true)
        if valid "$line"; then echo "$line"; return 0; fi
        echo "== AVISO: $MPI p=$1 (tamaño $2) no dio una línea TIME válida (intento $attempt); se repite." >&2
    done
    echo "== ERROR: $MPI p=$1 falló dos veces (¿OMPI_ALLOW_RUN_AS_ROOT? ¿slots? ¿TODO pendiente?)." >&2; return 1
}
label_for() { if [ "$1" -gt "$CORES" ]; then echo mpi_oversub; else echo mpi; fi; }

echo "== $DESC"
echo "== Entorno: $CORES núcleos físicos ($LOGICAL CPU lógicas); REPS=$REPS (+1 calentamiento); MPIRUN_FLAGS='$MPIRUN_FLAGS'; CPU ociosa ${IDLE0}%"
{
    echo "fecha: $(date -Is)"
    echo "programa: $PROG ($DESC)"
    echo "cpu: $(lscpu | awk -F: '/Model name/ {gsub(/^ +/, "", $2); print $2}')"
    echo "nucleos_fisicos: $CORES  (CPU logicas: $LOGICAL; hilos por nucleo: $(lscpu | awk -F: '/Thread\(s\) per core/ {gsub(/ /, "", $2); print $2}'))"
    echo "ram: $(awk '/MemTotal/ {printf "%.1f GiB", $2 / 1048576}' /proc/meminfo)"
    echo "sistema: $(uname -sr)"
    echo "compilador: $(mpicc --version | head -1)"
    echo "mpi: $(mpirun --version | head -1)"
    echo "flags: -std=c11 -O2 -Wall -Wextra ; mpirun $MPIRUN_FLAGS"
    echo "cpu_ociosa_antes_de_medir: ${IDLE0}%  (debe ser >= 85 %)"
    echo "carga_promedio_1min_antes_de_medir: $LOAD1"
    echo "wait_idle_s: $WAIT_IDLE"
    echo "procs: '$PROCS' oversub: '$OVERSUB'"
} > "$OUT/entorno.txt"

# ---------- Escalabilidad fuerte: tamaño fijo ----------
echo "== Escalabilidad fuerte: tamaño=$STRONG"
echo "$HEADER" > "$OUT/fuerte.csv"
line=$(run_seq "$STRONG"); T_SEQ=$(median_of "$line")
echo "seq,1,$STRONG,$(reps_and_median "$line"),1.0000,1.0000" >> "$OUT/fuerte.csv"
printf "%-12s %3s %10s %10s %8s %8s\n" config p n mediana_s speedup efic
printf "%-12s %3s %10s %10s %8s %8s\n" seq 1 "$STRONG" "$T_SEQ" 1.0000 1.0000
for p in $PROCS $OVERSUB; do
    label=$(label_for "$p"); line=$(run_mpi "$p" "$STRONG"); T=$(median_of "$line")
    read -r S E < <(awk -v t1="$T_SEQ" -v t="$T" -v p="$p" 'BEGIN { s = t1 / t; printf "%.4f %.4f\n", s, s / p }')
    echo "$label,$p,$STRONG,$(reps_and_median "$line"),$S,$E" >> "$OUT/fuerte.csv"
    printf "%-12s %3s %10s %10s %8s %8s\n" "$label" "$p" "$STRONG" "$T" "$S" "$E"
done

# ---------- Escalabilidad débil: tamaño por proceso fijo ----------
echo "== Escalabilidad débil: tamaño por proceso=$LOCAL"
echo "$HEADER" > "$OUT/debil.csv"
line=$(run_seq "$LOCAL"); T_W1=$(median_of "$line")
echo "seq,1,$LOCAL,$(reps_and_median "$line"),1.0000,1.0000" >> "$OUT/debil.csv"
printf "%-12s %3s %10s %10s %8s %8s\n" config p n mediana_s S_escal efic_debil
printf "%-12s %3s %10s %10s %8s %8s\n" seq 1 "$LOCAL" "$T_W1" 1.0000 1.0000
for p in $PROCS $OVERSUB; do
    label=$(label_for "$p"); n=$((p * LOCAL)); line=$(run_mpi "$p" "$n"); T=$(median_of "$line")
    read -r S E < <(awk -v t1="$T_W1" -v t="$T" -v p="$p" 'BEGIN { e = t1 / t; printf "%.4f %.4f\n", p * e, e }')
    echo "$label,$p,$n,$(reps_and_median "$line"),$S,$E" >> "$OUT/debil.csv"
    printf "%-12s %3s %10s %10s %8s %8s\n" "$label" "$p" "$n" "$T" "$S" "$E"
done

[ -n "$OVERSUB" ] && echo "== Aviso: p=$OVERSUB > $CORES núcleos -> sobre-suscrito; etiquetado mpi_oversub, se reporta aparte."
echo "== CSV: $OUT/fuerte.csv, $OUT/debil.csv ; entorno: $OUT/entorno.txt"
if [ "$PLOT" = "1" ]; then
    python3 graficar.py "$OUT/fuerte.csv" "$OUT/debil.csv" "$OUT" --titulo "$PROG"
fi
