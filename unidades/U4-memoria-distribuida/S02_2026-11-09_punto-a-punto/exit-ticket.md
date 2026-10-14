> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S02 · lunes 9 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S02 · Exit ticket (5 minutos, individual)

Escribe tu número de lista. Responde en media hoja. Se entrega al salir; cuenta como participación y
decide cómo empieza la sesión del jueves 12 de noviembre.

## Pregunta 1 (conceptual)

Hoy viste que `cross_exchange_buggy` termina con `n = 10` enteros y se cuelga con `n = 1 000 000`.
Un compañero concluye: "entonces el programa está bien y el cuelgue es un error de Open MPI".

En tres líneas: ¿está bien o mal el programa según el estándar MPI? ¿Por qué los dos comportamientos son
consistentes con lo que el estándar promete de `MPI_Send`? Escribe **una** forma de corregirlo.

## Pregunta 2 (aplicación corta)

Usa la tabla del *ping-pong* medida hoy (dos procesos en la misma máquina):

| bytes | latencia de ida (µs) |
|---|---|
| 8 | 0.21 |
| 32 768 | 12.5 |
| 262 144 | 29.5 |

Un programa envía a su vecino 10 000 valores `double` (8 bytes cada uno), **uno por mensaje**.

a) Estima cuánto tarda en total la comunicación.
b) Si en lugar de eso enviara los 10 000 valores en **un solo** mensaje de 80 000 bytes, ¿cuánto tardaría
aproximadamente? (Interpola entre las dos últimas filas o usa la más cercana.)
c) ¿Cuántas veces más caro es el primer esquema? ¿Qué idea errónea del curso desmiente este cálculo?

## Pregunta 3 (confianza)

¿Qué tan seguro estás de tus respuestas? (1 = adivinando, 4 = podría explicárselo a alguien).
¿Qué te quedó menos claro de hoy? (una frase)

---

<details>
<summary>Clave (para el profesor; se publica después de la sesión)</summary>

**Pregunta 1.** El programa está **mal** ("inseguro" en el lenguaje del estándar). `MPI_Send` solo promete
regresar cuando el búfer de envío se puede reutilizar; **no** promete regresar antes de que exista el
`MPI_Recv` correspondiente. Con mensajes pequeños Open MPI copia el mensaje a un búfer interno (protocolo
*eager*) y `MPI_Send` regresa; con mensajes grandes no copia (*rendezvous*) y espera al receptor, que nunca
llega porque también está en `MPI_Send`. Las dos conductas están permitidas; un programa correcto debe
terminar en ambas. Correcciones válidas: (a) orden por paridad (par: `Send`→`Recv`; impar: `Recv`→`Send`);
(b) `MPI_Sendrecv`; (c) `MPI_Irecv` + `MPI_Isend` + `MPI_Wait`.

Criterio de los montones: *bien* = dice que está mal, menciona el búfer/tamaño y da una corrección válida;
*parcial* = da la corrección pero cree que "con mensajes chicos sí está bien"; *mal* = culpa a Open MPI o
dice que `MPI_Send` siempre bloquea / nunca bloquea (idea errónea 17).

**Pregunta 2.**
a) 10 000 × 0.21 µs ≈ **2 100 µs ≈ 2.1 ms** (domina la latencia: 10 000 veces el costo fijo).
b) 80 000 bytes está entre 32 768 (12.5 µs) y 262 144 (29.5 µs); interpolando linealmente ≈ 12.5 +
(80 000 − 32 768) / (262 144 − 32 768) × (29.5 − 12.5) ≈ **16 µs**. Se acepta cualquier valor entre 12 y 30 µs.
c) ≈ 2 100 / 16 ≈ **130 veces** (se acepta "entre 70 y 170 veces", según la interpolación). Desmiente la
idea errónea **21**: "la comunicación es gratis comparada con el cómputo". El costo de un mensaje tiene una
parte fija (latencia) que se paga por mensaje; muchos mensajes chicos son mucho más caros que uno grande
con los mismos bytes.

**Pregunta 3.** Registrar la distribución de confianza junto con el montón de la pregunta 1: quien está en
"mal" con confianza 4 es la prioridad de la retroalimentación del jueves 12 de noviembre.

</details>
