> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S12 · martes 27 de octubre de 2026 · 08:30–10:00 · Lab LS4

# Práctica guiada S12 · ¿Dónde está el tiempo? Perfilado por secciones y plan de la V2

Mini PRIMM (≈ 9 minutos en clase para Predecir–Modificar y 10 para arrancar Crear; el resto en la tarea) sobre `fases.c`, un programa de tres fases: carga,
cómputo caliente y salida. Vas a **predecir** qué fase domina, **medir** con `omp_get_wtime()`, **calcular** la
fracción paralelizable en tiempo y la cota de Amdahl, **paralelizar** la fase correcta y **comparar** predicción
con medición. Al final aplicas lo mismo a tu V1 con la plantilla `plan-paralelizacion-V2.md`.

En parejas: conductor (teclado) y navegante (lee, predice, anota). Cambio de rol al pasar a "Modificar".

## Archivos

| Archivo | Qué es |
|---|---|
| `fases.c` | Programa del PRIMM: tres fases cronometradas; la fase de cómputo trae `TODO(1)` |
| `ejemplo_perfil.c` | Código del ejemplo resuelto de la sesión (`../ejemplo-resuelto.md`); ya paralelizado por modos |
| `medir.sh` | Protocolo del curso: calentamiento + 5 repeticiones, mediana [mín, máx], *speedup* de una fase y del total |
| `Makefile` | `make` (compila), `make run`, `make test`, `make medir`, `make tsan`, `make clean` |
| `tests/run_tests.sh` | Compara la versión paralela con la secuencial (tolerancia 1e-9 en flotantes, exactitud en enteros) |
| `plan-paralelizacion-V2.md` | Plantilla que tu equipo llena para su proyecto (secciones 0–2 hoy; 3–5 de tarea) |

Compilación (ya está en el `Makefile`): `gcc -std=c11 -O2 -Wall -Wextra -fopenmp fases.c -o fases -lm`.
Hilos: variable de entorno `OMP_NUM_THREADS`. Argumentos: `./fases [n] [k]` (n registros, k pasos por registro;
por defecto 500000 y 200).

Entorno en que se obtuvieron las salidas de este documento: máquina virtual Linux con 4 vCPU (Intel Xeon
2.80 GHz), gcc 13.3, `-O2`, **compartida con otros procesos** durante la autoría; las mediciones se repitieron
hasta tener una ventana sin carga ajena y se reportan mediana, mínimo y máximo. Tus tiempos serán distintos;
las fracciones y las conclusiones no deberían.

## P · Predecir (1 min, por escrito, antes de compilar)

Lee el encabezado de `fases.c` y las tres funciones (`load_phase`, `compute_phase`, `output_phase`). No lo
corras todavía.

1. ¿Qué fase domina el tiempo? ¿Qué porcentaje del total le das a cada una?
   carga ____ % · cómputo ____ % · salida ____ %
2. ¿Cuántas operaciones hace la carga **por registro**? ¿Y el cómputo por registro? (cuenta el ciclo interno)
3. Si paralelizaras **solo** la fase que crees dominante y escalara perfecto en 4 hilos, ¿qué *speedup* del
   programa completo esperas? ______
4. ¿Qué imprimirá el programa si lo corres con `OMP_NUM_THREADS=4` **sin** tocar el código? ______

## R · Ejecutar (1 min)

```bash
make
OMP_NUM_THREADS=1 ./fases          # perfil secuencial, tamaño por defecto
OMP_NUM_THREADS=4 ./fases          # ¿qué cambia? lee la última línea
```

Salida real con 1 hilo (una corrida; tus números cambiarán, las fracciones poco):

```
histograma=0,53685,81645,92849,271821,0,0,0,0,0
suma=-1.201347451248e+05
fases n=500000 k=200 hilos_max=1 hilos_en_computo=1
fase        tiempo_s  fraccion
carga         0.2032     0.142
computo       1.2277     0.857
salida        0.0012     0.001
total         1.4320     1.000
```

Con 4 hilos, sin completar el TODO, la última línea es:

```
TODO pendiente: la fase de computo corrio con 1 hilo; completa TODO(1) en fases.c
```

Compara con tu predicción: ¿acertaste la fase dominante? ¿Por cuántos puntos porcentuales fallaste? Anótalo.

## I · Investigar (2 min en clase: preguntas 1 y 2; la 3–6 se terminan en la tarea)

1. **Fracción paralelizable.** Supón que solo la fase de cómputo se paraleliza. Con la tabla de 1 hilo:
   f = tiempo de cómputo / tiempo total = ______. Cota de Amdahl: S_max(2) = 1/((1−f) + f/2) = ______;
   S_max(4) = ______; S_max(∞) = 1/(1−f) = ______.
2. **Dependencias de la fase de cómputo** (líneas 70–80). Por iteración de `i`: ¿qué variables **lee**?
   ¿Cuáles **escribe**? De las que escribe, ¿cuál la escriben **todas** las iteraciones? Esa es una reducción.
   ¿Qué alcance tienen `p` y `v` (línea 72–73) dentro de una región paralela y por qué?
3. **Línea 71** (`if (i == 0) *threads_used = …`): la escribe una sola iteración. ¿Es una carrera? ¿Por qué no?
4. **Fase de salida, línea 94** (`hist[bin]++`). Si la paralelizaras tal cual, ¿qué pasaría cuando dos hilos
   caen en el mismo `bin`? ¿Cómo lo resolverías sin un `critical` dentro del ciclo? ¿Vale la pena, dada su fracción?
5. **La carga** (líneas 42–47) genera texto y lo parsea con `strtod`. ¿Cuál de los dos ciclos podría repartirse
   entre hilos sin cambiar el resultado? En tu V1 la lectura viene de un archivo real: ¿qué parte de esa
   "carga" se puede repartir y cuál no?
6. ¿Cómo cambia la fracción si crece `n` o si crece `k`? Predice y después comprueba con dos corridas:

```bash
OMP_NUM_THREADS=1 ./fases 500000 50      # k cuatro veces menor
OMP_NUM_THREADS=1 ./fases 2000000 25     # mucho más registros, poco cómputo por registro
```

Corridas reales (1 hilo, una corrida cada una; tiempo en s y fracción):

| Comando | carga | cómputo | salida | total | ¿Qué cambió? |
|---|---|---|---|---|---|
| `./fases 500000 200` (defecto) | 0.2032 (0.142) | 1.2277 (0.857) | 0.0012 (0.001) | 1.4320 | referencia |
| `./fases 500000 400` | 0.1589 (0.065) | 2.2819 (0.934) | 0.0011 (0.000) | 2.4419 | más cómputo por registro: f sube |
| `./fases 500000 50` | 0.1982 (0.412) | 0.2814 (0.585) | 0.0015 (0.003) | 0.4811 | poco cómputo por registro: f baja a 0.59 |
| `./fases 2000000 25` | 0.6853 (0.603) | 0.4466 (0.393) | 0.0041 (0.004) | 1.1359 | la carga domina: f = 0.39, S_max(∞) = 1.6 |

<details>
<summary>Respuestas de autocomprobación (ábrelas después de escribir las tuyas)</summary>

1. Con la corrida de arriba: f = 1.2277 / 1.4320 = **0.857**. S_max(2) = 1/(0.143 + 0.857/2) = 1/0.572 ≈ **1.75**;
   S_max(4) = 1/(0.143 + 0.857/4) = 1/0.357 ≈ **2.80**; S_max(∞) = 1/0.143 ≈ **7.0**. Aunque el cómputo tardara
   cero, el programa nunca iría más de 7 veces más rápido: la carga manda desde ahí.
2. Lee `x[i]`, `k` y las constantes; escribe `p_out[i]` (solo la iteración `i`, independiente), `sum` (todas
   las iteraciones: **reducción**) y `*threads_used` (solo `i == 0`). `p` y `v` están declaradas dentro del
   cuerpo del ciclo, así que son privadas por alcance (idea errónea 15): no necesitan `private`.
3. No: solo la iteración 0 escribe esa dirección y nadie la lee hasta después del ciclo. TSan tampoco la marca.
4. Dos hilos harían leer-incrementar-escribir sobre la misma celda: cuenta perdida (carrera). Solución sin
   `critical` interno: histograma privado por hilo y combinar al final (o `atomic`, que para un contador simple es
   más barato que `critical`). Con una fracción ≈ 0.1 % del total no vale la pena: Amdahl lo dice antes que el código.
5. El `strtod` por bloques sí (cada línea es independiente); la generación con `snprintf` también, pero con un
   archivo real la **lectura desde disco** es secuencial: solo el *parseo* en memoria se reparte. Por eso se
   marca "parcial" en la plantilla y se cuenta solo esa parte en f.
6. Con k menor el cómputo cae y la carga pesa más: f baja. Con n mayor y k chico, carga y cómputo crecen juntos
   pero el cómputo por registro es poco: f baja aún más. Duplicar n con k fijo casi no mueve f (ambas crecen
   igual): eso es el argumento de Gustafson de la tarea.

</details>

## M · Modificar (4 min; cambio de roles)

**Objetivo verificable:** la fase de cómputo corre en paralelo, `make test` pasa, y la tabla de abajo tiene
predicción y medición para 1, 2 y 4 hilos.

1. Completa `TODO(1)` (línea 65). Antes de escribir el pragma, di en voz alta qué cláusula necesita `sum` y por
   qué `p` y `v` no necesitan nada.
2. `make test`. Debe decir `TODAS LAS PRUEBAS PASARON` y ya no debe aparecer `INFO: TODO(1) sigue pendiente`.
3. Mide con el protocolo (calentamiento + 5 repeticiones, mediana):
   ```bash
   make medir            # equivale a: ./medir.sh ./fases computo "1 2 4"
   ```
4. Llena la tabla:

| Hilos | S_max(p) por Amdahl (de tu f) | S medido de la **fase** | S medido del **total** | ¿Por qué el total es menor que la fase? |
|---|---|---|---|---|
| 2 | | | | |
| 4 | | | | |

Corrida real de `make medir` con el TODO completado (5 repeticiones; la máquina de referencia estaba
dedicada a la medición):

```
# ./fases 500000 200 · fase=computo · calentamiento 1 + 5 repeticiones · mediana [min, max]
hilos   total_med_s    S_total computo_med_s  S_computo rango_computo
1            1.3435       1.00       1.1369       1.00 [1.1101, 1.1478]
2            0.7352       1.83       0.5632       2.02 [0.5585, 0.5820]
4            0.4648       2.89       0.3006       3.78 [0.2856, 0.3261]
```

Lectura: la **fase** escaló casi ideal (2.02 con 2 hilos; 3.78 con 4, eficiencia 95 %): es un ciclo de
cómputo puro sin tráfico de memoria. El **total** se quedó en 1.83 y 2.89, pegado a la cota de Amdahl
(1.75 y 2.80 con f = 0.857; en esta corrida f = 1.1369/1.3435 = 0.846, cota 2.74). Que el total "le gane"
unas centésimas a la cota no es magia: la cota usa la carga de **una** corrida de 1 hilo (0.20 s) y en las
corridas de 4 hilos la carga tardó entre 0.16 y 0.21 s. Por eso se reportan mín y máx y no un solo número
(idea errónea 5). La diferencia entre 3.78 (fase) y 2.89 (total) es exactamente la carga secuencial: Amdahl
no es una opinión.

5. **Si `make test` falla o la suma cambia entre corridas**: te faltó la reducción. La evidencia decisiva es
   la suma: sin `reduction`, con `-O2` cada hilo acumula su parcial en un registro y la escribe en `sum` al
   final, así que sobrevive la de **un solo** hilo: ≈ ¼ del valor correcto, y cuál de las cuatro sobrevive
   cambia entre corridas (cinco corridas reales con 4 hilos, `./fases 500000 200`):
   ```
   suma=-3.009552028892e+04
   suma=-2.999118887396e+04
   suma=-2.999118887396e+04
   suma=-3.002570444867e+04
   suma=-3.009552028892e+04
   --- referencia correcta (1 hilo): suma=-1.201347451248e+05
   ```
   "Salió bien una vez" no es evidencia (idea errónea 7). Confírmalo con el detector de carreras (tamaño chico:
   TSan hace el programa 10–30× más lento y nunca se mide con él; `make tsan` compila con `-O0 -g` para que el
   aviso caiga en la línea exacta):
   ```bash
   make tsan
   OMP_NUM_THREADS=4 ./fases_tsan 20000 50
   ```
   Con el pragma sin `reduction` (insertado en la línea 70, así `sum += p` queda en la 80), TSan reporta un
   aviso en que **dos hilos trabajadores** escriben la misma dirección en `sum += p` (salida real recortada):
   ```
   WARNING: ThreadSanitizer: data race (pid=21104)
     Write of size 8 at 0x7ffd2f095a50 by thread T1:
       #0 compute_phase._omp_fn.0 fases.c:80
     Previous write of size 8 at 0x7ffd2f095a50 by thread T3:
       #0 compute_phase._omp_fn.0 fases.c:80
   SUMMARY: ThreadSanitizer: data race fases.c:80 in compute_phase._omp_fn.0
   ```
   **Con `reduction(+:sum)` ese aviso desaparece, pero TSan no queda en cero**: con la `libgomp` de gcc salen
   dos avisos más (`fases.c:70`, la línea del pragma, hilo principal contra un trabajador; y `fases.c:92`,
   `output_phase` leyendo `p[]` después de la región) que aparecen igual con la reducción correcta. Son ruido
   de la biblioteca, cuya sincronización TSan no ve (S07, práctica guiada §3.3; H2 §2.1). La regla: hilo
   principal contra trabajador al arrancar o terminar la región = ruido; dos trabajadores sobre tu variable
   dentro del ciclo = carrera tuya. Con `-O1` (lo que usan S07 y H2) el aviso real sigue siendo "trabajador
   contra trabajador", pero cae en la línea del pragma porque el compilador acumula en un registro y escribe
   `sum` una vez al final. Con la reducción, la suma coincide con la secuencial dentro de 1e-9 (el orden de
   la suma cambia el redondeo: por eso hay tolerancia).

<details>
<summary>Solución de TODO(1) (ábrela solo después de intentarlo y de correr <code>make test</code>)</summary>

```c
    #pragma omp parallel for reduction(+:sum)
    for (long i = 0; i < n; i++) {
```

`sum` es reducción; `p_out[i]` es independiente (cada iteración escribe su índice); `p`, `v`, `j` son privadas
por alcance; `x`, `k`, las constantes y `threads_used` se comparten sin conflicto (solo lectura, o una sola
escritura). `schedule` se deja por defecto porque todas las iteraciones hacen exactamente k pasos: trabajo
uniforme → `static` (idea errónea 11: `dynamic` no "siempre gana").

</details>

## M · Crear (*Make*; 10 min de arranque en clase, se termina como tarea)

**Instrumenta tu V1.** Con tu equipo:

1. Define las secciones de tu V1 (3–6 fases con sentido: leer, construir, ciclo principal, escribir…).
2. Pon un `omp_get_wtime()` entre sección y sección e imprime la tabla tiempo/fracción como `fases.c`.
3. Corre con el tamaño que usarás para medir (T(1) ≥ 1 s): 1 de calentamiento + 5 repeticiones; anota mediana,
   mín y máx de cada sección (puedes adaptar `medir.sh`: solo cambia el nombre de la fase que extrae).
4. Llena las **secciones 0, 1 y 2** de `plan-paralelizacion-V2.md`: perfil, f, S_max(2), S_max(4) y las
   dependencias del ciclo que domina.

**Criterio de "listo":** tabla con mediana de 5 para cada sección; f calculada en tiempo; S_max(4) escrita;
para el ciclo dominante, lista de variables leídas y escritas con su tipo de dependencia; *commit* en el
repositorio del equipo antes del jueves 29 de octubre a las 10:30 (es el perfilado que pide H1).

**Si tu V1 todavía no corre:** haz las secciones 1 y 2 para `fases.c` con n = 500000 y n = 2000000 (k = 200) y
explica en tres líneas qué cambió en f y por qué (ver `../tarea-espaciada.md`).

## Qué entra en la Práctica 4 y en el proyecto

- Parte D de la Práctica 4 (vence el **domingo 1 de noviembre, 23:59**): la misma disciplina de `medir.sh`
  (5 repeticiones, mediana, `-O2`, T(1) secuencial, región y total).
- H1 (**jueves 29 de octubre, en clase**): sección 1 de la plantilla = perfilado de la V1. Rúbrica en
  `proyecto/hitos/H1-avance-1.md`.
- H2 (**lunes 23 de noviembre, en clase**): secciones 3–5 se convierten en la V2 medida. Rúbrica en
  `proyecto/hitos/H2-avance-2.md`.

## Uso de IA en esta práctica guiada

Verde: pedir que te explique con otras palabras qué es una reducción o por qué el orden de la suma cambia el
redondeo. Amarillo (declarar): pedir que revise tu lista de dependencias y te señale qué se te pudo pasar; tú
verificas con TSan. Rojo: pedirle "el pragma" sin haber escrito antes qué lee y qué escribe cada iteración, o
pedirle que "mejore" tus tiempos. Mini-defensa: cualquier línea de tu código, dos preguntas ("¿qué hace?",
"¿qué pasa si la quito?").
