> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S09 · martes 20 de octubre de 2026 · 08:30–10:00 · Lab LS4

# Práctica guiada S09 · Mergesort con tareas: cuántas se crean, quién las ejecuta y con qué corte

Actividad PRIMM corta, en parejas (conductor/navegante; cambio de rol al minuto 11). Dura **20 minutos** en
clase (fases 1–4); la fase 5 (Crear) es el ejercicio 1 de `../tarea-espaciada.md`. Es autocontenida: solo
necesitas `gcc` con OpenMP y `make`. El código que vas a leer es el mismo patrón que pide la Parte B de la
Práctica 4; léelo aquí completo antes de completarlo allá.

## Qué hay en esta carpeta

| Archivo | Qué es | Error a propósito |
|---|---|---|
| `mergesort_tasks.c` | Ordenamiento por mezcla: secuencial (referencia) y con tareas + corte; contador atómico de tareas; traza con n ≤ 32; mediana de 5 repeticiones | No |
| `fib_tasks.c` | Fibonacci recursivo con tareas y corte (código del ejemplo resuelto; didáctico, mal ejemplo de rendimiento) | No |
| `fib_buggy.c` | Fibonacci **sin** `shared(x)`: las hijas escriben en copias `firstprivate` y el resultado es 0 | **Sí** (sin carrera) |
| `taskwait_buggy.c` | Lee el resultado de dos tareas **sin** `taskwait`: carrera de datos | **Sí** |
| `list_tasks.c` | Una tarea por nodo de una lista enlazada: el patrón `parallel` + `single` + `task` | No |
| `taskloop_demo.c` | `taskloop` frente a `parallel for schedule(dynamic)`: mapa de iteraciones (n ≤ 64) y tiempo (n > 64) | No |
| `tree_sum_tasks.c` | Fase Crear: suma de un árbol no balanceado con tareas; compila y corre tal cual (`TODO pendiente`) | No |
| `Makefile` | `all`, `run`, `test`, `clean`, `cutoffs` (barrido del corte), `tsan` (ThreadSanitizer sobre `taskwait_buggy`) | — |
| `tests/run_tests.sh` | 34 comprobaciones: compilación sin *warnings*, número de tareas, igualdad con la secuencial, síntomas de los `_buggy` | — |

Todos aceptan el tamaño por línea de comandos: `./mergesort_tasks [n] [cutoff]` (por defecto 2 000 000 y
4 096), `./fib_tasks [n] [cutoff]`, `./list_tasks [n_nodos]`, `./taskloop_demo [n] [grainsize]`,
`./tree_sum_tasks [n_nodos] [cutoff_profundidad]`. Hilos con `OMP_NUM_THREADS`; repeticiones cronometradas con
`REPS` (5 por defecto, siempre con un calentamiento que no cuenta). La entrada se genera con semilla fija: dos
corridas con el mismo `n` ordenan exactamente los mismos números.

Antes de medir: `uptime`. Si la carga es mayor que 1 (la pareja de al lado corre `cutoff = 1`), tus tiempos no
sirven (idea errónea 5).

## Fase 1 · Predecir (4 min, por escrito, sin compilar)

Lee `merge_sort_tasks` (líneas 79–103) y el bloque de medición con tareas de `main` (líneas 186–200). Responde
en la hoja de la pareja:

| # | Pregunta | Tu predicción |
|---|---|---|
| P1 | `./mergesort_tasks 8 2` con 4 hilos: ¿cuántas líneas `tarea [lo,hi)` se imprimen (tareas creadas)? Dibuja el árbol de llamadas: `[0,8)` arriba, cada nodo parte en dos, y marca cuáles crean tareas. | |
| P2 | ¿Qué hilo ejecuta la primera tarea que se imprime? ¿Será el mismo en dos corridas? ¿Saldrán las líneas en el mismo orden? | |
| P3 | Con `OMP_NUM_THREADS=1 ./mergesort_tasks 8 2`, ¿cuántas tareas se crean: 0, 1 o 6? | |
| P4 | Con n = 2 000 000 y corte 4 096, ¿cuántas tareas? (potencias de dos: 2·(n/cutoff − 1); n/4 096 ≈ 512). Pre-mortem: ¿qué *speedup* esperas con 4 hilos y por qué? | |
| P5 | Ordena de más rápido a más lento con n = 2 000 000 y 4 hilos: `cutoff` = 1, 256, 4 096, 2 000 000. ¿Alguno será **más lento** que la versión secuencial? | |

No corrijas tus predicciones después. El valor está en comparar.

## Fase 2 · Ejecutar (3 min)

```bash
make                                   # gcc -std=c11 -O2 -Wall -Wextra -fopenmp, sin warnings
export OMP_NUM_THREADS=4
./mergesort_tasks 8 2                  # traza: una línea por tarea
./mergesort_tasks 8 2                  # otra vez: ¿qué cambió?
./mergesort_tasks                      # n = 2 000 000, cutoff = 4 096, mediana de 5
```

Dos corridas reales consecutivas de `./mergesort_tasks 8 2` en la máquina de autoría (4 núcleos, gcc 13):

```
entrada: 342300 277626 112642 651922 267761 886793 319643 199767
  tarea [ 0, 4)  n= 4  ejecutada por el hilo 0
  tarea [ 2, 4)  n= 2  ejecutada por el hilo 0
  tarea [ 0, 2)  n= 2  ejecutada por el hilo 0
  tarea [ 4, 8)  n= 4  ejecutada por el hilo 3
  tarea [ 4, 6)  n= 2  ejecutada por el hilo 0
  tarea [ 6, 8)  n= 2  ejecutada por el hilo 0
salida:  112642 199767 267761 277626 319643 342300 651922 886793
tareas creadas = 6   ejecutadas por hilo: 5 0 0 1
verificacion: OK

entrada: 342300 277626 112642 651922 267761 886793 319643 199767
  tarea [ 4, 8)  n= 4  ejecutada por el hilo 2
  tarea [ 6, 8)  n= 2  ejecutada por el hilo 2
  tarea [ 4, 6)  n= 2  ejecutada por el hilo 2
  tarea [ 0, 4)  n= 4  ejecutada por el hilo 2
  tarea [ 2, 4)  n= 2  ejecutada por el hilo 2
  tarea [ 0, 2)  n= 2  ejecutada por el hilo 2
salida:  112642 199767 267761 277626 319643 342300 651922 886793
tareas creadas = 6   ejecutadas por hilo: 0 0 6 0
verificacion: OK
```

Siempre 6 tareas (P1) y siempre la misma salida ordenada; cambian **qué hilo** ejecuta cada tarea y **en qué
orden** se imprimen (P2): el reparto de tareas es dinámico, como `schedule(dynamic)` en S08. En la segunda
corrida un solo hilo hizo las 6: dos elementos se ordenan más rápido de lo que tardan los otros hilos en
despertar. Con `OMP_NUM_THREADS=1` también salen 6 tareas (P3): las crea la recursión, no los hilos.

Corrida real por defecto (`./mergesort_tasks`, 4 hilos):

```
n=2000000 cutoff=4096 hilos=4 reps=5 (mediana tras 1 calentamiento)
secuencial : mediana 0.1862 s  (min 0.1825  max 0.1934)
tareas     : mediana 0.0887 s  (min 0.0882  max 0.0960)  speedup 2.10  eficiencia 0.52
tareas creadas = 1022   ejecutadas por hilo: 129 321 382 190
verificacion: OK
resumen: n=2000000 cutoff=4096 hilos=4 t_seq=0.1862 t_tareas=0.0887 speedup=2.10 tareas=1022
```

Una segunda corrida dio `speedup=1.93` con reparto `382 129 256 255`. 1 022 tareas = 2·(512 − 1): n no es
potencia de dos exacta, pero 2 000 000 / 4 096 ≈ 488 cae en el mismo nivel de la recursión que 512 (P4).
Anota tu línea `resumen:`: la vas a usar en el punto de control, en el *exit ticket* y en la tarea.

## Fase 3 · Investigar (6 min)

### 3.1 El contador atómico (`task_begin`, líneas 28–37)

`task_begin` se llama al **inicio del cuerpo** de cada tarea, así que la ejecuta el hilo que **tomó** la tarea,
no el que la creó; por eso `omp_get_thread_num()` dice quién la ejecutó. Tres preguntas:

1. `task_count++` lleva `#pragma omp atomic`. ¿Qué pasaría sin él con 4 millones de tareas (`cutoff = 1`)?
   ¿Por qué `atomic` y no `critical`? (S07: una actualización simple de una variable escalar.)
2. `tasks_by_thread[tid]++` también lleva `atomic`. ¿Hace falta? ¿Quién más escribe la casilla `tid`?
   (Respuesta: nadie; cada hilo escribe solo su casilla. El `atomic` sobra para la correctitud. Que las cuatro
   casillas sean vecinas en memoria tiene otro costo que se llama falso compartido: S10, jueves 22 de octubre.)
3. Si moviéramos `task_begin` **antes** del `#pragma omp task` (fuera del cuerpo), ¿qué hilo reportaría?
   ¿Seguiría contando tareas o contaría otra cosa?

### 3.2 Árbol de llamadas: de dónde salen las 6 tareas

Completa para n = 8, cutoff = 2 (una llamada crea tareas solo si `n > cutoff`):

| Nivel | Llamadas | Tamaño | ¿Crea 2 tareas? | Tareas creadas en este nivel |
|---|---|---|---|---|
| 0 | `[0,8)` | 8 | sí (8 > 2) | 2 → `[0,4)`, `[4,8)` |
| 1 | `[0,4)`, `[4,8)` | 4 | sí (4 > 2) | 4 |
| 2 | `[0,2)`, `[2,4)`, `[4,6)`, `[6,8)` | 2 | **no** (2 ≤ 2): inserción, sin tareas | 0 |
| | | | **Total** | **6** |

Con potencias de dos: 2·(n/cutoff − 1). Comprueba con la traza: `./mergesort_tasks 8 1` da 14 y
`./mergesort_tasks 1024 1 | grep creadas` da 2 046 = 2n − 2 (cada elemento acaba en su propia tarea). ¿Y
`./mergesort_tasks 8 8`? ¿Quién ordena entonces?

### 3.3 Las cláusulas que no están (líneas 86–100)

Las dos tareas no llevan `shared(...)` ni `private(...)`. Regla de `task`: una variable que no es compartida
donde se crea la tarea entra como **`firstprivate`** (copia con el valor de ese momento). Aquí `a`, `tmp`, `lo`,
`mid`, `hi` y `cutoff` son parámetros de la función: privados del hilo, luego copias en la tarea.

1. ¿Por qué funciona sin `shared(a)`? Pista: `a` es un **puntero**. ¿Qué se copia, el puntero o el arreglo?
   ¿Cuántos arreglos hay?
2. ¿Por qué no hay carrera aunque las dos hijas escriban en el mismo arreglo? ¿Qué tramos escribe cada una?
3. Compara con `fib_tasks.c`, línea 43: ahí **sí** hace falta `shared(x)`. ¿Qué diferencia hay entre `x` en
   Fibonacci y `a` en mergesort? (Quién escribe y quién lee después.) Corre `./fib_buggy`: `0 esperado 832040`.

### 3.4 El `taskwait` (línea 101) y la barrera (líneas 193–194)

1. `taskwait` espera a las **hijas directas**. Las nietas (las tareas que crearon las hijas), ¿ya terminaron
   cuando `merge` arranca? Argumenta con el `taskwait` que tiene **cada** hija antes de regresar.
2. ¿Por qué la recursión arranca dentro de `#pragma omp single` (línea 194)? ¿Qué pasaría con `parallel`
   solo: cuántas recursiones sobre el mismo arreglo?
3. El cronómetro se detiene después de la región (línea 197). ¿Qué garantiza que para entonces **todas** las
   tareas terminaron, incluso sin `taskwait` en la raíz? (Barrera implícita del `single` y de `parallel`.)

## Fase 4 · Modificar (7 min; cada cambio se verifica con `make test`)

**M1 · Barrido del corte (obligatorio).** `make cutoffs` corre n = 2 000 000 con `cutoff` = 1, 16, 256, 4 096,
65 536 y n, con `REPS=3` (unos 20–30 s; `cutoff = 1` tarda varios segundos por repetición: no lo mates).
Llena la tabla con tus líneas `resumen:` y escribe **dos líneas**: dónde está el mínimo y por qué `cutoff = 1`
y `cutoff = n` pierden por razones distintas.

Barrido real en la máquina de autoría (`REPS=5`, 4 núcleos de una máquina virtual **compartida con otros
procesos**: los tiempos absolutos cambian entre corridas, el orden no; una corrida anterior del mismo barrido
dio 1.50 en 256 y 1.13 en 4 096):

| `cutoff` | Tareas creadas | t_seq (s) | t_tareas (s) | *Speedup* | Lectura |
|---|---|---|---|---|---|
| 1 | 3 999 998 | 0.1980 | **3.7123** | 0.05 | 19 veces más lento que la secuencial: 4 millones de tareas de 1–2 elementos |
| 16 | 262 142 | 0.1889 | 0.3361 | 0.56 | todavía más lento que la secuencial |
| 256 | 16 382 | 0.2321 | 0.1042 | 2.23 | zona útil: miles de tareas, cada una de cientos de elementos |
| 4 096 | 1 022 | 0.1961 | 0.0935 | 2.10 | zona útil |
| 65 536 | 62 | 0.1877 | 0.0990 | 1.90 | 62 tareas para 4 hilos: aún hay con qué balancear |
| 500 000 | 6 | 0.2051 | 0.0936 | 2.19 | 4 hojas iguales: aquí basta porque el trabajo es uniforme; con cargas irregulares no |
| 2 000 000 | 0 | 0.1938 | 0.2079 | 0.93 | sin tareas: un hilo hace todo y los otros tres esperan |

Entre 256 y 500 000 la diferencia (1.9–2.2) es menor que el ruido de la máquina; lo robusto es la meseta y
sus dos bordes: por abajo, la sobrecarga por tarea; por arriba, quedarse sin tareas que repartir.

| `cutoff` | Tareas | t_seq | t_tareas | *Speedup* |
|---|---|---|---|---|
| 1 | | | | |
| 16 | | | | |
| 256 | | | | |
| 4 096 | | | | |
| 65 536 | | | | |
| 2 000 000 | | | | |

**M2 · Hilos.** Con el mejor corte de tu tabla, corre con `OMP_NUM_THREADS=1`, `2` y `4`. En la máquina de
autoría, corte 4 096: 1 hilo → `t_tareas=0.2207` (*speedup* 0.88: el único hilo crea y ejecuta las 1 022 tareas
él solo y paga la sobrecarga sin ganar nada); 2 hilos → 1.85 (eficiencia 0.92); 4 hilos → 2.10 (eficiencia
0.52). Pregunta: ¿por qué la eficiencia cae tanto de 2 a 4 hilos si el número de tareas es el mismo? Dos
pistas: la mezcla del nivel superior la hace **un** hilo, y mezclar es copiar memoria (tarea, ejercicio 2).

**M3 · Quita el `taskwait`** (línea 101), compila y corre `./mergesort_tasks 8 2` y `./mergesort_tasks 1000000
4096`. Resultado real: `salida: 267761 277626 112642 342300 …` (desordenada), `verificacion: FALLA` en las tres
corridas, y un "*speedup*" de 2.5 a 6.1, porque `merge` mezcla tramos que nadie ordenó todavía mientras las
hijas siguen trabajando. Un programa rápido y equivocado no tiene *speedup* (protocolo, §1.2). `make test`
falla. Vuelve a poner la línea y confirma `34 PASS`.

**M4 (si alcanza) · `taskloop`.** `./taskloop_demo 16 4` tres veces: el mapa de qué hilo ejecutó cada
iteración cambia entre corridas y se parece a `schedule(dynamic,4)`. Mapa real:

```
n=16 hilos=4
taskloop grainsize(4)     | 1 1 1 1 3 3 3 3 2 2 2 2 0 0 0 0
for schedule(dynamic,4)   | 0 0 0 0 1 1 1 1 2 2 2 2 3 3 3 3
```

Después `./taskloop_demo 40000 64`: en la máquina de autoría `for schedule(dynamic,64)` dio *speedup* 1.57 y
`taskloop grainsize(64)` 0.88 (una corrida, máquina compartida). `taskloop` no es para ganarle a `parallel
for`: es para partir un ciclo en tareas cuando ya estás dentro de una tarea o de un `single` y no quieres
abrir otra región paralela; en libgomp la `reduction` sobre tareas cuesta más que la de `for`.

## Fase 5 · Crear (transferencia; hoy pasa íntegra a la tarea espaciada)

`tree_sum_tasks.c`: cada nodo de un árbol binario **no balanceado** de 10⁶ nodos pesa lo que tarda su
secuencia de Collatz; hay que sumar los pesos. No hay índices (un `parallel for` no sirve) y el trabajo por
rama es irregular. Completa:

- `TODO(1)`: la recursión con dos tareas por nodo (una por subárbol), `shared` donde la hija escribe y el padre
  lee, `taskwait`, y el **corte por profundidad**: a partir de `depth >= cutoff_depth`, secuencial.
- `TODO(2)`: la región `parallel` + `single` que arranca la recursión.
- `TODO(3)` (opcional): contador atómico de tareas como `task_begin`; compara con la cota 2·(2^cutoff − 1).

Criterio de "listo": compila sin *warnings*; `./tree_sum_tasks` imprime `verificacion: OK` con n = 10⁶; el
*speedup* con 4 hilos es > 1 para algún corte (prueba 4, 8 y 12); `make test` termina en `0 FAIL` (el script
detecta solo si el `TODO` sigue pendiente o si ya está resuelto, y en el segundo caso exige el resultado
correcto). Referencia de autoría con la solución: corte 8 → 502 tareas, *speedup* 1.65; corte 24 → 759 456
tareas, 0.30.

## Verificación automática

```bash
make test
```

Salida real (recortada; 34 comprobaciones en ≈ 3 s):

```
PASS  compila sin warnings: mergesort_tasks.c
PASS  compila sin warnings: fib_tasks.c
...
PASS  mergesort n=8  cutoff=2  -> 6 tareas
PASS  mergesort n=8  cutoff=1  -> 14 tareas
PASS  mergesort n=1024 cutoff=1 -> 2046 tareas (2n-2)
PASS  mergesort n=8 cutoff=2 con 1 hilo -> también 6 tareas (las crea el único hilo)
PASS  traza n=8 cutoff=2: 6 líneas de tarea y verificacion OK
PASS  mergesort 100003 1: ordenado e igual a la secuencial
PASS  mergesort 65536 70000: ordenado e igual a la secuencial
...
PASS  fib_tasks 25 10 -> 5166 tareas = 2*(fib(18)-1)
PASS  fib_buggy 25 10: devuelve 0 e informa INCORRECTO
PASS  taskwait_buggy 200000: tras la barrera 900000 correcto
PASS  list_tasks 8: nodos 0..7 una vez cada uno, verificacion OK
PASS  taskloop_demo 16 4: 16 iteraciones asignadas a hilos 0..3
PASS  tree_sum_tasks 100000: base compila y la suma secuencial es 10753712 (TODO pendiente: fase Crear)

Resumen: 34 PASS, 0 FAIL
```

Las comparaciones son exactas (enteros y arreglos ordenados); solo `taskloop_demo` suma en `double` y usa
tolerancia relativa `1e-9` (idea errónea 10). Las pruebas comprueban el **número de tareas**, que lo fija la
recursión, nunca qué hilo ejecutó cuál (eso cambia en cada corrida). De `taskwait_buggy` solo se exige la
lectura posterior a la barrera: la prematura es una carrera y "a veces" podría salir bien.

## ThreadSanitizer sobre la carrera a propósito

```bash
make tsan        # compila taskwait_buggy.c con -fsanitize=thread -g -O1 y lo corre con n = 2 000 000
```

En la máquina de autoría salen 11 reportes. Los que importan son dos, uno por variable (recortado):

```
WARNING: ThreadSanitizer: data race
  Write of size 8 ... by thread T3:
    #0 main._omp_fn.1 taskwait_buggy.c:21        <- la escritura de `left` (el return de sum_range, inlineado en la tarea)
  Previous read of size 8 ... by thread T1:
    #0 main._omp_fn.0 taskwait_buggy.c:46        <- premature = left + right, leído antes de tiempo
  Location is stack of main thread.
```

Los otros nueve señalan las líneas 41–44 contra `memcpy` dentro de `GOMP_task` (la biblioteca copiando el
entorno de datos de la tarea) o la línea 38 contra la 46 (una lectura después de la región, ordenada por la
barrera de `parallel`): son ruido de `libgomp`, que ThreadSanitizer no ve, con el mismo criterio de S07. Un
reporte es carrera real si la línea señalada toca memoria compartida sin `atomic`/`critical`/candado y sin
`taskwait` ni barrera entre la escritura y la lectura.

## Problemas de entorno frecuentes

| Síntoma | Causa | Qué hacer |
|---|---|---|
| `make cutoffs` "se queda colgado" en la primera línea | `cutoff = 1` crea 4 millones de tareas: 3–4 s por repetición | Espera; o `make cutoffs REPS=1` |
| `./fib_tasks 36 2` imprime `aviso: … se usa cutoff=8` | Guarda del programa: con n − cutoff > 28 serían decenas de millones de tareas (26 s con 48 millones en la máquina de autoría) | Es intencional; el corte real está en la salida |
| Todos los tiempos iguales con 1, 2 y 4 hilos | `OMP_NUM_THREADS` sin exportar | `OMP_NUM_THREADS=4 ./programa` en la misma línea |
| `speedup 0.00` con n = 8 | La secuencial tarda menos que la resolución del reloj | Es una traza, no una medición; mide con n ≥ 10⁶ |
| `ejecutadas por hilo: 6 0 0 0` | Las tareas son tan cortas que un hilo las acaba antes de que los demás despierten | Normal con n = 8; mira el reparto con n = 2 000 000 |
| `make tsan` reporta carreras en líneas con `#pragma omp task` | Falsos positivos de `libgomp` | Lee solo los reportes cuyas dos líneas tocan tus variables (21 y 46) |
| `tree_sum_tasks` imprime `TODO pendiente` | Es la fase Crear sin resolver | Completa `TODO(1)` y `TODO(2)` |

## Uso de IA en esta práctica

Verde: pedirle que te explique la regla de `firstprivate` implícito o un reporte de ThreadSanitizer.
Amarillo: pedirle que revise tu `tree_sum_tasks.c` y señale dónde una tarea escribe en una copia; tú verificas
con `make test` y lo declaras. Rojo: pegar el enunciado de la fase 5 (o la Parte B de la Práctica 4) y entregar
lo que salga sin poder explicar cada línea en la mini-defensa.
