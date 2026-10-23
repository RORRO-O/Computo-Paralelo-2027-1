> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S01 · lunes 23 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# Tarea espaciada · S01 (20–40 min)

**Entrega.** Individual, en el repositorio del equipo: `tareas/<usuario-github>/U5-S01.md` y, si lo terminaste,
`dot_partial.cu` o `dot_partial_numba.py` en `tareas/<usuario-github>/U5-S01/`, antes del **martes 24 de noviembre de
2026, 08:30** (inicio de S02, Lab LS4). La autocalificas con las claves de abajo en los minutos 5–10 de S02 (2 min);
el profesor registra la entrega, no el acierto, y revisa 3 al azar por parcial. **Esta tarea no tiene peso propio;
el examen de práctica del jueves 3 de diciembre y el 10–20 % acumulativo del Examen 3 toman ítems de aquí.** Si
faltaste hoy, entregarla en esa misma fecha sustituye tu recuperación y tu *exit ticket* de S01
(`docs/metodo/04-evaluacion.md` §5). El ejercicio 1 es insumo directo del pre-laboratorio de la Práctica 6, que se
entrega esa misma mañana, aparte de esta tarea.

## 1. Tema de hoy (15 min) · índices y producto punto por partes

**a) Sin ejecutar**, para `n = 100 000` y `block = 512`:

- ¿Cuántos bloques lanza `(n + block - 1) / block`? ¿Cuántos hilos en total? ¿Cuántos ociosos?
- ¿Qué índice global calcula el hilo `threadIdx.x = 511` del bloque `blockIdx.x = 100`?
- ¿Qué hace el hilo `threadIdx.x = 300` del bloque `blockIdx.x = 195`?

**b) Termina el "Crear" de la práctica guiada** (`dot_partial`): un hilo por producto `p[i] = a[i]·b[i]`, suma en la
CPU en `double`. Córrelo en Colab (o, si no tienes GPU, bajo `NUMBA_ENABLE_CUDASIM=1` con `n = 1000`) y anota:
`dot` para `n = 1000` y, con GPU, para `n = 2^24`; el tiempo del *kernel* y el de la copia D2H de `p` (dos
`cudaEvent_t` o `perf_counter` con `cuda.synchronize()`); una línea: ¿qué fracción del total es la copia?

<details><summary>Respuestas de 1a y valores de control de 1b</summary>
(a) <code>(100 000 + 511) / 512 = 196</code> bloques; <code>196 · 512 = 100 352</code> hilos; 352 ociosos.
<code>i = 100·512 + 511 = 51 711</code>. El hilo 300 del bloque 195: <code>i = 195·512 + 300 = 100 140 ≥
100 000</code>, no trabaja.
(b) <code>n = 1000 → dot = 17946.0</code>; <code>n = 16 777 216 → dot = 301989870.0</code>. En una T4 se espera
que la copia D2H de 64 MB tarde más que el <em>kernel</em> (orden de 10 ms contra ≈ 1 ms); el valor exacto depende
de la GPU y se anota con fecha.
</details>

## 2. Intercalado (10 min) · Unidad III: ¿qué dice tu H2 sobre la sobrecarga?

Con la tabla de tiempos de tu V2 (la que entregaste hoy), calcula para `p = 2, 4` (y 8 si lo mediste): *speedup*
`S(p) = T(1)/T(p)`, eficiencia `E(p) = S(p)/p` y la fracción secuencial de Karp–Flatt
`f(p) = (1/S − 1/p) / (1 − 1/p)`. Escribe dos líneas: ¿`f` crece con `p`? ¿Qué sobrecarga lo explica en **tu**
código (sincronización, falso compartido, memoria, sobre-suscripción)?

Si tu equipo no tiene tabla todavía, usa esta: `T(1) = 8.0 s`, `T(2) = 4.3 s`, `T(4) = 2.5 s`, `T(8) = 2.1 s`
(laptop de 4 núcleos físicos).

<details><summary>Respuesta con la tabla de ejemplo</summary>
<code>S = 1.86, 3.20, 3.81</code>; <code>E = 0.93, 0.80, 0.48</code>; <code>f ≈ 0.075, 0.083, 0.157</code>.
<code>f</code> crece, sobre todo de 4 a 8: hay sobrecarga que aumenta con los hilos, y con 4 núcleos físicos los
hilos 5–8 comparten unidades (sobre-suscripción). "Más hilos siempre es más rápido" (idea errónea 1) no se sostiene;
8 hilos dan 3.81 por el costo de 8, con eficiencia de 48 %.
</details>

## 3. Preparación para la S02 (10 min) · martes 24 de noviembre, 08:30, Lab LS4

1. Lee el enunciado de la **Práctica 6** (`practicas/P6-gpu/README.md`, publicada hoy) y resuelve su
   pre-laboratorio: se entrega al inicio de la S02. Fecha límite de la práctica: domingo 6 de diciembre, 23:59; vale
   15 % del 3.er parcial.
2. Predicción por escrito (dos líneas): en la multiplicación de matrices `C = A·B` con `N = 1024`, un hilo por
   elemento de `C`, cada hilo recorre una fila de `A` y una columna de `B`. ¿Cuántas veces en total se lee cada
   elemento de `A` desde la memoria global de la GPU? ¿Te parece un problema? Mañana se llama *tiling*.

<details><summary>Respuesta</summary>
Cada elemento <code>A[i][k]</code> lo leen los <code>N = 1024</code> hilos que calculan la fila <code>i</code> de
<code>C</code>: 1024 lecturas del mismo dato desde la memoria más lenta de la GPU. Sí es un problema; la memoria
compartida por bloque (S02) permite leer cada mosaico una vez y reutilizarlo.
</details>
