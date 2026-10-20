# Plantilla de práctica de laboratorio

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Plantilla · versión 1.0

Una práctica es la pieza donde el andamiaje se desvanece: empieza con código que funciona, pide completar,
luego pide diseñar, y termina con una medición honesta. Dura dos sesiones de laboratorio más trabajo en casa
(estimado total: 6–8 horas por integrante). Se entrega por equipo (2–3 integrantes) con responsabilidad individual.

## 1. Secciones obligatorias de `README.md`

### Portada
Título, unidad, fechas (publicación, sesiones de laboratorio, fecha límite con hora), ponderación según
`planeacion/mapa-evaluacion.md`, entregables en una línea, tiempo estimado.

### Objetivos
Tres a cinco, con verbo observable. Al menos uno de **medir e interpretar** rendimiento y uno de **explicar**
una decisión de diseño.

### Pre-laboratorio (individual, 20 min, se entrega antes del Laboratorio 1)
- 4 preguntas de recuperación sobre lo necesario para la práctica.
- Lectura de `notas-estudiante.md` de las sesiones indicadas.
- **Predicción**: "Antes de correr nada, ¿qué *speedup* esperas con 4 hilos y por qué?" (se compara al final).
- Se entrega en el repositorio del equipo (`practicas/Pn/prelab/`, un archivo por integrante) antes de la hora
  del Laboratorio 1, falte o no el estudiante; la pregunta 1 de la recuperación de esa sesión lo verifica.
- En P6 incluye, obligatorio: "Antes del martes 24 de noviembre, verifica que obtienes GPU en Colab y en Kaggle
  (verificación telefónica hecha), anota el modelo asignado y reporta ese día si no pudiste."

### Parte A · Guiada (código completo que se ejecuta, se lee y se modifica)
Pasos numerados. Cada paso dice qué correr, qué observar y qué anotar. Incluye al menos una tabla de rastreo
o predicción (PRIMM). Termina con una verificación automática (`make test`). Un constructo que aparece por primera
vez en el Laboratorio 1 (tareas en P4, colectivas en P5, memoria compartida y *tiling* en P6) entra aquí como
código completo para leer y predecir, después del ejemplo resuelto corto con que abre la sesión
(`02-plantilla-sesion.md`, §2.1); nunca como `TODO` en la Parte B de esa misma sesión.

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
- Repositorio del equipo, **privado**, con el profesor como colaborador (el equipo decide si lo hace público al
  terminar el semestre): carpeta `practicas/Pn/` con código, `Makefile`, `tests/`, `resultados/` (CSV + PNG),
  `REPORTE.md` (≤ 3 páginas: decisiones, tabla, gráfica, interpretación, reflexión, bitácora de errores,
  declaración de uso de IA, reparto de trabajo).
- Historial de *commits* con participación de cada integrante.
- Demostración en vivo en el Laboratorio 2 (mini-defensa). Quien no estuvo en su mini-defensa la repone en el
  siguiente laboratorio; si no lo hay antes del cierre o no puede, graba un video no listado de ≤ 3 minutos en el
  que explica dos fragmentos de su código que elige el profesor, a más tardar el martes 15 de diciembre, 08:30
  (`04-evaluacion.md`, §5).

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
| Medición | 20 | Tabla con mediana de ≥ 5 repeticiones para la lista de hilos/procesos del protocolo (1, 2, 4, 8 según hardware); gráfica con ejes rotulados y unidades; señala el punto donde la eficiencia cae de 50 % y da la causa con un dato (fracción secuencial medida, ancho de banda o conteo de sincronizaciones) | Tabla y gráfica completas según el protocolo; la caída de eficiencia se describe sin el dato que la explica | Faltan repeticiones, tamaños de la lista o la gráfica | Sin mediciones, o no reproducibles con el protocolo |
| Interpretación y reflexión | 20 | Conecta resultados con Amdahl/costos de comunicación/memoria; compara con su predicción | Explica resultados correctamente | Describe sin explicar | Ausente o incorrecta |
| Proceso e integridad | 15 | Cada integrante tiene ≥ 3 *commits* con cambios de código; bitácora con ≥ 3 entradas (síntoma, causa, cómo se detectó); declaración de IA con las cuatro líneas y la verificación descrita; cada integrante responde la pregunta de su parte y una sobre una función ajena | Cada integrante tiene ≥ 3 *commits* con cambios de código; bitácora con ≥ 2 entradas; declaración de IA con las cuatro líneas; cada integrante responde la pregunta de su parte | Algún integrante con < 3 *commits* de código sin explicación en el reparto, o bitácora con 1 entrada, o declaración incompleta | Un integrante no explica la línea que firmó (prueba de propiedad, `05`), o no hay bitácora ni declaración |

**Responsabilidad individual.** Las preguntas individuales se hacen en el Laboratorio 2 (con más de 12 equipos,
la mitad en el Laboratorio 1 con lista publicada; `02` §2.1) sobre el código de ese momento: una por integrante sobre la parte que firmó; la segunda solo si la primera falla, y cuenta la mejor de
las dos. Quien lo pide responde por escrito en el momento (5 min, papel). En la primera sesión posterior a la
fecha límite, el profesor dedica 5 minutos a preguntar a un integrante al azar de 2–3 equipos (tarjetas) qué
cambió desde el laboratorio (Parte D y correcciones de la bitácora). La consecuencia es la que fija
`05-politica-ia.md`, "Prueba de propiedad": el criterio "Proceso e integridad" baja a Insuficiente **para ese
integrante**, no para el equipo. Los descriptores de la rúbrica no usan "claro", "adecuado", "sólido" ni "útil"
sin el dato que lo demuestra.

## 3. Verificación automática

`tests/run_tests.sh` compila, ejecuta con tamaños fijos y compara contra la salida de referencia (secuencial)
con tolerancia. Imprime `PASS`/`FAIL` por caso y termina con código 0 solo si todo pasa. El estudiante lo corre
antes de entregar; el profesor lo corre al calificar.

## 4. Calendario interno típico de una práctica

| Momento | Qué pasa |
|---|---|
| Publicación (jueves; lunes 23 de noviembre en P6) | README disponible; se asigna el pre-laboratorio |
| Laboratorio 1 (martes) | Pre-lab en el repositorio antes de la hora; ejemplo resuelto corto si la sesión introduce un constructo nuevo (`02` §2.1); Partes A y B |
| Entre sesiones | Parte C y mediciones |
| Laboratorio 2 (martes siguiente) | Parte D, punto de control, mini-defensas (una pregunta por integrante) |
| Fecha límite (domingo 23:59) | Entrega en el repositorio |
| Primera sesión después de la fecha límite | 5 min: un integrante al azar de 2–3 equipos explica qué cambió desde el laboratorio |
| ≤ 7 días | Retroalimentación con rúbrica, formato mínimo de `04` §3 |
