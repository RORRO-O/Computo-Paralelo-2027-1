# Medir en el proyecto: cómo aplicar el protocolo a tu problema

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Guía de medición · versión 1.1 · 20 de octubre de 2026

Esta guía no sustituye a `herramientas/protocolo-medicion.md`: lo aplica a un proyecto con tres versiones, dos
máquinas (tu CPU y la GPU de Colab/Kaggle) y tres entregas. Donde esta guía y el protocolo difieran, manda el
protocolo. Las herramientas que se mencionan tienen su uso en la cabecera y pruebas en `proyecto/plantillas/`
(`make test`):

| Herramienta | En tu repositorio | Qué hace |
|---|---|---|
| `proyecto/plantillas/run_all.sh` | `herramientas/medir_proyecto.sh` | Mide **una** configuración: 1 calentamiento + 5 repeticiones, mediana, mín, máx, *speedup*, eficiencia; agrega filas a un CSV y escribe `entorno.txt` junto a él |
| `proyecto/plantillas/graficar_proyecto.py` | `herramientas/graficar_proyecto.py` | Tabla en Markdown con Karp–Flatt y gráficas `speedup.png`, `eficiencia.png`, `comparacion.png` |
| `proyecto/plantillas/plantilla_main.c` | base de `v1/main.c`, `v2/main.c` | Programa que cumple el contrato `[n] [semilla] [hilos]` → `tiempo_s=`, `checksum=` |
| `proyecto/entrega-final/plantilla-repo/run_all.sh` | `run_all.sh` (raíz) | Reproduce **todo** lo medible en CPU: entorno → `make` → `make test` → V1 y V2 → CSV → tabla y gráfica; `--rapido` prueba el flujo |
| `proyecto/entrega-final/plantilla-repo/v3/notebook_colab.ipynb` | `v3/notebook_colab.ipynb` | En Colab/Kaggle: entorno de la GPU, verificación V3 == V1 y medición con y sin transferencias |

## 1. Qué se mide en cada entrega

| Entrega | Fecha | Qué se mide | Dónde queda |
|---|---|---|---|
| H1 | jueves 29 de octubre, 10:30 | `T(1)` de V1 al tamaño declarado; perfil de la región de interés por secciones; `f_p`; predicción de Amdahl | `resultados/perfil-v1.csv`, `resultados/mediciones.csv` (fila V1), `resultados/entorno.txt`, `reporte/H1.md` |
| H2 | lunes 23 de noviembre, 10:30 | V1 y V2 con 1, 2, 4, 8 hilos; *speedup*, eficiencia, Karp–Flatt; experimentos de `schedule` y sincronización | `resultados/mediciones.csv`, `resultados/experimentos.csv`, `speedup.png`, `reporte/H2.md` |
| Entrega final | lunes 7 de diciembre, 10:30 | Todo lo anterior regenerado con el `run_all.sh` de la raíz + V3 con y sin transferencias contra la V1 de la misma máquina; aparte, comparación entre máquinas | `resultados/` (incluidos `mediciones_v3.csv` y `entorno_gpu.txt` del *notebook*), `reporte/reporte.pdf` |
| Defensa | jueves 10 de diciembre (y las sesiones que fije la opción elegida, `proyecto/README.md` §3) | Demo en vivo con tamaño de demo (segundos, no minutos); la tabla del reporte en pantalla | — |

## 2. Elegir los tamaños del problema

Tres tamaños, declarados en el `README.md` del repositorio desde H1:

| Nombre | Criterio | Para qué |
|---|---|---|
| `N_prueba` | `T(1) < 1 s` (ideal < 0.2 s); varios valores, incluido uno diminuto verificable a mano | `make test` en las tres versiones; TSan; demo en la defensa |
| `N_declarado` | `1 s ≤ T(1) ≤ 10 s` con `-O2` (ideal 2–5 s) | **Toda** medición comparativa: perfil, V2, V3, experimentos |
| `N_grande` (opcional) | El mayor que cabe en la memoria de la GPU y en tu RAM | Mostrar dónde la GPU amortiza las transferencias; va en una tabla aparte |

Cómo encontrar `N_declarado`: parte del tamaño de prueba y duplícalo hasta que la mediana de 5 corridas pase de
1 s. Anota los intentos en la bitácora (sección "Búsqueda del tamaño declarado"): es evidencia de que el tamaño no
se eligió para que el *speedup* se viera bien. `medir_proyecto.sh` avisa cuando `T(1) < 1 s`.

Restricciones que debes revisar antes de fijarlo:

- **Memoria.** Calcula los bytes: `elementos × tamaño del tipo × número de arreglos`. Debe caber en tu RAM sin
  intercambio (*swap*) y, para V3, en la memoria de la GPU que reporta `nvidia-smi`.
- **Índices.** Con `n` grande, `n*n` desborda `int`. Usa `size_t` o `long` para índices y tamaños.
- **Problemas con varios parámetros.** Una malla de `nx × ny` con `k` iteraciones tiene tres parámetros. Se declaran
  los tres; la columna `n` del CSV lleva el que más pesa en el tiempo y el `README.md` fija los otros.
- **Mismo tamaño en las tres versiones.** La tabla principal compara V1, V2 y V3 con el mismo `N_declarado` y la
  misma entrada (misma semilla). Si V3 necesita otro tamaño (por memoria), se reporta en una segunda tabla con su
  propio `T(1)` de V1 a ese tamaño. Nunca se mezclan tamaños en una tabla: eso es escalabilidad débil, no fuerte
  (Anexo A, 6).

## 3. Cuántas corridas

| Regla | Valor |
|---|---|
| Por configuración | 1 calentamiento (no se cuenta) + 5 repeticiones cronometradas |
| Dentro de cada corrida | La creación del equipo de hilos (primera región paralela) queda fuera de `tiempo_s`; en Numba/CuPy, la compilación JIT también |
| Estadístico | Mediana; se reportan también mínimo y máximo |
| Configuraciones mínimas | V1 × 1 · V2 × {1, 2, 4, 8} (hasta núcleos físicos + 1) · V3 × 1 (produce dos filas: total y *kernel*) · experimentos de H2 × ≥ 2 opciones cada uno |
| Tiempo total estimado | `Σ_config 6 × T_config`. Con `T(1) = 3 s` y `S(p) ≥ 1`, V1 más V2 con 1, 2, 4 y 8 hilos toman a lo sumo 6 × 3 × 5 = 90 s: todo el CSV principal se regenera en menos de 5 minutos |

Cuándo repetir una configuración completa (las 6 corridas), anotándolo en la bitácora:

- `(máx − mín) / mediana > 0.20` en CPU. Cierra lo demás (navegador, actualizaciones), conecta la laptop a la
  corriente y repite. Si persiste, reporta la variabilidad: es un dato, no un defecto tuyo.
- En Colab/Kaggle la GPU es compartida y puede cambiar entre sesiones. Si la variabilidad es alta, repite en la
  misma sesión y declara la fecha y la hora. Nunca combines corridas de sesiones distintas en una fila.
- Un valor atípico evidente (una corrida 5× más lenta) se queda en el CSV: la mediana lo absorbe. Se descarta una
  corrida solo si sabes qué pasó (otra celda corriendo, el sistema actualizándose) y lo escribes.

`medir_proyecto.sh`, el `run_all.sh` de la raíz y la celda de medición del *notebook* hacen el calentamiento, las 5
repeticiones y la mediana. Si escribes tu propio *script*, debe producir las mismas columnas.

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
Tamaño del problema: N_declarado = ____ · Entrada y semilla: ____ · Fecha(s): ____

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

- `T_kernel`: desde el lanzamiento del *kernel* hasta que termina (con sincronización). Se imprime como
  `tiempo_kernel_s=`.
- `T_total = T_H2D + T_kernel + T_D2H`: incluye las copias de entrada y salida. Se imprime como `tiempo_total_s=`.
  Las reservas (`cudaMalloc`) quedan fuera y se declara; si quieres, repórtalas en una columna aparte.
- Si tu algoritmo es iterativo y los datos viven en la GPU durante las `k` iteraciones, `T_total` cubre el ciclo
  completo con una copia de entrada y una de salida. Que las copias se amorticen es un resultado de diseño: dilo.

La regla que más mediciones invalida: **sincroniza antes de leer el reloj**. Los lanzamientos de *kernel* y
muchas copias son asíncronos; sin `cudaEventSynchronize`/`cudaDeviceSynchronize` (CUDA C), `cuda.synchronize()`
(Numba) o `cp.cuda.Stream.null.synchronize()` (CuPy) mides cuánto tarda en **encolarse** el trabajo, no en
hacerse (Anexo A, 33). Y la correctitud de V3 se prueba también sin GPU (`docs/metodo/04-evaluacion.md` §5): con
Numba, `NUMBA_ENABLE_CUDASIM=1`; con CUDA C o CuPy, el espejo en CPU del cómputo por elemento que comparte con V1.

### 5.1 CUDA C: eventos

Fragmento compilado con `nvcc -c -arch=sm_75 -Xcompiler -Wall,-Wextra` sin avisos en el entorno de autoría (dentro
de una función con `d_x`, `d_y`, `h_x`, `h_y`, `bytes` y `n` declarados). No hay GPU en ese entorno: la salida no
se ejecutó allí; verifícala en Colab.

```c
#define CUDA_CHECK(llamada)                                                        \
    do {                                                                           \
        cudaError_t err_ = (llamada);                                              \
        if (err_ != cudaSuccess) {                                                 \
            fprintf(stderr, "error CUDA en %s:%d: %s\n", __FILE__, __LINE__,       \
                    cudaGetErrorString(err_));                                     \
            exit(1);                                                               \
        }                                                                          \
    } while (0)

cudaEvent_t e0, e1, e2, e3;
CUDA_CHECK(cudaEventCreate(&e0)); CUDA_CHECK(cudaEventCreate(&e1));
CUDA_CHECK(cudaEventCreate(&e2)); CUDA_CHECK(cudaEventCreate(&e3));

CUDA_CHECK(cudaEventRecord(e0));                              // antes de la copia H2D
CUDA_CHECK(cudaMemcpy(d_x, h_x, bytes, cudaMemcpyHostToDevice));
CUDA_CHECK(cudaEventRecord(e1));                              // fin H2D / inicio kernel
kernel<<<(n + 255) / 256, 256>>>(d_x, d_y, n);
CUDA_CHECK(cudaGetLastError());                               // error de lanzamiento
CUDA_CHECK(cudaEventRecord(e2));                              // fin kernel / inicio D2H
CUDA_CHECK(cudaMemcpy(h_y, d_y, bytes, cudaMemcpyDeviceToHost));
CUDA_CHECK(cudaEventRecord(e3));                              // fin D2H
CUDA_CHECK(cudaEventSynchronize(e3));                         // sin esto los tiempos no valen

float ms_h2d, ms_kernel, ms_d2h, ms_total;
CUDA_CHECK(cudaEventElapsedTime(&ms_h2d, e0, e1));
CUDA_CHECK(cudaEventElapsedTime(&ms_kernel, e1, e2));
CUDA_CHECK(cudaEventElapsedTime(&ms_d2h, e2, e3));
CUDA_CHECK(cudaEventElapsedTime(&ms_total, e0, e3));
printf("tiempo_h2d_s=%.6f\n", ms_h2d / 1000.0f);
printf("tiempo_kernel_s=%.6f\n", ms_kernel / 1000.0f);      /* sin transferencias */
printf("tiempo_d2h_s=%.6f\n", ms_d2h / 1000.0f);
printf("tiempo_total_s=%.6f\n", ms_total / 1000.0f);        /* con transferencias: el que se compara con V1 */
```

Cada llamada a CUDA pasa por la macro: en el reporte no se aceptan *kernels* "que no dieron error" sin haberlo
revisado (Anexo A, 27). `proyecto/entrega-final/plantilla-repo/v3/kernel.cu` usa el mismo patrón completo.

### 5.2 Numba CUDA: `perf_counter` + `cuda.synchronize()` + calentamiento del JIT

Verificado con `NUMBA_ENABLE_CUDASIM=1` y Numba 0.68 en el entorno de autoría, con `n` = 4096: `checksum=` dio
1.677312e+07, el valor exacto de `2·Σi`. El simulador comprueba la lógica, no los tiempos.

```python
import time
import numpy as np
from numba import cuda

@cuda.jit(cache=True)                      # cache=True: no recompila en cada proceso nuevo
def kernel(x, y):
    i = cuda.grid(1)
    if i < x.size:                         # guarda: la malla casi siempre excede n (Anexo A, 34)
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

n = 4096                                           # en tu V3: el N_declarado (en el simulador, uno pequeño)
medir(1024)                                        # calentamiento: compila el kernel; no se cuenta
h_y, t_h2d, t_kernel, t_d2h, t_total = medir(n)
print(f"checksum={float(h_y.sum(dtype=np.float64)):.12e}")
print(f"tiempo_kernel_s={t_kernel:.6f}")
print(f"tiempo_total_s={t_total:.6f}")
```

La primera llamada a un *kernel* de Numba incluye la compilación (puede ser de segundos). El calentamiento dentro
del proceso la saca de la medición; `cache=True` evita pagarla en cada ejecución del *script* de medición (y deja
una carpeta `__pycache__/` que va en el `.gitignore`).

### 5.3 CuPy: eventos de CUDA

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
t_kernel = cp.cuda.get_elapsed_time(e1, e2) / 1000 # ms -> s
t_total = cp.cuda.get_elapsed_time(e0, e3) / 1000
print(f"tiempo_kernel_s={t_kernel:.6f}")
print(f"tiempo_total_s={t_total:.6f}")
```

`%timeit` de un *kernel* de CuPy o Numba sin sincronizar mide el tiempo de encolar, no el de calcular.

### 5.4 Cómo medir en Colab y guardar la evidencia

La evidencia de V3 que revisa la entrega final la produce el *notebook* (`v3/notebook_colab.ipynb`, que se genera
desde el repositorio con `herramientas/generar_notebook_v3.py` de la plantilla-repo): la celda "1. Entorno" escribe
`entorno_gpu.txt` (modelo de GPU, *driver*, fecha), la celda "4. Verificación" compara el `checksum=` de V3 con el de
V1 en la misma sesión, y la celda "5. Medición" mide V1 en la CPU de Colab y V3 con y sin transferencias, y escribe
`mediciones_v3.csv`. Detalle en `proyecto/entrega-final/reproducibilidad.md` §3–§4.

Si además quieres usar `medir_proyecto.sh` en Colab (por ejemplo, para un `N_grande` o una variante de tamaño de
bloque), escribe en una carpeta propia para no sobrescribir el `entorno.txt` de tu laptop:

```bash
!cd <repo> && make -C v1 && make -C v3                  # o compila con nvcc en una celda
!cd <repo> && ./herramientas/medir_proyecto.sh -e V1 -n <N_declarado> -t 1   -o resultados/colab/mediciones.csv -- ./v1/v1
!cd <repo> && ./herramientas/medir_proyecto.sh -e V3 -n <N_declarado> -t gpu -o resultados/colab/mediciones.csv -- ./v3/v3
```

Con `-t gpu`, el programa imprime `tiempo_total_s=` y `tiempo_kernel_s=`, y `medir_proyecto.sh` genera las filas
`V3` (con transferencias) y `V3-kernel` (sin ellas), con *speedup* respecto a la fila V1 del mismo CSV. El
`resultados/colab/entorno.txt` que escribe ya incluye la fecha, la CPU de Colab y la línea `gpu:` de `nvidia-smi`.

Descarga el *notebook* **ejecutado**, los CSV y los entornos al repositorio **antes de cerrar la sesión**: el sistema
de archivos de Colab es efímero. El modelo de GPU y la fecha van en el reporte junto a cada tabla de V3.

## 6. Comparar la GPU de Colab con tu CPU de forma honesta

El problema: V1 y V2 se midieron en tu laptop; V3 corre en otra máquina con otra CPU, otra memoria y otro
compilador. Un *speedup* entre máquinas distintas mezcla el paralelismo con la diferencia de hardware. Tres
formas aceptadas, en orden de preferencia:

| Forma | Qué haces | Qué puedes afirmar |
|---|---|---|
| **1. Misma máquina (titular)** | Compilas y mides **V1 en la CPU de Colab/Kaggle** (y V2 hasta las vCPU disponibles, normalmente 2), al mismo `N_declarado`, y mides V3 en su GPU, todo en la misma sesión (es lo que hace la celda de medición del *notebook*). Guardas `lscpu` y `nvidia-smi` | "En Colab, la GPU T4 es X veces más rápida que V1 en su CPU, con transferencias incluidas" |
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

### 7.1 CSV

Lo que produce `medir_proyecto.sh` (H1 y H2):

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
mín y máx". Un CSV por máquina y por carpeta (cada carpeta tiene su `entorno.txt`). Experimentos de H2 en
`experimentos.csv` con la etiqueta en `config` (`V2-static`, `V2-dynamic-64`, `V2-critical`…) y su propia fila `V1`.

El `run_all.sh` de la raíz (plantilla-repo) escribe las once columnas del protocolo, sin `min_s` ni `max_s`, con
etiquetas `v1` y `v2`; el *notebook* escribe `mediciones_v3.csv` con `v1`, `v3_kernel` y `v3_total`.
`graficar_proyecto.py`, `resumen_csv.py` (plantilla-repo) y `revisar_mediciones.py` (U4·S06) leen los dos formatos.

### 7.2 Tabla en el reporte

La imprime `graficar_proyecto.py` y la guarda en `tabla.md`:

```
Tamaño del problema n = ____; línea base T(1) = V1 = ____ s (mediana de las repeticiones).

| Versión | Hilos | Mediana (s) | Mín (s) | Máx (s) | Speedup | Eficiencia | f Karp–Flatt |
|---|---|---|---|---|---|---|---|
```

Debajo de cada tabla, una línea con: máquina, núcleos físicos, compilador y banderas, fecha. Sin esa línea la
tabla no se acepta.

Perfil por secciones (H1): `| Sección | Qué hace | Mediana (s) | % de T(1) | ¿Paralelizable? | Por qué |`.
Experimentos (H2): `| Decisión | Opciones medidas | Mediana con 4 hilos por opción | Elegida | Por qué | Costo de la descartada |`.

### 7.3 Gráficas

Las genera `graficar_proyecto.py`; si usas otra herramienta, respeta lo mismo:

| Gráfica | Ejes | Elementos obligatorios | Qué no |
|---|---|---|---|
| `speedup.png` | x: hilos (1, 2, 4, 8 como marcas) · y: *speedup* desde 0 | Línea ideal `S = p`; barras mín–máx (*speedup* con el tiempo máximo y con el mínimo de las repeticiones); un color por versión (el mismo color de esa versión en todas las gráficas); leyenda; etiqueta numérica en el último punto; subtítulo con `n` | Dos ejes y; escala truncada que exagere; una etiqueta en cada punto |
| `eficiencia.png` | x: hilos · y: eficiencia desde 0 | Referencia `E = 1`; leyenda | Mezclar máquinas |
| `comparacion.png` | x: tiempo en segundos (log si la razón máx/mín > 50, y se dice) · y: versiones | Barras V1, mejor V2, V3 total, V3 *kernel* (achurada) de la **misma máquina**; valor al final de cada barra | Omitir V3 total y dejar solo el *kernel* |

Pie de figura: "Mediana de 5 repeticiones con calentamiento, `-O2`, n = …, máquina …, fecha …". Colores:
V1 `#2a78d6`, V2 `#eb6834`, V3 `#1baf7a` (legibles con daltonismo; el *script* ya los usa).

### 7.4 Qué archivo produce cada herramienta y cuál revisa cada entrega

| Archivo | Lo produce | Lo revisa |
|---|---|---|
| `resultados/perfil-v1.csv` | La receta de `hitos/H1-avance-1.md` §2.3 (o `gprof` resumido a mano) | H1, criterio 3 |
| `resultados/mediciones.csv` en H1 y H2 | `medir_proyecto.sh` (etiquetas `V1`, `V2`) o el `run_all.sh` de la raíz (`v1`, `v2`) | H1 (fila V1), H2 criterio 2, `revisar_mediciones.py` en el taller del 19 de noviembre |
| `resultados/mediciones.csv` en la entrega final | El `run_all.sh` de la raíz, regenerado antes de la etiqueta `entrega-final` (lo sobrescribe con su formato) | `verificar_entrega.sh` ítems 9–11: cabecera del protocolo terminada en `eficiencia`, filas `v1` y ≥ 3 `v2`, `T(1) ≥ 1 s` |
| `resultados/experimentos.csv` | `medir_proyecto.sh` | H2 criterio 4 |
| `resultados/entorno.txt` | El último *script* que midió en esa carpeta | Todas las entregas; `verificar_entrega.sh` ítem 13 |
| `resultados/mediciones_v3.csv`, `resultados/entorno_gpu.txt` | El *notebook* de V3 (celdas de entorno y de medición) | `verificar_entrega.sh` ítems 12 y 14 |
| `resultados/colab/` (opcional) | `medir_proyecto.sh` en Colab | Tablas adicionales del reporte |
| `tabla.md`, `*.png` | `graficar_proyecto.py` o `resumen_csv.py` | Reporte y defensa; `verificar_entrega.sh` ítem 15 |

El CSV de H2 queda en la etiqueta `H2`: regenerar `resultados/mediciones.csv` para la entrega final no borra
evidencia. Si los números cambian respecto a H2, se explica en el reporte (otra máquina, otro código).

## 8. Errores que invalidan una medición del proyecto

Amplían la lista del protocolo §5. "Cómo se detecta" es lo que hace el profesor al calificar.

| Error | Cómo se detecta | Consecuencia |
|---|---|---|
| `T(1)` tomado de V2 con un hilo sin decirlo | La fila `V1,1` no existe en el CSV, o `speedup` de `V2,1` es exactamente 1.000 | Criterio de medición en En desarrollo |
| Región cronometrada que incluye lectura de archivos o impresión | `T(1)` no baja con hilos aunque el núcleo escale; el código lo muestra | Rehacer la medición |
| Creación del equipo de hilos dentro de `tiempo_s` | La diferencia `T_V2(1) − T_V1` es mayor que el rango (máx − mín) de las repeticiones y no hay otra causa; la primera región paralela está dentro del cronómetro | Explicar o rehacer |
| Problema tan pequeño que `T(1) < 1 s` (o `< 0.1 s`) | Columna `mediana_s`; `medir_proyecto.sh` lo avisa | Medición no aceptada |
| `-O0`, `-g` sin `-O2`, o *sanitizers* activados al medir | `Makefile`, `entorno.txt` | Medición no aceptada |
| Una repetición, o promedio con picos evidentes | Columnas `rep1..rep5` iguales o ausentes | En desarrollo |
| Tamaños distintos entre filas de la misma tabla | Columna `n` | Tabla rechazada (es escalabilidad débil no declarada) |
| Dos máquinas en una tabla | `entorno.txt` vs filas | Tabla rechazada |
| V3 sin sincronizar antes de leer el reloj | `T_kernel` de microsegundos para un problema de segundos; el código no sincroniza | Medición de V3 no aceptada |
| V3 reportada solo sin transferencias | Falta la fila `V3` (o `v3_total`) | Criterio de V3 baja un nivel |
| Numba/CuPy con la compilación JIT dentro del tiempo | `T_kernel` de segundos con `n` pequeño; sin calentamiento en el código | Rehacer |
| `float32` en V3 contra `float64` en V1 sin declararlo | Pruebas de V3 con tolerancia distinta sin explicación | Correctitud en En desarrollo |
| V3 comparada contra V1 en Python o contra una V1 degradada | El repositorio tiene otra V1 más rápida, o V1 en Python | Comparación rechazada |
| *Speedup* superlineal sin explicación ni verificación con ese número de hilos | Tabla y ausencia de comentario | Análisis en En desarrollo |
| Entorno omitido (CPU, núcleos físicos, GPU, fecha) | No hay `entorno.txt` ni línea bajo la tabla | Tabla no aceptada |
| Corridas descartadas sin registro | Huecos entre `rep` o versiones del CSV en el historial de git | Integridad: se trata como alteración de mediciones |
| `OMP_NUM_THREADS` ignorado (`num_threads(4)` fijo) | Las filas de 1, 2 y 8 hilos dan el mismo tiempo; `hilos=` no coincide | Rehacer |
| GPU de Colab medida en sesiones distintas y mezclada | Fechas/horas distintas en `entorno_gpu.txt` de una misma tabla | Tabla rechazada |

## 9. Lista de cotejo antes de pegar una tabla en el reporte

- [ ] `make test` pasó en la versión medida, con ese código, antes de medir.
- [ ] Escribimos la predicción antes de medir (bitácora, con fecha) y la comparamos después (está en el texto).
- [ ] `-O2`; sin *sanitizers*; sin depurador.
- [ ] Tamaño declarado; `T(1) ≥ 1 s`; el mismo en todas las filas.
- [ ] 1 calentamiento + 5 repeticiones; mediana, mín y máx en la tabla.
- [ ] `T(1)` = V1; la fila `V2,1` está aparte.
- [ ] Hilos hasta los núcleos físicos + 1, con la sobre-suscripción marcada.
- [ ] V3: con y sin transferencias; sincronizado; calentamiento del JIT; modelo de GPU y fecha.
- [ ] Una máquina por tabla; entorno completo debajo.
- [ ] Gráfica con línea ideal, barras mín–máx, leyenda, unidades, `n` y máquina en el pie.
- [ ] Texto de interpretación de 3–6 líneas: dónde la eficiencia cae de 0.5, por qué (con un dato) y si coincide con la predicción.
- [ ] El CSV se regenera con los comandos escritos desde el repositorio etiquetado.
