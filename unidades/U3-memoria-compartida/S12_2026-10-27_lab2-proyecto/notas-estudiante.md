> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S12 · martes 27 de octubre de 2026 · 08:30–10:00 · Lab LS4

# Notas · S12 · De la V1 a la V2: perfilar, calcular la fracción, listar dependencias, decidir

Hoy hay dos cosas: el segundo laboratorio de la Práctica 4 (Partes C y D, punto de control y mini-defensas)
y el taller que convierte tu V1 secuencial en un plan para la V2 con OpenMP. Estas notas cubren el taller;
para el laboratorio vale el enunciado de la Práctica 4 y `herramientas/protocolo-medicion.md`.

## 1. El orden correcto (y por qué no es "poner pragmas y ver")

1. **Perfilar por secciones.** Un `omp_get_wtime()` entre fase y fase de la V1; tiempo y fracción de cada una.
   Mediana de 5 repeticiones, con calentamiento, `-O2`, tamaño fijo con T(1) ≥ 1 s.
2. **Calcular la fracción paralelizable f en tiempo.** f = (tiempo de las secciones que sí se pueden
   paralelizar) / (tiempo total). **Nunca en líneas de código**: una lectura de archivo de 10 líneas puede
   tardar más que un ciclo de 200.
3. **Predecir con Amdahl.** S_max(p) = 1 / ((1 − f) + f/p). Con f = 0.85 y 4 hilos, S_max = 2.76 aunque la
   región escale perfecto; con infinitos hilos, 1/(1 − f) = 6.7. Si la cota ya es mala, el problema es la
   parte secuencial, no OpenMP.
4. **Listar dependencias del ciclo que domina.** Por iteración: qué lee, qué escribe. Clasificar (tabla §2).
5. **Elegir estrategia** (datos/tareas, `schedule`) y justificarla con Foster. Solo entonces, el pragma.
6. **Medir con el protocolo** la región **y** el programa completo; comparar con la predicción; explicar la
   diferencia.

El paso 1 es lo que pide H1 (jueves 29 de octubre); los pasos 4–6 son H2 (lunes 23 de noviembre). La
plantilla `practica-guiada/plan-paralelizacion-V2.md` tiene una sección por paso.

## 2. Palabras clave

| Término | Qué es | Cómo se ve en código |
|---|---|---|
| Perfil por secciones | Tiempo de cada fase del programa, medido con el reloj de pared | `t0 = omp_get_wtime(); fase(); t1 = omp_get_wtime();` → `t1 − t0` |
| Punto caliente (*hot spot*) | La sección con mayor fracción del tiempo | La fila más grande de la tabla, no la función más larga |
| Fracción paralelizable f | Parte del tiempo secuencial que sí se puede repartir | Suma de fracciones de las secciones "sí" |
| Cota de Amdahl | *Speedup* máximo con p hilos dada f | 1 / ((1 − f) + f/p) |
| Iteración independiente | Escribe solo "su" elemento; lee datos que nadie escribe en el ciclo | `out[i] = g(i)` → `parallel for` |
| Reducción | Todas las iteraciones escriben la misma variable con un operador asociativo | `acum += f(i)` → `reduction(+:acum)` |
| Carrera potencial sobre estructura compartida | Varias iteraciones pueden escribir la misma celda | `hist[bin]++` → copias privadas y combinar; `atomic` si es simple |
| Dependencia verdadera | La iteración i necesita el resultado de la i − 1 | `a[i] = a[i-1] + …` → cambiar algoritmo o no paralelizar |
| Aglomeración (Foster) | Agrupar tareas finas para reducir sobrecarga sin perder paralelismo | `schedule(static, chunk)`, bloques de filas; **no** "todo en un hilo" |
| Pre-mortem | Antes de medir, escribir qué *speedup* esperas y qué podría salir mal | Sección 5 de la plantilla |

## 3. El ejemplo resuelto, en corto (`ejemplo-resuelto.md`, código en `practica-guiada/ejemplo_perfil.c`)

Tres fases: carga de dos millones de puntos; cómputo de seis rasgos por punto (`sqrt`, `atan2`, `exp`; función de
23 líneas); resumen que cuenta pares a distancia < 0.01 entre los primeros 48 000 puntos (un ciclo de 6 líneas, O(m²)).

| Fase | Mediana 1 hilo (s) | Fracción | Cota S_max(4) si solo se paraleliza esta fase |
|---|---|---|---|
| carga | 0.019 | 0.015 | — |
| cómputo | 0.092 | 0.073 | 1.06 |
| resumen | 1.154 | 0.911 | 3.16 |
| total | 1.267 | 1.000 | |

Medido con 4 hilos: paralelizar solo el cómputo → total 1.08×; paralelizar el resumen con `dynamic, 64` → fase
3.41×, total **2.81×**; el mismo ciclo con `static` → fase 2.21× (el primer bloque de iteraciones es el más
pesado). Con el *speedup* real de la fase, Amdahl reproduce el total: 1.267 / (0.019 + 0.092 + 1.154/3.41) = 2.82.

Lecciones: (1) la fase que "se ve pesada" no era la pesada: el perfil manda; (2) paralelizar la fase
equivocada da un *speedup* total cercano a 1 aunque esa fase escale; (3) el ciclo triangular del resumen
tiene iteraciones desiguales: `schedule(dynamic, 64)` le ganó a `static` por mucho; (4) el *speedup* del
programa completo siempre queda por debajo del de la región, exactamente por la fracción secuencial.

## 4. Errores frecuentes

| Error | Corrección |
|---|---|
| Calcular f con líneas de código o "a ojo" | f sale de la tabla de tiempos de la V1 (1 hilo). |
| Calcular f con los tiempos de la corrida de 4 hilos | Amdahl usa los tiempos de la versión **secuencial**. |
| Cronometrar una sola corrida | Mediana de 5 con calentamiento; anota mín y máx. El pico se investiga, no se promedia. |
| Compilar sin `-O2` para "ver mejor el speedup" | Se mide lo que se usaría: `-O2`. Con `-O0` el *speedup* es de otro programa. |
| Poner el pragma antes de listar dependencias | Primero qué lee y qué escribe cada iteración; `sum += …` sin `reduction` es una carrera que a veces "sale bien". |
| Reportar solo el *speedup* de la región | Se reportan región **y** total; el total es lo que el usuario siente y es el que Amdahl acota. |
| "Aglomerar" = meter todo el programa en una región `parallel` | Aglomerar es elegir el tamaño de bloque/`chunk` para reducir sobrecarga manteniendo p bloques útiles. |
| T(1) = la V2 con `OMP_NUM_THREADS=1` sin decirlo | T(1) es la V1 (mejor secuencial). Si usas la V2 con un hilo, decláralo y reporta ambas. |
| Problema tan chico que el tiempo de crear hilos domina | Tamaño con T(1) ≥ 1 s; región de calentamiento; si la fase tarda 5 ms, no esperes *speedup*. |

## 5. Para saber más

- OpenMP Architecture Review Board, *OpenMP Application Programming Interface*, versión 5.2 (2021):
  `omp_get_wtime` (rutinas de tiempo), cláusulas `reduction`, `schedule`, `if`; rutina `omp_set_schedule`.
  <https://www.openmp.org/specifications/>
- GCC, *GNU Offloading and Multi Processing Runtime Library* (libgomp): variables de entorno
  `OMP_NUM_THREADS`, `OMP_SCHEDULE`, `OMP_PROC_BIND`. <https://gcc.gnu.org/onlinedocs/libgomp/>
- Pacheco, P. y Malensek, M., *An Introduction to Parallel Programming*, 2.ª ed., Morgan Kaufmann, 2022:
  capítulo 2 (§2.6, rendimiento: *speedup*, eficiencia, Amdahl, escalabilidad; §2.7, diseño con Foster) y
  capítulo 5 (OpenMP: `reduction`, `schedule`, carreras).
- `herramientas/protocolo-medicion.md` (este curso): la lista de lo que invalida una medición.
