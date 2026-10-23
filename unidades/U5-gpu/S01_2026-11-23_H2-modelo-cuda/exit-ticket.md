> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S01 · lunes 23 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# Exit ticket · S01

Cinco minutos, individual, en la misma hoja de la recuperación (lado B). Se entrega al salir. Cuenta la entrega, no
el acierto; el profesor la revisa hoy mismo y abre la S02 (martes 24 de noviembre, 08:30) con el error más frecuente.

**1. (Conceptual).** Un compañero te dice: "Mi *kernel* corrió sin ningún error de CUDA, así que la suma está bien.
Y como la T4 tiene 2560 núcleos, corrió 2560 veces más rápido que un núcleo de mi laptop". Señala los **dos** errores
de razonamiento y corrige cada uno en una línea.

**2. (Aplicación).** `n = 5000`, `block = 128`.
(a) ¿Cuántos bloques lanzas?
(b) ¿Qué índice global calcula el hilo `threadIdx.x = 5` del bloque `blockIdx.x = 7`?
(c) ¿Cuántos hilos quedan ociosos y qué hace el hilo `threadIdx.x = 120` del bloque `blockIdx.x = 39`?

**3. (Confianza).** ¿Qué tan seguro estás de tus respuestas? (1 = nada, 4 = muy seguro). ¿Qué te quedó menos claro
hoy? (una frase)

<details><summary>Clave</summary>

**1.** (i) "Sin error" no implica "correcto" (idea errónea 27): CUDA no sabe qué resultado esperabas; hay que
comparar contra la CPU con tolerancia (el ejemplo `grid = 3` terminó sin error y dejó 232 elementos en cero).
(ii) Un núcleo CUDA no es un núcleo de CPU (idea errónea 22): es una unidad aritmética que ejecuta en <em>warps</em>
de 32; el <em>speedup</em> real lo limitan el ancho de banda de memoria y, en problemas pequeños, las copias
anfitrión↔dispositivo; se mide, no se deduce del número de núcleos. (Lo esperado en una T4 para la suma de 2^24: el <em>kernel</em> solo,
~20× más rápido que un núcleo de CPU; contando las copias, más lento. Compara con lo que mediste hoy.)

**2.** (a) <code>(5000 + 127) / 128 = 40</code> bloques (5120 hilos). (b) <code>7·128 + 5 = 901</code>.
(c) <code>5120 − 5000 = 120</code> hilos ociosos. El hilo 120 del bloque 39 calcula <code>i = 39·128 + 120 =
5112</code>; como <code>5112 ≥ 5000</code>, la guardia es falsa y no escribe nada.

**Clasificación rápida.** <em>Bien</em>: los dos errores de la 1 y las tres partes de la 2. <em>Parcial</em>: una de
las dos ideas de la 1, o la 2 con el índice mal pero el número de bloques bien. <em>Mal</em>: usa <code>5000 /
128 = 39</code> bloques, o <code>i = threadIdx.x</code>, o acepta el argumento "sin error = correcto".
</details>
