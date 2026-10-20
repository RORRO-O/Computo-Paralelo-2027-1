> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Práctica 6 · publicada el lunes 23 de noviembre de 2026 · Lab 1 martes 24 de noviembre 08:30 · Lab 2 martes 1 de diciembre 08:30 · entrega domingo 6 de diciembre 23:59

# `resultados/` · qué va aquí y cómo se lee el CSV

En el repositorio del curso esta carpeta solo tiene este archivo. En el repositorio de **tu equipo**
(`practicas/P6/resultados/`) debe contener, al entregar:

| Archivo | Quién lo produce | Para qué |
|---|---|---|
| `resultados_P6_<AAAA-MM-DD>.csv` (uno por sesión de medición) | La sección 9 del `notebook_colab.ipynb` (la fecha la agrega sola) | Tabla de la Parte D; lo lee `graficar.py` |
| `tiempo_vs_bloque.png`, `speedup_vs_n.png`, `transferencias.png` | `python3 graficar.py resultados/resultados_P6_*.csv -o resultados` (o `make graficas`) | Las gráficas de `REPORTE.md` |
| `entorno.txt` | La misma sección 9: `nvidia-smi` (modelo de GPU, controlador, memoria), `nvcc --version`, CPU de la máquina y fecha | Sin modelo de GPU y fecha la medición no cuenta (`herramientas/protocolo-medicion.md` §1.4 y §5) |
| `hist_cpu.txt` (opción 1 de la Parte C) | `./c_histograma_cpu <n> --volcar hist_cpu.txt` | Las 256 cuentas de referencia para comparar tu histograma completo |
| Primera fila de la tabla de la Parte D | Tarea espaciada de la S04 (lunes 30 de noviembre), que cada integrante entrega en `tareas/<usuario-github>/U5-S04.md`; el equipo copia aquí la fila | Pre-mortem y primera fila de la tabla; el profesor usa la tarea en las mini-defensas del Lab 2 |
| Captura fechada del aviso de cuota (solo si aplica) | Tú, si Colab **y** Kaggle niegan GPU en las 48 h previas a la entrega | Evidencia para entregar la medición como "pendiente" sin penalización (`docs/metodo/04-evaluacion.md` §5) |

Los CSV y PNG **sí** se versionan (son la evidencia); los binarios no. Una sesión de medición = una GPU = un
archivo CSV: nunca mezcles en una fila corridas de sesiones o de GPU distintas (si el martes te dieron una T4 y el
jueves una P100, son dos archivos y lo dices en el reporte).

## Esquema del CSV (el mismo de la sesión S04; lo escribe `emit_row` de `src/common.cuh`)

```
experimento,kernel,n,block,grid,ocupacion_pct,memoria,t_h2d_ms,t_kernel_ms,t_d2h_ms,t_total_ms,t_cpu_ms,speedup_kernel,speedup_total,ancho_banda_gbs,origen,dispositivo
```

| Columna | Significado |
|---|---|
| `experimento` | `uno` (una configuración), `umbral` (barrido de `n` con bloque fijo) o `bloque` (barrido de bloque con `n` fijo). La multiplicación de la Parte A y la Parte C usan `bloque`; la Parte B, `uno`. Si mides tu *kernel* de la Parte C con varios `n` y bloque fijo, usa `umbral`: así entra en `speedup_vs_n.png` |
| `kernel` | Nombre del *kernel*: `vector_add`, `saxpy`, `matmul_naive`, `matmul_tiled` (Parte A), `matmul_rect_naive`, `matmul_rect_tiled` (Parte B), y el de tu Parte C (p. ej. `histograma_shared`, `jacobi_2d`) |
| `n` | Elementos del problema (en matrices cuadradas, `n` es el lado; en las rectangulares de la Parte B, `M·N`, los elementos de `C`; en Jacobi, `alto·ancho`) |
| `block`, `grid` | Hilos por bloque (en 2D, `bx·by`) y bloques totales lanzados |
| `ocupacion_pct` | Ocupación teórica que `cudaOccupancyMaxActiveBlocksPerMultiprocessor` da para ese bloque (`occupancy_pct` de `common.cuh`) |
| `memoria` | `pageable` (`malloc`) o `pinned` (`cudaMallocHost`; extensión opcional) |
| `t_h2d_ms`, `t_kernel_ms`, `t_d2h_ms` | Medianas de 5 repeticiones (tras 1 calentamiento) de las copias anfitrión→dispositivo, del *kernel* solo y de la copia de regreso, medidas con `cudaEvent_t` |
| `t_total_ms` | `t_h2d + t_kernel + t_d2h`: el tiempo **con** transferencias |
| `t_cpu_ms` | Mediana de la referencia secuencial en la **misma máquina** (`-O2`): el `T(1)` del protocolo, de la misma operación que el *kernel* de la fila (en la opción 1 de la Parte C, el histograma y la suma se miden por separado) |
| `speedup_kernel` | `t_cpu / t_kernel` (**sin** copias) |
| `speedup_total` | `t_cpu / t_total` (**con** copias): el que vale cuando los datos empiezan y terminan en la CPU |
| `ancho_banda_gbs` | Bytes útiles que mueve el *kernel* (entradas + salidas) entre `t_kernel`; compáralo con los ≈ 320 GB/s teóricos de una T4 |
| `origen` | `gpu` si se midió; `prueba`/`ilustrativo`/`modelo` si no. `graficar.py` lo pone en el título de cada gráfica |
| `dispositivo` | Nombre que reporta `cudaGetDeviceProperties` (sin comas) |

Columna opcional `t_omp4_ms`: si tu equipo tiene una versión OpenMP del mismo *kernel* (Práctica 4 o V2 del
proyecto), mide su mediana con 4 hilos **en la misma máquina** (en Colab hay 2 vCPU: decláralo) y agrégala al CSV
con ese encabezado; `graficar.py` dibuja entonces la curva "con copias vs. OpenMP 4 hilos" en `speedup_vs_n.png`.

## Cómo volver a dibujar

```bash
make graficas                                    # python3 graficar.py resultados/*.csv -o resultados
python3 graficar.py resultados/resultados_P6_2026-12-01.csv -o resultados   # un archivo concreto
```

`graficar.py` imprime además la tabla en Markdown (pégala en `REPORTE.md`) y un resumen: mejor bloque por *kernel*,
primer `n` con *speedup* > 1 sin y con copias, y porcentaje de copias en el `n` más grande.
