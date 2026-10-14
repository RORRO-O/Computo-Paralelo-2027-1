> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S11 · lunes 26 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S11 · ConcepTests (instrucción entre pares)

Secuencia fija: voto individual (1 min, tarjetas A/B/C/D o manos) → discusión en parejas (2 min: "convence a tu
compañero") → revoto → explicación (1–2 min). Si el primer voto supera 80 % de aciertos se salta la discusión;
si queda por debajo de 30 % se vuelve a explicar el concepto antes de discutir. Anota el porcentaje real de
cada voto en "Notas post-sesión" de `plan-sesion.md`.

## ConcepTest 1 · ¿Carrera o redondeo? (minuto ~28, después del *scan* en dos fases)

Corres `./scan 8388608 4` y el programa imprime:

```
max|y_par - y_seq| = 2.873e-07 (en i=5214114)   relativo a la suma total = 6.850e-14
identicos bit a bit: no   dentro de tolerancia 1e-12: si
```

Con 1 hilo imprime `identicos bit a bit: si`. ¿Qué concluyes?

- **A.** Hay una condición de carrera: con 1 hilo da igual y con 4 da distinto, que es justo el síntoma de una
  carrera.
- **B.** El algoritmo paralelo es correcto. Las sumas se agrupan en otro orden (por bloque y luego la
  corrección), y en punto flotante el orden cambia el redondeo. Se compara con tolerancia.
- **C.** El algoritmo paralelo está mal: una suma, se haga como se haga, debe dar exactamente lo mismo que la
  secuencial.
- **D.** Es un efecto de las optimizaciones: compilando con `-O0` los resultados coincidirían bit a bit.

**Respuesta:** B.

| Opción | Origen del distractor |
|---|---|
| A | Idea errónea 7 al revés: "distinto ⇒ carrera". Una carrera da diferencias **grandes y cambiantes** entre corridas (ver `scan_buggy`); aquí la diferencia es de 2.873e-07 absoluto (6.850e-14 relativo a la suma total) y es la **misma** en cada corrida con 4 hilos. |
| C | Idea errónea 10: "`reduction` da exactamente lo mismo que la suma secuencial". La suma en punto flotante no es asociativa. |
| D | Idea errónea 5 ("se mide/se verifica con -O0"). La optimización no cambia el orden de las sumas que dicta el algoritmo; sí podría cambiar otras cosas, pero no es la causa. |

**Primer voto esperado:** 50–60 % B; 20–25 % A; 15 % C; resto D.

**Guion de discusión (3 líneas).** "Quien votó A: ¿qué pasa con la diferencia si corres cuatro veces? ¿Y en
`scan_buggy`?" (misma vs. cambia). "Quien votó C: suma 1e16 + 1 − 1e16 en `double` a mano, y luego
1e16 − 1e16 + 1" (0 vs 1). Regla: **enteros y max/min son exactos; sumas flotantes se comparan con
tolerancia; una carrera no es "un poquito distinto", es impredecible.** Conecta con la Práctica 4: sus pruebas
usan tolerancia por esto.

## ConcepTest 2 · Más hilos, más lento (minuto ~68, puesta en común del PRIMM)

Con `n = 64` el Jacobi converge en 9626 iteraciones tanto en secuencial como con 4 hilos, y los resultados
son idénticos. Pero la mediana fue 0.0006 s en secuencial y 0.0330 s con 4 hilos. ¿Cuál es la **mejor**
explicación?

- **A.** Falso compartido: los 4 hilos escriben en `u_new` y sus bloques comparten líneas de caché.
- **B.** Cada iteración abre y cierra una región paralela (crear/despertar hilos, repartir, barrera,
  combinar la reducción). Con 62 puntos, ese costo fijo es mayor que el trabajo repartido.
- **C.** La cláusula `reduction(max:…)` obliga a que los hilos se turnen para comparar, así que el ciclo se
  ejecuta en serie.
- **D.** El doble búfer copia los `n` elementos de `u_new` a `u` al final de cada iteración, y esa copia no
  está paralelizada.

**Respuesta:** B.

| Opción | Origen del distractor |
|---|---|
| A | Idea errónea 14 mal aplicada. Sí existe falso compartido en las fronteras entre bloques (una línea de caché = 8 `double`), pero son 3 fronteras de 62 puntos: no explica una diferencia de más de un orden de magnitud, y persiste con `n` grande, donde el paralelo sí gana. |
| C | Idea nueva (agregar al Anexo A): "`reduction` serializa el ciclo". No: cada hilo acumula en una copia privada y solo la combinación final (p valores) está sincronizada. |
| D | Lectura equivocada del código: el intercambio es de **punteros** (`tmp = u; u = u_new; u_new = tmp;`), O(1). Quien vota D no rastreó la línea del *swap*. |

**Primer voto esperado:** 55–65 % B; 20 % A; 10 % C; 10 % D.

**Guion de discusión.** "¿Cuántas regiones paralelas se abrieron? (= iteraciones). Divide el tiempo paralelo
entre ese número: ¿cuántos microsegundos cuesta cada una? Compara con lo que tarda calcular 62 promedios." Luego:
"¿A partir de qué `n` gana el paralelo en tu tabla de la fase Investigar?" Regla: **más hilos no es más
rápido si el trabajo por región paralela no amortiza su costo fijo; se mide, no se supone** (idea errónea 1).
Puente a la ampliación: una sola región paralela fuera del `while` con `omp for` adentro reduce el costo, pero
no elimina la barrera por iteración.

## ConcepTest 3 (opcional, si el reloj lo permite; si no, va como pregunta en la S12) · Histograma

Histograma de 2·10^7 valores en 16 casillas, 4 hilos. ¿Qué versión esperas más rápida?

- **A.** `parallel for` y `#pragma omp atomic` sobre `hist[bin]++`.
- **B.** `reduction(+:hist[:16])`, o acumuladores locales por hilo volcados una vez con `critical`.
- **C.** `parallel for` y `#pragma omp critical` alrededor de `hist[bin]++`.
- **D.** Las tres igual: el histograma está limitado por memoria y la sincronización no importa.

**Respuesta:** B.

| Opción | Origen del distractor |
|---|---|
| A | Idea errónea 14 ("el falso compartido no existe"): las 16 casillas caben en 1–2 líneas de caché que los 4 hilos se arrebatan en cada elemento; además `atomic` por elemento cuesta más que una suma normal. |
| C | Idea errónea 8 (`critical` ≈ `atomic`): `critical` serializa todo el cuerpo y es más caro que `atomic`. |
| D | Idea nueva: "si es *memory-bound* nada más importa". El tráfico de coherencia de caché por las casillas compartidas sí domina. |

**Primer voto esperado:** 60–70 % B. **Discusión:** "¿Cuántas veces se toca la memoria compartida en cada
versión: una por elemento o 16 por hilo?"
