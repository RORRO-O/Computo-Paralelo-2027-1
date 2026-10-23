> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S03 · jueves 26 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# Exit ticket · S03

Cinco minutos, individual, en la misma hoja de la recuperación (lado B). Se entrega al salir. Cuenta la entrega, no
el acierto; el profesor lo revisa hoy mismo y abre la S04 (lunes 30 de noviembre, 10:30) con el error más frecuente.

**1. (Conceptual).** Un compañero quita el `__syncthreads()` de dentro del ciclo del árbol, compila con bloques de
32 hilos, corre cinco veces y las cinco dan `verificacion=OK`. Concluye: "con 32 hilos no hace falta la barrera: el
*warp* avanza junto, y además `__syncthreads()` sincroniza toda la GPU, así que daba igual". Elige la opción correcta:

- **A.** Tiene razón: un *warp* ejecuta en bloque, así que con `block = 32` la barrera sobra y cinco `OK` lo prueban.
- **B.** Se equivoca en "toda la GPU" (solo sincroniza el bloque), pero como el bloque es un solo *warp*, el código
  sin barrera es correcto.
- **C.** Hay una carrera: desde Volta (la T4 incluida) los hilos de un *warp* pueden avanzar de forma independiente,
  cinco `OK` no prueban nada, y `__syncthreads()` solo sincroniza el bloque, nunca toda la GPU.
- **D.** El error está en otra parte: si faltara la barrera, CUDA habría reportado `an illegal memory access`.

**2. (Aplicación).** `n = 2 000 000`, `block = 512`.
(a) ¿Cuántas operaciones atómicas en memoria global hace la versión `atomic`?
(b) ¿Cuántas hace `tree_nodiv` con la segunda etapa atómica?
(c) ¿Cuántos niveles tiene el árbol dentro de cada bloque?
(d) En `tree_div`, en el primer nivel (`stride = 1`), ¿cuántos *warps* del bloque ejecutan la suma y cuántos de
ellos divergen?

**3. (Confianza).** ¿Qué tan seguro estás de tus respuestas? (1 = nada, 4 = muy seguro). ¿Qué te quedó menos claro
hoy? (una frase, opcional)

<details><summary>Clave</summary>

**1. C.** Origen de los distractores: A → ideas erróneas 7 ("salió bien, no hay carrera") y la suposición de
<em>lockstep</em> garantizado, que desde Volta (planificación independiente de hilos) no existe; B → idea 25
corregida a medias, pero mantiene la conclusión de A; D → idea 27 ("si no hay error de CUDA, el resultado es
correcto"): una carrera sobre memoria compartida no produce ningún error, solo un número distinto.

**2.** (a) <code>2 000 000</code> (una por elemento). (b) <code>⌈2 000 000 / 512⌉ = 3907</code> (una por bloque).
(c) <code>log₂ 512 = 9</code>. (d) Los <strong>16</strong> <em>warps</em> del bloque ejecutan la suma (en cada uno
trabajan 16 carriles, los <code>tid</code> pares) y los <strong>16</strong> divergen. (En <code>tree_nodiv</code>,
para comparar: 8 <em>warps</em> completos, ninguno divergido.)

**Clasificación rápida (≤ 20 s por ticket).** <em>Bien</em>: 1 = C y al menos tres de los cuatro números de la 2
(<code>2 000 000 · 3907 · 9 · 16/16</code>). <em>Parcial</em>: 1 = C con uno o dos números, o 1 = B con los cuatro
números. <em>Mal</em>: 1 = A o D (acepta "cinco <code>OK</code> = correcto" o "sin error = correcto"), o la 2 con
(a) = (b) (no distingue atómica por elemento de atómica por bloque). Un error frecuente a anotar: (b) =
<code>3906</code> (división truncada: el último bloque parcial también hace su atómica).
</details>
