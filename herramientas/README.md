# Herramientas del curso

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · `herramientas/` · versión 1.1 · 20 de octubre de 2026

Scripts, cabeceras y plantillas que usan las prácticas (P4–P6), los hitos del proyecto (H1, H2) y la entrega
final, más la hoja de seguimiento del profesor. Cada script trae su uso en la cabecera (`./medir.sh -h`,
`python3 graficar_speedup.py -h`, `python3 seguimiento.py -h`, las primeras líneas de los `.h`, `.c` y
`Makefile.*`). `make test` ejecuta todos los comandos de la tabla de abajo y las pruebas de cada herramienta, y
termina con código 0 solo si todo pasa.

Antes de los ejemplos, desde `herramientas/`:

```bash
make            # ejemplo_cronometro.out (OpenMP), ejemplo_cronometro_seq.out y, si hay mpicc, ejemplo_mpi.out
export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1   # solo si corres MPI como root (contenedores)
```

Los ejemplos escriben en `resultados/` y dejan binarios `*.out`; `make clean` borra ambos.

## Índice

| Archivo | Para qué | Comando de ejemplo (desde `herramientas/`, tras `make`) |
|---|---|---|
| `protocolo-medicion.md` | El protocolo que toda medición del curso sigue: calentamiento, ≥ 5 repeticiones, mediana, T(1) secuencial, columnas del CSV | (lectura) |
| `medir.sh` | Corre un programa con una lista de hilos: 1 calentamiento + R repeticiones, lee la línea `tiempo_s=<valor>`, agrega filas al CSV del protocolo y escribe `entorno.txt` | `./medir.sh -c openmp -t "1 2 4" -n 20000000 -- ./ejemplo_cronometro.out` |
| `medir.sh --mpi` | Lo mismo con procesos: `mpirun $MPIRUN_FLAGS -np P` | `MPIRUN_FLAGS=--oversubscribe ./medir.sh --mpi -c mpi -t "1 2 4" -n 20000000 -- ./ejemplo_mpi.out` |
| `graficar_speedup.py` | Lee el CSV del protocolo (cualquier número de `rep`) y genera `speedup.png` (con la ideal S = p) y `eficiencia.png`; imprime la tabla Markdown con Karp–Flatt | `python3 graficar_speedup.py ejemplo_resultados.csv --titulo "pi por rectángulos" --salida resultados` |
| `cronometro.h` | Cabecera C (`static inline`): `cron_ahora()` (`omp_get_wtime` con `-fopenmp`, `clock_gettime` sin él), `cron_mediana()`, `cron_imprimir_tiempo()`, `cron_csv_fila()` | `OMP_NUM_THREADS=2 ./ejemplo_cronometro.out 20000000 5` |
| `ejemplo_cronometro.c` | Uso de `cronometro.h` (pi por rectángulos); la misma fuente es la versión OpenMP y, sin `-fopenmp`, la referencia secuencial | `./ejemplo_cronometro_seq.out 20000000` |
| `ejemplo_mpi.c` | Pi con MPI medible con `MPI_Wtime` (máximo entre procesos); prueba `medir.sh --mpi` y `Makefile.mpi` | `mpirun --oversubscribe -np 4 ./ejemplo_mpi.out 20000000` |
| `ejemplo_gpu.cu` | Suma de vectores en CUDA C con tiempo con y sin transferencias (`tiempo_s=`, `tiempo_kernel_s=`); se ejecuta en Colab o Kaggle (`colab-kaggle.md` §4–§6); aquí solo se compila | `nvcc -c -arch=sm_75 ejemplo_gpu.cu -o ejemplo_gpu.o` |
| `ejemplo_resultados.csv`, `ejemplo_entorno.txt` | Mediciones reales con el formato del protocolo (secuencial, OpenMP 1–8, MPI 1–4) y su entorno; ver la sección de abajo | `grep corrida ejemplo_entorno.txt` |
| `Makefile.openmp` | Plantilla comentada de `Makefile` para C + OpenMP: `all`, `run`, `test`, `medir`, `grafica`, `clean`, banderas de las convenciones y referencia secuencial | `make -f Makefile.openmp SRC=ejemplo_cronometro.c BIN=ej.out N=1000 run` |
| `Makefile.mpi` | Lo mismo para C + MPI (`mpicc`, `mpirun -np` con `$(MPIRUN_FLAGS)`) | `make -f Makefile.mpi SRC=ejemplo_mpi.c SRC_SEQ=ejemplo_cronometro.c BIN=mpi.out MPIRUN_FLAGS=--oversubscribe N=1000 run` |
| `plantilla-run_tests.sh` | Esqueleto de `tests/run_tests.sh`: paralelo contra secuencial con tolerancia, PASS/FAIL por caso, código 0 solo si todo pasa, OpenMP o MPI | `PROGRAMA_SEQ=./ejemplo_cronometro_seq.out PROGRAMA_PAR=./ejemplo_cronometro.out ./plantilla-run_tests.sh` |
| `plantilla-reporte-practica.md` | `REPORTE.md` de ≤ 3 páginas con las secciones de `03-plantilla-practica.md` y la lista de cotejo contra la rúbrica | (plantilla: se copia a `practicas/Pn/REPORTE.md` del repositorio del equipo) |
| `colab-kaggle.md` | Guía paso a paso de la GPU en Colab y Kaggle: activar, `nvidia-smi`, `%%writefile`, `nvcc -arch`, medir con `medir.sh`, guardar el CSV, cuotas, qué hacer sin GPU, Numba y CuPy | (lectura; Práctica 6 y V3) |
| `seguimiento-grupo.csv`, `seguimiento-grupo.md` | Plantilla vacía de la hoja del profesor con los indicadores de `01-marco-pedagogico.md` §5 y cómo llenarla en 5 minutos; la copia llena vive en `docente/` | (plantilla: `cp seguimiento-grupo.csv ../docente/`) |
| `seguimiento.py` | Lee la hoja llena, calcula los seis indicadores y marca cada umbral cruzado con `ALERTA`; solo imprime agregados | `python3 seguimiento.py seguimiento-grupo.csv` |
| `Makefile`, `tests/run_tests.sh` | Compilan los ejemplos y prueban todas las herramientas de esta carpeta | `make test` |

## Flujo típico en una carpeta nueva

Las prácticas y la plantilla del proyecto (`proyecto/entrega-final/plantilla-repo/`) ya traen su `Makefile` y sus
pruebas. Estas plantillas son para lo que no las trae: un experimento propio, la extensión opcional de una
práctica o una V2 que no parte de la plantilla del proyecto. Desde la raíz del repositorio del equipo, con una
copia de esta carpeta en `herramientas/`:

```bash
mkdir -p mi-experimento/tests && cd mi-experimento
cp ../herramientas/Makefile.openmp Makefile                     # 1. banderas del curso; edita "Ajusta aquí"
cp ../herramientas/plantilla-run_tests.sh tests/run_tests.sh
cp ../herramientas/medir.sh ../herramientas/graficar_speedup.py ../herramientas/cronometro.h .
# main.c imprime resultado=<valor> y tiempo_s=<segundos> (cronometro.h) y acepta n como último argumento
make && make test                                               # 2. correcto antes que rápido
make medir N=800000000 HILOS="1 2 4 8"                          # 3. protocolo: secuencial (T1) y luego OpenMP
make grafica                                                    # 4. speedup.png, eficiencia.png y tabla Markdown
```

`make medir` agrega filas a `resultados/mediciones.csv`: si lo repites, borra antes el CSV o usa `CSV=` con otro
nombre, para no mezclar corridas. El tamaño `N` se elige para que la versión secuencial tarde ≥ 1 s
(protocolo §2).

## Relación con las plantillas del proyecto

`proyecto/plantillas/run_all.sh` es la variante de `medir.sh` ajustada al proyecto (etiquetas `V1`, `V2`, `V3`,
filas `-kernel` automáticas, columnas extra `min_s,max_s`); en el repositorio del equipo se copia como
`herramientas/medir_proyecto.sh`. `proyecto/plantillas/graficar_proyecto.py` añade la gráfica de comparación entre
versiones. `graficar_speedup.py` lee los CSV de ambos flujos (tolera las columnas extra). No mezcles en un mismo
archivo filas con distinto encabezado.

## Sobre `ejemplo_resultados.csv`

Son las mediciones que producen los ejemplos de la cabecera de `medir.sh`, corridos el 20 de octubre de 2026 en
el contenedor donde se verificó este material (4 vCPU Intel Xeon a 2.10 GHz, 1 hilo por núcleo, 16 GB; las
líneas `corrida:` de `ejemplo_entorno.txt` dicen qué se corrió). `n = 8·10⁸` rectángulos, T(1) = 1.07 s. Sirven
para probar el formato y las gráficas, y para discutir tres cosas con datos:

- **Hasta 4 hilos o procesos** OpenMP y MPI escalan parecido (E(4) = 0.91 y 0.88): el problema reparte trabajo
  independiente y la única comunicación es una reducción al final.
- **Con 8 hilos en 4 núcleos** la eficiencia cae a 0.47: el *speedup* casi no pasa de 3.65 a 3.72 porque no hay
  más núcleos (sobre-suscripción; `medir.sh` avisa y el protocolo pide declararla).
- **f de Karp–Flatt negativa** en OpenMP con 2 hilos (−0.003): S(2) = 2.006 está dentro del ruido de la mediana;
  no es *speedup* superlineal que haya que explicar.

No son valores de referencia para ninguna práctica: cada equipo mide en su máquina y la declara.

## Pruebas

```bash
cd herramientas && make clean && make && make test
```

`tests/run_tests.sh` trabaja en una carpeta temporal fuera del repositorio (la borra si todo pasa; si algo falla,
imprime su ruta). Cubre:

- `cronometro.h`: reloj OpenMP y `clock_gettime`, mediana, mín y máx, fila CSV, y el `#error` si se incluye después
  de `<stdio.h>` sin `-fopenmp`.
- `medir.sh`: modos OpenMP, `--mpi` y `-t gpu`; `--clave`, `--t1`, `n` leído de la salida; mediana; líneas
  `corrida:` de `entorno.txt`; avisos de línea base y sobre-suscripción; códigos de salida 2, 3 y 4; y los
  ejemplos de su cabecera con `n` pequeño.
- `graficar_speedup.py`: CSV de 5 y de 3 repeticiones, columnas extra, filas `gpu`, recálculo desde T(1), `-h` y
  rechazo de un CSV sin `mediana_s`.
- `plantilla-run_tests.sh`: OpenMP y MPI, detección de una diferencia mayor que la tolerancia, aviso de
  `TODO pendiente`.
- `Makefile.openmp` y `Makefile.mpi` en una carpeta nueva: compilan sin *warnings*, `run`, `test`, `medir`,
  `grafica`, `clean`.
- `seguimiento.py`: plantilla vacía, los seis indicadores con sus umbrales, `--alertas`, las filas de ejemplo de
  `seguimiento-grupo.md` y rechazo de un encabezado ajeno.
- `colab-kaggle.md`: los fragmentos de Python compilan; el de Numba corre con `NUMBA_ENABLE_CUDASIM=1` si numba
  está instalado; el `checksum` de la salida esperada coincide con el cálculo; `nvcc -c -arch=sm_75` de
  `ejemplo_gpu.cu` si hay `nvcc`.
- `plantilla-reporte-practica.md`: tiene las secciones de `03-plantilla-practica.md` y los pesos de su lista de
  cotejo suman 100. Todos los `.md` llevan el encabezado de metadatos.
- Cada comando de la tabla del índice, tal cual, en una copia de esta carpeta.

Las pruebas de MPI, CUDA y Numba se omiten con aviso si falta `mpirun`, `nvcc` o numba.
