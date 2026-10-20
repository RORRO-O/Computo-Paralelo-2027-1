#!/usr/bin/env bash
# run_all.sh · Reproduce TODO lo medible en CPU en un solo comando (plantilla del proyecto)
#
# Uso:  ./run_all.sh [--n N] [--semilla S] [--hilos "1 2 4 8"] [--reps 5] [--rapido] [--sin-grafica]
#       --n N          tamaño del problema (por defecto: N_DEFAULT de comun/problema.h)
#       --semilla S    semilla de los datos (por defecto 12345)
#       --hilos "..."  lista de hilos para V2 (por defecto: 1 2 4 ... hasta los núcleos FÍSICOS
#                      y uno más allá, la siguiente potencia de 2; protocolo §2)
#       --reps K       repeticiones medidas por configuración (mínimo 5, protocolo §2)
#       --rapido       n pequeña (200000): comprueba que el flujo funciona en segundos. Escribe en
#                      resultados/rapido/ (ignorada por git), NUNCA en resultados/: así no pisa las
#                      mediciones del reporte. T(1) < 1 s invalida la medición: no se reporta.
#       --sin-grafica  no genera la tabla ni la gráfica
# Qué hace, en orden:
#   1. Escribe <salida>/entorno.txt (CPU, núcleos, RAM, SO, compilador, banderas, versiones de nvcc,
#      python3, numpy y matplotlib, fecha, commit, n, semilla, hilos, repeticiones). <salida> es
#      resultados/ o, con --rapido, resultados/rapido/.
#   2. make all (V1, V2 y verificación de compilación de V3 si hay nvcc).
#   3. make test: si falla, ABORTA (un programa rápido y equivocado no tiene speedup).
#   4. Mide V1 y V2 (1 calentamiento + K repeticiones por configuración) y escribe
#      <salida>/mediciones.csv con la cabecera del protocolo:
#      config,hilos,n,rep1,...,repK,mediana_s,speedup,eficiencia
#   5. Si hay python3 con numpy/matplotlib: <salida>/tabla.md y <salida>/speedup.png
#      (speedup vs hilos con la línea ideal y barras mín–máx; si existe resultados/mediciones_v3.csv
#      y no es --rapido, agrega la tabla de la V3 y un segundo panel con su speedup con y sin
#      transferencias).
#   La V3 NO se mide aquí: se mide en Colab/Kaggle con v3/notebook_colab.ipynb, que produce
#   resultados/mediciones_v3.csv y resultados/entorno_gpu.txt.
# Código de salida: 0 si todo terminó; 1 si falló la compilación, una prueba o una medición;
#   2 si los argumentos son inválidos.
# Ejemplo:  ./run_all.sh --rapido            (≈ 10 s; resultados/rapido/)
#           ./run_all.sh                     (mediciones del reporte, ≈ 30 s con el marcador de posición en 4 núcleos)
#           ./run_all.sh --hilos "1 2 4 8"   (lista explícita; declárala en el reporte)
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT" || exit 1

N=""
SEMILLA=12345
HILOS=""
REPS=5
GRAFICA=1
RAPIDO=0

falta_valor() { echo "error: $1 requiere un valor (usa --help)" >&2; exit 2; }
while [ $# -gt 0 ]; do
    case "$1" in
        --n) [ $# -ge 2 ] || falta_valor "$1"; N="$2"; shift 2 ;;
        --semilla) [ $# -ge 2 ] || falta_valor "$1"; SEMILLA="$2"; shift 2 ;;
        --hilos) [ $# -ge 2 ] || falta_valor "$1"; HILOS="$2"; shift 2 ;;
        --reps) [ $# -ge 2 ] || falta_valor "$1"; REPS="$2"; shift 2 ;;
        --rapido) RAPIDO=1; shift ;;
        --sin-grafica) GRAFICA=0; shift ;;
        -h|--help) sed -n '2,/^set -u$/p' "$0" | sed '$d'; exit 0 ;;
        *) echo "argumento desconocido: $1 (usa --help)" >&2; exit 2 ;;
    esac
done

es_entero() { case "$1" in ''|*[!0-9]*) return 1 ;; *) return 0 ;; esac; }
if ! es_entero "$REPS" || [ "$REPS" -lt 5 ]; then
    echo "error: --reps debe ser un entero >= 5 (protocolo §2)" >&2; exit 2
fi
if ! es_entero "$SEMILLA"; then echo "error: --semilla debe ser un entero sin signo" >&2; exit 2; fi
if [ "$RAPIDO" -eq 1 ]; then N="${N:-200000}"; fi
if [ -z "$N" ]; then N="$(sed -n 's/^#define N_DEFAULT[[:space:]]*\([0-9]*\)u.*/\1/p' comun/problema.h)"; fi
if ! es_entero "$N" || [ "$N" -eq 0 ]; then echo "error: n debe ser un entero > 0 (n='$N')" >&2; exit 2; fi

nucleos_logicos="$(nproc 2>/dev/null || echo 1)"
nucleos_fisicos="$(lscpu 2>/dev/null | awk -F: '/^Core\(s\) per socket/ {c=$2} /^Socket\(s\)/ {s=$2} END {if (c && s) print c*s}')"
[ -n "$nucleos_fisicos" ] || nucleos_fisicos="$nucleos_logicos"
if [ -z "$HILOS" ]; then
    # 1 2 4 ... (< físicos), los físicos, y la siguiente potencia de 2 como "uno más allá".
    HILOS="1"; p=2
    while [ "$p" -lt "$nucleos_fisicos" ]; do HILOS="$HILOS $p"; p=$((p * 2)); done
    if [ "$nucleos_fisicos" -gt 1 ]; then HILOS="$HILOS $nucleos_fisicos"; fi
    if [ "$p" -le "$nucleos_fisicos" ]; then p=$((p * 2)); fi
    HILOS="$HILOS $p"
fi
for h in $HILOS; do
    if ! es_entero "$h" || [ "$h" -eq 0 ]; then echo "error: --hilos contiene '$h' (enteros >= 1)" >&2; exit 2; fi
done

if [ "$RAPIDO" -eq 1 ]; then SALIDA=resultados/rapido; else SALIDA=resultados; fi
mkdir -p "$SALIDA"
ENTORNO="$SALIDA/entorno.txt"
CSV="$SALIDA/mediciones.csv"

# ---------- 1. Entorno ----------
{
    echo "fecha_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "commit=$(git rev-parse --short HEAD 2>/dev/null || echo sin-git)"
    echo "so=$(uname -srmo 2>/dev/null || uname -a)"
    echo "cpu_modelo=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2- | sed 's/^ //')"
    echo "nucleos_logicos=$nucleos_logicos"
    echo "nucleos_fisicos=$nucleos_fisicos"
    echo "ram_total=$(grep -m1 MemTotal /proc/meminfo 2>/dev/null | awk '{printf "%.1f GiB\n", $2/1024/1024}')"
    echo "compilador=$(gcc --version 2>/dev/null | head -1)"
    echo "banderas_v1=$(sed -n 's/^CFLAGS *?= *//p' v1/Makefile)"
    echo "banderas_v2=$(sed -n 's/^CFLAGS *?= *//p' v2/Makefile)"
    if command -v nvcc > /dev/null 2>&1; then echo "nvcc=$(nvcc --version | tail -1)"; else echo "nvcc=no-disponible"; fi
    echo "python=$(python3 --version 2>/dev/null || echo no-disponible)"
    echo "numpy=$(python3 -c 'import numpy; print(numpy.__version__)' 2>/dev/null || echo no-disponible)"
    echo "matplotlib=$(python3 -c 'import matplotlib; print(matplotlib.__version__)' 2>/dev/null || echo no-disponible)"
    echo "n=$N"
    echo "semilla=$SEMILLA"
    echo "hilos=$HILOS"
    echo "hilos_mas_alla_de_fisicos=$(for h in $HILOS; do [ "$h" -gt "$nucleos_fisicos" ] && echo "$h"; done | paste -sd' ' -)"
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
    local salida tiempos="" t
    salida="$("$@")" || return 1              # calentamiento (no se cuenta)
    for _ in $(seq 1 "$REPS"); do
        salida="$("$@")" || return 1
        t="$(campo "$salida" tiempo_s)"
        [ -n "$t" ] || { echo "ERROR: '$*' no imprimió tiempo_s=" >&2; return 1; }
        tiempos="$tiempos,$t"
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
        if [ "$RAPIDO" -eq 0 ] && [ -f resultados/mediciones_v3.csv ]; then extra="--v3 resultados/mediciones_v3.csv"; fi
        # shellcheck disable=SC2086
        python3 herramientas/resumen_csv.py "$CSV" $extra --png "$SALIDA/speedup.png" --md "$SALIDA/tabla.md" \
            || { echo "ERROR: resumen_csv.py falló" >&2; exit 1; }
    else
        echo "[5/5] python3 con numpy/matplotlib no disponible: se omite la gráfica (instálalos o usa --sin-grafica)"
    fi
else
    echo "[5/5] gráfica omitida (--sin-grafica)"
fi

echo "Listo. Revisa $SALIDA/ y ejecuta la lista de cotejo antes de entregar."
