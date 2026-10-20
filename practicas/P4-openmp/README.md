> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Práctica 4 · Procesamiento paralelo de datos con OpenMP · publicada jueves 15 de octubre de 2026 · Lab 1 martes 20 de octubre 08:30 · Lab 2 martes 27 de octubre 08:30 · Lab LS4 (Edificio 3) · entrega domingo 1 de noviembre de 2026, 23:59

# Práctica 4 · Procesamiento paralelo de datos con OpenMP

| | |
|---|---|
| Unidad | III · Programación en memoria compartida (OpenMP) |
| Publicación | jueves 15 de octubre de 2026, 10:30 (S07, Salón 3208) |
| Pre-laboratorio | individual, en el repositorio del equipo **antes del martes 20 de octubre, 08:30** |
| Laboratorio 1 | martes 20 de octubre, 08:30–10:00, Lab LS4 (S09): Partes A y B |
| Laboratorio 2 | martes 27 de octubre, 08:30–10:00, Lab LS4 (S12): Partes C y D, punto de control, mini-defensas |
| **Fecha límite** | **domingo 1 de noviembre de 2026, 23:59** (etiqueta `P4-entrega`) |
| Ponderación | **40 % del 2.º parcial** (`planeacion/mapa-evaluacion.md`) |
| Equipos | 2–3 integrantes (los de P1–P3 y del proyecto), con responsabilidad individual (mini-defensas y prueba de propiedad) |
| Entregables | `practicas/P4/` en el repositorio del equipo: código, `Makefile`, `tests/`, `resultados/` (CSV + PNG), `REPORTE.md` ≤ 3 páginas con reparto de trabajo, bitácora de errores y declaración de IA (detalle en `entrega.md`) |
| Tiempo estimado | 6–8 horas por integrante (dos laboratorios + trabajo en casa) |

Documentos de esta carpeta: este enunciado · `entrega.md` (qué, cómo, cuándo) · `rubrica.md` (100 puntos) ·
`src/` (código base) · `tests/run_tests.sh` · `Makefile` · `medir.sh` y `graficar.py` (Parte D) ·
`resultados/README.md`.

## Objetivos (al terminar, podrás…)

1. **Comparar** cinco formas correctas de acumular en un arreglo compartido (`critical`, `atomic`, acumulador
   local, `reduction` sobre arreglo y tareas con reducción en árbol), **midiendo** ns por elemento y *speedup* con
   1, 2 y 4 hilos, y **explicar** el orden con el cociente entre trabajo por elemento y costo de sincronizar
   (analizar).
2. **Predecir** cuántas tareas crea una recursión con corte, quién las ejecuta y qué garantiza `taskwait`, y
   **completar** un ordenamiento estable con tareas verificado registro por registro contra `qsort` (aplicar).
3. **Diseñar** la paralelización por filas del conjunto de Mandelbrot (o de la ecuación de calor 1D con
   convergencia) bajo restricciones, y **justificar** la política de `schedule` con el desbalance medido y la
   tabla de tiempos (evaluar/crear).
4. **Medir** con el protocolo del curso (1, 2, 4 y 8 hilos; 8 declarado como sobre-suscripción si tu máquina tiene
   menos núcleos), **producir** el CSV y las gráficas, e **interpretar** dónde deja de escalar con Amdahl y
   Karp–Flatt, comparando con tus predicciones (analizar/evaluar).

## Pre-laboratorio (individual, 20 min; se entrega antes del Laboratorio 1)

Un archivo `practicas/P4/prelab/prelab-<tu alias>.md` en el repositorio del equipo, **antes del martes 20 de
octubre a las 08:30**, faltes o no a la sesión. La pregunta 1 de la recuperación de ese día lo verifica (te pide
copiar tu predicción). Sin IA: son preguntas del tipo del Examen 2.

**Lectura previa (10 min).** `unidades/U3-memoria-compartida/S07_2026-10-15_sincronizacion/notas-estudiante.md`
§1 y §3 (la carrera y las cinco formas de corregirla, con su costo) y
`unidades/U3-memoria-compartida/S08_2026-10-19_planificacion/notas-estudiante.md` §1, §2 y §5 (repartir no es
balancear; las políticas de `schedule`). La lectura sobre tareas la pidió la tarea de S08 (ejercicio 3).

**Cuatro preguntas (una o dos líneas cada una).**

1. Cuatro hilos ejecutan `hist[b]++` sobre un arreglo compartido, sin protección, para n valores. Al final, la
   suma de todos los conteos, ¿puede ser mayor que n, menor que n o igual a n? ¿Por qué nunca lo otro?
2. Para proteger `hist[b]++`, ¿`atomic` o `critical`, y por qué? ¿Y para que `hist[b]++` y `total++` ocurran juntas
   como una sola operación?
3. Un ciclo de 1 200 filas de Mandelbrot en el que las filas del centro cuestan cientos de veces más que las de los
   bordes, con 4 hilos: ¿qué le pasa a `schedule(static)` y qué política probarías primero? ¿Qué cuesta esa política?
4. Un programa tarda 10 s en secuencial y 1 s de ese tiempo no se puede paralelizar. ¿Cuál es el *speedup* máximo
   con 4 hilos? ¿Y la eficiencia?

**Predicción (se copia tal cual en el reporte y se compara en la Parte A).** "Con 4 hilos espero un *speedup* de
___ en la Parte A (versión `reduction`, n = 10⁷) porque ___. La versión más lenta será ___ porque ___." Dato para
razonar: en esta práctica cada muestra cuesta ≈ 20–25 ns de cálculo (una transformación con `log`, `sqrt` y `cos`)
más una actualización del histograma; en el histograma de S07 el trabajo era ≈ 1.5 ns por elemento.

<details><summary>Respuestas de las cuatro preguntas (ábrelas después de entregar)</summary>

1. **Menor o igual, nunca mayor.** `hist[b]++` es leer, sumar 1 y escribir; si dos hilos leen el mismo valor antes
   de que alguno escriba, los dos escriben "valor + 1" y se pierde una cuenta. Cada escritura es "lo que leí + 1":
   un entrelazado puede perder cuentas, nunca inventarlas. Que salga igual a n en una corrida no prueba nada (idea
   errónea 7).
2. **`atomic`**: una sola actualización de una variable escalar se hace con una instrucción atómica del procesador,
   más barata que entrar y salir de una región crítica. Para dos variables que deben cambiar juntas, **`critical`** (o
   un candado): `atomic` cubre exactamente una operación (idea errónea 8).
3. Con `static` cada hilo recibe 300 filas contiguas: los dos hilos de las filas centrales trabajan mucho más y los
   otros esperan en la barrera implícita del `for`. Probaría **`dynamic` con *chunk* pequeño** (1–4 filas) o
   `static,1` (cíclico). `dynamic` cuesta un pedido atómico por *chunk*: despreciable frente a una fila de cientos
   de miles de iteraciones (idea errónea 11, al revés: aquí sí conviene).
4. Fracción secuencial 0.1: S = 1 / (0.1 + 0.9/4) ≈ **3.08**; eficiencia 3.08 / 4 ≈ **0.77**. Con infinitos hilos,
   S ≤ 10 (ideas erróneas 1 y 2: la fracción se mide en tiempo).
</details>

## Qué hay en `src/` y cómo se compila

| Archivo | Parte | Qué es | Qué haces tú |
|---|---|---|---|
| `common.h` | todas | Repeticiones (`REPS`), mediana, generador con semilla fija, líneas `tiempo_s=`/`tiempos_s=`, marcas de `TODO pendiente` | Leerlo |
| `a_hist.h` | A | Datos (semilla 20261015), trabajo por muestra (Box–Muller), histograma secuencial, arnés de medición | Leerlo |
| `a_histogram.c` | A | Cinco versiones correctas: `critical`, `atomic`, `local`, `reduction`, `tareas` | Leer, predecir, correr, modificar |
| `a_histogram_buggy.c` | A | La versión **con carrera**, a propósito, para observarla | Correr y diagnosticar |
| `b_mergesort.c` | B | Ordenamiento estable de registros con tareas y corte | Completar `TODO(1)`–`TODO(3)` |
| `c_mandel.h` | C | **Contrato** de Mandelbrot: región, píxel → complejo, iteración de escape, checksums, PGM | No se modifica |
| `c_mandelbrot.c` | C | Esqueleto: argumentos, medición, checksums, imagen | Diseñar `TODO(4)` y `TODO(5)` |
| `c_heat.h` | C (alt.) | **Contrato** de calor 1D: condición inicial, regla de un punto, checksums | No se modifica |
| `c_heat.c` | C (alt.) | Esqueleto: argumentos, medición, checksums | Diseñar `TODO(6)` y `TODO(7)` |

```bash
make              # compila todo en bin/ con gcc -std=c11 -O2 -Wall -Wextra -fopenmp (sin warnings)
make test-a       # pruebas de la Parte A: pasan desde el primer día (código completo)
make test         # todas: las de B y C FALLAN mientras haya TODO pendiente (es lo esperado)
make run          # demostración corta con los tamaños por defecto
make clean        # borra bin/ y tests/out/
```

Hilos con `OMP_NUM_THREADS` (o `make run THREADS=2`); repeticiones cronometradas con `REPS` (5 por defecto; cada
programa hace además 1 calentamiento que no se cuenta). Todos los programas aceptan el tamaño por línea de comandos
y su tamaño por defecto corre en menos de 5 s en 4 núcleos.

**Cómo funcionan los `TODO`.** Cada `TODO(n)` trae un código provisional que compila y llama a `p4_todo(n)`. Mientras
quede uno, el programa imprime `TODO pendiente: TODO(n) …`, termina con código distinto de 0 y las pruebas de su
parte marcan `FAIL`. En la Parte B cada prueba dice qué `TODO` comprueba y pasa en cuanto ese `TODO` está bien,
aunque falten otros; la prueba "B sin TODO pendiente" solo pasa con los tres. En la Parte C se prueba la opción
cuyo programa ya no imprime `TODO pendiente` (o la que fijes con `make test-c PARTE_C=calor`).

---

## Parte A · Guiada: un histograma, cinco mecanismos (Laboratorio 1, ≈ 15 min; se termina en casa)

**El problema.** Tienes n lecturas de un sensor con ruido. Cada lectura cruda son dos números uniformes en (0, 1]
que la transformación de Box–Muller convierte en una muestra normal, z = √(−2 ln u₁) · cos(2π u₂); el programa
cuenta cuántas muestras caen en cada uno de `nbins` intervalos de [−4.5, 4.5). Es el mismo patrón que el histograma
de S07 (`hist[b]++` sobre un arreglo compartido), con una diferencia que importa: aquí cada muestra **cuesta
≈ 20–25 ns de cálculo** antes de la actualización, no 1.5 ns. Compruébalo con `./bin/a_histogram ver 1000000 24`:
imprime la campana (después de `make`).

Las cinco versiones de `src/a_histogram.c` hacen lo mismo y difieren solo en cómo evitan la carrera:

| Versión | Líneas | Mecanismo |
|---|---|---|
| `critical` | 20–29 | `#pragma omp critical` alrededor de `hist[b]++` |
| `atomic` | 32–41 | `#pragma omp atomic` |
| `local` | 45–59 | un arreglo `local` por hilo, una combinación al final |
| `reduction` | 63–69 | `reduction(+:hist[:nbins])`: el patrón `local` hecho por OpenMP |
| `tareas` | 78–110 | **constructo nuevo de hoy**: el rango se parte en dos tareas hasta el corte; cada hoja cuenta en su arreglo; el padre espera (`taskwait`) y suma: una reducción en árbol. Es el esqueleto de la Parte B |

### A.1 · Predecir (4 min, por escrito, antes de correr)

Lee `hist_tasks_rec` y `hist_tasks` (líneas 78–110). Anota en el reporte, sección "Parte A":

| # | Pregunta | Tu predicción |
|---|---|---|
| P1 | Con 4 hilos y n = 10⁶, ordena de más rápida a más lenta: `critical`, `atomic`, `local`, `reduction`, `tareas`. ¿Cuáles serán más lentas que la secuencial? | |
| P2 | En la tabla de S07 (≈ 1.5–2 ns de trabajo por elemento) las tres versiones salieron más lentas que la secuencial, y al repetirlo `local` cambia mucho entre corridas. ¿Qué esperas aquí de `local`, con ≈ 20 ns por muestra? ¿Por qué podría cambiar? | |
| P3 | `./bin/a_histogram tareas 1000000 64 16384`: ¿cuántas tareas se crean? (cada llamada con más de 16 384 muestras crea dos; dibuja los dos primeros niveles del árbol) | |
| P4 | La misma corrida con `OMP_NUM_THREADS=1`: ¿cuántas tareas? | |
| P5 | `right` (línea 87) es una variable local del padre y la tarea de las líneas 96–97 la recibe sin cláusula `shared`. ¿La hija escribe en el arreglo que después suma el padre (línea 99) o en una copia? | |
| P6 | ¿Qué pasaría si quitaras el `taskwait` de la línea 98? (dos problemas) | |
| P7 | `a_histogram_buggy` con 4 hilos y n = 10⁶: ¿el total queda arriba, abajo o igual a n? ¿Igual en las 5 repeticiones? | |

### A.2 · Ejecutar (5 min)

```bash
make
OMP_NUM_THREADS=4 ./bin/a_histogram          # las cinco versiones, n = 10^6 (~2 s)
OMP_NUM_THREADS=4 ./bin/a_histogram_buggy    # la carrera, una línea por repetición
make speedup-a                               # versiones sin critical, n = 10^7, con 1, 2 y 4 hilos (~20 s)
```

Corrida real en la máquina de autoría (máquina virtual de 4 núcleos **compartida con otros procesos**: los tiempos
cambian entre corridas, el orden no; en otra corrida `local` dio *speedup* 3.30 con 4 hilos):

```
a_histogram: n=1000000 nbins=64 hilos=4 reps=5 modo=todos corte_tareas=16384
n=1000000
seq        mediana 0.0190 s (min 0.0189 max 0.0194)    19.0 ns/elemento  (referencia T(1))
critical   mediana 0.3558 s (min 0.3325 max 0.3957)   355.8 ns/elemento  speedup  0.05  eficiencia 0.01  correcto
atomic     mediana 0.0435 s (min 0.0384 max 0.0814)    43.5 ns/elemento  speedup  0.44  eficiencia 0.11  correcto
local      mediana 0.0092 s (min 0.0091 max 0.0095)     9.2 ns/elemento  speedup  2.06  eficiencia 0.52  correcto
reduction  mediana 0.0090 s (min 0.0088 max 0.0091)     9.0 ns/elemento  speedup  2.11  eficiencia 0.53  correcto
tareas     mediana 0.0096 s (min 0.0089 max 0.0118)     9.6 ns/elemento  speedup  1.97  eficiencia 0.49  correcto
tareas creadas = 126 (corte = 16384)
verificacion contra la secuencial: OK
```

Con 1 hilo, la misma corrida dio `critical` 28.8 ns/elemento y `atomic` 24.9 contra 26.0 de la secuencial: sin
competencia, proteger cuesta poco. Con 4 hilos, `critical` sube a 356 ns y `atomic` a 44. La línea `RESULT,...`
(que aquí se omite) es la que leen las pruebas.

`make speedup-a` (n = 10⁷, la medición que comparas con tu predicción del pre-lab), filas de 4 hilos:

```
seq        mediana 0.2189 s (min 0.1901 max 0.2730)    21.9 ns/elemento  (referencia T(1))
atomic     mediana 0.3998 s (min 0.3767 max 0.4339)    40.0 ns/elemento  speedup  0.55  eficiencia 0.14  correcto
local      mediana 0.0722 s (min 0.0639 max 0.0929)     7.2 ns/elemento  speedup  3.03  eficiencia 0.76  correcto
reduction  mediana 0.0698 s (min 0.0636 max 0.0963)     7.0 ns/elemento  speedup  3.14  eficiencia 0.78  correcto
tareas     mediana 0.0962 s (min 0.0698 max 0.1295)     9.6 ns/elemento  speedup  2.28  eficiencia 0.57  correcto
tareas creadas = 2046 (corte = 16384)
```

Y la carrera (`a_histogram_buggy`, 4 hilos, n = 10⁶, 64 intervalos), una corrida real:

```
  rep 1: 0.0370 s  total=933518 (esperado 1000000)  intervalos distintos=43  INCORRECTO
  rep 2: 0.0327 s  total=956455 (esperado 1000000)  intervalos distintos=42  INCORRECTO
  rep 3: 0.0349 s  total=975676 (esperado 1000000)  intervalos distintos=41  INCORRECTO
  rep 4: 0.0339 s  total=964944 (esperado 1000000)  intervalos distintos=43  INCORRECTO
  rep 5: 0.0354 s  total=945993 (esperado 1000000)  intervalos distintos=43  INCORRECTO
repeticiones incorrectas: 5 de 5
```

Ahora `./bin/a_histogram_buggy 2000 4096` tres veces: en la máquina de autoría salieron 3, 4 y 3 repeticiones
incorrectas de 5. Las demás "salieron bien". Llena tu tabla (ns/elemento):

| Versión | 1 hilo | 2 hilos | 4 hilos | ¿Correcta 5/5? |
|---|---|---|---|---|
| `seq` | | — | — | referencia |
| `critical` | | | | |
| `atomic` | | | | |
| `local` | | | | |
| `reduction` | | | | |
| `tareas` | | | | |

### A.3 · Investigar (5 min en el laboratorio; el resto en casa)

**3.1 Árbol de tareas.** Completa para n = 1 000 000 y corte 16 384 y compara con la línea `tareas creadas`:

| Nivel | Tamaño de cada llamada | Llamadas en el nivel | ¿Crea 2 tareas? | Tareas creadas en el nivel |
|---|---|---|---|---|
| 0 | 1 000 000 | 1 | sí | 2 |
| 1 | 500 000 | 2 | sí | 4 |
| 2 | | | | |
| … | | | | |
| | | | **Total** | |

**3.2 Preguntas sobre líneas concretas** (`src/a_histogram.c`):

1. Con 1 hilo, `critical` cuesta casi lo mismo que la secuencial; con 4 hilos, más de 10 veces más. ¿Qué cambió si
   el código es el mismo?
2. `atomic` es correcta y más barata que `critical`, y aun así con 4 hilos es más lenta que la secuencial. ¿Qué
   comparten los hilos en cada actualización? Pista: ¿qué intervalos reciben más cuentas en una campana?
3. Líneas 87 y 96–97: la hija recibe una **copia del puntero** `right` (`firstprivate` implícito). ¿Por qué aquí no
   hace falta `shared(right)` y en `fib_buggy.c` de S09 sí hacía falta `shared(x)`?
4. Líneas 89–90: `hist_task_count += 2` lleva `atomic`. ¿Qué hilos ejecutan esa línea? (no solo el del `single`).
5. Líneas 106–107: ¿por qué la recursión arranca dentro de `single`? ¿Qué harían 4 hilos que la arrancaran cada uno?

**3.3 ThreadSanitizer** (S07): `make tsan` compila con `-fsanitize=thread -g -O1` y corre con n = 20 000. Reporte
real (recortado):

```
WARNING: ThreadSanitizer: data race
  Read of size 8 at 0x7220000000b0 by thread T1:
    #0 hist_buggy._omp_fn.0 src/a_histogram_buggy.c:19
  Previous write of size 8 at 0x7220000000b0 by main thread:
    #0 hist_buggy._omp_fn.0 src/a_histogram_buggy.c:19
  Location is heap block of size 128 at 0x722000000080 allocated by main thread:
    #1 hist_benchmark src/a_hist.h:83
SUMMARY: ThreadSanitizer: data race src/a_histogram_buggy.c:19 in hist_buggy._omp_fn.0
...
SUMMARY: ThreadSanitizer: data race src/a_histogram.c:66 in hist_reduction._omp_fn.0
```

El primero es la carrera real: línea 19, `hist[...]++` sin protección, en el bloque de 128 bytes = 16 `long` (el
histograma). El segundo señala la línea 66 de la versión `reduction`, que es **correcta**: ahí el compilador
coloca la combinación de las copias privadas, protegida por la sincronización interna de `libgomp`, que
ThreadSanitizer no ve. Mismo criterio que en S07: un reporte es carrera real si la línea toca memoria compartida sin
`atomic`/`critical`/candado y sin barrera o `taskwait` entre la escritura y la lectura.

### A.4 · Modificar (en casa; cada cambio se verifica con `make test-a`)

**M1 · Contención.** `OMP_NUM_THREADS=4 ./bin/a_histogram atomic 10000000 B` con B = 1, 64 y 4096. En la máquina de
autoría: 82.8, 51.1 y 18.9 ns/elemento (*speedup* 0.31, 0.47 y 1.27). Explica en dos líneas por qué `atomic` mejora
con más intervalos y por qué `local` no depende de B.

**M2 · El corte de las tareas.** `OMP_NUM_THREADS=4 ./bin/a_histogram tareas 10000000 64 C` con C = 100, 16 384,
2 500 000 y 10 000 000. En la máquina de autoría (varias corridas): 262 142 tareas → *speedup* 0.74–0.92; 2 046 →
2.03–2.52; 6 → 1.86–2.09; 0 → 0.87–1.06. ¿Por qué pierden los dos extremos, y por razones distintas? (Con
C = 1 000, 32 766 tareas, el *speedup* quedó entre 1.85 y 2.39: cada hoja todavía trae ≈ 12 µs de cálculo.)

**M3 · Quita el `single` (línea 107)** y corre `./bin/a_histogram tareas 1000000 64` tres veces con 4 hilos.
Predice antes: ¿correcto?, ¿más rápido? En la máquina de autoría, en una sesión 8 de 9 repeticiones dieron el total
correcto y en otra 9 de 15; las demás, totales como `total=1811017 (esperado 1000000) INCORRECTO`. La línea de tareas
dijo `tareas creadas = 504` y la mediana fue de 0.022 a 0.068 s: lo que tarda la secuencial, o más (con `single`,
0.0096 s). Explica las tres cosas. Deja el archivo como estaba (`git checkout src/a_histogram.c`) y confirma
`make test-a`.

### A.5 · Verificación

```bash
make test-a
```

Salida real (12 casos más la compilación de los dos programas, ≈ 2 s): las cinco versiones iguales a la secuencial con 1, 2, 3 y 4 hilos; `atomic` y
`critical` con un solo intervalo; n = 7 con 4 hilos; 4 096 intervalos; el número de tareas para n = 8 (6, también
con 1 hilo), n = 100 000 con corte 1 000 (254) y n = corte (0); la línea `INFO` del `_buggy` no cuenta. Los conteos son
enteros: la comparación es exacta.

<details><summary>Respuestas de referencia de la Parte A (ábrelas después de ejecutar)</summary>

- **P1/P2.** Con 4 hilos: `reduction` ≈ `local` ≈ `tareas` < `seq` < `atomic` ≪ `critical`. A diferencia de S07,
  las versiones con acumulador privado sí le ganan a la secuencial: cada muestra trae 20–25 ns de cálculo privado
  que se reparte entre los hilos, y la sincronización ocurre una vez por hilo (o por hoja), no por muestra.
- **P3/P4.** 126 en los dos casos: 1 000 000 → 500 000 → … → 15 625 ≤ 16 384 en el nivel 6; 2 + 4 + 8 + 16 + 32 + 64
  = 126 (64 hojas). Las tareas las crea la recursión, no los hilos.
- **P5.** En el arreglo del padre: se copia el **puntero**, no el arreglo. En `fib_buggy.c` la hija escribía en
  la variable `x` misma (una copia privada); aquí escribe a través de una dirección.
- **P6.** (1) El padre sumaría `right` antes de que las hijas terminen; (2) liberaría `right` (línea 100) mientras
  una hija todavía escribe en él: uso de memoria liberada. Probado en la máquina de autoría (no lo repitas): el total
  sale 15 625, exactamente una hoja, en 3 de 3 corridas.
- **P7.** Abajo de n y distinto en cada repetición; con n = 2 000 y 4 096 intervalos, a veces igual: no prueba nada.
- **3.2-1.** La competencia: con 4 hilos cada entrada al `critical` espera a que otro salga y el candado viaja entre
  núcleos. **3.2-2.** La línea de caché del intervalo; los centrales reciben la mayoría de las cuentas, y cada
  `atomic` sobre ellos invalida la copia de los otros núcleos. **3.2-3.** En Fibonacci la hija escribía la variable
  `x` (que, sin `shared`, era su copia); aquí la hija escribe en `right[b]`, y la copia de un puntero apunta al mismo
  arreglo. **3.2-4.** Cualquier hilo que ejecute una tarea con más de `cutoff` muestras crea tareas nuevas: varios
  hilos incrementan el contador a la vez. **3.2-5.** Cuatro recursiones completas sobre el mismo `hist`: cuatro veces
  el trabajo y escrituras simultáneas al mismo arreglo (M3).
- **M1.** Con B = 1 los 4 hilos pelean por la misma línea de caché en cada muestra; con 4 096 intervalos dos hilos
  casi nunca tocan la misma línea a la vez y solo queda el costo de la instrucción atómica. `local` escribe en
  memoria privada en el ciclo caliente y combina B valores por hilo una vez: B solo cambia esa combinación final.
- **M2.** Abajo (C = 100): hojas de 76 muestras, ≈ 1.5 µs de cálculo, contra el costo de crear y planificar cada
  tarea más el `malloc` y la suma de 64 intervalos de cada nodo interno: domina la sobrecarga. Arriba: con 6 tareas
  hay 4 hojas para 4 hilos y nada con qué balancear (si un hilo comparte núcleo con otro proceso, todos lo esperan);
  con 0 tareas el hilo del `single` hace todo solo.
- **M3.** Cada uno de los 4 hilos arranca su propia recursión completa (504 = 4 × 126 tareas) y todas escriben en
  el mismo `hist`; a veces el último en escribir deja los valores correctos, pero las escrituras se cruzan y otras
  veces no (incluso por arriba de n: aquí no es solo `hist[b]++`, también `out[b] += right[b]` sobre el mismo
  arreglo). Es una carrera que "a veces sale bien" (idea errónea 7) y que cuesta 4 veces el trabajo.
</details>

---

## Parte B · Semi-guiada: ordenamiento estable de registros con tareas (Laboratorio 1, ≈ 15 min; se termina en casa)

**Qué cambia respecto a `mergesort_tasks.c` de S09.** Allá se ordenaban enteros y se comparaba contra la propia
versión secuencial. Aquí se ordenan **registros** `{clave float, id}` con muchas claves repetidas (4 096 valores
distintos), el orden debe ser **estable** (entre claves iguales se conserva el orden original), la verificación es
registro por registro contra `qsort` con el criterio (clave, id), y T(1) es el **mejor secuencial disponible**: el
menor entre `qsort` y tu mergesort secuencial (protocolo, §3). Las líneas de tareas (`parallel` + `single` en las
líneas 134–135, las dos `task` y el `taskwait` en las 105–109) vienen **completas**: las leíste en S09 y en la
Parte A.

Uso: `./bin/b_mergesort [n] [cutoff] [ambos | seq | omp]` (por defecto 2 000 000, 4 096, `ambos`).

### TODO(1) · La mezcla estable (`merge`, línea 59)

El comentario trae el plan completo en pseudocódigo. Criterio de "listo": `./bin/b_mergesort 100000 1024 seq`
imprime `mergesort seq … verificacion: OK`. La prueba `B TODO(1)` pasa aunque falten los otros dos.

### TODO(2) · El corte (`merge_sort_tasks`, línea 93)

Si el tramo tiene a lo más `cutoff` registros (o menos de 2), se ordena con `merge_sort_seq` y se regresa **sin**
crear tareas. Criterio: `./bin/b_mergesort 8 2 omp` reporta `tareas creadas = 6` y `./bin/b_mergesort 1000 1000
omp`, 0. Mientras falte, no hay corte (2n − 2 tareas): por eso `main` no corre la versión con tareas para n mayor
que 200 000 y lo dice.

### TODO(3) · El arnés de medición (`time_sort`, línea 142)

1 calentamiento que no se cuenta, `reps` corridas cronometradas con `omp_get_wtime()`, cada una desde la entrada
desordenada. Tú decides qué queda dentro del cronómetro. Criterio: con `REPS=3`, la línea `tiempos_s=` trae 3
valores mayores que 0 (prueba `B TODO(3)`), y en la mini-defensa puedes decir por qué la copia de la entrada no está
dentro.

### B.4 · Tres experimentos con la idea errónea de la parte

1. **"Salió bien".** Con tu `merge` terminado, cambia `<=` por `<` en la comparación y corre
   `./bin/b_mergesort 20 1024 seq` y `./bin/b_mergesort 200 1024 seq`. En la máquina de autoría: con n = 20,
   `verificacion: OK`; con n = 200, `FALLA (ordenado pero NO estable)`. Explica las dos razones por las que n = 20
   no lo detecta (pista: `SMALL_SORT` y los empates). Regresa a `<=`.
2. **Sin `taskwait`.** Comenta el `taskwait` de `merge_sort_tasks` (línea 109 del código base) y corre
   `./bin/b_mergesort 1000000 4096 omp` dos veces y `./bin/b_mergesort 8 2 omp`. En la máquina de autoría: `FALLA (no ordenado por clave)` las tres veces y una
   mediana de 0.020–0.026 s contra 0.039–0.041 s con `taskwait` (n = 10⁶, 4 hilos). Un programa rápido y
   equivocado no tiene *speedup* (protocolo §1.2; idea errónea 13). Restaura la línea.
3. **El corte, medido.** `make cortes` (≈ 35 s) corre n = 2 000 000 con `cutoff` = 1, 16, 256, 4 096, 65 536 y n.
   Una corrida real de autoría (4 hilos, máquina compartida con carga ≈ 2.5):

| `cutoff` | Tareas | t_seq (s) | t_tareas (s) | *Speedup* |
|---|---|---|---|---|
| 1 | 3 999 998 | 0.1631 | 3.9133 | 0.04 |
| 16 | 262 142 | 0.1686 | 0.2659 | 0.63 |
| 256 | 16 382 | 0.1743 | 0.0812 | 2.15 |
| 4 096 | 1 022 | 0.1629 | 0.0746 | 2.18 |
| 65 536 | 62 | 0.1590 | 0.0921 | 1.73 |
| 2 000 000 | 0 | 0.1760 | 0.1677 | 1.05 |

En otras dos corridas de autoría el corte 4 096 dio 2.67 y 1.25, y el 65 536, 3.09 y 1.21: entre 256 y 65 536 las
diferencias son del tamaño del ruido de una máquina compartida. Lo que se repite en todas son los bordes (16 o
menos, y n). Con tu tabla: ¿dónde están los dos bordes de la meseta y qué los causa? Elige tu corte y escríbelo en
`REPORTE.md` §2 con el dato.

Corrida real de referencia con los tres `TODO` resueltos (4 hilos, valores por defecto):

```
b_mergesort: n=2000000 cutoff=4096 hilos=4 reps=5 modo=ambos
n=2000000
qsort            : mediana 0.2626 s  (min 0.2529  max 0.2699)
mergesort seq    : mediana 0.1808 s  (min 0.1662  max 0.1933)  verificacion: OK
mergesort tareas : mediana 0.0775 s  (min 0.0637  max 0.0920)  verificacion: OK
tareas creadas = 1022 (cutoff = 4096)
T(1) = mergesort seq, 0.1808 s (el mejor secuencial)   speedup 2.33   eficiencia 0.58
resumen: n=2000000 cutoff=4096 hilos=4 t_seq=0.1808 t_tareas=0.0775 speedup=2.33 tareas=1022
verificacion contra qsort: OK
```

Tu línea `resumen:` va al punto de control del Laboratorio 1, al *exit ticket* de S09 y a la tarea de S10.
Verificación: `make test-b` (12 casos además de la compilación: n no potencia de 2 con 1, 2 y 4 hilos, n = 1, 2 y 33, muchos empates,
número de tareas, el arnés).

---

## Parte C · Diseño propio (entre el 20 y el 27 de octubre; se mide en el Laboratorio 2)

Elige **una** opción y decláralo en `REPORTE.md`. Se dan la entrada, la salida, el contrato, las restricciones y los
casos de prueba. La estructura del código la decides tú.

### C.1 · Conjunto de Mandelbrot por filas (opción principal)

**Entrada.** `./bin/c_mandelbrot [ancho] [alto] [max_iter] [seq|omp] [schedule] [chunk] [salida.pgm|-] [--verificar]`
(por defecto 1300 × 1200, `max_iter` = 500, `omp`, `static`, *chunk* 0). El esqueleto ya lee los argumentos, pasa
`[schedule] [chunk]` a `omp_set_schedule`, mide con el protocolo, calcula los checksums, compara contra la
secuencial con `--verificar` y escribe la imagen.

**Contrato** (`src/c_mandel.h`, no se modifica): región [−2.0, 0.6] × [−1.2, 1.2]; el píxel (col, fila) se mapea a su
centro con `mandel_pixel_to_c`; su valor es la iteración de escape de `mandel_pixel` (máximo `max_iter`); la fila 0 es
la de arriba. `checksum` = suma de iteraciones; `checksum2` detecta píxeles correctos en lugar equivocado.

**Lo que escribes.** `render_seq` (`TODO(4)`, la referencia T(1)) y `render_omp` (`TODO(5)`). Al terminar, la imagen es
idéntica píxel a píxel a la secuencial y `iters_by_thread[t]` tiene las iteraciones que calculó el hilo t; con eso el
programa imprime `max/promedio` (1.00 = balance perfecto; la eficiencia no puede pasar de 1/`max/promedio`). Si la
suma de `iters_by_thread` no coincide con `checksum`, el programa termina con `FALLA`: cada iteración debe contarse
exactamente una vez.

**Restricciones.**

1. Reparto **por filas**: una fila es la unidad que se reparte.
2. **Sin `critical` ni `atomic` dentro del ciclo de píxeles.** El conteo por hilo no puede escribir, en el ciclo
   caliente, casillas vecinas de un arreglo compartido (falso compartido, S10).
3. La política de `schedule` se elige midiendo al menos dos (una de ellas `static`) con el mismo tamaño, y se
   justifica con la mediana **y** el `max/promedio` de cada una.
4. *Speedup* medido con el protocolo en la Parte D, con T(1) = `render_seq`.

**Casos de prueba** (`make test-c`; 17 casos además de la compilación): `seq` 260 × 240 con `max_iter` 200 debe dar
`checksum=3361872 checksum2=106967741260`; `omp` con `static`, `dynamic,1` y `guided,4` y 1, 2, 3 y 4 hilos, igual
píxel a píxel; tamaños 7 × 5, 1 × 1 y 3 × 97 con 4 hilos; PGM de 13 × 12 con encabezado `P5 13 12 255` y 169 bytes.
`make imagen` escribe `resultados/mandelbrot.pgm` y su PNG para el reporte.

**Preguntas que tu diseño debe contestar en `REPORTE.md` §2:** ¿por qué filas y no píxeles o columnas? ¿qué
`max/promedio` dio `static` y cuál tu política? ¿qué *chunk* y por qué ese y no 1 o 64? ¿dónde se escribe el conteo de
cada hilo y cuántas veces?

### C.2 · Ecuación de calor 1D con convergencia (alternativa)

**Entrada.** `./bin/c_heat [n] [max_iter] [tol] [check_every] [seq|omp] [--verificar]` (por defecto 500 000 celdas,
500 pasos, `tol` = 0, revisión en cada paso).

**Contrato** (`src/c_heat.h`, no se modifica): barra de n celdas con extremos fijos en 0 °C y 100 °C en el tercio
central; cada paso es Jacobi: `u_new[i] = heat_point(u, i)` para 1 ≤ i ≤ n − 2, leyendo solo el arreglo viejo; se
detiene cuando el cambio máximo de un paso revisado es menor que `tol` (revisión cuando `heat_is_check_step` lo dice)
o en `max_iter` pasos. `heat_solve_*` devuelve el búfer con el estado final, el número de pasos y el último cambio.

**Lo que escribes.** `heat_solve_seq` (`TODO(6)`) y `heat_solve_omp` (`TODO(7)`).

**Restricciones.** Sin `critical` en el ciclo de celdas; el cambio máximo se calcula en paralelo; mismo número de pasos
y mismo estado final que la secuencial (tolerancia 1e-10); mide el costo de revisar en cada paso frente a hacerlo cada
`check_every` pasos.

**Casos de prueba** (`make test-c`; 8 casos además de la compilación): `seq` n = 1 000, 100 pasos:
`checksum=3.330000000000e+04 checksum2=3.250261396072e+06`; `omp` con 1–4 hilos igual a la secuencial; n = 3; convergencia con n = 3 000,
`tol` = 1e-3, `check_every` = 10 → **12 100 pasos**; `check_every` = 100 que no divide a `max_iter` = 1 234.

---

## Parte D · Medición e interpretación (Laboratorio 2 y casa; `herramientas/protocolo-medicion.md`)

1. **Antes de medir, escribe tu predicción** para la Parte C y para la Parte B con 4 hilos ("espero S ≈ ___ porque
   ___"; si hiciste la tarea de S11, cópiala de ahí).
2. **Correctitud primero:** `make test` en `0 FAIL`. Un programa que falla no se mide. Si en el Laboratorio 2 tu
   Parte C todavía no pasa, practica el procedimiento con la Parte A (ya es correcta) y llega al punto de control
   con esa tabla:
   `./medir.sh -c A-seq -t 1 -o resultados/practica.csv -- bin/a_histogram seq 50000000` y después
   `./medir.sh -c A-reduction --base A-seq -o resultados/practica.csv -- bin/a_histogram reduction 50000000`
   (≈ 1 min; n = 5·10⁷ ocupa 400 MB).
3. **Tamaño:** que T(1) tarde **≥ 1 s**. Los valores de `make medir` (Mandelbrot 1950 × 1800 con `max_iter` 1000:
   T(1) ≈ 2.5 s; calor n = 2 000 000 con 500 pasos: ≈ 1.8 s; mergesort n = 1.5·10⁷: ≈ 1.4 s) cumplen en la máquina de
   autoría; si en la tuya alguna fila `*-seq` baja de 1 s, súbelo (`make medir MANDEL="…" HEAT="…" NB=…`).
4. **Medir:** cierra lo demás, anota `uptime` y corre

```bash
make medir SCHED="tu-politica chunk" SCHED_ALT="static 0"        # opción Mandelbrot (~2–3 min)
make medir PARTE_C=calor                                         # opción calor
```

   `medir.sh` corre cada configuración con 1, 2, 4 y 8 hilos (variable `HILOS`), toma las 5 repeticiones que mide el
   propio programa tras su calentamiento y escribe `resultados/p4.csv` con las columnas del protocolo
   (`config,hilos,n,rep1..rep5,mediana_s,speedup,eficiencia`), `resultados/entorno.txt` y, en `resultados/salidas/`,
   la salida completa de cada corrida (de ahí sale el `max/promedio` de cada política). El *speedup* se calcula
   contra las filas `C-seq` y `B-seq` (el programa secuencial, no la versión paralela con 1 hilo). Si tu máquina
   tiene menos de 8 núcleos, la fila de 8 hilos es **sobre-suscripción** y se declara así (idea errónea 20).
5. **Graficar:** `make graficar` escribe `resultados/p4_speedup.png` (con la línea ideal S = p) y
   `resultados/p4_eficiencia.png` (con E = 1 y E = 0.5; los puntos con más hilos que núcleos salen huecos) e imprime
   la tabla Markdown con mediana, mínimo, máximo, *speedup*, eficiencia y la *f* de Karp–Flatt. Pégala en el reporte.

El encabezado y una fila reales del CSV de autoría, para que reconozcas el formato:

```
config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia
C-seq,1,3510000,2.598121,2.476605,2.456518,2.391802,2.457955,2.457955,1.000,1.000
```

**Preguntas de interpretación** (3–6 líneas cada una, con números de tu tabla):

1. ¿En qué número de hilos la eficiencia de cada configuración cae por debajo de 0.5 (o no cae)? Da la causa con un
   dato: el `max/promedio` de la política, la *f* de Karp–Flatt y si crece con p, o la fracción de la mezcla final
   del mergesort.
2. ¿Por qué tu política de C le gana (o no) a `static` con el mismo código? Usa el `max/promedio` de las dos.
3. El mergesort hace la última mezcla de n registros con un solo hilo (tarea de S09, ejercicio 2). ¿Qué techo de
   Amdahl implica con 4 hilos y cómo se compara con tu medición? Ese modelo supone que todo el trabajo son las
   mezclas de arriba del corte: ¿qué pasa con el techo si cuentas también el ordenamiento de las hojas, que sí se
   reparte entre los 4 hilos? ¿Qué otro límite actúa sobre un algoritmo que casi solo mueve memoria?
4. ¿Coincidieron tus predicciones (pre-lab y paso 1)? ¿Por cuánto y por qué?
5. ¿Qué pasó con 8 hilos? ¿Es escalabilidad o es otra cosa?

## Preguntas de reflexión (individuales, 5–8 líneas cada una, firmadas con tu alias en el reporte)

Cada integrante responde **una** de las dos primeras (que no la responda todo el equipo igual) y la tercera.

1. **Autoexplicación.** Explica con tus palabras por qué `local`, `reduction` y `tareas` escalan y `atomic` no,
   aunque las cuatro son correctas. Usa los ns por elemento de tu tabla.
2. **Autoexplicación.** Explica por qué el número de tareas no depende del número de hilos y qué decide entonces el
   corte. Usa tus números de M2 o de `make cortes`.
3. **Transferencia.** En la V2 de tu proyecto (H2, lunes 23 de noviembre): ¿qué variable compartida se escribe en tu
   ciclo caliente y qué mecanismo usarías, o qué parte es recursiva o irregular y la harías con tareas o con
   `schedule(dynamic)`? ¿Qué dato medido decidiría entre las alternativas?

## Entregables y formato

Resumen (detalle en `entrega.md`): repositorio **privado** del equipo con el profesor como colaborador; carpeta
`practicas/P4/` con `src/`, `Makefile`, `tests/run_tests.sh` (+ ≥ 1 caso propio), `resultados/` (`p4.csv`,
`entorno.txt`, `p4_speedup.png`, `p4_eficiencia.png`, y `mandelbrot.png` si elegiste Mandelbrot), `prelab/` y
`REPORTE.md` (≤ 3 páginas: reparto de trabajo, decisiones, tablas, gráficas, interpretación, reflexión, bitácora de
errores con ≥ 3 entradas, declaración de IA). Historial de *commits* con participación de cada integrante. Etiqueta
`P4-entrega` antes del **domingo 1 de noviembre, 23:59**. Mini-defensa en el Laboratorio 2; video de ≤ 3 minutos solo
para quien no estuvo en la suya.

## Rúbrica (resumen; completa en `rubrica.md`)

| Criterio | Peso | Ejemplar se ve así |
|---|---|---|
| Correctitud y pruebas | 25 | `make test` en `0 FAIL` sin *warnings* ni `TODO pendiente`, más ≥ 1 caso propio con sentido |
| Diseño paralelo | 20 | Mezcla estable, corte elegido con la tabla de `make cortes`; en C, filas sin `critical`/`atomic` por píxel, conteo privado con una escritura por hilo y `schedule` elegido entre ≥ 2 políticas medidas con mediana y `max/promedio` |
| Medición | 20 | CSV del protocolo con `C-seq`/`B-seq`, 1/2/4/8 hilos, T(1) ≥ 1 s, `entorno.txt`, dos gráficas, la caída de eficiencia de 50 % señalada con su causa y un dato |
| Interpretación y reflexión | 20 | Predicciones copiadas y comparadas; ns/elemento, `max/promedio` y Amdahl usados para explicar; 8 hilos explicado; reflexiones individuales con transferencia concreta |
| Proceso e integridad | 15 | Pre-labs a tiempo, ≥ 3 *commits* de código por integrante, bitácora ≥ 3 entradas (una de concurrencia), declaración de IA completa, cada integrante explica su parte y una función ajena |

## Política de IA aplicada a esta práctica (`docs/metodo/05-politica-ia.md`)

| 🟢 Verde | 🟡 Amarillo (se declara) | 🔴 Rojo |
|---|---|---|
| Pedir que te explique un reporte de ThreadSanitizer, la regla de `firstprivate` de las tareas o qué hace `schedule(guided)` | Pedir que revise tu `merge`, tu `render_omp` o tu `heat_solve_omp` y señale carreras o falso compartido; tú decides y verificas con `make test` y `make tsan` | Pegar el enunciado de una parte y entregar lo que salga |
| Pedir preguntas de práctica sobre `atomic`/`critical`/`reduction` o sobre Amdahl | Pedir casos de prueba para tu caso propio | Pedir el `TODO(n)` o la Parte C completos (cualquier fragmento de más de 10 líneas o una función completa generada por IA) |
| Pedir que te explique un *warning* de gcc | Pedir ayuda con la redacción del reporte a partir de **tus** datos | Inventar, "suavizar" o completar mediciones con la IA |

El pre-laboratorio, la recuperación y la mini-defensa son zonas sin IA. Prueba de propiedad: cualquier integrante debe
poder explicar en voz alta cualquier línea de la parte que firmó ("¿qué hace?", "¿qué pasa si la quito?").

## Errores comunes y cómo detectarlos

| Error | Síntoma | Primera pregunta que debes hacerte |
|---|---|---|
| Concluir que `a_histogram_buggy` "a veces está bien" | Una corrida con `repeticiones incorrectas: 0` | ¿Qué entrelazado de dos hilos pierde una cuenta? Si no puedes descartarlo, ¿qué sabes realmente? |
| Mezcla con `<` en lugar de `<=` | Pasa con n pequeño; con n ≥ 200, `FALLA (ordenado pero NO estable)` | Ante dos claves iguales, ¿cuál debe salir primero para conservar el orden original? |
| Corte que no detiene la recursión (o que crea tareas de todos modos) | `tareas creadas = 2n − 2` o `make cortes` tarda minutos | Con n ≤ cutoff, ¿cuántas tareas debe crear la llamada? ¿Qué línea lo decide? |
| La copia de la entrada dentro del cronómetro | *Speedup* más bajo que el de tus compañeros; la parte secuencial "crece" | ¿Qué hay entre los dos `omp_get_wtime()`? ¿Eso se paraleliza? |
| `critical` o `atomic` dentro del ciclo de píxeles o de celdas | Correcto, pero más lento que la secuencial con 4 hilos | ¿Cuántas veces se ejecuta esa línea por imagen? ¿Qué alternativa deja a cada hilo contar solo y combinar una vez? |
| Conteo por hilo en `iters_by_thread[tid] += k` dentro del ciclo | Escala bien a 2 hilos y mal a 4 | ¿Qué tan cerca en memoria están las casillas de hilos distintos? ¿Cuánto mide una línea de caché? |
| `static` sin medir alternativas | "Pusimos `static` porque es el de por defecto" | ¿Qué `max/promedio` imprimió? ¿Qué dio `dynamic` con el mismo tamaño? |
| *Speedup* contra la versión paralela con 1 hilo | Eficiencia > 1 o *speedup* "demasiado bueno" | ¿Qué fila usó `medir.sh` como T(1)? ¿Es el programa secuencial? |

## Extensión opcional (sin puntos; con reconocimiento en la defensa del proyecto)

**¿Cómo repartirías el histograma entre procesos MPI?** Escribe en media página (sin código, o con pseudocódigo) cómo
lo harías con p procesos que **no comparten memoria** (Unidad IV, desde el jueves 5 de noviembre): quién genera o lee
los datos, qué recibe cada proceso, dónde vive cada histograma parcial, qué operación colectiva los combina en uno y
cuántos bytes viajan en total con `nbins` = 64 frente a mandar las muestras. Compáralo con las cinco versiones de la
Parte A: ¿a cuál se parece y por qué ninguna de las otras cuatro tiene equivalente? Si quieres verificarlo, la
Práctica 5 trae lo necesario para escribirlo.

## Para saber más

- OpenMP Architecture Review Board, *OpenMP Application Programming Interface*, versión 5.2 (noviembre de 2021):
  secciones de *Tasking Constructs* (`task`, `taskwait`), de cláusulas de reducción (secciones de arreglo en
  `reduction`) y del constructo de ciclo (*worksharing-loop*, cláusula `schedule`). https://www.openmp.org/specifications/
- P. Pacheco y M. Malensek, *An Introduction to Parallel Programming*, 2.ª ed., Morgan Kaufmann, 2022, capítulo 5
  (OpenMP: `critical`, `atomic`, `reduction`, planificación y tareas).
- GCC, *GNU Offloading and Multi Processing Runtime Library (libgomp)*: variables de entorno `OMP_NUM_THREADS` y
  `OMP_SCHEDULE`. https://gcc.gnu.org/onlinedocs/libgomp/
- GCC, *Program Instrumentation Options* (`-fsanitize=thread`). https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html
