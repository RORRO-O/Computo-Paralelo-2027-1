> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S08 · lunes 19 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S08 · Planificación y balance de carga en OpenMP

Lectura de apoyo (≤ 2 páginas). Si faltaste, léela, sigue `ejemplo-resuelto.md` y haz `practica-guiada/`.

## 1. El problema: repartir no es lo mismo que balancear

`#pragma omp parallel for` reparte las iteraciones de un ciclo entre los hilos. **Cómo** las reparte lo
decide la **planificación** (*scheduling*). Es el "mapeo" de Foster aplicado a iteraciones: el objetivo es
que todos los hilos terminen al mismo tiempo, porque al final del ciclo hay una **barrera implícita** y el
tiempo del ciclo es el del hilo más lento.

Si todas las iteraciones cuestan lo mismo (carga **uniforme**), cualquier reparto en partes iguales funciona.
Si cuestan distinto (carga **desbalanceada**), repartir el mismo **número** de iteraciones no reparte el mismo
**trabajo**. Tres casos clásicos que usamos hoy:

| Ciclo | Forma de la carga | Dónde está el trabajo |
|---|---|---|
| Triangular: `for i<n: for j<i` | creciente | al final (la iteración i cuesta ~i) |
| Mandelbrot por filas | concentrada | en las filas centrales de la imagen |
| Longitud de la secuencia de Collatz para 1..n | irregular | repartido sin patrón |

## 2. Las políticas: la cláusula `schedule(tipo[, chunk])`

El *chunk* es un bloque de iteraciones consecutivas que se entrega a un hilo como unidad.

| Cláusula | Cómo reparte | Costo en ejecución | Predecible |
|---|---|---|---|
| `schedule(static)` | n/p iteraciones **contiguas** por hilo, decidido antes de empezar | ninguno | sí |
| `schedule(static, c)` | bloques de c iteraciones, repartidos **cíclicamente** (0,1,2,3,0,1,…) | ninguno | sí |
| `schedule(dynamic, c)` | cada hilo **pide** el siguiente bloque de c cuando se desocupa (c = 1 si se omite) | una operación atómica por bloque | no |
| `schedule(guided, c)` | como `dynamic`, pero los bloques **empiezan grandes** (~restantes/p) y **se encogen** hasta c | menos pedidos que `dynamic` | no |
| `schedule(runtime)` | la decide la variable de entorno `OMP_SCHEDULE` (p. ej. `OMP_SCHEDULE="dynamic,16"`) o `omp_set_schedule()` | la de la política elegida | — |
| `schedule(auto)` | la decide el compilador/biblioteca | — | no |

Dos hechos que se verifican en la práctica guiada con `schedule_map`:

- Sin cláusula `schedule`, GCC usa `static`. Con `schedule(runtime)` y **sin** definir `OMP_SCHEDULE`, GCC
  (libgomp) usa `dynamic,1`. Es decisión de la implementación; siempre conviene imprimir `omp_get_schedule()`.
- Para `static`, la especificación fija el reparto, por eso se puede predecir y por eso dos ciclos con el mismo
  `schedule(static)` y el mismo n asignan la iteración i al **mismo hilo** (lo que hace seguro un `nowait`
  entre ellos). Para `dynamic` y `guided` no hay garantía alguna.

Mapa real (n = 16, 4 hilos, costo de la iteración i = i+1 unidades; `OMP_NUM_THREADS=4 ./schedule_map 16 all`):

```
i =               | 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
static            | 0 0 0 0 1 1 1 1 2 2 2 2 3 3 3 3 | iters:  4  4  4  4 | trabajo:  10  26  42  58
static,2          | 0 0 1 1 2 2 3 3 0 0 1 1 2 2 3 3 | iters:  4  4  4  4 | trabajo:  22  30  38  46
dynamic           | 1 3 2 0 1 3 2 0 1 3 2 0 1 3 2 0 | iters:  4  4  4  4 | trabajo:  40  28  36  32
dynamic,2         | 3 3 2 2 1 1 0 0 3 3 2 2 1 1 0 0 | iters:  4  4  4  4 | trabajo:  46  38  30  22
guided            | 0 0 0 0 1 1 1 3 3 3 2 2 0 1 2 0 | iters:  6  4  3  3 | trabajo:  39  32  38  27
runtime=dynamic,1 | 1 0 3 2 1 0 3 2 1 0 3 2 1 0 3 2 | iters:  4  4  4  4 | trabajo:  32  28  40  36
```

Las filas `static` son idénticas en cada corrida; las de `dynamic`, `guided` y `runtime` cambian de una
corrida a otra (dependen de qué hilo se desocupa primero). Observa la columna **trabajo**: con `static` el
hilo 3 hace 58 unidades y el hilo 0 solo 10; con `static,2` la diferencia baja a 46 contra 22; las políticas
dinámicas la reducen más.

## 3. El costo del *chunk* pequeño

Pedir un bloque cuesta: un incremento atómico sobre un contador compartido por todos los hilos (decenas de
nanosegundos, más si hay competencia). Si el trabajo de un bloque es del mismo orden, el ciclo se vuelve
**más lento que secuencial**. Tabla real con 4 hilos, carga uniforme (8 000 000 iteraciones de ~50 ns):

Secuencial (referencia): mediana **0.4454 s** (mín 0.4057  máx 0.4544); n = 8 000 000  4 hilos  mediana de 5 repeticiones tras 1 calentamiento.

| Política | Mediana (s) | Mín (s) | Máx (s) | *Speedup* | Eficiencia | Verif. |
|---|---|---|---|---|---|---|
| `static` | 0.3681 | 0.3391 | 0.4298 | 1.21 | 0.30 | OK |
| `dynamic,1` | 0.7537 | 0.6016 | 0.9075 | 0.59 | 0.15 | OK |
| `dynamic,16` | 0.2450 | 0.2339 | 0.2505 | 1.82 | 0.46 | OK |
| `dynamic,256` | 0.2122 | 0.1905 | 0.2189 | 2.10 | 0.53 | OK |
| `dynamic,4096` | 0.2163 | 0.2058 | 0.2322 | 2.06 | 0.52 | OK |
| `dynamic,65536` | 0.2332 | 0.2178 | 0.2693 | 1.91 | 0.48 | OK |

Y con carga triangular (n = 40 000; la iteración i hace i divisiones):

Secuencial (referencia): mediana **1.0554 s** (mín 1.0246  máx 1.1016); n = 40 000  4 hilos  mediana de 5 repeticiones tras 1 calentamiento.

| Política | Mediana (s) | Mín (s) | Máx (s) | *Speedup* | Eficiencia | Verif. |
|---|---|---|---|---|---|---|
| `dynamic,1` | 0.5400 | 0.5320 | 0.5859 | 1.95 | 0.49 | OK |
| `dynamic,4` | 0.5695 | 0.5114 | 0.7221 | 1.85 | 0.46 | OK |
| `dynamic,16` | 0.5385 | 0.5088 | 0.5699 | 1.96 | 0.49 | OK |
| `dynamic,64` | 0.5564 | 0.5115 | 0.5994 | 1.90 | 0.47 | OK |
| `dynamic,256` | 0.5212 | 0.4885 | 0.5725 | 2.02 | 0.51 | OK |
| `dynamic,1024` | 0.5574 | 0.5361 | 0.6574 | 1.89 | 0.47 | OK |
| `dynamic,4096` | 0.7003 | 0.6123 | 0.9654 | 1.51 | 0.38 | OK |

(Las dos tablas se midieron con la máquina compartida con otros procesos; por eso algunos *speedups* quedan
por debajo de 1. El orden entre *chunks* es lo que se lee. Regenéralas en una máquina libre con los comandos
de la fase Investigar de la práctica.)

Lectura: el *chunk* se elige para que el trabajo de un bloque sea **mucho mayor** que el costo de pedirlo,
pero lo bastante pequeño para que al final del ciclo no quede un hilo con un bloque gigante mientras los
demás esperan. Un buen punto de partida es n / (p × 10 a 100).

## 4. Tabla de referencia: tiempos por política (4 hilos, mediana de 5)

Máquina de autoría: 4 núcleos Intel Xeon a 2.8 GHz, gcc 13.3, `-O2`, `OMP_NUM_THREADS=4`. Mediana de 5 repeticiones tras 1 calentamiento; *speedup* contra la versión secuencial del mismo binario. **Advertencia:** estas corridas se hicieron con la máquina compartida con otros procesos (carga promedio de 9 a 18 en 4 núcleos), así que los tiempos absolutos y los *speedups* están contaminados (varios quedan por debajo de 1). Lo que sí se conserva es el **orden relativo** entre políticas dentro de cada fila. Antes de proyectar esta tabla en clase, regenérala con `make tabla` en una máquina con `uptime` < 1 y sustitúyela.

| Núcleo (n) | T secuencial (s) | `static` | `static,1` | `dynamic` (=1) | `dynamic,c` | `guided,c` |
|---|---|---|---|---|---|---|
| `uniform` (8 000 000) | 0.563 | 0.769 s · S=0.73 | 0.898 s · S=0.63 | 1.294 s · S=0.44 | 0.492 s · S=1.15 (`dynamic,1024`) | 0.484 s · S=1.16 (`guided,64`) |
| `triangular` (40 000) | 1.057 | 0.877 s · S=1.20 | 0.810 s · S=1.30 | 0.721 s · S=1.47 | 0.750 s · S=1.41 (`dynamic,16`) | 0.782 s · S=1.35 (`guided,16`) |
| `collatz` (2 000 000) | 0.568 | 0.390 s · S=1.46 | 0.459 s · S=1.24 | 0.496 s · S=1.14 | 0.280 s · S=2.03 (`dynamic,256`) | 0.305 s · S=1.86 (`guided,64`) |
| `mandelbrot` (1000 × 1000) | 0.406 | 0.424 s · S=0.96 | 0.331 s · S=1.22 | 0.319 s · S=1.27 | 0.313 s · S=1.30 (`dynamic,4`) | 0.376 s · S=1.08 (`guided,4`) |

(`static,64` en triangular: 0.579 s · S=1.83.)

## 5. Regla práctica de elección

1. **Carga uniforme → `static`.** No paga nada y respeta la localidad de caché (iteraciones contiguas).
2. **Carga creciente o decreciente (triangular) → `static, c` pequeño** ya la balancea bien y sigue siendo
   predecible; `dynamic, c` con *chunk* razonable da lo mismo o un poco más.
3. **Carga concentrada o impredecible (Mandelbrot, archivos de tamaño variable) → `dynamic, c`** con *chunk*
   pequeño (que cada hilo tome muchos bloques).
4. **`guided`** cuando el ciclo es largo, el desbalance es moderado y quieres menos pedidos que `dynamic`;
   cuidado si el trabajo pesado está en los **primeros** bloques, que son los grandes.
5. **Nunca** `dynamic` sin *chunk* en un ciclo de iteraciones baratas.
6. **Mide.** La regla te da el punto de partida; el protocolo de medición decide. Cuando no estés seguro,
   deja `schedule(runtime)` y prueba con `OMP_SCHEDULE` sin recompilar.

## 6. `collapse(2)`: más iteraciones que repartir

```c
#pragma omp parallel for collapse(2) schedule(static)
for (int i = 0; i < rows; i++)
    for (int j = 0; j < cols; j++)
        cell(i, j);
```

`collapse(2)` fusiona los dos ciclos en un solo espacio de `rows × cols` iteraciones y reparte **ese**
espacio. Sirve cuando el ciclo externo tiene pocas iteraciones (menos que hilos, o no múltiplo de ellos).
Mapa real con 3 filas × 6 columnas y 4 hilos (`./collapse_map 3 6`): sin `collapse` el hilo 3 **no recibe
nada** (solo hay 3 filas que repartir); con `collapse(2)` las 18 celdas se reparten 5, 5, 4, 4. Requisitos:
los ciclos deben estar perfectamente anidados (nada entre los `for`) y los límites del interno no pueden
depender de variables modificadas dentro. Que el límite dependa de `i` (`j < i`, ciclo triangular) lo permite
OpenMP 5.0 ("ciclos no rectangulares"); gcc 13 lo compila y reparte bien (verificado), pero compiladores
anteriores a gcc 11 lo rechazan: si cambias de máquina, compila primero.

## 7. Errores frecuentes

| Error | Qué pasa | Cómo se ve |
|---|---|---|
| `schedule(dynamic)` "por si acaso" en un ciclo barato (idea errónea 11) | miles de pedidos atómicos; más lento que secuencial | `uniform` con `dynamic` en la tabla |
| Creer que al final del `omp for` no hay barrera (idea 12) | se intenta "optimizar" con `nowait` y aparece una carrera | `nowait_buggy.c` con `dynamic`: `b[i]` mal **a veces**; TSan señala `a[i] = i` contra `b[i] = 2 * a[i]` |
| Tomar todo reporte de ThreadSanitizer como carrera real | la libgomp de Ubuntu no está instrumentada: TSan no ve la barrera del final de la región | el reporte que toca código **fuera** de la región paralela (el ciclo de verificación) sale también con `static`: es falso |
| Comparar contra la versión paralela con 1 hilo | el *speedup* se infla | el protocolo exige el mejor secuencial |
| Medir una vez o con la máquina ocupada (idea 5) | tiempos todos parecidos o invertidos | mínimo y máximo muy separados; revisa `uptime` |
| Medir con `REPS` altas y n grande "para que sea exacto" | esperas minutos y el ruido no baja | el protocolo pide 5 repeticiones y mediana |
| Elegir el *chunk* al azar | o sobrecarga o cola final larga | barre 1, 16, 256, 4096 y compara |
| Función de medición "optimizada" por el compilador | la versión secuencial marca 0.0000 s | GCC elimina llamadas repetidas a funciones sin efectos secundarios; en `unbalanced.c` el puntero a función es `volatile` por eso |

## 8. Para saber más

- OpenMP Architecture Review Board, *OpenMP Application Programming Interface*, versión 5.2 (2021):
  secciones *Worksharing-Loop Construct* (cláusula `schedule`, cláusula `collapse`), *`nowait` Clause* y
  *`OMP_SCHEDULE`*. <https://www.openmp.org/specifications/>
- GCC, *GNU Offloading and Multi Processing Runtime Library (libgomp)*: `OMP_SCHEDULE`, `omp_set_schedule`,
  `omp_get_schedule`. <https://gcc.gnu.org/onlinedocs/libgomp/>
- P. Pacheco y M. Malensek, *An Introduction to Parallel Programming*, 2.ª ed., Morgan Kaufmann, 2022,
  capítulo 5 (OpenMP), sección sobre planificación de ciclos (*scheduling loops*).
