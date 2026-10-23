"""generar_notebook.py — Genera notebook_colab.ipynb (válido según nbformat) a partir de los fuentes de esta carpeta.

Uso: python3 generar_notebook.py      (o `make notebook`)

El notebook reproduce la práctica guiada en Colab/Kaggle: verifica la GPU, escribe cada fuente con %%writefile,
compila con nvcc -O2 -arch=sm_75, ejecuta el ejemplo resuelto y los barridos, perfila con nsys, aplica la
modificación (memoria pinned y streams), grafica y guarda el CSV de resultados.
"""
import nbformat
from nbformat.v4 import new_code_cell, new_markdown_cell, new_notebook

HEADER = ("> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S04 · "
          "lunes 30 de noviembre de 2026 · 10:30–12:00 · Salón 3208")

SOURCES = ["medir_eventos.cu", "bench_gpu.cu", "pinned_streams.cu", "graficar.py", "bench_numba.py"]


def read(name):
    with open(name, encoding="utf-8") as f:
        return f.read().rstrip("\n")


cells = [
    new_markdown_cell(f"""{HEADER}

# S04 · Rendimiento en GPU: práctica guiada (PRIMM)

Este cuaderno corre la práctica guiada de la sesión en una GPU de Colab o Kaggle. Antes de ejecutar nada:

1. **Entorno de ejecución → Cambiar tipo de entorno → GPU (T4)** en Colab; en Kaggle activa el acelerador GPU.
2. Ten a la mano tu hoja de **predicciones** del `README.md` (fase *Predecir*). No corras las celdas de medición
   sin haberlas escrito.
3. Los tiempos dependen de la GPU que te toque (T4 típica en Colab; P100 o T4 en Kaggle) y del día; anota
   modelo de GPU y fecha (protocolo de medición, §1.4).

Si Kaggle te asigna una **P100**, cambia `-arch=sm_75` por `-arch=sm_60` en la celda de compilación."""),
    new_markdown_cell("## 1. Verificar la GPU asignada"),
    new_code_cell("!nvidia-smi"),
    new_code_cell("""# Capacidad de cómputo de la GPU asignada: 7.5 = T4 (sm_75), 6.0 = P100 (sm_60), 8.0 = A100, 8.9 = L4.
import subprocess
cc = subprocess.run(["nvidia-smi", "--query-gpu=name,compute_cap", "--format=csv,noheader"],
                    capture_output=True, text=True).stdout.strip()
print(cc or "No se detectó GPU: revisa el tipo de entorno de ejecución")
if cc and float(cc.split(",")[-1]) < 7.5:
    print("AVISO: capacidad < 7.5. Edita la celda de compilación y usa -arch=sm_60 en lugar de sm_75.")"""),
    new_markdown_cell("## 2. Escribir los fuentes en el disco de la máquina virtual"),
]
for name in SOURCES:
    cells.append(new_code_cell(f"%%writefile {name}\n{read(name)}"))

cells += [
    new_markdown_cell("## 3. Compilar (con optimización; nunca se mide con -O0)"),
    new_code_cell("""!nvcc -O2 -arch=sm_75 -o medir_eventos medir_eventos.cu
!nvcc -O2 -arch=sm_75 -o bench_gpu bench_gpu.cu
!nvcc -O2 -arch=sm_75 -o pinned_streams pinned_streams.cu
!ls -l medir_eventos bench_gpu pinned_streams"""),
    new_markdown_cell("""## 4. Ejecutar · ejemplo resuelto: cuatro formas de medir el mismo kernel

Antes de correr: ¿cuál de las cuatro filas dará el número más pequeño y por qué está mal?"""),
    new_code_cell("!./medir_eventos"),
    new_markdown_cell("""## 5. Ejecutar · barrido de tamaño de bloque (experimento `bloque`)

Con tu predicción escrita (mejor bloque, peor bloque, razón), corre el barrido con `n = 2^24` y después con
`n = 4096`. Todas las corridas de esta sección agregan filas a `resultados.csv`."""),
    new_code_cell("""!rm -f resultados.csv
!./bench_gpu bloque 16777216 resultados.csv"""),
    new_code_cell("!./bench_gpu bloque 4096 resultados.csv"),
    new_markdown_cell("""## 6. Ejecutar · umbral de tamaño: tabla con y sin transferencias (experimento `umbral`)

Predicción: ¿a partir de qué `n` gana la GPU contando solo el kernel? ¿Y contando las copias?"""),
    new_code_cell("!./bench_gpu umbral 256 resultados.csv"),
    new_markdown_cell("""## 7. Investigar · perfilado con `nsys` (y `ncu` si está disponible)

`nsys profile --stats=true` imprime varias tablas. Mira estas tres y, en cada una, las columnas
**Time (%)**, **Total Time**, **Instances/Count**, **Avg** y **Name/Operation**:

- `cuda_api_sum`: tiempo de la CPU en cada llamada a la API (`cudaMemcpy`, `cudaMalloc`, `cudaEventSynchronize`).
- `cuda_gpu_kern_sum`: tiempo en la GPU de cada kernel (`vector_add_kernel`, `saxpy_kernel`).
- `cuda_gpu_mem_time_sum`: tiempo de las copias `[CUDA memcpy Host-to-Device]` y `[CUDA memcpy Device-to-Host]`.

Si `nsys` no existe en tu entorno, la celda lo dice y te quedas con los eventos, que miden lo mismo con menos detalle."""),
    new_code_cell("""import shutil
if shutil.which("nsys"):
    !nsys profile --stats=true -o perfil_s04 --force-overwrite true ./bench_gpu bloque 16777216 perfil.csv 2>&1 | grep -v "^$" | head -120
else:
    print("nsys no disponible: usa las columnas H2D/kernel/D2H que ya imprime bench_gpu (medidas con eventos)")"""),
    new_code_cell("""# ncu (Nsight Compute) suele estar bloqueado en Colab (ERR_NVGPUCTRPERM). Si corre, mira la sección
# "GPU Speed Of Light": % del ancho de banda de memoria y % de cómputo que alcanza el kernel.
import shutil
if shutil.which("ncu"):
    !ncu --section SpeedOfLight --kernel-name regex:saxpy --launch-skip 6 --launch-count 1 ./bench_gpu bloque 16777216 perfil_ncu.csv 2>&1 | tail -40
else:
    print("ncu no disponible en este entorno")"""),
    new_markdown_cell("""## 8. Modificar · memoria *pinned* y *streams*

1. Repite el experimento `umbral` con memoria fija (`pinned`). Predice primero: ¿cambia el tiempo del kernel?
   ¿cambian las copias? ¿aparece el cruce "con copias" que antes no aparecía?
2. Corre `pinned_streams`: tres versiones del mismo trabajo (paginable, pinned, pinned + 4 streams)."""),
    new_code_cell("!./bench_gpu umbral 256 resultados.csv pinned"),
    new_code_cell("!./pinned_streams"),
    new_code_cell("# Opcional: ¿y con 2 u 8 streams? Predice antes si mejora, empeora o da igual.\n!./pinned_streams 16777216 8"),
    new_markdown_cell("## 9. Graficar: tiempo vs. tamaño de bloque y speedup vs. n"),
    new_code_cell("""!python3 graficar.py resultados.csv .
from IPython.display import Image, display
display(Image("tiempo_vs_bloque.png"))
display(Image("speedup_vs_n.png"))"""),
    new_markdown_cell("""## 10. Opcional · el mismo barrido en Numba CUDA

Los kernels en Numba son el espejo de los de `bench_gpu.cu`; con GPU real también mide con eventos."""),
    new_code_cell("!python3 bench_numba.py --n 16777216"),
    new_markdown_cell("""## 11. Crear · tu propio kernel de la Práctica 6 con este protocolo

Copia tu kernel de la Práctica 6 a una celda `%%writefile`, compílalo y mídelo con el mismo esquema que `bench_gpu.cu`:
cuatro eventos (H2D, kernel, D2H), 1 calentamiento + 5 repeticiones, mediana, verificación contra la CPU y una
fila por configuración en un CSV con el mismo encabezado. Criterio de "listo": tabla con/sin copias para tres `n`,
barrido de bloque para un `n`, y una frase que diga si tu kernel está limitado por memoria o por cómputo (y por qué)."""),
    new_markdown_cell("""## 12. Guardar los resultados

Guarda el CSV con el nombre de la GPU y la fecha. En Colab se descarga; en Kaggle queda en `/kaggle/working`.
Súbelo a `resultados/` de tu repositorio de P6 junto con las dos PNG."""),
    new_code_cell("""import datetime, shutil, subprocess, os
gpu = subprocess.run(["nvidia-smi", "--query-gpu=name", "--format=csv,noheader"], capture_output=True,
                     text=True).stdout.strip().replace(" ", "_") or "sin_gpu"
stamp = datetime.date.today().isoformat()
nombre = f"resultados_S04_{gpu}_{stamp}.csv"
shutil.copy("resultados.csv", nombre)
for png in ("tiempo_vs_bloque.png", "speedup_vs_n.png"):
    if os.path.exists(png):
        shutil.copy(png, png.replace(".png", f"_{gpu}_{stamp}.png"))
print("Guardado:", nombre)
try:
    from google.colab import files  # solo existe en Colab
    files.download(nombre)
except ImportError:
    print("Fuera de Colab: el archivo queda en el directorio de trabajo")"""),
]

for i, cell in enumerate(cells):
    cell.id = f"s04-celda-{i:02d}"  # ids fijos: regenerar el notebook no produce diferencias espurias en git
nb = new_notebook(cells=cells)
nb.metadata = {
    "kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
    "language_info": {"name": "python"},
    "accelerator": "GPU",
    "colab": {"provenance": [], "gpuType": "T4", "name": "S04_rendimiento_gpu.ipynb"},
}
nbformat.validate(nb)
with open("notebook_colab.ipynb", "w", encoding="utf-8") as f:
    nbformat.write(nb, f)
print(f"notebook_colab.ipynb escrito con {len(cells)} celdas (válido según nbformat {nbformat.__version__})")
