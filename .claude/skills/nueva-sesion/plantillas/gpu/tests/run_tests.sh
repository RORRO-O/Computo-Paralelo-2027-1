#!/usr/bin/env bash
# tests/run_tests.sh — Práctica guiada de GPU: el espejo Numba (simulador CUDASIM) contra la referencia en CPU.
# Lo generó /nueva-sesion. Código 0 solo si todo pasa. Agrega tus casos al final (busca "Casos propios").
set -uo pipefail
export LC_ALL=C
cd "$(dirname "$0")/.." || exit 1
PY=${PY:-python3}
TOL=${TOL:-1e-6}
PASS=0
FAIL=0
pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1${2:+ — $2}"; FAIL=$((FAIL + 1)); }
valor_de() { awk -F= -v k="$1" '$1 == k { v = $2 } END { if (v == "") exit 1; print v }'; }
iguales() { awk -v a="$1" -v b="$2" -v t="$TOL" 'BEGIN { d = a - b; if (d < 0) d = -d; m = a < 0 ? -a : a; if (m < 1) m = 1; exit !(d <= t * m) }'; }

[[ -x ./main_cpu ]] || { fail "existe ./main_cpu" "corre make"; echo "Resultado: $PASS PASS, $FAIL FAIL"; exit 1; }

# n que no es múltiplo del bloque (1000 con 64) y n menor que un bloque (10 con 64): ejercitan la guarda de límites.
for caso in "1000 64" "4096 64" "10 64"; do
    read -r n bloque <<< "$caso"
    ref=$(./main_cpu "$n" | valor_de resultado) || { fail "main_cpu imprime resultado= (n=$n)"; continue; }
    obt=$(NUMBA_ENABLE_CUDASIM=1 "$PY" main_numba.py "$n" "$bloque" 2> /dev/null | valor_de resultado) \
        || { fail "main_numba.py (CUDASIM) imprime resultado= (n=$n, bloque=$bloque)"; continue; }
    if iguales "$ref" "$obt"; then pass "Numba (CUDASIM) == CPU (n=$n, bloque=$bloque, resultado=$ref)"
    else fail "Numba (CUDASIM) == CPU (n=$n, bloque=$bloque)" "esperado $ref, obtenido $obt"; fi
done

if ./main_cpu abc > /dev/null 2>&1; then fail "main_cpu rechaza un tamaño no válido"; else pass "main_cpu rechaza un tamaño no válido"; fi

# ---------- Casos propios de la sesión ----------

echo "Resultado: $PASS PASS, $FAIL FAIL"
[[ $FAIL -eq 0 ]]
