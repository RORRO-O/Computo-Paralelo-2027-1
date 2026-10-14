#!/usr/bin/env bash
# Pruebas de la práctica guiada S10.
# Compila todo y corre cada programa con tamaños pequeños y 1, 2, 3 y 4 hilos. Cada programa compara su
# resultado paralelo con su propia versión secuencial (conteos exactos; sumas en double con tolerancia
# relativa 1e-9) e imprime status=OK. Además verifica que el CSV tenga el formato del protocolo y que
# graficar.py produzca el PNG. Termina con código 0 solo si todas las pruebas pasan (< 40 s en 4 núcleos).
set -u
cd "$(dirname "$0")/.." || exit 1

if ! make -s all; then
    echo "FAIL  compilación"
    exit 1
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
pass=0
fail=0

# check <nombre> <comando...>: PASS si termina con 0 y todas sus líneas RESULT dicen status=OK
check() {
    local name="$1"; shift
    local out
    if out="$("$@" 2>&1)" && grep -q "status=OK" <<<"$out" && ! grep -q "status=INCORRECTO" <<<"$out"; then
        echo "PASS  $name"
        pass=$((pass + 1))
    else
        echo "FAIL  $name"
        echo "$out" | grep -E "RESULT|INCORRECTO|error|Error" | tail -4
        fail=$((fail + 1))
    fi
}

for t in 1 2 3 4; do
    check "false_sharing    hilos=$t n=2000000"            env OMP_NUM_THREADS=$t ./false_sharing 2000000 "$TMP/fs.csv"
    check "profile_amdahl   hilos=$t n=200000 iters=16"    env OMP_NUM_THREADS=$t ./profile_amdahl 200000 16 "$TMP/pa.csv"
    check "saxpy_vs_matmul  hilos=$t n=1000000 m=128"      env OMP_NUM_THREADS=$t ./saxpy_vs_matmul 1000000 128 "$TMP/sm.csv"
    check "weak_scaling     hilos=$t n_por_hilo=100000"     env OMP_NUM_THREADS=$t ./weak_scaling 100000 "$TMP/ws.csv"
done
check "region_overhead  hilos=4 n=500 k=2000 (pasadas cortas)"   env OMP_NUM_THREADS=4 ./region_overhead 500 2000
check "region_overhead  hilos=3 n=200000 k=5 (n no divisible)"   env OMP_NUM_THREADS=3 ./region_overhead 200000 5
check "region_overhead  hilos=4 n=7 k=3 (menos datos que hilos)" env OMP_NUM_THREADS=4 ./region_overhead 7 3
check "false_sharing    hilos=4 n=5 (menos datos que hilos)"    env OMP_NUM_THREADS=4 ./false_sharing 5 "$TMP/fs.csv"

# Formato del CSV del protocolo: encabezado exacto y 11 columnas en todas las filas.
HEADER="config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia"
for f in fs pa sm ws; do
    if [ "$(head -1 "$TMP/$f.csv")" = "$HEADER" ] && \
       awk -F, 'NR > 1 && NF != 11 { bad = 1 } END { exit bad }' "$TMP/$f.csv"; then
        echo "PASS  csv $f: encabezado del protocolo y 11 columnas ($(($(wc -l < "$TMP/$f.csv") - 1)) filas)"
        pass=$((pass + 1))
    else
        echo "FAIL  csv $f: formato"; fail=$((fail + 1))
    fi
done
# La fila secuencial se escribe solo con 1 hilo: debe haber exactamente una por CSV.
n_seq=$(grep -c '^secuencial,1,' "$TMP/fs.csv")
if [ "$n_seq" -eq 1 ]; then echo "PASS  csv fs: una sola fila secuencial"; pass=$((pass + 1));
else echo "FAIL  csv fs: $n_seq filas secuenciales"; fail=$((fail + 1)); fi

# graficar.py: PNG generado y tabla Markdown en la salida (se omite con aviso si no hay matplotlib).
if python3 -c "import matplotlib" 2>/dev/null; then
    if out="$(python3 graficar.py "$TMP/fs.csv" --salida "$TMP/fs.png" 2>&1)" && [ -s "$TMP/fs.png" ] \
       && grep -q "^| contiguo | 4 |" <<<"$out"; then
        echo "PASS  graficar.py: PNG y tabla Markdown"; pass=$((pass + 1))
    else
        echo "FAIL  graficar.py"; echo "$out" | tail -3; fail=$((fail + 1))
    fi
    if python3 graficar.py tests/run_tests.sh --salida "$TMP/x.png" >/dev/null 2>&1; then
        echo "FAIL  graficar.py acepta un archivo que no es CSV"; fail=$((fail + 1))
    else
        echo "PASS  graficar.py rechaza un archivo sin las columnas del protocolo"; pass=$((pass + 1))
    fi
else
    echo "SKIP  graficar.py (python3 sin matplotlib)"
fi

echo "Resumen: $pass PASS, $fail FAIL"
[ "$fail" -eq 0 ]
