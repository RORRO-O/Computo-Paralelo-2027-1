> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S01 · lunes 23 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# Práctica guiada S01 · Suma de vectores en CUDA (PRIMM)

Trabajas en pareja: **conductor** (teclea) y **navegante** (lee, predice, anota). Cambian de rol cuando el
profesor lo indique (a los 10 minutos). Todo lo que predigas lo escribes **antes** de ejecutar; después anotas lo
observado junto a la predicción. Las diferencias son el material de la puesta en común.

## Archivos

| Archivo | Qué es | Dónde corre |
|---|---|---|
| `vector_add.cu` | Suma `c = a + b` en CUDA C: reserva, copias, lanzamiento, verificación contra la CPU, medición con `cudaEvent_t` | GPU (Colab/Kaggle); sin GPU solo se compila con `nvcc -c` |
| `vector_add_numba.py` | Espejo del mismo *kernel* en Numba (`@cuda.jit`) | GPU, o CPU con `NUMBA_ENABLE_CUDASIM=1` (solo correctitud) |
| `vector_add_cpu.c` | Referencia secuencial; imprime el mismo `checksum` | Cualquier máquina con `gcc` |
| `index_probe.cu`, `index_probe_numba.py` | Cada hilo imprime su `blockIdx`, `threadIdx` e índice global; el anfitrión imprime la tabla ordenada | GPU / CUDASIM |
| `notebook_colab.ipynb` | Todo lo anterior en celdas: `!nvidia-smi`, `%%writefile`, `!nvcc`, ejecución, medición y CSV | Colab o Kaggle con GPU |
| `Makefile`, `tests/run_tests.sh` | `make all` (compila), `make run` (requiere GPU), `make test` (sin GPU), `make sim`, `make clean` | Laptop |

Los tres programas de suma inicializan igual (`a[i] = i % 7`, `b[i] = i % 13`): sus sumas son enteros exactos en
`float`, así que el `checksum` debe coincidir **exactamente** entre CPU, CUDASIM y GPU. Para `n = 1000` vale `8991.0`.

## Cómo ejecutar

**En Colab (recomendado en clase).** Sube `notebook_colab.ipynb` a <https://colab.research.google.com> →
*Entorno de ejecución → Cambiar tipo de entorno de ejecución → GPU (T4)*. Ejecuta las celdas en orden; la primera
(`!nvidia-smi`) debe mostrar la tarjeta. Las celdas `%%writefile` crean los archivos; después `!nvcc -O2 -arch=sm_75
vector_add.cu -o vector_add` y `!./vector_add`.

**En Kaggle.** Nuevo *notebook* → panel derecho *Settings → Accelerator → GPU*. Si te asignan una P100, compila con
`-arch=sm_60` (el notebook detecta la arquitectura solo).

**Sin GPU (laptop o Colab sin cuota).** Solo correctitud, con `n` pequeño:

```bash
NUMBA_ENABLE_CUDASIM=1 python3 index_probe_numba.py 10 4
NUMBA_ENABLE_CUDASIM=1 python3 vector_add_numba.py 1000 256
nvcc -c -arch=sm_75 vector_add.cu -o vector_add.o     # verifica que el .cu compila (si tienes nvcc)
make test                                             # todo lo anterior + referencia CPU, ~30 s
```

Si Colab dice que no hay GPU disponible, no esperes con la pestaña abierta: trabaja las fases Predecir e Investigar
con CUDASIM y vuelve a pedir GPU en una o dos horas (la cuota se libera sola).

---

## P · Predecir (5 min, por escrito, sin ejecutar)

Lee `vector_add.cu` (el *kernel* y las líneas de `main` marcadas con comentarios) y `index_probe.cu`. Contesta:

| # | Pregunta | Tu predicción | Observado |
|---|---|---|---|
| P1 | Con `blockDim.x = 256`, ¿qué índice global `i` calcula el hilo `threadIdx.x = 3` del bloque `blockIdx.x = 2`? | | |
| P2 | `n = 1000`, `block = 256`. ¿Cuántos bloques lanza `(n + block - 1) / block`? ¿Y `n / block`? ¿Cuántos elementos quedarían sin calcular con la segunda fórmula? | | |
| P3 | Sin la guardia `if (i < n)`, con `n = 1000` y 4 bloques de 256: ¿qué hilos escriben fuera del arreglo y en qué posiciones? ¿Crees que CUDA reportará un error? | | |
| P4 | `./index_probe 10 4`: ¿cuántas líneas imprime el *kernel*? ¿Cuántas dicen "NO trabaja"? ¿Saldrán en orden `i = 0, 1, 2, …`? | | |
| P5 | ¿El `checksum` de `n = 1000` será idéntico en `vector_add_cpu`, en CUDASIM y en la GPU? ¿Por qué sí o por qué no? | | |

<details><summary>Respuestas (ábrelas solo después de ejecutar)</summary>

- **P1.** `i = 2·256 + 3 = 515`.
- **P2.** `(1000 + 255) / 256 = 4` bloques (1024 hilos, 24 ociosos). `1000 / 256 = 3` bloques (768 hilos): quedarían
  sin calcular los 232 elementos `768…999`.
- **P3.** Los hilos `threadIdx.x = 232…255` del bloque 3 tienen `i = 3·256 + 232…255 = 1000…1023` y escriben
  `c[1000…1023]`, fuera del arreglo (los hilos `0…231` de ese bloque sí trabajan: `i = 768…999`). Lo más
  probable en la GPU es que **no** haya error: `cudaMalloc` redondea la reserva y esos 96 bytes caen en memoria que
  pertenece al proceso. Que no haya error no lo vuelve correcto (idea errónea 27). CUDASIM sí lo detecta
  (`IndexError`).
- **P4.** 12 líneas (3 bloques × 4 hilos); 2 dicen "NO trabaja" (`i = 10, 11`). El orden entre bloques **no** está
  garantizado; la tabla ordenada la imprime el anfitrión desde el arreglo `owner_*`.
- **P5.** Sí: las sumas son enteros pequeños, exactos en `float`, y el `checksum` se acumula en `double`. Si un
  resultado difiere, es un error de índices, no de redondeo.
</details>

## R · Ejecutar (6 min)

En el notebook, ejecuta en orden: `!nvidia-smi` → celdas `%%writefile` → celda `nvcc`/`gcc` → `!./index_probe 10 4` →
`!./vector_add 1000 256` → `!./vector_add_cpu` y `!./vector_add`. En paralelo, en la laptop: `make test`.

Anota en la columna "Observado" de la tabla de arriba. Salida real obtenida **sin GPU** (CUDASIM y CPU, este mismo
código):

```
$ NUMBA_ENABLE_CUDASIM=1 python3 vector_add_numba.py 1000 256
vector_add_numba: n=1000 block=256 grid=4 hilos_lanzados=1024 modo=CUDASIM
kernel_mediana_ms=269.7073 (min 243.3690, max 293.9053)      <- tiempo del simulador: NO es una medición
checksum=8991.0 max_abs_err=0 verificacion=OK

$ ./vector_add_cpu 1000
vector_add_cpu: n=1000 reps=5 mediana_ms=0.0006 (min 0.0006, max 0.0015)  ancho_banda_efectivo_GB_s=19.3
checksum=8991.0 max_abs_err=0 verificacion=OK

$ ./vector_add_cpu                       # n = 2^24, Xeon 2.8 GHz, un núcleo
vector_add_cpu: n=16777216 reps=5 mediana_ms=18.0454 (min 17.8284, max 18.2549)  ancho_banda_efectivo_GB_s=11.2
checksum=150994935.0 max_abs_err=0 verificacion=OK
```

Salida **esperada** en la GPU (no ejecutada en el entorno de autoría; los tiempos son órdenes de magnitud para una
T4 de Colab y cambian con la GPU asignada):

```
$ ./vector_add 1000 256
vector_add (CUDA C): n=1000 block=256 grid=4 hilos_lanzados=1024 gpu="Tesla T4" (SMs=40, cc 7.5)
kernel_mediana_ms≈0.005 (…)  con_copias_mediana_ms≈0.05 (…)  ancho_banda_efectivo_GB_s≈2     <- domina el costo de lanzar
checksum=8991.0 max_abs_err=0 verificacion=OK

$ ./vector_add                            # n = 2^24
vector_add (CUDA C): n=16777216 block=256 grid=65536 hilos_lanzados=16777216 gpu="Tesla T4" (SMs=40, cc 7.5)
kernel_mediana_ms≈0.8–1.0 (…)  con_copias_mediana_ms≈30–60 (…)  ancho_banda_efectivo_GB_s≈200–250
checksum=150994935.0 max_abs_err=0 verificacion=OK
```

Lo que **sí** debe coincidir exactamente: `grid`, `hilos_lanzados`, `checksum`, `max_abs_err=0`, `verificacion=OK`.
Fíjate en la última línea: con las copias, la GPU tarda más que un núcleo de CPU en este problema. Eso se estudia
en la sesión S04 (lunes 30 de noviembre); hoy solo anótalo.

## I · Investigar (6 min)

**I1. Tabla de rastreo.** Completa a mano para `n = 10`, `block = 4` y compárala con la tabla ordenada que imprime
`index_probe`:

| `blockIdx.x` | `threadIdx.x` | `i = blockIdx.x·blockDim.x + threadIdx.x` | ¿`i < n`? | Escribe `c[?]` |
|---|---|---|---|---|
| 0 | 0 | | | |
| 0 | 3 | | | |
| 1 | 0 | | | |
| 2 | 1 | | | |
| 2 | 2 | | | |
| 2 | 3 | | | |

Salida real (CUDASIM):

```
$ NUMBA_ENABLE_CUDASIM=1 python3 index_probe_numba.py 10 4
n=10 block=4 grid=3  hilos_lanzados=12  ociosos=2
--- print desde el kernel (orden NO garantizado) ---
bloque 0 , hilo 0 -> i = 0
bloque 0 , hilo 1 -> i = 1
…                                        <- en CUDASIM las líneas pueden salir entremezcladas; en la GPU, completas pero en otro orden
--- tabla ordenada por índice (la imprime el anfitrión) ---
i = 0 <- bloque 0, hilo 0
i = 1 <- bloque 0, hilo 1
i = 2 <- bloque 0, hilo 2
i = 3 <- bloque 0, hilo 3
i = 4 <- bloque 1, hilo 0
i = 5 <- bloque 1, hilo 1
i = 6 <- bloque 1, hilo 2
i = 7 <- bloque 1, hilo 3
i = 8 <- bloque 2, hilo 0
i = 9 <- bloque 2, hilo 1
indices_sin_dueno=0
```

Pregunta: ¿por qué la tabla ordenada sí sale en orden y los `printf` no? ¿Quién la imprime?

**I2. Malla insuficiente.** Fuerza 3 bloques: `./vector_add 1000 256 3` (GPU) o
`NUMBA_ENABLE_CUDASIM=1 python3 vector_add_numba.py 1000 256 3`. Salida real (CUDASIM):

```
vector_add_numba: n=1000 block=256 grid=3 hilos_lanzados=768 modo=CUDASIM
kernel_mediana_ms=190.9122 (min 150.5424, max 230.6027)
checksum=6901.0 max_abs_err=18 verificacion=FALLA
```

¿Hubo error de CUDA? ¿De dónde sale el 18 (`max_abs_err`)? ¿Y el 2090 de diferencia en el `checksum`
(`8991 − 6901`)? Pista: `max(a[i] + b[i]) = 6 + 12`; los elementos `768…999` quedaron en 0.

**I3. Sin guardia.** CUDASIM: `python3 vector_add_numba.py 1000 256 0 --sin-guardia`. Salida real (últimas líneas;
el hilo exacto que falla primero puede variar):

```
IndexError: tid=[237, 0, 0] ctaid=[3, 0, 0]: index 1005 is out of bounds for axis 0 with size 1000
```

GPU (notebook, sección 4b): `nvcc -O2 -arch=sm_75 -DSIN_GUARDIA vector_add.cu -o vector_add_sin_guardia` y
`./vector_add_sin_guardia 1000 256`. Esperado: ningún error y `verificacion=OK` (los 24 hilos sobrantes escriben en
memoria reservada de más). Después `./vector_add_sin_guardia 1000 1024 4000`: esperado `Error de CUDA en
vector_add.cu:…: an illegal memory access was encountered`, reportado por `cudaDeviceSynchronize`. Escribe en una
línea por qué el primer caso **también** es un error aunque "pase".

**I4. Líneas concretas de `vector_add.cu`.**

1. ¿Qué detecta `cudaGetLastError()` justo después de `<<<…>>>` que `cudaDeviceSynchronize()` no, y viceversa?
   Prueba: `./vector_add 1000 2000` (bloque de 2000 hilos). Esperado: `Error de CUDA … invalid configuration
   argument` en la línea del `cudaGetLastError` posterior al calentamiento.
2. Si quitas el `cudaEventSynchronize(stop)` del ciclo de medición, ¿qué tiempo medirías? ¿Por qué el lanzamiento
   de un *kernel* regresa antes de que termine?
3. ¿Por qué `h_c` se compara contra `h_ref` calculado **en la CPU** si la verificación de CUDA ya pasó? (idea
   errónea 27).

## M · Modificar (4 min + lo que falte en casa)

Convierte la suma en **saxpy** (`y = alpha·x + y`, en el mismo arreglo `y`). Crea `saxpy.cu` (copia de
`vector_add.cu`) y/o `saxpy_numba.py`:

- Firma del *kernel*: `saxpy(float alpha, const float *x, float *y, int n)`; en Numba, `saxpy(alpha, x, y, n)`.
- `x = a`, `y = b` con la misma inicialización; `alpha = 2.0f`.
- Verificación: guarda una copia de `y` **antes** del *kernel* y compara `y_gpu[i]` con `alpha·x[i] + y_antes[i]`.
- Criterio de "listo": para `n = 1000` imprime `checksum=11988.0 … verificacion=OK`; para `n = 2^24`,
  `checksum=201326580.0`. Si tus archivos se llaman `saxpy.cu` / `saxpy_numba.py`, `make test` los detecta y los
  revisa (compilación y CUDASIM con `1000 256`).

## M · Crear (8 min, transferencia)

**Producto punto por partes.** Escribe `dot_partial.cu` (y/o `dot_partial_numba.py`): un *kernel* donde cada hilo
calcula **solo** su producto parcial `p[i] = a[i]·b[i]`; el anfitrión copia `p` de vuelta y lo suma en `double`.
Todavía **no** hay reducción en la GPU: eso es la sesión S03 (jueves 26 de noviembre).

- Entrada: `n` por línea de comandos (por defecto `2^24`), misma inicialización.
- Salida: `dot=<valor> verificacion=<OK|FALLA>` comparando contra el producto punto calculado en la CPU en `double`.
- Criterio de "listo": `n = 1000` → `dot=17946.0`; `n = 16777216` → `dot=301989870.0`. Suma en `double`: en `float`
  la suma de 16 M términos pierde dígitos y la verificación falla por redondeo, no por índices.
- Restricciones: un hilo por elemento; guardia; `cudaGetLastError` + `cudaDeviceSynchronize`; liberar memoria.
- Extensión (quien termina): mide con `cudaEvent_t` el *kernel* solo y la copia D2H de `p`. ¿Qué fracción del total
  es la copia? Anótalo para la S04.

## Antes de cerrar

- [ ] La tabla de Predecir tiene las cinco predicciones **y** lo observado.
- [ ] `make test` pasa en la laptop (o explicas qué caso falla y por qué).
- [ ] Guardaste `resultados_S01_vector_add_<fecha>.csv` del notebook con el modelo de GPU.
- [ ] Bitácora de errores: una entrada por cada diferencia entre predicción y observación.

**Para saber más.** CUDA C Programming Guide, cap. "Programming Model" (*kernels*, *thread hierarchy*) y
"Programming Interface" (*device memory*, *error checking*); Numba, "Writing CUDA Kernels" y "Debugging CUDA Python
with the simulator"; Kirk & Hwu, *Programming Massively Parallel Processors*, cap. 2–3.
