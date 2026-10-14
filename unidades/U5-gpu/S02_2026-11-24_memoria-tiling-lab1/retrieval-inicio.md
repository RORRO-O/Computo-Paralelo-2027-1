> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S02 · martes 24 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# Recuperación de inicio · S02

Individual, por escrito, sin apuntes ni dispositivos. 4 minutos. Al terminar se proyectan las respuestas y
se cuentan manos por pregunta. Entrega también tu pre-laboratorio de la Práctica 6 en la caja de la entrada.

**1. (S01, lunes 23 de noviembre)** Un *kernel* 1D procesa un arreglo de 1000 elementos con bloques de 256
hilos. ¿Cuántos bloques lanzas y qué línea evita que los hilos sobrantes escriban fuera del arreglo?

**2. (S01)** Completa: un *warp* son ____ hilos que ejecutan ____________________. En el modelo SIMT, ¿qué
tiene cada hilo de propio aunque comparta la instrucción?

**3. (Unidad III, S10)** Dos hilos de OpenMP escriben en `cont[0]` y `cont[1]`, variables distintas y
contiguas. El programa escala mal. ¿Cómo se llama el fenómeno y qué unidad de memoria lo explica?

**4. (Unidad IV, S05 · enlace con la Parte A de la Práctica 6)** Modelo de costo `T = latencia + tamaño /
ancho de banda`, con latencia 10 µs y 10 GB/s. ¿Qué término domina al mover 4 MB? ¿Y al mover 4 KB? (basta
el orden de magnitud). La Parte A de la Práctica 6 pide medir la suma de vectores **con y sin** copias
anfitrión↔dispositivo: ¿por qué las dos?

**5. (Anticipa el tema de hoy; conjetura, "no sé" es válida y no cuenta)** Una matriz `float` de `1024×1024`
está guardada por filas. 32 hilos consecutivos leen, cada uno, un elemento: en el caso A leen 32 elementos de
la **misma fila**; en el caso B, 32 elementos de la **misma columna**. ¿Cuántos bytes separan dos lecturas
vecinas en cada caso? ¿Cuál crees que tarda menos y por qué?

<details><summary>Respuestas</summary>

1. `⌈1000/256⌉ = 4` bloques (1024 hilos). La guardia `if (i < n)` con `i = blockIdx.x * blockDim.x +
   threadIdx.x`. Sin ella, 24 hilos escriben fuera del arreglo (y CUDA puede no avisar).
2. 32 hilos que ejecutan **la misma instrucción al mismo tiempo**. Cada hilo tiene sus propios registros,
   sus propios índices (`threadIdx`) y, por tanto, sus propios datos. Un hilo de CUDA no es un núcleo de CPU
   (idea 22).
3. Falso compartido (*false sharing*). La unidad es la línea de caché (64 bytes): las dos variables caen en la
   misma línea y cada escritura invalida la copia del otro núcleo. Hoy la unidad análoga en la GPU es el
   segmento de 32/128 bytes que mueve un *warp*.
4. 4 MB: `10 µs + 4·10⁶ B / 10¹⁰ B/s = 10 µs + 400 µs ≈ 410 µs`, domina el ancho de banda. 4 KB:
   `10 µs + 0.4 µs ≈ 10.4 µs`, domina la latencia. Se miden las dos porque en problemas pequeños las copias
   dominan sobre el *kernel* (idea 24) y el protocolo exige reportarlo.
5. Caso A: 4 bytes (consecutivos; los 32 caben en 128 bytes contiguos). Caso B: `1024 · 4 = 4096` bytes.
   A tarda menos: una sola transacción de memoria frente a 32. Se llama acceso coalescido y es el primer
   tema de hoy.
</details>

**Si menos del 60 % acierta la pregunta 1** (índice global y guardia): dedicar 3 minutos del bloque de
objetivos a reconstruir `i = blockIdx.x * blockDim.x + threadIdx.x` en el pizarrón con 1000 y 256 antes de
pasar a la malla 2D, porque toda la sesión se apoya en la versión 2D de esa fórmula.
