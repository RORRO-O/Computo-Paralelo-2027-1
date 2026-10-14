#!/usr/bin/env python3
"""make_notebook.py — Genera notebook_colab.ipynb (válido, con nbformat) para el cazador de errores de S06.
Ejecuta `make notebook` o `python3 make_notebook.py` desde esta carpeta.

Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · Unidad V · Sesión S06 (jueves 3 de diciembre de 2026)
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

md("""# S06 · Cazador de errores (PRIMM) · tres programas, un error cada uno

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S06 · jueves 3 de diciembre de 2026 · 10:30–12:00 · Salón 3208

Antes de correr: **Entorno de ejecución → Cambiar tipo de entorno → GPU (T4)**. En Kaggle con P100 cambia `-arch=sm_75` por `-arch=sm_60`.
Anota la GPU asignada y la fecha (celda siguiente): el hardware de Colab cambia y el protocolo exige declararlo.

Sigue el `README.md` de la práctica guiada. **Escribe tus predicciones (P1–P8) antes de ejecutar** la sección "Ejecutar".
El tercer programa (MPI) está al final: Colab no trae MPI, pero se puede instalar en un minuto.""")

code("!nvidia-smi\n!nvcc --version | tail -1\n!date")

md("""## Código
Las celdas siguientes escriben los archivos en el disco de Colab. Cuando corrijas un error (fase **Modificar**), edita la celda
`%%writefile` correspondiente, vuelve a ejecutarla **y** vuelve a ejecutar la celda de compilación.""")

code("%%writefile caza2_guard_buggy.cu\n" + read("caza2_guard_buggy.cu"))
code("%%writefile caza3_reduce_buggy.cu\n" + read("caza3_reduce_buggy.cu"))
code("%%writefile caza_cpu.c\n" + read("caza_cpu.c"))
code("%%writefile caza2_guard_numba.py\n" + read("caza2_guard_numba.py"))
code("%%writefile caza3_reduce_numba.py\n" + read("caza3_reduce_numba.py"))

md("## Compilar")
code("!nvcc -O2 -arch=sm_75 caza2_guard_buggy.cu -o caza2_guard_buggy && echo 'caza2 listo'\n"
     "!nvcc -O2 -arch=sm_75 caza3_reduce_buggy.cu -o caza3_reduce_buggy && echo 'caza3 listo'\n"
     "!gcc -std=c11 -O2 -Wall -Wextra caza_cpu.c -o caza_cpu && echo 'caza_cpu listo'")

md("""## Ejecutar (PRIMM · R)
Primero la referencia en CPU (los valores que deben salir), después cada programa con error. Compara con P1–P8 del README.
Fíjate en tres cosas por programa: `cudaGetLastError`, el resultado contra la CPU y el código de salida.""")
code("!./caza_cpu todo 1000")
code("!./caza2_guard_buggy 1000 256; echo \"codigo de salida: $?\"")
code("!./caza2_guard_buggy 1024 256; echo \"codigo de salida: $?\"")
code("!./caza3_reduce_buggy 1000; echo \"codigo de salida: $?\"")
code("# Cinco corridas seguidas: ¿sale lo mismo cada vez?\n"
     "!for i in 1 2 3 4 5; do ./caza3_reduce_buggy 1000 | grep -E 'suma_gpu|verificacion' | tr '\\n' ' '; echo; done")

md("""## Investigar (PRIMM · I)
El simulador de Numba corre el **mismo** kernel en la CPU, con cada hilo del bloque como un hilo de Python que solo se coordina
en `syncthreads()`. No tiene GPU y no mide nada útil, pero reproduce (o no) el error con otro orden de ejecución.
Preguntas del README, sección Investigar: ¿por qué la GPU y el simulador pueden dar números distintos para caza3 y ninguno de los dos "tiene razón"?""")
code("!NUMBA_ENABLE_CUDASIM=1 python3 caza2_guard_numba.py 1000 256; echo \"codigo de salida: $?\"")
code("!NUMBA_ENABLE_CUDASIM=1 python3 caza3_reduce_numba.py 1000; echo \"codigo de salida: $?\"")
code("# Bloque de 32 hilos (un solo warp): ¿cambia algo en la GPU? ¿y en el simulador? ¿Cuál de los dos está bien? (ninguno: es comportamiento indefinido)\n"
     "!for i in 1 2 3; do ./caza3_reduce_buggy 1000 32 | grep -E 'suma_gpu|verificacion' | tr '\\n' ' '; echo; done\n"
     "!NUMBA_ENABLE_CUDASIM=1 python3 caza3_reduce_numba.py 1000 32 | grep -E 'suma_gpu|verificacion'")

md("""## Modificar (PRIMM · M)
Corrige **una línea** en cada programa (en el `.cu` y en su espejo `_numba.py`): edita las celdas `%%writefile`, ejecútalas,
recompila y corre la celda de verificación. Es el equivalente de `make cazar` del repositorio: pasa solo cuando los dos están corregidos.""")
code('''import subprocess

def run(cmd):
    p = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return p.returncode, p.stdout + p.stderr

casos = [
    ("caza2 GPU     n=1000 b=256", "./caza2_guard_buggy 1000 256"),
    ("caza2 GPU     n=37   b=8",   "./caza2_guard_buggy 37 8"),
    ("caza2 CUDASIM n=1000 b=256", "NUMBA_ENABLE_CUDASIM=1 python3 caza2_guard_numba.py 1000 256"),
    ("caza3 GPU     n=1000 b=256", "./caza3_reduce_buggy 1000"),
    ("caza3 GPU     n=1000 b=256 (2a vez)", "./caza3_reduce_buggy 1000"),
    ("caza3 GPU     n=1000 b=64",  "./caza3_reduce_buggy 1000 64"),
    ("caza3 CUDASIM n=1000 b=256", "NUMBA_ENABLE_CUDASIM=1 python3 caza3_reduce_numba.py 1000"),
]
fallas = 0
for nombre, cmd in casos:
    rc, out = run(cmd)
    ok = rc == 0 and "verificacion=OK" in out
    fallas += 0 if ok else 1
    print(f"{'PASS' if ok else 'FAIL'}  {nombre}")
print("\\nbichos cazados: " + ("2/2 (CUDA)" if fallas == 0 else f"todavía no: {fallas} casos fallan"))
''')

md("""## Medir (protocolo del curso) — solo con los programas ya corregidos
Cada programa hace 1 calentamiento + 5 repeticiones con `cudaEvent` y reporta la **mediana** del tiempo **solo del kernel**
(estos programas no miden las transferencias: por eso el *speedup* de esta tabla es "de kernel", no el del programa; en tu V3
reportas los dos). `T(1)` es `caza_cpu` con `-O2` en la CPU de la máquina virtual de Colab.""")
code('''import re, subprocess, datetime

def campo(texto, clave):
    m = re.search(clave + r"=([-0-9.]+)", texto)
    return float(m.group(1)) if m else float("nan")

filas = []
for n in [1 << 16, 1 << 20, 1 << 24]:
    for prog, tarea, cpu_cmd in [("caza2_guard_buggy", "axpb", "axpb"), ("caza3_reduce_buggy", "suma", "suma")]:
        gpu = subprocess.run(f"./{prog} {n} 256", shell=True, capture_output=True, text=True).stdout
        cpu = subprocess.run(f"./caza_cpu {cpu_cmd} {n}", shell=True, capture_output=True, text=True).stdout
        t_k, t_c = campo(gpu, "t_kernel_ms"), campo(cpu, "t_cpu_ms")
        ver = "OK" if "verificacion=OK" in gpu else "FALLA"
        filas.append([prog, n, 256, ver, t_k, t_c, t_c / t_k if t_k > 0 else float("nan")])
        print(f"{prog:18s} n={n:>9d} verif={ver:5s} t_kernel_ms={t_k:8.4f} t_cpu_ms={t_c:9.4f} speedup_kernel={t_c / t_k:7.1f}")
print("\\nUna fila con FALLA no tiene speedup: primero corrige, luego mide.")
''')

md("""## Opcional en Colab · el error de MPI (caza1)
Colab no trae MPI. Esta celda lo instala (≈ 1 minuto) y corre `caza1_bcast_buggy` con 4 procesos y un `timeout` de 5 s.
Código de salida 124 = `timeout` lo mató = interbloqueo. Con `-np 1` "funciona". Corrige la celda `%%writefile`, recompila y repite.""")
code("!apt-get -qq install -y openmpi-bin libopenmpi-dev > /dev/null 2>&1 && echo 'OpenMPI instalado'")
code("%%writefile caza1_bcast_buggy.c\n" + read("caza1_bcast_buggy.c"))
code("!mpicc -std=c11 -O2 -Wall -Wextra caza1_bcast_buggy.c -o caza1_bcast_buggy && echo 'caza1 listo'\n"
     "!./caza_cpu media 1000\n"
     "!timeout 5 mpirun --allow-run-as-root --oversubscribe -np 4 ./caza1_bcast_buggy 1000; echo \"codigo de salida: $? (124 = interbloqueo)\"\n"
     "!timeout 5 mpirun --allow-run-as-root --oversubscribe -np 1 ./caza1_bcast_buggy 1000; echo \"codigo de salida: $?\"")

md("""## Guardar resultados (CSV)
El archivo lleva la fecha y la GPU. Si usas estas mediciones en algún reporte, súbelo a `resultados/` de tu repositorio.""")
code('''import csv
gpu = subprocess.run(["nvidia-smi", "--query-gpu=name", "--format=csv,noheader"], capture_output=True, text=True).stdout.strip().replace(" ", "_")
fecha = datetime.date.today().isoformat()
nombre = f"resultados_S06_{fecha}_{gpu or 'gpu'}.csv"
with open(nombre, "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["fecha", "gpu", "programa", "n", "block", "verificacion", "t_kernel_ms", "t_cpu_ms", "speedup_kernel"])
    for fila in filas:
        w.writerow([fecha, gpu] + fila)
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
