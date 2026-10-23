> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S03 · jueves 26 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# Ejemplo resuelto · Suma de `n` números en la GPU con reducción en árbol (y su espejo en Numba)

Lee el código con las pausas. En cada pausa contesta en voz baja (o por escrito) **antes** de abrir la respuesta. El
archivo completo, con las tres versiones (`atomic`, `tree_div`, `tree_nodiv`), la segunda etapa atómica, la medición
con `cudaEvent_t` y la salida CSV, está en `practica-guiada/reduce_sum.cu`; aquí va la versión mínima del árbol sin
divergencia, que es la que conviene aprenderse.

## Problema

Dados `n` `float` en la GPU (`x[i] = 1.0 + (i % 10)·0.1`, `x[n−1] = 9.5`; `n = 1000` para verificar, `n = 2^20`
para medir), calcular su suma en la GPU sin que ningún hilo tenga que esperar a toda la GPU, y verificar el resultado
contra la CPU. En la S01 el producto punto dejó los productos parciales en un arreglo y los sumó el anfitrión; hoy la
GPU suma dentro de cada bloque y el anfitrión solo recibe un parcial por bloque.

## Plan en 3 líneas

1. Cada bloque copia sus 256 elementos a memoria compartida y los reduce **en árbol**: en cada nivel la mitad de los
   hilos activos suma pares; `log₂(256) = 8` niveles, una barrera entre nivel y nivel.
2. El hilo 0 de cada bloque escribe la suma del bloque en `partial[blockIdx.x]` (memoria global).
3. **Segunda etapa:** el anfitrión copia los `gridDim.x` parciales y los suma en `double`; compara contra la suma
   secuencial en `double` con tolerancia relativa `1e-4`.

## Código comentado

```c
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <cuda_runtime.h>

#define MAX_BLOCK 1024
#define TOL_REL 1e-4
#define CUDA_CHECK(call) do { cudaError_t e__ = (call); if (e__ != cudaSuccess) {                 \
    fprintf(stderr, "Error de CUDA en %s:%d: %s\n", __FILE__, __LINE__, cudaGetErrorString(e__)); \
    exit(EXIT_FAILURE); } } while (0)

/* Reducción en árbol SIN divergencia: los hilos activos de cada nivel son consecutivos (0..stride-1). */
__global__ void reduce_tree_nodiv(const float *x, float *partial, int n)
{
    __shared__ float s[MAX_BLOCK];               /* visible solo dentro de este bloque */
    int tid = threadIdx.x;
    int i = blockIdx.x * blockDim.x + tid;

    s[tid] = (i < n) ? x[i] : 0.0f;              /* (1) fuera de rango: el neutro de la suma, no return */
    __syncthreads();                             /* (2) barrera A: todo el bloque terminó de cargar */

    for (int stride = blockDim.x / 2; stride > 0; stride >>= 1) {
        if (tid < stride)                        /* (4) activos: 0..stride-1, warps completos */
            s[tid] += s[tid + stride];
        __syncthreads();                         /* (3) barrera B, FUERA del if: un nivel por vez */
    }
    if (tid == 0)
        partial[blockIdx.x] = s[0];              /* (5) un parcial por bloque sale a memoria global */
}

int main(int argc, char **argv)
{
    int n = (argc > 1) ? atoi(argv[1]) : (1 << 20);
    int block = 256;                             /* potencia de 2: el árbol lo necesita */
    int grid = (n + block - 1) / block;
    size_t bytes = (size_t)n * sizeof(float);

    float *h_x = (float *)malloc(bytes), *h_partial = (float *)malloc((size_t)grid * sizeof(float));
    for (int i = 0; i < n; i++) h_x[i] = 1.0f + (float)(i % 10) * 0.1f;
    h_x[n - 1] = 9.5f;
    double ref = 0.0;                            /* referencia: secuencial en double */
    for (int i = 0; i < n; i++) ref += h_x[i];

    float *d_x, *d_partial;
    CUDA_CHECK(cudaMalloc((void **)&d_x, bytes));
    CUDA_CHECK(cudaMalloc((void **)&d_partial, (size_t)grid * sizeof(float)));
    CUDA_CHECK(cudaMemcpy(d_x, h_x, bytes, cudaMemcpyHostToDevice));

    reduce_tree_nodiv<<<grid, block>>>(d_x, d_partial, n);
    CUDA_CHECK(cudaGetLastError());              /* ¿lanzamiento válido? */
    CUDA_CHECK(cudaDeviceSynchronize());         /* ¿ejecución sin falla? */

    /* (6) Segunda etapa en el anfitrión: copia de grid parciales (16 KB para 2^20) y suma en double */
    CUDA_CHECK(cudaMemcpy(h_partial, d_partial, (size_t)grid * sizeof(float), cudaMemcpyDeviceToHost));
    double sum = 0.0;
    for (int b = 0; b < grid; b++) sum += h_partial[b];

    double err_rel = fabs(sum - ref) / fabs(ref);    /* (7) verificación con tolerancia relativa */
    printf("n=%d block=%d grid=%d suma=%.6f referencia=%.6f err_rel=%.2e verificacion=%s\n",
           n, block, grid, sum, ref, err_rel, (err_rel <= TOL_REL) ? "OK" : "FALLA");

    CUDA_CHECK(cudaFree(d_x)); CUDA_CHECK(cudaFree(d_partial)); free(h_x); free(h_partial);
    return 0;
}
```

Compila en Colab con `nvcc -O2 -arch=sm_75 ejemplo.cu -o ejemplo`; sin GPU, `nvcc -c -arch=sm_75` solo comprueba
que compila (así se verificó `reduce_sum.cu`, que contiene este mismo *kernel*).

## Salida

**Real, sin GPU** (el mismo *kernel* en Numba bajo el simulador, y la referencia en C; obtenidas al escribir este
material con los archivos de `practica-guiada/`):

```
$ NUMBA_ENABLE_CUDASIM=1 python3 reduce_sum_numba.py all 1000 256
reduce_sum_numba: n=1000 block=256 grid=4 modo=CUDASIM
referencia_cpu_double=1457.600012  tolerancia_relativa=1e-04
version=atomic     etapa2=-      atomicas_globales=1000     tiempo_simulador_ms=189.0 (NO es una medición)
   suma=1457.599976 err_rel=2.49e-08 verificacion=OK
version=tree_div   etapa2=cpu    atomicas_globales=0        tiempo_simulador_ms=1588.5 (NO es una medición)
   suma=1457.600037 err_rel=1.70e-08 verificacion=OK parciales_bit_a_bit_igual_a_emulacion_cpu=si
version=tree_nodiv etapa2=cpu    atomicas_globales=0        tiempo_simulador_ms=2331.1 (NO es una medición)
   suma=1457.600006 err_rel=3.93e-09 verificacion=OK parciales_bit_a_bit_igual_a_emulacion_cpu=si

$ ./reduce_sum_cpu 1048576 256
ref_double            =1520442.012500  (suma secuencial en double; mediana_ms=1.210 de 5, min 0.765, max 1.877)
float_secuencial      =1520441.875000  err_rel=9.04e-08  dentro_de_tolerancia  (informativo: un acumulador)
float_orden_permutado =1520444.750000  err_rel=1.80e-06  dentro_de_tolerancia  (informativo: emula el orden arbitrario de las atómicas)
float_arbol_div       =1520442.024994  err_rel=8.22e-09  dentro_de_tolerancia  (mismo orden que tree_div)
float_arbol_nodiv     =1520442.024994  err_rel=8.22e-09  dentro_de_tolerancia  (mismo orden que tree_nodiv)
max=9.500000 en i=1048575
atomicas_globales: atomic=1048576  tree+etapa2=cpu: 0  tree+etapa2=atomic: 4096
```

Tres sumas distintas para `n = 1000`, las tres `OK`: el orden de las sumas cambia el último dígito. Los parciales
del árbol coinciden **bit a bit** con una emulación en CPU del mismo orden: la diferencia con la referencia es solo
redondeo, no un error.

**Esperada en la GPU** (no ejecutada en el entorno de autoría; T4 de Colab; los tiempos son órdenes de magnitud y
dependen de la GPU asignada):

```
$ ./ejemplo 1048576
n=1048576 block=256 grid=4096 suma=1520442.024994 referencia=1520442.012500 err_rel=8.22e-09 verificacion=OK
```

Con `reduce_sum.cu` completo, además: `atomic` `kernel_mediana_ms ≈ 0.5–10` (un millón de atómicas serializadas sobre
una dirección) y `suma` distinta en cada corrida; `tree_nodiv` `≈ 0.02–0.05 ms` con `etapa2_cpu_ms ≈ 0.02–0.05`: la
copia de 16 KB cuesta tanto como el *kernel*. Lo que **debe** coincidir con la salida real de arriba: `grid`,
`atomicas_globales`, la `suma` de los árboles (`1520442.024994`) y `parciales_bit_a_bit…=si`.

## Pausas de autoexplicación

**(1) Los hilos con `i ≥ n` no tienen dato. ¿Por qué escriben `0.0f` en `s[tid]` en lugar de hacer `return`?**
<details><summary>Respuesta</summary>
Porque más abajo hay barreras y <strong>todos</strong> los hilos del bloque deben alcanzarlas; un hilo que regresó
antes deja la barrera incompleta (comportamiento indefinido: cuelgue o basura). Y porque el árbol va a leer
<code>s[tid + stride]</code> para todo <code>tid &lt; stride</code>: si la posición no se escribió, contiene lo que
dejó un bloque anterior. <code>0.0f</code> es el <strong>neutro</strong> de la suma: participa sin alterar nada. Para
un máximo el neutro sería <code>-INFINITY</code> (fase Modificar).
</details>

**(2) ¿Para qué sirve la barrera A, justo después de la carga?**
<details><summary>Respuesta</summary>
El primer nivel hace <code>s[tid] += s[tid + 128]</code>: el hilo 0 lee lo que cargó el hilo 128, que está en
<strong>otro <em>warp</em></strong> y puede ir atrasado. Sin la barrera, el hilo 0 podría leer <code>s[128]</code>
antes de que el hilo 128 lo escriba. La barrera garantiza que, cuando cualquier hilo empieza el nivel 1, los 256
valores ya están en compartida.
</details>

**(3) ¿Por qué la barrera B está fuera del `if (tid < stride)` y no dentro?**
<details><summary>Respuesta</summary>
Dentro del <code>if</code> solo la alcanzarían los hilos activos de ese nivel; los demás seguirían de largo y la
barrera quedaría incompleta (idea errónea 32: "un <code>barrier</code> dentro de un <code>if</code> está bien si lo
ejecuta algún hilo"). Además la necesitan <strong>todos</strong>: el nivel siguiente lee posiciones que escribieron
hilos que en este nivel estaban activos y que en el siguiente ya no lo estarán. Una barrera por nivel, fuera de
todo <code>if</code>; <code>log₂(blockDim.x)</code> barreras en total.
</details>

**(4) `tid < stride` y `tid % (2·stride) == 0` recorren el mismo árbol. ¿Qué cambia?**
<details><summary>Respuesta</summary>
Qué hilos están activos en cada nivel. Con <code>tid % (2·stride) == 0</code> trabajan los pares, luego los
múltiplos de 4, etc.: en <strong>cada</strong> <em>warp</em> quedan 16, 8, 4, 2, 1 carriles activos y el <em>warp</em>
ejecuta la instrucción con el resto apagado (divergencia): 47 pasos de <em>warp</em> por bloque de 256. Con
<code>tid &lt; stride</code> trabajan los hilos 0..127, luego 0..63, …: <em>warps</em> <strong>completos</strong>
activos o completos apagados mientras <code>stride ≥ 32</code>; solo el <em>warp</em> 0 diverge en los últimos cinco
niveles (<code>stride = 16, 8, 4, 2, 1</code>): 12 pasos de <em>warp</em>. Mismas 255 sumas, cuatro veces menos instrucciones. Con <code>n = 2^20</code> la
diferencia de tiempo es modesta porque domina la lectura de 4 MB desde memoria global.
</details>

**(5) El hilo 0 tiene la suma de su bloque en `s[0]`. ¿Por qué no suma ahí mismo los `s[0]` de los demás bloques?**
<details><summary>Respuesta</summary>
Porque no puede verlos: <code>s</code> vive en la memoria compartida de <strong>cada</strong> bloque y desaparece
cuando el bloque termina. Y aunque los parciales estén en memoria global, ninguna <code>__syncthreads()</code>
espera a otros bloques (idea errónea 25): el bloque 0 podría leer parciales que todavía no se han escrito, sin
ningún error de CUDA. Entre bloques solo sincroniza el <strong>fin del <em>kernel</em></strong>; por eso la segunda
etapa ocurre después (anfitrión o segundo <em>kernel</em>) o con atómicas, que no esperan.
</details>

**(6) ¿Por qué la segunda etapa se hace en `double`, y es gratis la copia de los parciales?**
<details><summary>Respuesta</summary>
En <code>double</code> para no agregar redondeo a 4096 sumas más y poder usar el mismo resultado como referencia
precisa. La copia <strong>no</strong> es gratis: 16 KB por PCIe tienen una latencia fija de decenas de microsegundos,
comparable al <em>kernel</em> entero (≈ 30 µs en una T4; idea errónea 24). Si la reducción se repite muchas veces
dentro de un algoritmo, conviene la alternativa: <code>atomicAdd(out, s[0])</code> desde el hilo 0 de cada bloque
(4096 atómicas, el resultado se queda en la GPU) o un segundo <em>kernel</em>. Se mide en la S04.
</details>

**(7) ¿Por qué `err_rel <= 1e-4` y no `sum == ref`?**
<details><summary>Respuesta</summary>
Porque la GPU suma en <code>float</code> y en otro orden: el árbol da <code>1520442.024994</code>, la referencia en
<code>double</code> <code>1520442.012500</code>, y las dos son "correctas" (idea errónea 10). La tolerancia es
holgada a propósito: deja pasar el orden arbitrario de las atómicas (error ~<code>1e-6</code>) pero no la pérdida de
un bloque entero. Como no notaría un solo elemento faltante entre un millón, el programa completo además prueba con
<code>n</code> pequeño, compara los parciales bit a bit con la emulación y pone el máximo <code>9.5</code> al final
del arreglo. Con enteros (histograma) la comparación sí es exacta.
</details>

## Variantes que fallan

**Variante A: sin la barrera B.** Ejecutada realmente bajo CUDASIM (`--sin-sync` quita la barrera de dentro del
ciclo; tres corridas seguidas, `tree_div`, `n = 1000`, bloque 256):

```
   suma=227.600006 err_rel=8.44e-01 verificacion=FALLA parciales_bit_a_bit_igual_a_emulacion_cpu=no
   suma=119.300003 err_rel=9.18e-01 verificacion=FALLA parciales_bit_a_bit_igual_a_emulacion_cpu=no
   suma=188.900002 err_rel=8.70e-01 verificacion=FALLA parciales_bit_a_bit_igual_a_emulacion_cpu=no
```

Tres resultados distintos, ninguno cerca de `1457.6`, ningún error de CUDA. Un *warp* leyó `s[tid + stride]` antes
de que otro lo escribiera. En la GPU (esperado, no ejecutado aquí) con bloques de 256 falla casi siempre; con bloques
de 32 (un solo *warp*) "suele salir bien" porque el *warp* avanza casi junto, pero desde Volta no está garantizado:
cinco `OK` no demuestran nada (idea errónea 7). `compute-sanitizer --tool racecheck` reporta la carrera aunque el
número salga bien.

**Variante B: `block = 96`.** Ejecutada bajo CUDASIM (`tree_nodiv`, `n = 1000`):

```
aviso: el árbol supone block potencia de 2; con block=96 se pierden sumandos (experimento de la fase Investigar)
   suma=974.599998 err_rel=3.31e-01 verificacion=FALLA parciales_bit_a_bit_igual_a_emulacion_cpu=si
```

`stride = 48, 24, 12, 6, 3, 1`: tras `stride = 3` quedan tres parciales `s[0], s[1], s[2]`; con `stride = 1` solo
`s[0] += s[1]`, y `s[2]` (un tercio de los datos) nunca se suma: `974.6 ≈ 2/3 · 1457.6`. Sin error de CUDA (idea
errónea 27). La emulación coincide bit a bit porque repite el mismo algoritmo equivocado: esa comparación detecta
diferencias de orden, no de algoritmo; para eso está la referencia en `double`.

**Variante C: la atómica ingenua con `n = 2^24`.** Salida real de la referencia en CPU, que emula el acumulador
`float` en orden arbitrario:

```
ref_double            =24326970.200000
float_orden_permutado =27075950.000000  err_rel=1.13e-01  FUERA
float_arbol_nodiv     =24326970.399994  err_rel=8.22e-09  dentro_de_tolerancia
```

Un acumulador `float` que llega a `16 777 216 = 2^24` ya no cambia al sumarle `1.0`, y sumarle `1.1`–`1.9` lo
redondea a `+2` (el espaciado ahí es 2): por eso el resultado se pasa de la referencia. Esperado en la GPU: `atomic`
marca `FALLA` con 10 % de error; los árboles, `OK`. La atómica ingenua no solo es lenta: con `n` grande es
incorrecta.

## El mismo *kernel* en Numba

```python
from numba import cuda, float32

@cuda.jit
def reduce_tree_nodiv(x, partial, n):
    s = cuda.shared.array(256, float32)           # tamaño constante: el bloque es 256
    tid = cuda.threadIdx.x
    i = cuda.blockIdx.x * cuda.blockDim.x + tid
    s[tid] = x[i] if i < n else float32(0.0)
    cuda.syncthreads()                            # barrera A
    stride = cuda.blockDim.x // 2
    while stride > 0:
        if tid < stride:
            s[tid] += s[tid + stride]
        cuda.syncthreads()                        # barrera B, fuera del if
        stride //= 2
    if tid == 0:
        partial[cuda.blockIdx.x] = s[0]

# anfitrión: reduce_tree_nodiv[grid, 256](d_x, d_partial, n); cuda.synchronize()
# total = float(np.sum(d_partial.copy_to_host(), dtype=np.float64))
```

Con `NUMBA_ENABLE_CUDASIM=1` cada hilo se simula en Python: sirve para verificar barreras e índices con `n`
pequeño (en el simulador la carrera de la variante A falla **siempre**, también con bloques de 32), no para medir.

## Qué te llevas

- Una barrera por nivel, fuera de todo `if`; los hilos sobrantes cargan el neutro y no regresan antes.
- `__syncthreads()` es del bloque. La segunda etapa (parciales al anfitrión, segundo *kernel* o una atómica por
  bloque) existe porque no hay barrera entre bloques.
- Hilos activos consecutivos (`tid < stride`): *warps* enteros encendidos o apagados, no divergidos.
- Se verifica contra una referencia en `double` con tolerancia declarada; en `float` el orden cambia el resultado y
  la atómica ingenua con `n` grande es incorrecta. "Salió bien cinco veces" no es verificación.
