> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S10 · jueves 22 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S10 · Recuperación de inicio (5 minutos, individual, sin apuntes ni dispositivos)

Escribe las respuestas en una hoja o en tu cuaderno. A los 4 minutos se muestran las respuestas; cuenta tus
aciertos. No se califica por acierto: cuenta por participación (3 % del parcial, junto con los *exit tickets*).

**1. (S09, martes 20 de octubre)** Dentro de una tarea que creó otras tareas, `#pragma omp taskwait` espera…
¿a **todas** las tareas descendientes o solo a las **hijas directas** de la tarea actual? Una palabra basta.

**2. (S09)** En `fib_tasks.c` del Lab 1, por debajo del corte (`cutoff`) la función no crea tareas y calcula en
secuencial. ¿Qué costo evita el corte? ¿Qué pasaría con el tiempo si el corte fuera 2? (una línea)

**3. (Unidad I)** El mejor programa secuencial tarda `T(1) = 12 s`; la versión paralela con 4 hilos tarda
`T(4) = 4 s`. ¿Cuánto valen el *speedup* y la **eficiencia** con 4 hilos? (dos números)

**4. (Unidad II, perfilado)** Para aplicar Amdahl a tu V1 necesitas su fracción secuencial. ¿Se obtiene
**contando líneas** de código o **midiendo tiempo**? ¿Con qué herramienta lo hiciste en la Unidad II? (una línea)

**5. (Tema de hoy; conjetura, "no sé" es válida)** Dos hilos incrementan millones de veces, cada uno, su
propia casilla de `long c[2]`: el hilo 0 hace `c[0]++` y el hilo 1 hace `c[1]++`. No hay condición de carrera.
¿Crees que con 2 hilos tarde la **mitad** que con 1, **lo mismo**, o **más**? Una línea con tu razón.

<details><summary>Respuestas</summary>

1. Solo a las **hijas directas** (las tareas creadas por la tarea actual), no a las nietas. Para esperar a todas
   las descendientes se usa `taskgroup` o un `taskwait` en cada nivel (idea errónea 13 del Anexo A).
2. Evita el costo de **crear y encolar una tarea** (decenas de microsegundos cada una, entre memoria y
   sincronización) para subproblemas que se resuelven en nanosegundos. Con `cutoff = 2` se crearían millones de
   tareas diminutas y el programa sería **más lento** que el secuencial: la sobrecarga supera al trabajo. Hoy
   se mide ese mismo fenómeno con regiones paralelas.
3. `S(4) = T(1)/T(4) = 12/4 = 3`. `E(4) = S(4)/p = 3/4 = 0.75` (75 %). Eficiencia y *speedup* no son lo mismo
   (idea errónea 3).
4. **Midiendo tiempo** en la versión secuencial: la fracción de Amdahl es una fracción de **tiempo**, no de líneas
   (idea errónea 2). En la Unidad II se usó un perfilador (`gprof`) o cronómetros por sección
   (`omp_get_wtime()` / `clock_gettime`) alrededor de cada etapa de la V1.
5. Conjetura; no cuenta. Lo que pasa en realidad: suele tardar **más** que con un hilo, aunque no hay carrera.
   `c[0]` y `c[1]` viven en la misma línea de caché (64 bytes) y cada escritura de un hilo invalida la copia
   del otro núcleo: falso compartido (*false sharing*). Es el experimento central de la práctica guiada de hoy.
</details>

**Para el profesor.** Las preguntas 1 y 2 son de S09: anotar el porcentaje de acierto de cada una. Si la 1
queda bajo 60 %, en el bloque 5–10 se dibuja el árbol de tareas (padre → hijas → nietas) y se marca hasta
dónde espera `taskwait` (2 min; se descuentan de Transferencia). Si la 3 queda bajo 60 % (confundir eficiencia
con *speedup*), el ejemplo resuelto se detiene en el hueco 1 hasta que todo el grupo tenga `E = S/p` escrito.
La 5 no se corrige todavía: se retoma en la fase Predecir de PRIMM y se cierra con el ConcepTest 2.
