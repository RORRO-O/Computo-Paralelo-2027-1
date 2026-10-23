> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S13 · jueves 29 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S13 · Exit ticket (5 minutos, individual): tu plan de estudio para el Examen 2

Escribe tu número de lista. Entrega la hoja al salir, junto con la hoja de calibración del examen de
práctica. Cuenta por participación (3 % del 2.º parcial). Quien faltó hoy lo sustituye entregando la
`tarea-espaciada.md` antes del **martes 3 de noviembre, 08:30**. El profesor revisa hoy la pregunta 1 y abre
la Unidad IV (jueves 5 de noviembre) con el error más frecuente; la pregunta 2 es tuya: te la devuelve el
martes con tu examen.

**1. (Conceptual, elige una)** Un equipo mide con el protocolo `T(1) = 4.0 s` (mejor secuencial) y
`T(4) = 1.9 s`, y escribe en su reporte: "eficiencia 2.1 con 4 hilos; con 8 hilos esperamos 4.2". ¿Qué está mal?

- A) Nada: `4.0 / 1.9 = 2.1` y con el doble de hilos se duplica.
- B) `2.1` es el *speedup*; la eficiencia es `2.1 / 4 = 0.53`, y la predicción para 8 hilos sale de Amdahl con
  la `f_p` del perfil (o de Karp–Flatt), no de duplicar.
- C) Faltó medir con `-O0` para obtener el tiempo real del secuencial.
- D) `T(1)` debe ser la versión paralela con 1 hilo, no el secuencial; por eso les salió tan bajo.

**2. (Aplicación: tu plan, concreto)** Entre hoy y el martes 3 de noviembre a las 08:30 tienes también la
**Práctica 4** (vence el domingo 1 a las 23:59). Llena la tabla con **tema + archivo que vas a usar + minutos**;
una fila por día que vayas a estudiar (mínimo dos filas con contenido).

| Día | Tema (de la lista de `notas-estudiante.md` §1) | Material exacto (archivo y sección, o ítem a rehacer) | Minutos |
|---|---|---|---|
| Hoy, jueves 29 | | | |
| Viernes 30 / sábado 31 | | | |
| Domingo 1 (después de entregar P4) / lunes 2 | | | |

El ítem del examen de práctica con **menos puntos** que vas a rehacer primero, sin clave y cronometrado:
sección ____ ítem ____. Calificación que esperas en el Examen 2 (0–100): ____.

**3. (Confianza)** ¿Qué tan seguro estás de la pregunta 1? 1 = adivinando · 2 = poco · 3 = bastante ·
4 = podría explicárselo a alguien. ¿Qué te quedó **menos** claro después de la corrección de hoy? (una línea,
opcional)

<details><summary>Clave</summary>

1. **B.** `S = T(1)/T(p) = 2.1`; `E = S/p = 0.53` (idea errónea 3). "Con 8 hilos 4.2" es la idea errónea 1
   (más hilos, proporcionalmente más rápido); la cota la da Amdahl con `f_p` medida en tiempo (idea 2) y la
   sobrecarga la estima Karp–Flatt (`f = 0.30` con estos números, ítem V del examen de práctica). C es la idea
   5; D es la idea 31 (el denominador es el mejor secuencial).
2. Sin respuesta única. Clasificación por lo literal: **bien** = al menos dos filas con las tres columnas
   llenas (tema reconocible de la lista, un archivo o ítem concreto, minutos) **y** un ítem nombrado con
   sección y número; **parcial** = filas con tema pero sin material concreto ("repasar OpenMP"), o sin
   minutos, o sin ítem; **mal** = vacío, "todo", o un plan que suma más de 4 horas por día (no se va a cumplir).
   La calificación esperada se copia a la hoja de seguimiento (`docente/seguimiento-grupo.csv`) para compararla
   con la real del martes.
3. Sin clave. Para el profesor: la brecha entre confianza 4 y una respuesta incorrecta en la pregunta 1 se
   registra junto con la de la hoja de calibración.

**Clasificación rápida (profesor, 10 min después de clase).** Bien: pregunta 1 = B **y** pregunta 2 "bien".
Parcial: una de las dos. Mal: pregunta 1 ≠ B **y** pregunta 2 "parcial" o "mal". Si "mal" supera 30 % en la
pregunta 1, el error (eficiencia = *speedup*; "más hilos, más rápido") entra en la retroalimentación del
Examen 2 del jueves 12 de noviembre (U4 S04) y como pregunta de unidades previas en la recuperación del
jueves 5 de noviembre (U4 S01). Los planes "mal" se devuelven el martes 3 con una línea: "¿qué archivo y
cuántos minutos?".

</details>
