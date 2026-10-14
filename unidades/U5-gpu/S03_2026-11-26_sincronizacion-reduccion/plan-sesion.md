> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S03 · jueves 26 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S03 · Sincronización y reducción en GPU: `__syncthreads`, atómicas, árbol, divergencia e histograma

**Tipo:** Contenido (estructura base de 90 min de `02-plantilla-sesion.md`, §1). Sin hito ni laboratorio. La GPU
se usa desde Colab/Kaggle en la práctica guiada; todo lo que decide la correctitud se puede hacer sin GPU con
`make test` y el simulador de Numba.

## Objetivos (al terminar, el estudiante podrá…)

1. **Explicar** qué garantiza `__syncthreads()` (todos los hilos **del bloque**, y visibilidad de sus escrituras) y
   qué no (otros bloques, "toda la GPU"), y **decir** cómo se combinan resultados entre bloques (fin del *kernel*,
   atómicas, segundo *kernel*) (nivel: comprender). Se evalúa en CT1, *exit ticket* 1 y recuperación 5.
2. **Calcular**, dados `n` y `blockDim`, el número de operaciones atómicas globales de cada versión de la reducción
   (por elemento, por bloque, cero), los niveles del árbol y los *warps* activos y divergidos de un nivel, y
   **elegir** la versión adecuada para un caso dado (nivel: aplicar / analizar). Se evalúa en PRIMM P1/P4/I2,
   *exit ticket* 2 y tarea 1.
3. **Diagnosticar** una carrera de datos sobre memoria compartida (sin barrera entre niveles) y un algoritmo
   incorrecto sin error de CUDA (`block` no potencia de 2), **verificando** contra la CPU con tolerancia relativa y
   **explicando** por qué "salió bien cinco veces" no es evidencia (nivel: analizar / evaluar). Se evalúa en PRIMM
   I3/I4, CT2 y *exit ticket* 1.
4. **Modificar** el árbol a una reducción `max` y **crear** un histograma privado por bloque en memoria compartida
   con dos barreras, idéntico al de la CPU (nivel: crear). Se evalúa en PRIMM Modificar/Crear (`make test`) y en la
   tarea.

## Prerrequisitos y vínculo

- **Viene de:** S02 (martes 24 de noviembre, Lab LS4): memoria compartida, carga cooperativa, las dos barreras del
  *kernel* por mosaicos, coalescencia; Práctica 6 Lab 1 (Partes A y B). De unidades previas se reutilizan: U3 S07 y
  Práctica 4 (carreras, `atomic`/`critical`, histograma local por hilo + combinación, idea 7), U3 S07 (`reduction` en
  punto flotante, tolerancia), U4 S03 (`MPI_Reduce`/`Allreduce` como reducción en árbol entre procesos), U1
  (*speedup*, Amdahl). La tarea de la S02 (ejercicio 3) ya pidió predecir niveles, barreras, hilos ociosos y "cómo
  combinar 1000 parciales": se recoge en la recuperación 5 y en CT1.
- **Va hacia:** S04 (lunes 30 de noviembre, 10:30, salón 3208): transferencias y eventos (hoy se anota que la copia
  de 16 KB de parciales cuesta tanto como el *kernel*), tamaño de bloque y ocupación (hoy: *warps* divergidos). S05
  (martes 1 de diciembre, 08:30, Lab LS4): Lab 2 de la Práctica 6 y taller V3; la Parte C de la P6 (histograma /
  reducción) usa exactamente lo de hoy. Examen 3 (martes 8 de diciembre): "carreras de datos en una reducción CUDA"
  es un ítem previsto de la tabla de especificaciones (`04-evaluacion.md`, §2.1).
- **Ideas erróneas que ataca (Anexo A):** **25** (`__syncthreads` sincroniza toda la GPU) → CT1-A/D, PRIMM P3/I3,
  pausa 5 del ejemplo, *exit ticket* 1-B; **24** (las copias no cuentan) → PRIMM I5, pausa 6, CT3-A/D, tarea 2c y 3;
  **10** (`reduction` da exactamente el mismo resultado) → recuperación 4, PRIMM P2, pausa 7, CT2-A/D; **7** ("salió
  bien una vez, no hay carrera") → recuperación 1, PRIMM I3, CT2-C, *exit ticket* 1-A. De paso: 27 (sin error =
  correcto) en I4 y *exit ticket* 1-D; 32 (barrera dentro de un `if`) en la pausa 3 y la lista de errores; 8
  (`critical` = `atomic`) en la recuperación 3.
- **Nivel de andamiaje (07 §A.5):** **completo**: segunda sesión de contenido de la unidad; ejemplo resuelto
  completo con siete pausas y práctica guiada con las cinco fases de PRIMM (Crear en Transferencia).

## Materiales

- Archivos de esta carpeta. Proyector, cronómetro visible, tarjetas con números de lista, tarjetas A/B/C/D.
- Laptop del profesor con **Colab abierto y GPU asignada desde las 10:15**; `practica-guiada/notebook_colab.ipynb`
  cargado y ejecutado hasta la sección 3 (para tener los tiempos de la T4 del día); copia local de `practica-guiada/`
  con `make test` pasado esa mañana (≈ 40 s sin GPU; es también el Plan B: todo Investigar se muestra con CUDASIM).
- Pizarrón, antes de empezar: una fila de 8 casillas `s[0..7]` con `1.0 … 1.7` para la tabla de rastreo I1, y un
  rectángulo de 32 puntos (un *warp*) para marcar carriles activos.
- Hoja por estudiante: lado A recuperación, lado B *exit ticket*.
- Anotar aquí antes de empezar: error más frecuente del *exit ticket* de la S02 (martes 24): ________. ¿Se usó el
  CT3 de la S02? ____ (si no, es la pregunta 1 de la recuperación de hoy).

## Guion minuto a minuto

### 0–5 · Recuperación

Proyectar `retrieval-inicio.md` (5 preguntas; la 1 es el CT3 de la S02 si no se votó el martes). Minuto 4:
respuestas; manos por pregunta; anotar el conteo de la 1 y la 3. **Si < 60 % acierta la 1** (carrera latente sin la
segunda barrera): en el anclaje se dedica un minuto a "¿qué garantiza el *hardware* sobre el orden entre *warps*?
Nada", con el dibujo de dos *warps* avanzando a distinta velocidad; sin eso, I3 no se entiende. La 5 queda abierta:
"a las 10:58 la contestan ustedes".

### 5–10 · Objetivos y anclaje

- **5–7.** Autocalificación de la tarea de la S02 con su clave (2 min); registrar entrega levantando la mano por
  ejercicio. Pedir que dejen a la vista su respuesta al ejercicio 3 (predicción de hoy).
- **7–10.** Frase de conexión, según el error más frecuente del *exit ticket* de la S02: si fue "`TILE = 64`
  compila, así que corre": "El martes muchos aceptaron que un programa que compila funciona. Hoy van a ver tres
  programas que compilan, corren sin ningún error de CUDA y están mal, y uno que está bien y da un número distinto
  cada vez". Si fue confundir `n` con `TILE` en el conteo de lecturas: "El martes contamos cuántas veces se lee cada
  dato; hoy contamos cuántas veces se escribe la **misma** dirección: ahí está el costo de las atómicas". Proyectar los
  cuatro objetivos. Proyecto: "La V3 de casi todos los equipos necesita una suma, una norma o un máximo al final del
  *kernel*; hoy aprenden las tres formas de hacerlo y cuál elegir".

### 10–35 · Instrucción explícita I

**10–16 · Barrera, bloque y atómicas** (pizarrón, pensar en voz alta; `notas-estudiante.md` §1–2).

1. Dibujar un bloque de 256 hilos como 8 *warps*. "`__syncthreads()` es una puerta: nadie pasa hasta que los 8
   *warps* llegaron. ¿Y el bloque de al lado? No tiene idea de que esta puerta existe." Recoger dos respuestas a la
   pregunta 5 de la recuperación (tarjetas al azar): clasificar en "copiar parciales", "atómica", "segundo kernel".
2. Atómicas: "`atomicAdd` es correcta siempre; el precio es la cola: 1 048 576 hilos formados frente a **una**
   dirección". Conectar con la recuperación 3: "es el `atomic` de OpenMP con cien mil veces más hilos y la memoria
   más lejos". Anotar en el pizarrón los tres números que van a predecir: `1 048 576 / 0 / 4096`.

**16–28 · Ejemplo resuelto** (`ejemplo-resuelto.md`, código proyectado; una persona por pausa con tarjeta, 30 s).

- Plan en 3 líneas. Recorrer el *kernel* en este orden: carga con neutro (pausa 1), barrera A (pausa 2), ciclo con
  `tid < stride` (pausa 4: marcar en el *warp* dibujado los carriles activos con `tid % 2 == 0` y con `tid < 16`),
  barrera B fuera del `if` (pausa 3), `partial[blockIdx.x]` (pausa 5: "¿por qué no suma los demás aquí?"), etapa 2
  en el anfitrión (pausa 6: "¿cuánto cuesta copiar 16 KB? Lo medimos el lunes 30"), tolerancia (pausa 7).
- Mostrar la salida real del simulador (`n = 1000`: tres sumas distintas, tres `OK`) y la de `reduce_sum_cpu
  1048576 256` (cuatro órdenes, cuatro números). Decir explícitamente: "ninguno es 'el verdadero'; el criterio es la
  referencia en `double` más la tolerancia".
- Variante que falla A (sin barrera B): proyectar las tres corridas reales (`227.6`, `119.3`, `188.9`). "Esto es
  la pregunta 1 de la recuperación dentro de un árbol. En la GPU con bloques de 32 'a veces sale bien'; en diez
  minutos lo prueban."

**28–35 · ConcepTest 1** (`conceptests.md`, CT1, idea 25; esperado ~50 %). Voto → parejas (pregunta guía: "¿a qué
hilos exactamente espera esa barrera? ¿quién garantiza que el bloque 4095 ya corrió?") → revoto → cierre: "la
barrera es del bloque; entre bloques solo el fin del *kernel* o una atómica; por eso existe la etapa 2". Si > 80 % en
el primer voto, explicar en 1 min y ganar 3 min para PRIMM.

### 35–65 · Práctica guiada PRIMM (`practica-guiada/README.md`)

Parejas de nivel adyacente (diagnóstico de agosto); conductor/navegante; **cambio de rol al minuto 50**. Quien no
tenga GPU en Colab trabaja con `make test` y CUDASIM en la laptop (todo Predecir, Investigar y Modificar se puede
hacer así) y se asoma a la pantalla de otra pareja para la parte de tiempos.

- **35–41 · Predecir** (P1–P6 por escrito, sin ejecutar). El profesor circula y lee predicciones; no corrige. Anotar
  en el pizarrón tres predicciones distintas de P6 (orden y factor) para la puesta en común.
- **41–47 · Ejecutar.** Notebook: `!nvidia-smi` → `%%writefile` → `nvcc`/`gcc` → `reduce_sum_cpu 1048576 256` →
  `reduce_sum all 1048576 256 cpu` → `reduce_sum tree_nodiv 1048576 256 atomic`. En la laptop: `make test`. Llenar
  "Observado" junto a cada predicción.
- **47–57 · Investigar.** I1 tabla de rastreo (bloque de 8, con el pizarrón), I2 *warps* por nivel, I3 sin barrera
  (CUDASIM tres veces; en GPU `-DSIN_SYNC` con `block = 256` y `32`, cinco corridas cada uno), I4 `block = 96` y
  `n = 1 000 003`. I5 (costo de la etapa 2) e I6 (`2^24`) solo quien tiene GPU y va adelantado.
- **57–65 · Modificar.** `reduce_max` a partir de `tree_nodiv` (`fmaxf`/`max`, neutro `-INFINITY`, etapa 2 con el
  máximo de los parciales). Criterio: `max=9.500000 … verificacion=OK` para `n = 1000`, `n = 37` con `block = 8` y, en
  GPU, `2^20`; `make test` lo detecta si el archivo se llama `reduce_max.cu` / `reduce_max_numba.py`. Lo que no se
  termine va a casa (no es parte obligatoria de la tarea).

**Errores esperados y la pregunta que se hace ante cada uno** (no se da la respuesta):

| Error observado | Pregunta socrática |
|---|---|
| En P1 contestan `4096` atómicas para la versión `atomic` (o `1 048 576` para `tree` + atómica) | "¿Quién llama a `atomicAdd` en cada versión: cada hilo o el hilo 0 de cada bloque? ¿Cuántos hay de cada uno?" |
| En P2 esperan que las tres versiones den exactamente la misma `suma` | "¿En qué orden suma cada una? ¿Qué pasó en la S07 con `reduction` en `float`?" (idea 10) |
| En P3 predicen que sin barrera "funciona con 32 hilos" y lo dan por correcto | "¿Qué garantiza el *hardware* sobre el orden entre *warps*? ¿Y dentro de un *warp* desde Volta? ¿Qué dijo el simulador?" (idea 7) |
| En I1 el `tree_nodiv` lo rastrean con `stride = 1, 2, 4` (lo confunden con `tree_div`) | "¿Con qué `stride` arranca el ciclo de `tree_nodiv`? ¿Qué hilos cumplen `tid < 4`?" |
| En I2 cuentan hilos activos en vez de *warps* con trabajo | "¿De cuántos hilos es un *warp*? Si 16 de ellos trabajan, ¿cuántas instrucciones ejecuta el *warp*?" |
| Proponen `if (tid < stride) { s[tid] += …; __syncthreads(); }` | "¿Cuántos hilos tienen que llegar a esa barrera? ¿Qué hacen los `tid ≥ stride`?" (idea 32) |
| Proponen `if (i >= n) return;` antes de la carga | "Ese hilo ya no existe para las barreras: ¿qué le pasa al resto del bloque? ¿Y qué queda en `s[tid]`?" |
| En I4 dicen que `block = 96` "funcionó porque no dio error" | "¿Qué dijo `verificacion=`? ¿Qué fracción falta? Rastrea `stride = 3 → 1`: ¿quién suma `s[2]`?" (idea 27) |
| En I4 concluyen que `parciales_bit_a_bit…=si` prueba que el resultado es correcto | "¿Contra qué se compara ese `si`? Si la emulación repite el mismo error, ¿qué detecta?" |
| En Modificar cargan `0.0f` como neutro del máximo | "Si todos los datos del último bloque fueran negativos, ¿qué máximo saldría? ¿Cuál es el neutro de `max`?" |
| En Modificar usan `atomicMax` con `float` y no compila | "¿Para qué tipos existe `atomicMax`? ¿Qué otra etapa 2 tienes?" |
| Comparan el `max` con tolerancia "por si acaso" | "¿El máximo es uno de los datos o un cálculo nuevo? ¿Qué redondeo puede haber?" |
| Tiempos de `tree_div` y `tree_nodiv` iguales y concluyen que la divergencia no importa | "¿Qué domina con `n = 2^20`: leer 4 MB o 255 sumas por bloque? ¿Qué pasaría si el árbol se repitiera 1000 veces sobre datos ya en compartida?" |
| `kernel_mediana_ms` de `atomic` igual al del árbol | "¿Qué GPU te asignaron? ¿Cuántas atómicas y sobre cuántas direcciones? Vuelve a correr y compara `suma` entre corridas." |
| CUDASIM "se colgó" con `n = 1048576` | "¿Cuántos hilos de Python estás simulando? ¿Para qué sirve el simulador y para qué no?" |
| Kaggle con P100: `no kernel image is available` | "¿Qué capacidad de cómputo imprimió la celda 2? ¿Para cuál compilaste?" |

### 65–75 · Puesta en común

Mostrar (sin nombres) tres hallazgos: (1) la tabla de una pareja con P6 contra lo observado: `atomic` uno o dos
órdenes de magnitud más lenta, los dos árboles casi iguales; (2) las corridas de I3 de otra pareja: con 256 todas
`FALLA` y distintas; con 32 varias `OK`: "¿y qué?"; (3) `block = 96`: `FALLA` sin error de CUDA. **ConcepTest 2**
(CT2, ideas 10 y 7; esperado ~55 %): voto; discusión en parejas y revoto **solo** si el primer voto queda entre 30 % y
80 %. Regla general en una frase: *"La barrera es del bloque; la atómica es correcta pero hace cola; el árbol suma en
`log₂` niveles con una barrera por nivel y hilos activos consecutivos; y la correctitud se prueba contra una
referencia en `double` con tolerancia declarada, no con 'salió bien'."* Si sobran 2 min, CT3 (idea 24); si no, CT3
abre la recuperación de la S04.

### 75–85 · Transferencia

Reto (README, "Crear"): `TODO(1)`, histograma privado por bloque en memoria compartida (`hist_shared_atomic` en
`histogram.cu` y/o `histogram_numba.py`). Criterio de "listo": `make test` imprime `verificacion=OK, idéntico a
histogram_cpu` para `2000 128`; en GPU `n = 2^20` con `atomicas_globales=65536`. Restricciones: `BINS ≤ blockDim.x`,
exactamente dos `__syncthreads()`, ninguna dentro de `if (i < n)`. Quien no arranca: abrir la Pista 1 del README
(estructura en cinco pasos) y preguntar "¿qué debe estar en cero antes de que alguien sume, y qué debe estar completo
antes de que alguien vuelque?". Quien termina: extensión (a) `-DBINS=256` (¿sigue valiendo la pena?), (b) ciclo de
paso de malla con 320 bloques (¿cuántas atómicas globales quedan?), (c) datos uniformes contra sesgados. Si la
puesta en común se alargó y este bloque se recorta, el Crear pasa íntegro a la tarea como ejercicio 1 (ya está
escrito así en `tarea-espaciada.md`).

### 85–90 · Cierre

*Exit ticket* (`exit-ticket.md`, lado B de la hoja). Anuncios, con fechas exactas:

- **Tarea espaciada** (`tarea-espaciada.md`): `tareas/U5-S03.md` antes del **lunes 30 de noviembre, 10:30**; se
  autocalifica al inicio de la S04. Sin peso propio; alimenta el examen de práctica del jueves 3 de diciembre y el
  Examen 3.
- **S04, lunes 30 de noviembre, 10:30, salón 3208:** rendimiento en GPU (transferencias, eventos, tamaño de
  bloque). Traer el CSV del notebook de hoy con el modelo de GPU y la fecha.
- **Lab 2 de la Práctica 6: martes 1 de diciembre, 08:30, Lab LS4** (mediciones, punto de control, mini-defensas de
  la mitad de los equipos que no se defendió el 24). **La Práctica 6 vence el domingo 6 de diciembre, 23:59** (15 % del
  3er parcial). La Parte C puede usar el histograma o la reducción de hoy.
- Recoger las hojas al salir.

## Diferenciación

- **Apoyo (quien no arranca):** tabla I1 con el nivel 1 de `tree_nodiv` ya resuelto (`[2.4, 2.6, 2.8, 3.0, …]`) y se
  pide solo los niveles 2 y 3; para Modificar, el *kernel* `tree_nodiv` impreso con **tres huecos** (neutro de la
  carga, operación del ciclo, operación de la etapa 2) y la pista sellada "el neutro es el valor que no gana nunca";
  para Crear, la Pista 1 abierta desde el inicio y un esqueleto con los cinco comentarios `(a)…(e)` y los cuerpos
  vacíos; permitir todo PRIMM con CUDASIM y `n ≤ 4096`, sin GPU, con la ejecución en Colab como parte de la tarea.
- **Ampliación (quien termina):** el problema sin ejemplo: (a) reducción en **dos *kernels*** (el segundo reduce los
  4096 parciales con un solo bloque) comparada contra la etapa 2 atómica: ¿cuál es determinista y cuál más rápida?;
  (b) histograma con ciclo de paso de malla y 320 bloques, contando atómicas globales; (c) `compute-sanitizer --tool
  racecheck` sobre `reduce_sum_sin_sync tree_nodiv 4096 32` en Colab: ¿reporta la carrera aunque la salida sea `OK`?;
  (d) estimar con la tabla I2 cuántas veces más instrucciones de *warp* ejecuta `tree_div` y proponer cómo terminar
  los últimos cinco niveles sin barrera dentro de un solo *warp* (`__shfl_down_sync`; solo panorama, no se pide).

<details><summary>Solución de referencia del Crear y del Modificar (solo para el profesor; compilada con <code>nvcc -c</code> para sm_75 y sm_60 y verificada con el simulador: histograma idéntico a la CPU para 4096/256, 2000/128 y 256 bins; <code>max=9.5</code> para n = 5, 37, 1000, 1024)</summary>

```c
/* TODO(1) resuelto: histograma privado por bloque. Supone BINS <= blockDim.x (el for lo generaliza). */
__global__ void hist_shared_atomic(const unsigned char *v, unsigned int *hist, int n)
{
    __shared__ unsigned int s_hist[BINS];           /* histograma privado del bloque */
    int tid = threadIdx.x;
    int i = blockIdx.x * blockDim.x + tid;

    for (int j = tid; j < BINS; j += blockDim.x)    /* (a) poner en cero de forma cooperativa */
        s_hist[j] = 0u;
    __syncthreads();                                /* (b) nadie suma antes de que todo esté en cero */

    if (i < n)                                      /* (c) atómica en compartida: barata y repartida */
        atomicAdd(&s_hist[v[i]], 1u);
    __syncthreads();                                /* (d) el conteo del bloque está completo */

    for (int j = tid; j < BINS; j += blockDim.x)    /* (e) volcado: una atómica global por bin y bloque */
        if (s_hist[j] != 0u)
            atomicAdd(&hist[j], s_hist[j]);
}
```

Espejo en Numba (dentro de `make_shared_kernel(bins)`): `s_hist = cuda.shared.array(bins, uint32)`; ciclo `while j <
bins: s_hist[j] = uint32(0); j += cuda.blockDim.x`; `cuda.syncthreads()`; `if i < n: cuda.atomic.add(s_hist, v[i],
uint32(1))`; `cuda.syncthreads()`; ciclo de volcado con `cuda.atomic.add(hist, j, s_hist[j])`. En el simulador la
versión `shared` con `4096 256` tarda ≈ 12 s (por eso `make test` usa `2000 128`).

```c
/* Modificar resuelto: reducción max en árbol sin divergencia (solo cambian el neutro y la operación). */
s[tid] = (i < n) ? x[i] : -INFINITY;                 /* neutro del max: -inf, no 0 */
__syncthreads();
for (int stride = blockDim.x / 2; stride > 0; stride >>= 1) {
    if (tid < stride)
        s[tid] = fmaxf(s[tid], s[tid + stride]);
    __syncthreads();
}
if (tid == 0) partial[blockIdx.x] = s[0];
/* anfitrión: result = fmaxf sobre los parciales; verificación EXACTA (==): el máximo es uno de los datos */
```

En Numba: `float32(-np.inf)` y `max(s[tid], s[tid + stride])`; etapa 2 con `np.max(partial)`. Errores típicos:
neutro `0.0f` (falla si todos los datos de un bloque son negativos, no con estos datos: por eso conviene
preguntarlo), `atomicMax` con `float` (no existe), y comparar con tolerancia un resultado que debe ser exacto.
</details>

## Evaluación formativa de la sesión

| Objetivo | Qué mira el profesor | Umbral de alerta |
|---|---|---|
| 1 Alcance de la barrera | Revoto de CT1 ≥ 80 %; *exit ticket* 1 = C; recuperación 5 contestada con "no; parciales a global / atómica / segundo *kernel*" en ≥ la mitad | > 30 % de *exit tickets* en "mal" por la opción B (corrige "toda la GPU" pero acepta el código) |
| 2 Conteo de atómicas, niveles y *warps* | Columna "Predicho" de P1 y P4 correcta en ≥ 70 % de las parejas; *exit ticket* 2 con `2 000 000 · 3907 · 9 · 16/16` | (a) = (b) en > 20 % de los tickets |
| 3 Carrera y verificación | En I3 la pareja escribe por qué `block = 32` con `OK` no prueba nada; CT2 revoto ≥ 75 %; en I4 nombra la fracción perdida (1/3) | > 30 % vota A o D en el *exit ticket* 1 |
| 4 Modificar / Crear | `reduce_max` con `max=9.500000 … OK` al minuto 65 en ≥ la mitad de las parejas; histograma `shared` con `verificacion=OK` en `make test` al cierre o en la tarea | < 1/3 de las parejas con el histograma al cierre → el Crear se trabaja 10 min en la S04 antes de PRIMM |

## Notas post-sesión

- (se llenan después) ¿Cuántas parejas tuvieron GPU en Colab a las 11:05? ____. ¿Plan B con CUDASIM? ____.
- Recuperación: pregunta 1 ___ % / pregunta 3 ___ %. CT1 primer voto ___ % → revoto ___ %. CT2 ___ % → ___ %.
  ¿Se usó CT3? ____.
- ¿Hasta dónde llegó Investigar antes del minuto 57? ____. ¿Cuántas parejas terminaron `reduce_max`? ____. ¿El
  histograma? ____ (si se recortó Transferencia, confirmar que la tarea lo pide como ejercicio 1).
- Montones del *exit ticket*: bien ___ · parcial ___ · mal ___. Error más frecuente: ____ (abre la S04 del lunes
  30 de noviembre; por defecto la S04 asume la idea 25).
- Qué cambiar la próxima vez que se dé esta sesión: ____.
