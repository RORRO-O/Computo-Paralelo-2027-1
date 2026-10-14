# Rúbrica de la defensa oral · 15 puntos del proyecto

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Defensa oral · jueves 10 de diciembre de 2026, 10:30–12:00 (y lunes 14 de diciembre, 10:30–12:00, si el profesor elige la opción a de `logistica-defensa.md`) · 15 de los 100 puntos del proyecto · ajusta la calificación individual · versión 1.0 · 14 de octubre de 2026

## 1. Cómo se aplica

1. Se evalúa lo que ocurre en la sesión: los 12 minutos de exposición con demo y las preguntas individuales
   (`guion-defensa.md`). El material de referencia es la etiqueta `entrega-final` del repositorio del equipo; lo que se
   diga y no esté ahí no cuenta, y lo que contradiga al repositorio baja el criterio correspondiente.
2. Rúbrica de **100 puntos** en cuatro criterios; **puntos del proyecto = puntos de la rúbrica × 0.15** (misma mecánica
   que H2). Niveles: Ejemplar = 100 % del peso · Competente = 80 % · En desarrollo = 55 % · Insuficiente = 20 % · criterio
   ausente = 0. Cada criterio se ubica en **un** nivel según la evidencia observable de §3.
3. Los criterios D1, D2 y D3 son del **equipo**. El criterio D4 se asigna **por integrante** a partir de sus dos respuestas
   individuales (§3.4). Por eso la defensa produce una calificación distinta para cada integrante.
4. Además de D4, dos respuestas individuales pueden activar el **ajuste individual del proyecto** de §4 (hasta −20 % de los
   100 puntos del proyecto de esa persona). Es la regla de la "prueba de propiedad" (`docs/metodo/05-politica-ia.md`) aplicada
   con números; está anunciada desde `proyecto/README.md` §6.
5. La hoja de registro de §6 (y el *script* `scripts/calificar_defensa.py`) hacen el cálculo. La retroalimentación escrita se
   entrega en ≤ 7 días (a más tardar el jueves 17 de diciembre).

## 2. Pesos

| # | Criterio | Peso (rúbrica) | Puntos del proyecto | Ejemplar | Competente | En desarrollo | Insuficiente | Quién lo recibe |
|---|---|---:|---:|---:|---:|---:|---:|---|
| D1 | Claridad y rigor técnico de la exposición (problema, diseño, decisiones, manejo del tiempo) | 25 | 3.75 | 3.75 | 3.00 | 2.06 | 0.75 | Equipo |
| D2 | Resultados y análisis honesto (V2, V3, qué falló, qué no se entiende) | 25 | 3.75 | 3.75 | 3.00 | 2.06 | 0.75 | Equipo |
| D3 | Demo en vivo desde el clon de `entrega-final` | 20 | 3.00 | 3.00 | 2.40 | 1.65 | 0.60 | Equipo |
| D4 | Respuestas individuales (2 preguntas por integrante) | 30 | 4.50 | 4.50 | 3.60 | 2.48 | 0.90 | **Cada integrante** |
| | **Total** | **100** | **15.00** | 15.00 | 12.00 | 8.25 | 3.00 | |

Suma de pesos: 25 + 25 + 20 + 30 = **100**. Suma de puntos del proyecto: 3.75 + 3.75 + 3.00 + 4.50 = **15.00**.

| Puntos de la rúbrica | 100 | 90 | 80 | 70 | 60 | 50 | 40 |
|---|---|---|---|---|---|---|---|
| Puntos del proyecto (× 0.15) | 15.00 | 13.50 | 12.00 | 10.50 | 9.00 | 7.50 | 6.00 |

## 3. Niveles por criterio (evidencia observable)

### 3.1 D1 · Claridad y rigor técnico de la exposición (25)

Cubre los bloques 1 y 2 del guion (minutos 0:00–4:00) y la conducción de los 12 minutos.

| Nivel | Evidencia |
|---|---|
| **Ejemplar (25)** | El problema queda dicho en ≤ 1 minuto con entrada (origen, `n`, semilla), salida, dependencia que queda y `T(1)` con su CPU. Las cuatro etapas de Foster se explican **sobre este problema** con diagrama propio y tabla tarea → datos → dependencias; el mapeo distingue hilos de CPU (V2) de bloques e hilos CUDA (V3) y dice qué cambió. **Dos decisiones** con alternativas medidas: opción elegida, medianas en pantalla, costo de la descartada en términos del modelo (costo por *chunk*, contención, orden de redondeo, ocupación). Un fragmento de ≤ 15 líneas por versión paralela, explicado línea por línea, que coincide con el repositorio. Términos usados con precisión (*speedup* ≠ eficiencia; carrera ≠ resultado distinto por redondeo; bloque ≠ *warp*). Termina entre 11:30 y 12:00; todos los integrantes hablan ≥ 2 minutos; ≤ 8 diapositivas legibles |
| **Competente (20)** | Todo lo anterior presente, con una de estas faltas: una decisión se enuncia con su razón pero sin las medianas en pantalla; el diagrama es correcto pero genérico; un término mal usado y corregido en el momento; termina entre 11:00 y 11:30 o se corta en 12:00 con el bloque 5 completo |
| **En desarrollo (13.75)** | Foster descrito en abstracto (definiciones) con poca conexión al problema; "aglomerar" entendido como juntar todo en un hilo (idea errónea 28); decisiones sin alternativas ("usamos `dynamic` porque es mejor"); se lee de la diapositiva o del papel; un integrante habla menos de 2 minutos; el profesor corta a los 12:00 sin que se haya llegado a la demo |
| **Insuficiente (5)** | La exposición describe un diseño o un código distinto del que está en `entrega-final`; no hay diseño; habla un solo integrante; o faltan dos bloques del guion |

### 3.2 D2 · Resultados y análisis honesto (25)

Cubre los bloques 3 y 4 del guion (minutos 4:00–10:00).

| Nivel | Evidencia |
|---|---|
| **Ejemplar (25)** | Figura 1 con línea ideal `S = p`, ejes con unidades y barras mín–máx; Tabla 1 con `T(1)` = V1 (y la fila de V2 con 1 hilo aparte), `S(p)`, `E(p)` y `f(p)` de Karp–Flatt para cada `p`; tendencia de `f` interpretada (constante → Amdahl; crece → sobrecarga creciente, de qué). *Speedup* máximo de Amdahl con la fracción secuencial **medida** en V1 comparado con el obtenido. Dónde deja de escalar V2 y **una causa verificable** apoyada en un experimento o en un número (núcleos físicos vs lógicos, ancho de banda, sincronización, falso compartido). Tabla 2 de V3 sin y con transferencias contra la V1 de la **misma máquina**, con modelo de GPU y fecha; porcentaje de transferencias y `n` a partir del cual conviene la GPU. Predicción previa (bitácora, fecha) vs resultado. Lo que no saben explicar se dice como tal. Bloque 4: ≥ 2 entradas de bitácora con herramienta de detección, causa y prueba agregada; una medición descartada con su razón; ≥ 2 preguntas concretas en "qué no entendemos todavía" con el experimento que las respondería; "qué nos dijo la IA que resultó estar mal" con un ejemplo concreto. **Todos los números están en `resultados/*.csv`** |
| **Competente (20)** | Todo presente, con una de estas faltas: la causa de dónde deja de escalar es plausible pero sin experimento ni número; las transferencias de V3 se tratan solo de forma cualitativa; falta mín–máx o la fila de V2 con 1 hilo; una de las entradas de bitácora es genérica; "qué no entendemos" tiene una sola pregunta concreta |
| **En desarrollo (13.75)** | Se describen las curvas sin modelo ("sube hasta 4 y luego baja"); Amdahl con fracción estimada en líneas de código (idea errónea 2) o no calculado; *speedup* superlineal sin explicación; V3 presentada solo con o solo sin transferencias, o comparada con la V1 de otra máquina sin decirlo; bloque 4 reducido a errores de compilación; sin "qué no entendemos todavía"; sin la línea de la IA |
| **Insuficiente (5)** | Números que no están en los CSV del repositorio; afirmaciones contradichas por su propia tabla; se oculta que V3 no pasa las pruebas o que V2 no escala; *speedup* calculado contra V2 con 1 hilo sin decirlo; sin análisis |

### 3.3 D3 · Demo en vivo (20)

Cubre el bloque 5 del guion (minutos 10:00–12:00). La teclea el integrante que el profesor designa al minuto 10.

| Nivel | Evidencia |
|---|---|
| **Ejemplar (20)** | Clon limpio: `git describe --tags --exact-match` imprime `entrega-final` y `git status --short` no imprime nada. `make test` termina con código 0 y muestra `PASS` de V2 (y de V3 si hay GPU local) contra V1 en ≤ 40 s. V1 y V2 corren con 1 hilo y con el número de núcleos físicos al tamaño de demo; `checksum`/`RESULTADO` iguales; los tiempos tienen la misma forma que la Tabla 1 y el equipo lo señala. El *notebook* de V3 ejecutado se muestra en GitHub con la salida de `nvidia-smi`, la celda `PASS v3 == v1` y la de medición. Todo en ≤ 2 minutos, sin intervención de otro integrante |
| **Competente (16)** | Todo corre, con una de estas faltas: un tropiezo resuelto en < 30 s (ruta, variable de entorno); los tiempos se muestran sin compararlos con la tabla; no se muestra el *notebook* pero está ejecutado en el repositorio; el integrante designado necesita que otro le dicte un comando |
| **En desarrollo (11)** | La demo corre desde la carpeta de trabajo o desde un *commit* posterior a la etiqueta; `make test` falla y el equipo explica por qué; solo corre V1; el *notebook* no está ejecutado; o la demo en vivo falló y se mostró el **video del plan B** completo (tope de este nivel, salvo falla de la sala: §4) |
| **Insuficiente (4)** | Nada corre y no hay video; lo que corre no corresponde al repositorio (otra carpeta, otro código); `checksum` distinto entre V1 y V2 sin explicación; o el equipo se niega a que el integrante designado teclee |

### 3.4 D4 · Respuestas individuales (30; por integrante)

Cada integrante responde **dos preguntas** sin ayuda (`guion-defensa.md` §4): la pregunta 1 sobre la parte que firmó en el
reparto; la pregunta 2 del tema sorteado para su posición. Cada respuesta se ubica en un nivel con esta tabla; **D4 de la
persona = 30 × promedio de los dos factores** (Ejemplar 1.00 · Competente 0.80 · En desarrollo 0.55 · Insuficiente 0.20 ·
sin respuesta 0).

| Nivel de la respuesta | Evidencia |
|---|---|
| **Ejemplar (1.00)** | Responde sola, en ≤ 40 s (≤ 30 s en formato corto), nombrando el elemento concreto (línea, variable, `#pragma`, *kernel*, fila de la tabla): qué hace, por qué está ahí y qué pasaría si se quita o cambia. Cuando aplica, usa los números de sus propias tablas (`T(1)`, `S(4)`, `f(4)`, % de transferencias). Si hay algo que no sabe, lo dice y propone cómo averiguarlo, y la propuesta es correcta |
| **Competente (0.80)** | Responde correctamente después de la única reformulación del profesor, o con una imprecisión menor que corrige sola (p. ej. confunde eficiencia con *speedup* y lo nota) |
| **En desarrollo (0.55)** | Respuesta parcial: dice qué hace el código pero no por qué, o da el número sin interpretarlo, o describe el efecto de quitar la línea de forma vaga ("saldría mal"); necesita una pista para llegar |
| **Insuficiente (0.20)** | No puede decir qué hace la línea, el `#pragma` o el *kernel* que firmó; contradice el código que está en pantalla; describe código que no está en el repositorio; atribuye la línea a otro integrante o a "la IA" sin poder explicarla; responde con generalidades ("eso paraleliza"); no responde; o consulta teléfono, notas o a un compañero |

Tabla de D4 por combinación de niveles (puntos de la rúbrica → puntos del proyecto):

| Respuesta 1 \ Respuesta 2 | Ejemplar | Competente | En desarrollo | Insuficiente |
|---|---|---|---|---|
| **Ejemplar** | 30.00 → 4.50 | 27.00 → 4.05 | 23.25 → 3.49 | 18.00 → 2.70 |
| **Competente** | 27.00 → 4.05 | 24.00 → 3.60 | 20.25 → 3.04 | 15.00 → 2.25 |
| **En desarrollo** | 23.25 → 3.49 | 20.25 → 3.04 | 16.50 → 2.48 | 11.25 → 1.69 |
| **Insuficiente** | 18.00 → 2.70 | 15.00 → 2.25 | 11.25 → 1.69 | 6.00 → 0.90 |

## 4. Reglas que modifican la calificación

### 4.1 Ajuste individual del proyecto por desconocimiento del código propio

| Respuestas individuales en nivel **Insuficiente** | Efecto sobre los **100 puntos del proyecto** de esa persona |
|---|---|
| 0 | Sin ajuste (factor 1.00) |
| 1 | **−10 %** (factor 0.90) |
| 2 | **−20 %** (factor 0.80) |

- "Código propio" es el repositorio del equipo: la prueba de propiedad exige que **cualquier** integrante explique
  **cualquier** línea (`docs/metodo/05-politica-ia.md`). La pregunta 1 se hace sobre la parte firmada precisamente para que
  nadie sea evaluado primero sobre lo que no escribió.
- Una respuesta En desarrollo **no** activa el ajuste; solo baja D4. El ajuste castiga el desconocimiento, no los nervios:
  por eso existe la reformulación única y por eso la pregunta 1 es sobre lo firmado.
- Orden de cálculo, por integrante: (1) H2 (15) + repositorio (40, con C6 ya asignado por integrante según
  `proyecto/entrega-final/rubrica-codigo.md` §4) + reporte (30) + defensa (15, con D4 de esa persona) = puntos del proyecto;
  (2) × factor. Ejemplo: 13.5 + 34.0 + 25.5 + 13.2 = 86.2 puntos; con una respuesta Insuficiente → 86.2 × 0.90 = 77.58.
- El ajuste es la aplicación numérica de la regla "una respuesta que muestre desconocimiento del código propio baja la
  calificación individual del proyecto hasta en 20 %" (`proyecto/README.md` §6, `planeacion/mapa-evaluacion.md`, reglas
  transversales). No hay otros ajustes individuales no escritos.

### 4.2 Otras situaciones

| Situación | Efecto |
|---|---|
| El equipo se pasa de 12:00 | El profesor corta y pasa a las preguntas. Lo no mostrado no se evalúa; D1 baja según §3.1 |
| La demo falla por causa del equipo y se muestra el video del plan B (≤ 3 min, grabado antes, `logistica-defensa.md` §8) | D3 máximo **En desarrollo** si el video muestra clon con etiqueta, `make test`, 1 vs 4 hilos y *notebook*; Insuficiente si el video no muestra eso o no hay video |
| La demo falla por causa de la sala (proyector, corriente, máquina del salón) | Se repite al final de la sesión o el martes 15 de diciembre 08:30, sin penalización; D3 se evalúa con la repetición |
| El integrante designado para la demo no puede teclearla y otro lo sustituye | D3 baja un nivel; cuenta como una respuesta Insuficiente del integrante designado para efectos de §4.1 solo si además no puede explicar qué hace cada comando |
| Un integrante falta **con justificante institucional** | Sus dos preguntas se hacen el martes 15 de diciembre, 08:30 (sesión de reserva), sin tope; D1–D3 son los del equipo |
| Un integrante falta **sin justificante** | D4 = 0 para esa persona. Si solicita responder el martes 15 de diciembre, D4 tiene tope de 80 % (regla transversal de 72 h). No se aplica el factor de §4.1: no hubo respuesta que mostrara desconocimiento |
| El equipo completo falta sin justificante | 0 en los 15 puntos; con justificante, defensa el martes 15 de diciembre 08:30 |
| Uso de teléfono, notas o asistente de IA durante las preguntas | La respuesta en curso queda Insuficiente (cuenta para §4.1) y se reporta según `docs/metodo/04-evaluacion.md` §6 |
| Un integrante responde por otro o sopla | La respuesta se califica como estaba antes de la intervención; quien intervino pierde su reformulación |
| El repositorio cambió después de la etiqueta y la demo usa el nuevo código | D3 máximo En desarrollo; D1 y D2 se evalúan contra la etiqueta. Si la etiqueta se creó después del lunes 7 de diciembre 10:30, aplica además la entrega tardía de `proyecto/entrega-final/README.md` §2 |
| Respuesta individual Insuficiente sobre una línea que el equipo entregó | Además de §4.1, aplica C6 Insuficiente para esa persona en `rubrica-codigo.md` §4 (ya está anunciado ahí). El factor de §4.1 se aplica después de ese cambio en C6, no antes |
| Código idéntico entre equipos descubierto en la defensa | `docs/metodo/04-evaluacion.md` §6: 0 en la entrega para los involucrados y reporte según reglamento |

## 5. Lo que mira el profesor durante la sesión (guía rápida)

| Minuto | Qué anota en la hoja de §6 |
|---|---|
| 0–4 | ¿`n`, semilla, `T(1)`? ¿Diagrama propio? ¿Tabla tarea → datos? ¿Dos decisiones con medianas? ¿Fragmentos coinciden con el repositorio? → nivel D1 provisional |
| 4–10 | ¿Línea ideal y mín–máx? ¿`T(1)` = V1? ¿`f(p)` y su tendencia? ¿Amdahl con fracción medida? ¿Causa verificable? ¿V3 sin y con transferencias, misma máquina? ¿Predicción vs resultado? ¿Bitácora con detección y causa? ¿"Qué no entendemos"? ¿IA que se equivocó? Abrir `resultados/*.csv` y verificar dos números → nivel D2 |
| 10–12 | Designar quién teclea. ¿Etiqueta? ¿`status` limpio? ¿`make test` = 0? ¿1 vs `p` hilos, `checksum` igual? ¿*Notebook*? → nivel D3 |
| Preguntas | Por integrante: pregunta 1 (línea de la parte firmada), pregunta 2 (tema sorteado). Anotar ID del banco o descripción, nivel, y si hubo reformulación → D4 y conteo de Insuficientes |
| Cierre | Tiempo total; observaciones de 3 líneas para la retroalimentación escrita (lo mejor, lo que falta, qué cambiaría la calificación) |

## 6. Hoja de registro (una por equipo; la llena el profesor)

Versión imprimible. El formato CSV equivalente y el cálculo automático están en `logistica-defensa.md` §7 y
`scripts/calificar_defensa.py`.

| Equipo: `cp-6bm1-equipo__` | Fecha: `__/12/2026` | Posición en el orden: `__` | Inicio: `__:__` | Fin de exposición: `__:__` | Fin de preguntas: `__:__` |
|---|---|---|---|---|---|

**Criterios del equipo**

| Criterio | Nivel (E/C/D/I/A) | Puntos de rúbrica | Puntos del proyecto | Evidencia observada (diapositiva, archivo, comando, número) |
|---|---|---:|---:|---|
| D1 Claridad y rigor técnico (25) | | | /3.75 | |
| D2 Resultados y análisis honesto (25) | | | /3.75 | |
| D3 Demo en vivo (20) | | | /3.00 | |
| Demo: [ ] en vivo completa [ ] en vivo con tropiezo [ ] video plan B [ ] falla de la sala (repetir) | | | | Integrante que tecleó: `________` |

**Criterio individual (una fila por integrante; sin nombres en documentos públicos: usuario de GitHub)**

| Integrante (usuario de GitHub) | Pregunta 1 (línea de la parte firmada: archivo:línea) | Nivel P1 | Reformulada (sí/no) | Pregunta 2 (tema sorteado · ID del banco) | Nivel P2 | Reformulada (sí/no) | D4 (rúbrica /30) | D4 (proyecto /4.50) | Insuficientes (0/1/2) | Factor (1.00/0.90/0.80) |
|---|---|---|---|---|---|---|---:|---:|---:|---:|
| | | | | | | | | | | |
| | | | | | | | | | | |
| | | | | | | | | | | |

**Totales por integrante**

| Integrante | D1+D2+D3 (equipo, /10.50) | D4 (/4.50) | Defensa (/15) | H2 (/15) | Repositorio (/40, con C6 individual) | Reporte (/30) | Suma (/100) | × factor | **Proyecto individual (/100)** |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| | | | | | | | | | |
| | | | | | | | | | |
| | | | | | | | | | |

**Retroalimentación para el equipo (3 líneas):** lo mejor · lo que faltó · qué habría cambiado la calificación.

**Observaciones por integrante (1 línea cada uno):**
