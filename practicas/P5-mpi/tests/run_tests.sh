#!/usr/bin/env bash
# tests/run_tests.sh — Verificación automática de la Práctica 5 (termina en < 60 s en 4 núcleos).
#
# Uso:  bash tests/run_tests.sh [all|A|B|C|D]          (make test = all; make test-b = B estricta)
# Qué comprueba:
#   compilación con -std=c11 -O2 -Wall -Wextra sin warnings;
#   A: hello (p líneas y Gather ordenado); estadísticos MPI contra a2_stats_seq con tolerancia (p = 1..4,
#      n no múltiplo de p -> Scatterv; n múltiplo -> Scatter; Scatter FORZADO con residuo debe detectarse);
#   B: reparto de filas (TODO(1) solo: "filas por rango" con p = 3 y 4) y matriz-vector MPI contra
#      b_matvec_seq (p = 1..4, filas no múltiplo de p, un rango sin filas);
#   C: calor 1D MPI contra c_heat_seq (pasos fijos, convergencia por tol, check_every > 1, una celda por
#      rango, n < p rechazado) y/o primos MPI contra c_primes_seq (cíclico y bloques);
#   D: ping-pong (alpha, beta > 0), escalado.sh en pequeño (CSV del protocolo, oversub etiquetado, PNG),
#      graficar.py con --modelo, modelo.py con valores conocidos.
# Mientras un programa imprima "TODO pendiente" (Partes B y C de la versión estudiante) sus casos se
# reportan como PEND: no cuentan como FAIL en `make test`, pero SÍ en modo estricto (STRICT=1, que es lo
# que usan make test-b, test-c y test-entrega, y lo que corre el profesor al calificar). Un TODO mal
# resuelto es FAIL siempre.
# Variables: STRICT=1 · EXTRA=1 (casos extra de calificación) · PARTE_C=heat|primes|ambas (ambas) ·
#            MPIRUN_FLAGS (--oversubscribe) · TO (timeout por comando, 40 s)
# Imprime PASS/FAIL/PEND/SKIP por caso; código de salida 0 solo si no hay FAIL.
set -u
cd "$(dirname "$0")/.." || exit 1
PART=$(echo "${1:-all}" | tr '[:lower:]' '[:upper:]')   # acepta a/A, b/B, ... o all
STRICT=${STRICT:-0}
EXTRA=${EXTRA:-0}
PARTE_C=${PARTE_C:-ambas}
TO=${TO:-40}
MPIRUN_FLAGS=${MPIRUN_FLAGS:---oversubscribe}
if [ "$(id -u)" -eq 0 ]; then
    export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
fi
export MPLBACKEND=Agg PYTHONDONTWRITEBYTECODE=1
OUT=tests/out
rm -rf "$OUT" && mkdir -p "$OUT"
S=src
pass=0; fail=0; pend=0; skip=0
ok() { printf "PASS  %-62s %s\n" "$1" "${2:-}"; pass=$((pass + 1)); }
ko() { printf "FAIL  %-62s %s\n" "$1" "${2:-}"; fail=$((fail + 1)); }
pd() { if [ "$STRICT" = 1 ]; then printf "FAIL  %-62s %s\n" "$1" "TODO pendiente (modo estricto)"; fail=$((fail + 1));
       else printf "PEND  %-62s %s\n" "$1" "TODO pendiente"; pend=$((pend + 1)); fi; }
sk() { printf "SKIP  %-62s %s\n" "$1" "${2:-}"; skip=$((skip + 1)); }
want() { [ "$PART" = ALL ] || [ "$PART" = "$1" ]; }
want_c() { [ "$PARTE_C" = ambas ] || [ "$PARTE_C" = "$1" ]; }
# close A B TOL -> 0 si |A-B| <= TOL*max(1,|B|)
close() { awk -v a="$1" -v b="$2" -v t="$3" 'BEGIN { d = a - b; if (d < 0) d = -d; m = b < 0 ? -b : b; if (m < 1) m = 1; exit !(d <= t * m) }'; }
# field ARCHIVO K -> campo K (desde 1) de la última línea RESULT,...
field() { awk -F, -v k="$2" '/^RESULT,/ { v = $k } END { print v }' "$1"; }
pending() { grep -q "TODO pendiente" "$1"; }
# run_mpi NP PROG ARGS... -> salida en $LAST, código en $rc
run_mpi() { local np=$1; shift; LAST=$OUT/last_$$.txt
    # shellcheck disable=SC2086
    timeout -k 2 "$TO" mpirun $MPIRUN_FLAGS -np "$np" "$@" > "$LAST" 2>&1; rc=$?; }
run_seq() { LAST=$OUT/last_$$.txt; timeout -k 2 "$TO" "$@" > "$LAST" 2>&1; rc=$?; }

# ---------- compilación ----------
if make -s all > "$OUT/build.log" 2>&1 && ! grep -qi "warning" "$OUT/build.log"; then
    ok "compilacion (gcc/mpicc -std=c11 -O2 -Wall -Wextra, sin warnings)"
else
    ko "compilacion" "ver $OUT/build.log"; cat "$OUT/build.log"; echo "---- $pass PASS, $fail FAIL"; exit 1
fi

# ---------- Parte A ----------
if want A; then
    run_mpi 3 ./$S/a1_hello_rank
    if [ $rc -eq 0 ] && [ "$(grep -c '^hola desde el rango' "$LAST")" = 3 ] && grep -q "MPI_Gather 3 rangos: 0 1 2" "$LAST"; then
        ok "a1_hello_rank -np 3: 3 saludos y Gather ordenado"; else ko "a1_hello_rank -np 3" "$(tail -2 "$LAST")"; fi
    run_mpi 1 ./$S/a1_hello_rank
    if [ $rc -eq 0 ] && grep -q "rango 0 de 1" "$LAST" && grep -q "MPI_Gather 1 rangos: 0" "$LAST"; then
        ok "a1_hello_rank -np 1"; else ko "a1_hello_rank -np 1"; fi

    run_seq ./$S/a2_stats_seq 100003 2; cp "$LAST" "$OUT/stats_seq.txt"
    r_sum=$(field "$LAST" 6); r_max=$(field "$LAST" 7); r_mean=$(field "$LAST" 8); r_var=$(field "$LAST" 9)
    if [ $rc -eq 0 ] && [ -n "$r_var" ]; then ok "a2_stats_seq n=100003" "suma=$r_sum"; else ko "a2_stats_seq n=100003"; fi
    for p in 1 2 3 4; do
        want_mode=scatterv; [ $((100003 % p)) -eq 0 ] && want_mode=scatter   # con p = 1 el residuo es 0
        run_mpi $p ./$S/a2_stats_mpi 100003 auto 2
        if [ $rc -eq 0 ] && [ "$(field "$LAST" 5)" = "$want_mode" ] && [ "$(field "$LAST" 11)" = OK ] \
           && close "$(field "$LAST" 6)" "$r_sum" 1e-9 && close "$(field "$LAST" 7)" "$r_max" 1e-12 \
           && close "$(field "$LAST" 8)" "$r_mean" 1e-9 && close "$(field "$LAST" 9)" "$r_var" 1e-9; then
            ok "a2_stats_mpi -np $p n=100003 ($want_mode) == secuencial"
        else ko "a2_stats_mpi -np $p n=100003" "$(grep -E 'verificacion|RESULT|TODO' "$LAST" | tail -2)"; fi
    done
    run_mpi 4 ./$S/a2_stats_mpi 100000 auto 2
    if [ $rc -eq 0 ] && [ "$(field "$LAST" 5)" = scatter ] && [ "$(field "$LAST" 11)" = OK ]; then
        ok "a2_stats_mpi -np 4 n=100000: n % p = 0 usa Scatter y verifica OK"; else ko "a2_stats_mpi -np 4 n=100000 (Scatter)"; fi
    run_mpi 4 ./$S/a2_stats_mpi 100003 scatter 2
    if [ $rc -ne 0 ] && [ "$(field "$LAST" 11)" = FALLA ] && grep -q "ADVERTENCIA" "$LAST"; then
        ok "a2_stats_mpi -np 4 n=100003 Scatter FORZADO: detecta la perdida de n % p elementos"
    else ko "a2_stats_mpi Scatter forzado con residuo" "debia fallar la verificacion: $(grep RESULT "$LAST")"; fi
    if [ "$EXTRA" = 1 ]; then
        run_mpi 5 ./$S/a2_stats_mpi 7 auto 2
        if [ $rc -eq 0 ] && [ "$(field "$LAST" 11)" = OK ]; then ok "EXTRA a2_stats_mpi -np 5 n=7 (rangos con 1 elemento)"; else ko "EXTRA a2_stats_mpi -np 5 n=7"; fi
        run_mpi 3 ./$S/a2_stats_mpi 2 auto 2
        if [ $rc -eq 0 ] && [ "$(field "$LAST" 11)" = OK ]; then ok "EXTRA a2_stats_mpi -np 3 n=2 (un rango sin elementos)"; else ko "EXTRA a2_stats_mpi -np 3 n=2"; fi
    fi
fi

# ---------- Parte B ----------
check_matvec() { # nombre np m n iters
    local name=$1 np=$2 m=$3 n=$4 it=$5
    run_seq ./$S/b_matvec_seq "$m" "$n" "$it" 2
    local cs=$(field "$LAST" 7) y0=$(field "$LAST" 8) yl=$(field "$LAST" 9)
    run_mpi "$np" ./$S/b_matvec_mpi "$m" "$n" "$it" 2
    if pending "$LAST"; then pd "$name"; return; fi
    if [ $rc -eq 0 ] && [ "$(field "$LAST" 12)" = OK ] && close "$(field "$LAST" 7)" "$cs" 1e-10 \
       && close "$(field "$LAST" 8)" "$y0" 1e-10 && close "$(field "$LAST" 9)" "$yl" 1e-10; then
        ok "$name" "checksum=$cs"
    else ko "$name" "$(grep -E 'verificacion|RESULT|TODO|rror' "$LAST" | tail -2)"; fi
}
# TODO(1) por separado: la línea "filas por rango" sale en cuanto el reparto está hecho, aunque falten 2–5
check_rows() { # nombre np m esperado
    local name=$1 np=$2 m=$3 want=$4
    run_mpi "$np" ./$S/b_matvec_mpi "$m" 203 3 1
    if [ $rc -eq 0 ] && grep -q "filas por rango: $want\$" "$LAST"; then ok "$name" "filas por rango: $want"
    elif grep -q "filas por rango:" "$LAST"; then ko "$name" "$(grep -o 'filas por rango:.*' "$LAST") (se esperaba $want)"
    elif pending "$LAST"; then pd "$name"
    else ko "$name" "$(tail -2 "$LAST")"; fi
}
if want B; then
    run_seq ./$S/b_matvec_seq 301 203 3 2
    if [ $rc -eq 0 ] && [ -n "$(field "$LAST" 7)" ]; then ok "b_matvec_seq m=301 n=203 iters=3" "checksum=$(field "$LAST" 7)"; else ko "b_matvec_seq"; fi
    check_rows "b_matvec_mpi -np 3 m=301: reparto con residuo (TODO 1)" 3 301 "101 100 100"
    check_rows "b_matvec_mpi -np 4 m=301: reparto con residuo (TODO 1)" 4 301 "76 75 75 75"
    for p in 1 2 3 4; do check_matvec "b_matvec_mpi -np $p m=301 n=203 (filas 301 % $p) == secuencial" $p 301 203 3; done
    check_matvec "b_matvec_mpi -np 4 m=3 n=50: un rango sin filas (cuenta 0)" 4 3 50 2
    if [ "$EXTRA" = 1 ]; then
        check_matvec "EXTRA b_matvec_mpi -np 2 m=1 n=1" 2 1 1 1
        check_matvec "EXTRA b_matvec_mpi -np 5 m=7 n=5 iters=2" 5 7 5 2
        check_matvec "EXTRA b_matvec_mpi -np 4 m=640 n=10 iters=50" 4 640 10 50
    fi
fi

# ---------- Parte C: calor 1D ----------
check_heat() { # nombre np n max_iter tol check_every [flags]
    local name=$1 np=$2 n=$3 mi=$4 tol=$5 ce=$6; shift 6
    run_seq ./$S/c_heat_seq "$n" "$mi" "$tol" "$ce" 1
    local it=$(field "$LAST" 6) cs=$(field "$LAST" 8) uc=$(field "$LAST" 9) uq=$(field "$LAST" 10)
    run_mpi "$np" ./$S/c_heat_mpi "$n" "$mi" "$tol" "$ce" 1 "$@"
    if pending "$LAST"; then pd "$name"; return; fi
    if [ $rc -eq 0 ] && [ "$(field "$LAST" 6)" = "$it" ] && close "$(field "$LAST" 8)" "$cs" 1e-10 \
       && close "$(field "$LAST" 9)" "$uc" 1e-10 && close "$(field "$LAST" 10)" "$uq" 1e-10 \
       && { [ "$(field "$LAST" 12)" = OK ] || [ "$(field "$LAST" 12)" = SIN_VERIFICAR ]; }; then
        ok "$name" "iteraciones=$it checksum=$cs"
    else ko "$name" "$(grep -E 'iteraciones|verificacion|RESULT|TODO|rror' "$LAST" | tail -2)"; fi
}
if want C && want_c heat; then
    run_seq ./$S/c_heat_seq 1003 500 0 1 1
    if [ $rc -eq 0 ] && [ "$(field "$LAST" 6)" = 500 ]; then ok "c_heat_seq n=1003 max_iter=500 (tol=0 -> 500 pasos)" "checksum=$(field "$LAST" 8)"; else ko "c_heat_seq n=1003"; fi
    for p in 1 2 3 4; do
        flag=""; [ $p -ge 3 ] && flag="--verify"
        check_heat "c_heat_mpi -np $p n=1003 pasos fijos == secuencial $flag" $p 1003 500 0 1 $flag
    done
    check_heat "c_heat_mpi -np 3 n=31 tol=1e-6: misma iteracion de paro (Allreduce)" 3 31 100000 1e-6 1 --verify
    check_heat "c_heat_mpi -np 4 n=31 tol=1e-6 check_every=7 --sin-solape" 4 31 100000 1e-6 7 --verify --sin-solape
    check_heat "c_heat_mpi -np 4 n=4: una celda por rango" 4 4 50 0 1 --verify
    run_mpi 4 ./$S/c_heat_mpi 3 50 0 1 1
    if pending "$LAST"; then pd "c_heat_mpi -np 4 n=3 rechaza n < p"
    elif [ $rc -ne 0 ] && grep -q "n >= p" "$LAST"; then ok "c_heat_mpi -np 4 n=3: rechaza n < p con mensaje"
    else ko "c_heat_mpi -np 4 n=3 debia rechazar n < p" "rc=$rc"; fi
    if [ "$EXTRA" = 1 ]; then
        check_heat "EXTRA c_heat_mpi -np 4 n=7 tol=1e-3 (bloques 2 2 2 1)" 4 7 100000 1e-3 1 --verify
        check_heat "EXTRA c_heat_mpi -np 2 n=20000 check_every=50 --verify" 2 20000 200 0 50 --verify
        check_heat "EXTRA c_heat_mpi -np 4 n=1003 --sin-solape" 4 1003 300 0 1 --sin-solape
    fi
elif want C; then
    sk "Parte C calor 1D (PARTE_C=$PARTE_C)"
fi

# ---------- Parte C: primos (alternativa) ----------
check_primes() { # nombre np a b modo
    local name=$1 np=$2 a=$3 b=$4 mode=$5
    run_seq ./$S/c_primes_seq "$a" "$b" 1
    local cnt=$(field "$LAST" 6)
    run_mpi "$np" ./$S/c_primes_mpi "$a" "$b" "$mode" 1
    if pending "$LAST"; then pd "$name"; return; fi
    if [ $rc -eq 0 ] && [ "$(field "$LAST" 6)" = "$cnt" ]; then ok "$name" "primos=$cnt"
    else ko "$name" "seq=$cnt $(grep -E 'RESULT|TODO|rror' "$LAST" | tail -1)"; fi
}
if want C && want_c primes; then
    run_seq ./$S/c_primes_seq 2 100000 1
    if [ $rc -eq 0 ] && [ "$(field "$LAST" 6)" = 9592 ]; then ok "c_primes_seq [2,100000] = 9592 primos"; else ko "c_primes_seq [2,100000]" "$(field "$LAST" 6)"; fi
    for p in 1 3 4; do check_primes "c_primes_mpi -np $p [2,100000] ciclico == secuencial" $p 2 100000 ciclico; done
    check_primes "c_primes_mpi -np 4 [2,100000] bloques == secuencial" 4 2 100000 bloques
    check_primes "c_primes_mpi -np 4 [1,1] (sin primos)" 4 1 1 ciclico
    if [ "$EXTRA" = 1 ]; then
        check_primes "EXTRA c_primes_mpi -np 4 [2,2] = 1" 4 2 2 ciclico
        check_primes "EXTRA c_primes_mpi -np 4 [0,10] = 4" 4 0 10 bloques
        check_primes "EXTRA c_primes_mpi -np 3 [999900,1000100] ciclico" 3 999900 1000100 ciclico
    fi
elif want C; then
    sk "Parte C primos (PARTE_C=$PARTE_C)"
fi

# ---------- Parte D ----------
if want D; then
    run_mpi 2 ./$S/d_pingpong 0.05
    if [ $rc -eq 0 ] && awk -F, '/^RESULT,d_pingpong/ { exit !($4 > 0 && $6 > 0) }' "$LAST"; then
        ok "d_pingpong -np 2 (factor 0.05): alpha y beta medidos" "$(grep '^RESULT' "$LAST")"
    else ko "d_pingpong" "$(tail -2 "$LAST")"; fi
    rm -rf "$OUT/esc"; esc_ok=0
    # p sobre-suscrito = 2 x núcleos físicos (como escalado.sh): en 4 núcleos, 8
    cores=$(lscpu -p=CORE,SOCKET 2>/dev/null | grep -v '^#' | sort -u | wc -l); [ "${cores:-0}" -ge 1 ] || cores=$(nproc)
    OV=$((2 * cores))
    if PROG=heat N=20000 ITERS=50 NLOCAL=5000 PROCS="2" OVERSUB=$OV OUT="$OUT/esc" PLOT=1 MPIRUN_FLAGS="$MPIRUN_FLAGS" \
       timeout -k 2 "$TO" ./escalado.sh > "$OUT/escalado.log" 2>&1; then
        hdr="config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia"
        if [ "$(head -1 "$OUT/esc/fuerte.csv")" = "$hdr" ] && [ "$(head -1 "$OUT/esc/debil.csv")" = "$hdr" ] \
           && [ "$(tail -n +2 "$OUT/esc/fuerte.csv" | wc -l)" = 3 ] && [ "$(tail -n +2 "$OUT/esc/debil.csv" | wc -l)" = 3 ] \
           && awk -F, 'NF != 11 { bad = 1 } END { exit bad }' "$OUT/esc/fuerte.csv" "$OUT/esc/debil.csv" \
           && grep -q "^mpi_oversub,$OV,20000," "$OUT/esc/fuerte.csv" && grep -q '^mpi,2,20000,' "$OUT/esc/fuerte.csv" \
           && grep -q '^mpi,2,10000,' "$OUT/esc/debil.csv" && grep -q '^seq,1,5000,' "$OUT/esc/debil.csv" \
           && [ -s "$OUT/esc/fuerte.png" ] && [ -s "$OUT/esc/debil.png" ] && grep -q nucleos_fisicos "$OUT/esc/entorno.txt"; then
            ok "escalado.sh (pequeno): CSV del protocolo, oversub etiquetado, PNG, entorno.txt"; esc_ok=1
        else ko "escalado.sh: formato de salida" "ver $OUT/esc y $OUT/escalado.log"; fi
    elif grep -q "TODO pendiente" "$OUT/escalado.log"; then pd "escalado.sh (necesita c_heat_mpi completo)"
    else ko "escalado.sh termina sin error" "$(tail -3 "$OUT/escalado.log")"; fi
    if [ "$esc_ok" = 1 ] && python3 graficar.py "$OUT/esc/fuerte.csv" "$OUT/esc/debil.csv" "$OUT/esc" --modelo 0.4 5 1 > "$OUT/graficar.log" 2>&1 \
       && grep -q "modelo (fuerte): p=1: 1.00, p=2:" "$OUT/graficar.log" && grep -q '^| mpi | 2 |' "$OUT/graficar.log"; then
        ok "graficar.py --modelo: PNG + tabla Markdown + prediccion"
    elif [ "$esc_ok" != 1 ]; then sk "graficar.py (necesita el CSV completo de escalado.sh)"
    else ko "graficar.py" "$(tail -2 "$OUT/graficar.log")"; fi
    # alpha=1us, beta=1GB/s, bytes=8, sin Allreduce: T_com = 2*(1+0.008) us = 2.016 us; tc=1ns, p=4:
    # n* = 2.016e-6/(1e-9*0.75) = 2688 ; n_E(0.5) = 0.5*4*2.016e-6/(1e-9*0.5) = 8064 ; S(8064) = 2.00
    out=$(python3 modelo.py --alpha-us 1 --beta-gbps 1 --tc-ns 1 --p 4 --check-every 0 --n 8064)
    if echo "$out" | grep -q "S = 1): 2,688 celdas" && echo "$out" | grep -q "50%):      8,064 celdas" && echo "$out" | grep -q "S = 2.00, E = 50%"; then
        ok "modelo.py: n*, n_E y prediccion con valores conocidos"
    else ko "modelo.py" "$out"; fi
fi

rm -f "$OUT"/last_*.txt
echo "---- $pass PASS, $fail FAIL, $pend PEND, $skip SKIP"
[ "$pend" -gt 0 ] && echo "     PEND = programa con TODO pendiente; make test-b / test-c / test-entrega lo cuentan como FAIL"
[ "$fail" -eq 0 ]
