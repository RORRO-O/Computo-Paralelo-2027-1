> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S03 · martes 10 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# Práctica guiada S03 · Producto matriz-vector con colectivas (PRIMM corto)

Actividad PRIMM de **20 minutos** en clase (minutos 30–50 de la sesión), en parejas: **conductor** (teclado) y
**navegante** (lee el código, predice, anota); cambio de roles al minuto 40. Predecir, Ejecutar e Investigar se
hacen completos; Modificar (M1) se hace en clase; Crear se arranca en clase y, si no se termina, es el ejercicio
1(b) de `../tarea-espaciada.md`. Después de esta práctica sigue la Práctica 5 · Laboratorio 1 (Partes A y B).

Es autocontenida: solo necesitas `mpicc`, `mpirun`, `make` y `timeout` (coreutils). Todas las salidas de este
documento son corridas reales en la máquina de autoría (4 núcleos, gcc 13, Open MPI 4.1.6, `-O2`).

## Qué hay en esta carpeta

| Archivo | Qué es | Fase |
|---|---|---|
| `colectivas_demo.c` | Las siete colectivas con enteros chicos: `Bcast`, `Scatter`, `Gather`, `Reduce`, `Allreduce`, `Allgather`, `Barrier` | Predecir, Investigar |
| `matvec_seq.c` | `y = A·x` en un proceso. Es la **referencia**: contra ella comparan las pruebas y con ella se calcula el *speedup* | Ejecutar |
| `matvec_collectives.c` | El ejemplo resuelto (`../ejemplo-resuelto.md`): `y = A·x` por filas con `Scatter` + `Bcast` + cómputo local + `Gather` (+ `Reduce` del tiempo). Con un tercer argumento imprime las filas locales de cada rango | Predecir, Ejecutar, Investigar |
| `matvec_p2p.c` | El mismo producto solo con `Send`/`Recv` (estilo S02), para comparar líneas y tiempo | Investigar |
| `matvec_bcast_buggy.c` | **Variante que falla a propósito**: el `Bcast` está dentro de `if (rank == 0)`. Se corre siempre con `timeout` | Predecir, Investigar |
| `matvec_scatterv.c` | Panorama: `Scatterv`/`Gatherv` cuando `n` no es múltiplo de `p` | Modificar (M3) |
| `matvec_allgather.c` | `TODO(1)`: que **todos** los rangos terminen con `y` completo | **Modificar (M1)** |
| `norma_allreduce.c` | No existe todavía: lo escribes tú (norma de `y` con `Allreduce`) | **Crear** |
| `matvec_data.h` | Datos deterministas (`A[i][j] = i + j`, `x[j] = j + 1`), cómputo local, sumas, lectura de argumentos | — |
| `medir.sh` | Protocolo mínimo: 1 calentamiento + 5 repeticiones, mediana, mín y máx | Medición |
| `Makefile`, `tests/run_tests.sh` | `make`, `make run`, `make run-buggy`, `make test`, `make clean` | — |

Con `n = 8`: `y[i] = 36·i + 168`, es decir `168, 204, 240, 276, 312, 348, 384, 420`; `checksum` (suma de `y`)
= 2352; `norma` ‖y‖ = 863.666602. La fila `i` de `A` empieza en `i, i+1, i+2, …`: con eso sabes, viendo tres
números, qué fila global recibió cada rango.

### Compilar y correr

```bash
make                                   # mpicc -std=c11 -O2 -Wall -Wextra, sin warnings
mpirun -np 4 ./colectivas_demo         # cualquier programa MPI se corre así
./matvec_seq 8                         # el secuencial no usa mpirun
make test                              # PASS / FAIL / SKIP por caso (~25 s)
make clean
```

- Si `mpirun` dice *not enough slots*, agrega `--oversubscribe` (el `Makefile` ya lo pasa con `MPIRUN_FLAGS`;
  con MPICH ese *flag* no existe: `make MPIRUN_FLAGS="" test`).
- Como root (contenedor): `export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1`.
  `tests/run_tests.sh` y `medir.sh` lo hacen solos.
- `matvec_bcast_buggy` **puede colgarse**: córrelo siempre como `timeout 10 mpirun -np 4 ./matvec_bcast_buggy 1024;
  echo "codigo $?"` (124 = lo mató `timeout`) o con `make run-buggy N=1024`.
- `n` debe ser múltiplo de `p` en todos los programas salvo `matvec_scatterv`; si no lo es, el programa lo
  dice y termina con código 1.

---

## Fase 1 · Predecir (minutos 30–34) · por escrito, antes de compilar

Lee `matvec_collectives.c` (líneas 54–85: las cuatro colectivas) y `matvec_bcast_buggy.c` (líneas 45–56). Copia la
tabla y llena "Predicción". El navegante escribe; el conductor no toca el teclado hasta que estén las siete.

| # | Comando o pregunta | Predicción | Observado | ¿Coincide? |
|---|---|---|---|---|
| P1 | `mpirun -np 4 ./matvec_collectives 8 1 filas`: ¿qué filas globales recibe el **rango 2** y con qué tres números empieza su primera fila local? | | | |
| P2 | En `matvec_collectives.c`, ¿cuántas veces está **escrita** `MPI_Scatter` y cuántos procesos la **ejecutan** con `-np 4`? | | | |
| P3 | En el rango 1, ¿qué vale `x[0]` justo **antes** del `MPI_Bcast`? ¿Y justo **después**? | | | |
| P4 | Después del `MPI_Gather`, ¿cuántos elementos de `y` tiene el **rango 3**? | | | |
| P5 | `mpirun -np 4 ./colectivas_demo`: ¿qué imprime el rango 2 en su línea `Reduce:`? ¿Y en `Allreduce:`? | | | |
| P6 | `timeout 10 mpirun -np 4 ./matvec_bcast_buggy 8`: ¿termina? Si termina, ¿qué vale `y[5]`? | | | |
| P7 | `timeout 10 mpirun -np 4 ./matvec_bcast_buggy 1024`: ¿termina? ¿Con qué código de salida? | | | |

No corrijas tus predicciones después de correr. Lo que no coincide es lo que vale la pena entender.

---

## Fase 2 · Ejecutar (minutos 34–38)

```bash
make
mpirun -np 4 ./colectivas_demo
./matvec_seq 8
mpirun -np 4 ./matvec_collectives 8 1 filas
mpirun -np 4 ./matvec_p2p 8
timeout 10 mpirun -np 4 ./matvec_bcast_buggy 8;    echo "codigo $?"
timeout 10 mpirun -np 4 ./matvec_bcast_buggy 1024; echo "codigo $?"
```

Salida real de `colectivas_demo` con `-np 4` (el **orden de las líneas cambia** entre corridas: cada proceso
imprime cuando el sistema lo programa; los **valores** no cambian):

```
[rango 0] Bcast: n = 42
[rango 0] Scatter: mi bloque = {1, 2}
[rango 1] Bcast: n = 42
[rango 1] Scatter: mi bloque = {3, 4}
[rango 1] Gather: squares = {-1, -1, -1, -1}
[rango 2] Bcast: n = 42
[rango 2] Scatter: mi bloque = {5, 6}
[rango 3] Bcast: n = 42
[rango 3] Scatter: mi bloque = {7, 8}
[rango 3] Gather: squares = {-1, -1, -1, -1}
[rango 3] Reduce: sum = -1, max = -1
[rango 1] Reduce: sum = -1, max = -1
[rango 2] Gather: squares = {-1, -1, -1, -1}
[rango 2] Reduce: sum = -1, max = -1
[rango 0] Gather: squares = {1, 4, 9, 16}
[rango 0] Reduce: sum = 10, max = 4
[rango 0] Allreduce: sum = 10
[rango 1] Allreduce: sum = 10
[rango 3] Allreduce: sum = 10
[rango 2] Allreduce: sum = 10
[rango 2] Allgather: squares = {1, 4, 9, 16}
[rango 0] Allgather: squares = {1, 4, 9, 16}
[rango 3] Allgather: squares = {1, 4, 9, 16}
[rango 1] Allgather: squares = {1, 4, 9, 16}
[rango 0] Barrier: todos llegaron, sigo
[rango 1] Barrier: todos llegaron, sigo
[rango 2] Barrier: todos llegaron, sigo
[rango 3] Barrier: todos llegaron, sigo
```

Salida real de `matvec_collectives` con filas locales (`8 1 filas`):

```
[rango 0] filas globales 0..1; primera fila local empieza: 0 1 2 ...; x[0] = 1
[rango 1] filas globales 2..3; primera fila local empieza: 2 3 4 ...; x[0] = 1
[rango 2] filas globales 4..5; primera fila local empieza: 4 5 6 ...; x[0] = 1
[rango 3] filas globales 6..7; primera fila local empieza: 6 7 8 ...; x[0] = 1
n = 8, p = 4, filas por rango = 2, reps = 1
y[0] = 168.0
y[1] = 204.0
y[2] = 240.0
y[3] = 276.0
y[4] = 312.0
y[5] = 348.0
y[6] = 384.0
y[7] = 420.0
checksum = 2352.000000
tiempos (s): scatter = 0.000020, bcast = 0.000007, calcular = 0.000049 (max entre rangos), gather = 0.012017, total = 0.012093
```

`matvec_p2p 8` imprime el mismo vector y el mismo `checksum = 2352.000000`. Con `n = 8` los tiempos no significan
nada (microsegundos; el `gather` de 12 ms es el arranque de los procesos): para medir, ve a la sección "Medición".

Salida real de la variante que falla:

```
$ timeout 10 mpirun -np 4 ./matvec_bcast_buggy 8; echo "codigo $?"
n = 8, p = 4, filas por rango = 2 (BUGGY: Bcast solo en el rango 0)
y[0] = 168.0
y[1] = 204.0
y[2] = 0.0
y[3] = 0.0
y[4] = 0.0
y[5] = 0.0
y[6] = 0.0
y[7] = 0.0
checksum = 372.000000
codigo 0
$ timeout 10 mpirun -np 4 ./matvec_bcast_buggy 1024; echo "codigo $?"
codigo 124
```

Con 8 elementos **termina y está mal** (las filas de los rangos 1–3 se multiplicaron por `x = 0`); con 1 024
**se cuelga** (el rango 0 espera dentro de `Bcast` a tres procesos que nunca lo llaman). Son dos síntomas del
mismo error: una colectiva que no llaman todos (idea errónea 18). Anota en la tabla qué pasó con P6 y P7.

---

## Fase 3 · Investigar (minutos 38–43)

### I1. ¿Quién recibió qué? (tabla de reparto)

Con la salida de `8 1 filas` llena la tabla **sin** volver a correr. Después predice las dos últimas columnas
para `-np 2` y compruébalas con `mpirun -np 2 ./matvec_collectives 8 1 filas`.

| rango | filas globales (`-np 4`) | primera fila local empieza | bloque de `y` que regresa al rango 0 | filas globales (`-np 2`) | primera fila local (`-np 2`) |
|---|---|---|---|---|---|
| 0 | 0..1 | 0 1 2 | `y[0..1]` | | |
| 1 | | | | | |
| 2 | | | | — | — |
| 3 | | | | — | — |

Pregunta: `MPI_Scatter` recibe `sendcount = local_n * n`. ¿Por qué no `n * n` (toda la matriz) ni `local_n` (el
número de filas)? ¿En qué unidades está la cuenta?

### I2. Colectivas contra punto a punto

1. En `matvec_p2p.c`, cuenta cuántas llamadas `MPI_Send`/`MPI_Recv` **ejecuta el rango 0** con `-np 4` para
   repartir (`A` y `x`) y para juntar `y`. Cuenta cuántas llamadas MPI de comunicación ejecuta **cada** rango en
   `matvec_collectives.c`. Anota los dos números.
2. En `matvec_collectives.c`, el tiempo de cómputo se combina con `MPI_Reduce(..., MPI_MAX, ...)`. ¿Por qué
   `MPI_MAX` y no `MPI_SUM` ni el promedio? ¿Qué rango decide cuándo termina el `Gather`?
3. `matvec_p2p` imprime `calcular` solo del rango 0. ¿Qué información pierde respecto a la versión con
   colectivas?

### I3. La regla de oro, línea por línea

Busca en `matvec_collectives.c`, `matvec_p2p.c` y `matvec_bcast_buggy.c` cada llamada MPI que esté **dentro** de
un `if (rank == ...)`. Clasifícala: ¿es punto a punto o colectiva? Debe salir que las únicas llamadas dentro de un
`if` son `Send`/`Recv` (punto a punto, donde cada lado hace algo distinto) y el `Bcast` de la versión
`_buggy`. Escribe la regla en una frase propia.

### I4. ¿Dónde está el umbral del cuelgue?

```bash
for n in 500 504 508 512; do
    timeout 5 mpirun -np 4 ./matvec_bcast_buggy $n > /dev/null 2>&1; echo "n=$n bytes=$((n*8)) codigo=$?"
done
ompi_info --param btl vader --level 4 | grep eager_limit      # solo Open MPI
```

Resultado real en la máquina de autoría: `n=504` (4 032 bytes) termina con código 0; `n=508` (4 064 bytes) y
`n=512` (4 096 bytes) se cuelgan (código 124); `btl_vader_eager_limit = 4096`. Es el mismo límite *eager* que
encontraste en S02 con `cross_exchange_buggy`: por debajo, Open MPI copia el mensaje y el rango 0 sale del
`Bcast` como si nada; por encima, espera a receptores que no existen. Pregunta: ¿cuál de los dos síntomas es más
peligroso en un programa real y por qué? ¿MPI te avisó en algún momento de que faltaban tres llamadas?

### I5. Lo que deja (y lo que no deja) cada colectiva

Con la salida de `colectivas_demo`:

1. ¿Por qué el rango 1 imprime `Gather: squares = {-1, -1, -1, -1}` y después `Allgather: squares = {1, 4, 9, 16}`?
   ¿Qué dice eso sobre la memoria de cada proceso? (idea errónea 16)
2. ¿Qué valor queda en `sum` en los rangos 1–3 tras `MPI_Reduce`? ¿Y tras `MPI_Allreduce`? ¿Cuál de las dos
   usarías si **todos** necesitan el total?
3. `MPI_Barrier` está justo antes de la última línea. ¿Las cuatro líneas `Barrier:` salieron ordenadas? ¿Y las de
   `Allgather:`? ¿Qué sincroniza una barrera y qué **no** sincroniza?

---

## Fase 4 · Modificar (minutos 43–47; cada cambio se verifica con `make test`)

### M1 · `matvec_allgather.c` → `TODO(1)` (obligatorio)

En un método iterativo (potencias, Jacobi, gradiente conjugado) el `y` de esta iteración es el `x` de la
siguiente, y `x` lo necesitan **todos**. Con `Gather` harían falta `Gather` + `Bcast`; `Allgather` lo hace en una
colectiva.

1. Abre el archivo; localiza `TODO(1)`.
2. Sustituye el `MPI_Gather` por **una** llamada a `MPI_Allgather`. Los seis primeros argumentos son los mismos;
   no hay `root`; el último es el comunicador.
3. Cambia `todo_pending = 1` por `0`.
4. Verifica:

```bash
make
mpirun -np 4 ./matvec_allgather 8
make test          # matvec_allgather -np 2 y -np 4 pasan de SKIP a PASS
```

Salida real con la solución (el orden de los rangos varía):

```
[rango 0] y completo: y[0] = 168.0, y[7] = 420.0, checksum = 2352.000000
[rango 1] y completo: y[0] = 168.0, y[7] = 420.0, checksum = 2352.000000
[rango 2] y completo: y[0] = 168.0, y[7] = 420.0, checksum = 2352.000000
[rango 3] y completo: y[0] = 168.0, y[7] = 420.0, checksum = 2352.000000
```

Criterio de "listo": `PASS matvec_allgather -np 2 n=8` y `PASS matvec_allgather -np 4 n=8`. Si tu versión se
cuelga, `make test` lo dice: *¿todos los rangos llaman a la misma colectiva?*

### M2 · El maestro no tiene que ser el rango 0 (si terminaste M1)

En `matvec_collectives.c` haz que el que junta `y` e imprime sea el **último** rango: cambia el `root` del
`MPI_Gather` y del `MPI_Reduce` a `size - 1`, reserva `A`/`y` y llena `A` y `x` en ese rango, y cambia la raíz del
`Scatter` y del `Bcast` en consecuencia (o deja que el rango 0 reparta y el último junte: también es válido, pero
entonces `A` vive en el 0 y `y` en el último). Criterio: `checksum = 2352.000000` impreso por el rango 3 con
`-np 4`. Es la idea errónea 19: que el 0 sea el maestro es una convención, no una regla. Restaura el archivo al
terminar (`git checkout matvec_collectives.c`).

### M3 · `n` que no es múltiplo de `p` (si terminaste M2)

Antes de correrlo, predice la línea `filas por rango:` de `mpirun -np 4 ./matvec_scatterv 10` y de
`mpirun -np 4 ./matvec_scatterv 3`. Corre los dos. Resultado real: `3 3 2 2` y `1 1 1 0`. Pregunta: el rango 3 con
`n = 3` recibe **cero** filas, ¿y aun así llama a `Scatterv`, `Bcast` y `Gatherv`? ¿Qué pasaría si lo saltara con
un `if (my_rows > 0)`?

---

## Fase 5 · Crear (minuto 47 en adelante; se termina en casa si hace falta)

### `norma_allreduce.c`: la norma de `y` en todos los rangos

Escribe `norma_allreduce.c` a partir de `matvec_collectives.c`. Después del cómputo local, cada rango debe
calcular la suma de cuadrados de **su** bloque `y_local` (hay `vector_sum_squares` en `matvec_data.h`), combinar
esas sumas con **una** `MPI_Allreduce` (`MPI_SUM`) y, en **todos** los rangos, imprimir una línea que contenga
`norma = <valor>` con `%.6f`, donde `<valor>` = `sqrt(total)` (`#include <math.h>`; el `Makefile` ya enlaza `-lm`).

Restricciones:

- Una sola colectiva nueva. Sin `Gather` + `Bcast`, sin `Send`/`Recv`.
- Ninguna llamada MPI dentro de un `if (rank == ...)`.
- Debe funcionar con `-np 4 n=8`, `-np 3 n=12` y `-np 4 n=1024` (`n` múltiplo de `p`). El `Makefile` y
  `tests/run_tests.sh` detectan el archivo solos.

Criterio de "listo":

```bash
make test        # tres líneas: PASS norma_allreduce -np 4 n=8 · -np 3 n=12 · -np 4 n=1024
```

Salida real de la solución de referencia con `-np 4 n=8` (coincide con `norma = 863.666602` de `./matvec_seq 8`):

```
[rango 3] suma local de cuadrados = 323856.000000, norma = 863.666602
[rango 1] suma local de cuadrados = 133776.000000, norma = 863.666602
[rango 2] suma local de cuadrados = 218448.000000, norma = 863.666602
[rango 0] suma local de cuadrados = 69840.000000, norma = 863.666602
```

Pistas, de más general a más concreta (abre solo la que necesites):

<details><summary>Pista 1</summary>
La pregunta que decide la colectiva: ¿quién tiene el dato antes (cada rango, un pedazo) y quién lo necesita
después (todos, el total)? Un pedazo en cada uno → todos el combinado: <code>Allreduce</code>.
</details>

<details><summary>Pista 2</summary>
La firma es la de <code>Reduce</code> sin <code>root</code>:
<code>MPI_Allreduce(const void *sendbuf, void *recvbuf, int count, MPI_Datatype type, MPI_Op op, MPI_Comm comm)</code>.
Aquí <code>count</code> es 1 y los búferes son las direcciones de dos <code>double</code>.
</details>

<details><summary>Pista 3</summary>
<code>double local_sq = vector_sum_squares(y_local, local_n), total_sq = 0.0;</code> y después la llamada con
<code>&amp;local_sq</code>, <code>&amp;total_sq</code>, <code>1</code>, <code>MPI_DOUBLE</code>, <code>MPI_SUM</code>,
<code>MPI_COMM_WORLD</code>. Imprime <code>sqrt(total_sq)</code> en todos los rangos, fuera de cualquier <code>if</code>.
</details>

Si terminas antes: (a) escribe la misma norma con `MPI_Reduce` + `MPI_Bcast` y cuenta cuántas colectivas y
cuántas líneas te costó; (b) lee en la documentación de `MPI_Allreduce` qué hace `MPI_IN_PLACE` como `sendbuf` y
úsalo; (c) agrega el tiempo de la `Allreduce` con `MPI_Wtime()` y compáralo con el del `Scatter` para
`n = 4096`: ¿cuántos bytes mueve cada una?

---

## Medición (para el ejemplo resuelto y como ensayo de la Parte D de la Práctica 5)

`medir.sh` aplica el protocolo mínimo del curso (`herramientas/protocolo-medicion.md`): 1 calentamiento + 5
repeticiones, mediana, mín y máx. `reps` (segundo argumento) repite el producto con la **misma** matriz ya
repartida; `n = 4096` y `reps = 40` hacen que el secuencial tarde ≈ 1 s.

```bash
./medir.sh ./matvec_seq 4096 40
./medir.sh mpirun -np 2 ./matvec_collectives 4096 40
./medir.sh mpirun -np 4 ./matvec_collectives 4096 40
./medir.sh mpirun -np 4 ./matvec_p2p 4096 40
./medir.sh mpirun -np 4 ./matvec_collectives 4096 1        # un solo producto
```

Corrida real en la máquina de autoría (VM de 4 núcleos **compartida**, carga ajena ≈ 3 durante la medición; se
declara porque invalida la regla "cierra lo demás" del protocolo):

| Configuración | Mediana (s) | Mín–máx (s) | *Speedup* | Eficiencia |
|---|---|---|---|---|
| `matvec_seq 4096 40` | 1.092 | 1.055–1.214 | 1.00 | — |
| `matvec_collectives -np 2`, 40 productos | 0.659 | 0.621–0.857 | 1.66 | 0.83 |
| `matvec_collectives -np 4`, 40 productos | 0.360 | 0.244–0.395 | 3.04 | 0.76 |
| `matvec_p2p -np 4`, 40 productos | 0.349 | 0.310–0.376 | 3.13 | 0.78 |
| `matvec_seq 4096 1` | 0.043 | 0.028–0.047 | 1.00 | — |
| `matvec_collectives -np 4`, **1** producto | 0.115 | 0.088–0.191 | **0.37** | 0.09 |

Desglose de una corrida con `-np 4` (lo imprime el programa):

```
40 productos: scatter = 0.082214, bcast = 0.000057, calcular = 0.252381 (max entre rangos), gather = 0.000078, total = 0.334729
 1 producto : scatter = 0.085271, bcast = 0.000053, calcular = 0.007559 (max entre rangos), gather = 0.000744, total = 0.092992
```

Lo que se repite en cualquier máquina: el `scatter` mueve `n² × 8` bytes = 134 MB (128 MiB) y cuesta lo mismo haya 1 o 40
productos; el `bcast` mueve 32 KB y no se ve; con **un** producto la comunicación domina (92 % del total) y el
*speedup* es < 1; con 40 se amortiza y el *speedup* se acerca a 3. Colectivas y punto a punto cuestan casi lo
mismo aquí (una máquina, 4 procesos); la diferencia está en las líneas de código y en lo que pasa con `p` grande
o entre máquinas. Otra corrida de la misma máquina con carga ajena ≈ 5–6 (la que usa el ejercicio 2 de
`../tarea-espaciada.md`) dio *speedup* 1.9 con 4 procesos: el ruido de una máquina compartida se come la mitad
del *speedup*, y por eso el protocolo pide declarar el entorno y la carga. En tu laptop los números cambian; el
orden de magnitud y la conclusión, no.

Llena tu propia tabla (una fila por configuración) y guárdala: es el ensayo de la Parte D de la Práctica 5
(Lab 2, martes 17 de noviembre).

---

## Verificación automática

```bash
make test
```

Salida real tal como se entrega la carpeta (los `SKIP` son lo que te toca escribir):

```
PASS matvec_seq n=8                                 y[3] = 276, y[7] = 420, checksum = 2352
PASS matvec_collectives -np 1 n=8                   checksum = 2352.000000 (= secuencial)
PASS matvec_collectives -np 2 n=8                   checksum = 2352.000000 (= secuencial)
PASS matvec_collectives -np 4 n=8                   checksum = 2352.000000 (= secuencial)
PASS matvec_collectives -np 4 n=1024                checksum = 641381171200.000000 (= secuencial)
PASS matvec_collectives -np 3 n=8 (n % p != 0)      rechaza con mensaje; rc=1
PASS matvec_p2p -np 4 n=8                           checksum = 2352.000000 (= secuencial)
PASS matvec_p2p -np 4 n=1024                        checksum = 641381171200.000000 (= secuencial)
PASS matvec_scatterv -np 4 n=10                     checksum = 5775.000000 (= secuencial)
PASS matvec_scatterv -np 3 n=8                      checksum = 2352.000000 (= secuencial)
PASS matvec_scatterv -np 4 n=3 (un rango sin filas) checksum = 42.000000 (= secuencial)
PASS matvec_scatterv -np 4 n=10 reparto             filas por rango: 3 3 2 2
PASS colectivas_demo -np 4                          Bcast/Scatter/Gather/Reduce/Allreduce/Allgather/Barrier correctos
PASS matvec_bcast_buggy -np 4 n=8 (timeout 10)      termino con resultado INCORRECTO: checksum 372.000000 != 2352.000000 (sintoma esperado)
PASS matvec_bcast_buggy -np 4 n=1024 (timeout 10)   se colgo (sintoma esperado: el rango 0 espera dentro de Bcast)
SKIP matvec_allgather -np 2 n=8                     TODO(1) sin completar
SKIP matvec_allgather -np 4 n=8                     TODO(1) sin completar
SKIP norma_allreduce                                norma_allreduce.c no existe todavia (fase Crear)
== Resumen: 15 PASS, 0 FAIL, 3 SKIP ==
```

Con M1 y Crear terminados: `20 PASS, 0 FAIL, 0 SKIP`. Los `checksum` se comparan contra `matvec_seq` con
tolerancia relativa `1e-9`: los datos son enteros exactos en `double`, pero el orden de las sumas cambia entre
versiones y, con `n` grande, el redondeo también (idea errónea 10 de la Unidad III, otra vez). Para
`matvec_bcast_buggy` el `PASS` significa "falló como debía": cuelgue **o** resultado incorrecto; lo que sería
`FAIL` es que diera el resultado correcto.

## Antes de irte

- [ ] Tabla de predicciones P1–P7 con la columna "¿Coincide?".
- [ ] Tabla de reparto I1 llena para `-np 4` y `-np 2`.
- [ ] `make test` con `PASS` en `matvec_allgather` (M1).
- [ ] `norma_allreduce.c` empezado (o anotado como ejercicio 1(b) de la tarea).
- [ ] Una frase propia que empiece con "Una colectiva la llaman…".

## Errores frecuentes en esta práctica

| Síntoma | Primera pregunta que hacerte |
|---|---|
| Se queda colgado sin mensaje | ¿Hay alguna colectiva dentro de un `if (rank == ...)`? ¿En qué llamada está **cada** proceso ahora mismo? |
| `y` con ceros en algunas filas, sin error | ¿Todos los rangos tenían `x` cuando multiplicaron? ¿Quién llamó al `Bcast`? |
| `checksum` correcto en el rango 0 pero los demás imprimen basura o `0.0` en `y` | ¿Usaste `Gather` o `Allgather`? ¿En qué rangos deja el resultado cada una? |
| `MPI_ERR_TRUNCATE` o `checksum` incorrecto con `Scatter` | ¿`sendcount` está en **elementos por rango** (`local_n * n`) y no en bytes ni en filas ni en el total? |
| `n = 8 no es multiplo de p = 3` | Es el programa, no tú: `Scatter` reparte bloques iguales; usa `n` múltiplo de `p` o `matvec_scatterv` |
| `Allreduce` compila pero el total es solo el local | ¿Pasaste `&local_sq` y `&total_sq` (direcciones) o los valores? ¿`count = 1`? |
| *not enough slots* | `--oversubscribe` (el `Makefile` lo pone); con MPICH, `MPIRUN_FLAGS=""` |
| Tiempos iguales con `-np 1`, `2` y `4`, o *speedup* < 1 con 40 productos | ¿Qué dice `uptime` antes de medir? ¿Alguien más corre algo en esta máquina? ¿Mediste con `-O2` y `reps = 40`? |

## Uso de IA en esta práctica

Verde: pedirle que te explique la firma de `MPI_Scatter` o la diferencia entre `Reduce` y `Allreduce`, o que
te explique un mensaje de `mpirun`. Amarillo: pedirle que revise tu `norma_allreduce.c` y señale si alguna
colectiva quedó dentro de un `if`; tú verificas con `make test` y lo declaras. Rojo: pegar el enunciado de la
fase Crear y entregar lo que salga sin poder explicar qué rango tiene qué dato antes y después de cada línea.
