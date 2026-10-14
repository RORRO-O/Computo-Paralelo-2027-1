> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S02 · martes 24 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# Práctica guiada S02 · Multiplicación de matrices: ingenua vs. por mosaicos (PRIMM)

Actividad PRIMM corta (20 minutos en clase: Predecir, Ejecutar, Investigar; Modificar y Crear se terminan
en casa y en el Laboratorio 2 del martes 1 de diciembre). Se trabaja en parejas: conductor (teclea) y
navegante (lee el código y anota); se intercambian a los 10 minutos.

## Qué hay en esta carpeta

| Archivo | Qué es |
|---|---|
| `matmul_naive.cu` | Un hilo por elemento de C; lee A y B directamente de memoria global |
| `matmul_tiled.cu` | Mosaicos de `TILE×TILE` en `__shared__` con dos `__syncthreads()`; maneja n no múltiplo de `TILE` |
| `common.cuh` | `CUDA_CHECK`, inicialización determinista, referencia CPU, verificación con tolerancia, mediana |
| `matmul_cpu.c` | Referencia secuencial en C + calculadora del modelo de lecturas a memoria global |
| `matmul_numba.py` | Espejo en Numba CUDA de los dos kernels; corre sin GPU con `NUMBA_ENABLE_CUDASIM=1` |
| `transpose.cu`, `transpose_numba.py` | Fase Crear: transposición ingenua completa + `transpose_shared` con `TODO(1)` |
| `Makefile` | `all` (compila sin GPU), `run` (requiere GPU), `test` (sin GPU), `notebook`, `clean` |
| `notebook_colab.ipynb` | Todo lo anterior listo para Colab/Kaggle: escribe, compila, ejecuta, mide y guarda CSV |
| `tests/run_tests.sh` | 20 comprobaciones sin GPU (≈ 30 s) |

## Cómo se ejecuta

**Con GPU (Colab o Kaggle, cuenta de la Práctica 1).** Sube `notebook_colab.ipynb`, activa la GPU
(*Entorno de ejecución → Cambiar tipo de entorno → GPU*) y ejecuta las celdas en orden. La primera
(`!nvidia-smi`) debe mostrar una GPU; si no, nada de lo demás corre.

**Sin GPU (tu laptop o la máquina del LS4).** Se verifica la lógica, no el tiempo:

```bash
make              # nvcc -c de los .cu (solo compila) + matmul_cpu
make test         # 20 comprobaciones: compilación, CPU, simulador de Numba, notebook
./matmul_cpu 64 16
NUMBA_ENABLE_CUDASIM=1 python3 matmul_numba.py --n 64 --tile 16     # ≈ 10 s
```

El simulador ejecuta cada hilo de CUDA en Python: `n = 64` tarda unos 10 s y `--tile 8` unos 40 s.
Úsalo con `n ≤ 64`. Los tiempos que imprime no significan nada; los tiempos se miden en la GPU.

## Antes de empezar: el modelo de lecturas

Las dos versiones hacen las mismas `2·n³` operaciones de punto flotante. Lo que cambia es cuántas veces
van a memoria global por los datos:

- **Ingenua.** El hilo de `C[row][col]` lee `A[row][0..n-1]` y `B[0..n-1][col]`: `2n` lecturas por hilo,
  `n²` hilos → `2n³` lecturas. Cada elemento de A lo leen los `n` hilos de su fila: **n veces**.
- **Mosaicos.** El bloque de `TILE×TILE` hilos recorre `k` en `⌈n/TILE⌉` fases; en cada fase cada hilo
  trae **un** elemento de A y **uno** de B a memoria compartida y luego hace `TILE` productos con datos
  del bloque. `2·⌈n/TILE⌉` lecturas por hilo → `2·n²·⌈n/TILE⌉`. Cada elemento de A lo lee un bloque por
  cada bloque-columna: **⌈n/TILE⌉ veces**.

Se cuentan instrucciones de carga desde memoria global. Las cachés L1/L2 absorben parte de las lecturas
repetidas de la ingenua; por eso la ganancia de tiempo en la GPU es menor que el cociente de lecturas.

## 1. Predecir (5 min, por escrito, antes de correr nada)

Lee `matmul_tiled.cu` (solo el *kernel*, 30 líneas) y contesta en tu cuaderno:

**P1.** Con `n = 64` y `TILE = 16`: lecturas a memoria global de la ingenua = ______ ; de la de mosaicos =
______ ; cociente = ______ . Cada elemento de A se lee ______ veces en la ingenua y ______ en la de mosaicos.

**P2.** Si se quita la primera `__syncthreads()` (la marcada con `(2)`), ¿qué pasa? Marca una y justifica
en una línea: (a) no compila · (b) CUDA reporta un error en tiempo de ejecución · (c) corre sin error y el
resultado puede estar mal · (d) corre y el resultado es correcto porque la segunda barrera basta.

**P3.** ¿El resultado de la versión por mosaicos será idéntico al de la ingenua, o solo igual dentro de la
tolerancia? ¿Y comparado con la CPU? Pista: ¿en qué orden suma cada versión los `n` productos de `C[i][j]`?

**P4.** Con `n = 100` y `TILE = 16`: ¿cuántos bloques por dimensión lanza la malla? ¿Cuántas fases recorre
cada bloque? En el último bloque de cada fila de bloques, ¿cuántas columnas de hilos no escriben nada en C?

<details><summary>Respuestas (ábrelas después de ejecutar)</summary>

- **P1.** Ingenua: `2·64³ = 524 288`. Mosaicos: `2·64²·4 = 32 768`. Cociente 16 (= `TILE`). Cada elemento
  de A: 64 veces vs. 4 veces.
- **P2.** (c). Compila igual; CUDA no vigila carreras sobre memoria compartida. Un hilo rápido multiplica
  `s_A`/`s_B` antes de que los demás terminen de llenarlas: lee basura de la fase anterior (o memoria sin
  inicializar en la primera). El resultado cambia de una corrida a otra. La segunda barrera no lo evita.
- **P3.** Las dos versiones suman los productos en el mismo orden (`k = 0, 1, …, n−1`; los mosaicos solo lo
  parten en tramos de `TILE`), así que se espera el mismo resultado. Frente a la CPU hay diferencias de
  redondeo (la GPU usa FMA, la CPU no): por eso se compara con tolerancia, nunca con `==`.
- **P4.** `⌈100/16⌉ = 7` bloques por dimensión (49 bloques, 12 544 hilos para 10 000 elementos). 7 fases.
  En el último bloque-columna, `112 − 100 = 12` columnas de hilos cargan ceros y no escriben C.
</details>

## 2. Ejecutar (5 min)

En Colab, corre las celdas de los pasos 2 y 3 del notebook. Sin GPU:

```bash
./matmul_cpu 64 16
NUMBA_ENABLE_CUDASIM=1 python3 matmul_numba.py --n 64 --tile 16
```

Salida real de la referencia en CPU (este entorno, sin GPU):

```
matmul_cpu  n=64  tiempo 0.0002 s  checksum 54987.442763
  modelo de lecturas a memoria global con TILE=16 (fases=4):
    ingenua : 524288   (cada elemento de A se lee 64 veces)
    mosaicos: 32768   (cada elemento de A se lee 4 veces)
    cociente ingenua/mosaicos: 16.00
  C[0][0]=13.314686  C[n-1][n-1]=12.727274
csv,cpu,64,16,0.1572,54987.442763
```

Salida real del espejo en Numba con el simulador:

```
[CUDASIM] simulador de CUDA activo: se verifica la logica; los tiempos NO son representativos
ingenua   n=64 tile=16 malla=4x4 bloque=16x16  lecturas_globales(modelo)=524288  (cada elemento de A: 64 veces)
          error maximo vs NumPy 2.70e-06  mediana 4860.443 ms de 1 -> PASS
mosaicos  n=64 tile=16 malla=4x4 bloque=16x16  lecturas_globales(modelo)=32768  (cada elemento de A: 4 veces)
          error maximo vs NumPy 2.70e-06  mediana 6224.246 ms de 1 -> PASS
checksum C = 54987.442763   (compara con ./matmul_cpu 64 16)
csv,numba,64,16,sim,54987.442763,PASS
```

El *checksum* coincide con la CPU y las dos versiones tienen el mismo error frente a NumPy (P3).

Salida **esperada** en la GPU (no ejecutada aquí; órdenes de magnitud para una T4 de Colab, cambian con la
GPU asignada):

```
matmul_naive  n=512  bloque=16x16  malla=32x32  (256 hilos por bloque)
  lecturas a memoria global (modelo): 268435456   (cada elemento de A se lee 512 veces)
  kernel: mediana ~1 ms de 5 repeticiones -> ~250–500 GFLOP/s
  copias: H2D ~0.3–0.6 ms, D2H ~0.2–0.4 ms
  verificacion vs CPU (262144 elementos): error maximo ~1e-04 -> OK
matmul_tiled  n=512  TILE=16  malla=32x32  fases=32  compartida=2048 bytes por bloque
  lecturas a memoria global (modelo): 16777216   (cada elemento de A se lee 32 veces)
  kernel: mediana ~0.3–0.5 ms de 5 repeticiones -> ~600–1000 GFLOP/s
  verificacion vs CPU (262144 elementos): error maximo ~1e-04 -> OK
```

Anota en la tabla: predicción (P1) · modelo que imprime el programa · tiempo del *kernel* en tu GPU ·
cociente de tiempos naive/tiled. El cociente de tiempos será **2–4×**, no 16×. La pregunta de por qué es
la primera de Investigar.

## 3. Investigar (10 min)

**I1. Tabla de rastreo.** `n = 4`, `TILE = 2`. Sigue al hilo `(tx=0, ty=1)` del bloque `(bx=1, by=0)` en
`matmul_tiled`: `row = 0·2+1 = 1`, `col = 1·2+0 = 2`.

| Fase `t` | `a_col`, `b_row` | Este hilo carga | Tras la barrera, `s_A` y `s_B` contienen | `acc +=` |
|---|---|---|---|---|
| 0 | 0, 1 | `s_A[1][0] = A[1][0]`, `s_B[1][0] = B[1][2]` | `A[0..1][0..1]`, `B[0..1][2..3]` | `A[1][0]·B[0][2] + A[1][1]·B[1][2]` |
| 1 | 2, 3 | `s_A[1][0] = A[1][2]`, `s_B[1][0] = B[3][2]` | `A[0..1][2..3]`, `B[2..3][2..3]` | `A[1][2]·B[2][2] + A[1][3]·B[3][2]` |

Resultado: los cuatro términos de `C[1][2]`. Ahora llena tú la misma tabla para el hilo `(tx=1, ty=0)` del
bloque `(bx=0, by=1)` y di qué elemento de C calcula. Comprueba con
`NUMBA_ENABLE_CUDASIM=1 python3 matmul_numba.py --n 4 --tile 2` (checksum `13.832168`, igual que
`./matmul_cpu 4 2`).

<details><summary>Respuesta de I1 (ábrela después de llenar tu tabla)</summary>

Hilo `(tx=1, ty=0)` del bloque `(bx=0, by=1)`: `row = 1·2 + 0 = 2`, `col = 0·2 + 1 = 1` → calcula `C[2][1]`.

| Fase `t` | `a_col`, `b_row` | Este hilo carga | Tras la barrera, `s_A` y `s_B` contienen | `acc +=` |
|---|---|---|---|---|
| 0 | 1, 0 | `s_A[0][1] = A[2][1]`, `s_B[0][1] = B[0][1]` | `A[2..3][0..1]`, `B[0..1][0..1]` | `A[2][0]·B[0][1] + A[2][1]·B[1][1]` |
| 1 | 3, 2 | `s_A[0][1] = A[2][3]`, `s_B[0][1] = B[2][1]` | `A[2..3][2..3]`, `B[2..3][0..1]` | `A[2][2]·B[2][1] + A[2][3]·B[3][1]` |

Fíjate: `A[2][0]` y `B[1][1]` los trajeron sus compañeros `(tx=0, ty=0)` y `(tx=1, ty=1)`.
</details>

**I2. Preguntas sobre líneas concretas** (una respuesta por pareja, en el cuaderno):

1. ¿Por qué `col` usa `threadIdx.x` y `row` usa `threadIdx.y`, y no al revés? ¿Qué accesos dejarían de
   ser coalescidos si se invierten? (El resultado seguiría siendo correcto.)
2. En la carga, ¿por qué se escribe `0.0f` fuera de rango en vez de simplemente no cargar?
3. ¿Por qué la guardia `if (row < n && col < n)` está en la **escritura** y no envuelve todo el ciclo
   (`if (row >= n || col >= n) return;` al inicio)? Pista: ¿quién tiene que llegar a cada `__syncthreads()`?
4. ¿Por qué la ingenua no es 16× más lenta si hace 16× más lecturas? Mira cómo leen los 32 hilos de un
   *warp* (dos filas de 16) `B[k*n + col]` y `A[row*n + k]`, y piensa en la caché L2.

**I3. Dos programas sin error de CUDA que están mal.** Corre (sin GPU, 3 s cada uno):

```bash
NUMBA_ENABLE_CUDASIM=1 python3 matmul_numba.py --n 20 --tile 16 --grid-truncado
NUMBA_ENABLE_CUDASIM=1 python3 matmul_numba.py --n 32 --tile 16 --sin-sync1 --solo mosaicos
```

Salidas reales de este entorno:

```
[grid-truncado] malla 1x1 con division entera (deberia ser 2x2)
ingenua   n=20 tile=16 malla=1x1 bloque=16x16  lecturas_globales(modelo)=16000  (cada elemento de A: 20 veces)
          error maximo vs NumPy 5.34e+00  mediana 694.040 ms de 1 -> FAIL
mosaicos  n=20 tile=16 malla=1x1 bloque=16x16  lecturas_globales(modelo)=1600  (cada elemento de A: 2 veces)
          error maximo vs NumPy 5.34e+00  mediana 237.102 ms de 1 -> FAIL
```

```
[sin-sync1] se quito la primera cuda.syncthreads() del kernel por mosaicos
mosaicos  n=32 tile=16 malla=2x2 bloque=16x16  lecturas_globales(modelo)=4096  (cada elemento de A: 2 veces)
          error maximo vs NumPy 4.44e+00  mediana 1157.548 ms de 1 -> FAIL
```

En otras corridas del mismo comando `--sin-sync1` el error máximo fue `inf` o `4e+33`: el resultado depende
de qué hilo llegó primero, y tu número será otro. Ninguno de los dos programas lanzó excepción ni error de CUDA. ¿Qué los detectó? En la GPU
(paso 4b del notebook): `-DGRID_TRUNCADO` con `n = 100` y `-DSIN_SYNC1` tres veces con `n = 512`.

**I4. n no múltiplo de `TILE`.** `./matmul_tiled 100`, `./matmul_tiled 20`, `./matmul_tiled 1000` en la GPU;
sin GPU, `--n 20 --tile 16` y `--n 24 --tile 8`. Todos deben dar OK. Salida real del simulador con
`n = 100`: `malla=7x7 … (cada elemento de A: 7 veces) … error maximo vs NumPy 8.05e-06 -> PASS`.

## 4. Modificar (en casa; se retoma en el Laboratorio 2, martes 1 de diciembre)

Objetivo verificable: una tabla `n × TILE` de tiempos de *kernel* (mediana de 5) para `n ∈ {256, 512,
1024, 2048}` y `TILE ∈ {8, 16, 32}` de las dos versiones (`-DBLOCK` para la ingenua). El paso 5 y 6 del
notebook la producen y la guardan en CSV.

1. `-DTILE=8`, `16`, `32`. Escribe antes qué esperas: ¿`TILE=32` tardará la mitad que `TILE=16`? Hace la
   mitad de lecturas globales.
2. `-DTILE=64`. ¿Compila? ¿Corre? Salida **esperada** en la GPU:
   `Error CUDA en matmul_tiled.cu:91: invalid configuration argument`. Un bloque de 64×64 = 4096 hilos
   supera el máximo de 1024. Solo `cudaGetLastError()` lo dice (la primera llamada, línea 91; la del ciclo
   de medición, línea 100, lo atraparía una repetición después). Sin **ninguna** llamada a
   `cudaGetLastError()`, el programa imprimiría tiempos casi nulos y GFLOP/s absurdos de un *kernel* que
   nunca corrió, una C llena de ceros y "FALLA" en la verificación (si la hay).
3. Para `n = 1024`: GFLOP/s de cada versión y cociente. Explica en 3 líneas por qué el cociente de tiempos
   es menor que el cociente de lecturas (cachés, lecturas de la ingenua parcialmente coalescidas, el
   *kernel* por mosaicos pasa a estar limitado por cómputo y por sincronización, no solo por memoria).

Sin GPU solo se verifica la lógica: `--n 24 --tile 8` y `--n 64 --tile 32` (salida real: `malla=2x2
bloque=32x32 … (cada elemento de A: 2 veces) … PASS`).

## 5. Crear: transposición coalescida con memoria compartida

`transpose.cu` trae completa `transpose_naive`: lee `in` por filas (coalescido) y escribe `out` por
columnas (cada hilo del *warp* toca un segmento distinto de memoria). Escribe `transpose_shared` en el
`TODO(1)`: el bloque lee su mosaico de `in` por filas a `tile[][]`, sincroniza y escribe el mosaico
transpuesto en `out` **también por filas**. La transposición ocurre al indexar `tile`, no la memoria global.
Cuando termines, pon `TODO1_LISTO` en 1 (y `True` en `transpose_numba.py` si lo haces también en Numba).

Criterio de "listo":

- `NUMBA_ENABLE_CUDASIM=1 python3 transpose_numba.py --n 20 --tile 8` → `transpose_shared … PASS`
  (y `--n 17 --tile 16`, un solo mosaico parcial).
- En la GPU: `./transpose 1000` y `./transpose 1024` reportan `OK` en las dos versiones, y para
  `./transpose 4096` la versión con compartida alcanza más GB/s que la ingenua. Orden de magnitud
  **esperado** en T4 (pico ≈ 320 GB/s): ingenua ~60–120 GB/s, con compartida ~150–250 GB/s.
- Explicas en voz alta qué índice recorre `threadIdx.x` en cada uno de los dos accesos a memoria global.

El `+1` en `tile[TILE][TILE + 1]` evita conflictos de banco en la memoria compartida; se explica en S04
(lunes 30 de noviembre). Déjalo.

## Después de PRIMM: Práctica 6 · Laboratorio 1 (50 min)

El resto de la sesión es la Práctica 6 (`practicas/P6-gpu/README.md`, publicada el lunes 23 de
noviembre): Parte A (suma de vectores y SAXPY con medición del *kernel* con y sin transferencias) y
Parte B (multiplicación de matrices por mosaicos con `TODO(n)`: la misma estructura que acabas de
rastrear). Lo que anotaste en I2 y I3 es lo que te van a preguntar en la mini-defensa. Fecha límite de la
Práctica 6: domingo 6 de diciembre, 23:59 (15 % del 3er parcial).

## Errores frecuentes

| Síntoma | Primera pregunta que debes hacerte |
|---|---|
| `nvidia-smi` dice "command not found" o no lista GPU | ¿Activaste el entorno con GPU antes de ejecutar? |
| `CudaSupportError: ... driver library cannot be found` al correr el espejo local | ¿Pusiste `NUMBA_ENABLE_CUDASIM=1` delante del comando? |
| La verificación dice FALLA con error ~`0.2·n` (el valor de un elemento de C) | ¿Tu malla cubre todo `n` (división entera vs. redondeo hacia arriba)? ¿Se lanzó el *kernel*? |
| FALLA con error enorme, `inf` o `nan`, y a veces OK | ¿Falta una barrera? ¿Cuántas veces lo corriste? Una vez bien no es evidencia |
| El *kernel* "se cuelga" o da `unspecified launch failure` | ¿Algún hilo hace `return` antes de un `__syncthreads()`? |
| `invalid configuration argument` | ¿Cuántos hilos tiene tu bloque? El máximo es 1024 |
| La de mosaicos no es 16× más rápida | ¿Qué absorben las cachés? ¿Cuál era el cuello de botella real? |

## Uso de IA en esta actividad

- 🟢 Pedir que te explique con otras palabras qué es un acceso coalescido o para qué sirve cada barrera.
- 🟡 Pedir que revise tu `transpose_shared` y te señale (sin corregir) dónde un acceso no es coalescido;
  decláralo en el reporte de la Práctica 6.
- 🔴 Pedir el *kernel* de transposición completo. En la mini-defensa se pregunta línea por línea.

## Para saber más

- *CUDA C++ Programming Guide*, secciones "Memory Hierarchy", "Shared Memory" (incluye el ejemplo de
  multiplicación de matrices por mosaicos) y "Device Memory Accesses" (coalescencia).
- Documentación de Numba CUDA: "Writing CUDA Kernels" → *shared memory and thread synchronization*
  (`cuda.shared.array`, `cuda.syncthreads`), y "Debugging CUDA Python with the simulator".
- Kirk y Hwu, *Programming Massively Parallel Processors*, 4.ª ed., cap. 5 "Memory architecture and data
  locality" (tiling) y cap. 6 "Performance considerations" (coalescencia).
