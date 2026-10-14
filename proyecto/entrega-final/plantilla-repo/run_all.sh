#!/usr/bin/env bash
# run_all.sh · Reproduce TODO lo medible en CPU en un solo comando (plantilla del proyecto)
#
# Uso:  ./run_all.sh [--n N] [--semilla S] [--hilos "1 2 4 8"] [--reps 5] [--rapido] [--sin-grafica]
#       --n N          tamaño del problema (por defecto: N_DEFAULT de comun/problema.h, 4000000)
#       --semilla S    semilla de los datos (por defecto 12345)
#       --hilos "..."  lista de hilos para V2 (por defecto: 1 2 4 ... hasta nproc)
#       --reps K       repeticiones medidas por configuración (mínimo 5, protocolo §2)
#       --rapido       n pequeña (200000) y 5 repeticiones: para comprobar que el flujo
#                      funciona, NO para reportar (T(1) < 1 s invalida la medición)
#       --sin-grafica  no genera resultados/speedup.png
# Qué hace, en orden:
#   1. Escribe resultados/entorno.txt (CPU, RAM, SO, compilador, banderas, fecha, commit).
#   2. make all (V1, V2 y verificación de compilación de V3 si hay nvcc).
#   3. make test: si falla, ABORTA (un programa rápido y equivocado no tiene speedup).
#   4. Mide V1 y V2 (1 calentamiento + K repeticiones por configuración) y escribe
#      resultados/mediciones.csv con la cabecera del protocolo:
#      config,hilos,n,rep1,...,repK,mediana_s,speedup,eficiencia
#   5. Si hay python3 con numpy/matplotlib: tabla Markdown (resultados/tabla.md) y
#      gráfica speedup vs hilos con la línea ideal (resultados/speedup.png).
#   La V3 NO se mide aquí: se mide en Colab/Kaggle con v3/notebook_colab.ipynb, que
#   produce resultados/mediciones_v3.csv y resultados/entorno_gpu.txt.
# Código de salida: 0 si todo terminó; distinto de 0 si falló la compilación o una prueba.
# Ejemplo:  ./run_all.sh --rapido            (≈ 10 s)
#           ./run_all.sh --hilos "1 2 4"     (medición real con el tamaño por defecto)
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT" || exit 1

N=""
SEMILLA=12345
HILOS=""
REPS=5
GRAFICA=1
RAPIDO=0
while [ $# -gt 0 ]; do
    case "$1" in
        --n) N="$2"; shift 2 ;;
        --semilla) SEMILLA="$2"; shift 2 ;;
        --hilos) HILOS="$2"; shift 2 ;;
        --reps) REPS="$2"; shift 2 ;;
        --rapido) RAPIDO=1; shift ;;
        --sin-grafica) GRAFICA=0; shift ;;
        -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
        *) echo "argumento desconocido: $1 (usa --help)" >&2; exit 2 ;;
    esac
done
if [ "$REPS" -lt 5 ]; then echo "error: --reps debe ser >= 5 (protocolo §2)" >&2; exit 2; fi
if [ "$RAPIDO" -eq 1 ]; then N="${N:-200000}"; fi
if [ -z "$N" ]; then N="$(sed -n 's/^#define N_DEFAULT[[:space:]]*\([0-9]*\)u.*/\1/p' comun/problema.h)"; fi
if [ -z "$HILOS" ]; then
    nucleos="$(nproc 2>/dev/null || echo 4)"
    HILOS="1"; p=2
    while [ "$p" -le "$nucleos" ]; do HILOS="$HILOS $p"; p=$((p * 2)); done
fi

mkdir -p resultados
ENTORNO=resultados/entorno.txt
CSV=resultados/mediciones.csv

# ---------- 1. Entorno ----------
{
    echo "fecha_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "commit=$(git rev-parse --short HEAD 2>/dev/null || echo sin-git)"
    echo "so=$(uname -srmo 2>/dev/null || uname -a)"
    echo "cpu_modelo=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2- | sed 's/^ //')"
    echo "nucleos_logicos=$(nproc 2>/dev/null)"
    echo "nucleos_fisicos=$(lscpu 2>/dev/null | awk -F: '/^Core\(s\) per socket/ {c=$2} /^Socket\(s\)/ {s=$2} END {if (c && s) print c*s}')"
    echo "ram_total=$(grep -m1 MemTotal /proc/meminfo 2>/dev/null | awk '{print $2/1024/1024 " GiB"}')"
    echo "compilador=$(gcc --version 2>/dev/null | head -1)"
    echo "banderas_v1=$(sed -n 's/^CFLAGS *?= *//p' v1/Makefile)"
    echo "banderas_v2=$(sed -n 's/^CFLAGS *?= *//p' v2/Makefile)"
    echo "nvcc=$(nvcc --version 2>/dev/null | tail -1 || echo no-disponible)"
    echo "n=$N"
    echo "semilla=$SEMILLA"
    echo "hilos=$HILOS"
    echo "repeticiones=$REPS"
    echo "modo_rapido=$RAPIDO"
} > "$ENTORNO"
echo "[1/5] entorno -> $ENTORNO"

# ---------- 2. Compilación ----------
echo "[2/5] make all"
if ! make all; then echo "ERROR: falló la compilación" >&2; exit 1; fi

# ---------- 3. Pruebas ----------
echo "[3/5] make test"
if ! make test; then echo "ERROR: las pruebas no pasan; no se mide un programa incorrecto" >&2; exit 1; fi

# ---------- 4. Mediciones ----------
campo() { printf '%s\n' "$1" | awk -F= -v k="$2" '$1 == k { print $2; exit }'; }

# mide <comando...>: 1 calentamiento + REPS repeticiones; imprime "rep1,...,repK,mediana"
mide() {
    local salida tiempos=""
    salida="$("$@")" || return 1              # calentamiento (no se cuenta)
    for _ in $(seq 1 "$REPS"); do
        salida="$("$@")" || return 1
        tiempos="$tiempos,$(campo "$salida" tiempo_s)"
    done
    tiempos="${tiempos#,}"
    local mediana
    mediana="$(printf '%s\n' "$tiempos" | tr ',' '\n' | sort -g | awk '{a[NR]=$1} END {
        if (NR % 2) print a[(NR+1)/2]; else printf "%.6f\n", (a[NR/2]+a[NR/2+1])/2 }')"
    printf '%s,%s\n' "$tiempos" "$mediana"
}

cab="config,hilos,n"
for r in $(seq 1 "$REPS"); do cab="$cab,rep$r"; done
cab="$cab,mediana_s,speedup,eficiencia"
echo "$cab" > "$CSV"

echo "[4/5] midiendo V1 (n=$N, semilla=$SEMILLA, $REPS repeticiones + calentamiento)"
fila="$(mide ./v1/v1 "$N" "$SEMILLA")" || { echo "ERROR: v1 falló al medir" >&2; exit 1; }
T1="${fila##*,}"
echo "v1,1,$N,$fila,1.000,1.000" >> "$CSV"
echo "      v1  mediana=${T1}s"
if awk -v t="$T1" 'BEGIN { exit !(t < 1.0) }'; then
    echo "      AVISO: T(1)=${T1}s < 1 s. Válido para probar el flujo, NO para el reporte (protocolo §2)."
fi

for h in $HILOS; do
    echo "      midiendo V2 con $h hilo(s)"
    fila="$(mide ./v2/v2 "$N" "$SEMILLA" "$h")" || { echo "ERROR: v2 falló con $h hilos" >&2; exit 1; }
    Tp="${fila##*,}"
    se="$(awk -v t1="$T1" -v tp="$Tp" -v p="$h" 'BEGIN { s = t1/tp; printf "%.3f,%.3f", s, s/p }')"
    echo "v2,$h,$N,$fila,$se" >> "$CSV"
    echo "      v2  hilos=$h  mediana=${Tp}s  speedup,eficiencia=$se"
done
echo "      CSV -> $CSV"

# ---------- 5. Tabla y gráfica ----------
if [ "$GRAFICA" -eq 1 ]; then
    if python3 -c "import numpy, matplotlib" 2>/dev/null; then
        echo "[5/5] tabla y gráfica"
        extra=""
        [ -f resultados/mediciones_v3.csv ] && extra="--v3 resultados/mediciones_v3.csv"
        # shellcheck disable=SC2086
        python3 herramientas/resumen_csv.py "$CSV" $extra --png resultados/speedup.png --md resultados/tabla.md \
            || { echo "ERROR: resumen_csv.py falló" >&2; exit 1; }
    else
        echo "[5/5] python3 con numpy/matplotlib no disponible: se omite la gráfica (instálalos o usa --sin-grafica)"
    fi
else
    echo "[5/5] gráfica omitida (--sin-grafica)"
fi

echo "Listo. Revisa resultados/ y ejecuta la lista de cotejo antes de entregar."
