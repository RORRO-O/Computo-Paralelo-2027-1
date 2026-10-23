> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S06 · jueves 19 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S06 · Ejemplo resuelto: enviar una columna con un tipo derivado y hacer colectivas por fila con un comunicador

Código: `practica-guiada/ejemplo_columna_split.c`. Compila con `make` dentro de `practica-guiada/`; corre con
`mpirun -np 4 ./ejemplo_columna_split` (en el entorno de autoría, como root: `make run`, que exporta lo necesario).
Las salidas de este documento son corridas reales (Open MPI 4.1.6, gcc 13, 4 núcleos). Todo lo que imprime el
programa sale del rango 0 y en orden fijo, así que tu salida debe ser idéntica.

Es el último ejemplo de la Unidad IV y es **panorama**: dos herramientas que no entran en la Práctica 5 ni en el
proyecto, pero que aparecen en cualquier código MPI real y en el Examen 3 como lectura de código. Lee cada paso y,
en las pausas, responde **antes** de abrir la respuesta. Al final hay tres huecos para que completes tú.

## Problema

Una matriz `a[N][N]` de `double` está guardada por filas (como siempre en C). El rango 0 debe enviar **una
columna** al rango 1 con una sola llamada y sin copiarla a un arreglo auxiliar. Después, los `p` procesos se
organizan como una malla de 2 filas y cada fila debe calcular una suma **solo entre los procesos de esa fila**.

## Plan en tres líneas

1. Describir la forma "una columna" con `MPI_Type_vector`, registrarla con `MPI_Type_commit`, usarla en
   `MPI_Send`/`MPI_Recv` y liberarla con `MPI_Type_free`.
2. Partir `MPI_COMM_WORLD` en un comunicador por fila con `MPI_Comm_split(color = fila, key = posición)` y hacer
   `MPI_Allreduce` sobre ese comunicador.
3. Reunir todo en el rango 0 y verificar: `VERIFICACION OK` solo si cada dato llegó donde debía.

## Paso 1 · Describir la columna una sola vez

En memoria, `a[0][2]`, `a[1][2]`, `a[2][2]` y `a[3][2]` están separados por `N = 4` elementos (una fila
completa). Un tipo derivado (*derived datatype*) describe exactamente esa forma:

```c
MPI_Datatype col_t;
MPI_Type_vector(N,        /* count:       N bloques                         */
                1,        /* blocklength: de 1 elemento cada uno            */
                N,        /* stride:      separados N elementos (una fila)  */
                MPI_DOUBLE, &col_t);
MPI_Type_commit(&col_t);  /* sin esto el tipo no se puede usar en una comunicación */
/* ... comunicaciones ... */
MPI_Type_free(&col_t);    /* liberar es parte del contrato */
```

`MPI_Send(&a[0][COL], 1, col_t, 1, 100, MPI_COMM_WORLD)` envía **un** elemento de tipo "columna" que empieza en
`a[0][COL]`: MPI recorre la memoria con el patrón del tipo y manda los 4 `double`. Sin tipos derivados harías 4
envíos de 1 `double` (4 latencias) o copiarías la columna a un arreglo auxiliar y la mandarías como
`4, MPI_DOUBLE` (una copia extra por mensaje).

**Pausa 1.** ¿Qué tres números describirían una **fila** de la misma matriz con `MPI_Type_vector`? ¿Y la
**diagonal principal**?

<details><summary>Respuesta</summary>

Una fila son `N` elementos contiguos: `MPI_Type_vector(N, 1, 1, MPI_DOUBLE, …)` o, equivalente y más claro,
`MPI_Type_vector(1, N, 1, …)`; en la práctica una fila no necesita tipo derivado: se manda como `N, MPI_DOUBLE`
desde `&a[i][0]`. La diagonal principal son `N` elementos separados por `N + 1` posiciones (bajar una fila y
avanzar una columna): `MPI_Type_vector(N, 1, N + 1, MPI_DOUBLE, …)` desde `&a[0][0]`. El tipo no sabe de matrices:
solo describe un patrón de bloques y saltos sobre memoria.
</details>

## Paso 2 · Enviar y recibir con la misma firma, no con el mismo acomodo

El rango 1 recibe la columna de dos maneras distintas (el rango 0 la envía dos veces, con etiquetas 100 y 101):

```c
/* Recepción 1: como 4 doubles contiguos. */
MPI_Recv(col, N, MPI_DOUBLE, 0, 100, MPI_COMM_WORLD, &st);
MPI_Get_count(&st, MPI_DOUBLE, &count);          /* count == 4 */

/* Recepción 2: con el mismo tipo columna, sobre una matriz en ceros: cae en la columna 1 de b. */
memset(b, 0, sizeof b);
MPI_Recv(&b[0][1], 1, col_t, 0, 101, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
```

**Pausa 2.** El emisor manda `1, col_t` y el receptor recibe `N, MPI_DOUBLE`. ¿Por qué esto es correcto y no un
error de "tipos que no coinciden"?

<details><summary>Respuesta</summary>

Lo que tiene que coincidir es la **firma de tipo** (*type signature*): la secuencia de tipos básicos que viajan
en el mensaje. `1 × col_t` es la secuencia (`double`, `double`, `double`, `double`); `4 × MPI_DOUBLE` es la misma
secuencia. El **acomodo en memoria** (dónde están esos 4 `double` en el emisor y dónde caen en el receptor) lo
decide el tipo de cada lado y no tiene que ser igual: por eso la columna salteada del rango 0 llega contigua en
`col` y, con el otro tipo, llega salteada en la columna 1 de `b`. Lo que sí sería un error: enviar 4 `double`
y recibir 4 `MPI_INT` (misma cantidad de bytes, distinta firma), o recibir con capacidad para menos elementos
de los que llegan (`MPI_ERR_TRUNCATE`, el error de `caza3`).
</details>

## Paso 3 · Salida real de la Parte A

```
Parte A · columna 2 de una matriz 4x4 enviada con MPI_Type_vector(4, 1, 4, MPI_DOUBLE)
  recibida en el rango 1 como 4 MPI_DOUBLE contiguos: [ 2 12 22 32 ]
  recibida en el rango 1 con el mismo tipo, colocada en la columna 1 de una matriz en ceros:
       0    2    0    0
       0   12    0    0
       0   22    0    0
       0   32    0    0
```

`a[i][j] = 10·i + j`, así que la columna 2 es `2, 12, 22, 32`: un vistazo basta para verificar.

**Pausa 3.** Si el rango 0 escribiera `MPI_Send(&a[0][COL], 2, col_t, …)` esperando enviar las columnas `COL` y
`COL + 1`, ¿qué enviaría en realidad?

<details><summary>Respuesta</summary>

No las dos columnas. Cuando `count > 1`, el segundo elemento empieza donde termina la **extensión** (*extent*) del
primero, y la extensión de `col_t` va desde su primer `double` hasta el último: `(3·4 + 1) = 13` elementos
(104 bytes). El segundo "elemento columna" empezaría 13 posiciones después de `a[0][2]`, es decir en `a[3][3]`, y
sus cuatro `double` caerían fuera de la matriz: comportamiento indefinido (lee basura o falla). Para que
"la siguiente columna" empiece un `double` más adelante hay que redefinir la extensión con
`MPI_Type_create_resized(col_t, 0, sizeof(double), &col_resized_t)` y usar ese tipo. Es el detalle que más
confunde de los tipos derivados; está en `notas-estudiante.md` §1 y en el estándar (capítulo *Datatypes*).
</details>

## Paso 4 · Un comunicador por fila

Los `p` procesos se ven como una malla de `ROWS = 2` filas y `cols = p / 2` columnas. Se quiere una colectiva
**solo entre los procesos de la misma fila**:

```c
int color = rank / cols;      /* los de igual color quedan en el mismo comunicador nuevo */
int key   = rank % cols;      /* orden (rango) dentro del comunicador nuevo              */
MPI_Comm row_comm;
MPI_Comm_split(MPI_COMM_WORLD, color, key, &row_comm);

int row_rank, row_size;
MPI_Comm_rank(row_comm, &row_rank);
MPI_Comm_size(row_comm, &row_size);

int row_sum;
MPI_Allreduce(&rank, &row_sum, 1, MPI_INT, MPI_SUM, row_comm);   /* suma de rangos mundiales de MI fila */
/* ... */
MPI_Comm_free(&row_comm);
```

`MPI_Comm_split` es una **colectiva** sobre el comunicador original: la llaman los `p` procesos, cada uno con su
`color`, y cada uno recibe el comunicador de su grupo. Un proceso que no quiera quedar en ninguno pasa
`MPI_UNDEFINED` como color y recibe `MPI_COMM_NULL`.

**Pausa 4.** Con `-np 4`, el rango 3 ejecuta el `MPI_Allreduce` sobre `row_comm`. ¿Qué otros procesos tienen que
ejecutar ese `MPI_Allreduce` para que el del rango 3 termine? ¿Qué pasaría si el rango 1 no lo llamara?

<details><summary>Respuesta</summary>

Solo el rango 2: con `cols = 2`, los colores son `0, 0, 1, 1`, así que `row_comm` del rango 3 contiene a los
rangos mundiales 2 y 3 (con rangos 0 y 1 dentro de la fila). Una colectiva es una cita a la que van **todos los
procesos del comunicador sobre el que se llama**, no todos los de `MPI_COMM_WORLD` (idea errónea 18, versión
comunicadores). Si el rango 1 no llamara al suyo, el que se quedaría esperando sería el rango 0 (su compañero de
fila), no el 3. El programa después hace `MPI_Gather` y `MPI_Reduce` sobre `MPI_COMM_WORLD`: ahí sí van los cuatro.
</details>

**Pausa 5.** ¿Qué cambiarías para tener un comunicador por **columna** de la malla en lugar de por fila?

<details><summary>Respuesta</summary>

Intercambiar los papeles: `color = rank % cols` (los que comparten columna) y `key = rank / cols` (su fila, para
ordenarlos de arriba abajo). Con `-np 4`: colores `0, 1, 0, 1`; el comunicador de la columna 0 tiene a los rangos
0 y 2. Un mismo proceso puede pertenecer a los dos comunicadores a la vez (fila y columna); así se escriben los
algoritmos de matrices en 2D.
</details>

## Paso 5 · Salida real de la Parte B

Con `-np 4` (malla 2 × 2):

```
Parte B · malla de 2 x 2 procesos; MPI_Comm_split(color = rango / 2, key = rango % 2)
  rango 0 -> fila 0, rango en la fila 0 de 2, suma de rangos de la fila = 1
  rango 1 -> fila 0, rango en la fila 1 de 2, suma de rangos de la fila = 1
  rango 2 -> fila 1, rango en la fila 0 de 2, suma de rangos de la fila = 5
  rango 3 -> fila 1, rango en la fila 1 de 2, suma de rangos de la fila = 5
VERIFICACION OK
```

Con `-np 6` (malla 2 × 3) la fila 1 son los rangos 3, 4 y 5 y su suma es 12:

```
Parte B · malla de 2 x 3 procesos; MPI_Comm_split(color = rango / 3, key = rango % 3)
  rango 0 -> fila 0, rango en la fila 0 de 3, suma de rangos de la fila = 3
  rango 1 -> fila 0, rango en la fila 1 de 3, suma de rangos de la fila = 3
  rango 2 -> fila 0, rango en la fila 2 de 3, suma de rangos de la fila = 3
  rango 3 -> fila 1, rango en la fila 0 de 3, suma de rangos de la fila = 12
  rango 4 -> fila 1, rango en la fila 1 de 3, suma de rangos de la fila = 12
  rango 5 -> fila 1, rango en la fila 2 de 3, suma de rangos de la fila = 12
VERIFICACION OK
```

## Paso 6 · Dos errores clásicos que el programa evita a propósito

**Imprimir desde todos los rangos.** Cada proceso arma `info[4] = {rank, color, row_rank, row_sum}` y el rango 0
los reúne con `MPI_Gather` antes de imprimir. Si cada rango hiciera su `printf`, las líneas saldrían en un orden
distinto en cada corrida (S01 §6) y `tests/run_tests.sh` no podría comparar la salida con una esperada. Regla:
**la salida que se verifica la imprime un solo rango con datos que le enviaron los demás.**

**Usar el rango como coordenada sin verificar `p`.** `color = rank / cols` solo tiene sentido si `p` es múltiplo
de `ROWS`. El programa lo comprueba al inicio y aborta con un mensaje de uso; con `-np 3`:

```
Uso: mpirun -np <par >= 2> ./ejemplo_columna_split [--sin-commit]
```

(Open MPI agrega después unas líneas `ORTE_ERROR_LOG` al abortar; son del lanzador, no del programa.) Sin esa
verificación, con `-np 3` el rango 2 tendría `color = 2` y una "fila" de un solo proceso: el programa terminaría
**sin error y con un resultado que no es el que crees**. Es el peor síntoma: no hay cuelgue ni aborto que avise.

## Variante que falla · usar el tipo sin `MPI_Type_commit`

`./ejemplo_columna_split --sin-commit` salta la línea `MPI_Type_commit(&col_t)`. Salida real (recortada):

```
[vm:04435] *** An error occurred in MPI_Send
[vm:04435] *** reported by process [2108751873,0]
[vm:04435] *** on communicator MPI_COMM_WORLD
[vm:04435] *** MPI_ERR_TYPE: invalid datatype
[vm:04435] *** MPI_ERRORS_ARE_FATAL (processes in this communicator will now abort,
```

`MPI_Type_vector` solo **construye** la descripción; `MPI_Type_commit` la deja lista para comunicar (la
implementación puede optimizarla en ese momento). Un tipo sin *commit* sirve para construir otros tipos a
partir de él, pero no para `Send`/`Recv`. Este es un error amable: aborta con mensaje. Compáralo con el de
`-np 3` sin verificación, que no avisa.

## Huecos para completar (desvanecimiento; respuestas en `<details>`)

**Hueco 1.** Escribe la llamada que describe una **submatriz de 2 × 2** que empieza en `a[1][1]` de una matriz
`4 × 4` de `double` (dos bloques de dos elementos, separados una fila).

<details><summary>Respuesta</summary>

`MPI_Type_vector(2, 2, 4, MPI_DOUBLE, &sub_t)`; se envía con `MPI_Send(&a[1][1], 1, sub_t, …)` tras el *commit*.
Cubre `a[1][1], a[1][2], a[2][1], a[2][2]`. Para bloques en matrices más grandes conviene
`MPI_Type_create_subarray`, que recibe tamaños y desplazamientos en vez de pedirte el `stride`.
</details>

**Hueco 2.** En la Parte B, ¿cuántas veces se llama `MPI_Comm_split` en total con `-np 6` y cuántos
comunicadores nuevos existen al terminar la llamada?

<details><summary>Respuesta</summary>

Seis llamadas (una por proceso: es colectiva) y **dos** comunicadores nuevos (colores 0 y 1), cada uno con tres
procesos. Cada proceso solo tiene el *handle* del suyo; `MPI_Comm_free` también lo llaman los seis.
</details>

**Hueco 3.** Un compañero cambia `MPI_Allreduce(…, row_comm)` por `MPI_Allreduce(…, MPI_COMM_WORLD)` "para
simplificar". ¿Qué imprime la columna `suma de rangos de la fila` con `-np 4` y por qué `VERIFICACION` dice `FAIL`?

<details><summary>Respuesta</summary>

Imprime 6 en las cuatro filas (0 + 1 + 2 + 3): la suma ya no es por fila. El rango 0 compara cada suma con la
esperada de su fila (1 para la fila 0, 5 para la fila 1) y marca `FAIL`. El programa no se cuelga ni aborta:
los cuatro llamaron a la misma colectiva sobre el mismo comunicador, así que para MPI todo está bien. Solo la
verificación contra un resultado esperado detecta que el comunicador era el equivocado.
</details>

## Qué te llevas

1. Un tipo derivado describe **una vez** la forma de los datos en memoria (bloques, longitud, salto); se
   `commit`, se usa, se `free`. Enviar y recibir exigen la misma **firma**, no el mismo acomodo.
2. `MPI_Comm_split(comm, color, key, &nuevo)` reparte los procesos por `color` y los ordena por `key`. Una
   colectiva la llaman **todos los procesos del comunicador sobre el que se llama**, ni más ni menos.
3. Los errores que avisan (`MPI_ERR_TYPE`, `MPI_ERR_TRUNCATE`) son los fáciles. Los que no avisan (comunicador
   equivocado, malla imposible, colectiva que falta y "funciona" con datos chicos) solo se detectan verificando
   el resultado contra uno esperado, con distintos `n` y distintos `-np`. Eso es lo que hace `tests/run_tests.sh`
   y lo que debe hacer el `make test` de tu V2.
