#!/usr/bin/env python3
"""
herramientas/generar_notebook_v3.py · Genera el notebook de Colab/Kaggle de la V3 (plantilla)

Uso:
    python3 herramientas/generar_notebook_v3.py --fuente v3/kernel.cu --v1 v1/main.c
                                                --salida v3/notebook_colab.ipynb
                                                [--cabecera comun/problema.h] [--equipo NN] [--n 4000000]
                                                [--semilla 12345] [--reps 5] [--arch sm_75]
    --fuente    v3/kernel.cu (CUDA C) o un .py (Numba CUDA / CuPy). Se decide por la extensión.
    --cabecera  cabecera común que incluyen la V1 y, en CUDA C, la V3 (se escribe junto a ellas en
                Colab). Por defecto comun/problema.h; también hace falta con .py, porque la V1 la incluye.
    --v1        v1/main.c: se compila también en Colab para verificar el checksum y medir T(1)
                EN LA MISMA MÁQUINA (el speedup de la GPU se reporta contra ese T(1)).
Qué produce: un .ipynb válido (nbformat 4) con estas celdas, en orden:
    0  Markdown: qué es, cómo activar la GPU, qué descargar al terminar.
    1  Entorno: !nvidia-smi, !nvcc --version, python3 (y numba/cupy si la V3 es .py), fecha UTC,
       CPU anfitriona  -> entorno_gpu.txt
    2  Markdown + %%writefile de la cabecera, la V1 y la fuente de la V3 (copias exactas del repositorio).
    3  Compilación: gcc para V1; nvcc (o nada, si es .py) para V3.
    4  Verificación: corre V1 y V3 con la misma n y semilla y compara el checksum con tolerancia.
    5  Medición: 1 calentamiento + K repeticiones de V1 y de V3; escribe mediciones_v3.csv con
       la cabecera del protocolo y filas v1, v3_kernel (sin transferencias) y v3_total (con).
    6  Markdown final: descargar notebook CON salidas, mediciones_v3.csv y entorno_gpu.txt.
Código de salida: 0 si el notebook se escribió y valida; 1 si falta un archivo de entrada.
Ejemplo (desde la raíz del repositorio):
    python3 herramientas/generar_notebook_v3.py --fuente v3/kernel.cu --cabecera comun/problema.h \
        --v1 v1/main.c --salida v3/notebook_colab.ipynb --equipo 07
Después de ejecutarlo en Colab, descarga el .ipynb EJECUTADO y reemplaza v3/notebook_colab.ipynb;
la versión sin salidas no cuenta como evidencia (proyecto/entrega-final/reproducibilidad.md §4).
"""
import argparse
import os
import sys

import nbformat
from nbformat.v4 import new_code_cell, new_markdown_cell, new_notebook


def leer(ruta):
    if not os.path.isfile(ruta):
        sys.exit(f"error: no existe {ruta}")
    with open(ruta, encoding="utf-8") as f:
        return f.read()


def main():
    ap = argparse.ArgumentParser(description="Genera el notebook de Colab/Kaggle de la V3.")
    ap.add_argument("--fuente", required=True, help="v3/kernel.cu o v3/main_gpu.py")
    ap.add_argument("--cabecera", default="comun/problema.h",
                    help="cabecera que incluyen la V1 y la V3 en CUDA C (por defecto comun/problema.h)")
    ap.add_argument("--v1", required=True, help="v1/main.c para verificar y medir T(1) en Colab")
    ap.add_argument("--salida", required=True, help="ruta del .ipynb a escribir")
    ap.add_argument("--equipo", default="NN", help="número de equipo (cp-6bm1-equipoNN)")
    ap.add_argument("--n", type=int, default=4000000, help="tamaño del problema para medir")
    ap.add_argument("--semilla", type=int, default=12345, help="semilla de los datos")
    ap.add_argument("--reps", type=int, default=5, help="repeticiones medidas (>= 5)")
    ap.add_argument("--arch", default="sm_75", help="arquitectura CUDA (T4 = sm_75)")
    args = ap.parse_args()
    if args.reps < 5:
        sys.exit("error: --reps debe ser >= 5 (protocolo §2)")

    fuente = leer(args.fuente)
    v1 = leer(args.v1)
    nombre_fuente = os.path.basename(args.fuente)
    es_python = nombre_fuente.endswith(".py")
    cabecera = leer(args.cabecera)
    nombre_cab = os.path.basename(args.cabecera)

    celdas = []
    celdas.append(new_markdown_cell(
        f"# V3 · GPU · Proyecto integrador · Equipo {args.equipo}\n\n"
        "**Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1**\n\n"
        "Antes de ejecutar: *Entorno de ejecución → Cambiar tipo de entorno → GPU* (Colab) o "
        "*Settings → Accelerator → GPU* (Kaggle). Ejecuta las celdas en orden (*Entorno de ejecución → "
        "Ejecutar todo*).\n\n"
        "Al terminar: (1) descarga este notebook **con las salidas** (*Archivo → Descargar → .ipynb*) y "
        "reemplaza `v3/notebook_colab.ipynb`; (2) descarga `mediciones_v3.csv` y `entorno_gpu.txt` a "
        "`resultados/` del repositorio. Sin esos tres archivos la V3 no tiene evidencia.\n\n"
        "Este notebook lo generó `herramientas/generar_notebook_v3.py`; si cambias el código fuente, "
        "regenéralo en lugar de editar las celdas a mano."
    ))

    entorno = [
        "# 1. Entorno: qué GPU nos tocó HOY (cambia entre sesiones; por eso se guarda con fecha)",
        "!nvidia-smi",
        "!nvidia-smi --query-gpu=name,driver_version,memory.total,compute_cap --format=csv > entorno_gpu.txt",
        "!date -u +fecha_utc=%Y-%m-%dT%H:%M:%SZ >> entorno_gpu.txt",
        "!nvcc --version | tail -1 >> entorno_gpu.txt",
        "!python3 --version | sed 's/^/python: /' >> entorno_gpu.txt",
    ]
    if es_python:
        entorno.append("!pip show numba cupy-cuda12x 2>/dev/null | grep -E '^(Name|Version):' >> entorno_gpu.txt")
    entorno += [
        "!grep -m1 'model name' /proc/cpuinfo | sed 's/^/cpu_anfitrion: /' >> entorno_gpu.txt",
        "!nproc | sed 's/^/nucleos_anfitrion=/' >> entorno_gpu.txt",
        "!cat entorno_gpu.txt",
    ]
    celdas.append(new_code_cell("\n".join(entorno)))

    celdas.append(new_markdown_cell(
        "## 2. Código fuente\n\n"
        "Las tres celdas siguientes escriben en Colab copias exactas de los archivos del repositorio "
        f"(`{nombre_cab}`, la V1 como `main_v1.c` y `{nombre_fuente}`). No las edites aquí: cambia el "
        "repositorio y regenera el notebook; el verificador de la entrega compara estas celdas con el repositorio."
    ))
    celdas.append(new_code_cell(f"%%writefile {nombre_cab}\n{cabecera}"))
    celdas.append(new_code_cell(f"%%writefile main_v1.c\n{v1}"))
    celdas.append(new_code_cell(f"%%writefile {nombre_fuente}\n{fuente}"))

    compilar = ["# 3. Compilación (las mismas banderas que en el repositorio)",
                "!gcc -std=c11 -O2 -Wall -Wextra -I. -o v1 main_v1.c -lm"]
    if es_python:
        compilar.append("!python3 -c \"import numba, cupy\" 2>/dev/null || pip -q install numba cupy-cuda12x")
        ejecutar_v3 = f"python3 {nombre_fuente}"
    else:
        compilar.append(f"!nvcc -O2 -arch={args.arch} -Xcompiler -Wall,-Wextra -I. -o v3 {nombre_fuente}")
        ejecutar_v3 = "./v3"
    compilar.append("!ls -l v1" + ("" if es_python else " v3"))
    celdas.append(new_code_cell("\n".join(compilar)))

    celdas.append(new_code_cell(
        "# 4. Verificación: V3 debe dar el mismo checksum que V1 con los mismos datos\n"
        "import subprocess\n"
        "\n"
        "TOL = 1e-9\n"
        f"N_PRUEBA, SEMILLA = 200000, {args.semilla}\n"
        "\n"
        "def correr(cmd):\n"
        "    out = subprocess.run(cmd, shell=True, check=True, capture_output=True, text=True).stdout\n"
        "    return dict(l.split('=', 1) for l in out.strip().splitlines() if '=' in l)\n"
        "\n"
        "r1 = correr(f'./v1 {N_PRUEBA} {SEMILLA}')\n"
        f"r3 = correr(f'{ejecutar_v3} {{N_PRUEBA}} {{SEMILLA}}')\n"
        "c1, c3 = float(r1['checksum']), float(r3['checksum'])\n"
        "ok = abs(c1 - c3) <= TOL * max(1.0, abs(c1))\n"
        "print('v1 checksum =', r1['checksum'])\n"
        "print('v3 checksum =', r3['checksum'], '| gpu =', r3.get('gpu', '?'))\n"
        "print('PASS v3 == v1' if ok else 'FAIL v3 != v1: NO midas hasta corregirlo')\n"
        "assert ok"
    ))

    celdas.append(new_code_cell(
        "# 5. Medición (protocolo: 1 calentamiento + K repeticiones, mediana; con y sin transferencias)\n"
        "import csv, statistics\n"
        "\n"
        f"N, SEMILLA, REPS = {args.n}, {args.semilla}, {args.reps}\n"
        "\n"
        "def medir(cmd, campo):\n"
        "    correr(cmd)  # calentamiento, no se cuenta\n"
        "    return [float(correr(cmd)[campo]) for _ in range(REPS)]\n"
        "\n"
        "t_v1 = medir(f'./v1 {N} {SEMILLA}', 'tiempo_s')\n"
        f"t_k  = medir(f'{ejecutar_v3} {{N}} {{SEMILLA}}', 'tiempo_kernel_s')\n"
        f"t_t  = medir(f'{ejecutar_v3} {{N}} {{SEMILLA}}', 'tiempo_total_s')\n"
        "T1 = statistics.median(t_v1)\n"
        "if T1 < 1.0:\n"
        "    print(f'AVISO: T(1) = {T1:.3f} s < 1 s en esta CPU; sube N (protocolo §2)')\n"
        "\n"
        "cab = ['config', 'hilos', 'n'] + [f'rep{i}' for i in range(1, REPS + 1)] + ['mediana_s', 'speedup', 'eficiencia']\n"
        "filas = []\n"
        "for nombre, hilos, ts in (('v1', 1, t_v1), ('v3_kernel', 0, t_k), ('v3_total', 0, t_t)):\n"
        "    med = statistics.median(ts)\n"
        "    filas.append([nombre, hilos, N] + [f'{t:.6f}' for t in ts] + [f'{med:.6f}', f'{T1/med:.3f}', ''])\n"
        "with open('mediciones_v3.csv', 'w', newline='') as f:\n"
        "    w = csv.writer(f); w.writerow(cab); w.writerows(filas)\n"
        "for fila in filas:\n"
        "    print(f'{fila[0]:10s} mediana={fila[-3]} s  speedup_vs_v1={fila[-2]}')\n"
        "print('CSV -> mediciones_v3.csv (hilos=0 marca filas de GPU; el speedup es contra la V1 de ESTA máquina)')"
    ))

    celdas.append(new_markdown_cell(
        "## Antes de cerrar la sesión\n\n"
        "1. Revisa que las celdas 1, 4 y 5 tengan salida visible (nvidia-smi, PASS, medianas).\n"
        "2. *Archivo → Descargar → .ipynb*: ese archivo **con salidas** es `v3/notebook_colab.ipynb` en el repositorio.\n"
        "3. Descarga `mediciones_v3.csv` y `entorno_gpu.txt` a `resultados/` del repositorio y haz *commit*.\n"
        "4. En el reporte, cita el modelo de GPU y la fecha que aparecen en `entorno_gpu.txt`.\n"
    ))

    nb = new_notebook(cells=celdas)
    nb.metadata["kernelspec"] = {"name": "python3", "display_name": "Python 3", "language": "python"}
    nb.metadata["language_info"] = {"name": "python"}
    nb.metadata["accelerator"] = "GPU"
    nb.metadata["colab"] = {"provenance": [], "gpuType": "T4"}
    nbformat.validate(nb)
    os.makedirs(os.path.dirname(os.path.abspath(args.salida)), exist_ok=True)
    with open(args.salida, "w", encoding="utf-8") as f:
        nbformat.write(nb, f)
    print(f"notebook válido -> {args.salida} ({len(celdas)} celdas)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
