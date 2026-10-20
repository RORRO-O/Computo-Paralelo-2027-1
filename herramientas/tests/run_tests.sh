#!/usr/bin/env bash
# tests/run_tests.sh — Pruebas de todas las herramientas de herramientas/. Código 0 solo si todo pasa.
# Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · herramientas/
#
# Uso:  make test   (o ./tests/run_tests.sh después de `make`). Variable: MPIRUN_FLAGS (por defecto --oversubscribe).
#
# Verifica, en una carpeta temporal fuera del repositorio (se borra si todo pasa; si algo falla se imprime su ruta):
#   1. cronometro.h vía ejemplo_cronometro (OpenMP y secuencial) y el #error por orden de inclusión
#   2. medir.sh: OpenMP, --mpi, -t gpu, --clave, --t1, entorno.txt, avisos, códigos de error y los ejemplos de su cabecera
#   3. graficar_speedup.py: CSV de 5 y 3 repeticiones, columnas extra, filas gpu, recálculo, -h, CSV inválido
#   4. plantilla-run_tests.sh: OpenMP, MPI, diferencia mayor que la tolerancia, aviso TODO pendiente
#   5. Makefile.openmp y Makefile.mpi en una carpeta nueva: make, run, test, medir, grafica, clean
#   6. seguimiento.py: plantilla vacía, los seis indicadores, --alertas, filas de ejemplo de la guía, encabezado ajeno
#   7. colab-kaggle.md: fragmentos de Python, Numba en el simulador (si hay numba), checksum, nvcc -c (si hay nvcc)
#   8. plantilla-reporte-practica.md (secciones y pesos) y encabezado de metadatos en cada .md
#   9. README.md: documenta cada archivo de la carpeta y cada comando de su índice corre tal cual
#  10. Las pruebas no dejan archivos nuevos en herramientas/
set -uo pipefail
export LC_ALL=C
cd "$(dirname "$0")/.." || exit 1
RAIZ=$(pwd)

PASS=0
FAIL=0
ok() { echo "PASS: $1"; PASS=$((PASS + 1)); }
bad() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }
check() { if eval "$2" > /dev/null 2>&1; then ok "$1"; else bad "$1"; fi; }
# cerca A B TOL -> |A-B| <= TOL        · cerca_rel A B TOL -> |A-B| <= TOL*|A|
cerca() { awk -v a="$1" -v b="$2" -v t="$3" 'BEGIN { d = a - b; if (d < 0) d = -d; exit !(d <= t) }'; }
cerca_rel() { awk -v a="$1" -v b="$2" -v t="$3" 'BEGIN { d = a - b; if (d < 0) d = -d; m = a < 0 ? -a : a; exit !(d <= t * m) }'; }
valor() { awk -F= -v k="$1" '$1 == k { v = $2 } END { print v }'; }   # valor "clave" <<< "salida"

for b in ejemplo_cronometro.out ejemplo_cronometro_seq.out; do
    [[ -x $b ]] || { echo "Falta $b: corre 'make' antes de las pruebas."; exit 1; }
done
export MPIRUN_FLAGS="${MPIRUN_FLAGS:---oversubscribe}"
if [[ $(id -u) == 0 ]]; then export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1; fi
HAY_MPI=0
if command -v mpirun > /dev/null 2>&1 && [[ -x ./ejemplo_mpi.out ]]; then HAY_MPI=1; fi
HAY_NVCC=0
if command -v nvcc > /dev/null 2>&1; then HAY_NVCC=1; fi
NUCLEOS=$(getconf _NPROCESSORS_ONLN 2> /dev/null || echo 4)

ANTES=$(ls -A)
T=$(mktemp -d) || { echo "no pude crear una carpeta temporal"; exit 1; }
N=2000000
PI=3.141592653589793

# ---------- 1. cronometro.h ----------
salida=$(./ejemplo_cronometro.out $N)
res=$(valor resultado <<< "$salida")
check "ejemplo_cronometro (OpenMP) imprime resultado ~ pi" "cerca '$res' $PI 1e-6"
check "ejemplo_cronometro imprime tiempo_s > 0" "awk 'BEGIN { exit !($(valor tiempo_s <<< "$salida") > 0) }'"
salida_seq=$(./ejemplo_cronometro_seq.out $N)
res_seq=$(valor resultado <<< "$salida_seq")
check "ejemplo_cronometro_seq (clock_gettime) imprime resultado ~ pi e hilos=1" \
    "cerca '$res_seq' $PI 1e-6 && test '$(valor hilos <<< "$salida_seq")' = 1"
check "ejemplo_cronometro rechaza argumentos no válidos (código 2)" \
    "./ejemplo_cronometro.out abc; test \$? -eq 2 && { ./ejemplo_cronometro.out 10 0; test \$? -eq 2; }"
salida5=$(OMP_NUM_THREADS=2 ./ejemplo_cronometro.out $N 5 "$T/cron.csv" 0.5)
t_med=$(valor tiempo_s <<< "$salida5"); t_min=$(valor tiempo_min_s <<< "$salida5"); t_max=$(valor tiempo_max_s <<< "$salida5")
check "con reps=5 imprime tiempo_min_s <= tiempo_s <= tiempo_max_s" \
    "awk 'BEGIN { exit !($t_min <= $t_med && $t_med <= $t_max && $t_min > 0) }'"
check "cron_csv_abrir escribe el encabezado del protocolo con 5 repeticiones" \
    "test \"\$(head -n 1 $T/cron.csv)\" = 'config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia'"
fila=$(sed -n 2p "$T/cron.csv")
check "cron_csv_fila escribe 11 columnas, config ejemplo, hilos=2 y n" \
    "awk -F, '{ exit !(NF == 11 && \$1 == \"ejemplo\" && \$2 == 2 && \$3 == $N) }' <<< '$fila'"
sp_csv=$(cut -d, -f10 <<< "$fila"); med_csv=$(cut -d, -f9 <<< "$fila"); ef_csv=$(cut -d, -f11 <<< "$fila")
check "en la fila, mediana_s = tiempo_s impreso; speedup = t1/mediana; eficiencia = speedup/2" \
    "test '$med_csv' = '$t_med' && cerca_rel \$(awk 'BEGIN { print 0.5 / $med_csv }') $sp_csv 1e-3 && cerca_rel \$(awk 'BEGIN { print $sp_csv / 2 }') $ef_csv 1e-3"
OMP_NUM_THREADS=1 ./ejemplo_cronometro.out $N 5 "$T/cron.csv" > /dev/null
check "una segunda fila se agrega sin repetir el encabezado; sin t1 escribe NA,NA" \
    "test \$(wc -l < $T/cron.csv) -eq 3 && awk -F, 'NR == 3 { exit !(\$10 == \"NA\" && \$11 == \"NA\") }' $T/cron.csv"
printf '#include <stdio.h>\n#include "cronometro.h"\nint main(void) { printf("%%f\\n", cron_ahora()); return 0; }\n' > "$T/orden.c"
check "cronometro.h incluido después de <stdio.h> sin -fopenmp da el #error explicativo" \
    "! gcc -std=c11 -O2 -Wall -Wextra -I. -c $T/orden.c -o $T/orden.o 2> $T/orden.err && grep -q 'cronometro.h: incluye este archivo ANTES' $T/orden.err"
check "el mismo orden compila sin warnings con -fopenmp (reloj omp_get_wtime)" \
    "gcc -std=c11 -O2 -Wall -Wextra -fopenmp -I. -c $T/orden.c -o $T/orden.o 2> $T/orden2.err && ! test -s $T/orden2.err"

# ---------- 2. medir.sh ----------
M=$T/m
CSV=$M/medir.csv
check "medir.sh mide la versión secuencial y crea el CSV" \
    "./medir.sh -c secuencial -t 1 -n $N -r 3 -o $CSV -- ./ejemplo_cronometro_seq.out"
check "el CSV tiene el encabezado del protocolo con 3 repeticiones" \
    "test \"\$(head -n 1 $CSV)\" = 'config,hilos,n,rep1,rep2,rep3,mediana_s,speedup,eficiencia'"
check "la fila secuencial tiene speedup 1.000 y eficiencia 1.000" \
    "awk -F, 'NR == 2 { exit !(\$1 == \"secuencial\" && \$2 == 1 && \$3 == $N && \$8 == \"1.000\" && \$9 == \"1.000\") }' $CSV"
./medir.sh -c openmp -t '1 2 4' -n $N -r 3 -o "$CSV" -- ./ejemplo_cronometro.out > "$M/openmp.out" 2> "$M/openmp.err"
check "medir.sh agrega openmp con 1, 2 y 4 hilos" "test \$(grep -c '^openmp,' $CSV) -eq 3"
check "las filas openmp usan la T(1) secuencial del CSV (speedup numérico) sin aviso de línea base" \
    "awk -F, '\$1 == \"openmp\" { c++; if (\$8 == \"NA\" || \$9 == \"NA\") na = 1 } END { exit !(c == 3 && !na) }' $CSV && ! grep -q 'línea base' $M/openmp.err"
check "la mediana de cada fila es la mediana de sus repeticiones" \
    "awk -F, 'NR > 1 { a[1]=\$4; a[2]=\$5; a[3]=\$6; for (i=1;i<=3;i++) for (j=i+1;j<=3;j++) if (a[j]<a[i]) { x=a[i]; a[i]=a[j]; a[j]=x } if (sprintf(\"%.6f\", a[2]) != \$7) e = 1 } END { exit e }' $CSV"
check "entorno.txt tiene el bloque de la máquina y una línea corrida: por llamada" \
    "grep -q '^fecha:' $M/entorno.txt && grep -q '^compilador:' $M/entorno.txt && test \$(grep -c '^corrida: .*csv=medir.csv' $M/entorno.txt) -eq 2"
check "la línea corrida: dice config, lanzador, hilos y comando" \
    "grep -q 'config=openmp · lanzador=OMP_NUM_THREADS=P · hilos=1 2 4 · repeticiones=3' $M/entorno.txt && grep -q 'comando=./ejemplo_cronometro.out $N' $M/entorno.txt"
./medir.sh -c openmp -t '1 2' -n $N -r 1 -o "$M/sinbase.csv" -- ./ejemplo_cronometro.out > /dev/null 2> "$M/sinbase.err"
check "sin fila secuencial ni --t1, avisa que la línea base es la paralela con 1 hilo (idea errónea 31)" \
    "grep -q 'línea base T(1) es .openmp. con 1 hilo' $M/sinbase.err"
./medir.sh -c sobre -t "$((NUCLEOS + 1))" -n 1000 -r 1 -o "$M/sobre.csv" -- ./ejemplo_cronometro.out > /dev/null 2> "$M/sobre.err"
check "avisa de sobre-suscripción con más hilos que núcleos lógicos" "grep -q 'sobre-suscripción' $M/sobre.err"
check "--t1 fija la línea base y sin -n toma n de la salida del programa" \
    "./medir.sh -c t1 -t 1 -r 1 --t1 1.0 -o $M/t1.csv -- ./ejemplo_cronometro.out && awk -F, 'NR == 2 { d = 1.0 / \$5 - \$6; if (d < 0) d = -d; exit !(\$3 == 20000000 && d <= 1e-3 * \$6) }' $M/t1.csv"
check "-t gpu escribe hilos=gpu, speedup numérico (con --t1) y eficiencia NA" \
    "./medir.sh -c gpu-falsa -t gpu -n $N -r 1 --t1 1.0 -o $M/gpu.csv -- ./ejemplo_cronometro.out && awk -F, 'NR == 2 { exit !(\$2 == \"gpu\" && \$6 != \"NA\" && \$7 == \"NA\") }' $M/gpu.csv"
check "--clave lee otra línea clave=valor (tiempo_min_s) en lugar de tiempo_s" \
    "./medir.sh -c clave -t 1 -r 1 --clave tiempo_min_s -o $M/clave.csv -- ./ejemplo_cronometro.out $N 3 && awk -F, 'NR == 2 { exit !(\$4 > 0) }' $M/clave.csv"
check "medir.sh rechaza 'gpu' combinado con --mpi (código 2)" \
    "./medir.sh --mpi -t gpu -o $M/x.csv -- ./ejemplo_cronometro.out; test \$? -eq 2"
check "medir.sh rechaza un programa que no imprime tiempo_s= (código 4)" \
    "./medir.sh -c x -t 1 -r 1 -o $M/basura.csv -- /bin/true; test \$? -eq 4"
check "medir.sh rechaza una llamada sin programa (código 2)" \
    "./medir.sh -c x --; test \$? -eq 2"
check "medir.sh rechaza un CSV existente con otro número de repeticiones (código 3)" \
    "./medir.sh -c x -t 1 -r 2 -o $CSV -- ./ejemplo_cronometro.out; test \$? -eq 3"
./medir.sh -h > "$M/ayuda.txt" 2>&1
check "medir.sh -h imprime la ayuda de la cabecera" "grep -q '^Uso:' $M/ayuda.txt && grep -q -- '--clave K' $M/ayuda.txt"
if [[ $HAY_MPI -eq 1 ]]; then
    check "medir.sh --mpi mide ejemplo_mpi con 1, 2 y 4 procesos" \
        "./medir.sh --mpi -c mpi -t '1 2 4' -n $N -r 3 -o $CSV -- ./ejemplo_mpi.out"
    check "las filas mpi tienen speedup numérico respecto a la secuencial y la corrida registra mpirun" \
        "awk -F, '\$1 == \"mpi\" { c++; if (\$8 == \"NA\") na = 1 } END { exit !(c == 3 && !na) }' $CSV && grep -q 'lanzador=mpirun $MPIRUN_FLAGS -np P' $M/entorno.txt"
else
    echo "AVISO: sin mpirun o sin ejemplo_mpi.out; se omiten las pruebas de --mpi"
fi
# Ejemplos de la cabecera de medir.sh, tal cual salvo n (8·10⁸ -> N) para que la prueba dure segundos.
C=$T/cabecera
mkdir -p "$C"
cp ./*.out medir.sh graficar_speedup.py "$C/"
awk '/^# Ejemplos ejecutables/ { e = 1; next } e && /^#   / { sub(/^#   /, ""); print; next } e && !/^#/ { exit }' \
    medir.sh > "$C/ejemplos.txt"
if [[ $HAY_MPI -eq 0 ]]; then sed -i.bak '/--mpi/d' "$C/ejemplos.txt"; fi
check "la cabecera de medir.sh trae los ejemplos documentados (secuencial, openmp, mpi, gráfica)" \
    "test \$(wc -l < $C/ejemplos.txt) -ge 3 && grep -q 'graficar_speedup.py resultados/mediciones.csv' $C/ejemplos.txt"
errores=0
corridos=0
# < /dev/null: mpirun lee la entrada estándar y se tragaría las líneas siguientes del archivo.
while IFS= read -r cmd; do
    corridos=$((corridos + 1))
    (cd "$C" && bash -c "${cmd//800000000/$N}") < /dev/null >> "$C/ejemplo.log" 2>&1 || { errores=1; echo "   falló: $cmd"; }
done < "$C/ejemplos.txt"
filas_esperadas=$((1 + 1 + 4 + 3 * HAY_MPI))
check "los $corridos ejemplos de la cabecera corren: CSV con $filas_esperadas filas, speedup.png y eficiencia.png" \
    "test $errores -eq 0 && test $corridos -eq \$(wc -l < $C/ejemplos.txt) && test \$(wc -l < $C/resultados/mediciones.csv) -eq $filas_esperadas && test -s $C/resultados/speedup.png && test -s $C/resultados/eficiencia.png"

# ---------- 3. graficar_speedup.py ----------
G=$T/g
check "graficar_speedup.py genera speedup.png y eficiencia.png con ejemplo_resultados.csv" \
    "python3 graficar_speedup.py ejemplo_resultados.csv --titulo 'Prueba' --salida $G/1 > $G.tabla1 && test -s $G/1/speedup.png && test -s $G/1/eficiencia.png"
check "graficar_speedup.py imprime la tabla Markdown con f de Karp–Flatt" \
    "grep -q 'Karp' $G.tabla1 && grep -q '^| openmp | 8 |' $G.tabla1"
check "los números del README sobre ejemplo_resultados.csv salen de la tabla (E(4) 0.91 y 0.88; S(8) 3.72, E(8) 0.47)" \
    "grep -q '^| openmp | 4 | .* | 3.65 | 0.91 |' $G.tabla1 && grep -q '^| mpi | 4 | .* | 0.88 |' $G.tabla1 && grep -q '^| openmp | 8 | .* | 3.72 | 0.47 |' $G.tabla1 && grep -q '^| openmp | 2 | .* | -0.003 |' $G.tabla1"
check "graficar_speedup.py acepta el CSV de medir.sh con 3 repeticiones" \
    "python3 graficar_speedup.py $CSV --salida $G/2 > /dev/null && test -s $G/2/speedup.png"
check "graficar_speedup.py --recalcular --base secuencial funciona" \
    "python3 graficar_speedup.py $CSV --salida $G/3 --recalcular --base secuencial > /dev/null && test -s $G/3/eficiencia.png"
printf 'config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia,min_s,max_s\nV1,1,100,1.0,1.0,1.0,1.0,1.0,1.0,1.000,1.000,1.0,1.0\nV2,2,100,0.6,0.6,0.6,0.6,0.6,0.6,,,0.6,0.6\nV2,4,100,0.4,0.4,0.4,0.4,0.4,0.4,NA,NA,0.4,0.4\nV3,gpu,100,0.1,0.1,0.1,0.1,0.1,0.1,10,NA,0.1,0.1\n' > "$T/extra.csv"
check "tolera columnas extra (min_s,max_s), speedup vacío/NA y filas gpu (en la tabla, con aviso)" \
    "python3 graficar_speedup.py $T/extra.csv --salida $G/4 > $G.tabla4 2> $G.err4 && test -s $G/4/speedup.png && grep -q 'gpu' $G.err4 && grep -q '^| V3 | gpu |' $G.tabla4"
check "calcula el speedup faltante desde T(1): V2 con 4 hilos -> 2.50, E 0.62, f 0.200" \
    "grep -q '^| V2 | 4 | 0.400000 | 0.400000 | 0.400000 | 2.50 | 0.62 | 0.200 |' $G.tabla4"
printf 'config,hilos,n\nx,1,10\n' > "$T/malo.csv"
check "rechaza un CSV sin mediana_s (código 1)" \
    "python3 graficar_speedup.py $T/malo.csv --salida $G/5; test \$? -eq 1"
check "graficar_speedup.py -h muestra el uso de la cabecera" \
    "python3 graficar_speedup.py -h | grep 'speedup.png      speedup vs hilos'"

# ---------- 4. plantilla-run_tests.sh ----------
PROGRAMA_SEQ=./ejemplo_cronometro_seq.out PROGRAMA_PAR=./ejemplo_cronometro.out ./plantilla-run_tests.sh > "$T/plantilla.txt" 2>&1
codigo=$?
check "plantilla-run_tests.sh pasa con los ejemplos OpenMP (código 0)" "test $codigo -eq 0 && grep -q '0 FAIL' $T/plantilla.txt"
check "plantilla-run_tests.sh avisa 'TODO pendiente' mientras casos_extra() esté vacío" "grep -q 'TODO pendiente' $T/plantilla.txt"
check "plantilla-run_tests.sh falla (código 1) si no existen los programas" \
    "PROGRAMA_SEQ=./no_existe PROGRAMA_PAR=./tampoco ./plantilla-run_tests.sh; test \$? -eq 1"
printf '#!/usr/bin/env bash\necho "resultado=3.15"\n' > "$T/falso.sh"
chmod +x "$T/falso.sh"
PROGRAMA_SEQ=./ejemplo_cronometro_seq.out PROGRAMA_PAR=$T/falso.sh TAMANOS='1000' HILOS='1 2' ./plantilla-run_tests.sh > "$T/tol.txt" 2>&1
codigo_tol=$?
check "plantilla-run_tests.sh detecta un resultado fuera de la tolerancia (FAIL por caso y código 1)" \
    "test $codigo_tol -eq 1 && test \$(grep -c '^FAIL: resultado paralelo == secuencial' $T/tol.txt) -eq 2"
if [[ $HAY_MPI -eq 1 ]]; then
    check "plantilla-run_tests.sh pasa en MODO=mpi con ejemplo_mpi" \
        "MODO=mpi PROGRAMA_SEQ=./ejemplo_cronometro_seq.out PROGRAMA_PAR=./ejemplo_mpi.out ./plantilla-run_tests.sh"
fi

# ---------- 5. Plantillas Makefile.openmp y Makefile.mpi en una carpeta nueva ----------
D=$T/plantilla-openmp
mkdir -p "$D/tests"
cp cronometro.h ejemplo_cronometro.c medir.sh graficar_speedup.py "$D/" && cp Makefile.openmp "$D/Makefile" && cp plantilla-run_tests.sh "$D/tests/run_tests.sh"
MK="make -C $D SRC=ejemplo_cronometro.c BIN=programa.out"
check "Makefile.openmp: make compila sin warnings (programa.out y programa_seq.out)" \
    "$MK > $T/mk1.log 2>&1 && ! grep -qi warning $T/mk1.log && test -x $D/programa.out && test -x $D/programa_seq.out"
check "Makefile.openmp: make run ejecuta con N y THREADS" \
    "$MK N=1000 THREADS=2 run > $T/run1.txt 2>&1 && grep -q 'hilos=2' $T/run1.txt && grep -q 'n=1000' $T/run1.txt"
check "Makefile.openmp: make test pasa con la plantilla de pruebas" "$MK TAMANOS='1000 10000' test"
check "Makefile.openmp: make medir escribe secuencial + openmp con 5 repeticiones" \
    "$MK N=200000 HILOS='1 2' medir > $T/medir1.log 2>&1 && test \$(grep -c '^secuencial,1,200000,' $D/resultados/mediciones.csv) -eq 1 && test \$(grep -c '^openmp,' $D/resultados/mediciones.csv) -eq 2 && head -n 1 $D/resultados/mediciones.csv | grep rep5"
check "Makefile.openmp: make grafica genera speedup.png y eficiencia.png" \
    "$MK grafica > $T/graf1.log 2>&1 && test -s $D/resultados/speedup.png && test -s $D/resultados/eficiencia.png"
check "Makefile.openmp: make clean borra los binarios" \
    "$MK clean && test ! -e $D/programa.out && test ! -e $D/programa_seq.out"
if [[ $HAY_MPI -eq 1 ]]; then
    D=$T/plantilla-mpi
    mkdir -p "$D/tests"
    cp cronometro.h ejemplo_cronometro.c ejemplo_mpi.c medir.sh graficar_speedup.py "$D/" && cp Makefile.mpi "$D/Makefile" && cp plantilla-run_tests.sh "$D/tests/run_tests.sh"
    MK="make -C $D SRC=ejemplo_mpi.c SRC_SEQ=ejemplo_cronometro.c BIN=programa_mpi.out BIN_SEQ=programa_seq.out MPIRUN_FLAGS=$MPIRUN_FLAGS"
    check "Makefile.mpi: make compila sin warnings" \
        "$MK > $T/mk2.log 2>&1 && ! grep -qi warning $T/mk2.log && test -x $D/programa_mpi.out && test -x $D/programa_seq.out"
    check "Makefile.mpi: make run lanza mpirun con NP procesos" \
        "$MK N=1000 NP=2 run > $T/run2.txt 2>&1 && grep -q 'procesos=2' $T/run2.txt"
    check "Makefile.mpi: make test pasa en MODO=mpi" "$MK TAMANOS='1000 10000' PROCESOS='1 2' test"
    check "Makefile.mpi: make medir escribe secuencial + mpi" \
        "$MK N=200000 PROCESOS='1 2' medir > $T/medir2.log 2>&1 && test \$(grep -c '^mpi,' $D/resultados/mediciones.csv) -eq 2"
    check "Makefile.mpi: make grafica y make clean" \
        "$MK grafica > $T/graf2.log 2>&1 && test -s $D/resultados/speedup.png && $MK clean && test ! -e $D/programa_mpi.out && test ! -e $D/programa_seq.out"
fi

# ---------- 6. seguimiento.py ----------
S=$T/seguimiento
mkdir -p "$S"
python3 seguimiento.py seguimiento-grupo.csv > "$S/vacia.txt" 2>&1
codigo=$?
check "la plantilla seguimiento-grupo.csv está vacía (solo encabezado) e incluye nivel_diagnostico_ago" \
    "test \$(wc -l < seguimiento-grupo.csv) -eq 1 && head -n 1 seguimiento-grupo.csv | grep nivel_diagnostico_ago"
check "seguimiento.py con la plantilla vacía dice que no hay filas (código 0)" "test $codigo -eq 0 && grep -q 'Sin filas' $S/vacia.txt"
{
    cat seguimiento-grupo.csv
    cat << 'FILAS'
2026-10-15,U3-S07,grupo,,,71,64,45,78,52,81,18,11,5,,,,,,,error frecuente: atomic protege una región (A.8)
2026-10-19,U3-S08,grupo,,,56,70,40,72,,,14,10,11,,,,,,,
2026-10-20,U3-S09,grupo,,,64,66,,,,,20,9,4,74,,,,,,pre-lab P4
2026-10-29,H1,equipo,equipo01,,,,,,,,,,,,85,,,,,
2026-10-29,H1,equipo,equipo02,,,,,,,,,,,,55,,,,,
2026-10-29,H1,equipo,equipo03,,,,,,,,,,,,72,,,,,
2026-09-29,E1,estudiante,L07,refuerzo,,,,,,,,,,,,,,52,100,
2026-09-29,E1,estudiante,L12,refuerzo,,,,,,,,,,,,,,60,100,
2026-09-29,E1,estudiante,L20,alto,,,,,,,,,,,,,,90,100,
2026-11-03,E2,estudiante,L07,,,,,,,,,,,,,80,85,61,100,
2026-11-03,E2,estudiante,L12,,,,,,,,,,,,,90,90,55,100,
2026-11-03,E2,estudiante,L20,,,,,,,,,,,,,90,80,92,100,
2026-12-08,E3,estudiante,L07,,,,,,,,,,,,,,,58,100,
2026-12-08,E3,estudiante,L12,,,,,,,,,,,,,,,50,100,
2026-11-03,E2,estudiante,L33,raro,,,,,,,,,,,,abc,,70,100,
FILAS
} > "$S/hoja.csv"
python3 seguimiento.py "$S/hoja.csv" > "$S/informe.txt" 2> "$S/avisos.txt"
codigo=$?
check "seguimiento.py procesa una hoja con los tres ámbitos (código 0, 15 filas)" \
    "test $codigo -eq 0 && grep -q '15 filas (grupo 3, equipo 3, estudiante 9)' $S/informe.txt"
check "1. recuperación: alerta en U3-S08 ítem ant1 = 56 % y solo ahí" \
    "test \$(grep -c '^ALERTA retrieval' $S/informe.txt) -eq 1 && grep -q 'U3-S08 (2026-10-19), ítem ant1 (de la sesión anterior) = 56 %' $S/informe.txt"
check "2. exit ticket: alerta en U3-S08 con 31 % en mal (11 de 35)" \
    "test \$(grep -c '^ALERTA exit' $S/informe.txt) -eq 1 && grep -q \"'mal' = 31 % de 35 tickets\" $S/informe.txt"
check "3. entregas: alerta en U3-S09 con 74 %" "grep -q '^ALERTA entregas: U3-S09 (2026-10-20), 74 %' $S/informe.txt"
check "4. hitos: H1 con 3 equipos, equipo02 bajo 60 %" \
    "grep -q 'H1: 3 equipo(s), mediana 72 %, 1 bajo 60 %' $S/informe.txt && grep -q '^ALERTA hito: H1, 1 equipo(s) con < 60 % (equipo02)' $S/informe.txt"
check "5. calibración: E2 postdicción − real = +1.6 sobre 10 (alerta) y predicción = +1.7 aparte" \
    "grep -q 'E2: postdicción − real = +1.6 sobre 10 (n = 3; 2 sobreestiman por más de 1.5) · predicción − real = +1.7' $S/informe.txt && grep -q '^ALERTA calibracion: E2' $S/informe.txt"
check "6. mejora: refuerzo sube de E1 a E2 (mediana +0.2) y baja de E2 a E3 (mediana -0.4, alerta)" \
    "grep -q 'refuerzo (2): E1→E2: 1 de 2 suben, mediana +0.2; E2→E3: 0 de 2 suben, mediana -0.4' $S/informe.txt && test \$(grep -c '^ALERTA mejora' $S/informe.txt) -eq 1"
check "avisa los datos mal escritos (nivel 'raro', 'abc') sin detenerse" \
    "grep -q \"nivel_diagnostico_ago 'raro'\" $S/avisos.txt && grep -q \"'abc' en prediccion\" $S/avisos.txt"
check "la salida no contiene números de lista (solo agregados y claves de equipo)" \
    "! grep -qE 'L07|L12|L20|L33' $S/informe.txt"
check "--alertas imprime solo las 6 líneas ALERTA" \
    "python3 seguimiento.py --alertas $S/hoja.csv 2> /dev/null > $S/alertas.txt && test \$(wc -l < $S/alertas.txt) -eq 6 && test \$(grep -vc '^ALERTA' $S/alertas.txt) -eq 0"
{ cat seguimiento-grupo.csv; grep -E '^2026-' seguimiento-grupo.md; } > "$S/guia.csv"
check "las filas de ejemplo de seguimiento-grupo.md tienen 21 columnas y se leen como dice la guía" \
    "test \$(grep -E '^2026-' seguimiento-grupo.md | awk -F, 'NF != 21' | wc -l) -eq 0 && python3 seguimiento.py $S/guia.csv | grep '2 filas (grupo 1, equipo 0, estudiante 1)'"
check "--alertas sin umbrales cruzados imprime 'Sin alertas.'" \
    "{ cat seguimiento-grupo.csv; echo '2026-10-22,U3-S10,grupo,,,80,90,,,,,30,3,1,,,,,,,'; } > $S/limpia.csv && test \"\$(python3 seguimiento.py --alertas $S/limpia.csv)\" = 'Sin alertas.'"
printf 'fecha,evento\n2026-10-15,U3-S07\n' > "$S/ajena.csv"
check "rechaza una hoja sin las columnas de la plantilla (código 1)" \
    "python3 seguimiento.py $S/ajena.csv; test \$? -eq 1"

# ---------- 7. colab-kaggle.md y ejemplo_gpu.cu ----------
K=$T/colab
mkdir -p "$K"
python3 - colab-kaggle.md "$K" << 'PY'
import re, sys
texto = open(sys.argv[1], encoding="utf-8").read()
for i, bloque in enumerate(re.findall(r"```python\n(.*?)```", texto, re.S)):
    # Las líneas !comando y %magia son de IPython; para compilar el resto se cambian por comentarios.
    limpio = "\n".join("# " + l if l.lstrip().startswith(("!", "%")) else l for l in bloque.splitlines())
    open(f"{sys.argv[2]}/bloque{i}.py", "w", encoding="utf-8").write(limpio + "\n")
PY
check "colab-kaggle.md: los fragmentos de Python (Numba, CuPy, Colab) compilan" \
    "ls $K/bloque*.py > /dev/null && for f in $K/bloque*.py; do python3 -m py_compile \"\$f\" || exit 1; done"
NUMBA_PY=$(grep -l '^from numba import cuda' "$K"/bloque*.py | head -n 1)
if [[ -n $NUMBA_PY ]] && python3 -c 'import numba' > /dev/null 2>&1; then
    check "el esqueleto Numba corre en el simulador y su checksum es el exacto (n = 1000 -> 6997)" \
        "NUMBA_ENABLE_CUDASIM=1 python3 $NUMBA_PY 1000 | grep -x 'checksum=6997.0'"
else
    echo "AVISO: sin numba; se omite la ejecución del esqueleto con NUMBA_ENABLE_CUDASIM=1"
fi
# sum(i mod 7) + sum(2·(i mod 5)) para i < n, en forma cerrada: es el checksum que imprime ejemplo_gpu.cu.
esperado=$(awk 'BEGIN { n = 50000000; q = int(n / 7); r = n % 7; q5 = int(n / 5); r5 = n % 5;
                        printf "%d", 21 * q + r * (r - 1) / 2 + 2 * (10 * q5 + r5 * (r5 - 1) / 2) }')
check "el checksum de la salida esperada de ejemplo_gpu.cu (n = 5·10⁷) es el exacto ($esperado)" \
    "grep -q '^checksum=$esperado.0\$' colab-kaggle.md"
check "colab-kaggle.md usa los mismos nombres de salida que ejemplo_gpu.cu (tiempo_s, tiempo_kernel_s, ok)" \
    "grep -q 'printf(\"tiempo_kernel_s=' ejemplo_gpu.cu && grep -q 'printf(\"ok=' ejemplo_gpu.cu && grep -q '^tiempo_kernel_s=' colab-kaggle.md && grep -q '^ok=1' colab-kaggle.md"
if [[ $HAY_NVCC -eq 1 ]]; then
    check "ejemplo_gpu.cu compila con nvcc -c -arch=sm_75 sin warnings" \
        "nvcc -O2 -arch=sm_75 -Xcompiler -Wall,-Wextra -c ejemplo_gpu.cu -o $K/ejemplo_gpu.o > $K/nvcc.log 2>&1 && ! grep -qi warning $K/nvcc.log"
else
    echo "AVISO: sin nvcc; se omite la compilación de ejemplo_gpu.cu"
fi

# ---------- 8. Plantilla de reporte y encabezados ----------
R=plantilla-reporte-practica.md
faltan=""
for sec in "## 1. Entorno de medición" "## 2. Decisiones de diseño" "## 3. Predicción y resultado" \
    "## 4. Tabla de mediciones" "## 5. Gráficas" "## 6. Interpretación" "## 7. Reflexión individual" \
    "## 8. Bitácora de errores" "## 9. Qué no entendemos todavía" "## 10. Reparto de trabajo" \
    "## 11. Declaración de uso de IA"; do
    grep -qF "$sec" "$R" || faltan+=" [$sec]"
done
check "plantilla-reporte-practica.md tiene las 11 secciones (03-plantilla-practica.md, Entregables)" "test -z '$faltan'"
check "la declaración de IA tiene las cuatro líneas de 05-politica-ia.md" \
    "grep -q '^- Herramienta(s): …' $R && grep -q '^- Para qué la usamos (verde/amarillo): …' $R && grep -q '^- Qué fragmento(s) de código vinieron de la IA' $R && grep -q '^- Qué nos dijo la IA que resultó estar mal: …' $R"
check "los pesos de la lista de cotejo de la plantilla suman 100" \
    "test \$(grep -oE '^\| [^|]+ \(([0-9]+)\) \|' $R | grep -oE '\([0-9]+\)' | tr -d '()' | awk '{ s += \$1 } END { print s }') -eq 100"
sin_encabezado=""
for md in ./*.md; do
    head -n 5 "$md" | grep '^> \*\*Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1\*\*' > /dev/null || sin_encabezado+=" $md"
done
check "cada .md de herramientas/ empieza con el encabezado de metadatos" "test -z '$sin_encabezado'"

# ---------- 9. README.md: índice completo y comandos ejecutables ----------
no_doc=""
for f in *; do
    [[ -f $f && $f != README.md && $f != *.out && $f != *.o ]] || continue
    grep -qF "\`$f\`" README.md || no_doc+=" $f"
done
grep -qF '`tests/run_tests.sh`' README.md || no_doc+=" tests/run_tests.sh"
check "README.md documenta cada archivo de la carpeta" "test -z '$no_doc'"
[[ -z $no_doc ]] || echo "   sin documentar:$no_doc"
X=$T/copia
mkdir -p "$X"
cp -R ./* "$X/"
python3 - README.md > "$X/comandos.txt" << 'PY'
import re, sys
for linea in open(sys.argv[1], encoding="utf-8"):
    if not linea.startswith("| `"):
        continue
    celda = linea.rstrip("\n").rstrip("|").split(" | ")[-1].strip()
    if celda.startswith("("):
        continue                      # (lectura) o (plantilla: ...): no es un comando para correr aquí
    m = re.match(r"`([^`]+)`", celda)
    if m and m.group(1) not in ("make test",):
        print(m.group(1))
PY
check "el índice del README trae al menos 12 comandos de ejemplo" "test \$(wc -l < $X/comandos.txt) -ge 12"
errores=""
corridos=0
omitidos=0
while IFS= read -r cmd; do
    if [[ $cmd == *mpirun* || $cmd == *--mpi* || $cmd == *Makefile.mpi* ]] && [[ $HAY_MPI -eq 0 ]]; then
        omitidos=$((omitidos + 1)); continue
    fi
    if [[ $cmd == nvcc* && $HAY_NVCC -eq 0 ]]; then omitidos=$((omitidos + 1)); continue; fi
    corridos=$((corridos + 1))
    (cd "$X" && bash -c "$cmd") < /dev/null >> "$X/comandos.log" 2>&1 || errores+=" [$cmd]"
done < "$X/comandos.txt"
check "los $corridos comandos del índice del README corren tal cual desde herramientas/ (código 0; $omitidos omitidos)" \
    "test -z '$errores' && test $((corridos + omitidos)) -eq \$(wc -l < $X/comandos.txt)"
[[ -z $errores ]] || echo "   fallaron:$errores"

# ---------- 10. Sin residuos ----------
check "las pruebas no dejaron archivos nuevos en herramientas/" "test \"\$(ls -A)\" = '$ANTES'"

echo "Resultado: $PASS PASS, $FAIL FAIL"
if [[ $FAIL -eq 0 ]]; then
    rm -rf "$T"
    exit 0
fi
echo "Se conserva $T para revisar."
exit 1
