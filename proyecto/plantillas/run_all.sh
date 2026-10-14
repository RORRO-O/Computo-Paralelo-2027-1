#!/usr/bin/env bash
# run_all.sh — Aplica el protocolo de medición del curso a un ejecutable y agrega filas a un CSV.
# Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · Plantilla del proyecto integrador
#
# Uso:
#   ./run_all.sh -e ETIQUETA -n N [-t "1 2 4 8"] [-r 5] [-o resultados/mediciones.csv] -- ./programa [args...]
#
#   -e  Etiqueta de la versión: V1, V2 o V3. La fila "V1" con el mismo N es la línea base del speedup.
#   -n  Tamaño del problema. Se pasa al programa como ÚLTIMO argumento y se guarda en la columna n.
#   -t  Lista de hilos entre comillas (por defecto "1"). Cada valor se exporta en OMP_NUM_THREADS.
#       Usa "gpu" para una versión V3: no se fija OMP_NUM_THREADS y la eficiencia queda en NA.
#   -r  Repeticiones cronometradas por configuración (por defecto 5; el protocolo exige >= 5).
#   -o  CSV de salida (por defecto resultados/mediciones.csv). Se crea con encabezado si no existe.
#   -h  Muestra esta ayuda.
#
# Contrato con el programa medido:
#   - Imprime en stdout una línea "TIEMPO_S <segundos>" con el tiempo de la región de interés. Se acepta también
#     el formato clave=valor de la plantilla de entrega final (tiempo_s= o tiempo_total_s=, tiempo_kernel_s=).
#   - Opcional (V3): una línea "TIEMPO_KERNEL_S <segundos>" con el tiempo SIN transferencias; produce una
#     fila adicional con etiqueta "<ETIQUETA>-kernel".
#   - Termina con código 0. Si falla, la medición se aborta con código 4.
#
# Qué hace por cada valor de hilos: 1 ejecución de calentamiento (no se cuenta) + R ejecuciones; calcula
# mediana, mínimo y máximo; calcula speedup = T_V1 / mediana y eficiencia = speedup / hilos usando la fila
# V1 con el mismo N que ya esté en el CSV (si no la hay, escribe NA y avisa). Escribe además el entorno
# (fecha, sistema, CPU, RAM, compilador, GPU si la hay) en <carpeta del CSV>/entorno.txt.
#
# Columnas del CSV: config,hilos,n,rep1..repR,mediana_s,speedup,eficiencia,min_s,max_s
#
# Ejemplo ejecutable (desde esta carpeta, después de `make`):
#   ./run_all.sh -e V1 -n 20000000 -t 1       -o resultados-prueba/mediciones.csv -- ./plantilla_main.out
#   ./run_all.sh -e V2 -n 20000000 -t "1 2 4" -o resultados-prueba/mediciones.csv -- ./plantilla_main.out
#   python3 graficar_proyecto.py resultados-prueba/mediciones.csv
set -euo pipefail
export LC_ALL=C

ETIQUETA=""
N=""
HILOS="1"
REPS=5
OUT="resultados/mediciones.csv"

ayuda() { awk 'NR > 1 && !/^#/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "$0"; }

while getopts ":e:n:t:r:o:h" opt; do
    case "$opt" in
        e) ETIQUETA=$OPTARG ;;
        n) N=$OPTARG ;;
        t) HILOS=$OPTARG ;;
        r) REPS=$OPTARG ;;
        o) OUT=$OPTARG ;;
        h) ayuda; exit 0 ;;
        \?) echo "Opción desconocida: -$OPTARG (usa -h)" >&2; exit 2 ;;
        :) echo "La opción -$OPTARG requiere un valor" >&2; exit 2 ;;
    esac
done
shift $((OPTIND - 1))

if [[ $# -lt 1 ]]; then
    echo "Falta el programa a medir después de '--' (usa -h)" >&2
    exit 2
fi
if [[ -z $ETIQUETA || -z $N ]]; then
    echo "Faltan -e ETIQUETA y/o -n N (usa -h)" >&2
    exit 2
fi
if ! [[ $N =~ ^[0-9]+$ && $REPS =~ ^[0-9]+$ && $REPS -ge 1 ]]; then
    echo "N y R deben ser enteros positivos" >&2
    exit 2
fi
if [[ $ETIQUETA == *,* || $HILOS == *,* ]]; then
    echo "La etiqueta y la lista de hilos no pueden contener comas (rompen el CSV)" >&2
    exit 2
fi
if ! command -v "$1" > /dev/null 2>&1; then
    echo "No se encuentra el programa '$1' (¿falta compilar o el prefijo ./?)" >&2
    exit 2
fi
if [[ $REPS -lt 5 ]]; then
    echo "AVISO: el protocolo exige >= 5 repeticiones; con $REPS la fila no cuenta como evidencia." >&2
fi

DIR=$(dirname "$OUT")
mkdir -p "$DIR"

HEADER="config,hilos,n"
for ((i = 1; i <= REPS; i++)); do HEADER+=",rep$i"; done
HEADER+=",mediana_s,speedup,eficiencia,min_s,max_s"
if [[ -f $OUT ]]; then
    if [[ $(head -n 1 "$OUT") != "$HEADER" ]]; then
        echo "El encabezado de $OUT no coincide con R=$REPS repeticiones. Usa otro archivo o el mismo -r." >&2
        exit 3
    fi
else
    echo "$HEADER" > "$OUT"
fi

# Entorno de medición (se sobrescribe en cada corrida; cópialo al reporte).
{
    echo "fecha: $(date '+%Y-%m-%d %H:%M:%S %z')"
    echo "sistema: $(uname -srm)"
    if command -v lscpu > /dev/null 2>&1; then
        lscpu | grep -E 'Model name|^CPU\(s\)|Core\(s\) per socket|Thread\(s\) per core|Socket\(s\)' | sed 's/  */ /g'
    elif command -v sysctl > /dev/null 2>&1; then
        echo "cpu: $(sysctl -n machdep.cpu.brand_string 2> /dev/null || true)"
        echo "nucleos fisicos: $(sysctl -n hw.physicalcpu 2> /dev/null || true)"
        echo "nucleos logicos: $(sysctl -n hw.logicalcpu 2> /dev/null || true)"
    fi
    if [[ -r /proc/meminfo ]]; then grep MemTotal /proc/meminfo | sed 's/  */ /g'; fi
    if command -v gcc > /dev/null 2>&1; then echo "compilador: $(gcc --version | head -n 1)"; fi
    if command -v nvcc > /dev/null 2>&1; then echo "nvcc: $(nvcc --version | tail -n 1)"; fi
    if command -v nvidia-smi > /dev/null 2>&1; then
        echo "gpu: $(nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader 2> /dev/null || echo 'no disponible')"
    else
        echo "gpu: no detectada"
    fi
    echo "comando: $* <N>"
} > "$DIR/entorno.txt"

# extraer ARCHIVO CLAVE -> imprime el valor de la última línea "CLAVE valor"; código 1 si no existe.
# También acepta el formato clave=valor de la plantilla de entrega final: TIEMPO_S <- tiempo_total_s= o tiempo_s=;
# TIEMPO_KERNEL_S <- tiempo_kernel_s=.
extraer() {
    awk -v k="$2" '
        BEGIN {
            alt1 = ""; alt2 = ""
            if (k == "TIEMPO_S") { alt1 = "tiempo_total_s"; alt2 = "tiempo_s" }
            if (k == "TIEMPO_KERNEL_S") { alt1 = "tiempo_kernel_s" }
        }
        $1 == k { v = $2 }
        index($0, "=") > 0 {
            split($0, kv, "=")
            if (kv[1] == alt1 || (kv[1] == alt2 && alt1 != "" && v == "")) v = kv[2]
            else if (kv[1] == alt2 && alt1 == "") v = kv[2]
        }
        END { if (v == "") exit 1; print v }' "$1"
}

# escribir_fila CONFIG HILOS rep1 rep2 ... -> calcula estadísticos, speedup y eficiencia; agrega la fila.
escribir_fila() {
    local config=$1 hilos=$2
    shift 2
    local reps=("$@")
    local mediana min max
    read -r mediana min max <<< "$(printf '%s\n' "${reps[@]}" | sort -g | awk '
        { a[NR] = $1 }
        END {
            n = NR
            if (n % 2) m = a[(n + 1) / 2]; else m = (a[n / 2] + a[n / 2 + 1]) / 2
            printf "%.6f %.6f %.6f", m, a[1], a[n]
        }')"
    local speedup=NA eficiencia=NA t1=""
    if [[ $config == "V1" && $hilos == "1" ]]; then
        speedup=1.000
        eficiencia=1.000
    else
        # La mediana es la 5.ª columna contando desde el final (mediana_s,speedup,eficiencia,min_s,max_s).
        t1=$(awk -F, -v n="$N" '$1 == "V1" && $3 == n { print $(NF - 4); exit }' "$OUT")
        if [[ -n $t1 ]]; then
            speedup=$(awk -v a="$t1" -v b="$mediana" 'BEGIN { printf "%.3f", a / b }')
            if [[ $hilos =~ ^[0-9]+$ ]]; then
                eficiencia=$(awk -v s="$speedup" -v p="$hilos" 'BEGIN { printf "%.3f", s / p }')
            fi
        else
            echo "AVISO: no hay fila V1 con n=$N en $OUT; speedup y eficiencia quedan en NA." >&2
        fi
    fi
    local linea="$config,$hilos,$N"
    local r
    for r in "${reps[@]}"; do linea+=",$r"; done
    linea+=",$mediana,$speedup,$eficiencia,$min,$max"
    echo "$linea" >> "$OUT"
    echo "$linea"
}

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

echo "$HEADER"
for t in $HILOS; do
    if [[ $t == "gpu" ]]; then
        unset OMP_NUM_THREADS
    elif [[ $t =~ ^[0-9]+$ && $t -ge 1 ]]; then
        export OMP_NUM_THREADS=$t
    else
        echo "Valor de hilos no válido: '$t' (entero >= 1 o gpu)" >&2
        exit 2
    fi

    # Calentamiento: no se cuenta.
    if ! "$@" "$N" > "$tmp"; then
        echo "El programa falló en el calentamiento (hilos=$t). Revisa su salida arriba." >&2
        exit 4
    fi
    if ! extraer "$tmp" TIEMPO_S > /dev/null; then
        echo "El programa no imprimió la línea 'TIEMPO_S <segundos>' (hilos=$t)." >&2
        exit 4
    fi

    tiempos=()
    kernels=()
    for ((i = 1; i <= REPS; i++)); do
        if ! "$@" "$N" > "$tmp"; then
            echo "El programa falló en la repetición $i (hilos=$t)." >&2
            exit 4
        fi
        tiempos+=("$(extraer "$tmp" TIEMPO_S)")
        if k=$(extraer "$tmp" TIEMPO_KERNEL_S); then kernels+=("$k"); fi
    done

    escribir_fila "$ETIQUETA" "$t" "${tiempos[@]}"
    if [[ ${#kernels[@]} -eq $REPS ]]; then
        escribir_fila "${ETIQUETA}-kernel" "$t" "${kernels[@]}"
    fi
done
echo "Listo: filas agregadas a $OUT; entorno en $DIR/entorno.txt"
