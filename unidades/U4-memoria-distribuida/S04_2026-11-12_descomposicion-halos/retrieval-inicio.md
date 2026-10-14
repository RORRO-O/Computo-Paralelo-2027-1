> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S04 · jueves 12 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S04 · Recuperación de inicio

Individual, por escrito, sin apuntes ni dispositivos. Tienes 4 minutos. Después se proyectan las respuestas y levantas la
mano por cada pregunta que acertaste. No cuenta por acierto; cuenta por intentarlo.

1. **(S03, martes 10 de noviembre)** ¿En qué se diferencian `MPI_Reduce` y `MPI_Allreduce`? Di quién termina con el resultado
   en cada caso y qué procesos deben llamar a cada una.

2. **(S03)** En el producto matriz-vector distribuido del Lab 1: ¿qué colectiva usaste para repartir las filas de `A`, cuál
   para que todos los procesos tuvieran el vector `x` completo y cuál para juntar el vector resultado en un proceso?

3. **(Unidad II, método de Foster)** ¿Qué significa *aglomerar*? Si la partición de una malla 1D de 12 celdas produce 12 tareas
   (una por celda) y tienes 3 procesos, ¿cómo las agruparías y qué comunicación desaparece al agruparlas así?

4. **(Unidad III, S11, lunes 26 de octubre)** En Jacobi 1D con OpenMP usaste dos arreglos, `u` y `u_new`, y los intercambiabas al
   final de cada iteración. ¿Por qué no se puede escribir el resultado en el mismo arreglo `u` que se está leyendo?

5. **(Anticipa S04)** Reparte 12 celdas entre 3 procesos en bloques contiguos. Para calcular sus celdas en una iteración,
   ¿qué valores necesita el proceso 1 que **no** están en su memoria? ¿En qué proceso están?

<details>
<summary>Respuestas (abrir a los 4 minutos)</summary>

1. Ambas combinan un valor de cada proceso con una operación (`MPI_SUM`, `MPI_MAX`, …). `MPI_Reduce` deja el resultado solo en el
   proceso raíz; `MPI_Allreduce` lo deja en **todos**. Las dos son colectivas: las llaman todos los procesos del comunicador, no
   solo el raíz.

2. Repartir filas: `MPI_Scatter` (o `MPI_Scatterv` si las filas no se reparten exacto). Que todos tengan `x`: `MPI_Bcast`. Juntar
   el resultado: `MPI_Gather` (o `MPI_Gatherv`). Si tu Lab 1 usó otra variante equivalente, cuenta como correcta.

3. Aglomerar es agrupar tareas finas en tareas más grandes para reducir comunicación y sobrecarga **sin perder el paralelismo
   útil** (no es "juntar todo en un proceso"). Agruparía celdas contiguas: 1–4, 5–8 y 9–12. Desaparece la comunicación entre
   celdas vecinas del mismo bloque; solo queda la de las dos orillas de cada bloque.

4. Porque `u_new[i]` depende de `u[i-1]` y `u[i+1]` de la **iteración anterior**. Si se escribiera en `u`, al calcular la celda
   `i+1` ya se leería un `u[i]` nuevo: eso es Gauss–Seidel (otro método, con otro orden de dependencia), no Jacobi, y en paralelo
   sería además una carrera de datos.

5. El proceso 1 tiene las celdas 5–8. Necesita la celda 4 (está en el proceso 0) y la celda 9 (está en el proceso 2). Hoy
   veremos dónde se guardan esas copias (celdas fantasma) y cómo se refrescan en cada iteración.

</details>

**Para el profesor.** Si menos del 60 % acierta la pregunta 1, antes de empezar el ejemplo resuelto repetir en el pizarrón la regla
"colectiva = la llaman todos" con `Allreduce`: hoy se usa en cada iteración y su mal uso cuelga el programa (CT2).
