> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Práctica 5 · Simulación distribuida con MPI · publicada jueves 5 de noviembre de 2026 · Lab 1 martes 10 de noviembre 08:30 · Lab 2 martes 17 de noviembre 08:30 · Lab LS4 (Edificio 3) · entrega domingo 22 de noviembre de 2026, 23:59

# Práctica 5 · Simulación distribuida con MPI

| | |
|---|---|
| Unidad | IV · Programación en memoria distribuida (MPI) |
| Publicación | jueves 5 de noviembre de 2026, 10:30 (U4·S01, salón 3208) |
| Pre-laboratorio | individual, en el repositorio del equipo **antes del martes 10 de noviembre, 08:30** |
| Laboratorio 1 | martes 10 de noviembre, 08:30–10:00, Lab LS4 (U4·S03): Partes A y B |
| Laboratorio 2 | martes 17 de noviembre, 08:30–10:00, Lab LS4 (U4·S05): Partes C y D, punto de control, mini-defensas |
| **Fecha límite** | **domingo 22 de noviembre de 2026, 23:59** (etiqueta `P5-entrega`) |
| Ponderación | **15 % del 3.er parcial** (`planeacion/mapa-evaluacion.md`) |
| Equipos | 2–3 integrantes (los del proyecto), con responsabilidad individual (mini-defensas y prueba de propiedad) |
| Entregables | `practicas/P5/` en el repositorio del equipo: código, `Makefile`, `tests/`, `resultados/` (CSV + PNG), `REPORTE.md` ≤ 3 páginas con declaración de IA, reparto de trabajo y bitácora de errores (detalle en `entrega.md`) |
| Tiempo estimado | 6–8 horas por integrante (dos laboratorios + trabajo en casa) |

Documentos de esta carpeta: este enunciado · `entrega.md` (qué, cómo, cuándo) · `rubrica.md` (100 puntos) ·
`src/` (código base) · `tests/run_tests.sh` · `escalado.sh`, `graficar.py`, `modelo.py` (Parte D) · `resultados/README.md`.

## Objetivos (al terminar, podrás…)

1. **Distribuir** un arreglo y una matriz entre procesos con `MPI_Scatter`/`MPI_Scatterv` y **reunir** resultados con
   `MPI_Gather`/`MPI_Gatherv`, manejando el caso `n % p ≠ 0` con el reparto por bloques con residuo (aplicar).
2. **Elegir y justificar** entre `MPI_Reduce`, `MPI_Bcast` y `MPI_Allreduce` según quién tiene el dato antes y quién lo
   necesita después, y explicar por qué una colectiva la llaman todos los procesos (analizar).
3. **Diseñar** una simulación por descomposición de dominio (calor 1D) con celdas fantasma, comunicación no bloqueante
   (`MPI_Isend`/`MPI_Irecv`/`MPI_Waitall`) y una decisión de paro global con `MPI_Allreduce`, verificada contra la
   versión secuencial (crear).
4. **Medir** escalabilidad fuerte y débil con el protocolo del curso (1, 2, 4 procesos y 8 sobre-suscrito, declarado),
   **producir** el CSV y las gráficas, y **explicar** dónde deja de escalar con el modelo `T_com = α + m/β` alimentado
   con tu propio *ping-pong* (analizar / evaluar).
5. **Explicar** una decisión de diseño con un dato medido (p. ej., solapar cómputo y comunicación, o cada cuántos
   pasos revisar la convergencia) y **comparar** el resultado con tu predicción (evaluar).

## Pre-laboratorio (individual, 20 min; se entrega antes del Laboratorio 1)

Un archivo `practicas/P5/prelab/prelab-<tu alias>.md` en el repositorio del equipo, **antes del martes 10 de
noviembre a las 08:30**, faltes o no a la sesión. La pregunta 1 de la recuperación de ese día lo verifica.

**Lectura previa (15 min).** `unidades/U4-memoria-distribuida/S01_2026-11-05_modelo-spmd/notas-estudiante.md` (SPMD,
rango, reparto por bloques con residuo), `S02_2026-11-09_punto-a-punto/notas-estudiante.md` §4–§6 (qué promete
`MPI_Send`, interbloqueo, cuánto cuesta un mensaje) y `S03_2026-11-10_colectivas-lab1/notas-estudiante.md` §1–§2
(las siete colectivas: quién llama y quién recibe). Sin IA: son del tipo que aparece en el Examen 3.

**Cuatro preguntas (una línea cada una).**

1. Con `n = 13` elementos y `p = 5` procesos, reparto por bloques con residuo: ¿cuántos elementos recibe cada rango
   y en qué índice global empieza el rango 3?
2. `MPI_Scatter(data, 3, MPI_DOUBLE, local, 3, MPI_DOUBLE, 0, MPI_COMM_WORLD)` con `n = 13` y `p = 4`: ¿cuántos
   elementos viajan en total y qué pasa con los demás?
3. Cada rango tiene `double local_max`. Escribe la única llamada MPI con la que **todos** terminan con el máximo
   global en `global_max`. ¿Qué cambiarías para que solo lo tuviera el rango 0?
4. Dos procesos vecinos intercambian su celda de frontera: ambos hacen `MPI_Send` y luego `MPI_Recv`. ¿Es correcto?
   Nombra dos formas de hacerlo seguro.

**Predicción (se compara en la Parte D; se copia tal cual en el reporte).** "Para el producto matriz-vector de la
Parte B (`m = n = 2000`, 200 productos, una sola distribución de la matriz) espero con 4 procesos un *speedup* de
___ porque ___." Piensa en qué viaja una vez (la matriz: 32 MB) y qué viaja en cada producto (el vector `x` y el
resultado `y`: 16 KB cada uno), y en cuántas operaciones hace cada rango por producto.

<details><summary>Para autocalificarte después del Laboratorio 1 (no antes)</summary>

1. Tamaños 3, 3, 3, 2, 2 (`13 / 5 = 2`, residuo 3: los rangos 0–2 llevan uno más). El rango 3 empieza en el índice
   `3·2 + min(3, 3) = 9`.<br>
2. Viajan `3 × 4 = 12`; el elemento 12 no se envía a nadie y nadie lo cuenta. `Scatter` exige bloques iguales; con
   residuo se usa `Scatterv` (Parte A).<br>
3. `MPI_Allreduce(&local_max, &global_max, 1, MPI_DOUBLE, MPI_MAX, MPI_COMM_WORLD);` Para solo el 0:
   `MPI_Reduce(&local_max, &global_max, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);`.<br>
4. No es seguro: funciona si la implementación copia el mensaje (chico) y se interbloquea si no (grande; idea errónea
   17). Seguro: `MPI_Sendrecv`; `MPI_Irecv` + `MPI_Isend` + `MPI_Waitall`; o alternar el orden por paridad del rango.
</details>

## Qué hay en `src/` y cómo se compila

| Archivo | Parte | Estado | Qué hace |
|---|---|---|---|
| `common.h` | todas | completo | Datos deterministas `p5_value(i)`, `block_partition`, estadísticos de tiempo (mediana, mín, máx), línea `TIME,...` que lee `escalado.sh` |
| `a1_hello_rank.c` | A | completo | Hola con rango y máquina; el rango 0 reúne rangos y nombres con `MPI_Gather` |
| `a2_stats_seq.c`, `a2_stats_mpi.c` | A | completo | Suma, máximo, promedio y varianza de `n` datos: secuencial y repartido con `Scatter`/`Scatterv` + `Reduce` + `Bcast` + `Allreduce`; verificación contra la secuencial |
| `b_matvec_seq.c`, `b_matvec_mpi.c` | B | **`TODO(1)`–`TODO(5)`** | `y = A·x` por filas: `Scatterv` de filas, `Bcast` de `x`, `Gatherv` de `y`, cronómetro con `Reduce(MAX)`; verificación con tolerancia |
| `c_heat_common.h`, `c_heat_seq.c`, `c_heat_mpi.c` | C | **esqueleto** | Calor 1D: problema, condición inicial y verificación compartidos; la secuencial completa; en la MPI escribes `heat_solve_mpi` |
| `c_primes_seq.c`, `c_primes_mpi.c` | C (alternativa) | **esqueleto** | Conteo de primos en `[a, b]`: la secuencial completa; en la MPI escribes `count_primes_mpi` (cíclico y bloques) |
| `d_pingpong.c` | D | completo | Latencia α y ancho de banda β entre dos procesos; ajuste a `T_com = α + m/β` |
| `../escalado.sh`, `../graficar.py`, `../modelo.py` | D | completos | Escalabilidad fuerte y débil (CSV del protocolo + PNG); modelo de costo (n*, n_E) |

```bash
make                 # gcc / mpicc -std=c11 -O2 -Wall -Wextra; no debe salir ningún warning
make run-a           # Parte A con NP=4 (cambia con make run-a NP=2)
make test            # todas las pruebas; los TODO pendientes salen como PEND (no cuentan como FAIL)
make test-b          # Parte B en modo estricto: PEND cuenta como FAIL (es lo que corres en el Lab 1)
make test-entrega PARTE_C=heat    # lo que corre el profesor al calificar (o PARTE_C=primes)
make clean
```

- Si `mpirun` dice *not enough slots*, hace falta `--oversubscribe`: ya va en `MPIRUN_FLAGS` del `Makefile`. Con
  MPICH ese *flag* no existe: `make MPIRUN_FLAGS= test`. Sobre-suscribir no invalida las pruebas, pero sí las
  mediciones: la Parte D lo etiqueta (`mpi_oversub`).
- Como root (contenedor): `export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1`. El `Makefile`,
  `tests/run_tests.sh` y `escalado.sh` lo hacen solos.
- Un programa colgado se mata con `Ctrl+C`. Para no vigilarlo: `timeout 10 mpirun -np 4 ./src/c_heat_mpi 100 100; echo "codigo $?"`
  (124 = lo mató `timeout`). En la Parte C vas a necesitarlo.
- Todos los programas aceptan el tamaño por línea de comandos y tienen valores por defecto que corren en ≤ 5 s en
  una laptop de 4 núcleos. Todas las salidas de este documento son corridas reales en la máquina de autoría (VM de
  4 núcleos **compartida**, gcc 13.3, Open MPI 4.1.6, `-O2`): los valores se repiten en tu máquina; los tiempos y el
  orden de las líneas de distintos rangos, no.

---

## Parte A · Guiada: repartir, combinar, verificar (Laboratorio 1, minutos 50–62; se termina en casa)

Trabajo en parejas o equipo, con roles conductor/navegante. **Escribe cada predicción antes de ejecutar.** Las
colectivas que ves aquí son las del ejemplo resuelto de la sesión (`S03/ejemplo-resuelto.md`): este es el código
completo para leer, predecir y verificar; en la Parte B las vas a escribir tú.

### A.1 · Hola con rangos (3 min)

**Predecir.** `mpirun -np 3 ./src/a1_hello_rank`: ¿cuántas líneas `hola desde…` salen? ¿En qué orden? ¿Qué imprime
después el rango 0 y por qué ese sí está en orden?

**Ejecutar.** Corrida real:

```
$ mpirun -np 3 ./src/a1_hello_rank
hola desde el rango 1 de 3 en vm
hola desde el rango 2 de 3 en vm
hola desde el rango 0 de 3 en vm
rango 0 reunio con MPI_Gather 3 rangos: 0 1 2
  rango 0 corre en vm
  rango 1 corre en vm
  rango 2 corre en vm
```

**Investigar.** Las tres primeras líneas salen en el orden en que el sistema programa los procesos (otra corrida da
otro orden); las últimas cuatro las imprime **un** proceso con lo que reunió: `MPI_Gather` acomoda en `all_ranks[k]`
lo que envió el rango `k`, aunque los mensajes lleguen revueltos. Pregunta: `MPI_Gather` está escrita una vez en el
código; con `-np 3`, ¿cuántos procesos la ejecutan? ¿Qué pasaría si estuviera dentro de `if (rank == 0)`? (Lo viste
colgarse hoy con `matvec_bcast_buggy`; idea errónea 18).

### A.2 · Estadísticos de un arreglo repartido (9 min en clase + 20 en casa)

El rango 0 genera `n` datos y los reparte; cada rango calcula sobre su bloque; las colectivas combinan. Lee
`src/a2_stats_mpi.c` (los cinco pasos numerados dentro del ciclo) antes de predecir.

**Predecir** (tabla en tu cuaderno o en `prelab/`; llena "Predicción" antes de correr):

| # | Comando o pregunta | Predicción | Observado |
|---|---|---|---|
| P1 | `mpirun -np 4 ./src/a2_stats_mpi 100003 auto 2 --trace`: ¿qué reparto elige `auto` y cuántos elementos recibe cada rango? | | |
| P2 | En esa corrida, ¿qué imprime el rango 2 en `tras Reduce: suma=`? ¿Y en `tras Allreduce: max=`? (`global_sum` se inicializa en −1 antes del `Reduce`) | | |
| P3 | ¿Por qué el promedio hace falta en **todos** los rangos y cómo llega (paso 4 del código)? | | |
| P4 | `mpirun -np 4 ./src/a2_stats_mpi 100003 scatter 2` (Scatter **forzado** con `n % p = 3`): ¿termina? ¿qué dice la verificación? ¿cuántos elementos se contaron? | | |
| P5 | `mpirun -np 5 ./src/a2_stats_mpi 7 auto 2 --trace`: elementos por rango | | |
| P6 | La suma distribuida y la secuencial, ¿darán **exactamente** el mismo `double`? ¿Qué tolerancia usa la verificación y por qué? | | |

**Ejecutar.**

```bash
./src/a2_stats_seq 100003 2
mpirun -np 4 ./src/a2_stats_mpi 100003 auto 2 --trace
mpirun -np 4 ./src/a2_stats_mpi 100003 scatter 2; echo "codigo $?"
mpirun -np 5 ./src/a2_stats_mpi 7 auto 2 --trace
```

Corrida real con `-np 4`, `n = 100003` (las líneas `[rango k]` salen en cualquier orden):

```
[rango 2] recibio 25001 elementos (indices globales 50002..75002); suma_local=19.277652 max_local=0.999776 | tras Reduce: suma=-1.000000 | tras Bcast: promedio=-3.116733e-04 | tras Allreduce: varianza=3.337363e-01 max=0.999994
[rango 1] recibio 25001 elementos (indices globales 25001..50001); suma_local=59.680592 max_local=0.999910 | tras Reduce: suma=-1.000000 | tras Bcast: promedio=-3.116733e-04 | tras Allreduce: varianza=3.337363e-01 max=0.999994
[rango 3] recibio 25000 elementos (indices globales 75003..100002); suma_local=-183.426385 max_local=0.999994 | tras Reduce: suma=-1.000000 | tras Bcast: promedio=-3.116733e-04 | tras Allreduce: varianza=3.337363e-01 max=0.999994
[rango 0] recibio 25001 elementos (indices globales 0..25000); suma_local=73.299879 max_local=0.999862 | tras Reduce: suma=-31.168262 | tras Bcast: promedio=-3.116733e-04 | tras Allreduce: varianza=3.337363e-01 max=0.999994
a2_stats_mpi: n=100003 p=4 reparto=scatterv (n % p = 3; elementos por rango: 25001 25001 25001 25000) reps=2
global: suma=-3.116826238465e+01 max=9.999935195177e-01 promedio=-3.116732736483e-04 varianza=3.337363414084e-01
verificacion (rango 0 recorre el arreglo completo): OK; dif. rel. suma=1.2e-13; max igual; dif. rel. varianza=3.8e-15
nota: la suma distribuida y la secuencial suman en distinto orden; por eso se compara con tolerancia
```

La secuencial imprime `suma=-3.116826238466e+01`: difiere de la distribuida en la última cifra (`…465` contra
`…466`): mismo conjunto de números, otro orden de suma, otro redondeo (idea errónea 10). Por eso `make test` compara
con tolerancia relativa `1e-9`.

Scatter forzado con residuo (termina, pero **mal**, y el programa lo detecta):

```
a2_stats_mpi: n=100003 p=4 reparto=scatter (n % p = 3; elementos por rango: 25000 x 4) reps=2
ADVERTENCIA: Scatter forzado con n % p = 3: solo viajaron 100000 de 100003 elementos; los ultimos 3 no se contaron
verificacion (rango 0 recorre el arreglo completo): FALLA; dif. rel. suma=1.6e-03; max igual; dif. rel. varianza=3.3e-05
codigo 1
```

Con `-np 5` y `n = 7`: `elementos por rango: 2 2 1 1 1` (`7 / 5 = 1`, residuo 2).

**Investigar** (tabla de rastreo; con `n = 10^7` y `p = 4` para los bytes):

| Colectiva (línea del código) | Quién tiene el dato **antes** | Quién lo tiene **después** | Bytes que viajan |
|---|---|---|---|
| `MPI_Scatterv` (paso 1) | rango 0: `n` doubles | cada rango: su bloque | |
| `MPI_Reduce` (paso 3) | cada rango: 1 double | | |
| `MPI_Bcast` (paso 4) | | | |
| `MPI_Allreduce` ×2 (paso 5) | | | |

1. ¿Por qué `global_sum` vale −1 en los rangos 1–3 después del `Reduce` y el promedio sí vale lo mismo en todos
   después del `Bcast`? ¿Qué dice eso de la memoria de cada proceso? (idea errónea 16).
2. Los pasos 3 y 4 juntos (`Reduce` + `Bcast`) hacen lo mismo que una sola colectiva. ¿Cuál? ¿Por qué el programa no
   la usó para la suma y sí para la varianza y el máximo?
3. En la tabla, ¿qué colectiva mueve casi todos los bytes? Corre `./src/a2_stats_seq` y `mpirun -np 4 ./src/a2_stats_mpi`
   (tamaño por defecto, `n = 10 000 003`) y compara las medianas. ¿Da 4× menos tiempo con 4 procesos? ¿Qué parte del
   trabajo se hace una vez y no se reparte? (Es la regla del cierre de hoy: el costo de repartir los datos se cuenta).
4. Un rango con **cero** elementos (`-np 3`, `n = 2`): ¿qué valor aporta al máximo con `MPI_MAX`? Busca `-HUGE_VAL` en
   el código. ¿Y si aportara `0.0`?

**Modificar** (verificable con `make test-a`, que debe seguir en verde):

- **M1.** Sustituye el par `MPI_Reduce` + `MPI_Bcast` del promedio por **una** `MPI_Allreduce`. Criterio: misma salida,
  una colectiva menos, y puedes decir qué rango tiene `global_sum` después.
- **M2.** Agrega el mínimo global (`MPI_MIN`) y haz que lo impriman **todos** los rangos con `--trace`. Criterio: el mismo
  valor en las `p` líneas; ninguna llamada MPI nueva dentro de un `if (rank == …)`.
- **M3.** Haz que la raíz sea el **último** rango (`size - 1`): quien genera los datos y verifica. Criterio: `verificacion … OK`
  con `-np 1, 2, 4`. (Idea errónea 19: que el 0 sea el maestro es costumbre, no regla).

**Crear** (en casa; va en tu repositorio como `src/a3_histograma_mpi.c`, opcional pero recomendado como ensayo de la
Parte B). Histograma de los `n` datos en 8 intervalos iguales de `[-1, 1)`: reparto con `Scatterv`, conteo local en
un arreglo de 8 enteros, combinación con **una** colectiva (pista: `count = 8`) y verificación contra un conteo
secuencial en la raíz. Criterio de "listo": los 8 conteos suman `n` y coinciden con la secuencial para `n = 100003`
con `-np 1, 3, 4`.

**Verificación automática de la Parte A:** `make test-a` → `10 PASS, 0 FAIL`.

---

## Parte B · Semi-guiada: producto matriz-vector distribuido por filas (Laboratorio 1, minutos 62–80; se termina en casa)

`y = A·x` con `A` de `m × n` guardada por filas. El rango 0 tiene `A` y `x`. Cada rango recibe un bloque de filas
contiguas (reparto con residuo), calcula su bloque de `y`, y la raíz lo reúne. El producto se repite `iters` veces
con el mismo `x` (como en un método iterativo): la matriz se reparte **una** vez, el vector viaja en **cada**
producto. Es el programa de `S03/ejemplo-resuelto.md` con tres diferencias: filas desiguales (`Scatterv`/`Gatherv`),
matriz rectangular y verificación con tolerancia.

Abre `src/b_matvec_mpi.c`. La secuencial `src/b_matvec_seq.c` está completa y es la referencia. Hay cinco `TODO`,
con pistas que van de más a menos, y una máscara `todo_pending` al inicio del archivo: mientras tenga banderas, el
programa imprime `TODO pendiente: TODO(1) TODO(2) …` y termina sin calcular nada (`make test` lo reporta
como `PEND`; `make test-b` lo cuenta como `FAIL`). **Al terminar cada TODO, quita su bandera de la máscara.** Si la
quitas sin resolverlo, la verificación dice `FALLA`: eso sí es `FAIL`.

| TODO | Qué completas | Pista | Criterio de verificación |
|---|---|---|---|
| **1** | Cuentas y desplazamientos del reparto por filas: `row_counts`, `row_displs` (en filas) y `elem_counts`, `elem_displs` (en elementos = filas × `n`) | Es `block_partition(m, size, k, &c, &f)` de `common.h` en un ciclo sobre `k`; la fórmula está en el comentario | `mpirun -np 3 ./src/b_matvec_mpi 301 203 3` imprime `filas por rango: 101 100 100`; con `-np 4`, `76 75 75 75` |
| **2** | `MPI_Scatterv` de las filas de `A` a `A_local` | La firma completa y el papel de cada argumento están en el comentario; las cuentas van en **elementos** | Con `--trace`, `A_local[0]` de cada rango es el primer elemento de su primera fila global (rango 1 con `-np 3`: `A[101·203]`) |
| **3** | `MPI_Bcast` de `x` en cada producto | Una línea. La llaman todos | Con `--trace`, `x[0]=0.666100` en **todos** los rangos |
| **4** | `MPI_Gatherv` de `y_local` en `y` (raíz) | Es el inverso del TODO(2), con cuentas en **filas**. Sin firma: la viste en `matvec_scatterv.c` (S03, M3) y está en el estándar | `verificacion contra y secuencial (rango 0): OK` y el mismo `checksum` que `./src/b_matvec_seq 301 203 3` |
| **5** | El tiempo de la corrida es el del rango más lento: `slowest` y `slowest_dist` deben ser el máximo entre rangos | Una colectiva con una operación. Ya la usaste hoy para el tiempo | El tiempo que reporta `-np 4` no es el del rango 0 (compruébalo imprimiendo `elapsed` por rango con `--trace`) |

En clase: TODO(1)–(3) y `make test-b` al minuto 80 (anota `PASS/FAIL` en la cabecera del *exit ticket*). En casa: TODO(4)–(5).

Salida real de la solución de referencia:

```
$ ./src/b_matvec_seq 301 203 3
checksum=-5.717465116246e+01 y[0]=-3.442092077168e+00 y[m-1]=-7.286957186063e+00
$ mpirun -np 3 ./src/b_matvec_mpi 301 203 3
b_matvec_mpi: m=301 n=203 p=3 iters=3 reps=3; filas por rango: 101 100 100
checksum=-5.717465116246e+01 y[0]=-3.442092077168e+00 y[m-1]=-7.286957186063e+00
verificacion contra y secuencial (rango 0): OK; max |dif| = 0.0e+00
$ mpirun -np 4 ./src/b_matvec_mpi 3 50 2 --trace
[rango 3] filas globales 3..2 (0 filas, 0 elementos de A); A_local[0]=0.000000 x[0]=0.666100
...
b_matvec_mpi: m=3 n=50 p=4 iters=2 reps=3; filas por rango: 1 1 1 0
verificacion contra y secuencial (rango 0): OK; max |dif| = 0.0e+00
```

Aquí `max |dif| = 0`: cada `y[i]` lo calcula un solo rango con el mismo ciclo que la secuencial, así que el
redondeo es idéntico. La tolerancia (`1e-12`) sigue ahí porque el estándar no obliga a que sea así.

Preguntas de la Parte B (van al reporte, 3–5 líneas en total):

- El rango 3 con `m = 3` recibe **cero** filas y aun así llama a `Scatterv`, `Bcast` y `Gatherv`. ¿Qué pasaría si lo
  saltara con `if (my_rows > 0)`? (Idea errónea 18; pruébalo con `timeout 10`.)
- La línea `tiempo del Scatterv de A (una vez…)`: con `m = n = 2000` e `iters = 1`, ¿qué fracción del total es?
  ¿Y con `iters = 200`? ¿Qué le dice eso a quien va a diseñar la V2 de su proyecto?

**Verificación:** `make test-b` → `6 PASS, 0 FAIL` (compilación + cinco casos).

---

## Parte C · Diseño propio: simulación distribuida (entre el 10 y el 17 de noviembre; Laboratorio 2)

Elige **una** de las dos opciones. La primera es la principal (es la que usa el modelo de costo de la Parte D tal
cual); la segunda es la alternativa permitida. El equipo declara en `REPORTE.md` cuál entregó.

### C.1 · Ecuación de calor 1D con celdas fantasma (opción principal)

**Problema** (`src/c_heat_common.h`): barra de longitud 1 con `n` celdas interiores y fronteras fijas en 0 °C;
condición inicial fija: pulso gaussiano de 100 °C centrado en `x = 0.5`. Cada paso de tiempo, con dos búferes:

```
u_new[i] = u[i] + R · (u[i-1] − 2·u[i] + u[i+1]),   R = 0.25
```

Se detiene cuando `max_i |u_new[i] − u[i]| < tol` (revisado cada `check_every` pasos) o al llegar a `max_iter`. Con
`tol = 0` corre exactamente `max_iter` pasos: así se mide escalabilidad con trabajo fijo. Es el *stencil* de Jacobi
de S04/S11 con otra regla de actualización: mismas celdas fantasma, mismo doble búfer, misma decisión global.

**Entrada.** `mpirun -np P ./src/c_heat_mpi [n] [max_iter] [tol] [check_every] [reps] [--verify] [--print] [--trace]`,
los mismos argumentos y valores por defecto que `./src/c_heat_seq`. Se exige `n ≥ p`.

**Salida esperada.** Idéntica a la secuencial para los mismos argumentos: mismo número de `iteraciones`, mismo
`checksum` y mismas sondas `u[centro]`, `u[n/4]` (tolerancia `1e-10`; con el esquema compartido sale bit a bit).
Corridas reales de `c_heat_seq` (tu `c_heat_mpi` debe dar lo mismo con cualquier `p`):

```
$ ./src/c_heat_seq 1003 500 0 1 1          -> iteraciones=500 convergio=0  checksum=1.779543666292e+04 u[centro]=9.760843567600e+01 u[n/4]=2.531722926318e-01
$ ./src/c_heat_seq 31 100000 1e-6 1 1      -> iteraciones=4702 convergio=1 checksum=8.416301304499e-03 u[centro]=4.134663698007e-04
$ ./src/c_heat_seq 31 100000 1e-6 7 1      -> iteraciones=4704 convergio=1 checksum=8.375823300203e-03 (check_every=7: se revisa cada 7 pasos y se para en un múltiplo de 7)
```

**Lo que ya está escrito** en `src/c_heat_mpi.c` (no lo cambies: `tests/` y `escalado.sh` dependen de ello):
lectura de argumentos, reparto por bloques con residuo (`block_partition`), condición inicial local
(`heat_init_local`: fronteras físicas en los halos de las orillas), medición con el protocolo (`Barrier` + `Wtime` +
`Reduce(MAX)`, calentamiento + repeticiones), reconstrucción **una** vez al final con `MPI_Gatherv`, verificación
contra `heat_solve_seq` con `--verify`, impresión y línea `RESULT`. **Lo que escribes tú:** `heat_solve_mpi` (el
contrato está en el comentario) y lo que necesites alrededor. No se da la estructura interna.

**Restricciones.**

1. Halos (celdas fantasma) de una celda a cada lado, intercambiados con `MPI_Irecv`/`MPI_Isend`/`MPI_Waitall`
   (no `Send`/`Recv` bloqueantes ni `Sendrecv`). Entre publicar y `Waitall` no se lee el halo ni se escribe la celda
   que se está enviando.
2. Decisión de paro **global** con `MPI_Allreduce(MPI_MAX)` cada `check_every` pasos: todos los rangos ejecutan el
   mismo número de pasos.
3. **Sin** `Gather`/`Allgather` de la malla completa en cada paso. La malla se reconstruye una vez, al final (ya está).
4. Condición inicial y esquema: los de `c_heat_common.h` (usa `heat_step_range`, así tu resultado es bit a bit igual).
5. Verificación contra la secuencial: `--verify` en verde y `make test-c` en verde con `p = 1, 2, 3, 4`, `n % p ≠ 0`,
   `check_every > 1` y `n = p`.
6. Decisión de diseño que debes **medir y reportar** (rúbrica, criterio 2): ¿qué celdas puedes calcular **antes** del
   `Waitall`? Reporta la línea `por paso: computo=…, comunicacion=…` (o tu equivalente) con y sin ese solape, y
   también con `check_every = 1` y `10`.

**Casos de prueba** (`make test-c`): `n = 1003`, 500 pasos, `p = 1..4` · `n = 31`, `tol = 1e-6` (paro por tolerancia:
4702 pasos) con `p = 3` · lo mismo con `check_every = 7` (4704 pasos) y `p = 4` · `n = 4`, `p = 4` (una celda por rango)
· `n = 3`, `p = 4` rechazado con mensaje. El profesor agrega 2–3 casos parecidos (otros `n`, `tol` y `check_every`).

Pistas, de más general a más concreta. Ábrelas solo si llevas más de 30 minutos atorado en ese punto.

<details><summary>Pista 1 · vecinos y halos</summary>
Vecino izquierdo <code>rank − 1</code>, derecho <code>rank + 1</code>; en las orillas, <code>MPI_PROC_NULL</code>: enviar
no hace nada y recibir no toca el búfer, así el mismo código sirve para todos los rangos y el halo de la orilla conserva
la frontera física que puso <code>heat_init_local</code>. Lo que viaja hacia la derecha (tu última celda) llega al halo
izquierdo del vecino; usa una etiqueta por dirección y la misma en el <code>Isend</code> y en el <code>Irecv</code> que lo recibe.
</details>

<details><summary>Pista 2 · el orden dentro de un paso</summary>
Publica las dos recepciones, luego los dos envíos (<code>&u[n_local]</code> hacia la derecha, <code>&u[1]</code> hacia
la izquierda). Las celdas <code>2..n_local−1</code> no tocan ni los halos ni las celdas que se están enviando: calcúlalas
con <code>heat_step_range(u, u_new, 2, n_local − 1, check)</code> mientras viajan los mensajes. <code>MPI_Waitall(4, reqs,
MPI_STATUSES_IGNORE)</code>. Después, las celdas <code>1</code> y <code>n_local</code>. Cuidado con <code>n_local ≤ 2</code>:
no hay interior. Luego intercambia punteros; mira cómo <code>heat_solve_seq</code> devuelve el resultado en <code>u</code>.
</details>

<details><summary>Pista 3 · la decisión de paro</summary>
<code>heat_step_range</code> devuelve la diferencia máxima de su tramo cuando <code>want_diff</code> es 1; quédate con el
máximo de tus tramos. Cada <code>check_every</code> pasos:
<code>MPI_Allreduce(&diff, &gdiff, 1, MPI_DOUBLE, MPI_MAX, MPI_COMM_WORLD)</code> y <code>if (gdiff &lt; tol) break;</code>
en <strong>todos</strong> los rangos con el mismo <code>gdiff</code>. Si cada rango comparara su <code>diff</code> local,
pararían en pasos distintos y el <code>Gatherv</code> final se quedaría esperando (pruébalo con <code>timeout 10</code>).
</details>

### C.2 · Conteo de primos con reparto cíclico y balance de carga (alternativa)

**Problema** (`src/c_primes_seq.c`): número de primos en `[a, b]` por división de prueba. Solo se prueban los candidatos
impares (el 2 se cuenta aparte). El costo por candidato **no** es uniforme: los compuestos salen pronto, los primos
recorren hasta `sqrt(k)`, y `sqrt(k)` crece con `k`. Por eso un reparto por bloques contiguos desbalancea la carga
(el último bloque es el más caro) y un reparto cíclico la empareja sin comunicación extra.

**Entrada.** `mpirun -np P ./src/c_primes_mpi [a] [b] [ciclico|bloques] [reps] [--verify] [--trace]`.
**Salida esperada.** `primos=` igual al de `./src/c_primes_seq a b` para cualquier `[a, b]` y cualquier `p`
(`[2, 100000]` → 9592; `[1, 1]` → 0; `[2, 2]` → 1; `[0, 10]` → 4), más la línea de desbalance (tiempo del rango más
lento entre el más rápido).

**Lo que escribes tú:** `count_primes_mpi` (contrato en el comentario): reparto de los candidatos impares entre los
rangos, cíclico o por bloques según el argumento, y combinación del conteo. **Restricciones:** el conteo se combina con
una colectiva (no con `Send`/`Recv`); el modo `ciclico` reparte **trabajo**, no enteros: con `p` par, `k = a + rank + j·p`
le da a la mitad de los rangos puros pares (trabajo nulo) y el cociente lento/rápido se dispara aunque el conteo salga
bien (revísalo con `--trace`); el modo `bloques` debe existir para **mostrar** el desbalance; el cociente lento/rápido
del cíclico debe ser ≤ 1.2 con `[2, 3 000 000]` y `p = 4`. Reporta ambos modos con los tiempos por rango.

Corrida real de la solución de referencia con `[2, 100000]` y `-np 4`:

```
$ mpirun -np 4 ./src/c_primes_mpi 2 100000 ciclico 1 --trace
[rango 3] reparto=ciclico: 12499 candidatos impares, 2384 primos, 0.0011 s
[rango 2] reparto=ciclico: 12500 candidatos impares, 2399 primos, 0.0011 s
[rango 1] reparto=ciclico: 12500 candidatos impares, 2399 primos, 0.0011 s
[rango 0] reparto=ciclico: 12500 candidatos impares, 2410 primos, 0.0011 s
primos=9592
desbalance (ultima repeticion): rango mas lento 0.0011 s, mas rapido 0.0011 s, cociente 1.03
$ mpirun -np 4 ./src/c_primes_mpi 2 100000 bloques 1 --trace
[rango 3] reparto=bloques: 12499 candidatos impares, 2199 primos, 0.0014 s
[rango 2] reparto=bloques: 12500 candidatos impares, 2260 primos, 0.0013 s
[rango 1] reparto=bloques: 12500 candidatos impares, 2371 primos, 0.0010 s
[rango 0] reparto=bloques: 12500 candidatos impares, 2762 primos, 0.0006 s
primos=9592
desbalance (ultima repeticion): rango mas lento 0.0014 s, mas rapido 0.0006 s, cociente 2.19
```

Con bloques, el rango 3 (los candidatos más altos) tarda 2.2× lo que el rango 0 aunque tenga **menos** primos: cada
primo alto cuesta más divisiones. Con `[2, 3 000 000]` el cociente de bloques sube y el del cíclico se queda en ≈ 1.

**Casos de prueba** (`make test-c PARTE_C=primes`): `[2, 100000]` con `p = 1, 3, 4` cíclico y `p = 4` bloques; `[1, 1]`.
El profesor agrega `[2, 2]`, `[0, 10]` y un intervalo alto `[999900, 1000100]`.

---

## Parte D · Medición e interpretación (Laboratorio 2 y casa; `herramientas/protocolo-medicion.md`)

Mides tu Parte C (fuerte **y** débil) y la Parte B (fuerte, para cerrar la predicción del pre-lab). Todo con el
protocolo: `-O2`, correctitud primero, 1 calentamiento + 5 repeticiones, mediana, entorno declarado, máquina lo más
vacía posible. Los scripts de esta carpeta son la plantilla de la práctica guiada de S05 adaptada a tus programas.

**Pre-mortem (antes de medir, una línea cada una, van al reporte).** "Con `n = 10^6` y 4 procesos espero un *speedup*
de ___ porque ___" (la trajiste de la tarea de S04). "La configuración que creo que va a salir peor es ___ porque ___."

**Pasos.**

1. `make test-entrega PARTE_C=heat` (o `primes`) en verde. Un programa incorrecto no tiene *speedup*.
2. Latencia y ancho de banda **de tu máquina**: `make pingpong > resultados/pingpong.txt` (~20 s). Anota α (fila de 8
   bytes) y β. Corrida real en la máquina de autoría:

   ```
   $ mpirun -np 2 ./src/d_pingpong
   d_pingpong: rango 0 <-> rango 1, mediana de 5 repeticiones tras 1 calentamiento (factor 1.00)
        bytes    T_ida(us)      min(us)      max(us)         MB/s   modelo(us)
            8        0.414        0.387        0.544         19.3        0.415
          256        0.625        0.577        0.658        409.7        0.459
         4096        3.440        3.278        3.990       1190.5        1.129
        65536       14.813       14.552       22.700       4424.2       11.856
      1048576      183.485      174.907      196.988       5714.8      183.485
      4194304      593.124      545.636      676.552       7071.5      732.698
   alpha (latencia) = 0.414 us ; beta (ancho de banda) = 5.73 GB/s
   modelo: T_com(m) = 0.414 us + m / (5.73 GB/s); un halo de 8 B cuesta 0.415 us, un Gatherv de 1e6 doubles ~ 1397.1 us
   ```

   En otras corridas de la misma máquina α estuvo entre 0.36 y 0.42 µs y β entre 5.4 y 5.9 GB/s. El modelo de dos
   parámetros acierta en los extremos (8 B y 1 MiB, con los que se ajustó) y se equivoca hasta 3× en los tamaños
   intermedios: es suficiente para decidir, no para predecir al 5 %. Para los halos de 8 B solo importa α.

3. `t_c` de tu secuencial: la línea `t_c=… ns por celda-paso` de `./src/c_heat_seq` con el `n` grande.
4. Escalabilidad: `make run-d` corre `escalado.sh` con calor 1D (`N=1000000`, `ITERS=1200`, débil `NLOCAL=250000`,
   `p = 1, 2, 4` y `8` sobre-suscrito) y escribe `resultados/fuerte.csv`, `debil.csv`, `entorno.txt`, `fuerte.png`,
   `debil.png`. Ajusta `ITERS` para que la fila `seq` de `fuerte.csv` tenga `mediana_s ≥ 1 s`. Luego la Parte B:
   `PROG=matvec OUT=resultados-matvec ./escalado.sh` (fuerte con `M=2000`; la débil por filas es opcional). Si tu
   Parte C es primos: `PROG=primes MODO=ciclico ./escalado.sh` (y repite con `MODO=bloques` a otra carpeta).
5. Modelo de costo con **tus** α, β y `t_c`:
   `python3 modelo.py --alpha-us <α> --beta-gbps <β> --tc-ns <t_c> --p 4 --n 1000000 --tabla` da `T_com`, n*
   (punto de equilibrio, `S = 1`) y n_E(50 %). Verifica n* con una corrida cerca de él
   (`mpirun -np 4 ./src/c_heat_mpi <n*> <iters>` con `iters ≈ 2·10^8 / n*`, contra `./src/c_heat_seq`).
6. Dibuja la curva del modelo sobre tus puntos: `python3 graficar.py resultados/fuerte.csv resultados/debil.csv
   resultados --modelo <α> <β> <t_c> --check-every 1` (también imprime las tablas en Markdown para el reporte).

Corrida real de `escalado.sh` en la máquina de autoría (calor 1D; los números de tu máquina serán otros, el patrón no):

```
<!-- SALIDA-ESCALADO -->
```

**Tabla obligatoria** (las dos, fuerte y débil; la imprime `graficar.py`): tamaño, procesos, mediana, mín, máx,
*speedup* (o *speedup* escalado), eficiencia (o eficiencia débil). La fila `mpi_oversub,8` va en la tabla y **fuera**
de la curva. **Gráficas obligatorias:** `fuerte.png` (con la línea ideal y la curva del modelo) y `debil.png`.

**Tres preguntas de interpretación** (van al reporte, con un dato cada una):

1. **¿Dónde deja de escalar y por qué?** ¿A partir de qué `p` la eficiencia cae de 50 % (o no cae con `p ≤ 4`)? Sostenlo
   con la razón cómputo/comunicación que imprime tu programa por paso (o con `T_com × pasos` contra `T_seq`). ¿Qué pasa
   con la fila `p = 8` y por qué no forma parte de la curva? (Piensa en qué hace un rango mientras espera en `Waitall`
   o en `Allreduce` cuando comparte núcleo con el rango que debe enviarle el halo).
2. **Fuerte contra débil.** Con `n/p` fijo, ¿la eficiencia débil se sostiene mejor que la fuerte con `n` fijo? Explica con
   el modelo: ¿qué término crece con `p` y cuál no? ¿Qué pregunta responde la débil que la fuerte no?
3. **¿Coincide con tu predicción?** La del pre-lab (matriz-vector) y la de la tarea de S04 (calor, `n = 10^6`, 4
   procesos). Si no, ¿qué costo no habías contado: el `Scatterv` inicial, el `Allreduce` por paso, la carga ajena?
   ¿Qué dijo el modelo y qué dijo la medición cerca de n*?

**Verificación automática de la Parte D:** `make test-d` → ping-pong, `escalado.sh` en pequeño (formato del CSV, etiqueta
`mpi_oversub`, PNG), `graficar.py --modelo`, `modelo.py` con valores conocidos. No sustituye tus mediciones.

---

## Preguntas de reflexión (individuales, 5–8 líneas cada una; una por integrante en el reporte)

1. **Autoexplicación.** Explica con tus palabras por qué la decisión de paro de la Parte C tiene que tomarse con
   `MPI_Allreduce` y no con la diferencia local de cada rango, y qué pasaría exactamente (en qué llamada se quedaría
   esperando qué rango) si un rango parara un paso antes que los demás.
2. **Transferencia.** En la V2 de tu proyecto (OpenMP) no hay halos porque la memoria es compartida; en la V3 (CUDA)
   cada bloque de hilos carga su mosaico **más un borde** en memoria compartida. ¿Qué parte de tu diseño de la Parte C
   (reparto, halos, decisión global, reconstrucción) se conserva en cada versión y qué cambia? Da el dato de tu
   problema (tamaño del borde, cuántas celdas por bloque).
3. **Medición.** ¿Qué decisión de la Parte C cambiarías si α fuera 20 µs (dos máquinas por Ethernet) en lugar de los
   décimos de microsegundo de tu *ping-pong*? Usa `modelo.py` para sostenerlo (n* con α = 20 µs).

## Entregables y formato

Resumen (detalle y lista de cotejo en `entrega.md`): repositorio **privado** del equipo, carpeta `practicas/P5/` con
`prelab/` (un archivo por integrante), `src/`, `Makefile` con `MPIRUN_FLAGS`, `escalado.sh`/`graficar.py`/`modelo.py`,
`tests/run_tests.sh` con ≥ 1 caso propio, `resultados/` (`entorno.txt`, `fuerte.csv`, `debil.csv`, `pingpong.txt`,
`fuerte.png`, `debil.png`) y `REPORTE.md` ≤ 3 páginas (plantilla: `herramientas/plantilla-reporte-practica.md`) con
decisiones, tablas, gráficas, interpretación, reflexiones, bitácora de errores (≥ 3 entradas), **reparto de trabajo**
y **declaración de uso de IA**. Etiqueta `P5-entrega` antes del domingo 22 de noviembre, 23:59. Historial de *commits*
con participación de cada integrante (≥ 3 con código). Mini-defensa en el laboratorio; solo quien no estuvo graba un
video de ≤ 3 minutos.

## Rúbrica (resumen; completa en `rubrica.md`)

| Criterio | Peso | Qué mira el profesor (nivel Ejemplar) |
|---|---|---|
| Correctitud y pruebas | 25 | `make test-entrega` en `0 FAIL` sin *warnings*; casos límite (rango sin filas, `n % p ≠ 0`, `check_every > 1`, `n = p`); ≥ 1 caso propio con sentido |
| Diseño paralelo | 20 | `Irecv`/`Isend`/`Waitall` en el orden correcto; interior calculado antes del `Waitall` y medido; un `Allreduce` por `check_every`; un `Gatherv` al final; decisiones con alternativa y dato (primos: cíclico sobre candidatos impares, desbalance ≤ 1.2 medido contra bloques) |
| Medición | 20 | CSV del protocolo (5 reps, fila `seq`, `T_seq ≥ 1 s`, `p = 8` etiquetado aparte), `entorno.txt` con CPU ociosa ≥ 85 %, *ping-pong* propio, gráficas con ideal y modelo; el punto donde E cae de 50 % con la causa y un dato |
| Interpretación y reflexión | 20 | Predicción copiada y comparada; n* y n_E con parámetros propios y n* verificado; fuerte vs débil con el modelo; fila `p = 8` explicada; reflexión individual con autoexplicación y transferencia |
| Proceso e integridad | 15 | Pre-labs a tiempo; ≥ 3 *commits* de código por integrante; bitácora ≥ 3 entradas (una de MPI); declaración de IA con las cuatro líneas; cada integrante explica su parte y una función ajena |

Niveles: Ejemplar 100 % · Competente 80 % · En desarrollo 55 % · Insuficiente 20 % del peso. La prueba de propiedad
afecta el criterio 5 **del integrante**, no del equipo.

## Política de IA aplicada a esta práctica (`docs/metodo/05-politica-ia.md`)

| Verde (úsala) | Amarillo (úsala y decláralo) | Rojo (no) |
|---|---|---|
| Que te explique la firma de `MPI_Scatterv`, `MPI_Gatherv`, `MPI_Waitall` o qué significa un mensaje de `mpirun` (*not enough slots*, *run as root*, `MPI_ERR_TRUNCATE`) | Un fragmento de ≤ 10 líneas (p. ej., el ciclo de cuentas y desplazamientos del TODO(1), o la llamada a `MPI_Scatterv` con sus argumentos) que **reescribes** y explicas en el reporte con archivo y líneas | Pedir `heat_solve_mpi` o `count_primes_mpi` completas, o la Parte B entera: **ninguna** sección de esta práctica autoriza fragmentos de más de 10 líneas ni funciones completas |
| Que critique tu diseño de la Parte C con preguntas ("¿qué celdas dependen del halo?") | Que te sugiera casos de prueba (tú los implementas y verificas) | Inventar, completar o "suavizar" mediciones; generar la interpretación sin tus datos |
| Que te explique el modelo `α + m/β` o la diferencia entre escalabilidad fuerte y débil con otras palabras | Generar las gráficas a partir de **tus** CSV si no usas `graficar.py` | Usarla en la mini-defensa, en la recuperación de inicio o en el examen |

Declaración obligatoria al final de `REPORTE.md` (las cuatro líneas, incluida "qué nos dijo la IA que resultó estar
mal"; "Nada; verificado con `make test-entrega` y con el estándar MPI" es válido). Si no la usaron: "No usamos IA en
esta entrega", firmado por todos.

## Errores comunes y cómo detectarlos

| # | Síntoma | Primera pregunta que debes hacerte |
|---|---|---|
| 1 | `There are not enough slots available in the system` | ¿Cuántos núcleos detecta `mpirun` y cuántos procesos pedí? ¿Está `--oversubscribe` en `MPIRUN_FLAGS`? Si mido así, ¿etiqueté la fila como `mpi_oversub`? |
| 2 | El programa se cuelga (o termina con `y[k] = 0` en parte del vector) al agregar una colectiva | ¿Esta colectiva la ejecutan **todos** los rangos o está dentro de un `if (rank == …)`? ¿Cuántas colectivas ejecuta el rango 0 y cuántas el rango 1? (idea errónea 18) |
| 3 | La verificación dice `FALLA` y faltan exactamente `n % p` elementos (o filas) | ¿Usé `Scatter` con bloques desiguales? ¿Qué exige `Scatter` y qué par de llamadas acepta cuentas distintas? |
| 4 | `Scatterv` reparte filas revueltas o la mitad de la matriz | ¿Las cuentas y desplazamientos están en **elementos** o en filas? ¿`recvcount` es `my_rows` o `my_rows × n`? |
| 5 | Calor 1D: resultados distintos entre corridas con el mismo `n` | ¿Leo el halo o escribo `u[1]`/`u[n_local]` entre el `Isend`/`Irecv` y el `Waitall`? ¿Qué promete `MPI_Isend` sobre el búfer hasta que la operación termina? |
| 6 | Calor 1D: con `tol > 0` el programa se queda colgado al final (o `iteraciones` difiere de la secuencial) | ¿Todos los rangos deciden con el **mismo** número (`Allreduce`) o cada uno con su `diff` local? ¿Todos hacen el mismo número de `Allreduce`? |
| 7 | Calor 1D: resultado incorrecto pero `convergio=1` sin ningún error | ¿Hay una recepción para `u[0]` **y** otra para `u[n_local+1]` en cada paso? ¿La etiqueta del `Irecv` es la del `Isend` que lo alimenta? Compara con `--verify` y `n` pequeño (`--print`) |
| 8 | El programa sigue diciendo `TODO pendiente` aunque ya escribí el código | ¿Quité la bandera de `todo_pending`? ¿Dónde decide el programa imprimir eso? |
| 9 | *Speedup* > 1 con `p = 1`, o *speedup* enorme | ¿Contra qué `T(1)` calculé: la fila `seq` o `mpi,1`? ¿La secuencial tarda ≥ 1 s o estoy midiendo el arranque? |
| 10 | Las 5 repeticiones con `p = 4` varían 3× y el *speedup* es ridículo | ¿Qué dice `cpu_ociosa_antes_de_medir` en `entorno.txt`? ¿Quién más usa la máquina? ¿Qué hace un rango MPI mientras espera un halo? |
| 11 | Primos: conteo correcto pero un rango termina en 0.000 s y el cociente lento/rápido es enorme | ¿Qué números le tocaron a ese rango con `--trace`? ¿Repartí enteros (pares incluidos) o candidatos? |
| 12 | `mpirun has detected an attempt to run as root` | ¿Exporté `OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1`? (`make` lo hace; una terminal nueva no) |

## Extensión opcional (sin puntos; con reconocimiento en la defensa del proyecto)

Elige una; va en una carpeta aparte (`practicas/P5/extension/`) con su propio `make test`.

- **Híbrido MPI + OpenMP.** En `c_heat_mpi.c` sustituye `MPI_Init` por `MPI_Init_thread(…, MPI_THREAD_FUNNELED, …)` y
  paraleliza el cómputo local de cada paso con `#pragma omp parallel for`. Compara `OMP_NUM_THREADS=2 mpirun -np 2`
  contra `OMP_NUM_THREADS=1 mpirun -np 4` con `n = 10^6`: ¿cuántos mensajes de halo por paso tiene cada configuración?
  ¿Cuál gana y por qué? (Es el panorama de S05; conecta con la discusión de la V2 del proyecto).
- **Descomposición 2D.** Calor en una placa `n × n` repartida en una malla de `p_x × p_y` procesos (`MPI_Dims_create`,
  `MPI_Cart_create`), con cuatro halos por paso (las filas son contiguas; las columnas necesitan un tipo derivado
  `MPI_Type_vector` o un búfer de empaque). Mide cuánto cuesta un halo de `n/p_y` doubles contra el de 8 bytes de la
  Parte C y predícelo con tu α y β. Es exactamente el borde que carga cada bloque de hilos en la V3 (U5·S02, *tiling*).

## Para saber más

- MPI Forum, *MPI: A Message-Passing Interface Standard*, versión 4.1 (mpi-forum.org/docs): capítulo 3,
  "Point-to-Point Communication" (§3.7 *Nonblocking Communication*: `MPI_Isend`, `MPI_Irecv`, `MPI_Waitall`; `MPI_PROC_NULL`),
  y capítulo 6, "Collective Communication" (`MPI_Bcast`, `MPI_Scatter`, `MPI_Scatterv`, `MPI_Gather`, `MPI_Gatherv`,
  `MPI_Reduce`, `MPI_Allreduce`), y §"MPI and Threads" (`MPI_Init_thread`) para la extensión.
- Documentación de Open MPI (docs.open-mpi.org): página de `mpirun` (`--oversubscribe`, `--bind-to`, `--map-by`) y el
  parámetro MCA `mpi_yield_when_idle` (qué hace un rango mientras espera).
- Pacheco, P. y Malensek, M., *An Introduction to Parallel Programming*, 2.ª ed., Morgan Kaufmann, 2022: capítulo 3
  (MPI: colectivas, distribución de matrices y vectores, producto matriz-vector, rendimiento: *speedup*, eficiencia,
  escalabilidad fuerte y débil) y capítulo 2 (Amdahl, Gustafson, modelo de costo de la comunicación).
