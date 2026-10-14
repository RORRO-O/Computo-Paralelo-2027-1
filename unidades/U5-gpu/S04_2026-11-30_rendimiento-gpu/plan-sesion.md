> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S04 · lunes 30 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S04 · Rendimiento en GPU: medir con eventos, transferencias, tamaño de bloque y *roofline*

Tipo: **Contenido** (estructura base de 90 min). Práctica guiada en Colab/Kaggle (cuentas listas desde la
Práctica 1); localmente solo se compila y se ensayan las gráficas.

## Objetivos (al terminar, el estudiante podrá…)

1. **Medir** el tiempo de un kernel y de sus copias H2D/D2H por separado con `cudaEvent_t`, siguiendo el protocolo
   del curso (calentamiento, 5 repeticiones, mediana, verificación), y **explicar** por qué un cronómetro de CPU
   sin sincronizar miente. (aplicar / comprender)
2. **Determinar**, a partir de una tabla de tiempos con y sin copias para varios `n`, a partir de qué tamaño
   conviene la GPU y cuándo las copias dominan. (analizar)
3. **Explicar** con *warps*, bloques residentes por SM y ocupación el resultado de un barrido de tamaño de bloque
   (por qué múltiplos de 32 y por qué 1024 no siempre gana). (analizar)
4. **Clasificar** un kernel como limitado por memoria o por cómputo con su intensidad aritmética (*roofline*
   simplificado) y **decidir** qué optimizar primero: el kernel, el camino de los datos (*pinned*, *streams*) o
   el tamaño de bloque. (evaluar)

Dónde se evalúa cada uno: 1 → CT1 y la fila verificada de *Crear*; 2 → *exit ticket* 2a–2b; 3 → *exit ticket* 1 y CT2; 4 → *exit ticket* 2c.

## Prerrequisitos y vínculo

- **Viene de:** S03 (jueves 26 de noviembre): `__syncthreads`, atómicas, reducción en árbol, divergencia,
  histograma, verificación contra CPU. S02: jerarquía de memoria, coalescencia, matmul con mosaicos. S01: modelo
  CUDA, suma de vectores, Colab. Unidad III S10 y Unidad IV S05: protocolo de medición, *speedup*/eficiencia,
  modelo latencia + tamaño/ancho de banda.
- **Va hacia:** S05 (martes 1 de diciembre, 08:30): Práctica 6 · Lab 2 (mediciones, punto de control,
  mini-defensas) y taller V3 del proyecto. La Parte D de P6 y la medición de la V3 usan exactamente este protocolo.
- **Ideas erróneas que esta sesión ataca (Anexo A):** **24** (las copias no cuentan), **26** (cualquier tamaño de
  bloque funciona igual), **1** (más hilos siempre es más rápido), **5** (medir una vez basta / con -O0).
  Dónde aparece cada una: 24 → ejemplo resuelto forma 4, CT1-C, CT3-A, exit ticket 2; 26 → CT2-C, PRIMM
  Investigar 3, exit ticket 1; 1 → CT1-A, CT2-A, predicción P4; 5 → CT1-D, CT2-A, CT3-D, calentamiento en el código.

## Materiales

- Esta carpeta: `retrieval-inicio.md`, `ejemplo-resuelto.md`, `conceptests.md`, `practica-guiada/` (con
  `notebook_colab.ipynb`), `exit-ticket.md`, `tarea-espaciada.md`.
- Proyector, cronómetro visible, tarjetas de números de lista, tarjetas A/B/C/D.
- Cuenta de Colab del profesor con el cuaderno ya abierto y la GPU asignada **antes** de las 10:30 (la asignación
  puede tardar o fallar; si no hay GPU, se proyectan las salidas esperadas del README y la práctica se hace en
  las cuentas de los estudiantes).
- Máquina del salón con `nvcc`/`gcc`/`python3` para mostrar `make test` sin GPU (opcional).

## Guion minuto a minuto

### 0–5 · Recuperación

Proyectar las 5 preguntas de `retrieval-inicio.md`. A los 4 minutos, respuestas; manos por pregunta. Umbral:
si < 60 % acierta la 1 (`__syncthreads` solo sincroniza el bloque), redibujar el árbol de reducción en 2 min. Si
falla la 5 (49 ms contra 20 ms), **no corregir**: decir "en 20 minutos lo van a ver medido".

### 5–10 · Objetivos y anclaje

Frase de anclaje (sustituir el error por el más frecuente del *exit ticket* de S03, clasificado el domingo 29;
por defecto se asume la idea 25): "El jueves varios escribieron que `__syncthreads()` sincroniza toda la GPU.
Hoy vamos a ver que incluso la CPU y la GPU no están sincronizadas salvo que lo pidamos, y que si no lo
pedimos, el cronómetro miente." Leer los 4 objetivos. Vínculo con el proyecto: "La V3 que entregan el lunes 7 de
diciembre a las 10:30 se califica con la tabla con y sin copias; hoy aprenden a producirla."

### 10–35 · Instrucción explícita I

**10–22 · Ejemplo resuelto en voz alta** (`ejemplo-resuelto.md`, cuaderno celda `!./medir_eventos`).
Pensar en voz alta: "Miro el `<<<>>>`: regresa de inmediato. Si leo el reloj aquí, ¿qué medí?" Correr la celda.
Pausas 1–5 con tarjetas de lista (una persona por pausa, 30 s cada una). Subrayar: creación de contexto, forma 1
≈ 0.01 ms contra forma 3 ≈ 0.9 ms, forma 4 ≈ 50 ms → copias 98 %. Escribir en el pizarrón los **dos números** y
el porcentaje. Mostrar la variante que falla (bloque de 2048) y `cudaGetLastError`.

**22–28 · Mini-exposición con las notas (§3, §4, §6)**, tres láminas:
1. Umbral: lanzar cuesta 5–10 µs; cruce solo kernel ≈ 2^12–2^16; con copias quizá nunca (paginable).
2. Bloque y ocupación: warps de 32; tabla de ocupación de la T4 (32 → 50 %, 64+ → 100 %); por qué 1024 no es
   automático (bloques para balancear, 64 registros por hilo, SMs ociosos con `n` chico).
3. *Roofline*: `I` = FLOP/byte; balance T4 ≈ 25; saxpy 0.17 → *memory-bound*; matmul `N/6` ideal, `T/4` con mosaicos.
   Pregunta al azar: "¿Qué hace que matmul tenga intensidad alta: más FLOP o reúso?" (reúso).

**28–35 · ConcepTest 1** (`conceptests.md`): voto → discusión → revoto → explicación. Esperado 55–65 %.
Si > 80 %, explicar en 30 s y pasar a PRIMM con 5 min de ventaja para *Investigar*.

### 35–65 · Práctica guiada PRIMM (`practica-guiada/README.md`)

**Arranque (35–37).** Parejas; conductor abre `notebook_colab.ipynb` y pide GPU; navegante lee P1–P8. "Nadie
corre la celda de `bench_gpu` sin las 8 predicciones escritas." Anunciar el cambio de roles a las 10:50.

**35–42 · Predecir.** Las 8 predicciones por escrito. El profesor recoge en voz alta tres predicciones de P3
(mejor bloque) y dos de P7 (cruce con copias) y las anota en el pizarrón para la puesta en común.

**42–52 · Ejecutar.** Secciones 3–6 del cuaderno: compilar, `medir_eventos`, `bloque 2^24`, `bloque 4096`, `umbral 256`.
Comparar con P1–P7. **10:50: cambio de roles.**

**52–60 · Investigar.** Preguntas 1–5 del README (eventos en `measure_gpu`, fracción de copias, tabla de
ocupación, crecimiento del tiempo con `n`, `nsys`). La celda de `nsys` tarda ≈ 1 min: lanzarla y seguir con la
tabla de ocupación mientras corre.

**60–65 · Modificar.** `umbral 256 ... pinned` y `pinned_streams`. Quien va adelantado: `BLOCK_SIZES` con 48 y 96.

**Lista de errores esperados y la pregunta que se hace (no la respuesta):**

| Error observado | Pregunta socrática |
|---|---|
| `nvcc: command not found` / `nvidia-smi` falla | "¿Qué tipo de entorno de ejecución dice la primera celda?" |
| `no kernel image is available` (P100 con `sm_75`) | "¿Qué capacidad de cómputo imprimió la celda 2? ¿Para cuál compilaste?" |
| Corre `bloque 4096` y concluye "la GPU es lenta" | "¿Cuánto tarda lanzar un kernel vacío? ¿Qué fracción de esos 5 µs es cómputo?" |
| Predijo 1024 "porque más hilos" y defiende que el 0.90 es ruido | "¿Cuántos bloques caben por SM con 1024? ¿Y con 256? ¿Cuántos warps residentes en cada caso?" |
| Reporta `S_kern` como "el speedup" | "¿Dónde empezaban los datos? ¿Qué dice el protocolo sobre las transferencias?" |
| Pone 50 en `BLOCK_SIZES` y no entiende el aviso | "¿Cuántos warps tiene un bloque de 50? ¿Cuántos carriles trabajan en el segundo?" |
| La primera repetición tarda el doble y la incluye | "¿Qué hace el `r = -1` del ciclo? ¿Qué pasó en esa repetición que no vuelve a pasar?" |
| Con *pinned* esperaba que el kernel fuera más rápido | "¿Qué cambió: el kernel o el camino de los datos? ¿Qué columna debería moverse?" |
| Lee `cuda_api_sum` de `nsys` como tiempo del kernel | "¿Esa tabla mide tiempo de CPU o de GPU? ¿En cuál están los kernels?" |
| Corre `bench_numba.py` con `CUDASIM` en Colab y no ve tiempos | "¿Qué dice la línea `modo =`? ¿Para qué existe el simulador?" |

### 65–75 · Puesta en común

Mostrar (sin nombres) tres hallazgos: (1) la tabla de un equipo con copias ≈ 98 % frente a su P2; (2) el barrido
de bloque de otro equipo junto a las predicciones del pizarrón: 32 peor, 128–512 empatados, 1024 igual o peor;
(3) la columna `S_total` paginable vs. *pinned*: dónde (o si) cruzó 1. **ConcepTest 2** (esperado 45–55 %).
Regla general en una frase: **"Se reportan dos números (con y sin copias); el bloque es múltiplo de 32 y lo decide el
barrido, no la intuición; un kernel sin reúso de datos es *memory-bound* y lo que manda es el ancho de banda."**

### 75–85 · Transferencia

Reto (sección **Crear** del README): rodear el kernel propio de la Práctica 6 con los cuatro eventos y producir
la primera fila del CSV con el encabezado del curso. Criterio de "listo": una fila verificada (`OK`) con `n`,
bloque, H2D, kernel, D2H, CPU y los dos *speedups*, más la intensidad aritmética del kernel escrita.
Extensión para quien termina: barrido de bloque de su kernel; `pinned_streams` con 2 y 8 *streams*; CT3.
Apoyo para quien no arranca: usar `bench_gpu.cu` como plantilla, copiando `measure_gpu` tal cual y sustituyendo
solo la línea del lanzamiento; el profesor se sienta 3 min con esa pareja.

### 85–90 · Cierre

*Exit ticket* (`exit-ticket.md`), en papel. Anuncios, con fecha: **mañana martes 1 de diciembre, 08:30, Lab 2 de
la Práctica 6** (traer la fila del CSV y el pre-mortem de la tarea); **Práctica 6 vence el domingo 6 de diciembre a
las 23:59** (15 % del 3er parcial); **entrega final del proyecto el lunes 7 de diciembre a las 10:30** (V1·V2·V3 +
reporte PDF; 70 de los 100 puntos del proyecto). Tarea espaciada: `tarea-espaciada.md`, se entrega antes del Lab 2.

## Diferenciación

- **Apoyo (quien no arranca):** hoja impresa con la tabla de ocupación medio llena (filas 32 y 64) y la tabla
  H2D/kernel/D2H con la primera fila de ejemplo; trabajar solo con `n = 2^22`; para Crear, la plantilla de
  `measure_gpu` con el lanzamiento marcado como única línea a cambiar.
- **Ampliación (quien termina):** agregar 48, 96 y 192 a `BLOCK_SIZES` y explicar 48 vs. 64 con la ocupación;
  medir `pinned_streams` con 1, 2, 4, 8 *streams* y relacionar con `asyncEngineCount`; correr `ncu --section
  SpeedOfLight` si el entorno lo permite y leer el porcentaje de ancho de banda; portar el barrido a
  `bench_numba.py` y comparar tiempos con el `.cu`.

## Evaluación formativa de la sesión

| Objetivo | Qué mira el profesor |
|---|---|
| 1 (medir con eventos) | CT1 ≥ 80 % en el revoto; en PRIMM, nadie reporta la "forma 1"; en Crear, la fila tiene H2D/kernel/D2H separados y `OK` |
| 2 (umbral y copias) | En la hoja de la pareja, la fila marcada donde `S_kern > 1` y la respuesta a P7 comparada con lo medido; exit ticket 2a–2b correctos |
| 3 (bloque y ocupación) | Tabla de ocupación llena en Investigar 3; CT2 ≥ 75 % en el revoto; exit ticket 1 menciona bloques residentes por SM |
| 4 (roofline y decisión) | Exit ticket 2c elige *pinned* con los números; en Crear, la intensidad aritmética del kernel propio está escrita y es plausible |

## Notas post-sesión

Se llenan el mismo día (10 min), con los montones del *exit ticket*:

- Error más frecuente del *exit ticket* (y % en "mal"): ___
- ConcepTest que falló y por qué (primer voto / revoto): ___
- Qué se recorta o se mueve la próxima vez que se dé esta sesión (tiempo real de PRIMM, fallos de Colab): ___
- Ajuste para la recuperación de S05 (martes 1 de diciembre): ___
