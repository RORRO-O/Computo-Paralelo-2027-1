#!/usr/bin/env bash
# run_tests.sh — Prueba de las plantillas del proyecto. Imprime PASS/FAIL por caso; código 0 solo si todo pasa.
# Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1
#
# Verifica:
#   (1) el esqueleto: compila sin avisos con y sin OpenMP (-Werror), calcula pi con error < 1e-6, cumple el
#       contrato [n] [semilla] [hilos] con salida clave=valor y rechaza argumentos inválidos con código 2;
#       la variante secuencial (V1) y la OpenMP (V2) dan el mismo checksum con tolerancia relativa 1e-9;
#   (2) run_all.sh (medir_proyecto.sh en el repositorio del equipo): crea el CSV con V1 (speedup 1.000),
#       agrega V2 con 1, 2 y 4 hilos, registra el entorno (núcleos físicos y lógicos, banderas) y rechaza
#       llamadas mal formadas (códigos 2, 3 y 4);
#   (3) una V3 simulada produce las filas V3 y V3-kernel en los dos formatos de salida;
#   (4) graficar_proyecto.py genera tabla y gráficas con el CSV de run_all.sh y con el formato de la entrega
#       final (v1/v2 en minúsculas, sin min_s/max_s).
# Uso: ./tests/run_tests.sh   (o `make test` desde proyecto/plantillas/). Tarda ≈ 3–5 s.
set -uo pipefail
cd "$(dirname "$0")/.."

PASS=0
FAIL=0
ok()   { echo "PASS: $1"; PASS=$((PASS + 1)); }
bad()  { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }
check() { if eval "$2" > /dev/null 2>&1; then ok "$1"; else bad "$1"; fi; }
campo() { printf '%s\n' "$1" | awk -F= -v k="$2" '$1 == k { print $2; exit }'; }

N=1000000
OUTDIR=resultados-prueba
CSV=$OUTDIR/mediciones.csv
rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"

if [[ ! -x ./plantilla_main.out || ! -x ./plantilla_sec.out ]]; then
    echo "FAIL: faltan plantilla_main.out y plantilla_sec.out (ejecuta make)"
    exit 1
fi

# 1. Esqueleto
check "compila sin avisos con OpenMP (-Wall -Wextra -Werror)" \
    "gcc -std=c11 -O2 -Wall -Wextra -Werror -fopenmp plantilla_main.c -o $OUTDIR/omp.out"
check "compila sin avisos sin OpenMP, como V1 (-Wall -Wextra -Werror)" \
    "gcc -std=c11 -O2 -Wall -Wextra -Werror plantilla_main.c -o $OUTDIR/sec.out"

salida=$(./plantilla_main.out $N 7 3)
pi=$(campo "$salida" checksum)
check "checksum= con |pi - 3.141592653589793| < 1e-6" \
    "awk -v p='$pi' 'BEGIN { d = p - 3.141592653589793; if (d < 0) d = -d; exit !(d < 1e-6) }'"
check "tiempo_s= mayor que 0" \
    "awk -v t='$(campo "$salida" tiempo_s)' 'BEGIN { exit !(t > 0) }'"
check "reporta n=, semilla= e hilos= recibidos (n=$N, semilla=7, hilos=3)" \
    "test '$(campo "$salida" n)' = $N && test '$(campo "$salida" semilla)' = 7 && test '$(campo "$salida" hilos)' = 3"
check "sin tercer argumento respeta OMP_NUM_THREADS=2" \
    "test \"\$(OMP_NUM_THREADS=2 ./plantilla_main.out 1000 | awk -F= '\$1 == \"hilos\" { print \$2 }')\" = 2"
check "la variante secuencial reporta hilos=1" \
    "test \"\$(./plantilla_sec.out 1000 1 4 | awk -F= '\$1 == \"hilos\" { print \$2 }')\" = 1"
sec=$(campo "$(./plantilla_sec.out $N)" checksum)
check "V1 (sin OpenMP) y V2 (4 hilos) coinciden con tolerancia relativa 1e-9" \
    "awk -v a='$sec' -v b='$pi' 'BEGIN { d = a - b; if (d < 0) d = -d; exit !(d <= 1e-9 * a) }'"
check "rechaza n no numérico (código 2)" "./plantilla_main.out abc; test \$? -eq 2"
check "rechaza n = 0 (código 2)" "./plantilla_main.out 0; test \$? -eq 2"
check "rechaza hilos = 0 (código 2)" "./plantilla_main.out 100 1 0; test \$? -eq 2"
check "acepta semilla = 0" "./plantilla_main.out 100 0"

# 2. run_all.sh con V1 y V2
check "run_all.sh mide V1 (variante secuencial) y crea el CSV" \
    "./run_all.sh -e V1 -n $N -t 1 -o $CSV -- ./plantilla_sec.out"
check "el CSV tiene el encabezado del protocolo con 5 repeticiones, mín y máx" \
    "test \"\$(head -n 1 $CSV)\" = 'config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia,min_s,max_s'"
check "la fila V1 tiene speedup 1.000 y eficiencia 1.000" \
    "awk -F, 'NR == 2 && \$1 == \"V1\" && \$2 == 1 && \$10 == \"1.000\" && \$11 == \"1.000\" { f = 1 } END { exit !f }' $CSV"
check "la mediana de V1 está entre el mínimo y el máximo" \
    "awk -F, 'NR == 2 { exit !(\$12 <= \$9 && \$9 <= \$13) }' $CSV"
check "run_all.sh agrega V2 con 1, 2 y 4 hilos" \
    "./run_all.sh -e V2 -n $N -t '1 2 4' -o $CSV -- ./plantilla_main.out"
check "las filas V2 tienen speedup numérico (no NA)" \
    "awk -F, '\$1 == \"V2\" { c++; if (\$10 == \"NA\") na = 1 } END { exit !(c == 3 && !na) }' $CSV"
check "el entorno quedó registrado en entorno.txt" \
    "grep -q '^fecha:' $OUTDIR/entorno.txt && grep -q '^compilador:' $OUTDIR/entorno.txt"
check "entorno.txt dice núcleos físicos y lógicos y las banderas del Makefile (-O2)" \
    "grep -qE '^nucleos fisicos: [0-9]+' $OUTDIR/entorno.txt && grep -qE '^nucleos logicos: [0-9]+' $OUTDIR/entorno.txt && grep -qE '^banderas .*-O2' $OUTDIR/entorno.txt"
check "BANDERAS exportada sustituye a las del Makefile en entorno.txt" \
    "BANDERAS='-std=c11 -O2 -fopenmp' ./run_all.sh -e V1 -n 1000 -t 1 -o $OUTDIR/banderas/m.csv -- ./plantilla_sec.out && grep -qx 'banderas: -std=c11 -O2 -fopenmp' $OUTDIR/banderas/entorno.txt"

check "rechaza un programa que no imprime tiempo_s (código 4)" \
    "./run_all.sh -e X -n $N -o $OUTDIR/basura.csv -- /bin/true; test \$? -eq 4"
check "rechaza una llamada sin -e/-n (código 2)" \
    "./run_all.sh -- ./plantilla_main.out; test \$? -eq 2"
printf 'config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia\n' > "$OUTDIR/otro_formato.csv"
check "rechaza agregar filas a un CSV con otro encabezado (código 3)" \
    "./run_all.sh -e V2 -n $N -t 1 -o $OUTDIR/otro_formato.csv -- ./plantilla_main.out; test \$? -eq 3"
check "-h muestra la ayuda y termina con código 0" "./run_all.sh -h | grep -q 'medir_proyecto.sh'"

# 3. V3 simulada
check "run_all.sh produce filas V3 y V3-kernel con -t gpu (formato TIEMPO_S)" \
    "./run_all.sh -e V3 -n $N -t gpu -o $CSV -- ./tests/falso_gpu.sh && awk -F, '\$1 == \"V3\" && \$2 == \"gpu\" { a = 1 } \$1 == \"V3-kernel\" { b = 1 } END { exit !(a && b) }' $CSV"
check "la fila gpu tiene eficiencia NA y speedup numérico" \
    "awk -F, '\$1 == \"V3\" { exit !(\$11 == \"NA\" && \$10 != \"NA\") }' $CSV"
check "run_all.sh acepta clave=valor (tiempo_total_s= tiene prioridad; tiempo_kernel_s=)" \
    "./run_all.sh -e V3kv -n $N -t gpu -o $CSV -- ./tests/falso_gpu_kv.sh && awk -F, '\$1 == \"V3kv\" && \$9 == \"0.012000\" { a = 1 } \$1 == \"V3kv-kernel\" && \$9 == \"0.003000\" { b = 1 } END { exit !(a && b) }' $CSV"

# 4. Gráficas
check "graficar_proyecto.py termina con código 0" \
    "python3 graficar_proyecto.py $CSV --titulo 'Prueba de humo'"
check "se generaron tabla.md, speedup.png, eficiencia.png y comparacion.png" \
    "test -s $OUTDIR/tabla.md && test -s $OUTDIR/speedup.png && test -s $OUTDIR/eficiencia.png && test -s $OUTDIR/comparacion.png"
check "la tabla incluye la fila V2 con 4 hilos con mín, máx y f de Karp–Flatt numéricos" \
    "grep -E '^\| V2 \| 4 \|' $OUTDIR/tabla.md | awk -F'|' '{ exit !(\$5 ~ /[0-9]/ && \$6 ~ /[0-9]/ && \$9 ~ /[0-9]/) }'"
mkdir -p "$OUTDIR/final"
awk -F, -v OFS=, 'NR == 1 { NF = 11; print; next } $1 == "V1" || $1 == "V2" { $1 = tolower($1); NF = 11; print }' \
    "$CSV" > "$OUTDIR/final/mediciones.csv"
check "graficar_proyecto.py lee el formato de la entrega final (v1/v2, sin min_s/max_s)" \
    "python3 graficar_proyecto.py $OUTDIR/final/mediciones.csv && grep -E '^\| v2 \| 4 \|' $OUTDIR/final/tabla.md | awk -F'|' '{ exit !(\$5 ~ /[0-9]/ && \$6 ~ /[0-9]/ && \$7 ~ /[0-9]/) }'"
check "graficar_proyecto.py --help termina con código 0" "python3 graficar_proyecto.py --help"

echo "Resultado: $PASS PASS, $FAIL FAIL"
if [[ $FAIL -eq 0 ]]; then
    rm -rf "$OUTDIR" __pycache__
    exit 0
fi
echo "Se conserva $OUTDIR/ para revisar."
exit 1
