> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S04 · lunes 30 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# Ejemplo resuelto · Cuatro formas de medir el mismo kernel

Código completo: `practica-guiada/medir_eventos.cu`. Aquí se recorre paso a paso con pausas de autoexplicación:
intenta responder cada una antes de abrir la respuesta.

## Problema

Tienes `saxpy` (`y = α·x + y`) sobre `n = 2^24` floats (64 MB por vector) en una T4 de Colab. Quieres reportar
"cuánto tarda en GPU" para compararlo con la versión de CPU. ¿Qué número es el honesto?

## Plan (tres líneas)

1. Medir el kernel de cuatro maneras: cronómetro de CPU sin sincronizar, cronómetro de CPU con
   `cudaDeviceSynchronize`, eventos alrededor del kernel, eventos alrededor de H2D + kernel + D2H.
2. Seguir el protocolo: 1 calentamiento, 5 repeticiones, mediana, verificación contra la CPU.
3. Reportar **dos** números (con y sin copias) y el porcentaje que representan las copias.

## Código comentado (fragmentos)

El kernel es el de S01, con la guarda para el último bloque:

```cuda
__global__ void saxpy_kernel(float alpha, const float *x, float *y, int n)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) y[i] = alpha * x[i] + y[i];
}
```

Antes de medir, el arranque frío y el calentamiento:

```cuda
double t0 = cpu_seconds();
CUDA_CHECK(cudaFree(0));                      // fuerza la creación del contexto CUDA
double t_context_ms = (cpu_seconds() - t0) * 1e3;
...
saxpy_kernel<<<grid, BLOCK_SIZE>>>(alpha, d_x, d_y, n);   // calentamiento: no se cuenta
CUDA_CHECK(cudaGetLastError());
CUDA_CHECK(cudaDeviceSynchronize());
```

**Pausa 1.** ¿Por qué se llama a `cudaFree(0)` antes de cualquier otra cosa y se cronometra?

<details><summary>Respuesta</summary>
La primera llamada a la API de CUDA crea el contexto del dispositivo (carga el driver, reserva estructuras,
inicializa la GPU). Tarda decenas o cientos de milisegundos y ocurre **una vez por proceso**. Si no la separas,
la primera medición que hagas la incluye y parece que el primer kernel tardó 200 ms. `cudaFree(0)` es la forma
idiomática de pagar ese costo a propósito y fuera del cronómetro. Lo mismo hace el calentamiento con el primer
lanzamiento (carga del módulo, cachés frías): es la regla 2.1 del protocolo del curso.
</details>

Las cuatro formas, dentro del ciclo de repeticiones:

```cuda
// Forma 1 (INCORRECTA): cronómetro de CPU sin sincronizar
double t = cpu_seconds();
saxpy_kernel<<<grid, BLOCK_SIZE>>>(alpha, d_x, d_y, n);
t_nosync[r] = (cpu_seconds() - t) * 1e3;
CUDA_CHECK(cudaDeviceSynchronize());        // fuera del cronómetro: por eso la medición miente

// Forma 2: cronómetro de CPU + cudaDeviceSynchronize
t = cpu_seconds();
saxpy_kernel<<<grid, BLOCK_SIZE>>>(alpha, d_x, d_y, n);
CUDA_CHECK(cudaDeviceSynchronize());
t_sync[r] = (cpu_seconds() - t) * 1e3;

// Forma 3: eventos alrededor del kernel
CUDA_CHECK(cudaEventRecord(ev_start, 0));
saxpy_kernel<<<grid, BLOCK_SIZE>>>(alpha, d_x, d_y, n);
CUDA_CHECK(cudaEventRecord(ev_stop, 0));
CUDA_CHECK(cudaEventSynchronize(ev_stop));
CUDA_CHECK(cudaEventElapsedTime(&ms, ev_start, ev_stop));
t_event[r] = ms;

// Forma 4: eventos alrededor de H2D + kernel + D2H
CUDA_CHECK(cudaEventRecord(ev_start, 0));
CUDA_CHECK(cudaMemcpy(d_x, h_x, bytes, cudaMemcpyHostToDevice));
CUDA_CHECK(cudaMemcpy(d_y, h_y, bytes, cudaMemcpyHostToDevice));
saxpy_kernel<<<grid, BLOCK_SIZE>>>(alpha, d_x, d_y, n);
CUDA_CHECK(cudaMemcpy(h_out, d_y, bytes, cudaMemcpyDeviceToHost));
CUDA_CHECK(cudaEventRecord(ev_stop, 0));
CUDA_CHECK(cudaEventSynchronize(ev_stop));
CUDA_CHECK(cudaEventElapsedTime(&ms, ev_start, ev_stop));
t_total[r] = ms;
```

**Pausa 2.** La forma 1 da ≈ 0.01 ms y la forma 2 ≈ 1 ms para el **mismo** kernel. ¿Qué midió la forma 1?

<details><summary>Respuesta</summary>
Midió cuánto tardó la CPU en **encolar** el lanzamiento (≈ 5–15 µs). El operador `<<<>>>` es asíncrono:
regresa en cuanto el trabajo queda en la cola del *stream*; la GPU lo ejecuta después. Cuando la CPU lee el
reloj por segunda vez, el kernel apenas empieza. La forma 2 obliga a la CPU a esperar con
`cudaDeviceSynchronize()` y por eso ve el tiempo completo (más unos microsegundos de la propia espera).
Este es el error más común en reportes de "speedup de 1000×".
</details>

**Pausa 3.** ¿Por qué antes de cada forma se vuelve a copiar `h_y` a `d_y`, y por qué esa copia queda **fuera**
del cronómetro de las formas 1–3?

<details><summary>Respuesta</summary>
`saxpy` es en sitio: después de un lanzamiento `d_y` ya vale `α·x + y`; sin restaurarlo, la repetición
siguiente calcularía otra cosa y la verificación final fallaría. La copia se deja fuera porque en las formas
1–3 la región de interés es **solo el kernel** (protocolo §2: se cronometra la región que se paraleliza). En la
forma 4 la región de interés incluye las copias a propósito: es el costo real cuando los datos viven en la CPU.
</details>

**Pausa 4.** En la forma 3 se usa `cudaEventSynchronize(ev_stop)`. ¿Serviría `cudaDeviceSynchronize()`? ¿Qué
es lo que de verdad mide el tiempo?

<details><summary>Respuesta</summary>
Serviría: ambas esperan a que la GPU llegue a `ev_stop`. Lo que **mide** no es la espera, sino la diferencia
entre las dos marcas de tiempo que la GPU estampó al pasar por `ev_start` y `ev_stop` en el *stream* 0; la
sincronización solo garantiza que la segunda marca ya exista cuando la lees con `cudaEventElapsedTime`. Por eso
los eventos no incluyen la latencia de la CPU y dan algo menos que la forma 2. `cudaEventSynchronize` espera
solo a ese evento; `cudaDeviceSynchronize` espera a todo el dispositivo (más de lo necesario si hubiera
otros *streams*).
</details>

**Pausa 5.** La forma 4 da ≈ 50 ms y la forma 3 ≈ 1 ms. ¿Cuál reportas?

<details><summary>Respuesta</summary>
**Las dos**, y además el porcentaje: copias ≈ (50 − 1)/50 ≈ 98 %. El protocolo del curso (regla de
transferencias en GPU) pide reportar con y sin copias porque responden preguntas distintas: la forma 3 dice qué
tan bien usa la GPU su memoria (≈ 200 GB/s de 320); la forma 4 dice si conviene mandar este trabajo a la GPU
cuando los datos empiezan y terminan en la CPU (para saxpy aislado: no). Omitir la forma 4 es la idea errónea
24; omitir la forma 3 esconde que el kernel está bien escrito y que el problema es el camino de los datos.
</details>

## Salida

**Salida real en el entorno de autoría (sin GPU):** `nvcc -c -arch=sm_75 medir_eventos.cu` y
`nvcc -c -arch=sm_60 medir_eventos.cu` compilan sin errores ni *warnings* (es lo que verifica `make test`).
La versión de CPU equivalente (`bench_cpu`, `gcc -O2`, 4 núcleos) da para `n = 2^24`:
`saxpy 18.3 ms (11.0 GB/s)`, que es la escala del renglón "CPU" contra el que se calcula el *speedup*.

**Salida esperada en una T4 de Colab (no ejecutada en el entorno de autoría; los valores dependen de la GPU y del día):**

```
medir_eventos: saxpy con n = 16777216 (64.0 MB por vector), bloque = 256, malla = 65536
Primera llamada CUDA (creación del contexto): ≈ 80–300 ms
Primer lanzamiento del kernel (frío):          ≈ 1–5 ms  <- por eso hay calentamiento

Forma de medir                                 mediana ms        min        max
1. CPU sin sincronizar (INCORRECTA)              ≈ 0.01     ≈ 0.005    ≈ 0.03
2. CPU + cudaDeviceSynchronize                   ≈ 1.0–1.3  ...        ...
3. cudaEvent alrededor del kernel                ≈ 0.9–1.0  ...        ...
4. cudaEvent H2D + kernel + D2H                  ≈ 40–70    ...        ...

Copias = ≈ 97–98 % del total (total ≈ 50 ms, kernel ≈ 0.9 ms)
Ancho de banda efectivo del kernel: ≈ 200–230 GB/s (201326592 bytes leídos+escritos)
Verificación contra CPU: OK (error máximo 0.00e+00)
```

Lectura: 201 MB en ≈ 0.9 ms son ≈ 220 GB/s, 65–70 % de los 320 GB/s teóricos; el kernel está limitado por
memoria y ya está cerca del techo. Las copias (≈ 190 MB por PCIe a ≈ 4 GB/s) son el 98 %. Con la CPU en
≈ 18–40 ms: *speedup* solo kernel ≈ 20–40×; *speedup* con copias ≈ 0.3–0.6 (**la CPU gana**).

## Variante que falla (a propósito)

Lanza el kernel con 2048 hilos por bloque (más del máximo, 1024) y **no** revises `cudaGetLastError()`:

```cuda
saxpy_kernel<<<grid, 2048>>>(alpha, d_x, d_y, n);   // configuración inválida: el kernel NO se ejecuta
```

Los eventos reportan ≈ 0.003 ms (no hubo trabajo), el "*speedup*" sale de 10 000× y `h_out` conserva los valores
viejos. La verificación contra la CPU lo detecta (`FALLA`) y `cudaGetLastError()` devuelve
`invalid configuration argument`. Regla: ningún tiempo cuenta sin verificación (idea errónea 27).

## Qué te llevas

- Dos números por kernel: sin copias (calidad del kernel) y con copias (conveniencia real). Y el porcentaje.
- Eventos para todo lo que pasa en el *stream*; cronómetro de CPU solo con sincronización.
- Calentamiento, 5 repeticiones, mediana, verificación, `cudaGetLastError`. Sin excepciones.
