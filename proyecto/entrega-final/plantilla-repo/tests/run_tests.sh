#!/usr/bin/env bash
# tests/run_tests.sh · Pruebas automáticas del proyecto integrador (plantilla)
#
# Uso:  bash tests/run_tests.sh [--sin-compilar] [--solo-v3]
#       --sin-compilar  no invoca make (lo usa `make test`, que ya compiló)
#       --solo-v3       solo compara ./v3/v3 contra ./v1/v1 (para correr en Colab/Kaggle)
# Qué hace: compara V2 (y V3 si existe el binario) contra V1 con los MISMOS datos
#       (misma n y misma semilla) usando tolerancia relativa TOL, con 1, 2, 4 y 8 hilos y
#       REPS_PRUEBA corridas de V2 por caso (una carrera es no determinista: "salió bien una
#       vez" no es evidencia; proyecto/README.md §2 y hitos/H2-avance-2.md); verifica
#       determinismo, casos borde, OMP_NUM_THREADS y manejo de argumentos inválidos.
# Salida: una línea PASS/FAIL por caso; código 0 solo si todos pasan.
# Ejemplo: bash tests/run_tests.sh
#
# AGREGA TUS PROPIOS CASOS al final (sección "Casos del equipo"). La rúbrica (Correctitud,
# nivel Ejemplar) pide casos que vengan de TU problema: tamaños límite, datos degenerados,
# entradas que rompen la descomposición, etc. Para la V1 incluye los tres tipos que pide
# proyecto/README.md §2: un caso pequeño verificable a mano, uno con referencia externa
# (solución conocida o biblioteca) y un invariante del problema (simetría, conservación).
set -u

TOL="${TOL:-1e-9}"           # tolerancia relativa para comparar checksums
REPS_PRUEBA="${REPS_PRUEBA:-3}"   # corridas de V2 por caso (>= 3)
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
V1="$ROOT/v1/v1"
V2="$ROOT/v2/v2"
V3="$ROOT/v3/v3"
COMPILAR=1
SOLO_V3=0
for arg in "$@"; do
    case "$arg" in
        --sin-compilar) COMPILAR=0 ;;
        --solo-v3) SOLO_V3=1 ;;
        *) echo "argumento desconocido: $arg" >&2; exit 2 ;;
    esac
done

case "$REPS_PRUEBA" in ''|*[!0-9]*|0) echo "REPS_PRUEBA debe ser un entero >= 1" >&2; exit 2 ;; esac

pass=0
fail=0
ok()   { echo "PASS  $1"; pass=$((pass + 1)); }
bad()  { echo "FAIL  $1  ($2)"; fail=$((fail + 1)); }

# Extrae el valor de "clave=valor" de la salida de un programa.
campo() { printf '%s\n' "$1" | awk -F= -v k="$2" '$1 == k { print $2; exit }'; }

# ¿|a - b| <= TOL * max(1, |a|)?  (awk maneja notación científica)
iguales() {
    awk -v a="$1" -v b="$2" -v tol="$TOL" 'BEGIN {
        d = a - b; if (d < 0) d = -d;
        m = a; if (m < 0) m = -m; if (m < 1) m = 1;
        exit !(d <= tol * m) }'
}

# compara_v2 <nombre> <n> <semilla> <hilos>: corre V1 una vez y V2 REPS_PRUEBA veces; cada
# corrida de V2 debe coincidir con V1 dentro de TOL.
compara_v2() {
    local nombre="$1" n="$2" semilla="$3" hilos="$4"
    local s1 s2 c1 c2 r
    if ! s1="$("$V1" "$n" "$semilla")"; then bad "$nombre" "v1 terminó con error"; return; fi
    c1="$(campo "$s1" checksum)"
    if [ -z "$c1" ]; then bad "$nombre" "v1 no imprimió checksum"; return; fi
    for r in $(seq 1 "$REPS_PRUEBA"); do
        if ! s2="$("$V2" "$n" "$semilla" "$hilos")"; then bad "$nombre" "v2 terminó con error (corrida $r)"; return; fi
        c2="$(campo "$s2" checksum)"
        if [ -z "$c2" ]; then bad "$nombre" "v2 no imprimió checksum (corrida $r)"; return; fi
        if ! iguales "$c1" "$c2"; then
            bad "$nombre" "corrida $r de $REPS_PRUEBA: v1=$c1 v2=$c2 difieren más de TOL=$TOL"; return
        fi
    done
    ok "$nombre  ($REPS_PRUEBA corridas; v1=$c1 v2=$c2)"
}

if [ "$COMPILAR" -eq 1 ] && [ "$SOLO_V3" -eq 0 ]; then
    if ! make -C "$ROOT" v1 v2 > /dev/null; then echo "FAIL  compilación"; exit 1; fi
fi

if [ "$SOLO_V3" -eq 0 ]; then
    [ -x "$V1" ] || { echo "FAIL  no existe $V1 (ejecuta make)"; exit 1; }
    [ -x "$V2" ] || { echo "FAIL  no existe $V2 (ejecuta make)"; exit 1; }

    # 1. Determinismo de V1: misma semilla -> checksum idéntico (bit a bit).
    a="$(campo "$("$V1" 20000 3)" checksum)"; b="$(campo "$("$V1" 20000 3)" checksum)"
    if [ -n "$a" ] && [ "$a" = "$b" ]; then ok "v1 determinista con la misma semilla"; else bad "v1 determinista" "$a vs $b"; fi

    # 2. Semillas distintas producen datos distintos (si no, la semilla no se está usando).
    c="$(campo "$("$V1" 20000 4)" checksum)"
    if [ "$a" != "$c" ]; then ok "v1 cambia con la semilla"; else bad "v1 cambia con la semilla" "semillas 3 y 4 dan el mismo checksum"; fi

    # 3–6. V2 contra V1 con 1, 2, 4 y 8 hilos (8 puede ser más que los núcleos: también debe dar bien).
    compara_v2 "v2 == v1 con 1 hilo"  50000 11 1
    compara_v2 "v2 == v1 con 2 hilos" 50000 11 2
    compara_v2 "v2 == v1 con 4 hilos" 50000 11 4
    compara_v2 "v2 == v1 con 8 hilos" 50000 11 8

    # 7. Caso borde: n = 1.
    compara_v2 "v2 == v1 con n=1" 1 5 4

    # 8. n no divisible entre los hilos.
    compara_v2 "v2 == v1 con n=1001 y 3 hilos" 1001 9 3

    # 9. Argumentos inválidos devuelven código distinto de 0 y mensaje en stderr.
    if "$V1" 0 > /dev/null 2>&1; then bad "v1 rechaza n=0" "devolvió 0"; else ok "v1 rechaza n=0"; fi
    if "$V2" abc > /dev/null 2>&1; then bad "v2 rechaza n no numérico" "devolvió 0"; else ok "v2 rechaza n no numérico"; fi

    # 10. V2 reporta el número de hilos que realmente usó, y sin [hilos] respeta OMP_NUM_THREADS.
    h="$(campo "$("$V2" 1000 1 3)" hilos)"
    if [ "$h" = "3" ]; then ok "v2 reporta hilos=3"; else bad "v2 reporta hilos" "imprimió hilos=$h"; fi
    h="$(campo "$(OMP_NUM_THREADS=2 "$V2" 1000 1)" hilos)"
    if [ "$h" = "2" ]; then ok "v2 respeta OMP_NUM_THREADS=2"; else bad "v2 respeta OMP_NUM_THREADS" "imprimió hilos=$h"; fi

    # ---- Casos del equipo (agrega aquí; cada uno con un comentario de por qué importa) ----
    # compara_v2 "descripción" <n> <semilla> <hilos>
fi

# 11. V3 contra V1 (solo si existe el binario: Colab/Kaggle).
if [ -x "$V3" ]; then
    [ -x "$V1" ] || { echo "FAIL  no existe $V1 (compila v1 también en Colab)"; exit 1; }
    s1="$("$V1" 200000 21)"; s3="$("$V3" 200000 21)"
    c1="$(campo "$s1" checksum)"; c3="$(campo "$s3" checksum)"
    if [ -n "$c3" ] && iguales "$c1" "$c3"; then ok "v3 == v1 (n=200000)  (v1=$c1 v3=$c3)"; else bad "v3 == v1" "v1=$c1 v3=$c3"; fi
    tk="$(campo "$s3" tiempo_kernel_s)"; tt="$(campo "$s3" tiempo_total_s)"
    if [ -n "$tk" ] && [ -n "$tt" ]; then ok "v3 reporta tiempo con y sin transferencias"; else bad "v3 tiempos" "faltan tiempo_kernel_s/tiempo_total_s"; fi
elif [ "$SOLO_V3" -eq 1 ]; then
    echo "FAIL  no existe $V3 (compila con make -C v3 all en Colab/Kaggle)"; fail=$((fail + 1))
else
    echo "INFO  v3 no compilada en esta máquina: su prueba se ejecuta en Colab/Kaggle (notebook, celda 'Verificación')"
fi

echo "----"
echo "Resumen: $pass PASS, $fail FAIL"
[ "$fail" -eq 0 ]
