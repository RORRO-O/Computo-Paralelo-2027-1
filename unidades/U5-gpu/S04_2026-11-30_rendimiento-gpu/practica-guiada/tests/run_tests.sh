#!/usr/bin/env bash
# Pruebas de la práctica guiada S04 SIN GPU (terminan en menos de 60 s):
#  1. cada .cu compila con nvcc -c para sm_75 (T4) y sm_60 (P100) sin errores ni warnings
#  2. la referencia CPU compila con -Wall -Wextra -Werror, pasa su autoverificación y genera el CSV de ejemplo
#  3. el espejo Numba de los kernels pasa en el simulador (NUMBA_ENABLE_CUDASIM=1)
#  4. graficar.py produce las dos PNG a partir del CSV de ejemplo
#  5. notebook_colab.ipynb es un notebook válido (nbformat) con las celdas obligatorias y sus %%writefile
#     reproducen exactamente los fuentes de la carpeta
# Imprime PASS/FAIL por caso; código de salida 0 solo si todo pasa.
set -u
cd "$(dirname "$0")/.." || exit 1
OUT=tests/out
rm -rf "$OUT" && mkdir -p "$OUT"
pass=0
fail=0

check() {  # check <nombre> <código>
    if [ "$2" -eq 0 ]; then
        echo "PASS  $1"; pass=$((pass + 1))
    else
        echo "FAIL  $1   (ver $OUT)"; fail=$((fail + 1))
    fi
}

# 1. Compilación CUDA (objeto) para dos arquitecturas; un warning cuenta como falla.
for src in medir_eventos bench_gpu pinned_streams; do
    for arch in sm_75 sm_60; do
        log="$OUT/nvcc_${src}_${arch}.log"
        nvcc -c -arch=$arch "$src.cu" -o "$OUT/${src}_${arch}.o" >"$log" 2>&1
        rc=$?
        if [ $rc -eq 0 ] && grep -qi "warning" "$log"; then rc=2; fi
        check "nvcc -c -arch=$arch $src.cu" $rc
    done
done

# 2. Referencia CPU.
gcc -std=c11 -O2 -Wall -Wextra -Werror bench_cpu.c -o "$OUT/bench_cpu" -lm >"$OUT/gcc.log" 2>&1
check "gcc -std=c11 -O2 -Wall -Wextra -Werror bench_cpu.c" $?
"$OUT/bench_cpu" --test >"$OUT/bench_cpu_test.log" 2>&1
check "bench_cpu --test (vector_add, saxpy y mediana correctos)" $?
"$OUT/bench_cpu" --csv-ejemplo "$OUT/resultados_ejemplo.csv" 16 >"$OUT/bench_cpu_csv.log" 2>&1
check "bench_cpu --csv-ejemplo (genera el CSV)" $?
python3 - "$OUT/resultados_ejemplo.csv" >"$OUT/csv_check.log" 2>&1 <<'PY'
import csv, sys
rows = list(csv.DictReader(open(sys.argv[1], newline="")))
expected = ["experimento", "kernel", "n", "block", "grid", "ocupacion_pct", "memoria", "t_h2d_ms", "t_kernel_ms",
            "t_d2h_ms", "t_total_ms", "t_cpu_ms", "speedup_kernel", "speedup_total", "ancho_banda_gbs", "origen",
            "dispositivo"]
assert list(rows[0].keys()) == expected, rows[0].keys()
bloque = [r for r in rows if r["experimento"] == "bloque"]
umbral = [r for r in rows if r["experimento"] == "umbral"]
assert len(bloque) == 2 * 2 * 6, len(bloque)       # 2 tamaños x 2 kernels x 6 bloques
assert len(umbral) == 4 * 2 * 2, len(umbral)       # n = 2^10..2^16 (4 valores) x 2 kernels x 2 memorias
assert all(r["origen"] == "modelo" for r in rows)
assert all(float(r["t_cpu_ms"]) > 0 for r in rows)
print("CSV OK:", len(rows), "filas")
PY
check "CSV de ejemplo: esquema y número de filas" $?

# 3. Espejo Numba en el simulador.
NUMBA_ENABLE_CUDASIM=1 python3 bench_numba.py --n 1000 >"$OUT/numba_sim.log" 2>&1
check "bench_numba.py en CUDASIM (6 bloques x 2 kernels contra NumPy)" $?

# 4. Gráficas.
MPLBACKEND=Agg python3 graficar.py "$OUT/resultados_ejemplo.csv" "$OUT" >"$OUT/graficar.log" 2>&1
check "graficar.py sobre el CSV de ejemplo" $?
[ -s "$OUT/tiempo_vs_bloque.png" ] && [ -s "$OUT/speedup_vs_n.png" ]
check "graficar.py: existen tiempo_vs_bloque.png y speedup_vs_n.png" $?

# 5. Notebook.
python3 - >"$OUT/notebook_check.log" 2>&1 <<'PY'
import nbformat
nb = nbformat.read("notebook_colab.ipynb", as_version=4)
nbformat.validate(nb)
src = "\n".join(c.source for c in nb.cells if c.cell_type == "code")
for needle in ("!nvidia-smi", "%%writefile medir_eventos.cu", "%%writefile bench_gpu.cu",
               "%%writefile pinned_streams.cu", "%%writefile graficar.py", "nvcc -O2 -arch=sm_75",
               "./medir_eventos", "./bench_gpu bloque", "./bench_gpu umbral", "./pinned_streams",
               "nsys profile --stats=true", "graficar.py", "resultados"):
    assert needle in src, needle
print("notebook OK:", len(nb.cells), "celdas")
PY
check "notebook_colab.ipynb válido (nbformat) y con las celdas obligatorias" $?
python3 - >"$OUT/notebook_sync.log" 2>&1 <<'PY'
import nbformat
nb = nbformat.read("notebook_colab.ipynb", as_version=4)
seen = set()
for c in nb.cells:
    if c.cell_type == "code" and c.source.startswith("%%writefile"):
        first, body = c.source.split("\n", 1)
        name = first.split()[1]
        with open(name, encoding="utf-8") as f:
            assert body == f.read().rstrip("\n"), f"{name}: la celda no reproduce el archivo (corre make notebook)"
        seen.add(name)
missing = {"medir_eventos.cu", "bench_gpu.cu", "pinned_streams.cu", "graficar.py", "bench_numba.py"} - seen
assert not missing, missing
print("celdas %%writefile idénticas a los fuentes:", sorted(seen))
PY
check "notebook: cada %%writefile reproduce exactamente su fuente" $?

echo "Resumen: $pass PASS, $fail FAIL"
if [ $fail -eq 0 ]; then
    rm -rf "$OUT"
    exit 0
fi
exit 1
