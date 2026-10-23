> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S02 · martes 24 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# ConcepTests · S02

Secuencia: voto individual (1 min) → si 30–80 % acierta, discusión en parejas (2 min) → revoto → explicación
(1 min). Si el primer voto supera 80 %, se explica y se sigue; si baja de 30 %, se reexplica antes de discutir.
Se usan CT1 (minuto 18) y CT2 (minuto 80). CT3 es de reserva: se usa si CT2 sale > 80 % en el primer voto, o
abre la recuperación de S03 (jueves 26 de noviembre).

## CT1 · ¿Coalescido o no? (coalescencia, minuto 18–22)

Una matriz `M` de `1024×1024` `float` está guardada por filas. Un *warp* de 32 hilos ejecuta
`x = M[threadIdx.x * 1024 + k];` con `k` fijo. ¿Qué describe mejor este acceso?

- **(a)** Es coalescido: los hilos tienen índices consecutivos, así que leen posiciones consecutivas.
- **(b)** No es coalescido: las direcciones están separadas por 4096 bytes; el *warp* toca 32 segmentos
  distintos de memoria para usar 128 bytes.
- **(c)** Depende del tamaño del bloque: con bloques de 32×32 sí sería coalescido.
- **(d)** Da igual: la memoria global tiene caché L2 y es casi tan rápida como la compartida.

**Respuesta: (b).** Lo que importa son las **direcciones** de los 32 hilos del *warp*, no sus índices.
`threadIdx.x` multiplica al salto de fila (`1024·4 = 4096` bytes): cada hilo cae en un segmento distinto.
Para que fuera coalescido, `threadIdx.x` debería estar en la columna: `M[k * 1024 + threadIdx.x]`.

| Distractor | Origen |
|---|---|
| (a) | Idea nueva (se agrega al Anexo A): "índices de hilo consecutivos ⇒ direcciones consecutivas" |
| (c) | Idea 26: "cualquier tamaño de bloque funciona igual" (aquí, la inversa: creer que el bloque arregla el patrón de acceso) |
| (d) | Idea 23: "la memoria global es tan rápida como la compartida" |

**Primer voto esperado:** ~50 % en (b); (a) se lleva 25–30 %.

**Guion de discusión.** "Escribe la dirección en bytes que lee el hilo 0 y la que lee el hilo 1. ¿Cuántos
bytes las separan? ¿Cuántos segmentos de 32 bytes necesita el *warp* completo?" Tras el revoto: en el
pizarrón, los 32 accesos como 32 puntos en columna frente a 32 puntos en fila. Regla: `threadIdx.x`
recorre la columna. Enlace: esto es lo que la transposición con compartida (fase Crear) resuelve.

## CT2 · ¿Cuántas veces se lee cada elemento? (tiling, minuto 80–84)

Multiplicación por mosaicos con `n = 1024` y `TILE = 32`. ¿Cuántas veces se lee `A[5][7]` desde memoria
**global** durante todo el *kernel*?

- **(a)** 1 vez: la memoria compartida elimina las lecturas repetidas.
- **(b)** 32 veces: una por cada bloque de la fila de bloques de `A[5][7]` (`n / TILE` bloques).
- **(c)** 1024 veces: una por cada hilo de la fila 5.
- **(d)** 32 × 32 = 1024 veces: una por cada hilo del bloque que lo carga.

**Respuesta: (b).** `A[5][7]` lo necesitan todos los bloques que calculan la fila de bloques 0 (filas 0–31
de C): hay `1024/32 = 32` bloques en esa fila. Cada uno lo carga **una** vez a compartida (un solo hilo, el
`(tx=7, ty=5)` en la fase `t = 0`) y 32 hilos lo reutilizan desde ahí.

| Distractor | Origen |
|---|---|
| (a) | Idea nueva: "la compartida es una copia única de toda la matriz" (confunde el alcance de bloque con el de malla) |
| (c) | Es la cuenta de la versión ingenua: no se aplicó la reutilización (idea 23, de fondo) |
| (d) | Idea nueva: "cada hilo carga el mosaico completo" (no entendió la carga cooperativa) |

**Primer voto esperado:** ~55 % en (b); (c) 20 %, (a) 15 %.

**Guion de discusión.** "¿Qué bloques necesitan `A[5][7]`? Dibuja la fila de bloques. Dentro de un bloque,
¿cuántos hilos lo cargan y cuántos lo usan?" Tras el revoto, la fórmula general: `⌈n/TILE⌉` veces por
elemento, contra `n` en la ingenua. Regla en una frase: **una carga, `TILE` usos**.

## CT3 · "Sin la barrera también sale bien" (reserva; sincronización y verificación)

Se quita la **segunda** `__syncthreads()` del ciclo de fases de `matmul_tiled`. El programa compila, no
reporta ningún error de CUDA y en 10 ejecuciones con `n = 512` la verificación contra la CPU da OK.
¿Qué concluyes?

- **(a)** Que esa barrera sobraba: no hay error y el resultado coincide con la CPU.
- **(b)** Que sobraba porque la primera barrera ya sincroniza toda la GPU al final de cada fase.
- **(c)** Que hay una carrera latente: un hilo adelantado puede sobreescribir `s_A`/`s_B` de la fase
  siguiente mientras otros aún multiplican; que no se manifieste en 10 corridas depende del orden de los
  *warps*, no del código.
- **(d)** Que la carrera solo aparecería si `n` no fuera múltiplo de `TILE`.

**Respuesta: (c).** La segunda barrera protege la lectura del mosaico actual frente a la escritura del
siguiente. Con `TILE = 16` el bloque son 8 *warps* que avanzan sin orden garantizado; en una GPU concreta
pueden ir casi a la par y la carrera no se nota. Eso no la elimina. En otra GPU, con otro `TILE` o con el
*kernel* vecino ocupando el SM, aparece.

| Distractor | Origen |
|---|---|
| (a) | Ideas 27 ("si no da error, el resultado es correcto") y 7 ("si salió bien una vez, no hay carrera") |
| (b) | Idea 25: "`__syncthreads()` sincroniza toda la GPU" |
| (d) | Idea nueva: confunde el manejo de bordes con la sincronización |

**Primer voto esperado:** ~40 % en (c); (a) 35 %.

**Guion de discusión.** "¿Qué hilo escribe `s_B[ty][tx]` en la fase `t+1` y qué hilos leen `s_B[k][tx]`
(todas las filas `k`) en la fase `t`? ¿Están en el mismo *warp*? ¿Quién garantiza el orden entre *warps*
distintos?" (Se pregunta por `s_B` y no por `s_A`: la fila `ty` de `s_A` la escriben y la leen hilos de la
misma fila, que con `TILE ≤ 32` caen en el mismo *warp*; la columna `tx` de `s_B` la leen hilos de todas las
filas, es decir, de todos los *warps* del bloque. Ahí está la carrera entre *warps*.)
Tras el revoto: la salida real del simulador sin la **primera** barrera (`error maximo 4.44e+00` una vez,
`inf` o `4e+33` en otras). Regla: una barrera por cada dependencia leer/escribir sobre memoria compartida;
la prueba de que sobra no existe, la de que falta sí.
