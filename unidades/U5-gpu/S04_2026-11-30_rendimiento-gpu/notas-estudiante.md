> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S04 · lunes 30 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# Notas · Rendimiento en GPU: medir bien antes de optimizar

Palabras clave: evento (`cudaEvent_t`), lanzamiento asíncrono, H2D/D2H, umbral de tamaño, *warp*, ocupación
(*occupancy*), memoria fija (*pinned*), *stream*, intensidad aritmética, *roofline*, `nsys`.

## 1. Dos relojes y una trampa

El lanzamiento de un kernel es **asíncrono**: `kernel<<<g, b>>>()` regresa a la CPU en microsegundos, antes de que
la GPU termine. Un cronómetro de CPU (`omp_get_wtime`, `clock_gettime`) alrededor del lanzamiento mide **cuánto
tardó encolarlo**, no cuánto tardó el kernel. Hay dos formas correctas:

| Forma | Código | Qué mide | Cuándo usarla |
|---|---|---|---|
| CPU + sincronización | `t0; kernel<<<>>>(); cudaDeviceSynchronize(); t1` | Kernel + espera de la CPU | Para comparar con el total de un programa de CPU |
| Eventos | `cudaEventRecord(a,0); kernel<<<>>>(); cudaEventRecord(b,0); cudaEventSynchronize(b); cudaEventElapsedTime(&ms,a,b)` | Tiempo entre dos marcas **en el reloj de la GPU**, resolución ≈ 0.5 µs | Siempre que midas algo que ocurre en el *stream*: kernels y copias |

Un evento es una marca que se encola en un *stream*; se "completa" cuando la GPU llega a ella. Por eso se puede
poner una marca antes de la copia H2D, otra antes del kernel, otra después y otra después de la copia D2H, y
medir cada tramo por separado (así lo hace `bench_gpu.cu`).

Protocolo (igual que en OpenMP y MPI): **1 calentamiento que no cuenta** (la primera llamada a CUDA crea el
contexto, decenas o cientos de ms; el primer lanzamiento carga el módulo), **5 repeticiones, mediana**, `-O2`,
verificación contra la CPU antes de creer cualquier tiempo, y revisar `cudaGetLastError()`: un kernel que no se
lanzó tarda 0 ms y da "resultados" que son basura.

## 2. Las copias cuentan (y casi siempre dominan)

| Camino | Ancho de banda típico | ≈ 200 MB (saxpy, `n = 2^24`: 3 × 64 MiB) |
|---|---|---|
| Memoria global de la GPU leída por un kernel (T4) | ≈ 200–250 GB/s efectivos (320 teóricos) | ≈ 0.9 ms |
| PCIe 3.0 x16 con memoria paginable (`malloc`) | ≈ 3–6 GB/s | ≈ 30–60 ms |
| PCIe 3.0 x16 con memoria fija (`cudaMallocHost`) | ≈ 10–12 GB/s | ≈ 16–20 ms |

Copiar un byte por PCIe cuesta **20–80 veces** más (según sea *pinned* o paginable) que leerlo desde la memoria de la GPU. Para un kernel que usa
cada byte una sola vez (saxpy, suma de vectores), las copias son > 95 % del total con cualquier `n`. Por eso el
protocolo del curso exige reportar **con y sin copias** y por eso la pregunta correcta no es "¿es rápida la GPU?"
sino "¿dónde viven los datos y cuántos kernels corren sobre ellos antes de volver a la CPU?".

## 3. Umbral de tamaño

Lanzar un kernel cuesta ≈ 5–10 µs aunque no haga nada. Con `n = 1024`, la CPU suma dos vectores en < 1 µs: la GPU
pierde aunque no cuentes copias. El cruce **solo kernel** aparece alrededor de `n ≈ 2^12–2^16` (cuando el
trabajo supera el costo de lanzar). El cruce **con copias** para saxpy con memoria paginable **no aparece en
ningún `n`** en una T4 de Colab (la CPU lee su propia memoria más rápido de lo que PCIe la copia); con memoria
*pinned* apenas aparece (≈ 1–2×) a partir de `n ≈ 2^22`. Medir ambos cruces es parte de la práctica guiada.

## 4. Tamaño de bloque y ocupación

- La GPU ejecuta hilos en **warps de 32**. Un bloque de 50 hilos ocupa 2 warps y deja 14 de 64 carriles ociosos:
  por eso el bloque se elige **múltiplo de 32**.
- **Ocupación** = warps residentes en un SM ÷ máximo de warps del SM (32 en T4, 64 en A100). La limitan cuatro
  cosas: bloques residentes por SM (16 en T4), hilos por SM (1024 en T4), registros (65 536 por SM) y memoria
  compartida por bloque. `cudaOccupancyMaxActiveBlocksPerMultiprocessor` la calcula; `bench_gpu` la imprime.
- Bloque de 32 en T4: 16 bloques × 1 warp = 16 de 32 warps → **50 %**; el kernel *memory-bound* tiene la mitad de
  warps para ocultar la latencia de memoria y tarda ≈ 1.5–1.8× más. De 64 en adelante: 100 %.
- **1024 no siempre es mejor**: la ocupación ya no sube; quedan menos bloques para balancear el final; cada hilo
  queda limitado a 64 registros (si el kernel usa más, el lanzamiento falla con *too many resources requested
  for launch*); y con `n` pequeño hay menos bloques que SMs (con `n = 4096` y bloque de 1024 solo trabajan 4 de
  40 SM). Regla práctica: empezar en **128–256** y **medir** el barrido.

## 5. Memoria *pinned* y *streams* (panorama)

`cudaMallocHost` reserva memoria del anfitrión que el sistema operativo no puede paginar; el DMA la lee
directamente y la copia se acerca al límite de PCIe (×2–3 frente a `malloc`). Además es **requisito** para que
`cudaMemcpyAsync` sea de verdad asíncrona. Un *stream* es una cola de trabajo; operaciones en *streams* distintos
pueden solaparse: mientras el trozo `k` se calcula, el trozo `k+1` se copia hacia la GPU y el `k−1` regresa.
`pinned_streams.cu` lo muestra con 4 trozos. Costo: la memoria fija es escasa y lenta de reservar; no se fija
todo, solo los búferes que viajan.

## 6. Roofline simplificado: ¿memoria o cómputo?

- **Intensidad aritmética** `I` = FLOP ÷ bytes leídos y escritos en memoria global.
- **Balance de la máquina** = FLOP/s pico ÷ ancho de banda. T4: ≈ 8 TFLOP/s FP32 ÷ 320 GB/s ≈ **25 FLOP/byte**.
- Rendimiento alcanzable ≈ `min(pico, I × ancho_de_banda)`. Si `I` < balance, el kernel es ***memory-bound*** y lo
  único que lo acelera es mover menos bytes (o moverlos mejor: coalescencia, S02). Si `I` > balance, es
  ***compute-bound*** y lo que manda es la aritmética.

| Kernel | FLOP | Bytes | `I` | En una T4 |
|---|---|---|---|---|
| suma de vectores | `n` | `12n` | 0.083 | *memory-bound*: alcanza ≈ 27 GFLOP/s de 8 000 |
| saxpy | `2n` | `12n` | **≈ 0.17** | *memory-bound*: ≈ 53 GFLOP/s de 8 000 (0.7 % del pico) |
| matmul `N×N`, cada dato leído **una vez** (ideal) | `2N³` | `12N²` | `N/6` | `N = 2048` → 341 FLOP/byte: *compute-bound* |
| matmul con mosaicos `T×T` en memoria compartida (S02) | `2T³` por mosaico | `8T²` por mosaico | `T/4` | `T = 32` → 8: aún *memory-bound*, pero 50× mejor que saxpy |

La diferencia no es "matmul tiene más FLOP": es que matmul **reutiliza** cada dato `N` veces y saxpy ninguna. El
*tiling* existe para acercar la intensidad real a la ideal. Mismo criterio para tu kernel de P6: calcula `I` antes
de optimizar.

## 7. Perfilado en Colab

`nsys profile --stats=true ./programa` imprime tablas; mira tres: `cuda_api_sum` (tiempo de **CPU** en cada
llamada: `cudaMemcpy`, `cudaMalloc`, `cudaEventSynchronize`), `cuda_gpu_kern_sum` (tiempo de **GPU** por kernel)
y `cuda_gpu_mem_time_sum` (copias H2D y D2H). Columnas: **Time (%)**, **Total Time**, **Instances/Count**,
**Avg/Med**, **Name**. `ncu` (Nsight Compute) da el *roofline* por kernel ("Speed of Light"), pero en Colab suele
estar bloqueado (`ERR_NVGPUCTRPERM`); entonces, eventos.

## 8. Ejemplo resuelto en una tabla (detalle en `ejemplo-resuelto.md`)

`saxpy`, `n = 2^24`, bloque 256, T4 (salida esperada, no ejecutada en el entorno de autoría):

| Forma de medir | Mediana | Lectura |
|---|---|---|
| 1. CPU sin sincronizar | ≈ 0.01 ms | **Incorrecta**: midió el encolado |
| 2. CPU + `cudaDeviceSynchronize` | ≈ 1.0–1.3 ms | Correcta; incluye la espera |
| 3. Eventos alrededor del kernel | ≈ 0.9–1.0 ms | ≈ 200–230 GB/s: 65–70 % del teórico |
| 4. Eventos H2D + kernel + D2H | ≈ 40–70 ms | Copias ≈ 97–98 % del total |

## 9. Errores frecuentes

1. Cronometrar con la CPU sin sincronizar y reportar microsegundos (idea errónea 24 disfrazada: el kernel "no tarda").
2. Reportar solo el *speedup* del kernel cuando los datos empiezan y terminan en la CPU (idea 24).
3. Elegir 1024 "porque más hilos es más rápido" (ideas 1 y 26) o un bloque que no es múltiplo de 32.
4. Medir una vez, sin calentamiento, y creer la primera corrida (idea 5): la primera incluye crear el contexto.
5. Comparar contra una CPU compilada con `-O0`, o contra un solo hilo de OpenMP en vez del mejor secuencial.
6. No revisar `cudaGetLastError()`: un kernel que no se lanzó "tarda" 0 ms (idea 27).
7. Optimizar el kernel cuando las copias son el 97 % del tiempo.
8. Leer `cuda_api_sum` de `nsys` como si fuera tiempo de GPU.

## 10. Para saber más

- *CUDA C++ Best Practices Guide* (NVIDIA): "Timing" (eventos vs. cronómetros), "Data Transfer Between Host and
  Device" (*pinned*, asíncrono, *streams*), "Occupancy" y "Execution Configuration Optimizations".
- *CUDA C++ Programming Guide* (NVIDIA): "Page-Locked Host Memory", "Asynchronous Concurrent Execution", "Events".
- Documentación de Numba CUDA: *Events*, *Streams*, *Pinned memory*, *Occupancy*.
- Kirk y Hwu, *Programming Massively Parallel Processors*, 4.ª ed.: cap. 4 ("Compute architecture and
  scheduling": warps, ocupación), cap. 5 ("Memory architecture and data locality": intensidad y mosaicos) y
  cap. 6 ("Performance considerations").
