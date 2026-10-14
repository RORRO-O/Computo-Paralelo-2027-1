#!/usr/bin/env bash
# tests/run_tests.sh — Pruebas de las herramientas del curso. Código 0 solo si todo pasa.
# Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · herramientas/
#
# Verifica: (1) cronometro.h vía ejemplo_cronometro (OpenMP y secuencial): resultado correcto, tiempo_s,
# mediana y fila CSV; (2) medir.sh en modo OpenMP, -t gpu, --clave, sus códigos de error y, si hay mpirun, en
# modo --mpi con ejemplo_mpi; (3) graficar_speedup.py con ejemplo_resultados.csv, con un CSV de 3 repeticiones y
# con uno con columnas extra (formato de run_all.sh); (4) plantilla-run_tests.sh contra los ejemplos; (5) las
# plantillas Makefile.openmp y Makefile.mpi en una carpeta temporal (compilan sin warnings, run, test, clean);
# (6) si hay nvcc, que ejemplo_gpu.cu compila con nvcc -c -arch=sm_75.
# Uso: ./tests/run_tests.sh   (o `make test` desde herramientas/). Variable: MPIRUN_FLAGS (p. ej. --oversubscribe).
set -uo pipefail
export LC_ALL=C
cd "$(dirname "$0")/.." || exit 1

PASS=0
FAIL=0
ok() { echo "PASS: $1"; PASS=$((PASS + 1)); }
bad() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }
check() { if eval "$2" > /dev/null 2>&1; then ok "$1"; else bad "$1"; fi; }
# cerca A B TOL -> |A-B| <= TOL        · cerca_rel A B TOL -> |A-B| <= TOL*|A|
cerca() { awk -v a="$1" -v b="$2" -v t="$3" 'BEGIN { d = a - b; if (d < 0) d = -d; exit !(d <= t) }'; }
cerca_rel() { awk -v a="$1" -v b="$2" -v t="$3" 'BEGIN { d = a - b; if (d < 0) d = -d; m = a < 0 ? -a : a; exit !(d <= t * m) }'; }
valor() { awk -F= -v k="$1" '$1 == k { v = $2 } END { print v }'; }   # valor "clave" <<< "salida"

export MPIRUN_FLAGS="${MPIRUN_FLAGS:---oversubscribe}"
if [[ $(id -u) == 0 ]]; then export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1; fi
HAY_MPI=0
if command -v mpirun > /dev/null 2>&1 && [[ -x ./ejemplo_mpi.out ]]; then HAY_MPI=1; fi

T=pruebas-tmp
rm -rf "$T"
mkdir -p "$T"
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
check "en la fila, speedup = t1/mediana y eficiencia = speedup/2 (tolerancia 0.1 %)" \
    "cerca_rel \$(awk 'BEGIN { print 0.5 / $med_csv }') $sp_csv 1e-3 && cerca_rel \$(awk 'BEGIN { print $sp_csv / 2 }') $ef_csv 1e-3"
OMP_NUM_THREADS=1 ./ejemplo_cronometro.out $N 5 "$T/cron.csv" > /dev/null
check "una segunda fila se agrega sin repetir el encabezado; sin t1 escribe NA,NA" \
    "test \$(wc -l < $T/cron.csv) -eq 3 && awk -F, 'NR == 3 { exit !(\$10 == \"NA\" && \$11 == \"NA\") }' $T/cron.csv"

# ---------- 2. medir.sh ----------
CSV=$T/medir.csv
check "medir.sh mide la versión secuencial y crea el CSV" \
    "./medir.sh -c secuencial -t 1 -n $N -r 3 -o $CSV -- ./ejemplo_cronometro_seq.out"
check "el CSV tiene el encabezado del protocolo con 3 repeticiones" \
    "test \"\$(head -n 1 $CSV)\" = 'config,hilos,n,rep1,rep2,rep3,mediana_s,speedup,eficiencia'"
check "la fila secuencial tiene speedup 1.000 y eficiencia 1.000" \
    "awk -F, 'NR == 2 { exit !(\$1 == \"secuencial\" && \$2 == 1 && \$3 == $N && \$8 == \"1.000\" && \$9 == \"1.000\") }' $CSV"
check "medir.sh agrega openmp con 1, 2 y 4 hilos" \
    "./medir.sh -c openmp -t '1 2 4' -n $N -r 3 -o $CSV -- ./ejemplo_cronometro.out"
check "las filas openmp usan la T(1) secuencial del CSV (speedup numérico, no NA)" \
    "awk -F, '\$1 == \"openmp\" { c++; if (\$8 == \"NA\" || \$9 == \"NA\") na = 1 } END { exit !(c == 3 && !na) }' $CSV"
check "la mediana de cada fila es la mediana de sus repeticiones" \
    "awk -F, 'NR > 1 { a[1]=\$4; a[2]=\$5; a[3]=\$6; for (i=1;i<=3;i++) for (j=i+1;j<=3;j++) if (a[j]<a[i]) { x=a[i]; a[i]=a[j]; a[j]=x } if (sprintf(\"%.6f\", a[2]) != \$7) e = 1 } END { exit e }' $CSV"
check "el entorno quedó registrado en entorno.txt" \
    "grep -q '^fecha:' $T/entorno.txt && grep -q '^compilador:' $T/entorno.txt"
check "--t1 fija la línea base y sin -n toma n de la salida del programa" \
    "./medir.sh -c t1 -t 1 -r 1 --t1 1.0 -o $T/t1.csv -- ./ejemplo_cronometro.out && awk -F, 'NR == 2 { d = 1.0 / \$5 - \$6; if (d < 0) d = -d; exit !(\$3 == 20000000 && d <= 1e-3 * \$6) }' $T/t1.csv"
check "-t gpu escribe hilos=gpu, speedup numérico (con --t1) y eficiencia NA" \
    "./medir.sh -c gpu-falsa -t gpu -n $N -r 1 --t1 1.0 -o $T/gpu.csv -- ./ejemplo_cronometro.out && awk -F, 'NR == 2 { exit !(\$2 == \"gpu\" && \$6 != \"NA\" && \$7 == \"NA\") }' $T/gpu.csv"
check "--clave lee otra línea clave=valor (tiempo_min_s) en lugar de tiempo_s" \
    "./medir.sh -c clave -t 1 -r 1 --clave tiempo_min_s -o $T/clave.csv -- ./ejemplo_cronometro.out $N 3 && awk -F, 'NR == 2 { exit !(\$4 > 0) }' $T/clave.csv"
check "medir.sh rechaza 'gpu' combinado con --mpi (código 2)" \
    "./medir.sh --mpi -t gpu -o $T/x.csv -- ./ejemplo_cronometro.out; test \$? -eq 2"
check "medir.sh rechaza un programa que no imprime tiempo_s= (código 4)" \
    "./medir.sh -c x -t 1 -r 1 -o $T/basura.csv -- /bin/true; test \$? -eq 4"
check "medir.sh rechaza una llamada sin programa (código 2)" \
    "./medir.sh -c x --; test \$? -eq 2"
check "medir.sh rechaza un CSV existente con otro número de repeticiones (código 3)" \
    "./medir.sh -c x -t 1 -r 2 -o $CSV -- ./ejemplo_cronometro.out; test \$? -eq 3"
./medir.sh -h > "$T/ayuda.txt" 2>&1
check "medir.sh -h imprime la ayuda de la cabecera" "grep -q '^Uso:' $T/ayuda.txt"
if [[ $HAY_MPI -eq 1 ]]; then
    check "medir.sh --mpi mide ejemplo_mpi con 1, 2 y 4 procesos" \
        "./medir.sh --mpi -c mpi -t '1 2 4' -n $N -r 3 -o $CSV -- ./ejemplo_mpi.out"
    check "las filas mpi tienen speedup numérico respecto a la secuencial" \
        "awk -F, '\$1 == \"mpi\" { c++; if (\$8 == \"NA\") na = 1 } END { exit !(c == 3 && !na) }' $CSV"
else
    echo "AVISO: sin mpirun o sin ejemplo_mpi.out; se omiten las pruebas de --mpi"
fi

# ---------- 3. graficar_speedup.py ----------
check "graficar_speedup.py genera speedup.png y eficiencia.png con ejemplo_resultados.csv" \
    "python3 graficar_speedup.py ejemplo_resultados.csv --titulo 'Prueba' --salida $T/g1 > $T/tabla1.txt && test -s $T/g1/speedup.png && test -s $T/g1/eficiencia.png"
check "graficar_speedup.py imprime la tabla Markdown con f de Karp–Flatt" \
    "grep -q 'Karp' $T/tabla1.txt && grep -q '^| openmp | 8 |' $T/tabla1.txt"
check "graficar_speedup.py acepta el CSV de medir.sh con 3 repeticiones" \
    "python3 graficar_speedup.py $CSV --salida $T/g2 > /dev/null && test -s $T/g2/speedup.png"
check "graficar_speedup.py --recalcular --base secuencial funciona" \
    "python3 graficar_speedup.py $CSV --salida $T/g3 --recalcular --base secuencial > /dev/null && test -s $T/g3/eficiencia.png"
printf 'config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia,min_s,max_s\nV1,1,100,1.0,1.0,1.0,1.0,1.0,1.0,1.000,1.000,1.0,1.0\nV2,2,100,0.6,0.6,0.6,0.6,0.6,0.6,,,0.6,0.6\nV2,4,100,0.4,0.4,0.4,0.4,0.4,0.4,NA,NA,0.4,0.4\nV3,gpu,100,0.1,0.1,0.1,0.1,0.1,0.1,10,NA,0.1,0.1\n' > "$T/extra.csv"
check "tolera columnas extra (min_s,max_s), speedup vacío/NA y filas gpu" \
    "python3 graficar_speedup.py $T/extra.csv --salida $T/g4 > $T/tabla4.txt 2> $T/g4.err && test -s $T/g4/speedup.png && grep -q 'gpu' $T/g4.err"
check "calcula el speedup faltante desde T(1): V2 con 4 hilos -> 2.50, E 0.62, f 0.200" \
    "grep -q '^| V2 | 4 | 0.400000 | 0.400000 | 0.400000 | 2.50 | 0.62 | 0.200 |' $T/tabla4.txt"
printf 'config,hilos,n\nx,1,10\n' > "$T/malo.csv"
check "rechaza un CSV sin mediana_s (código 1)" \
    "python3 graficar_speedup.py $T/malo.csv --salida $T/g5; test \$? -eq 1"

# ---------- 4. plantilla-run_tests.sh ----------
check "plantilla-run_tests.sh pasa con los ejemplos OpenMP" \
    "PROGRAMA_SEQ=./ejemplo_cronometro_seq.out PROGRAMA_PAR=./ejemplo_cronometro.out ./plantilla-run_tests.sh"
check "plantilla-run_tests.sh falla (código 1) si no existen los programas" \
    "PROGRAMA_SEQ=./no_existe PROGRAMA_PAR=./tampoco ./plantilla-run_tests.sh; test \$? -eq 1"
PROGRAMA_SEQ=./ejemplo_cronometro_seq.out PROGRAMA_PAR=./ejemplo_cronometro.out TOL=1e-15 TAMANOS='1000' ./plantilla-run_tests.sh > "$T/tol.txt" 2>&1
codigo_tol=$?
check "plantilla-run_tests.sh detecta una diferencia mayor que la tolerancia (FAIL y código 1)" \
    "test $codigo_tol -eq 1 && grep -q '^FAIL' $T/tol.txt"
if [[ $HAY_MPI -eq 1 ]]; then
    check "plantilla-run_tests.sh pasa en MODO=mpi con ejemplo_mpi" \
        "MODO=mpi PROGRAMA_SEQ=./ejemplo_cronometro_seq.out PROGRAMA_PAR=./ejemplo_mpi.out ./plantilla-run_tests.sh"
fi

# ---------- 5. Plantillas Makefile.openmp y Makefile.mpi ----------
D=$T/plantilla-openmp
mkdir -p "$D/tests"
cp cronometro.h ejemplo_cronometro.c "$D/" && cp Makefile.openmp "$D/Makefile" && cp plantilla-run_tests.sh "$D/tests/run_tests.sh"
MK="make -C $D SRC=ejemplo_cronometro.c BIN=programa.out"
check "Makefile.openmp: make compila sin warnings" \
    "$MK > $T/mk1.log 2>&1 && ! grep -qi warning $T/mk1.log && test -x $D/programa.out && test -x $D/programa.out_seq"
check "Makefile.openmp: make run ejecuta con N y THREADS" \
    "$MK N=1000 THREADS=2 run > $T/run1.txt 2>&1 && grep -q 'hilos=2' $T/run1.txt && grep -q 'n=1000' $T/run1.txt"
check "Makefile.openmp: make test pasa con la plantilla de pruebas" \
    "$MK TAMANOS='1000 10000' test"
check "Makefile.openmp: make clean borra los binarios" \
    "$MK clean && test ! -e $D/programa.out && test ! -e $D/programa.out_seq"
if [[ $HAY_MPI -eq 1 ]]; then
    D=$T/plantilla-mpi
    mkdir -p "$D/tests"
    cp cronometro.h ejemplo_cronometro.c ejemplo_mpi.c "$D/" && cp Makefile.mpi "$D/Makefile" && cp plantilla-run_tests.sh "$D/tests/run_tests.sh"
    MK="make -C $D SRC=ejemplo_mpi.c SRC_SEQ=ejemplo_cronometro.c BIN=programa_mpi.out BIN_SEQ=programa_seq.out MPIRUN_FLAGS=$MPIRUN_FLAGS"
    check "Makefile.mpi: make compila sin warnings" \
        "$MK > $T/mk2.log 2>&1 && ! grep -qi warning $T/mk2.log && test -x $D/programa_mpi.out && test -x $D/programa_seq.out"
    check "Makefile.mpi: make run lanza mpirun con NP procesos" \
        "$MK N=1000 NP=2 run > $T/run2.txt 2>&1 && grep -q 'procesos=2' $T/run2.txt"
    check "Makefile.mpi: make test pasa en MODO=mpi" \
        "$MK TAMANOS='1000 10000' PROCESOS='1 2' test"
    check "Makefile.mpi: make clean borra los binarios" \
        "$MK clean && test ! -e $D/programa_mpi.out && test ! -e $D/programa_seq.out"
fi

# ---------- 6. ejemplo_gpu.cu (solo compilación; la ejecución es en Colab/Kaggle) ----------
if command -v nvcc > /dev/null 2>&1; then
    check "ejemplo_gpu.cu compila con nvcc -c -arch=sm_75 sin warnings" \
        "nvcc -O2 -arch=sm_75 -Xcompiler -Wall,-Wextra -c ejemplo_gpu.cu -o $T/ejemplo_gpu.o > $T/nvcc.log 2>&1 && ! grep -qi warning $T/nvcc.log"
else
    echo "AVISO: sin nvcc; se omite la compilación de ejemplo_gpu.cu"
fi

echo "Resultado: $PASS PASS, $FAIL FAIL"
if [[ $FAIL -eq 0 ]]; then
    rm -rf "$T"
    exit 0
fi
echo "Se conserva $T/ para revisar."
exit 1
