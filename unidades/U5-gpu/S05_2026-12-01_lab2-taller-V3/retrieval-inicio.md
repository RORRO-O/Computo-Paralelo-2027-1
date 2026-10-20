> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S05 · martes 1 de diciembre de 2026 · 08:30–10:00 · Lab LS4

# Recuperación de inicio · S05

Cuatro minutos, solo, sin apuntes ni dispositivos. Escribe las respuestas; a los 4 minutos se proyectan y cuentas
tus aciertos (la participación cuenta, el acierto no). Las preguntas 1 y 2 son de la S04 (lunes 30 de noviembre);
la 1 además es sobre la Parte D de la Práctica 6; la 3 es de la Unidad I; la 4 de la Unidad IV; la 5 anticipa el
tema de hoy.

**1.** (S04 · Parte D de P6) Un *kernel* tarda 2 ms. Copiar la entrada a la GPU tarda 30 ms y traer el resultado,
30 ms. La V1 en CPU tarda 120 ms. ¿Cuál es el *speedup* sin transferencias y cuál con transferencias? ¿Cuál de
los dos exige la Parte D?

<details><summary>Respuesta</summary>
Sin transferencias: 120 / 2 = 60×. Con transferencias: 120 / (30 + 2 + 30) = 120 / 62 ≈ 1.9×. La Parte D (y el protocolo del curso) exige <strong>ambos</strong>, en la misma tabla. El segundo es el que ve el usuario del programa.
</details>

**2.** (S04) En este fragmento el tiempo medido sale de 0.3 ms para 100 lanzamientos de un *kernel* que lee y escribe
8 MB en cada uno (serían 2.7 TB/s; una T4 da 320 GB/s). ¿Qué línea falta y qué se midió en realidad?

```c
double t0 = now_s();                       /* reloj de CPU */
for (int it = 0; it < 100; it++) kernel<<<grid, block>>>(d_a, d_b, n);
double ms = (now_s() - t0) * 1e3;
```

<details><summary>Respuesta</summary>
Falta <code>cudaDeviceSynchronize()</code> antes de la segunda lectura del reloj. Los lanzamientos son asíncronos: se midió el tiempo de <em>encolar</em> 100 lanzamientos, no de ejecutarlos. (Con eventos el equivalente es <code>cudaEventSynchronize(stop)</code>; sin ella, <code>cudaEventElapsedTime</code> regresa <code>cudaErrorNotReady</code>.) Faltan también el calentamiento y las 5 repeticiones.
</details>

**3.** (Unidad I · Amdahl) En la V2 de tu proyecto, la lectura de datos y la escritura de resultados ocupan el 10 %
del tiempo de la V1 y se quedan en CPU. Si la GPU hiciera el 90 % restante en tiempo cero, ¿cuál es el *speedup*
máximo de la V3 completa?

<details><summary>Respuesta</summary>
S_max = 1 / f_secuencial = 1 / 0.10 = 10×. Por eso la V3 se juzga por el tiempo total del programa, no solo por el del <em>kernel</em>, y por eso conviene medir primero qué porcentaje es realmente el ciclo caliente.
</details>

**4.** (Unidad IV · modelo de costo) Con latencia de 50 µs y ancho de banda de 1 GB/s, ¿cuánto cuesta enviar 1000
mensajes de 8 bytes frente a 1 mensaje de 8 000 bytes?

<details><summary>Respuesta</summary>
1000 mensajes: 1000 × (50 µs + 8 B / 1 GB/s) ≈ 1000 × 50.008 µs ≈ 50 ms; domina la latencia, pagada 1000 veces. 1 mensaje: 50 µs + 8 µs = 58 µs; todavía domina la latencia (50 de 58 µs), pero se paga una sola vez: ≈ 860 veces menos tiempo para los mismos bytes. Muchas transferencias pequeñas pagan la latencia muchas veces; en GPU, una <code>cudaMemcpy</code> por iteración paga la latencia de PCIe (≈ 10 µs) <em>y</em> vuelve a mover todos los datos en cada paso. Se sube una vez y se baja una vez.
</details>

**5.** (Anticipa el tema; conjetura: "no sé" es válida y no cuenta) Una malla de 6 filas × 8 columnas se guarda en un arreglo 1D por filas. ¿Qué índice tiene la
celda (fila 2, col 3)? Si un *kernel* 2D usa bloques de 4 × 4 y `threadIdx.x` recorre columnas, ¿qué `blockIdx` y
`threadIdx` la procesan?

<details><summary>Respuesta</summary>
idx = 2 · 8 + 3 = 19. Columna 3 → <code>blockIdx.x = 3 / 4 = 0</code>, <code>threadIdx.x = 3</code>; fila 2 → <code>blockIdx.y = 2 / 4 = 0</code>, <code>threadIdx.y = 2</code>. Es decir <code>blockIdx = (0,0)</code>, <code>threadIdx = (3,2)</code>: el par se escribe (x, y), no (fila, col).
</details>

Si acertaste menos de 3: antes de abrir Colab, lee la sección 2 de `notas-estudiante.md` (seis pasos y fórmulas).
