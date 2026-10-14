> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S01 · jueves 5 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S01 · Modelo de memoria distribuida y SPMD: primeros programas con MPI

Tipo: Contenido (estructura base de 90 min). Primera sesión de la Unidad IV. Se publica la Práctica 5.

## Objetivos (al terminar, el estudiante podrá…)

1. **Explicar**, con un diagrama y un fragmento de código, por qué dos procesos MPI no comparten variables y
   qué se necesita para que un dato pase de uno a otro (comprender). → Se evalúa en CT1 y exit ticket P1.
2. **Compilar y ejecutar** con `mpicc` y `mpirun -np p` un programa SPMD con `MPI_Init`, `MPI_Comm_rank`,
   `MPI_Comm_size` y `MPI_Finalize`, y **predecir** cuántas líneas imprime y si el orden está garantizado
   (aplicar). → PRIMM Predecir/Ejecutar, exit ticket P2(c).
3. **Calcular** a mano y en código los índices que toma cada rango con reparto por bloques con residuo y con
   reparto cíclico, para `n` no múltiplo de `p` (aplicar). → CT2, exit ticket P2(a)(b), TODO(1).
4. **Mapear** las etapas de Foster (partición, comunicación, aglomeración, mapeo) a una suma distribuida y
   **medir** su tiempo con `MPI_Barrier` + `MPI_Wtime` contra la versión secuencial (analizar). → Investigar I6,
   tarea espaciada ejercicios 1 y 2.

## Prerrequisitos y vínculo

- **Viene de:** Examen 2 (martes 3 de noviembre), Unidad III completa. El grupo lleva cinco semanas con hilos
  que comparten memoria; toda la sesión se construye por contraste con eso. De la Unidad I se usa memoria
  compartida vs. distribuida y Flynn; de la Unidad II, el método de Foster.
- **Va hacia:** S02 (lunes 9 de noviembre, 10:30): `MPI_Send`/`MPI_Recv` completos, etiquetas, `MPI_Status`,
  semántica de bloqueo e interbloqueo, *ping-pong*. S03 (martes 10 de noviembre, 08:30): Lab 1 de la Práctica 5
  con colectivas. Práctica 5 (`practicas/P5-mpi/`), límite domingo 22 de noviembre 23:59, 15 % del 3er parcial.
- **Ideas erróneas que ataca (Anexo A):**
  - **16** "Los procesos MPI comparten memoria" → `counter` en `hello_rank`, CT1, pausa 3 del ejemplo,
    Investigar I4, exit ticket P1.
  - **19** "El rango 0 tiene que ser el maestro" → línea del último rango en `hello_rank`, pausa 5, CT3, Modificar M2.
  - **1** "Más hilos/procesos siempre es más rápido" → Investigar I6: con `n = 10` cuatro procesos tardan más
    que uno; con `n = 10⁹` sí escala. Tarea, ejercicio 2.
  - **28** "Aglomerar es juntar todo en un proceso" → recuperación P4 y tabla de Foster del ejemplo.

## Materiales

- Todos los archivos de esta carpeta; proyector; cronómetro visible; tarjetas con números de lista; tarjetas A/B/C/D.
- Máquina del salón con Open MPI y `make`. **Antes de la sesión:** `cd practica-guiada && make && make test`
  (≈ 15 s; resultado esperado: 15 PASS, 0 FAIL, 2 SKIP; los SKIP son el TODO(1) y el programa de la fase Crear).
- Si la máquina del salón no tiene MPI: un estudiante proyecta desde su laptop. Instalación:
  `sudo apt install openmpi-bin libopenmpi-dev` (Ubuntu/Debian, también en WSL), `brew install open-mpi` (macOS).
- Pizarrón: antes de empezar, dibujar el diagrama de `notas-estudiante.md` §1 (dos columnas: hilos sobre una
  memoria; procesos con cajas separadas unidas por flechas de mensajes).

## Guion minuto a minuto

### 0–5 Recuperación

Proyectar `retrieval-inicio.md`. 4 minutos en silencio, por escrito. Al minuto 4, mostrar las respuestas y
contar manos por pregunta; anotar los conteos en "Notas post-sesión".

- Respuestas esperadas: P1 carrera + `reduction`; P2 E = 0.70, Amdahl 3.08, consistente; P3 solo la laptop,
  ambos MIMD; P4 agrupar tareas sin perder paralelismo; P5 cuatro variables, las otras ven 0.
- Si **P1 < 60 %** (carrera/`reduction`): no reexplicar hoy; decir "esto se retoma con la retroalimentación del
  Examen 2 el jueves 12 de noviembre" y anotarlo.
- Si **P3 < 60 %** (compartida vs. distribuida): dedicar 2 minutos extra al diagrama en el bloque 5–10 y
  recortar Transferencia.
- P5 es el gancho: pedir manos a "¿quién escribió *una* variable?". Ese número se retoma en CT1.

### 5–10 Objetivos y anclaje

Frase de apertura: "El martes hicieron el Examen 2 con hilos que comparten memoria. Hoy le quitamos la
memoria compartida. Lo que queda son procesos que solo pueden hablar por mensajes. Así corren los clústeres y
así es MPI."

Conexión con el *exit ticket* anterior (S13, jueves 29 de octubre; anotar aquí el error más frecuente:
________). Si fue "la fracción secuencial se cuenta en líneas de código" (idea 2), decir: "hoy volvemos a medir
y la fracción secuencial se mide en tiempo; tarea de hoy, ejercicio 2".

Conexión con el proyecto y la evaluación: "La V2 del proyecto (H2, lunes 23 de noviembre) sigue siendo memoria
compartida; MPI entra en la Práctica 5 (15 % del 3er parcial) y en el Examen 3 (martes 8 de diciembre)."

Proyectar los cuatro objetivos. Señalar el diagrama del pizarrón: "al terminar, me van a explicar por qué la
caja de la derecha no puede leer la de la izquierda".

### 10–35 Instrucción explícita I

**10–13 · Dos memorias, dos unidades de ejecución.** Pensar en voz alta sobre el diagrama: "en OpenMP, `total`
existía una vez y cuatro hilos la golpeaban: carrera. Aquí `total` existe cuatro veces y nadie golpea a nadie:
el riesgo cambia de carrera a *olvidar mandar el dato*". Tabla procesos vs. hilos de las notas (§2) en 60 s:
`mpirun -np 4` lanza 4 procesos con 4 `pid`; `ps` los vería.

**13–18 · `hello_rank.c`.** Proyectar el archivo. Leer línea por línea: `Init` → `rank`/`size` → `printf` que
ejecutan todos → `counter` → dos `if` por rango → `Finalize`. Preguntar por tarjeta de lista (nunca "¿alguien?"):
"número __: ¿cuántas líneas salen con `-np 4`?" (10) "número __: ¿y con `-np 1`?" (4: el rango 0 también es el
último). "número __: ¿qué imprime `[rango 3] counter = `?" (4, no 10). Ejecutar **dos veces** seguidas y
señalar que el orden cambió (si no cambia a la segunda, correr una tercera; en la máquina de autoría cambió entre
las corridas 1 y 2). Señalar los `pid` distintos. Decir en voz alta: "la línea 'nada me obliga a ser el maestro'
está ahí a propósito: rango 0 es una convención".

**18–23 · ConcepTest 1** (`conceptests.md`): voto → si 30–80 % discusión en parejas 2 min → revoto →
explicación. Acierto esperado en el primer voto: 55–65 %. Explicación en una frase: "cuatro procesos, cuatro
`x`; la barrera sincroniza el avance, no la memoria". Mostrar la salida real: `x = 0`.

**23–33 · Ejemplo resuelto** (`ejemplo-resuelto.md`). Proyectar el núcleo del código.
1. `block_range` en el pizarrón con `n = 10`, `p = 4`: tabla `q = 2`, `r = 2`, `count = 3,3,2,2`,
   `start = 0,3,6,8`. **Pausa 2** ("¿qué pasa con `n/p` para todos?"): pedir respuesta por tarjeta.
2. Correr `mpirun -np 4 ./suma_distribuida 10 bloques` y `-np 3`. Señalar que el orden de las líneas de rango
   fue distinto en las dos corridas.
3. **Pausa 3** ("¿cuánto vale `total` en el rango 2?"): mostrar la salida con `printf` de `total` en todos los
   rangos (está en el ejemplo resuelto): 64.9 / 206.7 / 548.5 / 97.3. "Cuatro variables, cuatro valores."
4. **Pausa 4** en 30 s: "el rango 0 recibe en orden 1, 2, 3 aunque el 3 termine primero; su mensaje espera".
5. Variante que falla: correr `suma_distribuida_buggy 10` con `-np 4` (483.6) y con `-np 5` (548.5). Frase:
   "un reparto se prueba con `n` que no sea múltiplo de `p`".
6. Tabla de Foster (ejemplo resuelto, "Plan"): partición `n` tareas → aglomeración `p` bloques → mapeo bloque
   `k` → rango `k`; la comunicación son `p − 1` mensajes. "Aglomerar bajó los mensajes de `n` a `p − 1` sin
   perder paralelismo; juntar todo en un proceso bajaría a 0 mensajes y a 0 paralelismo" (idea 28).

**33–35 · Medir.** Correr una vez `./referencia_secuencial 1000000000` y `mpirun -np 4 ./suma_distribuida
1000000000`. Decir: "esto es *una corrida*, no una medición; el protocolo (calentamiento, 5 repeticiones,
mediana) es parte de la tarea". Señalar la barrera antes de `MPI_Wtime` (**Pausa 6**).

### 35–65 Práctica guiada PRIMM

Arranque (1 min): parejas; roles conductor (teclado) y navegante (lee el README y escribe las predicciones);
**cambio de roles al minuto 50**. `cd practica-guiada && make`. Si la máquina tiene menos núcleos que procesos,
el `Makefile` ya pasa `--oversubscribe`.

Tiempos sugeridos: Predecir 35–42 (por escrito, antes de correr nada) · Ejecutar 42–47 · Investigar 47–57 ·
Modificar 57–65 (TODO(1) cíclico). Quien no llegue a I6 (medición) lo salta: está en la tarea.

El profesor circula con esta lista. No da respuestas; hace la pregunta de la derecha.

| # | Error esperado | Pregunta que se hace |
|---|---|---|
| 1 | `There are not enough slots available` | "¿Cuántos núcleos tiene tu máquina y cuántos procesos pediste? ¿Qué bandera pone el `Makefile` en `MPIRUN_FLAGS`?" |
| 2 | Predicen `counter = 10` (o 6) para el rango 3 | "¿Cuántas copias de `counter` hay cuando corres con `-np 4`? Mira los `pid`." |
| 3 | Predicen {4, 5} para el rango 2 por bloques | "Suma los tamaños de los cuatro bloques de tu respuesta. ¿Dan 10? ¿Quién toma el 8 y el 9?" |
| 4 | Predicen que el orden "Hola" es 0, 1, 2, 3 siempre | "¿Quién decide cuándo corre cada proceso? Córrelo tres veces y cuenta." |
| 5 | Creen que `MPI_Barrier` antes del `printf` ordena la salida | "Después de la barrera, ¿quién llega primero al `printf`? ¿Qué cambió?" |
| 6 | Compilan con `gcc` → `mpi.h: No such file or directory` (o `undefined reference to MPI_Init`, si añadieron la ruta de los encabezados) | "¿Qué agrega `mpicc` que `gcc` no sabe?" |
| 7 | Al agregar el `printf` de `total` (I4) dicen que "no se actualizó" en el rango 2 | "¿Quién le mandó algo al rango 2? Busca el `MPI_Recv` que lo recibiría." |
| 8 | Corren `_buggy` con `-np 5`, sale bien y concluyen que no tiene error | "¿Cuánto es 10 % 5? ¿Y 10 % 4? ¿Con qué `n` lo atraparías para cualquier `p`?" |
| 9 | TODO(1): `for (i = rank; i < n; i += rank)` | "¿Qué hace el rango 0 con ese paso? ¿Qué paso da la vuelta completa a los procesos?" |
| 10 | TODO(1): paso correcto pero no actualizan `last`, `first` o `step` | "¿Qué imprime tu línea de índices? ¿Coincide con tu predicción {2, 6}?" |
| 11 | TODO(1): dejan las tres líneas de `TODO pendiente` | "¿Qué línea imprime eso? ¿Qué hace el `return` que sigue?" |
| 12 | Miden con `n = 10` y concluyen que "MPI es más lento" | "¿Cuánto trabajo hace cada proceso con `n = 10`? ¿Qué estás midiendo entonces?" (idea 1 y protocolo 2.6) |
| 13 | `n = 2` con `-np 4`: se sorprenden de rangos con 0 elementos | "¿Qué suma parcial manda un rango sin elementos? ¿Rompe el total?" (no: manda 0.0) |
| 14 | Corren como root y Open MPI se niega | "Lee el mensaje completo: ¿qué dos variables pide?" |

Al minuto 50: cambio de roles. Al minuto 57: todos deben estar en Modificar; quien sigue en Investigar deja I5 e
I6 para la casa.

### 65–75 Puesta en común

Mostrar (sin nombres) 2–3 hallazgos recogidos al circular:

1. Dos hojas de predicción con órdenes distintos de "Hola" y las salidas reales de dos parejas: "ninguna
   estaba mal; ninguna estaba garantizada".
2. La tabla de rastreo de `block_range` de una pareja (I3) y, al lado, el error #3 si apareció.
3. La salida de I4 (`total` por rango) de una pareja que la tenía: "¿cuántas variables `total`?".

**ConcepTest 2** (índices del rango 2): voto → discusión si hace falta → revoto → explicación con la tabla del
pizarrón. Acierto esperado: 60–70 %.

Regla general (dictarla, que la copien): **"En MPI nada se comparte. Lo que un proceso necesita de otro
viaja en un mensaje. El reparto de índices es responsabilidad del programador: `n/p` no basta cuando hay
residuo."**

### 75–85 Transferencia

Reto (fase **Crear** del README): `promedio_maximo.c`. Cada proceso calcula suma parcial y máximo parcial de su
bloque; un rango combina e imprime `promedio = X` y `maximo = Y` (formato `%.3f`). Criterio de "listo":
`make test` muestra 8 PASS para `promedio_maximo` (n = 10 y n = 1 000 003 con 1, 2, 3 y 4 procesos).

- Apoyo para quien no arranca: "copia `suma_distribuida.c`, cambia el cuerpo del ciclo para llevar también el
  máximo, y manda **dos** `double` en un solo mensaje: `double stats[2]`". Quien no terminó TODO(1) lo termina
  en lugar del reto.
- Extensión para quien termina: que el **último** rango (`size − 1`) sea el que combina el máximo (idea 19);
  después, versión cíclica del promedio. Si sobran 5 minutos en el grupo: **ConcepTest 3**.

### 85–90 Cierre

`exit-ticket.md` en papel (5 min; número de lista, no nombre). Mientras escriben, anunciar textualmente:

1. "Queda publicada la **Práctica 5** (MPI) en `practicas/P5-mpi/`. El pre-laboratorio es individual y se
   entrega al inicio de la sesión del **martes 10 de noviembre, 08:30**. La entrega final es el **domingo 22 de
   noviembre a las 23:59** y vale **15 % del 3er parcial**. La rúbrica ya está publicada con el enunciado."
2. "La **retroalimentación del Examen 2** se da el **jueves 12 de noviembre** en clase."
3. "Tarea espaciada (`tarea-espaciada.md`): 30 minutos; se revisa al inicio de la sesión del lunes 9 de noviembre."
4. "Siguiente sesión: **lunes 9 de noviembre, 10:30, Salón 3208**: `MPI_Send`/`MPI_Recv` a fondo e
   interbloqueo. Lean las notas de hoy antes."

## Diferenciación

- **Apoyo (quien no arranca):** entregar impresa la tabla de rastreo de `block_range` con la primera fila
  resuelta (`rank 0: q=2, r=2, count=3, start=0, end=3`) y pedir las otras tres. Para TODO(1), dar la primera
  línea: `for (long long i = rank; i < n; i += size)` y pedir qué va dentro.
- **Ampliación (quien termina):** (a) que el último rango combine (M2) y que el rango 0 **también** intente
  recibir: observar el cuelgue (se termina con Ctrl+C; verificado: con `-np 4` imprime las cuatro parciales y nunca la
  suma total) y explicarlo (anticipa S02); (b) `promedio_maximo` con reparto cíclico;
  (c) medir con el protocolo completo y calcular Karp–Flatt para `p = 2, 3, 4`.

## Evaluación formativa de la sesión

| Objetivo | Qué mira el profesor | Umbral |
|---|---|---|
| 1 (memoria no compartida) | Revoto de CT1 ≥ 80 %; exit ticket P1 menciona "mensaje/enviar" | < 60 % en P1 → abrir S02 con el diagrama otra vez |
| 2 (compilar, ejecutar, predecir) | Hojas de predicción P1–P4 llenas antes de correr; todas las parejas ejecutaron `make` sin ayuda | Más de 3 parejas con error #1 o #6 → guía de instalación antes del martes |
| 3 (índices) | CT2 revoto ≥ 80 %; exit ticket P2(a)(b); TODO(1) pasa `make test` en ≥ 70 % de las parejas | < 60 % en P2(a) → ejercicio 1 de la tarea se revisa en el pizarrón el lunes |
| 4 (Foster + medir) | I6 llena con `n = 10` y `n = 10⁹`; la pareja explica por qué `n = 10` no sirve | Se verifica en la tarea (ejercicio 2) |

## Soluciones para el profesor

**TODO(1), reparto cíclico** (reemplaza las tres líneas de `TODO pendiente`):

```c
        for (long long i = rank; i < n; i += size) {
            local_sum += element(i);
            local_count++;
            last = i;
        }
        first = rank;
        step = size;
```

Salida real con `-np 4`, `n = 10`: rango 0 {0, 4, 8} = 106.700; rango 1 {1, 5, 9} = 182.400; rango 2 {2, 6} =
137.800; rango 3 {3, 7} = 121.600; total 548.500. Con esta solución `make test` da 24 PASS (incluye los 9 del
reparto cíclico).

**M2, combina el último rango:** destino de `MPI_Send` = `size - 1`; condición `if (rank != size - 1)`;
el ciclo de recepción recorre `src = 0 .. size - 2`; imprime `size - 1`. Las pruebas siguen pasando porque
leen la línea `suma total` sin importar quién la imprime.

**Crear, `promedio_maximo.c`:** cada rango llena `double stats[2] = {suma parcial, máximo parcial}` (máximo
inicial `-1.0`, menor que cualquier elemento, para que un bloque vacío no gane); un `MPI_Send(stats, 2,
MPI_DOUBLE, 0, 0, MPI_COMM_WORLD)` por rango; el rango 0 acumula la suma, toma el mayor máximo e imprime
`promedio = total / n` y `maximo`. Salida real con `-np 4`, `n = 10`: `promedio = 54.850`, `maximo = 93.200`
(coincide con `referencia_secuencial 10`). Con esta solución y la de TODO(1), `make test` da 32 PASS, 0 FAIL.

## Notas post-sesión

- Conteos de recuperación (P1–P5): ____ / ____ / ____ / ____ / ____
- CT1 primer voto ____ % · revoto ____ %. CT2 primer voto ____ % · revoto ____ %. CT3 (si se usó) ____ %.
- Errores de la lista que aparecieron (números): ____
- Parejas que pasaron TODO(1): ____ de ____. Parejas con `promedio_maximo` listo: ____
- Error más frecuente del exit ticket (abre S02 el lunes 9 de noviembre): ____
- Qué cambiar la próxima vez: ____
