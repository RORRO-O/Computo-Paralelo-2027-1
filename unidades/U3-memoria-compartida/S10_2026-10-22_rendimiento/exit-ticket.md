> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S10 · jueves 22 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S10 · Exit ticket (5 minutos, individual)

Escribe tu número de lista. Entrega la hoja al salir. Cuenta por participación; el profesor lo revisa hoy y abre
la sesión del lunes 26 de octubre con el error más frecuente.

**1. (Conceptual, opción múltiple)** Un equipo entrega esta tabla y escribe: "*speedup* 3.6 con 4 hilos;
escalabilidad fuerte casi perfecta".

| hilos | n | mediana (s) |
|---|---|---|
| 1 | 1 000 000 | 1.00 |
| 2 | 2 000 000 | 1.05 |
| 4 | 4 000 000 | 1.10 |

¿Qué está mal?

- **A)** Nada: `4 × 1.00 / 1.10 ≈ 3.6`.
- **B)** Cambiaron `n` con los hilos: eso es escalabilidad **débil**. Lo que midieron es la eficiencia débil
  `T(1,n) / T(4,4n) = 0.91`, no un *speedup* fuerte; el *speedup* fuerte exige el mismo `n` en las tres filas.
- **C)** Falta medir con `-O0` para ver el tiempo real.
- **D)** El *speedup* es 4 porque la eficiencia es 0.91.

**2. (Aplicación corta)** El mejor programa secuencial tarda `T(1) = 2.0 s`; con 4 hilos, `T(4) = 0.8 s`
(medianas de 5, `-O2`). Escribe tres números:
(a) *speedup*, (b) eficiencia, (c) fracción secuencial de Karp–Flatt `f = (1/S − 1/p) / (1 − 1/p)`.
Y una línea: si en lugar de `T(1)` secuencial hubieran usado la versión paralela con 1 hilo (`1.9 s`),
¿el *speedup* reportado sería mayor o menor, y por qué el protocolo lo prohíbe sin declararlo?

**3. (Confianza)** ¿Qué tan seguro estás de tus dos respuestas? 1 = adivinando · 2 = poco · 3 = bastante ·
4 = podría explicárselo a alguien. ¿Qué te quedó **menos** claro hoy? (una línea, opcional)

<details><summary>Clave</summary>

1. **B.** Fuerte: mismo problema, más procesadores. Débil: el problema crece con los procesadores (idea
   errónea 6). Con `n` creciente, el cociente `T(1,n)/T(p,p·n)` es la **eficiencia débil** (0.91) y el *speedup*
   escalado es `p × 0.91 ≈ 3.6`, que solo puede reportarse diciendo que `n` cambió (protocolo §5). A acepta
   la tabla tal cual; C es la idea errónea 5; D confunde eficiencia con *speedup* (idea errónea 3).
2. (a) `S = 2.0 / 0.8 = 2.5`. (b) `E = 2.5 / 4 = 0.625` (62.5 %). (c) `f = (1/2.5 − 1/4) / (1 − 1/4) =
   (0.40 − 0.25) / 0.75 = 0.20`. Línea: con `1.9 s` de referencia el *speedup* sería **menor** (`1.9 / 0.8 =
   2.4`); en general la versión paralela con 1 hilo puede ser más lenta **o** más rápida que el secuencial, y el
   protocolo exige el **mejor secuencial** como `T(1)` porque el *speedup* responde "cuánto gano respecto a lo
   mejor que tenía", no "respecto a mi propio código con un hilo" (idea errónea 31; se acepta cualquier línea que
   diga que la referencia debe ser el mejor secuencial y que la otra se declara si se usa).
3. Sin clave. Para el profesor: la brecha entre confianza 4 y respuestas incorrectas en la pregunta 2 es el dato
   de calibración de la sesión.
</details>

**Clasificación rápida (profesor, 10 min después de clase).** Bien: pregunta 1 = B **y** pregunta 2 con
`2.5`, `0.625` (o `62.5 %`) y `0.20` (se acepta `0.2`). Parcial: una de las dos, o la 2 con `S` y `E` bien y `f`
mal. Mal: pregunta 1 ≠ B **y** pregunta 2 con `E = 2.5` o `f` sin calcular. Si "mal" supera 30 %, la
recuperación del lunes 26 de octubre abre con el cálculo de `S`, `E` y `f` (ya está prevista como pregunta 1 de
S11) y el ejemplo de la tabla con `n` creciente se vuelve a proyectar.
