> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S05 · martes 17 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# S05 · Recuperación de inicio (5 minutos, individual, sin apuntes)

Responde por escrito. A los 4 minutos se proyectan las respuestas. Esta recuperación es zona sin IA.

## 1. Halos en Jacobi 1D (S04, jueves 12 de noviembre)

Un proceso **interior** (ni el rango 0 ni el último) ejecuta una iteración de Jacobi 1D con descomposición
por bloques. ¿Cuántos valores recibe en esa iteración, de quién, y qué cambia para el rango 0?

<details><summary>Respuesta</summary>

Recibe **2 valores**: el último punto del vecino izquierdo (va a su halo `u[0]`) y el primer punto del vecino
derecho (va a su halo `u[n_local+1]`). El rango 0 no tiene vecino izquierdo: su `left` es `MPI_PROC_NULL`,
la recepción de ese lado no hace nada y el halo `u[0]` conserva el valor de la frontera física.
</details>

## 2. `MPI_Irecv` y `MPI_Waitall` (S04)

Escribes `MPI_Irecv(&u[0], 1, MPI_DOUBLE, left, 0, comm, &req)` y en la línea siguiente lees `u[0]`.
¿Qué está mal y qué llamada falta?

<details><summary>Respuesta</summary>

`MPI_Irecv` solo **inicia** la recepción; al regresar, el contenido de `u[0]` es indefinido. Falta
`MPI_Wait(&req, ...)` (o `MPI_Waitall` si hay varias solicitudes) **antes** de leer el búfer. Lo mismo
aplica al búfer de un `MPI_Isend`: no se modifica hasta que su `Wait` termina.
</details>

## 3. Amdahl y Gustafson (Unidad I)

En una frase cada una: ¿qué supone la ley de Amdahl sobre el tamaño del problema y qué supone la de
Gustafson? ¿Con qué tipo de escalabilidad se relaciona cada una?

<details><summary>Respuesta</summary>

Amdahl: el **tamaño del problema es fijo** y se agregan procesadores; el *speedup* queda acotado por la
fracción secuencial (1/f). Es el marco de la **escalabilidad fuerte**. Gustafson: el **tamaño crece con el
número de procesadores** manteniendo el tiempo; el *speedup* escalado es `p − f(p − 1)`. Es el marco de la
**escalabilidad débil**.
</details>

## 4. Protocolo de medición y Parte D de la Práctica 5 (Unidad III, S10; enunciado de P5)

La Parte D de la Práctica 5 pide una tabla de escalabilidad. ¿Qué columnas lleva según el protocolo del curso,
cuántas repeticiones hay detrás de cada mediana y contra qué `T(1)` se calcula el *speedup*?

<details><summary>Respuesta</summary>

`config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia` (en MPI la columna `hilos` son
procesos). Cada mediana sale de **5 repeticiones tras 1 de calentamiento**, con `-O2`. El *speedup* se
calcula contra el **mejor programa secuencial**, no contra la versión MPI con un proceso (si se usa esa,
se declara y se reportan ambas). Los procesos van de 1 hasta el número de núcleos físicos; uno más allá se
reporta **aparte** como sobre-suscrito.
</details>

## 5. Lo que viene hoy: costo de un mensaje

Con latencia α = 0.5 µs y ancho de banda β = 1 GB/s, ¿cuánto tarda enviar un mensaje de 8 bytes? ¿Y uno
de 1 MB? ¿Qué término del costo domina en cada caso?

<details><summary>Respuesta</summary>

Modelo `T_com = α + m/β`. Para 8 bytes: 0.5 µs + 0.008 µs ≈ **0.51 µs**; domina la **latencia** (el tamaño
casi no importa). Para 1 MB: 0.5 µs + 1000 µs ≈ **1.0 ms**; domina el **ancho de banda**. Los halos de
Jacobi 1D son mensajes de 8 bytes: su costo es prácticamente α, sin importar n.
</details>

---

**Para el profesor.** Conteo rápido de manos por pregunta. Si la pregunta 1 o la 2 queda por debajo de 60 %,
se repasa el patrón `Irecv → Isend → Waitall` en el pizarrón antes de la mini-lección (2 minutos, con el
código de `practica-guiada/jacobi_mpi.c` proyectado). Si la 4 falla, la Parte D de la P5 va a llegar mal:
se proyecta el encabezado del CSV y se deja visible toda la sesión.
