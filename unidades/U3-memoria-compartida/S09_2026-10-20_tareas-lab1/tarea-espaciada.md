> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S09 · martes 20 de octubre de 2026 · 08:30–10:00 · Lab LS4

# S09 · Tarea espaciada (20–40 minutos)

**Entrega.** Carpeta `tareas/S09/` en el repositorio de tu equipo (el mismo de las prácticas), con un archivo
`respuestas.md` y el `.c` del ejercicio 1, antes del **jueves 22 de octubre de 2026, 10:30** (inicio de S10).
La autocalificas con las claves de abajo en los primeros minutos de S10; el profesor registra la entrega, no el
acierto, y revisa 3 tareas al azar por estudiante en el parcial ("Tareas espaciadas y ejercicios", 5 % del 2º
parcial, `planeacion/mapa-evaluacion.md`). Individual; el *commit* debe ser tuyo. Si faltaste a S09, esta
tarea sustituye tu recuperación y tu *exit ticket* de hoy (`docs/metodo/04-evaluacion.md`, §5).

IA: verde para que te explique la regla de datos de `task` o un mensaje de gcc; amarillo (declarado) para que
revise tu `tree_sum_tasks.c` y señale dónde una tarea escribe en una copia; rojo para que escriba la recursión
por ti.

No confundir con la **Práctica 4**: sus Partes A y B siguen en el repositorio del equipo; la Parte C se avanza
esta semana y la práctica completa se entrega el **domingo 1 de noviembre, 23:59** (40 % del 2º parcial).

## 1. Del tema de hoy (15–20 min) · La fase Crear y la elección de herramienta

**1a. Suma de un árbol con tareas** (es la fase 5 de `practica-guiada/README.md`; en clase no dio tiempo).
Completa `TODO(1)` y `TODO(2)` de `practica-guiada/tree_sum_tasks.c` (copia el archivo terminado a
`tareas/S09/`). Criterio de "listo": compila sin *warnings* con `gcc -std=c11 -O2 -Wall -Wextra -fopenmp`;
`./tree_sum_tasks` imprime `verificacion: OK`; con 4 hilos el *speedup* es mayor que 1 para algún corte de
profundidad (prueba 4, 8 y 12); `make test` en `practica-guiada/` sigue en `0 FAIL`. En `respuestas.md` pega la
línea `tareas :` de los tres cortes y escribe una línea: ¿cuál corte elegiste y por qué?

<details><summary>Pista (ábrela solo si a los 10 minutos no arrancas)</summary>

El corazón del `TODO(1)` son estas dos líneas, una antes de cada llamada recursiva. Te falta el resto: los dos
casos base, declarar `left_sum` y `right_sum`, las dos llamadas con `depth + 1`, el `taskwait` y el `return`.

```c
#pragma omp task shared(left_sum)
#pragma omp task shared(right_sum)
```
</details>

Si terminas, `TODO(3)`: el contador atómico de tareas. Para el corte 8 la cota es 2·(2⁸ − 1) = 510 tareas.
¿Por qué tu contador queda por debajo? (una línea).

**1b. ¿`parallel for`, `task` o `taskloop`?** Para cada caso elige **una** construcción y justifícala en una
línea (qué tiene el problema que descarta a las otras dos):

1. Sumar un arreglo de 10⁸ `double` ya en memoria.
2. Recorrer una lista enlazada de 5 000 archivos y comprimir cada uno (tamaños muy distintos).
3. Ordenar un arreglo con *quicksort* (partición secuencial, dos mitades de tamaño impredecible).
4. Un ciclo de 10⁶ iteraciones irregulares que está **dentro** de una tarea, en un programa que ya abrió su
   región paralela con `parallel` + `single`.

<details><summary>Clave del ejercicio 1</summary>

**1a.** Esqueleto de la recursión (la tuya puede variar en nombres):

```c
static long tree_sum_tasks(const node *t, int depth, int cutoff_depth)
{
    if (!t) return 0;
    if (depth >= cutoff_depth) return tree_sum_seq(t);     /* corte: sin tareas de aquí hacia abajo */
    long left_sum, right_sum;
    #pragma omp task shared(left_sum)                       /* la hija escribe, el padre lee */
    left_sum = tree_sum_tasks(t->left, depth + 1, cutoff_depth);
    #pragma omp task shared(right_sum)
    right_sum = tree_sum_tasks(t->right, depth + 1, cutoff_depth);
    #pragma omp taskwait                                    /* sin esto, left_sum y right_sum no están listas */
    return collatz_steps(t->value) + left_sum + right_sum;
}
/* TODO(2): */
#pragma omp parallel
#pragma omp single
total = tree_sum_tasks(root, 0, cutoff_depth);
```

Sin `shared(...)`, `left_sum` y `right_sum` entran a la tarea como `firstprivate` y el padre suma dos
valores sin inicializar (el mismo mecanismo de `fib_buggy.c`; `gcc -Wall` puede avisar `may be used
uninitialized`). Sin la región `parallel` + `single` no hay equipo de hilos: el resultado es correcto y el
*speedup* es 1.0. En la máquina de autoría (4 núcleos compartidos con otros procesos, n = 10⁶): corte 4 → 30
tareas, *speedup* 1.42; corte 8 → 502 tareas, 1.65; corte 12 → 5 898 tareas, 1.60; corte 24 → 759 456
tareas, 0.30. Un corte entre 8 y 12 da cientos o miles de tareas con trabajo suficiente cada una; con 24 la
sobrecarga por tarea domina. El valor exacto en tu máquina cambia; el orden no. **TODO(3):** el contador queda
por debajo de la cota porque el árbol no está balanceado: muchas ramas se acaban (`t == NULL`) antes de la
profundidad de corte y no crean las dos tareas.

**1b.** (1) `parallel for` (+ `reduction`): hay índices, trabajo uniforme, nada que justifique tareas.
(2) `task`, una por nodo, con el patrón `parallel` + `single`: no hay índices para repartir y el trabajo por
nodo es irregular; los hilos toman tareas conforme se desocupan. (3) `task` con corte: la recursión produce
subproblemas de tamaño impredecible; cada llamada grande crea dos tareas y espera con `taskwait`; por debajo
del corte, secuencial. (4) `taskloop grainsize(c)` o `taskloop num_tasks(k)`: parte el ciclo en tareas que
toma el mismo equipo, sin abrir otra región paralela dentro de la tarea (una región anidada crearía otro
equipo o correría en serie, según `OMP_MAX_ACTIVE_LEVELS`). Respuesta "parcial": construcción correcta sin la
razón que descarta a las otras.
</details>

## 2. Intercalado, Unidades I y II (10 min) · Amdahl y Foster en el mergesort con tareas

En `mergesort_tasks` con n = 2 000 000 y corte 4 096, por encima del corte hay 9 niveles de mezcla
(2 000 000 / 4 096 ≈ 2⁹). Cada nivel recorre los n elementos completos (mezclar es copiar). En el nivel más
alto hay **una** mezcla de n elementos que hace **un solo hilo** (el que terminó el `taskwait` de la raíz);
en el siguiente, dos mezclas de n/2 que pueden correr en dos hilos; del tercero hacia abajo hay 4 o más
mezclas y los 4 hilos pueden estar ocupados. Supón que todo el trabajo son esas 9 mezclas y que el resto se
reparte perfecto.

a) ¿Qué fracción del trabajo de mezcla no puede usar más de 1 hilo? ¿Y más de 2?
b) Con 4 hilos, calcula el tiempo relativo T(4)/T(1) = (fracción a 1 hilo) + (fracción a 2 hilos)/2 +
   (resto)/4 y el *speedup* máximo que resulta. Compáralo con tu línea `resumen:` de la práctica (o con la de
   autoría: `t_seq=0.1862 t_tareas=0.0887 speedup=2.10`). ¿Qué otro límite, además de Amdahl, actúa sobre un
   algoritmo que casi no calcula y solo mueve memoria?
c) Describe el mergesort con tareas con las cuatro etapas de Foster, una línea cada una: partición,
   comunicación, aglomeración, mapeo. ¿En cuál de las cuatro vive el corte?

<details><summary>Para autoverificar</summary>

a) 1/9 ≈ 0.11 del trabajo de mezcla es estrictamente de un hilo (la mezcla final); otro 1/9 no pasa de 2 hilos.
b) T(4)/T(1) = 1/9 + (1/9)/2 + (7/9)/4 ≈ 0.111 + 0.056 + 0.194 = 0.361 → *speedup* máximo ≈ **2.8** con 4
   hilos, aunque el código "sea 100 % paralelo". La medición de autoría (2.10, eficiencia 0.52) queda por
   debajo: además de la mezcla final secuencial, mezclar es copiar memoria y los 4 hilos compiten por el
   mismo ancho de banda (se mide en S10, jueves 22 de octubre). Con 8 hilos el techo de Amdahl sube poco
   (≈ 3.6 = 1 / (1/9 + 1/18 + 1/36 + 6/72)): la mezcla de arriba sigue siendo de un hilo. Idea errónea 1.
c) Partición: por dominio, cada llamada parte su tramo en dos mitades. Comunicación: la mezcla, que necesita
   las dos mitades ya ordenadas (por eso el `taskwait` antes de `merge`). Aglomeración: el corte, que junta
   todo el subárbol de llamadas pequeñas en una sola tarea secuencial. Mapeo: la cola de tareas de OpenMP,
   dinámico (quién ejecuta cada tarea se decide al vuelo, como `schedule(dynamic)` en S08). El corte vive en la
   **aglomeración**.
</details>

## 3. Preparación de S10, jueves 22 de octubre, 10:30, Salón 3208 (5–10 min)

S10 es la sesión de rendimiento: protocolo de medición, Amdahl con datos medidos, Karp–Flatt, falso compartido.

a) Lee `herramientas/protocolo-medicion.md`, §2 y §3 (5 min). Con tu línea `resumen:` del mergesort con 4
hilos calcula *speedup*, eficiencia y la fracción secuencial de Karp–Flatt `f = (1/S − 1/p) / (1 − 1/p)`.
Si no la tienes, usa la de autoría (`speedup=2.10`).

b) Conjetura (una línea; "no sé" vale): en `mergesort_tasks.c`, la función `task_begin` hace
`tasks_by_thread[tid]++` sobre un arreglo compartido donde los 4 hilos escriben posiciones **vecinas**. No hay
carrera (es `atomic`). Si cada tarea hiciera esa actualización millones de veces, ¿crees que el programa
tardaría más, menos o igual que si cada hilo contara en una variable local? ¿Por qué?

<details><summary>Para comparar el jueves</summary>

a) Con `speedup=2.10` y p = 4: eficiencia 0.52; f = (1/2.10 − 1/4) / (1 − 1/4) = (0.476 − 0.25) / 0.75 ≈ **0.30**.
   Esa "fracción secuencial" no es solo la mezcla final: Karp–Flatt mete en el mismo saco la sobrecarga de
   tareas, las esperas en `taskwait` y el ancho de banda. En S10 se ve cómo separarlas.
b) Tardaría **más**: cuatro posiciones `long` vecinas caben en una misma línea de caché de 64 bytes; cada
   escritura de un hilo invalida la copia de esa línea en los otros núcleos aunque toquen posiciones
   distintas. Se llama **falso compartido** (*false sharing*) y es tema de S10. En `mergesort_tasks.c` no
   importa porque se hace una vez por tarea (1 022 veces en total), no millones.
</details>
