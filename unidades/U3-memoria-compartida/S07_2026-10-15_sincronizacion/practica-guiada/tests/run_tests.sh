#!/usr/bin/env bash
# Pruebas de la práctica guiada S07.
# Compila todo y compara cada versión paralela contra la secuencial (misma semilla,
# mismos datos). Los histogramas son conteos enteros: deben coincidir exactamente.
# La suma en double de sum_variants se compara con tolerancia relativa (1e-9).
# Termina con código 0 solo si todas las pruebas pasan.
set -u
cd "$(dirname "$0")/.." || exit 1

if ! make -s all; then
    echo "FAIL  compilación"
    exit 1
fi

N_HIST=400000      # tamaños pequeños: cada caso dura < 1 s
NBINS=64
pass=0
fail=0

# check <nombre> <comando...>: PASS si el comando termina con 0 e imprime status=OK
check() {
    local name="$1"; shift
    local out
    if out="$("$@" 2>&1)" && grep -q "status=OK" <<<"$out"; then
        echo "PASS  $name"
        pass=$((pass + 1))
    else
        echo "FAIL  $name"
        echo "$out" | grep -E "RESULT|INCORRECTO|error" | tail -3
        fail=$((fail + 1))
    fi
}

for t in 1 2 4; do
    for v in critical atomic local; do
        check "histogram_$v  hilos=$t n=$N_HIST nbins=$NBINS" \
              env OMP_NUM_THREADS=$t ./histogram_$v $N_HIST $NBINS
    done
done
check "histogram_atomic  nbins=1 (maxima contencion)"   env OMP_NUM_THREADS=4 ./histogram_atomic 200000 1
check "histogram_local   nbins=4096 (combinacion larga)" env OMP_NUM_THREADS=4 ./histogram_local 400000 4096
check "histogram_local   n=7 nbins=3 (menos datos que hilos)" env OMP_NUM_THREADS=4 ./histogram_local 7 3
check "sum_variants      hilos=4 n=1000000"              env OMP_NUM_THREADS=4 ./sum_variants 1000000
check "sum_variants      hilos=3 n=1000001 (no divisible)" env OMP_NUM_THREADS=3 ./sum_variants 1000001
check "barrier_demo      hilos=4"                        env OMP_NUM_THREADS=4 ./barrier_demo 300000
check "barrier_demo      hilos=1"                        env OMP_NUM_THREADS=1 ./barrier_demo 300000

# Fase Crear (opcional): si el estudiante escribió histogram_locks.c, se prueba igual.
if [ -x ./histogram_locks ]; then
    for t in 1 4; do
        check "histogram_locks   hilos=$t n=$N_HIST nbins=$NBINS" \
              env OMP_NUM_THREADS=$t ./histogram_locks $N_HIST $NBINS
    done
    check "histogram_locks   nbins=1" env OMP_NUM_THREADS=4 ./histogram_locks 200000 1
fi

# Informativo: las versiones *_buggy deben compilar y correr; su resultado NO se exige
# (una carrera puede "salir bien" por casualidad; eso no la hace correcta).
echo "INFO  histogram_buggy hilos=4 (no cuenta para PASS/FAIL):"
OMP_NUM_THREADS=4 ./histogram_buggy 1000000 16 | grep RESULT | sed 's/^/      /'

echo "Resumen: $pass PASS, $fail FAIL"
[ "$fail" -eq 0 ]
