#!/usr/bin/env bash
# Pruebas de la práctica guiada S01 · Unidad IV · Modelo SPMD
# Uso: make test   (o ./tests/run_tests.sh desde practica-guiada/)
# Compara cada programa distribuido contra referencia_secuencial con tolerancia.
# Termina con código 0 solo si no hay ningún FAIL. Los SKIP no cuentan como fallo.
set -u
cd "$(dirname "$0")/.." || exit 1

# Open MPI se niega a correr como root salvo con estas variables (contenedores, VM de autoría).
if [ "$(id -u)" -eq 0 ]; then
    export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
fi
MPIRUN=${MPIRUN:-mpirun}
MPIRUN_FLAGS=${MPIRUN_FLAGS:---oversubscribe}
TOL=1e-6          # tolerancia relativa: el orden de las sumas en punto flotante cambia el redondeo
N_BIG=1000003     # primo: n % p != 0 para p = 2, 3, 4
pass=0; fail=0; skip=0

ok()   { pass=$((pass + 1)); echo "PASS  $*"; }
bad()  { fail=$((fail + 1)); echo "FAIL  $*"; }
skp()  { skip=$((skip + 1)); echo "SKIP  $*"; }

# close A B -> éxito si |A - B| <= TOL * max(1, |B|)
close() {
    awk -v a="$1" -v b="$2" -v t="$TOL" 'BEGIN {
        d = a - b; if (d < 0) d = -d; m = b; if (m < 0) m = -m; if (m < 1) m = 1;
        exit !(d <= t * m) }'
}
# run_mpi NP PROG ARGS... -> stdout+stderr, con límite de tiempo
run_mpi() { local np=$1; shift; timeout 60 "$MPIRUN" $MPIRUN_FLAGS -np "$np" "$@" 2>&1; }
# field "clave" TEXTO -> número después de "clave = "
field() { printf '%s\n' "$2" | sed -n "s/^$1 = \([-0-9.]*\).*/\1/p" | head -n 1; }

# 0. Compilación (make test ya compiló; esto cubre la ejecución directa del script)
if ! make -s all >/dev/null 2>&1; then
    bad "compilacion: 'make all' fallo"; echo "Resumen: $pass PASS, $fail FAIL, $skip SKIP"; exit 1
fi
for b in hello_rank suma_distribuida suma_distribuida_buggy referencia_secuencial; do
    [ -x "$b" ] || { bad "no existe el ejecutable $b"; }
done
[ "$fail" -eq 0 ] || { echo "Resumen: $pass PASS, $fail FAIL, $skip SKIP"; exit 1; }

# 1. hello_rank: con -np 4 salen 10 líneas: 4 "Hola", 4 "counter", 1 del rango 0 y 1 del último
out=$(run_mpi 4 ./hello_rank)
holas=$(printf '%s\n' "$out" | grep -c "^Hola desde el proceso")
[ "$holas" -eq 4 ] && ok "hello_rank -np 4: 4 lineas 'Hola'" || bad "hello_rank -np 4: $holas lineas 'Hola' (esperaba 4)"
for r in 0 1 2 3; do
    c=$(printf '%s\n' "$out" | grep -c "^Hola desde el proceso $r de 4 ")
    [ "$c" -eq 1 ] || bad "hello_rank: el rango $r imprimio 'Hola' $c veces (esperaba 1)"
done
# La memoria NO es compartida: cada rango ve su propio counter = rango + 1
if printf '%s\n' "$out" | grep -q "^\[rango 3\] counter = 4$" && printf '%s\n' "$out" | grep -q "^\[rango 0\] counter = 1$"; then
    ok "hello_rank: counter es privado de cada proceso (rango 3 -> 4, rango 0 -> 1)"
else
    bad "hello_rank: counter no muestra copias privadas por proceso"
fi
total_lines=$(printf '%s\n' "$out" | grep -c "^\(Hola\|\[rango\)")
[ "$total_lines" -eq 10 ] && ok "hello_rank -np 4: 10 lineas en total" || bad "hello_rank -np 4: $total_lines lineas (esperaba 10)"
out1=$(run_mpi 1 ./hello_rank)
l1=$(printf '%s\n' "$out1" | grep -c "^\(Hola\|\[rango\)")
[ "$l1" -eq 4 ] && ok "hello_rank -np 1: 4 lineas (el rango 0 tambien es el ultimo)" || bad "hello_rank -np 1: $l1 lineas (esperaba 4)"

# 2. suma_distribuida por bloques vs. referencia secuencial
for n in 10 "$N_BIG"; do
    ref=$(./referencia_secuencial "$n"); ref_sum=$(field suma "$ref")
    for np in 1 2 3 4; do
        out=$(run_mpi "$np" ./suma_distribuida "$n" bloques); got=$(field "suma total" "$out")
        if [ -n "$got" ] && close "$got" "$ref_sum"; then
            ok "suma_distribuida bloques n=$n -np $np: $got == $ref_sum"
        else
            bad "suma_distribuida bloques n=$n -np $np: '$got' != $ref_sum"
        fi
    done
done
# Reparto con residuo: n=10, p=4 -> rangos 0,1 toman 3 elementos; 2,3 toman 2; el rango 2 toma {6, 7}
out=$(run_mpi 4 ./suma_distribuida 10 bloques)
if printf '%s\n' "$out" | grep -q "^\[rango 2\] bloques: 2 elementos {6, 7}"; then
    ok "suma_distribuida bloques n=10 -np 4: el rango 2 toma {6, 7}"
else
    bad "suma_distribuida bloques n=10 -np 4: el rango 2 no toma {6, 7}"
fi

# 3. Reparto cíclico (TODO(1) de la fase Modificar): se prueba solo si ya se completó
out=$(run_mpi 4 ./suma_distribuida 10 ciclico)
if printf '%s\n' "$out" | grep -q "TODO pendiente"; then
    skp "suma_distribuida ciclico: TODO(1) pendiente (fase Modificar de PRIMM)"
else
    if printf '%s\n' "$out" | grep -q "^\[rango 2\] ciclico: 2 elementos {2, 6}"; then
        ok "suma_distribuida ciclico n=10 -np 4: el rango 2 toma {2, 6}"
    else
        bad "suma_distribuida ciclico n=10 -np 4: el rango 2 no toma {2, 6}"
    fi
    for n in 10 "$N_BIG"; do
        ref=$(./referencia_secuencial "$n"); ref_sum=$(field suma "$ref")
        for np in 1 2 3 4; do
            out=$(run_mpi "$np" ./suma_distribuida "$n" ciclico); got=$(field "suma total" "$out")
            if [ -n "$got" ] && close "$got" "$ref_sum"; then
                ok "suma_distribuida ciclico n=$n -np $np: $got == $ref_sum"
            else
                bad "suma_distribuida ciclico n=$n -np $np: '$got' != $ref_sum"
            fi
        done
    done
fi

# 4. Variante que falla: el síntoma esperado es una suma INCORRECTA cuando n % p != 0.
#    Se corre con 'timeout 10' por ser *_buggy (si se colgara, el cuelgue también sería síntoma).
ref_sum=$(field suma "$(./referencia_secuencial 10)")
out=$(timeout 10 "$MPIRUN" $MPIRUN_FLAGS -np 4 ./suma_distribuida_buggy 10 2>&1); rc=$?
got=$(field "suma total" "$out")
if [ "$rc" -eq 124 ]; then
    bad "suma_distribuida_buggy -np 4: se colgo (no es el sintoma esperado de esta variante)"
elif [ -n "$got" ] && ! close "$got" "$ref_sum"; then
    ok "suma_distribuida_buggy n=10 -np 4: suma incorrecta $got != $ref_sum (sintoma esperado: pierde n % p = 2 elementos)"
else
    bad "suma_distribuida_buggy n=10 -np 4: dio '$got'; el error didactico desaparecio"
fi
out=$(timeout 10 "$MPIRUN" $MPIRUN_FLAGS -np 5 ./suma_distribuida_buggy 10 2>&1); got=$(field "suma total" "$out")
if [ -n "$got" ] && close "$got" "$ref_sum"; then
    ok "suma_distribuida_buggy n=10 -np 5: correcta por casualidad (n % p = 0); 'salio bien una vez' no es evidencia"
else
    bad "suma_distribuida_buggy n=10 -np 5: esperaba la suma correcta porque 10 % 5 = 0"
fi

# 5. Fase Crear: promedio_maximo.c (opcional). Debe imprimir desde el rango 0
#    "promedio = X" y "maximo = Y" con el mismo formato que referencia_secuencial.
if [ -x promedio_maximo ]; then
    for n in 10 "$N_BIG"; do
        ref=$(./referencia_secuencial "$n"); ref_avg=$(field promedio "$ref"); ref_max=$(field maximo "$ref")
        for np in 1 2 3 4; do
            out=$(run_mpi "$np" ./promedio_maximo "$n"); avg=$(field promedio "$out"); mx=$(field maximo "$out")
            if [ -n "$avg" ] && [ -n "$mx" ] && close "$avg" "$ref_avg" && close "$mx" "$ref_max"; then
                ok "promedio_maximo n=$n -np $np: promedio $avg, maximo $mx"
            else
                bad "promedio_maximo n=$n -np $np: promedio '$avg' (ref $ref_avg), maximo '$mx' (ref $ref_max)"
            fi
        done
    done
else
    skp "promedio_maximo: no existe promedio_maximo.c (fase Crear de PRIMM)"
fi

echo "Resumen: $pass PASS, $fail FAIL, $skip SKIP"
[ "$fail" -eq 0 ]
