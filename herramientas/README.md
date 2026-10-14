# Herramientas del curso

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · `herramientas/` · versión 1.0 · 14 de octubre de 2026

Scripts, cabeceras y plantillas que usan todas las prácticas (P4–P6), los hitos del proyecto (H1, H2) y la
entrega final. Todo está probado: `make test` en esta carpeta ejecuta las pruebas de cada herramienta (OpenMP,
MPI, gráficas y plantillas) y termina con código 0 solo si todo pasa. Cada script trae su uso en la cabecera
(`./medir.sh -h`, `python3 graficar_speedup.py -h`, las primeras líneas de los `.h`, `.c` y `Makefile.*`).

## Índice

| Archivo | Para qué (una línea) | Comando de ejemplo (desde `herramientas/`, tras `make`) |
|---|---|---|
| `protocolo-medicion.md` | El protocolo que toda medición del curso sigue: calentamiento, ≥ 5 repeticiones, mediana, T(1) secuencial, columnas del CSV | (lectura) |
| `medir.sh` | Corre un programa con una lista de hilos (OpenMP), procesos (`--mpi`) o en GPU (`-t gpu`), 1 calentamiento + R repeticiones, lee `tiempo_s=` y escribe el CSV del protocolo y `entorno.txt` | `./medir.sh -c openmp -t "1 2 4 8" -n 100000000 -o resultados/m.csv -- ./ejemplo_cronometro.out` |
| `cronometro.h` | Cabecera C (`static inline`): `cron_ahora()` (omp_get_wtime o clock_gettime), `cron_mediana()`, `cron_imprimir_tiempo()`, `cron_csv_fila()` | `#include "cronometro.h"` (primero) y compilar con `-std=c11 -O2 -Wall -Wextra [-fopenmp]` |
| `ejemplo_cronometro.c` | Ejemplo de uso de `cronometro.h` (pi por rectángulos; OpenMP o secuencial según se compile) | `OMP_NUM_THREADS=4 ./ejemplo_cronometro.out 100000000 5 pruebas.csv 0.95` |
| `ejemplo_mpi.c` | "Hola MPI" medible con `MPI_Wtime` para probar `medir.sh --mpi` y `Makefile.mpi` | `MPIRUN_FLAGS=--oversubscribe ./medir.sh --mpi -c mpi -t "1 2 4" -n 100000000 -o m.csv -- ./ejemplo_mpi.out` |
| `ejemplo_gpu.cu` | Suma de vectores en CUDA C con tiempo con y sin transferencias; salida `clave=valor` que lee `medir.sh` | `nvcc -O2 -arch=sm_75 ejemplo_gpu.cu -o ejemplo_gpu && ./ejemplo_gpu 50000000` (en Colab; aquí solo `nvcc -c`) |
| `graficar_speedup.py` | Lee el CSV del protocolo (cualquier número de `rep`) y genera `speedup.png` (con la ideal S = p) y `eficiencia.png`; imprime la tabla Markdown con Karp–Flatt | `python3 graficar_speedup.py ejemplo_resultados.csv --titulo "pi por rectángulos" --salida resultados` |
| `ejemplo_resultados.csv` | CSV real con el formato del protocolo (secuencial, openmp 1–8, mpi 1–4) para probar las gráficas; su entorno está en `ejemplo_entorno.txt` | `python3 graficar_speedup.py ejemplo_resultados.csv` |
| `Makefile.openmp` | Plantilla de `Makefile` para C + OpenMP con `all`/`run`/`test`/`medir`/`grafica`/`clean` y las banderas de las convenciones; compila también la referencia secuencial | `cp Makefile.openmp ../mi-carpeta/Makefile` y editar la sección "Ajusta aquí" |
| `Makefile.mpi` | Lo mismo para C + MPI (`mpicc`, `mpirun -np` con `$(MPIRUN_FLAGS)`) | `make -f Makefile.mpi SRC=ejemplo_mpi.c SRC_SEQ=ejemplo_cronometro.c BIN=mpi.out run` |
| `plantilla-run_tests.sh` | Esqueleto de `tests/run_tests.sh`: compara la versión paralela contra la secuencial con tolerancia (awk o python3), PASS/FAIL por caso, código 0 solo si todo pasa | `PROGRAMA_SEQ=./ejemplo_cronometro_seq.out PROGRAMA_PAR=./ejemplo_cronometro.out ./plantilla-run_tests.sh` |
| `plantilla-reporte-practica.md` | `REPORTE.md` de ≤ 3 páginas con las secciones de `03-plantilla-practica.md` y lista de cotejo contra la rúbrica | copiar a `practicas/Pn/REPORTE.md` y llenar |
| `colab-kaggle.md` | Guía paso a paso para la GPU en Colab y Kaggle: activar, `nvidia-smi`, `%%writefile`, `nvcc -arch`, medir con `medir.sh`, guardar el CSV, cuotas, qué hacer sin GPU, cómo documentar la GPU | (lectura; Práctica 6 y V3) |
| `seguimiento-grupo.csv` + `seguimiento-grupo.md` | Hoja del profesor con los indicadores de `01-marco-pedagogico.md` §5 y cómo llenarla en 5 minutos | `grep ALERTA seguimiento-grupo.csv` |
| `Makefile`, `tests/run_tests.sh` | Compilan los ejemplos y prueban todas las herramientas de esta carpeta | `make && make test` |

## Flujo típico en una práctica o en el proyecto

```bash
cp herramientas/Makefile.openmp practicas/P4/Makefile          # 1. Makefile con las banderas del curso
cp herramientas/plantilla-run_tests.sh practicas/P4/tests/run_tests.sh
cp herramientas/medir.sh herramientas/graficar_speedup.py practicas/P4/
cd practicas/P4 && make && make test                           # 2. correcto antes que rápido
make medir N=200000000 HILOS="1 2 4 8"                         # 3. protocolo: secuencial (T1) y OpenMP
make grafica                                                   # 4. speedup.png, eficiencia.png y tabla Markdown
```

El programa medido solo tiene que imprimir `tiempo_s=<segundos>` de la región de interés (y aceptar `n` como
último argumento). `cronometro.h` lo hace en una línea; la convención completa está en la cabecera de `medir.sh`.

## Relación con las plantillas del proyecto

`proyecto/plantillas/run_all.sh` es la variante de `medir.sh` ajustada a las etiquetas del proyecto (`V1`, `V2`,
`V3`, filas `-kernel` automáticas, columnas extra `min_s,max_s`); `proyecto/plantillas/graficar_proyecto.py`
añade la gráfica de comparación entre versiones. Los CSV de ambos flujos se leen con `graficar_speedup.py`
(tolera las columnas extra). No mezcles en un mismo archivo filas con distinto encabezado.

## Sobre `ejemplo_resultados.csv`

Son mediciones reales hechas el 14 de octubre de 2026 en el contenedor donde se generó este material (4 vCPU
Intel Xeon 2.80 GHz compartidas, 16 GB; detalle en `ejemplo_entorno.txt`), con `n = 8·10⁸` rectángulos
(T(1) = 1.13 s). Sirven para probar el formato y las gráficas, y también para discutir: la eficiencia de OpenMP cae
por debajo de 50 % a partir de 8 hilos en 4 núcleos (sobre-suscripción) y MPI escala peor que OpenMP en este
problema porque el reparto por procesos paga la creación de procesos y la reducción. No son valores de
referencia para ninguna práctica: cada equipo mide en su máquina y la declara.

## Pruebas

```bash
cd herramientas && make clean && make && make test
```

Cubre: `cronometro.h` (reloj OpenMP y `clock_gettime`, mediana, fila CSV), `medir.sh` (OpenMP, `--mpi`, `-t gpu`,
`--clave`, `--t1`, códigos de salida 2/3/4), `graficar_speedup.py` (CSV de 5 y de 3 repeticiones, columnas extra,
filas `gpu`, recálculo desde T(1)), `plantilla-run_tests.sh` (OpenMP y MPI, detección de diferencias),
`Makefile.openmp` y `Makefile.mpi` en una carpeta temporal, y `nvcc -c -arch=sm_75` de `ejemplo_gpu.cu`. Las
pruebas de MPI y de CUDA se omiten con aviso si no hay `mpirun` o `nvcc`.
