> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S03 · martes 10 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# S03 · Notas: operaciones colectivas y el producto matriz-vector distribuido

Si faltaste: lee esto (10 min), haz `ejemplo-resuelto.md` con sus pausas (20 min) y la práctica guiada completa
(`practica-guiada/README.md`, 30 min). La Práctica 5 (Partes A y B) la haces con tu equipo según
`practicas/P5-mpi/README.md`.

## 1. Qué es una colectiva y la regla de oro

Una **operación colectiva** (*collective operation*) es una comunicación en la que participan **todos** los
procesos de un comunicador (`MPI_COMM_WORLD`, por ahora). Sustituye a un patrón de `Send`/`Recv` que se repite:
"el 0 le manda lo mismo a todos", "cada uno le manda su pedazo al 0", "combinar un valor de cada uno".

Palabras clave: *raíz* (*root*: el rango que tiene el dato al principio o lo recibe al final), *comunicador*,
*cuenta por rango*, *operación de reducción*.

**Regla de oro.** Todas las colectivas las llaman **todos** los procesos del comunicador, con la misma raíz, el
mismo tipo y cuentas compatibles. En el código la llamada aparece **una vez**, fuera de `if (rank == …)`. La
misma línea es envío en la raíz y recepción en los demás; el papel lo decide `rank`, no el texto. Si un proceso
no la llama, MPI **no avisa**: según el tamaño del mensaje, el programa se cuelga o sigue con datos
equivocados (`matvec_bcast_buggy`: 8 `double` → `y` con ceros; 1 024 `double` → cuelgue). Idea errónea 18.

## 2. Las siete colectivas

La pregunta que elige la colectiva: **¿quién tiene el dato antes y quién lo necesita después?**

| Colectiva | Antes | Después | Firma | Equivalente en OpenMP |
|---|---|---|---|---|
| `MPI_Bcast` | la raíz | **todos**, el mismo dato | `(buf, count, type, root, comm)` | `firstprivate`/variable compartida leída por todos |
| `MPI_Scatter` | la raíz, `p` bloques iguales | cada rango **su** bloque | `(sendbuf, sendcount, type, recvbuf, recvcount, type, root, comm)` | reparto de iteraciones de `omp for` |
| `MPI_Gather` | cada rango un bloque | la **raíz**, los `p` bloques en orden de rango | `(sendbuf, sendcount, type, recvbuf, recvcount, type, root, comm)` | escribir cada hilo su tramo de un arreglo compartido |
| `MPI_Reduce` | cada rango un valor | la **raíz**, combinados con `op` | `(sendbuf, recvbuf, count, type, op, root, comm)` | `reduction(op:x)` |
| `MPI_Allreduce` | cada rango un valor | **todos**, combinados | `(sendbuf, recvbuf, count, type, op, comm)` | `reduction` + leer el resultado en todos |
| `MPI_Allgather` | cada rango un bloque | **todos**, los `p` bloques | `(sendbuf, sendcount, type, recvbuf, recvcount, type, comm)` | arreglo compartido completo tras la barrera |
| `MPI_Barrier` | — | nadie sigue hasta que todos llegaron | `(comm)` | `#pragma omp barrier` |

Hechos que conviene memorizar:

- `sendcount`/`recvcount` de `Scatter` y `Gather` son **por rango** y en **elementos** del tipo (no bytes, no el
  total). Para repartir `local_n` filas de `n` columnas: `local_n * n`.
- `Gather` y `Reduce` dejan el resultado **solo en la raíz**; en los demás rangos el búfer de recepción no se toca
  (en `colectivas_demo` conserva el `-1`). Los demás rangos pasan igual un `recvbuf` (puede ser `NULL`).
- Operaciones de reducción: `MPI_SUM`, `MPI_PROD`, `MPI_MAX`, `MPI_MIN`, `MPI_LAND`, `MPI_LOR`, `MPI_MAXLOC`,
  `MPI_MINLOC`, entre otras. `count > 1` reduce elemento a elemento (un histograma de `k` bins en una llamada).
- `MPI_IN_PLACE` como `sendbuf` (en la raíz de `Reduce`, en todos en `Allreduce`) usa el mismo búfer de entrada y
  salida. Útil; no obligatorio en este curso.
- `Allreduce` ≈ `Reduce` + `Bcast` y `Allgather` ≈ `Gather` + `Bcast`, en una sola colectiva y sin que la raíz sea
  cuello de botella. Si todos necesitan el resultado, usa la versión `All…`.
- `Scatter`/`Gather` exigen bloques **iguales** (`n` múltiplo de `p`). Para bloques distintos existen
  `MPI_Scatterv` y `MPI_Gatherv`, que reciben un arreglo de cuentas y otro de desplazamientos (en elementos),
  ambos leídos solo por la raíz (`practica-guiada/matvec_scatterv.c`: con `n = 10` y `p = 4` reparte `3 3 2 2`).
- `MPI_Barrier` sincroniza el **avance** de los procesos, no el orden en que imprimen ni la llegada de datos:
  después de la barrera las líneas siguen saliendo mezcladas. Se usa para alinear cronómetros y poco más.
- Por dentro, la implementación suele usar árboles: `Bcast` a `p` procesos toma `⌈log₂ p⌉` pasos en vez de
  `p − 1` envíos seriados desde la raíz (lo calculaste en la tarea de S02, ejercicio 3).

## 3. El ejemplo resuelto en una pantalla: `y = A·x` por filas

Rango 0 con `A` (`n × n`) y `x`; resultado en el rango 0; `local_n = n / p` filas por rango. Tres colectivas de
comunicación y una de medición:

```c
MPI_Scatter(A, local_n * n, MPI_DOUBLE, A_local, local_n * n, MPI_DOUBLE, 0, MPI_COMM_WORLD); /* filas */
MPI_Bcast(x, n, MPI_DOUBLE, 0, MPI_COMM_WORLD);                                              /* x a todos */
local_matvec(A_local, x, y_local, local_n, n);                                               /* sin mensajes */
MPI_Gather(y_local, local_n, MPI_DOUBLE, y, local_n, MPI_DOUBLE, 0, MPI_COMM_WORLD);         /* y en el 0 */
MPI_Reduce(&t_compute, &t_compute_max, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);           /* el más lento */
```

Ninguna llamada está dentro de un `if (rank == …)`. Con `n = 8` y `p = 4` cada rango recibe dos filas (el rango 2,
las filas 4 y 5: su primera fila local empieza `4 5 6 …`) y el rango 0 imprime `y = 168, 204, …, 420`,
`checksum = 2352`, igual que `matvec_seq`. La versión con `Send`/`Recv` (`matvec_p2p.c`) da lo mismo con el triple
de llamadas, tres etiquetas y dos ramas `if`; en tiempo son parecidas con 4 procesos en una máquina.

Si **todos** los rangos necesitan `y` completo (el `y` de esta iteración es el `x` de la siguiente), el `Gather`
se cambia por `MPI_Allgather(y_local, local_n, MPI_DOUBLE, y, local_n, MPI_DOUBLE, MPI_COMM_WORLD)`. Si todos
necesitan la norma ‖y‖, cada rango suma los cuadrados de su bloque y una `MPI_Allreduce(&local_sq, &total, 1,
MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD)` deja el total en todos (fase Crear de la práctica guiada).

## 4. Cuánto cuesta repartir

Medido en la máquina de autoría (4 núcleos, VM compartida, carga ajena ≈ 3; protocolo de `medir.sh`: mediana de
5 tras calentamiento), `n = 4096`:

| Configuración | Mediana (s) | *Speedup* |
|---|---|---|
| `matvec_seq`, 40 productos | 1.092 | 1.00 |
| `matvec_collectives -np 4`, 40 productos (matriz repartida una vez) | 0.360 | 3.03 |
| `matvec_seq`, 1 producto | 0.043 | 1.00 |
| `matvec_collectives -np 4`, 1 producto | 0.115 | 0.37 |

Desglose con 4 procesos y un producto: `scatter = 0.085 s`, `bcast = 0.00005 s`, `calcular = 0.0076 s`,
`gather = 0.0007 s`. El `scatter` mueve `n² × 8` bytes = 134 MB (128 MiB); un producto hace `2n²` operaciones. Mismo orden
`n²`, pero la red es más lenta que la ALU: con un solo producto **la comunicación domina** (92 % del tiempo) y el
*speedup* es menor que 1; con 40 productos el reparto se amortiza y el *speedup* se acerca a `p`. Idea errónea 21:
la comunicación no es gratis; a veces es el costo principal. Salidas: repartir una vez y usar muchas veces, o no
repartir (cada rango genera o lee sus propias filas). Los números cambian en tu máquina y con la carga (otra
corrida con carga ≈ 5–6 dio *speedup* 1.9): por eso el protocolo pide declarar el entorno.

## 5. Errores frecuentes

1. Poner una colectiva dentro de `if (rank == 0)` "porque el 0 es el que tiene los datos". → Todos la llaman; la
   raíz va en el argumento `root` (idea errónea 18).
2. Creer que, tras `Gather` o `Reduce`, los rangos ≠ 0 "ven" el resultado. → Solo la raíz lo tiene; cada proceso
   tiene su memoria (idea errónea 16). Si todos lo necesitan: `Allgather`/`Allreduce`.
3. `sendcount = n * n` en `Scatter`, o en bytes, o en filas. → Elementos **por rango**: `local_n * n`.
4. Usar `Scatter` con `n` no múltiplo de `p`. → Los programas de esta carpeta lo rechazan; usa `Scatterv`.
5. Pasar valores en vez de direcciones a `Reduce`/`Allreduce` (`local_sq` en lugar de `&local_sq`). → Compila con
   advertencia o truena; los búferes son punteros.
6. Un `if` que corta el flujo en algunos rangos antes de una colectiva (`if (my_rows == 0) return;`). → Los
   demás esperan para siempre. Un rango con cero filas también llama a `Scatterv`/`Gatherv` (con cuenta 0).
7. Confiar en que `MPI_Barrier` ordena la salida o "entrega" los datos. → Solo sincroniza el avance.
8. Medir un solo producto y concluir que "MPI es más lento". → Distingue el costo de repartir (una vez) del
   cómputo (muchas veces); mide con el protocolo y reporta el desglose.
9. Reportar el tiempo de cómputo del rango 0 como el del programa. → El que manda es el rango más lento
   (`Reduce` con `MPI_MAX`).

## 6. Para saber más

- MPI Forum, *MPI: A Message-Passing Interface Standard*, versión 4.1 (2023), capítulo *Collective
  Communication*: secciones *Barrier Synchronization*, *Broadcast*, *Gather*, *Scatter*, *Gather-to-all* y
  *Global Reduction Operations* (incluye la tabla de operaciones predefinidas y `MPI_IN_PLACE`).
  <https://www.mpi-forum.org/docs/>
- Documentación de Open MPI 4.1 (páginas de manual): `MPI_Bcast(3)`, `MPI_Scatter(3)`, `MPI_Scatterv(3)`,
  `MPI_Gather(3)`, `MPI_Reduce(3)`, `MPI_Allreduce(3)`, `MPI_Allgather(3)`, `MPI_Barrier(3)`.
  <https://www.open-mpi.org/doc/>
- Pacheco, P. y Malensek, M., *An Introduction to Parallel Programming*, 2.ª ed., Morgan Kaufmann, 2022,
  capítulo 3 (*Distributed-Memory Programming with MPI*), sección 3.4 *Collective communication*: comunicación en
  árbol, `MPI_Reduce`, colectivas frente a punto a punto, `MPI_Allreduce`, `MPI_Bcast`, distribución de datos,
  `MPI_Scatter`, `MPI_Gather`, `MPI_Allgather` y el producto matriz-vector.
