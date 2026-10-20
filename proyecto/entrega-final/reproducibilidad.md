# Reproducibilidad: qué debe poder hacer el profesor en 10 minutos

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Entrega final · lunes 7 de diciembre de 2026, 10:30 · Aplica a los criterios C4 y C5 de `rubrica-codigo.md` y R4–R5 de `rubrica-reporte.md` · versión 1.1 · 20 de octubre de 2026

## 1. La regla de los 10 minutos

El profesor revisa cada repositorio en una máquina limpia (Linux con gcc 13, OpenMP, make, bash, git, python3 con numpy y
matplotlib; sin GPU) y le dedica 10 minutos a comprobar que lo entregado se puede reproducir. Lo que no se logre en ese
tiempo se califica como si no estuviera (C5 Insuficiente; C1–C4 solo con lo verificable en la demo de la defensa).

| Minuto | Qué hace el profesor | Qué debe pasar | Si no pasa |
|---|---|---|---|
| 0–1 | `git clone <URL> && cd cp-6bm1-equipoNN && git checkout entrega-final` | Clona; la etiqueta existe (si no, usa el último *commit* de `main` anterior a las 10:30 del lunes 7 de diciembre) | Sin etiqueta: aviso, no penaliza |
| 1–2 | Lee `README.md` §1–§3 | Entiende qué problema es, de dónde salen los datos, qué comandos correr y qué archivo produce cada tabla del PDF | C5 baja un nivel |
| 2–4 | `make` | V1 y V2 compilan sin *warnings*; la V3 se verifica con `nvcc -c` si hay `nvcc`, o se avisa que no | No compila: C5 Insuficiente, se pasa a la defensa |
| 4–5 | `make test` | Código 0; todos los casos `PASS`; hay casos propios del equipo | Falla: C1 Insuficiente |
| 5–8 | `./run_all.sh --rapido` | Termina con código 0 en ≤ 3 min y escribe en `resultados/rapido/` (entorno, CSV, tabla, gráfica) sin tocar `resultados/`; el aviso "T(1) < 1 s" es normal en `--rapido` | Falla: C5 En desarrollo o menor |
| 8–9 | Abre `resultados/mediciones.csv` y el CSV de la V3 y compara con las tablas del PDF | Cabecera del protocolo; `T(1)` ≥ 1 s; filas `v1`, `v2`×k, `v3_kernel`, `v3_total`; los números del PDF están ahí | No coinciden: R5 Insuficiente y C4 afectado |
| 9–10 | Abre `v3/notebook_colab.ipynb` en GitHub y `resultados/entorno_gpu.txt` | Salidas visibles: `nvidia-smi` con el modelo de GPU, `PASS v3 == v1`, medianas; fecha de la sesión; el código de las celdas es el del repositorio | Sin salidas: C5 En desarrollo; sin `PASS`: C1 En desarrollo; código distinto: C5 Insuficiente |

Para saber de antemano cómo le irá a tu repositorio: `scripts/verificar_entrega.sh` hace estos pasos (menos leer el PDF)
sobre un clon y reporta PASS/FAIL/AVISO por ítem de `lista-cotejo-entrega.md` (§5 de este documento).

## 2. Contrato del repositorio

La estructura es la de `proyecto/README.md` §4 (la misma desde H1); `plantilla-repo/` la cumple. El verificador acepta
también la variante con las versiones bajo `src/` y la bitácora como `bitacora-errores.md`.

### 2.1 `make`

- `Makefile` en la raíz con `all`, `run`, `test`, `clean`; llama a los `Makefile` de cada versión. `make test` termina con
  código 0 solo si todo pasa.
- Banderas del curso: `gcc -std=c11 -O2 -Wall -Wextra [-fopenmp]`; `nvcc -O2 -arch=sm_75 -Xcompiler -Wall,-Wextra`.
  Sin *warnings*. Si necesitas otra bandera (p. ej. `-march=native`), decláralo en el README y en `entorno.txt`, y mide con
  y sin ella si cambia el tiempo.
- Nada de rutas absolutas (`/home/usuario/...`), ni dependencias de variables de entorno que no estén documentadas.
- Si no hay `nvcc` en la máquina, `make` avisa y no falla: la V3 se ejecuta en Colab/Kaggle.

### 2.2 `run_all.sh`

Es el único comando que el profesor necesita para reproducir todo lo medible en CPU. Debe:

1. Escribir `resultados/entorno.txt` con CPU (modelo, núcleos físicos y lógicos), RAM, SO, compilador, banderas, fecha,
   *commit*, `n`, semilla, lista de hilos y repeticiones.
2. Compilar (`make all`) y probar (`make test`); si una prueba falla, **abortar** con código distinto de 0.
3. Medir V1 y V2 con el protocolo: una ejecución de calentamiento que no se registra y ≥ 5 repeticiones por
   configuración; hilos 1, 2, 4, … hasta los núcleos físicos y uno más allá (declarado); mismo `n` y semilla en todas
   las filas.
4. Escribir `resultados/mediciones.csv` con la cabecera `config,hilos,n,rep1,…,repK,mediana_s,speedup,eficiencia`.
5. Generar la tabla y la gráfica (`herramientas/resumen_csv.py`), si hay python3 con matplotlib; si no, avisar y seguir.
6. Aceptar `--rapido`: tamaño pequeño, el flujo completo en segundos, **todo** en `resultados/rapido/` (que va en
   `.gitignore`) y código 0. Así nadie hace *commit* por accidente de un CSV de `--rapido` (ítem 11 de la lista).

Lo que **no** debe hacer: pedir `sudo`, instalar paquetes sin avisar, descargar cosas sin documentarlo, escribir en
`resultados/` en modo `--rapido`, ni depender de que exista una GPU. En modo completo sí regenera `resultados/`: es su
función, y el equipo decide si hace *commit* de lo nuevo (y anota en la bitácora por qué cambió).

`herramientas/medir_proyecto.sh` (de `proyecto/plantillas/`) mide **una** configuración a la vez (perfil de H1,
experimentos de `schedule`, la V3 en Colab). Un `run_all.sh` propio puede llamarlo; el de `plantilla-repo/` no lo
necesita.

### 2.3 Los programas

- Aceptan `[n] [semilla] [hilos]` por línea de comandos (en la V3 el tercero es hilos por bloque, múltiplo de 32); con
  argumentos inválidos terminan con código distinto de 0 y mensaje en `stderr`.
- Imprimen `clave=valor`, una por línea:

  | Versión | Claves mínimas |
  |---|---|
  | V1 y V2 | `version=`, `n=`, `semilla=`, `hilos=` (los que realmente usó), `tiempo_s=`, `checksum=` |
  | V3 | `version=`, `n=`, `semilla=`, `gpu=`, `hilos_por_bloque=`, `tiempo_kernel_s=` (sin transferencias), `tiempo_total_s=` (con transferencias), `checksum=` |

- Cronometran **solo** la región de interés: ni lectura de archivos, ni generación de datos, ni impresión. La creación del
  equipo de hilos (V2) y la carga del módulo CUDA en el primer lanzamiento (V3) quedan fuera con un calentamiento dentro
  del programa, como en `plantilla-repo/v2/main.c` y `plantilla-repo/v3/kernel.cu`.
- Relojes: `clock_gettime(CLOCK_MONOTONIC)` u `omp_get_wtime()` en CPU; `cudaEvent_t` en CUDA C;
  `cuda.event()`/`cupy.cuda.Event` en Python. Nunca `clock()` (suma el tiempo de CPU de todos los hilos).

### 2.4 Semillas y datos

- Todos los datos de entrada se generan desde una semilla declarada o se leen de un archivo cuyo origen está documentado.
  Para generar, usa un generador propio determinista (como el LCG de `comun/problema.h`), no `rand()`: su secuencia
  cambia entre bibliotecas de C.
- V1, V2 y V3 reciben los **mismos datos** (misma `n`, misma semilla); así el `checksum` es comparable y las pruebas tienen
  sentido.
- Archivos de datos: si pesan ≤ 10 MB, van en el repositorio (`datos/`). Si pesan más, va un script `datos/descargar.sh` con
  la URL y la suma SHA-256 esperada, y el README lo dice. Un repositorio que no clona en un minuto por el peso de los datos
  no reproduce.
- Semilla de las pruebas y semilla de las mediciones pueden ser distintas; ambas van en el README §1.

### 2.5 Versiones

El README declara con qué versiones se midió: `gcc --version`, `nvcc --version` (la de Colab), `python3 --version` y las de
`numpy`, `matplotlib` y, si aplica, `numba` o `cupy` (`pip show`). `entorno.txt` y `entorno_gpu.txt` lo repiten
automáticamente para que el dato no dependa de que alguien lo haya copiado bien.

## 3. Cómo documentar la GPU de Colab/Kaggle

La GPU asignada **cambia entre sesiones** (T4, L4, P100…) y a veces dentro del día. Por eso:

1. **Todo lo de la V3 se mide en una sola sesión**: V1 compilada en Colab (para `T(1)` de la misma máquina), verificación
   y las repeticiones de V3. Nunca se mezclan filas de sesiones distintas en un mismo `mediciones_v3.csv`.
2. La **celda 1** del *notebook* escribe `entorno_gpu.txt` con `nvidia-smi --query-gpu=name,driver_version,memory.total,compute_cap`,
   la fecha UTC, la versión de `nvcc` y la CPU anfitriona. Ese archivo se descarga a `resultados/` tal cual.
3. En el reporte (§7) se cita: modelo de GPU, memoria, driver, `nvcc`, fecha. Si se repitió la medición otro día con otra
   GPU, se reporta como otra tabla, no se promedia ni se sustituye en silencio (va a la bitácora: "mediciones descartadas").
4. `-arch=sm_75` es la T4 de Colab gratuito. Si la GPU es otra, cambia `ARCH` en `v3/Makefile` y regenera el *notebook* con
   `--arch` (p. ej. `--arch sm_60` para P100, `--arch sm_89` para L4), y anótalo. Una arquitectura equivocada o compila y no
   corre, o corre con JIT y mide otra cosa.
5. Kaggle sirve igual y tiene su propia cuota semanal de GPU (revisa la vigente en tu perfil): *Settings → Accelerator →
   GPU T4 x2* (usa una) *o P100*; para guardar un *notebook* ejecutado usa *Save Version → Save & Run All* y descarga la
   salida.

## 4. Cómo incluir el notebook ejecutado

El *notebook* es la evidencia de que la V3 corrió en una GPU, dio el mismo resultado que V1 y se midió como dice el
protocolo. Sin salidas no es evidencia.

1. Genera el *notebook* desde el código fuente (así no hay dos copias del *kernel* que divergen):
   `python3 herramientas/generar_notebook_v3.py --fuente v3/kernel.cu --cabecera comun/problema.h --v1 v1/main.c --salida v3/notebook_colab.ipynb --equipo NN`.
   Para Numba/CuPy: `--fuente v3/main_gpu.py`; la cabecera se incluye igual, porque la V1 la necesita. El programa debe
   imprimir las mismas claves que la V3 en C.
2. Súbelo a Colab, activa la GPU y ejecuta todo. Revisa que las celdas 1 (`nvidia-smi`), 4 (`PASS v3 == v1`) y 5
   (medianas y CSV) tengan salida.
3. *Archivo → Descargar → .ipynb*. Ese archivo, **con salidas**, reemplaza `v3/notebook_colab.ipynb` en el repositorio.
   No uses `nbstripout` ni "Borrar todas las salidas" antes de subirlo.
4. Descarga `mediciones_v3.csv` y `entorno_gpu.txt` (panel de archivos de Colab) a `resultados/`.
5. `git add v3/notebook_colab.ipynb resultados/mediciones_v3.csv resultados/entorno_gpu.txt && git commit`.
6. Comprueba en GitHub que el *notebook* se ve con sus salidas (GitHub renderiza `.ipynb`). El verificador revisa esto en
   los ítems 16 y 17.
7. Si cambias `v3/kernel.cu`, `comun/problema.h` o `v1/main.c` después, repite desde el paso 1: el verificador compara las
   celdas `%%writefile` con el repositorio y marca FAIL en el ítem 16 si no coinciden. Un *notebook* cuyo código no
   coincide con el del repositorio cuenta como "describe código distinto" (C5 Insuficiente).

Numba CUDA y CuPy: para probar la lógica del *kernel* sin GPU usa `NUMBA_ENABLE_CUDASIM=1 python3 v3/main_gpu.py 1000 1`
(simulador; **no** sirve para medir). CuPy no tiene simulador: las pruebas de la V3 en CuPy se corren en Colab.

## 5. Antes de etiquetar: prueba en un clon limpio

Desde la carpeta que contiene tu repositorio (`RUTA_CURSO` es donde clonaste el repositorio del curso):

```bash
rm -rf prueba-entrega && git clone <URL de cp-6bm1-equipoNN> prueba-entrega
bash RUTA_CURSO/proyecto/entrega-final/scripts/verificar_entrega.sh prueba-entrega
```

El verificador termina con código 0 solo si no hay ningún `FAIL`. `--sin-ejecutar` revisa solo archivos y git (segundos);
`--sin-red` no consulta GitHub para confirmar la etiqueta. Causas típicas de "en mi máquina sí funcionaba": rutas
absolutas, archivo de datos que no está en git, `-lm` faltante al enlazar, `Makefile` que asume `clang` o una versión de
`gcc`, `run_all.sh` sin permiso de ejecución, *notebook* subido sin salidas o desactualizado, CSV generado con `--rapido`.
