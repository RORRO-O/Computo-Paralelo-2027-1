> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S06 · jueves 3 de diciembre de 2026 · 10:30–12:00 · Salón 3208

# Recuperación larga de inicio · S06 (acumulativa, Unidades IV–V + métricas)

Ocho minutos, individual, sin apuntes ni dispositivos (zona sin IA). Diez preguntas: cuatro de MPI, cuatro de CUDA
y dos de OpenMP/métricas; cada una se contesta con un número, una palabra o una opción. Al minuto 8 se muestran las
respuestas y se piden manos por pregunta. Cuenta la entrega, no el acierto. Las preguntas 5 y 6 son de la sesión
anterior (martes 1 de diciembre); las demás, de toda la Unidad IV, la Unidad V y las métricas de las Unidades I–III.

## MPI (Unidad IV)

**1.** Un mensaje de 8 bytes con latencia α = 0.5 µs y ancho de banda β = 2 GB/s tarda, aproximadamente: (a) 4 ns ·
(b) 0.5 µs · (c) 4 µs · (d) depende del número de procesos.

<details><summary>Respuesta</summary>
<strong>(b)</strong>. <code>T = α + m/β = 0.5 µs + 8 B / 2 GB/s = 0.5 µs + 0.004 µs</code>: con mensajes chicos manda la
latencia. Un halo de Jacobi cuesta α completa aunque lleve un solo <code>double</code> (idea errónea 21).
</details>

**2.** ¿Qué procesos deben llamar a `MPI_Bcast(&n, 1, MPI_INT, 0, MPI_COMM_WORLD)`? Contesta en una línea.

<details><summary>Respuesta</summary>
<strong>Todos</strong> los procesos del comunicador, con la misma raíz y los mismos argumentos; la llamada aparece una
vez, fuera de <code>if (rank == 0)</code>. Si solo la llama la raíz, los demás esperan para siempre o siguen con un
<code>n</code> equivocado, sin mensaje de error (idea errónea 18).
</details>

**3.** Después de `MPI_Isend(buf, n, MPI_DOUBLE, 1, 0, MPI_COMM_WORLD, &req)`, ¿desde cuándo puedes volver a
escribir en `buf`? (a) en la línea siguiente · (b) cuando regrese `MPI_Wait(&req, …)` · (c) cuando el rango 1 llame a
`MPI_Recv` · (d) nunca: `buf` queda reservado.

<details><summary>Respuesta</summary>
<strong>(b)</strong>. <code>MPI_Isend</code> solo <em>inicia</em> el envío; hasta que <code>MPI_Wait</code> (o un
<code>MPI_Test</code> que dé completo) termina la operación, el búfer es de MPI. Escribir antes puede mandar datos
mezclados, sin ningún error. (c) no sirve: el emisor no puede saber cuándo llama el otro a <code>Recv</code>; la
espera es local (idea errónea 17: "regresar" no es "terminar"; halos de U4 S04).
</details>

**4.** Jacobi 1D con 4 procesos en línea (los extremos no son periódicos): por cada frontera entre dos procesos
vecinos se manda un valor de halo en cada dirección. ¿Cuántos mensajes de halo hay por iteración en total?

<details><summary>Respuesta</summary>
<strong>6</strong> = 2(p − 1): 3 fronteras × 2 direcciones. Los rangos 0 y 3 mandan uno cada uno; los rangos 1 y 2,
dos. Cada mensaje cuesta al menos α aunque lleve un solo <code>double</code> (idea errónea 21); por eso el proceso
interior paga <code>2α</code> por iteración en el modelo <code>T_p = (n/p)·t_c + 2α</code>.
</details>

## CUDA (Unidad V)

**5. (Sesión anterior.)** Una imagen de 480 filas × 640 columnas aplanada por filas. ¿Qué índice lineal tiene el
píxel (fila 2, columna 5)?

<details><summary>Respuesta</summary>
<code>2 · 640 + 5 = <strong>1285</strong></code>. La fórmula es <code>fila · ancho + columna</code>; el error típico
es multiplicar por el número de filas (480).
</details>

**6. (Sesión anterior.)** Un equipo reporta "*speedup* del *kernel*: 45×"; otro, para el mismo programa, "*speedup*
de la V3: 4×". Ambos midieron bien. ¿Cuál de los dos describe lo que gana el usuario del programa?

<details><summary>Respuesta</summary>
El <strong>4×</strong>: incluye las transferencias H2D/D2H (y lo que quedó en CPU). El protocolo exige reportar los
dos, etiquetados (idea errónea 24).
</details>

**7.** `n = 1000`, `block = 256`. ¿Cuántos bloques se lanzan y cuántos hilos quedan ociosos?

<details><summary>Respuesta</summary>
<code>(1000 + 255) / 256 = <strong>4</strong></code> bloques; <code>4 · 256 − 1000 = <strong>24</strong></code>
ociosos (los detiene la guardia <code>if (i &lt; n)</code>). Con <code>n / block = 3</code> faltarían 232 elementos.
</details>

**8.** Un *kernel* declara `__shared__ float s[256];` y se lanza con `<<<4, 256>>>`. ¿Cuántas copias de `s` existen
durante la ejecución?

<details><summary>Respuesta</summary>
<strong>4</strong>, una por bloque: los 256 hilos de un bloque comparten la suya y ningún bloque ve la de otro. Por
eso la memoria compartida y <code>__syncthreads()</code> son de <strong>bloque</strong>; entre bloques solo se
sincroniza al terminar el <em>kernel</em> (idea errónea 25).
</details>

## OpenMP y métricas (Unidades I–III)

**9.** En una laptop de 4 núcleos físicos, la V2 de un equipo dio *speedup* 3.1 con 4 hilos y 2.4 con 8. En una
palabra o dos: ¿la causa más probable?

<details><summary>Respuesta</summary>
<strong>Sobre-suscripción</strong> (8 hilos en 4 núcleos físicos; los hilos 5–8 compiten por las mismas unidades).
"Más hilos siempre es más rápido" no se sostiene (ideas erróneas 1 y 20). Se acepta "falso compartido" o
"sincronización" si lo justifican con Karp–Flatt creciente.
</details>

**10.** Según el protocolo del curso, una medición válida necesita: ___ repetición(es) además del calentamiento, se
reporta la ___ y se compila con ___.

<details><summary>Respuesta</summary>
<strong>≥ 5</strong> repeticiones; la <strong>mediana</strong> (con mín y máx); <strong>-O2</strong> (nunca
<code>-O0</code>). Además: tamaño fijo declarado, hardware anotado y correctitud verificada antes de medir (idea
errónea 5).
</details>

**Para el profesor.** Anotar el conteo de manos por pregunta en la tabla de `plan-sesion.md` (bloque 0–10). Las
preguntas tocan los temas del examen de práctica sin repetir sus ítems (las respuestas se muestran dos minutos antes de
que empiece): 1 y 4 → I.2 y V.a; 2 → III.1, IV.a y CT1; 3 → I.1; 5 y 7 → II.2 y IV.b; 6 → V.b; 8 → I.6, II.2 y CT3;
9–10 → I.5 y V. Un ítem con menos de 60 % de aciertos se suma a los candidatos del bloque 60–72
("los tres ítems peor contestados") aunque el examen no lo confirme, y se repite con pista en la recuperación del
lunes 7 de diciembre.
