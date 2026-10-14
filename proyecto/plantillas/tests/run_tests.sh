#!/usr/bin/env bash
# run_tests.sh — Prueba de humo de las plantillas del proyecto. Código 0 solo si todo pasa.
# Verifica: (1) el esqueleto calcula pi con error < 1e-6 e imprime TIEMPO_S; (2) run_all.sh crea el CSV
# con V1 (speedup 1.000) y agrega V2 con 1, 2 y 4 hilos; (3) run_all.sh rechaza un programa sin TIEMPO_S;
# (4) una V3 simulada produce las filas V3 y V3-kernel, también con formato clave=valor; (5) graficar_proyecto.py
# genera tabla y PNG.
# Uso: ./tests/run_tests.sh   (o `make test` desde proyecto/plantillas/)
set -uo pipefail
cd "$(dirname "$0")/.."

PASS=0
FAIL=0
ok()   { echo "PASS: $1"; PASS=$((PASS + 1)); }
bad()  { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }
check() { if eval "$2" > /dev/null 2>&1; then ok "$1"; else bad "$1"; fi; }

N=1000000
OUTDIR=resultados-prueba
CSV=$OUTDIR/mediciones.csv
rm -rf "$OUTDIR"

# 1. Resultado del esqueleto
salida=$(./plantilla_main.out $N)
pi=$(echo "$salida" | awk '$1 == "RESULTADO" { print $2 }')
check "el esqueleto imprime RESULTADO con |pi - 3.141592653589793| < 1e-6" \
    "awk -v p='$pi' 'BEGIN { d = p - 3.141592653589793; if (d < 0) d = -d; exit !(d < 1e-6) }'"
check "el esqueleto imprime TIEMPO_S > 0" \
    "echo '$salida' | awk '\$1 == \"TIEMPO_S\" { t = \$2 } END { exit !(t > 0) }'"
check "el esqueleto rechaza un tamaño no válido (código 2)" \
    "./plantilla_main.out abc; test \$? -eq 2"

# 2. run_all.sh con V1 y V2
check "run_all.sh mide V1 y crea el CSV" \
    "./run_all.sh -e V1 -n $N -t 1 -o $CSV -- ./plantilla_main.out"
check "el CSV tiene el encabezado del protocolo con 5 repeticiones" \
    "test \"\$(head -n 1 $CSV)\" = 'config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia,min_s,max_s'"
check "la fila V1 tiene speedup 1.000 y eficiencia 1.000" \
    "awk -F, 'NR == 2 && \$1 == \"V1\" && \$2 == 1 && \$10 == \"1.000\" && \$11 == \"1.000\" { f = 1 } END { exit !f }' $CSV"
check "run_all.sh agrega V2 con 1, 2 y 4 hilos" \
    "./run_all.sh -e V2 -n $N -t '1 2 4' -o $CSV -- ./plantilla_main.out"
check "las filas V2 tienen speedup numérico (no NA)" \
    "awk -F, '\$1 == \"V2\" { c++; if (\$10 == \"NA\") na = 1 } END { exit !(c == 3 && !na) }' $CSV"
check "el entorno quedó registrado en entorno.txt" \
    "grep -q '^fecha:' $OUTDIR/entorno.txt && grep -q '^compilador:' $OUTDIR/entorno.txt"

# 3. Programa sin TIEMPO_S
check "run_all.sh rechaza un programa que no imprime TIEMPO_S (código 4)" \
    "./run_all.sh -e X -n $N -o $OUTDIR/basura.csv -- /bin/true; test \$? -eq 4"
check "run_all.sh rechaza una llamada sin -e/-n (código 2)" \
    "./run_all.sh -- ./plantilla_main.out; test \$? -eq 2"

# 4. V3 simulada
check "run_all.sh produce filas V3 y V3-kernel con -t gpu" \
    "./run_all.sh -e V3 -n $N -t gpu -o $CSV -- ./tests/falso_gpu.sh && awk -F, '\$1 == \"V3\" && \$2 == \"gpu\" { a = 1 } \$1 == \"V3-kernel\" { b = 1 } END { exit !(a && b) }' $CSV"
check "la fila gpu tiene eficiencia NA y speedup numérico" \
    "awk -F, '\$1 == \"V3\" { exit !(\$11 == \"NA\" && \$10 != \"NA\") }' $CSV"

check "run_all.sh acepta el formato clave=valor (tiempo_total_s=, tiempo_kernel_s=)" \
    "./run_all.sh -e V3kv -n $N -t gpu -o $CSV -- ./tests/falso_gpu_kv.sh && awk -F, '\$1 == \"V3kv\" && \$9 == \"0.012000\" { a = 1 } \$1 == \"V3kv-kernel\" && \$9 == \"0.003000\" { b = 1 } END { exit !(a && b) }' $CSV"

# 5. Gráficas
check "graficar_proyecto.py termina con código 0" \
    "python3 graficar_proyecto.py $CSV --titulo 'Prueba de humo'"
check "se generaron tabla.md, speedup.png, eficiencia.png y comparacion.png" \
    "test -s $OUTDIR/tabla.md && test -s $OUTDIR/speedup.png && test -s $OUTDIR/eficiencia.png && test -s $OUTDIR/comparacion.png"
check "la tabla incluye una fila V2 con 4 hilos y f de Karp–Flatt" \
    "grep -q '^| V2 | 4 |' $OUTDIR/tabla.md"

echo "Resultado: $PASS PASS, $FAIL FAIL"
if [[ $FAIL -eq 0 ]]; then
    rm -rf "$OUTDIR"
    exit 0
fi
echo "Se conserva $OUTDIR/ para revisar."
exit 1
