> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S03 · jueves 26 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# Práctica guiada S03 · Reducción en GPU en tres versiones e histograma con atómicas (PRIMM)

Trabajas en pareja: **conductor** (teclea) y **navegante** (lee, predice, anota). Cambian de rol cuando el profesor
lo indique (a los 15 minutos). Todo lo que predigas lo escribes **antes** de ejecutar; después anotas lo observado
junto a la predicción. Las diferencias son el material de la puesta en común.

## Archivos

| Archivo | Qué es | Dónde corre |
|---|---|---|
| `reduce_sum.cu` | Suma de `n` `float` en tres versiones: `atomic` (atómica ingenua), `tree_div` (árbol con divergencia), `tree_nodiv` (árbol sin divergencia); segunda etapa en CPU o con una atómica por bloque; medición con `cudaEvent_t` | GPU (Colab/Kaggle); sin GPU solo se compila con `nvcc -c` |
| `reduce_sum_numba.py` | Espejo de los tres *kernels* en Numba (`@cuda.jit`), con `--sin-sync` y `--etapa2 atomic` | GPU, o CPU con `NUMBA_ENABLE_CUDASIM=1` (solo correctitud) |
| `reduce_sum_cpu.c` | Referencia secuencial: la misma suma en `double`, en `float` secuencial, en `float` con otro orden y emulando el orden exacto de cada árbol; imprime el máximo y cuántas atómicas haría cada versión | Cualquier máquina con `gcc` |
| `histogram.cu`, `histogram_numba.py`, `histogram_cpu.c` | Histograma de 16 bins: versión `global` (atómicas en memoria global) completa y versión `shared` con `TODO(1)` (fase Crear) | GPU / CUDASIM / `gcc` |
| `notebook_colab.ipynb` | Todo lo anterior en celdas: `!nvidia-smi`, `%%writefile`, `!nvcc`, ejecución, experimentos, medición y CSV | Colab o Kaggle con GPU |
| `Makefile`, `tests/run_tests.sh` | `make all` (compila), `make run` (requiere GPU), `make test` (sin GPU, < 60 s), `make sim`, `make clean` | Laptop |

**Datos.** Los tres programas de suma usan `x[i] = 1.0f + (i % 10) * 0.1f` y `x[n-1] = 9.5f` (un máximo único al
final, para la fase Modificar). Como `0.1` no es exacto en `float`, **el orden de las sumas cambia el resultado**: por
eso la verificación es con tolerancia. La referencia es la suma secuencial en `double`: para `n = 1000` vale
`1457.600012`; para `n = 2^20 = 1 048 576`, `1520442.012500`. El histograma usa enteros: ahí la coincidencia con la
CPU debe ser **exacta**.

## Cómo ejecutar

**En Colab (recomendado en clase).** Sube `notebook_colab.ipynb` a <https://colab.research.google.com> → *Entorno
de ejecución → Cambiar tipo de entorno de ejecución → GPU (T4)*. Ejecuta las celdas en orden; la primera
(`!nvidia-smi`) debe mostrar la tarjeta. Las celdas `%%writefile` crean los archivos; después
`!nvcc -O2 -arch=sm_75 reduce_sum.cu -o reduce_sum` y `!./reduce_sum all 1048576 256 cpu`.

**En Kaggle.** *Settings → Accelerator → GPU*. Con una P100 compila con `-arch=sm_60` (el notebook lo detecta solo).

**Sin GPU (laptop, o Colab sin cuota).** Solo correctitud, con `n` pequeño (cada hilo se simula en Python):

```bash
NUMBA_ENABLE_CUDASIM=1 python3 reduce_sum_numba.py all 1000 256
NUMBA_ENABLE_CUDASIM=1 python3 histogram_numba.py all 4096 256
nvcc -c -arch=sm_75 reduce_sum.cu -o reduce_sum.o      # ¿compila? (si tienes nvcc)
make test                                              # todo lo anterior + referencias CPU + notebook, ~40 s
```

Si Colab no da GPU, no esperes con la pestaña abierta: haz Predecir, Investigar y Modificar con CUDASIM y vuelve a
pedir GPU en una o dos horas.

### Sobre la tolerancia (léelo antes de Predecir)

`verificacion=OK` significa `|suma − referencia_double| ≤ 1e-4 · |referencia|`. Es holgada a propósito: la versión
atómica suma en el orden en que llegan los hilos, distinto en cada ejecución, y con `n = 2^20` su error de redondeo
es del orden de `1e-6`–`1e-5`. Una tolerancia tan holgada **no** notaría un elemento faltante entre un millón
(`1.9 / 1 520 442 ≈ 1.3e-6`). Por eso el programa hace tres cosas más: prueba con `n` pequeño (ahí un elemento
faltante es `1e-3` de la suma), compara los parciales de los árboles **bit a bit** contra una emulación en CPU del
mismo orden (`parciales_bit_a_bit_igual_a_emulacion_cpu`), y pone el máximo `9.5` en `x[n-1]` para que la fase
Modificar detecte un último bloque mal tratado.

---

## P · Predecir (6 min, por escrito, sin ejecutar)

Lee los tres *kernels* de `reduce_sum.cu` (están comentados) y contesta:

| # | Pregunta | Tu predicción | Observado |
|---|---|---|---|
| P1 | `n = 1 048 576`, `block = 256`. ¿Cuántas operaciones atómicas en memoria **global** hace cada versión: `atomic`; `tree_*` con etapa 2 en CPU; `tree_*` con etapa 2 atómica? | | |
| P2 | ¿Las tres versiones imprimirán exactamente la misma `suma`? ¿Cuál se acercará más a `referencia_cpu_double`? ¿Alguna puede cambiar entre dos ejecuciones idénticas? | | |
| P3 | Si se quita el `__syncthreads()` de dentro del ciclo del árbol (`-DSIN_SYNC`) con `block = 256`: ¿resultado incorrecto, correcto, o "a veces"? ¿Y con `block = 32`? | | |
| P4 | Con `block = 256`, ¿cuántos niveles tiene el árbol? En `tree_div`, en el nivel `stride = 1`, ¿cuántos hilos están activos y en cuántos *warps* están repartidos? En `tree_nodiv`, en el nivel `stride = 128`, ¿cuántos hilos activos y en cuántos *warps*? | | |
| P5 | `n = 1000`, `block = 256`: 4 bloques; en el último, 232 hilos tienen `i ≥ n`. ¿Qué escriben en `s[tid]`? ¿Altera la suma? ¿Qué pasaría si **no** escribieran nada? | | |
| P6 | Ordena las tres versiones de la más lenta a la más rápida en una T4 con `n = 2^20`, y estima por cuánto (×2, ×10, ×100). | | |

<details><summary>Respuestas (ábrelas solo después de ejecutar)</summary>

- **P1.** `atomic`: una por elemento, **1 048 576**. `tree_*` + etapa 2 en CPU: **0** (los parciales se copian y se
  suman en el anfitrión). `tree_*` + etapa 2 atómica: una por bloque, `⌈1 048 576 / 256⌉ = `**4096**. La versión
  `atomic` hace 256 veces más atómicas que la de árbol, todas sobre **la misma dirección**.
- **P2.** No. Los árboles suman por pares (error de redondeo ~`1e-8` relativo); la atómica acumula un millón de
  sumas en un solo `float` en orden arbitrario (~`1e-6`) y **puede cambiar entre ejecuciones**. Los dos árboles
  tampoco coinciden entre sí bit a bit: emparejan los sumandos de distinta forma. Los parciales de cada árbol sí
  coinciden bit a bit con la emulación en CPU del mismo orden.
- **P3.** Con 256 hilos (8 *warps*) el resultado es casi siempre incorrecto y cambia entre corridas: un *warp*
  puede leer `s[tid + stride]` antes de que otro *warp* lo haya escrito. Con 32 hilos (un *warp*) "suele salir
  bien" porque el *warp* avanza casi en bloque, pero desde Volta (T4 incluida) los hilos de un *warp* pueden
  avanzar de forma independiente: no está garantizado. En el simulador falla siempre, también con 32.
- **P4.** `log2(256) = 8` niveles. `tree_div`, `stride = 1`: activos los `tid` pares, **128 hilos en los 8
  warps** (16 por *warp*: cada *warp* diverge). `tree_nodiv`, `stride = 128`: activos `tid < 128`, **128 hilos en
  los warps 0–3 completos**; los *warps* 4–7 no ejecutan la suma.
- **P5.** Escriben `0.0f`, el neutro de la suma: no altera nada. Si no escribieran nada, `s[tid]` tendría basura de
  un bloque anterior y el árbol la sumaría; el resultado sería incorrecto sin ningún error de CUDA.
- **P6.** Esperado: `atomic` (≈ 1–10 ms: un millón de atómicas serializadas sobre una dirección) ≫ `tree_div` ≥
  `tree_nodiv` (≈ 0.02–0.06 ms). Entre los dos árboles la diferencia es pequeña con este `n` (la lectura de 4 MB
  desde memoria global domina); entre atómica y árbol, uno o dos órdenes de magnitud. Los números exactos dependen
  de la GPU asignada.
</details>

## R · Ejecutar (6 min)

En el notebook, en orden: `!nvidia-smi` → celdas `%%writefile` → celda `nvcc`/`gcc` → `!./reduce_sum_cpu 1048576 256`
→ `!./reduce_sum all 1048576 256 cpu` → `!./reduce_sum tree_nodiv 1048576 256 atomic`. En paralelo, en la laptop:
`make test`. Anota en la columna "Observado".

Salida real obtenida **sin GPU** al escribir este material (referencia CPU y simulador, este mismo código):

```
$ ./reduce_sum_cpu 1048576 256
reduce_sum_cpu: n=1048576 block=256 grid=4096
ref_double            =1520442.012500  (suma secuencial en double; mediana_ms=1.293 de 5, min 1.267, max 1.306)
float_secuencial      =1520441.875000  err_rel=9.04e-08  dentro_de_tolerancia  (informativo: un acumulador)
float_orden_permutado =1520444.750000  err_rel=1.80e-06  dentro_de_tolerancia  (informativo: emula el orden arbitrario de las atómicas)
float_arbol_div       =1520442.024994  err_rel=8.22e-09  dentro_de_tolerancia  (mismo orden que tree_div)
float_arbol_nodiv     =1520442.024994  err_rel=8.22e-09  dentro_de_tolerancia  (mismo orden que tree_nodiv)
max=9.500000 en i=1048575
atomicas_globales: atomic=1048576  tree+etapa2=cpu: 0  tree+etapa2=atomic: 4096
verificacion=OK  (emulaciones del árbol dentro de tolerancia y máximo correcto)

$ NUMBA_ENABLE_CUDASIM=1 python3 reduce_sum_numba.py all 1000 256
reduce_sum_numba: n=1000 block=256 grid=4 modo=CUDASIM
referencia_cpu_double=1457.600012  tolerancia_relativa=1e-04
version=atomic     etapa2=-      atomicas_globales=1000     tiempo_simulador_ms=546.0 (NO es una medición)
   suma=1457.599976 err_rel=2.49e-08 verificacion=OK
version=tree_div   etapa2=cpu    atomicas_globales=0        tiempo_simulador_ms=2100.8 (NO es una medición)
   suma=1457.600037 err_rel=1.70e-08 verificacion=OK parciales_bit_a_bit_igual_a_emulacion_cpu=si
version=tree_nodiv etapa2=cpu    atomicas_globales=0        tiempo_simulador_ms=1730.0 (NO es una medición)
   suma=1457.600006 err_rel=3.93e-09 verificacion=OK parciales_bit_a_bit_igual_a_emulacion_cpu=si
```

Fíjate: cuatro órdenes de suma, cuatro resultados distintos, todos "correctos" con tolerancia. El mismo dato
sumado en otro orden (`float_orden_permutado`) se aleja 2.7 unidades de la referencia.

Salida **esperada** en la GPU (no ejecutada en el entorno de autoría; tiempos como órdenes de magnitud para una T4 de
Colab; cambian con la GPU asignada):

```
$ ./reduce_sum all 1048576 256 cpu
reduce_sum (CUDA C): n=1048576 block=256 grid=4096 gpu="Tesla T4" (SMs=40, cc 7.5, warp=32)
referencia_cpu_double=1520442.012500  tolerancia_relativa=1e-04
version=atomic     etapa2=-      atomicas_globales=1048576  kernel_mediana_ms≈1–10 (…)
   suma=15204xx.xxxxxx err_rel≈1e-6 verificacion=OK            <- el valor cambia entre corridas
version=tree_div   etapa2=cpu    atomicas_globales=0        kernel_mediana_ms≈0.03–0.06 (…) etapa2_cpu_ms≈0.02–0.05
   suma=1520442.024994 err_rel=8.22e-09 verificacion=OK parciales_bit_a_bit_igual_a_emulacion_cpu=si
version=tree_nodiv etapa2=cpu    atomicas_globales=0        kernel_mediana_ms≈0.02–0.05 (…) etapa2_cpu_ms≈0.02–0.05
   suma=1520442.024994 err_rel=8.22e-09 verificacion=OK parciales_bit_a_bit_igual_a_emulacion_cpu=si

$ ./reduce_sum tree_nodiv 1048576 256 atomic
version=tree_nodiv etapa2=atomic atomicas_globales=4096     kernel_mediana_ms≈0.02–0.05 (…)
   suma=1520442.0xxxxx err_rel≈1e-8 verificacion=OK            <- 4096 sumandos en orden arbitrario: puede variar en el último dígito
```

Lo que **sí** debe coincidir exactamente con lo de arriba: `grid`, `atomicas_globales`, `referencia_cpu_double`,
la `suma` de los dos árboles con etapa 2 en CPU (`1520442.024994`) y `parciales_bit_a_bit…=si`.

## I · Investigar (10 min)

**I1. Tabla de rastreo (un bloque de 8).** Datos del bloque 0 con `block = 8`: `s = [1.0, 1.1, 1.2, 1.3, 1.4, 1.5,
1.6, 1.7]`. Completa el contenido de `s[0..7]` después de cada nivel (trabaja con decimales exactos; la suma es
`10.8`). Marca con * las posiciones que se leen pero ya no se escriben.

| Nivel | `tree_nodiv` (`stride` = 4, 2, 1; activo si `tid < stride`) | `tree_div` (`stride` = 1, 2, 4; activo si `tid % (2·stride) == 0`) |
|---|---|---|
| carga | `[1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7]` | `[1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7]` |
| 1 | | |
| 2 | | |
| 3 | | |

Preguntas: ¿cuántas sumas hace cada árbol en total? ¿Qué `tid` están activos en el nivel 1 de cada uno? Si un hilo del
nivel 2 leyera `s[tid + stride]` **antes** de que el nivel 1 terminara, ¿qué valor podría leer?

<details><summary>Respuesta</summary>

`tree_nodiv`: nivel 1 (`stride = 4`, activos 0–3): `[2.4, 2.6, 2.8, 3.0, 1.4*, 1.5*, 1.6*, 1.7*]`; nivel 2
(`stride = 2`, activos 0–1): `[5.2, 5.6, 2.8*, 3.0*, …]`; nivel 3 (`stride = 1`, activo 0): `[10.8, 5.6*, …]`.
`tree_div`: nivel 1 (`stride = 1`, activos 0, 2, 4, 6): `[2.1, 1.1*, 2.5, 1.3*, 2.9, 1.5*, 3.3, 1.7*]`; nivel 2
(`stride = 2`, activos 0, 4): `[4.6, …, 6.2, …]`; nivel 3 (`stride = 4`, activo 0): `[10.8, …]`. Ambos hacen
`4 + 2 + 1 = 7 = block − 1` sumas (255 con 256 hilos). Sin la barrera, el hilo 0 del nivel 2 podría leer `s[2] = 1.2`
(valor viejo) en vez de `2.8`: la suma sale menor y distinta cada vez. En `tree_div` los activos del nivel 1 son los
pares: en un *warp* real, 16 lanes trabajan y 16 esperan.
</details>

**I2. *Warps* activos por nivel.** Con `block = 256` (8 *warps* de 32), llena cuántos *warps* ejecutan la suma en
cada nivel y cuántos de ellos están **divergidos** (algunos lanes activos y otros no):

| `stride` (`tree_div` ↑ / `tree_nodiv` ↓) | hilos activos | *warps* con trabajo en `tree_div` | de ellos, divergidos | *warps* con trabajo en `tree_nodiv` | de ellos, divergidos |
|---|---|---|---|---|---|
| 1 / 128 | 128 | | | | |
| 2 / 64 | 64 | | | | |
| 4 / 32 | 32 | | | | |
| 8 / 16 | 16 | | | | |
| 16 / 8 | 8 | | | | |
| 32 / 4 | 4 | | | | |
| 64 / 2 | 2 | | | | |
| 128 / 1 | 1 | | | | |
| **total de *warp*-pasos** | | | | | |

<details><summary>Respuesta</summary>

`tree_div`: 8, 8, 8, 8, 8 (todos divergidos: 16, 8, 4, 2, 1 lanes activos por *warp*), 4, 2, 1 (un lane activo cada
uno) → **47 *warp*-pasos, 47 divergidos**. `tree_nodiv`: 4, 2, 1 (completos, sin divergencia), 1, 1, 1, 1, 1 (solo
el *warp* 0, divergido porque quedan < 32 activos) → **12 *warp*-pasos, 5 divergidos**. Mismas 255 sumas, cuatro
veces menos instrucciones de *warp*. En la práctica la diferencia de tiempo con `n = 2^20` es modesta porque la
carga de 4 MB desde memoria global domina; en problemas donde el árbol se repite muchas veces (p. ej., dentro de
un ciclo), sí se nota. Kirk & Hwu lo tratan en el capítulo de reducción.
</details>

**I3. Sin barrera entre niveles.** En la laptop:

```bash
NUMBA_ENABLE_CUDASIM=1 python3 reduce_sum_numba.py tree_div 1000 256 --sin-sync     # repítelo 3 veces
NUMBA_ENABLE_CUDASIM=1 python3 reduce_sum_numba.py tree_nodiv 64 32 --sin-sync      # un solo warp
```

Salida real (tres corridas, últimas líneas; los valores cambian en cada una):

```
suma=168.299998 err_rel=8.85e-01 verificacion=FALLA parciales_bit_a_bit_igual_a_emulacion_cpu=no
suma=319.800007 err_rel=7.81e-01 verificacion=FALLA parciales_bit_a_bit_igual_a_emulacion_cpu=no
suma=155.700001 err_rel=8.93e-01 verificacion=FALLA parciales_bit_a_bit_igual_a_emulacion_cpu=no
```

En la GPU (notebook, sección 4a; esperado, no ejecutado aquí): `nvcc -O2 -arch=sm_75 -DSIN_SYNC reduce_sum.cu -o
reduce_sum_sin_sync`; cinco corridas con `block = 256` dan `FALLA` casi todas, con sumas distintas; cinco con
`block = 32` suelen dar `OK`. Escribe en una línea por qué el segundo caso **no** demuestra que el código sea correcto
(idea errónea 7 de la Unidad III, ahora en GPU). Pista: ¿qué garantiza el *hardware* sobre el orden entre *warps*?
¿Y dentro de un *warp* desde Volta? Si tu Colab tiene `compute-sanitizer`, prueba
`compute-sanitizer --tool racecheck ./reduce_sum_sin_sync tree_nodiv 4096 256`: reporta las carreras sobre memoria
compartida aunque el resultado haya salido bien.

**I4. `n` y `block` que no son potencias de 2.**

```bash
./reduce_sum all 1000003 256                    # GPU; en laptop: python3 reduce_sum_numba.py all 1003 256
./reduce_sum tree_nodiv 1048576 96              # GPU; en laptop: python3 reduce_sum_numba.py tree_nodiv 1000 96
```

Salida real (CUDASIM) del segundo:

```
aviso: el árbol supone block potencia de 2; con block=96 se pierden sumandos (experimento de la fase Investigar)
reduce_sum_numba: n=1000 block=96 grid=11 modo=CUDASIM
version=tree_nodiv etapa2=cpu    atomicas_globales=0        …
   suma=974.599998 err_rel=3.31e-01 verificacion=FALLA parciales_bit_a_bit_igual_a_emulacion_cpu=si
```

¿Por qué el primero funciona y el segundo no? Rastrea `stride = 48, 24, 12, 6, 3, 1` y di qué posición de `s` se
queda sin sumar. ¿Hubo algún error de CUDA? ¿Por qué `parciales_bit_a_bit…=si` aunque el resultado esté mal?

<details><summary>Respuesta</summary>

`n` arbitrario funciona porque los hilos con `i ≥ n` cargan `0` (neutro). Con `block = 96`, tras `stride = 3`
quedan tres parciales `s[0], s[1], s[2]` de 32 elementos cada uno; con `stride = 1` solo `s[0] += s[1]`: `s[2]`
(un tercio de los datos) nunca se suma: `974.6 ≈ 2/3 · 1457.6`. No hay error de CUDA: el programa es "válido" y
está mal (idea errónea 27). La emulación en CPU repite el mismo algoritmo, así que coincide bit a bit: esa
comparación detecta diferencias de orden, no errores de algoritmo; para eso está la referencia en `double`.
</details>

**I5. ¿Cuánto cuesta la etapa 2 en la CPU?** Compara, en tu salida de GPU, `etapa2_cpu_ms` (copia D2H de 16 KB +
suma de 4096 `double`) con `kernel_mediana_ms` de `tree_nodiv`. ¿Qué fracción del total es la copia? Una copia de
16 KB tiene una latencia fija de decenas de microsegundos: con un *kernel* de ~30 µs **no es gratis**. Si la
reducción se repitiera 1000 veces dentro de un algoritmo, ¿qué etapa 2 elegirías? (Las copias son el tema de la S04,
lunes 30 de noviembre.)

**I6 (solo GPU). `n = 2^24`.** `./reduce_sum_cpu 16777216 256` y `./reduce_sum all 16777216 256`. Salida real de
la referencia CPU:

```
ref_double            =24326970.200000
float_secuencial      =26777438.000000  err_rel=1.01e-01  FUERA  (informativo: un acumulador)
float_orden_permutado =27075950.000000  err_rel=1.13e-01  FUERA  (informativo: emula el orden arbitrario de las atómicas)
float_arbol_div       =24326970.399994  err_rel=8.22e-09  dentro_de_tolerancia
```

Un acumulador `float` que llega a `16 777 216 = 2^24` ya no cambia al sumarle `1.0` (el espaciado entre `float`
consecutivos ahí es 2). Esperado en GPU: la versión `atomic` marca `FALLA` con error del 10 %; los árboles, `OK`.
La versión atómica ingenua no solo es lenta: para `n` grande es **incorrecta** en `float`.

## M · Modificar (8 min + lo que falte en casa) · reducción `max`

Crea `reduce_max.cu` y/o `reduce_max_numba.py` a partir de la versión `tree_nodiv`:

- La operación deja de ser `+=`: usa `fmaxf(a, b)` en CUDA C, `max(a, b)` en Numba.
- El neutro de la carga para `i ≥ n` ya no es `0`: usa `-INFINITY` (`<math.h>`) o `-FLT_MAX`.
- Etapa 2: el anfitrión toma el máximo de los parciales (o `atomicMax` solo si pasas a enteros: `atomicMax` no
  existe para `float`; explica en una línea por qué no sirve `atomicAdd`).
- Salida: `max=<valor> referencia_cpu=<valor> verificacion=<OK|FALLA>` con `%.6f`.
- Criterio de "listo": para **cualquier** `n` imprime `max=9.500000 … verificacion=OK` (`n = 1000`, `n = 37` con
  `block = 8`, `n = 2^20`). El `9.5` está en `x[n-1]`: si tratas mal el último bloque, lo notarás. Si tus archivos se
  llaman `reduce_max.cu` / `reduce_max_numba.py`, `make test` los detecta y los revisa.
- Pregunta para la bitácora: ¿por qué aquí la verificación puede ser **exacta** (`==`) y en la suma no?

## M · Crear (10 min, transferencia) · histograma con atómicas en memoria compartida

`histogram.cu` ya trae la versión `global`: cada hilo hace `atomicAdd(&hist[v[i]], 1)` sobre 16 contadores en
memoria global. El 30 % de los datos cae en el bin 0, así que ~300 000 hilos compiten por **una** dirección. Completa
el `TODO(1)` (`hist_shared_atomic` en `histogram.cu` y/o en `histogram_numba.py`): un histograma **privado por
bloque** en memoria compartida y, al final, un volcado al histograma global. Es la misma idea que los histogramas
privados por hilo más reducción de la Práctica 4, con el bloque en el papel del hilo.

Salida real de la referencia y de la versión global (CUDASIM, `n = 4096`):

```
$ ./histogram_cpu 4096 256
hist_cpu=[1213,191,192,189,196,188,196,189,194,192,191,194,188,196,190,197]
total=4096  bin_mas_poblado=0 (29.6 % de los datos: esa es la contención de la versión global)
atomicas_globales: global=4096  shared=256 (= 16 bins x 16 bloques; además 4096 atómicas en compartida)

$ NUMBA_ENABLE_CUDASIM=1 python3 histogram_numba.py all 4096 256
version=global  atomicas_globales=4096     atomicas_compartidas=0        …
   hist_gpu=[1213,191,192,189,196,188,196,189,194,192,191,194,188,196,190,197]
   total=4096 verificacion=OK
version=shared  atomicas_globales=256      atomicas_compartidas=4096     …
   hist_gpu=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
   total=0 -> TODO pendiente: hist_shared_atomic no escribe nada todavía (TODO(1))
```

- **Criterio de "listo":** `histogram shared` imprime el **mismo** histograma que la CPU y `verificacion=OK`, en
  CUDASIM (`4096 256` y `2000 128`) y en GPU (`n = 2^20`: `atomicas_globales=65536`, 16 veces menos que `global`).
  `make test` lo revisa. Esperado en una T4: la versión `shared` entre 10 y 100 veces más rápida que `global` con
  estos datos sesgados; anota tu número con el modelo de GPU y la fecha.
- **Restricciones:** `BINS ≤ blockDim.x`; dos `__syncthreads()` exactamente (piensa dónde y por qué); sin escribir
  en `hist` desde más de un sitio por bloque y por bin.
- **Pistas selladas** (ábrelas una a la vez, solo si llevas 5 minutos sin avanzar):

<details><summary>Pista 1 · estructura</summary>
Cinco pasos: (a) declarar <code>__shared__ unsigned int s_hist[BINS]</code>; (b) ponerlo en cero de forma
cooperativa; (c) barrera; (d) cada hilo con <code>i &lt; n</code> hace su atómica <strong>en compartida</strong>;
(e) barrera; (f) volcado: cada bin del bloque se suma al global con <strong>una</strong> atómica.
</details>

<details><summary>Pista 2 · quién pone en cero y quién vuelca</summary>
Como <code>BINS ≤ blockDim.x</code>, basta <code>if (tid &lt; BINS) s_hist[tid] = 0;</code> y, al final,
<code>if (tid &lt; BINS) atomicAdd(&amp;hist[tid], s_hist[tid]);</code>. Un <code>for (j = tid; j &lt; BINS; j +=
blockDim.x)</code> funciona para cualquier <code>BINS</code>. Puedes saltarte el volcado de los bins con cero.
</details>

<details><summary>Pista 3 · las barreras</summary>
La primera barrera impide que un hilo rápido sume en un contador que otro hilo aún no puso en cero. La segunda
impide que el volcado lea un contador que otro hilo aún está incrementando. Sin la segunda, el histograma
global queda incompleto "a veces" (idea errónea 7). Ninguna barrera puede ir dentro de <code>if (i &lt; n)</code>:
todos los hilos del bloque deben llegar a la misma barrera (idea errónea 32).
</details>

- **Extensión (quien termina):** (a) `-DBINS=256` (notebook, sección 6): ¿cuántas atómicas globales hace ahora el
  volcado y sigue valiendo la pena? (b) Haz que cada bloque procese varios elementos con un ciclo de paso
  `gridDim.x * blockDim.x` (*grid-stride loop*) y lanza solo 40 × 8 bloques: ¿cuántas atómicas globales quedan?
  (c) Datos uniformes en vez de sesgados: ¿se achica la ventaja de `shared`? ¿Por qué?

## Antes de cerrar

- [ ] La tabla de Predecir tiene las seis predicciones **y** lo observado.
- [ ] `make test` pasa en la laptop (o explicas qué caso falla y por qué).
- [ ] Guardaste `resultados_S03_reduccion_<fecha>.csv` (y el del histograma) del notebook con el modelo de GPU.
- [ ] Bitácora de errores: una entrada por cada diferencia entre predicción y observación; en especial P3 y P6.

**Para saber más.** CUDA C Programming Guide: "Thread Hierarchy" (barreras y memoria compartida), "Atomic
Functions", "SIMT Architecture" y "Independent Thread Scheduling" (por qué un *warp* ya no garantiza *lockstep*),
"Compute Sanitizer" (*racecheck*); Numba CUDA: "Supported Atomic Operations", "Shared memory and thread
synchronization", "Debugging CUDA Python with the simulator"; Kirk & Hwu, *Programming Massively Parallel
Processors*, capítulos de reducción paralela (divergencia y variantes del árbol) e histograma (privatización).
