#!/usr/bin/env bash
# medir.sh — Aplica el protocolo de medición del curso a un programa y escribe el CSV del protocolo.
# Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · herramientas/
#
# Uso:
#   ./medir.sh [-c CONFIG] [-t "1 2 4 8"] [-n N] [-r 5] [-o salida.csv] [--t1 SEG] [--mpi] -- ./programa [args...]
#
#   -c CONFIG   Etiqueta de la columna config (por defecto "openmp"; con --mpi, "mpi"). Sin comas.
#   -t LISTA    Hilos (o procesos con --mpi) entre comillas, por defecto "1 2 4 8". Cada valor se exporta en
#               OMP_NUM_THREADS; con --mpi se pasa a mpirun -np. El valor especial "gpu" (V3, P6 en Colab) corre
#               el programa sin fijar hilos, escribe "gpu" en la columna hilos y deja la eficiencia en NA.
#   -n N        Tamaño del problema. Se agrega como ÚLTIMO argumento del programa y se guarda en la columna n.
#               Si se omite, el programa corre con sus valores por defecto y la columna n toma lo que el
#               programa imprima en una línea "n=<valor>" (o NA si no la imprime).
#   -r R        Repeticiones cronometradas por configuración (por defecto 5; el protocolo exige >= 5).
#   -o CSV      Archivo de salida (por defecto resultados/mediciones.csv). Se crea con encabezado si no existe;
#               si existe, debe tener el mismo número de repeticiones.
#   --t1 SEG    Tiempo de la MEJOR versión secuencial (mediana, en segundos) para calcular speedup y eficiencia.
#               Si se omite, se usa la fila con hilos=1 y el mismo n que ya esté en el CSV (la primera; por eso
#               conviene medir primero la versión secuencial con -c secuencial -t 1) o, si no la hay, la fila
#               con hilos=1 de esta misma corrida. Si nada de eso existe, speedup y eficiencia quedan en NA.
#   --clave K   Línea "K=<segundos>" que se lee en lugar de tiempo_s= (p. ej. --clave tiempo_kernel_s para la
#               fila "sin transferencias" de una versión GPU; ver colab-kaggle.md §6).
#   --mpi       Ejecuta "mpirun $MPIRUN_FLAGS -np P ./programa" en lugar de fijar OMP_NUM_THREADS. Exporta
#               MPIRUN_FLAGS="--oversubscribe" si pides más procesos que núcleos. Si corres como root, el script
#               exporta OMPI_ALLOW_RUN_AS_ROOT=1 y OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 (necesario en contenedores).
#   -h          Esta ayuda.
#
# Convención con el programa medido (ver cronometro.h):
#   - Imprime en stdout una línea "tiempo_s=<segundos>" con el tiempo de la región de interés (solo lo que se
#     paraleliza; no la lectura de archivos ni la impresión). Si imprime varias, se toma la ÚLTIMA.
#   - Acepta el tamaño del problema como último argumento (si usas -n).
#   - Termina con código 0. Si falla o no imprime tiempo_s=, la medición se aborta con código 4.
#
# Qué hace por cada valor de hilos: 1 ejecución de calentamiento (no se cuenta) + R ejecuciones cronometradas;
# calcula la mediana, el speedup = T1 / mediana y la eficiencia = speedup / hilos; agrega una fila al CSV y la
# muestra en pantalla. Escribe además el entorno (fecha, sistema, CPU, RAM, compilador) en
# <carpeta del CSV>/entorno.txt para copiarlo al reporte (protocolo §1.4).
#
# Columnas del CSV (protocolo §4):  config,hilos,n,rep1..repR,mediana_s,speedup,eficiencia
# Códigos de salida: 0 bien · 2 argumentos · 3 el CSV existente tiene otro encabezado · 4 el programa falló.
#
# Ejemplos ejecutables (desde herramientas/, después de `make`):
#   ./medir.sh -c secuencial -t 1       -n 100000000 -o pruebas-tmp/m.csv -- ./ejemplo_cronometro_seq.out
#   ./medir.sh -c openmp     -t "1 2 4" -n 100000000 -o pruebas-tmp/m.csv -- ./ejemplo_cronometro.out
#   MPIRUN_FLAGS="--oversubscribe" ./medir.sh --mpi -c mpi -t "1 2 4" -n 100000000 -o pruebas-tmp/m.csv -- ./ejemplo_mpi.out
#   python3 graficar_speedup.py pruebas-tmp/m.csv
set -euo pipefail
export LC_ALL=C

CONFIG=""
HILOS="1 2 4 8"
N=""
REPS=5
OUT="resultados/mediciones.csv"
T1=""
MODO="openmp"
CLAVE="tiempo_s"

ayuda() { awk 'NR > 1 && !/^#/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "$0"; }
error_uso() { echo "medir.sh: $1 (usa -h)" >&2; exit 2; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c) [[ $# -ge 2 ]] || error_uso "-c requiere un valor"; CONFIG=$2; shift 2 ;;
        -t) [[ $# -ge 2 ]] || error_uso "-t requiere un valor"; HILOS=$2; shift 2 ;;
        -n) [[ $# -ge 2 ]] || error_uso "-n requiere un valor"; N=$2; shift 2 ;;
        -r) [[ $# -ge 2 ]] || error_uso "-r requiere un valor"; REPS=$2; shift 2 ;;
        -o) [[ $# -ge 2 ]] || error_uso "-o requiere un valor"; OUT=$2; shift 2 ;;
        --t1) [[ $# -ge 2 ]] || error_uso "--t1 requiere un valor"; T1=$2; shift 2 ;;
        --clave) [[ $# -ge 2 ]] || error_uso "--clave requiere un valor"; CLAVE=$2; shift 2 ;;
        --mpi) MODO="mpi"; shift ;;
        -h | --help) ayuda; exit 0 ;;
        --) shift; break ;;
        -*) error_uso "opción desconocida: $1" ;;
        *) break ;;
    esac
done

[[ $# -ge 1 ]] || error_uso "falta el programa a medir después de '--'"
[[ -n $CONFIG ]] || CONFIG=$MODO
[[ $CONFIG != *,* ]] || error_uso "la etiqueta -c no puede contener comas"
[[ -z $N || $N =~ ^[0-9]+$ ]] || error_uso "-n debe ser un entero"
[[ $REPS =~ ^[0-9]+$ && $REPS -ge 1 ]] || error_uso "-r debe ser un entero >= 1"
[[ -z $T1 || $T1 =~ ^[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$ ]] || error_uso "--t1 debe ser un número"
for t in $HILOS; do
    [[ $t == gpu || ( $t =~ ^[0-9]+$ && $t -ge 1 ) ]] || error_uso "valor de hilos no válido: '$t' (entero >= 1 o gpu)"
    [[ $t != gpu || $MODO != mpi ]] || error_uso "'gpu' no se combina con --mpi"
done
command -v "$1" > /dev/null 2>&1 || error_uso "no se encuentra el programa '$1' (¿falta compilar o el prefijo ./?)"
if [[ $REPS -lt 5 ]]; then
    echo "AVISO: el protocolo exige >= 5 repeticiones; con $REPS la fila no cuenta como evidencia." >&2
fi

MPIRUN_CMD=()
if [[ $MODO == "mpi" ]]; then
    command -v mpirun > /dev/null 2>&1 || error_uso "--mpi requiere mpirun en el PATH"
    if [[ $(id -u) == 0 ]]; then
        export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
    fi
    # shellcheck disable=SC2206  # MPIRUN_FLAGS se divide a propósito por espacios
    MPIRUN_CMD=(mpirun ${MPIRUN_FLAGS:-})
fi

DIR=$(dirname "$OUT")
mkdir -p "$DIR"

HEADER="config,hilos,n"
for ((i = 1; i <= REPS; i++)); do HEADER+=",rep$i"; done
HEADER+=",mediana_s,speedup,eficiencia"
if [[ -s $OUT ]]; then
    if [[ $(head -n 1 "$OUT") != "$HEADER" ]]; then
        echo "medir.sh: el encabezado de $OUT no coincide con R=$REPS repeticiones:" >&2
        echo "  tiene:   $(head -n 1 "$OUT")" >&2
        echo "  espero:  $HEADER" >&2
        echo "  Usa otro archivo (-o) o el mismo -r que la primera vez." >&2
        exit 3
    fi
else
    echo "$HEADER" > "$OUT"
fi

# Entorno de medición (protocolo §1.4). Se sobrescribe en cada corrida.
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
    [[ -r /proc/meminfo ]] && grep MemTotal /proc/meminfo | sed 's/  */ /g'
    # En contenedores y Codespaces la cuota de CPU (cgroup) puede ser menor que los núcleos visibles: eso
    # limita el speedup y debe declararse en el reporte.
    [[ -r /sys/fs/cgroup/cpu.max ]] && echo "cuota_cpu_cgroup (cuota periodo; 'max' = sin límite): $(cat /sys/fs/cgroup/cpu.max)"
    [[ -r /sys/fs/cgroup/cpu/cpu.cfs_quota_us ]] && echo "cuota_cpu_cgroup_v1 (us por periodo; -1 = sin límite): $(cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us)"
    command -v gcc > /dev/null 2>&1 && echo "compilador: $(gcc --version | head -n 1)"
    command -v mpirun > /dev/null 2>&1 && echo "mpi: $(mpirun --version 2> /dev/null | head -n 1)"
    echo "modo: $MODO"
    echo "comando: $*${N:+ $N}"
    echo "clave leida: $CLAVE"
    echo "repeticiones: $REPS (+1 de calentamiento)"
} > "$DIR/entorno.txt"

# extraer ARCHIVO CLAVE -> valor de la última línea "CLAVE=valor"; código 1 si no hay ninguna.
extraer() {
    awk -F= -v k="$2" '$1 == k { v = $2 } END { if (v == "") exit 1; print v }' "$1"
}

# ejecutar HILOS ARCHIVO_SALIDA -> corre el programa una vez con esa cantidad de hilos/procesos.
PROGRAMA=("$@")
ejecutar() {
    local p=$1 salida=$2
    if [[ $MODO == "mpi" ]]; then
        "${MPIRUN_CMD[@]}" -np "$p" "${PROGRAMA[@]}" ${N:+"$N"} > "$salida"
    elif [[ $p == gpu ]]; then
        "${PROGRAMA[@]}" ${N:+"$N"} > "$salida"
    else
        OMP_NUM_THREADS=$p "${PROGRAMA[@]}" ${N:+"$N"} > "$salida"
    fi
}

# t1_del_csv N -> mediana de la primera fila con hilos=1 y ese n en el CSV; vacío si no hay.
t1_del_csv() {
    awk -F, -v n="$1" -v r="$REPS" 'NR > 1 && $2 == "1" && $3 == n { print $(4 + r); exit }' "$OUT"
}

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

echo "$HEADER"
for p in $HILOS; do
    # Calentamiento: no se cuenta.
    if ! ejecutar "$p" "$tmp"; then
        echo "medir.sh: el programa falló en el calentamiento (hilos=$p). Su salida:" >&2
        sed 's/^/   | /' "$tmp" >&2
        exit 4
    fi
    if ! extraer "$tmp" "$CLAVE" > /dev/null; then
        echo "medir.sh: el programa no imprimió la línea '$CLAVE=<segundos>' (hilos=$p). Su salida:" >&2
        sed 's/^/   | /' "$tmp" >&2
        exit 4
    fi
    n_fila=$N
    if [[ -z $n_fila ]]; then
        n_fila=$(extraer "$tmp" n || echo NA)
    fi

    tiempos=()
    for ((i = 1; i <= REPS; i++)); do
        if ! ejecutar "$p" "$tmp"; then
            echo "medir.sh: el programa falló en la repetición $i (hilos=$p)." >&2
            exit 4
        fi
        tiempos+=("$(extraer "$tmp" "$CLAVE")")
    done

    mediana=$(printf '%s\n' "${tiempos[@]}" | sort -g | awk '
        { a[NR] = $1 }
        END { if (NR % 2) m = a[(NR + 1) / 2]; else m = (a[NR / 2] + a[NR / 2 + 1]) / 2; printf "%.6f", m }')

    # Línea base para el speedup: --t1, luego el CSV (fila hilos=1 con el mismo n), luego esta corrida.
    base=$T1
    if [[ -z $base && $n_fila != "NA" ]]; then
        base=$(t1_del_csv "$n_fila")
    fi
    if [[ -z $base && $p == 1 ]]; then
        base=$mediana
    fi
    speedup=NA
    eficiencia=NA
    if [[ -n $base ]]; then
        speedup=$(awk -v a="$base" -v b="$mediana" 'BEGIN { printf "%.3f", a / b }')
        if [[ $p != gpu ]]; then
            eficiencia=$(awk -v s="$speedup" -v p="$p" 'BEGIN { printf "%.3f", s / p }')
        fi
    else
        echo "AVISO: no hay línea base T(1) para n=$n_fila (ni --t1, ni fila con hilos=1 en $OUT); speedup y eficiencia quedan en NA." >&2
    fi

    linea="$CONFIG,$p,$n_fila"
    for t in "${tiempos[@]}"; do linea+=",$t"; done
    linea+=",$mediana,$speedup,$eficiencia"
    echo "$linea" >> "$OUT"
    echo "$linea"
done
echo "Listo: filas agregadas a $OUT; entorno en $DIR/entorno.txt"
