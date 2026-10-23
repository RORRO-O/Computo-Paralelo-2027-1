#!/usr/bin/env python3
"""make_notebook.py — Genera notebook_colab.ipynb (válido, con nbformat) a partir de los fuentes de esta carpeta.

Uso: python3 make_notebook.py        (o: make notebook)
El notebook se abre en Google Colab o Kaggle con GPU y reproduce la práctica guiada S03: nvidia-smi,
%%writefile de cada fuente, compilación con nvcc, ejecución de las tres reducciones y del histograma,
experimentos de la fase Investigar, medición con CSV y celda final que guarda los resultados.
"""
import os

import nbformat
from nbformat.v4 import new_code_cell, new_markdown_cell, new_notebook

HERE = os.path.dirname(os.path.abspath(__file__))
SOURCES = ["reduce_sum.cu", "reduce_sum_cpu.c", "reduce_sum_numba.py",
           "histogram.cu", "histogram_cpu.c", "histogram_numba.py"]


def read(name):
    with open(os.path.join(HERE, name), encoding="utf-8") as f:
        return f.read()


cells = []

cells.append(new_markdown_cell(
    "# S03 · Sincronización y reducción en GPU (Colab / Kaggle)\n"
    "\n"
    "> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S03 · jueves 26 de noviembre de 2026 · "
    "10:30–12:00 · Salón 3208\n"
    "\n"
    "**Antes de correr nada, activa la GPU:**\n"
    "\n"
    "- **Colab:** *Entorno de ejecución → Cambiar tipo de entorno de ejecución → Acelerador de hardware: GPU (T4)* → Guardar.\n"
    "- **Kaggle:** panel derecho *Settings → Accelerator → GPU* (T4 x2 o P100).\n"
    "\n"
    "La primera celda debe mostrar una tarjeta NVIDIA. Si no hay GPU disponible, trabaja la correctitud con "
    "`NUMBA_ENABLE_CUDASIM=1` en tu laptop (`make test`) y reintenta más tarde.\n"
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
    "si los editas aquí (por ejemplo, el `TODO(1)` del histograma), vuelve a ejecutar la celda y recompila."
))
for name in SOURCES:
    cells.append(new_code_cell(f"%%writefile {name}\n" + read(name).rstrip("\n")))

cells.append(new_markdown_cell(
    "## 2. Compilar\n"
    "\n"
    "En una T4 la línea equivale a `nvcc -O2 -arch=sm_75 reduce_sum.cu -o reduce_sum`. "
    "Las referencias CPU se compilan con `gcc -Wall -Wextra` (sin *warnings*)."
))
cells.append(new_code_cell(
    "# En una T4 (Colab) esto equivale a:  !nvcc -O2 -arch=sm_75 reduce_sum.cu -o reduce_sum\n"
    "!nvcc -O2 -arch={ARCH} reduce_sum.cu -o reduce_sum\n"
    "!nvcc -O2 -arch={ARCH} histogram.cu -o histogram\n"
    "!gcc -std=c11 -O2 -Wall -Wextra reduce_sum_cpu.c -o reduce_sum_cpu -lm\n"
    "!gcc -std=c11 -O2 -Wall -Wextra histogram_cpu.c -o histogram_cpu\n"
    "!ls -l reduce_sum histogram reduce_sum_cpu histogram_cpu"
))

cells.append(new_markdown_cell(
    "## 3. Ejecutar (fase *Run* de PRIMM)\n"
    "\n"
    "Primero la referencia CPU (cuatro órdenes de suma distintos, mismo dato); después las tres versiones en GPU con "
    "`n = 2^20` y bloques de 256. Compara `suma`, `err_rel`, `atomicas_globales` y `kernel_mediana_ms` con lo que predijiste."
))
cells.append(new_code_cell("!./reduce_sum_cpu 1048576 256"))
cells.append(new_code_cell("!./reduce_sum all 1048576 256 cpu"))
cells.append(new_code_cell(
    "# Segunda etapa en la GPU: una atómica por bloque en lugar de copiar los parciales al anfitrión\n"
    "!./reduce_sum tree_nodiv 1048576 256 atomic"
))
cells.append(new_markdown_cell(
    "El espejo en Numba hace lo mismo desde Python (en GPU real la primera llamada compila el kernel; por eso calienta). "
    "Sin GPU, en tu laptop: `NUMBA_ENABLE_CUDASIM=1 python3 reduce_sum_numba.py all 1000 256`."
))
cells.append(new_code_cell("!python3 reduce_sum_numba.py all 1048576 256"))

cells.append(new_markdown_cell(
    "## 4. Investigar\n"
    "\n"
    "**a) Sin `__syncthreads()` entre niveles** (`-DSIN_SYNC`). Predice: ¿sale mal, o sale bien \"por suerte\"? "
    "Corre cinco veces con `block = 256` y cinco con `block = 32` (un solo *warp*). Anota cuántas veces dio `OK` cada una.\n"
    "\n"
    "**b) `n` no potencia de 2 ni múltiplo del bloque** (`n = 1 000 003`): el último bloque carga ceros donde `i ≥ n`.\n"
    "\n"
    "**c) `block = 96` (no potencia de 2)**: no hay error de CUDA. ¿Qué dice la verificación? ¿Qué fracción de los datos se perdió?\n"
    "\n"
    "**d) `n = 2^24` con la versión atómica**: el acumulador `float` llega a 16 777 216, donde sumar 1.0 ya no cambia el valor. "
    "¿Qué versión falla y cuál no?"
))
cells.append(new_code_cell(
    "!nvcc -O2 -arch={ARCH} -DSIN_SYNC reduce_sum.cu -o reduce_sum_sin_sync\n"
    "for block in (256, 32):\n"
    "    print(f\"=== -DSIN_SYNC, block={block}: 5 corridas ===\")\n"
    "    for k in range(5):\n"
    "        out = subprocess.run([\"./reduce_sum_sin_sync\", \"tree_nodiv\", \"1048576\", str(block)],\n"
    "                             capture_output=True, text=True).stdout\n"
    "        print([l.strip() for l in out.splitlines() if \"verificacion=\" in l][0])"
))
cells.append(new_code_cell("!./reduce_sum all 1000003 256; echo \"código de salida: $?\""))
cells.append(new_code_cell("!./reduce_sum tree_nodiv 1048576 96; echo \"código de salida: $?\""))
cells.append(new_code_cell("!./reduce_sum_cpu 16777216 256\n!./reduce_sum all 16777216 256; echo \"código de salida: $?\""))

cells.append(new_markdown_cell(
    "## 5. Medir (protocolo del curso)\n"
    "\n"
    "`reduce_sum` ya hace calentamiento + 5 repeticiones y reporta la mediana. Aquí barremos las tres versiones para varios `n` "
    "y las dos formas de la segunda etapa, y guardamos cada fila en `resultados.csv`. Anota el modelo de GPU y la fecha: "
    "el hardware que asigna Colab cambia. Los tiempos de la T4 son órdenes de magnitud; lo que debe coincidir es `suma`, "
    "`err_rel` y `atomicas_globales`."
))
cells.append(new_code_cell(
    "import os, subprocess\n"
    "if os.path.exists(\"resultados.csv\"):\n"
    "    os.remove(\"resultados.csv\")\n"
    "for n in [1 << 16, 1 << 20, 1 << 22]:\n"
    "    for stage2 in [\"cpu\", \"atomic\"]:\n"
    "        out = subprocess.run([\"./reduce_sum\", \"all\", str(n), \"256\", stage2, \"resultados.csv\"],\n"
    "                             capture_output=True, text=True)\n"
    "        for line in out.stdout.splitlines():\n"
    "            if line.startswith(\"version=\"):\n"
    "                print(f\"n={n:>8} \" + line)\n"
    "        if out.returncode != 0:\n"
    "            print(\"código de salida:\", out.returncode, out.stderr)"
))

cells.append(new_markdown_cell(
    "## 6. Histograma con atómicas (fase Crear)\n"
    "\n"
    "`histogram global` hace `atomicAdd` sobre 16 contadores en memoria global desde todos los hilos; el 30 % de los datos cae "
    "en el bin 0 (contención). `histogram shared` es el `TODO(1)`: histograma privado por bloque en memoria compartida y volcado "
    "de 16 atómicas por bloque. Mientras no lo completes, imprime `TODO pendiente`. Cuando lo completes: edita la celda "
    "`%%writefile histogram.cu`, vuelve a ejecutarla, recompila y corre esta celda; el criterio de \"listo\" es `verificacion=OK` "
    "con el mismo histograma que la CPU y `atomicas_globales=65536` para `n = 2^20`."
))
cells.append(new_code_cell("!./histogram_cpu 1048576 256\n!./histogram all 1048576 256 resultados_histograma.csv"))
cells.append(new_code_cell(
    "# Con 256 bins (bytes): misma idea, 16x más atómicas por bloque en el volcado\n"
    "!nvcc -O2 -arch={ARCH} -DBINS=256 histogram.cu -o histogram256\n"
    "!./histogram256 all 1048576 256"
))

cells.append(new_markdown_cell(
    "## 7. Guardar resultados\n"
    "\n"
    "La celda final muestra la tabla, agrega la fecha y descarga el CSV (en Kaggle queda en `/kaggle/working/`). "
    "Súbelo a tu repositorio en `resultados/`. Para tu bitácora: ¿cuántas veces más tarda la versión atómica que el árbol? "
    "¿Cambió `suma` entre corridas de la versión atómica? ¿Y entre las dos del árbol?"
))
cells.append(new_code_cell(
    "import datetime\n"
    "import pandas as pd\n"
    "df = pd.read_csv(\"resultados.csv\")\n"
    "df[\"fecha\"] = datetime.date.today().isoformat()\n"
    "print(df.to_string(index=False))\n"
    "nombre = f\"resultados_S03_reduccion_{datetime.date.today().isoformat()}.csv\"\n"
    "df.to_csv(nombre, index=False)\n"
    "print(\"guardado:\", nombre)\n"
    "if os.path.exists(\"resultados_histograma.csv\"):\n"
    "    dh = pd.read_csv(\"resultados_histograma.csv\")\n"
    "    dh[\"fecha\"] = datetime.date.today().isoformat()\n"
    "    print(dh.to_string(index=False))\n"
    "    nombre_h = f\"resultados_S03_histograma_{datetime.date.today().isoformat()}.csv\"\n"
    "    dh.to_csv(nombre_h, index=False)\n"
    "    print(\"guardado:\", nombre_h)\n"
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
nb.metadata["colab"] = {"provenance": [], "gpuType": "T4", "name": "S03_reduccion_cuda.ipynb"}

nbformat.validate(nb)
out_path = os.path.join(HERE, "notebook_colab.ipynb")
with open(out_path, "w", encoding="utf-8") as f:
    nbformat.write(nb, f)
print(f"escrito {out_path} ({len(cells)} celdas, válido)")
