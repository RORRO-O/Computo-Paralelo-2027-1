# Plantilla de sesión (90 minutos)

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Plantilla · versión 1.0

## 1. Estructura base

| Minuto | Bloque | Qué hace el estudiante | Qué hace el profesor | Material |
|---|---|---|---|---|
| 0–5 | **Recuperación** | Responde 4–5 preguntas por escrito, solo, sin apuntes | Proyecta las preguntas; a los 4 min muestra respuestas; pide manos por pregunta | `retrieval-inicio.md` |
| 5–10 | **Objetivos y anclaje** | Autocalifica la tarea espaciada anterior con su clave (2 min); lee los objetivos ("al final podrás…"); identifica dónde entra en el proyecto | Registra la entrega de la tarea; conecta con el error más frecuente del *exit ticket* anterior | `tarea-espaciada.md` anterior, `plan-sesion.md` |
| 10–35 | **Instrucción explícita I** | Sigue el ejemplo resuelto; responde las pausas de autoexplicación; vota ConcepTest 1 | Piensa en voz alta; muestra el código y el resultado; voto → discusión → revoto | `ejemplo-resuelto.md`, `conceptests.md` |
| 35–65 | **Práctica guiada PRIMM** | En parejas (conductor/navegante, cambio a los 15 min): predice, ejecuta, investiga, modifica | Circula con la lista de errores esperados; no da respuestas, da preguntas. Si la tarea espaciada anterior ya pidió la predicción, la revisa en 2 min y arranca en Ejecutar | `practica-guiada/` |
| 65–75 | **Puesta en común** | Compara su predicción con lo observado; vota ConcepTest 2 | Muestra 2–3 errores vistos (sin nombres ni números de lista); ConcepTest 2: voto; discusión en parejas y revoto solo si el acierto queda entre 30 % y 80 %, fuera de ese rango pasa a la explicación; si no hay tiempo, pasa como pregunta 1 de la recuperación siguiente; enuncia la regla general | `conceptests.md` |
| 75–85 | **Transferencia** | Resuelve el "Make" de PRIMM o aplica al proyecto/práctica | Atiende a quien se atoró en PRIMM; reta a quien ya terminó | `practica-guiada/README.md` (sección Crear) |
| 85–90 | **Cierre** | Responde el *exit ticket* (2 preguntas + confianza) | Anuncia la tarea espaciada y la fecha de la siguiente entrega | `exit-ticket.md`, `tarea-espaciada.md` |

Reglas de tiempo: si algo se alarga, se recorta **Transferencia**. Nunca se recortan Recuperación ni Cierre.
Si se recorta Transferencia, el "Crear" de PRIMM pasa íntegro a `tarea-espaciada.md` como el ejercicio del tema;
nunca se elimina. Si la sesión arranca con ≥ 5 min de retraso (martes 08:30), la recuperación baja a 3 preguntas
(nunca a cero) y el resto del retraso se descuenta de Transferencia. Si se pierden 20–30 min, se pasa a la
variante de 60 minutos (§2.6).

## 2. Variantes

### 2.1 Sesión de laboratorio (martes 08:30, o cuando toca práctica)

| Minuto | Bloque |
|---|---|
| 0–5 | Recuperación (incluye 1 pregunta sobre el enunciado de la práctica) |
| 5–15 | Demostración del profesor: compilar, correr, medir el código base; errores típicos de entorno |
| 15–70 | Trabajo en parejas/equipos sobre la práctica; el profesor circula con la rúbrica en mano y hace "mini-defensas" de 2 min por equipo |
| 70–85 | Punto de control: cada equipo muestra una medición y la explica en 1 minuto |
| 85–90 | *Exit ticket* + recordatorio de fecha límite |

Notas a la variante de laboratorio:

- **Constructo nuevo en Lab 1** (U3 S09: tareas; U4 S03: colectivas; U5 S02: jerarquía de memoria y *tiling*):
  el bloque 5–15 se extiende a 5–25 con un ejemplo resuelto corto (≥ 2 pausas de autoexplicación) y
  ConcepTest 1; el trabajo en parejas inicia en el minuto 25. El constructo entra en la Parte A de la práctica
  como código completo para leer y predecir, nunca como `TODO` en la Parte B de esa misma sesión.
- **Mini-defensas**: una pregunta por integrante ("¿qué hace esta línea?"); la segunda ("¿qué pasaría si la
  quito?") solo si la primera falla, y cuenta la mejor de las dos. Con más de 12 equipos, la mitad se defiende
  en Lab 1 y la otra mitad en Lab 2, con lista publicada en Lab 1. Quien pide responder por escrito lo hace en
  el momento (5 min, papel; `05-politica-ia.md`).
- **Punto de control**: si no caben todos los equipos en 15 min, 5 equipos al azar (tarjetas) muestran su
  medición; los demás anotan mediana y *speedup* en el *exit ticket*.

### 2.2 Sesión de repaso previa a examen

| Minuto | Bloque |
|---|---|
| 0–10 | Recuperación larga (8–10 preguntas acumulativas) |
| 10–50 | Examen de práctica individual (versión corta, misma estructura que el real) |
| 50–80 | Corrección entre pares con clave y rúbrica; discusión de los 3 ítems peor contestados |
| 80–85 | Predicción individual de calificación (calibración, en la escala del examen de práctica: 0–60) |
| 85–90 | *Exit ticket*: "¿qué vas a estudiar hoy y mañana?" (plan concreto) |

Si en esta sesión también se recibe un hito del proyecto (S13 con H1), se usa la variante 2.5.

### 2.3 Día de examen

Instrucciones impresas, versiones A/B alternadas por fila, 80 minutos efectivos, 10 minutos de margen.
Sin dispositivos. Hoja de calibración aparte, con dos casillas: la calificación que espera al recibir el examen
y la que cree haber obtenido al entregarlo, en la escala del examen (0–100); se recoge separada del examen
(`04-evaluacion.md`, §2.3). Si el
examen cae en horario de laboratorio (E2 y E3, martes 08:30), se aplica en el 3208 o en LS4 con los equipos
apagados y filas alternas.

### 2.4 Taller de proyecto

| Minuto | Bloque |
|---|---|
| 0–5 | Recuperación |
| 5–15 | Mini-lección dirigida al hito (p. ej., "cómo reportar *speedup* sin engañarte") |
| 15–75 | Trabajo por equipos con lista de cotejo del hito; el profesor hace rondas de 4 min por equipo con 2 preguntas fijas: "¿qué midieron?" y "¿qué no entienden todavía?" |
| 75–85 | Dos equipos muestran su avance (2 min cada uno) + retroalimentación de pares con lista de cotejo |
| 85–90 | *Exit ticket* |

### 2.5 Sesión con hito del proyecto (S13 con H1; U5 S01 con H2)

El hito se entrega en el repositorio (etiqueta) antes de la hora de clase; la rúbrica se aplica fuera de clase.

| Minuto | Bloque |
|---|---|
| 0–5 | Recuperación |
| 5–25 | Recepción del hito: ronda corta por equipo con lista de cotejo (dos preguntas fijas al equipo y una individual), o revisión cruzada entre equipos con la lista de cotejo firmada |
| 25–85 | Bloque de la variante que toque, comprimido (abajo) |
| 85–90 | *Exit ticket* |

- **S13 (H1 + repaso de Unidad III).** El examen de práctica se publica al menos dos días antes y se resuelve
  en casa, cronometrado (40 min). En clase: 5–25 recepción de H1 · 25–60 corrección entre pares con clave y
  rúbrica · 60–80 los 3 ítems peor contestados · 80–85 calibración · 85–90 *exit ticket*. La pregunta
  individual de H1 que no quepa se hace en los primeros 20 min de U4 S01 (`proyecto/hitos/H1-avance-1.md`).
- **U5 S01 (H2 + modelo CUDA).** 5–25 recepción de H2: ronda de ≤ 1 min por equipo con la lista rápida y las dos
  preguntas fijas, mientras el equipo vecino aplica la lista de cotejo; la pregunta individual, en PRIMM y al
  inicio de U5 S02 (`proyecto/hitos/H2-avance-2.md` §8, opción A) ·
  25–30 objetivos · 30–50 instrucción explícita · 50–70 PRIMM · 70–77 puesta en común · 77–85 transferencia ·
  85–90 cierre.

### 2.6 Sesión de 60 minutos (modo degradado)

Se usa cuando se pierden 20–30 minutos: proyector, red, máquinas sin `gcc`, Colab sin GPU, copias que no llegaron.

| Minuto | Bloque |
|---|---|
| 0–5 | Recuperación dictada |
| 5–25 | Ejemplo resuelto + ConcepTest 1 |
| 25–50 | PRIMM solo Ejecutar–Investigar |
| 50–55 | Regla general |
| 55–60 | *Exit ticket* dictado |

Modificar y Crear pasan a la tarea espaciada. La jerarquía se conserva: nunca se recortan Recuperación ni Cierre.

### 2.7 Plan B de materiales

- Votación sin proyector: dedos (1–4) o tarjetas A/B/C/D que cada estudiante recorta en S07 y conserva.
- Sin proyector ni copias: recuperación y *exit ticket* dictados; respuestas en hoja con número de lista.
- Código de la práctica guiada clonado la tarde anterior en la máquina del salón, con copia en USB.
- Unidad V sin GPU o sin internet: *notebook* descargado y espejo Numba con `NUMBA_ENABLE_CUDASIM=1`
  (`07-guia-de-autoria.md`, §E) para correr la lógica; la medición se pospone a la tarea. El profesor comprueba
  ese día, antes de clase, que Colab asigna GPU.
- Salón 3208: una laptop por pareja con `gcc -fopenmp` verificada en la tarea previa; quien no tenga, forma trío.

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
- Nivel de andamiaje: completo / por completar / con pistas (07 §A.5)

## Materiales
- Archivos de esta carpeta; proyector; cronómetro; tarjetas de lista; máquina con gcc/mpicc o Colab.
- En el 3208: una laptop por pareja con el compilador verificado en la tarea previa; Plan B de 02 §2.7.

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
- Apoyo (quien no arranca): el mismo ejemplo resuelto con un hueco menos o una pista sellada en `<details>` (01 P10)
- Ampliación (quien termina): el problema sin ejemplo, o la variante Crear con una restricción más

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
- [ ] El *exit ticket* tiene clave literal: cada ticket se clasifica (bien / parcial / mal) en ≤ 20 segundos.
- [ ] "Diferenciación" trae las dos formas concretas (apoyo con hueco menos o pista; ampliación sin ejemplo).
