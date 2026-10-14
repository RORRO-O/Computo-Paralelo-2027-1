#!/usr/bin/env bash
# medir.sh — Protocolo de medición del curso aplicado a los programas de esta carpeta.
#
# Para cada número de hilos de la lista: 1 corrida de calentamiento (no cuenta) + REPS corridas
# (5 por defecto). Reporta mediana, mínimo y máximo del tiempo TOTAL y del tiempo de UNA FASE,
# y el speedup de cada uno respecto a la mediana con 1 hilo (T(1) = la primera entrada de la lista,
# que debe ser 1 para que el speedup tenga sentido).
#
# Uso:  ./medir.sh <programa> <fase> "<lista de hilos>" [argumentos del programa...]
# Ej.:  ./medir.sh ./fases computo "1 2 4" 500000 200
#       ./medir.sh ./ejemplo_perfil resumen "1 2 4" 2000000 48000 resumen dynamic
# Variables: REPS (repeticiones, 5 por defecto).
set -u
if [ $# -lt 3 ]; then
    echo "uso: $0 <programa> <fase> \"<lista de hilos>\" [args...]" >&2
    exit 1
fi
prog=$1; phase=$2; threads_list=$3; shift 3
reps=${REPS:-5}

# mediana de una lista de números (uno por línea)
median() { sort -g | awk '{a[NR]=$1} END{ if (NR%2) print a[(NR+1)/2]; else print (a[NR/2]+a[NR/2+1])/2 }'; }

echo "# $prog $* · fase=$phase · calentamiento 1 + $reps repeticiones · mediana [min, max]"
printf "%-6s %12s %10s %12s %10s %10s\n" "hilos" "total_med_s" "S_total" "${phase}_med_s" "S_$phase" "rango_$phase"
t1_total=""; t1_phase=""
for t in $threads_list; do
    OMP_NUM_THREADS=$t "$prog" "$@" > /dev/null || { echo "error al ejecutar $prog" >&2; exit 1; }   # calentamiento
    totals=""; phases=""
    for ((r = 1; r <= reps; r++)); do
        out=$(OMP_NUM_THREADS=$t "$prog" "$@")
        totals+=$(awk '$1=="total"{print $2}' <<<"$out")$'\n'
        phases+=$(awk -v f="$phase" '$1==f{print $2}' <<<"$out")$'\n'
    done
    med_t=$(printf "%s" "$totals" | median); med_p=$(printf "%s" "$phases" | median)
    min_p=$(printf "%s" "$phases" | sort -g | head -1); max_p=$(printf "%s" "$phases" | sort -g | tail -1)
    [ -z "$t1_total" ] && { t1_total=$med_t; t1_phase=$med_p; }
    s_t=$(awk -v a="$t1_total" -v b="$med_t" 'BEGIN{printf "%.2f", a/b}')
    s_p=$(awk -v a="$t1_phase" -v b="$med_p" 'BEGIN{printf "%.2f", a/b}')
    printf "%-6s %12s %10s %12s %10s %10s\n" "$t" "$med_t" "$s_t" "$med_p" "$s_p" "[$min_p, $max_p]"
done
