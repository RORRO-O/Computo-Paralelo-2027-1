> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S04 · jueves 12 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S04 · Exit ticket (5 min, individual, en papel)

Escribe tu número de lista. Se entrega al salir.

**1. Conceptual (marca una opción y justifica en una línea).** En la versión MPI de Jacobi cada iteración termina con
`MPI_Allreduce(&local_diff, &global_diff, 1, MPI_DOUBLE, MPI_MAX, MPI_COMM_WORLD)`, que llaman todos los rangos.
Un compañero la quita "para ahorrar una colectiva por iteración": cada rango compara **su** `local_diff` con `tol` y sale del
ciclo cuando le toque. Con `n = 12`, `p = 3` (interior inicial en 0, frontera izquierda en 100), ¿qué pasa?

- A. Funciona y ahorra tiempo: cada rango sabe cuándo sus propias celdas dejaron de cambiar.
- B. Los rangos 1 y 2 salen del ciclo en la iteración 1 (su `local_diff` es 0) y el rango 0 se queda esperando su halo en el siguiente `Sendrecv`: el programa se cuelga.
- C. MPI aborta con un mensaje de error al detectar que un rango salió del ciclo antes que los demás.
- D. Todos salen en la misma iteración de todos modos: el intercambio de halos ya propaga la diferencia máxima.

Justifica: ¿qué llamada se queda esperando y a quién? ______________________________

**2. Aplicación.** `n = 10` celdas, `p = 4` procesos, reparto por bloques con residuo.
(a) Escribe `local_n` y las celdas globales de cada rango.
(b) ¿Qué celda global recibe el rango 2 en su halo izquierdo y de qué rango viene? ¿Y en su halo derecho?
(c) Si el rango 2 nunca recibiera su halo izquierdo, ¿el programa se cuelga, da error o termina? ¿Qué valor usaría como vecino?

**3. Confianza.** ¿Qué tan seguro estás de tus respuestas? (1 = adivinando, 4 = podría explicárselo a alguien).
¿Qué te quedó menos claro de hoy? (una línea)

<details>
<summary>Clave</summary>

**1. B.** En la iteración 1 las celdas y los halos de los rangos 1 y 2 valen 0, así que su `local_diff` es 0 y salen del ciclo
hacia el `Gatherv` final; el rango 0 (que sí cambió: `u[1] = 50`) sigue a la iteración 2 y en el segundo `Sendrecv` espera la celda 5
del rango 1, que ya no la manda. Verificado en el entorno de autoría: con `timeout 10` el programa no regresa. La decisión de parar
debe ser **global y la misma en todos**: por eso `Allreduce` la llaman todos (idea errónea 18). Justificación que cuenta como
completa: nombra `Sendrecv` (o "el halo") y al rango 0 esperando al 1.
Distractores: A = "la convergencia se decide localmente" (variante de la 18: una decisión global exige una colectiva); C = "MPI
detecta llamadas desemparejadas" (no lo hace: se manifiesta como cuelgue, igual que un `Recv` sin `Send`, S02); D = confunde el
intercambio de halos (dos valores con los vecinos) con una reducción global.

**2.** (a) `base = 2`, `rem = 2`: rango 0 → 3 celdas (1–3); rango 1 → 3 celdas (4–6); rango 2 → 2 celdas (7–8); rango 3 → 2 celdas (9–10).
(b) Halo izquierdo del rango 2: celda 6, enviada por el rango 1. Halo derecho: celda 9, enviada por el rango 3.
(Salida real de `mpirun -np 4 ./jacobi1d_mpi 10 1e-3 100000 --trace 1`: `rango 2: celdas 7..8 | ... recibe halo izq u[6] ..., halo der u[9]`.)
(c) Termina sin error (ninguna llamada queda esperando pareja), pero con resultado incorrecto: usaría el valor inicial de `u[0]`
(0.0) como si fuera la celda 6, es decir, una frontera falsa en 0. Es lo que hace `jacobi1d_mpi_buggy.c`.

**Clasificación rápida:** *bien* = 1 en B con la justificación completa y 2(a)(b) correctas; *parcial* = 1 en B sin justificación,
o un índice mal en 2(a)(b), o 2(c) con "termina" pero sin el valor 0.0; *mal* = 1 en A, C o D, o 2(a) mal, o 2(c) dice que el halo
faltante produce error o cuelgue. Más de 30 % en *mal* → reabrir S05 con el buggy en vivo antes de medir.

</details>
