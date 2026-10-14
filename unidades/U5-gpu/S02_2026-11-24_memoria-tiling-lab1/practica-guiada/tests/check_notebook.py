#!/usr/bin/env python3
"""check_notebook.py — valida ../notebook_colab.ipynb con nbformat y comprueba que cada celda
%%writefile coincide con el archivo fuente actual y que están las celdas obligatorias
(nvidia-smi, nvcc -O2 -arch=sm_75, ejecución, medición, CSV). Sale con 1 si algo falla."""
import sys
from pathlib import Path

import nbformat

ROOT = Path(__file__).resolve().parent.parent
NB = ROOT / "notebook_colab.ipynb"
REQUIRED = ["nvidia-smi", "nvcc -O2 -arch=sm_75", "./matmul_naive", "./matmul_tiled",
            "./transpose", "to_csv"]

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
    src = ROOT / name
    if not src.exists():
        errors.append(f"%%writefile {name}: el archivo no existe en practica-guiada/")
        continue
    if body != src.read_text(encoding="utf-8").rstrip("\n"):
        errors.append(f"%%writefile {name}: desincronizado con el fuente (corre `make notebook`)")
    n_writefile += 1
if n_writefile < 4:
    errors.append(f"solo {n_writefile} celdas %%writefile (se esperan >= 4)")

if errors:
    print("\n".join("ERROR  " + e for e in errors))
    sys.exit(1)
print(f"notebook OK: {len(nb.cells)} celdas, {n_writefile} archivos %%writefile sincronizados")
