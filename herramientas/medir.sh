#!/usr/bin/env bash
# medir.sh — Aplica el protocolo de medición del curso a un programa y escribe el CSV del protocolo.
# Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · herramientas/
#
# Uso:
#   ./medir.sh [-c CONFIG] [-t "1 2 4 8"] [-n N] [-r 5] [-o salida.csv] [--t1 SEG] [--clave K] [--mpi] \
#              -- ./programa [args...]
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
#               se mide primero la versión secuencial con -c secuencial -t 1) o, si no la hay, la fila con
#               hilos=1 de esta misma corrida; en ese caso avisa, porque el protocolo (§3) pide la secuencial.
#               Si nada de eso existe, speedup y eficiencia quedan en NA.
#   --clave K   Línea "K=<segundos>" que se lee en lugar de tiempo_s= (p. ej. --clave tiempo_kernel_s para la
#               fila "sin transferencias" de una versión GPU; ver colab-kaggle.md §6).
#   --mpi       Ejecuta "mpirun $MPIRUN_FLAGS -np P ./programa" en lugar de fijar OMP_NUM_THREADS. Define tú
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
# muestra en pantalla. Avisa si pides más hilos o procesos que núcleos lógicos (sobre-suscripción: se declara).
# Escribe además <carpeta del CSV>/entorno.txt para copiarlo al reporte (protocolo §1.4): el bloque de la
# máquina (fecha, sistema, CPU, RAM, cuota de CPU del contenedor, compilador, MPI) se reescribe en cada llamada y
# se agrega una línea "corrida:" por llamada terminada (inicio, CSV, config, lanzador, hilos, repeticiones, clave
# y comando).
#
# Columnas del CSV (protocolo §4):  config,hilos,n,rep1..repR,mediana_s,speedup,eficiencia
# Códigos de salida: 0 bien · 2 argumentos · 3 el CSV existente tiene otro encabezado · 4 el programa falló.
#
# Ejemplos ejecutables (desde herramientas/, después de `make`). Así se obtuvieron ejemplo_resultados.csv y
# ejemplo_entorno.txt: n = 8·10⁸ da T(1) ≈ 1 s (protocolo §2); en 4 núcleos tarda menos de 1 min. Escriben en
# resultados/ (la salida por defecto), que `make clean` borra:
#   ./medir.sh -c secuencial -t 1         -n 800000000 -- ./ejemplo_cronometro_seq.out
#   ./medir.sh -c openmp     -t "1 2 4 8" -n 800000000 -- ./ejemplo_cronometro.out
#   MPIRUN_FLAGS="--oversubscribe" ./medir.sh --mpi -c mpi -t "1 2 4" -n 800000000 -- ./ejemplo_mpi.out
#   python3 graficar_speedup.py resultados/mediciones.csv --titulo "pi por rectángulos"
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

# Entorno de medición (protocolo §1.4): el bloque de la máquina se reescribe; las líneas "corrida:" anteriores
# se conservan y al final se agrega la de esta llamada.
ENTORNO="$DIR/entorno.txt"
INICIO=$(date '+%Y-%m-%d %H:%M:%S %z')
if [[ $MODO == "mpi" ]]; then LANZADOR="mpirun ${MPIRUN_FLAGS:-} -np P"; else LANZADOR="OMP_NUM_THREADS=P"; fi
CORRIDAS=""
if [[ -f $ENTORNO ]]; then
    CORRIDAS=$(grep '^corrida:' "$ENTORNO" || true)
fi
{
    echo "fecha: $INICIO"
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
    if [[ -n $CORRIDAS ]]; then printf '%s\n' "$CORRIDAS"; fi
} > "$ENTORNO"

# Sobre-suscripción: más hilos o procesos que núcleos lógicos visibles. No se prohíbe; se declara (protocolo §2).
NUCLEOS=$(getconf _NPROCESSORS_ONLN 2> /dev/null || echo 0)
for t in $HILOS; do
    if [[ $t != gpu && $NUCLEOS -gt 0 && $t -gt $NUCLEOS ]]; then
        echo "AVISO: $t hilos/procesos > $NUCLEOS núcleos lógicos: sobre-suscripción; decláralo en el reporte (protocolo §2)." >&2
        break
    fi
done

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

# t1_del_csv N -> "mediana config" de la primera fila con hilos=1 y ese n en el CSV; vacío si no hay.
t1_del_csv() {
    awk -F, -v n="$1" -v r="$REPS" 'NR > 1 && $2 == "1" && $3 == n { print $(4 + r), $1; exit }' "$OUT"
}
N_VALORES=$(wc -w <<< "$HILOS")
AVISO_BASE=0

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
    config_base=""
    if [[ -z $base && $n_fila != "NA" ]]; then
        read -r base config_base <<< "$(t1_del_csv "$n_fila")" || true
    fi
    if [[ -z $base && $p == 1 ]]; then
        base=$mediana
        config_base=$CONFIG
    fi
    # Idea errónea 31 del Anexo A: el speedup se calcula contra la mejor secuencial, no contra la paralela con 1 hilo.
    if [[ $AVISO_BASE -eq 0 && -z $T1 && $config_base == "$CONFIG" && $N_VALORES -gt 1 ]]; then
        echo "AVISO: la línea base T(1) es '$CONFIG' con 1 hilo, no la versión secuencial (protocolo §3). Mide antes -c secuencial -t 1 en el mismo CSV, pasa --t1 o decláralo." >&2
        AVISO_BASE=1
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
echo "corrida: $INICIO · csv=$(basename "$OUT") · config=$CONFIG · lanzador=$LANZADOR · hilos=$HILOS · repeticiones=$REPS (+1 de calentamiento) · clave=$CLAVE · comando=$*${N:+ $N}" >> "$ENTORNO"
echo "Listo: filas agregadas a $OUT; entorno en $ENTORNO"
