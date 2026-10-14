> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S03 · martes 10 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# S03 · ConcepTests (instrucción entre pares)

Secuencia del ConcepTest 1: voto individual (1 min) → discusión en parejas (2 min, "convence a tu compañero")
→ revoto → explicación del profesor. Si el primer voto supera 80 % de aciertos se salta la discusión; si queda
por debajo de 30 % se vuelve a explicar antes de discutir. Tras la discusión se pregunta por tarjeta de lista
"¿qué concluyó tu pareja?", no "¿qué piensas tú?".
El ConcepTest 2 se vota **una sola vez** (punto de control, minuto 83) y solo se discute si el acierto queda
entre 30 % y 80 %; si no hay tiempo, pasa como pregunta 1 de la recuperación de S04 (jueves 12 de noviembre).
El ConcepTest 3 es reserva: recuperación de S05 (martes 17 de noviembre) o examen de práctica.

Las respuestas están en `<details>` para que el archivo sirva de autoestudio.

---

## ConcepTest 1 · ¿Quién llama a `MPI_Bcast`? (minuto 22, dentro de la mini-lección, ANTES de correr la variante que falla)

Fragmento de un producto matriz-vector por filas. Cada rango ya tiene sus filas en `A_local`. Se ejecuta con
`mpirun -np 4`:

```c
double *x = calloc(n, sizeof(double));     /* en TODOS los rangos: n ceros        */
if (rank == 0) fill_vector(x, n);          /* solo el rango 0 tiene los datos      */

if (rank == 0)
    MPI_Bcast(x, n, MPI_DOUBLE, 0, MPI_COMM_WORLD);

local_matvec(A_local, x, y_local, local_n, n);
MPI_Gather(y_local, local_n, MPI_DOUBLE, y, local_n, MPI_DOUBLE, 0, MPI_COMM_WORLD);
```

¿Qué pasa?

- **A.** Funciona: el único que tiene `x` es el rango 0, así que es el único que debe llamar a `MPI_Bcast`; los
  rangos 1–3 reciben `x` por debajo, como si hubiera un `MPI_Recv` implícito.
- **B.** Funciona: los cuatro procesos corren en la misma máquina y `x` es la misma memoria para todos; el
  `Bcast` solo avisa que ya está lista.
- **C.** El programa está mal: los rangos 1–3 nunca ejecutan la colectiva. Según el tamaño de `x` y el
  *buffering*, el rango 0 se queda esperando dentro de `MPI_Bcast` (cuelgue) o sale y el resultado es incorrecto
  (`y` = 0 en las filas de los rangos 1–3).
- **D.** MPI detecta que faltan tres llamadas y aborta con un mensaje de error en `MPI_Bcast`.

<details><summary>Respuesta y origen de los distractores</summary>

**Respuesta: C.** Comprobado con `matvec_bcast_buggy`: con `n = 8` (64 bytes) terminó con `y[2..7] = 0.0` y
`checksum = 372` en vez de 2352; con `n = 1024` (8 KB) `timeout 10` lo mató (código 124). El umbral en la
máquina de autoría está entre 4 032 y 4 064 bytes: el mismo límite *eager* de 4 096 bytes de S02.

| Opción | Origen |
|---|---|
| A | Idea errónea 18 ("solo el proceso raíz llama a `MPI_Bcast`"). Trata la colectiva como un `Send` con destino "todos"; una colectiva describe la operación completa y cada proceso ejecuta su parte |
| B | Idea errónea 16 ("los procesos MPI comparten memoria"). Hay cuatro arreglos `x`, uno por proceso; tres siguen en ceros |
| D | Nueva (también en S04, CT2): "MPI detecta las colectivas mal emparejadas". No lo hace: una colectiva que no llaman todos se manifiesta como cuelgue o como basura, igual que un `Recv` sin `Send` |

**Porcentaje esperado en el primer voto:** 45–55 %. El pre-lab y la tarea de S02 ya les pidieron conjeturar por
qué todos llaman a `Bcast`, pero no lo han visto fallar; A es el distractor fuerte.

**Guion de discusión (3 líneas):**
1. "Quien votó A: señala en el código la línea que ejecuta el rango 2 para *recibir* `x`." (No hay.)
2. "Quien votó D: ¿cómo sabría el rango 0 que los otros tres no van a llamar nunca? ¿Cuánto puede esperar?"
3. Tras el revoto, correr en vivo `timeout 10 mpirun -np 4 ./matvec_bcast_buggy 8` (termina, mal) y
   `... 1024` (se cuelga). Regla: **una colectiva es una cita a la que van todos los procesos del comunicador;
   si uno falta, los demás esperan sin aviso o siguen con datos que no son.**

</details>

---

## ConcepTest 2 · ¿Qué dice el desglose de tiempos? (minuto 83, punto de control; voto único)

Una corrida real de `matvec_collectives` con `n = 4096`, `p = 4` y **un solo** producto (máquina virtual de 4
núcleos compartida):

```
tiempos (s): scatter = 0.161, bcast = 0.024, calcular = 0.010 (max entre rangos), gather = 0.004, total = 0.199
```

El mismo producto en secuencial (`matvec_seq 4096`) tardó entre 0.027 y 0.045 s. ¿Qué conclusión es correcta?

- **A.** La comunicación es despreciable frente al cómputo; el problema es que el cómputo no escala con 4
  procesos.
- **B.** MPI siempre es más lento que el secuencial en matriz-vector; no tiene sentido paralelizarlo.
- **C.** Repartir `A` mueve n² datos y el producto hace n² operaciones: el mismo orden. Con un solo producto la
  comunicación domina; conviene cuando `A` se reparte una vez y se usa muchas veces, o cuando cada rango genera
  o lee sus propias filas sin pasar por el rango 0.
- **D.** Con 8 procesos el `scatter` se reparte entre más rangos y el total bajará a la mitad.

<details><summary>Respuesta y origen de los distractores</summary>

**Respuesta: C.** El `scatter` es el 81 % del total; `calcular` el 5 %. Con `reps = 40` (40 productos con la
misma `A` repartida) la misma máquina dio `calcular = 0.611 s` contra `scatter = 0.165 s` y el *speedup* frente
al secuencial (1.07 s) fue ≈ 1.9 con carga ajena en los núcleos; sin carga sería mayor.

| Opción | Origen |
|---|---|
| A | Idea errónea 21, literal: "la comunicación es gratis comparada con el cómputo". Los números dicen lo contrario |
| B | Nueva: "si una medición da *speedup* < 1, el problema no es paralelizable". Confunde una medición con una propiedad del problema; cambia el escenario (reparto único, lectura local de filas) y cambia el resultado |
| D | Idea errónea 1 ("más procesos siempre es más rápido"). El rango 0 sigue enviando los mismos n² datos; los reparte en más mensajes, no en menos bytes |

**Porcentaje esperado en el voto único:** 60–70 %. Si queda entre 30 % y 80 %: 90 s en parejas con la pregunta
"¿cuántos bytes salen del rango 0 en el `scatter` con p = 4 y con p = 8?" y revoto.

**Guion de discusión (3 líneas):**
1. "Escriban dos números: bytes que mueve el `scatter` (n² × 8) y operaciones del producto (2n²)."
2. "¿Qué cambia si el programa hace 40 productos con la misma `A`? ¿Y si cada rango lee sus filas de un archivo?"
3. Tras el revoto: regla para la Parte D de la Práctica 5 y para S05: **el costo de distribuir los datos se
   cuenta; se paga una vez y se amortiza, o se evita generando los datos donde se usan.**

</details>

---

## ConcepTest 3 · Reserva: ¿`Reduce`, `Allreduce`, `Gather`? (recuperación de S05, martes 17 de noviembre, o examen de práctica)

Cada rango calculó `local_sq`, la suma de cuadrados de **su** bloque de `y`. **Todos** los rangos necesitan la
norma ‖y‖ = √(Σ local_sq) para dividir su bloque entre ella en la siguiente iteración. ¿Cuál es la llamada
correcta y suficiente?

- **A.** `MPI_Reduce(&local_sq, &total, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);`
- **B.** `MPI_Allreduce(&local_sq, &total, 1, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);`
- **C.** `if (rank == 0) MPI_Allreduce(&local_sq, &total, 1, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);` y los demás
  usan su `local_sq`.
- **D.** `MPI_Gather(&local_sq, 1, MPI_DOUBLE, all, 1, MPI_DOUBLE, 0, MPI_COMM_WORLD);` y cada rango suma `all`.

<details><summary>Respuesta y origen de los distractores</summary>

**Respuesta: B.** Es la fase Crear de la práctica guiada (`norma_allreduce.c`): con `-np 4`, `n = 8`, los cuatro
rangos imprimen `norma = 863.666602`, igual que `matvec_seq 8`.

| Opción | Origen |
|---|---|
| A | Confusión `Reduce`/`Allreduce`: `total` solo queda en el rango 0; en los demás `total` conserva su valor anterior (en `colectivas_demo`, `-1`). Funcionaría con un `Bcast` adicional, pero no es "suficiente" |
| C | Idea errónea 18 (colectiva dentro de `if (rank == 0)`) más 16 (creer que `total` del rango 0 lo ven los demás) |
| D | Idea errónea 16 aplicada a `Gather`: `all` solo se llena en el rango 0 (`colectivas_demo` lo imprime: `{-1, -1, -1, -1}` en los demás). Con `Allgather` sí funcionaría, pero movería p valores a cada rango para sumar lo que `Allreduce` suma por el camino |

**Porcentaje esperado en el primer voto:** 65–75 %.

**Guion de discusión (3 líneas):**
1. "Para cada opción: al terminar la llamada, ¿en qué rangos vale `total` lo correcto?"
2. "¿Qué le pasa al rango 1 en la opción C cuando llega al siguiente `Scatter` mientras el 0 sigue en `Allreduce`?"
3. Tras el revoto: la pregunta que decide la colectiva es siempre la misma: **¿quién tiene el dato antes y quién
   lo necesita después?** Un rango → `Reduce`/`Gather`; todos → `Allreduce`/`Allgather`.

</details>

---

## Registro para el profesor (llenar en clase)

| ConcepTest | % primer voto | % revoto | Distractor más votado | Nota |
|---|---|---|---|---|
| 1 | | | | |
| 2 (voto único) | | — | | |
| 3 (si se usó) | | | | |
