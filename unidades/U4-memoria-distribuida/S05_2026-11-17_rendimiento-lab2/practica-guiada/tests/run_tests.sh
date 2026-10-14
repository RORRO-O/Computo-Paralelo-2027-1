#!/usr/bin/env bash
# Pruebas de la práctica guiada S05. Imprime PASS/FAIL por caso; código 0 solo si todo pasa.
# Tamaños pequeños (cada caso < 5 s). Las comparaciones son contra jacobi_seq con tolerancia.
set -u
cd "$(dirname "$0")/.."

if [ "$(id -u)" -eq 0 ]; then
    export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
fi
MPIRUN_FLAGS=${MPIRUN_FLAGS:---oversubscribe}
TOL=1e-9        # tolerancia relativa para el checksum (el orden de la suma cambia con p)
N=10007         # no divisible entre 2 ni 4: ejercita el reparto con residuo
ITERS=300

pass=0; fail=0
report() { # $1 = PASS|FAIL, $2 = nombre, $3 = detalle
    if [ "$1" = PASS ]; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
    printf "%s  %-52s %s\n" "$1" "$2" "${3:-}"
}

if ! make -s all; then
    echo "FAIL  compilación"
    exit 1
fi
report PASS "compilación (mpicc/gcc -std=c11 -O2 -Wall -Wextra)"

# --- Referencia secuencial
ref=$(timeout 30 ./jacobi_seq $N $ITERS 2 | grep '^RESULT')
ref_sum=$(echo "$ref" | awk -F, '{print $12}')
ref_mid=$(echo "$ref" | awk -F, '{print $13}')
if [ -n "$ref_sum" ]; then report PASS "jacobi_seq corre (n=$N, iters=$ITERS)" "checksum=$ref_sum"; else report FAIL "jacobi_seq corre"; fi

# --- Correctitud MPI contra la secuencial, p = 1, 2, 3, 4 (p=2 con reps=5 para revisar el formato RESULT)
for p in 1 2 3 4; do
    reps=2; [ "$p" = 2 ] && reps=5
    out=$(timeout 30 mpirun $MPIRUN_FLAGS -np $p ./jacobi_mpi $N $ITERS $reps | grep '^RESULT')
    got_sum=$(echo "$out" | awk -F, '{print $12}')
    got_mid=$(echo "$out" | awk -F, '{print $13}')
    if [ -z "$got_sum" ]; then report FAIL "jacobi_mpi p=$p corre"; continue; fi
    ok=$(awk -v a="$ref_sum" -v b="$got_sum" -v ma="$ref_mid" -v mb="$got_mid" -v tol=$TOL \
        'BEGIN { d = a - b; if (d < 0) d = -d; rel = d / (a < 0 ? -a : a);
                 print (rel <= tol && ma == mb) ? "yes" : "no" }')
    if [ "$ok" = yes ]; then
        report PASS "jacobi_mpi p=$p coincide con jacobi_seq" "checksum rel.err<=$TOL, u_probe igual"
    else
        report FAIL "jacobi_mpi p=$p coincide con jacobi_seq" "seq=$ref_sum mpi=$got_sum probe: $ref_mid vs $got_mid"
    fi
    if [ "$p" = 2 ]; then
        nf=$(echo "$out" | awk -F, '{print NF}')
        nt=$(echo "$out" | awk -F, '{print split($6, a, ";")}')
        if [ "$nf" = 13 ] && [ "$nt" = 5 ]; then report PASS "formato RESULT (13 campos, 5 repeticiones)"; else report FAIL "formato RESULT" "campos=$nf tiempos=$nt"; fi
    fi
done

# --- Híbrido: 2 procesos x 2 hilos, suma exacta
out=$(OMP_NUM_THREADS=2 timeout 30 mpirun $MPIRUN_FLAGS -np 2 ./hybrid_min 1000003)
if echo "$out" | grep -q " OK " && [ "$(echo "$out" | grep -c 'hilos OpenMP')" = 2 ] \
   && echo "$out" | grep -q "rango 1 de 2 en .*: 2 hilos OpenMP"; then
    report PASS "hybrid_min 2x2: suma exacta y 2 hilos por rango" "$(echo "$out" | grep -o 'provisto: [A-Z_]*')"
else
    report FAIL "hybrid_min 2x2" "$out"
fi
# Con 1 hilo también debe funcionar (y seguir siendo exacto)
out=$(OMP_NUM_THREADS=1 timeout 30 mpirun $MPIRUN_FLAGS -np 3 ./hybrid_min 777777)
if echo "$out" | grep -q " OK " && [ "$(echo "$out" | grep -c ': 1 hilos OpenMP')" = 3 ]; then
    report PASS "hybrid_min 3x1: suma exacta"
else
    report FAIL "hybrid_min 3x1" "$out"
fi

# --- Ping-pong: produce alpha y beta positivos
out=$(timeout 60 mpirun $MPIRUN_FLAGS -np 2 ./pingpong 0.1 | grep '^RESULT')
ok=$(echo "$out" | awk -F, '{ print ($3 > 0 && $5 > 0) ? "yes" : "no" }')
if [ "$ok" = yes ]; then report PASS "pingpong (factor 0.1): alpha y beta medidos" "$out"; else report FAIL "pingpong" "$out"; fi

# --- escalado.sh en pequeño (solo p=2 y p=8 sobre-suscrito, para que la prueba sea corta):
#     CSV con el encabezado del protocolo, 3 filas (seq, mpi, mpi_oversub), gráficas y entorno.txt
rm -rf resultados-prueba
if N=20000 ITERS=200 NLOCAL=5000 PROCS="2" OVERSUB=8 OUT=resultados-prueba PLOT=1 MPIRUN_FLAGS="$MPIRUN_FLAGS" \
   timeout 60 ./escalado.sh > resultados-prueba.log 2>&1; then
    hdr="config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia"
    rows_f=$(tail -n +2 resultados-prueba/fuerte.csv | wc -l)
    rows_w=$(tail -n +2 resultados-prueba/debil.csv | wc -l)
    cols_ok=$(awk -F, 'NF != 11 { bad = 1 } END { print bad ? "no" : "yes" }' resultados-prueba/fuerte.csv resultados-prueba/debil.csv)
    if [ "$(head -1 resultados-prueba/fuerte.csv)" = "$hdr" ] && [ "$(head -1 resultados-prueba/debil.csv)" = "$hdr" ] \
       && [ "$rows_f" = 3 ] && [ "$rows_w" = 3 ] && [ "$cols_ok" = yes ] && grep -q '^mpi_oversub,8,' resultados-prueba/fuerte.csv \
       && grep -q '^mpi,2,20000,' resultados-prueba/fuerte.csv && grep -q '^mpi,2,10000,' resultados-prueba/debil.csv \
       && [ -s resultados-prueba/fuerte.png ] && [ -s resultados-prueba/debil.png ] && [ -s resultados-prueba/entorno.txt ]; then
        report PASS "escalado.sh: CSV del protocolo (3 filas), oversub etiquetado, PNG"
    else
        report FAIL "escalado.sh: formato de salida" "filas fuerte=$rows_f debil=$rows_w cols_ok=$cols_ok"
    fi
else
    report FAIL "escalado.sh termina sin error" "$(tail -3 resultados-prueba.log)"
fi
rm -rf resultados-prueba resultados-prueba.log

# --- modelo.py: valores conocidos. alpha=1us, beta=1GB/s, bytes=8 -> T_halo = 2*(1 + 0.008) us = 2.016 us
#     tc=1ns, p=4 -> n* = 2.016e-6/(1e-9*0.75) = 2688 ; n_E(0.5) = 0.5*4*2.016e-6/(1e-9*0.5) = 8064
out=$(python3 modelo.py --alpha-us 1 --beta-gbps 1 --tc-ns 1 --p 4 --n 8064)
if echo "$out" | grep -q "n\* (punto de equilibrio, S=1):      2,688 puntos" \
   && echo "$out" | grep -q "n_E (eficiencia >= 50%):            8,064 puntos" \
   && echo "$out" | grep -q "S = 2.00, E = 50%"; then
    report PASS "modelo.py: n*, n_E y predicción con valores conocidos"
else
    report FAIL "modelo.py" "$out"
fi

echo "---- $pass PASS, $fail FAIL"
[ "$fail" -eq 0 ]
