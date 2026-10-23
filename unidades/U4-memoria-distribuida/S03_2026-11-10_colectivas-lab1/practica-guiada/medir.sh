#!/usr/bin/env bash
# medir.sh — Protocolo mínimo de medición del curso para los programas de esta carpeta:
# 1 corrida de calentamiento (no cuenta) + 5 repeticiones; reporta mediana, mín y máx del
# tiempo "total" (programas MPI) o "tiempo calcular" (matvec_seq) que imprime el programa.
#
# Uso:  ./medir.sh ./matvec_seq 4096 40
#       ./medir.sh mpirun -np 4 ./matvec_collectives 4096 40
#       REPS=7 ./medir.sh ...        (otro número de repeticiones)
# Recuerda: -O2 (ya en el Makefile), tamaño fijo y declarado, y anotar el entorno (CPU, carga).
set -u
REPS="${REPS:-5}"
if [ $# -lt 1 ]; then echo "Uso: $0 <comando y argumentos>"; exit 1; fi
if [ "$(id -u)" -eq 0 ]; then export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1; fi

extract() { # toma el número que sigue a "total = " o a "tiempo calcular = " (última línea que lo tenga)
    sed -n 's/.*\(total\|tiempo calcular\) = \([0-9.eE+-]*\).*/\2/p' | tail -n 1
}

"$@" >/dev/null 2>&1 || { echo "el comando falló en el calentamiento: $*"; exit 1; }   # calentamiento
vals=()
for ((i = 1; i <= REPS; i++)); do
    t=$("$@" 2>/dev/null | extract)
    [ -n "$t" ] || { echo "no encontré 'total =' ni 'tiempo calcular =' en la salida"; exit 1; }
    vals+=("$t")
done
sorted=$(printf '%s\n' "${vals[@]}" | sort -g)
median=$(printf '%s\n' "$sorted" | awk -v r="$REPS" 'NR == int((r + 1) / 2) { print; exit }')
min=$(printf '%s\n' "$sorted" | head -n 1)
max=$(printf '%s\n' "$sorted" | tail -n 1)
echo "comando : $*"
echo "corridas: ${vals[*]}"
printf 'mediana = %s s   (min = %s, max = %s, reps = %d)\n' "$median" "$min" "$max" "$REPS"
