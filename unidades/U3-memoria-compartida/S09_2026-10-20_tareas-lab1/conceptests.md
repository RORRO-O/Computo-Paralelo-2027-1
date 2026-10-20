> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S09 · martes 20 de octubre de 2026 · 08:30–10:00 · Lab LS4

# S09 · ConcepTests (instrucción entre pares)

Secuencia fija: voto individual (1 min, tarjetas A/B/C/D o dedos) → discusión en parejas (2 min: "convence a
tu par") → revoto → explicación (2 min). Si el primer voto supera 80 % de aciertos se salta la discusión; si
queda por debajo de 30 % se reexplica el punto antes de discutir. En el ConcepTest 2 la discusión y el revoto
ocurren solo si el primer voto queda entre 30 % y 80 %. Cada distractor nace de una idea errónea del Anexo A de
`docs/metodo/01-marco-pedagogico.md` o de una nueva que aquí se documenta. Hoy la sesión usa CT1 (minuto ~22,
al cerrar la mini-lección) y CT2 (minuto ~47, puesta en común de la práctica guiada); CT3 es reserva.

## CT1 · ¿Qué imprime? (minuto ~22, tras el ejemplo resuelto)

`head` apunta a una lista enlazada de 8 nodos; `work(id)` devuelve un entero positivo.

```c
#pragma omp parallel num_threads(4)
#pragma omp single
{
    long total = 0;                       /* declarada DENTRO de la región */
    for (node *p = head; p != NULL; p = p->next) {
        #pragma omp task
        total += work(p->id);
    }
    #pragma omp taskwait
    printf("%ld\n", total);
}
```

¿Qué imprime?

- **A)** La suma correcta: `taskwait` espera a las 8 tareas y para entonces `total` ya tiene todo acumulado.
- **B)** `0`, siempre: `total` es `firstprivate` implícita en cada tarea; cada tarea suma sobre **su** copia y
  el `printf` lee la copia del hilo que ejecuta el `single`, que nadie tocó.
- **C)** Un valor incorrecto que cambia entre corridas: las 8 tareas comparten `total` y `total +=` es una
  carrera de datos.
- **D)** La suma correcta solo si se ejecuta con `OMP_NUM_THREADS=1`: con un hilo las tareas se ejecutan en el
  acto y en orden.

| Opción | Origen |
|---|---|
| A | Idea errónea 13 (variante): cree que `taskwait` resuelve todo, sin mirar en qué memoria escribió cada tarea. |
| **B** | **Correcta.** Regla de OpenMP para `task`: una variable que **no** es compartida en el contexto que crea la tarea entra a la tarea como `firstprivate` (copia con el valor del momento). `total` se declaró dentro de la región: es privada del hilo del `single` (idea 15, al revés de como suele creerse) y por eso cada tarea recibe una copia. `p` también es `firstprivate`: por eso cada tarea procesa el nodo correcto aunque `p` siga avanzando. |
| C | Idea errónea 15: "lo declarado dentro de la región es compartido". La intuición de carrera es sana, pero el modelo de datos está mal: ninguna tarea toca la `total` de otra. |
| D | Anexo A, 13b: "con un hilo, `task` es una llamada directa". No: con un hilo la tarea también recibe su copia `firstprivate` (y libgomp también la difiere). |

**Acierto esperado en el primer voto:** 35–45 % (A y C se reparten el resto; D poca gente).

**Guion de discusión (3 líneas).** "¿Dónde está declarada `total`? Para el hilo que entró al `single`, ¿es
compartida o privada? Y para una tarea, ¿qué regla aplica a una variable que **no** es compartida donde se
crea?" Cerrar con la corrección: `shared(total)` en el `task` **y** `#pragma omp atomic` en `total +=` (o,
mejor, cada tarea escribe en `p->result` y el hilo del `single` suma al final, como en `list_tasks.c`). Mostrar
la salida de `./fib_buggy` (`0   esperado 832040`): mismo mecanismo, sin carrera y sin aviso del compilador.

## CT2 · ¿Por qué `cutoff = 1` tarda tanto? (minuto ~47, puesta en común de la práctica guiada)

En la fase Modificar midieron `mergesort_tasks` con n = 2 000 000 y 4 hilos: con `cutoff = 1` el programa
tarda **decenas de veces más** que con `cutoff = 4096`, y las dos versiones ordenan bien. ¿Cuál es la causa
principal?

- **A)** Con `cutoff = 1` se crean cerca de 4 millones de tareas; crear, encolar, tomar y terminar cada una
  cuesta mucho más que ordenar los 1 o 2 elementos que le tocan.
- **B)** Con `cutoff = 1` hay más carreras de datos: miles de tareas escriben el mismo arreglo al mismo tiempo
  y se estorban.
- **C)** Con `cutoff = 1` los otros 3 hilos se quedan sin trabajo, porque solo el hilo del `single` crea tareas
  y no le da tiempo de crearlas.
- **D)** Deberían tardar lo mismo: el número total de comparaciones es el mismo; la diferencia es ruido de
  medición.

| Opción | Origen |
|---|---|
| **A** | **Correcta.** El número de tareas lo fija la recursión, 2·(n/cutoff − 1) en potencias de dos (con n = 8 y cutoff = 2 salieron exactamente 6; con cutoff = 1, 14). La sobrecarga por tarea (reservar memoria para su entorno de datos, encolarla, que un hilo la tome, la termine y despierte a quien espera en `taskwait`) es de microsegundos; ordenar un elemento, de nanosegundos. Es la aglomeración de Foster: el corte agrupa trabajo hasta que cada tarea vale lo que cuesta. |
| B | Confunde sobrecarga con carrera. Cada tarea escribe un tramo **disjunto** del arreglo (`[lo, mid)` y `[mid, hi)`), y `taskwait` ordena hija-antes-de-mezcla: no hay carrera con ningún corte, y `make test` lo comprueba con cortes 1, 3, 1 024 y 70 000. Pariente de la idea 7 (razona sobre el síntoma, no sobre los accesos). |
| C | Anexo A, 13c: "solo el hilo del `single` crea tareas". Las tareas **crean tareas**: cada hija con más de `cutoff` elementos crea dos más, desde el hilo que la tomó. La traza con n = 8 lo deja ver: `[4,6)` y `[6,8)` las creó el hilo que ejecutó `[4,8)`, y `[0,2)`, `[2,4)` el que ejecutó `[0,4)`; cuando esos dos son distintos (casi siempre), al menos uno no es el del `single`. |
| D | Idea errónea 1 en versión de tareas ("más tareas/hilos no puede ser peor") combinada con la 5 ("la diferencia es ruido"). Una diferencia de 17–19 veces respecto a la secuencial (3.7 s contra 0.2 s en la máquina de autoría), estable en 5 repeticiones y en tres corridas distintas, no es ruido; el trabajo útil es el mismo, pero el tiempo mide trabajo útil **más** sobrecarga. |

**Acierto esperado en el primer voto:** 55–65 % (acaban de medirlo; si queda por debajo de 40 %, la tabla de
`make cutoffs` no se discutió: proyectarla antes de la discusión).

**Guion de discusión.** "¿Cuántas tareas hay con `cutoff = 1` y cuántas con 4096? ¿Cuánto trabajo hace una
tarea de un elemento? ¿Y cuánto cuesta crearla y que otro hilo la tome? Quien votó B: ¿qué tramo del arreglo
escribe cada tarea? ¿Se traslapan?" Regla general al cerrar, escrita en el pizarrón: **"el corte se elige para
que el trabajo de una tarea sea mucho mayor que el costo de crearla, y para que aun así haya varias veces más
tareas que hilos"**. Anticipar S10 (jueves 22 de octubre): esa sobrecarga es una de las causas de que el
*speedup* no crezca con los hilos.

## CT3 · `taskwait` y las nietas (reserva: minuto ~83 si el punto de control termina antes; si no, abre la recuperación de S10)

`a` y `b` están declaradas **antes** de la región paralela e inicializadas en 0. `f()` y `g()` devuelven 1.

```c
#pragma omp parallel
#pragma omp single
{
    #pragma omp task              /* tarea T1 */
    {
        #pragma omp task          /* tarea T2, hija de T1 */
        b = g();
        a = f();
    }
    #pragma omp taskwait
    printf("%d %d\n", a, b);
}
```

¿Qué garantiza OpenMP sobre lo que se imprime?

- **A)** `1 1`: `taskwait` espera a todas las tareas pendientes, incluida T2.
- **B)** `a` vale 1 con seguridad; `b` puede valer 0 o 1: `taskwait` espera a las hijas **directas** de la
  tarea actual (T1), no a las nietas (T2).
- **C)** Nada: `taskwait` solo espera si las tareas las tomaron **otros** hilos; si el mismo hilo las ejecuta
  después, no hay garantía.
- **D)** `1 1`, pero solo con `OMP_NUM_THREADS=1`.

| Opción | Origen |
|---|---|
| A | Idea errónea 13 (segunda mitad): "`taskwait` espera a todas". Espera a las hijas directas. Para esperar a todas las descendientes existe `#pragma omp taskgroup` alrededor del bloque que las crea. |
| **B** | **Correcta** (OpenMP API Specification 5.2, *taskwait Construct*: "the current task region is suspended until all child tasks that it generated before the taskwait region complete"). T1 termina sin esperar a T2, porque T1 no tiene `taskwait`. |
| C | Anexo A, 13d: confunde `taskwait` con una barrera de hilos. `taskwait` es una espera de **tareas**: quién las ejecute no importa. |
| D | Idea 13b (ver CT1-D): con un hilo las reglas son las mismas; libgomp también difiere la tarea. |

**Acierto esperado en el primer voto:** 40–50 %.

**Guion de discusión.** "¿De quién es hija T2? ¿Quién tiene el `taskwait`? ¿T1 espera a alguien antes de
terminar?" Corrección: un `#pragma omp taskwait` dentro de T1 después de crear T2, o envolver la creación de T1
en `#pragma omp taskgroup`. Conectar con `mergesort_tasks.c`: cada nivel tiene **su** `taskwait`, por eso la
mezcla de un nivel nunca ve tramos a medio ordenar.

## Registro para el profesor (llenar en la sesión)

| ConcepTest | % 1er voto | % revoto | Opción más votada entre los errados | Nota |
|---|---|---|---|---|
| CT1 | | | | |
| CT2 | | | | |
| CT3 | | | | |
