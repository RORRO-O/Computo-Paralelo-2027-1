> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S06 · jueves 19 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S06 · Notas: cierre de la Unidad IV — tipos derivados, comunicadores y los errores clásicos de MPI

Si faltaste: lee esto (15 min), haz `ejemplo-resuelto.md` con sus pausas (15 min) y la Parte 1 de
`practica-guiada/README.md` completa (los tres cazadores; 40 min). La Parte 2 del README es el taller del
proyecto: hazla con tu equipo antes del lunes 23 de noviembre. Con eso reconstruyes la sesión.

Palabras clave: tipo derivado (*derived datatype*) · firma de tipo (*type signature*) · extensión (*extent*) ·
`MPI_Type_vector` / `MPI_Type_commit` / `MPI_Type_free` · comunicador (*communicator*) · `MPI_Comm_split` ·
color y clave (*key*) · programa seguro (*safe*) · emparejamiento (*matching*) · capacidad del `MPI_Recv`.

## 1. Tipos derivados: describir la forma de los datos una sola vez

Un mensaje MPI es `count` elementos de un `datatype`. Con tipos básicos solo puedes mandar datos **contiguos**.
Un tipo derivado describe un patrón sobre memoria (bloques, longitud de bloque, salto) y después se usa como
cualquier otro tipo. Tres llamadas, siempre en este orden:

```c
MPI_Type_vector(count, blocklength, stride, oldtype, &newtype);  /* construir la descripción          */
MPI_Type_commit(&newtype);                                        /* dejarla lista para comunicar      */
/* ... MPI_Send(buf, 1, newtype, ...) / MPI_Recv(buf, 1, newtype, ...) ... */
MPI_Type_free(&newtype);                                          /* liberar cuando ya no se necesite  */
```

| Constructor (panorama) | Describe | Ejemplo |
|---|---|---|
| `MPI_Type_contiguous(n, old, &t)` | `n` elementos seguidos | Una fila; un registro de `n` `double` |
| `MPI_Type_vector(count, blen, stride, old, &t)` | `count` bloques de `blen` elementos, cada `stride` elementos | **Una columna**: `(N, 1, N)`; la diagonal: `(N, 1, N+1)`; una submatriz `2×2`: `(2, 2, N)` |
| `MPI_Type_indexed(count, blens[], displs[], old, &t)` | Bloques de tamaños y posiciones arbitrarios | El triángulo superior de una matriz |
| `MPI_Type_create_struct(count, blens[], displs[], types[], &t)` | Campos de tipos distintos | Un `struct { int id; double x[3]; }` |
| `MPI_Type_create_subarray(ndims, sizes[], subsizes[], starts[], order, old, &t)` | Un bloque de un arreglo multidimensional | El mosaico `[r0..r1) × [c0..c1)` de una malla 2D |

Dos reglas que resuelven la mayoría de las dudas:

- **Lo que debe coincidir entre `Send` y `Recv` es la firma de tipo**, la secuencia de tipos básicos que viajan,
  no el acomodo. Enviar `1 × columna` (4 `double` salteados) y recibir `4 × MPI_DOUBLE` (contiguos) es correcto;
  el receptor decide dónde caen. Enviar `double` y recibir `MPI_INT` no lo es, aunque midan lo mismo.
- **La extensión de un tipo vector va de su primer elemento al último.** `MPI_Type_vector(4, 1, 4, MPI_DOUBLE)`
  se extiende 13 `double`; con `count = 2` el segundo elemento empezaría 13 posiciones después, no en la columna
  de al lado. Para "la siguiente columna" se ajusta la extensión con `MPI_Type_create_resized(t, 0,
  sizeof(double), &t2)`. Si solo mandas una columna por llamada, no lo necesitas.

Para qué sirven en la práctica: mandar la columna frontera de un bloque 2D (halo vertical) sin copiarla, mandar
un `struct` de parámetros en un solo `Bcast`, leer o escribir con MPI-IO la parte de un archivo que le toca a
cada proceso. Un tipo sin `commit` produce `MPI_ERR_TYPE: invalid datatype` en el primer `Send` (es la variante
que falla del ejemplo resuelto).

## 2. Comunicadores: `MPI_Comm_split`

Un comunicador es un grupo de procesos más un contexto de comunicación: un mensaje enviado en un comunicador no
puede ser recibido en otro. Hasta hoy usaste solo `MPI_COMM_WORLD`. Para hacer una colectiva entre **parte** de
los procesos (una fila de una malla, los procesos pares, un subequipo) se crea un comunicador nuevo:

```c
MPI_Comm_split(MPI_COMM_WORLD, color, key, &new_comm);   /* colectiva: la llaman TODOS los de MPI_COMM_WORLD */
MPI_Comm_rank(new_comm, &new_rank);                      /* rango dentro del nuevo (ordenado por key)        */
MPI_Allreduce(&x, &s, 1, MPI_INT, MPI_SUM, new_comm);    /* solo entre los procesos con mi color             */
MPI_Comm_free(&new_comm);
```

- `color`: los procesos con el mismo color quedan en el mismo comunicador nuevo. `MPI_UNDEFINED` = en ninguno
  (recibe `MPI_COMM_NULL`).
- `key`: ordena los rangos dentro del nuevo comunicador (empates se desempatan por el rango original).
- Malla de `ROWS` filas: `color = rank / cols`, `key = rank % cols` da un comunicador por fila; `color = rank %
  cols`, `key = rank / cols`, uno por columna. Un proceso puede estar en varios a la vez.
- **Una colectiva la llaman todos los procesos del comunicador sobre el que se llama**: ni más (los de otra fila
  tienen su propia cita) ni menos (si uno falta, los demás esperan sin aviso). Es la idea errónea 18 con
  comunicadores. Verificar `p` antes de calcular coordenadas (`p % ROWS == 0`) evita filas de un solo proceso
  que "funcionan" con un resultado equivocado.

## 3. Ejemplo resuelto en una pantalla (detalle y pausas en `ejemplo-resuelto.md`)

```c
MPI_Type_vector(N, 1, N, MPI_DOUBLE, &col_t);  MPI_Type_commit(&col_t);
if (rank == 0) MPI_Send(&a[0][COL], 1, col_t, 1, 100, MPI_COMM_WORLD);        /* 1 "columna"          */
if (rank == 1) MPI_Recv(col, N, MPI_DOUBLE, 0, 100, MPI_COMM_WORLD, &st);      /* 4 doubles contiguos  */
MPI_Type_free(&col_t);

MPI_Comm_split(MPI_COMM_WORLD, rank / cols, rank % cols, &row_comm);           /* un comunicador por fila */
MPI_Allreduce(&rank, &row_sum, 1, MPI_INT, MPI_SUM, row_comm);                 /* suma solo en mi fila    */
MPI_Comm_free(&row_comm);
```

Salida real con `-np 4`: columna `[ 2 12 22 32 ]`; sumas por fila 1 (rangos 0 + 1) y 5 (rangos 2 + 3);
`VERIFICACION OK`. Con `-np 6`: filas de tres, sumas 3 y 12. Con `--sin-commit`: `MPI_ERR_TYPE`. Con `-np 3`:
el programa rechaza la malla y aborta con un mensaje de uso.

## 4. Siete errores clásicos de MPI

Cada fila: cómo se ve, por qué pasa, cómo se detecta y la regla que lo evita. Tres tienen un programa en
`practica-guiada/` para cazarlos; los otros cuatro son la fase Crear.

| # | Error | Síntoma típico | Regla del estándar que viola | Cómo detectarlo | Cazador |
|---|---|---|---|---|---|
| 1 | Dos `MPI_Send` cruzados antes de los `Recv` (intercambio, anillo) | Funciona con mensajes chicos (`< 4 KB` en Open MPI local); **se cuelga** con grandes | `MPI_Send` solo garantiza que tu búfer se puede reutilizar; puede esperar al receptor (idea errónea 17). Un programa que depende del *buffering* es **inseguro** | Probar con `n` grande bajo `timeout 10`; razonar "¿quién recibe primero?" | `caza1` (umbral real: 505 `double` termina, 508 se cuelga) |
| 2 | Etiqueta, fuente o comunicador que no coinciden entre `Send` y `Recv` | **Se cuelga** con cualquier `n`, sin mensaje de error; el emisor puede llegar a `Finalize` | El emparejamiento exige comunicador, fuente y etiqueta iguales (o comodín en el receptor) | Imprimir (a `stderr`) sobre de cada `Send`/`Recv` que no casa; revisar que el `tag` sea el mismo valor en ambos lados | — (Crear) |
| 3 | Cuenta o tipo del `Recv` que no corresponde a lo enviado | Si llega **más** de la capacidad: aborta con `MPI_ERR_TRUNCATE`. Si llega menos: termina y el programa usa basura o datos incompletos | La cuenta del `Recv` es una **capacidad**; la firma de tipo debe coincidir; `MPI_Get_count` dice cuántos llegaron | Probar con `n` que no sea múltiplo de `p`; comparar la fórmula del tamaño en emisor y receptor | `caza3` (`n = 10, p = 4` aborta; `n = 8` y `n = 5` "funcionan") |
| 4 | Colectiva llamada por un subconjunto ("solo la raíz hace `Bcast`") | Según el tamaño: **se cuelga** (`n = 2²⁰`) o **termina con resultado incorrecto** (`n = 100`: suma 1200 en vez de 4950) | Todas las colectivas las llaman **todos** los procesos del comunicador (idea errónea 18) | Buscar colectivas dentro de un `if (rank == …)`; verificar el resultado contra una fórmula | `caza2` |
| 5 | `MPI_Finalize` con mensajes pendientes (un `Send` sin `Recv`, un `Irecv` sin `Wait`) | Cuelgue en `Finalize`, aborto, o el programa "termina" y pierde datos; varía entre implementaciones | Al llamar `Finalize` toda comunicación del proceso debe estar completa; es responsabilidad del programa | Contar envíos y recepciones por rango; `MPI_Wait` para cada solicitud no bloqueante | — (Crear) |
| 6 | Usar el rango como índice o coordenada sin verificar `p` | Con el `-np` previsto funciona; con otro: acceso fuera de rango (fallo de segmentación) o un resultado equivocado **sin aviso** | Ninguna de MPI: es C. `p` lo decide `mpirun`, no tu programa | Correr con `-np` distinto al "cómodo" (3, 5, 6); verificar `p` al inicio y abortar con mensaje de uso | — (Crear; el ejemplo lo verifica) |
| 7 | Imprimir desde todos los rangos | Salida en orden distinto en cada corrida; una `MPI_Barrier` antes del `printf` **no** la ordena | Ninguna: la salida de cada proceso viaja por el lanzador sin orden garantizado | Comparar dos corridas; ¿la prueba automática depende del orden? | — (Crear; el ejemplo imprime solo desde el rango 0) |

Los errores 1 y 4 comparten el síntoma más engañoso: **"funciona" con datos chicos** porque el mensaje cabe en el
búfer interno (límite *eager*: 4 096 bytes en Open MPI entre procesos de la misma máquina, `ompi_info --param btl
vader --level 4`). Por eso `make test` de cualquier programa MPI debe incluir un caso con mensajes grandes.

## 5. Cómo se verifica un programa MPI (lo que hace `tests/run_tests.sh` y lo que debe hacer el tuyo)

1. El rango 0 imprime una línea verificable (`VERIFICACION OK`/`FAIL`) comparando contra una fórmula o contra la
   versión secuencial con tolerancia; nadie más imprime lo que se compara.
2. Se corre con `-np 1`, con el `-np` previsto, con un `-np` que no divida a `n` y con uno "incómodo" (3, 5, 6).
3. Se corre con `n` chico (cabe en el búfer *eager*) **y** con `n` grande (no cabe), siempre bajo `timeout 10`:
   un cuelgue es un síntoma, no un accidente.
4. Un error que se ve "a veces" se documenta con el `n` o el `-np` con el que se ve **siempre**.

## 6. Lo que se revisa el lunes 23 de noviembre en la tabla de *speedup* de tu V2

El taller de hoy (`practica-guiada/README.md`, Parte 2) aplica el protocolo del curso a H2. Lo que más se
olvida, en una lista:

| Regla | Dónde falla la gente | Cómo lo detecta el revisor (`revisar_mediciones.py`) |
|---|---|---|
| `T(1)` es **V1** (el mejor secuencial con `-O2`), no V2 con un hilo; la fila `V2,1` se reporta aparte | Tabla normalizada contra `V2,1`: todo parece escalar mejor | `E1`/`E6` |
| Mediana de ≥ 5 repeticiones tras 1 de calentamiento; se reportan mín y máx | Una corrida; o promedio con un pico | `E2`/`E3`; `A2` si la dispersión supera 20 % |
| `n` fijo en toda la tabla y `T(1) ≥ 1 s` | Cambiar `n` "porque así escala"; `n` tan chico que mides el arranque | `E5`; `E4`/`A4` |
| Hilos 1, 2, 4, … hasta los núcleos **físicos**; uno más allá, marcado | La fila de 8 en una laptop de 4 núcleos como si fuera escalabilidad | `A1`; `lscpu` dice los núcleos físicos |
| Karp–Flatt `f(p) = (1/S − 1/p)/(1 − 1/p)` para cada `p > 1`, comparado con `1 − f_p` de H1 | Se calcula y no se lee; o se calcula con `S` respecto a `V2,1` | `A6` si `f` crece con `p` |
| Predicción escrita **antes** de medir; texto que dice dónde deja de escalar y por qué, con una causa verificable | "Por la sobrecarga" sin número ni experimento | Lo revisa tu pareja de revisión, no el programa |

## 7. Errores frecuentes de esta sesión

1. Pedir que el receptor use "el mismo tipo" que el emisor. → Misma **firma**; el acomodo puede diferir.
2. `MPI_Type_vector` con `count = 2` para dos columnas. → La extensión no es un `double`; usa
   `MPI_Type_create_resized` o manda una columna por llamada.
3. Olvidar `MPI_Type_commit`. → `MPI_ERR_TYPE` en el primer `Send`. Olvidar `MPI_Type_free`/`MPI_Comm_free`:
   fuga de recursos; no falla, pero no es correcto.
4. Creer que una colectiva sobre `row_comm` la esperan los `p` procesos. → Solo los del comunicador.
5. Corregir `caza1` bajando `n`. → Un programa que funciona hasta cierto `n` está mal; corrige el orden
   (paridad), usa `MPI_Sendrecv` o `Isend`/`Irecv` + `Wait` (S02 §5).
6. Corregir `caza2` poniendo `MPI_Bcast` también en un `else`. → Es la misma llamada para todos: sácala del `if`.
7. Corregir `caza3` recibiendo con capacidad `n` "por si acaso" sin preguntar `MPI_Get_count`. → Recibir más
   capacidad está bien; después tienes que saber cuántos llegaron para avanzar `offset`.
8. En la tabla de H2, normalizar contra `V2,1` y descubrirlo el lunes. → Corre el revisor hoy.

## 8. Para saber más

- MPI Forum, *MPI: A Message-Passing Interface Standard*, versión 4.1 (mpi-forum.org/docs): capítulo
  *Datatypes* (constructores `MPI_Type_vector`, `MPI_Type_create_subarray`, `MPI_Type_create_resized`;
  *commit* y *free*; reglas de correspondencia de tipos), capítulo *Point-to-Point Communication* (semántica de
  `MPI_Send`, emparejamiento, `MPI_Get_count`, programas seguros) y capítulo *Groups, Contexts, Communicators,
  and Caching* (`MPI_Comm_split`, `MPI_Comm_free`).
- Documentación de Open MPI (docs.open-mpi.org): páginas `MPI_Type_vector(3)`, `MPI_Type_commit(3)`,
  `MPI_Type_create_resized(3)`, `MPI_Comm_split(3)`, `MPI_Sendrecv(3)`, `MPI_Get_count(3)`; y `ompi_info --param
  btl vader --level 4` para el límite *eager* de tu instalación.
- Pacheco, P. y Malensek, M., *An Introduction to Parallel Programming*, 2.ª ed., Morgan Kaufmann, 2022,
  capítulo 3 (MPI): secciones sobre tipos derivados (*MPI derived datatypes*), seguridad de los programas MPI
  (*safety in MPI programs*) y evaluación de desempeño.
- `herramientas/protocolo-medicion.md` y `proyecto/hitos/H2-avance-2.md` §2.2–2.3 para la tabla del lunes 23.
