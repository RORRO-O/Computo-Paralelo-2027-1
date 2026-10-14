> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S02 · lunes 9 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S02 · ConcepTests (instrucción entre pares)

Secuencia fija: voto individual (1 min) → discusión en parejas (2 min, "convence a tu compañero") → revoto →
explicación del profesor. Si el primer voto supera 80 % de aciertos, se salta la discusión; si queda por
debajo de 30 %, se vuelve a explicar antes de discutir. Se vota con tarjetas A/B/C/D o con los dedos.

Las respuestas están en `<details>` para que el archivo sirva de autoestudio.

---

## ConcepTest 1 · ¿Qué promete `MPI_Send`? (minuto 27, después del ejemplo resuelto)

Los rangos 0 y 1 ejecutan exactamente este código, cada uno con `partner` igual al otro y
`n = 1 000 000` enteros:

```c
MPI_Send(out, n, MPI_INT, partner, 0, MPI_COMM_WORLD);
MPI_Recv(in,  n, MPI_INT, partner, 0, MPI_COMM_WORLD, &status);
```

¿Qué afirmación es correcta según el estándar MPI?

- **A.** El programa es correcto: `MPI_Send` regresa de inmediato porque solo copia el mensaje a un búfer
  interno de MPI; después los dos reciben.
- **B.** El programa es correcto: `MPI_Send` siempre espera al `MPI_Recv` del otro lado, y como ambos llaman
  a `MPI_Recv` después, se sincronizan.
- **C.** El programa es incorrecto ("inseguro"): puede terminar o interbloquearse según el tamaño del
  mensaje y el *buffering* de la implementación; con `n = 10` probablemente termina y con `n = 10⁶`
  probablemente se cuelga.
- **D.** El programa es incorrecto solo si los dos procesos están en máquinas distintas; en la misma
  máquina comparten memoria y el intercambio no puede colgarse.

<details><summary>Respuesta y origen de los distractores</summary>

**Respuesta: C.**

| Opción | Origen |
|---|---|
| A | Idea errónea 17, variante "siempre regresa de inmediato". Confunde lo que Open MPI hace con mensajes chicos con lo que el estándar garantiza |
| B | Idea errónea 17, variante "siempre bloquea hasta que el otro recibe". Además, si fuera cierto, el programa se colgaría siempre, no "se sincronizaría" |
| D | Idea errónea 16: "los procesos MPI comparten memoria". El transporte cambia la velocidad y el umbral, no la semántica |

**Porcentaje esperado en el primer voto:** 50–60 % (acaban de ver el programa colgarse en vivo; los que
votan A o B suelen estar generalizando la demostración en un solo sentido).

**Guion de discusión (3 líneas):**
1. "Quien votó A: ¿qué pasó hace cinco minutos con n = 10⁶? Quien votó B: ¿y con n = 10?"
2. "Busquen en pareja la única cosa que el estándar promete cuando `MPI_Send` regresa." (Que el búfer se
   puede reutilizar.)
3. Tras el revoto: la regla. Un programa MPI es correcto solo si termina aunque todos los `MPI_Send`
   bloqueen hasta que exista la recepción. Lo que vieron con n = 10 no es evidencia de corrección.

</details>

---

## ConcepTest 2 · El anillo que nadie arranca (minuto 68, puesta en común)

Una pareja cambia `ring_token.c` para que **todos** los rangos, incluido el 0, hagan primero `MPI_Recv` del
vecino izquierdo y después `MPI_Send` al derecho. Lo corren con `-np 5` y un token de **un entero**
(4 bytes). ¿Qué pasa?

- **A.** Funciona igual que antes: el mensaje es pequeño y MPI lo guarda en su búfer interno.
- **B.** Se interbloquea: todos esperan un mensaje y nadie envía primero; no depende del tamaño.
- **C.** Funciona porque el rango 0 es el maestro y MPI lo hace empezar primero.
- **D.** Se interbloquea solo si el token es grande (mayor que el límite *eager*).

<details><summary>Respuesta y origen de los distractores</summary>

**Respuesta: B.** (Comprobado: `timeout 10 mpirun -np 5 ./ring_recvfirst` termina con código 124.)

| Opción | Origen |
|---|---|
| A | Idea errónea 17 mal aplicada: el *buffering* ayuda cuando alguien **envía**; aquí nadie envía nada que guardar |
| C | Idea errónea 19: "el rango 0 tiene que ser el maestro". El rango 0 no tiene ningún privilegio; es un proceso más y ejecuta lo que el código diga |
| D | Idea errónea 17: transfiere el criterio del tamaño (válido para el intercambio cruzado) a un caso donde el tamaño no interviene |

**Porcentaje esperado en el primer voto:** 60–70 %. El distractor fuerte es D: acaban de descubrir el
umbral de 4 KB en la fase Investigar y quieren aplicarlo a todo.

**Guion de discusión (3 líneas):**
1. "Dibujen los 5 procesos en círculo. Pongan una flecha de cada uno hacia quien está esperando."
2. "¿Hay alguna flecha que salga de un `MPI_Send`? Si nadie está en `Send`, ¿qué hay que guardar en el
   búfer?"
3. Tras el revoto: en un anillo alguien tiene que romper la simetría (el 0 envía primero), o todos usan
   `MPI_Sendrecv`. Y recordar E2 de la práctica: si todos envían primero, no se cuelga pero el token final
   es 4, no 10: terminar no es lo mismo que estar bien.

</details>

---

## ConcepTest 3 · Mil mensajes chicos o uno grande (minuto 72; si no hay tiempo, pasa al inicio de S05, martes 17 de noviembre)

Según la tabla medida hoy (dos procesos en la misma máquina): latencia de ida de 8 bytes ≈ 0.21 µs; latencia
de ida de 4 096 bytes ≈ 6.1 µs; de 32 768 bytes ≈ 12.5 µs. Un proceso debe entregar a su vecino 1 000 valores
`double` (8 000 bytes en total). ¿Qué opción es más barata y por cuánto?

- **A.** 1 000 mensajes de 8 bytes: cada uno es casi instantáneo (0.21 µs) y en total son menos bytes de
  encabezado que un mensaje grande.
- **B.** Un mensaje de 8 000 bytes: cuesta unos 7–8 µs frente a unos 210 µs de los mil mensajes, alrededor
  de 30 veces menos.
- **C.** Da igual: se mueven los mismos 8 000 bytes y, comparada con el cómputo, la comunicación es
  despreciable en ambos casos.
- **D.** Da igual: el tiempo lo decide el ancho de banda, y los bytes son los mismos.

<details><summary>Respuesta y origen de los distractores</summary>

**Respuesta: B.** 1 000 × 0.21 µs ≈ 210 µs. 8 000 bytes queda entre las filas de 4 096 (6.1 µs) y 32 768
(12.5 µs): ≈ 7 µs. Razón ≈ 30 (se acepta de 20 a 40 según la interpolación).

| Opción | Origen |
|---|---|
| A | Idea errónea 21: tratar 0.21 µs como "gratis" sin multiplicarlo por el número de mensajes |
| C | Idea errónea 21, literal: "la comunicación es gratis comparada con el cómputo" |
| D | Idea errónea 21, variante: modelo sin latencia (solo m/β). Ignora el costo fijo α por mensaje |

**Porcentaje esperado en el primer voto:** 65–75 % (la tabla está en pantalla; el error típico es no
multiplicar).

**Guion de discusión (3 líneas):**
1. "Escriban la cuenta, no la intuición: ¿cuánto cuestan 1 000 mensajes de 8 bytes con la tabla?"
2. "¿Dónde está el costo fijo α en la fórmula T(m) = α + m/β? ¿Cuántas veces se paga en cada opción?"
3. Tras el revoto: regla de diseño para la Práctica 5 y para la V2 del proyecto: agrupar datos en pocos
   mensajes grandes; un mensaje en el ciclo interno es una señal de alarma.

</details>

---

## Registro para el profesor (llenar en clase)

| ConcepTest | % primer voto | % revoto | Distractor más votado | Nota |
|---|---|---|---|---|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |
