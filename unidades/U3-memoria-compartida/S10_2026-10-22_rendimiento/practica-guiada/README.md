> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S10 · jueves 22 de octubre de 2026 · 10:30–12:00 · Salón 3208

# Práctica guiada S10 · Medir sin engañarse: falso compartido, sobrecarga y escalabilidad

Actividad PRIMM en parejas (conductor/navegante; cambio de rol a los 15 minutos). Es la tercera sesión de
contenido de la unidad, así que Predecir e Investigar son cortas y Crear tiene ≥ 10 minutos. Dura 30 minutos en
clase más 10 de transferencia. Es autocontenida: solo necesitas `gcc` con OpenMP, `make` y `python3` con
`matplotlib` (para la gráfica; sin él, todo lo demás funciona).

## Qué hay en esta carpeta

| Archivo | Qué mide | Idea errónea que expone |
|---|---|---|
| `false_sharing.c` | Contadores por hilo en arreglo contiguo vs. con relleno a 64 bytes vs. variable local | 14 (falso compartido), 1 |
| `profile_amdahl.c` | Perfil por secciones con `omp_get_wtime()`, `f` medida, Amdahl, Karp–Flatt, `clock()` vs. pared (es el `../ejemplo-resuelto.md`) | 2, 31 |
| `region_overhead.c` | Una región paralela por iteración vs. una sola región; costo por región y por barrera | 1 |
| `saxpy_vs_matmul.c` | Un núcleo limitado por memoria y uno limitado por cómputo con los mismos hilos | 1, 3 |
| `weak_scaling.c` | Escalabilidad fuerte (`n` fijo) y débil (`n/p` fijo) con el mismo núcleo | 6 |
| `common.h` | Reloj, mediana, generador determinista, `csv_append()` (CSV del protocolo), `report_row()` | 5 |
| `graficar.py` | *Speedup* vs. hilos con la línea ideal `S = p` a partir del CSV; imprime la tabla Markdown con Karp–Flatt | — |
| `Makefile` | `all`, `run`, `test`, `clean`, `medir` (barrido 1 2 4 → CSV), `grafica`, `afinidad` | — |
| `tests/run_tests.sh` | Cada programa contra su propia versión secuencial; formato del CSV; `graficar.py` | — |

Todos los programas aceptan el tamaño por línea de comandos (`./false_sharing [n] [csv]`,
`./profile_amdahl [n] [iters] [csv]`, `./region_overhead [n] [k]`, `./saxpy_vs_matmul [n_saxpy] [n_matmul] [csv]`,
`./weak_scaling [n_por_hilo] [csv]`), miden su propia referencia secuencial en el mismo proceso, aplican el
protocolo (1 calentamiento + 5 repeticiones, mediana, mín y máx) e imprimen una línea `RESULT … status=OK` si
el resultado paralelo coincide con el secuencial. Los hilos se controlan con `OMP_NUM_THREADS`. El `Makefile`
fija además `OMP_PROC_BIND=close OMP_PLACES=cores` (un hilo por núcleo físico; variable `BIND`): es la
configuración que el curso **declara** en todo reporte, para que una medición se pueda repetir (`make afinidad`
muestra qué cambia y qué no). Los tamaños
por defecto están **reducidos** para caber en la sesión (la secuencial tarda 0.1–0.3 s); el protocolo pide
≥ 1 s para un reporte, y eso es lo que hace la tarea.

## Fase 1 · Predecir (3 min, por escrito, antes de compilar)

Lee `false_sharing.c` (las dos funciones `count_shared` y `count_local`) y el encabezado de los demás archivos.
Anota en `predicciones.md`:

| # | Pregunta | Tu predicción |
|---|---|---|
| P1 | `false_sharing` con 4 hilos: ordena `contiguo`, `relleno` y `local` de más rápido a más lento. ¿Cuántas veces más lento será `contiguo` que `relleno`? (las tres variantes hacen exactamente las mismas operaciones) | |
| P2 | `region_overhead 2000 20000` (2000 elementos, 20 000 pasadas) con 4 hilos: ¿alguna versión paralela le gana a la secuencial? ¿Cuál? | |
| P3 | `saxpy_vs_matmul` con 4 hilos: ¿cuál de los dos núcleos tendrá mejor eficiencia y por qué? (pista: flop por byte) | |
| P4 | `weak_scaling` con 4 hilos: la eficiencia débil `E_w = T(1,n)/T(4,4n)`, ¿estará cerca de 1 o lejos? ¿Qué la haría caer, si el núcleo no tiene parte secuencial? | |

No corrijas tus predicciones después. El valor está en comparar.

## Fase 2 · Ejecutar (8 min)

```bash
make                 # compila con -std=c11 -O2 -Wall -Wextra -fopenmp (sin warnings)
make run             # los cinco programas con 4 hilos y afinidad (THREADS=4 por defecto)
make medir           # protocolo: barrido 1 2 4 hilos -> resultados/*.csv (unos 40 s)
make grafica         # un PNG por CSV con la linea ideal + tabla Markdown con Karp-Flatt
```

Salida real de `false_sharing` con 4 hilos en la máquina de autoría (máquina virtual con 4 vCPU; la tuya dará
otros números, el orden debe repetirse):

```
== falso compartido: n=100000000 hilos=4  casillas por hilo=2  linea de cache=64 B
  secuencial   hilos=1  mediana=0.1144 s  (min 0.1136, max 0.1204)  cuentas=50000001/49999999
  contiguo     hilos=4  mediana=0.0488 s  (min 0.0481, max 0.0505)  speedup=2.34  eficiencia=0.59  ok
  relleno      hilos=4  mediana=0.0318 s  (min 0.0314, max 0.0339)  speedup=3.60  eficiencia=0.90  ok
  local        hilos=4  mediana=0.0325 s  (min 0.0297, max 0.0357)  speedup=3.52  eficiencia=0.88  ok
  bytes por hilo: contiguo=16  relleno=64  -> hilos por linea de 64 B: contiguo=4  relleno=1
```

Y el barrido completo (`make medir` + `make grafica`), en la tabla que imprime `graficar.py`:

| config | hilos | n | mediana (s) | speedup | eficiencia | Karp–Flatt f |
|---|---|---|---|---|---|---|
| secuencial | 1 | 100000000 | 0.1178 | 1.00 | 1.00 | — |
| contiguo | 1 | 100000000 | 0.1238 | 0.95 | 0.95 | — |
| contiguo | 2 | 100000000 | 0.0905 | 1.37 | 0.69 | 0.457 |
| contiguo | 4 | 100000000 | 0.0524 | 2.17 | 0.54 | 0.280 |
| relleno | 1 | 100000000 | 0.1254 | 0.94 | 0.94 | — |
| relleno | 2 | 100000000 | 0.0588 | 2.11 | 1.06 | -0.054 |
| relleno | 4 | 100000000 | 0.0325 | 3.50 | 0.88 | 0.047 |
| local | 1 | 100000000 | 0.1144 | 1.03 | 1.03 | — |
| local | 2 | 100000000 | 0.0605 | 2.06 | 1.03 | -0.027 |
| local | 4 | 100000000 | 0.0320 | 3.56 | 0.89 | 0.041 |

Compara con P1. Las tres variantes dan el mismo resultado (`ok`) y hacen las mismas operaciones; solo cambia en qué
bytes vive cada contador. `contiguo` tardó 1.5 veces más que `relleno` con 4 hilos aquí (en la revisión, en la
misma máquina, entre 1.5 y 1.8 veces); en una laptop sin virtualización la diferencia suele ser mayor. Ojo: cada
programa divide entre la secuencial que midió **en su propio proceso**, así que la `mediana` de la fila
`secuencial` (la de la corrida con 1 hilo) no es exactamente el denominador de las filas con 2 y 4 hilos.

Salida real de `region_overhead` con 4 hilos, caso de pasadas cortas:

```
== sobrecarga de regiones: n=2000 elementos, k=20000 pasadas, hilos=4  (40000000 operaciones en total)
  secuencial   hilos=1  mediana=0.0130 s  (min 0.0129, max 0.0136)
  regiones     hilos=4  mediana=0.0768 s  (min 0.0645, max 0.1717)  speedup=0.17  eficiencia=0.04  ok
  una-region   hilos=4  mediana=0.0465 s  (min 0.0304, max 0.1108)  speedup=0.28  eficiencia=0.07  ok
  sin-barrera  hilos=4  mediana=0.0107 s  (min 0.0101, max 0.0107)  speedup=1.22  eficiencia=0.30  ok
  costo estimado por pasada: region paralela ~ 3.3 us, barrera ~ 1.8 us  (diferencias contra sin-barrera, entre k=20000)
```

Compara con P2. Con 2000 elementos por pasada, abrir una región (~3.3 µs) o pasar una barrera
(~1.8 µs) cuesta más que el trabajo de la pasada. La única versión que gana es la que no sincroniza en
cada pasada. Con `2000000 20` (mismo total de operaciones, pasadas largas) el panorama cambia:

```
== sobrecarga de regiones: n=2000000 elementos, k=20 pasadas, hilos=4  (40000000 operaciones en total)
  secuencial   hilos=1  mediana=0.0286 s  (min 0.0195, max 0.0291)
  regiones     hilos=4  mediana=0.0068 s  (min 0.0062, max 0.0169)  speedup=4.21  eficiencia=1.05  ok
  una-region   hilos=4  mediana=0.0074 s  (min 0.0068, max 0.0081)  speedup=3.85  eficiencia=0.96  ok
  sin-barrera  hilos=4  mediana=0.0067 s  (min 0.0063, max 0.0083)  speedup=4.27  eficiencia=1.07  ok
  (estimacion por pasada omitida: con k=20 el ruido de una pasada domina; usa k >= 1000)
```

(Eficiencias de 1.05–1.07 no son *speedup* superlineal: la secuencial de esa corrida tuvo mín 0.0195 s y mediana
0.0286 s, es decir, su propia mediana salió inflada por el ruido de la máquina virtual; contra el mínimo, los
*speedups* serían ≈ 2.6–2.9. Se reporta tal cual y se dice; idea errónea 4 al revés. En la revisión, con otros
procesos usando los núcleos, una corrida dio 1.4–2.6× y otra, más cargada, dejó `regiones` y `una-region` por
debajo de 1: con pasadas cortas o largas, una máquina ocupada invalida la medición, protocolo §1.5.)

Salida real de `saxpy_vs_matmul` y de `weak_scaling` (barrido `make medir`, tabla de `graficar.py`):

| config | hilos | n | mediana (s) | speedup | eficiencia | Karp–Flatt f |
|---|---|---|---|---|---|---|
| saxpy-seq | 1 | 10000000 | 0.1754 | 1.00 | 1.00 | — |
| saxpy | 1 | 10000000 | 0.1820 | 0.96 | 0.96 | — |
| saxpy | 2 | 10000000 | 0.0936 | 2.06 | 1.03 | -0.031 |
| saxpy | 4 | 10000000 | 0.0616 | 3.06 | 0.77 | 0.102 |
| matmul-seq | 1 | 640 | 0.1566 | 1.00 | 1.00 | — |
| matmul | 1 | 640 | 0.1990 | 0.79 | 0.79 | — |
| matmul | 2 | 640 | 0.0834 | 1.80 | 0.90 | 0.114 |
| matmul | 4 | 640 | 0.0537 | 2.87 | 0.72 | 0.131 |

Compara con P3. Aquí hay una sorpresa que depende de la máquina: en la de autoría `saxpy` escaló igual o mejor
que `matmul`, con `n = 10^7` y también con `n = 5·10^7` (800 MB, fuera de cualquier caché): `S(2) = 1.81` y `S(4) = 2.90` (eficiencia 0.72), con 10.9, 25.6 y 40.5 GB/s para 1, 2 y 4 hilos, frente a `S(4) = 3.06` con `n = 10^7`. El
ancho de banda alcanzado siguió creciendo con los hilos: el anfitrión es un servidor con memoria de muchos
canales y cuatro núcleos no bastan para saturarla. En una laptop (dos canales, 20–40 GB/s en total) `saxpy` suele
dejar de escalar a partir de 2 hilos mientras `matmul` sigue; M3 lo comprueba en la tuya. La lección no es
"`saxpy` no escala", sino: un núcleo de 0.083 flop/byte escala **hasta donde llega el ancho de banda de esa
máquina**, y por eso el reporte lleva los GB/s alcanzados y el hardware, no solo el *speedup*.

| config | hilos | n | mediana (s) | speedup | eficiencia | Karp–Flatt f |
|---|---|---|---|---|---|---|
| secuencial | 1 | 1000000 | 0.1076 | 1.00 | 1.00 | — |
| fuerte | 1 | 1000000 | 0.1095 | 0.98 | 0.98 | — |
| fuerte | 2 | 1000000 | 0.0605 | 1.90 | 0.95 | 0.053 |
| fuerte | 4 | 1000000 | 0.0296 | 3.66 | 0.92 | 0.031 |
| debil | 1 | 1000000 | 0.1134 | 0.95 | 0.95 | — |
| debil | 2 | 2000000 | 0.1056 | 2.18 | 1.09 | -0.081 |
| debil | 4 | 4000000 | 0.1306 | 3.32 | 0.83 | 0.068 |

Compara con P4: `fuerte` es el *speedup* clásico (mismo `n`); en `debil` la columna `n` crece con los hilos y el
"speedup" es el escalado de Gustafson (`p · E_w`). Llena tu propia tabla (la imprime `make grafica`):

| Experimento | config | S(2) | S(4) | E(4) | `f` Karp–Flatt (4) | ¿Coincidió con tu predicción? |
|---|---|---|---|---|---|---|
| falso compartido | contiguo / relleno / local | | | | | |
| Amdahl | total / seccionB | | | | | |
| memoria vs. cómputo | saxpy / matmul | | | | | |
| escalabilidad | fuerte / debil | | | | | |

## Fase 3 · Investigar (6 min)

1. `false_sharing.c`, función `count_shared`: la única diferencia entre `contiguo` y `relleno` es el valor de
   `stride` (2 u 8 `long`). Con 4 hilos y `stride = 2`, ¿cuántos bytes separan la casilla del hilo 0 de la del hilo
   3? ¿Caben los cuatro pares de casillas en una línea de 64 bytes? ¿Y con `stride = 8`?
2. Misma función: `mine[bin_of(i)]++` lee y escribe memoria **compartida** en cada iteración aunque nadie más
   toque esa casilla. ¿Por qué la variante `local` evita el problema sin relleno? ¿Cuántas escrituras al arreglo
   compartido hace cada hilo en `local`?
3. `main` reserva `counts` con `aligned_alloc(CACHE_LINE, …)`. Si usaras `malloc` (en x86-64 solo garantiza
   16 B de alineación), ¿seguiría garantizado que el bloque de 64 B de cada hilo coincide con una línea? ¿Y si
   cada hilo tuviera 8 casillas en lugar de 2? (pista: ¿dónde empieza la primera casilla?)
4. `region_overhead.c`, versión `sin-barrera`: lleva `schedule(static) nowait` y aun así es correcta. Lee el
   comentario del encabezado: ¿qué garantiza OpenMP sobre `schedule(static)` que lo hace seguro? ¿Qué pasaría
   con `schedule(dynamic) nowait`?
5. `saxpy_vs_matmul`: anota los GB/s de `saxpy` con 1, 2 y 4 hilos y los GFLOP/s de `matmul`. ¿Alguno de los dos
   deja de crecer en tu máquina? Si los GB/s se estancan, ¿qué recurso se saturó? Si no se estancan (como en la
   máquina de autoría), ¿qué te dice eso de la memoria de tu máquina frente a sus núcleos?
6. Abre `resultados/weak_scaling.csv`. En las filas `debil`, la columna `n` cambia con los hilos. ¿Qué regla del
   protocolo (§5) obliga a declararlo, y qué significa la columna `speedup` en esas filas (lee el encabezado de
   `weak_scaling.c`)?

<details><summary>Respuestas de Investigar (ábrelas después de discutir con tu pareja)</summary>

1. Con `stride = 2` las casillas del hilo 3 empiezan en el byte 48 y terminan en el 63: las ocho casillas
   (4 hilos × 2) ocupan exactamente una línea de 64 B. Con `stride = 8` cada hilo empieza en un múltiplo de 64:
   una línea por hilo.
2. En `local` el `++` va a una variable de la pila del hilo, que ningún otro núcleo toca; cada hilo escribe en
   el arreglo compartido **dos** veces en total (sus dos casillas, al final), no una vez por iteración.
3. No: con `malloc` el bloque puede empezar a mitad de una línea y el bloque de 64 B de cada hilo queda partido
   entre dos líneas. Con 2 casillas (16 B, alineadas a 16) las que **se escriben** todavía caen en una sola línea
   y no se nota; con 8 casillas por hilo, las últimas de un hilo y las primeras del siguiente compartirían línea.
   `aligned_alloc` lo garantiza por construcción.
4. Con `schedule(static)`, el mismo número de iteraciones y de hilos, OpenMP reparte **las mismas** iteraciones
   a cada hilo en todos los ciclos de la región: cada hilo solo vuelve a tocar sus `y[i]`. Con
   `schedule(dynamic) nowait`, la iteración `i` de la pasada siguiente puede tomarla otro hilo mientras el
   primero todavía actualiza `y[i]`: carrera y resultado incorrecto (a veces).
5. Depende de la máquina: en una laptop los GB/s de `saxpy` dejan de crecer entre 2 y 4 hilos (se saturó el
   ancho de banda de memoria) mientras los GFLOP/s de `matmul` siguen creciendo. Si no se estancan, la memoria
   de tu máquina da más ancho de banda del que 4 núcleos pueden pedir (servidor con muchos canales, o arreglos
   que caben en la L3).
6. "Cambiar el tamaño del problema entre configuraciones sin declararlo (eso es escalabilidad débil, no
   fuerte)". En las filas `debil`, `speedup` es el escalado de Gustafson `S_w = p · T(1,n) / T(p,p·n)` y
   `eficiencia` es `E_w`.
</details>

## Fase 4 · Modificar (12 min; cada cambio se verifica con `make test`)

**M1 · Dos hilos por línea.** En `false_sharing.c` agrega una tercera variante compartida con `stride = 4` (32
bytes por hilo: los hilos 0–1 comparten una línea y los 2–3 otra). Predice primero dónde queda su tiempo entre
`contiguo` y `relleno`; mide con 4 hilos. Criterio: `make test` en PASS y una línea con la predicción y el dato.

**M2 · Mueve la fracción secuencial.** Sin tocar el código: `make run ITERS=8` y `make run ITERS=256` (solo
cambia el trabajo por elemento de la sección B de `profile_amdahl`). Tabla de tres filas (`iters`, `f` medida,
`S(4)` medido, `f` Karp–Flatt). ¿Qué cambia y qué no? Relaciónalo con la idea errónea 2.

**M3 · Cambia el tamaño, cambia la conclusión.** Con afinidad y 1, 2 y 4 hilos: `./saxpy_vs_matmul 1000000 640`
(los arreglos caben en caché), el tamaño por defecto, y `… 50000000 640` (400 MB por arreglo; si tu laptop tiene
menos de 4 GB, usa `25000000`). Anota `S(4)` y los GB/s de `saxpy` en los tres casos. ¿A partir de qué tamaño y
de cuántos hilos dejan de crecer los GB/s en **tu** máquina? Compara con `lscpu` (L3) y con lo que dice la
sección anterior sobre la máquina de autoría. ¿Qué dice eso sobre reportar un *speedup* sin el tamaño del
problema ni el hardware?

**M4 · Afinidad.** `make afinidad`: el mismo `weak_scaling` sin fijar hilos, con `OMP_PROC_BIND=close
OMP_PLACES=cores` y con `spread`. Copia las tres filas `fuerte`. Salida real en la máquina de autoría, con la
máquina desocupada:

```
== sin afinidad (OMP_PROC_BIND=false): el sistema operativo mueve los hilos entre nucleos
  secuencial   hilos=1  n=1000000  mediana=0.1051 s
  fuerte       hilos=4  mediana=0.0294 s  (min 0.0281, max 0.0600)  speedup=3.57  eficiencia=0.89  ok
  debil        hilos=4  n=4000000  mediana=0.1326 s  eficiencia debil E_w=T(1,n)/T(p,pn)=0.79  speedup escalado=3.17  ok
== OMP_PROC_BIND=close OMP_PLACES=cores: un hilo por nucleo, sin migraciones
level 1 thread 0x7fbe07cd47c0 affinity 0
level 1 thread 0x7fbe05b7a6c0 affinity 1
level 1 thread 0x7fbe053796c0 affinity 2
level 1 thread 0x7fbe04b786c0 affinity 3
  secuencial   hilos=1  n=1000000  mediana=0.1088 s
  fuerte       hilos=4  mediana=0.0335 s  (min 0.0317, max 0.0484)  speedup=3.25  eficiencia=0.81  ok
  debil        hilos=4  n=4000000  mediana=0.1095 s  eficiencia debil E_w=T(1,n)/T(p,pn)=0.99  speedup escalado=3.97  ok
== OMP_PROC_BIND=spread OMP_PLACES=threads: reparte los hilos lo mas lejos posible
  fuerte       hilos=4  mediana=0.0300 s  (min 0.0286, max 0.0314)  speedup=3.48  eficiencia=0.87  ok
  debil        hilos=4  n=4000000  mediana=0.1187 s  eficiencia debil E_w=T(1,n)/T(p,pn)=0.88  speedup escalado=3.53  ok
```

Aquí las tres configuraciones quedan dentro del ruido (3.6, 3.3 y 3.5): con cuatro núcleos iguales y nadie más
usando la máquina, el sistema operativo ya reparte bien. Durante la autoría hubo otro proceso compitiendo por los
cuatro núcleos y entonces **las tres** cayeron a 1.0–1.6×: la afinidad no sustituye a una máquina desocupada
(protocolo §1.5). ¿Por qué se fija y se declara de todos modos? Porque en laptops con *hyper-threading*
(`OMP_PLACES=cores` evita dos hilos en el mismo núcleo físico), con núcleos híbridos (rápidos y eficientes) o en
servidores de dos zócalos la colocación sí cambia el resultado, y porque una medición que no dice dónde corrieron
los hilos no se puede repetir. Mira las líneas `affinity`: ese dato va al reporte.

## Fase 5 · Crear (transferencia, ≥ 10 min)

Aplica el protocolo completo a un núcleo **tuyo** y produce el CSV y la gráfica como los de hoy. Núcleo: el de la
Parte B de tu Práctica 4 o, si aún no compila, `histogram_atomic.c` y `histogram_local.c` de S07
(`../../S07_2026-10-15_sincronizacion/practica-guiada/`).

1. **Predicción escrita** (una línea): "con 4 hilos espero S ≈ ___ porque ___".
2. Copia `csv_append()` y el patrón `for (int r = -1; r < N_REPS; r++)` de `common.h` a tu programa. Debe
   escribir una fila `secuencial,1,…` (solo con 1 hilo) y una fila por número de hilos con `speedup = T_seq /
   mediana`.

   <details><summary>Pista (ábrela después de 3 minutos de intento)</summary>

   Copia `common.h` junto a tu `.c` y pon `#include "common.h"`. El esqueleto es el mismo de `false_sharing.c`:

   ```c
   int p = omp_get_max_threads();
   double times[N_REPS];
   for (int r = -1; r < N_REPS; r++) {            /* 1) referencia secuencial */
       double t0 = now();  mi_version_seq(...);  double t = now() - t0;
       if (r >= 0) times[r] = t;
   }
   double t_seq = median_of(times, N_REPS);
   if (p == 1) csv_append(csv, "secuencial", 1, n, times, t_seq, t_seq);
   for (int r = -1; r < N_REPS; r++) {            /* 2) versión paralela, mismo patrón */
       double t0 = now();  mi_version_par(...);  double t = now() - t0;
       if (r >= 0) times[r] = t;
   }
   csv_append(csv, "mi-config", p, n, times, median_of(times, N_REPS), t_seq);   /* y compara resultados */
   ```

   Luego: `for t in 1 2 4; do OMP_PROC_BIND=close OMP_PLACES=cores OMP_NUM_THREADS=$t ./mi_programa N mio.csv; done`.
   `csv_append` necesita el nombre de la configuración, los hilos, `n`, las 5 repeticiones, su mediana y el
   tiempo de referencia `t_seq`.
   </details>

3. Mide con 1, 2 y 4 hilos, afinidad fija y un tamaño con el que la secuencial tarde ≥ 1 s (aquí en clase, si no
   alcanza, ≥ 0.3 s y lo declaras).
4. `python3 graficar.py tu.csv --titulo "..."`; pega la tabla Markdown y mira el PNG.
5. Tres líneas de interpretación: dónde deja de escalar, por qué (cuál de las cuatro causas: fracción
   secuencial, memoria, sobrecarga, falso compartido), y si coincidió con tu predicción.

Criterio de "listo": el CSV tiene las 11 columnas y abre con `graficar.py` sin error; el PNG tiene tu serie y la
línea ideal; la tabla trae la `f` de Karp–Flatt; las tres líneas citan al menos un número.

Si terminas antes: agrega a tu CSV una `config` más con otra política (`schedule(dynamic,64)`, o `relleno`
contra `local`) y explica con Karp–Flatt cuál de las dos tiene más sobrecarga al crecer `p`.

## Verificación automática

```bash
make test
```

Salida real (unos 8 s):

```
PASS  false_sharing    hilos=1 n=2000000
PASS  profile_amdahl   hilos=1 n=200000 iters=16
PASS  saxpy_vs_matmul  hilos=1 n=1000000 m=128
PASS  weak_scaling     hilos=1 n_por_hilo=100000
PASS  false_sharing    hilos=2 n=2000000
PASS  profile_amdahl   hilos=2 n=200000 iters=16
PASS  saxpy_vs_matmul  hilos=2 n=1000000 m=128
PASS  weak_scaling     hilos=2 n_por_hilo=100000
PASS  false_sharing    hilos=3 n=2000000
PASS  profile_amdahl   hilos=3 n=200000 iters=16
PASS  saxpy_vs_matmul  hilos=3 n=1000000 m=128
PASS  weak_scaling     hilos=3 n_por_hilo=100000
PASS  false_sharing    hilos=4 n=2000000
PASS  profile_amdahl   hilos=4 n=200000 iters=16
PASS  saxpy_vs_matmul  hilos=4 n=1000000 m=128
PASS  weak_scaling     hilos=4 n_por_hilo=100000
PASS  region_overhead  hilos=4 n=500 k=2000 (pasadas cortas)
PASS  region_overhead  hilos=3 n=200000 k=5 (n no divisible)
PASS  region_overhead  hilos=4 n=7 k=3 (menos datos que hilos)
PASS  false_sharing    hilos=4 n=5 (menos datos que hilos)
PASS  csv fs: encabezado del protocolo y 11 columnas (16 filas)
PASS  csv pa: encabezado del protocolo y 11 columnas (9 filas)
PASS  csv sm: encabezado del protocolo y 11 columnas (10 filas)
PASS  csv ws: encabezado del protocolo y 11 columnas (9 filas)
PASS  csv fs: una sola fila secuencial
PASS  graficar.py: PNG y tabla Markdown
PASS  graficar.py rechaza un archivo sin las columnas del protocolo
Resumen: 27 PASS, 0 FAIL
```

Cada programa compara su resultado paralelo con su versión secuencial: los conteos enteros de forma exacta y las
sumas en `double` con tolerancia relativa `1e-9` (el orden de suma cambia el redondeo, idea errónea 10). Las
pruebas usan tamaños pequeños a propósito: verifican correctitud y formato, no rendimiento.

## Problemas de entorno frecuentes

| Síntoma | Causa | Qué hacer |
|---|---|---|
| Todos los tiempos iguales con 1, 2 y 4 hilos | `OMP_NUM_THREADS` no llegó al programa | Ponlo en la misma línea: `OMP_NUM_THREADS=4 ./programa`, o usa `make run THREADS=4` |
| `libgomp: Affinity not supported`, o tiempos peores con `BIND` | Tu sistema no soporta `OMP_PROC_BIND` (p. ej. macOS), o tiene núcleos híbridos y `cores` te dejó hilos en los lentos | `make medir BIND=` (o `BIND="OMP_PROC_BIND=spread OMP_PLACES=threads"`) y decláralo en el reporte |
| *Speedup* con 4 hilos ≈ 1 en todo, también en `matmul` | La máquina está ocupada (otro proceso, navegador, actualización) o tiene 2 núcleos físicos | `uptime` antes de medir; `nproc`/`lscpu`; mide con los núcleos que tienes y decláralo |
| `contiguo` y `relleno` tardan igual | Procesador con pocos núcleos físicos activos, o `n` pequeño | Sube `n` (`make run N_FS=400000000`), confirma con `lscpu` que hay ≥ 2 núcleos físicos |
| `saxpy` escala casi perfecto | Los arreglos caben en la caché L3 de tu CPU, o tu memoria tiene ancho de banda de sobra para 4 núcleos (servidores) | Sube `n` hasta exceder la L3 (`lscpu` la muestra), mira los GB/s y decláralo (M3) |
| `graficar.py` falla con `No module named matplotlib` | Falta la biblioteca | `pip install matplotlib` (o `python3 -m pip install --user matplotlib`); el resto de la práctica no la necesita |
| `make medir` tarda más de 2 min | Máquina lenta o cargada | `make medir HILOS="1 4"` o tamaños menores (`N_FS=50000000`), siempre declarando el tamaño |

## Uso de IA en esta práctica

Verde: pedirle que te explique Karp–Flatt, la diferencia entre escalabilidad fuerte y débil, o qué es una línea
de caché. Amarillo: pedirle que revise tu interpretación de la Fase 5 o que te sugiera por qué `saxpy` no escala;
tú verificas con tus datos y lo declaras. Rojo: pedirle las predicciones de la Fase 1, o "mejorar" un CSV. Los
números se te pueden pedir en vivo en el Lab 2 del martes 27 de octubre.
