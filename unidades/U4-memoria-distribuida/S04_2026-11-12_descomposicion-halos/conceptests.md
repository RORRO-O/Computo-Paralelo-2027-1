> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S04 · jueves 12 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# ConcepTests S04 (uso del profesor)

Secuencia: voto individual (1 min, tarjetas A/B/C/D) → si 30–80 % acierta, discusión en parejas (2 min) → revoto → explicación.
Si > 80 % acierta al primer voto, se explica en 30 s y se sigue. Si < 30 %, se vuelve a explicar el ejemplo antes de discutir.

## CT1 · Intercambio con dos `Send` (minuto ~38, dentro de Instrucción explícita I)

Cada rango ejecuta, en este orden, con vecinos inexistentes puestos en `MPI_PROC_NULL`:

```c
MPI_Send(&u[local_n], 1, MPI_DOUBLE, right, 10, MPI_COMM_WORLD);
MPI_Send(&u[1],       1, MPI_DOUBLE, left,  20, MPI_COMM_WORLD);
MPI_Recv(&u[0],           1, MPI_DOUBLE, left,  10, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
MPI_Recv(&u[local_n + 1], 1, MPI_DOUBLE, right, 20, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
```

¿Qué afirmación es correcta?

- A. Siempre funciona: `MPI_Send` regresa en cuanto copia el dato a un búfer interno.
- B. Siempre se interbloquea: `MPI_Send` no regresa hasta que el receptor llama a `MPI_Recv`.
- C. Con 1 `double` normalmente funciona, pero el estándar no lo garantiza; con mensajes grandes se interbloquea. Por eso se usa `MPI_Sendrecv` o `Isend/Irecv/Waitall`.
- D. Se interbloquea solo en los rangos de las orillas, porque `MPI_PROC_NULL` nunca contesta.

<details>
<summary>Respuesta, origen de los distractores, acierto esperado y guion (ábrelo después de votar)</summary>

| Opción | Origen del distractor |
|---|---|
| A | Idea errónea 17 (variante "siempre regresa de inmediato") |
| B | Idea errónea 17 (variante "siempre bloquea hasta que el otro recibe") |
| D | Nueva: "`MPI_PROC_NULL` es un proceso que no responde". Es un destino nulo: la operación termina de inmediato. Agregar al Anexo A si aparece en el exit ticket. |

Acierto esperado en el primer voto: 45 %. Respuesta: C.

Guion de discusión (3 líneas): "¿Qué pasa con el rango 1 si el rango 0 y el rango 2 también están detenidos en su primer `Send`?
¿De qué depende que `Send` regrese antes de que alguien reciba? ¿Qué llamada hace que el envío y la recepción ocurran en la
misma operación?" Cierre: un programa que depende del *buffering* es incorrecto aunque hoy funcione; lo mismo que una carrera que "salió bien" (idea 7).

</details>

## CT2 · Convergencia global (minuto ~70, Puesta en común)

Un equipo quiere ahorrar comunicación:

```c
if (rank == 0)
    MPI_Allreduce(&local_diff, &global_diff, 1, MPI_DOUBLE, MPI_MAX, MPI_COMM_WORLD);
if (global_diff < tol) break;
```

Con 3 procesos, ¿qué ocurre?

- A. Funciona: el rango 0 calcula el máximo y los demás lo reciben automáticamente, porque `Allreduce` entrega el resultado a todos.
- B. Se cuelga: `MPI_Allreduce` es colectiva; los rangos 1 y 2 nunca la llaman y el rango 0 los espera para siempre.
- C. No se cuelga, pero los rangos 1 y 2 comparan un `global_diff` sin actualizar y paran en una iteración distinta; el resultado sale mal.
- D. MPI aborta con un mensaje de error porque detecta que la colectiva no la llamaron todos.

<details>
<summary>Respuesta, origen de los distractores, acierto esperado y guion (ábrelo después de votar)</summary>

| Opción | Origen del distractor |
|---|---|
| A | Idea errónea 18 ("solo el raíz llama a la colectiva"), aplicada a `Allreduce` |
| C | Razonamiento parcial correcto sobre los datos, pero ignora que el rango 0 se queda esperando. Variante de la idea 18: "si la llama uno, los demás pueden saltársela". |
| D | Nueva: "MPI detecta las colectivas mal emparejadas". No lo hace: una colectiva desbalanceada se manifiesta como cuelgue, igual que un `Recv` sin `Send` (relaciona con S02). |

Acierto esperado en el primer voto: 55 %. Respuesta: B.

Guion: "¿Quién está dentro de `Allreduce` y a quién espera? ¿Qué hacen mientras tanto los rangos 1 y 2: llegan al siguiente
`Sendrecv` con el rango 0, y el rango 0 dónde está? ¿Qué regla vale para TODAS las colectivas de S03?" Regla general en una frase:
**una colectiva es una cita a la que van todos los procesos del comunicador; si uno falta, los demás esperan sin aviso.**

</details>

## CT3 · Reserva: reparto cíclico (si sobra tiempo en Puesta en común, o para abrir S05)

Un equipo propone repartir las celdas de forma cíclica (celda `i` al rango `i % p`) "para balancear mejor la carga que con bloques". Para Jacobi 1D:

- A. Mejora el balance y reduce la comunicación, porque cada rango tiene celdas de toda la barra.
- B. El balance es igual al de bloques (la diferencia entre rangos es ≤ 1 celda en ambos), pero la comunicación crece de 2 mensajes por rango a unos `2·local_n` por iteración: cada celda tiene sus vecinos en otros procesos.
- C. No funciona: Jacobi exige que cada rango tenga celdas contiguas, el programa daría resultados incorrectos.
- D. Es más rápida porque los mensajes de 8 bytes no cuestan nada comparados con el cómputo.

<details>
<summary>Respuesta, origen de los distractores, acierto esperado y guion (ábrelo después de votar)</summary>

| Opción | Origen del distractor |
|---|---|
| A | Idea errónea 28 (aglomerar mal entendido: no se ve que agrupar celdas contiguas es lo que reduce la comunicación) |
| C | Nueva: "el algoritmo exige contigüidad". Funcionaría (con más mensajes); la contigüidad es una decisión de diseño, no un requisito de corrección. |
| D | Idea errónea 21 (la comunicación es gratis). Cada mensaje paga latencia aunque lleve 8 bytes; `local_n` mensajes de 8 bytes cuestan mucho más que 1 mensaje de `8·local_n` bytes. |

Acierto esperado en el primer voto: 60 %. Respuesta: B.

Guion: "Con bloques, ¿cuántas celdas de otros procesos necesita el rango 1? ¿Y con reparto cíclico? Si la latencia por mensaje es
la que midieron en S02, ¿cuánto cuesta una iteración en cada caso con `local_n = 250 000`?" Enlaza con S05: modelo latencia + tamaño/ancho de banda.

</details>

## Registro de la sesión (llenar en clase)

| CT | % 1.er voto | % revoto | Distractor más elegido | Nota |
|---|---|---|---|---|
| CT1 | | | | |
| CT2 | | | | |
| CT3 | | | | |
