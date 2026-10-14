# Rúbrica del reporte final (PDF) · 30 puntos

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Entrega final · lunes 7 de diciembre de 2026, 10:30 · 30 de los 100 puntos del proyecto · versión 1.0 · 14 de octubre de 2026

## 1. Cómo se aplica

1. Se califica `reporte/reporte.pdf` del *commit* etiquetado `entrega-final` (o el último anterior a las 10:30 del lunes 7
   de diciembre). La estructura obligatoria está en `plantilla-reporte.md`; la numeración de secciones de esta rúbrica es la
   de esa plantilla.
2. Cada criterio se ubica en un nivel según la evidencia observable; los niveles valen 100 % · 80 % · 55 % · 20 % del peso.
   Criterio ausente: 0.
3. El reporte se lee **con el repositorio abierto**: cada número del PDF se busca en `resultados/*.csv` y cada decisión de
   diseño en el código. Lo que no coincide se califica como si no estuviera.

## 2. Pesos

| # | Criterio | Secciones de la plantilla | Puntos | Ejemplar | Competente | En desarrollo | Insuficiente |
|---|---|---|---:|---:|---:|---:|---:|
| R1 | Estructura, extensión y resumen | Portada, 1, 13 | 3 | 3.0 | 2.4 | 1.65 | 0.6 |
| R2 | Problema, datos y diseño por el método de Foster | 2, 3 | 5 | 5.0 | 4.0 | 2.75 | 1.0 |
| R3 | Descripción de V1, V2 y V3 | 4, 5, 6 | 5 | 5.0 | 4.0 | 2.75 | 1.0 |
| R4 | Metodología de medición | 7 | 4 | 4.0 | 3.2 | 2.2 | 0.8 |
| R5 | Resultados: tablas y gráficas | 8 | 5 | 5.0 | 4.0 | 2.75 | 1.0 |
| R6 | Análisis | 9 | 5 | 5.0 | 4.0 | 2.75 | 1.0 |
| R7 | Bitácora, reparto de trabajo, declaración de IA y referencias | 10, 11, 12, 13 | 3 | 3.0 | 2.4 | 1.65 | 0.6 |
| | **Total** | | **30** | 30.0 | 24.0 | 16.5 | 6.0 |

## 3. Niveles por criterio (evidencia observable)

### R1 · Estructura, extensión y resumen (3 puntos)

| Nivel | Evidencia |
|---|---|
| **Ejemplar (3.0)** | Las 13 secciones de la plantilla, en orden. Entre 8 y 12 páginas en total (portada y referencias incluidas, sin anexos). Resumen de ≤ 10 líneas que contiene: el problema en una frase, `n`, hardware (CPU y GPU), el mejor *speedup* de V2 con su número de hilos, el *speedup* de V3 con y sin transferencias, y una frase sobre qué lo limita. Figuras y tablas numeradas, con pie que dice qué comando y qué archivo las generan. |
| **Competente (2.4)** | Estructura completa; el resumen trae los números pero omite la limitante o el hardware; o algún pie de figura sin comando. |
| **En desarrollo (1.65)** | Falta una sección o el orden cambia; resumen sin *speedup*; o extensión fuera del rango por hasta una página. |
| **Insuficiente (0.6)** | Faltan dos o más secciones; menos de 7 o más de 13 páginas (el profesor lee solo las primeras 12); o no hay resumen. |

### R2 · Problema, datos y diseño por el método de Foster (5 puntos)

| Nivel | Evidencia |
|---|---|
| **Ejemplar (5.0)** | Problema en una frase y por qué vale la pena paralelizarlo (tamaño, tiempo de V1). Datos con origen, tamaño, formato, semilla y cómo se verifica que la salida es correcta. Las cuatro etapas de Foster (partición, comunicación, aglomeración, mapeo) aplicadas **a este problema**, con un diagrama propio y una tabla "tarea → datos que toca → dependencias". El mapeo distingue hilos de CPU (V2) de bloques e hilos CUDA (V3) y dice qué cambió entre ambos. |
| **Competente (4.0)** | Las cuatro etapas presentes y correctas; diagrama genérico, o mapeo idéntico para V2 y V3 sin discutir las diferencias. |
| **En desarrollo (2.75)** | Foster descrito en abstracto (definiciones de libro) con poca conexión al problema; aglomeración entendida como "juntar todo en un proceso" (idea errónea 28); o datos sin semilla ni origen. |
| **Insuficiente (1.0)** | Sin diseño por Foster, o el diseño no corresponde al código entregado. |

### R3 · Descripción de V1, V2 y V3 (5 puntos)

| Nivel | Evidencia |
|---|---|
| **Ejemplar (5.0)** | **V1:** perfilado de línea base (qué fracción del tiempo va a qué parte y con qué se midió: `gprof`, `perf` o cronómetros por sección) y la fracción secuencial que de ahí se deriva. **V2:** decisiones de región, alcance, `schedule`, reducción y sincronización, con el fragmento clave (≤ 15 líneas, como texto, no captura) comentado. **V3:** mapeo hilo→dato, tamaño de bloque, manejo de memoria y transferencias, con el fragmento del *kernel*. Cada decisión cita el experimento o la razón que la sostiene. |
| **Competente (4.0)** | Tres versiones descritas con fragmentos; una decisión sin razón; perfilado de V1 aproximado ("casi todo el tiempo está en el ciclo"). |
| **En desarrollo (2.75)** | Descripciones narrativas ("usamos `parallel for`") sin fragmentos ni razones; V1 sin perfilado. |
| **Insuficiente (1.0)** | Falta una versión, o el texto describe código distinto del que está en el repositorio. |

### R4 · Metodología de medición (4 puntos)

| Nivel | Evidencia |
|---|---|
| **Ejemplar (4.0)** | Hardware completo de CPU (modelo, núcleos físicos y lógicos, RAM, SO) y de GPU (modelo, memoria, driver, **fecha** de la sesión de Colab/Kaggle). Versiones de compiladores y banderas. Protocolo explícito: calentamiento, número de repeticiones, mediana con mín/máx, qué región se cronometra y con qué reloj. Tamaños y semillas. Los comandos exactos que reproducen cada tabla. La predicción previa, citada de la bitácora con fecha. |
| **Competente (3.2)** | Completo salvo un elemento (p. ej. el reloj usado o la fecha de la GPU). |
| **En desarrollo (2.2)** | Hardware genérico ("laptop con i5"), sin banderas, o protocolo descrito como "se midió varias veces". |
| **Insuficiente (0.8)** | Sin sección o sin hardware. |

### R5 · Resultados: tablas y gráficas (5 puntos)

| Nivel | Evidencia |
|---|---|
| **Ejemplar (5.0)** | Tabla 1 (V1 y V2 por hilos: mediana, mín, máx, *speedup*, eficiencia, Karp–Flatt) y Tabla 2 (V3 con y sin transferencias, *speedup* contra la V1 **de la misma máquina**). Figura 1: *speedup* vs hilos con la línea ideal `S = p` y barras mín–máx. Números idénticos a `resultados/*.csv`. Ejes con unidades. Cada tabla declara `n` y semilla. Si hay *speedup* superlineal, está marcado. |
| **Competente (4.0)** | Tablas y figura completas; falta Karp–Flatt o las barras; o una unidad en un eje. |
| **En desarrollo (2.75)** | Falta la línea ideal; V3 sin una de las dos mediciones; o algún número que no coincide con el CSV. |
| **Insuficiente (1.0)** | Sin tablas o sin gráficas; o resultados que no corresponden a los CSV del repositorio. |

### R6 · Análisis (5 puntos)

| Nivel | Evidencia |
|---|---|
| **Ejemplar (5.0)** | *Speedup* máximo según Amdahl calculado con la fracción secuencial **medida** en V1 (sección 4) y comparado con el obtenido. Tendencia de Karp–Flatt con `p` interpretada (si crece, hay sobrecarga creciente: ¿de qué?). Argumento de memoria vs cómputo (intensidad aritmética estimada o un experimento) que explica dónde deja de escalar V2. En V3, porcentaje del tiempo total que son transferencias y qué implica para el tamaño del problema a partir del cual la GPU conviene. Comparación explícita predicción vs resultado y explicación de la diferencia. Superlineal explicado (caché) si ocurrió. |
| **Competente (4.0)** | Amdahl y Karp–Flatt calculados e interpretados; memoria vs cómputo o transferencias tratados solo de forma cualitativa. |
| **En desarrollo (2.75)** | Descripción de las curvas sin modelo ("sube hasta 4 hilos y luego baja"); Amdahl con una fracción "estimada" sin medir o medida en líneas de código (idea errónea 2); transferencias no discutidas. |
| **Insuficiente (1.0)** | Sin análisis, o conclusiones que contradicen los datos. |

### R7 · Bitácora, reparto de trabajo, declaración de IA y referencias (3 puntos)

| Nivel | Evidencia |
|---|---|
| **Ejemplar (3.0)** | Entre 3 y 5 entradas de bitácora seleccionadas de `bitacora.md`, cada una con qué falló, cómo se detectó, causa, cambio y aprendizaje; "qué no entendemos todavía" escrito. Reparto por integrante (archivos y secciones) consistente con `git shortlog`. Declaración de IA con las cuatro líneas de la política, incluida "qué nos dijo la IA que resultó estar mal" con un ejemplo concreto. Referencias a documentación oficial (especificación de OpenMP, guía de programación de CUDA, documentación de Numba/CuPy si aplica, fuente de los datos), citadas en el texto. |
| **Competente (2.4)** | Todo presente; una entrada de bitácora genérica, o una referencia que no se cita en el texto. |
| **En desarrollo (1.65)** | Falta una de las cuatro partes; la declaración de IA omite la última línea; o el reparto no coincide con los *commits* y no se explica. |
| **Insuficiente (0.6)** | Faltan dos o más partes, o no hay declaración de IA (se pregunta en la defensa). |

## 4. Reglas que modifican la calificación

| Situación | Efecto |
|---|---|
| PDF entregado después del lunes 7 de diciembre 10:30 y hasta el jueves 10 de diciembre 10:30 | Máximo 80 % de los 30 puntos |
| Más de 12 páginas | R1 Insuficiente; se califica solo lo que está en las primeras 12 páginas |
| Tablas o gráficas que no coinciden con `resultados/*.csv` | R5 Insuficiente; también afecta C4 de la rúbrica de código |
| Texto generado por IA sin revisar (contradicciones con el código, afirmaciones sobre hardware que no se usó, citas inexistentes) | R-criterio afectado Insuficiente y preguntas dirigidas en la defensa |
| Reporte que describe un código distinto del repositorio | R3 Insuficiente y C5 Insuficiente |

## 5. Hoja de calificación (la llena el profesor; una por equipo)

| Equipo: `cp-6bm1-equipo__` | Páginas: `__` | Fecha de revisión: `__/12/2026` |
|---|---|---|

| Criterio | Nivel | Puntos | Evidencia observada (página, tabla, figura) |
|---|---|---:|---|
| R1 Estructura y resumen | | /3 | |
| R2 Problema, datos, Foster | | /5 | |
| R3 V1, V2, V3 | | /5 | |
| R4 Metodología | | /4 | |
| R5 Resultados | | /5 | |
| R6 Análisis | | /5 | |
| R7 Bitácora, reparto, IA, referencias | | /3 | |
| **Total** | | **/30** | |
| Ajustes de §4 | | | |
| Retroalimentación (3 líneas) | | | |
