> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S03 · martes 10 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# S03 · Ejemplo resuelto: `y = A·x` repartido por filas con cuatro colectivas (y la variante que se cuelga)

Código: `practica-guiada/colectivas_demo.c` (las siete colectivas con enteros), `practica-guiada/matvec_collectives.c`
(el ejemplo), `practica-guiada/matvec_p2p.c` (lo mismo con `Send`/`Recv`) y `practica-guiada/matvec_bcast_buggy.c`
(la variante que falla). Compila con `make` dentro de `practica-guiada/`. Todas las salidas son corridas reales en
la máquina de autoría (4 núcleos, gcc 13, Open MPI 4.1.6, `-O2`); donde se indica, los números cambian en la tuya.

Es el ejemplo corto con que abre el Laboratorio 1 (minutos 8–30). Lee cada paso y, en las pausas, responde
**antes** de abrir la respuesta.

## 1. Problema

Calcular `y = A·x` con `A` de `n × n` y `x` de `n`, usando `p` procesos MPI. Los datos empiezan en el rango 0
(los leyó de un archivo, o los generó); el resultado debe terminar en el rango 0. Para poder verificar a mano,
`A[i][j] = i + j` y `x[j] = j + 1`; con `n = 8`: `y[i] = 36·i + 168`, es decir `168, 204, …, 420`, y la suma de `y`
(el `checksum`) es 2352.

## 2. Plan en tres líneas (Foster)

1. **Partición por dominio, por filas**: la fila `i` de `y` solo necesita la fila `i` de `A` y **todo** `x`.
   Aglomeración: bloques contiguos de `n/p` filas; mapeo: un bloque por proceso.
2. **Comunicación**: repartir las filas de `A` (cada rango un bloque distinto), difundir `x` (todos el mismo),
   juntar los bloques de `y` en el rango 0. Tres movimientos de datos, uno por colectiva.
3. **Cómputo local** sin comunicación: cada rango multiplica sus `n/p` filas por `x`.

## 3. Vocabulario: las siete colectivas y la regla de oro

Una **operación colectiva** (*collective operation*) es una comunicación en la que participan **todos** los
procesos de un comunicador. Se describe con una sola llamada que cada proceso ejecuta; la implementación decide
cómo mover los datos (normalmente en árbol: `log₂ p` pasos en lugar de `p − 1`). La pregunta que elige la
colectiva es siempre la misma: **¿quién tiene el dato antes y quién lo necesita después?**

| Colectiva | Antes | Después | Firma (lo esencial) |
|---|---|---|---|
| `MPI_Bcast` | la raíz tiene `count` elementos | **todos** tienen los mismos | `(buf, count, type, root, comm)` |
| `MPI_Scatter` | la raíz tiene `p` bloques iguales | cada rango tiene **su** bloque | `(sendbuf, sendcount, type, recvbuf, recvcount, type, root, comm)` |
| `MPI_Gather` | cada rango tiene un bloque | la **raíz** tiene los `p` bloques en orden de rango | `(sendbuf, sendcount, type, recvbuf, recvcount, type, root, comm)` |
| `MPI_Reduce` | cada rango tiene un valor | la **raíz** tiene la combinación (`MPI_SUM`, `MPI_MAX`, …) | `(sendbuf, recvbuf, count, type, op, root, comm)` |
| `MPI_Allreduce` | cada rango tiene un valor | **todos** tienen la combinación | `(sendbuf, recvbuf, count, type, op, comm)` |
| `MPI_Allgather` | cada rango tiene un bloque | **todos** tienen los `p` bloques | `(sendbuf, sendcount, type, recvbuf, recvcount, type, comm)` |
| `MPI_Barrier` | — | nadie sigue hasta que todos llegaron | `(comm)` |

`sendcount` y `recvcount` de `Scatter`/`Gather` son **por rango** y en **elementos**, no el total ni bytes. Las
versiones `Scatterv`/`Gatherv` aceptan bloques de distinto tamaño (`matvec_scatterv.c`).

**Regla de oro.** Todas las colectivas las llaman **todos** los procesos del comunicador, con la misma raíz, el
mismo tipo y cuentas compatibles. En el código fuente la llamada aparece **una vez**, fuera de cualquier
`if (rank == ...)`; cada proceso hace su parte según su rango (la raíz aporta o recibe el total; los demás, su
bloque). Una colectiva no es "un `Send` a todos": es una cita a la que van todos.

## 4. Paso 1 · Ver las siete en acción con enteros (`colectivas_demo.c`)

Cada rango `r` aporta `v = r + 1`. El rango 0 tiene `n = 42`; los demás tienen `-1` hasta que algo lo cambie. Las
variables que reciben resultados se inicializan en `-1` para ver quién las llena y quién no.

```c
int n = (rank == 0) ? 42 : -1;
MPI_Bcast(&n, 1, MPI_INT, 0, MPI_COMM_WORLD);               /* todos: n = 42 */

int chunk[2] = {-1, -1};                                     /* data = {1..8} solo en el rango 0 */
MPI_Scatter(data, 2, MPI_INT, chunk, 2, MPI_INT, 0, MPI_COMM_WORLD);

int v = rank + 1, sq = v * v;                                /* squares[] = {-1,-1,-1,-1} en todos */
MPI_Gather(&sq, 1, MPI_INT, squares, 1, MPI_INT, 0, MPI_COMM_WORLD);

int sum = -1, max = -1;
MPI_Reduce(&v, &sum, 1, MPI_INT, MPI_SUM, 0, MPI_COMM_WORLD);
MPI_Reduce(&v, &max, 1, MPI_INT, MPI_MAX, 0, MPI_COMM_WORLD);

int all_sum = -1;
MPI_Allreduce(&v, &all_sum, 1, MPI_INT, MPI_SUM, MPI_COMM_WORLD);
MPI_Allgather(&sq, 1, MPI_INT, squares, 1, MPI_INT, MPI_COMM_WORLD);
MPI_Barrier(MPI_COMM_WORLD);
```

Corrida real con `-np 4`, agrupada por rango para leerla (en pantalla las líneas salen mezcladas):

```
[rango 0] Bcast: n = 42   Scatter: {1, 2}   Gather: squares = {1, 4, 9, 16}      Reduce: sum = 10, max = 4   Allreduce: sum = 10   Allgather: {1, 4, 9, 16}
[rango 1] Bcast: n = 42   Scatter: {3, 4}   Gather: squares = {-1, -1, -1, -1}   Reduce: sum = -1, max = -1  Allreduce: sum = 10   Allgather: {1, 4, 9, 16}
[rango 2] Bcast: n = 42   Scatter: {5, 6}   Gather: squares = {-1, -1, -1, -1}   Reduce: sum = -1, max = -1  Allreduce: sum = 10   Allgather: {1, 4, 9, 16}
[rango 3] Bcast: n = 42   Scatter: {7, 8}   Gather: squares = {-1, -1, -1, -1}   Reduce: sum = -1, max = -1  Allreduce: sum = 10   Allgather: {1, 4, 9, 16}
```

**Pausa 1.** Después de `MPI_Gather`, el rango 1 sigue con `squares = {-1, -1, -1, -1}`; después de `MPI_Allgather`
tiene `{1, 4, 9, 16}`. ¿Por qué? ¿Y por qué `sum` vale `-1` en los rangos 1–3 tras `MPI_Reduce` si "todos la
llamaron"?

<details><summary>Respuesta</summary>

Hay **cuatro** arreglos `squares` y cuatro variables `sum`, una por proceso, en memorias distintas (idea errónea
16: los procesos no comparten memoria). `Gather` y `Reduce` dejan el resultado **solo en la raíz**; en los demás
rangos el búfer de recepción ni se toca, por eso conserva el `-1`. Que "todos la llamen" es la condición para
que la operación ocurra; **dónde queda el resultado** lo define cada colectiva. Si todos necesitan el resultado,
la colectiva es la versión `All…` (`Allreduce`, `Allgather`), o `Reduce`/`Gather` seguidas de un `Bcast` (dos
colectivas y el rango 0 como cuello de botella).
</details>

## 5. Paso 2 · El producto matriz-vector (`matvec_collectives.c`)

Memoria: el rango 0 tiene `A` completa y `y` completo; **todos** tienen `x` completo (lo necesitan entero), su
bloque `A_local` de `local_n = n/p` filas y su bloque `y_local`. En los rangos ≠ 0, `A` y `y` son `NULL` y `x`
empieza en ceros (`calloc`).

```c
MPI_Barrier(MPI_COMM_WORLD);                   /* alinea el arranque del cronómetro */
double t0 = MPI_Wtime();

/* 1. Repartir filas: el bloque k va al rango k. Cuentas POR RANGO, en elementos. */
MPI_Scatter(A, (int)(local_n * n), MPI_DOUBLE,
            A_local, (int)(local_n * n), MPI_DOUBLE, 0, MPI_COMM_WORLD);
double t1 = MPI_Wtime();

/* 2. x completo a todos. La llaman TODOS: en el rango 0 'x' es la fuente; en los demás, el destino. */
MPI_Bcast(x, (int)n, MPI_DOUBLE, 0, MPI_COMM_WORLD);
double t2 = MPI_Wtime();

/* 3. Cómputo local, sin comunicación. */
for (int r = 0; r < reps; r++)
    local_matvec(A_local, x, y_local, local_n, n);
double t3 = MPI_Wtime();

/* 4. Juntar y: el bloque del rango k cae en y[k*local_n ..]. Solo el rango 0 recibe. */
MPI_Gather(y_local, (int)local_n, MPI_DOUBLE,
           y, (int)local_n, MPI_DOUBLE, 0, MPI_COMM_WORLD);
double t4 = MPI_Wtime();

/* Tiempo de cómputo del rango más lento: una reducción con MPI_MAX. */
double t_compute = t3 - t2, t_compute_max = 0.0;
MPI_Reduce(&t_compute, &t_compute_max, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
```

Corrida real: `mpirun -np 4 ./matvec_collectives 8 1 filas` (el tercer argumento hace que cada rango imprima su
primera fila local):

```
[rango 0] filas globales 0..1; primera fila local empieza: 0 1 2 ...; x[0] = 1
[rango 1] filas globales 2..3; primera fila local empieza: 2 3 4 ...; x[0] = 1
[rango 2] filas globales 4..5; primera fila local empieza: 4 5 6 ...; x[0] = 1
[rango 3] filas globales 6..7; primera fila local empieza: 6 7 8 ...; x[0] = 1
n = 8, p = 4, filas por rango = 2, reps = 1
y[0] = 168.0
y[1] = 204.0
...
y[7] = 420.0
checksum = 2352.000000
tiempos (s): scatter = 0.000020, bcast = 0.000007, calcular = 0.000049 (max entre rangos), gather = 0.012017, total = 0.012093
```

Igual que `./matvec_seq 8`. La fila `i` de `A` empieza en `i`, así que "empieza: 4 5 6" en el rango 2 confirma que
recibió las filas 4 y 5. Y `x[0] = 1` en los cuatro rangos confirma el `Bcast` (antes valía 0.0 en los rangos
1–3). Con `n = 8` los tiempos no significan nada; se miden en el Paso 5.

**Pausa 2.** `MPI_Scatter` recibe `sendcount = local_n * n`. ¿Por qué no `n * n` (toda la matriz), ni `local_n`
(las filas), ni `local_n * n * sizeof(double)`?

<details><summary>Respuesta</summary>

`sendcount` es lo que recibe **cada** rango, en **elementos** del tipo dado. `local_n` filas de `n` columnas son
`local_n × n` `double`. `n * n` enviaría toda la matriz a cada uno (y leería fuera del arreglo para los rangos
1–3); `local_n` mandaría dos números en vez de dos filas; en bytes es un error clásico heredado de `memcpy`:
MPI cuenta elementos. La matriz está guardada por filas (`A[i*n + j]`), así que el bloque `k` son `local_n × n`
elementos **contiguos** a partir de `k * local_n * n`: por eso `Scatter` puede repartirla sin copias
intermedias.
</details>

**Pausa 3.** En el rango 2, `x` vale todo ceros cuando se llega a `MPI_Bcast(x, n, MPI_DOUBLE, 0, …)`. ¿Esa línea,
en el rango 2, es un envío o una recepción? ¿Y en el rango 0? ¿Por qué el rango 2 **tiene** que ejecutarla si no
tiene nada que enviar?

<details><summary>Respuesta</summary>

La misma línea es **envío en la raíz y recepción en los demás**: el papel lo decide `rank == root`, no el texto
de la llamada. En el rango 2, `x` es el **destino**: después de la llamada contiene la copia de los datos del
rango 0. Tiene que ejecutarla porque nadie más va a escribir en su `x`: en memoria distribuida no hay forma de
que el rango 0 "meta" datos en la memoria del rango 2 sin que el 2 participe (y, con la implementación en árbol,
el rango 2 puede además reenviar `x` a otro rango). Idea errónea 18 en una frase: *no hay `MPI_Recv` implícito
en los demás rangos*; la colectiva **es** esa recepción.
</details>

**Pausa 4.** El tiempo de cómputo se combina con `MPI_Reduce(…, MPI_MAX, …)`. ¿Por qué `MPI_MAX` y no la suma o
el promedio?

<details><summary>Respuesta</summary>

El `Gather` no termina hasta que llega el bloque del rango **más lento**: el tiempo que "ve" el programa es el
máximo, no el promedio. Reportar el promedio escondería el desbalance (un rango con un núcleo ocupado por otro
proceso tarda el doble y los otros tres lo esperan). Es el mismo criterio que el `barrier` de OpenMP: la región
dura lo que dura el hilo más lento. Nota de paso: `MPI_MAX` con `MPI_DOUBLE` es una **reducción**, lo mismo que
`reduction(max:…)` en OpenMP, pero las "copias privadas" son variables en procesos distintos y la combinación
viaja en mensajes.
</details>

## 6. Paso 3 · Lo mismo con `Send`/`Recv` (`matvec_p2p.c`)

Las tres etapas de comunicación, "a mano":

```c
if (rank == 0) {
    memcpy(A_local, A, local_n * n * sizeof(double));                 /* mi propio bloque */
    for (int dest = 1; dest < size; dest++) {
        MPI_Send(A + dest * local_n * n, local_n * n, MPI_DOUBLE, dest, TAG_ROWS, MPI_COMM_WORLD);
        MPI_Send(x, n, MPI_DOUBLE, dest, TAG_X, MPI_COMM_WORLD);
    }
} else {
    MPI_Recv(A_local, local_n * n, MPI_DOUBLE, 0, TAG_ROWS, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    MPI_Recv(x, n, MPI_DOUBLE, 0, TAG_X, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
}
/* ... cómputo local ... */
if (rank == 0) {
    memcpy(y, y_local, local_n * sizeof(double));
    for (int src = 1; src < size; src++)
        MPI_Recv(y + src * local_n, local_n, MPI_DOUBLE, src, TAG_Y, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
} else {
    MPI_Send(y_local, local_n, MPI_DOUBLE, 0, TAG_Y, MPI_COMM_WORLD);
}
```

Mismo resultado (`checksum = 2352.000000`). Diferencias: 3 llamadas por rango contra 6 envíos + 3 recepciones en
el rango 0 (con `p = 4`; con `p = 64`, 126 + 63); tres etiquetas que inventar y emparejar; dos ramas `if` que
mantener; y el rango 0 hace **todos** los envíos uno tras otro, mientras que `Scatter`/`Bcast` pueden usar un
árbol en el que varios rangos reenvían a la vez (lo predijiste en el ejercicio 3 de la tarea de S02).

**Pausa 5.** En `matvec_p2p.c` las llamadas MPI **sí** están dentro de `if (rank == 0) … else …`, y el programa es
correcto. En `matvec_bcast_buggy.c` el `Bcast` está dentro de `if (rank == 0)` y el programa está mal. ¿Cuál es la
diferencia?

<details><summary>Respuesta</summary>

En punto a punto cada lado hace **algo distinto** (`Send` en uno, `Recv` en el otro), así que la ramificación por
rango es la forma normal de escribirlo; lo que importa es que cada `Send` tenga su `Recv`. Una colectiva ya trae
dentro los dos papeles: la **misma** llamada es envío en la raíz y recepción en los demás. Meterla en un `if`
quita la recepción. Regla práctica: `Send`/`Recv` dentro de `if (rank == …)`, normal; una colectiva dentro de
`if (rank == …)`, casi siempre un error (la excepción legítima es un `if` que **todos** evalúan igual, por
ejemplo `if (n > 0)` con `n` ya difundido).
</details>

## 7. Paso 4 · La variante que falla (`matvec_bcast_buggy.c`)

Un solo cambio respecto al ejemplo:

```c
if (rank == 0)                                    /* ERROR: "el que tiene x es el 0, que la mande él" */
    MPI_Bcast(x, (int)n, MPI_DOUBLE, 0, MPI_COMM_WORLD);
```

Dos corridas reales, siempre con `timeout`:

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

Y el umbral, buscado como en S02: `n = 504` (4 032 bytes) termina; `n = 508` (4 064 bytes) se cuelga;
`btl_vader_eager_limit = 4096`.

**Pausa 6.** ¿Por qué con 8 `double` el programa **termina** (mal) y con 1 024 se **cuelga**? ¿Cuál de los dos
síntomas preferirías encontrarte y por qué? ¿MPI avisó de que faltaban tres llamadas?

<details><summary>Respuesta</summary>

Es el mismo límite *eager* de S02. Con 64 bytes, Open MPI copia el mensaje del `Bcast` a un búfer interno y el
rango 0 **sale** de la llamada aunque nadie lo haya recibido; sigue, multiplica sus dos filas con `x` correcto y
hace el `Gather`, donde recibe los bloques de los rangos 1–3, que multiplicaron con `x = 0`: `y[2..7] = 0`, sin
ningún error. Con 8 KB el rango 0 espera dentro de `Bcast` a que los demás lleguen, y los demás están esperando
en el `Gather` a que el rango 0 llegue: interbloqueo. El cuelgue es el síntoma **menos** peligroso: se nota. El
resultado incorrecto silencioso llega al reporte. Y no, MPI no avisa (opción D del ConcepTest 1): el rango 0 no
tiene forma de saber que los otros tres nunca van a llamar. La verificación es tuya: ninguna colectiva dentro de
un `if` por rango, y `make test` contra la secuencial.
</details>

## 8. Paso 5 · Medir: ¿cuánto cuesta repartir?

`n = 4096`; `reps` productos con la **misma** matriz repartida una vez; protocolo mínimo con `medir.sh`
(1 calentamiento + 5 repeticiones, mediana). Máquina de autoría, VM compartida con carga ajena ≈ 3 (se declara).

| Configuración | Mediana (s) | Mín–máx (s) | *Speedup* | Eficiencia |
|---|---|---|---|---|
| `matvec_seq 4096 40` | 1.092 | 1.055–1.214 | 1.00 | — |
| `matvec_collectives -np 2`, 40 productos | 0.659 | 0.621–0.857 | 1.66 | 0.83 |
| `matvec_collectives -np 4`, 40 productos | 0.360 | 0.244–0.395 | 3.04 | 0.76 |
| `matvec_p2p -np 4`, 40 productos | 0.349 | 0.310–0.376 | 3.13 | 0.78 |
| `matvec_seq 4096 1` | 0.043 | 0.028–0.047 | 1.00 | — |
| `matvec_collectives -np 4`, **1** producto | 0.115 | 0.088–0.191 | **0.37** | 0.09 |

Desglose que imprime el programa en una corrida con `-np 4`:

```
40 productos: scatter = 0.082214, bcast = 0.000057, calcular = 0.252381 (max entre rangos), gather = 0.000078, total = 0.334729
 1 producto : scatter = 0.085271, bcast = 0.000053, calcular = 0.007559 (max entre rangos), gather = 0.000744, total = 0.092992
```

**Pausa 7.** Con **un** producto el *speedup* es 0.37; con 40 productos, 3.04. El código es el mismo. ¿Qué
cambió? Escribe los dos números que lo explican.

<details><summary>Respuesta</summary>

Los dos números: el `scatter` mueve `n² × 8` bytes = 134 MB (128 MiB; 0.08 s, igual con 1 que con 40 productos) y un
producto hace `2n²` operaciones (0.04 s en secuencial, 0.0076 s repartido entre 4). Mover la matriz cuesta más
que multiplicarla **una** vez; es del mismo orden (`n²`) y la red es más lenta que la ALU. Con 40 productos el
cómputo crece 40 veces y el reparto no: se amortiza, y el *speedup* se acerca a `p`. Es la idea errónea 21 con
datos: la comunicación no es gratis y a veces domina. Las salidas prácticas son dos: repartir una vez y usar
muchas veces (métodos iterativos), o **no** repartir: que cada rango genere o lea sus propias filas (lo verás en
la Práctica 5 y en Jacobi, S04). El `bcast` de 32 KB, en cambio, no se ve: 4 000 veces menos bytes. La
diferencia entre colectivas y punto a punto aquí es pequeña (una máquina, 4 procesos); en `p` grande o entre
máquinas el árbol de las colectivas gana.
</details>

Otra corrida en la misma máquina, con carga ajena ≈ 5–6, dio *speedup* 1.9 con 4 procesos (es la que usa el
ejercicio 2 de `tarea-espaciada.md`). Mismo programa, mismo `n`, la mitad del *speedup*: por eso el protocolo
pide declarar el entorno y la carga, y por eso la Parte D de la Práctica 5 se mide con la máquina lo más vacía
posible.

## 9. Qué te llevas

1. Una colectiva la llaman **todos** los procesos del comunicador; se escribe una vez, fuera de `if (rank == …)`;
   la misma línea es envío en la raíz y recepción en los demás. Si falta uno, no hay aviso: cuelgue o basura.
2. La colectiva se elige con una pregunta: ¿quién tiene el dato antes y quién lo necesita después? Un rango →
   `Bcast`/`Scatter` (de la raíz) o `Gather`/`Reduce` (hacia la raíz); todos → `Allgather`/`Allreduce`.
3. `Gather` y `Reduce` dejan el resultado **solo** en la raíz; los demás búferes no se tocan. Las cuentas son por
   rango y en elementos.
4. Repartir los datos cuesta `O(n²)` bytes, lo mismo que un producto en operaciones: se paga una vez y se amortiza,
   o se evita generando los datos donde se usan. Mídelo; no lo supongas.
