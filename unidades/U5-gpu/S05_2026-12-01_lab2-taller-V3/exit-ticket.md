> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S05 · martes 1 de diciembre de 2026 · 08:30–10:00 · Lab LS4

# Exit ticket · S05

Cinco minutos, individual, en papel. Se revisa hoy mismo; el error más frecuente abre la S06 del jueves 3 de
diciembre. Cuenta la entrega, no el acierto.

**1. (Conceptual)** Un equipo reporta "*speedup* del *kernel*: 45×" y otro reporta "*speedup* de la V3: 4×" para el
mismo programa y la misma GPU. Ambos midieron bien. Explica en dos líneas cómo pueden ser ciertos los dos números
y cuál de los dos describe lo que gana el usuario del programa.

<details><summary>Clave</summary>
El primero cronometra solo los <em>kernels</em> (eventos alrededor del ciclo); el segundo incluye las transferencias H2D/D2H (y, si aplica, lo que quedó en CPU). Si las copias tardan 10 veces más que el cómputo, 45× y 4× son el mismo programa. Lo que gana el usuario es el 4×: el tiempo total. El protocolo exige reportar ambos (idea errónea 24).
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

---

Recordatorios proyectados junto con el *exit ticket*: **P6** vence el domingo 6 de diciembre a las 23:59.
**Entrega final del proyecto** (repositorio V1·V2·V3 + reporte PDF): lunes 7 de diciembre, 10:30. **Examen 3**
(Unidades IV–V): martes 8 de diciembre, 08:30. **Defensa oral**: jueves 10 de diciembre.
