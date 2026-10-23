#!/usr/bin/env python3
"""make_notebook.py — Genera notebook_colab.ipynb (válido, con nbformat) para el mini PRIMM
"aplanar y mapear". Ejecuta `make notebook` o `python3 make_notebook.py` desde esta carpeta.

Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · Unidad V · Sesión S05 (martes 1 de diciembre de 2026)
"""
import os

import nbformat
from nbformat.v4 import new_code_cell, new_markdown_cell, new_notebook

HERE = os.path.dirname(os.path.abspath(__file__))


def read(name):
    with open(os.path.join(HERE, name), encoding="utf-8") as f:
        return f.read()


cells = []
md = lambda s: cells.append(new_markdown_cell(s))
code = lambda s: cells.append(new_code_cell(s))

md("""# S05 · Mini PRIMM "aplanar y mapear" · Jacobi 2D en una malla aplanada

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S05 · martes 1 de diciembre de 2026 · 08:30–10:00 · Lab LS4

Antes de correr: **Entorno de ejecución → Cambiar tipo de entorno → GPU (T4)**. En Kaggle con P100 cambia `-arch=sm_75` por `-arch=sm_60`.
Anota la fecha y la GPU que te asignaron (celda siguiente): el hardware de Colab cambia y el protocolo exige declararlo.

Sigue el `README.md` de la práctica guiada: **escribe tu predicción antes de ejecutar** la celda de la fase Ejecutar.""")

code("!nvidia-smi\n!nvcc --version | tail -1\n!date")

md("## Código\nLas tres celdas siguientes escriben los archivos en el disco de Colab. Si modificas el kernel (fase Modificar), edita la celda y vuelve a ejecutarla **y** la celda de compilación.")

code("%%writefile flatten_map_2d.cu\n" + read("flatten_map_2d.cu"))
code("%%writefile flatten_map_cpu.c\n" + read("flatten_map_cpu.c"))
code("%%writefile flatten_map_numba.py\n" + read("flatten_map_numba.py"))

md("## Compilar")
code("!nvcc -O2 -arch=sm_75 flatten_map_2d.cu -o flatten_map_2d && echo 'flatten_map_2d listo'\n"
     "!gcc -std=c11 -O2 -Wall -Wextra flatten_map_cpu.c -o flatten_map_cpu && echo 'flatten_map_cpu listo'")

md("""## Ejecutar (PRIMM · R)
Malla de 10 filas × 8 columnas, 3 iteraciones, bloques de 16×16. Compara con tu predicción: índice lineal de (fila 3, col 5) y `blockIdx`/`threadIdx` del hilo que la procesa.""")
code("!CPU_REPS=1 ./flatten_map_2d 10 8 3 16 16 2d 0 3 5")

md("""## Investigar (PRIMM · I) · dimensiones que no son múltiplos del bloque
37 × 45 con bloques de 16 × 16. Antes de ejecutar: ¿cuántos bloques en x y en y? ¿cuántos hilos se lanzan? ¿cuántos sobran?""")
code("!CPU_REPS=1 ./flatten_map_2d 37 45 3 16 16 2d 0 3 5")

md("""### Experimento incorrecto a propósito: sin guardia de rango
`-DSIN_GUARDIA` quita la línea `if (r >= height || c >= width) return;`. Los hilos sobrantes escriben fuera del arreglo.
Puede pasar cualquiera de estas tres cosas (es comportamiento indefinido): la verificación falla sin ningún error de CUDA,
aparece `illegal memory access`, o "sale bien" por casualidad. Ninguna de las tres es aceptable en tu V3.""")
code("!nvcc -O2 -arch=sm_75 -DSIN_GUARDIA flatten_map_2d.cu -o sin_guardia && CPU_REPS=1 ./sin_guardia 37 45 3 16 16 2d 0 3 5; echo \"codigo de salida: $?\"")

md("""## Medir (protocolo del curso)
Cada corrida del programa ya hace 1 calentamiento + 5 repeticiones y reporta la **mediana** del tiempo solo de kernels
(`cudaEvent`) y del tiempo total con transferencias H2D/D2H. El barrido cubre: tamaño de bloque, con/sin transferencias,
y el error típico de copiar en cada iteración. Tarda 1–2 minutos en una T4.""")
code('''import subprocess, csv, datetime

H, W, ITERS = 1024, 1024, 100
configs = [
    # (bloque_x, bloque_y, modo, copiar_cada_iter)
    (32, 1, "2d", 0), (8, 8, "2d", 0), (16, 16, "2d", 0), (32, 8, "2d", 0),
    (32, 32, "2d", 0), (64, 16, "2d", 0),
    (16, 16, "2d", 1),          # copiar en cada iteración (porte incorrecto)
    (16, 16, "1d", 0),          # mapeo 1D: aparece como TODO hasta que completes TODO(1)
]
header, rows = None, []
for bx, by, mode, copy_each in configs:
    cmd = ["./flatten_map_2d", str(H), str(W), str(ITERS), str(bx), str(by), mode, str(copy_each), "3", "5"]
    out = subprocess.run(cmd, capture_output=True, text=True).stdout
    lines = [l for l in out.splitlines() if l.startswith("CSV,")]
    if len(lines) < 2:
        print("sin CSV para", cmd, "\\n", out); continue
    header = lines[0].split(",")[1:]
    rows.append(lines[1].split(",")[1:])
    print(" | ".join(f"{k}={v}" for k, v in zip(header, rows[-1]) if k in
          ("modo","bloque_x","bloque_y","copiar_cada_iter","t_kernel_s","t_total_s","speedup_kernel","speedup_total","verificacion")))
''')

md("### T(1): la referencia secuencial con el protocolo completo (5 repeticiones, mediana, mín y máx)")
code("!./flatten_map_cpu 1024 1024 100")

md("""## Modificar (PRIMM · M) · mapeo 1D
Completa `TODO(1)` en `jacobi_step_1d` (celda `%%writefile flatten_map_2d.cu`), vuelve a compilar y ejecuta.
Predicción antes de correr: con bloques de 256 hilos, ¿qué `blockIdx.x` y `threadIdx.x` procesan (3,5) en la malla de ancho 8?""")
code("!CPU_REPS=1 ./flatten_map_2d 10 8 3 16 16 1d 0 3 5")

md("""## Opcional · el mismo kernel en Numba CUDA (para equipos que harán la V3 en Python)
La primera corrida incluye la compilación JIT (por eso el calentamiento no se cuenta).""")
code("!python3 flatten_map_numba.py 1024 1024 100 16 16 2d")

md("## Gráfica: tiempo solo de kernels vs. tiempo con transferencias por configuración")
code('''import matplotlib.pyplot as plt

ok_rows = [r for r in rows if r[-1] == "PASS"]
labels = [f"{r[0]} {r[1]}x{r[2]}" + (" copia/iter" if r[6] == "1" else "") for r in ok_rows]
t_kernel = [float(r[8]) * 1e3 for r in ok_rows]
t_total  = [float(r[9]) * 1e3 for r in ok_rows]
x = range(len(ok_rows))
plt.figure(figsize=(9, 4))
plt.bar([i - 0.2 for i in x], t_kernel, width=0.4, label="solo kernels")
plt.bar([i + 0.2 for i in x], t_total,  width=0.4, label="con transferencias H2D/D2H")
plt.xticks(list(x), labels, rotation=30, ha="right")
plt.ylabel("mediana de 5 (ms)"); plt.yscale("log")
plt.title(f"Jacobi 2D {H}x{W}, {ITERS} iteraciones")
plt.legend(); plt.grid(axis="y", alpha=0.3); plt.tight_layout(); plt.show()
''')

md("""## Guardar resultados (CSV)
El archivo lleva la fecha y la GPU. Súbelo a `resultados/` de tu repositorio si lo usas en el reporte.""")
code('''gpu = subprocess.run(["nvidia-smi", "--query-gpu=name", "--format=csv,noheader"], capture_output=True, text=True).stdout.strip().replace(" ", "_")
fecha = datetime.date.today().isoformat()
nombre = f"resultados_S05_{fecha}_{gpu or 'gpu'}.csv"
with open(nombre, "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["fecha", "gpu"] + header)
    for r in rows:
        w.writerow([fecha, gpu] + r)
print("guardado:", nombre)
try:
    from google.colab import files
    files.download(nombre)
except Exception:
    print("descarga manual desde el panel de archivos (no estás en Colab o el navegador bloqueó la descarga)")
''')

nb = new_notebook(cells=cells)
nb.metadata = {
    "kernelspec": {"name": "python3", "display_name": "Python 3", "language": "python"},
    "language_info": {"name": "python"},
    "colab": {"provenance": [], "gpuType": "T4"},
    "accelerator": "GPU",
}
nbformat.validate(nb)
out_path = os.path.join(HERE, "notebook_colab.ipynb")
with open(out_path, "w", encoding="utf-8") as f:
    nbformat.write(nb, f)
print(f"notebook válido escrito en {os.path.basename(out_path)} ({len(cells)} celdas)")
