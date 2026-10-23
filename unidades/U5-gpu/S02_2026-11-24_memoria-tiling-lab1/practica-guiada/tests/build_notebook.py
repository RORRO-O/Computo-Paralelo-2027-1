#!/usr/bin/env python3
"""build_notebook.py — genera ../notebook_colab.ipynb (válido, con nbformat) a partir de los
fuentes de la práctica guiada. Ejecutar con `make notebook` después de editar cualquier .cu/.c/.py
para que las celdas %%writefile queden sincronizadas (tests/check_notebook.py lo verifica)."""
from pathlib import Path

import nbformat
from nbformat.v4 import new_code_cell, new_markdown_cell, new_notebook

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "notebook_colab.ipynb"
SOURCES = ["common.cuh", "matmul_naive.cu", "matmul_tiled.cu", "transpose.cu",
           "matmul_cpu.c", "matmul_numba.py"]


def md(text):
    return new_markdown_cell(text.strip("\n"))


def code(text):
    return new_code_cell(text.strip("\n"))


def writefile(name):
    text = (ROOT / name).read_text(encoding="utf-8").rstrip("\n")
    return new_code_cell(f"%%writefile {name}\n{text}")


cells = [
    md("""
# S02 · Jerarquía de memoria y *tiling* — práctica guiada (Colab/Kaggle)

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S02 · martes 24 de noviembre de 2026 · 08:30–10:00 · Lab LS4

**Antes de ejecutar:** en Colab, *Entorno de ejecución → Cambiar tipo de entorno → GPU (T4)*. En Kaggle, *Settings → Accelerator → GPU*.
Si la primera celda no muestra una GPU, no sigas: nada de lo que sigue correrá.

Protocolo de medición del curso: anota la **GPU asignada y la fecha** (cambian entre sesiones), cada programa hace 1 calentamiento + 5 repeticiones y reporta la **mediana**, y las copias anfitrión↔dispositivo se reportan aparte.
Los tiempos que aparecen en el README son órdenes de magnitud para una T4; los tuyos dependen de la GPU que te toque.
"""),
    code("!nvidia-smi\n!nvcc --version | tail -2"),
    md("## Paso 1 · Escribir los fuentes en el disco de la máquina virtual\n\nCada celda `%%writefile` crea un archivo. Son los mismos archivos de `practica-guiada/` del repositorio."),
] + [writefile(name) for name in SOURCES] + [
    md("## Paso 2 · Compilar\n\n`-arch=sm_75` es la arquitectura de la T4 (Turing). Si te asignan otra GPU, el PTX incluido se recompila al vuelo."),
    code("""
!nvcc -O2 -arch=sm_75 matmul_naive.cu -o matmul_naive
!nvcc -O2 -arch=sm_75 matmul_tiled.cu -o matmul_tiled
!nvcc -O2 -arch=sm_75 transpose.cu -o transpose
!gcc -std=c11 -O2 -Wall -Wextra matmul_cpu.c -o matmul_cpu
!ls -l matmul_naive matmul_tiled transpose matmul_cpu
"""),
    md("## Paso 3 · Ejecutar (fase **Ejecutar** de PRIMM)\n\nPrimero `n = 64`, el caso de tus predicciones: compara las lecturas del modelo y el *checksum* de la CPU con la GPU. Después `n = 512`."),
    code("!./matmul_cpu 64 16\n!./matmul_naive 64\n!./matmul_tiled 64"),
    code("!./matmul_naive 512\n!./matmul_tiled 512"),
    md("## Paso 4 · Investigar\n\n**4a.** `n` no múltiplo de `TILE`: ¿cuántas fases y cuántos bloques? ¿la verificación sigue en OK?"),
    code("!./matmul_tiled 100\n!./matmul_tiled 20\n!./matmul_tiled 1000"),
    md("**4b.** Dos programas que **no reportan ningún error de CUDA** y aun así están mal. Corre la versión sin la primera barrera tres veces: ¿sale lo mismo?"),
    code("""
!nvcc -O2 -arch=sm_75 -DSIN_SYNC1 matmul_tiled.cu -o matmul_tiled_sin_sync1
!for i in 1 2 3; do ./matmul_tiled_sin_sync1 512 | grep -E "verificacion|csv"; done
!nvcc -O2 -arch=sm_75 -DGRID_TRUNCADO matmul_tiled.cu -o matmul_tiled_grid_truncado
!./matmul_tiled_grid_truncado 100
"""),
    md("**4c.** El espejo en Numba corre también en la GPU real (sin `NUMBA_ENABLE_CUDASIM`). Misma lógica, mismo *checksum*."),
    code("!python3 matmul_numba.py --n 512 --tile 16 --reps 5"),
    md("## Paso 5 · Modificar: tamaño de mosaico y de bloque\n\nCompila `TILE` = 8, 16, 32 (y `BLOCK` = 8, 16, 32 para la ingenua). Después intenta `TILE = 64`: ¿compila? ¿corre? ¿quién lo detecta?"),
    code("""
%%bash
for t in 8 16 32; do
  nvcc -O2 -arch=sm_75 -DTILE=$t  matmul_tiled.cu -o matmul_tiled_t$t
  nvcc -O2 -arch=sm_75 -DBLOCK=$t matmul_naive.cu -o matmul_naive_b$t
done
nvcc -O2 -arch=sm_75 -DTILE=64 matmul_tiled.cu -o matmul_tiled_t64 && echo "TILE=64 compila"
./matmul_tiled_t64 512; echo "codigo de salida con TILE=64: $?"
"""),
    md("## Paso 6 · Medición con el protocolo del curso\n\nCada programa ya hace calentamiento + 5 repeticiones y reporta la mediana; aquí se recorren `n` y `TILE` y se recogen las líneas `csv,...`. Tarda 1–3 minutos en una T4."),
    code("""
import datetime, subprocess
import pandas as pd

rows = []
COLS = ["version", "n", "tile", "kernel_med_ms", "kernel_min_ms", "kernel_max_ms",
        "h2d_ms", "d2h_ms", "gflops_o_gbps", "max_err", "estado"]

def run(cmd):
    out = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    for line in out.stdout.splitlines():
        if line.startswith("csv,"):
            f = line.split(",")[1:]
            rows.append(dict(zip(COLS, [f[0], int(f[1]), int(f[2])] + [float(x) for x in f[3:10]] + [f[10]])))
    if out.returncode != 0:
        print("AVISO: código", out.returncode, "en", cmd, "|", out.stderr.strip()[-200:])

gpu = subprocess.run("nvidia-smi --query-gpu=name --format=csv,noheader", shell=True,
                     capture_output=True, text=True).stdout.strip()
for n in [256, 512, 1024, 2048]:
    for t in [8, 16, 32]:
        run(f"./matmul_naive_b{t} {n}")
        run(f"./matmul_tiled_t{t} {n}")
for n in [1024, 2048, 4096]:
    run(f"./transpose {n}")

df = pd.DataFrame(rows)
df["gpu"] = gpu
df["fecha"] = datetime.date.today().isoformat()
print("GPU:", gpu)
print(df[df.version.isin(["naive", "tiled"])]
        .pivot_table(index="n", columns=["version", "tile"], values="kernel_med_ms").round(3))
print(df[df.version.str.startswith("transpose")][["version", "n", "kernel_med_ms", "gflops_o_gbps", "estado"]])
"""),
    md("## Paso 7 · Crear: transposición coalescida con memoria compartida\n\nCompleta `TODO(1)` en `transpose.cu` (celda `%%writefile transpose.cu` arriba), cambia `TODO1_LISTO` a 1, vuelve a ejecutar esa celda y compila aquí. Criterio de listo: `OK` en `n = 1000` y `n = 1024`, y más GB/s que la ingenua en `n = 4096`."),
    code("!nvcc -O2 -arch=sm_75 transpose.cu -o transpose\n!./transpose 1000\n!./transpose 1024\n!./transpose 4096"),
    md("## Paso 8 · Guardar los resultados (CSV)\n\nEl archivo va a `resultados/` del repositorio de tu equipo (Práctica 6, Parte B/D) junto con la GPU y la fecha."),
    code("""
nombre = f"resultados_S02_matmul_{datetime.date.today().isoformat()}.csv"
df.to_csv(nombre, index=False)
print(nombre, "->", len(df), "filas")
print(df.head(8).to_string())
try:
    from google.colab import files
    files.download(nombre)
except Exception as exc:  # fuera de Colab (Kaggle): descarga manual desde el panel de archivos
    print("Descarga manual desde el panel de archivos:", type(exc).__name__)
"""),
    md("""
## Qué te llevas

1. La tabla `n × TILE` de tiempos (naive vs tiled) y la razón de GFLOP/s entre ambas para `n = 1024`.
2. Tu respuesta, con los números de arriba, a: *¿por qué TILE=32 no es 2× más rápido que TILE=16 si hace la mitad de lecturas globales?*
3. La salida de 4b: dos programas sin error de CUDA y con resultado incorrecto. Es tu evidencia para la bitácora de errores de la Práctica 6.
4. El CSV con GPU y fecha.
"""),
]

nb = new_notebook(cells=cells)
nb.metadata.update({
    "accelerator": "GPU",
    "colab": {"gpuType": "T4", "provenance": [], "name": "S02_memoria_tiling.ipynb"},
    "kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
    "language_info": {"name": "python"},
})
nbformat.validate(nb)
nbformat.write(nb, OUT)
print(f"escrito {OUT.relative_to(ROOT.parent)} ({len(cells)} celdas)")
