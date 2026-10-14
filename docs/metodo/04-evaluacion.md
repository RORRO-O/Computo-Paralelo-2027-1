# Evaluación: parciales, exámenes, rúbricas y retroalimentación

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · versión 1.0 · 14 de octubre de 2026

## 1. Estructura de los parciales

Las ponderaciones del 1er y 3er parcial están definidas en la planeación del curso (calendario del grupo).
La del 2º parcial se infiere por simetría con el 1º y **debe confirmarse** por el profesor.

| Parcial | Examen | Prácticas | Otros | Fuente |
|---|---|---|---|---|
| 1º (U I–II) | 40 % | P1–P3: 40 % | Ejercicios y organizadores: 20 % | Calendario (29 sep) |
| 2º (U III) | 40 % | P4: 40 % | H1 + ejercicios + *exit tickets*: 20 % | **Supuesto por simetría** |
| 3º (U IV–V) | 30 % | P5–P6: 30 % | Proyecto integrador: 40 % | Calendario (8 dic) |

"Otros" del 2º parcial se reparte así (propuesta): H1 Avance 1 = 12 %, ejercicios/tareas espaciadas = 5 %,
*exit tickets* y recuperación (por participación, no por acierto) = 3 %.

Cómo se calculan los dos componentes pequeños del 2º parcial:

- **Participación (3 %)**: proporción de sesiones con *exit ticket* entregado. Dos ausencias no descuentan. Quien
  faltó lo sustituye con la `tarea-espaciada.md` de esa sesión entregada antes de la siguiente (§5).
- **Tareas (5 %)**: (tareas entregadas a tiempo / total) × promedio de calidad de 3 revisadas al azar entre las
  entregadas. Quien entregó todas y no cayó en el sorteo no pierde puntos por eso.

**3er parcial.** Tareas espaciadas y *exit tickets* no tienen peso propio: la ponderación del calendario no deja
componente "otros". Se conservan por su valor formativo y son la preparación explícita del Examen 3: el examen de
práctica del jueves 3 de diciembre y el 10–20 % acumulativo del E3 toman ítems de las tareas intercaladas de las
Unidades IV–V. Cada `tarea-espaciada.md` de U4–U5 lo dice con esas palabras (`07-guia-de-autoria.md`, §A.10).

## 2. Diseño de exámenes departamentales

### 2.1 Tabla de especificaciones (obligatoria antes de escribir ítems)

Filas: temas de la unidad (y 10–20 % de unidades previas). Columnas: nivel cognitivo. Los puntos de unidades
previas se integran dentro de problemas de la unidad evaluada (Amdahl y eficiencia aplicados a mediciones MPI o
GPU; carreras de datos en una reducción CUDA), de modo que el examen no sale de su alcance declarado y la
recuperación exige transferencia. Las ponderaciones no cambian.

| Tema | Recordar/Comprender | Aplicar/Analizar | Evaluar/Crear | Puntos |
|---|---|---|---|---|
| … | … | … | … | … |

Distribución objetivo: 30 % recordar/comprender · 50 % aplicar/analizar · 20 % evaluar/crear.

### 2.2 Tipos de ítem y para qué sirven

| Tipo | Mide | Notas |
|---|---|---|
| Opción múltiple con distractores de ideas erróneas | Comprensión conceptual | Cada distractor cita el número del Anexo A |
| Predecir salida / rastrear | Modelo mental de ejecución | Código corto (≤ 15 líneas); se pide justificar |
| Encontrar y corregir el error | Diagnóstico | Carreras, interbloqueos, barreras faltantes |
| Completar código | Aplicación de la herramienta | Se dan la estructura y las restricciones |
| Problema de rendimiento con números | Razonamiento cuantitativo | Amdahl, eficiencia, modelo de comunicación, transferencias GPU |
| Diseño breve | Evaluar/crear | Elegir estrategia y justificarla en ≤ 10 líneas |

### 2.3 Reglas

- Dos versiones (A/B) equivalentes en tabla de especificaciones y dificultad; se alternan por fila.
- 80 minutos efectivos. Puntaje total 100. Sin dispositivos. Hoja de fórmulas permitida solo si el examen lo indica.
- Clave con justificación por ítem (sirve para la sesión de retroalimentación).
- Una semana antes: examen de práctica con la misma estructura (versión corta) y clave.
- Calibración en hoja aparte con dos casillas: al recibir el examen, la calificación que espera; al entregarlo,
  la que cree haber obtenido. La hoja se entrega separada del examen, se abre después de calificar y se devuelve
  a cada estudiante con su propia brecha; al grupo solo se le muestra el promedio. No afecta la calificación.
- Devolución en ≤ 7 días: calificación y clave publicadas en ese plazo; la sesión de análisis de errores (los 3
  ítems peor contestados se trabajan en clase) es la que fija el calendario. E2: calificación y clave a más tardar
  el martes 10 de noviembre; análisis de errores el jueves 12 de noviembre (U4 S04).
- Si el examen cae en horario de laboratorio (E2 y E3, martes 08:30), se aplica en el 3208 o en LS4 con los
  equipos apagados y filas alternas.

## 3. Rúbricas

Todas las rúbricas del curso son analíticas, de cuatro niveles, con pesos que suman 100, y se publican con la
tarea. El nivel se describe con evidencia observable, no con adjetivos ("explica el límite de escalabilidad
usando la fracción secuencial medida", no "buena interpretación"). Modelo: las filas Medición y Proceso e
integridad de `03-plantilla-practica.md`, §2.

### 3.1 Formato mínimo de retroalimentación

| Entrega | Qué recibe el equipo o el estudiante | Cuándo |
|---|---|---|
| Hitos H1/H2 | Lista de cotejo de pares llena + 2 líneas del profesor; rúbrica aplicada fuera de clase | Cotejo el mismo día; rúbrica ≤ 7 días |
| Prácticas | Salida de `tests/run_tests.sh` + nivel por criterio + ≤ 2 líneas por criterio + un documento grupal con los 3 errores más frecuentes | ≤ 7 días |
| Exámenes | Calificación y clave + sesión de análisis de errores | ≤ 7 días; sesión según calendario |
| Tareas espaciadas | Autocalificación con la clave; el profesor registra entrega | Inicio de la siguiente sesión |

La semana del 29 de octubre al 3 de noviembre concentra H1, P4 y E2 con un solo calificador. El formato mínimo
existe para que el plazo se cumpla: no se relaja el plazo, se recorta el formato. Nota para el profesor: cuando se
desbloqueen `docs/CONVENCIONES.md` §4 y `planeacion/mapa-evaluacion.md`, conviene precisar "7 días hábiles".

### 3.2 Defensa del proyecto

Con 12–17 equipos, 12 minutos por equipo no caben en los 90 minutos del jueves 10 de diciembre.
`proyecto/README.md` §3 presenta tres opciones; el profesor elige y anuncia a más tardar el jueves 3 de
diciembre, y de preferencia desde el lunes 23 de noviembre (H2) para que los equipos graben con tiempo. Se
recomienda la opción C con dos ajustes respecto a como está escrita en ese README: exposición de ≤ 8 min (no
12) en video (no listado o privado) enlazado en el repositorio antes del lunes 7 de diciembre 10:30, junto con
la entrega final y no el 10, para que el profesor la vea antes de la sesión; se califica con la rúbrica de la
defensa. En clase, 6 min por equipo: 2 min de demo en vivo y una pregunta individual a cada integrante (la
segunda solo si la primera falla).

**Ajuste individual.** La calificación del proyecto de cada integrante parte de la del equipo y se mueve solo
por mecanismos escritos (`proyecto/README.md`, §6): los criterios que se asignan por integrante (proceso en H1,
H2 y repositorio; respuestas individuales en la defensa) y el ajuste por desconocimiento del código propio, de a
lo sumo −20 % de los 100 puntos del proyecto (−10 % por cada respuesta individual en Insuficiente, máximo dos;
`proyecto/defensa/rubrica-defensa.md`, §4.1). Nunca baja por las respuestas de otro integrante.

## 4. Evaluación formativa (no cuenta o cuenta poco, pero decide la enseñanza)

| Instrumento | Frecuencia | Uso |
|---|---|---|
| Recuperación de inicio | Cada sesión | Detectar olvido; decidir si se reexplica |
| ConcepTests | 2 por sesión | Detectar ideas erróneas en vivo |
| *Exit ticket* | Cada sesión | Ajustar la siguiente sesión; participación cuenta en "otros" del 2º parcial; sin peso propio en el 3º |
| Tarea espaciada | Cada sesión | El estudiante la autocalifica con la clave en `<details>` al inicio de la siguiente sesión (2 min, dentro del bloque 5–10); el profesor registra entrega, no acierto, y revisa 3 al azar por parcial |
| Examen de práctica | 1 por parcial | Calibración y repaso; si coincide con un hito (S13), se resuelve en casa cronometrado y en clase se corrige |
| Mini-defensas en laboratorio | Cada práctica (Laboratorio 2; con más de 12 equipos, la mitad en el Laboratorio 1, `02` §2.1) | Responsabilidad individual: una pregunta por integrante, la segunda solo si la primera falla |

## 5. Política de entregas (propuesta ajustable)

- Fecha límite firme. Entrega tardía dentro de las 72 h siguientes: máximo 80 %. Después, no se recibe salvo
  justificante institucional. Una entrega tardía no tiene segunda entrega.
- **Segunda entrega** de prácticas: si la primera obtiene < 70 % (umbral fijado en `planeacion/mapa-evaluacion.md`),
  el equipo puede corregir y reentregar una vez dentro de los 7 días siguientes a la retroalimentación, con nota
  de cambios ("qué corregimos y por qué"). La calificación final es la mayor entre la primera y la segunda; la
  segunda tiene tope de 80 %. P6: retroalimentación a más tardar el jueves 10 de diciembre; segunda entrega hasta
  el martes 15 de diciembre 08:30 (reserva del calendario).
- Un hito del proyecto no entregado no bloquea el siguiente, pero su porcentaje se pierde.
- **Inasistencia a una sesión.** El *exit ticket* y la recuperación de ese día se sustituyen entregando la
  `tarea-espaciada.md` de esa sesión antes de la siguiente (cuenta como participación). El pre-laboratorio se
  entrega en el repositorio antes de la hora de la sesión, falte o no. Mini-defensa pendiente: en la siguiente
  sesión de laboratorio o en la reserva del martes 15 de diciembre. Hito con justificante institucional: se recibe
  en la siguiente sesión al 100 %; sin justificante, aplica la regla de 72 h al 80 %. Examen de práctica: se hace
  en casa con la clave y la hoja de calibración se registra igual.
- **Entregas que requieren GPU (P6, V3).** La correctitud se verifica sin GPU (`make test` con
  `NUMBA_ENABLE_CUDASIM=1` o el espejo en CPU) y nunca depende de la cuota. Si Colab y Kaggle niegan GPU en las
  48 h previas a la fecha límite, el equipo entrega a tiempo con la captura fechada del aviso de cuota y la
  medición marcada como pendiente, y la completa en GPU en cuanto haya cuota y a más tardar el martes 15 de
  diciembre 08:30, sin penalización. Antes del martes 24 de noviembre cada integrante verifica que obtiene GPU en
  Colab y en Kaggle (pre-laboratorio de P6). Las mediciones de V3 se hacen en la semana del 30 de noviembre, no
  el fin de semana del 5–6 de diciembre.
- **Reporte final del proyecto.** Solo agrega la V3 y la sección de integración: las secciones de V1 y V2 se
  entregan corregidas a partir de la retroalimentación de H1 y H2, no reescritas. El `REPORTE.md` de P6 puede
  reutilizarse como base de la sección V3.

## 6. Integridad académica

- Exámenes, recuperación y defensa oral: sin IA ni dispositivos.
- Prácticas y proyecto: IA según `05-politica-ia.md`, con declaración.
- Código idéntico entre equipos sin explicación: 0 en la entrega para todos los involucrados y reporte según
  reglamento; el equipo de origen conserva su calificación si el historial de su repositorio privado muestra que
  no lo compartió.
- La "prueba de propiedad" (`05-politica-ia.md`) es la primera línea de verificación: oral o, a petición del
  estudiante, por escrito en el momento. Su consecuencia es la que fija `05`; `03-plantilla-practica.md` §2 y este
  documento solo la citan.
