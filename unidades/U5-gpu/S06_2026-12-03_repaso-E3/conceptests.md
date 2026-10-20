> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S06 · jueves 3 de diciembre de 2026 · 10:30–12:00 · Salón 3208

# ConcepTests · S06 (sesión de repaso)

En una sesión de repaso (variante 2.2) los ConcepTests no abren bloques de instrucción: **relanzan los tres ítems
peor contestados** del examen de práctica, uno por cazador de errores, en el bloque 60–72 de `plan-sesion.md`.
Secuencia por ítem: voto individual con tarjetas A/B/C/D (1 min) → si el acierto queda entre 30 % y 80 %, discusión
en parejas (1 min) y revoto; fuera de ese rango se pasa directo → el profesor **ejecuta** el cazador correspondiente
(1 min) → regla general en una frase. Las parejas arrancan Modificar en cuanto se enuncia la regla. Cada distractor
nace de una idea errónea del Anexo A de `docs/metodo/01-marco-pedagogico.md` o de una nueva que aquí se documenta.

Si el grupo falla otros ítems (manos por sección al minuto 60), el profesor relanza **el ítem del examen** como
voto A/B/C/D con su clave; los tres CT de abajo cubren las tres familias de error que el autor espera ver fallar:
colectivas (III.1, I.1, IV.a), guardia e índices (II.2, IV.b) y sincronización (I.6, III.2).

## CT1 · `caza1` se cuelga con 4 procesos y termina con 1 (ideas 18, 16, 17)

`caza1_bcast_buggy`: la raíz ejecuta `MPI_Bcast(&n, 1, MPI_INT, 0, …)` dentro de `if (rank == 0)` y los demás
ejecutan `MPI_Recv(&n, 1, MPI_INT, 0, 0, …)` en el `else`. Con `mpirun -np 4`, `timeout` lo mata (código 124);
con `-np 1` imprime `media=3.497000`. ¿Por qué?

- **A.** `MPI_Bcast` es asíncrono: la raíz sigue adelante y los demás reciben tarde; con `timeout 60` en lugar de 5
  terminaría bien.
- **B.** Los rangos 1–3 esperan en `MPI_Recv`, que solo empareja mensajes punto a punto; un `MPI_Bcast` no genera
  ese mensaje, así que esperan para siempre. Con un proceso no hay a quién esperar. Corrección: todos llaman a
  `MPI_Bcast`, fuera del `if`.
- **C.** El error está en `MPI_Scatterv`: `counts` y `displs` los calcula la raíz y los demás rangos no los conocen.
- **D.** Si con `-np 1` funciona, el programa está bien; el cuelgue lo causa `--oversubscribe` al poner 4 procesos
  en 2 núcleos.

**Respuesta: B.**

| Distractor | Origen |
|---|---|
| A | Anexo A n.º 17 ("`MPI_Send`/colectivas regresan de inmediato") + "está lento, no colgado" |
| C | Nueva (18d): confunde "argumentos significativos solo en la raíz" (correcto para `Scatterv`) con un error. Todos los rangos de `caza1` calculan `counts`/`displs` de todos modos |
| D | Anexo A n.º 20 (sobre-suscripción) usado como excusa + n.º 7 ("salió bien una vez / con un proceso") |

**Acierto esperado en el primer voto: 60–70 %** (acaban de corregir III.1 y I.1; el error de B es el mismo que el
del ítem III.1 visto desde otro lado: quién tiene que participar en la colectiva).

**Guion de discusión (3 líneas).** "Quien votó A: ¿qué llamada hace el rango 1 y qué mensaje espera? ¿Quién lo
manda?" → "Quien votó D: ¿qué prueba la corrida con un proceso? ¿Con cuántos procesos corre tu P5?" → Ejecutar:
`make run-mpi` (código 124) y `make run-mpi NP=1`. Regla: **toda colectiva la llaman todos los procesos del
comunicador, con la misma raíz; la línea aparece una vez, fuera de cualquier `if (rank == …)`.**

## CT2 · "Usemos `block = 200` para que no sobren hilos" (ideas 34, 27, 26)

`caza2_guard_buggy 1000 256` (sin guardia): `sobrantes=24`, `centinelas_alterados=24 (de 24)`,
`cudaGetLastError=no error`, `verificacion=FALLA`. Un compañero propone: "pon `block = 200`: `1000 / 200 = 5`
exacto, no sobra ningún hilo y ya". ¿Qué le dices?

- **A.** Tiene razón: cuando `n` es múltiplo del bloque no hacen falta ni la guardia ni el redondeo hacia arriba.
- **B.** Con `n = 1000` el resultado saldría bien, pero el error sigue en el código: con cualquier otro `n` vuelven a
  sobrar hilos. Además 200 no es múltiplo de 32: el último *warp* de cada bloque va a medias.
- **C.** No sirve porque CUDA exige que el tamaño de bloque sea potencia de 2.
- **D.** Da igual: la versión actual ya es correcta, puesto que `cudaGetLastError` y `cudaDeviceSynchronize` no
  reportaron nada.

**Respuesta: B.**

| Distractor | Origen |
|---|---|
| A | Anexo A n.º 34 ("no hace falta comprobar `idx < n`"): la guardia se "arregla" eligiendo el tamaño |
| C | Nueva (26b): "el bloque debe ser potencia de 2". El límite real es ≤ 1 024 y la recomendación, múltiplo de 32 |
| D | Anexo A n.º 27 ("si el *kernel* no da error, el resultado es correcto") |

**Acierto esperado en el primer voto: 65–75 %.**

**Guion de discusión.** "Quien votó A: ¿cuál es el `n` de tu V3? ¿Y el de la prueba de `make test` con otro
tamaño?" → "Quien votó D: ¿qué dijo `centinelas_alterados`? En tu programa no hay centinelas: ¿qué hay después de
`y`?" → Ejecutar: `caza2_guard_numba.py 1000 256` (FALLA) y `1024 256` (OK con el mismo error). Regla: **`grid =
(n + block − 1) / block` y `if (i < n)` van siempre juntos; que un tamaño "salga bien" no corrige nada.**

## CT3 · Cinco veces `5500.0` con `block = 32` (ideas 25, 7, 32)

`caza3_reduce_buggy` (sin `__syncthreads()` dentro del ciclo del árbol) se corrió cinco veces en una T4 con
`block = 32` y las cinco dio `suma_gpu=5500.0 verificacion=OK`. Con `block = 256` da sumas distintas cada vez.
¿Qué concluyes?

- **A.** Con un *warp* por bloque los 32 hilos avanzan juntos, así que la barrera sobra: el programa es correcto
  para `block = 32` y basta documentarlo.
- **B.** Es comportamiento indefinido en los dos casos: que salga bien cinco veces no es evidencia. Falta
  `__syncthreads()` al final de cada nivel, **fuera** del `if`.
- **C.** Falta la barrera, pero debe ir **dentro** de `if (tid < stride)`: solo los hilos que suman necesitan esperar.
- **D.** La barrera es innecesaria si el anfitrión llama a `cudaDeviceSynchronize()` después del lanzamiento, porque
  esa llamada sincroniza todos los hilos de la GPU.

**Respuesta: B.**

| Distractor | Origen |
|---|---|
| A | Anexo A n.º 7 ("salió bien una vez, no hay carrera") + supuesto de *lockstep* del *warp*, que desde Volta (planificación independiente de hilos) no está garantizado sin `__syncwarp()` |
| C | Anexo A n.º 32 ("una barrera dentro de un `if` está bien si la ejecuta algún hilo"): los hilos que no entran al `if` nunca llegan y el bloque se cuelga o el comportamiento queda indefinido |
| D | Anexo A n.º 25 y 33: `cudaDeviceSynchronize` es una llamada del anfitrión que espera a que el *kernel* **termine**; no ordena nada dentro del bloque |

**Acierto esperado en el primer voto: 50–60 %** (A es el distractor fuerte: en S03 vieron que la divergencia se
razona por *warp*).

**Guion de discusión.** "Quien votó A: ¿qué garantiza CUDA sobre el orden de dos hilos del mismo *warp* que leen
y escriben `s[]`? ¿Y si mañana Colab asigna otra GPU?" → "Quien votó C: si el hilo 5 no entra al `if` cuando
`stride = 4`, ¿llega a la barrera? ¿Qué le pasa al hilo 0 que sí llegó?" → Ejecutar: tres corridas de
`caza3_reduce_numba.py 1000` (587, 785, 399 en la autoría; otros números en cada corrida) y la solución (5500.0). Regla: **una barrera de bloque
entre cada nivel del árbol, fuera de cualquier rama; la correctitud se prueba comparando con la CPU en varias
corridas, nunca con una corrida afortunada.**

## Registro para el profesor (llenar en la sesión)

| ConcepTest | Ítem del examen que relanza | % primer voto | % revoto | Distractor más votado | Nota |
|---|---|---|---|---|---|
| CT1 | | | | | |
| CT2 | | | | | |
| CT3 | | | | | |

Si un CT queda por debajo de 30 % en el primer voto, se reexplica con el ejemplo resuelto (parte A para CT1: tabla
por rango; parte B para CT2 y CT3: síntoma → número → hipótesis) antes de discutir, y ese tema abre la
retroalimentación del Examen 3 el lunes 14 de diciembre.
