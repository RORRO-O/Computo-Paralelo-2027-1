> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S08 · lunes 19 de octubre de 2026 · 10:30–12:00 · Salón 3208

# Práctica guiada S08 · ¿Qué hilo ejecuta qué iteración y cuánto tarda?

Actividad PRIMM en parejas (conductor/navegante; cambio de rol a los 15 minutos). Tiempo en clase: 30 minutos
(fases 1–4) + 10 minutos de transferencia (fase 5). Todo lo que anotes va en una hoja con los dos números de
lista; la entregas con el *exit ticket*.

## Archivos

| Archivo | Qué hace |
|---|---|
| `schedule_map.c` | Imprime el mapa `owner[i]` (hilo que ejecutó cada iteración) para `static`, `static,c`, `dynamic,c`, `guided,c` y `runtime` |
| `collapse_map.c` | Mapa de un ciclo doble filas × columnas, con y sin `collapse(2)` |
| `unbalanced.c` | Mide con el protocolo del curso cuatro ciclos (`uniform`, `triangular`, `collatz`, `mandelbrot`) bajo las políticas que le pidas; verifica contra la versión secuencial |
| `nowait_buggy.c` | Carrera de datos **a propósito**: `nowait` entre dos ciclos dependientes, con `static` (seguro) y con `dynamic` (carrera) |
| `Makefile` | `make`, `make run`, `make test`, `make tabla`, `make tsan`, `make clean` |
| `tests/run_tests.sh` | Verificación automática (`make test` debe terminar en `0 FAIL`) |

Compila con `make` (banderas del curso: `gcc -std=c11 -O2 -Wall -Wextra -fopenmp`). Si tu máquina tiene otro
número de núcleos, usa `OMP_NUM_THREADS=4` de todos modos para que las predicciones coincidan.

Antes de medir cualquier cosa: `uptime`. Si la carga promedio es mayor que 1, hay otros procesos usando los
núcleos y tus tiempos no sirven (idea errónea 5: "medir una vez basta").

---

## Fase 1 · Predecir (8 min, sin ejecutar nada)

El ciclo es `for (int i = 0; i < 16; i++) owner[i] = omp_get_thread_num();` con **4 hilos**. Llena la tabla
de rastreo con el número de hilo que crees que ejecuta cada iteración. Si crees que no se puede saber,
escribe `?` y explica por qué.

| i → | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `schedule(static)` | | | | | | | | | | | | | | | | |
| `schedule(static, 2)` | | | | | | | | | | | | | | | | |
| `schedule(static, 5)` | | | | | | | | | | | | | | | | |
| `schedule(dynamic)` | | | | | | | | | | | | | | | | |
| `schedule(guided)` | | | | | | | | | | | | | | | | |

Contesta por escrito:

- **P1.** Si la iteración i cuesta i+1 unidades de trabajo (como el ciclo triangular), ¿cuántas unidades hace cada
  hilo con `static`? ¿Y con `static,2`? ¿Qué hilo termina al último en cada caso? ____
- **P2.** Con `schedule(runtime)` y **sin** definir `OMP_SCHEDULE`, ¿qué política crees que usa GCC? ____
- **P3.** Un ciclo doble de 3 filas × 6 columnas con 4 hilos. Sin `collapse`, ¿cuántos hilos se quedan sin
  trabajo? Con `collapse(2)` y `static`, ¿cuántas celdas recibe cada hilo? ____
- **P4.** Para el ciclo triangular con n = 40 000 y 4 hilos, ordena de más rápida a más lenta: `static`,
  `static,1`, `dynamic,16`. Escribe una razón de una línea. ____

## Fase 2 · Ejecutar (5 min)

```bash
make
OMP_NUM_THREADS=4 ./schedule_map 16 all
OMP_NUM_THREADS=4 ./schedule_map 16 static 5 uniform
OMP_NUM_THREADS=4 ./schedule_map 16 guided
OMP_NUM_THREADS=4 OMP_SCHEDULE="guided,2" ./schedule_map 16 runtime
OMP_NUM_THREADS=4 ./collapse_map 3 6
```

Marca en tu tabla ✓ o ✗ por fila. Luego:

- Corre `OMP_NUM_THREADS=4 ./schedule_map 16 dynamic` **tres veces**. ¿Cambia el mapa? ¿Cambia la fila
  `static` si la corres tres veces? Anota qué es determinista y qué no.
- Compara la columna `trabajo:` de `static` y `static,2` con tu P1.
- La fila `runtime=…` te dice la política real. Compárala con tu P2.

## Fase 3 · Investigar (10 min; I1, I3 e I5 son obligatorios, I2 e I4 si alcanza el tiempo)

- **I1. ¿Dónde se decide la política?** Abre `schedule_map.c`. Localiza las funciones `run_static`,
  `run_dynamic`, `run_guided` y `run_runtime`. ¿Por qué hay **dos** `#pragma` en cada una de las tres
  primeras? ¿Qué pasaría si escribieras `schedule(static, chunk)` con `chunk == 0`?
- **I2. Cómo se encoge `guided`.** Corre `OMP_NUM_THREADS=4 ./schedule_map 32 guided 0 uniform` y mide la
  longitud de cada tramo de iteraciones consecutivas del mismo hilo. Escribe la secuencia de tamaños (si un
  mismo hilo toma dos bloques seguidos verás un tramo más largo: es la suma de dos). ¿Qué relación tiene cada
  tamaño con las iteraciones que faltan y el número de hilos?
- **I3. El costo del *chunk*.** Corre:
  ```bash
  OMP_NUM_THREADS=4 ./unbalanced uniform 8000000 static dynamic,1 dynamic,16 dynamic,256 dynamic,4096
  ```
  Todas las iteraciones cuestan lo mismo. (a) ¿Qué política queda **más lenta que la secuencial**? (b) ¿A
  partir de qué *chunk* `dynamic` alcanza a `static`? (c) Estima el costo de pedir un *chunk*:
  `(T_dynamic,1 − T_static) × 4 hilos / 8 000 000 pedidos`. ¿Cuántos nanosegundos te da? Compáralo con los
  ~50 ns que cuesta una iteración.
- **I4. Verificación con tolerancia.** En `unbalanced.c`, busca `reduction(+ : acc)` y la línea con `1e-9`.
  ¿Por qué no se compara con `==`? ¿En cuál de los cuatro núcleos **sí** sería seguro comparar con `==`?
- **I5. `nowait` y la evidencia.** Corre tres veces cada uno:
  ```bash
  OMP_NUM_THREADS=4 ./nowait_buggy 2000 static
  OMP_NUM_THREADS=4 ./nowait_buggy 2000 dynamic
  make tsan
  ```
  (a) ¿Por qué con `static` siempre salen 0 incorrectas? Busca en `nowait_buggy.c` el comentario que lo
  explica y escribe la garantía con tus palabras. (b) Con `dynamic`, ¿cuántas salen mal? Si en alguna corrida
  salieran 0, ¿estaría correcto el programa? (c) `make tsan` imprime dos o tres reportes con `dynamic`. En el
  primero, ¿qué dos líneas del archivo señala como la lectura y la escritura en conflicto? Abre el archivo y
  di qué instrucción hay en cada una. (d) Los reportes restantes involucran la línea del ciclo de verificación
  (`if (b[i] != 2 * i)`) y, a veces, el `free(a)` final: código que corre **fuera** de la región paralela. El
  del ciclo de verificación aparece también si corres la variante `static` bajo TSan. ¿Puede ser una carrera
  real si la región paralela ya terminó? (Pista: la libgomp de Ubuntu no está instrumentada y TSan no ve la
  barrera del final de la región.) ¿Cómo distinguirías, en general, un reporte real de uno falso?

## Fase 4 · Modificar (7 min; cada cambio tiene un objetivo verificable)

- **M1. Repara la carrera sin cambiar la política.** En `nowait_buggy.c`, variante `dynamic`, quita el
  `nowait` del primer ciclo. Recompila (`make nowait_buggy`). Objetivo: `./nowait_buggy 2000 dynamic`
  reporta `0 de 2000` en 5 corridas seguidas y el primer reporte de `make tsan` (el de `a[i] = i` contra
  `b[i] = 2 * a[i]`) desaparece; los del ciclo de verificación y de `free` seguirán ahí porque son falsos. Después vuelve a
  poner el `nowait` (o `git checkout nowait_buggy.c`).
- **M2. Vuelve uniforme el ciclo triangular.** En `unbalanced.c`, función `triangular_item`, cambia
  `j < i` por `j < 20000` (todas las iteraciones hacen el mismo número de divisiones). Recompila y corre
  `OMP_NUM_THREADS=4 ./unbalanced triangular 40000 static static,1 dynamic,16`. Objetivo: anotar la nueva
  tabla y explicar en una línea por qué el orden de las políticas cambió respecto a tu P4. Después revierte
  el cambio y comprueba con `make test` que todo sigue en `0 FAIL`.
- **M3. Predice `collapse` con otras dimensiones.** Antes de correr, escribe para `./collapse_map 4 4` y
  `./collapse_map 5 3`: hilos sin trabajo en A (sin `collapse`) y celdas por hilo en B (`collapse(2)` +
  `static`). Objetivo: acertar las dos predicciones de B (es `static`: se puede).

## Fase 5 · Crear (10 min en clase; se termina en casa como ejercicio 1 de `tarea-espaciada.md`)

**Caso nuevo: contar primos por división de prueba.** La iteración i decide si i es primo probando divisores
desde 2 hasta √i. Un primo cuesta ~√i divisiones; un número par cuesta 1. La carga es **irregular y
creciente** a la vez.

1. **Predice por escrito** (antes de programar): ¿qué política y qué *chunk* usarías para n = 2 000 000 con
   4 hilos, y por qué? ¿Qué *speedup* esperas respecto a la secuencial?
2. Agrega a `unbalanced.c` un quinto núcleo `primes`: un valor `K_PRIMES` en `enum kernel_id`, una función
   `static inline double primes_item(long i)` que devuelva 1.0 si i es primo y 0.0 si no (trata 0 y 1 como no
   primos), su caso en `item()` y su nombre en `main()` con un tamaño por defecto. **No toques** `run_seq`,
   `run_par` ni `timed`: deben servir sin cambios.
3. Mide con el protocolo: `OMP_NUM_THREADS=4 ./unbalanced primes 2000000 static static,1 dynamic,64 guided,64`
   y al menos una política más que tú elijas.
4. Escribe 3 líneas: política elegida, por qué (forma de la carga + costo por *chunk*), y si tu predicción
   de *speedup* se cumplió.

**Criterio de "listo":** compila con `make` sin *warnings*; `make test` sigue en `0 FAIL`; las cinco o más
políticas de tu tabla dicen `OK` en la columna `verif`; la justificación nombra la forma de la carga y el
costo del *chunk*; la predicción está escrita **antes** de la tabla.

**Ampliación (si terminas antes):** haz que `primes_item` reciba también `n` y recorra el rango al revés
(`n − 1 − i`), de modo que las iteraciones caras queden al **principio**. ¿Qué política se vuelve mejor y por
qué `guided` lo agradece?

---

## Uso de IA en esta práctica

🟢 Pedirle que te explique con otras palabras qué hace `guided` o por qué el reparto de `static,c` es
cíclico. 🟡 Pedirle un borrador de `primes_item` (≤ 10 líneas): lo reescribes, lo explicas y lo declaras.
🔴 Pegar el README y entregar la tabla que salga: las mediciones son tuyas o no son.
