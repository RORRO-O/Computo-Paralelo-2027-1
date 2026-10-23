#!/usr/bin/env bash
# medir.sh — Protocolo de medición del curso aplicado a los programas de la Práctica 4 (Parte D).
# Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · versión local y corta de herramientas/medir.sh
#
# Uso:
#   ./medir.sh -c CONFIG [-t "1 2 4 8"] [-o resultados/p4.csv] [--base CONFIG_T1 | --t1 SEG] -- programa [args]
#
#   -c CONFIG   etiqueta de la fila (sin comas). Las que terminan en "-seq" son referencias T(1).
#   -t LISTA    hilos entre comillas (por defecto "1 2 4 8"); cada valor va a OMP_NUM_THREADS.
#   -o CSV      archivo de salida (por defecto resultados/p4.csv); se crea con encabezado si no existe.
#   --base C    T(1) = mediana de la fila con config C, hilos 1 y el mismo n que ya está en el CSV.
#   --t1 SEG    T(1) dado a mano (mediana del mejor secuencial, en segundos).
#               Sin --base ni --t1: si CONFIG termina en "-seq", su propia fila con 1 hilo es T(1); si no,
#               speedup y eficiencia quedan en NA (y se avisa).
#
# Contrato con el programa (todos los de src/ lo cumplen): hace él mismo 1 calentamiento + REPS
# repeticiones de la región de interés e imprime "n=<tamaño>", "tiempos_s=<t1> <t2> ..." y
# "tiempo_s=<mediana>"; termina con código 0 (si hay un TODO pendiente o la verificación falla, termina
# con código distinto de 0 y la medición se aborta: un programa equivocado no tiene speedup).
#
# Por cada valor de hilos agrega UNA fila:  config,hilos,n,rep1..repR,mediana_s,speedup,eficiencia,
# guarda la salida completa del programa en <carpeta del CSV>/salidas/<CONFIG>-<hilos>.txt (ahí quedan, p. ej.,
# las iteraciones por hilo y el max/promedio de la Parte C) y escribe el entorno de medición (protocolo §1.4)
# en <carpeta del CSV>/entorno.txt: la máquina (cuando el CSV es nuevo) y una línea por configuración con la
# carga antes de medir.
set -euo pipefail
export LC_ALL=C

CONFIG="" HILOS="1 2 4 8" OUT="resultados/p4.csv" BASE="" T1=""
uso() { awk 'NR > 1 && !/^#/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "$0"; }
error() { echo "medir.sh: $1" >&2; exit 2; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c) CONFIG=${2:?}; shift 2 ;;
        -t) HILOS=${2:?}; shift 2 ;;
        -o) OUT=${2:?}; shift 2 ;;
        --base) BASE=${2:?}; shift 2 ;;
        --t1) T1=${2:?}; shift 2 ;;
        -h | --help) uso; exit 0 ;;
        --) shift; break ;;
        *) error "opción desconocida: $1 (usa -h)" ;;
    esac
done
[[ $# -ge 1 ]] || error "falta el programa después de '--' (usa -h)"
[[ -n $CONFIG && $CONFIG != *,* ]] || error "-c CONFIG es obligatorio y no puede tener comas"
command -v "$1" > /dev/null 2>&1 || error "no encuentro '$1' (¿falta 'make'?)"

mkdir -p "$(dirname "$OUT")/salidas"
ENTORNO="$(dirname "$OUT")/entorno.txt"
if [[ ! -s $OUT ]]; then          # CSV nuevo: se describe la máquina una vez
    {
        echo "fecha: $(date '+%Y-%m-%d %H:%M:%S %z')"
        echo "sistema: $(uname -srm)"
        if command -v lscpu > /dev/null 2>&1; then
            lscpu | grep -E 'Model name|^CPU\(s\)|Core\(s\) per socket|Thread\(s\) per core|Socket\(s\)' | sed 's/  */ /g'
        fi
        [[ -r /proc/meminfo ]] && grep MemTotal /proc/meminfo | sed 's/  */ /g'
        [[ -r /sys/fs/cgroup/cpu.max ]] && echo "cuota_cpu_cgroup (cuota periodo; max = sin limite): $(cat /sys/fs/cgroup/cpu.max)"
        command -v gcc > /dev/null 2>&1 && echo "compilador: $(gcc --version | head -n 1)"
        echo "banderas: -std=c11 -O2 -Wall -Wextra -fopenmp"
        echo "mediciones (una línea por configuración; carga = load average de 1, 5 y 15 min antes de medir):"
    } > "$ENTORNO"
fi
echo "- $(date '+%H:%M:%S') $CONFIG hilos=<$HILOS> REPS=${REPS:-5} carga=$(cut -d' ' -f1-3 /proc/loadavg 2> /dev/null || uptime): $*" >> "$ENTORNO"

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
for p in $HILOS; do
    [[ $p =~ ^[0-9]+$ && $p -ge 1 ]] || error "valor de hilos no válido: $p"
    if ! OMP_NUM_THREADS=$p "$@" > "$tmp"; then
        echo "medir.sh: el programa terminó con error (hilos=$p). Últimas líneas:" >&2
        tail -n 6 "$tmp" | sed 's/^/   | /' >&2
        exit 4
    fi
    cp "$tmp" "$(dirname "$OUT")/salidas/$CONFIG-$p.txt"
    n=$(awk -F= '$1 == "n" { v = $2 } END { print v }' "$tmp")
    tiempos=$(awk -F= '$1 == "tiempos_s" { v = $2 } END { print v }' "$tmp")
    mediana=$(awk -F= '$1 == "tiempo_s" { v = $2 } END { print v }' "$tmp")
    [[ -n $n && -n $tiempos && -n $mediana ]] || error "el programa no imprimió n=, tiempos_s= y tiempo_s="
    reps=$(wc -w <<< "$tiempos")
    header="config,hilos,n"
    for ((i = 1; i <= reps; i++)); do header+=",rep$i"; done
    header+=",mediana_s,speedup,eficiencia"
    if [[ -s $OUT ]]; then
        [[ $(head -n 1 "$OUT") == "$header" ]] || error "$OUT tiene otro encabezado (¿otro REPS?); usa otro -o"
    else
        echo "$header" > "$OUT"
    fi
    (( reps >= 5 )) || echo "AVISO: $reps repeticiones; el protocolo exige >= 5 para que la fila cuente." >&2

    base=$T1
    if [[ -z $base && -n $BASE ]]; then
        base=$(awk -F, -v c="$BASE" -v n="$n" -v r="$reps" \
            'NR > 1 && $1 == c && $2 == "1" && $3 == n { print $(4 + r); exit }' "$OUT")
        [[ -n $base ]] || error "no hay fila $BASE con 1 hilo y n=$n en $OUT (mídela primero)"
    fi
    if [[ -z $base && $CONFIG == *-seq && $p == 1 ]]; then base=$mediana; fi
    speedup=NA eficiencia=NA
    if [[ -n $base ]]; then
        speedup=$(awk -v a="$base" -v b="$mediana" 'BEGIN { printf "%.3f", a / b }')
        eficiencia=$(awk -v s="$speedup" -v p="$p" 'BEGIN { printf "%.3f", s / p }')
    else
        echo "AVISO: sin T(1) para $CONFIG (usa --base o --t1): speedup y eficiencia quedan en NA." >&2
    fi
    linea="$CONFIG,$p,$n,${tiempos// /,},$mediana,$speedup,$eficiencia"
    echo "$linea" >> "$OUT"
    echo "$linea"
done
