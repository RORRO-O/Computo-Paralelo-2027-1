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

## Ejercicio 2 · Intercalado, Unidad III (10 min): "MPI es más lento que OpenMP en un nodo"

En la S11 paralelizaste Jacobi 1D con `#pragma omp parallel for` y doble búfer. Ahí no hay halos, pero hay una
**barrera implícita** al final de cada `omp for` (una por iteración) y las fronteras entre bloques de hilos
comparten líneas de caché.

1. Mide (o estima) cuánto cuesta una barrera con 4 hilos: compila y corre un ciclo de 100 000 iteraciones
   vacías dentro de `#pragma omp parallel` con `#pragma omp barrier`, cronometra con `omp_get_wtime()` y divide.
   Reporta el valor en µs.
2. Compara ese costo con 2α del halo MPI que mediste hoy. Con esos dos números, ¿es cierto que "MPI dentro de
   un nodo siempre pierde contra OpenMP"? Responde en tres líneas con los números.

## Ejercicio 3 · Preparación para el jueves 19 de noviembre (10 min)

La S06 cierra la Unidad IV con tipos derivados y comunicadores (panorama) y un taller hacia el H2.

1. Lee la descripción de `MPI_Type_vector` en la página de manual de Open MPI (`man MPI_Type_vector` o
   docs.open-mpi.org) y responde en dos líneas: si una matriz de 1 000 × 1 000 `double` está guardada por
   filas, ¿cuántos mensajes necesitarías para enviar una **columna** sin tipos derivados, y cuántos con
   `MPI_Type_vector`?
2. Para el H2: escribe tal como está hoy la tabla de *speedup* de la V2 (OpenMP) de tu proyecto. Marca con una
   línea qué le falta según el protocolo del curso (repeticiones, mediana, hardware, T(1) secuencial, gráfica
   con línea ideal). Eso es lo primero que se revisa en el taller del jueves.

<details><summary>Qué cuenta y cómo se revisa</summary>

En el 3er parcial la tarea espaciada no tiene ponderación propia (ver `planeacion/mapa-evaluacion.md`); su
valor está en que el ejercicio 1 es la interpretación de la Parte D de la P5 y el ejercicio 3.2 es la lista
de cotejo del H2. En la recuperación del jueves 19 se preguntan el valor de la barrera (ej. 2) y el número de
mensajes (ej. 3.1).
</details>
