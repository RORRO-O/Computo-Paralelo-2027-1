#!/usr/bin/env python3
"""check_notebook.py — valida ../notebook_colab.ipynb con nbformat, comprueba que cada celda %%writefile
coincide byte a byte con su fuente (src/<nombre>, o graficar.py en la raíz de la práctica) y que están las
celdas obligatorias: nvidia-smi, nvcc -O2 -arch=sm_75, ejecución, medición y CSV. Sale con 1 si algo falla."""
import sys
from pathlib import Path

import nbformat

ROOT = Path(__file__).resolve().parent.parent
NB = ROOT / "notebook_colab.ipynb"
GRAFICAR = ROOT / "graficar.py"
if not GRAFICAR.exists():
    GRAFICAR = ROOT.parents[2] / "practicas" / "P6-gpu" / "graficar.py"
REQUIRED = ["nvidia-smi", "nvcc -O2 -arch=sm_75", "%%writefile a_vectores.cu", "%%writefile b_matmul_tiled.cu",
            "./a_vectores uno", "./a_vectores umbral", "./a_vectores bloque", "./b_matmul_tiled_t", "./c_histograma_cpu",
            "./c_jacobi_cpu", "graficar.py resultados_P6.csv", "to_csv", "entorno.txt"]

errors = []
if not NB.exists():
    sys.exit(f"falta {NB.name}: genera con `make notebook`")
nb = nbformat.read(NB, as_version=4)
try:
    nbformat.validate(nb)
except nbformat.ValidationError as exc:
    errors.append(f"notebook inválido: {exc}")

all_code = "\n".join(c.source for c in nb.cells if c.cell_type == "code")
for req in REQUIRED:
    if req not in all_code:
        errors.append(f"falta una celda con `{req}`")

n_writefile = 0
for cell in nb.cells:
    if cell.cell_type != "code" or not cell.source.startswith("%%writefile "):
        continue
    first, _, body = cell.source.partition("\n")
    name = first.split(maxsplit=1)[1].strip()
    src = GRAFICAR if name == "graficar.py" else ROOT / "src" / name
    if not src.exists():
        errors.append(f"%%writefile {name}: el archivo fuente no existe")
        continue
    if body != src.read_text(encoding="utf-8").rstrip("\n"):
        errors.append(f"%%writefile {name}: desincronizado con el fuente (corre `make notebook`)")
    n_writefile += 1
if n_writefile < 9:
    errors.append(f"solo {n_writefile} celdas %%writefile (se esperan >= 9)")

if errors:
    print("\n".join("ERROR  " + e for e in errors))
    sys.exit(1)
print(f"notebook OK: {len(nb.cells)} celdas, {n_writefile} archivos %%writefile sincronizados")
