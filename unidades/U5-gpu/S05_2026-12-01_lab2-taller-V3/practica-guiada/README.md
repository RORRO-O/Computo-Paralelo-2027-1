> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S05 · martes 1 de diciembre de 2026 · 08:30–10:00 · Lab LS4

# Práctica guiada S05 · Mini PRIMM "aplanar y mapear" + plantilla del plan V3

Dos piezas, en este orden:

1. **Mini PRIMM "aplanar y mapear"** (Predecir → Ejecutar → Investigar → Modificar → Crear): una malla 2D
   guardada en un arreglo 1D, procesada por un *kernel* 2D y verificada contra la CPU. Es el patrón exacto que
   necesitas para portar la V2 de tu proyecto.
2. **`plan-V3.md`**: la plantilla que tu equipo llena en el taller (segunda mitad de la sesión). La fase
   *Crear* del PRIMM es la sección 4 de esa plantilla.

Trabajo en parejas o en equipo de proyecto. Roles conductor/navegante; cambio a los 10 minutos.

**Qué se hace en clase y qué en casa.** En la S05 (minutos 58–68): Fase 1, Fase 2 y la tabla de 3.1. Las preguntas
de 3.1, 3.2 y 3.3 se terminan en casa (no se entregan; claves en `<details>`); Modificar (`TODO(1)`) es el ejercicio 1
de `tarea-espaciada.md`; Crear es la sección 4 de `plan-V3.md`, que se empieza en el taller (minutos 68–79).

## Qué hay en esta carpeta

| Archivo | Qué es |
|---|---|
| `flatten_map_2d.cu` | Programa CUDA C: *kernel* 2D completo, *kernel* 1D con `TODO(1)`, referencia CPU interna, verificación con tolerancia, medición con y sin transferencias (protocolo del curso) |
| `flatten_map_numba.py` | Espejo en Numba CUDA del mismo programa. Corre sin GPU con `NUMBA_ENABLE_CUDASIM=1` |
| `flatten_map_cpu.c` | Referencia secuencial en C (la "V1" de este problema): T(1) con el protocolo completo |
| `Makefile` | `make` (verificación local), `make run` (requiere GPU), `make test` (sin GPU), `make notebook`, `make clean` |
| `tests/run_tests.sh` | Pruebas sin GPU: compila los `.cu`, corre la referencia CPU y el espejo en CUDASIM, compara |
| `notebook_colab.ipynb` | Notebook para Colab/Kaggle: `nvidia-smi`, `%%writefile`, `nvcc`, ejecución, barrido, CSV |
| `make_notebook.py` | Regenera el notebook con `nbformat` |
| `plan-V3.md` | Plantilla del plan de porte V2 → V3 que llena tu equipo |

## Cómo correrlo

**Sin GPU (Lab LS4 o tu laptop)**: verifica la lógica de índices con el simulador de Numba.

```bash
make            # nvcc -c del .cu (si hay nvcc) y gcc de la referencia CPU
make test       # ≈ 10 s: compila, corre CPU y CUDASIM, compara checksums
NUMBA_ENABLE_CUDASIM=1 python3 flatten_map_numba.py 10 8 3 16 16 2d 0 3 5
```

**Con GPU (Colab/Kaggle)**: abre `notebook_colab.ipynb`, selecciona GPU (T4) y ejecuta las celdas en orden.
En Kaggle con P100 cambia `-arch=sm_75` por `-arch=sm_60`.

Argumentos de ambos programas, en orden: `alto ancho iteraciones bloque_x bloque_y modo(2d|1d) copiar_cada_iter(0|1) fila_objetivo col_objetivo`.

## El problema

Un paso de Jacobi 2D: cada celda interior toma el promedio de sus cuatro vecinas; la frontera no cambia
(la fila 0 vale 100, el resto empieza en 0). Es el ciclo caliente típico de una V2 de difusión de calor,
y el mismo patrón de índices sirve para un filtro de imagen (3×3) o cualquier malla regular.

La malla de `alto` filas × `ancho` columnas **no** se guarda como `float **` sino como un solo arreglo de
`alto*ancho` floats, fila tras fila:

```
fila 0: [ 0  1  2  3  4  5  6  7 ]        ancho = 8
fila 1: [ 8  9 10 11 12 13 14 15 ]
fila 2: [16 17 18 19 20 21 22 23 ]        idx = fila * ancho + col
fila 3: [24 25 26 27 28 29 30 31 ]        fila = idx / ancho      col = idx % ancho
...
```

En el *kernel* 2D cada hilo calcula su (fila, col) a partir de sus coordenadas en la malla de bloques:

```
col  = blockIdx.x * blockDim.x + threadIdx.x     // x recorre lo contiguo (columnas)
fila = blockIdx.y * blockDim.y + threadIdx.y
bloques en x = ceil(ancho / blockDim.x)          bloques en y = ceil(alto / blockDim.y)
```

Los vecinos de `idx` son `idx - ancho` (arriba), `idx + ancho` (abajo), `idx - 1`, `idx + 1`.

## Fase 1 · Predecir (por escrito, antes de ejecutar nada)

Malla de **10 filas × 8 columnas**, 3 iteraciones, bloques de **16 × 16**, celda objetivo (fila 3, col 5).

| # | Pregunta | Tu predicción |
|---|---|---|
| P1 | ¿Qué índice lineal tiene (fila 3, col 5)? | |
| P2 | ¿Qué `blockIdx` y qué `threadIdx` (x, y) procesan esa celda? | |
| P3 | ¿Cuántos bloques lanza la malla 2D y cuántos hilos en total? ¿Cuántos hilos no tienen celda? | |
| P4 | Si el mapeo fuera 1D con bloques de 256 hilos, ¿qué `blockIdx.x` y `threadIdx.x` la procesan? | |
| P5 | Si el *kernel* está bien, ¿qué imprime la línea `verificacion vs CPU`? ¿Puede imprimir PASS y aun así estar mal el programa? | |

Anota también: ¿qué hilo escribe la celda (0, 0)? ¿Lee algún vecino?

## Fase 2 · Ejecutar

Localmente (sin GPU):

```bash
NUMBA_ENABLE_CUDASIM=1 python3 flatten_map_numba.py 10 8 3 16 16 2d 0 3 5
```

En Colab: celda "Ejecutar (PRIMM · R)" del notebook (`./flatten_map_2d 10 8 3 16 16 2d 0 3 5`).

Salida real del espejo en CUDASIM (máquina sin GPU):

```
# flatten_map_numba · alto=10 ancho=8 iteraciones=3 bloque=16x16 modo=2d copiar_cada_iter=0  [CUDASIM: tiempos no representativos]
indice lineal de (fila 3, col 5) con ancho 8: 29
malla 2D: bloques=1x1 hilos/bloque=16x16
hilos lanzados=256 celdas=80 hilos ociosos=176 (68.8 %)
hilo que la proceso: blockIdx=(0,0) threadIdx=(5,3) idx=29
verificacion vs CPU: PASS (max |diff| = 0.000e+00, tol = 1.0e-04)
checksum = 1128.125000
```

La referencia en C da el mismo índice y el mismo *checksum* (`./flatten_map_cpu 10 8 3 3 5` → `checksum = 1128.125000`).
En la GPU el programa imprime además el modelo (`GPU: Tesla T4`), los tiempos y la línea `CSV,...`.

Compara con P1–P5. Si fallaste P2, revisa: `threadIdx.x` recorre **columnas**, `threadIdx.y` recorre **filas**; el
par se imprime como (x, y) = (5, 3), no (3, 5).

<details><summary>Clave de Predecir (ábrela después de comparar con la salida)</summary>

- **P1.** `3 · 8 + 5 = 29`.
- **P2.** `blockIdx = (0,0)`, `threadIdx = (5,3)`: x = columna 5, y = fila 3.
- **P3.** `ceil(8/16) × ceil(10/16) = 1 × 1` bloque de 256 hilos; 80 celdas, **176** hilos sin celda (68.8 %).
- **P4.** `blockIdx.x = 29 / 256 = 0`, `threadIdx.x = 29 % 256 = 29`.
- **P5.** `PASS (max |diff| = 0.000e+00 ...)`. Sí puede estar mal: un PASS en una forma de malla no demuestra
  corrección en otras (por eso se prueba también un tamaño no múltiplo del bloque y uno grande), y PASS no dice nada
  del tiempo: copiar en cada iteración también da PASS (`copiar_cada_iter=1`).
- **Celda (0,0):** el hilo `threadIdx = (0,0)` del bloque `(0,0)`. Es frontera: copia `in[0]` en `out[0]` y no lee vecinos.
</details>

## Fase 3 · Investigar

### 3.1 Dimensiones que no son múltiplos del bloque

Llena la tabla **antes** de correr; luego verifica con `20 19 2 16 16 2d` (CUDASIM, ≈ 2 s) y con `37 45 3 16 16 2d`
(Colab, o CUDASIM en ≈ 3 s).

| Malla | Bloque | Bloques en x | Bloques en y | Hilos lanzados | Celdas | Hilos ociosos |
|---|---|---|---|---|---|---|
| 20 × 19 | 16 × 16 | | | | 380 | |
| 37 × 45 | 16 × 16 | | | | 1665 | |
| 1000 × 1000 | 16 × 16 | | | | 1 000 000 | |
| 1024 × 1024 | 32 × 8 | | | | 1 048 576 | |

Salida real (CUDASIM) para 20 × 19: `malla 2D: bloques=2x2 hilos/bloque=16x16`, `hilos lanzados=1024 celdas=380 hilos ociosos=644 (62.9 %)`,
`verificacion vs CPU: PASS`, `checksum = 2631.250000`. Para 37 × 45: `bloques=3x3`, `hilos lanzados=2304 celdas=1665 hilos ociosos=639 (27.7 %)`,
`checksum = 7025.000000`.

Preguntas:

1. ¿Qué línea del *kernel* evita que los 639 hilos sobrantes escriban? ¿Qué índice intentaría escribir el hilo
   (`threadIdx.x`=15, `threadIdx.y`=15) del bloque (2, 2) si esa línea no existiera? ¿Está dentro del arreglo de 1665 floats?
2. Solo en Colab: compila con `-DSIN_GUARDIA` (celda "Experimento incorrecto a propósito") y corre `37 45 3 16 16 2d`.
   Anota qué pasó: ¿falló la verificación?, ¿hubo `illegal memory access`?, ¿"salió bien"? Explica por qué
   **las tres** son posibles y por qué ninguna es aceptable (es comportamiento indefinido).
3. ¿Por qué el programa lee siempre de `in` y escribe siempre en `out`, y luego intercambia punteros? ¿Qué pasaría
   si un solo arreglo hiciera de entrada y salida? Conéctalo con las condiciones de carrera de la Unidad III.
4. La malla de 1024 × 1024 lanza 1 048 576 hilos y una T4 tiene 2560 núcleos CUDA en 40 SMs. ¿Es un error lanzar
   400 veces más hilos que núcleos? ¿Cuántos *warps* son? (Idea errónea 22: "un hilo de CUDA es un núcleo".)

<details><summary>Clave de 3.1 (ábrela después de llenar la tabla)</summary>

| Malla | Bloque | Bloques en x | Bloques en y | Hilos lanzados | Celdas | Hilos ociosos |
|---|---|---|---|---|---|---|
| 20 × 19 | 16 × 16 | 2 | 2 | 1 024 | 380 | 644 |
| 37 × 45 | 16 × 16 | 3 | 3 | 2 304 | 1665 | 639 |
| 1000 × 1000 | 16 × 16 | 63 | 63 | 1 016 064 | 1 000 000 | 16 064 |
| 1024 × 1024 | 32 × 8 | 32 | 128 | 1 048 576 | 1 048 576 | 0 |

1. `if (r >= height || c >= width) return;`. El hilo (15, 15) del bloque (2, 2): `c = r = 47`, `idx = 47 · 45 + 47 = 2162`,
   fuera de los 1665 floats. Ojo: un hilo sobrante con `c ≥ ancho` pero `r < alto` escribe **dentro** del arreglo, en
   la fila siguiente (`idx = r · ancho + c`); por eso el error puede no producir ningún acceso ilegal.
2. Es comportamiento indefinido. Los hilos con `c ≥ ancho` compiten con los legítimos por celdas de la fila siguiente:
   según cuál escriba al último sale FAIL sin ningún error de CUDA o "sale bien" (una simulación secuencial de 37 × 45
   da `max |diff| = 43.75` recorriendo los hilos en un orden y `0` en el orden inverso). Si una escritura con `r ≥ alto`
   cae fuera de la memoria reservada, aparece `illegal memory access`. Ninguna de las tres demuestra corrección.
3. Si un solo arreglo fuera entrada y salida, un hilo podría leer un vecino que otro hilo ya actualizó en el mismo paso:
   carrera de datos y resultado que depende del orden de ejecución. Con dos búferes no hay escrituras sobre lo que se lee.
4. No es un error: son 32 768 *warps* de 32 hilos ligeros. Cada SM alterna entre sus *warps* residentes para ocultar la
   latencia de memoria; hace falta **más** hilos que núcleos, no uno por núcleo.
</details>

### 3.2 Tabla de rastreo del bloque (0, 0) con ancho 8

| `threadIdx.x` | `threadIdx.y` | col | fila | idx | ¿interior o frontera? |
|---|---|---|---|---|---|
| 0 | 0 | | | | |
| 7 | 0 | | | | |
| 1 | 1 | | | | |
| 5 | 3 | | | | |
| 9 | 2 | | | | ¿existe esa columna en una malla de ancho 8? |

<details><summary>Clave de 3.2</summary>

| `threadIdx.x` | `threadIdx.y` | col | fila | idx | ¿interior o frontera? |
|---|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 0 | frontera (fila 0 y col 0) |
| 7 | 0 | 7 | 0 | 7 | frontera (fila 0 y col 7 = ancho − 1) |
| 1 | 1 | 1 | 1 | 9 | interior |
| 5 | 3 | 5 | 3 | 29 | interior |
| 9 | 2 | 9 | 2 | — | no existe: col 9 ≥ ancho 8, la guardia lo descarta. Sin guardia calcularía `idx = 2 · 8 + 9 = 25`, que es la celda (3, 1): escribiría en una celda ajena **dentro** del arreglo |
</details>

### 3.3 Medición (Colab, celda "Medir")

El programa hace 1 calentamiento + 5 repeticiones y reporta la mediana de dos tiempos: solo *kernels*
(`cudaEventRecord` antes y después del ciclo de iteraciones) y total (H2D + *kernels* + D2H).

1. En `run_once`, ¿por qué hay un `cudaEventSynchronize(e_k1)` antes de `cudaEventElapsedTime`? ¿Qué pasaría
   sin él? (Pista de la S04: ¿quién estampa la marca de `e_k1`, la CPU o la GPU, y cuándo?) ¿Y si en lugar de
   eventos usaras un reloj de CPU sin `cudaDeviceSynchronize()`?
2. ¿Por qué el `speedup con transferencias` es siempre menor que el `speedup sin transferencias`? ¿Cuál de los
   dos va en tu reporte de la V3? (Respuesta corta: los dos, con la tabla del protocolo.)
3. La fila `copiar_cada_iter=1` sube y baja la malla **en cada iteración**. Predice antes de ver el número: ¿el
   tiempo total crece ×2, ×10 o ×100 respecto a subir una vez? Luego compara con la tabla.
4. El barrido de bloque (32×1, 8×8, 16×16, 32×8, 32×32, 64×16): ¿cuál es más lento y por qué? Pista de la S02:
   ¿cuántos floats contiguos lee un *warp* en cada configuración?

<details><summary>Clave de 3.3 (respuestas de razonamiento; los números son los de tu corrida)</summary>

1. La GPU estampa `e_k1` cuando termina el último *kernel*; la CPU llega antes a `cudaEventElapsedTime` porque los
   lanzamientos son asíncronos. Sin `cudaEventSynchronize`, la llamada regresa `cudaErrorNotReady` (aquí `CUDA_CHECK`
   aborta). Con un reloj de CPU sin `cudaDeviceSynchronize()` se mediría el **encolado** de 100 lanzamientos.
2. Porque `t_total = t_H2D + t_kernel + t_D2H ≥ t_kernel`. En el reporte van **los dos**.
3. Se espera entre ×10 y ×100 respecto a `t_total` con una sola subida: 100 subidas y 100 bajadas de 4 MB (800 MB a
   3–6 GB/s ≈ 0.13–0.27 s) contra ≈ 5–15 ms.
4. Lo esperado: los más lentos son `8×8` (un *warp* cubre 4 filas × 8 columnas: segmentos de 32 B) y `32×1` (bloques
   de un solo *warp*: el límite de bloques residentes por SM deja la ocupación en 50 %, S04). `16×16`, `32×8` y `32×32`
   quedan cerca entre sí. Si tu tabla dice otra cosa, gana tu tabla: explícala.
</details>

Órdenes de magnitud **esperados** en una T4 para 1024 × 1024 × 100 iteraciones (no ejecutados aquí; dependen de la
GPU asignada): solo *kernels* ≈ 3–10 ms; con transferencias ≈ 5–15 ms; copiando en cada iteración ≈ 150–400 ms.
La referencia CPU tardó 0.088 s (real: mediana de 5; mín 0.084, máx 0.099) en la máquina de revisión (4 núcleos,
gcc 13, `-O2`); en la CPU de Colab (2 vCPU, otro compilador) se espera entre 0.1 y 0.4 s: mídela ahí, no la copies.

## Fase 4 · Modificar: mapeo 1D

Objetivo: que `modo=1d` pase la verificación. Completa `TODO(1)` en `jacobi_step_1d` (en el `.cu` **y** en el
espejo Numba): recupera `r` y `c` a partir de `idx`.

Criterio verificable:

```bash
make test        # la línea "CUDASIM 1d" debe pasar de SKIP a PASS
NUMBA_ENABLE_CUDASIM=1 python3 flatten_map_numba.py 10 8 3 16 16 1d 0 3 5
# esperado: hilo que la proceso: blockIdx=(0,0) threadIdx=(29,0) idx=29 · verificacion vs CPU: PASS · checksum = 1128.125000
```

Después, en Colab, compara para 1024 × 1024 × 100: `2d 16 16`, `1d 16 16` (= 256 hilos lineales) y `2d 32 8`.
Explica la diferencia (si la hay) con la coalescencia de la S02: un *warp* de 32 hilos en 1D lee 32 floats
contiguos (128 bytes, una transacción); en un bloque 16 × 16 el mismo *warp* cubre 2 filas × 16 columnas (dos
segmentos de 64 bytes). En este problema la diferencia suele ser pequeña; lo importante es que **sepas por qué**.

<details><summary>Solución de TODO(1) (ábrela solo después de intentarlo)</summary>

```c
int r = idx / width;   // división entera: cuántas filas completas caben antes de idx
int c = idx % width;   // lo que sobra es la columna
```

En Numba: `r = idx // width` y `c = idx % width`. Verificado en CUDASIM: `threadIdx=(29,0) idx=29`, `PASS`, `checksum = 1128.125000`.
</details>

## Fase 5 · Crear: el esqueleto del *kernel* de tu proyecto

Abre `plan-V3.md` y llena la sección 4 con el esqueleto del *kernel* candidato de **tu** V2 (CUDA C, Numba o CuPy
`RawKernel`, el que haya elegido tu equipo). Criterio de "listo":

- [ ] Firma del *kernel* con todos los arreglos aplanados como punteros 1D (ninguna `float **`).
- [ ] Cálculo de índices (1D o 2D) escrito y la fórmula del índice lineal de cada estructura.
- [ ] Guardia de rango para dimensiones no múltiplos del bloque.
- [ ] Ninguna escritura a una posición que otro hilo también escriba (si la hay: atómica o rediseño, y dilo).
- [ ] Compila con `nvcc -c -arch=sm_75` (CUDA C) o corre bajo `NUMBA_ENABLE_CUDASIM=1` con una malla de juguete.
- [ ] Sabes qué arreglos suben una vez, cuáles bajan una vez y qué se queda en la GPU entre iteraciones.

Quien termine antes: escribe también la llamada (`<<<grid, block>>>` o `kernel[grid, block]`) con las fórmulas de
`ceil` y la comparación contra la V1 con tolerancia (sección 5 de `plan-V3.md`).

## Errores frecuentes en esta actividad

| Síntoma | Primera pregunta que debes hacerte |
|---|---|
| `threadIdx=(3,5)` en vez de `(5,3)` | ¿Qué dimensión recorre columnas: x o y? |
| Verificación FAIL con dimensiones no múltiplos | ¿Dónde está la guardia `if (r >= height \|\| c >= width) return;`? |
| PASS en 10 × 8 pero FAIL en 37 × 45 | ¿Calculaste los bloques con `ceil` o con división entera? |
| Tiempo "solo kernels" de microsegundos sospechosamente bajo | ¿Sincronizaste antes de leer el evento o el reloj? |
| `speedup` de 100× en el reporte | ¿Incluiste las transferencias? ¿Es mediana de 5 con calentamiento? |
| Resultados distintos entre corridas | ¿Lees y escribes el mismo arreglo en el mismo paso? |

## Política de IA en esta actividad

Verde: pedir que te explique la aritmética de índices con otro ejemplo, o que te haga preguntas sobre tu
esqueleto de *kernel*. Amarillo: pedir una revisión de tu esqueleto señalando posibles escrituras compartidas
(tú verificas con el ejecutable). Rojo: pedirle el *kernel* de tu proyecto completo; no podrás explicarlo en la
mini-defensa ni en la defensa del jueves 10 de diciembre.
