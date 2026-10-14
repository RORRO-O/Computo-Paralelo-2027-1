> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S05 · martes 1 de diciembre de 2026 · 08:30–10:00 · Lab LS4

# Tarea espaciada · S05 (30–40 minutos)

Tres ejercicios: uno del tema de hoy, uno intercalado de la Unidad IV y uno de preparación para la S06 (jueves 3 de
diciembre, repaso de Unidades IV–V). **Entrega**: los tres van en un archivo `tareas/U5-S05.md` del repositorio de tu
equipo (ejercicio 1 en equipo; 2 y 3 individuales, firmados con número de lista) antes del jueves 3 de diciembre a
las 10:30. En el 3er parcial las tareas no tienen ponderación propia (ver `planeacion/mapa-evaluacion.md`): lo que
produce el ejercicio 1 entra directo en la Parte D de P6 y en la sección V3 del reporte final; los ejercicios 2 y 3
son preparación para el Examen 3.

## 1. Del tema (equipo, ~15 min, Colab) · mapeo 1D vs. 2D

Si no lo hiciste en clase, completa `TODO(1)` de `jacobi_step_1d` en `practica-guiada/flatten_map_2d.cu` (el
notebook `notebook_colab.ipynb` ya tiene las celdas). Luego corre, con `1024 1024 100`, tres configuraciones y llena
la tabla con las medianas que imprime el programa:

| Config | `t_kernel` (s) | `t_total` (s) | *speedup* sin transf. | *speedup* con transf. | Verificación |
|---|---|---|---|---|---|
| `2d 16 16` | | | | | |
| `1d 16 16` (256 hilos lineales) | | | | | |
| `2d 32 8` | | | | | |

Escribe 3 líneas: ¿hay diferencia entre 2D 16 × 16 y 1D 256? Explícala (o explica por qué no la hay) con la
coalescencia de la S02: cuántos floats contiguos lee un *warp* en cada caso. Anota GPU y fecha. Guarda el CSV del
notebook en `resultados/`.

## 2. Intercalado (individual, ~10 min, Unidad IV · modelo de costo aplicado a PCIe)

Un equipo porta una V2 de Jacobi con malla de 2048 × 2048 floats (16 777 216 bytes) y 200 iteraciones. El *kernel*
tarda 0.25 ms por iteración. La V1 tarda 3.0 s. Modela cada transferencia como en la Unidad IV:
`t = latencia + bytes / ancho_de_banda`, con latencia = 10 µs y ancho de banda = 6 GB/s (memoria paginable típica
en Colab).

(a) Opción A: subir la malla una vez y bajarla una vez. ¿Cuánto tardan las transferencias? ¿Cuál es el *speedup*
con transferencias?
(b) Opción B: subir y bajar la malla en **cada** iteración. Mismas dos preguntas.
(c) En la Unidad IV, con 1000 mensajes de 8 bytes dominaba la latencia. ¿Qué término domina aquí y por qué la
conclusión ("copia una vez") es la misma aunque la razón sea distinta?

<details><summary>Respuestas</summary>
(a) Una transferencia: 10 µs + 16 777 216 B / 6 GB/s ≈ 0.01 ms + 2.80 ms = 2.81 ms. Dos: ≈ 5.6 ms. Kernels: 200 × 0.25 = 50 ms. Total ≈ 55.6 ms → <em>speedup</em> ≈ 3.0 / 0.0556 ≈ <strong>54×</strong>.
(b) 400 transferencias × 2.81 ms ≈ 1.12 s. Total ≈ 1.17 s → <em>speedup</em> ≈ <strong>2.6×</strong>.
(c) Aquí domina el término de volumen (bytes / ancho de banda): la latencia total de 400 copias es solo 4 ms. En MPI con mensajes de 8 bytes dominaba la latencia. En ambos casos la regla es reducir el número de transferencias, pero en GPU el daño principal de copiar por iteración es mover <em>todos</em> los datos 200 veces, no pagar 400 latencias.
</details>

## 3. Preparación para la S06 (individual, ~10 min)

La S06 (jueves 3 de diciembre, 10:30) abre con una recuperación larga y un examen de práctica de las Unidades IV–V.

(a) Escribe **tres preguntas tipo examen con su respuesta**, de ≤ 5 líneas cada una: una de colectivas MPI
(`Bcast`/`Scatter`/`Reduce`: quién las llama y qué recibe cada rango), una de halos o modelo de costo (U4 S04–S05),
y una de CUDA que use un número (transferencias, tamaño de bloque, índice lineal). Llévalas: se intercambian en
parejas al inicio de la S06.
(b) Predice tu calificación del Examen 3 (0–100) y escribe en una línea en qué tema te sientes menos seguro.
Guárdala: se compara con la real el lunes 14 de diciembre.
(c) Lee la lista de cotejo de la entrega final en `proyecto/entrega-final/` y marca qué le falta hoy al repositorio de
tu equipo (sin resolverlo todavía).
