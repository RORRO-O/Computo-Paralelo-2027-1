> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S03 · jueves 26 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# Notas · Sincronización y reducción en GPU

Palabras clave: barrera de bloque (`__syncthreads()`), operación atómica (`atomicAdd`), contención, reducción en
árbol, segunda etapa, *warp*, divergencia, condición de carrera (*data race*), tolerancia, histograma privatizado.

## 1. `__syncthreads()`: una barrera, un bloque

`__syncthreads()` detiene a cada hilo hasta que **todos los hilos de su bloque** han llegado a esa línea, y garantiza
que lo que el bloque escribió antes (en compartida y en global) es visible para el bloque después. Eso es todo. No
espera a otros bloques ni sincroniza "toda la GPU" (idea errónea 25). Entre bloques solo hay dos formas de
coordinarse: el **fin del *kernel*** (el siguiente *kernel* o el `cudaMemcpy` ya ven lo que escribieron todos) y las
**atómicas**, que no esperan: combinan en el orden en que llegan.

Dos reglas: (1) la barrera la alcanzan **todos** los hilos del bloque, la misma barrera; un `__syncthreads()` dentro
de un `if` que solo cumplen algunos es comportamiento indefinido (idea errónea 32, ahora en GPU): va **fuera** del
`if`. (2) Los hilos sobrantes del último bloque (`i ≥ n`) no hacen `return` antes de una barrera: cargan el neutro
de la operación (`0` para sumar, `-INFINITY` para el máximo) y pasan por las barreras como todos.

## 2. Atómicas: correctas, pero con precio

`atomicAdd(&x, v)` hace leer-sumar-escribir sobre `x` de forma indivisible. Si 1000 hilos la aplican sobre la misma
dirección, las 1000 se **serializan**. El costo crece con la **contención** (cuántos hilos compiten por una
dirección), no solo con el número de atómicas. Es el `atomic` de OpenMP (S07) con cien mil veces más hilos y la
memoria más lejos; las atómicas sobre memoria **compartida** son mucho más baratas y compiten solo dentro del bloque.

En CUDA C hay `atomicAdd` para enteros, `float` y `double` (desde `sm_60`); `atomicMax`/`atomicMin` solo para
enteros; `atomicCAS` para construir el resto. En Numba: `cuda.atomic.add`, `cuda.atomic.max`, etc. Consecuencias: un
`atomicAdd` de `float` suma en orden arbitrario, así que el resultado puede cambiar entre corridas (es orden, no
carrera); y para un máximo de `float` no hay atómica directa: se usa el árbol.

## 3. Reducción en árbol: tres versiones y una segunda etapa

Sumar `n` números con un hilo por elemento (código completo en `practica-guiada/reduce_sum.cu`):

| Versión | Qué hace cada hilo | Atómicas globales (`n = 2^20`, bloque 256) | ¿Determinista? | Pasos de *warp* por bloque |
|---|---|---|---|---|
| `atomic` | `atomicAdd(out, x[i])` | 1 048 576 sobre **una** dirección | No (orden) | — |
| `tree_div` | carga a `s[tid]`; niveles `stride = 1, 2, 4, …` con `if (tid % (2·stride) == 0)` | 0 (etapa 2 en CPU) o 4096 (etapa 2 atómica) | Sí | 47, todos divergidos |
| `tree_nodiv` | carga a `s[tid]`; niveles `stride = 128, 64, …, 1` con `if (tid < stride)` | 0 o 4096 | Sí | 12, 5 divergidos |

El árbol tiene `log₂(blockDim.x)` niveles (8 para 256), hace `blockDim.x − 1` sumas por bloque y lleva **una**
`__syncthreads()` entre nivel y nivel: el nivel `k` lee lo que el `k−1` escribió. Al final `s[0]` tiene la suma del
bloque y hay que combinar los `gridDim.x` parciales (**segunda etapa**): copiarlos al anfitrión y sumarlos en
`double` (0 atómicas; una copia pequeña que **sí** cuesta: decenas de microsegundos de latencia, idea errónea 24), o
que el hilo 0 de cada bloque haga `atomicAdd(out, s[0])` (una atómica por bloque; el resultado se queda en la GPU),
o un segundo *kernel* de un bloque. El árbol supone `blockDim.x` potencia de 2: con `block = 96` no hay error de CUDA
y se pierde un tercio de los datos (`974.6` en vez de `1457.6`); "sin error" no es "correcto" (idea errónea 27).

## 4. *Warps* y divergencia

Un *warp* son 32 hilos consecutivos que ejecutan la misma instrucción. Si unos cumplen el `if` y otros no, el *warp*
ejecuta la rama con los carriles sobrantes apagados: cuesta lo mismo que si todos trabajaran. En `tree_div`, en el
primer nivel trabajan los `tid` pares: 16 carriles activos en **cada** uno de los 8 *warps*, todos divergidos. En
`tree_nodiv` trabajan `tid < 128`: 4 *warps* completos activos y 4 apagados (un *warp* apagado no cuesta
instrucciones). Regla: **hilos activos consecutivos**; la paridad es el peor caso. Con `n = 2^20` la diferencia de
tiempo entre los dos árboles es pequeña (domina leer 4 MB de memoria global); cuando el árbol es el trabajo
principal, se nota.

## 5. Carreras en GPU y por qué "a veces sale bien"

Sin la barrera entre niveles, el hilo 0 del nivel 2 puede leer `s[2]` antes de que el hilo 2 lo actualice: una
carrera de datos cuyo resultado depende de qué *warp* llegó primero. Con 8 *warps* por bloque casi siempre falla y
cambia entre corridas; con un solo *warp* (32 hilos) "suele salir bien" porque los 32 avanzan casi juntos. **No está
garantizado**: desde Volta (la T4 es Turing) los hilos de un *warp* pueden avanzar de forma independiente. Cinco
corridas `OK` no son evidencia (idea errónea 7). Sí lo son: comparar contra la referencia en varias corridas y con
varios tamaños de bloque, el simulador de Numba (en CUDASIM la carrera falla siempre) y `compute-sanitizer --tool
racecheck`, que reporta carreras sobre compartida aunque el número haya salido bien.

## 6. Verificar contra la CPU: con tolerancia o exacto

En `float` el orden de las sumas cambia el redondeo: cuatro órdenes del mismo arreglo dan cuatro números, todos
"correctos" (idea errónea 10). Por eso se compara contra una referencia en **mayor precisión** (`double`) con una
**tolerancia relativa declarada** (`1e-4` en la práctica), y no contra la suma secuencial en `float`: con `2^24`
elementos el acumulador `float` se equivoca 10 % (a `16 777 216` sumarle `1.0` no cambia el valor) y la versión
`atomic` **falla** aunque cada atómica sea correcta. Con enteros (histograma, conteos) o cuando el resultado es uno de
los datos (máximo), la comparación es **exacta**.

## 7. Histograma: atómicas globales contra histograma privado por bloque

`hist_global_atomic`: cada hilo hace `atomicAdd(&hist[v[i]], 1)` sobre 16 contadores en memoria global; con el 30 %
de los datos en un bin, cientos de miles de hilos compiten por una dirección. `hist_shared_atomic` (el `TODO(1)` de
la práctica guiada): cada bloque cuenta en `__shared__ unsigned int s_hist[BINS]` (ceros cooperativos → barrera →
atómicas en compartida → barrera → volcado con una `atomicAdd` global por bin), así que las atómicas globales pasan de
`n` a `BINS · gridDim.x` (`65 536` en vez de `1 048 576` para `2^20`). Es el histograma local por hilo de la Práctica 4
con el bloque en el papel del hilo. La primera barrera evita sumar sobre un contador aún no puesto en cero; la
segunda evita volcar un contador que otro hilo aún incrementa: sin ella el histograma queda incompleto "a veces".

## 8. Ejemplo resumido (árbol sin divergencia; completo en `ejemplo-resuelto.md`)

```c
__global__ void reduce_tree_nodiv(const float *x, float *partial, int n) {
    __shared__ float s[256];
    int tid = threadIdx.x, i = blockIdx.x * blockDim.x + tid;
    s[tid] = (i < n) ? x[i] : 0.0f;                      /* fuera de rango: neutro, no return */
    __syncthreads();                                     /* (A) todo el bloque cargó */
    for (int stride = blockDim.x / 2; stride > 0; stride >>= 1) {
        if (tid < stride) s[tid] += s[tid + stride];     /* hilos activos consecutivos */
        __syncthreads();                                 /* (B) fuera del if: un nivel por vez */
    }
    if (tid == 0) partial[blockIdx.x] = s[0];            /* etapa 2: el anfitrión suma los parciales */
}
```

Salida real sin GPU (simulador de Numba, `n = 1000`, bloque 256): `atomic 1457.599976`, `tree_div 1457.600037`,
`tree_nodiv 1457.600006`, referencia `1457.600012`, las tres `OK`; sin la barrera (B), tres corridas: `227.6`,
`119.3`, `188.9`, todas `FALLA`. Esperado en una T4 con `2^20`: `atomic` ≈ 1–10 ms; árboles ≈ 0.02–0.06 ms; etapa 2
en CPU ≈ 0.02–0.05 ms (la copia de 16 KB cuesta tanto como el *kernel*).

## 9. Errores frecuentes

| Síntoma | Causa probable | Qué revisar |
|---|---|---|
| Suma menor que la referencia y distinta en cada corrida | Falta la barrera entre niveles (carrera en compartida) | Una `__syncthreads()` tras cada nivel; corre varias veces con `block = 256` |
| Se cuelga o da basura con `n` no múltiplo del bloque | `return` de los sobrantes antes de la barrera, o barrera dentro del `if` | Barrera fuera de todo `if`; los sobrantes cargan el neutro |
| `FALLA` sin error de CUDA, error del 33 % | `blockDim.x` no es potencia de 2 | Usa potencias de 2 (o un ciclo de paso de malla previo) |
| `atomic` `FALLA` con `n = 2^24`; los árboles `OK` | Acumulador `float` saturado | Referencia en `double`; acumula por partes |
| Histograma en compartida con total menor que `n` "a veces" | Falta la segunda barrera antes del volcado | Dos barreras: tras los ceros y tras el conteo |
| La suma global vale lo de un solo bloque | El bloque 0 "remata" leyendo parciales ajenos tras `__syncthreads()` | La barrera no cubre otros bloques (idea 25): etapa 2 fuera del *kernel* o con atómicas |
| `atomicMax` no compila con `float` | No existe para punto flotante | Árbol con `fmaxf` |

## 10. Para saber más

- NVIDIA, *CUDA C++ Programming Guide*: "Synchronization Functions", "Atomic Functions", "SIMT Architecture",
  "Independent Thread Scheduling", "Shared Memory".
- NVIDIA, *CUDA C++ Best Practices Guide*: "Branching and Divergence", "Shared Memory"; *Compute Sanitizer* (`racecheck`).
- Numba, *CUDA Python*: "Supported Atomic Operations", "Shared memory and thread synchronization", "Debugging CUDA
  Python with the simulator".
- Kirk y Hwu, *Programming Massively Parallel Processors*: capítulos de reducción paralela (divergencia y variantes
  del árbol) e histograma (privatización y contención de atómicas).
