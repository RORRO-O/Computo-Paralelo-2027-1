> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Práctica 6 · publicada el lunes 23 de noviembre de 2026 · Lab 1 martes 24 de noviembre 08:30 · Lab 2 martes 1 de diciembre 08:30 · entrega domingo 6 de diciembre 23:59

# Práctica 6 · Aceleración en GPU con CUDA (Colab/Kaggle)

| | |
|---|---|
| Unidad | V · Programación de GPU (CUDA) |
| Publicación | lunes 23 de noviembre de 2026 (sesión S01) |
| Laboratorio 1 | martes 24 de noviembre, 08:30–10:00, Lab LS4 (sesión S02): Partes A y B |
| Laboratorio 2 | martes 1 de diciembre, 08:30–10:00, Lab LS4 (sesión S05): Parte D, punto de control, mini-defensas |
| Fecha límite | **domingo 6 de diciembre de 2026, 23:59**, en el repositorio del equipo (etiqueta `P6`) |
| Ponderación | **15 % del 3er parcial** (`planeacion/mapa-evaluacion.md`) |
| Equipos | 2–3 integrantes (los de P4 y P5), con responsabilidad individual (mini-defensas y `git log`) |
| Entregables | `practicas/P6/` del repositorio del equipo: `.cu` de las tres partes, espejos Numba de las Partes A y B, `notebook_colab.ipynb` **ejecutado**, `resultados/` (CSV + PNG + `entorno.txt`), `REPORTE.md` ≤ 3 páginas · detalle en `entrega.md` |
| Tiempo estimado | 6–8 h por integrante: pre-lab 20 min · Partes A y B ≈ 55 min (30 en el Lab 1; el resto en casa antes del Lab 2) · Parte C ≈ 3 h · Parte D y reporte ≈ 3 h |
| Rúbrica | `rubrica.md` (100 puntos, cuatro niveles; resumen al final de este documento) |

La GPU vive en la nube (Colab o Kaggle). La **correctitud** de todo lo que entregas se verifica **sin** GPU
(`make test`, simulador de Numba) y nunca depende de la cuota; la **medición** sí requiere GPU y por eso se hace en
sesiones cortas y se guarda enseguida. Si no consigues GPU, `entrega.md` §6 dice qué hacer.

## Objetivos (al terminar podrás…)

1. **Medir** con `cudaEvent_t`, por separado, las copias anfitrión→dispositivo (H2D), el *kernel* y la copia de
   regreso (D2H), y **reportar** el *speedup* con y sin transferencias para una lista de tamaños `n` (medir e interpretar).
2. **Predecir y comprobar**, leyendo un *kernel* por mosaicos completo (`__shared__`, dos `__syncthreads()`, bordes
   cuando `n` no es múltiplo de `TILE`), sus lecturas a memoria global, fases y bloques, y **compararlo** con la versión
   ingenua (comprender / analizar).
3. **Adaptar** ese *kernel* a matrices rectangulares corrigiendo índices, dimensiones y guardias, y **verificarlo** contra
   la CPU con una prueba que distinga "pasa con cuadradas" de "es correcto" (aplicar / evaluar).
4. **Diseñar** un *kernel* propio (histograma y reducción con atómicas, *stencil* de Jacobi con doble búfer, o el ciclo
   caliente de tu proyecto), **justificar** su tamaño de bloque con dos datos y **verificarlo** contra una referencia en
   CPU (crear / evaluar).
5. **Explicar** con números (intensidad aritmética, ocupación, porcentaje de copias) por qué un *kernel* está limitado por
   memoria o por cómputo y a partir de qué `n` conviene la GPU (analizar): es la decisión de diseño de la V3. Todo con la
   GPU asignada y la fecha documentadas y mediciones reproducibles con el protocolo del curso.

Ideas erróneas que esta práctica expone (`docs/metodo/01-marco-pedagogico.md`, Anexo A): **24** (las copias no
cuentan), **25** (`__syncthreads` sincroniza toda la GPU), **26** (cualquier bloque funciona igual), **27** (sin error
⇒ correcto), **33** (el *kernel* terminó cuando regresa la llamada), **34** (no hace falta comprobar `idx < n`), y de
paso **7** (salió bien una vez ⇒ no hay carrera), **22** (un hilo de CUDA = un núcleo) y **32** (una barrera dentro de
un `if`).

## Qué hay en esta carpeta

| Archivo | Qué es | Dónde corre |
|---|---|---|
| `src/common.cuh` | `CUDA_CHECK`, reloj, mediana, memoria *pinned*, descripción de la GPU, ocupación, **esquema del CSV** (`emit_row`) y los generadores de datos de la Parte C | Lo incluyen todos los `.cu` |
| `src/a_vectores.cu` | Parte A: `vector_add` y `saxpy` con medición H2D / *kernel* / D2H por eventos; modos `uno`, `umbral`, `bloque` | GPU; sin GPU solo `nvcc -c` |
| `src/a_vectores_cpu.c`, `src/a_vectores_numba.py` | Referencia secuencial (mismo `checksum`) y espejo de los dos *kernels* en Numba CUDA | `gcc` · GPU o CPU con `NUMBA_ENABLE_CUDASIM=1` |
| `src/a_matmul_tiled.cu` | Parte A: multiplicación `matmul_naive` y `matmul_tiled` (mosaicos) **completas**, con la misma medición; `-DTILE=8\|16\|32` | GPU; sin GPU `nvcc -c` |
| `src/a_matmul_cpu.c`, `src/a_matmul_numba.py` | Referencia secuencial + calculadora del modelo de lecturas; espejo completo en Numba | `gcc` · CUDASIM / GPU |
| `src/b_matmul_rect.cu` | Parte B: `matmul_rect_naive` completa y `matmul_rect_tiled` con `TODO(1)`–`TODO(4)` (índices y dimensiones) | GPU; sin GPU `nvcc -c` |
| `src/b_matmul_rect_cpu.c`, `src/b_matmul_rect_numba.py` | Referencia rectangular (imprime la geometría esperada) y espejo con los **mismos** `TODO`: aquí verificas tu lógica sin GPU | `gcc` · CUDASIM / GPU |
| `src/c_histograma_cpu.c`, `src/c_jacobi_cpu.c` | Referencias de la Parte C (opciones 1 y 2): entrada, salida y valores conocidos | `gcc` |
| `graficar.py` | Parte D: tres PNG + tabla Markdown + resumen a partir del CSV | Laptop o Colab |
| `notebook_colab.ipynb` | Todo lo anterior en celdas: `!nvidia-smi`, `%%writefile`, `!nvcc`, ejecución, medición, CSV | Colab o Kaggle **con GPU** |
| `Makefile` | `all` (compila sin GPU), `run` (requiere GPU), `test`, `test-b`, `sim`, `notebook`, `graficas`, `clean` | Laptop |
| `tests/run_tests.sh` | Verificación sin GPU (< 60 s): compilación, referencias CPU, CUDASIM, gráficas, *notebook* | Laptop |
| `entrega.md`, `rubrica.md`, `resultados/README.md` | Qué/cómo/cuándo se entrega; rúbrica; esquema del CSV | — |

Todos los programas de una misma parte usan la **misma inicialización** (vectores: `a[i] = i % 7`, `b[i] = i % 13`;
matrices, en las Partes A y B: `A[i][j] = ((3i + 7j) mod 11)/11`, `B[i][j] = ((5i + 2j) mod 13)/13`; Parte C:
generadores de `common.cuh`), por lo que el `checksum` es comparable entre CPU, simulador y GPU.

## Cómo ejecutar

### En Google Colab (paso a paso)

1. Entra a <https://colab.research.google.com> con tu cuenta de Google → *Archivo → Subir cuaderno* → elige
   `notebook_colab.ipynb` de esta carpeta (o `!git clone <URL del repositorio de tu equipo>` en una celda y abre el
   cuaderno desde ahí).
2. *Entorno de ejecución → Cambiar tipo de entorno de ejecución → Acelerador de hardware: **T4 GPU*** → *Guardar* →
   *Conectar* (arriba a la derecha). Al conectar debe verse "T4" junto a las barras de RAM y disco.
3. Ejecuta la **celda 1** (`!nvidia-smi`). Debe listar `Tesla T4`. Si dice `command not found` o `No devices were
   found`, no tienes GPU: repite el paso 2 o ve a "Sin GPU". Copia la salida: es tu `entorno.txt` (la sección 9 lo guarda).
4. Ejecuta la celda `ARCH`: detecta `sm_75` (T4). En otra GPU pone la bandera correcta sola.
5. Sección 1: cada celda `%%writefile` escribe un fuente en el disco de la sesión (`Writing a_vectores.cu`). Son
   copias exactas de `src/`. **Si editas un fuente** (por ejemplo, al corregir la Parte B), edítalo en su celda,
   vuelve a ejecutarla y recompila (sección 2); después copia el archivo al repositorio y haz *commit*.
6. Sección 2: compila todo con `nvcc -O2 -arch=sm_75` (y `gcc` para las referencias). Sin errores ni *warnings*.
7. Secciones 3 a 8: ejecútalas en el orden del README (cada celda corresponde a un paso de las Partes A–D). **Antes
   de ejecutar una celda de medición escribe tu predicción.**
8. Sección 9: agrega la fecha al CSV, escribe `entorno.txt`, empaqueta `resultados/` y lo descarga. Súbelo a
   `practicas/P6/resultados/` del repositorio del equipo. El disco de Colab se borra al desconectar: guarda al terminar
   cada bloque de mediciones.

Cuota: Colab gratuito limita la GPU de forma dinámica (unas horas al día) y desconecta tras ~90 min sin actividad. Mide
en sesiones cortas; no dejes el cuaderno conectado "por si acaso". Detalle y capturas descritas:
`herramientas/colab-kaggle.md` §2–§8.

### En Kaggle (paso a paso)

1. Entra a <https://www.kaggle.com> → *Settings → Phone verification* (sin teléfono verificado no hay GPU).
2. *Create → New Notebook* → *File → Import Notebook* → sube `notebook_colab.ipynb`.
3. Panel derecho, *Session options → Accelerator* → **GPU T4 x2** o **GPU P100** (cualquiera; anota cuál). El panel
   muestra la cuota restante (30 h por semana).
4. Ejecuta la celda 1 (`!nvidia-smi`) y la celda `ARCH`: con una P100 detecta `sm_60` y la celda de compilación lo usa.
5. Mismo flujo que en Colab (secciones 1–9). Los archivos quedan en `/kaggle/working/`: pestaña *Output* del panel
   derecho → descargar; para que persistan entre sesiones, *Save Version → Save & Run All*.
6. Desactiva el acelerador (*Accelerator: None*) mientras solo editas código; actívalo para compilar y medir.

### Sin GPU (tu laptop, la máquina del LS4, o Colab sin cuota)

Se verifica la **lógica**, no el tiempo. Con `gcc`, `python3` + `numba` (y `nvcc` si lo tienes):

```bash
make                 # nvcc -c de cada src/*.cu (¿compila?) + referencias CPU con gcc
make test            # todo lo verificable sin GPU (< 60 s): PASS/FAIL/PEND/SKIP por caso
make test-b          # solo la Parte B, estricta: falla hasta que TODO(1)-TODO(4) estén corregidos
make sim             # los espejos Numba bajo el simulador (tamaños pequeños)
NUMBA_ENABLE_CUDASIM=1 python3 src/a_vectores_numba.py 1000 256
NUMBA_ENABLE_CUDASIM=1 python3 src/a_matmul_numba.py 20 16
NUMBA_ENABLE_CUDASIM=1 python3 src/b_matmul_rect_numba.py 20 40 12 16
```

El simulador ejecuta cada hilo de CUDA en Python: usa `n ≤ 10 000` en los vectores y dimensiones `≤ 64` en las
matrices. Sus tiempos no significan nada (él mismo avisa: `Simulator timings are bogus`); lo que sí vale es `grid`,
`hilos_lanzados`, `checksum` y `verificacion`, y además revisa los límites de cada acceso (la GPU no). Si Colab y Kaggle
te niegan GPU, trabaja Predecir, Investigar y las Partes B y C aquí y vuelve a pedir GPU en una o dos horas
(`herramientas/colab-kaggle.md` §9).

---

## Pre-laboratorio (individual, 20 min; en el repositorio antes del martes 24 de noviembre, 08:30)

Archivo `practicas/P6/prelab/<alias>.md` (plantilla en `entrega.md` §3). La pregunta 1 de la recuperación de la S02
lo verifica. Falte o no al laboratorio, se entrega.

**Verificación de GPU (obligatoria).** Antes del martes 24 de noviembre, verifica que obtienes GPU en Colab y en
Kaggle (verificación telefónica hecha), anota el modelo asignado y reporta ese día si no pudiste.

**Preguntas de recuperación (una o dos líneas cada una).**

1. (S01) Un *kernel* 1D procesa `n = 10 000 000` elementos con bloques de 256 hilos. ¿Cuántos bloques lanzas con
   `(n + 255) / 256`? ¿Cuántos hilos quedan ociosos y qué línea impide que escriban fuera del arreglo?
2. (S01, `measure_gpu` de `a_vectores.cu`) Antes de leer los tiempos hay un `cudaEventSynchronize(ev[3])`. ¿Qué
   medirías si lo quitas y por qué? (pista: el lanzamiento de un *kernel* es asíncrono).
3. (S01 y tarea de la S01, ejercicio 3) Un *kernel* 2D calcula `C = A·B` (`n×n`) con un hilo por elemento de `C` y
   bloques de 16×16 hilos. Con `n = 1000`: ¿cuántos bloques por dimensión lanza la malla con redondeo hacia arriba y
   cuántos hilos no escriben en `C`? En esa versión, ¿cuántas veces se lee cada `A[i][k]` de memoria global?
4. (Unidad IV S05, protocolo) Con el modelo `T = latencia + tamaño / ancho de banda`: copiar los `12·n` bytes de
   `saxpy` con `n = 2^24` por PCIe a 5 GB/s tarda ≈ ___ ms; el *kernel* los lee de la memoria de la GPU a 200 GB/s en
   ≈ ___ ms. ¿Por qué el protocolo exige reportar el tiempo **con** y **sin** copias?

**Lectura.** `notas-estudiante.md` de S01 (modelo CUDA) y de S02 (jerarquía de memoria, coalescencia, mosaicos; se
publica el lunes 23 por la tarde; el martes se trabaja con ejemplo resuelto antes de pedir nada);
`herramientas/colab-kaggle.md` §2–§3. Cuando se publique, la de S04 (rendimiento).

**Predicción (se compara en la Parte D; cuenta por estar escrita, no por acertar).** Antes de correr nada:
(a) ¿a partir de qué `n` (potencia de 2 entre `2^10` y `2^26`) la GPU gana a un núcleo de CPU en `saxpy` contando
**solo el *kernel***? (b) ¿y contando las copias H2D/D2H? ("nunca en ese rango" es una respuesta válida).
(c) Con `n = 2^24`, ¿qué *speedup* esperas sin y con copias, y por qué? (d) ¿Qué tamaño de bloque crees que gane en
el barrido 32…1024 y por qué?

---

## Parte A · Guiada: código completo que se ejecuta, se lee y se mide (Lab 1, ≈ 30 min)

Dos programas completos. Los lees, predices, ejecutas, mides y modificas; no escribes *kernels* nuevos. Trabajo en
pareja (conductor/navegante; cambio a los 12 minutos). A.1–A.5 es la suma de vectores y SAXPY (≈ 20 min); A.6–A.9, la
multiplicación de matrices ingenua frente a la de mosaicos (≈ 10 min en el laboratorio, la medición en GPU en casa).

### A.0 · Lee antes de correr (5 min)

En `src/a_vectores.cu`: los dos *kernels* (índice global + guardia), `measure_gpu` (cuatro eventos en el *stream* 0:
H2D → *kernel* → D2H, 1 calentamiento + 5 repeticiones, mediana por tramo), `run_config` (mide la CPU con el mismo
protocolo, verifica contra ella y escribe una fila del CSV con `emit_row`) y los tres modos de `main`:

```
./a_vectores uno    <n> <block> [salida.csv]      una configuración, los dos kernels, imprime checksums
./a_vectores umbral [block=256] [salida.csv]      n = 2^10, 2^12, …, 2^26 con bloque fijo   (Parte D)
./a_vectores bloque [n=2^24]    [salida.csv]      bloque = 32, 64, …, 1024 con n fijo        (Parte D)
```

### A.1 · Predecir (por escrito, sin ejecutar)

| # | Pregunta | Tu predicción | Observado |
|---|---|---|---|
| P1 | `n = 1000`, bloque 256: ¿`grid`? ¿hilos lanzados? ¿ociosos? | | |
| P2 | `n = 10⁷`, bloque 256: ¿`grid`? ¿hilos ociosos? | | |
| P3 | `saxpy` hace 2 FLOP por elemento y `vector_add` 1. ¿El *kernel* de `saxpy` tardará el doble, lo mismo o algo intermedio? ¿Por qué? | | |
| P4 | Con `n = 2^24`, ¿qué porcentaje del tiempo total (H2D + *kernel* + D2H) serán las copias? | | |
| P5 | ¿El `checksum` será **idéntico** en `a_vectores_cpu`, en CUDASIM y en la GPU? ¿Por qué? | | |
| P6 | Bloque de 32 frente a 256 con `n = 2^24`: ¿cuánto más lento el *kernel* (igual, 1.5×, 8×)? ¿Qué dice la columna `ocup%`? | | |
| P7 | `./a_vectores uno 1000 2048`: ¿qué pasa y qué línea lo reporta? | | |

<details><summary>Respuestas (ábrelas después de ejecutar)</summary>

- **P1.** `grid = 4`, 1024 hilos, 24 ociosos (`i = 1000…1023`, detenidos por `if (i < n)`).
- **P2.** `grid = 39 063`, 10 000 128 hilos, 128 ociosos.
- **P3.** Lo mismo (dentro del ruido): los dos mueven `12·n` bytes y están limitados por memoria; 1 o 2 FLOP por 12
  bytes (intensidad 0.08 y 0.17 FLOP/byte) quedan lejísimos del balance de la T4 (≈ 25 FLOP/byte).
- **P4.** Más del 90 % (en una T4 con memoria paginable, 95–98 %): 192 MB por PCIe a ≈ 5 GB/s son ≈ 35–40 ms; el
  *kernel* lee 192 MB a ≈ 200 GB/s en ≈ 1 ms.
- **P5.** Sí: las sumas son enteros pequeños, exactos en `float`, y el `checksum` se acumula en `double`. Si difiere,
  es un error de índices, no de redondeo.
- **P6.** ≈ 1.5–1.8× más lento: con bloques de 32 solo caben 16 bloques por SM = 16 *warps* de 32 posibles (ocupación
  50 %), y la mitad de *warps* oculta peor la latencia de memoria. De 64 en adelante la ocupación es 100 %.
- **P7.** `Error CUDA en a_vectores.cu:112: invalid configuration argument`: el bloque excede 1024 hilos; lo reporta
  el `cudaGetLastError()` de `measure_gpu`, no el lanzamiento (que no regresa error).
</details>

### A.2 · Ejecutar (notebook, sección 3)

Salida **real** sin GPU (CPU en C y simulador, obtenidas con este mismo código en un Xeon de 2.1 GHz):

```
$ ./a_vectores_cpu 1000
a_vectores_cpu: n=1000 reps=5 (1 calentamiento + 5, mediana)
kernel=vector_add n=1000 t_cpu_ms=0.0003 (min 0.0003, max 0.0003) ancho_banda_GB_s=44.4 checksum=8991.0 max_abs_err=0 verificacion=OK
kernel=saxpy n=1000 t_cpu_ms=0.0003 (min 0.0003, max 0.0004) ancho_banda_GB_s=34.3 checksum=11988.0 max_abs_err=0 verificacion=OK

$ NUMBA_ENABLE_CUDASIM=1 python3 src/a_vectores_numba.py 1000 256
kernel=vector_add n=1000 block=256 grid=4 hilos_lanzados=1024 modo=CUDASIM
    t_kernel_ms=0.0000 t_total_ms=142.9411 checksum=8991.0 max_abs_err=0 verificacion=OK      <- tiempos del simulador: no significan nada
kernel=saxpy n=1000 block=256 grid=4 hilos_lanzados=1024 modo=CUDASIM
    t_kernel_ms=0.0000 t_total_ms=201.6947 checksum=11988.0 max_abs_err=0 verificacion=OK

$ ./a_vectores_cpu                 # n = 2^24
kernel=vector_add n=16777216 t_cpu_ms=22.1915 (min 22.0865, max 22.8883) ancho_banda_GB_s=9.1 checksum=150994935.0 max_abs_err=0 verificacion=OK
kernel=saxpy n=16777216 t_cpu_ms=22.6176 (min 22.4532, max 22.9083) ancho_banda_GB_s=8.9 checksum=201326580.0 max_abs_err=0 verificacion=OK
```

Salida **esperada** en la GPU (no ejecutada en el entorno de autoría; órdenes de magnitud para una T4 de Colab con
memoria paginable y la CPU Xeon de 2 vCPU de Colab; tus números dependen de la GPU y del día):

```
$ ./a_vectores uno 16777216 256
GPU: Tesla T4 · 40 SM · 1024 hilos/SM · cc 7.5 · ancho de banda teórico 320 GB/s
memoria del anfitrión: pageable · protocolo: 1 calentamiento + 5 repeticiones, mediana
Experimento 'uno': n = 16777216 (64.00 MB por vector), bloque = 256
kernel                      n bloque    malla  ocup%    H2D ms  kernel ms    D2H ms   total ms     CPU ms   S_kern  S_total    GB/s  verif
vector_add           16777216    256    65536    100   ≈22–28    ≈0.9–1.0   ≈11–14    ≈35–42    ≈18–25    ≈20–25   ≈0.5  ≈200–230  OK
saxpy                16777216    256    65536    100   ≈22–28    ≈0.9–1.0   ≈11–14    ≈35–42    ≈18–25    ≈20–25   ≈0.5  ≈200–230  OK
    vector_add: checksum=150994935.0 max_abs_err=0 (compara con a_vectores_cpu 16777216 y el espejo Numba)
    saxpy: checksum=201326580.0 max_abs_err=0 (compara con a_vectores_cpu 16777216 y el espejo Numba)
Verificación contra la CPU: OK
```

Lo que **sí** debe coincidir exactamente con lo de arriba: `malla`, `checksum`, `max_abs_err=0`, `verif=OK`. Fíjate
en `S_total ≈ 0.5`: **con las copias, la GPU pierde** contra un núcleo de CPU en este problema (idea errónea 24).

### A.3 · Tabla con y sin transferencias (notebook, celda "Tabla de la Parte A")

Corre `./a_vectores uno <n> 256` para `n = 10⁵, 10⁶, 10⁷` y llena, para `saxpy` (y `vector_add` si da tiempo):

| `n` | *kernel* (ms) | H2D + D2H (ms) | total (ms) | CPU (ms) | `S_kern` | `S_total` | copias (% del total) |
|---|---|---|---|---|---|---|---|
| 10⁵ | | | | | | | |
| 10⁶ | | | | | | | |
| 10⁷ | | | | | | | |

Escribe debajo tu **pre-mortem**: "con `n = 10⁷` esperaba que las copias fueran ___ % y resultaron ___ % porque ___".

### A.4 · Barridos para la Parte D (notebook, sección 4; ≈ 2 min en T4)

`./a_vectores umbral 256 resultados_P6.csv` (`n = 2^10…2^26`) y `./a_vectores bloque 16777216 resultados_P6.csv`
(bloque 32…1024). Las filas se **agregan** al CSV con el esquema de `resultados/README.md`. Espejo Numba en la GPU:
`python3 a_vectores_numba.py 16777216 256`; su `t_kernel_ms` debe parecerse al de CUDA C (mismo *kernel*; la primera
llamada compila con JIT y por eso el calentamiento no cuenta).

### A.5 · Investigar (por escrito; va al reporte)

1. Quita mentalmente `cudaEventSynchronize(ev[3])`: ¿qué número saldría en `kernel ms` y por qué (idea errónea 33)?
2. ¿Por qué `cudaGetLastError()` va **después** de la sincronización y qué atrapa que `CUDA_CHECK(cudaMemcpy…)` no?
   Compruébalo con `./a_vectores uno 1000 2048` (P7).
3. Con tus datos del barrido `umbral`: ¿primer `n` con `S_kern > 1`? ¿Primer `n` con `S_total > 1` (o "ninguno")?
   Compara con tu predicción del pre-lab.
4. Con tus datos del barrido `bloque`: ¿qué bloque ganó, cuánto peor fue 32 y qué dice `ocup%`? ¿1024 fue mejor que 256?
5. `GB/s` de la fila `n = 2^24`: ¿qué porcentaje de los 320 GB/s teóricos? ¿A qué se parece ese número en la CPU
   (`ancho_banda_GB_s` de `a_vectores_cpu`)? Esa comparación es el *speedup* real del *kernel*.

### A.6 · Multiplicación por mosaicos: de dónde viene y qué leer (2 min)

En la S02 (hoy, minutos 22–50) viste el ejemplo resuelto y rastreaste en la práctica guiada el *kernel* por mosaicos
con `n = 4, TILE = 2`. `src/a_matmul_tiled.cu` trae **ese mismo *kernel*, completo**, junto a la versión ingenua y
con la medición de la Parte A (cuatro eventos, CSV). No cambias nada: lo lees por sus cinco pasos numerados en los
comentarios (carga cooperativa con cero fuera de rango, primera barrera, `TILE` productos desde memoria compartida,
segunda barrera, guardia de escritura después del ciclo) y predices.

### A.7 · Predecir (por escrito; `n = 1000`, `TILE = 16`)

| # | Pregunta | Tu predicción | Observado (`a_matmul_cpu 1000 16` y la GPU) |
|---|---|---|---|
| Q1 | Lecturas a memoria global de la ingenua y de la de mosaicos (modelo: instrucciones de carga); cociente | | |
| Q2 | ¿Cuántas fases (`n_tiles`) recorre cada bloque? ¿Cuántos bloques tiene la malla y cuántos hilos se lanzan? | | |
| Q3 | ¿Cuántos hilos **no** escriben `C`? En la última fase, ¿qué hilos cargan `0.0f` en `s_A` y cuáles en `s_B`? | | |
| Q4 | ¿Qué protege cada una de las dos `__syncthreads()`? ¿Qué pasaría con `if (row >= n \|\| col >= n) return;` al inicio? | | |
| Q5 | En la T4, ¿cuántas veces más rápida será la de mosaicos que la ingenua con `n = 1024`: 16×, 2–4× o igual? | | |

<details><summary>Respuestas (ábrelas después de ejecutar)</summary>

- **Q1.** Ingenua `2·n³ = 2 000 000 000`; mosaicos `2·n²·⌈n/16⌉ = 126 000 000`; cociente 15.87 (≈ `TILE`). Cada
  elemento de `A` se lee 1000 veces en la ingenua y 63 en la de mosaicos (`a_matmul_cpu` lo imprime).
- **Q2.** `⌈1000/16⌉ = 63` fases; malla `63 × 63 = 3 969` bloques; `3 969 × 256 = 1 016 064` hilos.
- **Q3.** `1008² − 1000² = 16 064` (las 8 filas y 8 columnas sobrantes). En `t = 62`, `a_col = 992 + tx ≥ 1000`
  para `tx ≥ 8`: esos hilos cargan 0 en `s_A`; `b_row = 992 + ty ≥ 1000` para `ty ≥ 8`: cargan 0 en `s_B`; además
  los hilos con `row ≥ 1000` cargan 0 en `s_A` y los de `col ≥ 1000` en `s_B`, en todas las fases.
- **Q4.** La primera: que el mosaico esté **completo** antes de que alguien lo lea (`s_A[ty][k]` lo trajo otro hilo).
  La segunda: que nadie lo **sobreescriba** con la fase `t + 1` mientras otro todavía lee la fase `t`. Las dos
  sincronizan solo al bloque (idea 25). Con `return` al inicio, los hilos que regresan no llegan a las barreras y no
  cargan sus ceros: los demás esperan a hilos que ya no existen y leen posiciones del mosaico que nadie escribió
  (comportamiento indefinido; ideas 32 y 34). Por eso la guardia va en la **escritura**.
- **Q5.** 2–4×, **no** 16×: las cachés L1/L2 absorben buena parte de las lecturas repetidas de la ingenua y la de
  mosaicos pasa a pagar barreras y lecturas de memoria compartida (notas de S02 §3 y de S04 §4).
</details>

### A.8 · Ejecutar (notebook, sección 5)

Salida **real** sin GPU (este Xeon de 2.1 GHz; los tiempos del simulador no significan nada):

```
$ ./a_matmul_cpu 1000 16
a_matmul_cpu: n=1000 tile=16 t_cpu_ms=488.032 (mediana de 5; min 444.557, max 508.964) 4.10 GFLOP/s
  modelo de lecturas a memoria global: ingenua=2000000000 (cada elemento de A: 1000 veces) mosaicos=126000000 (cada elemento de A: 63 veces) cociente=15.87 fases=63
  C[0][0]=209.776321 C[n-1][n-1]=209.748383 checksum=209790146.212784

$ NUMBA_ENABLE_CUDASIM=1 python3 src/a_matmul_numba.py 20 16       # n = 20: no múltiplo de TILE
matmul_naive  n=20 tile=16 malla=2x2 bloque=16x16 fases=2 t_kernel_ms=0.000 (CUDASIM: no representativo)
    error maximo vs NumPy 8.30e-07 (tolerancia 2.0e-03) checksum=1680.790287 verificacion=PASS
matmul_tiled  n=20 tile=16 malla=2x2 bloque=16x16 fases=2 t_kernel_ms=0.000 (CUDASIM: no representativo)
    error maximo vs NumPy 8.30e-07 (tolerancia 2.0e-03) checksum=1680.790287 verificacion=PASS
```

En la GPU: `./a_matmul_tiled_t16 512`, `1000` (no múltiplo de 16) y `1024`, con `OK` en `matmul_naive` y en
`matmul_tiled`. Referencias CPU reales (este Xeon, `-O2`, varían ±15 % entre corridas): `n = 512` → ≈ 53 ms,
`checksum=28157295.924507`; `n = 1000` → ≈ 490 ms, `checksum=209790146.212784`; `n = 1024` → ≈ 545 ms,
`checksum=225260495.531555`. El `checksum` de la GPU coincide en las primeras 6–7 cifras (la GPU usa FMA); el error
máximo por elemento queda bajo la tolerancia `1e-4·n` (nunca compares `float` con `==`, idea 10). **Esperado en una
T4** (no ejecutado aquí), `n = 1024`: ingenua ≈ 300–700 GFLOP/s, mosaicos `TILE = 16` ≈ 1 000–2 500 GFLOP/s; H2D de
8 MB ≈ 1.5–3 ms y D2H de 4 MB ≈ 0.7–1.5 ms, del mismo orden que el *kernel*.

### A.9 · Investigar (por escrito; va al reporte)

1. Cociente de tiempos ingenua/mosaicos con `n = 1024` frente al cociente de lecturas (16): ¿por qué no coinciden?
2. Porcentaje de copias del total en `matmul_tiled` con `n = 1024` y `n = 2048`, frente al de `saxpy` con `n = 2^24`.
   ¿Por qué en la multiplicación baja al crecer `n` y en `saxpy` no? (pista: cuántas operaciones hace cada uno por
   cada byte que cruza el PCIe).
3. Barrido `TILE ∈ {8, 16, 32} × n ∈ {512, 1024, 2048}` (celda `%%bash` de la sección 5; es la tabla de la tarea
   espaciada de la S02 y entra en la Parte D): ¿`TILE = 32` tarda la mitad que `TILE = 16` si hace la mitad de
   lecturas? `-DTILE=64` **compila** y no corre: `Error CUDA en a_matmul_tiled.cu:139: invalid configuration
   argument` (4096 hilos por bloque; idea 26). ¿Por qué lo reporta esa línea y no el lanzamiento?

**Verificación automática de la Parte A:** `make test` (compilación para `sm_75` y `sm_60`, también con `-DTILE=8` y
`-DTILE=32`; referencias CPU; CUDASIM de vectores con `n = 1000` y `n = 37` con bloque 8, y de la multiplicación con
`n = 32` y `n = 20`, mismos `checksum` que la CPU).

---

## Parte B · Semi-guiada: mosaicos con matrices rectangulares (Lab 1, ≈ 25 min + casa)

### B.0 · Qué se te pide y por qué así

En tu V3 (y en casi cualquier problema real) las matrices no son cuadradas: `C = A·B` con `A` de `M×K`, `B` de `K×N`
y `C` de `M×N`. `src/b_matmul_rect.cu` trae dos *kernels*:

- `matmul_rect_naive`, **completa**: tu referencia de índices (cada matriz se recorre con **su** número de columnas).
- `matmul_rect_tiled`: el *kernel* de la Parte A en el que alguien cambió `n` por `M` en todos lados. Está
  "generalizado a medias": las cuatro líneas marcadas `TODO(1)`–`TODO(4)` son **correctas cuando `M = K = N`** y están
  mal con matrices rectangulares. El espejo `src/b_matmul_rect_numba.py` tiene las mismas cuatro.

Lo que **no** tocas: la memoria compartida, las dos `__syncthreads()`, el ciclo de productos y la malla del anfitrión
(`grid((N + TILE − 1)/TILE, (M + TILE − 1)/TILE)`); son lo que leíste y rastreaste en la Parte A. El *tiling* se
presenta hoy, en este mismo laboratorio, y por eso entra completo en la Parte A y no como `TODO`
(`docs/metodo/07-guia-de-autoria.md` §B). Lo que corriges aquí son índices, dimensiones y guardias, que vienen de la S01.

La idea errónea que esta parte expone: **una prueba que pasa no demuestra que el código sea correcto** (ideas 27 y 34).
Con `TODO_LISTO` en 1 y sin corregir nada, la prueba `32×32×32` **pasa**; la de `20×40×12` (tres dimensiones distintas,
ninguna múltiplo de 16) no.

### B.1 · Predecir (por escrito; `M = 20`, `K = 40`, `N = 12`, `TILE = 16`)

(a) ¿Cuántos bloques tiene la malla en `x` y en `y`, y cuántos hilos se lanzan? (b) ¿Cuántas fases necesita cada
bloque? (c) ¿Cuántos hilos **no** deben escribir `C`? (d) Si alguien intercambia `M` y `N` en la malla, ¿qué elementos
de `C` quedan sin calcular y qué error de CUDA aparece? (e) Con el código sin corregir y `TODO_LISTO` en 1, ¿qué
esperas de la prueba `32×32×32` y de la `20×40×12`?

<details><summary>Respuestas</summary>

(a) `x = ⌈12/16⌉ = 1` (columnas de `C`), `y = ⌈20/16⌉ = 2` (filas): 2 bloques, 512 hilos. (b) `⌈40/16⌉ = 3` fases: se
recorre `k = 0 … K−1`. (c) `512 − 20·12 = 272`. (d) Con `x = ⌈20/16⌉ = 2` y `y = ⌈12/16⌉ = 1` la malla cubre las
filas 0–15: las filas 16–19 de `C` (48 elementos) se quedan en cero, **sin ningún error de CUDA**; solo la comparación
con la CPU lo detecta (idea 27). `./b_matmul_rect_cpu 20 40 12 16` imprime la geometría correcta: `malla=1x2`,
`fases=3`, `sin_escritura=272`. (e) `32×32×32` pasa (con `M = K = N`, cada `M` equivocado vale lo que debería); la
`20×40×12` falla: el simulador reporta un acceso fuera de rango; en la GPU sería comportamiento indefinido.
</details>

### B.2 · Corregir `TODO(1)`–`TODO(4)` (en el `.cu` **y** en el espejo Numba)

Las pistas van de más a menos. Cada `TODO` tiene su criterio de verificación (salidas reales del espejo con la solución
y **solo ese** `TODO` sin corregir, `20×40×12`).

| `TODO` | Línea | Pista | Cómo sabes que está bien |
|---|---|---|---|
| **(1)** `load_or_zero` | `(r < rows && c < rows) ? mat[r * rows + c] : 0.0f` | En `matmul_rect_naive`, ¿por qué número se multiplica `row` al leer `A`? Una fila de una matriz de `rows×cols` tiene `cols` elementos, y la columna se compara contra `cols` | Sin (1): `acceso fuera de rango en el kernel -> … index 529 is out of bounds for axis 0 with size 480` (lee más allá de `B`, que tiene `40·12 = 480` elementos) |
| **(2)** fases | `n_tiles = (M + TILE - 1) / TILE` | En `C[row][col] = Σ_k A[row][k]·B[k][col]`, ¿hasta dónde llega `k`? Compara con `fases=` de `b_matmul_rect_cpu` | Sin (2): `error maximo vs NumPy 2.39e+00 … checksum=1609.797292 verificacion=FAIL` (falta la fase `k = 32…39`; sin error de ningún tipo) |
| **(3)** dimensiones en las cargas | `load_or_zero(A, …, M, M)` y `load_or_zero(B, …, M, M)` | ¿Cuántas filas y columnas tiene `A`? ¿Y `B`? | Sin (3): `error maximo vs NumPy 6.10e+00 … checksum=1058.461596 verificacion=FAIL` |
| **(4)** escritura | `if (row < M && col < M) C[row * M + col] = acc;` | Dos defectos | Sin (4): acceso fuera de rango en `C` (`size 240`). Con el índice corregido y la guardia aún en `col < M`, también falla (`index 242 … size 240`): en la GPU esas escrituras caen en la fila siguiente o fuera del arreglo y el resultado puede salir bien "a veces" (idea 7) |

El índice exacto que reporta el simulador cambia entre corridas (el orden de los hilos no es fijo); lo que no cambia
es `verificacion=FAIL`. Cuando termines: `#define TODO_LISTO 1` en el `.cu` y `TODO_LISTO = True` en el `.py`.
Mientras valgan 0/`False`, los programas imprimen `TODO pendiente` y terminan con código 3 sin lanzar el *kernel* por
mosaicos (la ingenua y la CPU sí corren):

```
$ NUMBA_ENABLE_CUDASIM=1 python3 src/b_matmul_rect_numba.py 20 40 12 16      # salida real, versión sin corregir
matmul_rect_naive M=20 K=40 N=12 tile=16 malla=1x2 bloque=16x16 t_kernel_ms=0.000 (CUDASIM: no representativo)
    error maximo vs NumPy 2.03e-06 (tolerancia 4.0e-03) checksum=2011.881224 verificacion=PASS
matmul_rect_tiled TODO pendiente: corrige TODO(1)-TODO(4) y pon TODO_LISTO = True
```

### B.3 · Verificar sin GPU

```bash
make test       # los dos casos de la Parte B salen como PEND mientras TODO_LISTO sea False (no cuentan como FAIL)
make test-b     # estricto: FAIL hasta que TODO(1)-TODO(4) estén corregidos (32×32×32 y 20×40×12) y el .cu tenga TODO_LISTO 1
```

Salidas **reales**. Antes de corregir, `make test`: `PEND  CUDASIM b_matmul_rect_numba 32 32 32 16 tiled: TODO(1)-TODO(4)
pendientes` y lo mismo para `20 40 12 16`; `RESULTADO: PASS` con la nota "Parte B pendiente". `make test-b`: los dos
casos en `FAIL` y `RESULTADO: FAIL`. Con `TODO_LISTO` en 1 y nada corregido, `make test-b`: `PASS  … 32 32 32 16 tiled
-> PASS, checksum 6866.126259 igual a la CPU` y `FAIL  … 20 40 12 16 tiled` (acceso fuera de rango). **Esperado al
corregir** (real, obtenido con la solución de referencia bajo CUDASIM):

```
$ NUMBA_ENABLE_CUDASIM=1 python3 src/b_matmul_rect_numba.py 20 40 12 16 tiled
matmul_rect_tiled M=20 K=40 N=12 tile=16 malla=1x2 bloque=16x16 t_kernel_ms=0.000 (CUDASIM: no representativo)
    error maximo vs NumPy 2.03e-06 (tolerancia 4.0e-03) checksum=2011.881224 verificacion=PASS
```

La verificación es **con tolerancia** (`1e-4·K` por elemento): lo bastante chica para detectar un elemento sin calcular
(`≈ 0.2·K`) y lo bastante grande para el redondeo de la GPU.

### B.4 · En la GPU (notebook, sección 6)

`./b_matmul_rect 512 512 512`, `./b_matmul_rect 1000 600 700` y `./b_matmul_rect 300 2000 900`: `OK` en las dos
versiones. Referencias CPU reales (este Xeon, `-O2`): `512 512 512` → ≈ 50 ms, `checksum=28157295.924507` (el mismo
de la Parte A con `n = 512`); `1000 600 700` → ≈ 190 ms, `checksum=88111843.934845`, `malla=44x63`, `fases=38`;
`300 2000 900` → ≈ 230 ms, `checksum=113286539.085083`, `fases=125`. Anota los GFLOP/s de la ingenua y de la de
mosaicos: **esperado en T4** un cociente del mismo orden que en la Parte A (2–4×). Las filas van al CSV con
`experimento=uno` y `n = M·N`.

---

## Parte C · Diseño propio (entre el 25 y el 30 de noviembre; ≈ 3 h)

Un *kernel* **tuyo**, sin estructura dada, que se verifica contra una referencia en CPU que sí se da. Elige **una**
opción por equipo. Entregas `src/c_<nombre>.cu` (y, si quieres verificarlo sin GPU, `src/c_<nombre>_numba.py`; `make
test` lo corre bajo CUDASIM sin argumentos y exige `verificacion=OK` en ≤ 20 s; `make notebook` agrega los dos al
cuaderno).

**Restricciones comunes (se califican en "Diseño paralelo" y "Correctitud"):**

- Incluye `common.cuh` y usa `CUDA_CHECK` en **toda** llamada, `describe_device`, los generadores de datos de la opción
  (`init_histogram_data` / `init_jacobi_grid`; son idénticos a los de las referencias) y `emit_row` para el CSV
  (experimento `bloque`, una fila por tamaño de bloque, `origen=gpu`).
- Tamaño de bloque por línea de comandos; en el reporte lo justificas con **dos** datos: múltiplo de 32 (¿por qué?) y
  ocupación (`occupancy_pct`) o memoria compartida por bloque. Barrido 32, 64, 128, 256, 512, 1024 en la Parte D.
- Medición con los cuatro eventos (H2D, *kernel(s)*, D2H), 1 calentamiento + 5 repeticiones, mediana, **con y sin
  transferencias**; `T(1)` = la referencia CPU compilada con `-O2` **en la misma máquina** (en el mismo programa o con
  `c_*_cpu` en Colab).
- Verificación contra la referencia en **cada** corrida, incluido un tamaño que no es múltiplo del bloque; el programa
  termina con código 2 si falla. Sin error de CUDA ≠ correcto (idea 27).
- Los datos cruzan PCIe **una vez** de ida y una de regreso (en Jacobi, nada de copiar la malla en cada iteración).
- Nada de bibliotecas que hagan el trabajo (`thrust::reduce`, `cub`, `cupy.bincount` como solución); sí puedes usarlas
  en la extensión opcional para comparar.

### Opción 1 · Histograma de 256 clases + reducción (suma) con atómicas en memoria compartida

- **Entrada.** `n` bytes `data[i] = ((i · 2654435761) mod 2^32) >> 24` (`init_histogram_data`). Por defecto `n = 2^24`.
- **Salida (exacta, son enteros).** Las 256 cuentas, `suma = Σ data[i]`, `hist_checksum = Σ (b+1)·hist[b]`; compara
  las 256 cuentas con `./c_histograma_cpu <n> --volcar hist_cpu.txt` y la suma con la referencia.
- **Restricciones.** Histograma: cada bloque acumula en `__shared__ unsigned int s_hist[256]` con `atomicAdd`, y al
  final vuelca sus 256 cuentas a global con **una** atómica global por clase y bloque (S03 §7); cero atómicas globales
  por elemento en la versión final (puedes conservar la versión "global" como comparación: es un buen dato para el
  reporte). Reducción: árbol en memoria compartida sin divergencia (`tid < s`) + una atómica de 64 bits por bloque, o
  segunda etapa en la CPU; el bloque debe ser potencia de 2 y el programa lo valida. Ciclo con zancada de malla
  (*grid-stride*) para que el número de bloques sea una decisión tuya (p. ej. 8 por SM).
- **Casos de prueba** (tu programa debe imprimir estos valores):

| `n` | bloque | `suma` | `hist_checksum` | Notas |
|---|---|---|---|---|
| 4096 | 256 | 522271 | 526367 | `bin_max=0 cuenta_max=17` |
| 1024 | 256 | 130400 | 131424 | |
| 1031 | 64 | 131432 | 132463 | `n` no múltiplo del bloque |
| 1 | 32 | 0 | 1 | un solo elemento, `hist[0] = 1` |
| 16777216 | 32…1024 | 2139095336 | 2155872552 | `bin_max=18 cuenta_max=65539`; CPU ≈ 14–24 ms (Xeon 2.1 GHz; varía entre corridas) |

- **Esperado en T4** (`n = 2^24`, bloque 256): `histograma_shared` ≈ 0.2–0.4 ms; `histograma_global` ≈ 2–4 ms (la
  contención en 256 direcciones serializa); `reduccion_suma` ≈ 0.1–0.2 ms; H2D de 16 MB ≈ 3 ms (≈ 90 % del total).

### Opción 2 · *Stencil* 2D de Jacobi con doble búfer y convergencia por reducción máxima

- **Entrada.** Malla `alto × ancho` de `float` por filas, fila 0 = 100, resto 0 (`init_jacobi_grid`); frontera fija.
- **Algoritmo (idéntico al de `c_jacobi_cpu.c`).** `out[r][c] = 0.25·(in[r−1][c] + in[r+1][c] + in[r][c−1] + in[r][c+1])`
  en el interior; cada `check_every` iteraciones `max_diff = máx |out − in|` (reducción máxima) y paro si
  `max_diff < tol`; también paro en `max_iter`.
- **Salida.** `iteraciones` (**exacto**), `paro`, `max_diff`, `checksum = Σ malla final` (tolerancia relativa `1e-4`) y
  malla final igual a la de la CPU con error máximo `≤ 1e-3`.
- **Restricciones.** Dos arreglos en el dispositivo e intercambio de **punteros** (doble búfer), sin `cudaMemcpy` de la
  malla entre iteraciones; un hilo por celda con `threadIdx.x` recorriendo columnas (coalescido); la reducción máxima
  en un *kernel* aparte (árbol en compartida + `atomicMax` sobre los bits del `float`, que es válido porque los valores
  son `≥ 0`, o segunda etapa en CPU) y **una** copia de 4 bytes por comprobación; bloque 2D `bx × by` por línea de
  comandos.
- **Casos de prueba** (valores de `c_jacobi_cpu`, reales):

| `alto ancho tol max_iter check_every` | `iteraciones` | `paro` | `checksum` | Notas |
|---|---|---|---|---|
| `10 8 1e-3 50 5` | 50 | `max_iter` | 1751.582337 | malla no múltiplo del bloque |
| `9 7 1e-3 1000 5` | 75 | `convergio` | 1376.600528 | pequeño: cabe en el simulador (≈ 6 s) |
| `24 24 1e-2 3000 10` | 390 | `convergio` | 14275.449805 | el criterio de paro **sí** actúa |
| `64 64 1e-2 1000 10` | 1000 | `max_iter` | 83693.698790 | `max_diff=1.649284e-02` |
| `1024 1024 1e-3 500 10` | 500 | `max_iter` | 1326893.537447 | CPU ≈ 915 ms (Xeon 2.1 GHz, 1 repetición) |

- **Barrido de bloque para la Parte D:** `32×1, 32×2, 32×4, 32×8, 32×16, 32×32` (= 32…1024 hilos); compara además
  `16×16` con `32×8` (mismos 256 hilos, otra forma). **Esperado en T4** (`1024²`, 500 iteraciones): ≈ 60–120 ms de
  *kernel* (0.1–0.2 ms por paso), H2D + D2H ≈ 2–3 ms (≈ 3 %): aquí el *speedup* con copias **sí** se parece al del
  *kernel*, al revés que en la suma de vectores. Con mallas grandes Jacobi converge muy despacio: que mande `max_iter`
  es normal.

### Opción 3 · Portar el *kernel* caliente de tu proyecto

- **Entrada/salida.** Las de tu V1. El ciclo que portas es el que el perfil de H1 señaló como el más caro (≥ 50 % del
  tiempo de la V1); si no lo es, dilo y justifica (Amdahl: ¿cuál es el *speedup* máximo?).
- **Restricciones.** Estructuras aplanadas en un bloque contiguo (nada de `float **` fila por fila); subida una vez y
  bajada una vez; guardia de rango y malla con redondeo hacia arriba; verificación contra la **V1** (no contra la V2)
  con tolerancia declarada, en la misma máquina de Colab; tamaño del problema tal que `T(1) ≥ 1 s`; barrido de bloque
  y un tamaño no múltiplo. El mismo CSV y el mismo `emit_row`. Cuenta también como arranque de la V3 (taller S05),
  pero P6 y proyecto se califican por separado; `REPORTE.md` de P6 puede ser la base de la sección V3.
- **Casos de prueba.** Los de tu V1 (al menos tres tamaños, uno no múltiplo del bloque) y la salida de la V1 como
  referencia; documenta en el reporte qué comparas y con qué tolerancia.

---

## Parte D · Medición e interpretación (Lab 2, martes 1 de diciembre + casa)

Protocolo: `herramientas/protocolo-medicion.md` (`-O2`, correctitud primero, predicción escrita, entorno anotado, 1
calentamiento + 5 repeticiones, mediana, con y sin copias). **La GPU asignada cambia entre sesiones** (T4 en Colab;
T4 o P100 en Kaggle): la celda 1 (`nvidia-smi`) y la fecha van en `entorno.txt` y en el reporte; una sesión = un CSV.

### D.1 · Tabla obligatoria

| Experimento | Qué | Filas del CSV |
|---|---|---|
| Barrido de bloque | `vector_add`, `saxpy` (`n = 2^24`) **y tu *kernel* de la Parte C**, con bloque 32, 64, 128, 256, 512, 1024 | `experimento=bloque` |
| Umbral de tamaño | `vector_add`, `saxpy` con bloque 256 y `n = 2^10 … 2^26` | `experimento=umbral` |
| Mosaicos | `matmul_naive` y `matmul_tiled` (Parte A) con `n = 512, 1024, 2048` y `TILE = 8, 16, 32` | `experimento=bloque` |
| Rectangular (Parte B) | `matmul_rect_naive` y `matmul_rect_tiled` con las tres formas de B.4 | `experimento=uno` |

Cada fila: `t_h2d`, `t_kernel`, `t_d2h`, `t_total`, `t_cpu` (misma máquina, `-O2`), `speedup_kernel`,
`speedup_total`, `ocupacion_pct`, `ancho_banda_gbs`, GPU. El *speedup* se calcula contra el **mejor secuencial**
disponible en esa máquina. Si tu equipo tiene una versión OpenMP del mismo *kernel* (Práctica 4 o V2 del proyecto),
mídela con 4 hilos en la misma máquina (en Colab hay 2 vCPU: decláralo) y agrégala como columna `t_omp4_ms`
(`resultados/README.md`): `graficar.py` dibuja entonces la curva "con copias vs. OpenMP 4 hilos".

### D.2 · Gráficas (`python3 graficar.py resultados/resultados_P6_<fecha>.csv -o resultados`)

`tiempo_vs_bloque.png` (tiempo del *kernel* y total vs. hilos por bloque, un panel por *kernel*, marca el mejor),
`speedup_vs_n.png` (*speedup* sin y con copias vs. `n`, línea `S = 1`) y `transferencias.png` (H2D / *kernel* / D2H
en el `n` mayor, con porcentajes). Ejes rotulados con unidades; el título dice la GPU (o "DATOS NO MEDIDOS" si el CSV
no viene de una GPU). La tabla Markdown que imprime va al reporte.

### D.3 · Interpretación (≤ 250 palabras en total; cada respuesta con un número)

1. **¿Memoria o cómputo?** Calcula la intensidad aritmética de `saxpy`, de `matmul_tiled` (`TILE/4` FLOP/byte con
   mosaicos de `TILE`) y de tu *kernel* de la Parte C; compárala con el balance de una T4 (≈ 25 FLOP/byte) y con el
   ancho de banda que alcanzaste (`ancho_banda_gbs` frente a 320 GB/s). ¿Cuál es *memory-bound* y cuál
   *compute-bound*? ¿Qué optimizarías primero en cada uno?
2. **¿A partir de qué `n` gana la GPU?** Del barrido `umbral`: primer `n` con `S_kern > 1` y primer `n` con
   `S_total > 1` (o "ninguno"); porcentaje de copias en `n = 2^24`. Compara con la predicción del pre-lab y explica el
   desajuste. ¿Qué cambia si los datos ya viven en la GPU (varios *kernels* seguidos, como en Jacobi) o si el
   *kernel* hace muchas operaciones por byte (la multiplicación de la Parte A)?
3. **¿Qué bloque y por qué?** Del barrido de bloque: el mejor y el peor, su cociente, y la ocupación de 32 frente a
   256; ¿1024 ganó? ¿por qué no necesariamente (bloques residentes, registros, `n` pequeño)? Para la multiplicación:
   ¿por qué `TILE = 32` no tarda la mitad que `TILE = 16` si hace la mitad de lecturas?

### D.4 · Punto de control (minuto 38–50 del Lab 2)

Cada equipo proyecta **una** tabla y la explica en 1 minuto: qué bloque ganó, cuánto pesan las copias, si coincide con
su pre-mortem. Tabla aceptable: dos tiempos, mediana de 5 tras calentamiento, `T(1)` declarado, GPU y fecha, ≥ 3
tamaños de bloque múltiplos de 32.

---

## Preguntas de reflexión (individuales; 5–8 líneas cada una, firmadas con tu alias en `REPORTE.md`)

1. **Autoexplicación.** Explica con tus palabras por qué un *kernel* que no reporta ningún error de CUDA y que pasa una
   prueba puede estar mal, y cuáles son las verificaciones distintas que hace esta práctica (lanzamiento, ejecución,
   referencia CPU, una forma de entrada que no es la "cómoda").
2. **Transferencia a la V3.** ¿Qué ciclo de tu V2 se vuelve *kernel* en la V3, qué datos suben una sola vez, qué
   fracción del tiempo total esperas que sean las copias (con un dato de tu Parte A o C) y qué tolerancia usarás para
   compararla con la V1?
3. **Criterio.** ¿Cuándo **no** conviene usar la GPU? Da un `n` y una razón sacados de tus propias mediciones.

## Entregables y formato (resumen; detalle en `entrega.md`)

Repositorio privado del equipo, carpeta `practicas/P6/`: `prelab/<alias>.md` (uno por integrante), `src/` con los
`.cu` (Partes A, B y C) y los espejos Numba (A, B y, si lo hiciste, C), `tests/`, `Makefile`, `graficar.py`,
`notebook_colab.ipynb` **ejecutado con las salidas visibles**, `resultados/` (CSV por sesión, tres PNG,
`entorno.txt`), `REPORTE.md` (≤ 3 páginas, plantilla en `herramientas/plantilla-reporte-practica.md`: entorno con
modelo de GPU y fecha, decisiones, predicción vs. resultado, tabla, gráficas, interpretación, reflexiones, bitácora de
errores con ≥ 3 entradas, reparto de trabajo, declaración de uso de IA). Historial de *commits* con ≥ 3 *commits* de
código por integrante; etiqueta `P6`. Demostración en vivo en el Lab 2; solo graba un video de ≤ 3 min quien no
estuvo en su mini-defensa.

## Rúbrica (resumen; la completa, con los cuatro niveles, en `rubrica.md`)

| Criterio | Peso | Ejemplar, en una línea |
|---|---|---|
| Correctitud y pruebas | 25 | `make test` y `make test-b` en verde sin GPU; casos extra; Parte A `OK` con 512, 1024 y 1000 y Parte B `OK` con las tres formas de B.4 en GPU; Parte C igual a la referencia en todos los casos, incluido uno no múltiplo; un caso de prueba propio |
| Diseño paralelo | 20 | Barreras y guardia de escritura justificadas por lo que fallaría sin ellas; cada dimensión de la Parte B justificada; Parte C con el patrón de la opción, bloque elegido con dos datos, datos por PCIe una vez, sin sincronización sobrante |
| Medición | 20 | CSV completo según el protocolo (barridos de bloque, umbral y mosaicos; dos tiempos; `T(1)` de la misma máquina; GPU y fecha); tres PNG rotuladas; bloque óptimo y umbral con su causa y un dato |
| Interpretación y reflexión | 20 | Las tres preguntas de D.3 con número; comparación con la predicción; por qué mosaicos no da `TILE`×; reflexiones individuales |
| Proceso e integridad | 15 | ≥ 3 *commits* de código por integrante; bitácora ≥ 3; declaración de IA de cuatro líneas; cada integrante explica su línea y una ajena; *notebook* ejecutado |

## Política de IA aplicada a esta práctica (`docs/metodo/05-politica-ia.md`)

| 🟢 Verde (libre) | 🟡 Amarillo (declarar en el reporte) | 🔴 Rojo |
|---|---|---|
| Que te explique eventos, ocupación, coalescencia, memoria compartida o intensidad aritmética con otras palabras; que te genere preguntas de práctica; que te explique un error de `nvcc` o un mensaje de CUDA | Fragmentos de ≤ 10 líneas que después **reescribes y explicas** (p. ej. el bloque de cuatro eventos alrededor de tu *kernel* de la Parte C, o un ciclo *grid-stride*); que revise tu Parte B o C y señale (sin corregir) dónde falta una barrera o una guardia; casos de prueba sugeridos; gráficas a partir de **tus** datos | Pedirle la corrección de `TODO(1)`–`TODO(4)`; pedirle el *kernel* de la Parte C completo o una función completa; inventar o "ajustar" mediciones; pegar texto del reporte sin revisar |

Declaración obligatoria al final de `REPORTE.md` (las cuatro líneas, incluida "qué nos dijo la IA que resultó estar
mal"; si no usaron IA, "No usamos IA en esta entrega", firmado por todos). Prueba de propiedad: cualquier línea que
entregues la explica en voz alta cualquier integrante; en el laboratorio se pregunta.

## Errores comunes y cómo detectarlos

| Síntoma | Primera pregunta que debes hacerte |
|---|---|
| `no CUDA-capable device is detected` o `nvidia-smi: command not found` | ¿Activaste el acelerador antes de ejecutar? (`!nvidia-smi` es la celda 1 por algo) |
| `no kernel image is available for execution on the device` | ¿`-arch` coincide con `compute_cap` de **esta** sesión (T4 → `sm_75`, P100 → `sm_60`)? |
| `kernel ms ≈ 0.00` con `n = 2^24` y GB/s absurdos | ¿Sincronizaste antes de leer el tiempo? El lanzamiento es asíncrono (idea 33) |
| `verificacion=FALLA` sin ningún error de CUDA, error ≈ `0.2·n` por elemento | ¿La malla cubre `n` (redondeo hacia arriba, `x` para columnas y `y` para filas)? ¿Se lanzó el *kernel* (`cudaGetLastError`)? |
| La Parte B pasa con `32×32×32` y falla, o da "acceso fuera de rango", con `20×40×12` | ¿Qué dimensión usaste en cada lugar: filas, columnas, fases, guardia? ¿Probaste una forma con tres dimensiones distintas y no múltiplos de `TILE` (ideas 27 y 34)? |
| `FAIL` con un error máximo grande (de unidades hasta `inf` o `nan`) en la Parte B tras "simplificar" con `if (row >= M \|\| col >= N) return;` al inicio, y `PASS` con `32×32×32` (salida real en el simulador con `20×40×12`: `error maximo vs NumPy 4.59e+00 … verificacion=FAIL`; en la GPU el valor cambia porque se leen posiciones del mosaico que nadie escribió) | ¿Quién carga los ceros del mosaico que esos hilos debían traer? ¿Llegan todos a las dos barreras (ideas 32 y 34)? |
| `FAIL` con `checksum` que **cambia entre corridas** y a veces `PASS` | ¿Hay una barrera de menos o varios hilos escribiendo la misma posición? ¿Cuántas veces lo corriste? Una vez bien no es evidencia (idea 7) |
| El *kernel* "se cuelga" o `unspecified launch failure` | ¿Algún hilo hace `return` antes de un `__syncthreads()`? ¿Hay una barrera dentro de un `if`? |
| `invalid configuration argument` | ¿Cuántos hilos tiene tu bloque? Máximo 1024 (`TILE = 64` → 4096; `block = 2048`) |
| `S_total < 1` aunque `S_kern` sea 20 | ¿Qué fracción del total son las copias? ¿Es un error o es el dato de la Parte A (idea 24)? |
| Histograma con `total_cuentas != n` o suma que varía (Parte C) | ¿Quién más escribe esa posición? ¿Pusiste el histograma local en cero **antes** de la barrera? ¿La reducción supone bloque potencia de 2? |
| Jacobi con `iteraciones` distintas a la CPU | ¿Comprobaste el criterio **exactamente** cada `check_every`? ¿Inicializaste la frontera del segundo búfer? ¿Reinicias el `atomicMax` a 0 antes de cada reducción? |
| El *speedup* de Colab es enorme comparado con tu laptop | ¿Mediste la CPU en Colab (`t_cpu_ms` sale del mismo programa)? Máquinas distintas no se comparan |
| `make test` dice que el *notebook* está desincronizado | ¿Corriste `make notebook` después de editar un fuente de `src/`? |
| El cuaderno "se murió" y el CSV desapareció | ¿Descargaste `resultados/` al terminar cada bloque (sección 9)? |

## Extensión opcional (sin puntos; reconocimiento en la defensa del proyecto)

Elige una y repórtala en ≤ ½ página extra con una medición:

- ***Streams* y memoria fija.** Reserva los vectores de la Parte A con `cudaMallocHost` (modo `pinned` de
  `a_vectores`), parte `n` en 4 trozos y solapa `cudaMemcpyAsync` H2D, *kernel* y D2H en 2–4 `cudaStream_t`. Criterio
  de "listo": `t_total` con *streams* < `t_total` paginable con un solo *stream* para `n = 2^24`, verificación `OK`, y
  una frase que diga qué fracción de la copia quedó oculta (S04 §5).
- **CuPy contra tu *kernel*.** Implementa la misma operación de tu Parte C con CuPy (`cp.bincount` + `cp.sum`, o el
  paso de Jacobi con rebanadas) y compara con tu *kernel*: tiempo del cómputo, tiempo con transferencias y líneas de
  código. Criterio de "listo": tabla con las dos filas y una frase sobre cuándo vale la pena escribir el *kernel*
  (S05 §4: para la V3 cuenta el *kernel* propio, no la llamada a biblioteca).

## Para saber más

- NVIDIA, *CUDA C++ Programming Guide*: "Programming Model" (jerarquía de hilos y memoria), "Shared Memory" (el
  ejemplo de multiplicación por mosaicos), "Device Memory Accesses" (coalescencia), "Events", "Page-Locked Host Memory",
  "Asynchronous Concurrent Execution".
- NVIDIA, *CUDA C++ Best Practices Guide*: "Timing", "Data Transfer Between Host and Device", "Occupancy", "Execution
  Configuration Optimizations", "Shared Memory".
- Numba, *CUDA Python*: "Writing CUDA Kernels" (memoria compartida, `cuda.syncthreads`, atómicas), "Events",
  "Debugging CUDA Python with the simulator".
- Kirk y Hwu, *Programming Massively Parallel Processors*, 4.ª ed.: cap. 4 (*warps*, ocupación), 5 (memoria y
  localidad: mosaicos), 6 (consideraciones de rendimiento), 8 (*stencil*), 9 (histograma y atómicas), 10 (reducción).
