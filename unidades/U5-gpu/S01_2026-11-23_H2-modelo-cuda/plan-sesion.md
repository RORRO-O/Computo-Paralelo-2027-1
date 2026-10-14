> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S01 · lunes 23 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S01 · Recepción de H2 · Por qué GPU, SIMT y el modelo CUDA: suma de vectores en Colab

**Tipo:** Contenido (estructura base de 90 min) con recepción de H2 en un bloque de 20 min al inicio. El contenido
queda comprimido a 60 min (25–85). La recuperación (0–5) y el cierre (85–90) no se recortan.

## Objetivos (al terminar, el estudiante podrá…)

1. **Explicar** la diferencia entre una CPU orientada a latencia y una GPU orientada a rendimiento, y describir
   SIMT, *warp* y SM con los números de una T4 (nivel: comprender). Se evalúa en CT1 y *exit ticket* 1.
2. **Calcular**, dados `n` y `blockDim`, el número de bloques, el índice global de un hilo y los hilos ociosos, y
   **justificar** la guardia `if (i < n)` (nivel: aplicar). Se evalúa en PRIMM-Predecir, CT2 y *exit ticket* 2.
3. **Compilar, ejecutar y verificar** un *kernel* CUDA C en Colab/Kaggle y su espejo en Numba (con CUDASIM sin GPU),
   revisando errores con `cudaGetLastError`/`cudaDeviceSynchronize` y comparando contra la CPU (nivel: aplicar). Se
   evalúa en PRIMM-Ejecutar/Investigar y en la tabla predicho/observado.
4. **Modificar** el *kernel* a *saxpy* y **crear** un *kernel* de productos parciales con verificación en CPU
   (nivel: crear). Se evalúa en PRIMM-Modificar/Crear y en la tarea.

## Prerrequisitos y vínculo

- **Viene de:** Unidad IV S06 (jueves 19 de noviembre: cierre de MPI, taller hacia H2). Práctica 5 entregada el
  domingo 22 de noviembre, 23:59. De unidades previas se reutilizan: Flynn/SIMD (U I), *speedup*/eficiencia/Amdahl
  (U I, U III S10), reparto con redondeo hacia arriba y espacios de memoria separados (U IV).
- **Va hacia:** S02 (martes 24 de noviembre, 08:30, Lab LS4): jerarquía de memoria y *tiling* + Práctica 6 Lab 1
  (pre-lab se entrega al inicio). S03 (jueves 26): reducción en GPU (el "Crear" de hoy la deja pendiente a propósito). S04
  (lunes 30): costo de las copias (hoy solo se anota). V3 del proyecto.
- **Ideas erróneas que ataca (Anexo A):** 22 (hilo CUDA = núcleo de CPU) en CT1, notas y *exit ticket* 1; 27 (sin
  error = correcto) en PRIMM-Investigar I2/I3, CT3 y *exit ticket* 1; 26 (cualquier tamaño de bloque da igual) en el
  distractor D de CT2 y en el barrido de bloque del notebook (se retoma en S04); 1 (más hilos siempre más rápido) en
  la recuperación, pregunta 4, y en el ejercicio intercalado de la tarea.

## Materiales

- Archivos de esta carpeta. Proyector, cronómetro visible, tarjetas con números de lista.
- Laptop del profesor con: **Colab abierto y GPU ya asignada desde las 10:15** (pedirla en clase puede tardar);
  `notebook_colab.ipynb` cargado; copia local de `practica-guiada/` con `make test` pasado esa mañana (plan B si Colab
  no da GPU: todo lo de Investigar se muestra con CUDASIM).
- Para H2: lista de equipos impresa con la lista de cotejo rápida (abajo); `proyecto/hitos/H2-avance-2.md` a la
  mano para responder dudas de rúbrica (no se califica en clase).
- Hoja por estudiante: lado A recuperación, lado B *exit ticket*.
- Anotar aquí antes de empezar: error más frecuente del *exit ticket* de S06 (jueves 19 de noviembre): ________.

## Lista de cotejo rápida de recepción de H2 (registro, no rúbrica)

Un renglón por equipo, ✓/✗ por columna, ≤ 1 minuto por equipo frente a su laptop. Es un **registro de recepción**:
la calificación (15 puntos del proyecto) se hace después, fuera de clase, con la rúbrica de `proyecto/hitos/H2-avance-2.md`
(§4), clonando la etiqueta `H2` como indica su §3; retroalimentación escrita antes del lunes 30 de noviembre. Los seis
renglones son un resumen de la lista de autoevaluación de ese documento (§5), no la sustituyen.

| # | Verificación en 1 minuto |
|---|---|
| 1 | Etiqueta `H2` creada y empujada antes de las 10:30 de hoy (`git tag -a H2`); URL del repositorio anotada |
| 2 | La V2 compila con `make` sin *warnings* y `make test` pasa frente al profesor (compara contra V1 con 1/2/4/8 hilos) |
| 3 | `resultados/mediciones.csv` con el protocolo: `n` fijo declarado, filas `V1,1` y `V2,1/2/4/8`, mediana de ≥ 5, `entorno.txt` |
| 4 | `speedup.png` con la línea ideal; `T(1)` = V1, no V2 con un hilo |
| 5 | Karp–Flatt `f(p)` calculado y comparado con la predicción de Amdahl escrita en H1 (el "pre-mortem") |
| 6 | `reporte/H2.md` con "qué no entendemos todavía" (≥ 3) y "Hacia V3"; bitácora con ≥ 3 entradas nuevas; *commits* de todos |

Preguntas fijas al equipo (las dos de `H2-avance-2.md` §6, en 30 s): **"¿qué midieron?"** (deben decir `T(1)`, `S(4)` y
`f(4)` viendo su gráfica) y **"¿qué no entienden todavía?"** (leen una de su lista). Se anota en una palabra si `T(1)`
es el mejor secuencial / la versión paralela con un hilo / no saben.

**Pregunta individual (criterio 5 de la rúbrica).** No cabe en 20 minutos con 12–15 equipos (la rúbrica prevé 3 min
por equipo y ofrece tres opciones en su §8). Este plan sigue la **opción A**: en clase solo la ronda corta; la
pregunta individual del banco de §6 se hace **a un integrante por equipo mientras el profesor circula en PRIMM
(50–70)**, con la tarjeta al azar y 30 s por persona, y las que falten se completan al inicio de la S02 (martes 24
de noviembre, Lab LS4). Si se prefiere otra opción, se anuncia el jueves 19 de noviembre, como pide `H2-avance-2.md` §8.

## Guion minuto a minuto

### 0–5 · Recuperación

Proyectar `retrieval-inicio.md` (5 preguntas). Minuto 4: respuestas; manos por pregunta; anotar el conteo de la
pregunta 1 (`MPI_Send` cruzados). **Si < 60 % acierta la 1:** en el anclaje se dedica un minuto a la semántica de
bloqueo (idea 17) con el dibujo de dos *buffers*. La pregunta 5 (2560 "núcleos") se deja abierta: "en 30 minutos la
contestamos con números".

### 5–25 · Recepción de H2 (20 min)

- **5–7.** Instrucciones: "Cada equipo abre su repositorio en la V2 y deja `make test` corriendo. Paso por cada mesa
  un minuto. Mientras esperan: (a) intercambien laptop con el equipo vecino y apliquen la lista de cotejo de seis
  puntos al otro equipo; (b) abran Colab, cambien el tipo de entorno a GPU T4 y dejen que se asigne" (así la GPU ya
  está lista a las 10:55).
- **7–22.** Ronda por equipos (12–15 equipos × ≤ 1 min): marcar la lista; una pregunta fija; sin discutir la
  calificación. Si un equipo no tiene nada que mostrar, se anota "no presentado" y se le recuerda la política de
  entrega tardía (≤ 72 h, máximo 80 %).
- **22–25.** Cierre de recepción: "Lo entregado se califica con la rúbrica de H2 que conocen, sobre la etiqueta `H2`;
  retroalimentación antes del lunes 30 de noviembre. Dos observaciones generales que vi:" (p. ej., `T(1)` tomado de
  la versión paralela con un hilo; sin `entorno.txt`). Enlace: "la V3 porta exactamente esa V2 a GPU; hoy empieza; la
  sección 'Hacia V3' de su `reporte/H2.md` es el plan de lo que van a escribir el jueves 26 y el martes 1 de diciembre".

### 25–30 · Objetivos y anclaje

Frase de conexión: "El error más frecuente del *exit ticket* del jueves fue ________; hoy lo vamos a reencontrar en
otra forma: en GPU también hay dos memorias separadas y todo cruce es una copia explícita". Proyectar los cuatro
objetivos. Ubicar en el proyecto: "V3 = el *kernel* de su cuello de botella; hoy escriben el primero".

### 30–50 · Instrucción explícita I

**30–37 · CPU vs. GPU, SIMT, warps, SM** (pizarrón, pensar en voz alta).

1. Tabla de dos columnas: latencia vs. rendimiento (de `notas-estudiante.md` §1). Números de la T4: 40 SM × 64
   unidades FP32 = 2560 "núcleos"; 320 GB/s; laptop: 4 núcleos, ~20–40 GB/s.
2. Responder la pregunta 5 de la recuperación: "un núcleo CUDA no decide nada; decide el *warp*". Dibujar un SM con
   32 *warps* residentes y un planificador que cambia de *warp* cuando uno espera memoria. "Por eso lanzar 16
   millones de hilos no es un error: es el plan".
3. Puente con Flynn: SIMD (pregunta 3) → SIMT: "ustedes escriben código escalar para un hilo; el *hardware* lo
   agrupa de 32 en 32".

**37–45 · Ejemplo resuelto** (`ejemplo-resuelto.md`, código proyectado, pausas en voz alta).

- Plan en 3 líneas. Recorrer el código en este orden: `__global__` (pausa 1), fórmula del índice (pausa 2: "si dos
  bloques tienen un hilo 3, ¿qué calcula cada uno?"), `grid` con redondeo (pausa 4: "¿cuántos bloques para 1000?"),
  guardia (pausa 3), copias (pausa 5: "es MPI otra vez: dos memorias"), dos verificaciones de error (pausa 6),
  comparación con la CPU (pausa 7).
- Mostrar la salida real de CUDASIM y de `vector_add_cpu` (18 ms, 2^24) y la esperada de la T4 (≈ 1 ms el *kernel*,
  30–60 ms con copias). Decir explícitamente: "la última línea se las debo hasta el 30 de noviembre; hoy solo anoten
  que con copias la GPU perdió".
- Variante que falla A (`grid = 3`): proyectar la salida real `max_abs_err=18 verificacion=FALLA` **sin error de
  CUDA**. "Esta es la idea 27; la van a ver en sus manos en diez minutos".

**45–50 · ConcepTest 1** (`conceptests.md`, CT1, idea 22). Esperado ~45 % en el primer voto. Voto → parejas
(pregunta guía: "si solo hubiera 2560 hilos a la vez, ¿cómo se repartirían 65 536 bloques?") → revoto → cierre:
"la unidad es el *warp*; un SM de T4 tiene hasta 32 *warps* residentes; los bloques entran en oleadas". Si > 80 %
en el primer voto, saltar la discusión y ganar 3 min para PRIMM.

### 50–70 · Práctica guiada PRIMM (`practica-guiada/README.md`)

Parejas: conductor/navegante; **cambio de rol al minuto 60**. Colab debe tener GPU desde la recepción de H2; quien
no la tenga trabaja con CUDASIM en la laptop y comparte pantalla con otra pareja para la parte de GPU. Mientras
circula, el profesor hace la pregunta individual de H2 (banco de `H2-avance-2.md` §6) a un integrante por equipo.

- **50–54 · Predecir** (P1–P5 por escrito, sin ejecutar). El profesor circula y lee predicciones; no corrige.
- **54–60 · Ejecutar.** Notebook: `!nvidia-smi` → `%%writefile` → `nvcc` → `index_probe 10 4` → `vector_add 1000
  256` → `vector_add_cpu` y `vector_add` (2^24). En laptop: `make test`. Llenar la columna "Observado".
- **60–66 · Investigar.** I1 tabla de rastreo (`n = 10`, `block = 4`); I2 `grid = 3`; I3 sin guardia (CUDASIM
  primero, luego GPU con `-DSIN_GUARDIA`); I4.1 `block = 2000`.
- **66–70 · Modificar.** *saxpy* (`y = alpha·x + y`); criterio: `checksum=11988.0` para `n = 1000`. Lo que no se
  termine se termina en casa (no es parte de la tarea obligatoria).

**Errores esperados y la pregunta que se hace ante cada uno** (no se da la respuesta):

| Error observado | Pregunta socrática |
|---|---|
| `no CUDA-capable device is detected` / `nvidia-smi: command not found` | "¿Qué dijo la primera celda? ¿Qué tipo de entorno tiene esta sesión?" |
| Kaggle con P100: `no kernel image is available for execution` | "¿Qué GPU te asignaron y qué capacidad de cómputo tiene? ¿Para cuál compilaste?" |
| Editan el código y el resultado no cambia | "¿Qué archivo compila `nvcc`: el de la celda o el del disco? ¿Cuándo se escribió?" |
| En la tabla de rastreo escriben `i = threadIdx.x` | "Si el bloque 0 y el bloque 1 tienen cada uno un hilo 0, ¿qué elemento calcula cada uno?" |
| Usan `n / block` y dicen que "está bien porque no dio error" | "¿Cuántos hilos lanzaste en total? ¿Alcanzan para 1000 elementos? ¿Qué dijo `max_abs_err`?" (idea 27) |
| Quitan la guardia, en GPU "funciona" y concluyen que sobra | "¿Dónde escribió el hilo con `i = 1023` (hilo 255 del bloque 3)? ¿De quién es esa memoria? ¿Qué pasó en CUDASIM?" |
| Tiempo del *kernel* ≈ 0.00 ms al medir con `perf_counter` sin sincronizar | "¿El lanzamiento espera a que el *kernel* termine? Entonces, ¿qué mediste?" |
| *saxpy* "falla" porque comparan contra la `y` ya modificada | "¿Contra qué copia de `y` estás comparando? ¿Cuándo la guardaste?" |
| CUDASIM con `n = 2^24` "se colgó" | "¿Cuántos hilos de Python estás simulando? ¿Para qué sirve el simulador y para qué no?" |
| `block = 2000` y el error aparece "en otra línea" | "¿Qué llamada reporta errores de lanzamiento y cuál los de ejecución?" |

### 70–77 · Puesta en común

Mostrar (sin nombres) tres hallazgos: (1) el orden de los `printf` del *kernel* no es el de `i` y la tabla ordenada la
imprime el anfitrión; (2) `grid = 3`: cero errores, 232 elementos en cero; (3) sin guardia: CUDASIM lo cacha, la GPU
no necesariamente, y con `grid = 4000` sí revienta. **ConcepTest 2** (CT2, idea 26 + índice; esperado ~55 %). Regla
general en una frase: *"Cada hilo calcula su `i`; el anfitrión calcula los bloques redondeando hacia arriba; la
guardia protege al último bloque; y la correctitud se prueba contra la CPU, no con la ausencia de errores."* Si
sobran 2 min: CT3 (idea 27); si no, CT3 abre la recuperación de la S02.

### 77–85 · Transferencia

Reto (README, "Crear"): `dot_partial`: un hilo por producto `p[i] = a[i]·b[i]`, suma en la CPU en `double`. Criterio
de "listo": `n = 1000 → dot=17946.0`, `verificacion=OK`; en GPU además `n = 2^24 → dot=301989870.0`. Decir por qué
no se reduce todavía en la GPU: "el jueves 26 aprenden a sumar dentro del bloque sin carreras". Quien termina: medir
*kernel* vs. copia D2H de `p` con dos pares de eventos. Quien no arranca: darle el esqueleto (firma del *kernel* y el
`main` de `vector_add.cu` con el ciclo de verificación vacío) y la pregunta "¿qué cambia respecto a la suma: la
operación, los índices o las copias?".

### 85–90 · Cierre

*Exit ticket* (`exit-ticket.md`, lado B de la hoja). Anuncios, con fechas exactas:

- **Práctica 6 · GPU** publicada hoy en `practicas/P6-gpu/`: 15 % del 3.er parcial; **pre-laboratorio individual se
  entrega al inicio de la S02, martes 24 de noviembre, 08:30, Lab LS4**; fecha límite **domingo 6 de diciembre, 23:59**.
- Tarea espaciada (`tarea-espaciada.md`): `tareas/U5-S01.md` antes del martes 24 de noviembre, 08:30.
- H2: retroalimentación con rúbrica antes del lunes 30 de noviembre.
- Recoger las hojas al salir.

## Diferenciación

- **Apoyo (quien no arranca):** tabla de rastreo I1 con las dos primeras filas resueltas; esqueleto de *saxpy* con
  `/* TODO */` solo en la línea del *kernel*; emparejar con una pareja que ya tiene GPU asignada; permitir todo el
  bloque PRIMM con CUDASIM (`n = 1000`), sin GPU, y mover la ejecución en Colab a la S02.
- **Ampliación (quien termina):** (a) barrido de tamaño de bloque del notebook (sección 5) y una frase sobre
  `block = 32` vs. `256` (anticipa S04 e idea 26); (b) `dot_partial` con `n = 2^24` midiendo *kernel* y copia D2H por
  separado; (c) reescribir el índice con `cuda.grid(1)` y explicar por qué es equivalente; (d) lanzar
  `vector_add<<<1, 1>>>` con un ciclo interno sobre `n` y comparar el tiempo con la versión de 65 536 bloques.

## Evaluación formativa de la sesión

| Objetivo | Qué mira el profesor |
|---|---|
| 1 | Revoto de CT1 ≥ 80 %; *exit ticket* 1 identifica "núcleo CUDA ≠ núcleo de CPU" |
| 2 | Columna "Predicho" de P1 y P2 correcta en ≥ 70 % de las parejas; *exit ticket* 2 con 40 bloques, `i = 901`, 120 ociosos |
| 3 | Pareja muestra `verificacion=OK` en Colab o CUDASIM **y** explica la salida de `grid = 3`; `make test` en PASS |
| 4 | *saxpy* con `checksum=11988.0`; `dot_partial` con `dot=17946.0` al cierre o en la tarea |

Umbrales de alerta (marco §5): > 30 % de *exit tickets* en "mal" → la S02 abre con la fórmula del índice y la guardia
antes del pre-lab; < 60 % en la pregunta 1 de la recuperación → repaso de `MPI_Send` de 3 min en S02.

## Notas post-sesión

- (se llenan después) Equipos sin H2: ____. Conteo de la lista rápida: ____.
- ¿Cuántas parejas tuvieron GPU en Colab a las 10:55? ____. ¿Hubo que usar el plan B (CUDASIM)? ____.
- CT1 primer voto ___ % / revoto ___ %. CT2 ___ % / ___ %. ¿Se usó CT3? ____.
- Error más frecuente del *exit ticket*: ____. Cambio para la S02: ____.
