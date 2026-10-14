> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S04 · jueves 12 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S04 · Exit ticket (5 min, individual, en papel)

Escribe tu número de lista. Se entrega al salir.

**1. Conceptual.** En la versión MPI de Jacobi cada iteración termina con
`MPI_Allreduce(&local_diff, &global_diff, 1, MPI_DOUBLE, MPI_MAX, MPI_COMM_WORLD)`.
(a) ¿Por qué la llaman todos los rangos y no solo el 0? (b) ¿Qué pasa en la ejecución si alguien escribe
`if (rank == 0) MPI_Allreduce(...)`? (c) ¿Qué pasaría si, en vez de eso, cada rango comparara su propio `local_diff` con `tol`?

**2. Aplicación.** `n = 10` celdas, `p = 4` procesos, reparto por bloques con residuo.
(a) Escribe `local_n` y las celdas globales de cada rango.
(b) ¿Qué celda global recibe el rango 2 en su halo izquierdo y de qué rango viene? ¿Y en su halo derecho?
(c) Si el rango 2 nunca recibiera su halo izquierdo, ¿el programa se cuelga, da error o termina? ¿Qué valor usaría como vecino?

**3. Confianza.** ¿Qué tan seguro estás de tus respuestas? (1 = adivinando, 4 = podría explicárselo a alguien).
¿Qué te quedó menos claro de hoy? (una línea)

<details>
<summary>Clave</summary>

**1.** (a) Es una operación colectiva: por definición la ejecutan todos los procesos del comunicador; además el resultado (el
máximo global) lo necesitan todos para tomar la **misma** decisión de parar en la **misma** iteración. (b) Se cuelga: el rango 0
espera dentro de `Allreduce` a los demás, que siguieron al siguiente intercambio de halos con el rango 0 y ahí se quedan esperando
(idea errónea 18). (c) Cada rango pararía en una iteración distinta: con `n=12, p=3` el rango 1 tiene `local_diff = 0` en la iteración 1 (todos sus
vecinos valen 0) y saldría del ciclo; los rangos 0 y 2 se quedarían esperando en el siguiente `Sendrecv` el halo del que ya salió
(cuelgue). Si por casualidad todos salieran, `Gatherv` juntaría estados de iteraciones diferentes.

**2.** (a) `base = 2`, `rem = 2`: rango 0 → 3 celdas (1–3); rango 1 → 3 celdas (4–6); rango 2 → 2 celdas (7–8); rango 3 → 2 celdas (9–10).
(b) Halo izquierdo del rango 2: celda 6, enviada por el rango 1. Halo derecho: celda 9, enviada por el rango 3.
(Salida real de `mpirun -np 4 ./jacobi1d_mpi 10 1e-3 100000 --trace 1`: `rango 2: celdas 7..8 | ... recibe halo izq u[6] ..., halo der u[9]`.)
(c) Termina sin error (ninguna llamada queda esperando pareja), pero con resultado incorrecto: usaría el valor inicial de `u[0]`
(0.0) como si fuera la celda 6, es decir, una frontera falsa en 0. Es lo que hace `jacobi1d_mpi_buggy.c`.

**Clasificación rápida:** *bien* = 1(a)(b) correctas y 2(a)(b) correctas; *parcial* = falla 1(c) o 2(c) o un índice; *mal* =
dice que `Allreduce` la llama solo el raíz o que el halo faltante produce error o cuelgue. Más de 30 % en *mal* → reabrir S05 con
el buggy en vivo antes de medir.

</details>
