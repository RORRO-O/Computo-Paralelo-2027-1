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

**3.** Dos procesos ejecutan cada uno `MPI_Send` al otro y después `MPI_Recv` del otro. El programa es:
(a) correcto · (b) incorrecto aunque a veces termine · (c) correcto solo con mensajes grandes.

<details><summary>Respuesta</summary>
<strong>(b)</strong>. Termina solo si <code>MPI_Send</code> copia a un búfer interno (mensaje chico, ≈ &lt; 4 KB en
Open MPI local); con mensajes grandes los dos esperan al <code>Recv</code> del otro. Un programa seguro termina
aunque todos los <code>Send</code> bloqueen: <code>MPI_Sendrecv</code>, orden por paridad o <code>Isend/Irecv +
Wait</code> (idea errónea 17).
</details>

**4.** Cuatro procesos; `total = 0` en todos; `MPI_Reduce(&x, &total, 1, MPI_INT, MPI_SUM, 0, MPI_COMM_WORLD)`.
Después de la llamada, ¿qué vale `total` en el rango 2?

<details><summary>Respuesta</summary>
<strong>0</strong>: <code>MPI_Reduce</code> deja el resultado solo en la raíz y no toca el búfer de los demás. Si todos
lo necesitan, <code>MPI_Allreduce</code> (idea errónea 16; es el ítem III.1 del examen de práctica).
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

**8.** `__syncthreads()` sincroniza: (a) todos los hilos de la GPU · (b) los hilos de un bloque · (c) los 32 hilos
de un *warp* · (d) el anfitrión con el dispositivo.

<details><summary>Respuesta</summary>
<strong>(b)</strong>. Entre bloques solo se sincroniza al terminar el <em>kernel</em> (segunda etapa en el anfitrión o
en otro <em>kernel</em>); (d) es <code>cudaDeviceSynchronize()</code> (idea errónea 25).
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
preguntas se corresponden con secciones del examen de práctica: 1 y 9–10 → V; 2 y 4 → III.1 y IV.a; 3 → I.1; 5 y 7 →
II.2 y IV.b; 6 → V.b; 8 → I.6. Un ítem con menos de 60 % de aciertos se suma a los candidatos del bloque 60–72
("los tres ítems peor contestados") aunque el examen no lo confirme, y se repite con pista en la recuperación del
lunes 7 de diciembre.
