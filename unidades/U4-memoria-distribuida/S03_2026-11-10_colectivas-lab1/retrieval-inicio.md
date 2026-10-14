> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S03 · martes 10 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# S03 · Recuperación de inicio (5 minutos, individual, sin apuntes ni dispositivos)

Responde por escrito, una línea por pregunta (o elige la opción). A los 4 minutos se muestran las respuestas;
levanta la mano por cada pregunta que hayas acertado. No se califica por acierto: cuenta como participación.
La pregunta 1 verifica el pre-laboratorio; la 5 es una conjetura: "no sé" es válida y no cuenta.

## Preguntas

**1. (Pre-laboratorio de la Práctica 5; debió quedar en el repositorio de tu equipo antes de hoy a las 08:30)**
Escribe de memoria la predicción que dejaste en tu pre-lab: el *speedup* que esperas con 4 procesos para el
producto matriz-vector distribuido y la razón, en una línea.

**2. (S02, lunes 9 de noviembre)** `MPI_Send` promete **una sola cosa** cuando regresa. ¿Cuál?
(a) que el receptor ya recibió el mensaje; (b) que tu búfer ya se puede reutilizar; (c) que el mensaje ya
salió por la red; (d) que el receptor ya llamó a `MPI_Recv`.

**3. (S02)** Con la tabla del *ping-pong* de ayer (8 bytes ≈ 0.21 µs de ida; 8 000 bytes ≈ 7 µs), ¿qué es más
barato para entregar 1 000 `double` a un vecino, y aproximadamente por cuánto: 1 000 mensajes de 8 bytes o
un mensaje de 8 000 bytes?

**4. (Unidad III, S07, jueves 15 de octubre)** En `#pragma omp parallel for reduction(+:s)` con 4 hilos,
¿cuántas copias de `s` existen mientras corre el ciclo y qué pasa con ellas al terminar?

**5. (Anticipa el tema de hoy; conjetura)** El rango 0 tiene una matriz de 8 × 8 y hay 4 procesos; cada uno
debe quedarse con 2 filas. Si eso se hace con **una** colectiva (`MPI_Scatter`), ¿cuántas veces aparece la
llamada en el código fuente y cuántos procesos la ejecutan? Opciones: 1 / 1 · 1 / 4 · 4 / 4 · no sé.

## Respuestas

<details>
<summary>Mostrar respuestas (a los 4 minutos)</summary>

**1.** No tiene respuesta "correcta": se compara con lo medido en el Lab 2 (martes 17 de noviembre). Quien no
pueda escribirla no entregó el pre-lab; se registra. Una predicción razonable para hoy: *speedup* < 1 si solo
se hace un producto (repartir la matriz cuesta tanto como multiplicarla); cercano a 3–4 si la matriz se reparte
una vez y se usa muchas veces.

**2.** (b). Solo garantiza que tu búfer es reutilizable. Puede regresar antes de que el receptor llame a
`MPI_Recv` (mensaje chico, copiado a un búfer interno) o después (mensaje grande). Por eso dos `Send` cruzados
pueden colgarse (idea errónea 17).

**3.** El mensaje único: ≈ 7 µs contra ≈ 1 000 × 0.21 µs ≈ 210 µs; unas 30 veces más barato. Cada mensaje paga
la latencia α; la comunicación no es gratis (idea errónea 21). Hoy lo verás en grande: repartir una matriz de
128 MB cuesta más que multiplicarla una vez.

**4.** Cinco: la variable compartida original y una copia privada por hilo (4), inicializadas en 0. Al terminar,
las 4 copias se combinan con `+` sobre la original. Guarda la idea: en MPI eso mismo se llama `MPI_Reduce`,
pero las "copias" son variables en procesos distintos y la combinación viaja en mensajes.

**5.** 1 / 4. La llamada se escribe **una vez**, fuera de cualquier `if (rank == ...)`, y la ejecutan los **cuatro**
procesos: en el rango 0 el búfer de envío es la fuente; en todos, el búfer de recepción recibe su bloque. Esa es
la regla de oro de hoy.

</details>

## Para el profesor

- Umbral de alerta: si menos del 60 % acierta la **2**, no se reexplica hoy (no hay tiempo en la variante de
  laboratorio); se repite con pista como pregunta de S02 en la recuperación de S04 (jueves 12 de noviembre) y se
  anota en "Notas post-sesión".
- La **4** es el gancho: pedir manos a "¿quién escribió que se combinan al final?" y decir "eso, entre procesos,
  es `MPI_Reduce`; en 10 minutos lo ven correr".
- La **5** no se corrige aquí: contar manos por opción (1/1, 1/4, 4/4, no sé) y anotar el conteo; se retoma en el
  ConcepTest 1 (minuto 22). Quien escribió 1/1 trae la idea errónea 18.
- La **1** se registra como entrega del pre-lab (hoja aparte: número de lista y "sí/no"). No se lee en voz alta.
