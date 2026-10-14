> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S02 · martes 24 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# Tarea espaciada · S02 (20–40 min)

**Esta tarea no tiene peso propio; el examen de práctica del jueves 3 de diciembre y el 10–20 % acumulativo
del Examen 3 toman ítems de aquí.** Se autocalifica con las claves de abajo al inicio de S03 (jueves 26 de
noviembre de 2026, 10:30, salón 3208; 2 minutos); el profesor registra la entrega, no el acierto, y revisa 3 al
azar por parcial. Tráela en papel o como `tarea-S02.md` en el repositorio del equipo (una por persona, con tu
nombre solo en el *commit*). La tabla del ejercicio 1 se incorpora a la Parte D de la Práctica 6 (15 % del 3er
parcial, domingo 6 de diciembre, 23:59); los ejercicios 2 y 3 son del tipo que aparece en el Examen 3 (30 %,
martes 8 de diciembre).

## 1. Del tema de hoy (18 min) · tamaño del mosaico y dónde vive cada dato

Corre los pasos 5 y 6 del `notebook_colab.ipynb` de la práctica guiada en Colab o Kaggle. Llena:

| `n` | naive `BLOCK=16` (ms) | tiled `TILE=8` (ms) | tiled `TILE=16` (ms) | tiled `TILE=32` (ms) | GPU y fecha |
|---|---|---|---|---|---|
| 1024 | | | | | |
| 2048 | | | | | |

Después contesta en ≤ 6 líneas: (a) ¿cuántas lecturas a memoria global hace cada `TILE` para `n = 1024`
(fórmula y número)? (b) `TILE=32` hace la mitad de lecturas que `TILE=16`: ¿tardó la mitad? Da al menos
dos razones de lo que observaste (cachés, hilos y memoria compartida por bloque, cuántos bloques caben
por SM, barreras). (c) ¿Qué pasó con `TILE=64` y qué llamada lo detectó?

(d) Elige **registro · compartida · global · constante** y justifica en una línea, pensando en el *kernel*
por mosaicos y en el SAXPY de la Parte A de la Práctica 6: (i) el acumulador `acc`; (ii) el mosaico `s_A`;
(iii) la matriz `C`; (iv) el escalar `alpha` de SAXPY, que leen todos los hilos. ¿Cuál de las cuatro admite
dos respuestas razonables?

<details><summary>Clave del ejercicio 1 (a, c y d; la b depende de tu GPU)</summary>

(a) `2·n²·⌈n/TILE⌉` con `n = 1024`: `TILE=8` → 268 435 456; `TILE=16` → 134 217 728; `TILE=32` →
67 108 864 (ingenua: `2·n³ = 2 147 483 648`).
(b) No: entre `TILE=16` y `TILE=32` lo típico es 1.0–1.5×, no 2×. Razones válidas: la L1/L2 ya absorbe parte
de las lecturas repetidas; con `TILE=32` el bloque tiene 1024 hilos y 8 KB de compartida, así que caben menos
bloques por SM (menos *warps* para ocultar latencia); cada barrera espera a 32 *warps* en lugar de 8; el
*kernel* pasa a estar limitado por cómputo y sincronización. Se formaliza el lunes 30 de noviembre (S04).
(c) No se lanza: 4096 hilos por bloque > 1024. Lo detecta `cudaGetLastError()` tras el lanzamiento
(`invalid configuration argument`); el programa termina con código distinto de 0.
(d) (i) registro: lo usa un solo hilo. (ii) compartida: lo cargan y lo leen los `TILE²` hilos del bloque en la
misma fase. (iii) global: la escriben todos los bloques y la lee el anfitrión con `cudaMemcpy`.
(iv) constante (`__constant__`) **o** un argumento del *kernel* (que también viaja por memoria constante):
todos los hilos leen la misma dirección, el caso ideal de esa caché. La (iv) es la que admite dos respuestas;
en (i)–(iii) solo hay una.
</details>

## 2. Intercalado (10 min) · Unidad IV y Unidad I

(a) Con el modelo de costo de MPI (`T = latencia + tamaño / ancho de banda`, latencia 5 µs, 2 GB/s):
¿cuánto tarda enviar 32 mensajes de 4 bytes? ¿Y 1 mensaje de 128 bytes? Explica en dos líneas por qué un
*warp* que lee 32 `float` saltados se parece al primer caso y uno que los lee contiguos, al segundo.

(b) La V2 de tu proyecto tiene una fracción secuencial medida de 8 %. Con Amdahl, ¿cuál es el *speedup*
máximo con 8 hilos y cuál el límite con infinitos? Si en la V3 el *kernel* de GPU se lleva el 92 % restante
y lo acelera 20×, ¿qué *speedup* total obtienes? ¿Qué te dice eso sobre dónde hay que trabajar ahora?

<details><summary>Respuestas del ejercicio 2</summary>

(a) 32 mensajes: `32 · (5 µs + 4 B / 2·10⁹ B/s) = 32 · 5.002 µs ≈ 160 µs`. Un mensaje de 128 B:
`5 µs + 0.064 µs ≈ 5.06 µs`. Domina la latencia por mensaje; en memoria global el costo por transacción es
el análogo: 32 segmentos para 128 bytes útiles frente a un segmento.
(b) `S(8) = 1 / (0.08 + 0.92/8) = 1 / 0.195 ≈ 5.1`. Límite `1/0.08 = 12.5`. Con el 92 % acelerado 20×:
`1 / (0.08 + 0.92/20) = 1 / 0.126 ≈ 7.9`. La parte secuencial (y las transferencias, que caen en ella)
limita todo: antes de optimizar más el *kernel*, hay que reducir ese 8 %.
</details>

## 3. Preparación de S03 (jueves 26 de noviembre, 10:30) · sincronización y reducción (10 min)

Lee en la *CUDA C++ Programming Guide* la descripción de `__syncthreads()` (sección "Synchronization
Functions") y responde por escrito, sin correr nada (es una predicción: se contrasta el jueves, no tiene clave):

1. Un bloque de 256 hilos suma 256 números que ya están en memoria compartida reduciendo "en árbol": en
   cada paso la mitad de los hilos suma pares. ¿Cuántos pasos hay? ¿Cuántas `__syncthreads()` necesitas y
   dónde van?
2. Predicción: en el último paso trabaja un solo hilo. ¿Qué fracción del bloque está ociosa en promedio a lo
   largo de la reducción? ¿Qué pasa con los 32 hilos de un *warp* si solo los pares (`threadIdx.x % 2 == 0`)
   ejecutan la suma?
3. Si hay 1000 bloques, cada uno produce una suma parcial. ¿Puede `__syncthreads()` combinar las 1000
   parciales? ¿Qué alternativas se te ocurren? (Se discute el jueves; trae tu respuesta.)
