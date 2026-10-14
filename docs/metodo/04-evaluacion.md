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

## 2. Diseño de exámenes departamentales

### 2.1 Tabla de especificaciones (obligatoria antes de escribir ítems)

Filas: temas de la unidad (y 10–20 % de unidades previas). Columnas: nivel cognitivo.

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
- Antes de entregar el examen, el estudiante escribe su calificación esperada (calibración).
- Devolución en ≤ 7 días con sesión de análisis de errores (los 3 ítems peor contestados se trabajan en clase).

## 3. Rúbricas

Todas las rúbricas del curso son analíticas, de cuatro niveles, con pesos que suman 100, y se publican con la
tarea. El nivel se describe con evidencia observable, no con adjetivos ("explica el límite de escalabilidad
usando la fracción secuencial medida", no "buena interpretación").

## 4. Evaluación formativa (no cuenta o cuenta poco, pero decide la enseñanza)

| Instrumento | Frecuencia | Uso |
|---|---|---|
| Recuperación de inicio | Cada sesión | Detectar olvido; decidir si se reexplica |
| ConcepTests | 2 por sesión | Detectar ideas erróneas en vivo |
| *Exit ticket* | Cada sesión | Ajustar la siguiente sesión; participación cuenta en "otros" |
| Examen de práctica | 1 por parcial | Calibración y repaso |
| Mini-defensas en laboratorio | Cada práctica | Responsabilidad individual |

## 5. Política de entregas (propuesta ajustable)

- Fecha límite firme. Entrega tardía dentro de las 72 h siguientes: máximo 80 %. Después, no se recibe salvo
  justificante institucional.
- **Segunda entrega** de prácticas: si la primera obtiene < 70 %, el equipo puede corregir y reentregar en 7 días
  para alcanzar hasta 80 %. Se exige una nota de cambios ("qué corregimos y por qué").
- Un hito del proyecto no entregado no bloquea el siguiente, pero su porcentaje se pierde.

## 6. Integridad académica

- Exámenes, recuperación y defensa oral: sin IA ni dispositivos.
- Prácticas y proyecto: IA según `05-politica-ia.md`, con declaración.
- Código idéntico entre equipos sin explicación: 0 en la entrega para todos los involucrados y reporte según
  reglamento. La "prueba de propiedad" oral es la primera línea de verificación.
