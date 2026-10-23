> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S04 · jueves 12 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# Notas · Descomposición de dominio y celdas fantasma

## 1. La idea en una tabla

| Término | Qué es | En Jacobi 1D |
|---|---|---|
| Descomposición de dominio (*domain decomposition*) | Repartir los **datos** entre procesos; cada uno calcula sobre los suyos | Cada rango recibe un bloque contiguo de celdas |
| Reparto por bloques con residuo | `local_n = n/p`, más 1 para los primeros `n % p` rangos; `offset = rank·(n/p) + min(rank, n % p)` | `n=13, p=5` → tamaños 3,3,3,2,2; la carga difiere en ≤ 1 celda |
| Celda fantasma (*ghost cell*, halo) | Copia local de un dato que pertenece a otro proceso y que el *stencil* necesita | `u[0]` y `u[local_n+1]`; el arreglo local mide `local_n + 2` |
| Intercambio de halos (*halo exchange*) | Refrescar las celdas fantasma antes de calcular | 2 mensajes de 1 `double` por rango y por iteración |
| `MPI_PROC_NULL` | Vecino nulo: enviar no hace nada, recibir no toca el búfer | Los rangos de las orillas usan el mismo código; su halo guarda la frontera física |
| Convergencia global | Todos deciden con el mismo dato | `MPI_Allreduce(&local_diff, &global_diff, 1, MPI_DOUBLE, MPI_MAX, comm)` |
| Reconstrucción | Juntar los bloques en un proceso | `MPI_Gatherv` con `counts`/`displs` calculados con la misma función de reparto |

Índices: la frontera izquierda es la celda global 0, el interior va de 1 a `n`, la frontera derecha es `n+1`. La celda local `i`
del rango `r` es la global `offset + i`.

## 2. Dos formas de intercambiar halos

**Con `MPI_Sendrecv`** (envía y recibe en una sola llamada; no se interbloquea aunque todos la ejecuten a la vez):

```c
MPI_Sendrecv(&u[local_n], 1, MPI_DOUBLE, right, TAG_TO_RIGHT,   /* mi última celda → derecha      */
             &u[0],       1, MPI_DOUBLE, left,  TAG_TO_RIGHT,   /* ← última celda del de la izq.  */
             MPI_COMM_WORLD, MPI_STATUS_IGNORE);
MPI_Sendrecv(&u[1],           1, MPI_DOUBLE, left,  TAG_TO_LEFT, /* mi primera celda → izquierda */
             &u[local_n + 1], 1, MPI_DOUBLE, right, TAG_TO_LEFT, /* ← primera celda del de la der. */
             MPI_COMM_WORLD, MPI_STATUS_IGNORE);
```

**Sin bloqueo** (`MPI_Irecv` + `MPI_Isend` + `MPI_Waitall`): se publican las cuatro operaciones y se espera a todas. Entre el
`Isend` y el `Waitall` no se puede tocar el búfer enviado; entre el `Irecv` y el `Waitall` no se puede leer el recibido.
Patrón: recepciones primero, luego envíos, luego `MPI_Waitall(4, reqs, MPI_STATUSES_IGNORE)`. En S05 verás para qué sirve el
hueco entre publicar y esperar: calcular las celdas interiores mientras viajan los halos.

Etiquetas: el mensaje que viaja hacia la derecha lleva `TAG_TO_RIGHT` tanto en el `Send` del emisor como en el `Recv` del receptor.
Es el mismo mensaje visto desde los dos lados.

## 3. El ejemplo resuelto en cinco líneas

`n = 12, p = 3, tol = 1e-3`. Rango 1 tiene las celdas 5–8; envía la 5 al rango 0 y la 8 al rango 2; recibe la 4 (de 0) en `u[0]` y
la 9 (de 2) en `u[5]`. Secuencial y MPI: `iteraciones=280`, `checksum=5.998646183794e+02`, las 12 celdas idénticas. Si se omite el
intercambio del halo izquierdo (`jacobi1d_mpi_buggy.c`), el programa termina sin error en 49 iteraciones con las celdas 5–12 en 0:
cada rango resolvió una barra con una frontera falsa. Detalle en `ejemplo-resuelto.md`.

## 4. Cómo se verifica una versión MPI

1. La secuencial es la referencia; se corre primero.
2. Mismo número de iteraciones y mismos valores con tolerancia (`tests/run_tests.sh` usa 1e-12; para sumas largas se usaría más).
3. Se prueba con `p = 1` (sin halos), con `p` que no divide a `n` (reparto desigual) y con `p` mayor que el número de bloques "cómodos".
4. Se prueba un caso que para por `max_iter` y otro que para por `tol`.
5. Un error de halo **no produce mensaje de error**; solo la comparación lo detecta.

## 5. Errores frecuentes

| Error | Síntoma | Qué revisar |
|---|---|---|
| Halo que no se actualiza | Resultado incorrecto, `convergio=1`, sin error | ¿Hay una recepción para `u[0]` **y** otra para `u[local_n+1]` en cada iteración? |
| Índice local usado como global (o al revés) | Predicción "el rango 1 envía u[1]"; fuente de calor en el lugar equivocado | Global = `offset + local`; conviértelo una sola vez |
| Solo el rango 0 llama a `MPI_Allreduce` | Se cuelga | Las colectivas las llaman todos (idea errónea 18) |
| Cada rango decide con su `local_diff` | Rangos terminan en iteraciones distintas; `Gatherv` se cuelga o mezcla estados | Una sola decisión global por iteración |
| Leer el halo antes de `MPI_Waitall` | Resultados que cambian de corrida a corrida | Nada se lee ni se escribe entre `Isend/Irecv` y `Waitall` |
| Etiquetas cruzadas en `Irecv` | Se cuelga | La etiqueta del `Recv` es la del `Send` que lo alimenta |
| Fronteras solo en `u` y no en `u_new` | La frontera "desaparece" en las iteraciones pares | Doble búfer: los valores fijos van en ambos arreglos |
| Más procesos que núcleos "para que vaya más rápido" | Tiempos enormes y erráticos | Sobre-suscripción (idea errónea 20); se declara y se mide aparte (S05) |

## 6. Hacia el proyecto y hacia S05

- **Proyecto.** Si tu problema es una malla (Jacobi 2D, autómatas celulares, filtros de imagen), la V2 (OpenMP) reparte filas entre
  hilos sin halos porque la memoria es compartida, pero el doble búfer y la partición por bloques son los mismos. En la V3 (CUDA)
  cada bloque de hilos copia a memoria compartida su mosaico **más un borde de celdas vecinas**: es exactamente un halo, cargado
  desde memoria global en lugar de recibido por mensaje. La descomposición se diseña una vez; cambia cómo llega el halo.
- **S05 (martes 17 de noviembre, 08:30, Lab 2 de P5).** Costo por iteración: `local_n` actualizaciones contra 2 mensajes de
  latencia α cada uno más un `Allreduce`. Con `n` grande el cómputo domina; con `n` pequeño o `p` grande domina la comunicación
  (idea errónea 21: la comunicación no es gratis). Lleva tus valores de latencia y ancho de banda del *ping-pong* de S02.

## 7. Para saber más

- MPI Forum, *MPI: A Message-Passing Interface Standard*, versión 4.1 (mpi-forum.org/docs): capítulo de comunicación punto a punto
  (`MPI_Sendrecv`, `MPI_Isend`, `MPI_Irecv`, `MPI_Waitall`, `MPI_PROC_NULL`) y capítulo de comunicación colectiva (`MPI_Allreduce`, `MPI_Gatherv`).
- Documentación de Open MPI (docs.open-mpi.org): páginas de manual de `MPI_Sendrecv`, `MPI_Waitall`, `MPI_Gatherv` y la opción `--oversubscribe` de `mpirun`.
- Pacheco y Malensek, *An Introduction to Parallel Programming*, 2.ª ed., capítulo 3 (MPI): seguridad en programas MPI y `MPI_Sendrecv`.
