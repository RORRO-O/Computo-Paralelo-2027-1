> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S04 · jueves 12 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# Ejemplo resuelto · Jacobi 1D distribuido con celdas fantasma

Código completo en `practica-guiada/jacobi1d_seq.c` y `practica-guiada/jacobi1d_mpi.c`. Aquí se recorre el diseño paso a paso.
En cada pausa, responde antes de abrir la respuesta.

## 1. Problema

Barra de `n` celdas. Frontera izquierda fija en 100 °C, derecha en 0 °C, interior inicial en 0. Queremos la temperatura
estacionaria con el método de Jacobi, repartiendo las celdas entre `p` procesos MPI, y verificar que el resultado es el
**mismo** que el de la versión secuencial de U3-S11 (sin OpenMP).

Caso de trabajo: `n = 12`, `p = 3`, `tol = 1e-3`.

## 2. Plan (método de Foster en tres líneas)

1. **Partición y aglomeración.** Una tarea por celda; se aglomeran en `p` bloques contiguos de `n/p` celdas (el residuo
   `n % p` se reparte una celda a cada uno de los primeros rangos). Bloques contiguos porque el *stencil* solo mira a `i-1` e `i+1`:
   así cada bloque solo necesita dos valores ajenos.
2. **Comunicación.** Cada rango guarda esos dos valores ajenos en dos **celdas fantasma** (*ghost cells*, halos): `u[0]` y
   `u[local_n+1]`. Al inicio de cada iteración los refresca con su vecino: un `MPI_Sendrecv` por dirección.
3. **Decisión global.** El criterio de paro es `max |u_new - u| < tol` sobre **toda** la barra: `MPI_Allreduce(MPI_MAX)`.
   Al final, `MPI_Gatherv` reconstruye el vector en el rango 0 para imprimirlo y compararlo.

> **Pausa 1.** ¿Por qué no repartir las celdas de forma cíclica (celda `i` al rango `i % p`), como se hizo con los
> elementos independientes en S01?
> <details><summary>Respuesta</summary>
> Con reparto cíclico ninguna celda tiene a sus vecinos en el mismo proceso: cada celda necesitaría dos mensajes por iteración,
> `2·local_n` mensajes por rango en lugar de 2. El balance de carga sería igual de bueno (difiere en ≤ 1 celda, como el de bloques).
> Aglomerar en bloques contiguos es justamente agrupar tareas para reducir comunicación sin perder paralelismo (idea errónea 28:
> aglomerar no es "meter todo en un proceso").
> </details>

## 3. Código comentado (fragmentos de `jacobi1d_mpi.c`)

### 3.1 Reparto por bloques con residuo

```c
static void block_partition(int n, int p, int rank, int *local_n, int *offset) {
    int base = n / p, rem = n % p;
    *local_n = base + (rank < rem ? 1 : 0);          /* los primeros rem rangos reciben una celda extra */
    *offset  = rank * base + (rank < rem ? rank : rem); /* índice global (base 0) de mi primera celda   */
}
```

Para `n = 12, p = 3`: `base = 4, rem = 0` → rangos 0, 1, 2 con celdas globales 1–4, 5–8 y 9–12.
Para `n = 13, p = 5`: `base = 2, rem = 3` → tamaños 3, 3, 3, 2, 2.

> **Pausa 2.** ¿Qué índice global tiene la celda local `i` del rango `r`? ¿Y por qué el arreglo local se reserva con
> `local_n + 2` posiciones?
> <details><summary>Respuesta</summary>
> Global = `offset + i` (con `i` de 1 a `local_n`). Las dos posiciones extra son los halos: `u[0]` guarda la copia de la celda
> `offset` (última del vecino izquierdo) y `u[local_n+1]` la de `offset + local_n + 1` (primera del vecino derecho). En los rangos
> extremos, el halo guarda la frontera física y no se intercambia.
> </details>

### 3.2 Vecinos y fronteras

```c
int left  = (rank > 0)     ? rank - 1 : MPI_PROC_NULL;
int right = (rank < p - 1) ? rank + 1 : MPI_PROC_NULL;
if (left  == MPI_PROC_NULL) u[0] = u_new[0] = T_LEFT;                  /* solo el rango 0   */
if (right == MPI_PROC_NULL) u[local_n + 1] = u_new[local_n + 1] = T_RIGHT; /* solo el último */
```

`MPI_PROC_NULL` es un "vecino nulo": enviarle algo no hace nada y recibir de él regresa de inmediato **sin tocar el búfer**.
Por eso el mismo código de intercambio sirve para los rangos de en medio y para los de las orillas, sin `if`.

### 3.3 Intercambio de halos con `MPI_Sendrecv`

```c
/* Paso 1: mi última celda viaja a la derecha; recibo del vecino izquierdo en mi halo izquierdo. */
MPI_Sendrecv(&u[local_n], 1, MPI_DOUBLE, right, TAG_TO_RIGHT,
             &u[0],       1, MPI_DOUBLE, left,  TAG_TO_RIGHT, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
/* Paso 2: mi primera celda viaja a la izquierda; recibo del vecino derecho en mi halo derecho. */
MPI_Sendrecv(&u[1],           1, MPI_DOUBLE, left,  TAG_TO_LEFT,
             &u[local_n + 1], 1, MPI_DOUBLE, right, TAG_TO_LEFT, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
```

> **Pausa 3.** En S02 viste que dos `MPI_Send` cruzados pueden interbloquearse. ¿Por qué aquí no hay interbloqueo aunque
> todos los rangos ejecuten el Paso 1 al mismo tiempo?
> <details><summary>Respuesta</summary>
> `MPI_Sendrecv` es una sola operación que envía y recibe a la vez; el estándar garantiza que no depende del *buffering* del
> envío, así que no cae en la trampa de la idea errónea 17 ("`Send` siempre regresa de inmediato" / "siempre bloquea").
> Además, en el Paso 1 todos envían hacia la derecha y reciben desde la izquierda: cada envío tiene su recepción publicada en
> la misma llamada del vecino. La etiqueta es la misma en ambos lados (`TAG_TO_RIGHT`) porque es el **mismo** mensaje visto por emisor y receptor.
> </details>

### 3.4 Paso de Jacobi y decisión global

```c
double local_diff = 0.0;
for (int i = 1; i <= local_n; i++) {
    u_new[i] = 0.5 * (u[i - 1] + u[i + 1]);          /* misma expresión que la secuencial */
    double d = fabs(u_new[i] - u[i]);
    if (d > local_diff) local_diff = d;
}
double *tmp = u; u = u_new; u_new = tmp;             /* doble búfer */
MPI_Allreduce(&local_diff, &global_diff, 1, MPI_DOUBLE, MPI_MAX, MPI_COMM_WORLD);
if (global_diff < tol) { converged = 1; break; }
```

> **Pausa 4.** Un compañero propone ahorrar comunicación así: `if (rank == 0) MPI_Allreduce(...)` y que los demás usen su
> `local_diff`. ¿Qué pasa al ejecutarlo con 3 procesos?
> <details><summary>Respuesta</summary>
> Se cuelga. `MPI_Allreduce` es colectiva: la deben llamar **todos** los procesos del comunicador (idea errónea 18). El rango 0 se
> queda esperando dentro de `Allreduce` a los rangos 1 y 2, que nunca la llaman: ellos siguen de largo al siguiente `Sendrecv` con el
> rango 0 o, si su `local_diff` ya quedó bajo `tol` (con `n = 12` pasa en la iteración 1: todas sus celdas y halos valen 0), al
> `Gatherv` final, y ahí esperan al rango 0. Verificado en el entorno de autoría: con `timeout 10` el programa no regresa. Y aunque
> no se colgara, cada rango decidiría parar en una iteración distinta y el `Gatherv` final mezclaría estados de iteraciones diferentes.
> </details>

### 3.5 Reconstrucción

```c
for (int r = 0; r < p; r++) block_partition(n, p, r, &counts[r], &displs[r]);   /* solo rango 0 */
MPI_Gatherv(&u[1], local_n, MPI_DOUBLE, u_all, counts, displs, MPI_DOUBLE, 0, MPI_COMM_WORLD);
```

`Gatherv` (y no `Gather`) porque los bloques pueden tener tamaños distintos. Se envía desde `&u[1]`: los halos no son parte de la solución.

## 4. Salida real

```
$ ./jacobi1d_seq 12 1e-3 100000
n=12 tol=1.000e-03 max_iter=100000 p=1
iteraciones=280 convergio=1
diff_final=9.767517e-04
checksum=5.998646183794e+02

$ mpirun --oversubscribe -np 3 ./jacobi1d_mpi 12 1e-3 100000 --trace 1
reparto: rango 0 tiene local_n=4 (celdas globales 1..4); vecino izq: nadie (MPI_PROC_NULL); vecino der: rango 1
reparto: rango 1 tiene local_n=4 (celdas globales 5..8); vecino izq: rango 0; vecino der: rango 2
reparto: rango 2 tiene local_n=4 (celdas globales 9..12); vecino izq: rango 1; vecino der: nadie (MPI_PROC_NULL)
[it 1] rango 0: celdas 1..4 | envia u[1] a nadie (MPI_PROC_NULL) y u[4] a rango 1 | recibe halo izq u[0]=100.0000, halo der u[5]=0.0000
[it 1] rango 1: celdas 5..8 | envia u[5] a rango 0 y u[8] a rango 2 | recibe halo izq u[4]=0.0000, halo der u[9]=0.0000
[it 1] rango 2: celdas 9..12 | envia u[9] a rango 1 y u[12] a nadie (MPI_PROC_NULL) | recibe halo izq u[8]=0.0000, halo der u[13]=0.0000
n=12 tol=1.000e-03 max_iter=100000 p=3
iteraciones=280 convergio=1
diff_final=9.767517e-04
checksum=5.998646183794e+02
```

Mismas iteraciones, mismo `checksum`, y con `--print` las 12 celdas coinciden con diferencia máxima 0.0 (lo verifica `make test`).
Se omite `tiempo_s`: en el entorno de autoría la máquina estaba compartida y el valor cambiaba de una corrida a otra; medir es tema de S05.

> **Pausa 5.** ¿Por qué las iteraciones coinciden exactamente (280 y 280) si en la Práctica 4 la `reduction` de OpenMP daba
> resultados que solo coincidían "con tolerancia"?
> <details><summary>Respuesta</summary>
> Cada celda se calcula con la misma expresión de dos operandos en ambas versiones, en el mismo orden; no hay sumas largas que
> se reordenen. El máximo (`MPI_MAX`) es exacto en punto flotante, a diferencia de una suma (idea errónea 10 aplica a sumas,
> no a máximos). Aun así la prueba usa tolerancia 1e-12: si alguien cambia la fórmula a `(u[i-1]+u[i+1])/2` o activa FMA, podría
> haber diferencias de redondeo y la verificación sigue siendo válida.
> </details>

## 5. Variante que falla: sin halo izquierdo (`jacobi1d_mpi_buggy.c`)

Se eliminó el Paso 1 del intercambio. Nada avisa: compila sin warnings, corre, reporta `convergio=1`.

```
$ mpirun --oversubscribe -np 3 ./jacobi1d_mpi_buggy 12 1e-3 100000 --print
iteraciones=49 convergio=1
checksum=1.999941466768e+02
1 7.999900013303306e+01
2 5.999800026606614e+01
3 3.999838218126328e+01
4 1.999876409646042e+01
5 0.000000000000000e+00
... (celdas 6 a 12 también en 0)
```

Los rangos 1 y 2 usan como vecino izquierdo el 0.0 con que `calloc` inicializó `u[0]`: cada uno resuelve una barra con "frontera
izquierda 0". El rango 2 queda plano en 0 (frontera falsa 0 a la izquierda, frontera real 0 a la derecha), el rango 1 también, y
el rango 0 traza una recta de 100 a la "frontera" 0 que ve en la celda 5. Converge en 49 iteraciones porque el problema que
resolvió es más corto. Con `p = 1` el error es invisible (`make test` lo comprueba): no hay halos que intercambiar.

Regla: **un halo que no se actualiza no truena; miente.** La única defensa es comparar contra la versión secuencial.
