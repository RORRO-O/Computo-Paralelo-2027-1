#!/usr/bin/env bash
# plantilla-run_tests.sh — Esqueleto de tests/run_tests.sh para prácticas y proyecto (PASS/FAIL con tolerancia).
# Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · herramientas/
#
# Qué hace: para cada tamaño de TAMANOS ejecuta la versión secuencial de referencia, toma el valor que imprime
# en la línea "CLAVE=<valor>" y lo compara, con tolerancia relativa TOL, contra lo que imprime la versión
# paralela con cada cantidad de HILOS. Imprime PASS/FAIL por caso y termina con código 0 solo si todo pasa
# (lo exige docs/CONVENCIONES.md §3 y 03-plantilla-practica.md §3). Después agrega tus casos en casos_extra().
#
# Cómo usarlo en tu repositorio:
#   1. cp herramientas/plantilla-run_tests.sh  <tu-carpeta>/tests/run_tests.sh  &&  chmod +x tests/run_tests.sh
#   2. Ajusta las variables de CONFIGURACIÓN (o pásalas por entorno desde el Makefile: ver Makefile.openmp).
#   3. Completa casos_extra() (busca TODO). Mientras no tenga casos propios, el script imprime "TODO pendiente"
#      (no falla por eso; la rúbrica pide casos propios para el nivel Ejemplar). El Makefile llama a este script
#      en el objetivo `test`.
#
# Convención con los programas: imprimen "CLAVE=valor" (p. ej. resultado= o checksum=) y aceptan el tamaño
# como último argumento. Con MODO=mpi la versión paralela se lanza con "$MPIRUN -np P programa".
#
# Variables (todas se pueden dar por entorno):
#   PROGRAMA_SEQ   ejecutable secuencial de referencia      (por defecto ./programa_seq)
#   PROGRAMA_PAR   ejecutable paralelo                       (por defecto ./programa)
#   CLAVE          clave que se compara                      (por defecto resultado)
#   TOL            tolerancia relativa |a-b| <= TOL*max(1,|a|) (por defecto 1e-6)
#   TAMANOS        tamaños de prueba, pequeños (<= 1 s)      (por defecto "1000 100000")
#   HILOS          hilos o procesos a probar                 (por defecto "1 2 4")
#   MODO           openmp | mpi                              (por defecto openmp)
#   MPIRUN         comando mpirun con sus banderas           (por defecto "mpirun ${MPIRUN_FLAGS:-}")
#
# Ejemplos ejecutables (desde herramientas/, después de `make`):
#   PROGRAMA_SEQ=./ejemplo_cronometro_seq.out PROGRAMA_PAR=./ejemplo_cronometro.out ./plantilla-run_tests.sh
#   MODO=mpi MPIRUN_FLAGS=--oversubscribe PROGRAMA_SEQ=./ejemplo_cronometro_seq.out PROGRAMA_PAR=./ejemplo_mpi.out ./plantilla-run_tests.sh
set -uo pipefail
export LC_ALL=C
# El script vive en tests/ y los programas un nivel arriba; si se ejecuta desde otra carpeta no se mueve.
if [[ $(basename "$(cd "$(dirname "$0")" && pwd)") == tests ]]; then
    cd "$(dirname "$0")/.." || exit 1
fi

# ---------- CONFIGURACIÓN (edita aquí o pasa variables de entorno) ----------
PROGRAMA_SEQ=${PROGRAMA_SEQ:-./programa_seq}
PROGRAMA_PAR=${PROGRAMA_PAR:-./programa}
CLAVE=${CLAVE:-resultado}
TOL=${TOL:-1e-6}
TAMANOS=${TAMANOS:-"1000 100000"}
HILOS=${HILOS:-"1 2 4"}
MODO=${MODO:-openmp}
MPIRUN=${MPIRUN:-"mpirun ${MPIRUN_FLAGS:-}"}
if [[ $MODO == mpi && $(id -u) == 0 ]]; then
    export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
fi

# ---------- Infraestructura (normalmente no se toca) ----------
PASS=0
FAIL=0
pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1${2:+ — $2}"; FAIL=$((FAIL + 1)); }

# valor_de "CLAVE" <<< "salida" -> imprime el valor de la última línea CLAVE=valor; código 1 si no hay.
valor_de() { awk -F= -v k="$1" '$1 == k { v = $2 } END { if (v == "") exit 1; print v }'; }

# iguales_con_tol A B TOL -> código 0 si |A-B| <= TOL * max(1, |A|). Implementado con awk; si prefieres
# python3: python3 -c "import sys,math; a,b,t=map(float,sys.argv[1:]); sys.exit(0 if abs(a-b)<=t*max(1,abs(a)) else 1)" A B TOL
iguales_con_tol() {
    awk -v a="$1" -v b="$2" -v t="$3" 'BEGIN { d = a - b; if (d < 0) d = -d; m = a < 0 ? -a : a; if (m < 1) m = 1; exit !(d <= t * m) }'
}

# correr_par HILOS ARGS... -> ejecuta la versión paralela con esa cantidad de hilos o procesos.
correr_par() {
    local p=$1
    shift
    if [[ $MODO == mpi ]]; then
        # shellcheck disable=SC2086  # MPIRUN se divide a propósito
        $MPIRUN -np "$p" "$PROGRAMA_PAR" "$@"
    else
        OMP_NUM_THREADS=$p "$PROGRAMA_PAR" "$@"
    fi
}

# caso_valor "nombre" ESPERADO OBTENIDO [TOL] -> PASS si coinciden con tolerancia.
caso_valor() {
    local nombre=$1 esperado=$2 obtenido=$3 tol=${4:-$TOL}
    if [[ -z $esperado || -z $obtenido ]]; then
        fail "$nombre" "falta un valor (esperado='$esperado', obtenido='$obtenido')"
    elif iguales_con_tol "$esperado" "$obtenido" "$tol"; then
        pass "$nombre"
    else
        fail "$nombre" "esperado $esperado, obtenido $obtenido (tol $tol)"
    fi
}

# caso_comando "nombre" comando... -> PASS si el comando termina con código 0 (salida silenciada).
caso_comando() {
    local nombre=$1
    shift
    if "$@" > /dev/null 2>&1; then pass "$nombre"; else fail "$nombre" "código $?"; fi
}

# caso_archivos "nombre" ARCHIVO_REF ARCHIVO_OBT [TOL] -> compara número a número (python3) o texto exacto.
caso_archivos() {
    local nombre=$1 ref=$2 obt=$3 tol=${4:-$TOL}
    if [[ ! -f $ref || ! -f $obt ]]; then
        fail "$nombre" "falta $ref o $obt"
    elif command -v python3 > /dev/null 2>&1; then
        if python3 - "$ref" "$obt" "$tol" << 'PY' > /dev/null; then pass "$nombre"; else fail "$nombre" "difieren más de la tolerancia"; fi
import re
import sys

ref, obt, tol = sys.argv[1], sys.argv[2], float(sys.argv[3])
num = re.compile(r"[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?")
with open(ref, encoding="utf-8", errors="replace") as fa, open(obt, encoding="utf-8", errors="replace") as fb:
    la, lb = fa.read().split(), fb.read().split()
if len(la) != len(lb):
    sys.exit(1)
for a, b in zip(la, lb):
    if num.fullmatch(a) and num.fullmatch(b):
        x, y = float(a), float(b)
        if abs(x - y) > tol * max(1.0, abs(x)):
            sys.exit(1)
    elif a != b:
        sys.exit(1)
PY
    else
        if cmp -s "$ref" "$obt"; then pass "$nombre"; else fail "$nombre" "difieren (sin python3 la comparación es exacta)"; fi
    fi
}

# ---------- Casos base: paralelo vs secuencial con tolerancia ----------
casos_base() {
    local faltan=0
    for prog in "$PROGRAMA_SEQ" "$PROGRAMA_PAR"; do
        if [[ ! -x $prog ]]; then
            fail "existe y es ejecutable $prog" "edita PROGRAMA_SEQ/PROGRAMA_PAR o corre make"
            faltan=1
        fi
    done
    [[ $faltan -eq 0 ]] || return
    for n in $TAMANOS; do
        local salida_seq ref
        salida_seq=$("$PROGRAMA_SEQ" "$n" 2> /dev/null)
        if [[ $? -ne 0 ]]; then
            fail "secuencial termina con código 0 (n=$n)"
            continue
        fi
        ref=$(valor_de "$CLAVE" <<< "$salida_seq") || { fail "secuencial imprime $CLAVE= (n=$n)"; continue; }
        pass "secuencial corre e imprime $CLAVE=$ref (n=$n)"
        for p in $HILOS; do
            local salida_par obt
            salida_par=$(correr_par "$p" "$n" 2> /dev/null)
            if [[ $? -ne 0 ]]; then
                fail "paralelo termina con código 0 (n=$n, p=$p)"
                continue
            fi
            obt=$(valor_de "$CLAVE" <<< "$salida_par") || { fail "paralelo imprime $CLAVE= (n=$n, p=$p)"; continue; }
            caso_valor "$CLAVE paralelo == secuencial (n=$n, p=$p)" "$ref" "$obt"
        done
    done
}

# ---------- Casos propios de la práctica o del proyecto ----------
casos_extra() {
    : # TODO(1): agrega aquí casos específicos. Ejemplos (descomenta y adapta):
    # caso_comando "rechaza un tamaño no válido" bash -c "! $PROGRAMA_PAR abc"
    # caso_valor "n=1 da el valor conocido a mano" 3.2 "$("$PROGRAMA_PAR" 1 | valor_de resultado)" 1e-12
    # local salida; salida=$(mktemp); "$PROGRAMA_PAR" 1000 > "$salida"
    # caso_archivos "salida completa igual a la referencia" tests/ref_1000.txt "$salida" 1e-9; rm -f "$salida"
}

casos_base
antes=$((PASS + FAIL))
casos_extra
if [[ $((PASS + FAIL)) -eq $antes ]]; then
    echo "AVISO: TODO pendiente — casos_extra() no tiene casos propios (TODO(1) de este archivo)."
fi

echo "Resultado: $PASS PASS, $FAIL FAIL"
[[ $FAIL -eq 0 ]]
