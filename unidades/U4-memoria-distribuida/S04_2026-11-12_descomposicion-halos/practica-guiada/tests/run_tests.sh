#!/usr/bin/env bash
# Pruebas de la práctica guiada S04: la versión MPI debe coincidir con la secuencial
# (mismas iteraciones, mismos valores con tolerancia 1e-12). La versión _buggy debe terminar
# y DIFERIR de la secuencial con p > 1 (ese es el punto didáctico).
# Termina con código 0 solo si ninguna prueba falla. Los casos "isend" se marcan SKIP mientras
# exchange_halos_isend tenga TODO pendientes.

set -u
cd "$(dirname "$0")/.." || exit 1

# Open MPI se niega a correr como root salvo que se declare explícitamente.
if [ "$(id -u)" -eq 0 ]; then
    export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
fi
MPIRUN="${MPIRUN:-mpirun}"
MPIRUN_FLAGS="${MPIRUN_FLAGS:---oversubscribe}"
TOL_CMP=1e-12

make -s all || { echo "FAIL: no compila"; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0; skip=0

# compare_outputs SEQ MPI → 0 si iteraciones iguales y max|dif| <= TOL_CMP; imprime el detalle.
compare_outputs() {
    local it1 it2
    it1=$(grep '^iteraciones=' "$1"); it2=$(grep '^iteraciones=' "$2")
    if [ -z "$it1" ] || [ -z "$it2" ]; then echo "salida incompleta"; return 1; fi
    if [ "$it1" != "$it2" ]; then echo "distinto: seq '$it1' vs mpi '$it2'"; return 1; fi
    paste <(grep -E '^[0-9]+ ' "$1") <(grep -E '^[0-9]+ ' "$2") | awk -v tol="$TOL_CMP" '
        { if (NF != 4 || $1 != $3) { bad = 1 }
          d = $2 - $4; if (d < 0) d = -d; if (d > m) m = d; n++ }
        END { printf("%s, %d celdas, max|dif|=%.1e", "'"$it1"'", n, m);
              if (bad || n == 0 || m > tol) exit 1; else exit 0 }'
}

# run_case NOMBRE N TOL MAX_ITER NP MODO   (MODO: sendrecv | isend)
run_case() {
    local name=$1 n=$2 tol=$3 maxit=$4 np=$5 mode=$6 detail rc
    ./jacobi1d_seq "$n" "$tol" "$maxit" --print > "$tmp/seq.txt"
    timeout 60 "$MPIRUN" $MPIRUN_FLAGS -np "$np" ./jacobi1d_mpi "$n" "$tol" "$maxit" --print --exchange "$mode" > "$tmp/mpi.txt" 2> "$tmp/err.txt"
    rc=$?
    if grep -q 'TODO pendiente' "$tmp/mpi.txt"; then
        echo "SKIP  $name (exchange_halos_isend con TODO pendiente)"; skip=$((skip+1)); return
    fi
    if [ $rc -eq 124 ]; then echo "FAIL  $name: se colgó (timeout)"; fail=$((fail+1)); return; fi
    if [ $rc -ne 0 ]; then echo "FAIL  $name: mpirun terminó con código $rc"; head -3 "$tmp/err.txt"; fail=$((fail+1)); return; fi
    if detail=$(compare_outputs "$tmp/seq.txt" "$tmp/mpi.txt"); then
        echo "PASS  $name ($detail)"; pass=$((pass+1))
    else
        echo "FAIL  $name ($detail)"; fail=$((fail+1))
    fi
}

# run_buggy NOMBRE N TOL MAX_ITER NP ESPERADO   (ESPERADO: igual | distinto)
run_buggy() {
    local name=$1 n=$2 tol=$3 maxit=$4 np=$5 expect=$6 detail rc
    ./jacobi1d_seq "$n" "$tol" "$maxit" --print > "$tmp/seq.txt"
    timeout 10 "$MPIRUN" $MPIRUN_FLAGS -np "$np" ./jacobi1d_mpi_buggy "$n" "$tol" "$maxit" --print > "$tmp/bug.txt" 2>/dev/null
    rc=$?
    if [ $rc -eq 124 ]; then echo "FAIL  $name: se colgó (timeout)"; fail=$((fail+1)); return; fi
    if [ $rc -ne 0 ]; then echo "FAIL  $name: mpirun terminó con código $rc"; fail=$((fail+1)); return; fi
    detail=$(compare_outputs "$tmp/seq.txt" "$tmp/bug.txt"); rc=$?
    if [ "$expect" = distinto ] && [ $rc -ne 0 ]; then
        echo "PASS  $name (difiere de la secuencial, como se esperaba: $detail)"; pass=$((pass+1))
    elif [ "$expect" = igual ] && [ $rc -eq 0 ]; then
        echo "PASS  $name (coincide con la secuencial: con p=1 el error es invisible)"; pass=$((pass+1))
    else
        echo "FAIL  $name (se esperaba '$expect'; $detail)"; fail=$((fail+1))
    fi
}

echo "== jacobi1d_mpi (Sendrecv) vs jacobi1d_seq =="
run_case "n=12 p=3 tol=1e-3 (caso de la práctica)"      12   1e-3 100000 3 sendrecv
run_case "n=13 p=5 tol=1e-2 (bloques 3,3,3,2,2)"        13   1e-2 100000 5 sendrecv
run_case "n=100 p=4 tol=1e-4"                           100  1e-4 1000000 4 sendrecv
run_case "n=5000 p=4 max_iter=2000 (para por límite)"   5000 1e-9 2000 4 sendrecv
run_case "n=7 p=1 (sin vecinos: todo es MPI_PROC_NULL)" 7    1e-6 100000 1 sendrecv

echo "== jacobi1d_mpi (Isend/Irecv/Waitall, fase MODIFICAR) =="
run_case "isend n=12 p=3 tol=1e-3"                      12   1e-3 100000 3 isend
run_case "isend n=13 p=5 tol=1e-2"                      13   1e-2 100000 5 isend
run_case "isend n=5000 p=4 max_iter=2000"               5000 1e-9 2000 4 isend

echo "== jacobi1d_mpi_buggy (sin halo izquierdo) =="
run_buggy "buggy n=12 p=3 debe diferir"                 12   1e-3 100000 3 distinto
run_buggy "buggy n=12 p=1 debe coincidir"               12   1e-3 100000 1 igual

echo "== resumen: $pass PASS, $fail FAIL, $skip SKIP =="
[ "$fail" -eq 0 ]
