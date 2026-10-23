#!/usr/bin/env bash
# tests/run_tests.sh · Pruebas de verificar_entrega.sh y de las herramientas de plantilla-repo/
# Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1
#
# Uso:  bash tests/run_tests.sh        (desde proyecto/entrega-final/scripts; también lo llama `make test`)
# Qué hace: arma en una carpeta temporal repositorios de equipo de prueba y comprueba lo que el
#   verificador dice de cada uno:
#     A  plantilla-repo/ tal cual (sin llenar): compila, prueba y corre, pero NO es una entrega (código 1)
#        y el verificador no modifica el repositorio que revisa.
#     B  entrega completa con la estructura de plantilla-repo/: código 0, sin ningún FAIL.
#     C  entrega completa con la otra estructura aceptada (src/v1 src/v2 src/v3, bitacora-errores.md,
#        declaracion-ia.md, CSV con V1/V2/V3/V3-kernel y min_s,max_s): código 0, sin ningún FAIL.
#     D  B con --sin-ejecutar: ítems 6–8 como MANUAL, código 0; con LIMITE_EPOCH en el pasado, aviso
#        de entrega tardía (ítem 24).
#     E  errores de uso: código 2.
#     F  B con v3/kernel.cu cambiado después de generar el notebook: FAIL 16 (notebook desactualizado).
#     G  C con un run_all.sh cuyo --rapido sobrescribe resultados/mediciones.csv: AVISO 8.
#     H  generar_notebook_v3.py con una V3 en Python: incluye la cabecera (la V1 la necesita).
#   Las mediciones, los PDF y las salidas de GPU de B y C son DATOS SINTÉTICOS DE PRUEBA: solo
#   ejercitan el formato que revisa el verificador; no se publican ni se usan como ejemplo.
# Salida: PASS/FAIL por caso; código 0 solo si todo pasa. Tarda ≈ 30 s (compila y corre 4 veces).
# Requisitos: bash, make, gcc con OpenMP, git, python3 con nbformat y matplotlib.
set -u
cd "$(dirname "$0")/.." || exit 2
SCRIPTS="$(pwd -P)"
VERIF="$SCRIPTS/verificar_entrega.sh"
PLANTILLA="$(cd "$SCRIPTS/../plantilla-repo" && pwd -P)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/prueba_verificar.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass=0; fail=0
ok()  { echo "PASS  $1"; pass=$((pass + 1)); }
bad() { echo "FAIL  $1"; fail=$((fail + 1)); }
# espera NOMBRE ARCHIVO REGEX: la salida del verificador contiene una línea que cumple REGEX.
espera()    { if grep -qE -- "$3" "$2"; then ok "$1"; else bad "$1 (no aparece: $3)"; fi; }
no_espera() { if grep -qE -- "$3" "$2"; then bad "$1 (aparece: $(grep -E -- "$3" "$2" | head -1))"; else ok "$1"; fi; }
codigo_es() { if [ "$3" -eq "$2" ]; then ok "$1 (código $3)"; else bad "$1 (código $3, se esperaba $2)"; fi; }

# commit_como NOMBRE CORREO FECHA MENSAJE: commit con autor y fecha fijos (historial de prueba).
commit_como() {
    git add -A
    GIT_AUTHOR_DATE="$3" GIT_COMMITTER_DATE="$3" git -c user.name="$1" -c user.email="$2" \
        commit -q --allow-empty -m "$4"
}
# historial_dos_integrantes: 6 commits de dos integrantes en 6 semanas distintas y etiqueta entrega-final.
historial_dos_integrantes() {
    git init -q .
    commit_como integrante-a a@ejemplo.mx "2026-10-26T12:00:00-06:00" "Agregar V1 y pruebas"
    commit_como integrante-b b@ejemplo.mx "2026-11-02T12:00:00-06:00" "Agregar perfil de V1"
    commit_como integrante-a a@ejemplo.mx "2026-11-09T12:00:00-06:00" "Paralelizar el ciclo principal"
    commit_como integrante-b b@ejemplo.mx "2026-11-16T12:00:00-06:00" "Medir V2 con el protocolo"
    commit_como integrante-a a@ejemplo.mx "2026-11-23T12:00:00-06:00" "Agregar kernel de V3"
    commit_como integrante-b b@ejemplo.mx "2026-11-30T12:00:00-06:00" "Agregar notebook ejecutado"
    git tag entrega-final
}
# pdf_de N RUTA: PDF sintético de N páginas.
pdf_de() {
    python3 - "$1" "$2" << 'EOF'
import sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
n, ruta = int(sys.argv[1]), sys.argv[2]
with PdfPages(ruta) as pdf:
    for i in range(n):
        fig = plt.figure(figsize=(8.5, 11))
        fig.text(0.5, 0.5, f"página {i + 1} (sintética)", ha="center")
        pdf.savefig(fig)
        plt.close(fig)
EOF
}

# ======================= A. plantilla-repo tal cual =======================
A="$TMP/A"; cp -a "$PLANTILLA" "$A"
(cd "$A" && git init -q . && commit_como integrante-a a@ejemplo.mx "2026-10-26T12:00:00-06:00" "Agregar plantilla")
bash "$VERIF" "$A" --sin-red > "$TMP/A.out" 2>&1; cA=$?
codigo_es "A1 plantilla sin llenar no es entrega" 1 "$cA"
espera "A2 la plantilla compila sin warnings" "$TMP/A.out" '^PASS +6 '
espera "A3 make test de la plantilla pasa" "$TMP/A.out" '^PASS +7 '
espera "A4 run_all.sh --rapido de la plantilla corre" "$TMP/A.out" '^PASS +8 '
espera "A5 detecta el cómputo de marcador de posición" "$TMP/A.out" '^FAIL +P .*elemento'
espera "A6 notebook de la plantilla coincide con sus fuentes" "$TMP/A.out" '^PASS +16 .*coinciden'
espera "A7 sin mediciones: FAIL 9" "$TMP/A.out" '^FAIL +9 '
no_espera "A8 --rapido no pisa resultados/" "$TMP/A.out" 'sobrescribió'
if [ -z "$(cd "$A" && git status --porcelain)" ]; then ok "A9 el verificador no modifica el repositorio revisado"; else bad "A9 el repositorio revisado cambió"; fi

# ======================= B. entrega completa (estructura plantilla-repo) =======================
B="$TMP/B"; cp -a "$PLANTILLA" "$B"
(
cd "$B" || exit 1
# El equipo sustituye el marcador de posición (elemento() en la cabecera, que también usa el kernel)
# y agrega dos casos propios.
sed -i 's/y = sin(y) + cos(0.5 \* y) \* 0.25;/y = sin(y) * 0.5 + cos(y) * 0.25;/' comun/problema.h
python3 - << 'EOF'
p = "tests/run_tests.sh"
s = open(p, encoding="utf-8").read()
marca = '    # compara_v2 "descripción" <n> <semilla> <hilos>\n'
s = s.replace(marca, marca +
    "    # n primo: ningún número de hilos lo divide; prueba el reparto del último bloque.\n"
    '    compara_v2 "v2 == v1 con n=7919 y 4 hilos" 7919 3 4\n'
    "    # Más hilos que elementos: hay hilos sin trabajo.\n"
    '    compara_v2 "v2 == v1 con n=3 y 8 hilos" 3 2 8\n')
open(p, "w", encoding="utf-8").write(s)
EOF
sed -i 's/«[^»]*»/dato del equipo/g' README.md
python3 herramientas/generar_notebook_v3.py --fuente v3/kernel.cu --cabecera comun/problema.h \
    --v1 v1/main.c --salida v3/notebook_colab.ipynb --equipo 99 > /dev/null
python3 - << 'EOF'
# Salidas sintéticas en el notebook (como si se hubiera ejecutado en Colab).
import nbformat
from nbformat.v4 import new_output
nb = nbformat.read("v3/notebook_colab.ipynb", as_version=4)
textos = {"# 1.": "| NVIDIA-SMI 535.104.05   Driver Version: 535.104.05   CUDA Version: 12.2 |\n| Tesla T4 |\n",
          "%%writefile": "Writing archivo\n",
          "# 3.": "-rwxr-xr-x 1 root root 16696 v1\n",
          "# 4.": "v1 checksum = 1.0e+06\nv3 checksum = 1.0e+06 | gpu = Tesla T4\nPASS v3 == v1\n",
          "# 5.": "v1         mediana=1.800000 s  speedup_vs_v1=1.000\n"}
for i, c in enumerate(c for c in nb.cells if c.cell_type == "code"):
    for inicio, texto in textos.items():
        if c.source.startswith(inicio):
            c.outputs = [new_output("stream", name="stdout", text=texto)]
            c.execution_count = i + 1
nbformat.write(nb, "v3/notebook_colab.ipynb")
EOF
cat > resultados/mediciones.csv << 'EOF'
config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia
v1,1,4000000,1.300000,1.310000,1.290000,1.320000,1.300000,1.300000,1.000,1.000
v2,1,4000000,1.310000,1.300000,1.320000,1.330000,1.310000,1.310000,0.992,0.992
v2,2,4000000,0.660000,0.670000,0.650000,0.680000,0.660000,0.660000,1.970,0.985
v2,4,4000000,0.340000,0.350000,0.330000,0.360000,0.340000,0.340000,3.824,0.956
v2,8,4000000,0.330000,0.340000,0.330000,0.350000,0.330000,0.330000,3.939,0.492
EOF
cat > resultados/entorno.txt << 'EOF'
fecha_utc=2026-11-28T18:00:00Z
cpu_modelo=CPU sintética de prueba
nucleos_logicos=4
nucleos_fisicos=4
ram_total=16.0 GiB
compilador=gcc 13.3.0
banderas_v1=-std=c11 -O2 -Wall -Wextra
banderas_v2=-std=c11 -O2 -Wall -Wextra -fopenmp
n=4000000
modo_rapido=0
EOF
cat > resultados/mediciones_v3.csv << 'EOF'
config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia
v1,1,4000000,1.800000,1.810000,1.790000,1.820000,1.800000,1.800000,1.000,
v3_kernel,0,4000000,0.010000,0.011000,0.010000,0.012000,0.010000,0.010000,180.000,
v3_total,0,4000000,0.050000,0.051000,0.050000,0.052000,0.050000,0.050000,36.000,
EOF
printf 'name, driver_version, memory.total [MiB], compute_cap\nTesla T4, 535.104.05, 15360 MiB, 7.5\nfecha_utc=2026-11-30T17:00:00Z\n' > resultados/entorno_gpu.txt
python3 herramientas/resumen_csv.py resultados/mediciones.csv --v3 resultados/mediciones_v3.csv \
    --png resultados/speedup.png --md resultados/tabla.md > /dev/null
pdf_de 9 reporte/reporte.pdf
python3 - << 'EOF'
# Bitácora con 5 errores, 1 medición descartada y 1 predicción.
lineas, seccion, hechas, salida = open("bitacora.md", encoding="utf-8").read().splitlines(), "", set(), []
filas = {"error": [f"| 2026-11-{d:02d} | V2 | síntoma | prueba | causa | cambio (abc{d}) | aprendizaje | propio |" for d in (2, 5, 9, 12, 16)],
         "descart": ["| 2026-11-17 | V2, 8 hilos, n=4000000, laptop | ruido | sobre-suscripción | se marcó aparte |"],
         "predic": ["| 2026-11-10 | S(4) ≈ 3.2 | f ≈ 8 % | 3.8 | sección 9.5 |"]}
for l in lineas:
    if l.startswith("## "):
        seccion = next((k for k in filas if k in l.lower()), "")
    if l.startswith("| AAAA-MM-DD") and seccion in filas:
        if seccion not in hechas:
            salida += filas[seccion]
            hechas.add(seccion)
        continue
    salida.append(l)
open("bitacora.md", "w", encoding="utf-8").write("\n".join(salida) + "\n")
EOF
historial_dos_integrantes
) > "$TMP/B.prep" 2>&1 || { bad "B preparación del repositorio de prueba"; cat "$TMP/B.prep"; }
bash "$VERIF" "$B" --sin-red > "$TMP/B.out" 2>&1; cB=$?
codigo_es "B1 entrega completa (plantilla-repo) pasa" 0 "$cB"
no_espera "B2 ningún FAIL" "$TMP/B.out" '^FAIL'
espera "B3 cuenta los 2 casos del equipo" "$TMP/B.out" "^PASS +5 .*tiene 2 líneas"
espera "B4 T(1) >= 1 s" "$TMP/B.out" '^PASS +11 '
espera "B5 CSV de GPU" "$TMP/B.out" '^PASS +12 .*mediciones_v3.csv'
espera "B6 notebook ejecutado y al día" "$TMP/B.out" '^PASS +16 .*coinciden'
espera "B7 PASS v3 == v1" "$TMP/B.out" '^PASS +17 '
espera "B8 PDF de 9 páginas" "$TMP/B.out" '^PASS +18 .*9 páginas'
espera "B9 bitácora con 5 errores" "$TMP/B.out" '^PASS +19 .*5 entradas'
espera "B10 declaración de IA llena" "$TMP/B.out" '^PASS +20 '
espera "B11 dos autores" "$TMP/B.out" '^PASS +21 .*2 autores'
espera "B12 etiqueta en HEAD" "$TMP/B.out" '^PASS +24 '
no_espera "B13 sin avisos de C6 por integrante" "$TMP/B.out" '^AVISO +21 '
espera "B14 detalle de C6 por autor (commits y semanas)" "$TMP/B.out" '^ +a@ejemplo\.mx: 3 commit\(s\) en 3 semana\(s\)'

# ======================= C. entrega completa (estructura src/) =======================
C="$TMP/C"; mkdir -p "$C"
(
cd "$C" || exit 1
mkdir -p src/v1/tests src/v2 src/v3 resultados reporte
cat > src/v1/main.c << 'EOF'
/* Programa de prueba del verificador: suma de sin(i·1e-3). Uso: ./prog [n] */
#define _POSIX_C_SOURCE 200809L
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(int argc, char **argv) {
    long n = argc > 1 ? atol(argv[1]) : 1000000;
    if (n <= 0) {
        fprintf(stderr, "error: n inválido\n");
        return 2;
    }
    struct timespec a, b;
    double s = 0.0;
    clock_gettime(CLOCK_MONOTONIC, &a);
#ifdef _OPENMP
#pragma omp parallel for reduction(+ : s)
#endif
    for (long i = 0; i < n; ++i) {
        s += sin((double)i * 1e-3);
    }
    clock_gettime(CLOCK_MONOTONIC, &b);
    printf("tiempo_s=%.6f\nchecksum=%.12e\n",
           (double)(b.tv_sec - a.tv_sec) + 1e-9 * (double)(b.tv_nsec - a.tv_nsec), s);
    return 0;
}
EOF
cp src/v1/main.c src/v2/main.c
printf 'all: prog\nprog: main.c\n\tgcc -std=c11 -O2 -Wall -Wextra -o prog main.c -lm\nrun: prog\n\t./prog\ntest: prog\n\t./prog 1000 > /dev/null\nclean:\n\trm -f prog\n' > src/v1/Makefile
printf 'all: prog\nprog: main.c\n\tgcc -std=c11 -O2 -Wall -Wextra -fopenmp -o prog main.c -lm\nrun: prog\n\t./prog\ntest: prog\n\t./prog 1000 > /dev/null\nclean:\n\trm -f prog\n' > src/v2/Makefile
printf 'all:\n\t$(MAKE) -C src/v1 all\n\t$(MAKE) -C src/v2 all\nrun: all\n\t./src/v1/prog\ntest: all\n\tbash src/v1/tests/run_tests.sh\nclean:\n\t$(MAKE) -C src/v1 clean\n\t$(MAKE) -C src/v2 clean\n\trm -rf resultados/rapido\n' > Makefile
cat > src/v1/tests/run_tests.sh << 'EOF'
#!/usr/bin/env bash
# Compara el checksum de V2 (4 hilos) contra V1 con tolerancia relativa 1e-9.
cd "$(dirname "$0")/../../.." || exit 2
c1=$(./src/v1/prog 100000 | sed -n 's/^checksum=//p')
c2=$(OMP_NUM_THREADS=4 ./src/v2/prog 100000 | sed -n 's/^checksum=//p')
if awk -v a="$c1" -v b="$c2" 'BEGIN { d = a - b; if (d < 0) d = -d; m = (a < 0 ? -a : a); exit !(d <= 1e-9 * (m < 1 ? 1 : m)) }'; then
    echo "PASS  v2 == v1"; exit 0
fi
echo "FAIL  v2 != v1"; exit 1
EOF
cat > run_all.sh << 'EOF'
#!/usr/bin/env bash
# run_all.sh de prueba: --rapido escribe en resultados/rapido/.
set -eu
cd "$(dirname "$0")"
OUT=resultados; N=20000000
if [ "${1:-}" = "--rapido" ]; then OUT=resultados/rapido; N=100000; fi
mkdir -p "$OUT"
make all > /dev/null
make test > /dev/null
./src/v1/prog "$N" > "$OUT/v1.txt"
OMP_NUM_THREADS=2 ./src/v2/prog "$N" > "$OUT/v2.txt"
EOF
chmod +x run_all.sh src/v1/tests/run_tests.sh
cat > resultados/mediciones.csv << 'EOF'
config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia,min_s,max_s
V1,1,20000000,1.200000,1.210000,1.190000,1.220000,1.200000,1.200000,1.000,1.000,1.190000,1.220000
V2,1,20000000,1.210000,1.200000,1.220000,1.230000,1.210000,1.210000,0.992,0.992,1.200000,1.230000
V2,2,20000000,0.610000,0.620000,0.600000,0.630000,0.610000,0.610000,1.967,0.984,0.600000,0.630000
V2,4,20000000,0.320000,0.330000,0.310000,0.340000,0.320000,0.320000,3.750,0.938,0.310000,0.340000
EOF
cat > resultados/mediciones-colab.csv << 'EOF'
config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia,min_s,max_s
V1,1,20000000,1.800000,1.810000,1.790000,1.820000,1.800000,1.800000,1.000,1.000,1.790000,1.820000
V3,gpu,20000000,0.050000,0.051000,0.050000,0.052000,0.050000,0.050000,36.000,NA,0.050000,0.052000
V3-kernel,gpu,20000000,0.010000,0.011000,0.010000,0.012000,0.010000,0.010000,180.000,NA,0.010000,0.012000
EOF
printf 'fecha: 2026-11-20 10:00:00 -0600\nModel name: CPU sintética de prueba\nCPU(s): 4\nCore(s) per socket: 4\nMemTotal: 16000000 kB\ncompilador: gcc 13.3.0\nbanderas: -O2\n' > resultados/entorno.txt
printf 'fecha: 2026-11-30 11:00:00 -0600\ngpu: Tesla T4, 535.104.05, 15360 MiB\n' > resultados/entorno-colab.txt
python3 "$PLANTILLA/herramientas/resumen_csv.py" resultados/mediciones.csv --v3 resultados/mediciones-colab.csv \
    --png resultados/speedup.png > /dev/null
python3 - << 'EOF'
import nbformat
from nbformat.v4 import new_code_cell, new_notebook, new_output
nb = new_notebook(cells=[
    new_code_cell("!nvidia-smi", outputs=[new_output("stream", name="stdout", text="| NVIDIA-SMI 535.104.05 |\n")]),
    new_code_cell("!bash tests_v3.sh", outputs=[new_output("stream", name="stdout", text="PASS v3 == v1\n")]),
])
nbformat.write(nb, "src/v3/notebook_colab.ipynb")
EOF
pdf_de 10 reporte/reporte.pdf
cat > README.md << 'EOF'
# cp-6bm1-equipo98 · prueba del verificador
Cómo compilar: make. Reproducir: ./run_all.sh. Semilla: no aplica (datos deterministas).
Hardware y entorno: resultados/entorno.txt. Integrantes y reparto: integrante-a (V1, V2), integrante-b (V3).
Uso de IA: ver declaracion-ia.md.
EOF
cat > bitacora-errores.md << 'EOF'
# Bitácora de errores · Equipo 98
## Entradas
| # | Fecha | Versión | Síntoma | Detección | Causa | Cambio | Aprendizaje | Origen | Commit |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 2026-10-27 | V1 | a | b | c | d | e | propio | abc1 |
| 2 | 2026-11-05 | V2 | a | b | c | d | e | IA | abc2 |
| 3 | 2026-11-19 | V3 | a | b | c | d | e | propio | abc3 |
## Mediciones descartadas
| Fecha | Configuración | Qué se observó | Por qué | Después |
|---|---|---|---|---|
| 2026-11-18 | V2 8 hilos | ruido | sobre-suscripción | aparte |
EOF
cat > declaracion-ia.md << 'EOF'
# Declaración de uso de IA · Equipo 98
## H1
- Qué nos dijo la IA que resultó estar mal:
## Entrega final (lunes 7 de diciembre de 2026, 10:30)
Uso de IA en esta entrega:
- Herramienta(s): asistente de chat
- Para qué la usamos (verde/amarillo): explicar un error de nvcc (verde)
- Qué fragmento(s) de código vinieron de la IA (archivo y líneas) y cómo los verificamos: ninguno
- Qué nos dijo la IA que resultó estar mal: que __syncthreads() sincroniza toda la GPU; la guía de CUDA dice que solo el bloque
EOF
printf 'src/v1/prog\nsrc/v2/prog\nresultados/rapido/\n' > .gitignore
historial_dos_integrantes
) > "$TMP/C.prep" 2>&1 || { bad "C preparación del repositorio de prueba"; cat "$TMP/C.prep"; }
bash "$VERIF" "$C" --sin-red > "$TMP/C.out" 2>&1; cC=$?
codigo_es "C1 entrega completa (estructura src/) pasa" 0 "$cC"
no_espera "C2 ningún FAIL" "$TMP/C.out" '^FAIL'
espera "C3 encuentra src/v1 src/v2 src/v3" "$TMP/C.out" '^PASS +4 .*src/v1 src/v2 src/v3'
espera "C4 lee el CSV con V1/V2 y min_s,max_s" "$TMP/C.out" '^PASS +9 '
espera "C5 T(1) en la columna mediana_s" "$TMP/C.out" '^PASS +11 .*1\.2 s'
espera "C6 CSV de GPU con V3 y V3-kernel" "$TMP/C.out" '^PASS +12 .*mediciones-colab.csv'
espera "C7 entorno de GPU en otro archivo" "$TMP/C.out" '^PASS +14 .*entorno-colab.txt'
espera "C8 bitácora con la fecha en la 2.ª columna" "$TMP/C.out" '^PASS +19 .*bitacora-errores.md: 3 entradas'
espera "C9 declaración de IA de la sección final" "$TMP/C.out" '^PASS +20 .*declaracion-ia.md'
espera "C10 PDF de 10 páginas" "$TMP/C.out" '^PASS +18 .*10 páginas'

# ======================= D. --sin-ejecutar =======================
bash "$VERIF" "$B" --sin-ejecutar --sin-red > "$TMP/D.out" 2>&1; cD=$?
codigo_es "D1 --sin-ejecutar sobre B" 0 "$cD"
espera "D2 ítems 6–8 como MANUAL" "$TMP/D.out" '^MANUAL +8 '
LIMITE_EPOCH=1 bash "$VERIF" "$B" --sin-ejecutar --sin-red > "$TMP/D3.out" 2>&1
espera "D3 LIMITE_EPOCH: aviso de entrega tardía" "$TMP/D3.out" '^AVISO +24 .*posterior'
no_espera "D4 sin aviso de entrega tardía con la fecha límite real" "$TMP/D.out" '^AVISO +24 .*posterior'

# ======================= E. errores de uso =======================
bash "$VERIF" > /dev/null 2>&1; codigo_es "E1 sin argumentos" 2 $?
bash "$VERIF" "$TMP/no-existe" > /dev/null 2>&1; codigo_es "E2 carpeta inexistente" 2 $?
bash "$VERIF" "$B" --opcion-rara > /dev/null 2>&1; codigo_es "E3 opción desconocida" 2 $?

# ======================= F. notebook desactualizado =======================
(cd "$B" && echo "/* cambio posterior al notebook */" >> v3/kernel.cu \
    && commit_como integrante-a a@ejemplo.mx "2026-12-01T12:00:00-06:00" "Cambiar kernel") > /dev/null 2>&1
bash "$VERIF" "$B" --sin-ejecutar --sin-red > "$TMP/F.out" 2>&1; cF=$?
codigo_es "F1 notebook desactualizado no pasa" 1 "$cF"
espera "F2 FAIL 16 nombra kernel.cu" "$TMP/F.out" '^FAIL +16 .*kernel\.cu'
espera "F3 la etiqueta ya no está en HEAD" "$TMP/F.out" '^AVISO +24 .*apunta a'

# ======================= G. --rapido que pisa resultados/ =======================
(cd "$C" && sed -i 's#OUT=resultados/rapido#OUT=resultados#; s#"\$OUT/v1.txt"#"$OUT/mediciones.csv"#' run_all.sh \
    && commit_como integrante-b b@ejemplo.mx "2026-12-01T12:00:00-06:00" "Cambiar run_all") > /dev/null 2>&1
bash "$VERIF" "$C" --sin-red > "$TMP/G.out" 2>&1
espera "G1 AVISO cuando --rapido sobrescribe mediciones.csv" "$TMP/G.out" '^AVISO +8 .*sobrescribió'

# ======================= H. generar_notebook_v3.py con V3 en Python =======================
H="$TMP/H"; cp -a "$PLANTILLA" "$H"
printf 'print("version=v3")\n' > "$H/v3/main_gpu.py"
if (cd "$H" && python3 herramientas/generar_notebook_v3.py --fuente v3/main_gpu.py --v1 v1/main.c \
        --salida v3/nb_py.ipynb > /dev/null) \
   && grep -q '%%writefile problema.h' "$H/v3/nb_py.ipynb" && grep -q 'python3 main_gpu.py' "$H/v3/nb_py.ipynb"; then
    ok "H1 notebook de V3 en Python incluye la cabecera de la V1"
else
    bad "H1 notebook de V3 en Python"
fi
(cd "$H" && python3 herramientas/generar_notebook_v3.py --fuente v3/no-existe.cu --v1 v1/main.c \
    --salida v3/x.ipynb > /dev/null 2>&1); codigo_es "H2 fuente inexistente" 1 $?

echo "----"
echo "Resumen: $pass PASS, $fail FAIL"
[ "$fail" -eq 0 ]
