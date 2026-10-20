> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S13 · jueves 29 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S13 · Recepción de H1 (Avance 1 del proyecto) + repaso de la Unidad III: examen de práctica, corrección entre pares, calibración

Tipo: repaso previo a examen (variante 2.2 de `docs/metodo/02-plantilla-sesion.md`) con recepción de hito en
los primeros 20 minutos, como fija la variante 2.5 para S13: el examen de práctica se publica el martes 27 de
octubre, se resuelve **en casa** cronometrado (40 min) y en clase se corrige. Este plan está escrito para que lo
pueda dar otro profesor sin hablar con el autor.

## Objetivos (al terminar, el estudiante podrá…)

1. **Demostrar** en 90 segundos, con el repositorio abierto, qué midió su equipo en la V1 (perfil por
   secciones, `T(1)`, `f_p`, predicción de Amdahl) y qué no entiende todavía (nivel: evaluar).
2. **Corregir** el examen de práctica de un compañero con la clave y la guía de corrección, asignando puntos
   por inciso con el criterio literal (nivel: aplicar/evaluar).
3. **Explicar** los tres errores más frecuentes del grupo en los ítems de la Unidad III, nombrando la idea
   errónea y la regla que la sustituye (nivel: analizar).
4. **Calibrar** su juicio: comparar la calificación que predijo y la que creyó obtener con la real, y
   **escribir** un plan de estudio con tema, archivo y minutos por día hasta el martes 3 de noviembre
   (nivel: evaluar).

El objetivo 1 se evalúa en la lista de cotejo rápida de H1; el 2 en la hoja corregida y firmada; el 3 en el
revoto de los ConcepTests y en la pregunta 1 del *exit ticket*; el 4 en la hoja de calibración (casilla 3) y
en la pregunta 2 del *exit ticket*.

## Prerrequisitos y vínculo

- **Viene de:** S12, martes 27 de octubre (Lab 2 de la Práctica 4 y taller V1 → V2). El grupo trae: la
  etiqueta `H1` en su repositorio antes de las 10:30 de hoy; el examen de práctica (`examen-practica-U3.md`)
  resuelto en casa, cronometrado, con las casillas 1 y 2 de la hoja de calibración llenas; la tarea de S12
  (partes 1b, 2 y 3) para autocalificar.
- **Va hacia:** **Examen departamental 2**, martes 3 de noviembre, 08:30–10:00 (versiones A/B, 80 min, sin
  dispositivos); **Práctica 4**, domingo 1 de noviembre, 23:59; lunes 2 de noviembre sin clase; **Unidad IV**,
  jueves 5 de noviembre, 10:30 (modelo de memoria distribuida y SPMD), donde se hace la pregunta individual de
  H1 que no cabe hoy; retroalimentación escrita de H1 a más tardar el jueves 5 de noviembre.
- **Ideas erróneas que esta sesión ataca** (Anexo A): repaso completo de la **7 a la 15** (Unidad III) y de la
  **1 a la 6** (rendimiento), más 30, 31 y 32. Dónde aparece cada una:

| Idea | Examen de práctica | ConcepTest | Práctica guiada (en casa) | Retrieval / exit |
|---|---|---|---|---|
| 1, 3, 31 | I.5, V, *exit* 1 | CT1 (A, C) | Pausa 5 del ejemplo | R7, *exit* 1 |
| 2 | V.a, guía de corrección | — | — | R1 |
| 5 | I.1-C, I.5 | CT1-D | — | — |
| 6 | I.5-C/D | — | — | tarea 2a |
| 7 | I.1, III.1 | — | caza1 (una rep. "buena" con 2 hilos), variante que falla | — |
| 8 | I.2 | — | tabla de alternativas de caza1 | R3 |
| 9, 15 | II.1-c, III.1-c | CT2 (A, B) | caza3, Pausas 1–2 del ejemplo | — |
| 10 | III.1-d | — | `make test` con tolerancia (caza1) | — |
| 11 | I.3, VI | CT3-A | — | R4 |
| 12, 32 | — | CT2 (D) | caza2, Pausa 3 del ejemplo | — |
| 13 | I.4, IV | — | pista de Crear (`caza4`) | R5 |
| 14 | VI | — | — | — |
| 30 | III.2 | CT3 | — | R6 |

- **Nivel de andamiaje:** problema libre con pistas selladas (fin de unidad, `07-guia-de-autoria.md` §A.5): el
  ejemplo resuelto es un problema por completar (3 huecos con pista y respuesta en `<details>`); la práctica
  guiada se hace en casa y da 15 minutos a Crear; el examen de práctica no tiene pistas, solo clave.

## Materiales

- Esta carpeta completa. Antes de la sesión, en la máquina del salón: `cd practica-guiada && make && make test`
  (53 PASS, ~17 s) y `make run-examen` (salidas de la clave en pantalla, ~15 s). Tener abiertas dos terminales
  en `practica-guiada/` con `export OMP_NUM_THREADS=4`.
- `examen-practica-U3.md` proyectable (clave por ítem en `<details>`; la guía de corrección entre pares impresa
  o proyectada). Hoja de calibración: cada estudiante trae la suya con las casillas 1 y 2; hojas en blanco
  para quien no.
- Lista de cotejo rápida de H1 (abajo), impresa: una fila por equipo. Antes de clase (la tarde del miércoles
  28): clonar cada repositorio en la etiqueta `H1` y correr los cuatro comandos de `proyecto/hitos/H1-avance-1.md`
  §3 (≈ 5 min por equipo; criterios 1–4 se califican fuera de clase, opción A de H1 §8).
- Proyector, cronómetro visible, tarjetas con números de lista. Plan B de `02` §2.7: recuperación y *exit
  ticket* dictados; corrección entre pares con la clave impresa (una por pareja).
- Hoja de seguimiento (`herramientas/seguimiento-grupo.csv` → copia en `docente/`) para registrar predicción,
  postdicción y real del examen de práctica.

## Decisiones previas que este plan asume

1. **Opción A** de `proyecto/hitos/H1-avance-1.md` §8, anunciada el lunes 26 de octubre (S11): criterios 1–4 se
   evalúan con la etiqueta fuera de clase; hoy, ronda de 90 s por equipo con las dos preguntas fijas; la
   pregunta individual se hace el jueves 5 de noviembre (U4 S01) en los primeros 20 minutos. Si se eligió la
   **opción B** (recepción anticipada el 27 para quien tenía etiqueta), hoy solo pasan los equipos restantes y
   el bloque 8–28 se acorta en proporción (el tiempo sobrante va a la corrección entre pares). Si se eligió la
   **opción C**, se sustituye el bloque 8–28 por 8–43 y la corrección entre pares se hace en 43–60 con solo
   las secciones I, II y V; III, IV y VI se corrigen en casa.
2. El examen de práctica se publicó el martes 27 y se anunció en el cierre de S12. Quien no lo trae resuelto lo
   resuelve **en silencio** en el bloque 8–48 (40 min) mientras los demás corrigen, lo corrige en casa con la
   clave y entrega la hoja de calibración el martes 3; participa en el bloque 50–80 y en el *exit ticket*.
3. Con más de 12 equipos, la ronda es de 75 s (dos preguntas, sin repreguntar) y se avisa al empezar.

## Lista de cotejo rápida de H1 (una fila por equipo; se llena en la ronda de 90 s y con lo visto el 28)

Referencia: `proyecto/hitos/H1-avance-1.md` §3 (qué corre el profesor), §5 (autoevaluación) y §6 (preguntas).
La rúbrica (§4) **no** se aplica aquí; se aplica fuera de clase y la retroalimentación escrita llega a más
tardar el jueves 5 de noviembre.

| Equipo | Etiqueta `H1` antes de 10:30 | `make && make test` sin *warnings*, código 0 (visto el 28) | `T(1) ≥ 1 s` declarado; región sin E/S | Perfil ≥ 3 secciones, suma 90–100 % | `f_p` en tiempo + Amdahl 2/4/8 | Foster: 4 etapas + diagrama | Plan V2 con ≥ 4 riesgos | P1 "¿qué midieron?" (B/P/N) | P2 "¿qué no entienden?" (≥ 3 preguntas: B/P/N) | Bitácora ≥ 3 · declaración de IA con "qué nos dijo mal" | Nota de 1 línea |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | | | | | | | | | | | |
| … | | | | | | | | | | | |

B = bien · P = parcial · N = no. Las dos preguntas fijas (H1 §6): **"¿Qué midieron?"** (se espera la tabla del
perfil en pantalla, `T(1)`, `f_p` y la predicción de Amdahl) y **"¿Qué no entienden todavía?"** (la lista de
`reporte/H1.md`; una lista vacía cuenta en contra). Repregunta solo si la primera respuesta es "el ciclo
grande": "¿cuántos segundos y qué fracción?". La casilla "Nota" recoge lo que hay que decir por escrito.

## Guion minuto a minuto

### 0–8 · Recuperación larga (8 preguntas)

Proyectar `retrieval-inicio.md`. Seis minutos en silencio, sin apuntes. Al minuto 6 mostrar las respuestas y
pedir manos por pregunta; anotar el conteo de la 1 y la 2 (S12) y de la 3 y la 5 (S07, S09).

- Si la 1 (fracción en tiempo) queda bajo 60 %: el ítem V se discute **primero** en el bloque 50–80, esté o no
  entre los tres peores.
- Si la 3 o la 5 quedan bajo 60 %: CT2 se usa aunque los ítems II–IV no estén entre los tres peores.
- Si algún ítem de S12 quedó bajo 60 % en su sesión, hoy se repitió con pista en lugar de la pregunta 2 (ya
  previsto en `retrieval-inicio.md`).

### 8–28 · Recepción de H1 (ronda de 90 s por equipo) en paralelo con el arranque de la corrección

Frase de arranque (1 min): "Dos cosas al mismo tiempo. Yo paso por cada equipo 90 segundos con el repositorio
abierto en su laptop: dos preguntas, las de siempre: qué midieron y qué no entienden. Mientras no estoy con
ustedes: dos minutos para autocalificar la tarea del martes con su clave, y después intercambian el examen de
práctica con su pareja y corrigen con la guía de la última sección. Cuando llegue a su mesa, pausan y me
muestran el perfil."

Orden de la ronda: por sorteo con tarjetas (se anuncia el orden completo al inicio para que cada equipo tenga
el repositorio listo). Con 12 equipos: 18 minutos; el profesor lleva la lista de cotejo y marca B/P/N sin
discutir la calificación ("la rúbrica llega por escrito el jueves 5"). Qué **no** hacer: no abrir el código en
la ronda (ya se vio el 28), no aceptar "lo midió mi compañero" (la pregunta es al equipo, no a un integrante),
no extender más de 20 s a un equipo que no trae la etiqueta (se anota N en la primera casilla y aplica la regla
de 72 h al 80 %, H1 §1).

Mientras tanto, en las mesas:

1. (2 min) Autocalificación de la tarea de S12 (1b, 2, 3) con su clave; el profesor registra la entrega al
   pasar por cada mesa (una marca por integrante).
2. (16 min) **Corrección entre pares**, por parejas de PRIMM: intercambian hojas; corrigen con la clave de cada
   ítem (proyectada, o impresa una por pareja) y la guía de corrección; anotan puntos por inciso en el margen;
   marcan con "?" lo que no sabrían decidir. Orden sugerido: I, V, II (lo más rápido primero), después III, IV y VI.

### 28–50 · Corrección entre pares (continúa) y conteo por ítem

Al minuto 28 el profesor termina la ronda y circula entre las parejas con la lista de errores de corrección
(abajo). Al minuto 44: "Tres minutos: devuelvan la hoja, revisen lo que les marcaron, sumen el total y
escríbanlo en la casilla 3 de la hoja de calibración, con la brecha".

**Minuto 47–50, conteo a mano alzada por ítem** (12 preguntas, 10 segundos cada una): "¿Quién tuvo I.1 bien?…
¿II.1 completo?… ¿V completo?…". Anotar el conteo en la tabla de abajo. Los **tres ítems con menos manos** son
los del bloque 50–80. Si hay empate, gana el de más puntos.

| Ítem | I.1 | I.2 | I.3 | I.4 | I.5 | II.1 | II.2 | III.1 | III.2 | IV | V | VI |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Manos | | | | | | | | | | | | |

#### Errores esperados en la corrección entre pares y la pregunta que se hace

| # | Error del corrector | Pregunta socrática |
|---|---|---|
| 1 | Da los 3 puntos de II.1-a a `out=10 11 13 16 …` "porque la aritmética está bien" | "¿Cuántas copias de `base` hay con 4 hilos? ¿Qué dice la cláusula?" |
| 2 | Quita puntos en III.1-d porque `…686 ≠ …676` | "¿En qué orden suma `reduction`? ¿Qué dice la clave sobre la tolerancia?" (idea 10) |
| 3 | Da 2 puntos en III.1-b a `atomic` "porque es correcto" | "La pregunta dice *más barata que sea correcta*. ¿Cuántas operaciones atómicas hace `atomic` y cuántas `reduction`?" |
| 4 | Acepta en III.2-c "ponerle `critical`" | "¿`critical` obliga a que la iteración `i−1` termine antes que la `i`? ¿Qué obliga eso?" |
| 5 | Acepta `f_p = 0.9` en V.a porque "el núcleo A es la mayor parte del código" | "¿De qué se calcula la fracción de Amdahl, de líneas o de segundos? ¿Cuántos segundos son paralelizables?" (idea 2) |
| 6 | Da 2 puntos en V.c con `E = 2.11` | "¿Qué es la eficiencia? ¿Puede ser mayor que 1 sin explicación?" (idea 3) |
| 7 | En IV acepta `firstprivate(left)` en el hueco 1 | "¿Quién escribe `left` y quién la lee? Si cada uno tiene su copia, ¿qué lee el padre?" (S09 `fib_buggy`) |
| 8 | En VI da los 2 puntos de b) a `static` "porque no hay sincronización" | "¿Todas las `k` cuestan lo mismo? ¿Qué hilo termina al último con `static`?" (idea 11) |
| 9 | En I.4 discute que "depende de la máquina" | "¿Qué garantiza OpenMP sobre cuándo se ejecuta una tarea? ¿Qué construcción esperaría?" (idea 13) |
| 10 | Corrige con su propia respuesta en lugar de la clave | "¿Qué dice la clave? Si no estás de acuerdo, márcalo con ? y lo vemos en el bloque de discusión" |

### 50–80 · Los tres ítems peor contestados (10 minutos cada uno)

Cada ítem sigue la misma secuencia: (1) ConcepTest de la fila correspondiente (`conceptests.md`): voto →
discusión en parejas y revoto solo si el primer voto queda entre 30 % y 80 % → explicación (4 min); (2) la
clave del ítem **leída por un estudiante al azar** (tarjetas) y una pregunta del profesor sobre el distractor
más votado (3 min); (3) demostración en vivo cuando aplique (3 min). Guiones por ítem, en orden de
probabilidad de aparecer (por los *exit tickets* de S07–S12 y la experiencia del Examen 1):

| Ítem | ConcepTest | Qué proyectar / correr | Qué decir en 60 segundos |
|---|---|---|---|
| **V** (rendimiento) | CT1 | `python3 examen_items/item_V_numeros.py`; la tabla del perfil | "La fracción es de **segundos**: 3.2 de 4.0. Amdahl predice 2.5; midieron 2.1; Karp–Flatt dice que un 10 % del tiempo se fue en algo que el perfil no ve: sincronización, memoria, desbalance. Esa diferencia es lo que ustedes van a explicar en H2." |
| **II.1** (`firstprivate`) | CT2 | `OMP_NUM_THREADS=4 ./examen_items/item_II1_firstprivate` y con 1 hilo | "Cuatro copias que arrancan en 10. Si fuera `private`, cuatro copias que arrancan en basura. Lo de adentro del `for` es privado sin cláusula. Y fíjense: el programa es correcto y su salida depende de los hilos." |
| **III.2** (dependencia) | CT3 | `./examen_items/item_III2_scan_buggy` y `_fixed` con 4 hilos | "Un cuarto del resultado: cada hilo arrancó su bloque leyendo un cero. No hay cláusula que ordene iteraciones; se cambia el algoritmo (dos fases) o se deja secuencial si no domina el tiempo." |
| III.1 (carrera) | — (ya cubierta por CT2 si se usó) | `make tsan` (caza1) y `item_III1_dot_buggy` vs `_fixed` | "Un cuarto del producto punto: con `-O2` cada hilo acumula en registro y escribe al final; sobrevive uno. `reduction` es la más barata que es correcta. La tolerancia no es un error: es otro orden de suma." |
| IV (tareas) | — | `item_IV_tasks_sum` con 4 hilos: `total=52952176 tareas=510` | "Hija escribe, padre lee: `shared`. `taskwait` antes de combinar. `parallel` crea el equipo, `single` genera las raíces; sin `single`, cuatro árboles." |
| I.3 / VI (`schedule`) | CT3 | `item_VI_collatz` con 4 hilos (tabla de las cuatro estrategias) | "`dynamic,1024` ganó a `static` en todas las corridas porque el trabajo es irregular; `dynamic,1` perdió siempre. Acumular en privado y combinar una vez no depende del tamaño del trabajo; se mide, no se opina." |
| I.2 / I.1 | — | `ejemplo_revision_falla` + `make tsan` (línea 63) | "Salió bien 6 de 6 y TSan lo reporta: la ventana es de nanosegundos, no una garantía. `atomic` no cubre un `if` con dos variables." |

Regla general que se escribe en el pizarrón al cerrar el bloque: *"Variable compartida que se escribe →
decisión explícita. `private` → basura. `nowait` → solo si nadie lee lo ajeno. La fracción de Amdahl → en
segundos. Más hilos → no es más rápido por sí solo."*

Si sobran 3 minutos: los ConcepTests no usados se votan sin discusión (un voto) y pasan como preguntas de
unidades previas a la recuperación del jueves 5 de noviembre.

### 80–85 · Hoja de calibración

Proyectar la tabla de tres casillas de `examen-practica-U3.md`. Cada estudiante completa la casilla 3 (real,
brecha, equivalente sobre 10, calificación que ahora espera en el Examen 2). Pedir manos: "¿quién tuvo brecha
positiva de más de 9 puntos?" (sobreestimación) y "¿quién negativa de más de 9?" (subestimación). Decir una
sola frase: "La brecha es el dato que mejor predice sorpresas el martes; su plan de estudio empieza por la
sección de la casilla 2." Las hojas se recogen con el *exit ticket*, separadas del examen; al grupo solo se le
muestra el promedio (`04-evaluacion.md`, §2.3).

### 85–90 · Cierre: *exit ticket* y anuncios

*Exit ticket* (`exit-ticket.md`): pregunta 1 de opción múltiple y pregunta 2 con la tabla del plan. Mientras
escriben, anuncios en el proyector, leídos una vez:

1. "**Práctica 4: domingo 1 de noviembre, 23:59**, en el repositorio del equipo (40 % del 2.º parcial)."
2. "**Lunes 2 de noviembre no hay clase** (Día de Muertos)."
3. "**Examen 2: martes 3 de noviembre, 08:30–10:00**, aquí en el 3208 (o en LS4 con los equipos apagados),
   versiones A y B alternadas por fila, 80 minutos efectivos, sin dispositivos, hoja de calibración aparte.
   Misma estructura que el examen de práctica, 100 puntos."
4. "Tarea (`tarea-espaciada.md`): el cazador de errores en pareja (`practica-guiada/`), el intercalado y rehacer
   los dos ítems que fallaron. Entrega en `tareas/S13/` antes del martes 3 a las 08:30; se autocalifica el
   jueves 5."
5. "H1: la rúbrica aplicada llega por escrito el jueves 5 de noviembre; ese día, en los primeros 20 minutos,
   la pregunta individual de H1. Unidad IV empieza el jueves 5 a las 10:30."

## Práctica guiada: errores esperados y la pregunta que se hace (para asesoría y para el jueves 5)

La práctica guiada (`practica-guiada/README.md`) se hace en casa entre el 29 y el 2 de noviembre. Estos son
los errores que aparecerán en asesoría y en los `respuestas.md`; se revisan 3 al azar el jueves 5.

| # | Error esperado | Pregunta socrática |
|---|---|---|
| 1 | Corrigen `caza1` con `private(sum, sumsq)`: compila, `make cazar` falla con media 0 | "¿Dónde queda lo que cada hilo acumuló cuando termina la región? ¿Qué cláusula sí combina?" |
| 2 | Corrigen `caza1` con `critical` y lo declaran "la más barata porque es la más segura" | "¿Cuántas veces entra cada hilo a la región crítica? ¿Y con `reduction`? Mide con `n = 40 000 000`." |
| 3 | En `caza2` ponen `single` sin barrera previa; "funciona" en sus pruebas | "¿Dónde está la barrera de `single`, al inicio o al final? Corre `make cazar` diez veces." (idea 7) |
| 4 | En `caza2` dejan el `nowait` y agregan `#pragma omp barrier` **dentro** del `if` del hilo 0 "para que solo él espere" | "¿Cuántos hilos tienen que llegar a una barrera para que se abra? ¿Cuántos llegan a la que está dentro del `if`?" (idea 32) |
| 5 | En `caza3` ponen `firstprivate` y lo justifican con "así cada hilo tiene su copia y no hay carrera" | "¿Alguien escribe `shift` dentro de la región? Si nadie escribe, ¿qué carrera evita la copia? ¿Cuánto cuesta no poner nada?" |
| 6 | "TSan no reporta nada en `caza3`, entonces está bien" | "¿Qué busca TSan: accesos concurrentes o valores sin inicializar? Corre `make warn`." |
| 7 | "TSan reporta carrera en `caza3` (línea 53 contra el `memset`), entonces hay carrera" | "¿Entre qué hilos? ¿El principal fuera de la región o dos trabajadores? ¿Qué ordena el inicio de una región?" (S07 3.3) |
| 8 | `make cazar` pasa `caza1` con 1 hilo y creen que está corregido | "Lee las líneas FAIL. ¿Con cuántos hilos se necesita que pase? ¿Por qué 1 hilo no demuestra nada?" |
| 9 | El `caza4` no calcula su referencia secuencial ("la pareja ya sabe el resultado") | "¿Cómo va a saber `make cazar` que está corregido? ¿Qué hace `print_result`?" |
| 10 | El `caza4` tiene dos errores o un error de C (índice fuera de rango), no de OpenMP | "¿Qué idea errónea del Anexo A estás plantando? Una por archivo." |

## Diferenciación

- **Apoyo (quien no arranca).** En la corrección entre pares: la pareja corrige los ítems I, II y V primero y
  deja III, IV y VI para casa con la clave. En la práctica guiada: la pista sellada de la fase Crear del README
  (`caza4` a partir de `item_IV_tasks_sum.c` sin `shared`) y, en el ejemplo resuelto, las pistas de los huecos
  antes que las respuestas. En el plan de estudio: el mapa "ítem → dónde repasar" del examen de práctica da el
  archivo exacto; se le pide llenar solo dos filas.
- **Ampliación (quien termina).** El problema sin ejemplo: escribir **dos** `caza4` de temas distintos y
  medir, en `caza1`, `reduction` contra `atomic` contra `critical` con `n = 40 000 000` y el protocolo; o, en
  el ítem VI, implementar la cuarta estrategia que falta (`guided`) y explicar con Karp–Flatt por qué ninguna
  pasa de 2.8 con 4 hilos en la máquina de autoría. En el bloque 50–80, explicar el CT a la pareja de al lado.

## Evaluación formativa de la sesión

| Objetivo | Qué mira el profesor | Umbral de alerta |
|---|---|---|
| 1 (demostrar H1) | Lista de cotejo rápida: casillas P1 y P2 por equipo | > 3 equipos con N en P1 ("¿qué midieron?") → mini-lección de perfilado en U4 S01 antes de la pregunta individual |
| 2 (corregir con criterio) | Hojas firmadas; "?" marcados; errores de corrección vistos en la ronda | > 30 % de hojas con II.1 o V mal corregidos → repetir la guía de corrección el jueves 5 con el examen real |
| 3 (explicar los 3 errores) | Revoto de los CT usados; *exit ticket* 1 | Revoto < 70 % en algún CT → ese CT abre la recuperación del jueves 5 |
| 4 (calibrar y planear) | Hoja de calibración (casilla 3); *exit ticket* 2 | Promedio de brecha > 9 puntos (1.5 sobre 10) → se dice al grupo el martes antes del examen; planes "mal" > 30 % → se devuelven con la pregunta "¿qué archivo y cuántos minutos?" |

Datos que se registran hoy en la hoja de seguimiento: % de aciertos de la recuperación 1, 2, 3 y 5; conteo de
manos por ítem; % de primer voto y revoto de los CT usados; predicción, postdicción y real del examen de
práctica por estudiante (columna propia, separada de la del Examen 2); montones del *exit ticket*
(bien/parcial/mal); lista de cotejo de H1 por equipo.

## Notas post-sesión

Se llenan el mismo jueves 29, después de clasificar los *exit tickets* y las hojas de calibración (15 min):

- Equipos sin etiqueta `H1` a las 10:30: ___ de ___. Equipos con N en "¿qué midieron?": ___.
- ¿Cuántos trajeron el examen de práctica resuelto? ___ de ___ (los que no, lo hicieron en el bloque 8–48).
- Los tres ítems peor contestados (por manos) y si coincidieron con los previstos (V, II.1, III.2): ___.
- ConcepTest con peor primer voto y opción más votada entre los errados: ___.
- Promedio de brecha de calibración (postdicción − real), y cuántos sobreestimaron por más de 9 puntos: ___.
- Error más frecuente del *exit ticket* (abre la recuperación del jueves 5 de noviembre): ___.
- ¿Alcanzó el tiempo de la ronda de H1 (8–28)? Si no, ¿cuántos equipos quedaron para el jueves 5?: ___.
- Cambio concreto para la próxima vez que se dé esta sesión: ___.
