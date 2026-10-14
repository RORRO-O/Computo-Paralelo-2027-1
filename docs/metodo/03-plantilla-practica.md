# Plantilla de práctica de laboratorio

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Plantilla · versión 1.0

Una práctica es la pieza donde el andamiaje se desvanece: empieza con código que funciona, pide completar,
luego pide diseñar, y termina con una medición honesta. Dura dos sesiones de laboratorio más trabajo en casa
(estimado total: 6–8 horas por equipo). Se entrega por equipo (2–3 integrantes) con responsabilidad individual.

## 1. Secciones obligatorias de `README.md`

### Portada
Título, unidad, fechas (publicación, sesiones de laboratorio, fecha límite con hora), ponderación según
`planeacion/mapa-evaluacion.md`, entregables en una línea, tiempo estimado.

### Objetivos
Tres a cinco, con verbo observable. Al menos uno de **medir e interpretar** rendimiento y uno de **explicar**
una decisión de diseño.

### Pre-laboratorio (individual, 20 min, se entrega al inicio de la sesión)
- 4 preguntas de recuperación sobre lo necesario para la práctica.
- Lectura de `notas-estudiante.md` de las sesiones indicadas.
- **Predicción**: "Antes de correr nada, ¿qué *speedup* esperas con 4 hilos y por qué?" (se compara al final).

### Parte A · Guiada (código completo que se ejecuta, se lee y se modifica)
Pasos numerados. Cada paso dice qué correr, qué observar y qué anotar. Incluye al menos una tabla de rastreo
o predicción (PRIMM). Termina con una verificación automática (`make test`).

### Parte B · Semi-guiada (completar)
Código con `TODO(n)` y pistas decrecientes. Cada `TODO` tiene un criterio de verificación. Aquí entra la
idea errónea que la práctica quiere exponer (p. ej., una carrera que "a veces" sale bien).

### Parte C · Diseño propio (restricciones claras)
Un problema nuevo pero cercano. Se dan: entrada, salida esperada, restricciones (p. ej., "sin `critical` en el
ciclo interno"), y los casos de prueba. No se da la estructura del código.

### Parte D · Medición e interpretación
Protocolo del curso (`herramientas/protocolo-medicion.md`). Tabla obligatoria: tamaño del problema, hilos o
procesos (1, 2, 4, 8 según hardware), mediana de tiempo, *speedup*, eficiencia. Una gráfica. Tres preguntas de
interpretación ("¿dónde deja de escalar y por qué?", "¿coincide con tu predicción?").

### Preguntas de reflexión (individuales, 5–8 líneas cada una)
Al menos una de autoexplicación ("explica con tus palabras por qué…") y una de transferencia ("¿cómo
aplicarías esto en la V2 de tu proyecto?").

### Entregables y formato
- Repositorio del equipo: carpeta `practicas/Pn/` con código, `Makefile`, `tests/`, `resultados/` (CSV + PNG),
  `REPORTE.md` (≤ 3 páginas: decisiones, tabla, gráfica, interpretación, reflexión, bitácora de errores,
  declaración de uso de IA, reparto de trabajo).
- Historial de *commits* con participación de cada integrante.
- Un video de ≤ 3 minutos o una demostración en vivo en la sesión de entrega (según se indique).

### Rúbrica
Incluida (ver `rubrica.md`) y resumida en una tabla en el README.

### Política de IA aplicada a esta práctica
Qué está en verde/amarillo/rojo para esta práctica en particular, y cómo se declara.

### Errores comunes y cómo detectarlos
Lista de 5–8 errores con el síntoma y la primera pregunta que debe hacerse el estudiante.

### Extensión opcional (sin puntos extra, con reconocimiento en la defensa)
Un reto que conecta con la siguiente unidad.

## 2. Rúbrica analítica (estructura fija)

Cuatro niveles por criterio. Los pesos suman 100.

| Criterio | Peso sugerido | Ejemplar (100 %) | Competente (80 %) | En desarrollo (55 %) | Insuficiente (20 %) |
|---|---|---|---|---|---|
| Correctitud y pruebas | 25 | Pasa todas las pruebas; agrega casos propios con sentido | Pasa todas las pruebas | Falla casos límite | No compila o falla casos básicos |
| Diseño paralelo | 20 | Decisiones justificadas con el modelo de la unidad; sin sincronización innecesaria | Correcto, con alguna ineficiencia explicada | Funciona pero con decisiones no justificadas | Paralelización incorrecta o ausente |
| Medición | 20 | Protocolo completo; gráfica clara; identifica límites de escalabilidad | Protocolo completo con interpretación parcial | Mediciones incompletas o sin repeticiones | Sin mediciones o no reproducibles |
| Interpretación y reflexión | 20 | Conecta resultados con Amdahl/costos de comunicación/memoria; compara con su predicción | Explica resultados correctamente | Describe sin explicar | Ausente o incorrecta |
| Proceso e integridad | 15 | *Commits* de todos; bitácora de errores útil; declaración de IA completa; defensa individual sólida | Todo presente con detalles menores | Participación desigual o declaración incompleta | Evidencia de entrega sin comprensión |

**Responsabilidad individual.** En la sesión de entrega, el profesor hace 2 preguntas a cada integrante sobre el
código. Una respuesta que muestre que no se entiende el código propio baja el criterio "Proceso e integridad"
**de ese integrante** a Insuficiente.

## 3. Verificación automática

`tests/run_tests.sh` compila, ejecuta con tamaños fijos y compara contra la salida de referencia (secuencial)
con tolerancia. Imprime `PASS`/`FAIL` por caso y termina con código 0 solo si todo pasa. El estudiante lo corre
antes de entregar; el profesor lo corre al calificar.

## 4. Calendario interno típico de una práctica

| Momento | Qué pasa |
|---|---|
| Publicación (jueves) | README disponible; se asigna el pre-laboratorio |
| Laboratorio 1 (martes) | Pre-lab entregado; Partes A y B |
| Entre sesiones | Parte C y mediciones |
| Laboratorio 2 (martes siguiente) | Parte D, punto de control, mini-defensas |
| Fecha límite (domingo 23:59) | Entrega en el repositorio |
| ≤ 7 días | Retroalimentación con rúbrica |
