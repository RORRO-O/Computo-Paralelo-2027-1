#!/usr/bin/env bash
# tests/run_tests.sh · Pruebas de sortear_orden.py y calificar_defensa.py
# Uso: bash tests/run_tests.sh   (desde proyecto/defensa/scripts; también lo llama `make test`)
# Imprime PASS/FAIL por caso y termina con código 0 solo si todo pasa. No deja archivos: trabaja en un mktemp.
set -u
cd "$(dirname "$0")/.." || exit 2
export PYTHONDONTWRITEBYTECODE=1
PY=${PYTHON:-python3}
SEM=20261210
LOG=../logistica-defensa.md
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
pass=0; fail=0
ok()   { echo "PASS $1"; pass=$((pass+1)); }
bad()  { echo "FAIL $1"; fail=$((fail+1)); }

# ---------- sortear_orden.py ----------

# 1. El sorteo es determinista: dos corridas con la misma semilla dan el mismo orden.
$PY sortear_orden.py --semilla $SEM --equipos 1-12 --solo-orden > "$TMP/o1.txt"
$PY sortear_orden.py --semilla $SEM --equipos 1-12 --solo-orden > "$TMP/o2.txt"
cmp -s "$TMP/o1.txt" "$TMP/o2.txt" && ok "1 sorteo determinista" || bad "1 sorteo determinista"

# 2. Salen los 12 equipos, cada uno una vez.
[ "$(sort -u "$TMP/o1.txt" | wc -l)" -eq 12 ] && [ "$(wc -l < "$TMP/o1.txt")" -eq 12 ] \
    && ok "2 doce equipos sin repetir" || bad "2 doce equipos sin repetir"

# 3. Verificación independiente con sha256sum: mismo orden que el script (logistica-defensa.md §4).
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

# 7. Formato completo con las tres sesiones por defecto (jue 10, lun 14, mar 15): caben los 12, 4 + 4 + 4.
$PY sortear_orden.py --semilla $SEM --equipos ejemplo/equipos.csv --formato completo > "$TMP/c3.md"; rc=$?
a10=$(grep -c "| jueves 10 de diciembre de 2026 | " "$TMP/c3.md")
a14=$(grep -c "| lunes 14 de diciembre de 2026 | " "$TMP/c3.md")
a15=$(grep -c "| martes 15 de diciembre de 2026 | " "$TMP/c3.md")
[ $rc -eq 0 ] && ! grep -q "SIN HORARIO" "$TMP/c3.md" && [ "$a10$a14$a15" = "444" ] \
    && ok "7 completo en 3 sesiones: 4+4+4 (rc=0)" || bad "7 completo en 3 sesiones (rc=$rc, $a10/$a14/$a15)"

# 8. Formato corto con dos sesiones y tope de 6 por sesión: caben, 6 y 6.
$PY sortear_orden.py --semilla $SEM --equipos ejemplo/equipos.csv --formato corto \
    --sesiones "2026-12-10 10:30 90" "2026-12-14 10:30 90" --max-por-sesion 6 > "$TMP/b.md"; rc=$?
n10=$(grep -c "| jueves 10 de diciembre de 2026 | " "$TMP/b.md")
n14=$(grep -c "| lunes 14 de diciembre de 2026 | " "$TMP/b.md")
[ $rc -eq 0 ] && [ "$n10" -eq 6 ] && [ "$n14" -eq 6 ] && ok "8 corto 6+6 (rc=0)" || bad "8 corto 6+6 (rc=$rc, $n10/$n14)"

# 9. Formato mixto en una sola sesión de 90 min: caben los 12 con 77 min usados (logistica-defensa.md §2).
$PY sortear_orden.py --semilla $SEM --equipos ejemplo/equipos.csv --formato mixto \
    --sesiones "2026-12-10 10:30 90" > "$TMP/m.md"; rc=$?
[ $rc -eq 0 ] && grep -q "| 12 (.*) | 77.0 | 3.0 |" "$TMP/m.md" && ok "9 mixto en 1 sesión: 77 min (rc=0)" \
    || bad "9 mixto en 1 sesión (rc=$rc)"

# 10. La tabla de ejemplo de logistica-defensa.md §4 es la salida literal del script (formato corto 6 + 6),
#     y el prefijo de la verificación a mano de equipo07 coincide con sha256sum.
grep "^| [0-9]* | cp-6bm1-equipo" "$TMP/b.md" > "$TMP/tabla_script.txt"
grep "^| [0-9]* | cp-6bm1-equipo" "$LOG" > "$TMP/tabla_doc.txt"
h07=$(printf '%s' "$SEM-equipo07" | sha256sum | cut -c1-12)
[ "$(wc -l < "$TMP/tabla_doc.txt")" -eq 12 ] && cmp -s "$TMP/tabla_script.txt" "$TMP/tabla_doc.txt" \
    && grep -q "sha256sum *# → $h07" "$LOG" \
    && ok "10 tabla y hash de logistica-defensa.md §4 = salida real" || bad "10 tabla o hash de logistica-defensa.md §4"

# 11. Argumentos inválidos → código 2 con mensaje, sin traza de Python.
arg_bad=0
for args in "--equipos abc" "--equipos 1,1" "--equipos 0-3" "--equipos no-existe.csv" \
            "--equipos 1-3 --integrantes 4" "--equipos 1-3 --max-por-sesion 0"; do
    # shellcheck disable=SC2086
    $PY sortear_orden.py --semilla $SEM $args > /dev/null 2> "$TMP/e.txt"; rc=$?
    { [ $rc -eq 2 ] && ! grep -q Traceback "$TMP/e.txt"; } || { arg_bad=1; echo "   ($args → rc=$rc)"; }
done
$PY sortear_orden.py --semilla $SEM --equipos 1-3 --sesiones "2026-13-10 10:30 90" > /dev/null 2> "$TMP/e.txt"; rc=$?
{ [ $rc -eq 2 ] && ! grep -q Traceback "$TMP/e.txt"; } || { arg_bad=1; echo "   (fecha inválida → rc=$rc)"; }
[ $arg_bad -eq 0 ] && ok "11 argumentos inválidos → rc=2 sin traza" || bad "11 argumentos inválidos"

# ---------- calificar_defensa.py ----------

# 12. Ejemplo: valores calculados a mano (rubrica-defensa.md §2–§4).
$PY calificar_defensa.py ejemplo/registro-defensa.csv --salida "$TMP/cal.csv" > "$TMP/cal.md" 2>/dev/null; rc=$?
[ $rc -eq 0 ] && ok "12 calificar_defensa corre (rc=0)" || bad "12 calificar_defensa corre (rc=$rc)"
cab="equipo,integrante,D4_rubrica,rubrica_100,defensa_15,insuficientes,factor,c6_insuficiente,suma_100,proyecto_ajustado,referencia_equipo,tope_aplicado,proyecto_final"
[ "$(head -1 "$TMP/cal.csv" | tr -d '\r')" = "$cab" ] && ok "13 encabezado del CSV de salida" || bad "13 encabezado del CSV de salida"
chk() { grep -qx "$1" <(tr -d '\r' < "$TMP/cal.csv") && ok "14 $2" || bad "14 $2 (esperado: $1)"; }
chk "07,usuario-a,30.00,100.00,15.00,0,1.00,no,88.00,88.00,88.00,no,88.00"   "todo Ejemplar → 15.00 y 88.00"
chk "07,usuario-b,15.00,85.00,12.75,1,0.90,no,85.75,77.18,88.00,no,77.18"    "P1=I, rescate C → una Insuficiente: 0.90; C6 no"
chk "07,usuario-c,6.00,76.00,11.40,2,0.80,sí,81.20,64.96,88.00,sí,68.00"     "P1=I y rescate I → 0.80, C6 sí y tope −20"
chk "03,usuario-d,20.25,70.00,10.50,0,1.00,no,74.50,74.50,74.50,no,74.50"    "C y D → sin ajuste"
chk "03,usuario-e,11.25,61.00,9.15,1,0.90,no,73.15,65.84,74.50,no,65.84"     "P1=I, rescate D → 0.90"
chk "03,usuario-f,0.00,49.75,7.46,0,1.00,no,71.46,71.46,74.50,no,71.46"      "ausente → D4 = 0, sin factor"
chk "11,usuario-h,16.50,81.50,12.23,0,1.00,no,,,,n/a,"                        "opción c sin rescate → D4 = 30·f(P1)"

# 15. P1 bien y P2 Insuficiente también cuenta (−10 %): las dos respuestas cuentan para §4.1.
printf 'equipo,integrante,D1,D2,D3,P1,P2,h2,repo,reporte\n01,x,E,E,E,E,I,15,40,30\n' > "$TMP/p2i.csv"
$PY calificar_defensa.py "$TMP/p2i.csv" --salida "$TMP/p2i_out.csv" --sin-tabla 2>/dev/null
grep -qx "01,x,18.00,88.00,13.20,1,0.90,no,98.20,88.38,98.20,no,88.38" <(tr -d '\r' < "$TMP/p2i_out.csv") \
    && ok "15 P1=E y P2=I → factor 0.90" || bad "15 P1=E y P2=I → factor 0.90"

# 16. Entradas inválidas → código 1 con mensaje, sin traza.
inval() {  # inval "descripción" "contenido del CSV" "texto esperado en el mensaje"
    printf '%b' "$2" > "$TMP/malo.csv"
    $PY calificar_defensa.py "$TMP/malo.csv" > /dev/null 2> "$TMP/err.txt"; rc=$?
    [ $rc -eq 1 ] && grep -q "$3" "$TMP/err.txt" && ! grep -q Traceback "$TMP/err.txt" \
        && ok "16 $1 → rc=1" || bad "16 $1 → rc=$rc"
}
H='equipo,integrante,D1,D2,D3,P1,P2,h2,repo,reporte\n'
inval "nivel inválido"                  "${H}01,x,E,E,E,Z,E,,,\n"              "nivel inválido"
inval "P1=I sin rescate"                "${H}01,x,E,E,E,I,-,,,\n"              "rescate"
inval "A en P2 sin ausencia"            "${H}01,x,E,E,E,E,A,,,\n"              "ausencia"
inval "P1 ausente con P2 respondida"    "${H}01,x,E,E,E,A,E,,,\n"              "ausente"
inval "D1–D3 distintos en un equipo"    "${H}01,x,E,E,E,E,E,,,\n01,y,C,E,E,E,E,,,\n" "deben ser iguales"
inval "puntos fuera de rango"           "${H}01,x,E,E,E,E,E,16,40,30\n"        "fuera de rango"
inval "faltan columnas"                 'equipo,integrante,D1\n01,x,E\n'       "columnas"
$PY calificar_defensa.py "$TMP/no-existe.csv" > /dev/null 2> "$TMP/err.txt"; rc=$?
[ $rc -eq 1 ] && grep -q "no existe" "$TMP/err.txt" && ok "16 archivo inexistente → rc=1" || bad "16 archivo inexistente → rc=$rc"
inval "integrante repetido en un equipo" "${H}01,x,E,E,E,E,E,,,\n1,x,E,E,E,C,C,,,\n" "ya aparece"
inval "integrante vacío"                "${H}01,,E,E,E,E,E,,,\n"               "integrante"

# 17. CSV exportado desde una hoja de cálculo: marca BOM y "7" en lugar de "07" → mismo resultado que el ejemplo.
{ printf '\xef\xbb\xbf'; sed 's/^07,/7,/' ejemplo/registro-defensa.csv; } > "$TMP/bom.csv"
$PY calificar_defensa.py "$TMP/bom.csv" --salida "$TMP/bom_out.csv" --sin-tabla 2>/dev/null; rc=$?
[ $rc -eq 0 ] && cmp -s "$TMP/cal.csv" "$TMP/bom_out.csv" \
    && ok "17 CSV con BOM y equipo sin cero inicial = ejemplo" || bad "17 CSV con BOM y equipo sin cero inicial (rc=$rc)"
{ printf '\xef\xbb\xbf'; cat ejemplo/equipos.csv; } > "$TMP/eq_bom.csv"
$PY sortear_orden.py --semilla $SEM --equipos "$TMP/eq_bom.csv" --solo-orden > "$TMP/o_bom.txt" 2>/dev/null; rc=$?
[ $rc -eq 0 ] && cmp -s "$TMP/o1.txt" "$TMP/o_bom.txt" \
    && ok "17 equipos.csv con BOM = mismo orden" || bad "17 equipos.csv con BOM (rc=$rc)"

echo "== $pass PASS · $fail FAIL =="
[ $fail -eq 0 ]
