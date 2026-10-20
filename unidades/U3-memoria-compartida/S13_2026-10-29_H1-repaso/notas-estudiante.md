> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S13 · jueves 29 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S13 · Notas: guía de repaso de la Unidad III para el Examen 2

Si faltaste: resuelve `examen-practica-U3.md` en casa, cronometrado (40 min), corrígelo con la clave y llena
la hoja de calibración; después haz `practica-guiada/README.md` (40 min) y la `tarea-espaciada.md`. Con eso
reconstruyes la sesión. El **Examen 2** es el **martes 3 de noviembre, 08:30–10:00** (100 puntos, 80 min,
versiones A/B, sin dispositivos). El **lunes 2 no hay clase**. La **Práctica 4 vence el domingo 1 de noviembre
a las 23:59**.

## 1. Qué tienes que poder hacer (mapa de la unidad)

| Tema | Sesión | Debes poder… | Idea errónea que te tienden |
|---|---|---|---|
| Regiones, `parallel for`, alcance | 1–13 oct, S07 | Decir de cada variable si es compartida o privada y con qué valor entra | 9 (`private` copia), 15 (lo de adentro es compartido) |
| Carreras y corrección | S07 | Encontrar la variable compartida que se escribe y elegir la protección más barata que sea correcta | 7 ("salió bien"), 8 (`atomic` ≡ `critical`), 10 (`reduction` exacta) |
| Barreras y `nowait` | S07, S08 | Decir quién llega a cada barrera y quién lee después de ella | 12 (no hay barrera al final del `for`), 32 (`barrier` en un `if`) |
| `schedule` y balance | S08 | Predecir el mapeo `static`; elegir política por la forma del trabajo | 11 (`dynamic` siempre gana) |
| Tareas | S09 | `parallel` + `single` + `task` + `taskwait`; qué entra `shared` y qué `firstprivate` | 13 (la tarea se ejecuta al crearse) |
| Medición y Amdahl | S10, S12 | Protocolo; `f` en tiempo; `S`, `E`, Karp–Flatt; fuerte vs débil | 1, 2, 3, 5, 6, 31 |
| Falso compartido | S10 | Reconocerlo (correcto pero lento) y corregirlo con locales o relleno | 14 |
| Patrones y `simd` | S11 | Reducción sobre arreglo, *scan* en dos fases, Jacobi con doble búfer; `simd` es una promesa | 30 (todo `for` se paraleliza) |
| Diseño con Foster | S12, U II | Medir → dependencias → pragma; tarea, aglomeración, mapeo | 28, 29 |

## 2. El protocolo de lectura (para predecir, encontrar el error y completar)

1. **Variables escritas dentro de la región.** Lista cada una. Declarada afuera sin cláusula → compartida. Si
   la escriben varias iteraciones o varios hilos, necesita una decisión: `reduction`, `atomic`, `critical` /
   candado, o privada + combinar. Si solo se **lee**, no necesita nada.
2. **Alcance de los temporales.** `private` → copia **sin inicializar**; `firstprivate` → copia con el valor de
   afuera; declarada adentro del bloque o del `for` → privada; `shared` explícito en `task` cuando la hija
   escribe y el padre lee.
3. **Barreras.** Implícita al final de `omp for`, `sections`, `single` y `parallel`; `nowait` la quita en los
   tres primeros. Es seguro quitarla solo si nadie lee después lo que otro hilo escribió. `#pragma omp barrier`
   la deben alcanzar **todos** los hilos; dentro de un `if` o de `single` es interbloqueo. `master` no tiene
   barrera.
4. **Mapeo.** `static` sin *chunk*: bloques contiguos casi iguales (sobrantes a los primeros hilos); `static,c`:
   bloques de `c` cíclicos; `dynamic`/`guided`: no predecible. Dos ciclos `static` con el mismo `n` en la misma
   región reparten igual.
5. **Dependencias entre iteraciones** (`a[i]` usa `a[i-1]`, mismo arreglo leído y escrito en un *stencil*,
   *scan*): ninguna cláusula lo arregla; se cambia el algoritmo o se deja secuencial.

**El protocolo aplicado** (`ejemplo-resuelto.md`, código en `practica-guiada/ejemplo_revision.c`). Una región
con dos `omp for schedule(static)`: el primero escribe `a[i] = 2·x[i] − 0.5` con `nowait`, el segundo cuenta
los `a[i] > 0.6` en `my_hits` (declarada adentro) y al final `atomic` suma `hits += my_hits`. (1) Se escriben
`a[]`, `my_hits` y `hits`: `my_hits` es privada por alcance; `hits` es compartida y se protege una vez por
hilo. (2) `thr` solo se lee: sin cláusula o `firstprivate`; nunca `private`. (3) El `nowait` es seguro porque
(4) los dos ciclos `static` con el mismo `n` dan el mismo mapeo: cada hilo lee solo lo que él escribió. Con
4 hilos y `n = 16`: `hits por hilo: h0=2 h1=2 h2=1 h3=3`, total 8. Si el ciclo 1 pasa a `dynamic,1`, el
resultado sigue saliendo bien y ThreadSanitizer reporta la carrera en la lectura de `a[i]`: "salió bien" no
es evidencia.

## 3. Tabla de decisión: la más barata que sea correcta

| Situación | Elige | Descarta |
|---|---|---|
| `s += e`, `s *= e`, `max`, `min`, `&&`… sobre un escalar | `reduction(op:s)` | `atomic` (×5), `critical` (×20–100) |
| `hist[f(x)]++` (índice que depende de los datos) | `reduction(+:hist[:n])` o histograma local + volcado | `atomic` por elemento (contención, falso compartido); `critical` (serializa) |
| `x++` disperso donde los hilos rara vez chocan | `atomic` | `critical` |
| Varias variables juntas, `if` + asignación, llamadas | `critical` o candado; mejor: local por hilo + una combinación protegida | `atomic` (no compila o no protege) |
| Variable que solo se lee | nada (compartida) | `private` (basura); `firstprivate` sobra salvo que cada hilo la modifique |
| Iteraciones uniformes | `static` | `dynamic,1` (atómica por iteración) |
| Iteraciones de costo creciente o irregular | `dynamic,c` o `guided,c` con `c` de cientos–miles; `static,c` si el patrón es conocido | `static` (el hilo que recibe el final hace casi todo) |
| Recursión / lista enlazada / trabajo que aparece | `task` con corte (*cutoff*); `taskwait` por nivel | `parallel for` (no hay índice) |
| `a[i] = a[i-1] + …` | *scan* en dos fases, o secuencial | `parallel for`, `simd`, `ordered` (serializa) |
| `u_new[i] = f(u[i-1], u[i], u[i+1])` | doble búfer + intercambio de punteros | escribir sobre `u` |

## 4. Fórmulas (hoja mental; en el examen no hay formulario)

- `S(p) = T(1)/T(p)` con `T(1)` = **mejor secuencial**, mismo `n`. `E(p) = S(p)/p`.
- Amdahl: `S(p) = 1 / ((1 − f_p) + f_p/p)`; `S(∞) = 1 / (1 − f_p)`; `f_p` = fracción **del tiempo** secuencial
  que sí se paraleliza (del perfil por secciones, no de las líneas).
- Karp–Flatt: `f = (1/S − 1/p) / (1 − 1/p)`. Si crece con `p`: sobrecarga creciente. Si `f > 1 − f_p`: hay
  costo que el perfil no muestra. Si `f > 1`: el paralelo hace más trabajo que el secuencial (el modelo no aplica).
- Escalabilidad fuerte: mismo `n`, más `p`. Débil: `n` crece con `p`; eficiencia débil `T(1,n)/T(p,p·n)`
  (Gustafson). Una tabla con `n` distinto por fila **no** da *speedup*.
- Protocolo: `-O2`, 1 calentamiento, ≥ 5 repeticiones, **mediana** (con mín y máx), `T(1) ≥ 1 s` (y nunca
  `< 0.1 s`), hilos hasta los núcleos físicos, solo la región de interés, `omp_get_wtime()` (nunca `clock()`).

## 5. Cómo se contesta bajo tiempo (100 puntos en 80 minutos: 0.8 min por punto)

1. Primero la opción múltiple y el problema numérico (puntos rápidos y sin trampa de tiempo). Después
   completar código, predecir, encontrar el error, y al final el diseño.
2. En "predecir la salida": escribe el mapeo (qué hilo, qué iteraciones) **antes** de calcular valores; rastrea
   una copia por hilo con `firstprivate`.
3. En "encontrar el error": aplica las cinco preguntas de §2 en orden; el error casi siempre está en la
   primera que no puedas contestar "bien". Corrige con la fila correspondiente de §3 y di por qué descartaste
   las otras dos.
4. En "problema numérico": escribe la fórmula, sustituye, redondea al final. Un `E > 1` o un `f_p` calculado
   con líneas es un cero seguro.
5. En "diseño": nombra la construcción, el `schedule` con su razón, y qué medirías (protocolo). Diez líneas.
6. Hoja de calibración: tu predicción al recibir el examen, tu postdicción al entregar, las dos en la escala
   del examen (0–100; en el examen de práctica, 0–60). No afecta la calificación; sí te dice si estudiaste lo
   que creías.

## 6. Errores frecuentes en exámenes de esta unidad

1. Proteger la variable equivocada (la privada) y dejar la compartida sin nada.
2. `private` donde hace falta el valor (idea 9); `firstprivate` "por si acaso" en variables que se escriben
   (cada hilo escribe su copia y el resultado de afuera no cambia).
3. Creer que `atomic` protege un `if` o dos variables (idea 8).
4. Olvidar que `nowait` también quita la protección del ciclo siguiente (idea 12), o poner `barrier` dentro
   de un `if` (idea 32).
5. `dynamic` "porque balancea" en un ciclo uniforme (idea 11), o `static` en un ciclo triangular.
6. Leer el resultado de una tarea sin `taskwait`, o sin `shared` (idea 13 y el entorno de datos de `task`).
7. `f` de Amdahl por líneas (idea 2); `E = S` (idea 3); *speedup* contra la paralela con 1 hilo (idea 31);
   tabla con `n` distinto por fila reportada como escalabilidad fuerte (idea 6).
8. Dar por correcta una carrera porque "salió bien" o porque TSan no se quejó del código protegido (idea 7).

## 7. Para saber más

- OpenMP Architecture Review Board, *OpenMP Application Programming Interface*, versión 5.2 (noviembre de
  2022): *Data-Sharing Attribute Clauses*; *worksharing-loop Construct* (reglas de `schedule(static)`);
  *barrier Construct*; *atomic Construct*; *critical Construct*; *task Construct* y *taskwait Construct*.
  <https://www.openmp.org/specifications/>
- GCC 13, *GNU Offloading and Multi Processing Runtime Library (libgomp)*: variables de entorno
  (`OMP_NUM_THREADS`, `OMP_SCHEDULE`). <https://gcc.gnu.org/onlinedocs/libgomp/> · *Instrumentation Options*:
  `-fsanitize=thread`. <https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html>
- Pacheco, P. y Malensek, M., *An Introduction to Parallel Programming*, 2.ª ed., Morgan Kaufmann, 2022:
  capítulo 2 (rendimiento: *speedup*, eficiencia, Amdahl, escalabilidad) y capítulo 5 (OpenMP: alcance de
  variables, `reduction`, `critical`/`atomic`, `schedule`, tareas, cachés y falso compartido).
