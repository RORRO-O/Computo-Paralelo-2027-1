> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S06 · jueves 3 de diciembre de 2026 · 10:30–12:00 · Salón 3208

# Tarea espaciada · S06 (30 minutos; es el estudio para el Examen 3, no trabajo adicional)

**Entrega.** Un archivo `tareas/U5-S06.md` en tu repositorio del curso (el mismo de las tareas anteriores), más
`caza4_<tema>_buggy.cu` y `caza4_<tema>_numba.py` si hiciste el ejercicio 1c, antes del **lunes 7 de diciembre de
2026, 10:30** (inicio de la sesión C1). Individual, salvo el 1c, que es por parejas. Se autocalifica con las claves
en `<details>` al inicio de esa sesión (2 min); el profesor registra entrega, no acierto, y revisa 3 al azar por
parcial.

Esta tarea no tiene peso propio; el examen de práctica del jueves 3 de diciembre y el 10–20 % acumulativo del
Examen 3 toman ítems de aquí. En concreto: el ejercicio 1a es un ítem de opción múltiple y de diseño breve del
Examen 3 con otros números; el 2 es su parte acumulativa de la Unidad III.

Ese mismo fin de semana vencen la **Práctica 6** (domingo 6 de diciembre, 23:59) y la **entrega final del proyecto**
(lunes 7, 10:30, etiqueta `entrega-final`). Haz esta tarea el viernes; el ejercicio 3 **es** la última revisión de
la entrega.

IA: verde para que te explique una colectiva o un mensaje de `nvcc`; amarillo (declarado) para que revise tu
`caza4` y te diga si el síntoma es reproducible; rojo para que corrija los cazadores por ti o te resuelva el
examen de práctica.

## 1. Del tema (15 min) · Terminar la caza y elegir con justificación

**a) Elección justificada (5 min).** Para cada caso elige **una** de tres técnicas vistas en sesiones distintas de la
Unidad V: (1) una `atomicAdd` por hilo sobre memoria global (S03); (2) reducción en árbol en memoria compartida con
segunda etapa en el anfitrión (S03); (3) acumulador privado por bloque en memoria compartida y un volcado atómico
por bloque (S03, fase Crear). Escribe la letra y **un número** que la justifique (cuántas atómicas globales, cuántas
barreras, cuántos bytes bajan al anfitrión).

- (i) Suma de `2^24` `float` en una T4.
- (ii) Histograma de 16 bins de `2^24` bytes.
- (iii) Máximo de 1 000 valores, una sola vez, dentro de un programa que ya tiene esos datos en la GPU.

**b) Modificar (5 min).** Si `make cazar` no dice `bichos cazados: 3/3`, termina las correcciones en los tres
archivos **y** en los espejos Numba. Pega la última línea de `make cazar` en `tareas/U5-S06.md`.

**c) Crear (5 min para la ficha; el programa entra en los 15 si ya tienes la plantilla de caza2 a la mano).**
Escribe `caza4_<tema>_buggy.cu` y su espejo según `practica-guiada/README.md`, sección "Crear" (temas: `tiempo`,
`copias`, `return`, `igualdad`), con la ficha sellada. Tu pareja lo caza. Si no coincidieron fuera de clase, cázalo
tú mismo y dilo en el archivo.

<details><summary>Clave de 1a y criterio de 1b–1c</summary>

(i) <strong>(2)</strong>: 0 atómicas globales, 8 barreras por bloque, <code>⌈2^24 / 256⌉ = 65 536</code> parciales
(256 KB) al anfitrión; (1) haría 16 777 216 atómicas sobre <strong>una</strong> dirección (en S03: uno o dos órdenes
de magnitud más lenta) y, en <code>float</code>, con error de redondeo que crece con <code>n</code>. (ii)
<strong>(3)</strong>: 16 atómicas globales por bloque (<code>16 × 65 536 ≈ 10^6</code>) en lugar de <code>2^24</code>
sobre 16 direcciones; (2) no aplica directamente (no es una suma escalar). (iii) <strong>(1)</strong> con
<code>atomicMax</code> si los datos son enteros, o (2) si son <code>float</code>: con 1 000 valores el costo es
despreciable y manda la simplicidad; lanzar un árbol de dos etapas para 1 000 datos una sola vez no se amortiza;
copiar 4 KB y hacerlo en la CPU también vale si lo justificas con el costo de la copia (≈ 10 µs de latencia).
1b: la línea esperada es <code>---- bichos cazados: 3/3 (9 PASS, 0 FAIL, 0 SKIP)</code>. 1c: el criterio de "listo"
está en el README; el error más fácil de reproducir en CUDASIM es <code>igualdad</code>; <code>tiempo</code> y
<code>copias</code> solo se ven en la GPU, y el encabezado debe decirlo.
</details>

## 2. Intercalado (8 min) · Unidad III: el mismo histograma en la V2

La V2 (OpenMP) de un equipo hace `hist[b]++` dentro de `#pragma omp parallel for` sobre `2^24` elementos y 16 bins.
Con 1, 2, 4 y 8 hilos (laptop de 4 núcleos físicos) midieron, con el protocolo: `T = 0.080, 0.095, 0.120, 0.260 s`
usando `#pragma omp critical` alrededor del incremento; la V1 tarda `0.052 s`.

(a) Calcula `S(p)` y `E(p)` para `p = 2, 4` y la fracción secuencial de Karp–Flatt `f(p)`. ¿Qué indica que `f`
crezca con `p`?
(b) Elige entre `atomic`, `critical`, `reduction(+:hist[:16])` (OpenMP ≥ 4.5) y "un arreglo privado por hilo que se
suma al final" para arreglarlo, y di en una línea por qué las otras dos que descartaste son peores aquí.
(c) ¿Qué técnica de la pregunta 1a es la misma idea que tu elección en (b)?

<details><summary>Respuesta</summary>
(a) <code>T(1)</code> es la V1 (0.052 s): <code>S(2) = 0.55</code>, <code>E(2) = 0.27</code>; <code>S(4) = 0.43</code>,
<code>E(4) = 0.11</code>. <code>f(2) = (1/0.55 − 1/2)/(1/2) = 2.64</code>; <code>f(4) = (1/0.43 − 1/4)/(3/4) = 2.77</code>.
Una <code>f</code> mayor que 1 y creciente dice que el tiempo paralelo <strong>crece</strong> con los hilos: la
sincronización domina (16 bins, 16 millones de secciones críticas). (b) <strong>Arreglo privado por hilo</strong> (o
<code>reduction(+:hist[:16])</code>, que es lo mismo escrito por el compilador): 16 millones de incrementos sin
sincronizar y 16 × <code>p</code> sumas al final. <code>atomic</code> es más barata que <code>critical</code> pero
sigue serializando sobre 16 direcciones y, con 16 bins contiguos, mete falso compartido (idea errónea 14);
<code>critical</code> es lo que ya tienen. (c) La técnica (3) de 1a: acumulador privado (por bloque allá, por hilo
aquí) y un volcado al final. El patrón es el mismo en OpenMP, MPI (<code>Reduce</code> de arreglos) y CUDA.
</details>

## 3. Preparación para el lunes 7 de diciembre (7 min) · Entrega final y Examen 3

**a) Entrega final (equipo).** Clona tu repositorio en una carpeta nueva y corre
`bash proyecto/entrega-final/scripts/verificar_entrega.sh /ruta/al/clon` (desde el repositorio del curso). Pega el
resumen en `tareas/U5-S06.md` y escribe quién cierra cada ítem en **no** antes del domingo. Recuerda: la etiqueta
`entrega-final` se crea y se empuja **antes de las 10:30** del lunes (`git tag -a entrega-final -m "Entrega final"
&& git push origin entrega-final`); el PDF (8–12 páginas) va en `reporte/reporte.pdf` dentro del repositorio.

**b) Ensayo de defensa (equipo).** Prepara la demo de 2 minutos que se ensaya el lunes: clonar la etiqueta,
`make test`, correr V2 con 1 y `p` hilos y abrir el *notebook* de V3 ejecutado. Lee `proyecto/defensa/lista-cotejo-pares.md`:
es la lista con la que otro equipo te va a revisar el lunes. Prepara el formato que el profesor anunció hoy
(opción a, b o c de `proyecto/defensa/logistica-defensa.md`).

**c) Examen 3 (individual).** Vuelve a resolver, **con la clave cerrada**, los tres ítems del examen de práctica en
los que perdiste más puntos; después compara. Intercambia con tu pareja las tres preguntas que escribiste en la
tarea de la S05 (ejercicio 3a) y contesta las suyas en ≤ 5 líneas cada una. Anota en una línea si tu predicción de
calificación (hoja de calibración de hoy) cambió y por qué.

<details><summary>Para autoverificar</summary>
(a) Sin clave: el criterio es que el verificador no reporte ítems en <strong>no</strong> entre el 1 y el 24, y que el
ítem 25 (cinco números del PDF encontrados en los CSV) lo haya revisado alguien que no escribió el reporte. (b) La
demo cabe en 2 minutos solo si el clon y la compilación ya se probaron en una máquina distinta de la que se usó
para desarrollar. (c) Si al segundo intento un ítem sigue mal, ese es el tema de tu asesoría del viernes o del
lunes; llévalo escrito (qué intentaste y qué observaste).
</details>
