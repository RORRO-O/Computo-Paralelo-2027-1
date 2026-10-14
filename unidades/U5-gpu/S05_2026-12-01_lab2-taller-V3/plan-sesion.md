> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S05 · martes 1 de diciembre de 2026 · 08:30–10:00 · Lab LS4

# S05 · Práctica 6 · Laboratorio 2 (mediciones, punto de control, mini-defensas) + taller V3: portar la V2 a GPU

Tipo: laboratorio (variante 2.1 de la plantilla, comprimida a 45 min) + taller de proyecto (variante 2.4,
comprimida a 35 min). Recuperación al inicio y *exit ticket* al cierre, sin recorte.

## Objetivos (al terminar, el estudiante podrá…)

1. **Presentar y defender** una tabla de la Parte D de P6 (barrido de bloque, con/sin transferencias, *speedup* vs.
   CPU) explicando en un minuto qué muestra y qué no (nivel: analizar).
2. **Calcular** el índice lineal de una celda de una malla 2D aplanada y el `blockIdx`/`threadIdx` que la procesa en un
   *kernel* 2D o 1D, incluido el caso de dimensiones no múltiplos del bloque (nivel: aplicar).
3. **Decidir y justificar** el plan de porte de su V2 a GPU: *kernel* candidato, estructuras aplanadas, mapeo, movimiento
   de datos una sola vez, verificación contra la V1 y medición según el protocolo (nivel: evaluar).
4. **Distinguir** lo que cuenta como V3 (un *kernel* propio verificado) de lo que no (biblioteca que hace todo; V3 sin
   verificación), y reconocer cinco errores típicos de porte (nivel: comprender).

Se evalúan en el *exit ticket* (objetivos 2 y 4 en la pregunta 2 y 1), en el punto de control (objetivo 1) y en la
sección 1–5 de `plan-V3.md` (objetivo 3).

## Prerrequisitos y vínculo

- Viene de: S04 (lunes 30 de noviembre): transferencias H2D/D2H, eventos, ocupación, tamaño de bloque, perfilado en
  Colab. Partes A–C de P6 (Lab 1 el martes 24 de noviembre; Parte C entre sesiones).
- Va hacia: S06 (jueves 3 de diciembre): repaso de Unidades IV–V y lista de cotejo de la entrega final. P6 vence el
  domingo 6 de diciembre 23:59. Entrega final del proyecto el lunes 7 de diciembre 10:30; Examen 3 el martes 8 de
  diciembre 08:30; defensa el jueves 10 de diciembre.
- Ideas erróneas que ataca (Anexo A): **24** (las transferencias no cuentan), **27** (sin error = correcto), **22** (un
  hilo = un núcleo), **5** (medir una vez basta / `-O0`). Cada una aparece en un ConcepTest, en un paso de la práctica
  guiada y en el *exit ticket* o la recuperación.

## Materiales

- Esta carpeta: `retrieval-inicio.md`, `conceptests.md`, `practica-guiada/` (código, `notebook_colab.ipynb`,
  `plan-V3.md`), `exit-ticket.md`, `tarea-espaciada.md`.
- `practicas/P6-gpu/README.md` (Parte D) y `rubrica.md` impresa o en pantalla para las mini-defensas.
- Proyector, cronómetro visible, tarjetas con números de lista. Máquina del laboratorio con `gcc`, `python3` + `numba`
  (para CUDASIM) y navegador con Colab/Kaggle. Antes de la sesión: `cd practica-guiada && make test` en la máquina
  del salón (≈ 30 s) y abrir el notebook en una cuenta de Colab con GPU asignada.
- Hoja de registro de mini-defensas (una fila por integrante: número de lista, pregunta 1, pregunta 2, resultado).

## Guion minuto a minuto

### 0–5 · Recuperación

Proyectar las 5 preguntas de `retrieval-inicio.md`. A los 4 min, mostrar respuestas; manos por pregunta.
Respuestas esperadas: (1) 60× y ≈ 1.9×, ambos; (2) falta `cudaEventSynchronize`, se midió el encolado; (3) 10×;
(4) ≈ 50 ms vs. 58 µs, latencia; (5) idx 19, `blockIdx=(0,0)`, `threadIdx=(3,2)`.
Si menos del 60 % acierta la pregunta 1: antes del minuto 10, repetir en voz alta la regla "dos tiempos en la misma
tabla" con el ejemplo de la práctica guiada (`copiar_cada_iter=1`); es exactamente lo que se va a revisar en el punto
de control.

### 5–10 · Objetivos, anclaje y ConcepTest 1

Frase de anclaje: "El *exit ticket* del lunes dejó [error más frecuente de la S04; típicamente: confundir el tiempo
del *kernel* con el tiempo del programa]. Hoy, en el punto de control, cada tabla tiene que tener las dos columnas.
Y en el taller van a decidir qué parte de su V2 se vuelve *kernel*: eso es la V3 que entregan el lunes 7 a las 10:30."

Proyectar los objetivos. Lanzar **CT1** (`conceptests.md`, "¿Qué le falta a esta medición?"): voto, discusión 2 min,
revoto, regla: **dos tiempos, cinco repeticiones, mediana, T(1) = V1 con `-O2`**. Si el primer voto supera 80 %, saltar
la discusión y usar el minuto para la demostración siguiente.

Demostración de 2 min en Colab (notebook de esta carpeta, celda "Medir" ya ejecutada antes de clase): mostrar la fila
`16x16 copiar_cada_iter=0` y la fila `copiar_cada_iter=1`. "Mismo *kernel*, misma verificación PASS; una V3 sirve y la
otra no. Así debe verse su tabla de la Parte D."

### 10–40 · Trabajo por equipos en la Parte D de P6 + mini-defensas

Instrucción de arranque: "Cada equipo abre su Colab con la Parte C ya funcionando. Objetivo al minuto 40: una tabla con
barrido de bloque (≥ 3 tamaños, múltiplos de 32), con y sin transferencias, *speedup* vs. la referencia CPU, mediana de
5 con calentamiento, GPU y fecha. Si la Parte C no corre todavía, me avisan ahora y trabajan sobre el código de la
práctica guiada para la medición; la Parte C la terminan en casa."

El profesor circula con la rúbrica de P6 y hace la **mini-defensa**: 2 min por equipo, **dos preguntas por integrante**,
elegidas de este banco (una de la columna A y una de la B; anotar en la hoja de registro):

| A · "¿Qué hace esta línea?" | B · "¿Qué pasaría si…?" |
|---|---|
| La línea que calcula el índice global del hilo | …quito la guardia de rango y pruebo con un tamaño que no es múltiplo del bloque |
| El `cudaMemcpy` de bajada: de dónde a dónde, cuántos bytes | …muevo el `cudaMemcpy` de subida dentro del ciclo de iteraciones |
| El `cudaEventSynchronize` (o `cudaDeviceSynchronize`) antes de leer el tiempo | …lo quito: ¿qué número sale y por qué? |
| La comparación contra la CPU: qué compara y con qué tolerancia | …la comparación pasa pero `cudaGetLastError` nunca se llama: ¿qué error se les escapa? |
| El tamaño de bloque que eligieron | …uso 1000 hilos por bloque en vez de 1024, o 48 en vez de 32 |
| La atómica o la reducción (si la Parte C la tiene) | …la quito y pruebo tres veces: ¿por qué "a veces sale bien"? |

Una respuesta que muestre que el integrante no entiende su propio código baja "Proceso e integridad" de ese integrante
(rúbrica de P6; `docs/metodo/04-evaluacion.md` §4). No se discute en el momento: se anota y se avisa en privado.

Con 12 equipos a 2 min son 24 min; el resto del tiempo se dedica a quien se atoró. Orden de visita: primero los equipos
que avisaron que la Parte C no corre.

**Errores típicos de la Parte C/D y la pregunta que se hace** (no se da la respuesta):

| Error observado | Pregunta socrática |
|---|---|
| Reportan solo el tiempo del *kernel* ("las copias no son del algoritmo") | "¿Cuánto tarda tu programa completo desde que el usuario lo lanza? ¿Cuál de los dos tiempos le importa?" |
| Una sola corrida; o promedio con un valor atípico | "¿Cuánto cambió entre la primera y la segunda corrida? ¿Qué pide el protocolo y por qué mediana?" |
| Sin calentamiento: la primera corrida incluye la creación del contexto o el JIT de Numba | "¿Por qué la repetición 1 tarda el doble que la 2? ¿Cuál descartas?" |
| Miden sin sincronizar (eventos sin `cudaEventSynchronize`, o `time.perf_counter` sin `cuda.synchronize()`) | "Tu *kernel* procesa 4 MB en 12 µs: ¿qué ancho de banda es eso? ¿Existe esa GPU?" |
| Comparan contra la versión paralela con 1 hilo, o contra la CPU con `-O0` | "¿Cuál es el mejor programa secuencial que tienes? ¿Con qué banderas lo compilaste?" |
| Tamaño tan pequeño que T(1) < 0.1 s | "¿Qué estás midiendo: el trabajo o la sobrecarga de lanzar?" |
| Barrido de bloque con tamaños que no son múltiplos de 32 (p. ej., 100, 500) | "¿De cuántos hilos es un *warp*? ¿Cuántos hilos del último *warp* trabajan con 100 por bloque?" |
| Falta la guardia; PASS porque el tamaño de prueba es múltiplo del bloque | "Pruébalo con N = 1000 en vez de 1024. ¿Qué pasó? ¿Por qué antes no se notó?" |
| `cudaMemcpy` dentro del ciclo de iteraciones (Parte C con varios pasos) | "¿Cuántas veces cruza tu arreglo el PCIe? ¿Cuántas necesita cruzar?" |
| Verificación que compara con `==` en float, o que no existe ("no dio error") | "¿Qué errores detecta `cudaGetLastError`? ¿Detecta un índice equivocado que cae dentro del arreglo?" |
| Escrituras compartidas sin atómica (histograma/reducción de la Parte C) que "a veces" coinciden | "Córrelo tres veces con el mismo dato. ¿Mismo resultado? ¿Qué hilo escribe esa posición además de ti?" |
| No anotan la GPU ni la fecha; mezclan corridas de T4 y de otra GPU | "Si mañana Colab te da otra GPU, ¿tu tabla sigue siendo comparable? ¿Cómo lo sabrá quien lea el reporte?" |
| Gráfica de *speedup* sin la línea ideal o con ejes sin unidades | "¿Contra qué comparo visualmente tu curva? ¿Qué unidad tiene el eje y?" |

### 40–52 · Punto de control

Cada equipo (en orden de tarjeta al azar) proyecta **una** tabla de la Parte D y la explica en **1 minuto**: qué
configuración ganó, cuánto cuesta la transferencia respecto al *kernel*, y si coincide con su predicción (pre-mortem de
P6). El profesor hace una sola pregunta de seguimiento, tomada de la columna B del banco. Los equipos que no alcanzan
turno (si son más de 12) muestran la tabla en la ronda del taller.

Criterio de "tabla aceptable" (se dice en voz alta antes de empezar): dos tiempos, mediana de 5, T(1) declarado, GPU
y fecha, al menos tres tamaños de bloque. Una tabla que no lo cumple no se critica en público: se anota "revisar antes
del domingo" y se les dice qué falta.

### 52–57 · Mini-lección del taller + ConcepTest 2

Lanzar **CT2** ("El *kernel* no dio error"): voto, discusión 2 min, revoto. Regla: **verificar contra la V1 es parte
del *kernel*, no un extra.**

Mini-lección de 3 min, con `notas-estudiante.md` §2 proyectado: los seis pasos del porte (identificar → aplanar → mapear
→ mover una vez → verificar → medir) y la tabla "qué cuenta como V3 / qué no" (§4). Decir explícitamente: "CUDA C, Numba
CUDA o CuPy con `RawKernel`; las tres valen. `cupy.matmul` solo, no. Una V3 que no se compara con la V1, no."

### 57–80 · Trabajo por equipos: mini PRIMM "aplanar y mapear" + `plan-V3.md`

Instrucción de arranque: "Primero 10 minutos de PRIMM con `practica-guiada/README.md`: predicen P1–P5 por escrito,
corren el caso 10 × 8 (CUDASIM en la máquina del laboratorio o Colab), llenan la tabla de 3.1. Después abren `plan-V3.md`
y llenan las secciones 1 a 5; la sección 4 es el esqueleto del *kernel* de **su** proyecto. Al minuto 80 dos equipos lo
muestran."

Roles conductor/navegante; cambio al minuto 67.

El profesor hace rondas de 2 min por equipo con las dos preguntas fijas del taller: **"¿cuál es su *kernel* candidato y
qué porcentaje del tiempo de la V1 es?"** y **"¿qué no entienden todavía?"**. Anota la segunda respuesta: alimenta la
S06 y la asesoría de la semana.

**Errores esperados en el PRIMM y la pregunta que se hace:**

| Error | Pregunta |
|---|---|
| P2: escriben `threadIdx=(3,5)` | "¿Qué dimensión recorre columnas: x o y? ¿En qué orden se imprime el par?" |
| P3: calculan 80 hilos (uno por celda) | "¿De qué tamaño es el bloque? ¿Se puede lanzar medio bloque?" |
| P4: `blockIdx.x = 29` o `threadIdx.x = 5` | "En 1D, ¿cuántos hilos hay antes del bloque 1? ¿Dónde cae el 29?" |
| 3.1: bloques por división entera (2 × 2 para 37 × 45) | "¿Qué celdas quedan sin hilo si redondeas hacia abajo? ¿Quién las procesa?" |
| Creen que `-DSIN_GUARDIA` "no hizo nada" porque dio PASS | "¿Es evidencia de corrección que salga bien una vez? ¿Qué dijimos de las carreras en la Unidad III?" |
| Investigar 3.3.1: no saben qué hace `cudaEventSynchronize` | "¿Qué pasa en la CPU cuando lanzas un *kernel*: espera o sigue? ¿Entonces qué marca el segundo evento?" |
| Modificar: `r = idx % width; c = idx / width` (al revés) | "Con ancho 8 e idx 29, ¿qué fila te da tu fórmula? ¿Existe la fila 5 en 10 filas? Ahora prueba con idx 9." |
| `plan-V3.md` §1: eligen el ciclo más fácil, no el más caro | "¿Qué dice el perfil de H1? Si portas ese ciclo y es el 10 %, ¿cuál es el *speedup* máximo por Amdahl?" |
| §2: planean copiar `float **` fila por fila a la GPU | "¿Cuántas `cudaMemcpy` son? ¿Cuántas latencias de PCIe? ¿Cómo lo guardarías en un solo bloque contiguo?" |
| §4: el esqueleto tiene varios hilos escribiendo el mismo acumulador | "¿Quién más escribe esa posición? ¿Qué hicimos con el histograma en la S03?" |
| §5: "subimos los datos en cada iteración porque la CPU los necesita para imprimir el avance" | "¿Cada iteración o cada 100? ¿Qué te cuesta cada bajada según tu propia tabla de la Parte D?" |
| §6: tolerancia 0 o comparación contra la V2 | "¿Qué pasa con el orden de las sumas en float? ¿Contra qué versión se define el *speedup* en el protocolo?" |
| Equipo con V3 en CuPy que llama `cupy.linalg`/`cupyx.scipy` para todo | "¿Dónde está el *kernel* que escribieron ustedes? ¿Qué línea explicarían en la defensa?" |

### 80–85 · Dos equipos muestran su plan + retroalimentación de pares

Dos equipos (tarjeta al azar) proyectan las secciones 1, 3 y 4 de su `plan-V3.md` (2 min cada uno). El resto del grupo
retroalimenta con **tres** ítems de la lista de cotejo (sección 9): "¿es el ciclo caliente?", "¿tiene guardia y bloques
con `ceil`?", "¿sube una vez y baja una vez?". Una frase de cierre del profesor por equipo, sin repetir lo que ya
dijeron los pares.

### 85–90 · Cierre

*Exit ticket* (`exit-ticket.md`) en papel, individual. Mientras escriben, proyectar la tarea (`tarea-espaciada.md`) y los
recordatorios: **P6: domingo 6 de diciembre, 23:59** · **Entrega final del proyecto (V1·V2·V3 + reporte PDF): lunes 7 de
diciembre, 10:30** · **Examen 3 (Unidades IV–V): martes 8 de diciembre, 08:30** · **Defensa oral: jueves 10 de
diciembre.** Rúbricas en `proyecto/entrega-final/` y `proyecto/defensa/`; S06 el jueves 3 de diciembre, 10:30, con examen
de práctica y lista de cotejo de la entrega final.

## Diferenciación

- **Apoyo (equipo cuya Parte C no corre):** trabajan la medición sobre `practica-guiada/flatten_map_2d.cu` en Colab
  (la celda "Medir" ya produce la tabla con el formato correcto) para cumplir el punto de control con una tabla real, y
  terminan la Parte C en casa con una asesoría por protocolo (escriben qué intentaron y qué observaron antes de pedirla).
  En el taller, si no identifican el ciclo caliente, se les pide el perfil de H1 y se les da la pregunta: "¿qué función
  aparece primero?".
- **Apoyo (pareja que no arranca el PRIMM):** llenar juntos la fila `(5,3)` de la tabla de rastreo 3.2 con el profesor,
  luego dejarlos con la fila `(9,2)`.
- **Ampliación (equipo que ya tiene V3 corriendo):** medir la V3 con tres tamaños de bloque y un tamaño no múltiplo;
  después completar `TODO(1)` y comparar 1D vs. 2D en su propio problema; opcionalmente, intentar `cudaMallocHost`
  (memoria fija) para la subida y reportar la diferencia en `t_total`. Reconocimiento en la defensa, no puntos extra.

## Evaluación formativa de la sesión

| Objetivo | Qué mira el profesor |
|---|---|
| 1 (tabla de la Parte D) | Punto de control: ¿cuántas tablas cumplen los cinco criterios? Meta: ≥ 80 % de los equipos. Hoja de registro de mini-defensas: integrantes con respuesta insuficiente |
| 2 (índices y mapeo) | Revoto de CT3 si se aplica; pregunta 2 del *exit ticket* (los tres incisos); montones bien/parcial/mal |
| 3 (plan de porte) | Secciones 1–5 de `plan-V3.md` llenas al minuto 80; respuesta a "¿cuál es su *kernel* candidato?" en la ronda |
| 4 (qué cuenta como V3; errores de porte) | Revoto de CT2; pregunta 1 del *exit ticket*; lista de "qué no entienden todavía" |

Umbral de alerta (marco pedagógico §5): más del 30 % de *exit tickets* en "mal" en la pregunta 2 → la S06 abre con la
aritmética de índices en la recuperación larga.

## Notas post-sesión

- Error más frecuente del *exit ticket*:
- Equipos con tabla no aceptable en el punto de control (revisar antes del domingo 6 de diciembre):
- Integrantes con mini-defensa insuficiente (aviso en privado):
- "Qué no entienden todavía" más repetido (para la S06 y la asesoría):
- ConcepTest que falló y por qué:
- Qué cambiar la próxima vez:
