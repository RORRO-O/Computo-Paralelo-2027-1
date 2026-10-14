> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S04 · jueves 12 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S04 · Descomposición de dominio: celdas fantasma en Jacobi 1D

Tipo: **Contenido** (estructura base de 90 min) con 10 min de retroalimentación del Examen 2 dentro del bloque de anclaje.
Para absorberlos se recortan Transferencia (10 → 7 min), Puesta en común (10 → 8 min) y Práctica guiada (30 → 27 min) e Instrucción explícita (25 → 23 min).
Recuperación y Cierre no se tocan.

## Objetivos (al terminar, el estudiante podrá…)

1. Calcular, dados `n` y `p`, el reparto por bloques con residuo de cada rango (`local_n`, celdas globales) y decir qué celdas envía y recibe como halo. (aplicar)
2. Explicar por qué el intercambio de halos con `MPI_Sendrecv` o con `Isend/Irecv/Waitall` no se interbloquea, y por qué un halo que no se actualiza produce un resultado incorrecto **sin** error ni cuelgue. (analizar)
3. Implementar la condición de paro global con `MPI_Allreduce(MPI_MAX)` y justificar por qué la llaman todos los procesos. (aplicar / evaluar)
4. Verificar una versión MPI contra la secuencial (iteraciones y valores con tolerancia) y ubicar la misma descomposición en la V2 (OpenMP) y la V3 (CUDA, mosaicos con borde) del proyecto. (evaluar)

Los objetivos 1–3 se miden en el exit ticket; el 4 en la fase Crear y en la tarea.

## Prerrequisitos y vínculo

- **Viene de:** S03 (martes 10 de noviembre): colectivas (`Bcast`, `Scatter`, `Gather`, `Reduce`, `Allreduce`), producto matriz-vector, Lab 1 de P5.
  S02 (lunes 9): `Send`/`Recv`, interbloqueo, *ping-pong*. U3-S11 (lunes 26 de octubre): Jacobi 1D con doble búfer en OpenMP. U2: método de Foster.
- **Va hacia:** S05 (martes 17 de noviembre, 08:30, Lab LS4): rendimiento en MPI (modelo latencia + ancho de banda, escalabilidad fuerte y débil, sobre-suscripción) y Lab 2 de P5 (Partes C y D). El lunes 16 de noviembre no hay clase.
- **Nivel de andamiaje:** con pistas (07 §A.5). Es la tercera sesión de contenido de la unidad: el ejemplo resuelto está completo
  (se escribió antes de esta regla), así que el desvanecimiento va en la práctica guiada: Predecir e Investigar abreviados (6 y 7 min),
  Modificar con `TODO(1)`–`TODO(4)` sin código dado, y Crear sin estructura (7 min en clase, el resto en la tarea 1).
- **Ideas erróneas que ataca (Anexo A):** 17 (semántica de `Send`, dos envíos cruzados) → CT1 y pausa 3 del ejemplo; 18 (las colectivas las llaman todos) → CT2, pausa 4, exit ticket 1; 20 (más procesos que núcleos) → I6 de la práctica y tarea 2(c); 21 (la comunicación no es gratis) → CT3, notas §6, tarea 3; 28 (aglomerar no es juntar todo) → recuperación 3, pausa 1, CT3.

## Materiales

- Esta carpeta compilada en la máquina del salón: `cd practica-guiada && make && make test` (debe dar 7 PASS, 0 FAIL, 3 SKIP; tarda ≈ 15 s en 4 núcleos).
  Si `mpirun` rechaza 4 procesos por falta de *slots*, el Makefile ya pasa `--oversubscribe`.
- Proyector; cronómetro visible; tarjetas con números de lista; tarjetas A/B/C/D para los ConcepTests.
- Tres diapositivas o impresiones con los 3 ítems peor contestados del Examen 2 (sin la respuesta) y el registro de abajo lleno.
- Exit tickets de S03 clasificados; el error más frecuente anotado para el anclaje.

## Guion minuto a minuto

### 0–5 · Recuperación

Proyectar `retrieval-inicio.md`. Responden solos, en papel. A los 4 min se abre la clave; manos por pregunta.
Respuestas esperadas: 1) `Reduce` deja el resultado en la raíz, `Allreduce` en todos, ambas las llaman todos; 2) `Scatter(v)`, `Bcast`, `Gather(v)`;
3) agrupar celdas contiguas 1–4, 5–8, 9–12; desaparece la comunicación interna del bloque; 4) `u_new[i]` lee valores de la iteración anterior; 5) celdas 4 y 9, en los procesos 0 y 2.
Si < 60 % acierta la 1: repetir en el pizarrón "colectiva = la llaman todos" antes del ejemplo; hoy se usa en cada iteración y CT2 lo retoma.

### 5–10 · Objetivos y anclaje

Frase de arranque: "El martes repartieron una matriz con `Scatter` y juntaron el resultado con `Gather`. Hoy repartimos una barra de
celdas, pero con una diferencia: cada celda necesita a sus vecinas, y dos de ellas viven en otro proceso. Ese par de celdas ajenas
se llama halo, y es el patrón que aparece en cualquier malla: Jacobi 2D, autómatas celulares, filtros de imagen, y los mosaicos
con borde de la V3 en CUDA".
Conectar con el error más frecuente del exit ticket de S03 (anotarlo aquí: __________________________). Si fue "solo la raíz llama a la colectiva", anunciar que hoy se ve qué pasa en vivo cuando eso ocurre.
Leer los 4 objetivos. Señalar: "al final del día deben poder decir qué celda envía y recibe el rango 1 sin correr el programa".

### 10–20 · Retroalimentación del Examen 2 (3 de noviembre)

Procedimiento, 3 ítems × ~3 min + 1 min de calibración:

1. Proyectar el ítem **sin** la respuesta. 30 s de revoto individual con tarjetas A/B/C/D (o "levanta la mano si lo resolverías distinto hoy" en ítems abiertos).
2. Mostrar la distribución real del examen (porcentaje por opción) y nombrar la idea errónea del Anexo A que explica el distractor más elegido.
3. Re-resolverlo en voz alta en ≤ 90 s: qué se mira primero, qué se descarta y por qué. Una línea de "cómo detectarlo la próxima vez".
4. Cierre (1 min): brecha de calibración del grupo (promedio de calificación predicha vs. obtenida), sin nombres. Si la sobreestimación promedio pasa de 1.5 puntos, decirlo: es el umbral de alerta del método.

Registro (llenar antes de la sesión con las estadísticas de `docente/examenes/E2/`):

```
Ítem ___ · tema: ______________________ · % de acierto: ___ · distractor más elegido: ___ · idea errónea A-___
Ítem ___ · tema: ______________________ · % de acierto: ___ · distractor más elegido: ___ · idea errónea A-___
Ítem ___ · tema: ______________________ · % de acierto: ___ · distractor más elegido: ___ · idea errónea A-___
```

Regla de tiempo: si a los 10 min no se terminó el tercer ítem, se pospone al inicio de S06 (jueves 19 de noviembre); no se recorta el ejemplo resuelto.
Los exámenes se devuelven al final de la sesión o en asesoría; las dudas individuales no se atienden en este bloque.

### 20–43 · Instrucción explícita I (ejemplo resuelto + CT1)

Proyectar `ejemplo-resuelto.md` y el código `practica-guiada/jacobi1d_mpi.c`. Pensar en voz alta; en cada pausa, 30 s de respuesta en parejas y 1 tarjeta al azar.

| Min | Paso | Qué decir / hacer |
|---|---|---|
| 20–23 | Problema y plan (Foster en 3 líneas) | Dibujar la barra de 12 celdas con fronteras 0 y 13; cortar en 3 bloques. **Pausa 1** (¿por qué no cíclico?): esperar "cada celda necesitaría a sus dos vecinos por mensaje". Ligar con la idea 28. |
| 23–27 | `block_partition` | Calcular en el pizarrón `n=12,p=3` y `n=13,p=5` (3,3,3,2,2). **Pausa 2**: índice global = `offset + i`; el arreglo mide `local_n + 2`. Dibujar los halos como cajas punteadas. |
| 27–31 | Vecinos y `MPI_PROC_NULL` | "Enviarle a nadie no hace nada; recibir de nadie no toca el búfer. Por eso el rango 0 conserva 100 en `u[0]` sin ningún `if`." |
| 31–36 | `exchange_halos_sendrecv` | Mostrar los dos pasos con flechas: paso 1 todo viaja a la derecha, paso 2 todo a la izquierda. **Pausa 3** (¿por qué no se interbloquea?): la operación envía y recibe a la vez; no depende del *buffering*. |
| 36–39 | **CT1** (`conceptests.md`) | Voto → si 30–80 %, parejas 2 min → revoto → explicación. Regla: "un programa que depende del *buffering* es incorrecto aunque hoy funcione". |
| 39–42 | Paso de Jacobi + `Allreduce` + `Gatherv` | **Pausa 4** (`if (rank == 0) Allreduce`): se cuelga. Mostrar el `Gatherv` con `counts`/`displs` de la misma función de reparto. |
| 42–43 | Salida real | Secuencial y MPI: `iteraciones=280`, mismo `checksum`. **Pausa 5** (¿por qué exactamente iguales?): dos operandos, mismo orden, `MAX` exacto. Anunciar: "ahora ustedes van a romperlo a propósito". |

### 43–70 · Práctica guiada PRIMM (parejas conductor/navegante; cambio a los 12 min, minuto 55)

Arranque (1 min): "Abran `practica-guiada/README.md`. Fase P sin tocar el teclado, 6 minutos; el navegante escribe. Después R, I y M.
Quien termine M antes del minuto 70 empieza C." Circular con esta lista. No dar respuestas: hacer la pregunta.

| Error esperado | Dónde aparece | Pregunta que se hace |
|---|---|---|
| "El rango 1 envía `u[1]` y `u[4]`" (índices locales como globales) | P2 | "¿Qué índice global tiene la celda local 1 del rango 1? ¿Qué devuelve `block_partition` como `offset`?" |
| "Sin halo izquierdo se interbloquea / da error" | P5 | "¿Qué llamada se queda esperando una pareja que no llega? Señálala en el código." |
| "MPI converge en otro número de iteraciones por redondeo" | P4 | "¿Qué operaciones hace cada celda en cada versión? ¿Hay alguna suma cuyo orden cambie?" |
| "El halo llegó en 0.0000: el intercambio falló" | R, I2 | "¿Cuánto valía la celda 4 del rango 0 antes de la iteración 1? ¿Cuándo deja de ser 0? Prueba `--trace 6`." (el rango 1 ve `u[4]=6.2500` en la iteración 5; el rango 0 ve `u[5]=3.1250` en la 6) |
| `mpirun`: "not enough slots" | R | "¿Cuántos núcleos ve `mpirun`? ¿Qué bandera agrega el Makefile y qué efecto tiene en los tiempos?" (idea 20) |
| Tiempos enormes con `NP=4` | I6 | "¿Cuántos procesos corren y cuántos núcleos libres hay? ¿Qué hace un proceso dentro de `Allreduce` mientras espera?" |
| En M: `MPI_Waitall` antes de los `Isend`, o sin `Waitall` | M, paso 3–4 | "¿En qué momento está garantizado que `u[0]` ya tiene el valor? ¿Qué dice el estándar sobre leer el búfer de un `Irecv` antes de `Wait`?" |
| En M: etiquetas cruzadas (`Irecv` en `u[0]` con `TAG_TO_LEFT`) → cuelgue | M | "¿Con qué etiqueta sale el mensaje que debe llegar a tu halo izquierdo? ¿Quién lo manda?" Usar `timeout 10`. |
| En M: una sola `MPI_Request` reutilizada para las cuatro operaciones | M | "¿Cuántas operaciones publicaste? ¿Cuántas espera `Waitall`?" |
| En M: olvidan `done = 1` y creen que su código no corre | M, paso 5 | "¿Qué imprime el programa? ¿Qué línea produce ese mensaje?" |
| En C: fuente fijada en `local_n/2` de **cada** rango | C, opción A | "¿Cuántas fuentes tiene el problema? ¿Cuántas celdas fijas tiene tu versión con `p=4`? ¿Cómo pasas de índice global a local?" |
| En C: fuente o frontera solo en `u`, no en `u_new` | C | "¿Qué arreglo se lee en la iteración 2? ¿Qué valor tiene ahí la celda fuente?" |

Al minuto 55: anunciar cambio de roles. Al minuto 62: quien no haya llegado a M, que ejecute `--exchange isend` para ver el mensaje `TODO pendiente` y lea los cuatro TODO aunque no los complete.

Solución de la fase M (para el profesor; el estudiante la construye):

<details><summary>exchange_halos_isend completa</summary>

```c
static int exchange_halos_isend(double *u, int local_n, int left, int right) {
    MPI_Request reqs[4];
    MPI_Irecv(&u[0],           1, MPI_DOUBLE, left,  TAG_TO_RIGHT, MPI_COMM_WORLD, &reqs[0]);
    MPI_Irecv(&u[local_n + 1], 1, MPI_DOUBLE, right, TAG_TO_LEFT,  MPI_COMM_WORLD, &reqs[1]);
    MPI_Isend(&u[local_n],     1, MPI_DOUBLE, right, TAG_TO_RIGHT, MPI_COMM_WORLD, &reqs[2]);
    MPI_Isend(&u[1],           1, MPI_DOUBLE, left,  TAG_TO_LEFT,  MPI_COMM_WORLD, &reqs[3]);
    MPI_Waitall(4, reqs, MPI_STATUSES_IGNORE);
    return 1;
}
```

Verificado en el entorno de autoría: con esta función `make test` pasa 10/10 (los tres casos `isend` dan `iteraciones=280`, `228` y `2000`, diferencia máxima 0.0 contra la secuencial).
</details>

### 70–78 · Puesta en común + CT2

Mostrar 2–3 hallazgos del salón sin nombres (típicos: índices locales confundidos con globales; "el halo en 0 es un error"; etiquetas cruzadas en M).
Proyectar el perfil (`python3 graficar_perfil.py perfil_seq.txt perfil_mpi.txt perfil_buggy.txt`): la curva del buggy cae a 0 desde la celda 5.
**CT2** (`if (rank == 0) MPI_Allreduce`): voto → parejas → revoto → explicación.
Regla general en una frase: **"Una colectiva es una cita a la que van todos los procesos; si uno falta, los demás esperan sin aviso. Y un halo que no se actualiza no truena: miente."**
Si sobran 2 min: CT3 (reparto cíclico) como puente a S05.

### 78–85 · Transferencia (fase C)

Reto: opción A (fuente de calor en el centro) u opción B (frontera distinta) del README, en las dos versiones.
Criterio de "listo": `make` sin warnings, secuencial y MPI coinciden en iteraciones y `checksum` (opción A con `n=15`: `iteraciones=117`, `checksum=7.999401682787e+02`), y el estudiante explica qué línea evita que la fuente se pierda al intercambiar `u` y `u_new`.
Quien no arranca: dar la secuencial ya modificada (3 líneas: `src = (n+1)/2`, fijar en ambos arreglos, `if (i == src) continue;`) y pedir solo la MPI.
Quien termina: convergencia cada `k` iteraciones (`if (iter % k == 0) Allreduce`) con `k = 10`: ¿cambia el número de iteraciones? ¿cuántas colectivas se ahorran? Anotar para S05.
Lo que no se termine aquí es el ejercicio 1 de la tarea.

### 85–90 · Cierre

Exit ticket en papel (`exit-ticket.md`), individual. Mientras escriben, anunciar:
- Tarea espaciada: `tarea-espaciada.md`, entrega antes del **martes 17 de noviembre, 08:30**; el ejercicio 3 es la predicción obligatoria para la Parte D de P5.
- **Lunes 16 de noviembre no hay clase** (Revolución Mexicana).
- **Martes 17 de noviembre, 08:30, Lab LS4: Lab 2 de la Práctica 5 (Partes C y D)**; traer la Parte C avanzada y los datos del *ping-pong* de S02.
- Fecha límite de P5: **domingo 22 de noviembre, 23:59** (15 % del 3er parcial).

## Diferenciación

- **Apoyo (quien no arranca en P):** entregar la tabla P1 con la fila del rango 0 llena y pedir solo las filas 1 y 2; correr `--trace 1` juntos y leer la línea del rango 1 palabra por palabra contra el código. En M, dar la primera `MPI_Irecv` escrita y pedir las otras tres por simetría.
- **Ampliación (quien termina C):** (1) convergencia cada `k` iteraciones y conteo de colectivas; (2) solapar cómputo y comunicación: calcular las celdas `2..local_n-1` entre el `Isend` y el `Waitall`, y las dos de la orilla después; verificar que `make test` sigue pasando; (3) esbozar en papel el reparto por filas de Jacobi 2D con `p=4`: ¿cuántos halos, de qué tamaño?

## Evaluación formativa de la sesión

| Objetivo | Qué mira el profesor |
|---|---|
| 1 Reparto y halos | Tabla P1/P2 correcta en ≥ 80 % de las parejas al minuto 52; exit ticket 2(a)(b) |
| 2 Sendrecv/Isend y halo omitido | CT1 revoto ≥ 80 %; P5 con opción (c) justificada; exit ticket 2(c) |
| 3 Convergencia global | CT2 revoto ≥ 80 %; exit ticket 1 (opción B con la llamada que espera nombrada) |
| 4 Verificación y proyecto | `make test` con el caso de la variante propia (tarea 1); mención del halo en la V3 en la pregunta de cierre al azar: "¿dónde reaparece el halo en CUDA?" |

Umbral de alerta: > 30 % de exit tickets en "mal" (pregunta 1 en A, C o D, o 2(c) con "error" o "se cuelga") → abrir S05 con el buggy en vivo antes de medir.

## Notas post-sesión

- Qué falló / qué cambiar: ______________________________________________
- Error más frecuente del exit ticket: ____________________________________
- CT con menor acierto y distractor dominante (copiar de `conceptests.md`): ______________
- Ítems del Examen 2 que quedaron pendientes para S06: ____________________
