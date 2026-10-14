> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S04 · lunes 30 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# Práctica guiada S04 · ¿Cuánto tarda de verdad mi kernel? (PRIMM)

Trabajas en parejas: **conductor** (teclea) y **navegante** (lee el README, anota predicciones y resultados).
Cambio de roles a los 15 minutos (el profesor lo anuncia). Cada pareja entrega al final una hoja con las
predicciones, la tabla observada y las respuestas de *Investigar*.

## Qué vas a hacer

1. Medir un kernel con eventos de CUDA y ver por qué el cronómetro de la CPU miente si no sincronizas.
2. Medir **por separado** las copias anfitrión→dispositivo (H2D), el kernel y las copias dispositivo→anfitrión (D2H).
3. Barrer el tamaño de bloque (32 … 1024) y explicar el resultado con *warps* y ocupación.
4. Barrer el tamaño del problema `n` y encontrar a partir de qué `n` la GPU gana, con y sin copias.
5. Cambiar a memoria fija (*pinned*) y ver un ejemplo mínimo de *streams*.
6. Graficar todo desde un CSV y, en *Crear*, aplicar el mismo protocolo a tu kernel de la Práctica 6.

## Archivos

| Archivo | Qué es |
|---|---|
| `medir_eventos.cu` | Ejemplo resuelto: cuatro formas de medir el mismo `saxpy` (una está mal a propósito) |
| `bench_gpu.cu` | Barridos `bloque` y `umbral`; mide H2D, kernel y D2H con cuatro eventos; agrega filas a un CSV |
| `pinned_streams.cu` | Panorama: paginable vs. *pinned* vs. *pinned* + *streams* |
| `bench_numba.py` | Espejo en Numba CUDA de los dos kernels; verificable sin GPU con `NUMBA_ENABLE_CUDASIM=1` |
| `bench_cpu.c` | Referencia en CPU; genera un CSV de ejemplo (GPU **modelada**, no medida) para ensayar las gráficas |
| `graficar.py` | Lee el CSV y produce `tiempo_vs_bloque.png` y `speedup_vs_n.png` + resumen en pantalla |
| `notebook_colab.ipynb` | Todo lo anterior en celdas para Colab/Kaggle (generado con `generar_notebook.py`) |
| `Makefile`, `tests/run_tests.sh` | `make test` verifica todo sin GPU en menos de un minuto |

## Cómo se corre

**En Colab o Kaggle (lo que haces en clase).** Sube `notebook_colab.ipynb`, activa la GPU (Entorno de ejecución →
Cambiar tipo de entorno → T4) y ejecuta las celdas en orden. Si Kaggle te da una P100, cambia `sm_75` por
`sm_60` en la celda de compilación. Las celdas equivalen a:

```bash
nvcc -O2 -arch=sm_75 -o medir_eventos medir_eventos.cu
nvcc -O2 -arch=sm_75 -o bench_gpu bench_gpu.cu
nvcc -O2 -arch=sm_75 -o pinned_streams pinned_streams.cu
./medir_eventos                                  # ejemplo resuelto
./bench_gpu bloque 16777216 resultados.csv       # barrido de bloque, n = 2^24
./bench_gpu bloque 4096 resultados.csv           # barrido de bloque, n pequeño
./bench_gpu umbral 256 resultados.csv            # barrido de n con bloque 256, memoria paginable
nsys profile --stats=true ./bench_gpu bloque 16777216 perfil.csv
./bench_gpu umbral 256 resultados.csv pinned     # Modificar: memoria pinned
./pinned_streams                                 # Modificar: streams
python3 graficar.py resultados.csv .
```

**En tu máquina sin GPU (para preparar o repasar).** `make` compila los `.cu` a objeto con `nvcc -c` y la
referencia de CPU; `make test` corre todo lo verificable sin GPU; para ensayar las gráficas:

```bash
make
./bench_cpu                                        # tabla de tiempos de tu CPU
./bench_cpu --csv-ejemplo resultados_ejemplo.csv   # CSV con t_cpu medido y GPU MODELADA (origen=modelo)
python3 graficar.py resultados_ejemplo.csv .
NUMBA_ENABLE_CUDASIM=1 python3 bench_numba.py      # espejo Numba en el simulador
```

El CSV de ejemplo sirve para probar el flujo, **no** para reportar: sus columnas de GPU salen de un modelo de
costo escrito en `bench_cpu.c` (constantes `MODEL_*`) y el título de las gráficas lo dice.

## Esquema del CSV (lo produce `bench_gpu`; tu kernel de P6 debe producir el mismo)

```
experimento,kernel,n,block,grid,ocupacion_pct,memoria,t_h2d_ms,t_kernel_ms,t_d2h_ms,t_total_ms,t_cpu_ms,speedup_kernel,speedup_total,ancho_banda_gbs,origen,dispositivo
```

`t_*` son medianas de 5 repeticiones tras 1 calentamiento. `speedup_kernel = t_cpu / t_kernel`;
`speedup_total = t_cpu / (t_h2d + t_kernel + t_d2h)`. `ancho_banda_gbs = 12·n bytes / t_kernel`.

---

## P · Predecir (escríbelo antes de ejecutar; 5 minutos)

Datos: `saxpy` y `vector_add` sobre vectores `float` de `n = 2^24` (64 MB cada uno) en una T4
(40 SM, 1024 hilos residentes por SM, 16 bloques residentes por SM, ancho de banda teórico 320 GB/s, PCIe 3.0 x16).

| # | Pregunta | Tu predicción | Razón en una línea |
|---|---|---|---|
| P1 | En `medir_eventos`, ¿cuál de las cuatro formas dará el número más pequeño? ¿Es correcto ese número? | | |
| P2 | ¿Qué porcentaje del total (H2D + kernel + D2H) serán las copias con memoria paginable? (< 50 %, 50–90 %, > 90 %) | | |
| P3 | Barrido de bloque con `n = 2^24`: ¿cuál será el **mejor** tamaño de bloque y cuál el **peor**? | | |
| P4 | ¿El bloque de 1024 será el más rápido? ¿Por qué sí o por qué no? | | |
| P5 | Barrido de bloque con `n = 4096`: ¿las diferencias entre bloques serán mayores o menores que con `2^24`? | | |
| P6 | Experimento `umbral`: ¿a partir de qué `n` gana la GPU contando **solo el kernel**? (2^10, 2^14, 2^18, 2^22, nunca) | | |
| P7 | ¿Y contando **las copias**? (2^14, 2^18, 2^22, 2^26, nunca en el rango) | | |
| P8 | Al cambiar a memoria *pinned*: ¿cambia el tiempo del kernel? ¿cambia el de las copias? ¿cuánto (×1, ×2, ×10)? | | |

## R · Ejecutar

1. Secciones 1–3 del cuaderno (GPU, fuentes, compilación). Anota el modelo de GPU que te tocó y la fecha.
2. `./medir_eventos`. Compara con P1 y P2. Copia la tabla de cuatro filas a tu hoja.
3. `./bench_gpu bloque 16777216 resultados.csv` y `./bench_gpu bloque 4096 resultados.csv`. Compara con P3–P5.
4. `./bench_gpu umbral 256 resultados.csv`. Compara con P6 y P7. Marca en la tabla la primera fila donde
   `S_kern > 1` y la primera donde `S_total > 1` (si existe).

Salida esperada en una T4 (órdenes de magnitud; **no ejecutada en el entorno de autoría**, cambia con la GPU y el día):

```
kernel              n bloque    malla  ocup%    H2D ms  kernel ms    D2H ms   total ms     CPU ms   S_kern  S_total    GB/s
saxpy        16777216     32   524288     50   ≈25–50    ≈1.3–1.7   ≈12–25     ≈40–75     ≈15–40    ≈10–25  ≈0.3–0.6  ≈120–150
saxpy        16777216     64   262144    100   ≈25–50    ≈0.9–1.1   ≈12–25     ≈40–75     ≈15–40    ≈15–40  ≈0.3–0.6  ≈180–220
saxpy        16777216    256    65536    100   ≈25–50    ≈0.8–1.0   ≈12–25     ≈40–75     ≈15–40    ≈15–45  ≈0.3–0.6  ≈200–250
saxpy        16777216   1024    16384    100   ≈25–50    ≈0.85–1.0  ≈12–25     ≈40–75     ≈15–40    ≈15–45  ≈0.3–0.6  ≈200–240
```

Con `n = 4096` todos los bloques tardan entre ≈3 y ≈8 µs y el orden cambia de una corrida a otra: ahí se
mide el costo de lanzar, no el trabajo.

Salida real de la referencia de CPU en el entorno de autoría (4 núcleos, `gcc -O2`), para que tengas una
escala de la columna `CPU ms`:

```
         n       add ms     add GB/s     saxpy ms   saxpy GB/s
      1024       0.0006         19.4       0.0006         19.8
     16384       0.0109         18.1       0.0127         15.4
   1048576       0.8338         15.1       0.5430         23.2
  16777216      18.4982         10.9      18.3445         11.0
```

## I · Investigar

Responde en la hoja, con números de tu tabla:

1. **Línea por línea.** En `bench_gpu.cu`, función `measure_gpu`: ¿entre qué dos eventos queda el kernel?
   ¿Por qué `cudaGetLastError()` va después de `cudaEventSynchronize(ev[3])` y no inmediatamente después del
   lanzamiento? (Pista: ¿qué errores aparecen al lanzar y cuáles al ejecutar?)
2. **Copias.** Con `n = 2^24`, ¿qué fracción del total son H2D + D2H? ¿Coincide con P2? ¿Cuántas veces más
   lento es copiar un byte por PCIe que leerlo desde la memoria de la GPU? (Divide `GB/s` del kernel entre
   `bytes copiados / t_h2d`.)
3. **Bloque.** Llena la tabla de ocupación con la columna `ocup%` que imprime el programa y explica la fila de 32:

   | bloque | warps por bloque | bloques residentes por SM (máx. 16 en T4) | warps residentes | ocupación |
   |---|---|---|---|---|
   | 32 | 1 | 16 | 16 de 32 | 50 % |
   | 64 | | | | |
   | 256 | | | | |
   | 1024 | | | | |

   ¿Por qué 1024 no mejora a 256 aunque la ocupación sea la misma? Escribe dos razones (bloques disponibles
   para repartir al final; registros por hilo: 65 536 por SM ÷ 1024 hilos = 64 por hilo como máximo).
4. **Umbral.** Entre dos filas consecutivas de `umbral`, `n` se multiplica por 4. ¿Por cuánto se multiplica
   `kernel ms` al pasar de 2^10 a 2^12? ¿Y de 2^22 a 2^24? ¿Qué domina en cada extremo (lanzamiento o bytes)?
5. **nsys.** Corre la celda de `nsys profile --stats=true`. En `cuda_gpu_kern_sum` localiza `saxpy_kernel` y
   compara su `Avg (ns)` con tu `kernel ms`. En `cuda_gpu_mem_time_sum` compara `[CUDA memcpy Host-to-Device]`
   con `H2D ms`. En `cuda_api_sum`, ¿qué llamada consume más tiempo de **CPU** y por qué no es el kernel?
   Si `nsys` no existe en tu entorno, la celda lo dice: te quedas con los eventos, que miden lo mismo con menos detalle.

Formato esperado de `nsys --stats=true` (aproximado; **no ejecutado aquí**; las cifras dependen de la GPU):

```
[5/8] Executing 'cuda_api_sum' stats report
 Time (%)  Total Time (ns)  Num Calls   Avg (ns)   ...  Name
     ≈70      ≈2 000 000 000        84  ≈24 000 000      cudaMemcpy
     ≈20        ≈600 000 000        36  ≈17 000 000      cudaMalloc
      ≈1         ≈30 000 000        84     ≈360 000      cudaEventSynchronize
[6/8] Executing 'cuda_gpu_kern_sum' stats report
 Time (%)  Total Time (ns)  Instances  Avg (ns)  Med (ns)  ...  Name
     ≈50        ≈40 000 000         36  ≈1 100 000  ...       saxpy_kernel(float, const float *, const float *, float *, int)
     ≈50        ≈40 000 000         36  ≈1 100 000  ...       vector_add_kernel(const float *, const float *, float *, int)
[7/8] Executing 'cuda_gpu_mem_time_sum' stats report
 Time (%)  Total Time (ns)  Count  Avg (ns)  ...  Operation
     ≈65      ≈2 500 000 000    144  ≈17 000 000     [CUDA memcpy Host-to-Device]
     ≈35      ≈1 300 000 000     72  ≈18 000 000     [CUDA memcpy Device-to-Host]
```

Columnas que importan: **Time (%)** (quién domina), **Total Time** y **Instances/Count** (cuántas veces),
**Avg/Med** (lo comparable con tus eventos), **Name/Operation** (qué cosa).

## M · Modificar

1. **Memoria *pinned*.** Escribe P8 si no lo hiciste. Corre `./bench_gpu umbral 256 resultados.csv pinned`.
   Compara columna por columna con la corrida paginable: ¿qué cambió y qué no? ¿Apareció el cruce `S_total > 1`?
   ¿En qué `n`?
2. **Streams.** Corre `./pinned_streams`. Predice primero el orden de A, B y C. Después prueba
   `./pinned_streams 16777216 8` y `./pinned_streams 16777216 2`. ¿Más *streams* siempre ayuda? ¿Qué limita?
3. **Un bloque que no es múltiplo de 32.** En `bench_gpu.cu`, agrega `48` y `96` a `BLOCK_SIZES` (línea
   `static const int BLOCK_SIZES[]`), recompila y corre `bloque 16777216`. Predice antes: ¿48 se parecerá más a
   32 o a 64? Explica con el aviso que imprime el programa y con la columna `ocup%`.
4. (Si te sobra tiempo) En `measure_gpu`, cambia el orden a H2D → **D2H** → kernel. ¿Qué pasa con la
   verificación? Es la forma de comprobar que las pruebas detectan un error de orden.

Salida esperada de `pinned_streams` en una T4 (órdenes de magnitud; **no ejecutada aquí**):

```
Versión (H2D + kernel + D2H)               mediana ms        vs. A
A. paginable, síncrona                        ≈40–80         1.00x
B. pinned, síncrona                           ≈18–22       ≈2–4x
C. pinned + streams, asíncrona                ≈12–17       ≈3–6x
Verificación contra CPU: A OK · B OK · C OK
```

## M · Crear (transferencia: tu kernel de la Práctica 6)

Aplica el protocolo a **tu** kernel de la Práctica 6 (el que entregas el domingo 6 de diciembre a las 23:59):

1. Copia tu `.cu` a una celda `%%writefile` del cuaderno. Rodea cada fase con los mismos cuatro eventos que
   `measure_gpu` (H2D, kernel, D2H); 1 calentamiento + 5 repeticiones; mediana; verificación contra tu
   versión de CPU.
2. Escribe una fila por configuración en un CSV **con el mismo encabezado** que el de arriba (así `graficar.py`
   lo lee sin cambios). Cubre: tres `n` distintos con bloque fijo y un barrido de bloque con `n` fijo.
3. Calcula la intensidad aritmética de tu kernel (FLOP por byte leído+escrito desde memoria global) y
   decide si está limitado por memoria o por cómputo en una T4 (balance ≈ 25 FLOP/byte).

**Criterio de "listo":** CSV con ≥ 9 filas, dos PNG generadas por `graficar.py`, una frase que diga cuál es el
mejor bloque y por qué, una que diga a partir de qué `n` conviene la GPU **con copias**, y una que clasifique tu
kernel (*memory-bound* / *compute-bound*) con el número que lo sustenta. Esto mismo es lo que se revisa mañana,
martes 1 de diciembre a las 08:30, en el Lab 2 de la Práctica 6, y es la Parte D de su reporte.

## Errores que vas a ver (y la primera pregunta que debes hacerte)

| Síntoma | Primera pregunta |
|---|---|
| `nvcc: command not found` o `nvidia-smi` falla | ¿Activaste la GPU en el tipo de entorno de ejecución? |
| `no kernel image is available for execution on the device` | ¿Qué capacidad de cómputo imprimió la celda 2? ¿Compilaste con `sm_75` en una P100? |
| `too many resources requested for launch` | ¿Cuántos registros usa cada hilo × 1024 hilos? ¿Cabe en 65 536? |
| `S_kern` enorme y `S_total < 1` | ¿Dónde empezaban los datos? ¿Cuál de los dos números es honesto para tu caso? |
| Todos los bloques "iguales" con `n = 4096` | ¿Cuánto tarda lanzar un kernel vacío? ¿Qué fracción de 5 µs es cómputo? |
| La primera repetición tarda el doble | ¿Contaste el calentamiento? ¿Qué hace el `r = -1` del ciclo? |
| `nsys` muestra `cudaMemcpy` arriba de todo en `cuda_api_sum` y piensas que es el kernel | ¿Esa tabla mide tiempo de GPU o de CPU? ¿Dónde están los kernels? |

## Política de IA en esta práctica

Verde: pedir que te expliquen qué es la ocupación o cómo funciona un *stream*. Amarillo: pedir un fragmento
(≤ 10 líneas) para rodear tu kernel de P6 con eventos, siempre que lo reescribas y lo expliques. Rojo: pedirle
los números de la tabla o "mejorar" tus mediciones. En la mini-defensa de mañana se pregunta "¿qué hace esta
línea?" sobre cualquier línea de tu medición.
