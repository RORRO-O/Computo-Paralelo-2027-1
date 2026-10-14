> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S07 · jueves 15 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S07 · Ejemplo resuelto: sumar un arreglo con varios hilos sin perder cuentas

Código: `practica-guiada/counter_buggy.c`, `practica-guiada/sum_variants.c`, `practica-guiada/private_buggy.c`.
Compila con `make` dentro de `practica-guiada/`. Las salidas de este documento son corridas reales en la
máquina de autoría (4 núcleos, gcc 13, `-O2`); las tuyas tendrán otros números donde se indica.

Lee cada paso y, en las pausas, responde **antes** de abrir la respuesta.

## Problema

Dado un arreglo `data[0..n)` de enteros, calcular (a) cuántos elementos hay y (b) su suma, usando 4 hilos.
La versión secuencial es trivial. La paralela ingenua está mal, y hay que ver **por qué** antes de ver
**cómo** se arregla.

## Plan en tres líneas

1. Escribir la versión ingenua (`count++`, `sum += data[i]` dentro de `parallel for`) y correrla varias veces.
2. Diagnosticar: rastrear leer-modificar-escribir a mano y confirmar con ThreadSanitizer.
3. Corregir con cinco mecanismos distintos, medir su costo y elegir con criterio.

## Paso 1 · La versión ingenua

```c
long count = 0;
#pragma omp parallel for
for (long i = 0; i < n; i++) {
    count++;                 /* CARRERA: leer count, sumar 1, escribir count */
}

long sum = 0;
#pragma omp parallel for
for (long i = 0; i < n; i++) {
    sum += data[i];          /* CARRERA: misma secuencia leer-modificar-escribir */
}
```

Tres corridas reales con `-O2` y 4 hilos (`OMP_NUM_THREADS=4 ./counter_buggy`):

```
count = 10000000  (esperado 10000000)  coincide (¡no significa que no haya carrera!)
sum   = 3836246333  (esperado 5115395184)  INCORRECTO

count = 10000000  (esperado 10000000)  coincide (¡no significa que no haya carrera!)
sum   = 2557148887  (esperado 5115395184)  INCORRECTO

count = 10000000  (esperado 10000000)  coincide (¡no significa que no haya carrera!)
sum   = 5115395184  (esperado 5115395184)  coincide (¡no significa que no haya carrera!)
```

Y tres corridas del **mismo código** compilado con `-O0` (`make counter_buggy_O0`):

```
count = 8302381  (esperado 10000000)  INCORRECTO
sum   = 2442639109  (esperado 5115395184)  INCORRECTO

count = 7644653  (esperado 10000000)  INCORRECTO
sum   = 3062194917  (esperado 5115395184)  INCORRECTO

count = 6030689  (esperado 10000000)  INCORRECTO
sum   = 4292975516  (esperado 5115395184)  INCORRECTO
```

Observa tres cosas. `sum` cambia en cada corrida y una vez salió **bien**. `count` salió bien las tres veces con
`-O2` y mal las tres con `-O0`. Con un solo hilo (`OMP_NUM_THREADS=1`) todo sale bien siempre.

**Pausa 1.** ¿Por qué `count` sale bien con `-O2` y mal con `-O0`, si el código es el mismo?

<details><summary>Respuesta</summary>

Con `-O2` el compilador ve un ciclo que solo hace `count++` y lo convierte en una sola suma por hilo
(`count += iteraciones_de_este_hilo`). Cada hilo hace **una** operación leer-modificar-escribir en lugar de
2.5 millones, así que la ventana para chocar es diminuta y casi siempre "sale bien". Con `-O0` cada
iteración lee y escribe memoria, y los choques son constantes. La carrera existe en ambos casos: lo que
cambia es la probabilidad de observarla. Esto es la idea errónea 7 en acción: "salió bien" no es evidencia.
</details>

## Paso 2 · Diagnóstico razonando: leer-modificar-escribir

`sum += data[i]` son tres pasos para el procesador. Con `sum == 100`, `data[i] == 5` en el hilo 0 y
`data[j] == 7` en el hilo 1:

| Paso | Hilo 0 | Hilo 1 | `sum` en memoria |
|---|---|---|---|
| 1 | lee `sum` → 100 | | 100 |
| 2 | | lee `sum` → 100 | 100 |
| 3 | suma 5 → 105 | | 100 |
| 4 | | suma 7 → 107 | 100 |
| 5 | escribe 105 | | 105 |
| 6 | | escribe 107 | **107** (debería ser 112) |

Se perdió la aportación del hilo 0. Esto es una **condición de carrera** (*data race*): dos hilos acceden a la
misma posición de memoria, al menos uno escribe, y nada ordena los accesos. El resultado depende de quién
llega primero; por eso es no determinista.

**Pausa 2.** En las corridas del Paso 1, `sum` y `count` siempre salieron **menores o iguales** que el valor
esperado, nunca mayores. ¿Por qué?

<details><summary>Respuesta</summary>

Un choque solo puede **perder** aportaciones: dos hilos leen el mismo valor viejo y el segundo en escribir
sobreescribe al primero. No hay entrelazado de leer-modificar-escribir que sume algo dos veces. Así que el
total observado es la suma correcta menos lo perdido. Con `-O2` el compilador puede acumular en un registro y
escribir pocas veces; entonces un solo choque pierde el bloque entero de un hilo. Fíjate en la segunda corrida:
2 557 148 887 es casi exactamente la mitad de lo esperado: se perdieron dos de los cuatro bloques.
</details>

## Paso 3 · Diagnóstico con ThreadSanitizer

```bash
make tsan      # gcc -std=c11 -fsanitize=thread -g -O1 -Wall -Wextra -fopenmp; corre con n = 200 000
```

Reporte real (recortado) para `counter_buggy`:

```
WARNING: ThreadSanitizer: data race
  Write of size 8 at 0x7fff21b280b8 by main thread:
    #0 main._omp_fn.0 counter_buggy.c:38
  Previous read of size 8 at 0x7fff21b280b8 by thread T1:
    #0 main._omp_fn.0 counter_buggy.c:37
  Location is stack of main thread.
SUMMARY: ThreadSanitizer: data race counter_buggy.c:38 in main._omp_fn.0
```

Cómo leerlo: la línea 38 es `count++`; el hilo principal escribe y el hilo T1 había leído la misma dirección
(`0x7fff…`, una variable de la pila de `main`: `count`). `main._omp_fn.0` es el nombre que gcc da al cuerpo de
la primera región paralela. ThreadSanitizer encontró la carrera **aunque el resultado de esa corrida fuera
correcto**: analiza accesos, no resultados.

Dos avisos. Primero, ThreadSanitizer multiplica el tiempo por 5–20: úsalo con `n` pequeño. Segundo, con gcc
también reporta "carreras" en código **correcto** que usa `critical`, candados o barreras, porque no ve la
sincronización interna de `libgomp`. Cómo distinguirlos está en `practica-guiada/README.md`, fase 3.3.

## Paso 4 · Cinco correcciones

Todas dan el resultado exacto. Difieren en qué protegen y cuánto cuestan.

```c
/* 1) reduction: copia privada por hilo; OpenMP combina al final. */
#pragma omp parallel for reduction(+:s)
for (long i = 0; i < n; i++) s += data[i];

/* 2) atomic: una instrucción atomica del procesador por actualización. */
#pragma omp parallel for
for (long i = 0; i < n; i++) {
    #pragma omp atomic
    s += data[i];
}

/* 3) critical: un hilo a la vez en la región (cualquier código, no solo x += e). */
#pragma omp parallel for
for (long i = 0; i < n; i++) {
    #pragma omp critical
    s += data[i];
}

/* 4) candado explícito: igual que critical, pero con un objeto que controlamos. */
omp_lock_t lock;
omp_init_lock(&lock);
#pragma omp parallel for
for (long i = 0; i < n; i++) {
    omp_set_lock(&lock);
    s += data[i];
    omp_unset_lock(&lock);   /* si se olvida, el programa se cuelga */
}
omp_destroy_lock(&lock);

/* 5) acumulador local por hilo + una sola combinación por hilo. */
#pragma omp parallel
{
    long local = 0;          /* privada por alcance: declarada dentro de la región */
    #pragma omp for nowait   /* sin barrera: quien termina, combina */
    for (long i = 0; i < n; i++) local += data[i];
    #pragma omp atomic       /* una actualización compartida por hilo, no por elemento */
    s += local;
}
```

**Pausa 3.** En la versión 5, el ciclo caliente no tiene `atomic` ni `critical`. ¿Por qué no hay carrera?
¿Dónde está la única actualización de memoria compartida?

<details><summary>Respuesta</summary>

`local` se declara dentro de la región paralela, así que cada hilo tiene la suya (idea errónea 15: las variables
declaradas adentro **no** son compartidas). Sumar sobre memoria privada no choca con nadie. La única escritura
compartida es `s += local`, una por hilo (4 en total, no 10 millones), y esa sí va protegida con `atomic`. Es
exactamente lo que `reduction` hace por ti.
</details>

**Pausa 4.** La versión 5 usa `nowait` en el `for`. ¿Por qué aquí es seguro quitar la barrera?

<details><summary>Respuesta</summary>

Después del ciclo, cada hilo solo toca `local` (suya) y `s` (protegida por `atomic`). Nadie lee lo que otro
hilo escribió dentro del ciclo. La barrera implícita al final de `omp for` existe para que nadie lea datos
que otro todavía no termina de escribir (idea errónea 12); si no hay esa dependencia, sobra. En
`practica-guiada/nowait_buggy.c` verás el caso contrario: el segundo ciclo lee `a[n-1-i]`, escrito por otro
hilo, y quitar la barrera rompe el resultado. La barrera que sí falta en la versión 5 es la del final de la
región `parallel`, y esa no se puede quitar: por eso `s` está completa cuando `main` la imprime.
</details>

## Paso 5 · Medir el costo

Una corrida real de `OMP_NUM_THREADS=4 ./sum_variants` (`n = 4 000 000`, mediana de 5 repeticiones tras un
calentamiento). Tres corridas más dieron el mismo orden; los rangos observados van entre paréntesis.

| Versión | Mediana (s) | ns por elemento | Tiempo / secuencial | Rango de ns/elemento en 3 corridas |
|---|---|---|---|---|
| secuencial | 0.0024 | 0.60 | x1.00 | 0.6–0.7 |
| `reduction` | 0.0108 | 2.70 | x4.5 | 2.7–4.7 |
| `atomic` | 0.0570 | 14.26 | x23.6 | 14–15 |
| `critical` | 0.2499 | 62.48 | x103 | 55–65 |
| `lock` | 0.2567 | 64.18 | x106 | 59–64 |
| `local` | 0.0135 | 3.36 | x5.6 | 3.2–10 |

Lectura. Estos números son **orientativos** (máquina virtual compartida; `n` pequeño a propósito para que
`critical` termine en segundos). Lo que se repite en cualquier máquina:

- `critical` y `lock` cuestan lo mismo: son el mismo mecanismo (exclusión mutua con un candado). Diez millones
  de regiones críticas en cuatro hilos son diez millones de turnos: todos esperan a todos.
- `atomic` es 4–5 veces más barato que `critical`, pero cada actualización sigue viajando entre las cachés de
  los núcleos: la línea de caché con `s` rebota de un núcleo a otro.
- `reduction` y `local` son el mismo patrón (acumular en privado, combinar una vez) y por eso cuestan casi
  igual. Que ninguna versión paralela gane aquí a la secuencial no es un error de medición: sumar 4 millones
  de enteros toma 2 ms, menos de lo que cuesta despertar y coordinar 4 hilos. Es la primera aparición de un
  tema de S10 (jueves 22 de octubre): el tamaño del problema decide si vale la pena paralelizar.

**Pausa 5.** `atomic` y `critical` dieron el mismo resultado. ¿Son equivalentes? ¿Qué pasa si la operación
protegida fuera `if (data[i] > max) max = data[i];`?

<details><summary>Respuesta</summary>

No son equivalentes (idea errónea 8). `atomic` solo acepta una operación simple sobre **una** variable
escalar: `x++`, `x--`, `x += e`, `x = x op e` y similares (OpenMP API Specification 5.2, sección *atomic Construct*). Un `if` con una lectura y
una escritura condicional no cabe en `atomic`; ahí se usa `critical`, un candado o, mejor, `reduction(max:max)`.
`critical` protege una región arbitraria de código; `atomic` protege una actualización de memoria y por eso
puede ser más barata.
</details>

## Paso 6 · La suma en punto flotante no es "exactamente igual"

La última parte de `sum_variants` suma `1/(i+1)` para `i < n` en `double`, secuencial y con `reduction`:

```
suma double secuencial = 15.779020708984671
suma double reduction  = 15.779020708984943
diferencia absoluta    = 2.718e-13  (distintas: el orden de suma cambia el redondeo; tolerancia relativa 1e-9: ok)
```

Mismos números, distinto orden de suma, distinto redondeo (idea errónea 10). Por eso `make test` compara los
resultados en punto flotante con tolerancia y los conteos enteros de forma exacta.

## Variante que falla · `private` no copia el valor inicial

`private_buggy.c` genera 8 números pseudoaleatorios a partir de una semilla `seed = 2026`. La versión
secuencial es la referencia. Las paralelas difieren solo en la cláusula:

```c
seed = 2026u;
#pragma omp parallel for private(seed)        /* B */
for (int i = 0; i < N; i++) out[i] = lcg_next(&seed) % 100;

seed = 2026u;
#pragma omp parallel for firstprivate(seed)   /* C */
for (int i = 0; i < N; i++) out[i] = lcg_next(&seed) % 100;
```

Dos corridas reales con 4 hilos (cada hilo toma 2 iteraciones seguidas):

```
A) secuencial    20  58  87  82  44  55  84  25
B) private       21  66  40  46  40  46  40  46
C) firstprivate  20  58  20  58  20  58  20  58

A) secuencial    20  58  87  82  44  55  84  25
B) private       59  24  81  15  81  15  81  15
C) firstprivate  20  58  20  58  20  58  20  58
```

**Pausa 6.** ¿Por qué B cambia entre corridas y C no? ¿Por qué C repite `20 58` cuatro veces?

<details><summary>Respuesta</summary>

Con `private(seed)` cada hilo recibe una copia **sin inicializar** (idea errónea 9): lo que hubiera en esa
posición de memoria. Leerla es comportamiento indefinido; en la práctica, basura que cambia entre corridas.
Con `firstprivate(seed)` cada hilo recibe una copia **inicializada con 2026**, así que los cuatro hilos generan
la misma secuencia desde el principio: `20 58` cada uno. Es correcto según OpenMP, aunque para tener azar
distinto por hilo habría que usar `seed + omp_get_thread_num()`. Nota al margen: si `lcg_next` fuera visible
para el compilador (sin `noinline`), `gcc -Wall` avisa `'seed' may be used uninitialized`. Lee los *warnings*.
</details>

## Qué te llevas

1. Toda variable compartida que se **escribe** dentro de una región paralela necesita una decisión explícita:
   `reduction`, `atomic`, `critical`/candado, o convertirla en privada y combinar al final.
2. El diagnóstico es por razonamiento (¿quién escribe? ¿quién lee? ¿qué los ordena?) y por herramienta
   (ThreadSanitizer sobre la versión sin sincronizar). El resultado de una corrida no es evidencia.
3. El orden de costo es estable: privado + combinar ≈ `reduction` < `atomic` < `critical` ≈ candado. Se elige
   el más barato que **sea correcto** para la operación.
4. `private` no inicializa; `firstprivate` copia. Lo que se declara dentro de la región es privado.
