> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S05 · martes 17 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# S05 · Exit ticket (5 minutos, individual, en papel)

Escribe tu número de lista. Se revisa hoy mismo; el error más frecuente abre la sesión del jueves 19 de
noviembre.

## Pregunta 1 (conceptual)

En Jacobi 1D con p procesos, el cómputo por iteración es proporcional a n/p y la comunicación por iteración es
constante. Explica en tres líneas, con esas dos cantidades, por qué el *speedup* con p = 4 puede ser **menor
que 1** para n pequeño y cercano a 4 para n grande.

## Pregunta 2 (aplicación)

Mediste α = 0.5 µs (ping-pong de 8 bytes) y t_c = 1 ns por punto por iteración (versión secuencial). Cada
proceso interior intercambia dos halos de 8 bytes por iteración; desprecia m/β.

a) ¿A partir de qué n el tiempo con p = 4 es menor que el secuencial? Muestra el cálculo.
b) Tu compañero midió además con `-np 8` en una laptop de 4 núcleos y quiere ponerlo en la misma curva de
*speedup* que p = 1, 2, 4. ¿Qué le dices, en una línea?

## Confianza

¿Qué tan seguro estás de tus respuestas? (1 = adiviné · 2 = dudo · 3 = bastante seguro · 4 = seguro)
¿Qué te quedó menos claro de hoy? (una línea)

<details><summary>Clave (para el profesor; se publica después de la sesión)</summary>

**P1.** T₁ = n·t_c; T₄ = (n/4)·t_c + T_halo, con T_halo constante (≈ 2α). Para n pequeño, (n/4)·t_c es
despreciable frente a T_halo y T₄ ≈ T_halo puede superar a T₁ = n·t_c: *speedup* < 1. Para n grande,
(n/4)·t_c domina sobre T_halo y T₄ ≈ T₁/4: *speedup* → 4. La razón cómputo/comunicación `(n/p)·t_c / T_halo`
crece linealmente con n. (Ataca la idea errónea 21 y la 1.)

**P2a.** T_halo = 2 × 0.5 µs = 1 µs. Condición T₄ < T₁: (n/4)·t_c + 1 µs < n·t_c ⇒ 1 µs < n·t_c·(3/4) ⇒
n > 1 µs / (0.75 ns) ≈ **1 333 puntos**. (Equivalente: n* = T_halo / (t_c·(1 − 1/p)).)

**P2b.** Con 8 procesos en 4 núcleos el dato está sobre-suscrito: se reporta **aparte** y etiquetado, no en
la curva de escalabilidad (idea errónea 20; protocolo §2, "uno más allá, declarado").

**Clasificación rápida.** Bien: P1 nombra las dos cantidades y su dependencia de n; P2a llega a ~1 300 con
el cálculo visible; P2b dice "aparte/etiquetado". Parcial: P1 correcta pero P2a con T_halo = α (n ≈ 667) o
sin el factor (1 − 1/p). Mal: P1 dice que el *speedup* no depende de n, o P2b acepta el dato en la curva.
</details>
