> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S05 · martes 1 de diciembre de 2026 · 08:30–10:00 · Lab LS4

# Exit ticket · S05

Cinco minutos, individual, en papel. Se revisa hoy mismo; el error más frecuente abre la S06 del jueves 3 de
diciembre. Cuenta la entrega, no el acierto.

**1. (Conceptual)** Cuatro equipos describen su V3. ¿Cuál cumple con lo que pide la entrega final? Escribe la letra.

- A) "Subimos la malla una vez, llamamos a `cupyx.scipy.ndimage.convolve` en cada paso y bajamos al final. Verificado
  contra la V1; 40× sin transferencias y 25× con ellas, mediana de 5."
- B) "*Kernel* propio en Numba. `cuda.synchronize()` no lanzó ninguna excepción, así que no hizo falta compararlo con
  la V1. 30× con transferencias, mediana de 5."
- C) "*Kernel* propio en CUDA C, verificado contra la V1 con tolerancia 1e-4 en 37 × 45 y en 2048 × 2048. Mediana de 5
  tras calentamiento: 35× solo *kernels* y 12× con transferencias, T4, 1 de diciembre."
- D) "*Kernel* propio en CUDA C verificado contra la V1. Reportamos 60×: una corrida, solo el tiempo del *kernel*,
  porque las copias no son parte del algoritmo."

<details><summary>Clave</summary>
<strong>C</strong>. A: no hay <em>kernel</em> propio, la biblioteca hace todo (C3 queda en "En desarrollo" como máximo). B: "sin error = correcto" (idea errónea 27); falta la comparación con la V1. D: las transferencias sí cuentan (idea 24) y una corrida no basta (idea 5). Bien = C; mal = cualquier otra letra (anota cuál: dice qué idea errónea sigue viva).
</details>

**2. (Aplicación)** Una imagen de 480 filas × 640 columnas se guarda aplanada por filas y se procesa con un *kernel*
2D de bloques 32 × 8 (`blockDim.x = 32`, `blockDim.y = 8`; `x` recorre columnas).
(a) ¿Qué índice lineal tiene el píxel (fila 100, col 33)?
(b) ¿Qué `blockIdx` (x, y) y qué `threadIdx` (x, y) lo procesan?
(c) ¿Cuántos bloques lanza la malla?

<details><summary>Clave</summary>
(a) 100 · 640 + 33 = <strong>64 033</strong>.
(b) Columna 33: <code>blockIdx.x = 33 / 32 = 1</code>, <code>threadIdx.x = 33 % 32 = 1</code>. Fila 100: <code>blockIdx.y = 100 / 8 = 12</code>, <code>threadIdx.y = 100 % 8 = 4</code>. Es decir <code>blockIdx = (1, 12)</code>, <code>threadIdx = (1, 4)</code>.
(c) <code>ceil(640/32) × ceil(480/8) = 20 × 60 = 1 200</code> bloques (aquí no sobran hilos porque ambas dimensiones son múltiplos; con 481 filas serían 20 × 61 y haría falta la guardia).
</details>

**3. (Confianza)** ¿Qué tan seguro estás de tus dos respuestas? (1 = nada, 4 = podría explicarlo a un compañero).
¿Qué te quedó menos claro hoy: la medición de la Parte D, la aritmética de índices, o qué cuenta como V3?

**Solo si tu equipo no presentó en el punto de control:** configuración con menor `t_total` de tu tabla de la Parte D:
______ · mediana de `t_total` (s): ______ · *speedup* con transferencias: ______ (así queda registrado tu punto de control).

---

Recordatorios proyectados junto con el *exit ticket*: **P6** vence el domingo 6 de diciembre a las 23:59.
**Entrega final del proyecto** (repositorio V1·V2·V3 + reporte PDF): lunes 7 de diciembre, 10:30. **Examen 3**
(Unidades IV–V): martes 8 de diciembre, 08:30. **Defensa oral**: jueves 10 de diciembre.
