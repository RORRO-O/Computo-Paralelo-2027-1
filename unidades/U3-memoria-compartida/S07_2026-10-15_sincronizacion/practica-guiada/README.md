> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S07 · jueves 15 de octubre de 2026 · 10:30–12:00 · Salón 3208

# Práctica guiada S07 · Histograma en paralelo: de la carrera a la corrección

Actividad PRIMM en parejas (conductor/navegante; cambio de rol a los 15 minutos). Dura 30 minutos en clase
más 10 de transferencia. Es autocontenida: solo necesitas `gcc` con OpenMP y `make`.

## Qué hay en esta carpeta

| Archivo | Qué es | Carrera a propósito |
|---|---|---|
| `histogram_buggy.c` | Histograma con `hist[bin]++` compartido sin protección | **Sí** |
| `histogram_critical.c` | Corrección con `#pragma omp critical` | No |
| `histogram_atomic.c` | Corrección con `#pragma omp atomic` | No |
| `histogram_local.c` | Corrección con histograma local por hilo + combinación final | No |
| `common.h` | Datos deterministas, histograma secuencial de referencia, arnés de medición (1 calentamiento + 5 repeticiones, mediana) | — |
| `counter_buggy.c`, `sum_variants.c` | Código del ejemplo resuelto (`../ejemplo-resuelto.md`): contador/suma con carrera y cinco soluciones medidas | Solo `counter_buggy.c` |
| `private_buggy.c` | `private` vs `firstprivate`: la variante que falla | Uso de variable sin inicializar (a propósito) |
| `barrier_demo.c` | Barrera implícita y explícita, `nowait`, `single`, `master` | No |
| `nowait_buggy.c` | `nowait` donde sí hacía falta la barrera | **Sí** |
| `Makefile` | `all`, `run`, `test`, `clean`, `tsan` | — |
| `tests/run_tests.sh` | Compara cada versión paralela contra la secuencial | — |

Todos los programas aceptan el tamaño por línea de comandos: `./histogram_atomic [n] [nbins]`,
`./sum_variants [n]`. Por defecto `n = 10 000 000` y `nbins = 64` (histogramas) y `n = 4 000 000` (suma).
El número de hilos se controla con `OMP_NUM_THREADS` (o `make run THREADS=2`).

Los datos se generan con una semilla fija: dos corridas con el mismo `n` ven exactamente los mismos
valores. Si el resultado cambia entre corridas, el culpable es el programa, no los datos.

## Fase 1 · Predecir (5 min, por escrito, antes de compilar)

Lee `histogram_buggy.c` (20 líneas) y `histogram_local.c`. Responde en tu cuaderno o en un archivo
`predicciones.md`:

| # | Pregunta | Tu predicción |
|---|---|---|
| P1 | `histogram_buggy` con 4 hilos, `n = 10 000 000`, 64 bins: ¿el total de cuentas será igual a `n`, mayor o menor? ¿Será el mismo en las 5 repeticiones? | |
| P2 | Ordena de más rápido a más lento con 4 hilos: `critical`, `atomic`, `local`. ¿Alguna será más lenta que la versión secuencial? | |
| P3 | En `histogram_local.c`, el arreglo `local` se declara dentro de la región paralela sin cláusula `private`. ¿Cuántos arreglos `local` existen con 4 hilos? | |
| P4 | En `nowait_buggy.c`, el ciclo 2 lee `a[n-1-i]`. ¿Qué elementos de `b[]` saldrán mal: los de índice bajo, los de índice alto, o cualquiera? ¿Por qué? | |
| P5 | En `barrier_demo.c`, ¿cuántas veces se imprime la línea `single -> verifico`? ¿Qué hilo ejecuta el bloque `master`? | |

No corrijas tus predicciones después. El valor está en comparar.

## Fase 2 · Ejecutar (5 min)

```bash
make                       # compila todo con -std=c11 -O2 -Wall -Wextra -fopenmp (sin warnings)
make run-histograms        # las cuatro versiones con 4 hilos
OMP_NUM_THREADS=4 ./nowait_buggy
OMP_NUM_THREADS=4 ./barrier_demo
```

Salida real de `histogram_buggy` en la máquina de autoría (4 núcleos; la tuya dará otros números):

```
== histograma buggy: n=10000000 nbins=64 hilos=4  (secuencial: 0.0155 s, mediana de 5)
  rep 1: 0.0431 s  total=9669399 (esperado 10000000)  bins distintos=64  INCORRECTO
  rep 2: 0.0326 s  total=9612676 (esperado 10000000)  bins distintos=64  INCORRECTO
  rep 3: 0.0266 s  total=9891323 (esperado 10000000)  bins distintos=64  INCORRECTO
  rep 4: 0.0283 s  total=9744058 (esperado 10000000)  bins distintos=64  INCORRECTO
  rep 5: 0.0286 s  total=9696641 (esperado 10000000)  bins distintos=64  INCORRECTO
RESULT version=buggy threads=4 n=10000000 nbins=64 t_seq=0.0155 t_par=0.0286 speedup=0.54 reps_incorrectas=5 status=INCORRECTO
```

Una segunda corrida dio totales `9857054, 9839952, 9465475, 9894847, 9851012`. Ninguno se repite: el
programa es **no determinista**. Y la misma versión con 16 bins dio 5 de 5 repeticiones correctas:

```
RESULT version=buggy threads=4 n=10000000 nbins=16 ... reps_incorrectas=0 status=OK
```

Anota: ¿coincidió con P1? La segunda salida es la trampa de la sesión: "salió bien" no es evidencia de
que no haya carrera (idea errónea 7).

Salida real de las tres versiones correctas (misma máquina, corridas consecutivas con 4 hilos):

| Versión | Mediana (s), 4 hilos | ns por elemento | Resultado |
|---|---|---|---|
| secuencial | 0.014–0.022 (varió entre corridas) | 1.4–2.2 | referencia |
| `critical` | 0.7306 | 73 | correcto, 5/5 |
| `atomic` | 0.1584 | 16 | correcto, 5/5 |
| `local` | 0.0242 | 2.4 | correcto, 5/5 |

Estos tiempos son **orientativos**: la máquina de autoría es una máquina virtual compartida y el ciclo
es tan ligero (un acceso a memoria por elemento) que el ancho de banda y la creación de hilos pesan
tanto como el cómputo. Lo que sí se repite en cualquier máquina es el orden: `critical` ≫ `atomic` ≫ `local`.
Llena tu propia tabla:

| Versión | 1 hilo | 2 hilos | 4 hilos | ¿Correcto 5/5? |
|---|---|---|---|---|
| `buggy` | | | | |
| `critical` | | | | |
| `atomic` | | | | |
| `local` | | | | |

Comando: `OMP_NUM_THREADS=2 ./histogram_atomic` (y así para cada celda).

## Fase 3 · Investigar (10 min)

### 3.1 Rastreo de leer-modificar-escribir

`hist[bin]++` son tres pasos para el procesador: leer `hist[bin]`, sumar 1, escribir `hist[bin]`. Completa la
tabla para dos hilos que caen en el bin 5 cuando `hist[5] == 7`:

| Paso | Hilo 0 | Hilo 1 | `hist[5]` en memoria |
|---|---|---|---|
| 1 | lee `hist[5]` → 7 | | 7 |
| 2 | | lee `hist[5]` → 7 | 7 |
| 3 | suma → 8 | | 7 |
| 4 | | suma → 8 | 7 |
| 5 | escribe 8 | | 8 |
| 6 | | escribe 8 | **8** (debería ser 9) |

Pregunta: ¿cuántos entrelazados distintos de esos seis pasos producen 9 y cuántos producen 8? Con eso
explica por qué el total de `buggy` siempre queda **por debajo** de `n` y nunca por encima.

### 3.2 ThreadSanitizer sobre la versión con carrera

```bash
make tsan        # compila los *_buggy con -fsanitize=thread -g -O1 y los corre con n pequeño
```

Reporte real (recortado) para `histogram_buggy`:

```
WARNING: ThreadSanitizer: data race
  Read of size 8 at 0x725000000310 by main thread:
    #0 histogram_buggy._omp_fn.0 histogram_buggy.c:21
  Previous write of size 8 at 0x725000000310 by thread T2:
    #0 histogram_buggy._omp_fn.0 histogram_buggy.c:21
  Location is heap block of size 512 at 0x725000000200 allocated by main thread:
    #1 run_histogram_benchmark common.h:103
SUMMARY: ThreadSanitizer: data race histogram_buggy.c:21 in histogram_buggy._omp_fn.0
```

Lee el reporte con estas tres preguntas: (a) ¿qué **línea** señala? (21: `hist[bin]++`); (b) ¿qué dos hilos
chocan y qué hace cada uno? (el hilo principal lee; T2 había escrito); (c) ¿de quién es la memoria?
(el bloque de 512 bytes = 64 `long`: el histograma compartido). Esas tres respuestas son el diagnóstico.

### 3.3 ThreadSanitizer sobre una versión correcta (lee esto antes de confiar ciegamente)

```bash
make histogram_atomic_tsan histogram_critical_tsan
OMP_NUM_THREADS=4 TSAN_OPTIONS=halt_on_error=1 ./histogram_atomic_tsan 50000
OMP_NUM_THREADS=4 TSAN_OPTIONS=halt_on_error=1 ./histogram_critical_tsan 50000   # tarda varios segundos
```

Las dos versiones correctas también producen "data race". En la máquina de autoría, `atomic` señaló la línea 16
(`hist[b] = 0`, escrita por el hilo principal antes de la región) y la 18 (el encabezado del `parallel for`);
`critical` señaló la línea 20, `hist[bin]++`, que está **dentro** del `critical`. Son **falsos positivos**:
ThreadSanitizer no ve la sincronización interna de la biblioteca OpenMP de gcc (`libgomp`): ni sus barreras,
ni `critical`, ni los candados. Regla de la sesión:

- Si la línea señalada accede a memoria compartida **sin** `atomic`/`critical`/candado y **sin** barrera entre
  la escritura y la lectura, el reporte es una carrera real (3.2).
- Si la línea está protegida o separada por una barrera de OpenMP, el reporte es ruido de `libgomp`.
  La verificación de una versión sincronizada es: razonar sobre cada acceso compartido y comparar
  contra la secuencial en varias corridas y con distinto número de hilos (`make test`).

### 3.4 Preguntas sobre líneas concretas

1. `histogram_critical.c`, línea 18: `bin` se calcula **antes** del `critical`. ¿Qué pasaría con el tiempo si
   el cálculo estuviera adentro? ¿Y con la corrección?
2. `histogram_local.c`, línea 21: `local` se declara dentro de la región paralela. ¿Es compartida o privada?
   ¿Qué cláusula haría falta si se declarara afuera? (idea errónea 15)
3. `histogram_local.c`, línea 21: si cambias `calloc` por `malloc`, ¿qué sale? Relaciónalo con
   `private` vs `firstprivate` (idea errónea 9): `private` tampoco inicializa.
4. `histogram_local.c`, línea 23: el `for` lleva `nowait`. ¿Por qué aquí es seguro y en `nowait_buggy.c`
   (línea 48) no? Pista: ¿qué lee cada hilo después del ciclo?
5. `barrier_demo.c`: hay un `#pragma omp barrier` explícito antes de leer `sum_phase3`. Quítalo, compila y
   corre tres veces. ¿Falla? Si no falla, ¿ya es correcto? (idea errónea 7 otra vez)

## Fase 4 · Modificar (10 min; cada cambio se verifica con `make test`)

**M1 · Combinación con `atomic`.** En `histogram_local.c` sustituye la región crítica de la combinación
(líneas 28–29) por un `#pragma omp atomic` dentro del ciclo `for (b…)`. Verifica con `make test` y compara
el tiempo con 4 hilos y `nbins = 64` y `nbins = 4096`. Criterio: pruebas en PASS y una línea escrita con
cuál fue más rápida y por qué (cuántas operaciones protegidas hace cada variante).

**M2 · Contención.** Sin tocar el código, corre `atomic` y `local` con `nbins = 4`, `64` y `4096` y 4 hilos.
Tabla de tres filas. Pregunta: ¿a cuál versión le afecta más el número de bins? Explica con la tabla de 3.1:
¿cuándo chocan dos hilos?

**M3 · Rompe `local` a propósito.** Mueve la declaración `long *local` fuera de la región paralela (antes
del `#pragma omp parallel`), con un solo `calloc`. Compila, corre con 4 hilos: ¿qué pasa con el total?
Después agrégale `private(local)` a la región: ¿compila? ¿funciona? ¿por qué no? (cada hilo recibe un
puntero sin inicializar). Deja el archivo como estaba al terminar (`git checkout histogram_local.c`).

**M4 · Quita el `nowait` de `nowait_buggy.c`** (línea 48). Corre tres veces: los errores deben ser 0.
Explica en una frase qué garantiza ahora la barrera implícita. Vuelve a dejar el `nowait`.

## Fase 5 · Crear (transferencia, 10 min)

Escribe `histogram_locks.c`: un histograma con **un candado por bin** (`omp_lock_t *locks`, uno por cada
bin, `omp_init_lock` antes de la región, `omp_set_lock`/`omp_unset_lock` alrededor de `hist[bin]++`,
`omp_destroy_lock` al final). Parte de `histogram_atomic.c`. El `Makefile` y `tests/run_tests.sh` lo detectan
solos si el archivo existe.

Criterio de "listo":

1. `make test` termina en PASS incluyendo las tres pruebas de `histogram_locks`.
2. Una tabla con 4 hilos, `n = 10 000 000`, `nbins = 64`: tiempo de `locks` contra `atomic` y `local`.
3. Tres líneas: ¿por qué `locks` es más lento que `atomic` aunque los dos protegen "por bin"? ¿Cuándo
   preferirías un candado a `atomic`? (pista: `atomic` solo cubre `x++`, `x += e`, `x = x op e` y similares
   sobre **una** variable escalar; un candado cubre cualquier bloque).

Si terminas antes: versión con reducción de arreglo, `#pragma omp parallel for reduction(+:hist[:nbins])`
(OpenMP 4.5; gcc lo soporta). Mide y compara con `local`: ¿qué está haciendo OpenMP por ti?

## Verificación automática

```bash
make test
```

Salida real:

```
PASS  histogram_critical  hilos=1 n=400000 nbins=64
PASS  histogram_atomic  hilos=1 n=400000 nbins=64
PASS  histogram_local  hilos=1 n=400000 nbins=64
PASS  histogram_critical  hilos=2 n=400000 nbins=64
PASS  histogram_atomic  hilos=2 n=400000 nbins=64
PASS  histogram_local  hilos=2 n=400000 nbins=64
PASS  histogram_critical  hilos=4 n=400000 nbins=64
PASS  histogram_atomic  hilos=4 n=400000 nbins=64
PASS  histogram_local  hilos=4 n=400000 nbins=64
PASS  histogram_atomic  nbins=1 (maxima contencion)
PASS  histogram_local   nbins=4096 (combinacion larga)
PASS  histogram_local   n=7 nbins=3 (menos datos que hilos)
PASS  sum_variants      hilos=4 n=1000000
PASS  sum_variants      hilos=3 n=1000001 (no divisible)
PASS  barrier_demo      hilos=4
PASS  barrier_demo      hilos=1
INFO  histogram_buggy hilos=4 (no cuenta para PASS/FAIL):
      RESULT version=buggy threads=4 n=1000000 nbins=16 ... reps_incorrectas=1 status=INCORRECTO
Resumen: 16 PASS, 0 FAIL
```

Los histogramas son conteos enteros: la comparación es exacta. La suma en `double` de `sum_variants` se
compara con tolerancia relativa `1e-9`, porque `reduction` suma en otro orden y el redondeo cambia
(idea errónea 10). Las versiones `*_buggy` no forman parte del PASS/FAIL: una carrera puede "salir bien".

## Problemas de entorno frecuentes

| Síntoma | Causa | Qué hacer |
|---|---|---|
| Todos los tiempos iguales con 1, 2 y 4 hilos | `OMP_NUM_THREADS` no se exportó o la terminal lo ignora | `OMP_NUM_THREADS=4 ./programa`, en la misma línea |
| `make tsan` tarda minutos | ThreadSanitizer multiplica el tiempo por 5–20 | Usa `n` pequeño (ya lo hace el `Makefile`: 200 000) |
| ThreadSanitizer reporta carrera en `critical` | Falso positivo de `libgomp` (3.3) | Verifica con `make test`, no con TSan |
| `histogram_critical` tarda 4 s o más | Es el punto: 10 millones de regiones críticas (y más si la máquina está cargada) | Compara con `atomic` y `local`; si urge, `make run-histograms N=5000000` |
| Resultado correcto en `buggy` | Casualidad (idea errónea 7) | Sube `n`, cambia `nbins`, corre más veces |

## Uso de IA en esta práctica

Verde: pedirle que te explique el reporte de ThreadSanitizer o la diferencia entre `atomic` y `critical`.
Amarillo: pedirle que revise tu `histogram_locks.c` y señale carreras; tú verificas con `make test` y lo
declaras. Rojo: pegar el enunciado de la Fase 5 y entregar lo que salga sin poder explicar cada línea.
