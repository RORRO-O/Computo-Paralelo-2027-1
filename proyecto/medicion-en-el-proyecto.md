# Medir en el proyecto: cómo aplicar el protocolo a tu problema

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Guía de medición · versión 1.0 · 14 de octubre de 2026

Esta guía no sustituye a `herramientas/protocolo-medicion.md`: lo aplica a un proyecto con tres versiones, dos
máquinas (tu CPU y la GPU de Colab/Kaggle) y tres entregas. Donde esta guía y el protocolo difieran, manda el
protocolo. Las herramientas que se mencionan están en `proyecto/plantillas/` (`run_all.sh`, `graficar_proyecto.py`,
`plantilla_main.c`) y tienen su uso en la cabecera.

## 1. Qué se mide en cada entrega

| Entrega | Fecha | Qué se mide | Dónde queda |
|---|---|---|---|
| H1 | jueves 29 de octubre, 10:30 | `T(1)` de V1 al tamaño declarado; perfil por secciones; `f_p`; predicción de Amdahl | `resultados/perfil-v1.csv`, `resultados/entorno.txt`, `reporte/H1.md` |
| H2 | lunes 23 de noviembre, 10:30 | V1 y V2 con 1, 2, 4, 8 hilos; *speedup*, eficiencia, Karp–Flatt; experimentos de `schedule` y sincronización | `resultados/mediciones.csv`, `speedup.png`, `reporte/H2.md` |
| Entrega final | lunes 7 de diciembre, 10:30 | Todo lo anterior + V3 con y sin transferencias; comparación V1 vs mejor V2 vs V3 en la misma máquina y, aparte, entre máquinas | `resultados/`, `reporte/reporte.pdf` |
| Defensa | jueves 10 de diciembre | Demo en vivo con tamaño de prueba (segundos, no minutos); la tabla del reporte en pantalla | — |

## 2. Elegir los tamaños del problema

Tres tamaños, declarados en el `README.md` del repositorio desde H1:

| Nombre | Criterio | Para qué |
|---|---|---|
| `N_prueba` | `T(1) < 1 s` (ideal < 0.2 s); varios valores, incluido uno diminuto verificable a mano | `make test` en las tres versiones; TSan; demo en la defensa |
| `N_declarado` | `1 s ≤ T(1) ≤ 10 s` con `-O2` (ideal 2–5 s) | **Toda** medición comparativa: perfil, V2, V3, experimentos |
| `N_grande` (opcional) | El mayor que cabe en la memoria de la GPU y en tu RAM | Mostrar dónde la GPU amortiza las transferencias; va en una tabla aparte |

Cómo encontrar `N_declarado`: parte del tamaño de prueba y duplícalo hasta que la mediana de 5 corridas pase de
1 s. Anota los intentos en la bitácora (tabla "tamaño → `T(1)`"): es evidencia de que el tamaño no se eligió para
que el *speedup* se viera bien.

Restricciones que debes revisar antes de fijarlo:

- **Memoria.** Calcula los bytes: `elementos × tamaño del tipo × número de arreglos`. Debe caber en tu RAM sin
  intercambio (*swap*) y, para V3, en la memoria de la GPU que reporta `nvidia-smi`.
- **Índices.** Con `n` grande, `n*n` desborda `int`. Usa `size_t` o `long` para índices y tamaños.
- **Problemas con varios parámetros.** Una malla de `nx × ny` con `k` iteraciones tiene tres parámetros. Se declaran
  los tres; la columna `n` del CSV lleva el que más pesa en el tiempo y el `README.md` fija los otros.
- **Mismo tamaño en las tres versiones.** La tabla principal compara V1, V2 y V3 con el mismo `N_declarado` y la
  misma entrada. Si V3 necesita otro tamaño (por memoria), se reporta en una segunda tabla con su propio `T(1)`
  de V1 a ese tamaño. Nunca se mezclan tamaños en una tabla: eso es escalabilidad débil, no fuerte (Anexo A, 6).

## 3. Cuántas corridas

| Regla | Valor |
|---|---|
| Por configuración | 1 calentamiento (no se cuenta) + 5 repeticiones cronometradas |
| Estadístico | Mediana; se reportan también mínimo y máximo |
| Configuraciones mínimas | V1 × 1 · V2 × {1, 2, 4, 8} (hasta núcleos físicos + 1) · V3 × 1 (produce dos filas: total y *kernel*) · experimentos de H2 × ≥ 2 opciones cada uno |
| Tiempo total estimado | `Σ_config 6 × T_config`. Con `T(1) = 3 s` y escalamiento razonable, todo el CSV principal se regenera en menos de 5 minutos |

Cuándo repetir una configuración completa (las 6 corridas), anotándolo en la bitácora:

- `(máx − mín) / mediana > 0.20` en CPU. Cierra lo demás (navegador, actualizaciones), conecta la laptop a la
  corriente y repite. Si persiste, reporta la variabilidad: es un dato, no un defecto tuyo.
- En Colab/Kaggle la GPU es compartida y puede cambiar entre sesiones. Si la variabilidad es alta, repite en la
  misma sesión y declara la fecha y la hora. Nunca combines corridas de sesiones distintas en una fila.
- Un valor atípico evidente (una corrida 5× más lenta) se queda en el CSV: la mediana lo absorbe. Se descarta una
  corrida solo si sabes qué pasó (otra celda corriendo, el sistema actualizándose) y lo escribes.

`run_all.sh` hace el calentamiento, las 5 repeticiones, la mediana, el mínimo y el máximo, y registra el entorno.
Si escribes tu propio *script*, debe producir las mismas columnas.

## 4. Cómo reportar V1 vs V2 vs V3

Línea base única: `T(1)` = V1 al `N_declarado`, en la máquina M, compilada con `-O2`.

| Comparación | Fórmula | Dónde va |
|---|---|---|
| V2 con `p` hilos | `S_V2(p) = T_V1 / T_V2(p)`; `E(p) = S(p)/p`; `f(p)` de Karp–Flatt | Tabla principal y `speedup.png` |
| V2 con 1 hilo vs V1 | `T_V2(1) / T_V1` = sobrecarga de OpenMP | Una fila de la tabla principal; se comenta en una línea |
| V3 **con** transferencias | `S_V3,total = T_V1 / T_V3,total` | **Titular** de V3: es lo que vería un usuario |
| V3 **sin** transferencias | `S_V3,kernel = T_V1 / T_V3,kernel` | Junto al anterior; explica el costo de las copias: `(T_total − T_kernel) / T_total` |
| V3 vs mejor V2 | `T_V2,mejor / T_V3,total` | Una línea: "la GPU es X veces más rápida que la mejor versión de CPU que tenemos" |
| Diferente máquina | Ver sección 6 | Tabla aparte titulada "comparación entre máquinas" |

Precisión: si V3 usa `float32` y V1 `float64`, decláralo, ajusta la tolerancia de las pruebas con una razón
numérica (error relativo observado frente al esperado para `float32`) y, si V1 puede correr en `float32` sin
perder corrección, mide también esa V1 y úsala como línea base de V3.

Tabla resumen para el reporte final:

```
Tamaño del problema: N_declarado = ____ · Entrada: ____ · Fecha(s): ____

| Versión | Máquina | Configuración | Mediana (s) | Speedup vs V1 (misma máquina) | Eficiencia | Notas |
|---|---|---|---|---|---|---|
| V1 | laptop (CPU: ____, __ núcleos físicos) | 1 hilo | | 1.00 | 1.00 | línea base |
| V2 | laptop | mejor: __ hilos | | | | f(p) = ____ |
| V1 | Colab (CPU: ____, __ vCPU) | 1 hilo | | 1.00 | — | línea base en Colab |
| V3 | Colab (GPU: ____) | total, con transferencias | | | — | H2D __ s · kernel __ s · D2H __ s |
| V3 | Colab (GPU: ____) | solo kernel | | | — | |
```

## 5. Cómo incluir las transferencias en V3

Definiciones que usa el curso:

- `T_kernel`: desde el lanzamiento del *kernel* hasta que termina (con sincronización).
- `T_total = T_H2D + T_kernel + T_D2H`: incluye las copias de entrada y salida. Las reservas (`cudaMalloc`) quedan
  fuera y se declara; si quieres, repórtalas en una columna aparte.
- Si tu algoritmo es iterativo y los datos viven en la GPU durante las `k` iteraciones, `T_total` cubre el ciclo
  completo con una copia de entrada y una de salida. Que las copias se amorticen es un resultado de diseño: dilo.

La regla que más mediciones invalida: **sincroniza antes de leer el reloj**. Los lanzamientos de *kernel* y
muchas copias son asíncronos; sin `cudaEventSynchronize`/`cudaDeviceSynchronize` (CUDA C), `cuda.synchronize()`
(Numba) o `cp.cuda.Stream.null.synchronize()` (CuPy) mides cuánto tarda en **encolarse** el trabajo, no en
hacerse (Anexo A, 24).

### 5.1 CUDA C: eventos

Fragmento compilado con `nvcc -c -arch=sm_75` sin avisos en el entorno de autoría; la salida que se muestra es el
formato esperado, no una ejecución (no hay GPU en el entorno de autoría; verifícalo en Colab).

```c
cudaEvent_t e0, e1, e2, e3;
cudaEventCreate(&e0); cudaEventCreate(&e1); cudaEventCreate(&e2); cudaEventCreate(&e3);

cudaEventRecord(e0);                                        // antes de la copia H2D
cudaMemcpy(d_x, h_x, bytes, cudaMemcpyHostToDevice);
cudaEventRecord(e1);                                        // fin H2D / inicio kernel
kernel<<<(n + 255) / 256, 256>>>(d_x, d_y, n);
cudaGetLastError();                                         // error de lanzamiento (revísalo siempre)
cudaEventRecord(e2);                                        // fin kernel / inicio D2H
cudaMemcpy(h_y, d_y, bytes, cudaMemcpyDeviceToHost);
cudaEventRecord(e3);                                        // fin D2H
cudaEventSynchronize(e3);                                   // sin esto los tiempos no valen

float ms_h2d, ms_kernel, ms_d2h, ms_total;
cudaEventElapsedTime(&ms_h2d, e0, e1);
cudaEventElapsedTime(&ms_kernel, e1, e2);
cudaEventElapsedTime(&ms_d2h, e2, e3);
cudaEventElapsedTime(&ms_total, e0, e3);
printf("TIEMPO_H2D_S %.6f\n", ms_h2d / 1000.0f);
printf("TIEMPO_KERNEL_S %.6f\n", ms_kernel / 1000.0f);     /* sin transferencias */
printf("TIEMPO_D2H_S %.6f\n", ms_d2h / 1000.0f);
printf("TIEMPO_S %.6f\n", ms_total / 1000.0f);             /* con transferencias: el que se compara con V1 */
```

Cada llamada a CUDA se envuelve en una macro que revisa el `cudaError_t` (en el reporte no se aceptan *kernels*
"que no dieron error" sin haberlo revisado; Anexo A, 27).

### 5.2 Numba CUDA: `perf_counter` + `cuda.synchronize()` + calentamiento del JIT

Verificado con `NUMBA_ENABLE_CUDASIM=1` en el entorno de autoría (el simulador comprueba la lógica, no los tiempos).

```python
import time
import numpy as np
from numba import cuda

@cuda.jit(cache=True)                      # cache=True: no recompila en cada proceso nuevo
def kernel(x, y):
    i = cuda.grid(1)
    if i < x.size:
        y[i] = 2.0 * x[i]

def medir(n):
    h_x = np.arange(n, dtype=np.float32)
    bloques = (n + 255) // 256
    t0 = time.perf_counter()
    d_x = cuda.to_device(h_x)                      # H2D
    d_y = cuda.device_array_like(d_x)
    cuda.synchronize(); t1 = time.perf_counter()
    kernel[bloques, 256](d_x, d_y)                 # kernel
    cuda.synchronize(); t2 = time.perf_counter()   # sin esto, el kernel sigue corriendo al leer el reloj
    h_y = d_y.copy_to_host()                       # D2H
    cuda.synchronize(); t3 = time.perf_counter()
    return h_y, t1 - t0, t2 - t1, t3 - t2, t3 - t0

medir(1024)                                        # calentamiento: compila el kernel; no se cuenta
h_y, t_h2d, t_kernel, t_d2h, t_total = medir(n)
print(f"TIEMPO_KERNEL_S {t_kernel:.6f}")
print(f"TIEMPO_S {t_total:.6f}")
```

La primera llamada a un *kernel* de Numba incluye la compilación (puede ser de segundos). El calentamiento dentro
del proceso la saca de la medición; `cache=True` evita pagarla en cada ejecución de `run_all.sh`.

### 5.3 CuPy: eventos de CUDA o `perf_counter` con sincronización

No verificado en el entorno de autoría (CuPy no está instalado); verifícalo en Colab y anota la versión.

```python
import cupy as cp
e0, e1, e2, e3 = (cp.cuda.Event() for _ in range(4))
e0.record()
d_x = cp.asarray(h_x)                              # H2D
e1.record()
d_y = kernel_propio(d_x)                           # RawKernel / ElementwiseKernel / composición explicada
e2.record()
h_y = cp.asnumpy(d_y)                              # D2H
e3.record(); e3.synchronize()
t_h2d = cp.cuda.get_elapsed_time(e0, e1) / 1000    # ms -> s
t_kernel = cp.cuda.get_elapsed_time(e1, e2) / 1000
t_total = cp.cuda.get_elapsed_time(e0, e3) / 1000
```

`%timeit` de un *kernel* de CuPy o Numba sin sincronizar mide el tiempo de encolar, no el de calcular.

### 5.4 Cómo correr `run_all.sh` en Colab y guardar la evidencia

```bash
!git clone <repo> && cd <repo> && make -C src/v3           # o compilar con nvcc en una celda
!cd <repo> && bash run_all.sh -e V3 -n <N_declarado> -t gpu -o resultados/mediciones-colab.csv -- ./src/v3/<programa>
!cd <repo> && bash run_all.sh -e V1 -n <N_declarado> -t 1   -o resultados/mediciones-colab.csv -- ./src/v1/<programa>
!nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv && lscpu | grep -E 'Model name|^CPU\(s\)' && date
```

El programa de V3 imprime `TIEMPO_S` (total) y `TIEMPO_KERNEL_S`; `run_all.sh` genera las filas `V3` y `V3-kernel`.
Copia `mediciones-colab.csv` y `entorno.txt` al repositorio (desde Colab: `git commit` con un *token* o descarga y
sube a mano) **antes de cerrar la sesión**: el sistema de archivos de Colab es efímero. El modelo de GPU y la fecha
van en el reporte junto a cada tabla de V3.

## 6. Comparar la GPU de Colab con tu CPU de forma honesta

El problema: V1 y V2 se midieron en tu laptop; V3 corre en otra máquina con otra CPU, otra memoria y otro
compilador. Un *speedup* entre máquinas distintas mezcla el paralelismo con la diferencia de hardware. Tres
formas aceptadas, en orden de preferencia:

| Forma | Qué haces | Qué puedes afirmar |
|---|---|---|
| **1. Misma máquina (titular)** | Compilas y mides **V1 en la CPU de Colab/Kaggle** (y V2 hasta las vCPU disponibles, normalmente 2), al mismo `N_declarado`, y mides V3 en su GPU, todo en la misma sesión. Guardas `lscpu` y `nvidia-smi` | "En Colab, la GPU T4 es X veces más rápida que V1 en su CPU, con transferencias incluidas" |
| **2. Entre máquinas (declarada)** | Reportas V3 en Colab frente a V1 en tu laptop, en una tabla titulada "comparación entre máquinas", con los dos entornos completos al lado | "La V3 en la GPU asignada tardó T; la V1 en nuestra laptop tardó T'. La razón T'/T no es un *speedup* de paralelismo" |
| **3. Todo local** | Si un integrante tiene GPU NVIDIA: V1, V2 y V3 en la misma máquina, declarada | Lo mismo que la forma 1, con la ventaja de poder repetirlo |

Reglas que aplican a las tres:

- V3 también se compara con la **mejor V2** (no solo con V1): es la pregunta que importa en ingeniería.
- Se reportan **ambos** tiempos de V3 (con y sin transferencias). El titular es con transferencias.
- Nunca se compara V3 contra una V1 en Python, ni contra una V1 con `-O0`, ni contra V2 con un hilo.
- La CPU de Colab es modesta y varía; por eso la forma 1 se hace en una sola sesión y con la fecha. Si Colab
  interrumpe la sesión ("límite de uso"), se repite completa; no se juntan mitades.
- Si el `N_declarado` no cabe en la GPU asignada, se baja el tamaño **para las tres versiones en esa tabla** y se dice.
- Una gráfica de barras con V1, mejor V2, V3 total y V3 *kernel* de la **misma máquina**; si hace falta otra para la
  comparación entre máquinas, lleva ese título.

Tabla de comparación entre máquinas (solo si usas la forma 2):

```
| Versión | Máquina (CPU/GPU, núcleos, RAM, compilador, fecha) | Configuración | Mediana (s) | Razón respecto a V1 laptop | Qué parte es hardware y qué parte paralelismo (tu estimación y cómo la hiciste) |
|---|---|---|---|---|---|
| V1 | laptop: ____ | 1 hilo | | 1.00 | — |
| V1 | Colab CPU: ____ | 1 hilo | | | esta razón es solo hardware |
| V3 | Colab GPU: ____ | total | | | |
```

## 7. Plantilla de tabla y de gráfica

### 7.1 CSV (lo que produce `run_all.sh`)

```
config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia,min_s,max_s
V1,1,<n>,…
V2,1,<n>,…
V2,2,<n>,…
V2,4,<n>,…
V2,8,<n>,…
V3,gpu,<n>,…            (con transferencias; eficiencia NA)
V3-kernel,gpu,<n>,…     (sin transferencias)
```

Las primeras once columnas son la tabla mínima del protocolo (§4); `min_s` y `max_s` cumplen "se reporta también
mín y máx". Un CSV por máquina (`mediciones.csv`, `mediciones-colab.csv`). Experimentos de H2 en
`experimentos.csv` con la etiqueta en `config` (`V2-static`, `V2-dynamic-64`, `V2-critical`…).

### 7.2 Tabla en el reporte

La imprime `graficar_proyecto.py` y la guarda en `tabla.md`:

```
Tamaño del problema n = ____; línea base T(1) = V1 = ____ s (mediana de las repeticiones).

| Versión | Hilos | Mediana (s) | Mín (s) | Máx (s) | Speedup | Eficiencia | f Karp–Flatt |
|---|---|---|---|---|---|---|---|
```

Debajo de cada tabla, una línea con: máquina, núcleos físicos, compilador y banderas, fecha. Sin esa línea la
tabla no se acepta.

Perfil por secciones (H1): `| Sección | Qué hace | Mediana (s) | % del total | ¿Paralelizable? | Por qué |`.
Experimentos (H2): `| Decisión | Opciones medidas | Mediana con 4 hilos por opción | Elegida | Por qué | Costo de la descartada |`.

### 7.3 Gráficas

Las genera `graficar_proyecto.py`; si usas otra herramienta, respeta lo mismo:

| Gráfica | Ejes | Elementos obligatorios | Qué no |
|---|---|---|---|
| `speedup.png` | x: hilos (1, 2, 4, 8 como marcas) · y: *speedup* desde 0 | Línea ideal `S = p`; un color por versión (el mismo color de esa versión en todas las gráficas); leyenda; etiqueta numérica en el último punto; subtítulo con `n` | Dos ejes y; escala truncada que exagere; una etiqueta en cada punto |
| `eficiencia.png` | x: hilos · y: eficiencia desde 0 | Referencia `E = 1`; leyenda | Mezclar máquinas |
| `comparacion.png` | x: tiempo en segundos (log si la razón máx/mín > 50, y se dice) · y: versiones | Barras V1, mejor V2, V3 total, V3 *kernel* (achurada) de la **misma máquina**; valor al final de cada barra | Omitir V3 total y dejar solo el *kernel* |

Pie de figura: "Mediana de 5 repeticiones con calentamiento, `-O2`, n = …, máquina …, fecha …". Colores:
V1 `#2a78d6`, V2 `#eb6834`, V3 `#1baf7a` (legibles con daltonismo; el *script* ya los usa).

## 8. Errores que invalidan una medición del proyecto

Amplían la lista del protocolo §5. "Cómo se detecta" es lo que hace el profesor al calificar.

| Error | Cómo se detecta | Consecuencia |
|---|---|---|
| `T(1)` tomado de V2 con un hilo sin decirlo | La fila `V1,1` no existe en el CSV, o `speedup` de `V2,1` es exactamente 1.000 | Criterio de medición en En desarrollo |
| Región cronometrada que incluye lectura de archivos o impresión | `T(1)` no baja con hilos aunque el núcleo escale; el código lo muestra | Rehacer la medición |
| Problema tan pequeño que `T(1) < 1 s` (o `< 0.1 s`) | Columna `mediana_s` | Medición no aceptada |
| `-O0`, `-g` sin `-O2`, o *sanitizers* activados al medir | `Makefile`, `entorno.txt` | Medición no aceptada |
| Una repetición, o promedio con picos evidentes | Columnas `rep1..rep5` iguales o ausentes | En desarrollo |
| Tamaños distintos entre filas de la misma tabla | Columna `n` | Tabla rechazada (es escalabilidad débil no declarada) |
| Dos máquinas en una tabla | `entorno.txt` vs filas | Tabla rechazada |
| V3 sin sincronizar antes de leer el reloj | `T_kernel` de microsegundos para un problema de segundos; el código no sincroniza | Medición de V3 no aceptada |
| V3 reportada solo sin transferencias | Falta la fila `V3` (total) | Criterio de V3 baja un nivel |
| Numba/CuPy con la compilación JIT dentro del tiempo | `T_kernel` de segundos con `n` pequeño; sin calentamiento en el código | Rehacer |
| `float32` en V3 contra `float64` en V1 sin declararlo | Pruebas de V3 con tolerancia distinta sin explicación | Correctitud en En desarrollo |
| V3 comparada contra V1 en Python o contra una V1 degradada | El repositorio tiene otra V1 más rápida, o V1 en Python | Comparación rechazada |
| *Speedup* superlineal sin explicación ni verificación con ese número de hilos | Tabla y ausencia de comentario | Análisis en En desarrollo |
| Entorno omitido (CPU, núcleos físicos, GPU, fecha) | No hay `entorno.txt` ni línea bajo la tabla | Tabla no aceptada |
| Corridas descartadas sin registro | Huecos entre `rep` o versiones del CSV en el historial de git | Integridad: se trata como alteración de mediciones |
| `OMP_NUM_THREADS` ignorado (`num_threads(4)` fijo) | Las filas de 1, 2 y 8 hilos dan el mismo tiempo | Rehacer |
| GPU de Colab medida en sesiones distintas y mezclada | Fechas/horas distintas en `entorno.txt` de una misma tabla | Tabla rechazada |

## 9. Lista de cotejo antes de pegar una tabla en el reporte

- [ ] `make test` pasó en la versión medida, con ese tamaño, antes de medir.
- [ ] Escribimos la predicción antes de medir y la comparamos después (está en el texto).
- [ ] `-O2`; sin *sanitizers*; sin depurador.
- [ ] Tamaño declarado; `T(1) ≥ 1 s`; el mismo en todas las filas.
- [ ] 1 calentamiento + 5 repeticiones; mediana, mín y máx en el CSV.
- [ ] `T(1)` = V1; la fila `V2,1` está aparte.
- [ ] Hilos hasta los núcleos físicos + 1, con la sobre-suscripción marcada.
- [ ] V3: con y sin transferencias; sincronizado; calentamiento del JIT; modelo de GPU y fecha.
- [ ] Una máquina por tabla; entorno completo debajo.
- [ ] Gráfica con línea ideal, leyenda, unidades, `n` y máquina en el pie.
- [ ] Texto de interpretación de 3–6 líneas: dónde deja de escalar, por qué, y si coincide con la predicción.
- [ ] El CSV se regenera con `run_all.sh` desde el repositorio etiquetado.
