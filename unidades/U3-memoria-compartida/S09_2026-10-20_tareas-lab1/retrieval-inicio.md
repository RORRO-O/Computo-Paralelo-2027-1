> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S09 · martes 20 de octubre de 2026 · 08:30–10:00 · Lab LS4

# S09 · Recuperación de inicio (5 minutos, individual, sin apuntes ni dispositivos)

Responde por escrito en una hoja con tu número de lista (se entrega junto con el *exit ticket*). A los 4
minutos se proyectan las respuestas y se cuenta a mano alzada quién acertó cada una. No se califica por
acierto: cuenta por participación (3 % del parcial, junto con los *exit tickets*). Cada respuesta es una
línea, una letra o un número.

**1. (Práctica 4 · pre-laboratorio)** Copia en una línea la predicción que entregaste en tu pre-lab: "con 4
hilos espero un *speedup* de ___ en la Parte A porque ___". Si no lo entregaste en el repositorio antes de las
08:30, escribe `sin pre-lab`.

*Variante B (solo si la Práctica 4 no se publicó a tiempo y no hubo pre-lab; el profesor avisa cuál toca):* antes de
correr nada, con 4 hilos y 10⁷ elementos, ¿qué *speedup* esperas para el histograma con `atomic` de S07 y para
el de acumuladores locales? Un número cada uno y una razón de una línea.

**2. (S08, lunes 19 de octubre)** Un `parallel for` de 16 iteraciones con 4 hilos lleva `schedule(static, 3)`.
¿Qué hilo ejecuta la iteración `i = 14`?

**3. (S08)** Un ciclo de 10 millones de iteraciones, **todas** de unos 50 ns. ¿`schedule(static)` o
`schedule(dynamic)`? Una razón de una línea.

**4. (Unidad II, método de Foster)** Hoy vas a agrupar muchas llamadas recursivas pequeñas en una sola
unidad de trabajo para no pagar el costo de repartir cada una por separado. ¿Cómo se llama la etapa de Foster
en la que se toma esa decisión?

**5. (Conjetura sobre el tema de hoy; "no sé" es válida y no cuenta en contra)** Un hilo, dentro de un
`single`, crea dos tareas (`#pragma omp task`) que calculan `left` y `right`, y en la **línea siguiente**
imprime `left + right`, sin nada en medio. ¿Qué crees que imprima? ¿Por qué?

<details><summary>Respuestas (se proyectan al minuto 4)</summary>

1. Sin clave: la respuesta es tu propia predicción (se compara hoy con `make speedup-a` de la Parte A y otra
   vez en la pregunta 4 de la Parte D, en el Lab 2, martes 27 de octubre). Para el profesor: cuenta cuántos
   escribieron `sin pre-lab`. *Variante B:* también es predicción y se compara hoy, en la parte A′ del
   laboratorio (si la Práctica 4 ya está publicada, con las filas `atomic` y `local` de `make speedup-a`: allí
   cada muestra trae ≈ 20 ns de cálculo y `local` sí escala, que es la pregunta P2). Referencia de autoría: `atomic` ≈ 0.06 (más lento que el
   secuencial: cada incremento pelea por la línea de caché del *bin*) y locales ≈ 4.7.
2. **Hilo 0.** `static,3` forma los bloques {0,1,2}, {3,4,5}, {6,7,8}, {9,10,11}, {12,13,14}, {15} y los
   reparte cíclicamente: bloques 0–3 a los hilos 0–3, el bloque 4 otra vez al hilo 0. `i = 14` está en el
   bloque 4. Quien contestó "hilo 3" pensó en `static` sin *chunk* (bloques contiguos de 4); quien contestó
   "hilo 2" pensó en `static,1` (14 mod 4).
3. **`static`.** Con carga uniforme no hay nada que balancear; `dynamic` sin *chunk* es `dynamic,1`: un pedido
   atómico a un contador compartido por cada iteración, del mismo costo que la iteración misma (en S08 quedó
   más lento que la versión secuencial). Idea errónea 11.
4. **Aglomeración**: agrupar tareas finas en tareas más grandes para reducir la sobrecarga de repartirlas sin
   perder paralelismo útil. Hoy esa decisión tiene nombre en el código: el **corte** (*cutoff*) de la recursión.
5. Lo más probable es que imprima el valor que `left` y `right` tenían **antes** (p. ej. 0): `task` **encola**
   la tarea, no la ejecuta en el acto; el hilo que la creó sigue de largo y lee antes de que las tareas
   terminen o incluso empiecen. Para esperar hay que escribir `#pragma omp taskwait`. Es la idea errónea 13 y
   el primer error que vas a ver hoy en `taskwait_buggy.c`.
</details>

**Para el profesor.** La pregunta 2 repite, con otro índice, la 2b del *exit ticket* de S08 (que preguntaba
`i = 13`). Si en S08 esa pregunta quedó bajo 60 %, proyectarla con la pista "bloques de 3, repartidos como
cartas: 0, 1, 2, 3, 0, 1…" en lugar de sin pista; anotar de nuevo el conteo. Si hoy sigue bajo 60 %, el
ejercicio intercalado de la tarea de hoy la retoma. La pregunta 1 verifica la entrega del pre-lab (regla de
`docs/metodo/04-evaluacion.md` §5: se entrega en el repositorio antes de la hora, falte o no el estudiante);
anotar cuántos no lo entregaron. La pregunta 5 anticipa la idea errónea 13: anotar cuántos contestan "la suma
correcta"; ese número decide cuánto tiempo se dedica a `taskwait_buggy.c` en el minuto 13 (si son más de un
tercio, correrlo tres veces y leer el reporte de ThreadSanitizer completo; si no, una corrida basta).
