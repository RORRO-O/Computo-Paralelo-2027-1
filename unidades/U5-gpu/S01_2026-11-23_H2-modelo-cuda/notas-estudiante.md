> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S01 · lunes 23 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# Notas · Por qué GPU, SIMT y el modelo CUDA

## 1. CPU orientada a latencia, GPU orientada a rendimiento

Una CPU está diseñada para terminar **una** tarea lo antes posible: pocos núcleos complejos, cachés grandes,
predicción de saltos, ejecución fuera de orden. Una GPU está diseñada para terminar **muchas** tareas iguales por
segundo (*throughput*): miles de unidades aritméticas simples, cachés pequeñas, y en lugar de evitar la espera de
memoria, la **oculta** cambiando a otro grupo de hilos que ya tiene sus datos.

| | CPU de laptop (4 núcleos) | GPU Tesla T4 (Colab) |
|---|---|---|
| Unidades de ejecución | 4 núcleos (8 con *hyper-threading*) | 40 multiprocesadores (SM) × 64 unidades FP32 = 2560 "núcleos CUDA" |
| Qué optimiza | Latencia de una tarea | Rendimiento de miles de tareas iguales |
| Ancho de banda a memoria | ≈ 20–40 GB/s | ≈ 320 GB/s (16 GB GDDR6) |
| Cómo tolera esperar memoria | Cachés grandes, predicción | Cambia de *warp* mientras otro espera |
| Hilos "en vuelo" | Decenas | Decenas de miles (hasta 1024 por SM en una T4) |

Un "núcleo CUDA" **no** es un núcleo de CPU (idea errónea 22): es una unidad aritmética sin su propio control de
flujo. El control lo lleva el *warp*.

## 2. SIMT, *warps* y SM

- **SIMT** (*Single Instruction, Multiple Threads*): la GPU ejecuta la misma instrucción para un grupo de hilos a la
  vez, cada uno con sus propios datos y registros. Es el SIMD de Flynn (Unidad I) visto desde el hilo: tú escribes
  código escalar "para un hilo" y el *hardware* lo agrupa.
- **Warp**: grupo de 32 hilos consecutivos de un bloque que avanzan juntos, instrucción por instrucción. Si dentro de
  un *warp* unos hilos toman un `if` y otros el `else`, se ejecutan ambas ramas en serie (divergencia; S03).
- **SM** (*Streaming Multiprocessor*): la unidad que ejecuta bloques. Mantiene varios bloques residentes, reparte sus
  *warps* entre planificadores y, cuando un *warp* se detiene esperando memoria (cientos de ciclos), emite la
  instrucción de otro que esté listo. Por eso lanzar muchos más hilos que "núcleos" no es un error: es la forma de
  mantener ocupada la máquina.

## 3. El modelo CUDA

**Anfitrión y dispositivo.** El programa corre en la CPU (*host*). La GPU (*device*) tiene su propia memoria. El
anfitrión reserva memoria en el dispositivo, copia datos, lanza *kernels* y copia resultados de regreso.

**Kernel.** Función marcada con `__global__` que se ejecuta en la GPU por muchos hilos a la vez. Se lanza con
`kernel<<<grid, block>>>(args)`: `block` hilos por bloque (máximo 1024), `grid` bloques en la malla. El lanzamiento
es **asíncrono**: el anfitrión continúa de inmediato.

**Jerarquía.** hilo ∈ bloque ∈ malla. Dentro del *kernel*:

| Variable | Significado | Ejemplo con `n = 1000`, `block = 256` |
|---|---|---|
| `threadIdx.x` | Posición del hilo en su bloque | 0…255 |
| `blockIdx.x` | Posición del bloque en la malla | 0…3 |
| `blockDim.x` | Hilos por bloque | 256 |
| `gridDim.x` | Bloques en la malla | 4 |
| `i = blockIdx.x * blockDim.x + threadIdx.x` | Índice global | hilo 3 del bloque 2 → 515 |

**Tres reglas que van juntas:**

1. Bloques necesarios: `grid = (n + block - 1) / block` (división entera redondeada hacia arriba). `n / block` deja
   elementos sin calcular.
2. Guardia: `if (i < n)`. Los `grid·block − n` hilos sobrantes del último bloque no deben tocar memoria.
3. Verificación: revisar errores de CUDA **y** comparar contra la CPU con tolerancia. Sin error ≠ correcto (idea
   errónea 27).

**API mínima.**

| Llamada | Para qué | Equivalente en Numba |
|---|---|---|
| `cudaMalloc(&d_p, bytes)` | Reservar en el dispositivo | `cuda.to_device(arr)` / `cuda.device_array(n)` |
| `cudaMemcpy(dst, src, bytes, cudaMemcpyHostToDevice / DeviceToHost)` | Copiar (sincroniza) | `cuda.to_device`, `d.copy_to_host()` |
| `kernel<<<grid, block>>>(…)` | Lanzar | `kernel[grid, block](…)` |
| `cudaGetLastError()` | Error de **lanzamiento** (p. ej. `block > 1024`) | Excepción al lanzar |
| `cudaDeviceSynchronize()` | Esperar; error de **ejecución** (acceso ilegal) | `cuda.synchronize()` |
| `cudaFree(d_p)` | Liberar | Automático (recolector) |
| `cudaEventRecord` / `cudaEventElapsedTime` | Medir en ms | `time.perf_counter()` + `cuda.synchronize()` |

## 4. Ejemplo resumido (suma de vectores)

```c
__global__ void vector_add(const float *a, const float *b, float *c, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) c[i] = a[i] + b[i];
}
/* en main: */
int grid = (n + block - 1) / block;
cudaMalloc((void **)&d_a, bytes);  cudaMemcpy(d_a, h_a, bytes, cudaMemcpyHostToDevice);  /* igual b, c */
vector_add<<<grid, block>>>(d_a, d_b, d_c, n);
cudaGetLastError();  cudaDeviceSynchronize();
cudaMemcpy(h_c, d_c, bytes, cudaMemcpyDeviceToHost);
/* comparar h_c con la suma hecha en la CPU; cudaFree(...) */
```

Salida real sin GPU (CUDASIM, `n = 1000`): `grid=4 hilos_lanzados=1024 … checksum=8991.0 max_abs_err=0
verificacion=OK`. Con `grid = 3` forzado: `checksum=6901.0 max_abs_err=18 verificacion=FALLA` **sin** ningún error
de CUDA. Esperado en una T4 con `n = 2^24`: *kernel* ≈ 1 ms; con copias ≈ 30–60 ms; un núcleo de CPU ≈ 18 ms.

## 5. Dónde ejecutar

| Entorno | Cómo activar la GPU | Comandos |
|---|---|---|
| Google Colab | *Entorno de ejecución → Cambiar tipo de entorno de ejecución → GPU (T4)* | `!nvidia-smi` · `%%writefile f.cu` · `!nvcc -O2 -arch=sm_75 f.cu -o f` · `!./f` |
| Kaggle | *Settings → Accelerator → GPU* (T4 o P100) | Igual; con P100 usa `-arch=sm_60` |
| Sin GPU | — | `NUMBA_ENABLE_CUDASIM=1 python3 f_numba.py` (solo correctitud, `n` pequeño); `nvcc -c` para ver si compila |

Si Colab no tiene GPU disponible, verifica la correctitud con CUDASIM y vuelve a intentar en 1–2 horas; no dejes la
pestaña abierta esperando (consume cuota).

## 6. Errores frecuentes

| Síntoma | Causa probable | Qué revisar |
|---|---|---|
| `no CUDA-capable device is detected` | No activaste la GPU en Colab/Kaggle | `!nvidia-smi` |
| `no kernel image is available for execution` | Compilaste para otra arquitectura (P100 ≠ `sm_75`) | `-arch=sm_60` |
| `invalid configuration argument` | `block > 1024` o `grid = 0` | `cudaGetLastError` tras el lanzamiento |
| `an illegal memory access was encountered` | Sin guardia, índice mal calculado, apuntador de anfitrión en el *kernel* | La fórmula de `i`, la guardia, qué apuntadores pasas |
| `verificacion=FALLA` sin error de CUDA | `grid = n / block`, o leer `h_c` sin copiar de vuelta | Número de bloques; `cudaMemcpy` D2H |
| Tiempo del *kernel* ≈ 0 | Mediste sin sincronizar: el lanzamiento es asíncrono | `cudaEventSynchronize` / `cuda.synchronize()` |
| El *kernel* tarda igual con cualquier cambio | No volviste a ejecutar `%%writefile` ni a compilar | Orden de las celdas |
| CUDASIM "se cuelga" | `n` grande simulado hilo por hilo en Python | Usa `n ≤ 10 000` |

## 7. Para saber más

- NVIDIA, *CUDA C Programming Guide*: "Programming Model" (*kernels*, *thread hierarchy*, *memory hierarchy*,
  *heterogeneous programming*) y "Hardware Implementation" (*SIMT architecture*).
- Numba, *CUDA Python*: "Writing CUDA Kernels", "Memory management", "Debugging CUDA Python with the simulator".
- Kirk y Hwu, *Programming Massively Parallel Processors*, cap. 2 (programación heterogénea de datos paralelos) y
  cap. 3 (organización de hilos).
