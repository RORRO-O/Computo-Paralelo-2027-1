> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S02 · lunes 9 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S02 · Comunicación punto a punto: `MPI_Send`/`MPI_Recv`, semántica de bloqueo, interbloqueo, *ping-pong* y anillo

Tipo: **Contenido** (estructura base de 90 minutos). Este plan debe poder darlo otro profesor sin hablar con
el autor: contiene las frases clave, las salidas reales y las soluciones de los `TODO`.

## Objetivos (al terminar, el estudiante podrá…)

1. **Escribir** la llamada completa a `MPI_Send` y `MPI_Recv` para intercambiar un arreglo de un tipo básico
   entre dos rangos, usando etiquetas y `MPI_Status`, y **obtener** el número de elementos recibidos con
   `MPI_Get_count`. (Aplicar.)
2. **Explicar** por qué un intercambio cruzado `Send`/`Recv` puede terminar con mensajes pequeños e
   interbloquearse con grandes, en términos de lo que el estándar promete de `MPI_Send` y del *buffering*
   de la implementación. (Comprender / analizar.) → *Exit ticket* P1, ConcepTest 1.
3. **Corregir** un intercambio inseguro con orden por paridad o `MPI_Sendrecv` y **verificar** que termina
   con n = 10⁶ enteros. (Aplicar.) → Práctica guiada M1, `make test`.
4. **Estimar** latencia y ancho de banda con un *ping-pong* siguiendo el protocolo de medición y **usar** el
   modelo T(m) = α + m/β para comparar el costo de muchos mensajes pequeños contra uno grande.
   (Analizar / evaluar.) → *Exit ticket* P2, ConcepTest 3.

## Prerrequisitos y vínculo

- **Viene de:** S01 (jueves 5 de noviembre): modelo SPMD, `MPI_Init`/`Comm_rank`/`Comm_size`, compilar y
  ejecutar con `mpicc`/`mpirun`, mapeo de Foster a procesos.
- **Va hacia:** S03 (martes 10 de noviembre, 08:30): Práctica 5 · Lab 1 y colectivas (`Bcast`, `Scatter`,
  `Gather`, `Reduce`). S04 (jueves 12 de noviembre): `Isend`/`Irecv`/`Wait` a fondo e intercambio de halos.
  S05 (martes 17 de noviembre): modelo latencia + ancho de banda con los datos de hoy.
- **Ideas erróneas que ataca (Anexo A):** **17** (`MPI_Send` siempre regresa de inmediato / siempre bloquea)
  → ConcepTest 1, práctica I1–I2, *exit ticket* P1; **21** (la comunicación es gratis) → ConcepTest 3,
  práctica I4, *exit ticket* P2; **16** (los procesos comparten memoria) → recuperación P2, práctica P1c,
  ejemplo resuelto pausa 3, distractor D del ConcepTest 1.
- **Nivel de andamiaje:** completo (07 §A.5; segunda sesión de contenido de la unidad). Ejemplo resuelto
  completo (`status_demo.c` y la variante que falla, con sus pausas) y práctica guiada con las cinco fases de
  PRIMM; Crear (`ring_neighbors.c`) en Transferencia.

## Materiales

- Esta carpeta completa; proyector; cronómetro visible; tarjetas con números de lista; tarjetas A/B/C/D.
- Máquina del salón con `mpicc`/`mpirun` (Open MPI o MPICH) y una terminal grande para la demostración.
- Una hoja por estudiante para el *exit ticket*.

**Antes de la sesión (15 min).**

1. `cd practica-guiada && make clean && make && make test`. Debe terminar con `9 PASS, 0 FAIL, 4 SKIP`
   (los SKIP son los `TODO` de los estudiantes).
2. Confirmar en la máquina del salón que `timeout 10 mpirun -np 2 ./cross_exchange_buggy 1000000` se cuelga
   (código 124). Si no se cuelga, probar con `10000000`; si tampoco, esa implementación copió el mensaje:
   decirlo tal cual en el minuto 20 ("aquí copió; el estándar no lo garantiza") y usar la salida real de la
   máquina de autoría que está en `ejemplo-resuelto.md`.
3. Anotar el límite *eager* local: `ompi_info --param btl vader --level 4 | grep eager_limit` (en la máquina
   de autoría: 4096). Con MPICH el comando no existe; se omite I1 del `ompi_info` y se queda la búsqueda
   del umbral.
4. Revisar los *exit tickets* de S01 y escribir aquí el error más frecuente: ______________________.
   Si no hay datos, el anclaje por defecto es la idea 16 (ver minuto 5).

## Guion minuto a minuto

### 0–5 · Recuperación

Proyectar `retrieval-inicio.md` (5 preguntas). Individual, sin apuntes. Al minuto 4, mostrar respuestas y
pedir manos por pregunta.

- Respuestas esperadas: P1 cuatro líneas, `size` = 4, orden no garantizado; P2 `counter` sigue en 0; P3
  S = 3.2, E = 0.80, mirar la fracción secuencial del tiempo; P4 comunicación / aglomeración; P5 "depende".
- Si menos del 60 % acierta P2: dibujar en el pizarrón dos cajas (procesos) con dos copias de `counter` y
  una flecha "mensaje" entre ellas antes de seguir. Son 2 minutos que se recuperan en Transferencia.
- P5 no se corrige: anotar en el pizarrón el conteo de manos "siempre / nunca / depende". Se retoma en el
  minuto 20.

### 5–10 · Objetivos y anclaje

Autocalificación de la tarea de S01 con su clave (2 min); el profesor registra la entrega en el repositorio
(`tareas/<usuario-github>/U4-S01.md`), no el acierto.

Frase de apertura: "El jueves cada proceso imprimió su rango. Hoy un proceso le manda algo a otro. El error
más frecuente del *exit ticket* del jueves fue ______ [o: creer que si el rango 2 cambia una variable el
rango 3 la ve]. Hoy van a ver que ni siquiera el búfer que acaban de enviar lo ve el otro: lo que viaja es
una copia."

Proyectar los cuatro objetivos. Vínculo con la práctica y el proyecto: "En la Práctica 5, que empieza mañana,
el costo de comunicación decide si su versión distribuida gana o pierde. Hoy lo miden. La V2 del proyecto es
OpenMP, sin mensajes; la pregunta es la misma con hilos: cuánto trabajo hay por cada sincronización."

### 10–35 · Instrucción explícita I

**10–13 · El sobre y el contenido.** Escribir en el pizarrón las dos firmas (sección 3 de
`ejemplo-resuelto.md`). Señalar con el dedo: contenido (búfer, cuenta, tipo) y sobre (destino/fuente,
etiqueta, comunicador). Frase: "`count` en `Recv` es cuánto cabe, no cuánto llega."

**13–20 · Ejemplo resuelto `status_demo.c`.** Pensar en voz alta mientras se recorre el código proyectado:

- "Miro primero quién envía y quién recibe. Los rangos 1, 2 y 3 envían 3, 4 y 5 enteros. El 0 no sabe cuál
  llega primero: por eso `MPI_ANY_SOURCE` y por eso pregunto con `status`."
- Correr `mpirun -np 3 ./status_demo` y luego `mpirun -np 4 ./status_demo` dos veces. Señalar si el orden
  cambió (en autoría salió 3, 2, 1). "Lo que no está garantizado, no lo asuman."
- Pausa 1 (capacidad vs. recibido) y pausa 3 (`buf[0] = -1` tras el `Send`): preguntar a dos números de
  lista al azar; respuestas en `ejemplo-resuelto.md` §6.
- Pausa 5 en vivo si da tiempo: cambiar la cuenta de `MPI_Recv` a 4 y mostrar `MPI_ERR_TRUNCATE`.

**20–27 · Semántica de `MPI_Send` y la variante que falla.** Volver al conteo de manos de P5.

- Correr `mpirun -np 2 ./cross_exchange_buggy 10` → termina. Correr
  `timeout 10 mpirun -np 2 ./cross_exchange_buggy 1000000; echo $?` → 124. Silencio de 10 segundos mientras
  se cuelga: vale la pena.
- Pensar en voz alta: "Los dos están en `Send`. Cada uno espera a que el otro llegue a `Recv`. ¿Por qué con
  10 no pasó? Porque Open MPI copió 40 bytes a un búfer interno y `Send` regresó. Con 4 MB decidió no
  copiar." Escribir la regla: **"`MPI_Send` promete una sola cosa: cuando regresa, tu búfer es tuyo."**
  Debajo: "Un programa MPI es correcto solo si termina aunque todos sus `MPI_Send` bloqueen."
- Mostrar la tabla de tres correcciones (`ejemplo-resuelto.md` §7). Correr
  `mpirun -np 2 ./cross_exchange_fixed paridad 1000000`. Decir que `MPI_Sendrecv` la escriben ellos en 40
  minutos y que `Isend`/`Irecv` se ve a fondo el jueves 12 de noviembre.

**27–33 · ConcepTest 1** (`conceptests.md`): voto → discusión en parejas → revoto → explicación. Esperado
50–60 % en el primer voto. Si el primer voto es > 80 %, saltar la discusión y ganar 3 minutos para la
práctica.

**33–35 · Puente al *ping-pong*.** Una frase: "Lo segundo que van a medir es cuánto cuesta un mensaje.
Modelo: tiempo = latencia + bytes / ancho de banda. Apuesten antes de medir: ¿cuántas veces más tarda 1 MiB
que 8 bytes?" (Es la predicción P5a de la práctica.)

### 35–65 · Práctica guiada PRIMM (`practica-guiada/README.md`)

**Arranque (35–36).** Parejas; conductor y navegante; `make` en una terminal. "Primero predicen por escrito
las 10 preguntas de la tabla. Nadie corre nada hasta el minuto 40."

**35–40 Predecir · 40–48 Ejecutar · 48–58 Investigar (I1, I2 con E1, I4; I3 se contesta con la salida
impresa en el README; E2 solo si sobra) · 58–65 Modificar (M1).** Cambio de roles al minuto 50 (anunciarlo
en voz alta). Si al minuto 58 ninguna pareja corrió E2, el profesor lo corre en la puesta en común: una copia
de `ring_token.c` donde todos hacen `Send(token + rank)` y luego `Recv` (20 segundos).

El profesor circula con esta lista. No da respuestas: hace la pregunta de la derecha.

| Error esperado | Pregunta que se hace |
|---|---|
| `mpirun`: *not enough slots* | "¿Cuántos núcleos detecta tu máquina? ¿Qué hace `--oversubscribe` en el `Makefile`?" |
| Predicen que el rango 1 recibe −1 (P1c, idea 16) | "¿Cuántas variables llamadas `token` existen cuando corres con `-np 5`? ¿En qué memoria vive cada una?" |
| Predicen que el intercambio cruzado "siempre termina" o "nunca termina" (idea 17) | "¿Qué es lo único que promete `MPI_Send` al regresar? ¿Eso depende del tamaño?" |
| Al colgarse, creen que la máquina se trabó | "¿En qué llamada está **cada** proceso ahora mismo? Dibújalos." |
| Buscan el umbral con `-O0` o sin `timeout` y se desesperan | "¿Qué código regresa `timeout` cuando mata al programa? ¿Cómo lo usas en un ciclo?" |
| En I2-E1 ponen al rango 0 a recibir primero y no entienden el cuelgue "si el mensaje es chico" | "¿Quién envía el **primer** mensaje del anillo? Si nadie, ¿qué hay que copiar a un búfer?" |
| En I2-E2 obtienen `token final = 4` y lo reportan como correcto | "¿Qué valor tenía el rango 4 cuando envió? ¿Ya había recibido el acumulado?" |
| En I3 cambian `CAPACITY` en vez de la cuenta del `Recv` y disparan la validación de uso | "¿Qué argumento de `MPI_Recv` decide cuánto cabe? ¿Dónde más se usa `CAPACITY`?" |
| En I4 reportan la latencia de una sola corrida o el promedio | "¿Qué estadístico pide el protocolo y por qué? ¿Qué columnas de la tabla muestran el ruido?" |
| M1: pasan `&send_buf` o `sizeof` como cuenta en `MPI_Sendrecv` | "¿`count` es en bytes o en elementos? ¿`send_buf` ya es una dirección?" |
| M1: `MPI_Sendrecv` con etiquetas distintas en envío y recepción → se cuelga con n = 10 | "¿Qué tres cosas deben coincidir para que una recepción acepte un mensaje? ¿Coinciden las tuyas?" |
| M1: usan el mismo búfer para enviar y recibir | "¿Puede MPI escribir lo recibido encima de lo que todavía no termina de enviar? Lee el estándar: los búferes de `Sendrecv` no pueden solaparse." |
| Terminan M1 y declaran "listo" sin correr `make test` | "¿Qué dice la línea `cross_exchange_sendrecv` de `make test`?" |

**Solución de referencia de `TODO(1)`** (verificada: `make test` → `13 PASS` cuando se completan todos los `TODO`):

```c
MPI_Sendrecv(send_buf, n, MPI_INT, partner, TAG_DATA,
             recv_buf, n, MPI_INT, partner, TAG_DATA,
             MPI_COMM_WORLD, &status);
```

y `todo_pending = 0`.

### 65–75 · Puesta en común

Mostrar tres hallazgos (sin nombres), pidiendo a una pareja al azar que lea su tabla:

1. **El umbral.** En autoría: termina con n = 1 010 (4 040 bytes), se cuelga con n = 1 015 (4 060 bytes);
   `btl_vader_eager_limit` = 4096 incluyendo encabezado. "Ese número no es de ustedes: es de esta máquina,
   hoy. Un programa correcto no lo conoce."
2. **El anillo.** E1 (todos reciben primero) se cuelga con 4 bytes: no es cuestión de tamaño. E2 (todos
   envían primero) termina con `token final = 4` en vez de 10: terminar no es estar bien. (Ambos verificados
   con `-np 5`; si nadie llegó a E2, correrlo aquí en vivo.)
3. **El costo.** Rtt de 3.0 µs a 512 bytes y 12.2 µs a 4 096 bytes: el salto coincide con el cambio de
   protocolo (*eager* → *rendezvous*), el mismo umbral del hallazgo 1 visto desde el tiempo (parte del salto
   es simplemente 8 veces más bytes). Un mensaje de 1 MiB (≈ 460 µs) vale unos 2 000 mensajes de 8 bytes
   (≈ 0.21 µs).

**ConcepTest 2** (minuto 68; esperado 60–70 %). **ConcepTest 3** (minuto 72; esperado 65–75 %). Si la práctica
se alargó, ConcepTest 3 pasa al inicio de S05 (martes 17 de noviembre) y se recorta Transferencia, nunca el
cierre.

Regla general en una frase, escrita en el pizarrón y copiada por todos: **"Un programa MPI es correcto solo
si termina aunque todos sus `MPI_Send` bloqueen; y la comunicación se paga por mensaje, no solo por byte."**

### 75–85 · Transferencia: fase Crear (`ring_neighbors.c`)

Reto: completar `TODO(2)` y `TODO(3)`: cada rango envía su arreglo a sus dos vecinos y recibe el de cada
uno. Criterio de "listo": `make test` con `PASS` en los tres casos `ring_neighbors` (`-np 2`, `4`, `5`) con
n = 10⁶.

- Apoyo para quien no arranca: "Es `cross_exchange_sendrecv` dos veces: una hacia la derecha, otra hacia la
  izquierda. ¿Quién es `partner` en cada una? ¿Con qué etiqueta?"
- Extensión para quien termina: versión por paridad. **Ojo:** hay dos organizaciones y solo una se cuelga.
  Por *corrimientos* (en cada dirección, pares `Send→Recv`, impares `Recv→Send`) termina con `-np 2`, `3`,
  `4` y `5`: el 0 envía al 1 (impar, ya recibiendo) antes de recibir del 4. Por *parejas* (pares intercambian
  todo con su derecho mientras impares con su izquierdo, luego al revés) termina con `-np 2` y `4` y se cuelga
  con `-np 3` y `5` (4 y 0 son pares y vecinos y se envían el uno al otro al mismo tiempo). Verificado con
  n = 10⁶ en autoría; con n = 10 todo termina. Pedir la predicción por escrito antes de correr y la explicación
  de por qué `MPI_Sendrecv` no necesita el análisis. Segunda extensión: medir el intercambio con `MPI_Wtime`
  y compararlo con la fila de 4 MiB del *ping-pong*.

**Solución de referencia de `TODO(2)` y `TODO(3)`** (verificada con `-np 2`, `3`, `4`, `5` y n = 10⁶):

```c
/* TODO(2): hacia la derecha */
MPI_Sendrecv(send_buf, n, MPI_INT, right, TAG_RIGHT,
             from_left, n, MPI_INT, left, TAG_RIGHT,
             MPI_COMM_WORLD, MPI_STATUS_IGNORE);
/* TODO(3): hacia la izquierda */
MPI_Sendrecv(send_buf, n, MPI_INT, left, TAG_LEFT,
             from_right, n, MPI_INT, right, TAG_LEFT,
             MPI_COMM_WORLD, MPI_STATUS_IGNORE);
```

y `todo_pending = 0`.

### 85–90 · Cierre

- *Exit ticket* (`exit-ticket.md`): 2 preguntas + confianza, en la hoja, con número de lista. Se recoge al salir.
- Anuncios, con fecha:
  - **Mañana martes 10 de noviembre, 08:30, Lab LS4 (Edificio 3): Práctica 5 · Lab 1.** El
    **pre-laboratorio de la Práctica 5** se entrega antes de las **08:30 del martes 10 de noviembre**, en el
    repositorio del equipo. La Práctica 5 vale **15 % del 3er parcial** y se entrega el **domingo 22 de
    noviembre, 23:59**.
  - Tarea espaciada (`tarea-espaciada.md`, 20–40 min): individual, en `tareas/<usuario-github>/U4-S02.md` (el
    código, en `tareas/<usuario-github>/U4-S02/`), antes del **martes 10 de noviembre, 08:30** (inicio de S03);
    ahí se autocalifica en los minutos 5–10.
  - El jueves 12 de noviembre también se devuelve la retroalimentación del Examen 2.

## Diferenciación

- **Apoyo (quien no arranca en PRIMM):** entregarle impresa la tabla de rastreo del anillo (I2) ya llena
  para `-np 3` y pedirle que la extienda a `-np 5`; para M1, darle la firma de `MPI_Sendrecv` con los
  argumentos numerados 1–12 y pedirle que escriba al lado de cada número de dónde sale (de la llamada a
  `Send` o a `Recv` que quita).
- **Ampliación (quien termina Crear antes del minuto 85):** (a) versión por paridad de `ring_neighbors` en
  sus dos organizaciones (corrimientos vs. parejas) y demostrar cuál se cuelga con `-np 5` y por qué; (b) medir el intercambio de 4 MB con `MPI_Wtime` y explicar la
  diferencia con el *ping-pong*; (c) leer `MPI_Probe` en la documentación de Open MPI y reescribir el
  receptor de `status_demo.c` para que reserve exactamente lo que llega.

## Evaluación formativa de la sesión

| Objetivo | Qué mira el profesor | Umbral de alerta |
|---|---|---|
| 1 (firma, `Status`, `Get_count`) | Columna "Observado" de P4b; M1 compila a la primera sin confundir cuenta/bytes | > 30 % de parejas con `MPI_ERR_TRUNCATE` o cuenta en bytes en M1 |
| 2 (semántica de `Send`) | ConcepTest 1 revoto; *exit ticket* P1 | Revoto < 80 % o > 30 % de *exit tickets* en "mal" |
| 3 (corregir el intercambio) | `make test` con `PASS` en `cross_exchange_sendrecv` al minuto 65 | < 70 % de parejas con `PASS` |
| 4 (modelo de costo) | ConcepTest 3; *exit ticket* P2 inciso c | > 30 % contesta que "da igual" |

El mismo día: clasificar los *exit tickets* (bien / parcial / mal) y abrir S03 (martes 10 de noviembre, 08:30)
con el error más frecuente. Si la P2 del *exit ticket* sale mal en más del 30 %, el ConcepTest 3 se repite en S05.

## Notas post-sesión

| Qué | Anotación |
|---|---|
| ConcepTest que falló y por qué | |
| Error más frecuente del *exit ticket* | |
| ¿Se colgó `cross_exchange_buggy` en la máquina del salón? ¿Con qué n? | |
| Bloque que se alargó / qué recortar la próxima vez | |
| Cambio para la siguiente edición | |
