# cp-6bm1-equipoNN · «Título corto del problema»

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Entrega final: lunes 7 de diciembre de 2026, 10:30 · Defensa: jueves 10 de diciembre de 2026, 10:30–12:00

<!-- Plantilla: sustituye todo lo que está entre «» y borra este comentario. Las secciones son
     obligatorias y en este orden. El profesor lee ESTE archivo primero y le da 10 minutos
     (proyecto/entrega-final/reproducibilidad.md). -->

## 1. Problema y datos

- **Qué calcula el programa (una frase):** «…»
- **Entrada:** «origen de los datos (archivo, generador con semilla, API); tamaño; formato». Si es un
  archivo, cómo obtenerlo o regenerarlo: «comando o URL + suma SHA-256».
- **Salida y cómo se verifica que es correcta:** «checksum / comparación con V1 / solución conocida; tolerancia».
- **Semillas:** V1, V2 y V3 usan la misma semilla «12345» para el mismo `n`; las pruebas usan «…».
- **Por qué es paralelizable (3 líneas):** «…»

## 2. Cómo compilar y correr (sin leer nada más)

```bash
git clone «https://github.com/.../cp-6bm1-equipoNN» && cd cp-6bm1-equipoNN
make                 # V1 y V2; verifica que V3 compila si hay nvcc
make test            # pruebas: código 0 si todo pasa
./run_all.sh --rapido   # flujo completo en ~1 min (NO son las mediciones del reporte)
./run_all.sh            # mediciones del reporte (≈ «N» min en «CPU usada»)
```

Requisitos: gcc ≥ «13» con OpenMP, make, bash, python3 con numpy y matplotlib (solo para la gráfica).
V3: Google Colab o Kaggle con GPU; ver §4.

Cada programa acepta `[n] [semilla] [hilos]` e imprime `clave=valor`:

```bash
./v1/v1 4000000 12345          # secuencial
./v2/v2 4000000 12345 4        # OpenMP con 4 hilos
```

## 3. Cómo reproducir cada tabla y gráfica del reporte

| Figura / tabla del PDF | Comando que la genera | Archivo que produce |
|---|---|---|
| Tabla 1 (V1 vs V2, speedup, eficiencia) | `./run_all.sh --hilos "1 2 4 8"` | `resultados/mediciones.csv`, `resultados/tabla.md` |
| Figura 1 (speedup vs hilos) | ídem | `resultados/speedup.png` |
| Tabla 2 (V3 con y sin transferencias) | `v3/notebook_colab.ipynb`, celdas 1–5 en Colab | `resultados/mediciones_v3.csv`, `resultados/entorno_gpu.txt` |
| «otra figura» | «comando» | «archivo» |

Hardware de las mediciones de CPU: ver `resultados/entorno.txt` (lo escribe `run_all.sh`).
Hardware de la GPU y fecha: ver `resultados/entorno_gpu.txt` (lo escribe la celda 1 del notebook).

## 4. V3 en Colab/Kaggle

1. Abrir `v3/notebook_colab.ipynb` en Colab; activar GPU; *Ejecutar todo*.
2. El notebook compila V1 y V3 en la misma máquina, verifica `checksum(V3) == checksum(V1)` y mide.
3. Descargar el notebook **ejecutado** (con salidas), `mediciones_v3.csv` y `entorno_gpu.txt`; hacer *commit*.
4. Si cambias `v3/kernel.cu`, regenera el notebook: `python3 herramientas/generar_notebook_v3.py --fuente v3/kernel.cu --cabecera comun/problema.h --v1 v1/main.c --salida v3/notebook_colab.ipynb --equipo NN`.

Tecnología de la V3: «CUDA C | Numba CUDA | CuPy». GPU en la que se midió: «modelo y fecha, copiados de entorno_gpu.txt».

## 5. Estructura del repositorio

```
comun/problema.h        datos con semilla, checksum, cómputo por elemento (compartido por V1/V2/V3)
v1/                     V1 secuencial (main.c, Makefile)
v2/                     V2 OpenMP (main.c, Makefile)
v3/                     V3 GPU (kernel.cu o main_gpu.py, Makefile, notebook_colab.ipynb EJECUTADO)
tests/run_tests.sh      pruebas: V2 y V3 contra V1 con tolerancia; casos borde; casos del equipo
herramientas/           resumen_csv.py (tabla + gráfica), generar_notebook_v3.py
resultados/             mediciones.csv, mediciones_v3.csv, entorno.txt, entorno_gpu.txt, *.png, tabla.md
reporte/reporte.pdf     reporte final (8–12 páginas; proyecto/entrega-final/plantilla-reporte.md)
bitacora.md             qué falló, cómo se detectó, qué se cambió (fechado)
run_all.sh              reproduce todo lo medible en CPU
```

## 6. Integrantes y reparto de trabajo

| Integrante (nombre completo) | Usuario de GitHub | Qué hizo (archivos y secciones) | % del trabajo (acordado por el equipo) |
|---|---|---|---|
| «…» | «…» | «…» | «…» |
| «…» | «…» | «…» | «…» |
| «…» | «…» | «…» | «…» |

El historial de *commits* debe respaldar esta tabla. Si no coincide, la defensa individual lo aclara.

## 7. Uso de IA en esta entrega

```
Uso de IA en esta entrega:
- Herramienta(s): «…»
- Para qué la usamos (verde/amarillo): «…»
- Qué fragmento(s) de código vinieron de la IA (archivo y líneas) y cómo los verificamos: «…»
- Qué nos dijo la IA que resultó estar mal: «…»   ← esta línea no es opcional
```

## 8. Estado de la entrega

- Etiqueta de la entrega: `entrega-final` (commit «hash corto»), creada el «fecha y hora».
- Lo que NO funciona o no entendemos todavía (se lee en la defensa, no se penaliza por decirlo): «…»
