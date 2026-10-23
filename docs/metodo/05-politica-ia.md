# Política de uso de IA generativa

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · versión 1.0 · 14 de octubre de 2026

## Para ti, estudiante

La IA generativa (ChatGPT, Claude, Gemini, Copilot y similares) es parte de tu caja de herramientas y lo será en
tu trabajo. En este curso la usas como **tutor**, no como **sustituto**. La razón es práctica, no moral: un
ensayo controlado con cerca de mil estudiantes de preparatoria (Bastani et al., 2025) mostró que quienes usaron
un asistente sin restricciones resolvieron mejor la práctica y 17 % peor el examen sin ayuda; quienes usaron un
asistente diseñado como tutor (que da pistas y no respuestas) quedaron igual que quienes no usaron IA. Queremos
el segundo efecto. En cursos de programación pasa lo mismo: quien usa la IA para que le explique aprende; quien
la usa para que le resuelva, no (Lehmann et al., 2025). Las fuentes están en `06-evidencia-y-bibliografia.md`.

### Semáforo

| 🟢 Verde: úsala libremente | 🟡 Amarillo: úsala y decláralo | 🔴 Rojo: no |
|---|---|---|
| Pedir que te explique un concepto con otras palabras o con una analogía | Pedir un fragmento de código de ≤ 10 líneas que después **reescribes y explicas** con tus palabras en el reporte | Pegar el enunciado y entregar lo que salga |
| Pedir preguntas de práctica o un examen simulado sobre un tema | Pedir que revise tu código y te señale posibles carreras o interbloqueos (tú decides y verificas) | Usarla durante la recuperación de inicio, los exámenes o la defensa oral |
| Pedir que te explique un error de compilación o un mensaje de `mpirun` | Pedir que te sugiera casos de prueba | Inventar o "mejorar" mediciones con la IA |
| Pedir que te ayude a planear el estudio o a organizar el reporte | Traducir documentación | Entregar texto de reporte generado sin revisar (se nota, y en la defensa se pregunta) |
| Pedir que critique tu diseño de Foster con preguntas | Generar gráficas a partir de **tus** datos | Pedirle el proyecto completo o una versión completa (V1/V2/V3); cualquier fragmento de más de 10 líneas o una función completa generada por IA, salvo que la sección "Política de IA aplicada" de la práctica lo autorice |

### Declaración de uso (va al final de cada reporte)

```
Uso de IA en esta entrega:
- Herramienta(s): …
- Para qué la usamos (verde/amarillo): …
- Qué fragmento(s) de código vinieron de la IA (archivo y líneas) y cómo los verificamos: …
- Qué nos dijo la IA que resultó estar mal: …
```

La última línea no es opcional. Si no encontraron nada mal, escriban qué verificaron y cómo (compilaron con
`-Wall -Wextra`, midieron con el protocolo, contrastaron con la documentación oficial). "Nada; verificado con X"
es una respuesta válida; inventar un error no lo es. Si no usaron IA, escriban "No usamos IA en esta entrega" y
fírmenlo todos. Declarar uso verde o amarillo nunca baja la calificación; omitirlo sí (criterio "Proceso e
integridad" de la rúbrica).

### Prueba de propiedad

Cualquier línea que entregues debe poder explicarla cualquier integrante del equipo en voz alta: qué hace,
por qué está ahí, qué pasaría si se quita. En la práctica, el profesor te pregunta sobre la parte que firmaste
en el reparto de trabajo; del resto del código debes poder decir qué hace cada función y por qué está. Se
pregunta en laboratorio, al recibir los hitos y en la defensa oral.

Reglas, iguales en todo el curso (`03-plantilla-practica.md` §2 y `04-evaluacion.md` §6 solo las citan):

- Si no puedes explicar una línea de la parte que firmaste, el criterio "Proceso e integridad" de esa entrega
  baja a Insuficiente **para ti**, no para tu equipo. Si además hay indicios de copia, aplica `04-evaluacion.md` §6.
- Si la primera respuesta falla, el profesor pregunta sobre otra línea y cuenta la mejor de las dos.
- Puedes pedir, sin dar razones, responder las mismas preguntas por escrito en el momento (5 min, papel, sin
  dispositivos). Vale igual.

### Un *prompt* que sí ayuda a aprender

Copia esto al inicio de la conversación con cualquier asistente:

```
Actúa como tutor socrático de Cómputo Paralelo (C, OpenMP, MPI, CUDA). No me des la solución ni código
completo. Hazme una pregunta a la vez para que yo llegue a la respuesta. Si te pego código, señala en qué
línea mirar y por qué, pero no lo corrijas por mí. Si me equivoco, dime qué concepto debo repasar.
Cuando te pida una explicación, dámela en menos de 150 palabras y termina con una pregunta para verificar
que entendí.
```

### Cómo verificar lo que te dice la IA

1. **Compila y corre.** Si no compila con `-Wall -Wextra` sin *warnings*, no sirve.
2. **Mide.** Si la IA dice "esto es más rápido", pídele por qué y después mídelo con el protocolo del curso.
3. **Contrasta con la fuente oficial.** Especificación de OpenMP, estándar MPI, guía de programación de CUDA.
4. **Busca la carrera.** Compila con `-fsanitize=thread` cuando sea posible. "Me dio el resultado correcto
   una vez" no es verificación.
5. **Pregúntale lo contrario.** "¿Por qué podría estar mal lo que acabas de decir?" suele sacar la verdad.

## Para el profesor

- Zonas sin IA (recuperación, exámenes, defensa) se cuidan con el formato: papel, sin dispositivos, preguntas
  individuales.
- La IA sí se usa para preparar el curso: generar variantes de ejercicios, borradores de retroalimentación
  (que se revisan), casos de prueba adicionales, y resúmenes de *exit tickets*. Todo se verifica antes de llegar
  al estudiante, con los mismos cinco pasos de arriba.
- En las mini-defensas de laboratorio, dos preguntas fijas bastan: "¿qué hace esta línea?" y "¿qué pasaría si la
  quito?". Se hace la primera a cada integrante; la segunda solo si la primera falla. Con 12–17 equipos no hay
  tiempo para más (`02-plantilla-sesion.md`, §2.1).
