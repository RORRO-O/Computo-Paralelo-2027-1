> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S13 · jueves 29 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S13 · Recuperación larga de inicio (8 minutos, individual, sin apuntes ni dispositivos)

Sesión de repaso: ocho preguntas acumulativas (seis de la Unidad III, dos de las Unidades I–II) en lugar de
cinco. Escribe las respuestas en una hoja con tu número de lista. A los 6 minutos se muestran las respuestas;
cuenta tus aciertos. No se califica por acierto: cuenta por participación (3 % del 2.º parcial, con los
*exit tickets*). Cada respuesta es una línea, un número o una letra.

**1. (S12, martes 27 de octubre)** Perfil de una V1 (mediana de 5, `-O2`): lectura 0.5 s, núcleo 3.0 s,
escritura 0.5 s. Solo se paraleliza el núcleo. ¿Cuánto vale la fracción paralelizable `f_p` y de qué se calcula
(¿de líneas o de tiempo?)? (un número y una palabra)

**2. (S12)** Antes de escribir el `#pragma` en el ciclo que domina tu V1, ¿qué dos cosas haces primero, en
orden? (dos palabras o dos frases cortas)

**3. (S07, jueves 15 de octubre)** Elige la única corrección correcta para
`if (x[i] > max_val) max_val = x[i];` dentro de un `parallel for`:
A) `#pragma omp atomic` antes del `if` · B) `reduction(max:max_val)` · C) `private(max_val)` · D) nada, cada
hilo tiene su `i`

**4. (S08, lunes 19 de octubre)** Ciclo `for (i < n) for (j < i) …` (el trabajo de la iteración `i` crece con
`i`) con 4 hilos. Elige: A) `schedule(static)` · B) `schedule(dynamic, 1)` · C) `schedule(dynamic, 256)` o
`schedule(static, 16)` · D) da igual, el reparto no afecta el tiempo

**5. (S09, martes 20 de octubre)** `#pragma omp taskwait` espera a… ¿las **hijas directas** de la tarea actual
o a **todas** sus descendientes? (una palabra)

**6. (S11, lunes 26 de octubre)** En Jacobi 1D, ¿por qué se escribe `u_new[i]` en un arreglo distinto de
`u[i]` en lugar de actualizar en el lugar? (una línea)

**7. (Unidad I)** Un programa tarda 20 s en serie y 4 s de ese tiempo no se pueden paralelizar. Según Amdahl,
¿cuál es el *speedup* máximo con **infinitos** hilos? ¿Y la **eficiencia** con 4 hilos si se logra el *speedup*
que predice Amdahl? (dos números)

**8. (Unidad II, método de Foster)** Escribe las cuatro etapas en orden y di en cuál se decide el tamaño del
*chunk* de un `schedule(dynamic, c)`. (cuatro palabras y una de ellas)

<details><summary>Respuestas</summary>

1. `f_p = 3.0 / 4.0 = 0.75`, calculada con **tiempos** de la versión secuencial, nunca con líneas de código
   (idea errónea 2).
2. **Medir** dónde está el tiempo (perfil por secciones, protocolo) y **listar las dependencias** del ciclo
   dominante (qué lee y qué escribe cada iteración). Hasta entonces, el pragma (ideas 29 y 30).
3. **B.** Un `if` con lectura y escritura condicional no cabe en `atomic` (idea 8); `private` descarta el
   resultado (idea 9); "cada hilo tiene su `i`" confunde el índice con la variable compartida (idea 7d).
   `critical` alrededor del `if` también sería correcto, pero más caro.
4. **C.** Trabajo creciente: `static` deja al último hilo casi todo (S08: 58 contra 10 unidades); `dynamic,1`
   paga una atómica por iteración (idea 11); `dynamic` con *chunk* mediano o `static,c` cíclico balancean sin
   pagar tanto. D es la idea nueva del examen de práctica I.3-C.
5. Solo a las **hijas directas** (idea 13). Para todas las descendientes: `taskgroup`, o un `taskwait` en cada
   nivel de la recursión.
6. Porque si se actualiza en el lugar, la iteración `i` leería `u[i−1]` **ya actualizado** por otra iteración
   u otro hilo: dependencia entre iteraciones y resultado distinto del secuencial (idea 30). Con doble búfer
   cada iteración solo escribe `u_new[i]` y al final se intercambian los punteros.
7. `f = 4/20 = 0.2`; `S(∞) = 1/0.2 = `**`5`**. Con 4 hilos: `S(4) = 1/(0.2 + 0.8/4) = 2.5`; `E(4) = 2.5/4 =
   `**`0.625`** (62.5 %). Eficiencia y *speedup* no son lo mismo (idea 3).
8. **Partición, comunicación, aglomeración, mapeo.** El *chunk* es la **aglomeración**: cuántas tareas finas
   (iteraciones) se agrupan en una unidad; asignarlas dinámicamente a hilos es el **mapeo**. Aglomerar no es
   juntar todo en un hilo (idea 28).
</details>

**Para el profesor.** Las preguntas 1 y 2 son de S12: anotar su porcentaje de acierto. Si la 1 queda bajo
60 %, el ítem V del examen de práctica se discute **primero** en el bloque 50–80 aunque no esté entre los tres
peores por manos, porque el error (fracción por líneas) invalida todo el ítem. Si la 3 o la 5 quedan bajo
60 %, CT2 se usa aunque los ítems II–IV no estén entre los peores. Si algún ítem de S12 quedó bajo 60 % en su
propia sesión, se repite aquí con pista en lugar de la pregunta 2 (`07-guia-de-autoria.md`, §A.8).
