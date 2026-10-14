> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S11 · lunes 26 de octubre de 2026 · 10:30–12:00 · Salón 3208

# Práctica guiada S11 · Jacobi 1D con doble búfer, `reduction(max)` y `simd`

Actividad PRIMM en parejas (conductor teclea, navegante lee y anota; cambian de rol a los 15 minutos).
Duración en clase: 30 minutos (fases Predecir–Modificar) + 10 minutos de transferencia (Crear). Lo que no
termines en clase lo puedes completar en casa: todo es autocontenido.

## Qué hay en esta carpeta

| Archivo | Qué es | Se usa en |
|---|---|---|
| `jacobi1d.c` | *Stencil* 1D de Jacobi (ecuación de calor estacionaria) con doble búfer; modos `seq`, `par`, `simd`. Tiene el `TODO(1)` | Todas las fases |
| `array_reduction.c` | Histograma: `reduction(+:hist[:nbins])` frente a acumuladores locales | Ejemplo resuelto; Investigar |
| `scan.c` | Suma de prefijos en dos fases, verificada con tolerancia | Ejemplo resuelto; Investigar |
| `scan_buggy.c` | El *scan* con `parallel for` directo: **incorrecto a propósito** (carrera) | Investigar (`make tsan`) |
| `vec_kernels.c/.h` | saxpy en tres versiones + un ciclo con dependencia, para leer el reporte del vectorizador | `make report` |
| `saxpy_simd.c` | Mide saxpy con y sin `simd` a `-O2` en cuatro tamaños (L1, L2, L3, RAM) | Investigar |
| `Makefile` | `all`, `run`, `test`, `clean` + `report` (vectorizador) + `tsan` (carrera del *scan*) | — |
| `tests/run_tests.sh` | Verificación automática: cada versión paralela contra la secuencial | `make test` |

Compila y verifica antes de empezar (no debe haber *warnings*):

```bash
make            # gcc -std=c11 -O2 -Wall -Wextra -fopenmp
make test       # 9 PASS y 1 SKIP (el SKIP desaparece cuando completes el TODO(1))
```

Usa como máximo tantos hilos como núcleos físicos tenga tu máquina (`nproc`, o `lscpu`). Con más hilos
que núcleos, las barreras de cada iteración se vuelven lentísimas y las mediciones no sirven.

## Cómo funciona `jacobi1d`

```
./jacobi1d [n] [max_iter] [tol] [modo] [hilos] [reps] [check_every]        modo: seq | par | simd
```

Barra de `n` puntos, `u[0] = 100`, `u[n−1] = 0`, interior inicial 0. Cada iteración: `u_new[i] = 0.5·(u[i−1] + u[i+1])`
para `1 ≤ i ≤ n−2`, y `diff = max |u_new[i] − u[i]|`. Termina cuando `diff < tol` o al llegar a `max_iter`. El
programa **siempre** corre primero la versión secuencial como referencia y luego el modo pedido, cada uno con
1 calentamiento + `reps` repeticiones (mediana), y compara ambos resultados. `check_every` (por defecto 1)
dice cada cuántas iteraciones se calcula el cambio máximo: con 10, nueve de cada diez iteraciones usan un
ciclo que **solo actualiza** (sin reducción). Hasta la fase Modificar déjalo en 1.

## Fase 1 · Predecir (5 min; escribe antes de correr nada)

**P1.** `./jacobi1d 64 100000 1e-6 par 4 3`

| Pregunta | Tu predicción |
|---|---|
| (a) ¿El modo `par` hará el **mismo** número de iteraciones que `seq`? ¿Por qué? | |
| (b) Al converger, ¿cuánto vale `u[n/2]` = `u[32]`? (la solución exacta es una recta de 100 a 0 sobre 63 intervalos) | |
| (c) `max\|u_par − u_seq\|` será: exactamente 0 / pequeña, de redondeo (como en el *scan*) / grande | |
| (d) ¿Quién tarda menos, `seq` o `par` con 4 hilos? ¿Por qué factor? | |

**P2.** `./jacobi1d 100000 2000 1e-6 par 4`

| Pregunta | Tu predicción |
|---|---|
| (a) ¿Converge antes de 2 000 iteraciones? (pista: Jacobi necesita del orden de `n²` iteraciones) | |
| (b) *Pre-mortem*: *speedup* esperado con 2 y con 4 hilos, y por qué | |

**P3.** `make report` compila `vec_kernels.c` con `-fopt-info-vec-*`. Marca cuáles de los cuatro ciclos
crees que GCC vectoriza a `-O2`: `saxpy_plain` ☐ · `saxpy_restrict` ☐ · `saxpy_simd` ☐ · `prefix_dep` ☐.

## Fase 2 · Ejecutar (5 min)

```bash
./jacobi1d 64 100000 1e-6 par 4 3
./jacobi1d 64 100000 1e-6 par 1 3
for t in 1 2 4; do ./jacobi1d 100000 2000 1e-6 par $t; done
make report
```

Llena con **tus** números (mediana que imprime el programa):

| n | hilos | iteraciones seq / par | mediana seq (s) | mediana par (s) | *speedup* | max\|u_par − u_seq\| |
|---|---|---|---|---|---|---|
| 64 | 1 | | | | | |
| 64 | 4 | | | | | |
| 100 000 | 1 | | | | | |
| 100 000 | 2 | | | | | |
| 100 000 | 4 | | | | | |

Compara con tus predicciones: marca cuáles acertaste y cuáles no, y escribe por qué en una línea cada una.

<details><summary>Salida real en la máquina de autoría (Xeon 2.8 GHz, 4 núcleos, L2 4 MiB/núcleo, gcc 13.3). Tus tiempos serán distintos; las iteraciones y el valor de u[n/2], no.</summary>

```
jacobi1d: n=64 max_iter=100000 tol=1.0e-06 modo=par hilos=4 reps=3 check_every=1
  seq   iteraciones=9626     cambio_max=9.995e-07  u[n/2]=49.205948  mediana=0.0006 s (min 0.0006, max 0.0007)
  par   iteraciones=9626     cambio_max=9.995e-07  u[n/2]=49.205948  mediana=0.0330 s (min 0.0316, max 0.0339)
  convergio=si  max|u_par - u_seq|=0.0e+00  speedup=0.02
CHECK OK
```

```
jacobi1d: n=64 max_iter=100000 tol=1.0e-06 modo=par hilos=1 reps=3 check_every=1
  seq   iteraciones=9626     cambio_max=9.995e-07  u[n/2]=49.205948  mediana=0.0012 s (min 0.0011, max 0.0014)
  par   iteraciones=9626     cambio_max=9.995e-07  u[n/2]=49.205948  mediana=0.0049 s (min 0.0047, max 0.0055)
  convergio=si  max|u_par - u_seq|=0.0e+00  speedup=0.24
CHECK OK
```

```
jacobi1d: n=100000 max_iter=2000 tol=1.0e-06 modo=par hilos=1 reps=5 check_every=1
  seq   iteraciones=2000     cambio_max=2.419e-02  u[n/2]=0.000000  mediana=0.2994 s (min 0.2819, max 0.3707)
  par   iteraciones=2000     cambio_max=2.419e-02  u[n/2]=0.000000  mediana=0.2766 s (min 0.2716, max 0.3533)
  convergio=no (llego a max_iter)  max|u_par - u_seq|=0.0e+00  speedup=1.08
CHECK OK
```

```
jacobi1d: n=100000 max_iter=2000 tol=1.0e-06 modo=par hilos=2 reps=5 check_every=1
  seq   iteraciones=2000     cambio_max=2.419e-02  u[n/2]=0.000000  mediana=0.2855 s (min 0.2760, max 0.3303)
  par   iteraciones=2000     cambio_max=2.419e-02  u[n/2]=0.000000  mediana=0.1583 s (min 0.1377, max 0.3405)
  convergio=no (llego a max_iter)  max|u_par - u_seq|=0.0e+00  speedup=1.80
CHECK OK
```

```
jacobi1d: n=100000 max_iter=2000 tol=1.0e-06 modo=par hilos=4 reps=5 check_every=1
  seq   iteraciones=2000     cambio_max=2.419e-02  u[n/2]=0.000000  mediana=0.2892 s (min 0.2793, max 0.3229)
  par   iteraciones=2000     cambio_max=2.419e-02  u[n/2]=0.000000  mediana=0.0881 s (min 0.0752, max 0.1029)
  convergio=no (llego a max_iter)  max|u_par - u_seq|=0.0e+00  speedup=3.28
CHECK OK
```
</details>

## Fase 3 · Investigar (10 min)

**I1. Rastreo del reparto (sin correr).** Con `n = 8` y 2 hilos, `schedule(static)` por defecto reparte
`i = 1..6` en bloques contiguos. Llena la tabla y contesta: ¿algún hilo **lee** en este paso un valor que el otro
hilo **escribe** en este mismo paso? ¿Qué pasaría si `u_new` y `u` fueran el mismo arreglo?

| Hilo | Iteraciones `i` | Lee `u[...]` | Escribe `u_new[...]` |
|---|---|---|---|
| 0 | | | |
| 1 | | | |

**I2. Costo de una región paralela.** Con `n = 64`, cada iteración es una región paralela. Divide la mediana
del modo `par` con 4 hilos entre el número de iteraciones: ¿cuántos microsegundos cuesta cada región? Haz lo
mismo con `seq`: ¿cuántos nanosegundos cuesta cada punto? ¿Cuántos puntos tendría que tener el bloque de cada
hilo para que el trabajo pague el costo fijo de la región?

**I3. ¿Desde qué `n` gana el paralelo?** Corre `./jacobi1d 1000 20000 1e-9 par 4 3` y
`./jacobi1d 10000 2000 1e-9 par 4 3`, agrega las filas a tu tabla y localiza el cruce. Relaciónalo con I2.

**I4. El reporte del vectorizador.** En la salida de `make report`:

- `vec_kernels.c`: ¿coincidió con tu P3? Lee los comentarios del archivo y explica en una línea por qué
  `saxpy_restrict` (sin aliasing posible) **tampoco** se vectoriza a `-O2`.
- `jacobi1d.c`: aparecen `couldn't vectorize loop` para los seis ciclos de `step_seq`, `step_par` y
  `step_simd` (líneas 48–99; son ocho mensajes porque en 72 y 97 el compilador reporta además el ciclo externo
  que genera la directiva). Todavía ninguno se vectoriza, ni siquiera los que solo actualizan (sin
  reducción) y tienen `restrict`. ¿Por qué? (pista: es la misma razón que `saxpy_restrict`; y el ciclo con
  `if (d > max_diff)` además tiene una reducción condicional que el vectorizador no acepta sin la directiva).

**I5. saxpy con y sin `simd`.** Corre `./saxpy_simd`. La columna `S_simd` es el cociente entre el mejor tiempo
escalar (`plain` o `restrict`: generan el mismo código, compruébalo con `objdump -d saxpy_simd`) y el tiempo
`simd`. ¿Por qué el beneficio es mayor cuando los datos caben en L1 que cuando vienen de RAM? ¿Qué
mide la columna GB/s y con qué la compararías para decidir si el ciclo está limitado por memoria?

<details><summary>Salida real en la máquina de autoría</summary>

```
saxpy: y = a*x + y, float, -O2, un solo hilo; 33554432 elementos por repeticion, 5 repeticiones intercaladas, mediana
         n   KB/arr  nivel |   plain_s   restr_s    simd_s |  S_simd |   GB/s
      4096       16     L1 |    0.0231    0.0137    0.0055 |    2.48 |   72.9   max|dif|=0.0e+00
     65536      256     L2 |    0.0215    0.0133    0.0054 |    2.44 |   73.9   max|dif|=0.0e+00
   1048576     4096  L2/L3 |    0.0225    0.0146    0.0100 |    1.46 |   40.3   max|dif|=0.0e+00
  16777216    65536    RAM |    0.0351    0.0388    0.0263 |    1.33 |   15.3   max|dif|=0.0e+00
S_simd = min(plain_s, restr_s) / simd_s (>1: simd mas rapido que el mejor escalar). GB/s: version simd.
CHECK OK
```

Comentario: saxpy hace 2 flops por cada 12 bytes que mueve. Vectorizar multiplica la velocidad de cálculo, no
la de la memoria. Con los datos en L1 el cálculo era el cuello de botella y SIMD ayuda; en RAM el cuello es el
ancho de banda y SIMD cambia poco. (A `-O2` sin `-march=native` GCC usa SSE2: 4 `float` por instrucción.)
</details>

**I6. La carrera del *scan* ingenuo.** Corre `./scan_buggy 1000000 4` dos veces, luego `./scan_buggy 1000000 2`
y por último `make tsan`. ¿Cambió `max|dif|` entre corridas? ¿Y entre 4 y 2 hilos? ¿Por qué `y_bad[n-1]` vale
≈ 1/4 (≈ 1/2) de la suma total? (pista: cada hilo arranca leyendo un `y_bad[i-1]` que otro hilo aún no escribió,
el 0 con que llegó la memoria). Que salga igual dos veces, ¿lo vuelve correcto? ¿Qué par de accesos señala
ThreadSanitizer (lectura de `y_bad[i-1]`, escritura de `y_bad[i]`)? Compara con `./scan 8388608 4`: la
diferencia ahí es 2.873e-07 (6.850e-14 relativo), del tamaño del redondeo, y es la misma en cada corrida.

## Fase 4 · Modificar (10 min)

M1 y M1b son el objetivo mínimo de la clase; M2 y M3 se terminan en casa si no alcanza el tiempo.

**M1 · `TODO(1)`: vectoriza el ciclo interno.** En `step_simd` de `jacobi1d.c` hay dos directivas (la del
ciclo que solo actualiza y la del ciclo con la reducción `max`). Cambia ambas para que repartan el ciclo entre
hilos **y** lo vectoricen, conservando la cláusula de reducción en la segunda; borra las dos líneas marcadas
`/* quitar */`. Antes de medir, predice: con 1 hilo, ¿`simd` será más rápido que `seq`? ¿Por cuánto (saxpy en
L2 dio 2.44×)? ¿Y con 4 hilos frente a `par`?

Verificación: `make report` debe mostrar dos líneas `optimized: loop vectorized using 16 byte vectors` en
`step_simd` (los `missed` que queden en la línea de la directiva son el ciclo externo del reparto entre hilos,
no el ciclo interno); `make test` debe pasar los 10 casos (ya sin SKIP); y

```bash
for t in 1 2 4; do ./jacobi1d 100000 2000 1e-6 simd $t; done
```

debe dar las **mismas** iteraciones y `max|u_simd − u_seq| = 0`. Agrega las filas a tu tabla y compara con
tu predicción.

<details><summary>Salida real con el TODO(1) resuelto (máquina de autoría)</summary>

```
jacobi1d: n=100000 max_iter=2000 tol=1.0e-06 modo=simd hilos=1 reps=5 check_every=1
  seq   iteraciones=2000     cambio_max=2.419e-02  u[n/2]=0.000000  mediana=0.2877 s (min 0.2755, max 0.3430)
  simd  iteraciones=2000     cambio_max=2.419e-02  u[n/2]=0.000000  mediana=0.3067 s (min 0.3036, max 0.3317)
  convergio=no (llego a max_iter)  max|u_simd - u_seq|=0.0e+00  speedup=0.94
CHECK OK
```

```
jacobi1d: n=100000 max_iter=2000 tol=1.0e-06 modo=simd hilos=2 reps=5 check_every=1
  seq   iteraciones=2000     cambio_max=2.419e-02  u[n/2]=0.000000  mediana=0.2982 s (min 0.2775, max 0.3138)
  simd  iteraciones=2000     cambio_max=2.419e-02  u[n/2]=0.000000  mediana=0.1586 s (min 0.1492, max 0.2273)
  convergio=no (llego a max_iter)  max|u_simd - u_seq|=0.0e+00  speedup=1.88
CHECK OK
```

```
jacobi1d: n=100000 max_iter=2000 tol=1.0e-06 modo=simd hilos=4 reps=5 check_every=1
  seq   iteraciones=2000     cambio_max=2.419e-02  u[n/2]=0.000000  mediana=0.2919 s (min 0.2776, max 0.3309)
  simd  iteraciones=2000     cambio_max=2.419e-02  u[n/2]=0.000000  mediana=0.1015 s (min 0.0877, max 0.1203)
  convergio=no (llego a max_iter)  max|u_simd - u_seq|=0.0e+00  speedup=2.88
CHECK OK
```

Compara con `par` (fase Ejecutar): con 1 hilo, 0.2766 s (`par`) frente a 0.3067 s (`simd`); con
4 hilos, 0.0881 s frente a 0.1015 s. **La ganancia es nula**, aunque el reporte dice "loop
vectorized" y los arreglos (800 KB) caben en L2.
</details>

**M1b · ¿Por qué no ganó nada?** El ciclo vectorizado existe, pero no es más rápido. Dos pistas:

1. Ejecuta `objdump -d jacobi1d | grep -B2 -A2 maxpd`. Verás algo como `maxpd (%rsp),%xmm0` seguido de
   `movaps %xmm0,(%rsp)`: GCC 13 implementa la reducción `max` de `simd` con el acumulador **en memoria**
   (en la pila), no en un registro. Cada par de puntos espera a que el anterior se escriba y se vuelva a leer:
   una cadena de dependencia de ~4–5 ciclos por punto, igual que el `maxsd` escalar. El cálculo del promedio
   sí va en vectores; el máximo manda.
2. Quita la reducción de en medio: con `check_every = 10`, nueve de cada diez iteraciones usan el ciclo que
   solo actualiza. Mide `par` y `simd` en igualdad de condiciones:

```bash
./jacobi1d 100000 2000 1e-6 par  1 5 10
./jacobi1d 100000 2000 1e-6 simd 1 5 10
./jacobi1d 100000 2000 1e-6 par  4 5 10
./jacobi1d 100000 2000 1e-6 simd 4 5 10
```

¿Cuánto gana ahora `simd` sobre `par` con 1 hilo? ¿Y con 4? ¿Llega a lo que dio saxpy en L2
(2.44×)? ¿Qué sigue limitando (vuelve a I5: bytes movidos por punto frente a flops por punto)?
Regla para tu bitácora: **"loop vectorized" es una afirmación sobre el código, no sobre el tiempo;
la ganancia se mide, y la limita la dependencia más larga o la memoria, lo que llegue primero.**

<details><summary>Salida real con check_every = 10 (máquina de autoría)</summary>

```
jacobi1d: n=100000 max_iter=2000 tol=1.0e-06 modo=par hilos=1 reps=5 check_every=10
  seq   iteraciones=2000     cambio_max=2.419e-02  u[n/2]=0.000000  mediana=0.1454 s (min 0.1413, max 0.1484)
  par   iteraciones=2000     cambio_max=2.419e-02  u[n/2]=0.000000  mediana=0.1744 s (min 0.1601, max 0.2089)
  convergio=no (llego a max_iter)  max|u_par - u_seq|=0.0e+00  speedup=0.83
CHECK OK
```

```
jacobi1d: n=100000 max_iter=2000 tol=1.0e-06 modo=simd hilos=1 reps=5 check_every=10
  seq   iteraciones=2000     cambio_max=2.419e-02  u[n/2]=0.000000  mediana=0.1670 s (min 0.1481, max 0.2023)
  simd  iteraciones=2000     cambio_max=2.419e-02  u[n/2]=0.000000  mediana=0.1415 s (min 0.1167, max 0.1474)
  convergio=no (llego a max_iter)  max|u_simd - u_seq|=0.0e+00  speedup=1.18
CHECK OK
```

```
jacobi1d: n=100000 max_iter=2000 tol=1.0e-06 modo=par hilos=4 reps=5 check_every=10
  seq   iteraciones=2000     cambio_max=2.419e-02  u[n/2]=0.000000  mediana=0.1536 s (min 0.1494, max 0.1618)
  par   iteraciones=2000     cambio_max=2.419e-02  u[n/2]=0.000000  mediana=0.0728 s (min 0.0680, max 0.0815)
  convergio=no (llego a max_iter)  max|u_par - u_seq|=0.0e+00  speedup=2.11
CHECK OK
```

```
jacobi1d: n=100000 max_iter=2000 tol=1.0e-06 modo=simd hilos=4 reps=5 check_every=10
  seq   iteraciones=2000     cambio_max=2.419e-02  u[n/2]=0.000000  mediana=0.1872 s (min 0.1488, max 0.2433)
  simd  iteraciones=2000     cambio_max=2.419e-02  u[n/2]=0.000000  mediana=0.0368 s (min 0.0358, max 0.0380)
  convergio=no (llego a max_iter)  max|u_simd - u_seq|=0.0e+00  speedup=5.09
CHECK OK
```

Con 1 hilo, `simd` es 1.23× más rápido que `par`; con 4 hilos, 1.98×. Los tiempos de esta máquina
compartida varían entre corridas (mira min y max); por eso se reporta la mediana. Con `n = 4 000 000` (32 MB
por arreglo, en RAM) y la reducción en cada iteración, `par` y `simd` con 4 hilos quedan casi iguales: manda
la memoria.

```
jacobi1d: n=4000000 max_iter=100 tol=1.0e-09 modo=par hilos=4 reps=3 check_every=1
  seq   iteraciones=100      cambio_max=4.847e-01  u[n/2]=0.000000  mediana=0.9080 s (min 0.8805, max 0.9235)
  par   iteraciones=100      cambio_max=4.847e-01  u[n/2]=0.000000  mediana=0.2308 s (min 0.1831, max 0.2510)
  convergio=no (llego a max_iter)  max|u_par - u_seq|=0.0e+00  speedup=3.93
CHECK OK
```

```
jacobi1d: n=4000000 max_iter=100 tol=1.0e-09 modo=simd hilos=4 reps=3 check_every=1
  seq   iteraciones=100      cambio_max=4.847e-01  u[n/2]=0.000000  mediana=0.8261 s (min 0.7725, max 0.8963)
  simd  iteraciones=100      cambio_max=4.847e-01  u[n/2]=0.000000  mediana=0.1992 s (min 0.1867, max 0.2015)
  convergio=no (llego a max_iter)  max|u_simd - u_seq|=0.0e+00  speedup=4.15
CHECK OK
```
</details>

**M2 · Planificación.** En `step_par` cambia la directiva a `#pragma omp parallel for schedule(dynamic) reduction(max:max_diff)`
(chunk por defecto = 1). Predice y mide con **pocas iteraciones y una sola repetición**, porque es muy lento:
`./jacobi1d 100000 200 1e-6 par 4 1` (con los valores por defecto tardaría minutos; medido: 3.9 s frente a
0.03 s de `seq`, cuando `static` con 4 hilos tarda ~0.01 s en esas 200 iteraciones). Prueba después
`schedule(dynamic,4096)` con el mismo comando. Regresa a `static` al terminar. Objetivo verificable: explicar las
dos diferencias de tiempo con lo visto en S08 (costo por *chunk*; iteraciones uniformes).

**M3 · ¿Quién manda, `restrict` o la directiva?** Quita los dos `restrict` de la firma de `step_simd` y corre
`make report`: ¿sigue vectorizado? Ahora haz lo contrario en `step_seq`: déjale `restrict` y agrega solo
`#pragma omp simd reduction(max:max_diff)` (sin `parallel for`). ¿Vectoriza? Conclusión en una línea: qué
decide el compilador y qué decides tú. Deja el archivo como estaba (o con tus cambios, si pasan `make test`).

## Fase 5 · Crear (transferencia, 10 min; termina en casa si hace falta)

Elige **una**:

**C1 · Poisson 1D con fuente.** Copia `jacobi1d.c` a `poisson1d.c` y resuelve `−u'' = 1` en `[0, 1]` con
`u(0) = u(1) = 0`: con `h = 1/(n−1)`, la iteración es `u_new[i] = 0.5·(u[i−1] + u[i+1] + h²)`. La solución
exacta es `u(x) = x(1 − x)/2` (máximo 0.125 en el centro). Criterio de "listo": (1) tu programa imprime el
error máximo contra la solución exacta y es pequeño (≤ 1e-3 con `n = 101`, `tol = 1e-9`); (2) `seq` y `par`
hacen las mismas iteraciones y `max|u_par − u_seq| = 0`; (3) agregas un caso a `tests/run_tests.sh` y un
objetivo al `Makefile`; (4) una tabla con 1, 2 y 4 hilos y una línea de interpretación.

**C2 · *Scan* de máximos (prefijo máximo).** Copia `scan.c` a `scan_max.c` y calcula `y[i] = max(x[0..i])` con
el mismo patrón de dos fases. Criterio de "listo": (1) coincide **exactamente** con la versión secuencial
(¿por qué aquí sí puedes exigir igualdad?); (2) funciona con `n` no divisible entre los hilos; (3) caso en
`run_tests.sh`; (4) una línea: qué cambió respecto a la suma y qué no.

## Si te atoras

- `make test` falla en `jacobi`: ¿escribes en `u` dentro del ciclo? ¿Pusiste `diff` fuera de la reducción?
- `make report` no muestra las dos líneas de `step_simd` como vectorizadas: ¿cambiaste las **dos** directivas?
  ¿La cláusula `reduction(max:…)` sigue en la segunda? Sin ella, `max_diff` queda compartida entre carriles e
  hilos: carrera y resultado incorrecto.
- Tiempos enormes con 4 hilos: ¿tu máquina tiene 4 núcleos físicos? Prueba con 2.
- El modo `simd` imprime `TODO pendiente`: aún no borraste las líneas `/* quitar */`.

## Política de IA en esta práctica

Verde: pedir que te explique un mensaje de `-fopt-info`, qué es una reducción condicional, o por qué el
*scan* necesita dos fases. Amarillo (declarándolo): pedir ≤ 10 líneas para el `Makefile` o el caso de prueba
de la fase Crear. Rojo: pedirle la directiva del `TODO(1)` o el programa de la fase Crear completo. En la S12
se te preguntará "¿qué hace esta línea y qué pasa si la quito?".
