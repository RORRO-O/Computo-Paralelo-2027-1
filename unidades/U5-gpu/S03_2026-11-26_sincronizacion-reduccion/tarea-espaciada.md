> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S03 · jueves 26 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# Tarea espaciada · S03 (20–40 min)

**Entrega.** Individual, en el repositorio del equipo: `tareas/<usuario-github>/U5-S03.md` (y el CSV del
*notebook*, si lo corriste en GPU, en `tareas/<usuario-github>/U5-S03/`), antes del **lunes 30 de noviembre de 2026,
10:30** (inicio de la S04, salón 3208). Se autocalifica con las claves de abajo en los minutos 5–10 de la S04
(2 min); el profesor registra la entrega, no el acierto, y revisa 3 al azar por parcial. **Esta tarea no tiene peso
propio; el examen de práctica del jueves 3 de diciembre y el 10–20 % acumulativo del Examen 3 toman ítems de aquí.**
Quien faltó hoy la entrega en esa misma fecha y así sustituye la recuperación y el *exit ticket* de la sesión
(`docs/metodo/04-evaluacion.md` §5). Recordatorio de fechas: **Lab 2 de la Práctica 6, martes 1 de diciembre,
08:30, Lab LS4**; **Práctica 6 vence el domingo 6 de diciembre, 23:59** (15 % del 3er parcial).

## 1. Del tema de hoy (15 min) · ¿Atómica ingenua, árbol + etapa 2 en CPU, o árbol + etapa 2 atómica?

**Si en clase no terminaste el histograma en memoria compartida (fase Crear, `TODO(1)` de `histogram.cu` o de
`histogram_numba.py`), ese es tu ejercicio 1**: termínalo hasta que `make test` diga `verificacion=OK, idéntico a
histogram_cpu` y escribe en tres líneas dónde van las dos barreras y por qué. Si lo terminaste, resuelve lo siguiente.

Para cada situación elige **una** de las cuatro estrategias vistas hoy (`atomic` por elemento · `tree` + etapa 2 en
el anfitrión · `tree` + una `atomicAdd` por bloque · histograma privado por bloque en compartida) y justifícala en
≤ 2 líneas con un número (cuántas atómicas, dónde queda el resultado, qué precisión):

| # | Situación | Tu elección y justificación |
|---|---|---|
| a | Sumar una sola vez `2^24` `float` que ya están en la GPU; el resultado lo necesita la CPU para imprimirlo | |
| b | Calcular la norma del residuo (una suma de `2^20` cuadrados) en **cada una** de 1000 iteraciones de Jacobi que corren en la GPU; la iteración siguiente decide con ese valor si continúa | |
| c | Contar cuántos de `10^8` `unsigned char` son iguales a 0 (un entero) | |
| d | Histograma de 256 bins de `10^8` bytes cuyos valores están **uniformemente** repartidos, y el mismo histograma cuando el 30 % cae en un solo bin | |

<details><summary>Clave del ejercicio 1</summary>

<strong>a.</strong> Árbol + etapa 2 en el anfitrión: 0 atómicas, 65 536 parciales (256 KB) viajan una vez y se suman
en <code>double</code>; la precisión queda controlada. La atómica ingenua está descartada dos veces: <code>2^24</code>
atómicas serializadas y, peor, el acumulador <code>float</code> se equivoca 10 % (I6: <code>26777438</code> contra
<code>24326970</code>).
<strong>b.</strong> Árbol + una atómica por bloque sobre un acumulador que vive en la GPU (o un segundo
<em>kernel</em>): 4096 atómicas por iteración, el resultado se queda donde se usa, cero copias por iteración; copiar
16 KB 1000 veces costaría tanto como los <em>kernels</em> (CT3, idea errónea 24). Hay que poner el acumulador en cero
en cada iteración (<code>cudaMemsetAsync</code> o un hilo al final del <em>kernel</em> anterior).
<strong>c.</strong> Cualquiera de las dos de árbol es correcta y <strong>exacta</strong> (enteros: sin redondeo); la
atómica por elemento también es exacta pero hace <code>10^8</code> atómicas sobre una dirección. Mejor aún: contar en
un registro con un ciclo de paso de malla y una atómica por bloque. Lo que decide aquí no es la precisión sino la
contención.
<strong>d.</strong> Histograma privado por bloque en compartida en los dos casos: <code>256 · gridDim.x</code>
atómicas globales en lugar de <code>10^8</code>. Con datos uniformes la ventaja es menor (las <code>10^8</code>
atómicas globales se reparten entre 256 direcciones y chocan menos); con el 30 % en un bin la versión global se
serializa sobre una dirección y la privatizada gana uno o dos órdenes de magnitud (extensión (c) de la práctica
guiada).
</details>

## 2. Intercalado (10 min) · Unidades III, IV y I: la misma reducción en tres modelos

**a) Tabla de correspondencias.** Completa con el constructo que hace el mismo papel en cada modelo (una palabra o
una llamada por celda):

| Papel | OpenMP (S07, Práctica 4) | MPI (Unidad IV) | CUDA (hoy) |
|---|---|---|---|
| Unidad que acumula en privado | hilo | | bloque |
| Dónde vive el acumulador privado | arreglo local (privado por alcance) | | |
| Combinación final protegida | `#pragma omp critical` de `nbins` sumas | | |
| Reducción "de biblioteca" | `reduction(+:s)` | `MPI_Reduce` | |
| El resultado queda en… | la variable compartida | | |

**b) Elección justificada.** En MPI, 1000 rangos tienen un parcial cada uno. Opción 1: cada rango hace
`MPI_Send` al rango 0 y el rango 0 suma al recibir. Opción 2: `MPI_Reduce`. ¿Cuál es el análogo de la **atómica
ingenua** de hoy y cuál del **árbol**? ¿Y qué se parece más a `MPI_Allreduce`: dejar el total en el anfitrión o en un
acumulador de la GPU que todos los bloques del siguiente *kernel* pueden leer? Dos líneas.

**c) Métricas (Unidad I).** En la máquina de autoría la suma secuencial en `double` de `2^20` `float` tarda
`1.21 ms` (mediana de 5, salida real de `reduce_sum_cpu`). Supón que en una T4 mediste, con el protocolo: `atomic`
`3.0 ms`, `tree_nodiv` `0.04 ms`, y que copiar los 4 MB a la GPU tarda `0.8 ms` (≈ 5 GB/s). Calcula el *speedup*
de `tree_nodiv` **sin** y **con** la copia, y el de `atomic` sin copia. Si la reducción es el 10 % del tiempo de un
algoritmo cuyos datos ya viven en la GPU y la aceleras 30×, ¿cuál es el *speedup* total del algoritmo (Amdahl)?

<details><summary>Respuestas del ejercicio 2</summary>

<strong>a.</strong> MPI: proceso (rango) · variable local del proceso (memoria propia; no hay otra) ·
<code>MPI_Reduce</code> (o <code>Recv</code> + suma en la raíz) · <code>MPI_Reduce</code> · en la raíz
(<code>Allreduce</code>: en todos). CUDA: bloque · <code>__shared__</code> · <code>atomicAdd</code> al arreglo
global (una por bin y bloque) · árbol en compartida + etapa 2 (no hay <code>reduction</code> en CUDA C; Numba y
las bibliotecas como CUB/Thrust la traen) · en memoria global del dispositivo, que el anfitrión copia.
<strong>b.</strong> 1000 <code>Send</code> al rango 0 que suma en serie = la atómica ingenua: todo converge en un
punto y se serializa (latencia × 1000). <code>MPI_Reduce</code> = el árbol: combina por pares en
<code>log₂ 1000 ≈ 10</code> rondas. <code>Allreduce</code> se parece a dejar el total en la GPU, visible para
todos los bloques del siguiente <em>kernel</em>; dejarlo en el anfitrión es <code>Reduce</code> con raíz en la CPU.
<strong>c.</strong> <code>S = 1.21 / 0.04 ≈ 30</code> sin copia; <code>1.21 / (0.8 + 0.04) ≈ 1.4</code> con copia;
<code>atomic</code>: <code>1.21 / 3.0 ≈ 0.4</code> (más lenta que un núcleo de CPU). Amdahl:
<code>1 / (0.9 + 0.1/30) ≈ 1.11</code>: acelerar 30× el 10 % da 11 % en total; antes de optimizar más la reducción,
hay que mirar el otro 90 % (y las copias, idea errónea 24).
</details>

## 3. Preparación de la S04 (10 min) · lunes 30 de noviembre, 10:30 · rendimiento en GPU

1. Lee `herramientas/protocolo-medicion.md`, §2 (fila "Transferencias (GPU)") y §5, y anota en una línea qué dos
   números exige el protocolo para cualquier medición en GPU.
2. Si corriste el notebook en GPU: en tu CSV `resultados_S03_reduccion_<fecha>.csv`, compara `etapa2_cpu_ms` con
   `kernel_mediana_ms` de `tree_nodiv` para `n = 2^16` y `n = 2^22`. ¿En cuál de los dos pesa más la copia de los
   parciales? Tráelo impreso o en la laptop: la S04 arranca con esa fila. Si no tuviste GPU, usa los órdenes de
   magnitud del README (`kernel ≈ 0.02–0.05 ms`, `etapa2_cpu ≈ 0.02–0.05 ms` para `2^20`).
3. **Predicción por escrito (sin correr nada; se contrasta el lunes, no tiene clave):** la suma de vectores de la S01
   con `n = 2^24` tardó ≈ 1 ms de *kernel* en una T4. Sus tres arreglos ocupan 64 MB cada uno. Si el bus mueve
   ≈ 5 GB/s, ¿cuánto tardan las copias H2D de `a` y `b` y la D2H de `c`? ¿Conviene la GPU si los datos empiezan en
   la CPU? ¿Y si ya estaban en la GPU porque los produjo otro *kernel*? Escribe los tres números y tu conclusión.
