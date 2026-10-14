#!/usr/bin/env python3
"""make_notebook.py — Genera notebook_colab.ipynb (válido, con nbformat) a partir de los fuentes de esta carpeta.

Uso: python3 make_notebook.py        (o: make notebook)
El notebook se abre en Google Colab o Kaggle con GPU y reproduce la práctica guiada: nvidia-smi,
%%writefile de cada fuente, compilación con nvcc, ejecución, investigación, medición y CSV final.
"""
import os

import nbformat
from nbformat.v4 import new_code_cell, new_markdown_cell, new_notebook

HERE = os.path.dirname(os.path.abspath(__file__))
SOURCES = ["vector_add.cu", "index_probe.cu", "vector_add_cpu.c", "vector_add_numba.py", "index_probe_numba.py"]


def read(name):
    with open(os.path.join(HERE, name), encoding="utf-8") as f:
        return f.read()


cells = []

cells.append(new_markdown_cell(
    "# S01 · Suma de vectores en CUDA (Colab / Kaggle)\n"
    "\n"
    "> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S01 · lunes 23 de noviembre de 2026 · "
    "10:30–12:00 · Salón 3208\n"
    "\n"
    "**Antes de correr nada, activa la GPU:**\n"
    "\n"
    "- **Colab:** menú *Entorno de ejecución → Cambiar tipo de entorno de ejecución → Acelerador de hardware: GPU (T4)* → Guardar.\n"
    "- **Kaggle:** panel derecho *Settings → Accelerator → GPU* (T4 x2 o P100). Kaggle pide verificar el teléfono para usar GPU.\n"
    "\n"
    "La primera celda debe mostrar una tarjeta NVIDIA. Si dice `command not found` o `No devices were found`, no hay GPU: "
    "vuelve a cambiar el tipo de entorno. Si Colab avisa que no hay GPU disponible, trabaja la correctitud con "
    "`NUMBA_ENABLE_CUDASIM=1` en tu laptop (celdas marcadas) y reintenta más tarde; la cuota se libera en horas.\n"
    "\n"
    "Sigue el `README.md` de la práctica guiada: **predice por escrito antes de ejecutar cada celda.**"
))

cells.append(new_code_cell("!nvidia-smi"))

cells.append(new_code_cell(
    "# Arquitectura para nvcc: T4 (Colab) -> sm_75; P100 (Kaggle) -> sm_60. Se detecta; si falla, queda sm_75.\n"
    "import subprocess\n"
    "ARCH = \"sm_75\"\n"
    "try:\n"
    "    cap = subprocess.check_output([\"nvidia-smi\", \"--query-gpu=compute_cap\", \"--format=csv,noheader\"],\n"
    "                                  text=True).strip().splitlines()[0]\n"
    "    ARCH = \"sm_\" + cap.replace(\".\", \"\")\n"
    "except Exception as exc:  # sin GPU o nvidia-smi viejo\n"
    "    print(\"No se pudo detectar la GPU:\", exc)\n"
    "print(\"ARCH =\", ARCH)"
))

cells.append(new_markdown_cell(
    "## 1. Escribir los fuentes en el disco de la sesión\n"
    "\n"
    "Cada celda `%%writefile` guarda un archivo. Son los mismos archivos de `practica-guiada/`; "
    "si los editas aquí, vuelve a ejecutar la celda y recompila."
))
for name in SOURCES:
    cells.append(new_code_cell(f"%%writefile {name}\n" + read(name).rstrip("\n")))

cells.append(new_markdown_cell(
    "## 2. Compilar\n"
    "\n"
    "`nvcc` compila el código de anfitrión (con el compilador de C++ del sistema) y el de dispositivo (a código de la GPU). "
    "En una T4 la línea equivale a `nvcc -O2 -arch=sm_75 vector_add.cu -o vector_add`."
))
cells.append(new_code_cell(
    "# En una T4 (Colab) esto equivale a:  !nvcc -O2 -arch=sm_75 vector_add.cu -o vector_add\n"
    "!nvcc -O2 -arch={ARCH} vector_add.cu -o vector_add\n"
    "!nvcc -O2 -arch={ARCH} index_probe.cu -o index_probe\n"
    "!gcc -std=c11 -O2 -Wall -Wextra vector_add_cpu.c -o vector_add_cpu -lm\n"
    "!ls -l vector_add index_probe vector_add_cpu"
))

cells.append(new_markdown_cell(
    "## 3. Ejecutar (fase *Run* de PRIMM)\n"
    "\n"
    "Antes de cada celda anota tu predicción en el README. Primero la sonda de índices con `n=10`, `block=4`; "
    "después la suma con `n=1000`; después el tamaño por defecto (2^24 = 16 777 216 elementos)."
))
cells.append(new_code_cell("!./index_probe 10 4"))
cells.append(new_code_cell("!./vector_add 1000 256"))
cells.append(new_code_cell("!./vector_add_cpu\n!./vector_add"))
cells.append(new_markdown_cell(
    "El espejo en Numba hace lo mismo desde Python. En GPU real la primera llamada compila el kernel (JIT); "
    "por eso el programa calienta antes de medir. Sin GPU, en tu laptop: `NUMBA_ENABLE_CUDASIM=1 python3 vector_add_numba.py 1000 256`."
))
cells.append(new_code_cell("!python3 vector_add_numba.py\n!python3 index_probe_numba.py 10 4"))

cells.append(new_markdown_cell(
    "## 4. Investigar\n"
    "\n"
    "**a) Grid insuficiente.** Forzamos 3 bloques de 256 para `n=1000` (768 hilos). No hay error de CUDA. "
    "¿Qué dice la verificación? ¿Qué elementos quedaron sin calcular?\n"
    "\n"
    "**b) Sin guardia.** Compilamos con `-DSIN_GUARDIA`: 4 bloques de 256 = 1024 hilos para `n=1000`; "
    "24 hilos escriben fuera del arreglo. Observa si CUDA reporta algo. Repite con `n=1000 block=1024 grid=4000` "
    "(mucho más allá del arreglo) y compara."
))
cells.append(new_code_cell("!./vector_add 1000 256 3; echo \"código de salida: $?\""))
cells.append(new_code_cell(
    "!nvcc -O2 -arch={ARCH} -DSIN_GUARDIA vector_add.cu -o vector_add_sin_guardia\n"
    "!./vector_add_sin_guardia 1000 256; echo \"código de salida: $?\"\n"
    "!./vector_add_sin_guardia 1000 1024 4000; echo \"código de salida: $?\""
))

cells.append(new_markdown_cell(
    "## 5. Medir (protocolo del curso)\n"
    "\n"
    "`vector_add` ya hace calentamiento + 5 repeticiones y reporta la mediana, el tiempo del kernel solo y el tiempo "
    "con copias anfitrión↔dispositivo. Aquí barremos el tamaño de bloque con `n = 2^24` y guardamos cada fila en "
    "`resultados.csv`. Anota el modelo de GPU y la fecha: el hardware que asigna Colab cambia."
))
cells.append(new_code_cell(
    "import os, subprocess\n"
    "if os.path.exists(\"resultados.csv\"):\n"
    "    os.remove(\"resultados.csv\")\n"
    "N = 16777216\n"
    "for block in [32, 64, 128, 256, 512, 1024]:\n"
    "    out = subprocess.run([\"./vector_add\", str(N), str(block), \"0\", \"resultados.csv\"],\n"
    "                         capture_output=True, text=True)\n"
    "    print(out.stdout.strip().splitlines()[-2])  # línea de tiempos\n"
    "    print(out.stdout.strip().splitlines()[-1])  # línea de verificación\n"
    "    if out.returncode != 0:\n"
    "        print(\"stderr:\", out.stderr)"
))

cells.append(new_markdown_cell(
    "## 6. Guardar resultados\n"
    "\n"
    "La celda final muestra la tabla, agrega la fecha y descarga el CSV (en Kaggle queda en `/kaggle/working/`). "
    "Súbelo a tu repositorio en `resultados/`. Para tu bitácora: ¿cuántas veces más tarda la versión *con copias* que el "
    "kernel solo? ¿Y comparado con `vector_add_cpu`? Eso es el tema de la sesión S04 (lunes 30 de noviembre)."
))
cells.append(new_code_cell(
    "import datetime\n"
    "import pandas as pd\n"
    "df = pd.read_csv(\"resultados.csv\")\n"
    "df[\"fecha\"] = datetime.date.today().isoformat()\n"
    "print(df.to_string(index=False))\n"
    "nombre = f\"resultados_S01_vector_add_{datetime.date.today().isoformat()}.csv\"\n"
    "df.to_csv(nombre, index=False)\n"
    "print(\"guardado:\", nombre)\n"
    "try:\n"
    "    from google.colab import files  # solo existe en Colab\n"
    "    files.download(nombre)\n"
    "except ImportError:\n"
    "    print(\"En Kaggle: descarga el archivo desde el panel Output (/kaggle/working/).\")"
))

nb = new_notebook(cells=cells)
nb.metadata["kernelspec"] = {"display_name": "Python 3", "language": "python", "name": "python3"}
nb.metadata["language_info"] = {"name": "python"}
nb.metadata["accelerator"] = "GPU"
nb.metadata["colab"] = {"provenance": [], "gpuType": "T4", "name": "S01_vector_add_cuda.ipynb"}

nbformat.validate(nb)
out_path = os.path.join(HERE, "notebook_colab.ipynb")
with open(out_path, "w", encoding="utf-8") as f:
    nbformat.write(nb, f)
print(f"escrito {out_path} ({len(cells)} celdas, válido)")
