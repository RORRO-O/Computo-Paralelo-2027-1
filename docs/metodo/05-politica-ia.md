# Política de uso de IA generativa

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · versión 1.0 · 14 de octubre de 2026

## Para ti, estudiante

La IA generativa (ChatGPT, Claude, Gemini, Copilot y similares) es parte de tu caja de herramientas y lo será en
tu trabajo. En este curso la usas como **tutor**, no como **sustituto**. La razón es práctica, no moral: un
estudio con miles de estudiantes mostró que quienes usaron un asistente sin restricciones resolvieron mejor
las tareas y peor el examen; quienes usaron un asistente diseñado como tutor (que da pistas y no respuestas)
no sufrieron ese daño. Queremos el segundo efecto.

### Semáforo

| 🟢 Verde: úsala libremente | 🟡 Amarillo: úsala y decláralo | 🔴 Rojo: no |
|---|---|---|
| Pedir que te explique un concepto con otras palabras o con una analogía | Pedir un fragmento de código de ≤ 10 líneas que después **reescribes y explicas** con tus palabras en el reporte | Pegar el enunciado y entregar lo que salga |
| Pedir preguntas de práctica o un examen simulado sobre un tema | Pedir que revise tu código y te señale posibles carreras o interbloqueos (tú decides y verificas) | Usarla durante la recuperación de inicio, los exámenes o la defensa oral |
| Pedir que te explique un error de compilación o un mensaje de `mpirun` | Pedir que te sugiera casos de prueba | Inventar o "mejorar" mediciones con la IA |
| Pedir que te ayude a planear el estudio o a organizar el reporte | Traducir documentación | Entregar texto de reporte generado sin revisar (se nota, y en la defensa se pregunta) |
| Pedir que critique tu diseño de Foster con preguntas | Generar gráficas a partir de **tus** datos | Pedirle el proyecto completo o una versión completa (V1/V2/V3) |

### Declaración de uso (va al final de cada reporte)

```
Uso de IA en esta entrega:
- Herramienta(s): …
- Para qué la usamos (verde/amarillo): …
- Qué fragmento(s) de código vinieron de la IA (archivo y líneas) y cómo los verificamos: …
- Qué nos dijo la IA que resultó estar mal: …
```

La última línea no es opcional. Si no encontraste nada mal, no verificaste lo suficiente.

### Prueba de propiedad

Cualquier línea que entregues debe poder explicarla cualquier integrante del equipo en voz alta: qué hace,
por qué está ahí, qué pasaría si se quita. En laboratorio y en la defensa oral se pregunta. Si no puedes
explicarla, no es tuya, y cuenta como si no la hubieras entregado.

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
  quito?".
