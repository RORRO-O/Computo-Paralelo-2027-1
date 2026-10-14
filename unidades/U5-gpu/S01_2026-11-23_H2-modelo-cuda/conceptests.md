> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S01 · lunes 23 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# ConcepTests · S01

Secuencia: voto individual (1 min) → discusión en parejas (2 min) → revoto → explicación (2 min). Si el primer voto
supera 80 % de aciertos, se salta la discusión; si queda por debajo de 30 %, se reexplica antes de discutir. Se vota
con dedos (1–4) o tarjetas. CT1 va en Instrucción explícita I; CT2 en la puesta en común; CT3 es reserva (si sobra
tiempo en la puesta en común; si no, abre la recuperación de la S02 del martes 24 de noviembre).

## CT1 · ¿Qué es un "núcleo CUDA"? (idea errónea 22)

Una Tesla T4 tiene 40 SM y 2560 "núcleos CUDA". Lanzas `vector_add<<<65536, 256>>>` para `n = 2^24`
(16 777 216 hilos). ¿Cuál afirmación es correcta?

- **A.** Solo pueden existir 2560 hilos a la vez; los demás esperan en una cola y entran uno por uno conforme un
  núcleo se libera, como procesos en una CPU.
- **B.** Los hilos se agrupan en *warps* de 32 que ejecutan la misma instrucción; cada SM mantiene muchos *warps*
  residentes y cambia entre ellos para ocultar la latencia de memoria.
- **C.** Cada hilo CUDA corre en su propio núcleo, con su propio predictor de saltos y caché, así que un `if` dentro
  del *kernel* no cuesta nada.
- **D.** Lanzar 16.7 millones de hilos es un error: CUDA solo permite tantos hilos como núcleos CUDA y el
  lanzamiento falla con `invalid configuration argument`.

**Respuesta: B.**

| Distractor | Origen |
|---|---|
| A | Anexo A n.º 22: "un hilo CUDA = un núcleo de CPU"; modelo de cola de procesos |
| C | Anexo A n.º 22, variante: atribuye al hilo el control de flujo que en SIMT pertenece al *warp* |
| D | Anexo A n.º 22 + confusión de límites de lanzamiento (el límite real es 1024 hilos **por bloque** y 2^31−1 bloques en `x`) |

**Acierto esperado en el primer voto: ~45 %.** Es la primera sesión de GPU y la analogía con núcleos de CPU es la
que traen.

**Guion de discusión (3 líneas).** "Pregunta a tu pareja: si solo hubiera 2560 hilos a la vez, ¿cómo se repartirían
los 65 536 bloques?" → Tras el revoto: la unidad de ejecución es el *warp*, no el hilo; un SM de T4 tiene hasta 32
*warps* residentes (1024 hilos) y los bloques entran en oleadas. → Cierre: "por eso la regla es lanzar **muchos**
hilos ligeros, no pocos pesados; mañana veremos qué pasa cuando el *warp* diverge".

## CT2 · Bloques, índice y guardia (ideas erróneas 26 y confusión de índice)

`n = 1000`, `block = 256`. ¿Cuántos bloques lanzas y qué hace el hilo `threadIdx.x = 232` del bloque `blockIdx.x = 3`?

- **A.** 3 bloques (`1000 / 256 = 3`); los 232 elementos que faltan los calcula el último bloque en una segunda
  pasada que la GPU hace sola.
- **B.** 4 bloques; el hilo calcula `i = 3·256 + 232 = 1000`, la guardia `1000 < 1000` es falsa y no escribe nada.
- **C.** 4 bloques; el hilo calcula `i = 232`, porque `threadIdx.x` ya es el índice del arreglo y `blockIdx.x` solo
  agrupa hilos.
- **D.** Da igual: 1000 bloques de 1 hilo es equivalente y más simple, porque el tamaño de bloque no afecta ni la
  correctitud ni el rendimiento.

**Respuesta: B.**

| Distractor | Origen |
|---|---|
| A | Nueva (agregar al Anexo A): "la GPU completa sola el trabajo que no cubre la malla"; división entera truncada |
| C | Nueva (agregar al Anexo A): "`threadIdx.x` es el índice global"; es el error más frecuente en la tabla de rastreo |
| D | Anexo A n.º 26: "cualquier tamaño de bloque funciona igual" (1000 bloques de 1 hilo desperdician 31/32 de cada *warp*) |

**Acierto esperado en el primer voto: ~55 %** (después de PRIMM; antes sería menor).

**Guion de discusión.** "Quien votó A: ¿cuántos hilos lanzaste en total y cuántos elementos tienes?" → "Quien votó C:
si dos bloques tienen cada uno un hilo 232, ¿qué elemento calcula cada uno?" → Cierre: el bloque 3 **existe**
porque redondeamos hacia arriba; su hilo 232 existe y la guardia es lo único que le impide escribir `c[1000]`. Sobre
D: correcto en resultado, pésimo en rendimiento; lo medimos en la S04.

## CT3 · Sin error ≠ correcto (idea errónea 27) — reserva

Tu *kernel* terminó. `cudaGetLastError()` y `cudaDeviceSynchronize()` regresaron `cudaSuccess`. ¿Qué puedes concluir?

- **A.** Que el resultado es correcto: CUDA valida los accesos a memoria y la aritmética de cada hilo.
- **B.** Que el lanzamiento fue válido y no hubo falla detectable en la ejecución; la correctitud se establece
  comparando con una referencia (la CPU) con tolerancia.
- **C.** Que el resultado es correcto siempre que el *kernel* tenga la guardia `if (i < n)`.
- **D.** Nada: `cudaGetLastError()` solo reporta errores de compilación de `nvcc`.

**Respuesta: B.**

| Distractor | Origen |
|---|---|
| A | Anexo A n.º 27: "si el *kernel* no da error, el resultado es correcto" |
| C | Anexo A n.º 27, variante: la guardia evita escribir fuera, no garantiza cubrir todo `n` (ver `grid = 3`) |
| D | Confusión entre tiempo de compilación y tiempo de ejecución (nueva, menor) |

**Acierto esperado en el primer voto: ~60 %** si ya vieron la variante `grid = 3` en PRIMM; ~35 % si no.

**Guion de discusión.** "Recuerden `grid = 3`: ¿hubo error? ¿Fue correcto?" → "¿Qué sabe CUDA de lo que **tú**
querías calcular?" → Cierre: dos verificaciones de error **más** una comparación con referencia; ninguna sustituye
a las otras. Esta pregunta reaparece en el *exit ticket*.
