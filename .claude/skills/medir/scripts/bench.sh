#!/bin/bash
# bench.sh — Respaldo de herramientas/medir.sh con la misma interfaz y el mismo CSV del protocolo del curso.
# Úsalo solo si herramientas/medir.sh no existe en la rama (el oficial del curso manda).
# Uso: bench.sh [-c CONFIG] [-t "1 2 4 8"] [-n N] [-r 5] [-o resultados/mediciones.csv] [--t1 SEG] [--clave K] [--mpi] -- ./programa [args]
#   El programa imprime "tiempo_s=<segundos>" (o la clave de --clave) de la región de interés y acepta n como ÚLTIMO argumento.
#   Por cada valor de hilos: 1 calentamiento + R repeticiones; mediana, speedup = T1/mediana, eficiencia = speedup/hilos.
#   T1: --t1, o la primera fila con hilos=1 (y el mismo n) ya presente en el CSV (mide antes con -c secuencial -t 1),
#   o la fila con 1 hilo de esta corrida (entonces avisa: el protocolo pide la versión secuencial).
# CSV: config,hilos,n,rep1..repR,mediana_s,speedup,eficiencia  ·  además <carpeta del CSV>/entorno.txt
# Códigos de salida: 0 bien · 2 argumentos · 3 el CSV existente tiene otro encabezado · 4 el programa falló
set -uo pipefail
export LC_ALL=C
CONFIG=""; HILOS="1 2 4 8"; N=""; REPS=5; OUT="resultados/mediciones.csv"; T1=""; MODO=openmp; CLAVE="tiempo_s"
uso() { sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; }
err() { echo "bench.sh: $1 (usa -h)" >&2; exit 2; }
while [ $# -gt 0 ]; do
  case "$1" in
    -c) [ $# -ge 2 ] || err "-c requiere un valor"; CONFIG=$2; shift 2 ;;
    -t) [ $# -ge 2 ] || err "-t requiere un valor"; HILOS=$2; shift 2 ;;
    -n) [ $# -ge 2 ] || err "-n requiere un valor"; N=$2; shift 2 ;;
    -r) [ $# -ge 2 ] || err "-r requiere un valor"; REPS=$2; shift 2 ;;
    -o) [ $# -ge 2 ] || err "-o requiere un valor"; OUT=$2; shift 2 ;;
    --t1) [ $# -ge 2 ] || err "--t1 requiere un valor"; T1=$2; shift 2 ;;
    --clave) [ $# -ge 2 ] || err "--clave requiere un valor"; CLAVE=$2; shift 2 ;;
    --mpi) MODO=mpi; shift ;;
    -h|--help) uso; exit 0 ;;
    --) shift; break ;;
    -*) err "opción desconocida: $1" ;;
    *) break ;;
  esac
done
[ $# -ge 1 ] || err "falta el programa después de '--'"
PROG=$1; shift; ARGS=("$@")
[ -n "$CONFIG" ] || CONFIG=$MODO
[[ $CONFIG != *,* ]] || err "-c no puede contener comas"
[[ -z $N || $N =~ ^[0-9]+$ ]] || err "-n debe ser un entero"
[[ $REPS =~ ^[0-9]+$ && $REPS -ge 1 ]] || err "-r debe ser un entero >= 1"
[[ -z $T1 || $T1 =~ ^[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$ ]] || err "--t1 debe ser un número"
for p in $HILOS; do [[ $p =~ ^[0-9]+$ && $p -ge 1 ]] || err "valor de hilos no válido: '$p'"; done
command -v "$PROG" >/dev/null 2>&1 || err "no se encuentra '$PROG' (¿falta compilar o el prefijo ./?)"
[ "$REPS" -ge 5 ] || echo "AVISO: el protocolo exige >= 5 repeticiones; con $REPS la fila no cuenta como evidencia." >&2
MPIRUN_CMD=()
if [ "$MODO" = mpi ]; then
  command -v mpirun >/dev/null 2>&1 || err "--mpi requiere mpirun en el PATH"
  [ "$(id -u)" = 0 ] && export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
  # shellcheck disable=SC2206  # MPIRUN_FLAGS se divide a propósito por espacios
  MPIRUN_CMD=(mpirun ${MPIRUN_FLAGS:-})
fi

DIR=$(dirname "$OUT"); mkdir -p "$DIR"
HEADER="config,hilos,n"; for ((i=1; i<=REPS; i++)); do HEADER+=",rep$i"; done; HEADER+=",mediana_s,speedup,eficiencia"
if [ -s "$OUT" ]; then
  if [ "$(head -n1 "$OUT")" != "$HEADER" ]; then
    echo "bench.sh: el encabezado de $OUT no coincide con -r $REPS. Usa otro archivo (-o) o el mismo -r que la primera vez." >&2; exit 3
  fi
else
  echo "$HEADER" > "$OUT"
fi

# entorno.txt (protocolo §1.4): bloque de la máquina (se reescribe) + una línea "corrida:" por llamada (se conservan)
ENT="$DIR/entorno.txt"; CORRIDAS=$(grep '^corrida:' "$ENT" 2>/dev/null || true)
{
  echo "fecha: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo "sistema: $(uname -srm)"
  lscpu 2>/dev/null | grep -E 'Model name|^CPU\(s\)|Core\(s\) per socket|Thread\(s\) per core' | sed 's/  */ /g'
  grep MemTotal /proc/meminfo 2>/dev/null | sed 's/  */ /g'
  [ -r /sys/fs/cgroup/cpu.max ] && echo "cuota_cpu_cgroup (cuota periodo; max = sin límite): $(cat /sys/fs/cgroup/cpu.max)"
  echo "carga_antes_de_medir: $(uptime 2>/dev/null | sed 's/.*load average: //')"
  command -v gcc >/dev/null 2>&1 && echo "compilador: $(gcc --version | head -n1)"
  command -v mpirun >/dev/null 2>&1 && echo "mpi: $(mpirun --version 2>/dev/null | head -n1)"
  [ -n "$CORRIDAS" ] && printf '%s\n' "$CORRIDAS"
} > "$ENT"

NUC=$(nproc 2>/dev/null || echo 0)
if [ -z "$T1" ]; then
  T1=$(awk -F, -v n="${N:-}" 'NR>1 && $2==1 && (n=="" || $3==n) {print $(NF-2); exit}' "$OUT")
  [ -n "$T1" ] && echo "T(1) tomado del CSV ($OUT, primera fila con hilos=1): $T1 s" >&2
fi
extraer() { awk -F= -v k="$CLAVE" '$1==k {v=$2} END {if (v=="") exit 1; print v}'; }
correr() { # $1 = hilos o procesos
  if [ "$MODO" = mpi ]; then "${MPIRUN_CMD[@]}" -np "$1" "$PROG" "${ARGS[@]}" ${N:+"$N"}
  else OMP_NUM_THREADS=$1 "$PROG" "${ARGS[@]}" ${N:+"$N"}; fi
}

echo "# $CONFIG | $PROG ${ARGS[*]} ${N:-} | hilos: $HILOS | reps: $REPS (+1 calentamiento) | nproc: $NUC" >&2
for p in $HILOS; do
  [ "$NUC" -gt 0 ] && [ "$p" -gt "$NUC" ] && echo "AVISO: p=$p > $NUC núcleos: sobre-suscripción; decláralo en el reporte (protocolo §2)." >&2
  if ! sal=$(correr "$p" 2>&1); then echo "ERROR: el programa falló con p=$p (calentamiento):" >&2; printf '%s\n' "$sal" | tail -5 >&2; exit 4; fi
  N_FILA=${N:-$(printf '%s\n' "$sal" | awk -F= '$1=="n"{v=$2} END{print (v==""?"NA":v)}')}
  tiempos=()
  for ((r=1; r<=REPS; r++)); do
    if ! sal=$(correr "$p" 2>&1); then echo "ERROR: el programa falló con p=$p rep=$r:" >&2; printf '%s\n' "$sal" | tail -5 >&2; exit 4; fi
    if ! t=$(printf '%s\n' "$sal" | extraer); then echo "ERROR: no encontré '$CLAVE=' en la salida (p=$p):" >&2; printf '%s\n' "$sal" | tail -3 >&2; exit 4; fi
    tiempos+=("$t"); printf '  p=%-3s rep=%-2s %s s\n' "$p" "$r" "$t" >&2
  done
  fila=$(python3 -I - "$CONFIG" "$p" "$N_FILA" "$T1" "${tiempos[@]}" <<'PY'
import statistics, sys
cfg, p, n, t1 = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4]
ts = [float(x) for x in sys.argv[5:]]
med = statistics.median(ts)
if not t1 and p == 1:
    t1 = str(med)          # sin línea base: la fila con 1 hilo pasa a serlo (el script avisa)
if t1:
    s = float(t1) / med
    sp, ef = f"{s:.4f}", f"{s / p:.4f}"
else:
    sp, ef = "NA", "NA"
print(",".join([cfg, str(p), str(n)] + [f"{x:.6f}" for x in ts] + [f"{med:.6f}", sp, ef]))
PY
  )
  echo "$fila" >> "$OUT"; echo "$fila" >&2
  if [ -z "$T1" ] && [ "$p" = 1 ]; then
    T1=$(echo "$fila" | awk -F, '{print $(NF-2)}')
    case "$CONFIG" in
      secuencial|*-seq|seq|*_seq) ;;   # línea base correcta: la versión secuencial
      *) echo "AVISO: T(1) = versión paralela con 1 hilo (config $CONFIG). El protocolo (§3) pide la mejor versión secuencial: mide antes con -c secuencial -t 1 o pasa --t1." >&2 ;;
    esac
  fi
  if [ "$p" = 1 ]; then
    awk -v m="$(echo "$fila" | awk -F, '{print $(NF-2)}')" 'BEGIN{ if (m+0 < 1) print "AVISO: T(1) < 1 s: sirve para probar el flujo, no como evidencia (protocolo §2). Aumenta n." }' >&2
  fi
done
echo "corrida: $(date '+%Y-%m-%d %H:%M:%S') | csv=$OUT | config=$CONFIG | modo=$MODO | hilos=\"$HILOS\" | reps=$REPS | cmd=$PROG ${ARGS[*]} ${N:-}" >> "$ENT"
echo "CSV: $OUT · entorno: $ENT · siguiente: /graficar $OUT" >&2
exit 0
