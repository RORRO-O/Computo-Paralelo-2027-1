#!/usr/bin/env bash
# tests/run_tests.sh · Pruebas de sortear_orden.py y calificar_defensa.py
# Uso: bash tests/run_tests.sh   (desde proyecto/defensa/scripts; también lo llama `make test`)
# Imprime PASS/FAIL por caso y termina con código 0 solo si todo pasa.
set -u
cd "$(dirname "$0")/.." || exit 2
PY=${PYTHON:-python3}
SEM=20261210
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
pass=0; fail=0
ok()   { echo "PASS $1"; pass=$((pass+1)); }
bad()  { echo "FAIL $1"; fail=$((fail+1)); }

# 1. El sorteo es determinista: dos corridas con la misma semilla dan el mismo orden.
$PY sortear_orden.py --semilla $SEM --equipos 1-12 --solo-orden > "$TMP/o1.txt"
$PY sortear_orden.py --semilla $SEM --equipos 1-12 --solo-orden > "$TMP/o2.txt"
cmp -s "$TMP/o1.txt" "$TMP/o2.txt" && ok "1 sorteo determinista" || bad "1 sorteo determinista"

# 2. Salen los 12 equipos, cada uno una vez.
[ "$(sort -u "$TMP/o1.txt" | wc -l)" -eq 12 ] && [ "$(wc -l < "$TMP/o1.txt")" -eq 12 ] \
    && ok "2 doce equipos sin repetir" || bad "2 doce equipos sin repetir"

# 3. Verificación independiente con sha256sum: mismo orden que el script.
: > "$TMP/hash.txt"
for n in $(seq 1 12); do
    nn=$(printf '%02d' "$n")
    h=$(printf '%s' "$SEM-equipo$nn" | sha256sum | cut -c1-64)
    echo "$h $nn" >> "$TMP/hash.txt"
done
sort "$TMP/hash.txt" | awk '{print $2}' > "$TMP/o_sha.txt"
cmp -s "$TMP/o1.txt" "$TMP/o_sha.txt" && ok "3 orden coincide con sha256sum" || bad "3 orden coincide con sha256sum"

# 4. Otra semilla da otro orden (con probabilidad abrumadora).
$PY sortear_orden.py --semilla 20261214 --equipos 1-12 --solo-orden > "$TMP/o3.txt"
cmp -s "$TMP/o1.txt" "$TMP/o3.txt" && bad "4 otra semilla cambia el orden" || ok "4 otra semilla cambia el orden"

# 5. Temas de la pregunta 2: tres temas distintos por equipo de 3.
$PY sortear_orden.py --semilla $SEM --equipos 1-12 --solo-temas > "$TMP/t.txt"
malos=$(awk '{ if ($2==$3 || $2==$4 || $3==$4) c++ } END { print c+0 }' "$TMP/t.txt")
[ "$malos" -eq 0 ] && [ "$(wc -l < "$TMP/t.txt")" -eq 12 ] && ok "5 temas distintos por equipo" || bad "5 temas distintos por equipo"

# 6. Formato completo con dos sesiones de 90 min: no caben 12 equipos → código 3 y aviso.
$PY sortear_orden.py --semilla $SEM --equipos ejemplo/equipos.csv --formato completo \
    --sesiones "2026-12-10 10:30 90" "2026-12-14 10:30 90" > "$TMP/c2.md"; rc=$?
[ $rc -eq 3 ] && grep -q "SIN HORARIO" "$TMP/c2.md" && ok "6 completo en 2 sesiones: sobrecupo detectado (rc=3)" \
    || bad "6 completo en 2 sesiones: sobrecupo detectado (rc=$rc)"

# 7. Formato completo con tres sesiones: caben los 12 (4 por sesión) → código 0.
$PY sortear_orden.py --semilla $SEM --equipos ejemplo/equipos.csv --formato completo > "$TMP/c3.md"; rc=$?
[ $rc -eq 0 ] && ! grep -q "SIN HORARIO" "$TMP/c3.md" && ok "7 completo en 3 sesiones: caben (rc=0)" \
    || bad "7 completo en 3 sesiones: caben (rc=$rc)"

# 8. Formato corto con dos sesiones y tope de 6 por sesión: caben, 6 y 6.
$PY sortear_orden.py --semilla $SEM --equipos ejemplo/equipos.csv --formato corto \
    --sesiones "2026-12-10 10:30 90" "2026-12-14 10:30 90" --max-por-sesion 6 > "$TMP/b.md"; rc=$?
n10=$(grep -c "| jueves 10 de diciembre de 2026 | " "$TMP/b.md")
n14=$(grep -c "| lunes 14 de diciembre de 2026 | " "$TMP/b.md")
[ $rc -eq 0 ] && [ "$n10" -eq 6 ] && [ "$n14" -eq 6 ] && ok "8 corto 6+6 (rc=0)" || bad "8 corto 6+6 (rc=$rc, $n10/$n14)"

# 9. Formato mixto en una sola sesión de 90 min: caben los 12.
$PY sortear_orden.py --semilla $SEM --equipos ejemplo/equipos.csv --formato mixto \
    --sesiones "2026-12-10 10:30 90" > "$TMP/m.md"; rc=$?
[ $rc -eq 0 ] && ok "9 mixto en 1 sesión: caben (rc=0)" || bad "9 mixto en 1 sesión: caben (rc=$rc)"

# 10. Calificación: valores calculados a mano (rubrica-defensa.md §2–§4).
$PY calificar_defensa.py ejemplo/registro-defensa.csv --salida "$TMP/cal.csv" > "$TMP/cal.md" 2>/dev/null; rc=$?
[ $rc -eq 0 ] && ok "10 calificar_defensa corre (rc=0)" || bad "10 calificar_defensa corre (rc=$rc)"
chk() { grep -q "^$1" "$TMP/cal.csv" && ok "11 $2" || bad "11 $2 (esperado: $1)"; }
chk "07,usuario-a,30.00,100.00,15.00,1.00,88.00,88.00,88.00,no,88.00"   "todo Ejemplar → 15.00 y 88.00"
chk "07,usuario-b,15.00,85.00,12.75,1.00,85.75,85.75,88.00,no,85.75"    "P1=I rescatada con C → factor 1.00"
chk "07,usuario-c,6.00,76.00,11.40,0.80,81.20,64.96,88.00,sí,68.00"     "P1=I y rescate I → 0.80 y tope −20 aplicado"
chk "03,usuario-e,11.25,61.00,9.15,0.90,73.15,65.84,74.50,no,65.84"     "P1=I rescatada con D → 0.90"
chk "03,usuario-f,0.00,49.75,7.46,1.00,71.46,71.46,74.50,no,71.46"      "ausente → D4 = 0, sin factor"
chk "11,usuario-h,16.50,81.50,12.23,1.00,,,,n/a,"                        "opción c sin rescate → D4 = 30·f(P1)"

# 12. Nivel inválido → código 1 con mensaje.
printf 'equipo,integrante,D1,D2,D3,P1,P2\n01,x,E,E,E,Z,E\n' > "$TMP/malo.csv"
$PY calificar_defensa.py "$TMP/malo.csv" > /dev/null 2> "$TMP/err.txt"; rc=$?
[ $rc -eq 1 ] && grep -q "nivel inválido" "$TMP/err.txt" && ok "12 nivel inválido → rc=1" || bad "12 nivel inválido → rc=$rc"

# 13. P1 = I sin pregunta de rescate → código 1.
printf 'equipo,integrante,D1,D2,D3,P1,P2\n01,x,E,E,E,I,-\n' > "$TMP/malo2.csv"
$PY calificar_defensa.py "$TMP/malo2.csv" > /dev/null 2> "$TMP/err2.txt"; rc=$?
[ $rc -eq 1 ] && grep -q "rescate" "$TMP/err2.txt" && ok "13 P1=I sin rescate → rc=1" || bad "13 P1=I sin rescate → rc=$rc"

echo "== $pass PASS · $fail FAIL =="
[ $fail -eq 0 ]
