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

## 3. Los experimentos de la práctica, con sus números

`make medir` (1, 2 y 4 hilos; tamaños reducidos para la sesión: la secuencial tarda 0.1–0.3 s) y `make grafica`
producen las tablas completas, que están en `practica-guiada/README.md`, Fase 2. Aquí, solo la fila de 4 hilos de
la máquina de autoría (mediana de 5 tras 1 calentamiento). Cada programa divide entre la secuencial que midió en
su propio proceso.

| Experimento | Qué cambia | Resultado con 4 hilos | Lectura |
|---|---|---|---|
| **Falso compartido** (`false_sharing`, `n = 10^8`) | Solo dónde viven los contadores; mismas operaciones | `contiguo` S = 2.17 (`f_KF` = 0.28); `relleno` 3.50; `local` 3.56 (`f_KF` = 0.04) | El programa no tiene parte secuencial: la `f` de `contiguo` es el rebote de la línea de caché. `local` es el mejor código (no depende del tamaño de la línea) |
| **Amdahl medido** (`profile_amdahl`, `n = 2·10^6`, `iters = 64`) | — | `f` medida 0.101 → Amdahl S(4) = 3.07, techo 9.88. Medido: total 2.58 (`f_KF` = 0.184); sección B 3.25 | `f_KF ≫ f`: la pérdida está dentro de la región paralela, no en A ni en C |
| **Memoria vs. cómputo** (`saxpy_vs_matmul`, `10^7` y 640 × 640) | Intensidad aritmética: 0.083 frente a 53 flop/byte | `saxpy` 3.06; `matmul` 2.87. Con `n = 5·10^7` (800 MB): `saxpy` 2.90, 40.5 GB/s | En la de autoría (servidor con muchos canales de memoria) los GB/s siguieron creciendo. En una laptop (20–40 GB/s) `saxpy` se estanca desde 2 hilos y `matmul` no: el reporte declara hardware y GB/s |
| **Fuerte y débil** (`weak_scaling`, `10^6` por hilo) | `n` fijo frente a `n/p` fijo | Fuerte: S(4) = 3.66. Débil: `T(1,n)` = 0.108 s, `T(4,4n)` = 0.131 s → `E_w` = 0.83, `S_w` = 3.3 | En `debil` la columna `n` crece (se declara); `speedup` es el escalado `p·E_w` |
| **Sobrecarga** (`region_overhead 2000 20000`) | Una región por pasada, una región con barreras, sin barreras | `regiones` 0.17; `una-region` 0.28; `sin-barrera` 1.22. Región ≈ 3.3 µs, barrera ≈ 1.8 µs por pasada | Cuestan más que los 2000 elementos de la pasada (≈ 0.65 µs en secuencial): idea errónea 1 en acción. Con `2000000 20` (mismas operaciones) las paralelas aceleran |
| **Afinidad** (`make afinidad`, `weak_scaling` fuerte) | Sin fijar, `close`+`cores`, `spread` | 3.57, 3.25 y 3.48 (máquina desocupada) | Dentro del ruido; con otro proceso compitiendo, las tres cayeron a 1.0–1.6×. Fijar hilos no sustituye a cerrar lo demás (protocolo §1.5); se fija y se **declara** (§4) |

Una `f` de Karp–Flatt ligeramente negativa (p. ej., `relleno` con 2 hilos, −0.05) solo dice que esa medición quedó
unos puntos por encima de la ideal: ruido, dentro del rango mín–máx que imprime el programa; no es caché ni error.

## 4. Afinidad: panorama

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
desocupados (§3), mucho con *hyper-threading* (dos hilos en un núcleo físico), con núcleos híbridos o con dos
zócalos. Lo que nunca arregla es la competencia con otros procesos.

## 5. Cuatro causas de que "no escale", y cómo se distinguen

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

## 6. Errores frecuentes

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

## 7. Para saber más

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
