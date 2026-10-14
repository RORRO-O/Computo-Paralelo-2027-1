> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S10 · jueves 22 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S10 · Notas: rendimiento en memoria compartida (medir sin engañarse)

Si faltaste: lee esto (10 min), haz el `ejemplo-resuelto.md` con sus huecos (20 min) y la práctica guiada
(`practica-guiada/README.md`, 40 min). Con eso reconstruyes la sesión. Todo número de estas notas es una corrida
real en la máquina de autoría (máquina virtual con 4 vCPU Intel Xeon 2.1 GHz, gcc 13.3, `-O2`, un hilo por
núcleo con `OMP_PROC_BIND=close OMP_PLACES=cores`); los tuyos cambiarán, las conclusiones no.

## 1. El protocolo, en seis reglas

El protocolo completo está en `herramientas/protocolo-medicion.md`. Lo que se aplica hoy en cada programa:

| Regla | Cómo se ve en el código de la práctica | Qué pasa si no se cumple |
|---|---|---|
| `-O2`, correctitud primero | `CFLAGS = -std=c11 -O2 -Wall -Wextra -fopenmp`; cada programa compara su resultado con el secuencial antes de reportar tiempo | Un programa rápido y equivocado no tiene *speedup* (idea errónea 5: "se mide con `-O0`") |
| 1 calentamiento que no se cuenta | `for (int r = -1; r < N_REPS; r++) { … if (r >= 0) times[r] = t; }` | La primera corrida paga cachés frías y creación de hilos |
| ≥ 5 repeticiones, se reporta la **mediana** (y mín/máx) | `median_of(times, 5)` | Un pico del sistema arruina el promedio; una sola corrida no es evidencia |
| Reloj de pared, no de CPU | `omp_get_wtime()` | `clock()` suma la CPU de todos los hilos: con 4 hilos marca más, no menos (idea errónea 31) |
| `T(1)` es el **mejor secuencial**, no la paralela con 1 hilo | cada programa tiene `*_seq()` sin pragmas y lo mide en el mismo proceso | La paralela con 1 hilo puede ser más lenta (o más rápida) que el secuencial; se declara si se usa |
| Tamaño fijo y declarado; hilos 1, 2, 4, … hasta los núcleos físicos | columna `n` del CSV; `OMP_NUM_THREADS` | Cambiar `n` con `p` sin decirlo convierte la escalabilidad fuerte en débil (idea errónea 6) |

Formato de salida (protocolo §4), una fila por configuración y número de hilos:

```
config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia
```

`practica-guiada/common.h` lo escribe con `csv_append()`; `practica-guiada/graficar.py` lo lee y dibuja *speedup*
vs. hilos con la línea ideal `S = p`.

## 2. Las métricas y sus trampas

| Métrica | Fórmula | Pregunta que responde | Trampa habitual |
|---|---|---|---|
| *Speedup* | `S(p) = T(1) / T(p)` | ¿Cuántas veces más rápido que lo mejor que tenía? | Usar la paralela con 1 hilo como `T(1)` |
| Eficiencia | `E(p) = S(p) / p` | ¿Qué fracción de los `p` núcleos estoy aprovechando? | Confundirla con `S` (idea errónea 3): `S = 3` con 4 hilos es `E = 0.75` |
| Escalabilidad fuerte | `n` fijo, `p` crece; se reporta `S(p)` | ¿Cuánto más rápido el **mismo** problema? | Cambiar `n` entre filas |
| Escalabilidad débil | `n/p` fijo; se reporta `E_w(p) = T(1,n) / T(p, p·n)` y `S_w = p·E_w` | ¿Cuánto más problema en el **mismo** tiempo? (Gustafson) | Llamarle *speedup* fuerte (idea errónea 6) |
| Amdahl | `S(p) ≤ 1 / (f + (1−f)/p)`, `S(∞) = 1/f` | ¿Cuál es el techo si solo paralelizo lo paralelizable? | Tomar `f` en líneas de código; se mide en **tiempo** de la versión secuencial (idea errónea 2) |
| Karp–Flatt | `f_KF = (1/S − 1/p) / (1 − 1/p)` | ¿Qué fracción secuencial **efectiva** explica el `S` que medí? | Olvidar que incluye sobrecarga, sincronización, memoria y desbalance, no solo código fuera de la región |
| *Speedup* superlineal | `S(p) > p` | ¿Entró algo en caché que antes no cabía? | Llamarle error de medición y descartarlo (idea errónea 4), o celebrarlo sin explicarlo |

Dos lecturas de Karp–Flatt que conviene memorizar: si `f_KF ≈ f medida`, el programa está limitado por su parte
secuencial y el remedio es atacarla; si `f_KF ≫ f medida`, hay sobrecarga (hilos, barreras, memoria, falso
compartido, competencia por el procesador) y el remedio está dentro de la región paralela. Si `f_KF` **crece** con
`p`, la sobrecarga crece con los hilos.

## 3. Los cuatro experimentos de la práctica, con sus números

Todo con `make medir` (1, 2 y 4 hilos, tamaños reducidos para la sesión: la secuencial tarda 0.1–0.3 s) y
`make grafica`, que imprime estas tablas. Columnas: mediana de 5 repeticiones tras 1 calentamiento; `speedup`
contra la versión secuencial sin OpenMP medida en el mismo proceso; `f` = Karp–Flatt.

**a) Falso compartido** (`false_sharing`, `n = 10^8`): tres variantes con el mismo resultado y las mismas
operaciones; solo cambia dónde viven los contadores.

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

Lectura: `contiguo` tarda 1.5 veces más que `relleno` con 4 hilos y su `f` de Karp–Flatt es la mayor,
aunque el programa no tiene ninguna parte secuencial: lo que `f` captura es el rebote de la línea de caché.
`relleno` y `local` son equivalentes en tiempo; `local` es mejor código (no depende del tamaño de la línea). Una
`f` ligeramente negativa (filas con 2 hilos) solo dice que esa medición quedó un 3–6 % por encima de la ideal: ruido
de la máquina virtual, dentro del rango mín–máx que imprime el programa; no es un efecto de caché ni un error.

**b) Amdahl con fracción medida** (`profile_amdahl`, `n = 2·10^6`, `iters = 64`): perfil secuencial
`f = 0.101` → Amdahl `S(4) = 3.07`, techo `9.88`.

| config | hilos | n | mediana (s) | speedup | eficiencia | Karp–Flatt f |
|---|---|---|---|---|---|---|
| secuencial | 1 | 2000000 | 0.2118 | 1.00 | 1.00 | — |
| total | 1 | 2000000 | 0.1983 | 1.07 | 1.07 | — |
| total | 2 | 2000000 | 0.1256 | 1.45 | 0.72 | 0.380 |
| total | 4 | 2000000 | 0.0726 | 2.58 | 0.64 | 0.184 |
| seccionB | 1 | 2000000 | 0.1788 | 1.05 | 1.05 | — |
| seccionB | 2 | 2000000 | 0.1027 | 1.59 | 0.80 | 0.257 |
| seccionB | 4 | 2000000 | 0.0520 | 3.25 | 0.81 | 0.077 |

Lectura: la sección B escaló 3.25× y el programa 2.58×. `f_KF` del total (0.184) es mayor que la `f` medida
(0.101): la diferencia es sobrecarga dentro de la región paralela, no código secuencial.

**c) Memoria frente a cómputo** (`saxpy_vs_matmul`, `n = 10^7` elementos y matrices de 640 × 640):

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

Lectura: `saxpy` hace 2 flop por cada 24 bytes (0.083 flop/byte); `matmul` 53 flop/byte sobre sus datos. Un
núcleo de baja intensidad aritmética escala hasta donde llega el ancho de banda de la máquina. En la de autoría
no se agotó: con `n = 10^7` (160 MB, que aún caben en la L3 del anfitrión, 260 MB) y también con `n = 5·10^7`
(800 MB) los GB/s siguieron creciendo con los hilos: `S(2) = 1.81` y `S(4) = 2.90` (eficiencia 0.72), con 10.9, 25.6 y 40.5 GB/s para 1, 2 y 4 hilos, frente a `S(4) = 3.06` con `n = 10^7`. Es un servidor con memoria de muchos canales.
En una laptop (dos canales, 20–40 GB/s en total) `saxpy` se estanca a partir de 2 hilos y `matmul` no: la misma
medición cambia de conclusión con el hardware, y por eso el reporte declara el hardware y los GB/s alcanzados.

**d) Escalabilidad fuerte y débil** (`weak_scaling`, `n = 10^6` por hilo, 64 pasos de cómputo por elemento):

| config | hilos | n | mediana (s) | speedup | eficiencia | Karp–Flatt f |
|---|---|---|---|---|---|---|
| secuencial | 1 | 1000000 | 0.1076 | 1.00 | 1.00 | — |
| fuerte | 1 | 1000000 | 0.1095 | 0.98 | 0.98 | — |
| fuerte | 2 | 1000000 | 0.0605 | 1.90 | 0.95 | 0.053 |
| fuerte | 4 | 1000000 | 0.0296 | 3.66 | 0.92 | 0.031 |
| debil | 1 | 1000000 | 0.1134 | 0.95 | 0.95 | — |
| debil | 2 | 2000000 | 0.1056 | 2.18 | 1.09 | -0.081 |
| debil | 4 | 4000000 | 0.1306 | 3.32 | 0.83 | 0.068 |

Lectura: en las filas `debil` la columna `n` crece con los hilos (declarado), `speedup` es el *speedup* escalado
`p·T(1,n)/T(p,p·n)` y `eficiencia` es la eficiencia débil. El núcleo no tiene parte secuencial: lo que baja la
eficiencia es la sobrecarga de hilos y la competencia por los núcleos de la máquina virtual.

## 4. Sobrecarga de regiones y afinidad, medidas

`region_overhead 2000 20000` (40 millones de operaciones en 20 000 pasadas de 2000 elementos), 4 hilos:

```
== sobrecarga de regiones: n=2000 elementos, k=20000 pasadas, hilos=4  (40000000 operaciones en total)
  secuencial   hilos=1  mediana=0.0130 s  (min 0.0129, max 0.0136)
  regiones     hilos=4  mediana=0.0768 s  (min 0.0645, max 0.1717)  speedup=0.17  eficiencia=0.04  ok
  una-region   hilos=4  mediana=0.0465 s  (min 0.0304, max 0.1108)  speedup=0.28  eficiencia=0.07  ok
  sin-barrera  hilos=4  mediana=0.0107 s  (min 0.0101, max 0.0107)  speedup=1.22  eficiencia=0.30  ok
  costo estimado por pasada: region paralela ~ 3.3 us, barrera ~ 1.8 us  (diferencias contra sin-barrera, entre k=20000)
```

Abrir una región cuesta aquí ≈ 3.3 µs y una barrera ≈ 1.8 µs: más que los 2000 elementos de la pasada.
Las versiones `regiones` y `una-region` pierden contra la secuencial (idea errónea 1 en acción); solo gana la que
no sincroniza por pasada. Con `2000000 20` (mismas operaciones, pasadas 1000 veces más largas) las tres versiones
paralelas aceleran: la sobrecarga es la misma, el trabajo que la amortiza no.

`make afinidad` (`weak_scaling`, 4 hilos, máquina desocupada; `fuerte` es la fila relevante):

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

Con la máquina desocupada, las tres colocaciones quedan dentro del ruido (3.6, 3.3 y 3.5): cuatro núcleos iguales
y un solo programa es el caso fácil para el sistema operativo. Durante la autoría, cuando otro proceso compitió
por los cuatro núcleos, las tres configuraciones cayeron por igual a 1.0–1.6×: fijar hilos **no sustituye** a
cerrar lo demás (protocolo §1.5). Se fija y se declara de todos modos por las razones de §5: en otras máquinas sí
cambia el resultado, y sin ese dato la medición no se puede repetir.
## 5. Afinidad: panorama

El sistema operativo puede mover un hilo de un núcleo a otro en cualquier momento. Cada migración tira lo que el
hilo tenía en su caché privada y, en máquinas virtuales, con *hyper-threading* o con varios zócalos, puede dejar
dos hilos compitiendo por el mismo núcleo mientras otro queda vacío. OpenMP permite fijarlos:

| Variable | Valores útiles | Qué hace |
|---|---|---|
| `OMP_PLACES` | `threads`, `cores`, `sockets`, o una lista `{0},{1},{2},{3}` | Define los "lugares" donde puede vivir un hilo |
| `OMP_PROC_BIND` | `false`, `true`, `close`, `spread`, `primary` | `false`: el SO decide. `close`: hilos consecutivos en lugares vecinos (comparten caché). `spread`: lo más separados posible (más ancho de banda por hilo). `true`: fijos, en el orden de la implementación |
| `OMP_DISPLAY_AFFINITY=true` | — | libgomp imprime en qué CPU quedó cada hilo al arrancar la región (OpenMP 5.0) |
| `OMP_DISPLAY_ENV=true` | — | Imprime todas las variables de control al inicio: sirve para **documentar** la medición |

Regla del curso: la medición se hace con `OMP_PROC_BIND=close OMP_PLACES=cores` (un hilo por núcleo físico) y
**se declara** en el reporte, junto con `OMP_NUM_THREADS`. Si cambias la afinidad, es otra configuración (otra
fila `config` del CSV), no una repetición. Cuánto cambia depende de la máquina: nada en cuatro núcleos iguales
desocupados (§4), mucho con *hyper-threading* (dos hilos en un núcleo físico), con núcleos híbridos o con dos
zócalos. Lo que nunca arregla es la competencia con otros procesos.

## 6. Cuatro causas de que "no escale", y cómo se distinguen

| Síntoma en la tabla | Causa probable | Cómo confirmarla | Remedio |
|---|---|---|---|
| `S` se acerca a un techo aunque `E` de la sección paralela sea alta | Fracción secuencial (Amdahl) | Perfil por secciones: `f medida ≈ f_KF` | Paralelizar o acortar la sección secuencial |
| `S` crece de 1 a 2 hilos y casi nada de 2 a 4; el ciclo hace poca aritmética por byte | Límite de ancho de banda de memoria | GB/s alcanzados ≈ constantes al subir hilos; comparar con un núcleo de alta intensidad aritmética | Reutilizar datos (bloques, fusionar ciclos), reducir precisión, aceptar el límite |
| Paralelo **más lento** que secuencial con `n` pequeño; `f_KF` enorme | Sobrecarga: regiones, barreras, tareas, `dynamic` con *chunk* pequeño | `region_overhead`: costo por región ≈ microsegundos; comparar con el trabajo por región | Una región, menos barreras (`nowait` si es seguro), *chunks* mayores, `cutoff` en tareas, `n` mayor |
| Sin carrera, `make test` pasa, y aun así 4 hilos rinden mucho menos de lo esperado (aquí 2.2× contra 3.6×; en otras máquinas, menos que 1 hilo) | Falso compartido | El mismo código con relleno o con acumulador local se acelera | Acumulador local + una combinación (`reduction`), o relleno/alineación a 64 bytes |

El falso compartido merece una frase propia: la unidad que viaja entre las cachés de los núcleos es la **línea de
caché** (64 bytes en x86-64), no la variable. Dos hilos que escriben variables **distintas** que caen en la misma
línea se la arrebatan en cada escritura, como si compartieran el dato (idea errónea 14). Más hilos no lo arreglan;
lo empeoran.

## 7. Errores frecuentes

1. Reportar el *speedup* de la sección paralela como el del programa. → El usuario ve el total; se perfila por
   secciones y se reporta el total (y, aparte, el de la sección si ayuda a explicar).
2. Calcular `f` de Amdahl contando líneas. → `f` es tiempo medido de la versión secuencial.
3. `clock()` para medir tiempo paralelo. → `omp_get_wtime()`; `clock()` suma la CPU de todos los hilos.
4. Una corrida, sin calentamiento, con `-O0`, con el navegador abierto. → Protocolo §1–§2.
5. "4 hilos me dieron 3.9 con `n` creciente, escalabilidad fuerte perfecta". → Eso es escalabilidad débil; se
   reporta como `E_w` y se declara que `n` cambió.
6. Descartar `S > p` como error. → Verificar correctitud, explicar por caché, reportarlo así.
7. Abrir una región paralela por iteración de un ciclo externo corto. → Una región afuera y `omp for` adentro;
   `nowait` solo si el reparto es `static` idéntico y nadie lee datos ajenos.
8. Contadores o acumuladores "por hilo" en un arreglo contiguo. → Variable local y una sola escritura al final
   (o `reduction`); si tiene que ser un arreglo, relleno a 64 bytes.
9. Comparar mediciones hechas con distinta afinidad, distinto `n` o distinta carga del sistema. → Una
   configuración = una fila; `uptime` antes de medir; `OMP_DISPLAY_ENV=true` en el reporte.

## 8. Para saber más

- OpenMP Architecture Review Board, *OpenMP Application Programming Interface*, versión 5.2 (noviembre de 2022):
  *Environment Variables* (`OMP_PLACES`, `OMP_PROC_BIND`, `OMP_DISPLAY_AFFINITY`, `OMP_DISPLAY_ENV`), *Timing
  Routines* (`omp_get_wtime`), *Worksharing-Loop Construct* (garantía de reparto de `schedule(static)` que hace
  seguro `nowait` entre ciclos iguales). <https://www.openmp.org/specifications/>
- GCC, *GNU Offloading and Multi Processing Runtime Library (libgomp)*, manual de la versión 13: *Environment
  Variables* (incluye `GOMP_CPU_AFFINITY`, `OMP_WAIT_POLICY`, `GOMP_SPINCOUNT`). <https://gcc.gnu.org/onlinedocs/libgomp/>
- GCC, *Optimize Options* (`-O2`) y *Instrumentation Options* (por qué no se mide con *sanitizers*).
  <https://gcc.gnu.org/onlinedocs/gcc/>
- Pacheco, P. y Malensek, M., *An Introduction to Parallel Programming*, 2.ª ed., Morgan Kaufmann, 2022:
  capítulo 2 (rendimiento: *speedup*, eficiencia, Amdahl, Gustafson, escalabilidad fuerte y débil, cómo
  cronometrar) y capítulo 5 (OpenMP: cachés, coherencia y falso compartido).
- `herramientas/protocolo-medicion.md`, `herramientas/medir.sh` y `herramientas/graficar_speedup.py` del curso:
  la versión general de lo que hoy hiciste a mano, para usar en la Práctica 4 y en el proyecto.
