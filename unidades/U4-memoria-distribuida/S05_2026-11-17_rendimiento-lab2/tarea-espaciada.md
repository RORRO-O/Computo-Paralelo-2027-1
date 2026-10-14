> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S05 · martes 17 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# S05 · Tarea espaciada (20–40 minutos)

**Entrega:** archivo `tareas/U4-S05.md` en el repositorio de tu equipo (una entrada por integrante, con tu
nombre de usuario de Git) antes del **jueves 19 de noviembre de 2026, 10:30**. Los ejercicios 1 y 3 se
reutilizan directamente en la Parte D de la Práctica 5 (vence el **domingo 22 de noviembre, 23:59**) y en el
H2 del proyecto (**lunes 23 de noviembre, en clase**); por eso conviene hacerlos bien una sola vez. La tarea se
revisa en la recuperación del jueves.

## Ejercicio 1 · Del tema de hoy (15 min): tu modelo contra tus datos

Usa el CSV de escalabilidad fuerte que generaste en la práctica guiada (`practica-guiada/resultados/fuerte.csv`;
si no lo tienes, usa `practica-guiada/resultados-ejemplo/fuerte.csv`).

1. Calcula la fracción secuencial de Karp–Flatt `f = (1/S − 1/p) / (1 − 1/p)` para p = 2 y p = 4. ¿Crece con
   p? ¿Qué indica eso según el protocolo del curso?
2. Corre el modelo con **tus** números (α y β del `pingpong`, t_c de `jacobi_seq`):
   `python3 modelo.py --alpha-us <α> --beta-gbps <β> --tc-ns <t_c> --p 4 --n <tu N> --tabla`.
   Compara el *speedup* predicho con el medido para tu N y para n = 10 000. Escribe en cinco líneas: dónde el
   modelo acierta, dónde falla y qué costo no incluye el modelo (pista: ¿qué pasa con t_c cuando n/p cabe en
   caché? ¿qué costo agrega `MPI_Waitall` cuando un proceso llega tarde?).

<details><summary>Clave del ejercicio 1 (autocalificación)</summary>

1. Con `resultados-ejemplo/fuerte.csv` (n = 10⁶): <<KF>>. Si f crece con p hay **sobrecarga creciente**
   (protocolo §3): no es una fracción secuencial fija, es espera en `Waitall` y ancho de banda de memoria
   compartido entre procesos. Con tus datos los números cambian; lo que se califica es el cálculo y la lectura.
2. El modelo acierta el orden de magnitud y la forma: S(4) crece con n y se acerca a 4 con n = 10⁶; falla en el
   valor absoluto cerca de n* (predice el cruce en ~1 200 puntos; medido queda entre 2 000 y 4 000) porque
   (a) la "comunicación" real por iteración incluye la espera a que el vecino llegue (desbalance y *jitter*: el
   programa mide 1–3 µs, no 0.8 µs), (b) t_c no es constante: con n/p en caché L1/L2 baja hasta ~0.5 ns, y
   (c) con n grande el ancho de banda de memoria compartido limita antes que los mensajes. Bien: menciona (a) y
   una de (b)/(c) con un número. Parcial: solo describe que "difieren". Mal: concluye que el modelo "está mal"
   sin decir qué costo falta.
</details>

## Ejercicio 2 · Intercalado, Unidad III (10 min): "MPI es más lento que OpenMP en un nodo"

En la S11 paralelizaste Jacobi 1D con `#pragma omp parallel for` y doble búfer. Ahí no hay halos, pero hay una
**barrera implícita** al final de cada `omp for` (una por iteración) y las fronteras entre bloques de hilos
comparten líneas de caché.

1. Mide (o estima) cuánto cuesta una barrera con 4 hilos: compila y corre un ciclo de 100 000 iteraciones
   vacías dentro de `#pragma omp parallel` con `#pragma omp barrier`, cronometra con `omp_get_wtime()` y divide.
   Reporta el valor en µs.
2. Compara ese costo con 2α del halo MPI que mediste hoy. Con esos dos números, ¿es cierto que "MPI dentro de
   un nodo siempre pierde contra OpenMP"? Responde en tres líneas con los números.

<details><summary>Clave del ejercicio 2 (autocalificación)</summary>

1. Programa mínimo: `#pragma omp parallel { for (i < 100000) { #pragma omp barrier } }` cronometrado con
   `omp_get_wtime()` y compilado con `-O2 -fopenmp`. En la VM de autoría (4 núcleos, máquina libre):
   **0.7–1.1 µs por barrera** con 4 hilos. El mismo programa con la máquina ocupada por otros procesos dio 39 µs
   y hasta 630 µs por barrera: la sobre-suscripción castiga igual a OpenMP que a MPI.
2. 2α del halo ≈ 0.8 µs (α ≈ 0.4 µs en la VM; con tu α la cuenta cambia). Es decir, **la sincronización por
   iteración cuesta lo mismo en los dos modelos (~1 µs)**; la frase es falsa como regla. Lo que sí paga MPI de más
   es la copia de los halos y la memoria duplicada; lo que paga OpenMP de más es el falso compartido en las
   fronteras entre bloques. Bien: compara los dos números y concluye "del mismo orden". Parcial: da los números
   pero concluye "MPI pierde" sin justificarlo. Mal: no mide ni estima la barrera.
</details>

## Ejercicio 3 · Preparación para el jueves 19 de noviembre (10 min)

La S06 cierra la Unidad IV con tipos derivados y comunicadores (panorama) y un taller hacia el H2.

1. Lee la descripción de `MPI_Type_vector` en la página de manual de Open MPI (`man MPI_Type_vector` o
   docs.open-mpi.org) y responde en dos líneas: si una matriz de 1 000 × 1 000 `double` está guardada por
   filas, ¿cuántos mensajes necesitarías para enviar una **columna** sin tipos derivados, y cuántos con
   `MPI_Type_vector`?
2. Para el H2: escribe tal como está hoy la tabla de *speedup* de la V2 (OpenMP) de tu proyecto. Marca con una
   línea qué le falta según el protocolo del curso (repeticiones, mediana, hardware, T(1) secuencial, gráfica
   con línea ideal). Eso es lo primero que se revisa en el taller del jueves.

<details><summary>Clave del ejercicio 3 (autocalificación)</summary>

1. Sin tipos derivados: **1 000 mensajes** de 8 bytes (uno por elemento de la columna; cuestan ~1 000 α), o bien
   copiar la columna a un arreglo contiguo y mandar **1 mensaje** más el costo de la copia. Con
   `MPI_Type_vector(1000, 1, 1000, MPI_DOUBLE, &col)` + `MPI_Type_commit`: **1 mensaje** y sin copia manual
   (count = 1000 bloques, blocklength = 1, stride = 1000 = ancho de la fila).
2. Lista de cotejo del protocolo para la tabla del H2: 1 calentamiento + ≥ 5 repeticiones por configuración;
   mediana (con mín y máx); hilos 1, 2, 4 hasta los núcleos **físicos**, y la fila de más allá etiquetada aparte;
   T(1) = el mejor secuencial (no OpenMP con 1 hilo); tamaño fijo con T(1) ≥ 1 s; hardware, compilador y `-O2`
   declarados; gráfica *speedup* vs hilos con la línea ideal. Bien: marca todo lo que falta. Parcial: olvida T(1)
   secuencial o la fila sobre-suscrita. Mal: entrega la tabla sin marcar nada.
</details>

## Qué cuenta y cómo se revisa

Esta tarea no tiene peso propio; el examen de práctica del jueves 3 de diciembre y el 10–20 % acumulativo del
Examen 3 toman ítems de aquí. La autocalificas con las claves de arriba en los primeros minutos del jueves 19
de noviembre (2 min); el profesor registra la entrega, no el acierto, y revisa 3 al azar por parcial. Su valor
inmediato: el ejercicio 1 es la interpretación de la Parte D de la P5 y el ejercicio 3.2 es la lista de cotejo
del H2. En la recuperación del jueves 19 se preguntan el valor de la barrera (ej. 2) y el número de mensajes
(ej. 3.1).
