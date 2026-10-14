> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S04 · lunes 30 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# ConcepTests · S04

Secuencia fija: voto individual (1 min) → si 30–80 % acierta, discusión en parejas (2 min) → revoto →
explicación (2 min). Si el primer voto supera 80 %, se explica en 30 s y se sigue; si baja de 30 %, se
reexplica el concepto antes de discutir. Votación con tarjetas A/B/C/D.

## CT1 · ¿Qué midió? (minuto ≈ 28, al cerrar el ejemplo resuelto)

Un compañero mide así su kernel sobre 16 millones de elementos:

```c
double t0 = omp_get_wtime();
saxpy_kernel<<<grid, 256>>>(alpha, d_x, d_y, n);
double t1 = omp_get_wtime();
printf("kernel: %.1f us\n", (t1 - t0) * 1e6);     // imprime: kernel: 12.0 us
```

y concluye: "la GPU es 1 500 veces más rápida que la CPU (18 ms)". ¿Cuál es la explicación más probable?

- **A.** El kernel sí tarda 12 µs: hay 65 536 bloques trabajando a la vez y cada hilo hace una sola operación.
- **B.** Midió solo el lanzamiento: el operador `<<<>>>` es asíncrono y la CPU leyó el reloj antes de que el kernel terminara.
- **C.** El kernel tarda 12 µs, pero olvidó sumar las copias H2D y D2H; con ellas el *speedup* real es menor.
- **D.** Es ruido de una sola medición; con 5 repeticiones y mediana obtendría el tiempo correcto.

**Respuesta: B.** Origen de los distractores: A → ideas 1 y 22 ("más hilos = proporcionalmente más rápido"; el
hilo de CUDA como núcleo); C → idea 24 mal aplicada (las copias importan, pero aquí el error es anterior: ni
el kernel está medido); D → idea 5 (repetir no corrige una medición mal colocada).

**Acierto esperado en el primer voto: 55–65 %.** Muchos eligen C porque acaban de oír "las copias cuentan".

**Guion de discusión.** "Si B tiene razón, ¿qué línea le falta al código y dónde?" (respuesta:
`cudaDeviceSynchronize()` antes de `t1`, o eventos). "Si C tuviera razón, ¿cuánto darían 192 MB a 230 GB/s?"
(≈ 0.9 ms, no 12 µs: el número es físicamente imposible para ese kernel). Cerrar con la regla: el reloj de la
CPU solo vale con sincronización; los eventos miden en el reloj de la GPU.

## CT2 · El barrido de bloque (minuto ≈ 68, en la puesta en común)

Barrido de `saxpy` con `n = 2^24` en una T4 (medianas de 5): 32 → 1.60 ms · 64 → 1.00 · 128 → 0.88 ·
256 → 0.85 · 512 → 0.86 · 1024 → 0.90 ms. ¿Qué explica **mejor** que 32 sea el peor y que 1024 no sea el mejor?

- **A.** Con 32 hilos hay más bloques y lanzar cada bloque cuesta; con 1024 hay menos bloques, así que debería ser el mejor: el 0.90 es ruido de medición.
- **B.** Con 32 hilos cada SM solo admite 16 bloques residentes, es decir 16 warps de 32 posibles: 50 % de ocupación y menos warps para ocultar la latencia de memoria. Con 1024 la ocupación ya no sube y quedan menos bloques para balancear la cola final.
- **C.** Cualquier múltiplo de 32 rinde igual; las diferencias son del orden del ruido y no hay nada que explicar.
- **D.** 1024 excede el máximo de hilos por bloque de la T4; el kernel no corrió y por eso "tardó" 0.90 ms.

**Respuesta: B.** Origen de los distractores: A → ideas 1 y 5 (más hilos por bloque siempre mejor; lo que no
cuadra es "ruido"); C → idea 26 (cualquier tamaño funciona igual); D → idea 27 (confunde el límite real, 1024, y
no sabe que un lanzamiento inválido se detecta con `cudaGetLastError`, no con el tiempo).

**Acierto esperado en el primer voto: 45–55 %.** El error típico es A: la intuición "menos bloques, menos
sobrecarga" es correcta pero pequeña frente a la ocupación.

**Guion de discusión.** "Llenen la fila de 32 y la de 64 de la tabla de ocupación: ¿cuántos warps residentes
hay en cada caso?" (16 y 32 de 32). "¿Qué le pasa a la ocupación de 256 a 1024?" (nada: ya es 100 %). "¿Qué sí
cambia?" (65 536 bloques contra 16 384 para 40 SM; 64 registros por hilo como tope). Regla: múltiplos de 32,
empezar en 128–256, y el barrido decide; 1024 se gana midiendo, no suponiendo.

## CT3 · ¿Conviene la GPU? (minuto ≈ 80, en Transferencia, si el grupo va a tiempo; si no, va a la tarea)

`saxpy` con `n = 2^26` en Colab: kernel 3.4 ms, H2D 130 ms, D2H 65 ms (memoria paginable). La CPU tarda 100 ms.
¿Qué afirmación es correcta?

- **A.** La GPU es 29× más rápida (100 / 3.4); ese es el *speedup* que se reporta.
- **B.** Si los datos empiezan y terminan en la CPU, la GPU pierde (198 ms contra 100); el kernel solo conviene si los datos ya viven en la GPU para varios kernels, o si se solapan copias y cómputo.
- **C.** La GPU pierde porque saxpy tiene poca intensidad aritmética; con un bloque más grande el kernel pasaría a ser *compute-bound* y ganaría.
- **D.** 3.4 ms es demasiado poco para ser cierto; hay que repetir la medición con más repeticiones antes de concluir.

**Respuesta: B.** Origen de los distractores: A → idea 24 (las copias no cuentan); C → idea 26 mezclada con una
confusión de *roofline* (el bloque no cambia la intensidad aritmética, que depende del algoritmo); D → idea 5
(desconfiar del número correcto en lugar de razonarlo: 805 MB a 240 GB/s son 3.4 ms).

**Acierto esperado en el primer voto: 60–70 %.**

**Guion de discusión.** "¿Cuántos bytes mueve el kernel y a qué velocidad?" (12 × 2^26 ≈ 805 MB; 805 MB /
3.4 ms ≈ 237 GB/s: coherente con una T4). "¿Y las copias?" (≈ 537 MB H2D a ≈ 4 GB/s ≈ 130 ms: también coherente).
"¿Qué cambiaría si en vez de un saxpy fueran 50 iteraciones de Jacobi sobre los mismos vectores?" (las copias
se pagan una vez: 195 + 50 × 3.4 = 365 ms contra 5 000 ms de CPU). Regla: el *speedup* honesto depende de dónde
viven los datos y cuánto trabajo se hace por byte transferido.
