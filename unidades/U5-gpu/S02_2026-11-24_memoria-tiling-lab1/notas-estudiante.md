> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S02 · martes 24 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# Notas · Jerarquía de memoria de la GPU, acceso coalescido y multiplicación por mosaicos

## 1. Dónde viven los datos en la GPU

| Memoria | Alcance | Vida | Latencia relativa | Tamaño típico (T4) | Cómo se usa |
|---|---|---|---|---|---|
| Registros | un hilo | el hilo | ~1 ciclo | 65 536 de 32 bits por SM; ≤ 255 por hilo | variables locales escalares |
| Compartida (*shared*) | un bloque | el bloque | decenas de ciclos | 48 KB por bloque (64 KB por SM) | `__shared__ float s[TILE][TILE];` |
| Cachés L1 / L2 | automático | — | L1 ≈ compartida; L2 ~cientos | L2: 4 MB | no se programa; se aprovecha |
| Global | toda la malla + anfitrión | la aplicación | ~400–800 ciclos | 15 GB; ~320 GB/s | `cudaMalloc`, `cudaMemcpy` |
| Constante | toda la malla, solo lectura | la aplicación | caché propia; rápida si todo el *warp* lee la misma dirección | 64 KB | `__constant__` |

Las cifras son órdenes de magnitud (Anexo A, idea 23: la global **no** es tan rápida como la compartida;
hay uno o dos órdenes de magnitud de diferencia). La compartida es, en la práctica, una caché que
programas tú: decides qué entra, cuándo y quién lo lee.

## 2. Acceso coalescido

Un *warp* son 32 hilos que ejecutan la misma instrucción. Cuando esa instrucción es una carga de memoria
global, el hardware junta las direcciones de los 32 hilos y pide los segmentos de memoria que las cubren.

- 32 hilos leen `M[fila*n + threadIdx.x]`: 32 `float` consecutivos = 128 bytes contiguos → **una**
  transacción (o pocas). Acceso **coalescido**.
- 32 hilos leen `M[threadIdx.x*n + col]`: direcciones separadas por `4n` bytes → **32** segmentos de 32
  bytes, 1024 bytes movidos para usar 128. Acceso saltado.

Regla práctica: **`threadIdx.x` debe recorrer el índice que cambia más rápido en memoria** (la columna, en
matrices por filas). Por eso en todos los *kernels* de esta sesión `col` sale de `threadIdx.x` y `row` de
`threadIdx.y`. La transposición es el caso límite: leer por filas y escribir por columnas es inevitable
*en memoria global*, salvo que el bloque pase por memoria compartida y haga ahí el cambio de índices
(fase Crear de la práctica guiada).

## 3. Multiplicación de matrices: ingenua vs. por mosaicos

**Ingenua.** Un hilo por `C[row][col]`; lee la fila `row` de A y la columna `col` de B de memoria global.
`2n` lecturas por hilo, `2n³` en total. Cada elemento de A se lee `n` veces (una por hilo de su fila).

**Por mosaicos (*tiling*).** El bloque de `TILE×TILE` hilos recorre `k` en `⌈n/TILE⌉` fases. En cada fase:

1. cada hilo trae **un** elemento de A y **uno** de B a `s_A`, `s_B` (carga cooperativa, coalescida);
2. `__syncthreads()`: el mosaico está completo;
3. cada hilo hace `TILE` productos con datos de memoria compartida;
4. `__syncthreads()`: nadie reemplaza el mosaico mientras otros lo leen.

Lecturas: `2·⌈n/TILE⌉` por hilo, `2n²·⌈n/TILE⌉` en total; cada elemento de A se lee `⌈n/TILE⌉` veces.
Cociente ingenua/mosaicos = `TILE`. Para `n = 64, TILE = 16`: 524 288 frente a 32 768.

**Bordes.** Si `n` no es múltiplo de `TILE`, la malla se redondea hacia arriba (`(n + TILE − 1) / TILE`);
los hilos fuera de rango cargan `0.0f`, pasan por las dos barreras y no escriben C. Nunca se pone un
`return` antes de una barrera: todos los hilos del bloque deben alcanzarla.

**Tamaño del mosaico.** `TILE = 16` → 256 hilos y 2 KB de compartida por bloque; `TILE = 32` → 1024 hilos
(el máximo) y 8 KB; `TILE = 64` → 4096 hilos: el lanzamiento falla con `invalid configuration argument`
(idea 26: no cualquier tamaño de bloque funciona). Un mosaico más grande reduce lecturas globales pero
también reduce cuántos bloques caben por SM; se mide (S04, lunes 30 de noviembre).

## 4. Ejemplo resumido

`n = 4, TILE = 2`, hilo `(tx=0, ty=1)` del bloque `(bx=1, by=0)` → `row = 1, col = 2`. Fase 0: carga
`A[1][0]` y `B[1][2]`; tras la barrera acumula `A[1][0]B[0][2] + A[1][1]B[1][2]`. Fase 1: carga `A[1][2]`
y `B[3][2]`; acumula `A[1][2]B[2][2] + A[1][3]B[3][2]`. Total: `C[1][2]`. Mitad de lo que usa lo trajeron
sus compañeros de bloque. El detalle y las pausas están en `ejemplo-resuelto.md`.

Verificación real sin GPU (simulador de Numba y CPU en C, `n = 64`): mismo *checksum* `54987.442763` en
los dos programas; error máximo frente a NumPy `2.70e-06` en las dos versiones. En la GPU (esperado, T4)
la de mosaicos es 2–4× más rápida que la ingenua para `n ≥ 512`, no 16×: las cachés absorben parte de las
lecturas repetidas de la ingenua.

## 5. Errores frecuentes

1. **Esperar `TILE`× de aceleración.** El cociente de lecturas es `TILE`; el de tiempos es menor por las
   cachés L1/L2 y porque el *kernel* por mosaicos pasa a estar limitado por cómputo y barreras.
2. **Quitar una barrera "porque funcionó".** Sin la primera, se lee el mosaico incompleto; sin la segunda,
   se sobreescribe mientras se usa. Las dos fallas son no deterministas y CUDA no las reporta (ideas 7, 27).
3. **`return` temprano para los hilos de borde.** Deja hilos sin llegar a `__syncthreads()`: cuelgue o
   basura. La guardia va en la escritura.
4. **Malla con división entera** (`n / TILE`). Con `n = 100` faltan 4 filas y 4 columnas; sin error de CUDA.
5. **Invertir `x` y `y`.** `row` desde `threadIdx.x` da el resultado correcto, pero las lecturas de B y las
   escrituras de C dejan de ser coalescidas.
6. **Confiar en "no dio error".** `cudaGetLastError()` atrapa configuraciones inválidas; la correctitud se
   verifica comparando con la CPU con tolerancia, nunca con `==` (FMA y orden de suma cambian el redondeo).

## 6. Para saber más

- *CUDA C++ Programming Guide*: "Memory Hierarchy", "Shared Memory" (ejemplo de multiplicación por
  mosaicos) y "Device Memory Accesses".
- Numba CUDA: "Writing CUDA Kernels" (memoria compartida y `cuda.syncthreads()`), "Debugging CUDA Python
  with the simulator".
- Kirk y Hwu, *Programming Massively Parallel Processors*, 4.ª ed., cap. 5 y 6.
