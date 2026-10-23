> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S02 · martes 24 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# Ejemplo resuelto · ¿Cuántas veces va a memoria global cada versión de la multiplicación de matrices?

## Problema

`C = A·B`, matrices `n×n` de `float` guardadas por filas. Se tienen dos *kernels*: el ingenuo (un hilo por
elemento de C) y el de mosaicos (`TILE×TILE` en memoria compartida). Para `n = 64` y `TILE = 16`:

1. ¿Cuántas lecturas a memoria global hace cada versión y cuántas veces se lee cada elemento de A?
2. ¿Qué calcula exactamente un hilo del *kernel* por mosaicos? (rastreo con `n = 4`, `TILE = 2`)
3. ¿Cómo se verifica que el resultado es correcto sin confiar en que "no dio error"?

## Plan (3 líneas)

1. Contar lecturas por hilo y multiplicar por el número de hilos; en la de mosaicos, contar por fase.
2. Fijar un hilo (bloque, índices) y seguir el ciclo de fases con una tabla.
3. Comparar contra la CPU con tolerancia; usar el simulador de Numba para correr la misma lógica sin GPU.

## Código: el *kernel* por mosaicos (de `practica-guiada/matmul_tiled.cu`)

```c
__global__ void matmul_tiled(const float *A, const float *B, float *C, int n) {
    __shared__ float s_A[TILE][TILE];       // mosaico de A, visible para todo el bloque
    __shared__ float s_B[TILE][TILE];       // mosaico de B
    int tx = threadIdx.x, ty = threadIdx.y;
    int row = blockIdx.y * TILE + ty;       // fila de C de este hilo
    int col = blockIdx.x * TILE + tx;       // columna de C de este hilo
    float acc = 0.0f;
    int n_tiles = (n + TILE - 1) / TILE;    // fases = ceil(n / TILE)
    for (int t = 0; t < n_tiles; ++t) {
        int a_col = t * TILE + tx;          // qué columna de A trae este hilo
        int b_row = t * TILE + ty;          // qué fila de B trae este hilo
        s_A[ty][tx] = (row < n && a_col < n) ? A[row * n + a_col] : 0.0f;   // (1) carga cooperativa
        s_B[ty][tx] = (b_row < n && col < n) ? B[b_row * n + col] : 0.0f;
        __syncthreads();                    // (2) el mosaico está completo
        for (int k = 0; k < TILE; ++k)      // (3) TILE productos con datos de compartida
            acc += s_A[ty][k] * s_B[k][tx];
        __syncthreads();                    // (4) nadie pisa el mosaico antes de tiempo
    }
    if (row < n && col < n) C[row * n + col] = acc;   // guardia de escritura
}
```

El ingenuo es el ciclo `for k` directo sobre `A[row*n + k] * B[k*n + col]`, sin mosaicos ni barreras.

## Paso 1 · Contar lecturas

**Ingenuo.** El hilo de `C[row][col]` recorre `k = 0 … n−1` y en cada vuelta lee `A[row][k]` y `B[k][col]`:
`2n` lecturas. Hay `n²` hilos: `2n³`. Con `n = 64`: `2·262 144 = 524 288`. ¿Cuántas veces se lee `A[i][k]`?
Lo leen todos los hilos de la fila `i`: `n = 64` veces.

**Mosaicos.** Cada hilo hace `⌈n/TILE⌉ = 4` fases y en cada una lee un elemento de A y uno de B: 8
lecturas por hilo, `n² = 4096` hilos: `32 768`. ¿Cuántas veces se lee `A[i][k]`? Una vez por cada bloque
que lo necesite: los bloques de la fila de bloques `i / TILE`, que son `⌈n/TILE⌉ = 4`. Cociente:
`524 288 / 32 768 = 16 = TILE`.

> **Pausa 1. ¿Por qué el cociente es exactamente `TILE` y no depende de `n`?**
> <details><summary>Respuesta</summary>
> Cada elemento que llega a memoria compartida lo usan `TILE` hilos (los de su fila del mosaico para A, los
> de su columna para B). Una carga, `TILE` usos. En el ingenuo cada carga tiene un solo uso. La reutilización
> por carga es `TILE`, independiente de `n`; `n` solo cambia cuántas fases hay.
> </details>

## Paso 2 · Rastreo con `n = 4`, `TILE = 2`

Hilo `(tx=0, ty=1)` del bloque `(bx=1, by=0)`: `row = 0·2 + 1 = 1`, `col = 1·2 + 0 = 2`. Dos fases.

| Fase | `a_col`, `b_row` | Carga este hilo | Mosaico completo tras (2) | `acc +=` |
|---|---|---|---|---|
| `t=0` | 0, 1 | `s_A[1][0]=A[1][0]`, `s_B[1][0]=B[1][2]` | `s_A = A[0..1][0..1]`, `s_B = B[0..1][2..3]` | `A[1][0]B[0][2] + A[1][1]B[1][2]` |
| `t=1` | 2, 3 | `s_A[1][0]=A[1][2]`, `s_B[1][0]=B[3][2]` | `s_A = A[0..1][2..3]`, `s_B = B[2..3][2..3]` | `A[1][2]B[2][2] + A[1][3]B[3][2]` |

Suma: `Σ_k A[1][k]·B[k][2] = C[1][2]`. El hilo cargó 4 elementos y usó 8 (4 suyos y 4 que trajeron otros).

> **Pausa 2. En la fase `t=0` este hilo carga `B[1][2]`, pero en su producto usa `B[0][2]` y `B[1][2]`.
> ¿Quién trajo `B[0][2]`?**
> <details><summary>Respuesta</summary>
> El hilo `(tx=0, ty=0)` del mismo bloque: `b_row = 0·2 + 0 = 0`, `col = 2`. Por eso hace falta la barrera
> (2): sin ella, este hilo podría leer `s_B[0][0]` antes de que su compañero la escriba. La carga es
> cooperativa: cada hilo trae una pieza y todos usan el conjunto.
> </details>

> **Pausa 3. ¿Para qué sirve la segunda barrera (4) si ya nadie va a leer este mosaico?**
> <details><summary>Respuesta</summary>
> Sí lo van a leer: los hilos lentos que aún están en el ciclo `k`. Sin (4), un hilo rápido pasa a la fase
> `t+1` y sobreescribe `s_B[ty][tx]` (y `s_A[ty][tx]`) mientras un hilo de **otro *warp***, que todavía está
> multiplicando, lee `s_B[k][tx]` de la fase `t` (la columna `tx` de `s_B` la leen hilos de todas las filas
> del bloque). Es la carrera simétrica a la de (2): una protege "leer antes de escribir", la otra "escribir
> antes de terminar de leer".
> </details>

> **Pausa 4. ¿Por qué la guardia `row < n && col < n` está solo en la escritura y no al inicio del
> *kernel* con un `return`?**
> <details><summary>Respuesta</summary>
> Porque `__syncthreads()` la deben alcanzar **todos** los hilos del bloque. Un hilo que regresó antes nunca
> llega a la barrera; el comportamiento queda indefinido (en la práctica, cuelgue o resultados corruptos).
> Los hilos fuera de rango sí participan: cargan `0.0f`, pasan por las barreras y al final no escriben.
> El `0.0f` tampoco es casual: si no cargaran nada, el mosaico tendría el valor de la fase anterior y los
> productos sumarían basura.
> </details>

## Paso 3 · Salidas reales (sin GPU) y esperadas (GPU)

Referencia en CPU (`./matmul_cpu 64 16`, salida real de este entorno):

```
matmul_cpu  n=64  tiempo 0.0002 s  checksum 54987.442763
  modelo de lecturas a memoria global con TILE=16 (fases=4):
    ingenua : 524288   (cada elemento de A se lee 64 veces)
    mosaicos: 32768   (cada elemento de A se lee 4 veces)
    cociente ingenua/mosaicos: 16.00
```

Espejo en Numba con simulador (`NUMBA_ENABLE_CUDASIM=1 python3 matmul_numba.py --n 64 --tile 16`,
salida real):

```
ingenua   n=64 tile=16 malla=4x4 bloque=16x16  lecturas_globales(modelo)=524288  (cada elemento de A: 64 veces)
          error maximo vs NumPy 2.70e-06  -> PASS
mosaicos  n=64 tile=16 malla=4x4 bloque=16x16  lecturas_globales(modelo)=32768  (cada elemento de A: 4 veces)
          error maximo vs NumPy 2.70e-06  -> PASS
checksum C = 54987.442763   (compara con ./matmul_cpu 64 16)
```

Mismo *checksum* que la CPU; las dos versiones tienen exactamente el mismo error frente a NumPy porque
suman en el mismo orden. Con `n = 4, TILE = 2` el *checksum* es `13.832168` en los dos programas.

Salida **esperada** en la GPU (no ejecutada aquí; T4 de Colab, `./matmul_tiled 512`): `malla=32x32
fases=32 compartida=2048 bytes por bloque`, lecturas `16777216`, *kernel* ~0.3–0.5 ms frente a ~1 ms del
ingenuo, `verificacion vs CPU (262144 elementos): error maximo ~1e-04 -> OK`. Los tiempos dependen de la
GPU asignada; el cociente típico entre versiones es 2–4×, no 16×, porque las cachés L1/L2 absorben parte
de las lecturas repetidas del ingenuo.

## Variante que falla: sin la primera barrera

`matmul_tiled.cu` compilado con `-DSIN_SYNC1` (o `--sin-sync1` en el espejo). Compila. No produce ningún
error de CUDA. Salida real del simulador, `--n 32 --tile 16 --solo mosaicos`:

```
mosaicos  n=32 tile=16 malla=2x2 bloque=16x16  lecturas_globales(modelo)=4096  (cada elemento de A: 2 veces)
          error maximo vs NumPy 4.44e+00  -> FAIL
```

En otras corridas idénticas el error fue `inf` o `4e+33`: cada corrida lee basura distinta. Lo único que lo
detectó fue la comparación con la referencia.
Lo mismo ocurre con `--grid-truncado` (malla `n/TILE` con división entera): con `n = 20` la malla es `1×1`,
solo se calculan 256 de 400 elementos, no hay error de CUDA y la verificación reporta `error maximo
5.34e+00 -> FAIL`.

> **Pausa 5. Un compañero corre la versión sin barrera, obtiene OK y dice "entonces la barrera sobra".
> ¿Qué le contestas?**
> <details><summary>Respuesta</summary>
> Que una carrera es no determinista: salir bien una vez no es evidencia (Anexo A, ideas 7 y 27). Que lo
> corra diez veces con `n = 512` en la GPU y mire si el error máximo cambia. Y que el programa no puede
> avisarle: CUDA no detecta carreras en memoria compartida; solo la comparación con la CPU lo hace.
> </details>

## Qué te llevas

- Lecturas globales: ingenuo `2n³`; mosaicos `2n²·⌈n/TILE⌉`; cociente `TILE`.
- Dos barreras por fase: una antes de usar el mosaico, otra antes de reemplazarlo.
- La guardia va en la escritura; los hilos sobrantes cargan ceros y pasan por las barreras.
- Verificar es comparar con la CPU con tolerancia. `cudaGetLastError()` atrapa configuraciones inválidas,
  no carreras ni mallas cortas.
