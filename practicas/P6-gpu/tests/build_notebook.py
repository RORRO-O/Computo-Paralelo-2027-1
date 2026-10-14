#!/usr/bin/env python3
"""build_notebook.py — genera ../notebook_colab.ipynb (válido, con nbformat) a partir de los fuentes de src/.
Ejecutar con `make notebook` después de editar cualquier .cu/.c/.py: las celdas %%writefile deben coincidir
byte a byte con los archivos (tests/check_notebook.py lo verifica)."""
from pathlib import Path

import nbformat
from nbformat.v4 import new_code_cell, new_markdown_cell, new_notebook

SOLUCION = False  # True en docente/practicas/P6 (agrega la Parte C resuelta)

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
OUT = ROOT / "notebook_colab.ipynb"
GRAFICAR = ROOT / "graficar.py"
if not GRAFICAR.exists():  # carpeta docente: usa el graficar.py público
    GRAFICAR = ROOT.parents[2] / "practicas" / "P6-gpu" / "graficar.py"

SOURCES = ["common.cuh", "a_vectores.cu", "a_vectores_cpu.c", "a_vectores_numba.py",
           "b_matmul_tiled.cu", "b_matmul_cpu.c", "b_matmul_numba.py",
           "c_histograma_cpu.c", "c_jacobi_cpu.c"]
if SOLUCION:
    SOURCES += ["c_histograma.cu", "c_histograma_numba.py", "c_jacobi.cu"]

HEADER = ("> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Práctica 6 · publicada el lunes 23 de "
          "noviembre de 2026 · Lab 1 martes 24 de noviembre 08:30 · Lab 2 martes 1 de diciembre 08:30 · "
          "entrega domingo 6 de diciembre 23:59")


def md(text):
    return new_markdown_cell(text.strip("\n"))


def code(text):
    return new_code_cell(text.strip("\n"))


def writefile(name):
    path = GRAFICAR if name == "graficar.py" else SRC / name
    return new_code_cell(f"%%writefile {name}\n" + path.read_text(encoding="utf-8").rstrip("\n"))


cells = [
    md(f"""
# Práctica 6 · Aceleración en GPU con CUDA (Colab / Kaggle){" · SOLUCIÓN DE REFERENCIA" if SOLUCION else ""}

{HEADER}

**Antes de ejecutar nada, activa la GPU:**

- **Colab:** *Entorno de ejecución → Cambiar tipo de entorno de ejecución → Acelerador de hardware: GPU (T4)* → Guardar.
- **Kaggle:** panel derecho *Settings → Accelerator → GPU T4 x2* (o P100). Kaggle pide verificación telefónica para usar GPU.

La primera celda debe mostrar una tarjeta NVIDIA. Si no la muestra, nada de lo que sigue corre: no sigas. Si Colab y Kaggle
niegan GPU, trabaja la correctitud en tu laptop con `NUMBA_ENABLE_CUDASIM=1` (ver README, "Sin GPU") y reintenta después.

Protocolo del curso: **anota la GPU asignada y la fecha** (cambian entre sesiones); cada programa hace 1 calentamiento +
5 repeticiones y reporta la **mediana**; las copias anfitrión↔dispositivo se reportan **aparte** y también sumadas.
Los órdenes de magnitud del README son para una T4; los tuyos dependen de la GPU que te toque.

Sigue el `README.md` de la práctica: **predice por escrito antes de ejecutar cada celda.**
"""),
    code("!nvidia-smi\n!nvcc --version | tail -2\n!lscpu | grep -E 'Model name|^CPU\\(s\\)|Thread|MHz' ; free -h | head -2"),
    code("""
# Arquitectura para nvcc: T4 (Colab) -> sm_75; P100 (Kaggle) -> sm_60. Se detecta; si falla, queda sm_75.
import subprocess
ARCH = "sm_75"
try:
    cap = subprocess.check_output(["nvidia-smi", "--query-gpu=compute_cap", "--format=csv,noheader"], text=True).strip().splitlines()[0]
    ARCH = "sm_" + cap.replace(".", "")
except Exception as exc:  # sin GPU o nvidia-smi viejo
    print("No se pudo detectar la GPU:", exc)
print("ARCH =", ARCH)
"""),
    md("## 1 · Escribir los fuentes en el disco de la sesión\n\nCada celda `%%writefile` guarda un archivo. Son los mismos de `src/` (y `graficar.py`) del repositorio. "
       "Si editas uno aquí (por ejemplo, al completar los `TODO` de la Parte B), vuelve a ejecutar su celda y recompila."),
] + [writefile(name) for name in SOURCES + ["graficar.py"]] + [
    md("## 2 · Compilar\n\n`nvcc` compila el código de anfitrión con el compilador de C++ del sistema y el de dispositivo para la GPU. "
       "En una T4 cada línea equivale a `nvcc -O2 -arch=sm_75 archivo.cu -o archivo`. La Parte B se compila con tres tamaños de mosaico."),
    code("""
# En una T4 (Colab) esto equivale a:  !nvcc -O2 -arch=sm_75 a_vectores.cu -o a_vectores
!nvcc -O2 -arch={ARCH} a_vectores.cu -o a_vectores
!for t in 8 16 32; do nvcc -O2 -arch={ARCH} -DTILE=$t b_matmul_tiled.cu -o b_matmul_tiled_t$t; done
!gcc -std=c11 -O2 -Wall -Wextra a_vectores_cpu.c -o a_vectores_cpu -lm
!gcc -std=c11 -O2 -Wall -Wextra b_matmul_cpu.c -o b_matmul_cpu
!gcc -std=c11 -O2 -Wall -Wextra c_histograma_cpu.c -o c_histograma_cpu
!gcc -std=c11 -O2 -Wall -Wextra c_jacobi_cpu.c -o c_jacobi_cpu -lm
!ls -l a_vectores b_matmul_tiled_t* *_cpu
"""),
    md("## 3 · Parte A · Ejecutar\n\nPrimero `n = 1000`, el caso de tus predicciones (A.1): compara los *checksums* de la CPU, la GPU y el espejo Numba. "
       "Después el tamaño por defecto, `n = 2^24` (64 MB por vector)."),
    code("!./a_vectores_cpu 1000\n!./a_vectores uno 1000 256\n!python3 a_vectores_numba.py 1000 256"),
    code("!./a_vectores_cpu 16777216\n!./a_vectores uno 16777216 256"),
    md("## 4 · Parte A · Medir (A.4): umbral de tamaño y barrido de bloque\n\nTodo se acumula en `resultados_P6.csv` con el esquema del curso. "
       "`umbral` recorre `n = 2^10 … 2^26` con bloque 256; `bloque` recorre 32 … 1024 con `n = 2^24`. Tarda 1–2 minutos en una T4."),
    code("""
import os
if os.path.exists("resultados_P6.csv"):
    os.remove("resultados_P6.csv")
!./a_vectores umbral 256 resultados_P6.csv
!./a_vectores bloque 16777216 resultados_P6.csv
"""),
    md("## 5 · Parte B · Multiplicación por mosaicos\n\nLa versión ingenua y la CPU corren siempre. La de mosaicos imprime `TODO pendiente` hasta que completes "
       "`TODO(1)`–`TODO(4)` en la celda `%%writefile b_matmul_tiled.cu` (y `TODO_LISTO 1`), la vuelvas a ejecutar y recompiles la celda 2. "
       "Verifica primero la lógica sin GPU con `b_matmul_numba.py` (CUDASIM). Criterio: `OK` con `n = 512`, `1024` **y** `1000` (no múltiplo de 16)."),
    code("!./b_matmul_cpu 512 16\n!./b_matmul_tiled_t16 512 resultados_P6.csv\n!./b_matmul_tiled_t16 1000 resultados_P6.csv"),
    code("""
%%bash
# Barrido TILE x n para la Parte D (cada TILE es un tamaño de bloque: 64, 256 y 1024 hilos). ~1 min en T4.
for n in 512 1024 2048; do
  for t in 8 16 32; do ./b_matmul_tiled_t$t $n resultados_P6.csv | grep -E "matmul_(naive|tiled) |TODO"; done
done
"""),
    md("## 6 · Parte C · Diseño propio\n\nLas referencias CPU dan la salida que tu *kernel* debe reproducir (histograma/reducción: exacto; Jacobi: iteraciones exactas y "
       "malla con tolerancia). Escribe tu `.cu` en una celda `%%writefile c_<nombre>.cu`, compílalo y haz que agregue sus filas a `resultados_P6.csv` "
       "con `emit_row` de `common.cuh` (experimento `bloque`, una fila por tamaño de bloque)."),
    code("!./c_histograma_cpu 16777216 --volcar hist_cpu.txt\n!./c_jacobi_cpu 1024 1024 1e-3 500 10\n!./c_jacobi_cpu 64 64 1e-2 1000 10"),
]
if SOLUCION:
    cells += [
        md("### Solución de referencia de la Parte C (docente)\n\nOpción 1 (histograma/reducción) con barrido de bloque y opción 2 (Jacobi) con cuatro formas de bloque."),
        code("""
!nvcc -O2 -arch={ARCH} c_histograma.cu -o c_histograma
!nvcc -O2 -arch={ARCH} c_jacobi.cu -o c_jacobi
!for b in 32 64 128 256 512 1024; do ./c_histograma 16777216 $b resultados_P6.csv | grep -E "histograma_|reduccion_|Verif"; done
!python3 c_histograma_numba.py 16777216 256
!./c_jacobi 1024 1024 1e-3 500 10 32 8 resultados_P6.csv
!./c_jacobi 1024 1024 1e-3 500 10 16 16 resultados_P6.csv
!./c_jacobi 1024 1024 1e-3 500 10 32 32 resultados_P6.csv
!./c_jacobi 1024 1024 1e-3 500 10 256 1 resultados_P6.csv
"""),
    ]
else:
    cells += [
        code("""
# Plantilla para tu Parte C (descomenta y completa):
# %%writefile c_mi_kernel.cu
# ...
# !nvcc -O2 -arch={ARCH} c_mi_kernel.cu -o c_mi_kernel
# !for b in 32 64 128 256 512 1024; do ./c_mi_kernel <args> $b resultados_P6.csv; done
"""),
    ]
cells += [
    md("## 7 · Parte D · Gráficas e interpretación\n\n`graficar.py` lee el CSV y produce `tiempo_vs_bloque.png`, `speedup_vs_n.png` y `transferencias.png`, "
       "más la tabla en Markdown para `REPORTE.md`. Las tres preguntas de interpretación están en el README (D.3)."),
    code("""
!python3 graficar.py resultados_P6.csv -o resultados
from IPython.display import Image, display
for png in ("tiempo_vs_bloque.png", "speedup_vs_n.png", "transferencias.png"):
    display(Image(filename=f"resultados/{png}"))
"""),
    md("## 8 · Guardar resultados (CSV, PNG y entorno)\n\nSe agrega la fecha, se guarda `entorno.txt` con la GPU y la CPU de esta sesión y se descarga todo. "
       "Súbelo a `practicas/P6/resultados/` del repositorio de tu equipo. En Kaggle los archivos quedan en `/kaggle/working/` (panel *Output*)."),
    code("""
import datetime, shutil, subprocess
import pandas as pd
hoy = datetime.date.today().isoformat()
df = pd.read_csv("resultados_P6.csv")
df["fecha"] = hoy
df.to_csv(f"resultados/resultados_P6_{hoy}.csv", index=False)
with open("resultados/entorno.txt", "w") as f:
    f.write(f"fecha: {hoy}\\n")
    f.write(subprocess.run("nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv", shell=True, capture_output=True, text=True).stdout)
    f.write(subprocess.run("nvcc --version | tail -1; lscpu | grep -E 'Model name|^CPU\\\\(s\\\\)'", shell=True, capture_output=True, text=True).stdout)
print(open("resultados/entorno.txt").read())
print(df.groupby(["experimento", "kernel"]).size())
shutil.make_archive(f"resultados_P6_{hoy}", "zip", "resultados")
try:
    from google.colab import files  # solo existe en Colab
    files.download(f"resultados_P6_{hoy}.zip")
except ImportError:
    print("En Kaggle: descarga resultados_P6_*.zip desde el panel Output (/kaggle/working/).")
"""),
    md("""
## Qué te llevas

1. `resultados_P6_<fecha>.csv`, las tres PNG y `entorno.txt` (GPU, CPU, fecha): van en `resultados/` del repositorio.
2. La tabla Markdown que imprimió `graficar.py`: va en `REPORTE.md` con tu interpretación (D.3) y tu pre-mortem comparado.
3. La bitácora: cada `FALLA`, `TODO pendiente` o `invalid configuration argument` que viste aquí es una entrada.
"""),
]

nb = new_notebook(cells=cells)
nb.metadata.update({
    "accelerator": "GPU",
    "colab": {"gpuType": "T4", "provenance": [], "name": "P6_gpu_cuda.ipynb"},
    "kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
    "language_info": {"name": "python"},
})
nbformat.validate(nb)
nbformat.write(nb, OUT)
print(f"escrito {OUT} ({len(cells)} celdas, válido)")
