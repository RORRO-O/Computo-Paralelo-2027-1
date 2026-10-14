> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S05 · martes 1 de diciembre de 2026 · 08:30–10:00 · Lab LS4

# ConcepTests S05

Secuencia fija: voto individual (1 min) → discusión en parejas (2 min) → revoto → explicación (2 min). Si el primer
voto supera 80 % de aciertos se salta la discusión; si queda bajo 30 % se reexplica antes de discutir. En esta
sesión de laboratorio se aplican dos (CT1 en el minuto 10, CT2 en el 52); CT3 es de reserva para la puesta en
común del taller si sobra tiempo o para la S06.

## CT1 · ¿Qué le falta a esta medición? (minuto 10, antes del trabajo en la Parte D)

Un equipo reporta la V3 de su proyecto así: "`cudaEventRecord` antes y después del lanzamiento del *kernel*, una
corrida, 4 ms; la V1 tarda 400 ms; *speedup* = 100×". ¿Qué le falta para que la medición sea válida según el
protocolo del curso?

- A) Nada: así se mide un *kernel*; las copias no son parte del algoritmo.
- B) Incluir las transferencias H2D/D2H en una segunda medición, hacer una corrida de calentamiento y repetir 5 veces reportando la mediana. **(correcta)**
- C) Compilar la V1 con `-O0` para que la comparación sea "sin optimizaciones de ambos lados".
- D) Llamar a `__syncthreads()` al final del *kernel* para que toda la GPU termine antes del segundo evento.

| Distractor | Origen |
|---|---|
| A | Idea 24: "las transferencias `cudaMemcpy` no cuentan en el tiempo" + idea 5: "medir una vez basta" |
| C | Idea 5: "se mide con -O0"; protocolo §1.1 y §5 |
| D | Idea 25: "`__syncthreads()` sincroniza toda la GPU"; la sincronización que falta es del anfitrión (`cudaEventSynchronize`) |

Acierto esperado en el primer voto: ~55 %. A atrae a quien hizo la Parte D midiendo solo el *kernel*; D a quien
confunde sincronización de bloque con sincronización anfitrión–dispositivo.

Guion de discusión: "Pregúntale a tu pareja: ¿cuánto tarda copiar la entrada de su proyecto a la GPU? Si no lo
sabe, ¿cómo puede afirmar 100×?". Tras el revoto: la regla es **dos tiempos, cinco repeticiones, mediana, T(1) = V1
con `-O2`**. Mostrar la fila `copiar_cada_iter=1` de la práctica guiada: mismo *kernel*, *speedup* de ~30× a ~1×.

## CT2 · El *kernel* no dio error (minuto 52, apertura del taller V3)

Después de lanzar el *kernel* de la V3, `cudaGetLastError()` y `cudaDeviceSynchronize()` regresan `cudaSuccess`.
¿Qué puedes concluir?

- A) El resultado es correcto; si hubiera un índice mal calculado, CUDA lo habría reportado.
- B) No hubo errores de lanzamiento ni de ejecución detectables; el resultado puede estar mal y falta compararlo con la V1 con tolerancia. **(correcta)**
- C) Todos los hilos escribieron dentro de los arreglos; un acceso fuera de rango siempre produce `illegal memory access`.
- D) Cada hilo corrió en su propio núcleo sin interferir con los demás, así que no puede haber carreras.

| Distractor | Origen |
|---|---|
| A | Idea 27: "si el *kernel* no da error, el resultado es correcto" |
| C | Variante de la 27: un acceso fuera de rango que cae en memoria asignada (p. ej., el otro búfer) no se detecta; es comportamiento indefinido |
| D | Idea 22: "un hilo de CUDA equivale a un núcleo de CPU"; además ignora que los hilos comparten memoria global |

Acierto esperado en el primer voto: ~50 %. C es el distractor fuerte: suena técnico y a veces es cierto.

Guion de discusión: "Convence a tu pareja con un ejemplo concreto de un error que `cudaSuccess` no atrapa" (índice
dentro del arreglo pero equivocado; guardia que descarta celdas válidas; búfer que nunca se copió). Tras el revoto:
el experimento `-DSIN_GUARDIA` de la práctica guiada muestra las tres salidas posibles. Regla: **verificar contra la V1
es parte del *kernel*, no un extra**.

## CT3 · Hilos lanzados vs. hilos que trabajan (reserva)

Malla de 37 filas × 45 columnas aplanada por filas; *kernel* 2D con bloques de 16 × 16. ¿Cuántos hilos se lanzan y
cuántos escriben una celda?

- A) 1665 y 1665: la malla de bloques se ajusta para lanzar exactamente los hilos necesarios.
- B) 2304 y 1665: 3 × 3 bloques; los 639 sobrantes salen por la guardia `if (r >= height || c >= width) return;`. **(correcta)**
- C) 2304 y 2304: los hilos sobrantes procesan celdas de la frontera, que de todos modos se copian.
- D) 1665 y 1665: el *hardware* recorta el último bloque de cada dimensión automáticamente.

| Distractor | Origen |
|---|---|
| A | Idea 22 (modelo de "tantos hilos como trabajo", como en OpenMP): los bloques son de tamaño fijo |
| C | Nueva idea errónea (proponer para el Anexo A): "sin guardia no pasa nada; los hilos extra hacen trabajo inofensivo". En realidad escriben fuera del arreglo |
| D | Nueva idea errónea (proponer para el Anexo A): "la GPU ajusta el tamaño del último bloque" |

Acierto esperado en el primer voto: ~45 %. Quien calculó `37·45/256 = 6.5 → 7` bloques confundió el mapeo 1D con el 2D.

Guion de discusión: "Calculen juntos `ceil(45/16)` y `ceil(37/16)`; luego el índice que escribiría el hilo (15,15) del
bloque (2,2) sin guardia" (c = 47, r = 47, idx = 2162 > 1665). Regla: **bloques con `ceil`, siempre guardia, y se
prueba con un tamaño no múltiplo**.
