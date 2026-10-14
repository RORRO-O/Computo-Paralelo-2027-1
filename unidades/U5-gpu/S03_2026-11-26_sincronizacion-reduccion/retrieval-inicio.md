> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S03 · jueves 26 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# Recuperación de inicio · S03

Cuatro minutos, individual, sin apuntes ni dispositivos. Escribe en la hoja de la sesión (lado A). Al minuto 4 se
proyectan las respuestas y se piden manos por pregunta. Cuenta la entrega, no el acierto. Cada pregunta se contesta
en una línea o eligiendo una opción.

**1. (Sesión anterior, martes 24 de noviembre; es el CT3 de la S02 si no se alcanzó a votar).** Se quita la
**segunda** `__syncthreads()` del ciclo de fases de `matmul_tiled`. El programa compila, no reporta ningún error
de CUDA y en 10 ejecuciones con `n = 512` la verificación contra la CPU da `OK`. ¿Qué concluyes?

- **(a)** Que esa barrera sobraba: no hay error y el resultado coincide con la CPU.
- **(b)** Que sobraba porque la primera barrera ya sincroniza toda la GPU al final de cada fase.
- **(c)** Que hay una carrera latente: un hilo adelantado puede sobreescribir `s_A`/`s_B` de la fase siguiente
  mientras otros aún multiplican; que no se manifieste en 10 corridas depende del orden de los *warps*, no del
  código.
- **(d)** Que la carrera solo aparecería si `n` no fuera múltiplo de `TILE`.

<details><summary>Respuesta</summary>
<strong>(c).</strong> "Salió bien 10 veces" no es evidencia de que no hay carrera (idea errónea 7): el orden entre
<em>warps</em> no está garantizado y en otra GPU, con otro <code>TILE</code> o con otro <em>kernel</em> ocupando el
SM, aparece. (b) repite la idea errónea 25: <code>__syncthreads()</code> solo sincroniza el bloque. Hoy la misma
carrera se produce a propósito dentro de la reducción en árbol.
</details>

**2. (Sesión anterior).** `__shared__ float s_A[TILE][TILE];` ¿Qué hilos pueden leer ese arreglo y en qué momento
deja de existir?

<details><summary>Respuesta</summary>
Solo los hilos del <strong>mismo bloque</strong>; existe mientras el bloque está en ejecución y desaparece cuando el
bloque termina. Otro bloque, aunque corra al mismo tiempo en el mismo SM, tiene su propia copia. Por eso una suma
parcial calculada en compartida tiene que salir a memoria global antes de que el bloque termine.
</details>

**3. (Unidad III, S07 y Práctica 4).** En el histograma de OpenMP probaste tres formas de proteger `hist[bin]++`:
`critical`, `atomic` y un histograma local por hilo combinado al final. Ordénalas de la más lenta a la más rápida
y di en una línea por qué gana la última.

<details><summary>Respuesta</summary>
<code>critical</code> (≈ 73 ns por elemento en la S07) &gt; <code>atomic</code> (≈ 16 ns) &gt; local + combinación
(≈ 2.4 ns). <code>atomic</code> protege una sola actualización simple y es más barato que una región
<code>critical</code> (idea errónea 8). El local gana porque en el ciclo caliente <strong>no toca memoria
compartida</strong>: cada hilo cuenta en su arreglo privado y al final hace solo <code>nbins</code> actualizaciones
protegidas. Hoy ese mismo patrón se llama "histograma privado por bloque", con el bloque en el papel del hilo.
</details>

**4. (Unidad III, S07 / Unidad I).** Tu `reduction(+:s)` con 8 hilos dio `1520441.750000`; la suma secuencial en
`float` del mismo arreglo dio `1520441.875000`. ¿Está mal la versión paralela? ¿Con qué criterio lo decides?

<details><summary>Respuesta</summary>
No necesariamente: en <code>float</code> el orden de las sumas cambia el redondeo (idea errónea 10). Se decide
comparando contra una referencia en mayor precisión (la suma en <code>double</code>, <code>1520442.012500</code>)
con una <strong>tolerancia relativa</strong> declarada: aquí el error relativo es <code>1.7e-7</code>, muy por debajo
de <code>1e-4</code>. Igualdad exacta solo se exige cuando los datos son enteros (histogramas, conteos).
</details>

**5. (Anticipa el tema de hoy; conjetura, "no sé" es válida y no cuenta).** Un *kernel* con 4096 bloques deja en
cada bloque una suma parcial en memoria compartida. ¿Puede una `__syncthreads()` juntar las 4096 parciales en un
solo número? Si crees que no, ¿qué harías? (Es la pregunta 3 de la tarea de la S02: compara con lo que escribiste.)

<details><summary>Respuesta</summary>
No. <code>__syncthreads()</code> solo espera a los hilos del <strong>propio bloque</strong> y la memoria compartida
no se ve desde otros bloques. Opciones que hoy se comparan: cada bloque escribe su parcial en memoria global y el
anfitrión (o un segundo <em>kernel</em>) las suma; o cada bloque hace <strong>una</strong> operación atómica sobre
un acumulador global. Cualquier respuesta razonada vale: es una predicción.
</details>

**Para el profesor.** Si la pregunta 1 queda por debajo de 60 %, el bloque de anclaje dedica un minuto a "qué
garantiza el *hardware* sobre el orden entre *warps*: nada", porque toda la fase Investigar de hoy (I3) depende de
esa idea. La pregunta 4 se retoma literalmente en el ConcepTest 2. La pregunta 5 no cuenta: se contesta con el
ConcepTest 1 (minuto 28) y con la "etapa 2" del ejemplo resuelto.
