> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S03 · jueves 26 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# ConcepTests · S03

Secuencia: voto individual (1 min) → discusión en parejas (2 min) → revoto → explicación (2 min). Si el primer voto
supera 80 % de aciertos, se salta la discusión; si queda por debajo de 30 %, se reexplica antes de discutir. Se vota
con dedos (1–4) o tarjetas A/B/C/D. CT1 va en Instrucción explícita I (minuto 28); CT2 en la puesta en común
(minuto 70; discusión y revoto solo si el primer voto queda entre 30 % y 80 %); CT3 es reserva: si sobra tiempo en la
puesta en común, o abre la recuperación de la S04 (lunes 30 de noviembre).

## CT1 · ¿A quién espera `__syncthreads()`? (idea errónea 25)

Un compañero quiere evitar la "segunda etapa" de la reducción y escribe, al final del *kernel* en árbol lanzado con
`<<<4096, 256>>>`:

```c
if (tid == 0) partial[blockIdx.x] = s[0];      /* cada bloque publica su parcial */
__syncthreads();
if (blockIdx.x == 0 && tid == 0) {             /* "el bloque 0 remata" */
    float total = 0.0f;
    for (int b = 0; b < gridDim.x; b++) total += partial[b];
    *out = total;
}
```

Compila y corre sin ningún error de CUDA. ¿Qué pasa?

- **A.** Es correcto: después de `__syncthreads()` los 4096 parciales ya están escritos en `partial`.
- **B.** Es incorrecto: la barrera solo espera a los 256 hilos del bloque 0; los otros 4095 bloques pueden no haber
  empezado siquiera. `total` suma ceros o basura y CUDA no reporta nada.
- **C.** Es correcto si el bloque 0 llama a `cudaDeviceSynchronize()` justo antes del ciclo.
- **D.** Es correcto cuando la malla cabe completa en la GPU (en una T4, hasta 40 SM × 4 bloques de 256), porque
  entonces todos los bloques corren a la vez y llegan juntos a la barrera.

**Respuesta: B.**

| Distractor | Origen |
|---|---|
| A | Anexo A n.º 25: "`__syncthreads()` sincroniza toda la GPU" |
| C | Nueva (agregar al Anexo A): confunde funciones de anfitrión con funciones de dispositivo; `cudaDeviceSynchronize()` no existe dentro de un *kernel* |
| D | Nueva (variante de la 25): "simultáneo = sincronizado"; aunque todos los bloques estén residentes, nada ordena sus *warps* entre sí |

**Acierto esperado en el primer voto: ~50 %.** La tarea de la S02 ya planteó la pregunta ("¿puede `__syncthreads()`
combinar 1000 parciales?") y la recuperación de hoy la repitió como conjetura; quienes trajeron la respuesta votan B,
el resto se reparte entre A y D.

**Guion de discusión (3 líneas).** "Pregunta a tu pareja: ¿a qué hilos, exactamente, espera esa barrera? ¿Quién
garantiza que el bloque 4095 ya corrió cuando el bloque 0 llega al ciclo?" → Tras el revoto: la barrera es del
**bloque**; entre bloques, lo único que sincroniza es el **fin del *kernel*** (o una atómica, que no espera: suma
en el orden en que llegan). → Cierre: por eso existe la "etapa 2": copiar los parciales al anfitrión o lanzar un
segundo *kernel*, o una `atomicAdd` por bloque. Sobre D: en la S04 se ve que ni siquiera caben todos; y aunque
cupieran, "al mismo tiempo" no es "en el mismo orden".

## CT2 · Cuatro sumas, cuatro resultados (ideas erróneas 10 y 7)

El mismo arreglo de `2^20` `float` (`x[i] = 1.0 + (i % 10)·0.1`) sumado de cuatro maneras (salida real de
`reduce_sum_cpu 1048576 256`):

```
ref_double            = 1520442.012500   (secuencial en double: la referencia)
float_secuencial      = 1520441.875000   (un acumulador float, i = 0, 1, 2, …)
float_orden_permutado = 1520444.750000   (un acumulador float en el orden arbitrario de las atómicas)
float_arbol_nodiv     = 1520442.024994   (mismo orden que el kernel en árbol)
```

Un compañero concluye algo. ¿Cuál conclusión es correcta?

- **A.** La versión con atómicas está mal: se aleja 2.7 de la referencia, mientras que las otras dos coinciden casi
  exactamente.
- **B.** Las tres sumas en `float` son aceptables: la diferencia es redondeo que depende del **orden** de las sumas;
  se juzga con una tolerancia relativa declarada (aquí `1e-4`; los errores son `9e-8`, `1.8e-6` y `8e-9`) contra una
  referencia en mayor precisión. Que la atómica cambie entre corridas no la hace incorrecta.
- **C.** Si el resultado de la atómica cambia entre corridas, hay una condición de carrera en `atomicAdd`: habría que
  protegerlo con una barrera.
- **D.** La referencia correcta es `float_secuencial`, porque la GPU también suma en `float`; comparar contra `double`
  es injusto y por eso "fallan" las otras.

**Respuesta: B.**

| Distractor | Origen |
|---|---|
| A | Anexo A n.º 10: "`reduction` da exactamente el mismo resultado que la suma secuencial" (espera igualdad) |
| C | Anexo A n.º 7, invertida: toma el no determinismo por carrera; una atómica no tiene carrera, tiene **orden arbitrario** |
| D | Nueva (variante de la 10): la referencia debe ser **más** precisa que lo que se verifica, no igual de imprecisa; con `2^24` el acumulador `float` secuencial se equivoca 10 % |

**Acierto esperado en el primer voto: ~55 %** (después de PRIMM, donde vieron `verificacion=OK` con tres sumas
distintas). Si el primer voto queda entre 30 % y 80 %, discusión y revoto; fuera de ese rango, directo a la
explicación.

**Guion de discusión.** "¿Cuál de los cuatro números es 'el verdadero'? ¿Qué distingue una diferencia por orden de
una diferencia por carrera?" → "¿Qué pasó con `float_secuencial` cuando `n = 2^24` (I6)?": `26777438` contra
`24326970`, 10 % de error, porque a `16 777 216` sumarle `1.0` ya no cambia el `float`. → Cierre: referencia en
`double` + tolerancia declarada; lo no determinista de la atómica es orden, no carrera; cuando los datos son enteros
(histograma, conteo) la comparación es **exacta** y ahí sí, un `−1` es un error.

## CT3 · La segunda etapa y las copias (idea errónea 24) — reserva

Una reducción de `2^20` `float` se repite **1000 veces** dentro de un algoritmo que corre en la GPU (la norma del
residuo en cada iteración de Jacobi). En una T4 el *kernel* en árbol tarda ≈ 0.03 ms; copiar los 4096 parciales
(16 KB) al anfitrión y sumarlos ahí tarda ≈ 0.03 ms más. ¿Qué segunda etapa eliges y por qué?

- **A.** Copiar los 4096 parciales al anfitrión en cada iteración: 16 KB es tan poco que la copia no cuenta en el
  tiempo.
- **B.** Una `atomicAdd` por bloque sobre un acumulador que vive en la GPU (o un segundo *kernel* de un bloque): el
  resultado se queda en el dispositivo, lo lee la siguiente iteración y se copia **una** vez al final (4 bytes).
- **C.** La versión atómica ingenua (`atomicAdd` por elemento): las atómicas son instrucciones de *hardware*, así que
  no tienen costo apreciable.
- **D.** Da igual cuál: con 1000 repeticiones el tiempo lo domina el *kernel*, no las copias.

**Respuesta: B.**

| Distractor | Origen |
|---|---|
| A | Anexo A n.º 24: "las transferencias `cudaMemcpy` no cuentan en el tiempo" (aquí cuestan lo mismo que el *kernel*: 50 % del total) |
| C | Nueva (agregar al Anexo A): "las atómicas son gratis"; `2^20` atómicas sobre **una** dirección se serializan: uno o dos órdenes de magnitud más lento que el árbol |
| D | Anexo A n.º 24 (variante) y n.º 21 ("la comunicación es gratis"): la copia **no** se amortiza, se repite 1000 veces |

**Acierto esperado en el primer voto: ~50 %** si ya hicieron I5 (comparar `etapa2_cpu_ms` con `kernel_mediana_ms`);
~35 % si no.

**Guion de discusión.** "Si copiar 16 KB tarda lo mismo que sumar 4 MB en la GPU, ¿de qué depende el costo de una
copia: del tamaño o del hecho de cruzar el bus?" → "¿Dónde tiene que estar el resultado en la iteración siguiente?" →
Cierre: la latencia fija de una copia (decenas de microsegundos) la hace cara cuando el *kernel* es corto; la regla
es **dejar los datos donde se usan** y copiar una vez. Es el tema de la S04 (lunes 30 de noviembre): medir con y
sin copias.
