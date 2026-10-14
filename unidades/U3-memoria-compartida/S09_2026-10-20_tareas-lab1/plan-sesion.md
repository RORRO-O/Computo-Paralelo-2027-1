> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S09 · martes 20 de octubre de 2026 · 08:30–10:00 · Lab LS4

# S09 · Paralelismo de tareas (`task`, `taskwait`, `taskloop`, corte) + Práctica 4 · Laboratorio 1 (Partes A y B)

Tipo: **laboratorio**, variante 2.1 de `docs/metodo/02-plantilla-sesion.md` adaptada porque hoy entra un
constructo nuevo (tareas) en el Lab 1: recuperación 5 min · mini-lección de 25 min con ejemplo resuelto y
ConcepTest 1 · 50 min de Práctica 4 · Lab 1 (los primeros 20 son el PRIMM corto de `practica-guiada/`, que es
el código completo del constructo que la Parte B pide; los otros 30, Partes A y B con mini-defensas) · punto
de control 5 min · *exit ticket* 5 min. Este guion debe bastar para que otro profesor dé la sesión.

## Objetivos (al terminar, el estudiante podrá…)

1. **Explicar** qué ocurre al ejecutar `#pragma omp task` (la tarea se encola y la ejecuta cualquier hilo del
   equipo cuando puede) y qué garantizan `taskwait` (hijas directas) y la barrera implícita del `single`,
   rastreando un fragmento de ≤ 15 líneas (nivel: comprender/analizar). Se evalúa en *exit ticket* 1, CT1 y
   recuperación 5.
2. **Determinar** el entorno de datos de una tarea (`firstprivate` implícito para lo que no es compartido
   donde se crea; `shared` explícito para lo que la hija escribe y el padre lee) y **corregir** el "resultado 0"
   de `fib_buggy.c` (nivel: aplicar). Se evalúa en *exit ticket* 2b, CT1 y la fase Investigar 3.3.
3. **Predecir** cuántas tareas genera una recursión con corte (*cutoff*) y **elegir** el corte con una medición
   (nivel: aplicar/evaluar). Se evalúa en *exit ticket* 2a, CT2, Predecir P1 y Modificar M1.
4. **Completar** en equipo las Partes A y B de la Práctica 4 y **defender** en un minuto una línea de código
   propia y una medición (nivel: aplicar/evaluar). Se evalúa en las mini-defensas y el punto de control.

## Prerrequisitos y vínculo

- **Viene de:** S08, lunes 19 de octubre (`schedule`, costo por *chunk*, `collapse`); S07, jueves 15 de octubre
  (carreras, `atomic`/`critical`, barreras, ThreadSanitizer); sesiones del 1 al 13 de octubre (`parallel for`,
  alcance, `reduction`). La tarea de S08 ya pidió leer *tasking* y predecir el programa de las 8 tareas en un
  `single`: se retoma en el minuto 7.
- **Va hacia:** S10, jueves 22 de octubre, 10:30, Salón 3208 (protocolo de medición, Amdahl medido,
  Karp–Flatt, falso compartido: la tarea de hoy prepara los dos últimos); S12, martes 27 de octubre, 08:30,
  Lab LS4 (Lab 2 de P4: Partes C y D, mini-defensas de la otra mitad de los equipos); **Práctica 4: domingo 1
  de noviembre, 23:59** (40 % del 2º parcial); **H1, jueves 29 de octubre** (12 %); V2 del proyecto (H2,
  lunes 23 de noviembre), donde el paralelismo de tareas es la opción para recursión o listas.
- **Ideas erróneas que esta sesión ataca** (Anexo A): **13** ("las tareas se ejecutan al crearse; `taskwait`
  espera a todas") → recuperación 5, `taskwait_buggy.c` (minuto 13), CT1-A, CT3, *exit ticket* 1; **1** ("más
  hilos/tareas siempre es más rápido") → tabla de cortes de `fib_tasks` (minuto 17), barrido M1, CT2-D, tarea
  2; **15** ("lo declarado dentro de la región es compartido") → `p` en `list_tasks.c` (Pausa 2), `fib_buggy.c`,
  CT1-C, *exit ticket* 2b. De paso: 7 ("salió bien 5 veces", *exit ticket* 1), 31 (T(1) es el mejor secuencial:
  el lineal de Fibonacci) y 11 (`dynamic` siempre gana, recuperación 3).
- **Nivel de andamiaje:** **completo** para el constructo nuevo (ejemplo resuelto íntegro con 5 pausas;
  `mergesort_tasks.c` completo para leer, predecir y modificar), como pide `02` §2.1 para un constructo que
  debuta en Lab 1. El desvanecimiento está en la fase Crear (`tree_sum_tasks.c` con `TODO(1)`–`TODO(3)`), que
  pasa íntegra a la tarea espaciada, y en la Parte B de la Práctica 4 (semi-guiada).

## Materiales

- Esta carpeta, compilada **antes** de la sesión en la máquina del profesor del LS4: `cd practica-guiada &&
  make clean && make && make test` (34 PASS, ≈ 3 s) y `make tsan` (≈ 2 s). Terminal con
  `export OMP_NUM_THREADS=4`.
- `practicas/P4-openmp/README.md` y `rubrica.md` abiertos (si al dar la sesión la carpeta de P4 aún no
  existe, el flujo de la sección 50–80 describe lo mínimo: Parte A histograma guiado, Parte B mergesort con
  tareas semi-guiado). Lista impresa de qué mitad de los equipos se defiende hoy (equipos con número impar;
  los pares el martes 27), si hay más de 12 equipos.
- Proyector; cronómetro visible; tarjetas con números de lista; pizarrón para el árbol de llamadas de n = 8.
- Estudiantes: una máquina del LS4 por pareja (misma pareja que en S08, nivel adyacente en el diagnóstico de
  agosto) y el repositorio del equipo clonado con el pre-lab en `practicas/P4/prelab/`.
- Plan B (`02` §2.7): si el LS4 no tiene `gcc -fopenmp`, el PRIMM se hace en una laptop por pareja; sin
  máquinas, Predecir e Investigar en papel con la traza proyectada y Modificar pasa a la tarea.

## Guion minuto a minuto

### 0–5 · Recuperación

Proyectar las 5 preguntas de `retrieval-inicio.md`. Individual, sin apuntes, 4 min; al minuto 4 las respuestas
y manos por pregunta. Anotar tres conteos: `sin pre-lab` (pregunta 1), aciertos de la 2 (`static,3`; si en S08
la 2b quedó bajo 60 %, proyectarla con la pista "bloques de 3 repartidos como cartas") y cuántos contestan "la
suma correcta" en la 5. Más de un tercio en la 5 → en el minuto 13 `taskwait_buggy` se corre tres veces y se
lee el reporte de TSan completo; si no, una corrida.

### 5–30 · Mini-lección: ejemplo resuelto + ConcepTest 1

El profesor **piensa en voz alta** con `ejemplo-resuelto.md` proyectado y el código en la terminal. No se
teclea código nuevo; solo se corre el que existe.

| Minuto | Qué se hace | Qué se dice |
|---|---|---|
| 5–7 | Objetivos en una pantalla. Anclaje con S08: "el error más frecuente del *exit ticket* de ayer fue ____ [si no se revisó: 'poner `dynamic` sin pensar en el costo por *chunk*']. Hoy el reparto dinámico vuelve, pero sin ciclo: cuando no hay índices que repartir." Autocalificación de la tarea de S08 con su clave (2 min): las preguntas 3a–3c de esa tarea son exactamente el patrón de hoy. | "¿Cuántos hilos crearon las 8 tareas? ¿Puede salir `fin del single` antes que una tarea?" |
| 7–10 | **Paso 1** del ejemplo: `list_tasks.c` proyectado (solo la región). Correr `./list_tasks 8` dos veces. | "Un `parallel for` no puede repartir una lista: no hay `i`. Un hilo recorre y encola; los demás toman." **Pausa 1** (tarjeta): "¿por qué `fin del recorrido` sale antes que los nodos?" **Pausa 2**: "`p` está declarada adentro: ¿la tarea ve el puntero que sigue avanzando o una copia?" (idea 15 al revés: lo de adentro es privado, y la tarea recibe copia `firstprivate`). |
| 10–13 | **Paso 2**: `fib_tasks.c`, solo la función `fib_tasks`. Correr `./fib_buggy`. | "Mismo código sin `shared(x)`: 0, siempre, sin carrera y sin *warning*." **Pausa 3**: "¿dónde escribió la hija y qué leyó el padre?" Regla en el pizarrón: *lo que la hija escribe y el padre lee, `shared`*. |
| 13–16 | **Paso 3**: `./taskwait_buggy` (una o tres veces según la recuperación). Proyectar el reporte de `make tsan` recortado: la escritura de `left` (línea 21 inlineada en la tarea) contra la lectura prematura (línea 46). | "`task` encola; el hilo sigue de largo y lee 0. La barrera del `single` sí espera a todas; por eso la segunda lectura sale bien." **Pausa 4**: "¿qué línea falta y dónde?" Señalar, una vez, los reportes de TSan que son ruido de `libgomp` (líneas 41–44 contra `GOMP_task`): mismo criterio que en S07. |
| 16–20 | **Paso 4 y 5**: tabla de cortes de `fib_tasks` (del ejemplo; no se corre en vivo salvo `./fib_tasks`, 1 s). Fórmula 2·(fib(n−c+3)−1). La línea `lineal: 0.000000017 s`. | "48 millones de tareas tardaron 26 s en calcular lo que el recursivo hace en 0.03 s y el lineal en 17 ns." **Pausa 5**: "¿contra qué T(1) se reporta el *speedup*?" (protocolo §3; idea 31). "Fibonacci enseña la mecánica; para rendimiento la práctica usa mergesort." Mostrar la tabla de `list_tasks 100000` (1, 2, 4 hilos). |
| 20–22 | Panorama: `./taskloop_demo 16 4` dos veces (mapa cambia; "`schedule(dynamic)` del mundo de las tareas"). `depend` en dos frases: "se puede declarar que una tarea lee lo que otra escribe (`depend(in:x)`, `depend(out:x)`) y OpenMP las ordena sin `taskwait`; no se usa en P4". | No profundizar aunque pregunten: "anótenlo para la V2". |
| 22–28 | **CT1** (`conceptests.md`): la suma sobre `total` declarada adentro. Voto → parejas → revoto → explicación. Esperado 35–45 % en el primer voto. Si < 30 %, volver a la Pausa 2 antes de discutir. | Guion de CT1. Cerrar con la corrección (`shared(total)` + `atomic`, o escribir en `p->result`). |
| 28–30 | Instrucciones del PRIMM: "`practica-guiada/README.md`, fase 1 **sin tocar el teclado**, 4 minutos; el navegante escribe las cinco predicciones". Anunciar los hitos: 08:38 Ejecutar, 08:41 Investigar, 08:47 Modificar, 08:55 puesta en común. | "Hoy no hay fase Crear en clase: es el ejercicio 1 de la tarea." |

Si la sesión arranca con ≥ 5 min de retraso (es martes 08:30): recuperación de 3 preguntas (1, 2 y 5), se
salta la tabla de `list_tasks 100000` y el panorama de `taskloop` pasa al README (M4).

### 30–50 · PRIMM corto: `mergesort_tasks.c` (parejas conductor/navegante, cambio de rol al minuto 41)

Es el código completo del constructo que la Parte B de P4 pide; por eso va antes de la Parte B
(`02` §2.1: "nunca como `TODO` en la Parte B de esa misma sesión").

- **30–34 Predecir** (P1–P5 del README, por escrito). **34–37 Ejecutar**: `make`, `./mergesort_tasks 8 2` dos
  veces, `./mergesort_tasks`. **37–43 Investigar** (3.1 contador atómico, 3.2 árbol de llamadas, 3.3 cláusulas,
  3.4 `taskwait`). **43–50 Modificar**: M1 obligatorio (`make cutoffs`, 20–30 s con `REPS=3`), M2 si alcanza
  (1, 2, 4 hilos con el mejor corte), M3 opcional (quitar el `taskwait` y ver fallar `make test`).

**El profesor circula** con esta lista. Ante cada error, **una pregunta**, no la respuesta:

| # | Error esperado | Pregunta socrática |
|---|---|---|
| 1 | P1: predicen 7 u 8 tareas (cuentan la raíz `[0,8)` o las hojas de 1 elemento) | "¿Quién ejecuta `[0,8)`: una tarea o el hilo del `single`? ¿Qué hace una llamada con n ≤ cutoff?" |
| 2 | P2: "la primera tarea la ejecuta siempre el hilo 0 / el del `single`" | "¿Quién decide qué hilo toma una tarea encolada y cuándo lo decide? Corre la traza otra vez." |
| 3 | P3: "con 1 hilo no se crean tareas" | "¿Qué línea decide crear una tarea: una condición sobre `n` o sobre los hilos?" |
| 4 | Leen `ejecutadas por hilo: 5 0 0 1` como error o desbalance | "¿Cuánto dura una tarea de 2 elementos? ¿Alcanzan los otros hilos a despertar antes de que se acaben?" |
| 5 | M1: con `cutoff = 1` se impacientan y matan el proceso | "¿Cuántas tareas son (2n − 2)? ¿Cuánto cuesta cada una? Haz la cuenta antes de volver a correrlo; usa `REPS=1`." |
| 6 | M1: concluyen "corte más grande siempre mejor" tras ver 1 < 16 < 256 | "¿Qué pasa con `cutoff = n`? ¿Cuántas tareas hay y quién hace el trabajo?" (idea 1 al revés) |
| 7 | M3: quitan el `taskwait` y una corrida sale `OK` | "¿Qué comparó el test, un resultado o los accesos? ¿Qué mezcla `merge` si una hija no terminó? Corre con n = 10⁶." (idea 7) |
| 8 | Agregan `shared(a, tmp)` "por seguridad" o `private(lo, hi)` | "¿Qué es `a`: el arreglo o un puntero? ¿Qué copia `firstprivate`: el puntero o lo apuntado? ¿Qué valor tendría `lo` privado?" |
| 9 | Proponen `parallel for` dentro de la recursión | "¿Cuántos equipos de hilos crearías en cada nivel? Las tareas existen exactamente para esto." |
| 10 | Miden con la máquina ocupada (la otra pareja corre `cutoff = 1`) | "¿Qué dice `uptime`? ¿Qué dice el protocolo sobre medir con otros procesos?" (idea 5) |
| 11 | "`taskloop` dentro de `single`, entonces el `single` lo ejecutan varios hilos" | "¿Cuántos hilos ejecutan el bloque `single`? ¿Quién **crea** las tareas de `taskloop` y quién las **ejecuta**?" |
| 12 | Explican la sobrecarga de `cutoff = 1` como "carreras entre tareas" | "¿Qué tramo escribe cada tarea? ¿Se traslapan `[lo,mid)` y `[mid,hi)`?" (CT2-B) |

**Al minuto 41** (cambio de rol): preguntar a dos parejas al azar su P1 y su P3. La mayoría acierta P1 (6) y
falla P3 ("con 1 hilo también 6"): guardar para la puesta en común.

### 47–50 · Puesta en común + ConcepTest 2 (dentro del bloque PRIMM)

Proyectar el barrido de cortes de **una pareja** junto al de autoría (README, fase 4). Dos hallazgos, un minuto
cada uno: (1) el número de tareas no depende de los hilos (P3); (2) `cutoff = 1` ≈ 4 millones de tareas y
17–19 veces más lento que la secuencial (3.7 s contra 0.2 s en autoría); `cutoff = n` = sin paralelismo. **CT2**: ¿por qué `cutoff = 1` tarda
tanto? Voto; discusión y revoto **solo si** el primer voto queda entre 30 % y 80 %; fuera de ese rango, a la
explicación. **Regla general** en el pizarrón: *"el corte se elige para que una tarea valga mucho más que
crearla, y para que aun así haya varias veces más tareas que hilos; se mide"*.

### 50–80 · Práctica 4 · Laboratorio 1: Partes A y B (equipos de P1–P3; el profesor circula con la rúbrica)

Arranque (1 min): "Parte A primero: es código completo, se lee, se predice, se corre y se pasa `make test`.
Parte B después: completar los `TODO`. Orden de trabajo: `make test` antes de cada `commit`; un *commit* por
`TODO` resuelto, con el nombre de quien lo hizo."

Flujo mínimo de P4 en esta sesión (`practicas/P4-openmp/README.md`):

- **Parte A · histograma guiado** (≈ 15 min): el histograma de S07 con las tres correcciones (`atomic`,
  `critical`, acumulador local) y `reduction(+:hist[:nbins])`; se lee, se predice el orden de tiempos, se
  corre con 1, 2 y 4 hilos y se pasa `make test`. Es la medición que se compara con la predicción del pre-lab.
- **Parte B · mergesort con tareas semi-guiado** (≈ 15 min en clase; se termina en casa): el esqueleto es el de
  `mergesort_tasks.c` que acaban de leer. Las líneas `parallel` + `single`, `task` y `taskwait` vienen
  **completas**; los `TODO(n)` piden la mezcla, el corte parametrizable y el arnés de medición con el protocolo.
  Si el enunciado publicado pusiera los pragmas de tareas como `TODO`, el profesor los escribe en el pizarrón
  (son las líneas 91, 96 y 101 de `mergesort_tasks.c`, más el `parallel` + `single` de las líneas 193–194): el
  constructo nuevo no se pide a ciegas el día que debuta.

**Mini-defensas** (una por equipo, 2 min; con más de 12 equipos solo la mitad hoy, lista publicada): una
pregunta por integrante sobre el código de ese momento ("¿qué hace esta línea?"); la segunda ("¿qué pasaría si
la quito?") solo si la primera falla; cuenta la mejor de las dos. Quien lo pide responde por escrito en el
momento (5 min, papel). Líneas que conviene señalar: el `taskwait` antes de `merge`, la condición del corte,
`shared(...)` donde exista, la línea del `atomic` del histograma.

Errores de P4 esperados hoy, con la pregunta: histograma de la Parte A "más lento con 4 hilos que con 1" →
"¿cuánto trabajo hay por elemento? ¿qué dijo tu pre-lab?"; `critical` alrededor de todo el cuerpo → "¿qué parte
toca memoria compartida?"; en la Parte B, `make test` falla con n grande y pasa con n pequeño → "¿tu corte
funciona cuando n no es potencia de 2? ¿qué pasa con `hi − lo == 1`?"; resultado 0 o basura → tabla 8
(`shared`).

### 80–85 · Punto de control

Cinco equipos al azar (tarjetas) muestran **una** medición y la explican en un minuto: la línea `resumen:` del
mergesort con 4 hilos y el corte que eligieron, o la tabla de la Parte A con 1, 2 y 4 hilos. Los demás anotan
su línea `resumen:` en el *exit ticket* (hay un renglón para eso). Pregunta fija a cada equipo que presenta:
"¿contra qué secuencial es ese *speedup*?" Si sobra tiempo, **CT3** (`taskwait` y las nietas) por voto rápido
sin discusión; si no, abre la recuperación de S10.

### 85–90 · Cierre

1. **Exit ticket** (`exit-ticket.md`): 2 preguntas + confianza, individual, hoja con número de lista; se
   recoge junto con la hoja de recuperación.
2. **Tarea espaciada** (`tarea-espaciada.md`): la fase Crear (`tree_sum_tasks.c`), Amdahl/Foster sobre el
   mergesort y la preparación de S10. Entrega en `tareas/S09/` antes del **jueves 22 de octubre, 10:30**.
3. Anuncios con fecha: "Partes A y B de la Práctica 4 terminadas y en el repositorio antes del martes 27 de
   octubre, 08:30 (Lab 2: Partes C y D, mini-defensas de los equipos pares). La Práctica 4 completa se entrega
   el **domingo 1 de noviembre a las 23:59** (40 % del 2º parcial). H1 del proyecto: jueves 29 de octubre en
   clase. Siguiente sesión: jueves 22 de octubre, 10:30, Salón 3208, rendimiento: traigan su línea `resumen:`."

## Diferenciación

- **Apoyo (quien no arranca en PRIMM):** entregarle impreso el árbol de llamadas de n = 8, corte 2 (fase 3.2
  del README) con los dos primeros niveles ya llenos, para que complete el tercero y cuente; después, solo
  Ejecutar + Investigar 3.2–3.3 y M1 con los cortes 16, 4096 y n (no requiere escribir código). En la tarea,
  pista sellada: el `TODO(1)` con las dos líneas `#pragma omp task shared(...)` ya escritas y solo la recursión
  por completar (está en la clave de la tarea, en `<details>`).
- **Ampliación (quien termina M1–M3 antes del minuto 47):** M4 (`taskloop_demo 40000 64` y 16: explicar por
  qué `taskloop` pierde contra `for dynamic` aquí) y, sin ejemplo, *quicksort* con tareas: partición
  secuencial, dos tareas, sin arreglo auxiliar, corte en 4 096; criterio de listo: igual a `qsort` en 1, 2 y 4
  hilos y una línea sobre por qué su balance es peor que el de mergesort. En la Práctica 4, la extensión
  opcional del README.

## Evaluación formativa de la sesión

| Objetivo | Qué mira el profesor | Umbral de alerta |
|---|---|---|
| 1 (encolar, `taskwait`, barrera) | Recuperación 5; revoto CT1; *exit ticket* 1 | > 30 % eligen A o D en el *exit ticket* 1 |
| 2 (entorno de datos) | Pausa 2 y 3 en voz alta; Investigar 3.3; *exit ticket* 2b | > 30 % sin `shared(x)` en 2b |
| 3 (corte y número de tareas) | P1/P3 comparadas con la traza; tabla M1 con dos líneas; CT2; *exit ticket* 2a | Revoto CT2 < 70 % o > 30 % contestan "cambia con 2 hilos" |
| 4 (Partes A y B, propiedad) | Mini-defensas (mejor de dos preguntas); punto de control; `make test` de la Parte A en el repositorio | Más de 3 equipos sin Parte A en PASS al minuto 80 |

Datos que se registran hoy en `herramientas/seguimiento-grupo.csv`: % aciertos recuperación 2 y 5, `sin
pre-lab`, % CT1 y CT2 (primer voto y revoto), montones del *exit ticket*, equipos con mini-defensa hecha.

## Notas post-sesión

Se llenan el mismo martes 20 de octubre, después de clasificar los *exit tickets* (10 min):

- Qué falló en el tiempo (¿el PRIMM se comió minutos de P4? ¿cuántos equipos llegaron a la Parte B?):
- ConcepTest que falló y por qué (opción más votada entre los errados):
- Error más frecuente del *exit ticket* (abre la recuperación del jueves 22 de octubre):
- Equipos pendientes de mini-defensa (pasan al martes 27 de octubre):
- Cambio concreto para la próxima vez que se dé esta sesión:
