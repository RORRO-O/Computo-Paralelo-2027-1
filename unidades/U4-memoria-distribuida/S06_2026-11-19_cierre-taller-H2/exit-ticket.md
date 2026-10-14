> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S06 · jueves 19 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S06 · Exit ticket (5 minutos, individual, en papel)

Escribe tu número de lista. Entrega la hoja al salir (junto con la hoja de predicciones del cazador de errores, con
los dos números de lista de la pareja). El profesor lo revisa hoy y abre la sesión del **lunes 23 de noviembre**
(U5·S01, recepción de H2 + modelo CUDA) con el error más frecuente. En el 3er parcial no tiene peso propio.

**1. (Conceptual; opción múltiple)** Dos procesos, cualquier `n`:

```c
if (rank == 1) MPI_Send(buf, n, MPI_INT, 0, 6, MPI_COMM_WORLD);
if (rank == 0) MPI_Recv(buf, n, MPI_INT, 1, 5, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
```

¿Qué pasa al ejecutarlo con `mpirun -np 2`?

- **A)** MPI aborta con un mensaje de error porque las etiquetas no coinciden.
- **B)** El rango 0 se queda esperando para siempre (ningún mensaje casa con etiqueta 5); el rango 1 puede
  terminar su `Send` si `n` es chico y llegar a `MPI_Finalize` con un mensaje que nadie recibirá. Sin mensaje de error.
- **C)** Funciona: las etiquetas son informativas; lo que empareja un mensaje es la fuente y el comunicador.
- **D)** Funciona si `n` es chico (el mensaje cabe en el búfer interno) y se cuelga si es grande.

**2. (Aplicación; respuestas numéricas)** Tabla de un equipo, laptop de **4 núcleos físicos**, medianas de 5:
`V1,1 = 2.40 s` · `V2,4 = 0.80 s` · `V2,8 = 0.78 s`.

a) `S(4)` = ______ · b) `f(4)` de Karp–Flatt = ______ (dos decimales) · c) ¿La fila de 8 hilos entra en la
conclusión sobre escalabilidad? (sí/no y una palabra de por qué) ______

**3. (Confianza)** ¿Qué tan seguro estás de tus dos respuestas? 1 = adivinando · 2 = poco · 3 = bastante ·
4 = podría explicárselo a alguien. ¿Qué te quedó **menos** claro hoy? (una línea, opcional)

<details><summary>Clave</summary>

1. **B.** El emparejamiento exige comunicador, fuente **y etiqueta** iguales (S02 §3): el `Recv` con etiqueta 5
   nunca casa con un mensaje de etiqueta 6, y MPI no avisa (no hay forma de saber que "ya no va a llegar"). Si `n`
   es chico el `Send` del rango 1 termina (*eager*) y el rango 1 llega a `Finalize` con un mensaje pendiente
   (error clásico 5): el lanzador se queda esperando al rango 0. Distractores: A, nueva ("MPI detecta
   etiquetas cruzadas"; ya apareció en S03/S04 como "MPI detecta colectivas mal emparejadas"); C, nueva ("las
   etiquetas no emparejan"); D, idea errónea 17 trasladada: el tamaño decide si el `Send` regresa, no si el
   `Recv` casa.
2. a) `S(4) = 2.40 / 0.80 = 3.0` · b) `f(4) = (1/3 − 1/4) / (1 − 1/4) = (1/12) / (3/4) = 1/9 ≈ 0.11` · c) **No**:
   sobre-suscripción (8 hilos en 4 núcleos físicos; se reporta aparte y marcada). Quien calcula `S(8) = 3.08` y
   lo usa para "escala hasta 8" cae en las ideas 1 y 20.
3. Sin clave. Para el profesor: la brecha entre confianza 4 y pregunta 2b incorrecta es el dato de calibración de
   la sesión.
</details>

**Clasificación rápida (profesor, 10 min después de clase).** Bien: pregunta 1 = B **y** pregunta 2 con `3.0`,
`0.11` y "no". Parcial: 1 = B con un error en 2 (lo más probable: `f` mal calculada o "sí" en c), o 1 ≠ B con la 2
completa. Mal: 1 ≠ B y algún error en 2, o 2c = "sí". Si "mal" supera 30 %, la recuperación del lunes 23 de
noviembre repite 2b con la fórmula escrita (su ítem 2 ya pregunta `T(1)` y el protocolo).
