> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Práctica 6 · publicada el lunes 23 de noviembre de 2026 · Lab 1 martes 24 de noviembre 08:30 · Lab 2 martes 1 de diciembre 08:30 · entrega domingo 6 de diciembre 23:59

# Rúbrica de la Práctica 6 · Aceleración en GPU con CUDA

Rúbrica analítica de cuatro niveles (`docs/metodo/03-plantilla-practica.md` §2, instanciada para esta práctica).
Pesos: 25 + 20 + 20 + 20 + 15 = 100. Cada nivel vale un porcentaje del peso del criterio: **Ejemplar 100 %**,
**Competente 80 %**, **En desarrollo 55 %**, **Insuficiente 20 %**. La calificación de la práctica es la suma; vale
15 % del 3er parcial. Se publica con el enunciado el lunes 23 de noviembre y no cambia después.

## 1. Correctitud y pruebas (25 puntos)

| Ejemplar (25) | Competente (20) | En desarrollo (13.75) | Insuficiente (5) |
|---|---|---|---|
| `make test` **y** `make test-b` terminan con código 0 sin GPU y sin *warnings*; los casos extra de calificación pasan (vectores `n = 1` y `n = 1025` con bloque 1024; mosaicos `17×17` con `TILE = 16` y `24×24` con `TILE = 8`; Parte B `1×37×3`, `17×33×5`, `33×8×17` y `12×20×30`); en GPU la Parte A da `OK` con `n = 512`, `1024` **y** `1000`, la Parte B con `512×512×512`, `1000×600×700` **y** `300×2000×900`, y la Parte C reproduce la referencia CPU en los tamaños del README (exacta en histograma/reducción; `iteraciones` iguales y malla dentro de `1e-3` en Jacobi; tolerancia declarada en la opción 3) **incluido un tamaño que no es múltiplo del bloque**; el equipo agregó a `tests/run_tests.sh` ≥ 1 caso propio que detecta un error real (p. ej. una forma rectangular con `K` mayor que `M` y que `N`, `n` no múltiplo, bloque de 1 hilo) | `make test` y `make test-b` en verde; Partes A y B `OK` en GPU con los tamaños del README; Parte C coincide con la referencia CPU en los tamaños del README; sin casos propios o con casos que no detectan nada nuevo | La Parte B pasa solo con matrices cuadradas o con dimensiones múltiplos de `TILE` (falla `20×40×12` o un caso extra), **o** la Parte C se verificó en un solo tamaño, **o** falla algún caso extra | Algún `.cu` no compila con `nvcc -c -arch=sm_75`, o `make test` falla en casos públicos, o la Parte C no se compara contra la CPU ("no dio error" no es verificación: idea errónea 27) |

## 2. Diseño paralelo (20 puntos)

| Ejemplar (20) | Competente (16) | En desarrollo (11) | Insuficiente (4) |
|---|---|---|---|
| Partes A y B: cada `__syncthreads()` y la guardia de escritura se justifican con lo que fallaría sin ellos (lectura de mosaico incompleto; sobreescritura en la fase `t+1`; hilos que no llegan a la barrera ni cargan sus ceros si hay `return` temprano), y cada corrección de la Parte B con la forma de la matriz (`cols` como longitud de fila, fases a lo largo de `K`, `M×K` y `K×N` en las cargas, `col < N` y `row·N` en la escritura). Parte C: *kernel* propio con el patrón de la opción elegida (atómicas en `__shared__` y volcado a global; doble búfer en el dispositivo sin copias entre iteraciones y reducción máxima; o el ciclo caliente de la V1 con el mapeo declarado); tamaño de bloque elegido con **dos** datos (múltiplo de 32 y ocupación de `ocupacion_pct` o memoria compartida por bloque); los datos cruzan PCIe una vez de ida y una de regreso; sin sincronización ni atómicas que el diseño no necesite (se compara con una alternativa descartada y su tiempo) | Diseño correcto con el patrón de la opción; bloque justificado con un dato; alguna ineficiencia (p. ej. `cudaMemcpy` del criterio de paro en cada iteración, atómicas globales por elemento) identificada y explicada en el reporte | Funciona, pero el bloque se eligió "porque sí" o solo por ser múltiplo de 32, o hay copias dentro del ciclo de iteraciones sin explicación, o la Parte C usa atómicas globales por elemento sin comparar, o las correcciones de la Parte B no se explican | Paralelización incorrecta (varios hilos escriben el mismo acumulador sin atómica; barrera dentro de un `if`; `return` antes de `__syncthreads`) o ausente (la Parte C es una biblioteca sin *kernel* propio) |

## 3. Medición (20 puntos)

| Ejemplar (20) | Competente (16) | En desarrollo (11) | Insuficiente (4) |
|---|---|---|---|
| CSV con `origen=gpu` y el esquema del curso: 1 calentamiento + 5 repeticiones, mediana, para el barrido de bloque **32, 64, 128, 256, 512, 1024** de los *kernels* de la Parte A y del de la Parte C, el barrido `umbral` de `n` (`2^10`…`2^26`) y `matmul_naive`/`matmul_tiled` con `n = 512, 1024, 2048` y `TILE = 8, 16, 32`, más las filas `matmul_rect_*` de las tres formas de la Parte B; cada fila con `t_h2d`, `t_kernel`, `t_d2h` y `t_cpu` de la **misma máquina** con `-O2`; `entorno.txt` con modelo de GPU (`nvidia-smi`), `compute_cap`, versión de `nvcc` y fecha; las tres PNG con ejes rotulados y unidades; el reporte señala el bloque óptimo con su tiempo y el primer `n` con *speedup* > 1 sin y con copias, y da la causa con un dato (porcentaje de copias, ocupación del bloque de 32, ancho de banda alcanzado frente a 320 GB/s) | Tabla y gráficas completas según el protocolo (todos los barridos, dos tiempos, `T(1)` de la misma máquina, GPU y fecha); el bloque óptimo y el umbral se señalan pero la causa se describe sin el dato que la explica | Faltan repeticiones, tamaños del barrido (menos de 6 bloques o menos de 4 `n`), alguna de las tres PNG, el `T(1)` se midió en otra máquina sin decirlo, o falta `entorno.txt` | Sin mediciones, una sola corrida, tiempos sin sincronizar (*kernel* de microsegundos con `n = 2^24`), sin modelo de GPU, o solo el tiempo del *kernel* sin las copias (idea errónea 24) |

## 4. Interpretación y reflexión (20 puntos)

| Ejemplar (20) | Competente (16) | En desarrollo (11) | Insuficiente (4) |
|---|---|---|---|
| Las tres preguntas de la Parte D se responden con un número cada una: (1) *memory-bound* o *compute-bound* con la intensidad aritmética calculada (FLOP por byte) frente al balance de la T4 (≈ 25 FLOP/byte) y el ancho de banda alcanzado; (2) umbral de `n` sin y con copias leído del CSV, y qué fracción del total son las copias en `n = 2^24`; (3) ocupación del bloque de 32 frente a 256 y su efecto medido; se compara con la predicción del pre-laboratorio y se explica el desajuste; la de mosaicos frente a la ingenua se explica con el cociente de lecturas (`TILE`) **y** con por qué el cociente de tiempos es menor (cachés, barreras, ocupación); se explica por qué el porcentaje de copias de la multiplicación baja al crecer `n` y el de `saxpy` no; reflexión individual de cada integrante con la pregunta de autoexplicación y la de transferencia a la V3 | Las tres preguntas respondidas correctamente con datos del CSV; comparación con la predicción; reflexiones individuales presentes; falta uno de los razonamientos (p. ej. por qué `TILE = 32` no es 2× más rápido que `TILE = 16`) | Describe las gráficas ("sube", "baja") sin explicar la causa, o la clasificación *memory/compute-bound* se afirma sin la intensidad aritmética, o no compara con la predicción | Ausente, o incorrecta (p. ej. "la GPU es 2 560 veces más rápida porque tiene 2 560 núcleos", idea errónea 22; "las copias no cuentan", idea 24) |

## 5. Proceso e integridad (15 puntos; se ajusta por integrante)

| Ejemplar (15) | Competente (12) | En desarrollo (8.25) | Insuficiente (3) |
|---|---|---|---|
| Cada integrante tiene ≥ 3 *commits* con cambios de código; bitácora con ≥ 3 entradas (síntoma, causa, cómo se detectó, *commit*), al menos una sobre un error que "a veces salía bien" o que no daba error de CUDA; declaración de IA con las cuatro líneas y la verificación descrita (compilación con `-Wall -Wextra`, CUDASIM, comparación con la CPU); en la mini-defensa cada integrante explica la línea de su parte **y** una función ajena; el *notebook* entregado está ejecutado con salidas | Cada integrante con ≥ 3 *commits* de código; bitácora con ≥ 2 entradas; declaración de IA con las cuatro líneas; cada integrante responde la pregunta de su parte en la mini-defensa; *notebook* ejecutado | Algún integrante con < 3 *commits* de código sin explicación en el reparto, o bitácora con 1 entrada, o declaración incompleta, o *notebook* sin salidas | Un integrante no explica la línea que firmó (prueba de propiedad, `docs/metodo/05-politica-ia.md`), o no hay bitácora ni declaración, o el *notebook* no se entregó |

## Responsabilidad individual

Las preguntas individuales se hacen en el Laboratorio 2 (martes 1 de diciembre); con más de 12 equipos, la mitad en el
Laboratorio 1 (martes 24 de noviembre) con lista publicada ese día. Una pregunta por integrante sobre la parte que
firmó; la segunda solo si la primera falla, y cuenta la mejor de las dos. Quien lo pide responde por escrito en el
momento (5 min, papel). Mini-defensa pendiente: se repone en el siguiente laboratorio; si ya no hay uno antes del
cierre o el estudiante no puede, envía un video no listado de ≤ 3 min en el que explica dos fragmentos de su código
que elige el profesor, a más tardar el martes 15 de diciembre, 08:30. El lunes 7 de diciembre el profesor pregunta a
un integrante al azar de 2–3 equipos qué cambió desde el laboratorio. Consecuencia (fijada en
`docs/metodo/05-politica-ia.md`, "Prueba de propiedad"): el criterio 5 baja a Insuficiente **para ese integrante**, no
para el equipo; si además hay indicios de copia, aplica `docs/metodo/04-evaluacion.md` §6.

## Cómo se aplica

1. Criterios 1 y 3 se evalúan primero con `make test`, `make test-b`, `EXTRA=1 bash tests/run_tests.sh`, el CSV y
   `entorno.txt`; el *notebook* ejecutado confirma que lo que dice el CSV se corrió en la GPU que dice.
2. Criterios 2 y 4 se evalúan con `REPORTE.md` y el código; una afirmación sin número se califica en el nivel inferior.
3. Criterio 5 se evalúa con `git log --author`, la hoja de registro de las mini-defensas y la declaración de IA.
4. Mediciones pendientes por cuota (`entrega.md` §6) con evidencia fechada: el criterio 3 se califica cuando llega la
   medición (a más tardar el martes 15 de diciembre, 08:30) sin descuento; sin evidencia, aplica el nivel que
   corresponda a lo entregado.

## Lo que esta rúbrica no premia

Puntos extra por la extensión opcional (*streams* o CuPy): no hay; se reconoce en la defensa del proyecto. Velocidad
absoluta: no se califica cuánto tarda tu *kernel* (la GPU asignada cambia), sino que esté medido como pide el
protocolo y explicado con los datos que produjo.
