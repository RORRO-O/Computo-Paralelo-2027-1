> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S04 · lunes 30 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# Tarea espaciada · S04 (20–40 minutos)

**Entrega:** antes de mañana, martes 1 de diciembre de 2026, 08:30, en la carpeta `practicas/P6/resultados/`
del repositorio de tu equipo (un archivo `tarea-S04.md` por integrante, con tu nombre de usuario de Git, más el
CSV y las PNG si los generaste). **Qué cuenta: Esta tarea no tiene peso propio; el examen de práctica del jueves
3 de diciembre y el 10–20 % acumulativo del Examen 3 toman ítems de aquí.** Se autocalifica con la clave en
`<details>` al inicio de la S05 (martes 1 de diciembre, 08:30, Lab LS4; 2 minutos después de la recuperación); el
profesor registra la entrega, no el acierto, y revisa 3 al azar por parcial. Además es la entrada directa de la
Parte D de la Práctica 6 (15 % del 3er parcial, vence el domingo 6 de diciembre a las 23:59) y de la medición de la
V3 del proyecto (entrega final el lunes 7 de diciembre a las 10:30). En el Lab 2 el profesor la usa para las
mini-defensas. Si en clase se recortó la Transferencia, el *Crear* de la práctica guiada es tu ejercicio 3b.

## 1. Del tema de hoy (≈ 15 min) · ¿Memoria o cómputo?

Con tu CSV de Colab (`resultados.csv`) o, si no alcanzaste a correrlo, con el CSV de ejemplo
(`./bench_cpu --csv-ejemplo resultados_ejemplo.csv`, recordando que sus columnas de GPU son de modelo):

a) Para `saxpy` con `n = 2^24`, toma `t_kernel_ms` y calcula el ancho de banda efectivo
   (`12·n bytes / t_kernel`) y los GFLOP/s alcanzados (`2·n FLOP / t_kernel`). ¿Qué porcentaje de 320 GB/s y de
   8 000 GFLOP/s representan?
b) Calcula la intensidad aritmética de **tu kernel de la Práctica 6** (FLOP ÷ bytes leídos y escritos en memoria
   global por hilo; si usa memoria compartida, cuenta solo el tráfico con la global). Ubícalo frente al balance de
   la T4 (≈ 25 FLOP/byte).
c) En ≤ 5 líneas: ¿tu kernel es *memory-bound* o *compute-bound*? ¿Qué optimizarías primero (coalescencia,
   mosaicos, tamaño de bloque, memoria *pinned*, dejar los datos en la GPU entre kernels) y por qué ese orden?

## 2. Intercalado (≈ 10 min) · Unidad IV y Unidad I

a) **(Unidad IV, modelo de costo)** En la Práctica 5 mediste latencia y ancho de banda con *ping-pong*. Con tus
   números (o, si no los tienes, 2 µs y 10 GB/s), calcula el costo de un intercambio de halo de Jacobi 1D de
   **2 doubles** y de uno de **10^6 doubles**. ¿Qué término domina en cada caso? Compara el segundo con la copia
   H2D de 64 MB de hoy (≈ 4 GB/s paginable, ≈ 11 GB/s *pinned*): ¿cuál de los dos "cables" es más lento?
b) **(Unidad I, métricas)** Un equipo reporta "*speedup* total de 1.2 con una T4 de 2 560 núcleos CUDA, eficiencia
   = 1.2 / 2 560 = 0.05 %". Explica en 3 líneas por qué esa eficiencia no significa lo mismo que en OpenMP
   (pista: ¿qué es `p` en `E = S/p` cuando los "procesadores" son carriles SIMT y el límite es el ancho de banda,
   no el número de núcleos?). ¿Qué métrica reportarías en su lugar? (porcentaje del ancho de banda teórico).

## 3. Preparación de la siguiente sesión (≈ 10 min) · Lab 2 de la Práctica 6, martes 1 de diciembre, 08:30

a) Lee la sección "M · Crear" del `practica-guiada/README.md` y la Parte D del enunciado de la Práctica 6.
b) Rodea tu kernel de P6 con los cuatro eventos de `measure_gpu` (H2D, kernel, D2H) y llena **al menos una fila**
   de la tabla con el encabezado del CSV de hoy. Si no te da tiempo de correrlo en Colab, deja el código listo y
   escribe la fila con tu predicción marcada como tal.
c) **Pre-mortem (escríbelo antes de medir):** "Con `n = ___`, espero `S_kernel ≈ ___` y `S_total ≈ ___` porque
   mi kernel mueve ___ bytes por elemento y las copias pesan ___ %". Mañana lo comparas con lo medido.

<details>
<summary>Para autoverificar (no son todas las respuestas; sí los órdenes de magnitud)</summary>

- 1a) En una T4 típica: ≈ 200–240 GB/s (65–75 % del teórico) y ≈ 35–40 GFLOP/s (≈ 0.5 % del pico): saxpy está
  pegado al techo de memoria y lejísimos del de cómputo.
- 1b) Suma de vectores 0.083; saxpy 0.17; *stencil* 1D de 3 puntos con pesos ≈ 0.3 si cada hilo lee sus 3 vecinos de la
  global (5 FLOP / 16 B) y ≈ 0.6 si los vecinos se reúsan desde caché o compartida (5 FLOP / 8 B); histograma
  ≈ 0 FLOP útiles por byte (lo que manda son las atómicas); matmul con mosaicos de 32 ≈ 8; todos *memory-bound*
  en T4 salvo matmul grande con mosaicos y reúso en registros.
- 2a) 2 doubles: 2 µs + 16 B / 10 GB/s ≈ 2.0 µs (domina la latencia). 10^6 doubles: 2 µs + 8 MB / 10 GB/s ≈
  0.8 ms (domina el ancho de banda). La copia H2D paginable (≈ 4 GB/s) es **más lenta** que ese enlace MPI de
  10 GB/s; la *pinned* (≈ 11 GB/s) es parecida.
- 2b) `p` = 2 560 cuenta carriles que ejecutan la misma instrucción en warps y que, en un kernel *memory-bound*,
  pasan la mayor parte del tiempo esperando memoria; la eficiencia por núcleo no es la métrica del modelo. Se
  reporta ancho de banda alcanzado / teórico (o GFLOP/s / pico si es *compute-bound*) y el *speedup* con y sin
  copias contra el mejor secuencial.

</details>
