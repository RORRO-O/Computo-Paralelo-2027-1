> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S06 · jueves 3 de diciembre de 2026 · 10:30–12:00 · Salón 3208

# Examen de práctica · Unidades IV–V (MPI y CUDA)

**40 minutos · 60 puntos · individual · sin dispositivos ni apuntes.** Misma estructura que el Examen 3 del
martes 8 de diciembre de 2026 (08:30–10:00, 80 minutos, 100 puntos, versiones A/B): seis secciones, los mismos
tipos de ítem, la misma proporción. El Examen 3 cambia números, nombres y orden de opciones, no lo que mide. El
10–20 % acumulativo de Unidades I–III va **integrado** en los problemas (eficiencia, Amdahl, protocolo de medición),
no en una sección aparte.

**Calibración.** Al recibir el examen escribe en la casilla A la calificación (0–60) que crees que vas a obtener;
al entregarlo, en la casilla B la que crees haber obtenido. Después de la corrección entre pares anota la real en C
y la brecha `B − C`. No afecta nada; sirve para saber si tu sensación de dominio coincide con tu desempeño.

| A · al recibir | B · al entregar | C · real | B − C |
|---|---|---|---|
| | | | |

Se corrige en parejas con la clave de la sección final (minutos 50–60 de la sesión). La clave trae la
justificación de cada respuesta y el número de la idea errónea del Anexo A de la que nace cada distractor.

---

## I · Opción múltiple (6 ítems × 2 puntos = 12)

Una sola opción correcta. Encierra la letra.

**I.1** Dos procesos ejecutan, cada uno, `MPI_Send` al otro y después `MPI_Recv` del otro. Con `n = 100`
`double` el programa termina con `VERIFICACION OK`; con `n = 1 000 000` se queda colgado. ¿Qué concluyes?

- **A.** El programa es correcto: `MPI_Send` es asíncrono y regresa de inmediato; el cuelgue con `n` grande es
  falta de memoria.
- **B.** El programa es incorrecto en los dos casos: `MPI_Send` puede regresar al copiar a un búfer interno
  (mensaje chico) o esperar al receptor (grande), y las dos conductas son válidas; se corrige con `MPI_Sendrecv`,
  orden por paridad o `Isend`/`Irecv` + `Wait`.
- **C.** El programa es incorrecto y Open MPI está mal: `MPI_Send` debe esperar siempre al `MPI_Recv` del otro
  lado, así que debió colgarse también con `n = 100`.
- **D.** Funciona porque son solo dos procesos; con cuatro se colgaría con cualquier `n`.

**I.2** Jacobi 1D con MPI: por iteración, cada proceso actualiza `n/p` puntos (1 ns cada uno) e intercambia dos
halos de 8 bytes (latencia α = 2 µs cada uno). Con `n = 4 000` y `p = 4` el programa tarda **más** que el
secuencial. La explicación correcta es:

- **A.** El programa tiene un error: con más procesos siempre debe tardar menos.
- **B.** Es sobre-suscripción: 4 procesos en 4 núcleos ya saturan la máquina.
- **C.** La comunicación domina: 2α = 4 µs por iteración contra 1 µs de cómputo por proceso; el modelo
  `T_p = (n/p)·t_c + 2α` predice `S < 1` por debajo de `n ≈ 5 300`.
- **D.** Se midió con `-O2`; con `-O0` el cómputo pesaría más y el *speedup* aparecería.

**I.3** La hoja de datos de la Tesla T4 dice "2 560 núcleos CUDA". Lanzas `kernel<<<65536, 256>>>`
(16 777 216 hilos). ¿Cuál afirmación es correcta?

- **A.** Solo 2 560 hilos existen a la vez; los demás entran uno por uno conforme un núcleo se libera, como
  procesos en una CPU.
- **B.** Los hilos se agrupan en *warps* de 32 que ejecutan la misma instrucción; cada SM mantiene varios *warps*
  residentes y cambia entre ellos para ocultar la latencia de memoria.
- **C.** Cada hilo corre en su propio núcleo con su propio predictor de saltos, así que un `if` dentro del *kernel*
  no cuesta nada.
- **D.** El lanzamiento falla con `invalid configuration argument`: no se pueden lanzar más hilos que núcleos.

**I.4** La multiplicación de matrices por mosaicos (*tiling*) con `TILE = 16` es más rápida que la ingenua porque:

- **A.** La memoria compartida es tan rápida como la global pero más grande, así que cabe más de la matriz.
- **B.** Cada elemento de A y de B se lee de memoria global `n/16` veces en lugar de `n`: el bloque lo carga una
  vez a memoria compartida (uno o dos órdenes de magnitud más rápida) y 16 hilos lo reutilizan.
- **C.** Usa más hilos por bloque, y más hilos siempre es más rápido.
- **D.** Las dos llamadas a `__syncthreads()` aceleran el *kernel* al ordenar los accesos.

**I.5** Barrido de tamaño de bloque de un *kernel* *memory-bound* en una T4, medianas de 5: 32 → 1.60 ms ·
64 → 1.00 · 128 → 0.88 · 256 → 0.85 · 1024 → 0.90. ¿Qué explica **mejor** que 32 sea el peor y 1024 no sea el mejor?

- **A.** El 0.90 es ruido: una corrida más y 1024 sería el mejor, porque más hilos por bloque es más rápido.
- **B.** Con 32 hilos cada SM solo admite 16 bloques residentes = 16 *warps* de 32 posibles (50 % de ocupación);
  con 1024 la ocupación ya no sube y quedan menos bloques para balancear el final.
- **C.** Cualquier múltiplo de 32 rinde igual; las diferencias son ruido y no hay nada que explicar.
- **D.** 1024 excede el máximo de hilos por bloque; el *kernel* no corrió y por eso "tardó" 0.90 ms.

**I.6** Un *kernel* de reducción deja una suma parcial por bloque en `partial[blockIdx.x]`. Un compañero propone
que, tras un `__syncthreads()`, el hilo 0 del **bloque 0** sume `partial[0..gridDim.x)` y así evitar la segunda
etapa en el anfitrión. ¿Funciona?

- **A.** Sí: `__syncthreads()` espera a que todos los bloques hayan escrito su parcial.
- **B.** No: `__syncthreads()` solo sincroniza los hilos de **su** bloque; entre bloques solo se sincroniza al
  terminar el *kernel* (segunda etapa en el anfitrión, un segundo *kernel* o atómicas).
- **C.** Sí, si el hilo 0 llama a `cudaDeviceSynchronize()` dentro del *kernel* antes de sumar.
- **D.** Sí, porque los bloques se ejecutan en orden de índice y el bloque 0 es el último en terminar.

## II · Predecir la salida (13 puntos)

**II.1 (7 puntos).** Se compila con `mpicc` y se ejecuta con `mpirun -np 4`. Escribe la salida completa (cuatro
líneas, en cualquier orden) y contesta los incisos.

```c
int rank, size, value, total = 0, from_left = -1, max_root = 0;
MPI_Init(&argc, &argv);
MPI_Comm_rank(MPI_COMM_WORLD, &rank);
MPI_Comm_size(MPI_COMM_WORLD, &size);
value = rank + 1;
int right = (rank + 1) % size, left = (rank + size - 1) % size;
MPI_Allreduce(&value, &total, 1, MPI_INT, MPI_SUM, MPI_COMM_WORLD);
MPI_Sendrecv(&value, 1, MPI_INT, right, 7, &from_left, 1, MPI_INT, left, 7,
             MPI_COMM_WORLD, MPI_STATUS_IGNORE);
MPI_Reduce(&from_left, &max_root, 1, MPI_INT, MPI_MAX, 0, MPI_COMM_WORLD);
printf("rango %d: value=%d total=%d from_left=%d max_root=%d\n", rank, value, total, from_left, max_root);
MPI_Finalize();
```

(a) Las cuatro líneas (4 puntos: 1 por columna correcta en los cuatro rangos: `value`/`total`, `from_left`,
`max_root`, y 1 por el orden "cualquiera"). (b) ¿Por qué `total` vale lo mismo en los cuatro rangos y `max_root`
no? (1 punto). (c) Si la raíz del `MPI_Reduce` fuera el rango 3 en lugar del 0, ¿qué cambiaría? (1 punto).
(d) Salida con `mpirun -np 1` (1 punto).

**II.2 (6 puntos).** `n = 10`, `data = {0,1,…,9}`, lanzamiento `reverse_in_block<<<3, 4>>>(d, n)`:

```c
__global__ void reverse_in_block(int *data, int n) {
    __shared__ int s[4];
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) s[threadIdx.x] = data[i];
    __syncthreads();
    int j = blockDim.x - 1 - threadIdx.x;            /* posición espejo dentro del bloque */
    int src = blockIdx.x * blockDim.x + j;           /* índice global de esa posición */
    if (i < n && src < n) data[i] = s[j];
}
```

(a) Escribe el contenido final de `data` (4 puntos: 1 por bloque correcto, 1 por el bloque 2 completo).
(b) ¿Por qué los elementos 8 y 9 no se invierten entre sí, y qué pasaría con ellos si la última guardia fuera solo
`if (i < n)`? (2 puntos).

## III · Encontrar y corregir el error (10 puntos)

**III.1 (5 puntos).** Cuatro procesos; la raíz reparte `x = {1,…,8}` en bloques de 2 y **cada rango debe restar
la media global (4.5) a su bloque**. El programa compila sin *warnings*, no se cuelga, y la salida (ordenada) es:

```
rango 0: media=4.50 centrado=-3.50 -2.50
rango 1: media=0.00 centrado=3.00 4.00
rango 2: media=0.00 centrado=5.00 6.00
rango 3: media=0.00 centrado=7.00 8.00
```

```c
double x[8], local[2], local_sum, total = 0.0;
if (rank == 0) for (int i = 0; i < n; i++) x[i] = i + 1.0;
MPI_Scatter(x, 2, MPI_DOUBLE, local, 2, MPI_DOUBLE, 0, MPI_COMM_WORLD);
local_sum = local[0] + local[1];
MPI_Reduce(&local_sum, &total, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
double mean = total / n;
local[0] -= mean;  local[1] -= mean;
printf("rango %d: media=%.2f centrado=%.2f %.2f\n", rank, mean, local[0], local[1]);
```

(a) ¿Cuál es el error y en qué línea? (2 puntos). (b) Corrígelo cambiando **una** llamada (2 puntos). (c) ¿Por qué
el programa no se cuelga ni imprime ningún error de MPI? (1 punto).

**III.2 (5 puntos).** Histograma de 8 bins; `v[i] = i % 8`, así que cada bin debe valer `n / 8`. Con `n = 2^20` en
una T4 la salida es `hist_gpu=[…]` con `total_gpu` mucho menor que 1 048 576, distinto en cada corrida,
`cudaGetLastError=no error` y `verificacion=FALLA`.

```c
__global__ void hist8(const unsigned char *v, unsigned int *hist, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) {
        hist[v[i]] += 1;
    }
}
```

(a) ¿Cuál es el error? (2 puntos). (b) Corrígelo con **una** llamada de la API de CUDA (2 puntos). (c) ¿Por qué el
total es **menor** que `n` (y nunca mayor) y por qué cambia entre corridas? (1 punto).

## IV · Completar código (10 puntos)

**IV.a (6 puntos).** Producto punto distribuido, `n = 8` divisible entre `size`; `x[i] = i + 1`, `y[i] = 1`; la
raíz imprime `dot=36.000000`. Llena los tres huecos.

```c
int local_n = n / size;
double *local_x = malloc(local_n * sizeof(double));
double *local_y = malloc(local_n * sizeof(double));
MPI_Scatter(x, ___(1)___, MPI_DOUBLE, local_x, ___(1)___, MPI_DOUBLE, 0, MPI_COMM_WORLD);
MPI_Scatter(y, ___(1)___, MPI_DOUBLE, local_y, ___(1)___, MPI_DOUBLE, 0, MPI_COMM_WORLD);
double local_dot = 0.0, dot = 0.0;
for (int i = 0; i < local_n; i++) local_dot += local_x[i] * local_y[i];
___(2)___(&local_dot, &dot, 1, ___(3)___, ___(3)___, 0, MPI_COMM_WORLD);
if (rank == 0) printf("dot=%f\n", dot);
```

(1) la cuenta de elementos que recibe **cada** proceso, igual en el envío y en la recepción (2 puntos); (2) la
colectiva que junta en la raíz (2 puntos); (3) el tipo MPI y la operación (2 puntos).

**IV.b (4 puntos).** `y[i] = a·x[i] + b` para `i < n`; `block = 256`. Un punto por hueco.

```c
__global__ void axpb(const float *x, float *y, float a, float b, int n) {
    int i = ___(1)___;
    if (___(2)___) y[i] = a * x[i] + b;
}
/* anfitrión */
int grid = ___(3)___;
axpb<<<grid, block>>>(d_x, d_y, a, b, n);
cudaError_t launch_err = ___(4)___();        /* ¿fue válido el lanzamiento? */
```

## V · Problema numérico (9 puntos)

**V.a (4 puntos) · Jacobi 1D con MPI.** Por iteración, cada proceso actualiza `n/p` puntos a `t_c = 1 ns` por punto
e intercambia dos halos de 8 bytes; cada mensaje cuesta `α = 2 µs` (el término `m/β` es despreciable). Modelo:
`T_1 = n·t_c`, `T_p = (n/p)·t_c + 2α`. Con `p = 4`:

(i) `S(4)` y (ii) `E(4)` para `n = 1 000 000` (1 punto cada uno). (iii) `S(4)` para `n = 10 000` (1 punto).
(iv) ¿A partir de qué `n` conviene usar los 4 procesos (`S > 1`)? (1 punto).

**V.b (5 puntos) · Un *kernel* en Colab.** Medianas de 5 en una T4: *kernel* 1.5 ms; copia H2D 24 ms; copia D2H
12 ms (memoria paginable). La V1 en la CPU de la misma máquina virtual tarda 90 ms.

(i) *Speedup* contando solo el *kernel* (1 punto). (ii) *Speedup* contando las copias (2 puntos). (iii) Si el
*kernel* se repite 100 iteraciones sobre los mismos datos (se copia una vez de subida y una de bajada) y la V1
tarda 100 × 90 ms, ¿cuál es el *speedup* con copias? (1 punto). (iv) ¿Cuál de los números de (i) y (ii) va en tu
reporte? (1 punto).

## VI · Diseño breve (6 puntos; ≤ 10 líneas en total)

Un equipo simula difusión de calor con un *stencil* de 5 puntos sobre una malla de `8 192 × 8 192` `float`
(256 MB por malla, dos mallas por doble búfer) durante 10 000 iteraciones. Tienen: (1) una laptop de 4 núcleos,
(2) un clúster de 8 nodos de 4 núcleos con Ethernet (`α ≈ 50 µs`, `β ≈ 100 MB/s`), (3) Colab con una T4 (16 GB).

(a) Elige **una** plataforma (OpenMP, MPI o GPU) y justifícala con **dos datos numéricos** del problema (memoria,
bytes transferidos, cómputo por iteración, costo de comunicación) (4 puntos).
(b) Di qué cambiaría tu decisión si la malla fuera de `65 536 × 65 536` (16 GB por malla) (2 puntos).

---

## Tabla de especificaciones (para verificar la cobertura; el Examen 3 usa la misma, escalada a 100)

| Tema | Recordar / Comprender | Aplicar / Analizar | Evaluar / Crear | Puntos |
|---|---|---|---|---|
| MPI: punto a punto, colectivas, SPMD (U4 S01–S04) | I.1 (2), II.1b–c (2), III.1c (1) | II.1a,d (5), III.1a–b (4), IV.a (6) | | 20 |
| Modelo de costo, escalabilidad, eficiencia (U4 S05; U I–III) | I.2 (2) | V.a i–iii (3) | V.a iv (1) | 6 |
| Modelo CUDA, índices, guardia, memoria (U5 S01–S02) | I.3 (2), I.4 (2), II.2b (2) | II.2a (4), IV.b (4) | | 14 |
| Sincronización y atómicas (U5 S03) | I.6 (2), III.2c (1) | III.2a–b (4) | | 7 |
| Rendimiento en GPU: transferencias, bloque (U5 S04–S05) | I.5 (2) | V.b i–iii (4) | V.b iv (1) | 7 |
| Diseño: elegir plataforma | | | VI (6) | 6 |
| **Total** | **17 (28 %)** | **35 (58 %)** | **8 (13 %)** | **60** |

Acumulativo de Unidades I–III integrado: eficiencia y umbral de escalabilidad (V.a), protocolo de medición (I.5,
V.b), "más hilos siempre es más rápido" (I.2 A, I.5 A, idea 1), medición única (I.5 C, idea 5), opción OpenMP en VI:
≈ 8 puntos (13 %). El Examen 3 (100 puntos) agrega un segundo ítem de diseño para llegar al 20 % de Evaluar/Crear.

---

<details><summary><strong>Clave con justificación</strong> (ábrela a los 50 minutos; para la corrección entre pares)</summary>

### I · Opción múltiple (2 puntos cada una; sin puntos parciales)

| Ítem | Respuesta | Justificación | Origen de los distractores (Anexo A) |
|---|---|---|---|
| I.1 | **B** | `MPI_Send` solo promete que el búfer se puede reutilizar; el envío inmediato con mensajes chicos (≈ 4 KB en Open MPI local) es una cortesía, no una garantía. Un programa que depende de eso es inseguro | A: 17 ("siempre regresa de inmediato") · C: 17 ("siempre bloquea") · D: nueva 17b (confunde número de procesos con la condición) |
| I.2 | **C** | Cómputo por proceso: `1 000 × 1 ns = 1 µs`; comunicación `2α = 4 µs`; `T_4 = 5 µs > T_1 = 4 µs`. Umbral: `n·1 ns > (n/4)·1 ns + 4 µs` → `n > 5 333` | A: 1 (más procesos siempre más rápido) · B: 20 (sobre-suscripción; 4 en 4 núcleos no lo es) · D: 5 (medir con `-O0`) |
| I.3 | **B** | La unidad de ejecución es el *warp*; un SM de T4 tiene hasta 32 *warps* residentes y los 65 536 bloques entran en oleadas | A, C: 22 (hilo CUDA = núcleo de CPU) · D: 22 + límite real de 1 024 hilos **por bloque** |
| I.4 | **B** | Lecturas de A: `n³` frente a `n³/16` (S02 §3); la compartida está uno o dos órdenes de magnitud más cerca que la global | A: 23 (global tan rápida como compartida) · C: 1 · D: nueva ("la barrera acelera"; sincroniza, cuesta) |
| I.5 | **B** | Ocupación 50 % con bloques de 32 (16 bloques × 1 *warp*); de 64 en adelante 100 %; 1 024 no sube más y deja 16 384 bloques en vez de 65 536 | A: 1 + 5 · C: 26 (cualquier tamaño igual) · D: 27 (un lanzamiento inválido se ve en `cudaGetLastError`, no en el tiempo) |
| I.6 | **B** | `__syncthreads()` es una barrera de **bloque**; los bloques pueden correr en cualquier orden y no todos a la vez | A: 25 (sincroniza toda la GPU) · C: 33/25 (`cudaDeviceSynchronize` es una llamada de anfitrión) · D: nueva ("los bloques corren en orden de índice") |

### II · Predecir la salida

**II.1** (salida real con `mpirun -np 4`, ordenada por rango):

```
rango 0: value=1 total=10 from_left=4 max_root=4
rango 1: value=2 total=10 from_left=1 max_root=0
rango 2: value=3 total=10 from_left=2 max_root=0
rango 3: value=4 total=10 from_left=3 max_root=0
```

(a) `total = 1+2+3+4 = 10` en todos (`Allreduce`); `from_left` es el `value` del vecino izquierdo
(`(rank+3) % 4`): el rango 0 recibe del 3 (`4`), el 1 del 0 (`1`), etc.; `max_root = max(4,1,2,3) = 4` **solo en
la raíz**, los demás conservan su `0` inicial. Orden de las líneas: cualquiera (cuatro procesos imprimen sin
coordinarse). (b) `Allreduce` deja el resultado en todos; `Reduce` solo en la raíz y no toca el búfer de los demás
(idea 16: no hay memoria compartida). (c) Solo cambia **dónde** queda el máximo: `max_root=4` en el rango 3 y `0` en
los otros tres; que la raíz sea el 0 es una convención, no una regla (idea 19). (d) Con un proceso `right = left = 0`:
`rango 0: value=1 total=1 from_left=1 max_root=1` (salida real).

Puntuación: (a) 1 punto por `value`/`total` correctos, 1 por `from_left`, 1 por `max_root` (incluido el `0` en los
rangos 1–3), 1 por decir que el orden no está garantizado; (b), (c), (d) 1 punto cada uno.

**II.2** Salida real (CUDASIM y, esperada, GPU): `3 2 1 0 7 6 5 4 8 9`.

(a) Bloques 0 y 1 (4 hilos, 4 elementos cada uno): cada hilo escribe `data[i] = s[3 − threadIdx.x]`, la inversión
local. Bloque 2: solo los hilos 0 y 1 tienen `i < n` (`i = 8, 9`); sus espejos son `j = 3, 2` → `src = 11, 10 ≥ n`:
la segunda guardia es falsa y **no escriben**; `data[8]` y `data[9]` se quedan como estaban. (b) No se invierten
entre sí porque el espejo se calcula dentro del bloque de 4, no dentro de los 2 elementos válidos. Con solo
`if (i < n)`, los hilos 8 y 9 escribirían `s[3]` y `s[2]`, que **nadie cargó** (memoria compartida sin inicializar):
basura, distinta en cada corrida, sin ningún error de CUDA (idea 27).

Puntuación: (a) 1 punto por cada bloque (0, 1, 2) y 1 por explicar que 8 y 9 no cambian; (b) 1 punto por "espejo
dentro del bloque de 4", 1 por "memoria compartida sin inicializar / basura".

### III · Encontrar y corregir el error

**III.1** (a) `MPI_Reduce` deja `total` **solo en la raíz**; los rangos 1–3 usan el `0.0` con que inicializaron
`total` (línea del `MPI_Reduce`; idea 16: cada proceso tiene su memoria). (b) `MPI_Allreduce(&local_sum, &total, 1,
MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);` (también vale `MPI_Reduce` + `MPI_Bcast(&total, 1, MPI_DOUBLE, 0, …)`, con 1
punto menos por usar dos llamadas cuando una basta). Salida real corregida: los cuatro rangos imprimen
`media=4.50` y `centrado` = `-3.50 -2.50 / -1.50 -0.50 / 0.50 1.50 / 2.50 3.50`. (c) Todos llaman a la colectiva
con la misma raíz y los mismos argumentos: MPI hizo exactamente lo que se le pidió; no hay nada que reportar. El
error es de **diseño** (quién necesita el dato después), y solo lo detecta comparar con la referencia.

Puntuación: (a) 1 por señalar `MPI_Reduce`, 1 por "solo la raíz recibe"; (b) 2 por `Allreduce` con argumentos
correctos (1 si la idea es correcta pero faltan argumentos o se usa `Reduce` + `Bcast`); (c) 1.

**III.2** (a) `hist[v[i]] += 1` es lectura-suma-escritura en tres pasos sobre una dirección que comparten
`n/8 = 131 072` hilos: dos hilos leen el mismo valor, ambos escriben `valor + 1` y se pierde una cuenta (condición
de carrera; ideas 7 y 27: sin error ≠ correcto). (b) `atomicAdd(&hist[v[i]], 1u);`. (c) Nunca mayor porque cada
escritura perdida resta una cuenta y ninguna la duplica; cambia porque el orden en que los *warps* llegan al
contador cambia en cada lanzamiento. Nota de autoría: el simulador de Numba (`NUMBA_ENABLE_CUDASIM=1`) **no**
reproduce esta carrera (da `total_gpu=1000` exacto con `n = 1000`): ejecuta los hilos de Python con tan poca
intercalación que casi nunca separa la lectura de la escritura. Que una plataforma no muestre la carrera no la
corrige. En la GPU, con `n = 2^20`, se espera `total_gpu` de unos cientos a unos miles.

Puntuación: (a) 1 por "carrera / varios hilos escriben la misma posición", 1 por "lectura-modificación-escritura
no atómica"; (b) 2 por `atomicAdd` con la dirección correcta (1 si escriben `atomicAdd(hist[v[i]], 1)` sin `&`);
(c) 1 (las dos partes).

### IV · Completar código

**IV.a** (1) `local_n` en las cuatro posiciones (la cuenta es **por rango** y en elementos, no `n` ni bytes);
(2) `MPI_Reduce`; (3) `MPI_DOUBLE, MPI_SUM`. Salida real con `-np 4` y con `-np 2`: `dot=36.000000`. Errores que
valen 0 en el hueco: `n` o `n * sizeof(double)` en (1) (idea: cuenta total/bytes, S03 §2); `MPI_Gather` en (2)
(junta valores, no los suma); `MPI_INT` en (3) (`local_dot` es `double`). `MPI_Allreduce` en (2) con 5 argumentos
no compila con `0, MPI_COMM_WORLD`: 1 punto si lo advierten.

**IV.b** (1) `blockIdx.x * blockDim.x + threadIdx.x`; (2) `i < n`; (3) `(n + block - 1) / block`;
(4) `cudaGetLastError`. Cero puntos en (1) por `threadIdx.x` solo; en (3) por `n / block` (deja 232 elementos sin
procesar con `n = 1000`: `ejemplo-resuelto.md`, parte B); en (4) por `cudaDeviceSynchronize` (detecta errores de
**ejecución**, no de lanzamiento; medio punto si lo justifican).

### V · Problema numérico

**V.a** (i) `T_1 = 10^6 × 1 ns = 1 000 µs`; `T_4 = 250 µs + 4 µs = 254 µs`; `S(4) = 1 000 / 254 ≈ 3.94`.
(ii) `E(4) = 3.94 / 4 ≈ 0.98` (98 %). (iii) `T_1 = 10 µs`; `T_4 = 2.5 + 4 = 6.5 µs`; `S(4) ≈ 1.54`.
(iv) `S > 1` ⇔ `n·1 ns > (n/4)·1 ns + 4 µs` ⇔ `0.75·n ns > 4 000 ns` ⇔ `n > 5 333` puntos (≈ 5 300). Puntuación: 1
punto por inciso; se acepta ±5 % por redondeo; sin unidades, medio punto.

**V.b** (i) `90 / 1.5 = 60×`. (ii) `90 / (24 + 1.5 + 12) = 90 / 37.5 = 2.4×`. (iii) `9 000 / (36 + 100 × 1.5) =
9 000 / 186 ≈ 48×`: las copias se pagan una vez y el cómputo las amortiza. (iv) **Los dos**, con etiqueta: el
protocolo exige reportar con y sin transferencias; el que describe lo que gana el usuario es el de (ii) (idea 24).
Puntuación: (i) 1; (ii) 2 (1 si suman mal pero incluyen las tres partes); (iii) 1; (iv) 1 (0 si eligen solo uno).

### VI · Diseño breve

(a) Respuesta esperada: **GPU (T4)**. Datos que la sostienen (cualquier par vale): las dos mallas ocupan 512 MB y
caben en 16 GB; la copia de subida y bajada se paga **una vez** (512 MB a ≈ 4–6 GB/s ≈ 0.1 s) frente a 10 000
iteraciones de *kernel*; un *stencil* lee ≈ 5 valores y escribe 1 por punto (≈ 24 bytes, 6 FLOP: *memory-bound*,
donde una T4 da ≈ 200 GB/s contra ≈ 20–40 GB/s de la laptop → ≈ 5–10× solo por ancho de banda); un hilo por celda
da 67 millones de hilos independientes por iteración. MPI en ese clúster: halos de 8 192 × 4 B = 32 KB por
vecino y por iteración (`50 µs + 32 KB / 100 MB/s ≈ 0.38 ms` cada uno, ≈ 0.8 ms por iteración de comunicación)
contra ≈ 8 ms de cómputo por nodo en un núcleo (8 192² / 8 ≈ 8.4 millones de puntos a ≈ 1 ns; ≈ 2 ms con 4 hilos
OpenMP): **sí escala** (≈ 8 nodos × 4 núcleos ≈ 20–25× sobre un núcleo) y es
una respuesta válida con esos números; OpenMP solo en la laptop (≤ 4×) es la opción más débil, válida únicamente
si el argumento es "no hay cuota de GPU y no hay clúster". 4 puntos: 2 por la elección con dos datos numéricos
correctos del problema, 1 por descartar explícitamente una alternativa con un número, 1 por mencionar cómo se
verifica (contra la V1 con tolerancia; con/sin transferencias si es GPU).
(b) Con 16 GB por malla (32 GB con doble búfer) la T4 **no la aloja**: se necesita memoria distribuida (MPI en
los 8 nodos: 4 GB por nodo) o descomponer la malla en franjas que suben y bajan de la GPU en cada iteración, lo
que convierte el problema en uno dominado por transferencias (≈ 32 GB por iteración por PCIe). 2 puntos: 1 por
"no cabe", 1 por la alternativa con su costo.

### Los tres ítems que suelen fallar (predicción del autor; el grupo decide con manos)

III.1 (confundir dónde queda el resultado de `Reduce`), II.2 (el último bloque del *kernel*) y V.b (ii)–(iv)
(el *speedup* con copias y qué se reporta). Los tres tienen su cazador o su discusión en `plan-sesion.md`, bloque
60–72.

</details>
