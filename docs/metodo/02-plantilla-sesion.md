# Plantilla de sesión (90 minutos)

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Plantilla · versión 1.0

## 1. Estructura base

| Minuto | Bloque | Qué hace el estudiante | Qué hace el profesor | Material |
|---|---|---|---|---|
| 0–5 | **Recuperación** | Responde 4–5 preguntas por escrito, solo, sin apuntes | Proyecta las preguntas; a los 4 min muestra respuestas; pide manos por pregunta | `retrieval-inicio.md` |
| 5–10 | **Objetivos y anclaje** | Lee los objetivos ("al final podrás…"); identifica dónde entra en el proyecto | Conecta con el error más frecuente del *exit ticket* anterior | `plan-sesion.md` |
| 10–35 | **Instrucción explícita I** | Sigue el ejemplo resuelto; responde las pausas de autoexplicación; vota ConcepTest 1 | Piensa en voz alta; muestra el código y el resultado; voto → discusión → revoto | `ejemplo-resuelto.md`, `conceptests.md` |
| 35–65 | **Práctica guiada PRIMM** | En parejas (conductor/navegante, cambio a los 15 min): predice, ejecuta, investiga, modifica | Circula con la lista de errores esperados; no da respuestas, da preguntas | `practica-guiada/` |
| 65–75 | **Puesta en común** | Compara su predicción con lo observado; vota ConcepTest 2 | Muestra 2–3 errores vistos (sin nombres); enuncia la regla general | `conceptests.md` |
| 75–85 | **Transferencia** | Resuelve el "Make" de PRIMM o aplica al proyecto/práctica | Atiende a quien se atoró en PRIMM; reta a quien ya terminó | `practica-guiada/README.md` (sección Crear) |
| 85–90 | **Cierre** | Responde el *exit ticket* (2 preguntas + confianza) | Anuncia la tarea espaciada y la fecha de la siguiente entrega | `exit-ticket.md`, `tarea-espaciada.md` |

Reglas de tiempo: si algo se alarga, se recorta **Transferencia**. Nunca se recortan Recuperación ni Cierre.

## 2. Variantes

### 2.1 Sesión de laboratorio (martes 08:30, o cuando toca práctica)

| Minuto | Bloque |
|---|---|
| 0–5 | Recuperación (incluye 1 pregunta sobre el enunciado de la práctica) |
| 5–15 | Demostración del profesor: compilar, correr, medir el código base; errores típicos de entorno |
| 15–70 | Trabajo en parejas/equipos sobre la práctica; el profesor circula con la rúbrica en mano y hace "mini-defensas" de 2 min por equipo |
| 70–85 | Punto de control: cada equipo muestra una medición y la explica en 1 minuto |
| 85–90 | *Exit ticket* + recordatorio de fecha límite |

### 2.2 Sesión de repaso previa a examen

| Minuto | Bloque |
|---|---|
| 0–10 | Recuperación larga (8–10 preguntas acumulativas) |
| 10–50 | Examen de práctica individual (versión corta, misma estructura que el real) |
| 50–80 | Corrección entre pares con clave y rúbrica; discusión de los 3 ítems peor contestados |
| 80–85 | Predicción individual de calificación (calibración) |
| 85–90 | *Exit ticket*: "¿qué vas a estudiar hoy y mañana?" (plan concreto) |

### 2.3 Día de examen

Instrucciones impresas, versiones A/B alternadas por fila, 80 minutos efectivos, 10 minutos de margen.
Sin dispositivos. Al terminar, se recoge la hoja de predicción de calificación.

### 2.4 Taller de proyecto

| Minuto | Bloque |
|---|---|
| 0–5 | Recuperación |
| 5–15 | Mini-lección dirigida al hito (p. ej., "cómo reportar *speedup* sin engañarte") |
| 15–75 | Trabajo por equipos con lista de cotejo del hito; el profesor hace rondas de 4 min por equipo con 2 preguntas fijas: "¿qué midieron?" y "¿qué no entienden todavía?" |
| 75–85 | Dos equipos muestran su avance (2 min cada uno) + retroalimentación de pares con lista de cotejo |
| 85–90 | *Exit ticket* |

## 3. Esqueleto de `plan-sesion.md`

```markdown
> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad X · Sesión Sxx · <día> <fecha> · <hora> · <lugar>

# Sxx · <Título de la sesión>

## Objetivos (al terminar, el estudiante podrá…)
1. <verbo observable + contenido + condición>  (nivel: comprender / aplicar / analizar / evaluar)
2. …

## Prerrequisitos y vínculo
- Viene de: <sesión anterior / unidad previa>
- Va hacia: <siguiente sesión / práctica / hito del proyecto>
- Idea(s) errónea(s) que esta sesión ataca: <números del Anexo A>

## Materiales
- Archivos de esta carpeta; proyector; cronómetro; tarjetas de lista; máquina con gcc/mpicc o Colab.

## Guion minuto a minuto
### 0–5 Recuperación
<qué proyectar; respuesta esperada; qué hacer si < 60 % acierta la pregunta 1>
### 5–10 Objetivos y anclaje
<frase exacta para conectar con el exit ticket anterior y con el proyecto>
### 10–35 Instrucción explícita I
<pasos del ejemplo resuelto; qué decir en cada pausa; ConcepTest 1: pregunta, % esperado, guion de discusión>
### 35–65 Práctica guiada PRIMM
<instrucciones de arranque; lista de errores esperados y la pregunta que se hace ante cada uno; qué hacer a los 15 min>
### 65–75 Puesta en común
<los 2–3 hallazgos que se muestran; ConcepTest 2; regla general en una frase>
### 75–85 Transferencia
<reto; criterio de "listo"; extensión para quien termina antes; apoyo para quien no arranca>
### 85–90 Cierre
<exit ticket; anuncio de tarea; fecha y hora de la siguiente entrega>

## Diferenciación
- Apoyo (quien no arranca): <andamio adicional concreto>
- Ampliación (quien termina): <reto adicional concreto>

## Evaluación formativa de la sesión
- Qué mira el profesor para saber si se cumplió cada objetivo.

## Notas post-sesión
- (se llenan después) qué falló, qué cambiar, error más frecuente del exit ticket.
```

## 4. Lista de cotejo de calidad de una sesión

- [ ] Los objetivos usan verbos observables y se evalúan en el *exit ticket*.
- [ ] La recuperación incluye al menos una pregunta de una unidad anterior.
- [ ] El ejemplo resuelto tiene ≥ 3 pausas de autoexplicación con respuesta.
- [ ] Cada distractor de los ConcepTests corresponde a una idea errónea del Anexo A (o a una nueva, que se agrega).
- [ ] La práctica guiada compila con `make` y pasa `make test`; tiene las cinco fases PRIMM.
- [ ] Hay lista de errores esperados con la pregunta que el profesor hace ante cada uno.
- [ ] La tarea espaciada tiene un ejercicio intercalado de unidades previas y cabe en ≤ 40 min.
- [ ] Las fechas y ponderaciones coinciden con `planeacion/mapa-evaluacion.md`.
- [ ] Un estudiante que faltó puede reconstruir la sesión con `notas-estudiante.md` + ejemplo + práctica guiada.
