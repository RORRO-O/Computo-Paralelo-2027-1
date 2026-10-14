> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S09 · martes 20 de octubre de 2026 · 08:30–10:00 · Lab LS4

# S09 · Notas: paralelismo de tareas (`task`, `taskwait`, `taskloop`, corte)

Si faltaste: lee esto (10 min), haz `ejemplo-resuelto.md` con sus pausas (20 min) y la práctica guiada
(`practica-guiada/README.md`, 25 min; la fase Crear es la tarea). La Parte A y la Parte B de la Práctica 4
(`practicas/P4-openmp/README.md`) se trabajaron en el laboratorio y se terminan en casa.

## 1. Qué es una tarea y para qué sirve

`#pragma omp parallel for` reparte **iteraciones**: necesita un ciclo con índices y un número de iteraciones
conocido. Hay trabajo que no viene así: recorrer una lista enlazada, una recursión (árbol, mergesort,
quicksort), piezas de trabajo que aparecen mientras se calcula. Para eso OpenMP tiene **tareas** (*tasks*).

```c
#pragma omp parallel          /* se crea el equipo de hilos */
#pragma omp single            /* UN hilo ejecuta este bloque; los demás esperan... tomando tareas */
for (node *p = head; p != NULL; p = p->next) {
    #pragma omp task          /* se ENCOLA una unidad de trabajo; cualquier hilo del equipo la ejecutará */
    p->result = work(p->id);
}                             /* barrera implícita del single: aquí ya terminaron TODAS las tareas */
```

Tres hechos para memorizar:

- **`task` encola, no ejecuta.** El hilo que crea la tarea sigue de largo. La tarea la ejecuta cualquier hilo
  del equipo, cuando puede; puede ser el mismo creador, más tarde. "Se ejecuta al crearse" es la idea errónea
  13. Con un solo hilo también se difiere.
- **El patrón es `parallel` + `single` + `task`.** `parallel` crea el equipo; `single` hace que **un** hilo
  genere las tareas (sin él, los 4 hilos recorrerían la lista y cada nodo se procesaría 4 veces); los otros
  tres hilos no están ociosos en la barrera del `single`: toman tareas de la cola.
- **El reparto es dinámico.** Como `schedule(dynamic)` en S08, pero sin espacio de iteraciones: quién ejecuta
  cada tarea se decide al vuelo, cambia entre corridas, y el número de tareas **no depende de los hilos**.

Palabras clave: *tarea*, *encolar*, *hilo generador*, *cola de tareas*, *robo de trabajo*.

## 2. Esperar: `taskwait`, barreras, `taskgroup`

| Construcción | A quién espera |
|---|---|
| `#pragma omp taskwait` | A las tareas **hijas directas** de la tarea actual (las que esta creó). No a las nietas. |
| Barrera implícita al final de `single`, `for`, `sections` y `parallel` | A **todas** las tareas pendientes del equipo, además de a los hilos. |
| `#pragma omp taskgroup { … }` | A todas las tareas creadas dentro del bloque **y a sus descendientes**. |

El error típico (`practica-guiada/taskwait_buggy.c`): crear dos tareas que calculan `left` y `right` y leer
`left + right` en la línea siguiente. Salida real, tres corridas:

```
dentro del single, sin taskwait   : 0  -> INCORRECTO
despues de la barrera del single  : 90000000  -> correcto
```

Es una carrera de datos (ThreadSanitizer la señala: escritura de `left` dentro de la tarea contra la lectura
prematura). La barrera del `single` sí esperó: la segunda lectura es correcta. En una recursión, cada nivel
pone **su** `taskwait` antes de combinar; como cada hija espera a las suyas antes de terminar, cuando el padre
pasa su `taskwait` todo el subárbol terminó.

`depend` (panorama, no se usa en P4): `#pragma omp task depend(out: x)` y `depend(in: x)` declaran que una
tarea produce `x` y otra lo consume; OpenMP las ordena sin `taskwait`. Útil para *pipelines* y *stencils*
por bloques.

## 3. Entorno de datos de una tarea: la regla que explica el "resultado 0"

Regla de OpenMP para `task` sin cláusulas: una variable **compartida** en el contexto donde se crea la tarea
sigue compartida; cualquier otra entra como **`firstprivate`** (copia con el valor del momento).

| Variable | En la tarea | Ejemplo |
|---|---|---|
| Global, o declarada **antes** de `parallel` | compartida | `s1`, `s2` en `taskwait_buggy.c`; `task_count` |
| Parámetro o local de la función que crea la tarea (incluido lo declarado dentro de la región) | `firstprivate` | `a`, `tmp`, `lo`, `hi` en `mergesort_tasks.c`; `p` en `list_tasks.c`; `x`, `y` en `fib_tasks.c` |
| Con `shared(v)` explícito | compartida (referencia a la original) | `x`, `y` en `fib_tasks.c`; `left`, `right` en `taskwait_buggy.c` |

Consecuencias:

- `p` en la lista entra como copia: por eso cada tarea procesa **su** nodo aunque `p` siga avanzando. Lo
  declarado dentro de la región es privado del hilo (idea errónea 15) y la tarea recibe copia.
- Un puntero `firstprivate` se copia **el puntero**, no el arreglo: las tareas de mergesort escriben en el
  mismo arreglo (tramos disjuntos) sin ninguna cláusula.
- **Lo que la hija escribe y el padre lee necesita `shared`.** Sin `shared(x)` en Fibonacci la hija escribe en
  su copia y el padre lee la suya: `fib_buggy(30)… 0 esperado 832040`, siempre, sin carrera y sin aviso del
  compilador (`practica-guiada/fib_buggy.c`).

## 4. Corte (*cutoff*) y granularidad

Crear una tarea cuesta microsegundos (reservar su entorno de datos, encolarla, que un hilo la tome, avisar al
`taskwait`). Si el trabajo de la tarea es de nanosegundos, el programa se vuelve más lento que el secuencial.
Por eso toda recursión con tareas lleva un **corte**: por debajo de cierto tamaño (o profundidad) se deja de
crear tareas y se llama a la versión secuencial. Es la **aglomeración** del método de Foster.

Número de tareas: en mergesort con potencias de dos, 2·(n/cutoff − 1); en Fibonacci, 2·(fib(n − cutoff + 3) − 1).
Mediciones reales (máquina de autoría: 4 núcleos virtuales compartidos, gcc 13, `-O2`, mediana de 5 tras 1
calentamiento; los valores absolutos cambian entre corridas, el orden no):

| `fib_tasks 40 c` | Tareas creadas | t recursivo (s) | t tareas (s) | *Speedup* vs recursivo |
|---|---|---|---|---|
| c = 30 | 464 | 0.159 | 0.074 | 2.15 |
| c = 27 | 1 972 | 0.156 | 0.070 | 2.23 |
| c = 25 | 5 166 | 0.164 | 0.095 | 1.73 |
| c = 20 | 57 312 | 0.169 | 0.113 | 1.51 |
| c = 15 | 635 620 | 0.169 | 0.612 | 0.28 |
| `36 2` (48 315 632 tareas, una sola corrida) | 48 315 632 | 0.023 | 25.9 | 0.00 |

| `mergesort_tasks 2000000 c`, 4 hilos | Tareas | t_seq (s) | t_tareas (s) | *Speedup* |
|---|---|---|---|---|
| c = 1 | 3 999 998 | 0.198 | 3.712 | 0.05 |
| c = 16 | 262 142 | 0.189 | 0.336 | 0.56 |
| c = 256 | 16 382 | 0.232 | 0.104 | 2.23 |
| c = 4 096 | 1 022 | 0.196 | 0.094 | 2.10 |
| c = 65 536 | 62 | 0.188 | 0.099 | 1.90 |
| c = 2 000 000 | 0 | 0.194 | 0.208 | 0.93 |

Regla práctica: el corte se elige para que **una tarea valga mucho más que crearla** (cientos de elementos o
más) y para que aun así haya **varias veces más tareas que hilos** (decenas a miles). Entre esos dos bordes hay
una meseta ancha; fuera de ella, o pagas sobrecarga o te quedas sin qué repartir. Se mide (`make cutoffs`).

## 5. Por qué Fibonacci es un mal ejemplo de rendimiento

El recursivo repite trabajo de forma exponencial; el **mejor secuencial** es el lineal, que calcula fib(40) en
unos 20–30 ns. El protocolo del curso (§3) mide el *speedup* contra el mejor secuencial, no contra la misma
versión paralela con un hilo ni contra un algoritmo malo (idea errónea 31). Con tareas, fib(40) tarda 0.07 s:
*speedup* "2.2" contra el recursivo y 0.000000 contra el lineal. Fibonacci enseña la mecánica de
`task`/`shared`/`taskwait`/corte en 15 líneas; para rendimiento, mergesort (2.0–2.2 con 4 hilos), la lista
(`list_tasks 100000`: 1 hilo 1.00, 2 hilos 1.88, 4 hilos 3.46) o el árbol de la fase Crear (corte 8: 1.6).

## 6. `taskloop`

```c
#pragma omp parallel
#pragma omp single
#pragma omp taskloop grainsize(64)       /* o num_tasks(k) */
for (long i = 0; i < n; i++) work(i);
```

Parte el ciclo en tareas de ~`grainsize` iteraciones que el equipo toma de la cola. Sirve cuando el ciclo
vive dentro de una tarea o de un `single` y no quieres abrir otra región paralela. Mapa real
(`./taskloop_demo 16 4`, cambia entre corridas):

```
taskloop grainsize(4)     | 1 1 1 1 3 3 3 3 2 2 2 2 0 0 0 0
for schedule(dynamic,4)   | 0 0 0 0 1 1 1 1 2 2 2 2 3 3 3 3
```

No es para ganarle a `parallel for`: en el ciclo triangular de S08 (n = 40 000), `for schedule(dynamic,64)`
dio *speedup* 2.69 y `taskloop grainsize(64)` 1.10 en la máquina de autoría (la `reduction` sobre tareas de
libgomp es más cara que la del `for`). Si hay ciclo e índices, `parallel for`.

## 7. Ejemplo resuelto en una pantalla

```c
static void merge_sort_tasks(int *a, int *tmp, long lo, long hi, long cutoff)
{
    long n = hi - lo;
    if (n <= cutoff || n < 2) { merge_sort_seq(a, tmp, lo, hi); return; }   /* corte: sin tareas */
    long mid = lo + n / 2;
    #pragma omp task              /* a, tmp, lo, mid, cutoff: firstprivate (copias del puntero y de los índices) */
    merge_sort_tasks(a, tmp, lo, mid, cutoff);
    #pragma omp task
    merge_sort_tasks(a, tmp, mid, hi, cutoff);
    #pragma omp taskwait          /* las dos mitades ordenadas antes de mezclar */
    merge(a, tmp, lo, mid, hi);
}
/* en main:  #pragma omp parallel
             #pragma omp single
             merge_sort_tasks(a, tmp, 0, n, cutoff);   */
```

Con n = 8 y corte 2: 6 tareas, siempre; quién las ejecuta, cambia. Con n = 2 000 000 y corte 4 096: 1 022
tareas y *speedup* 2.1 con 4 hilos (eficiencia 0.5: la mezcla final la hace un hilo y mezclar es copiar memoria).

## 8. Errores frecuentes

1. Leer el resultado de una tarea sin `taskwait` (idea 13). → `taskwait` antes de usar lo que la hija escribe.
2. Creer que `taskwait` espera a las nietas. → Solo a las hijas directas; `taskgroup` para todas.
3. Olvidar `shared(x)` en la variable que la hija escribe. → Resultado 0 o basura, sin carrera ni *warning*.
4. Poner `shared(a)` "por si acaso" en un puntero. → Innecesario: la copia es del puntero, el arreglo es uno.
5. Crear tareas sin corte (o con corte 1). → Millones de tareas; más lento que el secuencial.
6. Corte tan grande que quedan menos tareas que hilos. → Hilos ociosos; *speedup* ≈ 1.
7. Abrir `parallel for` dentro de la recursión. → Regiones anidadas; usa tareas, que para eso son.
8. Olvidar el `single`. → Cada hilo arranca su propia recursión sobre los mismos datos: carrera y trabajo × 4.
9. Reportar el *speedup* de Fibonacci contra el recursivo. → El mejor secuencial es el lineal (idea 31).
10. Tomar todo reporte de ThreadSanitizer sobre `#pragma omp task` como carrera. → Los que señalan `GOMP_task`
    son ruido de `libgomp`; los que tocan tus variables sin `taskwait` ni barrera, no.

## 9. Para saber más

- OpenMP Architecture Review Board, *OpenMP Application Programming Interface*, versión 5.2 (noviembre de
  2022): *task Construct*, *taskloop Construct*, *taskwait Construct*, *taskgroup Construct*, *depend Clause*
  y, para la regla del §3, *Implicitly Determined Data-Sharing Attributes*. <https://www.openmp.org/specifications/>
- GCC, *GNU Offloading and Multi Processing Runtime Library (libgomp)*, manual de la versión 13: variables de
  entorno (`OMP_NUM_THREADS`, `OMP_MAX_ACTIVE_LEVELS`). <https://gcc.gnu.org/onlinedocs/libgomp/>
- Pacheco, P. y Malensek, M., *An Introduction to Parallel Programming*, 2.ª ed., Morgan Kaufmann, 2022,
  capítulo 5 (OpenMP): sección sobre tareas (*tasking*).
