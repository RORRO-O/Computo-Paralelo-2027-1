> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S02 · martes 24 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# Exit ticket · S02

Individual, 5 minutos, en papel. Se entrega al salir. Cuenta la entrega, no el acierto.

Medición de tu equipo (si la tienen; no se califica): GPU ________ · `n = 512` · naive ______ ms ·
tiled ______ ms · cociente ______

**1. (Conceptual · lecturas y coalescencia)** Multiplicación de matrices con `n = 256` y `TILE = 16`.
(a) Cada elemento de A se lee desde memoria global ______ veces en la versión ingenua y ______ veces en la
de mosaicos. (b) En una línea: ¿de dónde sale el segundo número (quién lo carga, en qué memoria queda y quién lo reutiliza)?
(c) En la carga `s_A[ty][tx] = A[row * n + a_col]`, ¿qué índice de hilo (`threadIdx.x` o `threadIdx.y`)
recorre la columna de A, y por qué eso hace que la lectura del *warp* sea coalescida (pocas transacciones
en vez de 32)? (una línea)

**2. (Aplicación · verificación)** Un compañero compila `matmul_tiled.cu` con `-DTILE=64`, ve que `nvcc` no
se queja y dice: "compila sin errores, así que funciona". (a) ¿Qué va a pasar al ejecutarlo y por qué? (una
línea) (b) ¿Qué llamada del programa lo detecta y qué mensaje imprime? (nombre de la función; el mensaje con
tus palabras) (c) Si el programa no llamara a `cudaGetLastError()` en **ningún** punto, ¿qué parte del código
atraparía el error de todos modos y con qué síntoma? (una línea)

**3. (Confianza)** ¿Qué tan seguro estás de tus respuestas? 1 (nada) · 2 · 3 · 4 (muy seguro).
¿Qué te quedó menos claro hoy? (una frase; opcional)

<details><summary>Clave</summary>

1. (a) Ingenua: **256** (= `n`: cada hilo de la fila `row` recorre toda la fila de A). Mosaicos: **16**
   (= `⌈256/16⌉`, una vez por cada bloque de la fila de bloques que lo necesita). Totales:
   `2·256³ = 33 554 432` frente a `2·256²·16 = 2 097 152` (cociente 16).
   (b) Palabras que deciden: "un bloque por cada bloque-columna" / "lo carga **un** hilo (`(tx, ty)` en la
   fase `t = a_col / TILE`) y lo usan los 16 hilos de su fila del mosaico desde memoria compartida". Debe
   nombrar la memoria **compartida** (`__shared__`, alcance de bloque); "caché" o "global" cuentan como parcial
   (objetivo 1).
   (c) **`threadIdx.x`** (`a_col = t·TILE + tx`): los 16 hilos de una fila del bloque leen 16 `float`
   consecutivos (64 bytes contiguos); el *warp* (dos filas) necesita dos segmentos, no 32. Palabras que
   deciden: `threadIdx.x`/`tx` **y** "consecutivas"/"contiguas"/"coalescido".
2. (a) Un bloque de `64×64 = 4096` hilos excede el máximo de 1024 por bloque: el *kernel* **no se lanza**. El
   compilador no lo sabe porque `dim3 block(TILE, TILE)` se evalúa en tiempo de ejecución (idea 26).
   (b) `cudaGetLastError()` (dentro de `CUDA_CHECK`, justo después del lanzamiento de calentamiento): imprime
   `Error CUDA en matmul_tiled.cu:91: invalid configuration argument` y termina con código 1. (Para el
   profesor: si solo se borrara esa línea, la misma llamada dentro del ciclo de medición, línea 100, lo
   atraparía una repetición después; por eso la pregunta (c) dice "en ningún punto".)
   (c) La **verificación contra la CPU** (`verify_matmul`): el `cudaMemcpy` de regreso traería la C en ceros
   del `cudaMemset`, los tiempos de *kernel* serían casi nulos (GFLOP/s absurdos) y la comparación diría
   `FALLA` con error máximo ≈ `0.2·n` (≈ 100 para `n = 512`). Sin verificación, nada lo atraparía (idea 27).
   Palabras que deciden: "verificación" / "comparar con la CPU" / "FALLA". Quien conteste
   "`cudaDeviceSynchronize()`" va a **parcial**: un error de configuración ocurre *antes* del lanzamiento y no es
   "pegajoso"; queda solo en la variable de error del hilo anfitrión, que únicamente devuelven
   `cudaGetLastError()` / `cudaPeekAtLastError()` (*CUDA C++ Programming Guide*, "Error Checking"); la
   sincronización regresa `cudaSuccess` porque no hubo *kernel* que fallara.
3. Se registra. Si la confianza media es ≥ 3 y los aciertos en 2(a) son < 60 %, hay sobreconfianza: abrir
   S03 con ese ítem.

**Clasificación en ≤ 20 s** (por la pregunta 1; la 2 se lee solo en el montón "mal" y en 5 tickets al azar):
**bien** = 1(a) con 256 y 16, y 1(c) con `threadIdx.x` más la razón; **parcial** = un solo número correcto, o
1(c) con el índice correcto sin la razón; **mal** = confunde `n` con `TILE` en 1(a) (p. ej. "16 y 1" o
"256 y 256") o pone `threadIdx.y` en 1(c). Al leer la 2: "cree que `TILE=64` corre" cuenta como mal.
</details>
