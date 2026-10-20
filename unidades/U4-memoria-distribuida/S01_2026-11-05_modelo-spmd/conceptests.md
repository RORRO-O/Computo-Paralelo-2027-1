> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S01 · jueves 5 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S01 · ConcepTests

Secuencia fija: voto individual (tarjetas A/B/C/D o manos, 1 min) → discusión en parejas (2 min, "convence a
tu compañero") → revoto → explicación. Si el primer voto supera 80 % de aciertos se salta la discusión; si
queda por debajo de 30 % se vuelve a explicar antes de discutir. Se anota el porcentaje de cada voto en
"Notas post-sesión" de `plan-sesion.md`.

## ConcepTest 1 · ¿Qué imprime? (minuto ~42, después de la demostración de `hello_rank`)

Este programa se compila con `mpicc` y se ejecuta con `mpirun -np 4 ./a.out`. ¿Qué imprime?

```c
#include <mpi.h>
#include <stdio.h>

int x = 0;                                 /* variable global */

int main(int argc, char **argv)
{
    int rank;
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    x += rank;
    MPI_Barrier(MPI_COMM_WORLD);
    if (rank == 0) printf("x = %d\n", x);
    MPI_Finalize();
    return 0;
}
```

- **A)** `x = 6`
- **B)** `x = 0`
- **C)** Puede ser `0`, `1`, `3` o `6`, según el orden en que los procesos lleguen a la barrera
- **D)** No compila: en MPI una variable global debe declararse compartida (`shared`) para que todos la usen

<details>
<summary>Respuesta, origen de los distractores, acierto esperado y guion (ábrelo después de votar)</summary>

| | |
|---|---|
| Respuesta | **B**. Hay cuatro procesos y por tanto cuatro variables `x`, una en cada espacio de direcciones. El rango 0 sumó `0` a la suya. La barrera sincroniza el **avance** de los procesos, no copia memoria. Salida real: `x = 0`. |
| Distractor A | Idea errónea 16: "los procesos MPI comparten memoria". Quien la tiene suma 0+1+2+3 como si fuera una variable compartida de OpenMP. |
| Distractor C | Traslado de la idea 7 (condición de carrera no determinista) a un modelo donde no hay memoria compartida, más la variante 16b del Anexo A: "`MPI_Barrier` sincroniza la memoria". |
| Distractor D | Traslado de las cláusulas de OpenMP (ideas 9 y 15) a MPI: "si no digo `shared`, no se comparte". En MPI no existe la noción de variable compartida; no hay nada que declarar. |
| Acierto esperado en el primer voto | 55–65 %. El grupo viene de cinco semanas de OpenMP; la idea 16 está fresca. |
| Guion de discusión (3 líneas) | "Dibujen cuántas variables `x` hay cuando corren con `-np 4`. ¿En qué momento una de ellas podría recibir un valor de otro proceso? Busquen en el código la llamada que mueve datos entre procesos." (No hay ninguna: por eso es B.) |

</details>

## ConcepTest 2 · ¿Qué índices toma el rango 2? (minuto ~78, puesta en común)

Un arreglo de `n = 10` elementos (índices 0 a 9) se reparte **por bloques con residuo** entre `p = 4`
procesos: los primeros `n % p` rangos reciben un elemento extra. ¿Qué índices le tocan al **rango 2**?

- **A)** 4 y 5
- **B)** 6 y 7
- **C)** 2 y 6
- **D)** 6, 7 y 8

<details>
<summary>Respuesta, origen de los distractores, acierto esperado y guion (ábrelo después de votar)</summary>

| | |
|---|---|
| Respuesta | **B**. `q = 10/4 = 2`, `r = 10 % 4 = 2`. Rangos 0 y 1: 3 elementos ({0,1,2} y {3,4,5}). Rangos 2 y 3: 2 elementos ({6,7} y {8,9}). Fórmula: `start = rank·q + min(rank, r)`, `count = q + (rank < r)`. Salida real de `suma_distribuida 10 bloques` con `-np 4`: `[rango 2] bloques: 2 elementos {6, 7}`. |
| Distractor A | Bloque fijo `n/p = 2` para todos, sin residuo: `start = 2·2 = 4`. Es exactamente el error de `suma_distribuida_buggy.c`, que deja sin sumar los índices 8 y 9. Variante 16c del Anexo A: "`n/p` reparte todo el arreglo". |
| Distractor C | Confunde el reparto por bloques con el cíclico (`2, 2+4`). Variante 16d del Anexo A: "bloques y cíclico dan los mismos índices, solo cambia el orden". |
| Distractor D | Bloque de `ceil(n/p) = 3` para todos: `start = 2·3 = 6`, `{6,7,8}`. El rango 3 empezaría en 9 y se saldría del arreglo (`{9,10,11}`). Variante de la idea 16c. |
| Acierto esperado en el primer voto | 60–70 %. Acaban de ver la salida real en la práctica guiada; quien falla no rastreó la fórmula. |
| Guion de discusión | "Sumen los tamaños de los cuatro bloques de su opción. ¿Dan 10? ¿Algún índice se repite o se sale del arreglo? ¿Quién toma el 8 y el 9?" |

</details>

## ConcepTest 3 · ¿Quién puede combinar? (reserva: si sobran 5 min en la puesta en común, o como apertura de S02)

En `suma_distribuida.c` el rango 0 recibe las sumas parciales y las combina. ¿Qué hay que cambiar para que
lo haga el **rango 3** (el último, con `-np 4`)?

- **A)** Nada se puede cambiar: MPI exige que el rango 0 sea el que recibe
- **B)** Poner `3` como destino en `MPI_Send`, y que sea el rango 3 quien haga el ciclo de `MPI_Recv` sobre los rangos 0, 1 y 2
- **C)** Basta con que el rango 3 imprima `total` después de la barrera: ya está en memoria
- **D)** Ejecutar con `-np 3` para que el último rango sea el 3

<details>
<summary>Respuesta, origen de los distractores, acierto esperado y guion (ábrelo después de votar)</summary>

| | |
|---|---|
| Respuesta | **B**. "Rango 0 = maestro" es una convención de quien escribe el programa, no una regla de MPI. Cualquier rango puede ser destino de los mensajes; lo único que importa es que emisores y receptor estén de acuerdo. |
| Distractor A | Idea errónea 19: "el rango 0 tiene que ser el maestro". |
| Distractor C | Idea errónea 16: "los procesos comparten memoria" (más 16b: la barrera "sincroniza memoria"). `total` en el rango 3 solo contiene su parcial. |
| Distractor D | Variante 19b del Anexo A: confunde la **cantidad** de procesos con la **identidad** del rango. Con `-np 3` los rangos son 0, 1 y 2. |
| Acierto esperado | 65–75 %. |
| Guion de discusión | "Escriban las dos líneas que cambian. ¿Qué pasa si el rango 3 hace `MPI_Recv` de sí mismo? ¿Qué pasa si el rango 0 también intenta recibir?" (La segunda pregunta anticipa el interbloqueo de S02.) |

</details>

## Variantes de ideas erróneas que usan estos ítems (definidas en el Anexo A)

<details>
<summary>Ábrelo después de votar: dice qué idea alimenta cada distractor</summary>

- **16b.** "`MPI_Barrier` sincroniza la memoria entre procesos." → Solo sincroniza el avance; ningún dato se mueve sin un mensaje.
- **16c.** "Repartir `n/p` elementos a cada proceso cubre todo el arreglo." → Solo cuando `n % p == 0`; el residuo se reparte explícitamente.
- **16d.** "Bloques y cíclico asignan los mismos índices, solo en otro orden." → Asignan conjuntos distintos; afecta localidad y balance.
- **19b.** "Con `-np 3` el último rango es el 3." → Confunde la cantidad de procesos con la identidad del rango: los rangos siempre son `0..size−1`; con `-np 3`, 0, 1 y 2.

</details>
