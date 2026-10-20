> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S13 · jueves 29 de octubre de 2026 · 10:30–12:00 · Salón 3208

# Práctica guiada S13 · Cazador de errores: tres programas, un error cada uno

Actividad PRIMM para la semana del Examen 2 (martes 3 de noviembre, 08:30). En la sesión S13 el tiempo de
clase se va en la recepción de H1 y en la corrección del examen de práctica; esta práctica se hace **en
casa, en parejas** (la misma pareja de PRIMM del diagnóstico), entre el jueves 29 y el lunes 2 de
noviembre. Dura unos 55 minutos: las fases 1–3 (30 min) se hacen primero, como práctica guiada, y las fases
4–5 (Modificar y Crear, 25 min) son el ejercicio 1 de `../tarea-espaciada.md`. Es autocontenida: solo necesitas `gcc` con OpenMP, `make` y, para la fase Investigar, `-fsanitize=thread`.

Cada programa hace algo sencillo (estadística de un arreglo, transformación y suma, estandarización) y
**tiene exactamente un error**. Los tres errores son los que más se repiten en los exámenes y en la Práctica 4:
una carrera sin protección, una barrera o un `nowait` mal puestos, y `private` donde iba `firstprivate` (o
nada). Lo que practicas es el protocolo con el que vas a leer código el martes 3: *¿qué variable se escribe?,
¿quién más la toca?, ¿qué lo ordena?, ¿qué alcance tiene cada temporal?, ¿quién llega a cada barrera?*

## Qué hay en esta carpeta

| Archivo | Qué es | Error a propósito |
|---|---|---|
| `caza1_race_buggy.c` | Media y varianza de `x[0..n)` con `parallel for`; compara con la secuencial | **Sí** (uno) |
| `caza2_barrier_buggy.c` | `a[i] = transform(x[i])` en paralelo; el hilo 0 suma `a[]` cuando "todos terminaron" | **Sí** (uno) |
| `caza3_private_buggy.c` | Estandariza `y[i] = (x[i] − shift)·scale` con `shift` y `scale` calculados antes | **Sí** (uno) |
| `soluciones/caza*_fixed.c` | Las tres correcciones comentadas. **No las abras antes de la fase Modificar** | No |
| `ejemplo_revision.c` | Código de `../ejemplo-resuelto.md`: dos ciclos `static` con `nowait`, `firstprivate`, `atomic`; modo `medir`; variante que falla con `-DVARIANTE_FALLA` | Solo la variante |
| `examen_items/` | Código de los ítems II, III, IV y VI de `../examen-practica-U3.md`, compilado y ejecutado para fijar la clave; `item_V_numeros.py` calcula los números del ítem V | III.1 y III.2 (con `-DCORREGIDO` se corrigen) |
| `common.h` | Datos deterministas (misma semilla, mismos datos), mediana, tolerancia, línea `RESULT` | — |
| `Makefile` | `all`, `run`, `test`, `cazar`, `tsan`, `warn`, `run-examen`, `clean` | — |
| `tests/run_tests.sh` | `make test`: el material tal como se entrega; `make cazar`: **tu** avance | — |

Todos aceptan el tamaño por línea de comandos (`./caza1_race_buggy 1000000`; por defecto `n = 4 000 000`) y
el número de hilos por `OMP_NUM_THREADS`. Cada programa imprime una línea por repetición y una línea
`RESULT … status=OK|INCORRECTO` comparando con su propia referencia secuencial, y termina con código 1 si
algo salió mal. `caza2` **se cuelga**: córrelo siempre con `timeout 10` (el `Makefile` ya lo hace).

## Fase 1 · Predecir (10 min, por escrito, antes de compilar)

Lee los tres programas (cada función paralela cabe en una pantalla). Para cada uno llena las tres columnas.
El navegante escribe; el conductor no toca el teclado hasta que estén las tres filas.

| Programa | ¿Cuál es el error? (línea y qué regla rompe) | Síntoma que predices al correr con 4 hilos (resultado incorrecto / se cuelga / resultado correcto por casualidad / otro) | ¿Y con 1 hilo? |
|---|---|---|---|
| `caza1` | | | |
| `caza2` | | | |
| `caza3` | | | |

Dos preguntas más: **P4.** ¿Cuál de los tres errores encontrará ThreadSanitizer y cuáles no? ¿Por qué?
**P5.** Si `make cazar` corre cada programa con 1, 2 y 4 hilos, ¿cuál de los tres puede "pasar" alguna corrida
sin estar corregido?

No corrijas tus predicciones después de correr. El valor está en comparar.

## Fase 2 · Ejecutar (5 min)

```bash
make                    # compila todo con -std=c11 -O2 -Wall -Wextra -fopenmp (sin warnings)
make run                # los tres cazadores con 4 hilos (caza2 bajo timeout 10) y el ejemplo con n = 16
OMP_NUM_THREADS=2 ./caza1_race_buggy
OMP_NUM_THREADS=1 ./caza3_private_buggy
```

Salida real en la máquina de autoría (4 núcleos, gcc 13, `-O2`; los números de la tuya cambian, los
síntomas no):

```
== caza1 (THREADS=4)
caza1: n=4000000 hilos=4  referencia secuencial: media=0.500079709366 varianza=0.083271250182
  rep 1: media=0.125119540098 varianza=0.067756243500  INCORRECTO
  rep 2: media=0.125003449750 varianza=0.067718935603  INCORRECTO
  rep 3: media=0.125119540098 varianza=0.067756243500  INCORRECTO
RESULT program=caza1 threads=4 n=4000000 reps_incorrectas=3/3 status=INCORRECTO

== caza2 (THREADS=4); si se cuelga, timeout lo mata a los 10 s (codigo 124)
caza2: n=4000000 hilos=4  referencia secuencial: suma=5000575.112309
codigo de salida: 124

== caza3 (THREADS=4)
caza3: n=4000000 hilos=4  shift=0.500080 scale=3.465393  referencia: y[0]=0.154172 y[1]=-1.100656 y[n-1]=-0.612443
  rep 1: y[0]=0.000000 y[1]=0.000000 y[n-1]=0.000000  elementos distintos=4000000  INCORRECTO
  rep 2: y[0]=0.000000 y[1]=0.000000 y[n-1]=0.000000  elementos distintos=4000000  INCORRECTO
  rep 3: y[0]=0.000000 y[1]=0.000000 y[n-1]=0.000000  elementos distintos=4000000  INCORRECTO
RESULT program=caza3 threads=4 n=4000000 reps_incorrectas=3/3 status=INCORRECTO
```

Y con otros hilos (corridas reales; la de `caza1` con 2 hilos es la de autoría: en 13 corridas de revisión
salió 3/3 incorrectas, así que una repetición "buena" es posible, no segura):

```
caza1, 2 hilos:  rep 1 ok · rep 2 media=0.249956719518 INCORRECTO · rep 3 INCORRECTO   -> 2/3 incorrectas
caza1, 1 hilo:   3/3 ok  -> status=OK
caza2, 2 hilos:  se cuelga (124);  caza2, 1 hilo: termina, status=OK
caza3, 1 hilo:   y[] = 0.000000 en todo el arreglo -> 3/3 INCORRECTO
```

Anota qué coincidió con tu tabla. Tres observaciones que conviene no dejar pasar: en `caza1` la media con 4
hilos salió casi exactamente **un cuarto** de la correcta y con 2 hilos **la mitad**, y en la corrida de
autoría una repetición con 2 hilos salió **bien**; `caza2` con 1 hilo termina y da `OK`; `caza3` falla **también con 1 hilo**.

## Fase 3 · Investigar (15 min)

### 3.1 ThreadSanitizer: qué encuentra y qué no

```bash
make tsan
```

Reporte real (recortado) para `caza1`:

```
WARNING: ThreadSanitizer: data race
  Read of size 8 at 0x7fff950b3650 by thread T2:
  Previous write of size 8 at 0x7fff950b3650 by thread T3:
  Location is stack of main thread.
SUMMARY: ThreadSanitizer: data race caza1_race_buggy.c:33 in stats_par._omp_fn.0
```

Léelo con las tres preguntas de S07: (a) qué línea señala (la 33 es el `#pragma omp parallel for`; en otras
corridas señala la 35 o la 36, `sum += x[i]` y `sumsq += …`); (b) qué hilos chocan (**dos trabajadores**, T2 y
T3: una lectura y una escritura previa de la misma dirección); (c) de quién es la memoria (la pila de `main`:
`sum` y `sumsq`, declaradas fuera de la región). Dos hilos trabajadores sobre una variable de `main` sin
nada que los ordene: carrera real. En otras corridas uno de los dos aparece como `main thread`: el hilo
principal **también** es el hilo 0 del equipo. Lo que decide es el marco `#0` de cada acceso: si los dos están
en `stats_par._omp_fn.0` (dentro de la región), son dos trabajadores.

Reporte real para `caza3`:

```
WARNING: ThreadSanitizer: data race
  Write of size 8 at 0x7febd522c500 by thread T2:
  Previous write of size 8 at 0x7febd522c500 by main thread:
    #1 memset ...
    #3 main caza3_private_buggy.c:70
  Location is heap block of size 1600000 ...
SUMMARY: ThreadSanitizer: data race caza3_private_buggy.c:53 in standardize_par._omp_fn.0
```

Aquí el choque es entre el **hilo principal fuera de la región** (el `memset` de la línea 70, que borra `y[]`
antes de cada repetición) y un trabajador dentro de ella (línea 53, `y[i] = …`). El inicio de la región
paralela ordena esos dos accesos, pero ThreadSanitizer no ve la sincronización de `libgomp` (S07, fase 3.3):
es un **falso positivo**. No hay ningún aviso entre dos trabajadores, y sin embargo el programa está mal.
Conclusión para P4: TSan encuentra `caza1`; en `caza2` no sirve (el programa no termina); en `caza3` no hay
carrera que encontrar porque el error es **un valor sin inicializar**, no un acceso concurrente.

### 3.2 El compilador también sabe algo

```bash
make warn
```

Compila `caza3` con el ayudante `standardize` como `inline` (`-DINLINE_HELPER`). Salida real:

```
caza3_private_buggy.c:26:15: warning: 'shift' may be used uninitialized [-Wmaybe-uninitialized]
caza3_private_buggy.c:49:72: note: 'shift' was declared here
caza3_private_buggy.c:26:25: warning: 'scale' may be used uninitialized [-Wmaybe-uninitialized]
```

Con el ayudante marcado `noipa` (como se entrega) gcc no puede ver la lectura y no avisa. Dos lecciones: lee
los *warnings*, y no dependas de ellos: `private` crea una copia **sin inicializar** aunque el compilador no
lo diga (idea errónea 9). Con 1 hilo también se crea esa copia; por eso `caza3` falla con 1 hilo.

### 3.3 Rastreo de `caza2`: ¿quién llega a cada barrera?

Llena la tabla para 4 hilos. En cada fila escribe qué hace cada hilo después del ciclo.

| Hilo | Sale del `for nowait` y… | ¿Llega al `#pragma omp barrier` de la línea 45? | ¿Llega a la barrera implícita del final de la región? |
|---|---|---|---|
| 0 | | | |
| 1 | | | |
| 2 | | | |
| 3 | | | |

Pregunta: ¿cuántos hilos tiene que contar esa barrera para liberar al hilo 0? ¿Cuántos van a llegar? Con eso
explica el código de salida 124 y por qué con 1 hilo "funciona" (idea errónea 32 y, otra vez, la 7).

### 3.4 Preguntas sobre líneas concretas

1. `caza1`, línea 35: `sum` se declara en la línea 32, fuera de la región. ¿Es compartida o privada? ¿Qué pasa
   si la declaras **dentro** del cuerpo del `for`? (compila, pero ¿qué calcula?)
2. `caza1`: la media con 4 hilos salió **un cuarto** de la correcta en las tres repeticiones y con 2 hilos la
   mitad. ¿Qué está haciendo el compilador con `-O2` para que se pierdan bloques completos y no cuentas
   sueltas? (S07, Pausa 2: acumula en registro y escribe pocas veces). ¿Y por qué, en la corrida de autoría,
   una repetición con 2 hilos salió bien?
3. `caza2`, línea 40: si quitas el `nowait`, ¿sigue haciendo falta la barrera de la línea 45? ¿Por qué?
4. `caza3`, línea 51: `shift` y `scale` solo se **leen** dentro de la región. ¿Necesitan alguna cláusula? ¿Cuál
   sería la diferencia de costo entre "ninguna" y `firstprivate`? ¿Cuándo sería obligatorio `firstprivate`?
5. `make test` compara `caza1` con tolerancia relativa `1e-9` y `caza3` con igualdad exacta. ¿Por qué la
   diferencia? (idea errónea 10; mira qué operación hace cada hilo y en qué orden se combinan).

## Fase 4 · Modificar (10 min; cada corrección se verifica con `make cazar`)

Corrige los tres archivos **en el lugar** (no cambies los nombres: `make cazar` los busca así). Para cada uno
elige la corrección **más barata que sea correcta** entre estas alternativas, y escribe en una línea por qué
descartaste las otras dos:

| Programa | Alternativas (todas vistas en S07–S11) |
|---|---|
| `caza1` | `reduction(+:sum, sumsq)` · `#pragma omp atomic` en cada línea · `#pragma omp critical` alrededor de las dos |
| `caza2` | quitar `nowait` · dejar `nowait` y poner la `barrier` fuera del `if` · sustituir el `if (tid == 0)` por `single` |
| `caza3` | ninguna cláusula · `firstprivate(shift, scale)` · `private(shift, scale)` (la actual) |

```bash
make cazar        # pasa solo cuando los tres terminan con status=OK con 1, 2 y 4 hilos (y 3 hilos con n no divisible)
```

Salida real de `make cazar` con el material tal como se entrega (lo que ves antes de corregir):

```
PASS  compila sin warnings: caza1_race_buggy.c
PASS  caza1_race_buggy con 1 hilos: termina y status=OK
FAIL  caza1_race_buggy con 2 hilos: termina y status=OK   (RESULT ... reps_incorrectas=3/3 status=INCORRECTO)
FAIL  caza1_race_buggy con 4 hilos: termina y status=OK   (RESULT ... reps_incorrectas=3/3 status=INCORRECTO)
...
PASS  caza2_barrier_buggy con 1 hilos: termina y status=OK
FAIL  caza2_barrier_buggy con 2 hilos: termina y status=OK
...
FAIL  caza3_private_buggy con 1 hilos: termina y status=OK   (RESULT ... reps_incorrectas=3/3 status=INCORRECTO)
Resumen: 5 PASS, 10 FAIL
```

Y cuando los tres están corregidos: `Resumen: 15 PASS, 0 FAIL` seguido de "Los tres errores están
corregidos. Ahora escribe el cuarto (fase Crear)". Fíjate en que `caza1` con 1 hilo y `caza2` con 1 hilo
**pasan sin corregir**: por eso la prueba corre con 2 y 4 hilos (respuesta a P5).

Criterio de "listo" de esta fase: `make cazar` en `0 FAIL` **y** las tres líneas de justificación escritas.

## Fase 5 · Crear (transferencia, 15 min; con la fase 4, es el ejercicio 1 de `../tarea-espaciada.md`)

Escribe `caza4_<tema>_buggy.c` con **un** error a propósito para tu pareja, distinto de los tres de arriba.
Temas válidos (uno): `taskwait` faltante o `shared` faltante en una tarea (S09); `schedule` que produce un
resultado incorrecto por una dependencia entre iteraciones (S08/S11); `atomic` donde la operación no es una
actualización simple (S07); `reduction` con la variable equivocada; `nowait` entre dos ciclos cuyo mapeo no
coincide (`ejemplo_revision.c`, variante que falla).

Reglas del archivo (el `Makefile` y `make cazar` lo detectan solos por el nombre):

1. Hace algo sencillo y **calcula su propia referencia secuencial**, como los tres cazadores (copia la
   estructura de `caza1_race_buggy.c`: `generate_data`, repeticiones, `print_result`, código de salida).
2. Compila sin *warnings* con las banderas del curso y acepta `n` por línea de comandos.
3. El encabezado declara, en dos líneas con estas palabras exactas: `Síntoma esperado: …` e
   `Idea errónea: <número del Anexo A>`. No digas dónde está el error.
4. Tu pareja lo recibe sin pistas, lo predice, lo corre, lo investiga y lo corrige; cuando `make cazar` pasa
   con el archivo corregido, intercambian papeles.

Criterio de "listo": `make cazar` pasa con el archivo **corregido por tu pareja**, y los dos encabezados
(síntoma e idea errónea) coinciden con lo que tu pareja encontró.

<details><summary>Pista si no arrancas (ábrela después de 3 minutos de intento)</summary>

Toma `examen_items/item_IV_tasks_sum.c` (suma recursiva con tareas) y quita el `shared(left)` de la primera
tarea: la hija escribe en su copia y el padre lee la suya (S09, `fib_buggy.c`). Síntoma esperado: total
incorrecto siempre, sin carrera y sin aviso del compilador. Idea errónea: 13 (y la regla de entorno de datos de
las tareas). Cambia el nombre, el encabezado y la línea `RESULT`, y ya tienes tu `caza4_task_shared_buggy.c`.
</details>

## Respuestas de referencia (ábrelas después de Modificar; sirven si trabajas solo)

<details><summary>Predicciones P1–P5</summary>

- **caza1.** Líneas 35–36: `sum` y `sumsq` son compartidas (declaradas fuera de la región) y todas las
  iteraciones las escriben: carrera (idea 7). Síntoma: resultado incorrecto que cambia entre repeticiones;
  a veces sale bien. Con 1 hilo siempre bien (nadie compite): eso no lo hace correcto.
- **caza2.** Línea 45: `#pragma omp barrier` dentro de `if (tid == 0)`: solo un hilo llega a esa barrera; los
  demás esperan en la del final de la región (idea 32). Síntoma: se cuelga con ≥ 2 hilos; con 1 termina y
  "funciona". El `nowait` de la línea 40 no es el error, pero es lo que creó la necesidad de esa barrera.
- **caza3.** Línea 51: `private(shift, scale)` crea copias sin inicializar (idea 9). Síntoma: `y[]` con basura
  (en la máquina de autoría, ceros); falla también con 1 hilo.
- **P4.** TSan encuentra solo `caza1`: es la única carrera. `caza2` no termina; `caza3` no es una carrera.
- **P5.** `caza1` y `caza2` pasan con 1 hilo (y `caza1` puede pasar alguna repetición con 2); `caza3` nunca pasa.
</details>

<details><summary>Investigar 3.3 y 3.4</summary>

- **3.3.** El hilo 0 llega a la barrera de la línea 45; los hilos 1–3 no entran al `if` y llegan a la barrera
  del final de la región. La de la línea 45 necesita a los 4 y solo llega 1; la del final necesita a los 4 y
  llegan 3. Nadie avanza: interbloqueo, código 124. Con 1 hilo, el único hilo es el 0, llega a ambas y las dos
  "se completan" con un hilo.
- **3.4-1.** Compartida. Declarada dentro del cuerpo del `for`, cada iteración tendría su propia `sum` que
  muere al terminar la iteración: compila, no hay carrera, y la media sale de `sum = 0`: incorrecta de otra
  manera. La variable tiene que vivir fuera **y** estar protegida: `reduction`.
- **3.4-2.** Con `-O2`, el compilador acumula `sum` en un registro dentro del ciclo de cada hilo y escribe a
  memoria pocas veces. Cuatro hilos leen el mismo `0`, acumulan su cuarto y lo escriben: sobrevive el último.
  Por eso se pierden bloques enteros. La repetición "buena" con 2 hilos ocurrió cuando un hilo terminó y
  escribió antes de que el otro leyera: casualidad de tiempos (idea 7).
- **3.4-3.** No. Sin `nowait`, el `for` termina con barrera implícita y `a[]` está completo cuando el hilo 0 suma.
  Es la corrección más barata: no agrega sincronización, quita una que estaba mal.
- **3.4-4.** No necesitan cláusula: una variable compartida que **nadie escribe** dentro de la región no tiene
  carrera y no cuesta nada. `firstprivate` también es correcta (una copia por hilo, costo despreciable aquí) y
  sería obligatoria solo si cada hilo fuera a **modificar** su copia. `private` nunca, porque el valor se usa.
- **3.4-5.** `caza1` suma en otro orden con `reduction` (parciales por hilo): el redondeo cambia en los últimos
  dígitos. `caza3` hace exactamente la misma operación por elemento en cualquier reparto: debe salir idéntico.
</details>

<details><summary>Modificar: las correcciones y por qué (coinciden con soluciones/)</summary>

- **caza1 → `reduction(+:sum, sumsq)`.** `atomic` es correcto pero paga una operación atómica por elemento (en
  S07, ×5 respecto a `reduction`); `critical` serializa el ciclo entero (más lento que secuencial). Con la
  corrección, `rep 1: media=0.500079709366 varianza=0.083271250182 ok` con 1, 2 y 4 hilos.
- **caza2 → quitar `nowait`** (y la `barrier` del `if`). La barrera implícita del `for` ya garantiza `a[]`
  completo. Poner la `barrier` fuera del `if` también es correcto (una barrera más, equivalente); `single`
  solo sirve si va precedido de una barrera, porque la suya está al **final** del bloque. Corregido:
  `suma=5000575.112309 ok` y termina.
- **caza3 → ninguna cláusula** (o `firstprivate`). Corregido: `elementos distintos=0 ok` con 1, 2 y 4 hilos.
</details>

## Verificación automática

```bash
make test       # el material tal como se entrega: 53 PASS en ~17 s en la máquina de autoría
make cazar      # tu avance: pasa cuando corregiste los tres (y el caza4 si existe)
```

`make test` verifica, en este orden: (A) que cada fuente compila sin *warnings* (`-Werror`) y que gcc **sí**
avisa en `caza3` cuando puede ver la lectura; (B) que los errores se reproducen (`caza2` se cuelga con 4 hilos
y termina con 1; `caza1` y `caza3` dan `INCORRECTO`; si por azar alguno sale bien se imprime `INFO` y no
cuenta, porque una carrera o un valor indefinido pueden "salir bien"); (C) que las soluciones pasan con 1, 2 y
4 hilos y con `n` no divisible; (D) que ThreadSanitizer detecta la carrera de `caza1`; (E) que el ejemplo
resuelto imprime `hits = 8` con mapas iguales; (F) que los ítems del examen de práctica dan las salidas de la
clave. Resumen real: `53 PASS, 0 FAIL, 0 SKIP`.

## Problemas de entorno frecuentes

| Síntoma | Causa | Qué hacer |
|---|---|---|
| `caza2` "no hace nada" | Se colgó y no usaste `timeout` | `timeout 10 ./caza2_barrier_buggy`; Ctrl-C si ya lo lanzaste |
| `make cazar` pasa `caza1` con 1 hilo y falla con 4 | Es lo esperado: la carrera necesita ≥ 2 hilos | Corrige la variable compartida, no el número de hilos |
| TSan reporta carrera en `caza3` | Falso positivo entre el `memset` de `main` y los trabajadores (S07 3.3) | Mira el marco `#0` de cada acceso: los dos dentro de `_omp_fn` = dos trabajadores = real (aunque uno diga `main thread`); uno en `main`, fuera de la región = ruido |
| `make tsan` tarda minutos | TSan multiplica el tiempo ×5–20 | El `Makefile` ya usa `n = 200 000`; no subas `n` |
| `caza3` da `OK` en tu máquina | La basura coincidió con el valor correcto (muy improbable) o el compilador reutilizó la pila | Corre con otro `n` y con 1 hilo; lee `make warn` |
| El ejemplo `medir` da *speedup* < 1 | Es real: `T(1) ≈ 0.02 s` y dos pasadas sobre `a[]`; el protocolo rechaza esa medición | Lee `../ejemplo-resuelto.md`, Pausa 6 |

## Uso de IA en esta práctica

Verde: pedirle que te explique un reporte de ThreadSanitizer o la diferencia entre `private` y `firstprivate`.
Amarillo: pedirle que revise tu `caza4` y te diga si el error es detectable; tú verificas con `make cazar` y
lo declaras en `tareas/S13/respuestas.md`. Rojo: pedirle que corrija los tres cazadores por ti, o que escriba
el `caza4`; el martes 3 de noviembre no habrá IA y sí habrá un ítem igual a estos.
