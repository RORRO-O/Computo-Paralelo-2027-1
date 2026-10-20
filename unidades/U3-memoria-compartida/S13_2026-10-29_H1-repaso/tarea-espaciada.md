> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S13 · jueves 29 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S13 · Tarea espaciada (30–40 minutos): cazador de errores, intercalado y preparación del Examen 2

**Entrega.** Carpeta `tareas/S13/` en el repositorio de tu equipo con `respuestas.md`, los tres cazadores
corregidos y tu `caza4_<tema>_buggy.c`, antes del **martes 3 de noviembre de 2026, 08:30** (hora del Examen 2:
esta tarea es tu preparación y no sirve después). La **autocalificas con la clave** en `<details>` al inicio
de la sesión del **jueves 5 de noviembre** (U4 S01, bloque 5–10; el martes es el examen y no hay bloque de
tarea). El profesor registra la entrega, no el acierto; revisa 3 tareas al azar por parcial (5 % del 2.º
parcial, "Tareas espaciadas y ejercicios"). Quien faltó hoy: entregarla antes del martes 3 a las 08:30
sustituye el *exit ticket* y la recuperación de la sesión.

IA: verde para que te explique un reporte de ThreadSanitizer o una idea errónea; amarillo (declarado en
`respuestas.md`) para que revise tu `caza4`; rojo para que corrija los cazadores o escriba el `caza4` por ti.
El martes 3 no hay IA y sí hay un ítem igual a estos.

**Recordatorios.** **Práctica 4: domingo 1 de noviembre, 23:59** (40 % del 2.º parcial). **Lunes 2 de
noviembre: no hay clase.** **Examen 2: martes 3 de noviembre, 08:30–10:00**, versiones A/B, 80 minutos, sin
dispositivos, hoja de calibración aparte. **Unidad IV** (MPI) inicia el **jueves 5 de noviembre, 10:30**.

## 1. Del tema (20 min, en pareja) · Cazador de errores: Modificar y Crear

Es la fase Crear de `practica-guiada/README.md`, que no cabe en la sesión de repaso (en clase no se hace
PRIMM: se recibe H1 y se corrige el examen de práctica).

1. Haz las fases Predecir, Ejecutar e Investigar del README (20 min) si no las hiciste antes.
2. **Modificar.** Corrige `caza1_race_buggy.c`, `caza2_barrier_buggy.c` y `caza3_private_buggy.c` en el lugar
   hasta que `make cazar` termine en `0 FAIL`. Para cada uno, en `respuestas.md`, la **elección justificada**
   entre las tres alternativas de la tabla de la fase 4 (una línea por alternativa: por qué la elegiste o por
   qué la descartaste, citando correctitud **y** costo). Ejemplo del formato, para un caso distinto:
   "`atomic`: correcto, una atómica por elemento, descartado por costo; `critical`: correcto, serializa,
   descartado; `reduction`: correcto, una combinación por hilo, elegido".
3. **Crear.** Escribe `caza4_<tema>_buggy.c` con un error para tu pareja (reglas en el README, fase 5: encabezado
   con `Síntoma esperado:` e `Idea errónea:`, referencia secuencial propia, `RESULT`). Intercámbienlo; cada
   quien corrige el de la otra persona hasta que `make cazar` pase con los cuatro archivos. En `respuestas.md`:
   qué error plantaste, en cuántos minutos lo encontró tu pareja y con qué herramienta (razonamiento, TSan,
   `make warn`, `make cazar`).

Criterio de "listo": `make cazar` en `0 FAIL` con los cuatro archivos; tres elecciones justificadas; un `caza4`
cuyo encabezado coincide con lo que tu pareja encontró.

<details><summary>Clave de 1.2 (coincide con practica-guiada/soluciones/)</summary>

- `caza1` → `reduction(+:sum, sumsq)`. `atomic`: correcto, una operación atómica por elemento (en S07, ×5),
  descartado por costo. `critical`: correcto, serializa el ciclo (más lento que secuencial), descartado.
- `caza2` → quitar `nowait` (la barrera implícita del `for` basta; no agrega sincronización). `barrier` fuera
  del `if`: correcto, equivalente, una barrera explícita de más. `single` sin barrera previa: **incorrecto**
  (la barrera del `single` está al final; el bloque leería `a[]` incompleto).
- `caza3` → ninguna cláusula (`shift` y `scale` solo se leen: compartidas sin carrera, costo cero).
  `firstprivate`: correcto, una copia por hilo, sobra salvo que cada hilo modifique su copia. `private`:
  incorrecto, copia sin inicializar (idea 9); falla también con 1 hilo.
</details>

## 2. Intercalado de las Unidades I y II (8 min, individual)

a) **(Unidad I, Gustafson.)** Para `item_VI_collatz` del examen de práctica se midió `T(1, N) = 0.50 s` con
`N = 2·10⁶`. Supón que con 4 hilos y `4N` se mide `T(4, 4N) = 0.62 s`. Calcula la eficiencia débil y el
*speedup* escalado, y di en una línea por qué este experimento **no** está acotado por `1/(1 − f_p)`.

b) **(Unidad I, Flynn.)** Clasifica en la taxonomía de Flynn (SISD, SIMD, MISD, MIMD): (i) `#pragma omp parallel
for` en 4 núcleos; (ii) `#pragma omp simd` dentro de un núcleo; (iii) la versión secuencial de tu V1.

c) **(Unidad II, Foster, sobre el ítem VI.)** En tres líneas: cuál es la tarea más fina, qué comunicación hay
entre tareas (y en qué se convierte en OpenMP), y qué decisión de aglomeración tomaste con el `schedule`.

<details><summary>Clave de 2</summary>

a) `E_w = T(1,N)/T(4,4N) = 0.50/0.62 ≈ 0.81`; `S_w = 4 × 0.81 ≈ 3.2`. Es escalabilidad **débil** (Gustafson): el
problema crece con los procesadores, así que la parte secuencial se vuelve proporcionalmente más pequeña y
el *speedup* escalado crece casi linealmente con `p`; Amdahl (`1/(1 − f_p)`) acota solo el caso de **mismo
problema** con más hilos (fuerte) (idea 6).
b) (i) **MIMD** (varios hilos, cada uno con su flujo de instrucciones sobre datos distintos; en memoria
compartida). (ii) **SIMD** (una instrucción, varios datos, dentro de un núcleo). (iii) **SISD**.
c) Tarea: calcular la longitud de **un** `k`. Comunicación: cada tarea aporta un `+1` a `hist[len]` y compite
por `maxlen`: en OpenMP se vuelve `reduction(+:hist[:1000])` y `reduction(max:maxlen)` (acumular en privado,
combinar al cerrar). Aglomeración: `schedule(dynamic, c)` agrupa `c` valores consecutivos en una unidad y el
mapeo a hilos es dinámico porque el costo por `k` es irregular (ideas 28 y 11).
</details>

## 3. Preparación (10 min, individual) · El Examen 2 y la Unidad IV

a) **Rehaz sin clave y cronometrado** los dos ítems del examen de práctica en que menos puntos obtuviste (los
anotaste en el *exit ticket*). Compara después con la clave y escribe en `respuestas.md` una línea por ítem:
"la segunda vez obtuve __/__; lo que cambió fue __".

b) El Examen 2 tiene un ítem de **encontrar el error** como los cazadores. Escribe tu lista de verificación
de cinco preguntas (las de `notas-estudiante.md` §2, con tus palabras) en una tarjeta; úsala el martes.

c) **Unidad IV, jueves 5 de noviembre (memoria distribuida, MPI).** Conjetura, sin leer nada ("no sé" es
válido): dos procesos MPI que corren **en la misma máquina** ejecutan el mismo programa, que tiene una variable
global `long total`. ¿Comparten esa variable, como dos hilos de OpenMP? Si no, ¿cómo crees que un proceso le
hace llegar su resultado al otro? Una línea.

<details><summary>Para comparar después de la sesión del jueves 5</summary>

c) **No la comparten**: cada proceso tiene su propio espacio de direcciones, aunque corran en la misma
máquina; `total` existe una vez **en cada proceso** y cambiar una no cambia la otra (idea errónea 16). Todo
intercambio es un **mensaje** explícito (`MPI_Send`/`MPI_Recv`, o una colectiva como `MPI_Reduce`). Es el
cambio de modelo de la Unidad IV: lo que en OpenMP era `reduction` se vuelve una comunicación.
</details>
