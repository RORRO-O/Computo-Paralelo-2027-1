> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S04 · lunes 30 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# Exit ticket · S04

Individual, 5 minutos, en papel. Se entrega al salir. Cuenta por participación, no por acierto.

**1. (Conceptual)** En el barrido de hoy, el bloque de 32 hilos fue el más lento y el de 1024 **no** fue el más
rápido. Explica ambas cosas en ≤ 3 líneas usando las palabras *warp*, *ocupación* y *bloques residentes por SM*.

**2. (Aplicación)** Un kernel de tu Práctica 6 da estas medianas con `n = 2^24`: kernel 2 ms, H2D 30 ms,
D2H 15 ms. La versión de CPU tarda 60 ms.
   a) *Speedup* contando solo el kernel.
   b) *Speedup* contando las copias.
   c) Si solo puedes hacer un cambio antes de mañana, ¿ajustas el tamaño de bloque o cambias a memoria
      *pinned*? Justifica con los números.

**3. (Confianza)** ¿Qué tan seguro estás de tus respuestas? (1 = nada · 4 = muy seguro). ¿Qué te quedó menos
claro de la sesión? (una línea)

<details>
<summary>Clave</summary>

1. Con 32 hilos cada bloque es **un warp**; una T4 admite como máximo 16 bloques residentes por SM, así que
   solo hay 16 warps de los 32 posibles: **50 % de ocupación**, menos warps para ocultar la latencia de memoria
   y el kernel, que es *memory-bound*, tarda más. A partir de 64 hilos la ocupación ya es 100 %; con 1024 no
   sube más y, además, hay menos bloques (16 384 en vez de 65 536) para balancear el final del trabajo y cada
   hilo queda limitado a 64 registros. Por eso 1024 no mejora y a veces empeora (idea errónea 26).
   **Clasificación (≤ 20 s):** *bien* = escribe "16 bloques" (o "16 warps") y "50 %" para el de 32 **y** da una
   razón para 1024 (ocupación ya al 100 % / menos bloques para repartir / 64 registros); *parcial* = solo una de
   las dos partes; *mal* = "32 son pocos hilos" o "1024 es más rápido" sin bloques residentes ni ocupación.

2. a) `60 / 2 = 30×`. b) `60 / (30 + 2 + 15) = 60 / 47 ≈ 1.3×`. c) **Memoria pinned**: las copias son 45 de 47 ms
   (96 %). El mejor bloque solo puede recortar parte de 2 ms; pasar las copias de ≈4 GB/s a ≈11 GB/s las baja
   de 45 ms a ≈17 ms y el total a ≈19 ms (≈3×). Optimiza lo que domina (idea errónea 24).
   **Clasificación (≤ 20 s):** *bien* = `30` y `≈1.3` y "*pinned*" con el dato "copias 45 de 47 ms" (o "96 %");
   *parcial* = los dos números bien y c) sin dato, o c) bien con un número mal; *mal* = b) igual a a) (no sumó
   las copias) o c) "bloque".

3. Se registra la confianza para la brecha de calibración; "menos claro" alimenta la recuperación de S05
   (martes 1 de diciembre).

</details>

**Para el profesor.** Tres montones: bien / parcial / mal. "Mal" típico en la 1: explicar 32 con "pocos hilos"
sin mencionar bloques residentes por SM. "Mal" típico en la 2c: elegir el bloque "porque el kernel es lo que se
optimiza". Si "mal" supera el 30 %, S05 abre con la tabla de ocupación y con la pregunta 2 en el pizarrón.
