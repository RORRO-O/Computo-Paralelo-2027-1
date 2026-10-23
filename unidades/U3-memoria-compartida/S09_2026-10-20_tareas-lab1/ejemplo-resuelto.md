> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S09 · martes 20 de octubre de 2026 · 08:30–10:00 · Lab LS4

# S09 · Ejemplo resuelto: repartir trabajo que no tiene índices (lista enlazada y recursión) con tareas

Código: `practica-guiada/list_tasks.c`, `practica-guiada/fib_tasks.c`, `practica-guiada/fib_buggy.c`,
`practica-guiada/taskwait_buggy.c`. Compila con `make` dentro de `practica-guiada/`. Las salidas son corridas
reales en la máquina de autoría (4 núcleos virtuales **compartidos con otros procesos**, gcc 13, `-O2`); los
tiempos de la tuya serán otros, el comportamiento no. Lee cada paso y, en las pausas, responde **antes** de
abrir la respuesta.

## Problema

Dos trabajos que `parallel for` no puede repartir: (a) procesar cada nodo de una **lista enlazada** (no hay
`i`, solo `p->next`); (b) una **recursión** (Fibonacci, por lo corto; mergesort en la práctica guiada). Hay que
repartirlos entre 4 hilos, obtener el resultado correcto y entender qué los hace lentos.

## Plan en tres líneas

1. Un hilo recorre la lista y **encola** una tarea por nodo; los demás hilos las toman (`parallel` + `single` + `task`).
2. En la recursión, cada llamada grande crea dos tareas y **espera** con `taskwait`; ver las dos formas de
   equivocarse (una variable que no es `shared`, un `taskwait` que falta).
3. Poner un **corte** para no crear tareas diminutas, contar cuántas se crean y medir contra el mejor secuencial.

## Paso 1 · El patrón `parallel` + `single` + `task` (`list_tasks.c`, líneas 60–77)

```c
#pragma omp parallel
#pragma omp single
{
    for (node *p = head; p != NULL; p = p->next) {
        #pragma omp task            /* p entra como firstprivate: la tarea guarda SU copia del puntero */
        {
            p->result = work(p->id);
            if (verbose) printf("  nodo %ld procesado por el hilo %d\n", p->id, omp_get_thread_num());
        }
    }
    if (verbose) printf("  fin del recorrido (hilo %d): %ld tareas creadas, no necesariamente ejecutadas\n",
                        omp_get_thread_num(), n);
}   /* barrera implícita del single: aquí ya terminaron todas las tareas */
```

Dos corridas reales de `OMP_NUM_THREADS=4 ./list_tasks 8`:

```
  fin del recorrido (hilo 1): 8 tareas creadas, no necesariamente ejecutadas
  nodo 1 procesado por el hilo 3
  nodo 0 procesado por el hilo 0
  nodo 4 procesado por el hilo 1
  nodo 5 procesado por el hilo 0
  nodo 6 procesado por el hilo 1
  nodo 7 procesado por el hilo 0
  nodo 3 procesado por el hilo 3
  nodo 2 procesado por el hilo 2
n=8 hilos=4  secuencial 0.0002 s  tareas 0.0106 s  speedup 0.02  verificacion: OK

  fin del recorrido (hilo 2): 8 tareas creadas, no necesariamente ejecutadas
  nodo 0 procesado por el hilo 3
  nodo 2 procesado por el hilo 0
  nodo 1 procesado por el hilo 1
  nodo 3 procesado por el hilo 2
  ...
```

**Pausa 1.** `fin del recorrido` se imprime **antes** que cualquier nodo, en las dos corridas. ¿Por qué, si
las ocho tareas se crearon dentro del `for` que está antes de ese `printf`?

<details><summary>Respuesta</summary>

Porque `#pragma omp task` **encola** la tarea; no la ejecuta en el acto (idea errónea 13). El hilo que entró
al `single` crea las ocho en microsegundos, imprime `fin del recorrido` y solo entonces, al llegar a la
barrera implícita del `single`, se pone a ejecutar tareas junto con los otros tres hilos. Fíjate en que el
hilo que recorrió (1 en la primera corrida, 2 en la segunda) también procesa nodos: en la barrera nadie se
queda cruzado de brazos. Quién procesa qué nodo cambia entre corridas: el reparto es dinámico.
</details>

**Pausa 2.** `p` se declara dentro del `for`, dentro de la región paralela, y sigue avanzando mientras las
tareas esperan en la cola. ¿Por qué cada tarea procesa el nodo correcto y no el último de la lista?

<details><summary>Respuesta</summary>

`p` es una variable local del hilo del `single` (lo declarado dentro de la región es privado del hilo, idea
errónea 15 al revés). Para una tarea, toda variable que **no** es compartida en el contexto que la crea entra
como **`firstprivate`**: la tarea guarda una copia del puntero con el valor que tenía en ese instante. Ocho
tareas, ocho copias, ocho nodos distintos. Si `p` fuera `shared` (por ejemplo, declarada antes del
`parallel` y con `shared(p)`), todas las tareas verían el `p` que avanza y varias procesarían el mismo nodo o
`NULL`.
</details>

## Paso 2 · Recursión con tareas: Fibonacci (`fib_tasks.c`, líneas 39–59)

```c
static long fib_tasks(int n, int cutoff)
{
    if (n < cutoff)                 /* corte: por debajo, recursivo secuencial, sin tareas */
        return fib_seq(n);
    long x, y;
    #pragma omp task shared(x)      /* x la ESCRIBE la hija y la LEE el padre: shared, no copia */
    x = fib_tasks(n - 1, cutoff);
    #pragma omp task shared(y)
    y = fib_tasks(n - 2, cutoff);
    #pragma omp taskwait            /* antes de esta línea NO es seguro leer x ni y */
    return x + y;
}
/* en main:  #pragma omp parallel
             #pragma omp single
             r = fib_tasks(n, cutoff);  */
```

Las tareas crean tareas: la hija que calcula `fib(n−1)` crea a su vez dos nietas, desde el hilo que la tomó. El
`single` solo arranca la raíz.

**Pausa 3.** `x` y `y` son locales de la función, igual que `p` en el paso 1. Allá no hizo falta ninguna
cláusula; aquí llevan `shared(x)` y `shared(y)`. ¿Qué cambió?

<details><summary>Respuesta</summary>

La dirección del dato. `p` la **lee** la tarea (copia suficiente). `x` la **escribe** la hija y la **lee** el
padre después del `taskwait`: si `x` entrara como `firstprivate`, la hija escribiría en su copia y el padre
leería su propia `x`, que nadie tocó. Regla: *lo que la hija escribe y el padre lee, `shared`*.
</details>

### Variante que falla 1 · Sin `shared` (`fib_buggy.c`)

Mismo código, sin las cláusulas; `x` e `y` inicializadas en 0 para que la lectura esté definida:

```
$ ./fib_buggy
fib_buggy(30) con cutoff=20 e hilos=4: 0   esperado 832040   -> INCORRECTO (las hijas escribieron en copias firstprivate)
```

Siempre 0, con 1 o con 4 hilos. **No** es una carrera (nadie comparte nada) y gcc no avisa: el programa es
correcto según el lenguaje; simplemente no calcula lo que querías. ThreadSanitizer tampoco lo ve. La única
defensa es la regla de la Pausa 3.

## Paso 3 · Esperar: `taskwait` y la barrera (`taskwait_buggy.c`, líneas 37–48)

```c
long left = 0, right = 0, premature = -1;     /* declaradas ANTES de parallel: compartidas en la región */
#pragma omp parallel
#pragma omp single
{
    #pragma omp task shared(left)
    left = sum_range(a, 0, n / 2);
    #pragma omp task shared(right)
    right = sum_range(a, n / 2, n);
    /* FALTA AQUÍ:  #pragma omp taskwait  */
    premature = left + right;                 /* lectura prematura */
}   /* barrera implícita del single: aquí ya terminaron TODAS las tareas */
long after = left + right;
```

Tres corridas reales con 4 hilos y una con 1 hilo, todas iguales:

```
n=20000000 hilos=4 esperado=90000000
dentro del single, sin taskwait   : 0  -> INCORRECTO
despues de la barrera del single  : 90000000  -> correcto
```

**Pausa 4.** La misma variable `left` se lee dos veces: mal la primera, bien la segunda. ¿Qué hay entre las
dos lecturas que cambia el resultado? ¿Qué línea falta y dónde iría?

<details><summary>Respuesta</summary>

Entre ambas está la llave de cierre del `single`, que lleva una **barrera implícita**: ningún hilo la cruza
hasta que todos los hilos llegan **y todas las tareas pendientes terminan**. La primera lectura ocurre
microsegundos después de encolar dos tareas de 10 millones de sumas cada una: ninguna ha terminado (en esta
máquina, ninguna ha empezado: `left` y `right` todavía valen 0). Falta `#pragma omp taskwait` justo antes de
`premature = left + right;`. Que con un hilo también salga 0 confirma que libgomp difiere la tarea aunque no
haya nadie más que la tome.
</details>

Reporte real de ThreadSanitizer (`make tsan`; recortado a lo que importa):

```
WARNING: ThreadSanitizer: data race
  Write of size 8 ... by thread T3:
    #0 main._omp_fn.1 taskwait_buggy.c:21      <- la escritura de `left` (el return de sum_range, inlineado en la tarea)
  Previous read of size 8 ... by thread T1:
    #0 main._omp_fn.0 taskwait_buggy.c:46      <- premature = left + right
  Location is stack of main thread.
```

Hay otro igual para `right`. Son dos de los once reportes que salen: los otros nueve señalan las líneas 41–44
contra un `memcpy` dentro de `GOMP_task` (la biblioteca copiando el entorno de datos de la tarea) o la línea
38 contra la 46 (una lectura después de la región, ordenada por la barrera). Como en S07: ThreadSanitizer no
ve la sincronización de `libgomp`; un reporte es carrera real solo si las dos líneas tocan **tus** variables
sin `taskwait` ni barrera en medio.

## Paso 4 · El corte y cuántas tareas se crean

Cada llamada con `n ≥ cutoff` crea dos tareas; el total es 2·(fib(n − cutoff + 3) − 1): crece como
1.618^(n − cutoff). Mediciones reales de `./fib_tasks 40 c` con 4 hilos (mediana de 5 tras 1 calentamiento):

| `cutoff` | Tareas creadas | t recursivo (s) | t tareas (s) | *Speedup* vs recursivo |
|---|---|---|---|---|
| 30 | 464 | 0.159 | 0.074 | 2.15 |
| 27 | 1 972 | 0.156 | 0.070 | 2.23 |
| 25 (por defecto) | 5 166 | 0.164 | 0.095 | 1.73 |
| 22 | 21 890 | 0.184 | 0.107 | 1.72 |
| 20 | 57 312 | 0.169 | 0.113 | 1.51 |
| 15 | 635 620 | 0.169 | 0.612 | 0.28 |

Y una sola corrida de `./fib_tasks 36 2` hecha una vez por quien escribió esto (el programa ahora lo impide con
un aviso): **48 315 632 tareas, 25.9 s**, para un `fib(36)` que el recursivo calcula en 0.023 s.

**Pausa 5.** El trabajo útil (las sumas) es el mismo con cualquier corte. ¿De dónde salen los 25.9 s?
¿Y por qué con corte 30 (464 tareas) ya no mejora respecto a 27?

<details><summary>Respuesta</summary>

De la **sobrecarga por tarea**: reservar memoria para su entorno de datos, encolarla, que un hilo la tome,
terminarla y despertar al `taskwait` que la espera. Son microsegundos por tarea; 48 millones de veces son
decenas de segundos, mientras que el trabajo de cada tarea (`fib(1)`, `fib(0)`) es de nanosegundos. Por arriba
pasa lo contrario: con 464 tareas para 4 hilos todavía hay con qué balancear, pero menos; con corte 35 habría
2·(fib(8)−1) = 40 tareas de tamaños muy desiguales (`fib(34)` tarda 1.6 veces lo que `fib(33)`) y algún hilo
se quedaría esperando. El corte se elige en la meseta: tareas que valgan mucho más que crearlas, y varias
veces más tareas que hilos. Es la aglomeración de Foster escrita en una línea de código.
</details>

## Paso 5 · Contra qué se mide (por qué Fibonacci es mal ejemplo de rendimiento)

Corrida real por defecto, `OMP_NUM_THREADS=4 ./fib_tasks` (n = 40, corte 25):

```
fib(40) = 102334155   hilos=4 cutoff=25 reps=5 (mediana tras 1 calentamiento)
lineal    : 0.000000024 s   <- mejor secuencial: T(1) del protocolo
recursivo : 0.1640 s  (min 0.1616  max 0.1831)
tareas    : 0.0947 s  (min 0.0628  max 0.1013)   tareas creadas = 5166
speedup contra el recursivo: 1.73   speedup contra el lineal: 0.000000
verificacion: OK
```

El recursivo repite trabajo de forma exponencial; el **mejor secuencial** es el lineal: 24 nanosegundos. El
protocolo del curso (§3) define `T(1)` como el mejor programa secuencial disponible (idea errónea 31). Contra
él, las tareas pierden por un factor de cuatro millones; paralelizar un algoritmo malo no lo arregla. Por eso
Fibonacci solo enseña la mecánica, y la práctica guiada mide con mergesort.

Una advertencia que también es dato real: el mismo comando, corrido mientras otros procesos ocupaban los 4
núcleos (carga promedio 4.6), dio `recursivo 0.3014 s`, `tareas 0.3079 s`, *speedup* 0.98. Medir con la
máquina ocupada no mide tu programa (idea errónea 5; `uptime` antes de medir).

Dónde sí rinden las tareas con el mismo patrón, `./list_tasks 100000` (trabajo de ~25 µs por nodo):

| Hilos | Secuencial (s) | Tareas (s) | *Speedup* |
|---|---|---|---|
| 1 | 2.141 | 2.146 | 1.00 |
| 2 | 2.041 | 1.086 | 1.88 |
| 4 | 2.176 | 0.628 | 3.46 |

Con un hilo las tareas no cuestan casi nada aquí (100 000 tareas de 25 µs: la sobrecarga es < 1 %); con 4,
la lista se reparte casi perfecto porque un hilo genera 100 000 unidades de trabajo iguales y tres las
consumen.

## Panorama en dos líneas (no se usa en la Práctica 4)

- `taskloop`: parte un ciclo en tareas (`grainsize` o `num_tasks`) cuando ya estás dentro de un `single` o de
  una tarea; `practica-guiada/taskloop_demo.c` imprime el mapa y lo compara con `schedule(dynamic)`.
- `depend(in:…)` / `depend(out:…)`: declara qué tarea produce qué dato y OpenMP ordena las tareas sin
  `taskwait`; sirve para *pipelines* y *stencils* por bloques (S11 los ve con `parallel for`).

## Qué te llevas

1. `task` **encola**; el creador sigue. Para leer lo que una tarea escribió: `taskwait` (hijas directas) o la
   barrera del `single`/`parallel` (todas). `taskgroup` espera también a las nietas.
2. Lo que no es compartido donde se crea la tarea entra como **`firstprivate`** (copia). Lo que la hija escribe
   y el padre lee va con **`shared`**; sin ella, resultado 0 sin carrera ni aviso.
3. El **corte** decide el número de tareas (2·(n/c − 1) en mergesort; exponencial en Fibonacci) y por tanto la
   sobrecarga. Meseta: tareas mucho más caras que crearlas, y muchas más tareas que hilos. Se mide.
4. El *speedup* se reporta contra el **mejor secuencial**. Fibonacci con tareas pierde contra el lineal por
   un factor de millones; mergesort, la lista y el árbol sí ganan.
