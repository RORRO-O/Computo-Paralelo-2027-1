> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S07 · jueves 15 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S07 · Corrección en memoria compartida: condiciones de carrera, `critical`, `atomic`, candados, `barrier`, `nowait`; ThreadSanitizer

Tipo: contenido (estructura base de 90 min). Este plan está escrito para que lo pueda dar otro profesor sin
hablar con el autor: cada bloque dice qué se proyecta, qué se dice y qué se hace si algo falla.

## Objetivos (al terminar, el estudiante podrá…)

1. **Explicar** por qué `x++` o `hist[bin]++` sobre una variable compartida es una condición de carrera,
   rastreando la secuencia leer-modificar-escribir de dos hilos sobre una tabla (nivel: comprender/analizar).
2. **Diagnosticar** una carrera en un programa OpenMP dado, por razonamiento sobre los accesos y con
   ThreadSanitizer, e **interpretar** su reporte distinguiendo una carrera real de un falso positivo de `libgomp`
   (nivel: analizar).
3. **Corregir** una carrera eligiendo entre `reduction`, `atomic`, `critical`, `omp_lock_t` y acumuladores locales,
   y **justificar** la elección con la correctitud de la operación y el costo medido (nivel: aplicar/evaluar).
4. **Predecir** el efecto de `barrier`, `nowait`, `single`, `master`, `private` y `firstprivate` en un fragmento
   de ≤ 15 líneas (nivel: aplicar).

Los objetivos 1 y 2 se evalúan en la pregunta 1 del *exit ticket*; el 3 en la pregunta 2; el 4 en CT3 y en la
tarea espaciada.

## Prerrequisitos y vínculo

- **Viene de:** sesión del martes 13 de octubre (primera mitad de la Unidad III: `reduction` y primera medición
  de *speedup*). Se asume que el grupo ya escribió `parallel for`, usó `shared`/`private`/`firstprivate` y midió
  con `omp_get_wtime()`.
- **Va hacia:** S08, lunes 19 de octubre, 10:30, Salón 3208 (planificación y balance de carga: `schedule`,
  `collapse`); S09, martes 20 de octubre, 08:30, Lab LS4 (Práctica 4 · Lab 1, con pre-lab entregado); Práctica 4
  completa (domingo 1 de noviembre, 23:59); V2 del proyecto (H2, lunes 23 de noviembre).
- **Ideas erróneas que esta sesión ataca** (Anexo A): **7** ("si salió bien una vez no hay carrera"), **8**
  (`critical` ≡ `atomic`), **9** (`private` copia el valor inicial), **10** (`reduction` da exactamente lo mismo),
  **12** (no hay barrera al final de `omp for`), **15** (lo declarado dentro de la región es compartido); y **1**
  ("más hilos siempre es más rápido") en la recuperación. Dónde aparece cada una: 7 → CT1, práctica 3.4-5 y 2,
  *exit ticket* 1; 8 → CT2, tabla de tiempos, *exit ticket* 2; 9 → `private_buggy.c`, CT3, retrieval 2; 10 →
  `sum_variants` (suma `double`), `make test`; 12 → `nowait_buggy.c`, CT2-D, práctica 3.4-4; 15 → Pausa 3 del
  ejemplo, CT3-D, práctica M3.

## Materiales

- Esta carpeta completa, compilada **antes** de la sesión en la máquina del salón: `cd practica-guiada && make
  && make test` (16 PASS, ~6 s) y `make tsan` (~3 s). Tener abiertas dos terminales: una en `practica-guiada/`
  con 4 hilos (`export OMP_NUM_THREADS=4`) y otra para `-O0`.
- Proyector; cronómetro visible; tarjetas con números de lista; pizarrón para la tabla leer-modificar-escribir.
- Estudiantes: laptop con `gcc` + OpenMP por pareja (basta una por pareja). Si alguna pareja no tiene
  compilador, trabaja con la salida proyectada y hace la fase Predecir e Investigar en papel.
- Anuncio preparado: enlace a `practicas/P4-openmp/` (se publica hoy).

## Guion minuto a minuto

### 0–5 · Recuperación

Proyectar las 5 preguntas de `retrieval-inicio.md`. Individual, sin apuntes, 4 minutos. Al minuto 4 mostrar las
respuestas y pedir manos por pregunta ("¿quién la tuvo bien?"); anotar el conteo de la pregunta 1 y 2.

- Si < 60 % acierta la pregunta 1 (`reduction`): en el bloque siguiente, antes del ejemplo, dibujar en el pizarrón
  "4 copias privadas de `s`, cada una en 0 → ciclo → combinación con `+`" (2 min). Todo el tema se apoya en esa imagen.
- Anotar cuántos contestaron "5" en la pregunta 2 (`private`). Si son más de un tercio, CT3 se usa hoy en
  Transferencia; si no, se guarda para abrir S08.

### 5–10 · Objetivos y anclaje

No hay tarea espaciada previa en este formato (S07 es la primera sesión con el método): los 2 minutos de
autocalificación se usan en el anclaje. Proyectar los cuatro objetivos. Frase de anclaje: "El martes 13 el error más frecuente del *exit ticket* fue
[sustituir por el error real registrado en las notas post-sesión del martes 13; si no se tiene, usar: *pensar que
`reduction` es la única forma de acumular en paralelo*]. Hoy vemos qué pasa cuando no se usa nada, por qué, y
las cinco formas de arreglarlo." Vínculo con el proyecto: "En la V2 de su proyecto va a haber al menos una variable
compartida que se escribe dentro de un ciclo paralelo. Lo que hagan con ella hoy es lo que van a tener que
defender el 23 de noviembre en H2."

### 10–35 · Instrucción explícita I (ejemplo resuelto + CT1)

Seguir `ejemplo-resuelto.md`. El profesor **piensa en voz alta**: qué mira, qué descarta, por qué.

| Minuto | Qué se hace | Qué se dice |
|---|---|---|
| 10–13 | Proyectar `counter_buggy.c` (solo los dos ciclos). Correr `./counter_buggy` tres veces en vivo. Después `make counter_buggy_O0 && ./counter_buggy_O0` tres veces. | "Mismo código. Con `-O2` el contador sale bien y la suma mal; con `-O0` casi todo sale mal (si una corrida de `-O0` sale bien, mejor: es la idea 7 en vivo). ¿Qué es lo que cambia y qué es lo que no?" (Pausa 1; elegir al azar quién responde). |
| 13–17 | Tabla leer-modificar-escribir en el pizarrón, con dos hilos y `sum = 100`. Pedir al grupo que dicte los pasos. | "Tres pasos por hilo. Seis pasos en total. ¿En cuántos órdenes queda 112 y en cuántos menos?" Cerrar con: "por eso el total siempre queda por debajo" (Pausa 2). |
| 17–20 | `make tsan`. Proyectar el reporte de `counter_buggy` y leerlo línea por línea: par de líneas 37–38 (`for` y `count++`), un hilo escribe y otro leyó la misma dirección, memoria de la pila de `main`; qué hilo hace qué cambia entre corridas. | "ThreadSanitizer no mira resultados: mira accesos. Por eso lo encuentra aunque la corrida haya salido bien." Advertir una sola vez: "con gcc también se queja de código correcto con `critical`; en la práctica van a ver cómo distinguirlo". |
| 20–26 | Proyectar las cinco correcciones de `sum_variants.c` (una pantalla). Correr `./sum_variants` en vivo (~4 s) y proyectar la tabla. | Recorrer la tabla de arriba abajo: "`critical` y `lock`: lo mismo, un turno por elemento. `atomic`: 3–5 veces más barato, pero la línea de caché rebota. `reduction` y `local`: el mismo patrón, acumular en privado y combinar una vez." Pausas 3 y 4 (dos estudiantes al azar). Señalar la suma `double`: "mismos números, otro orden, otro redondeo: por eso se compara con tolerancia" (idea 10). |
| 26–28 | `./private_buggy` dos veces. | "Fila B cambia, fila C no. `private` no copia; `firstprivate` sí" (Pausa 6). |
| 28–35 | **CT1** (`conceptests.md`): voto → parejas → revoto → explicación. | Guion de discusión de CT1. Si el primer voto > 80 %, saltar la discusión y usar los 3 minutos para preguntar "¿y si fuera `-O3`?" |

Qué **no** hacer: no teclear código nuevo en vivo (solo correr el que ya existe); no explicar `schedule` aunque
pregunten (es S08: "anótenlo, el lunes 19").

### 35–65 · Práctica guiada PRIMM (parejas: conductor/navegante, cambio al minuto 50)

**Arranque (1 min).** "Abran `practica-guiada/README.md`. Fase 1, Predecir, por escrito, 5 minutos, sin compilar.
El navegante escribe, el conductor no toca el teclado hasta que estén las cinco predicciones." Al minuto 40:
"Compilen y corran. Comparen con lo que predijeron." Al minuto 50: cambio de roles; deben ir en Investigar.
Al minuto 57: "Modificar: M1 y M2 son obligatorios; M3 y M4 si alcanzan."

**El profesor circula** con esta lista. Ante cada error, **una pregunta**, no la respuesta:

| # | Error esperado | Pregunta socrática |
|---|---|---|
| 1 | "`buggy` nos dio bien con 16 bins; entonces ahí no hay carrera." | "¿Qué secuencia de pasos de dos hilos daría un total menor? Si no la puedes descartar, ¿qué sabes realmente?" |
| 2 | Ponen `critical` alrededor de todo el cuerpo del ciclo, incluido `bin_of`. | "¿Qué parte de este cuerpo toca memoria compartida y qué parte es privada del hilo?" |
| 3 | En M1 ponen `#pragma omp atomic` antes del `for` de combinación entero; gcc rechaza. | "¿A cuántas instrucciones aplica `atomic`? Lee el mensaje de gcc completo." |
| 4 | En M3, `local` afuera sin cláusula → compartida → total mal; luego `private(local)` → basura o fallo de segmentación. | "¿Qué valor tiene un puntero privado recién creado? ¿Quién le dio memoria a cada hilo?" |
| 5 | "¡TSan dice que `histogram_atomic` tiene carrera!" | "¿Qué línea señala? ¿Qué la protege? ¿ThreadSanitizer sabe lo que hace `libgomp` entre regiones?" |
| 6 | Todos los tiempos iguales con 1, 2 y 4 hilos. | "¿Qué dice la línea `hilos=` que imprime el programa? ¿Dónde pusiste `OMP_NUM_THREADS`?" |
| 7 | En 3.4-5 quitan la `barrier` de `barrier_demo.c`, no falla, y concluyen que sobra. | "¿Por qué no falló? ¿Qué tendría que pasar para que fallara? ¿Lo puedes descartar?" (idea 7 otra vez) |
| 8 | En `nowait_buggy` creen que la carrera está en `b[]`. | "¿Dos hilos escriben el mismo `b[i]`? Entonces, ¿qué dato es el que un hilo lee antes de tiempo?" |
| 9 | Reportan `local` más lento que la secuencial y lo toman por error propio. | "¿Cuánto trabajo hace cada hilo por elemento? ¿Cuánto cuesta despertar 4 hilos? ¿Qué pasaría con `n` diez veces mayor?" (anticipa S10) |
| 10 | Comparan la mediana de `critical` con un solo tiempo de `atomic`. | "¿Cuántas repeticiones tiene cada número que estás comparando? ¿Qué dice el protocolo?" |

Si una pareja termina M1–M4 antes del minuto 65, pasa a Crear (Fase 5).

### 65–75 · Puesta en común + CT2

Proyectar la tabla de tiempos de **dos parejas** (una con 2 hilos, otra con 4) junto a la de autoría. Mostrar
sin nombres dos o tres hallazgos de la ronda (los más probables: #1, #4 y #5 de la lista anterior) y pedir a la
pareja correspondiente que diga qué pregunta la destrabó.

**CT2** (`conceptests.md`): voto → parejas → revoto → explicación con la tabla de tiempos a la vista.

**Regla general en una frase** (escribirla en el pizarrón y dejarla): *"Toda variable compartida que se escribe
dentro de una región paralela necesita una decisión explícita: `reduction`, `atomic`, `critical`/candado, o
privada + combinar. Se elige la más barata que sea correcta para esa operación."*

Dos frases más antes de pasar: "`nowait` se quita solo si nadie lee después lo que otro escribió en el ciclo" y
"`private` no inicializa; `firstprivate` copia; lo declarado adentro es privado".

### 75–85 · Transferencia (Fase 5 · Crear)

**Reto:** `histogram_locks.c` con un candado por bin. **Criterio de listo:** `make test` en PASS (el script detecta
el archivo solo) + tabla de 4 hilos contra `atomic` y `local` + tres líneas de interpretación.

- **Quien no arranca:** "Copia `histogram_atomic.c` a `histogram_locks.c`. Reserva un arreglo de `omp_lock_t` de
  tamaño `nbins` antes de la región. ¿Cuántas veces debe ejecutarse `omp_init_lock`? ¿Dónde va entonces el
  ciclo que lo llama?" Dejarles la pregunta y volver en 3 minutos.
- **Quien termina:** versión con `reduction(+:hist[:nbins])` (OpenMP 4.5). "¿Qué está haciendo OpenMP por ti?
  Compara su tiempo con `local`." Si también termina: **CT3** en su mesa, y que lo expliquen a la pareja de al lado.
- Si la práctica se alargó, este bloque se recorta (nunca Recuperación ni Cierre). Entonces el reto pasa
  **íntegro** a la tarea espaciada como ejercicio del tema (sustituye al ejercicio 1; `tarea-espaciada.md` ya
  trae la nota) y se anuncia así en el cierre.

### 85–90 · Cierre

1. **Exit ticket** (`exit-ticket.md`): 2 preguntas + confianza, individual, en hoja con número de lista. Se recoge
   al salir.
2. **Tarea espaciada** (`tarea-espaciada.md`): 20–40 min; se entrega en `tareas/S07/` del repositorio del equipo
   antes del lunes 19 de octubre, 10:30.
3. **Anuncio: se publica la Práctica 4** (`practicas/P4-openmp/`). Decir exactamente: "La Práctica 4 queda
   publicada hoy. El **pre-laboratorio es individual y se entrega al inicio de la sesión del martes 20 de octubre,
   08:30, Lab LS4**. La práctica completa se entrega el **domingo 1 de noviembre a las 23:59** y vale **40 % del
   2.º parcial**. La rúbrica está en la carpeta desde hoy."
4. "Siguiente sesión: lunes 19 de octubre, 10:30, Salón 3208: planificación y balance de carga. La pregunta 3 de la
   tarea es la entrada a ese tema."

## Diferenciación

- **Apoyo (quien no arranca en PRIMM):** entregarle impresa la tabla leer-modificar-escribir de la Fase 3.1 con
  los seis pasos y pedirle que la llene para `hist[5]` antes de volver a la computadora; después, hacer solo
  Ejecutar + Investigar 3.2 y M2 (no requiere escribir código). En Crear, la pista sellada (`<details>`) de la
  Fase 5 del README.
- **Ampliación (quien termina):** reducción de arreglo (`reduction(+:hist[:nbins])`), medición con `nbins = 4096` y
  explicación de por qué `atomic` se degrada menos con muchos bins; CT3 explicado a otra pareja.

## Evaluación formativa de la sesión

| Objetivo | Qué mira el profesor | Umbral de alerta |
|---|---|---|
| 1 (explicar la carrera) | Tabla leer-modificar-escribir llena en Investigar 3.1; CT1 revoto | Revoto CT1 < 70 % |
| 2 (diagnosticar e interpretar TSan) | Respuesta a la pregunta socrática #5; *exit ticket* 1 | > 30 % en "mal" en la pregunta 1 |
| 3 (corregir y justificar) | M1 con `make test` en PASS y línea de justificación; CT2; *exit ticket* 2 | Revoto CT2 < 70 % o > 30 % proponen `atomic` para el `max` |
| 4 (predecir barreras y alcance) | Predicciones P3–P5 comparadas con la salida; M3/M4; CT3 si se aplica | Más de un tercio responde "5" en retrieval 2 y falla CT3 |

Datos que se registran hoy en `herramientas/seguimiento-grupo.csv`: % aciertos retrieval 1 y 2, % CT1 y CT2
(primer voto y revoto), montones del *exit ticket* (bien/parcial/mal).

## Notas post-sesión

Se llenan el mismo jueves 15 de octubre, después de clasificar los *exit tickets* (10 min):

- Qué falló en el tiempo (¿se recortó Transferencia? ¿cuánto?):
- ConcepTest que falló y por qué (opción más votada entre los errados):
- Error más frecuente del *exit ticket* (abre la recuperación del lunes 19 de octubre):
- Cambio concreto para la próxima vez que se dé esta sesión:
