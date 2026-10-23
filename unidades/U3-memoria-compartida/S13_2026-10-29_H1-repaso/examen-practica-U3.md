> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S13 · jueves 29 de octubre de 2026 · 10:30–12:00 · Salón 3208

# Examen de práctica · Unidad III (versión corta: 40 minutos, 60 puntos)

## Cómo se usa

- Se publica el **martes 27 de octubre** (S12). Lo resuelves **en casa antes del jueves 29 a las 10:30**, en
  papel, cronometrado a **40 minutos**, sin apuntes, sin dispositivos y sin IA (es zona sin IA, igual que el
  examen). Antes de empezar llenas la casilla 1 de la hoja de calibración (al final de este archivo); al
  terminar, la casilla 2. **No abras los bloques de clave** hasta que termine el cronómetro.
- El jueves 29 traes tus respuestas; en clase se corrigen **entre pares** con la clave y la guía de corrección
  (abajo), se discuten los tres ítems peor contestados y llenas la casilla 3.
- El **Examen 2** es el **martes 3 de noviembre, 08:30–10:00**: misma estructura, 100 puntos, 80 minutos,
  versiones A/B alternadas por fila, sin dispositivos, hoja de calibración aparte. Esta versión corta tiene
  60 % de los puntos y la mitad del tiempo: aquí vas a 0.67 min por punto; en el examen tendrás 0.8, un poco
  más de holgura.
- Si faltas el 29: lo haces en casa con la clave y registras igual la hoja de calibración
  (`docs/metodo/04-evaluacion.md`, §5).

Todo el código de los ítems II, III, IV y VI está en `practica-guiada/examen_items/` y se compiló y ejecutó
para fijar las salidas (`make run-examen`). En el examen no hay computadora: lo que practicas es predecir.

## Tabla de especificaciones (versión corta)

| Tema | Recordar / comprender | Aplicar / analizar | Evaluar / crear | Puntos |
|---|---|---|---|---|
| Carreras, `atomic`, `critical`, `reduction` (S07) | I.1, I.2 (6) | III.1 (6) | | 12 |
| Alcance: `private`, `firstprivate`, declarado adentro (S07) | | II.1 (5), III.1-c (incluido) | | 5 |
| Barreras, `nowait`, `schedule`, mapeo (S07–S08) | I.3 (3) | II.2 (5) | | 8 |
| Tareas (S09) | I.4 (3) | IV (8) | | 11 |
| Patrones y dependencias (S11) | | III.2 (6) | | 6 |
| Rendimiento: Amdahl en tiempo, eficiencia, Karp–Flatt, escalabilidad (S10, S12; U I) | I.5 (3) | V.a–c (6) | V.d (3) | 12 |
| Diseño: elegir construcción y `schedule`, plan de medición (S08, S11; U II) | | | VI (6) | 6 |
| **Total** | 15 (25 %) | 36 (60 %) | 9 (15 %) | **60** |

Unidades previas integradas: I.5, V.a–b (Amdahl y eficiencia, Unidad I) y la partición/aglomeración de VI
(Unidad II): 9 puntos, 15 %. Objetivo del Examen 2: 30 / 50 / 20 y 10–20 % de unidades previas; la versión
corta queda cargada hacia aplicar/analizar porque es donde más se falla.

---

## I. Opción múltiple (5 ítems × 3 puntos = 15). Una sola opción; no se justifica.

**I.1.** ThreadSanitizer reporta `data race` en la línea `total += v;` de un `parallel for` de tu Práctica 4,
donde `total` está declarada fuera de la región y sin cláusula. Corriste el programa 20 veces con 4 hilos y
las 20 veces el resultado coincidió con la versión secuencial. ¿Qué haces?

- A) Ignoro el reporte: 20 corridas correctas demuestran que no hay carrera.
- B) Protejo `total` (`reduction(+:total)` o, si no se puede, `atomic`) porque la carrera existe aunque no
  se manifieste, y verifico con `make test` con 2 y 4 hilos.
- C) Recompilo con `-O0`: si con `-O0` también sale bien, no hay carrera.
- D) Subo a 8 hilos: si sigue saliendo bien, el reporte era un falso positivo de `libgomp`.

<details><summary>Clave I.1</summary>

**B.** Una carrera es no determinista: que no se manifieste no es evidencia (idea errónea 7). Dos hilos
trabajadores sobre una variable de fuera de la región sin nada que los ordene es una carrera real, no ruido
de `libgomp` (el ruido aparece en código **protegido** por `critical`, candados o barreras, S07 fase 3.3).
A: idea 7. C: idea 5 (`-O0` cambia la probabilidad de observarla, no su existencia; además nunca se mide ni se
valida con `-O0`). D: ideas 7 y 1 combinadas; más hilos no demuestran nada.
</details>

**I.2.** Para encontrar el máximo de `x[0..n)` **y su posición**:

```c
double best = x[0]; long best_i = 0;
#pragma omp parallel for
for (long i = 1; i < n; i++)
    if (x[i] > best) { best = x[i]; best_i = i; }
```

¿Cuál es la corrección correcta y más barata?

- A) `#pragma omp atomic` justo antes del `if`: es una actualización de variables compartidas.
- B) Un máximo local por hilo (`my_best`, `my_i`, declarados dentro de la región) y, al final de cada hilo, una
  sola comparación-y-escritura dentro de `#pragma omp critical`.
- C) `reduction(max:best, best_i)`: OpenMP combina los dos máximos al final.
- D) Nada: cada hilo procesa índices `i` distintos, así que nunca escriben al mismo tiempo.

<details><summary>Clave I.2</summary>

**B.** Dos variables que deben cambiar **juntas** y una comparación: no cabe en `atomic` (idea errónea 8;
`atomic` cubre `x++`, `x += e`, `x = x op e` sobre **una** variable escalar). `critical` alrededor del `if`
en cada iteración también es correcto pero serializa el ciclo; con máximos locales el `critical` se ejecuta
una vez por hilo. C: `reduction(max:best_i)` daría el **mayor de los índices** que encontró cada hilo, no
el índice del máximo (idea errónea 10b: `reduction` combina cada variable por separado, no sabe que las dos
van juntas). D: confunde el índice del ciclo con la variable compartida que todos escriben (idea 7d; S07,
CT2-C).
</details>

**I.3.** Un ciclo de 10⁶ iteraciones donde **todas cuestan lo mismo** (≈ 50 ns cada una) corre con
`schedule(static)` y 4 hilos. Un compañero lo cambia a `schedule(dynamic, 1)` "porque `dynamic` balancea
mejor". ¿Qué pasa con el tiempo del ciclo?

- A) Baja: `dynamic` siempre reparte mejor que `static`.
- B) Sube: cada iteración paga una operación atómica para pedir el siguiente bloque, y aquí no hay desbalance
  que compensar.
- C) No cambia: el reparto solo afecta la correctitud, no el tiempo.
- D) Baja solo si además se agrega `nowait`, que quita la barrera que `dynamic` añade.

<details><summary>Clave I.3</summary>

**B.** Idea errónea 11: `dynamic` tiene costo por *chunk* y gana solo cuando las iteraciones son desiguales.
En S08 con carga uniforme: `static` 0.37 s, `dynamic,1` 0.75 s (más lento que la secuencial, 0.45 s),
`dynamic,256` 0.21 s (con *chunk* grande el costo por pedido desaparece; que en esa máquina virtual quedara
por debajo de `static` es ruido de la VM, como advierte S08 §3). A: idea 11 literal. C: idea 11b ("el reparto
no afecta el tiempo"); el reparto es exactamente lo que decide el tiempo del hilo más lento. D: idea 12
mezclada: `dynamic` no añade barreras; la implícita del `for` está en todas las políticas.
</details>

**I.4.** Con 4 hilos:

```c
long r = 0;
#pragma omp parallel
#pragma omp single
{
    #pragma omp task shared(r)
    r = heavy(42);                 /* tarda ~1 s */
    printf("%ld\n", r);
}
```

¿Qué imprime?

- A) `heavy(42)`: la tarea se ejecuta en el momento en que se crea.
- B) Lo más probable es `0`: la tarea se **encola** y el hilo del `single` sigue al `printf` sin esperarla;
  falta `#pragma omp taskwait` antes del `printf`.
- C) `heavy(42)`: `single` termina con una barrera que espera a todas las tareas.
- D) No compila: `shared` no se permite en `task`.

<details><summary>Clave I.4</summary>

**B.** Idea errónea 13: `task` encola; `taskwait` espera a las hijas directas. En `taskwait_buggy.c` (S09) la
lectura dentro del `single` dio `0` tres de tres veces. C: la barrera del `single` está al **final** del bloque,
**después** del `printf`; sí espera a las tareas, pero demasiado tarde para esta lectura (idea 12 en
variante). A: idea 13 literal. D: `shared` es precisamente la cláusula que necesita `r` en una tarea.
</details>

**I.5.** Mediciones con el protocolo (`-O2`, mediana de 5): mejor secuencial `T(1) = 8.0 s` con `n`;
`T(4) = 2.5 s` con el mismo `n`; y `T(8) = 2.6 s` con `2n` (8 núcleos físicos). ¿Cuál afirmación es correcta?

- A) La eficiencia con 4 hilos es 3.2.
- B) `S(4) = 3.2` y `E(4) = 0.8`; la fila de 8 hilos cambió `n`, así que no da un *speedup* (fuerte): solo
  sirve como dato de escalabilidad **débil**.
- C) `S(8) = 8.0 / 2.6 ≈ 3.1`: con 8 hilos escala peor que con 4.
- D) Con 8 hilos la eficiencia es `3.1 / 8 ≈ 0.38`: pasar de 4 a 8 hilos empeora el programa.

<details><summary>Clave I.5</summary>

**B.** `S = T(1)/T(p)` con el **mismo** problema; `E = S/p`. A: idea errónea 3 (eficiencia = *speedup*). C y
D: idea 6 (fuerte y débil como sinónimos): con `2n` el cociente `T(1,n)/T(8,2n)` no es un *speedup*. Lo que
sí se puede reportar es débil: de 4 a 8 hilos se duplicaron `p` y `n`, así que la eficiencia débil entre esas
dos filas es `T(4,n)/T(8,2n) = 2.5/2.6 ≈ 0.96` (escala bien en débil). Contra `T(1)` no es débil propiamente:
habría que medir con `8n`. D además es la idea 1 al revés.
</details>

---

## II. Predecir la salida (2 ítems × 5 puntos = 10). Justifica en una línea.

**II.1.** (`examen_items/item_II1_firstprivate.c`)

```c
int base = 10;
int out[8];
#pragma omp parallel for firstprivate(base) schedule(static)
for (int i = 0; i < 8; i++) {
    base += i;
    out[i] = base;
}
printf("base=%d out=", base);
for (int i = 0; i < 8; i++) printf("%d ", out[i]);
```

a) (3 pts) ¿Qué imprime con **4 hilos**? b) (1 pt) ¿Y con **1 hilo**? c) (1 pt) Si la cláusula fuera
`private(base)`, ¿qué se puede afirmar de la salida?

<details><summary>Clave II.1</summary>

a) `base=10 out=10 11 12 15 14 19 16 23`. `static` con 8 iteraciones y 4 hilos: cada hilo toma dos
iteraciones contiguas y arranca con **su copia** `base = 10` (`firstprivate`): hilo 0: `10, 11`; hilo 1:
`12, 15`; hilo 2: `14, 19`; hilo 3: `16, 23`. La `base` de afuera no cambia (`firstprivate` no escribe de
regreso). Salida real con 4 hilos. Puntos: 3 si las ocho cifras y `base=10`; 2 si el patrón por hilo es
correcto con un error aritmético; 1 si solo `base=10`; 0 si `out = 10 11 13 16 …` (ignora que hay 4 copias).
b) `base=10 out=10 11 13 16 20 25 31 38` (una sola copia que acumula; salida real con 1 hilo). El programa
es correcto y aun así **su resultado depende del número de hilos**: señal de diseño dudoso, no de carrera.
c) Nada: cada copia arranca con un valor **indefinido** (idea errónea 9); no se puede predecir ni es
reproducible. Se acepta "basura/indefinido". No se acepta "`out` con ceros" (idea 9b) ni "igual que a)".
</details>

**II.2.** (`examen_items/item_II2_static_map.c`)

```c
int owner[12];
#pragma omp parallel num_threads(4)
{
    #pragma omp for schedule(static, 2)
    for (int i = 0; i < 12; i++)
        owner[i] = omp_get_thread_num();

    #pragma omp single
    printf("single ejecutado por el hilo %d\n", omp_get_thread_num());
}
printf("owner="); for (int i = 0; i < 12; i++) printf("%d ", owner[i]);
```

a) (3 pts) Escribe `owner[0..11]`. b) (1 pt) ¿Cuántas veces se imprime la línea del `single` y qué hilo la
imprime? c) (1 pt) Si el ciclo fuera `schedule(dynamic, 2)`, ¿qué puedes afirmar de `owner`?

<details><summary>Clave II.2</summary>

a) `owner=0 0 1 1 2 2 3 3 0 0 1 1`: bloques de 2 repartidos cíclicamente (S08, `schedule_map`). Salida real.
Puntos: 3 si exacto; 1 si escribe el reparto de `static` sin *chunk* (`0 0 0 1 1 1 2 2 2 3 3 3`: ignora el 2).
b) **Una** vez, por **cualquier** hilo (el primero que llega; en seis corridas reales salió 1, 2, 3, 3, 1, 1).
"El hilo 0" es incorrecto (ese es `master`); "cuatro veces" también.
c) **Nada**: con `dynamic` el reparto depende de qué hilo se desocupa primero; cambia entre corridas y no se
puede predecir (S08). Se acepta "no determinista". No se acepta un arreglo concreto.
</details>

---

## III. Encontrar y corregir el error (2 ítems × 6 puntos = 12)

**III.1.** (`examen_items/item_III1_dot_buggy.c`) Producto punto con 4 hilos. Compila, corre y, en la máquina
de autoría, imprimió `dot=125001.736971857` contra `500415.914381676` de la secuencial.

```c
double dot = 0.0;
#pragma omp parallel for
for (long i = 0; i < n; i++) {
    double p = x[i] * y[i];
    dot += p;
}
```

a) (2 pts) ¿Cuál es el error? Línea y regla que rompe. b) (2 pts) Escribe la corrección **más barata que sea
correcta** (una línea de código). c) (1 pt) ¿Hay que hacer algo con `p`? ¿Por qué? d) (1 pt) Con la
corrección, el resultado con 4 hilos fue `500415.914381686` contra `…676` de la secuencial. ¿Está mal?
¿Cómo debe compararse?

<details><summary>Clave III.1</summary>

a) `dot += p`: `dot` está declarada fuera de la región sin cláusula (compartida) y todas las iteraciones la
escriben: carrera (leer-modificar-escribir sin orden; idea 7). El resultado de la máquina de autoría fue
**un cuarto** del correcto: con `-O2` cada hilo acumula en registro y escribe al final; sobrevivió un hilo.
b) `#pragma omp parallel for reduction(+:dot)`. También correctos, con menos puntos (1): `#pragma omp atomic`
antes de `dot += p` (una atómica por elemento, ×5 más caro en S07) y `critical` (serializa; 0.5). 0 puntos:
`private(dot)` (el resultado sería 0: cada hilo suma en una copia que se descarta).
c) No: `p` está declarada **dentro** del cuerpo, es privada por alcance (idea errónea 15). `private(p)`
no es un error pero sobra; "hay que ponerla `private`" vale 0.5.
d) No está mal: `reduction` suma los parciales en otro orden y el redondeo cambia en el undécimo dígito
(idea errónea 10). Se compara con tolerancia relativa (`make test` usa `1e-9`), no con `==`.
</details>

**III.2.** (`examen_items/item_III2_scan_buggy.c`) Suma de prefijos `y[i] = x[0] + … + x[i]` con enteros.
Con 4 hilos imprimió `y[n-1]=524813375` contra `2099249768` de la secuencial, y 3 145 727 de los 4 194 304
elementos distintos: los del primer cuarto salieron bien.

```c
y[0] = x[0];
#pragma omp parallel for
for (long i = 1; i < n; i++)
    y[i] = y[i - 1] + x[i];
```

a) (2 pts) ¿Cuál es el error? b) (2 pts) Un compañero propone "ponerle `reduction`, o `atomic`, o
`critical`, o `ordered`". Explica por qué **ninguna cláusula** lo corrige. c) (2 pts) ¿Cómo se corrige?
(estructura en 3–4 líneas de texto o pseudocódigo; no hace falta el código completo).

<details><summary>Clave III.2</summary>

a) Dependencia acarreada por el ciclo: la iteración `i` **lee** `y[i-1]`, que **escribe** la iteración `i-1`
(idea errónea 30: no todo `for` se paraleliza con `parallel for`). Con `static`, cada hilo arranca su bloque
leyendo un `y[lo-1]` que otro hilo no ha escrito (en la corrida real valía 0): cada bloque sale como suma
local; solo el bloque del hilo 0 coincide.
b) No es una carrera por una variable compartida que se pueda proteger: es un **orden** obligatorio entre
iteraciones. `reduction` combina copias al final (no sirve para "el valor anterior"); `atomic`/`critical`
hacen atómica cada escritura pero no obligan a que `i-1` termine antes que `i`; `ordered` sí lo obliga y por
eso **serializa** el ciclo: correcto y más lento que la secuencial. Se acepta cualquier dos de las cuatro
razones bien dichas.
c) Cambiar el algoritmo (S11, *scan* en dos fases): (1) cada hilo hace el *scan* **local** de su bloque y guarda el
total del bloque; (2) barrera; (3) cada hilo calcula su desplazamiento sumando los totales de los bloques
anteriores; (4) suma el desplazamiento a todo su bloque. Costo: casi el doble del tráfico de memoria del secuencial
(la fase final vuelve a leer y escribir todo el arreglo); en S11 dio *speedup* 1.9 con 4 hilos. También vale
"dejarlo secuencial si es < 5 % del tiempo" con la razón (Amdahl), 1 punto. Salida real corregida:
`elementos distintos=0 ok` con 1, 3 y 4 hilos.
</details>

---

## IV. Completar código (4 huecos × 2 puntos = 8)

(`examen_items/item_IV_tasks_sum.c`) Suma de un arreglo por división recursiva con tareas y corte. Llena
los cuatro huecos para que el programa sea correcto con cualquier número de hilos.

```c
static long sum_tasks(const long *v, long lo, long hi, long cutoff)
{
    if (hi - lo <= cutoff)
        return sum_seq(v, lo, hi);
    long mid = lo + (hi - lo) / 2;
    long left, right;
    #pragma omp task ______(1)______
    left = sum_tasks(v, lo, mid, cutoff);
    #pragma omp task ______(2)______
    right = sum_tasks(v, mid, hi, cutoff);
    #pragma omp ______(3)______
    return left + right;
}

int main(void) { ...
    long total = 0;
    #pragma omp ______(4a)______
    #pragma omp ______(4b)______
    total = sum_tasks(v, 0, n, cutoff);
    printf("total=%ld\n", total);
```

Sin puntos: con `n = 2²⁰` y `cutoff = 4096`, ¿cuántas tareas se crean?

<details><summary>Clave IV</summary>

(1) `shared(left)` (2) `shared(right)`: `left` y `right` son locales de la función que crea la tarea, así que
por omisión entrarían como `firstprivate` (copia): la hija escribiría en su copia y el padre leería la suya
(S09, `fib_buggy.c`: resultado 0 sin carrera ni aviso). (3) `taskwait`: espera a las dos hijas directas antes
de combinar; sin él, `left + right` se lee antes de tiempo (idea 13). (4a) `parallel` (4b) `single`: el
equipo se crea una vez y **un** hilo genera las tareas raíz; sin `single`, cada hilo recorrería el árbol
completo y el total se calcularía 4 veces (y se escribiría 4 veces en `total`). Se acepta `parallel` y
`single` en dos pragmas o `parallel` seguido de `single` en bloque; se acepta `master` en (4b) con 1 punto
(funciona pero no tiene barrera: `total` se lee después de la región, así que aquí no falla).
Salida real con 4 hilos: `total=52952176 (secuencial 52952176) tareas=510`. Tareas: `2²⁰/4096 = 256` hojas →
255 nodos internos × 2 tareas = **510**.
</details>

---

## V. Problema numérico de rendimiento (9 puntos). Muestra las operaciones; dos decimales.

Perfil por secciones de la V1 de un equipo, al tamaño declarado, `-O2`, mediana de 5 corridas con
calentamiento:

| Sección | Tiempo (s) | ¿Paralelizable en V2? |
|---|---|---|
| Lectura y preparación | 0.60 | No |
| Núcleo A | 2.40 | Sí |
| Núcleo B | 0.80 | Sí |
| Combinación y escritura | 0.20 | No |

El equipo paraleliza A y B y mide `T(4) = 1.90 s` (mismo tamaño, 4 núcleos físicos, mediana de 5).

a) (2 pts) Fracción paralelizable `f_p` **en tiempo**. b) (2 pts) *Speedup* que predice Amdahl con 4 hilos y
cota con infinitos hilos. c) (2 pts) *Speedup* y eficiencia **medidos** con 4 hilos. d) (3 pts) Fracción
secuencial de Karp–Flatt `f = (1/S − 1/p)/(1 − 1/p)` con la medición, comparada con `1 − f_p`. ¿Qué te dice
la diferencia y qué dos causas físicas buscarías primero?

<details><summary>Clave V (números de `examen_items/item_V_numeros.py`)</summary>

a) `T(1) = 4.00 s`; paralelizable `2.40 + 0.80 = 3.20 s`; **`f_p = 0.80`**. Cero puntos si se calcula con
líneas de código o "a ojo" (idea errónea 2).
b) `S_A(4) = 1 / (0.20 + 0.80/4) = 1 / 0.40 = `**`2.50`**; `S_A(∞) = 1 / 0.20 = `**`5.0`**.
c) `S = 4.00 / 1.90 = `**`2.11`**; `E = 2.11 / 4 = `**`0.53`** (53 %). Un punto si `S` bien y `E = 2.11`
(idea errónea 3).
d) `f = (1/2.11 − 1/4) / (1 − 1/4) = (0.475 − 0.250) / 0.750 = `**`0.30`**. Es mayor que `1 − f_p = 0.20`: la
parte paralela no escaló perfecto; hay un 0.10 de "secuencial efectivo" que no está en el perfil:
sobrecarga que crece con los hilos. Causas a buscar primero (dos de estas): sincronización (`critical`/
`atomic` por elemento, barreras por iteración), ancho de banda de memoria compartido entre núcleos,
desbalance de carga (`static` con iteraciones desiguales), falso compartido en acumuladores contiguos,
creación de regiones paralelas dentro de un ciclo. Tres puntos: `f` correcta + comparación + dos causas; dos:
`f` correcta + una causa; uno: solo `f`. No vale "hay que medir con `-O0`" (idea 5) ni "usar la paralela con 1
hilo como `T(1)`" (idea 31).
</details>

---

## VI. Diseño breve (6 puntos; ≤ 10 líneas)

Para cada `k` en `1..N` (`N = 2 000 000`) se calcula la longitud de la secuencia de Collatz (`k → k/2` si es
par, `3k+1` si es impar, hasta llegar a 1; entre 0 y 556 pasos, sin patrón respecto a `k`), se acumula un
histograma `hist[len]++` de 1000 clases y el máximo `maxlen`. Diseña la versión OpenMP con 4 hilos:

a) (2 pts) Qué construcción usas para `hist` y para `maxlen`, y por qué no `atomic`/`critical` por elemento.
b) (2 pts) Qué `schedule` eliges y por qué (una razón ligada a la forma del trabajo); qué es "una tarea" y qué
es la aglomeración en términos de Foster.
c) (2 pts) Qué medirías para comprobar que tu elección fue la correcta (protocolo: qué, contra qué, cuántas
veces, con qué tamaño).

<details><summary>Clave VI (referencia medida en `examen_items/item_VI_collatz.c`)</summary>

a) `reduction(+:hist[:1000])` (o histograma local por hilo y volcado una vez al final con `critical`) y
`reduction(max:maxlen)`. `atomic`/`critical` por elemento ponen una operación sincronizada por `k` sobre una
línea de caché compartida (contención y falso compartido, ideas 8 y 14); con acumuladores privados la única
sincronización es una combinación por hilo. 2 puntos; 1 punto si propone `atomic` por elemento **con** la
observación de que aquí el trabajo por iteración (~250 ns) es 10× el costo del `atomic` y por eso se debe
medir; 0 si `critical` por elemento sin más.
b) `schedule(dynamic, c)` con `c` del orden de cientos a miles (o `guided`): el costo por `k` es irregular y
sin patrón, así que `static` deja hilos ociosos; `dynamic,1` pagaría una atómica por iteración (idea 11).
Foster: la **tarea** es "la longitud de un `k`"; la **aglomeración** es el *chunk* de `c` valores
consecutivos; el **mapeo** es dinámico. 2 puntos: `dynamic`/`guided` con *chunk* y la razón "trabajo
irregular"; 1: `dynamic` sin *chunk* o sin razón; 0: `static` "porque es más rápido".
c) Con el protocolo: `-O2`, 1 calentamiento + 5 repeticiones, mediana, `T(1)` del **mejor secuencial**, mismo
`N` para 1, 2 y 4 hilos; comparar `static` contra `dynamic,c` para dos o tres `c`, y la versión con
acumuladores privados contra `atomic`; verificar antes que `hist` y `maxlen` coinciden exactamente con la
secuencial (enteros). 2 puntos: menciona mediana de ≥ 5, `T(1)` secuencial y la comparación `static` vs
`dynamic`; 1: solo "medir el *speedup*".

Lo medido (`make run-examen`: 4 hilos, `N = 2·10⁶`, secuencial 0.42–0.51 s, 1 calentamiento + 5
repeticiones, mediana) en una máquina virtual de 4 núcleos **compartida con otros procesos**, nueve corridas
(tres de autoría y seis de revisión). Las salidas no son deterministas: los rangos son anchos y la tuya dará
otros números.

| Versión | *Speedup* con 4 hilos (rango en 9 corridas) |
|---|---|
| `static` + `reduction` | 1.6–3.8 |
| `dynamic,1024` + `reduction` | 1.7–4.1 |
| `dynamic,1024` + `atomic`/`critical` por elemento | 1.6–3.8 |
| `dynamic,1` + `reduction` | 1.3–2.2 |

Lo estable es el **orden**, no el número: `dynamic,1` perdió en las nueve; `dynamic,1024` ganó a `static` en
ocho de nueve (hasta 25 %; en la otra empataron dentro del ruido); la versión con `atomic` por elemento quedó
entre 0 y 30 % por debajo de `dynamic,1024` + `reduction`, cerca **en este problema** porque cada iteración
trabaja ~250 ns y los 1000 bins reparten la contención. Un 4.1 con 4 hilos no es superlinealidad: el
secuencial de esa corrida salió lento (idea 4: se explica, no se celebra). La respuesta de diseño sigue siendo
acumular en privado: no depende de que el trabajo por iteración sea grande; y la diferencia se decide
midiendo, no opinando.
</details>

---

## Hoja de calibración (tres momentos; se entrega aparte del examen, no afecta la calificación)

| Casilla | Cuándo | Qué escribes |
|---|---|---|
| 1 · Predicción | En casa, **antes** de empezar el cronómetro | Puntos que esperas obtener (0–60): ____ · Calificación que esperas en el Examen 2 (0–100): ____ (la misma que escribiste en la tarea de S12) |
| 2 · Postdicción | En casa, al terminar los 40 min, **antes** de abrir la clave | Puntos que crees haber obtenido (0–60): ____ · Sección en la que te sentiste menos seguro: ____ |
| 3 · Real | En clase, jueves 29, tras la corrección entre pares | Puntos reales (0–60): ____ · Brecha = postdicción − real: ____ · Equivalente sobre 100: real/0.6 = ____ · Calificación que ahora esperas en el Examen 2 (0–100): ____ |

Brecha positiva de más de 9 puntos (15 % de los 60): sobreestimaste. Es el dato que más predice tropiezos en el
examen real (`01-marco-pedagogico.md`, P9); tu plan de estudio del *exit ticket* debe empezar por la sección
de la casilla 2.

## Guía de corrección entre pares (jueves 29, minutos 8–50)

Intercambia tu hoja con tu pareja de PRIMM. Corrige con la clave de cada ítem; anota puntos por inciso en
el margen y firma. Ante una duda, aplica estas reglas y marca el ítem con "?" para la discusión:

| Sección | Puntos | Bien (puntos completos) | Parcial | Mal (0) |
|---|---|---|---|---|
| I (×5) | 3 c/u | La letra de la clave | — (no hay parcial) | Otra letra o dos letras |
| II.1 | 5 | a) 3: las 8 cifras · b) 1 · c) 1 | a) 2 si el patrón por hilo es correcto con un error aritmético; 1 si solo `base=10` | `out=10 11 13 16…` en a) |
| II.2 | 5 | a) 3: exacto · b) 1: "una vez, cualquier hilo" · c) 1: "no predecible" | a) 1 si escribe el reparto de `static` sin *chunk* (`0 0 0 1 1 1 …`) | "hilo 0" en b); un arreglo concreto en c) |
| III.1 | 6 | a) 2 · b) 2 (`reduction`) · c) 1 · d) 1 | b) 1 con `atomic`, 0.5 con `critical` · c) 0.5 si "ponerla `private`" | b) `private(dot)`; d) "está mal" |
| III.2 | 6 | a) 2 · b) 2 (dos razones) · c) 2 (dos fases) | b) 1 (una razón) · c) 1 ("dejarlo secuencial" con Amdahl) | "falta `reduction`" |
| IV | 8 | 2 por hueco (`shared(left)`, `shared(right)`, `taskwait`, `parallel`+`single`) | (4b) `master`: 1 · (1)/(2) `firstprivate`: 0 | `taskwait` ausente o `barrier` en (3): 0 en (3) |
| V | 9 | a) 2 · b) 2 · c) 2 · d) 3 | c) 1 si `E = 2.11` · d) 2 con una causa, 1 solo `f` | a) con líneas de código: 0 en a) |
| VI | 6 | a) 2 · b) 2 · c) 2 | según la clave | `critical` por elemento; `static` "porque es más rápido" |

Al terminar, el profesor pide manos por ítem ("¿quién tuvo III.2 completo?") y los tres con menos manos se
discuten en el bloque 50–80.

## Qué hacer con tu resultado (mapa ítem → dónde repasar)

| Si fallaste… | Repasa | Rehaz |
|---|---|---|
| I.1, III.1 | S07 `notas-estudiante.md` §1–3; `practica-guiada/` de S13, cazador 1 | S07 *exit ticket* 2; `make cazar` |
| I.2 | S07 §3 (tabla de mecanismos); Pausa 5 del ejemplo de S07 | S07 tarea 1 |
| II.1, III.1-c | S07 §5 (`private`/`firstprivate`/adentro); cazador 3 | S07 CT3; Pausa 1 del ejemplo de S13 |
| I.3, II.2 | S08 §2–3 (`schedule`, costo del *chunk*); cazador 2 | `schedule_map` de S08 con 16 iteraciones |
| I.4, IV | S09 §1–3 (tareas, `taskwait`, entorno de datos) | `fib_buggy.c` y `taskwait_buggy.c` de S09 |
| III.2 | S11 §1.2 (*scan*), §3 error 4 | `scan_buggy.c` de S11 con TSan |
| I.5, V | S10 `notas-estudiante.md` (Amdahl medido, Karp–Flatt, fuerte/débil); protocolo §3 | S10 *exit ticket*; S12 *exit ticket* 2 |
| VI | S08 §1–2, S11 §1.1, S12 ejemplo resuelto (medir → dependencias → pragma) | S12 tarea 1b |
