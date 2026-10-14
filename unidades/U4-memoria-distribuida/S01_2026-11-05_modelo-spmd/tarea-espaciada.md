> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S01 · jueves 5 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S01 · Tarea espaciada (20–40 min)

Se revisa al inicio de la sesión del **lunes 9 de noviembre de 2026, 10:30**; trae las respuestas por escrito
(papel o archivo `tareas/U4-S01.md` en tu repositorio). En el 3er parcial las tareas no tienen ponderación
propia (`planeacion/mapa-evaluacion.md`); su contenido reaparece en la recuperación de inicio, en la Práctica 5
y en el Examen 3 (martes 8 de diciembre). Las respuestas están al final; úsalas **después** de intentar.

Aparte de esta tarea, el pre-laboratorio de la **Práctica 5** (`practicas/P5-mpi/README.md`) se entrega al inicio
de la sesión del martes 10 de noviembre, 08:30.

## Ejercicio 1 · Tema de hoy: reparto de índices y rangos (10–15 min)

**(a)** `n = 100`, `p = 8`. Llena la tabla para los rangos 0, 3 y 7.

| Rango | Bloques: `start` | Bloques: `count` | Bloques: índices | Cíclico: primeros tres índices | Cíclico: `count` |
|---|---|---|---|---|---|
| 0 | | | | | |
| 3 | | | | | |
| 7 | | | | | |

Comprueba que, sumando `count` de los 8 rangos, cada esquema cubre exactamente 100 índices.

**(b)** `n = 3`, `p = 4`. ¿Qué índices toma cada rango por bloques y por reparto cíclico? ¿Qué suma parcial
envía un rango sin elementos? ¿Rompe el total?

**(c)** Modifica `practica-guiada/suma_distribuida.c` para que combine el rango `size − 1` en lugar del 0 (M2
del README). Copia las líneas que cambiaste. `make test` debe seguir pasando. En una frase: ¿qué tiene de
especial el rango 0 en MPI? (Si ya hiciste M2 en clase, haz en su lugar la versión cíclica de `promedio_maximo.c`.)

## Ejercicio 2 · Intercalado (Unidad III · rendimiento y protocolo) (10 min)

Medición real de `suma_distribuida` con `n = 10⁹`, medianas de 5 repeticiones con calentamiento, en una
máquina virtual de 4 núcleos que estaba **compartida con otros procesos** (carga del sistema 5–7):

| Configuración | Mediana (s) |
|---|---|
| `referencia_secuencial` | 1.473 |
| `suma_distribuida -np 1` | 1.464 |
| `suma_distribuida -np 2` | 0.755 |
| `suma_distribuida -np 4` | 0.723 |

**(a)** Calcula *speedup* `S(p)` y eficiencia `E(p)` para `p = 1, 2, 4`, usando como `T(1)` la secuencial.
**(b)** Calcula la fracción secuencial estimada de Karp–Flatt `f = (1/S − 1/p) / (1 − 1/p)` para `p = 2` y `p = 4`.
**(c)** `f` crece mucho de `p = 2` a `p = 4`. ¿Qué regla de `herramientas/protocolo-medicion.md` se violó y cómo
se nota en los números? ¿Es correcto decir que "la suma tiene 32 % de código secuencial"?
**(d)** Pre-mortem: en tu laptop de 4 núcleos **sin carga**, ¿qué `S(4)` predices para este programa y por qué?
Escríbelo antes de medir; en la Práctica 5 lo mides.

## Ejercicio 3 · Preparación de S02 (5–10 min)

Busca en el MPI Standard (mpi-forum.org, capítulo "Point-to-Point Communication") o en `man MPI_Send` y
`man MPI_Recv` la lista de argumentos de cada función y escríbela con tus palabras (qué es cada uno).

Predicción para discutir el lunes: dos procesos, 0 y 1, ejecutan **ambos** primero `MPI_Send` hacia el otro
y después `MPI_Recv` del otro, con un arreglo de `count` elementos.
**(a)** ¿Funciona siempre? **(b)** ¿De qué podría depender? **(c)** Si el rango 0 espera un mensaje con
etiqueta `1` pero el rango 1 lo envió con etiqueta `0`, ¿qué pasa?

## Respuestas

<details>
<summary>Mostrar respuestas</summary>

**1(a)** `q = 100 / 8 = 12`, `r = 100 % 8 = 4`: los rangos 0–3 toman 13, los rangos 4–7 toman 12.

| Rango | `start` | `count` | Bloques | Cíclico | `count` cíclico |
|---|---|---|---|---|---|
| 0 | 0 | 13 | 0–12 | 0, 8, 16, … (hasta 96) | 13 |
| 3 | 3·12 + 3 = 39 | 13 | 39–51 | 3, 11, 19, … (hasta 99) | 13 |
| 7 | 7·12 + 4 = 88 | 12 | 88–99 | 7, 15, 23, … (hasta 95) | 12 |

Cíclico: `count_k = ⌈(n − k) / p⌉`; rangos 0–3: 13, rangos 4–7: 12. Ambos esquemas: 4·13 + 4·12 = 100.

**1(b)** Bloques: `q = 0`, `r = 3` → rangos 0, 1, 2 toman {0}, {1}, {2}; el rango 3 no toma nada. Cíclico:
igual ({0}, {1}, {2}, {}). El rango 3 envía `local_sum = 0.0`; sumar 0 no rompe nada. (Para el máximo sí habría
que cuidarlo: por eso `promedio_maximo` inicia el máximo parcial en −1.0.)

**1(c)** Tres cambios: `MPI_Send(&local_sum, 1, MPI_DOUBLE, size - 1, 0, MPI_COMM_WORLD)`; la condición
`if (rank != size - 1)`; y el ciclo `for (int src = 0; src < size - 1; src++)` con la impresión en
`rank == size - 1`. Nada: el rango 0 es un número como cualquier otro; "rango 0 = maestro" es una convención
(idea errónea 19).

**2(a)** `S(1) = 1.473/1.464 = 1.01`, `E = 1.01`; `S(2) = 1.473/0.755 = 1.95`, `E = 0.98`;
`S(4) = 1.473/0.723 = 2.04`, `E = 0.51`.
**2(b)** `p = 2`: `f = (1/1.95 − 0.5)/0.5 ≈ 0.025`. `p = 4`: `f = (1/2.04 − 0.25)/0.75 ≈ 0.32`.
**2(c)** Regla 1.5 ("cierra lo demás") y, por consecuencia, la lista de hilos/procesos hasta los núcleos
**disponibles**: con otros procesos ocupando núcleos, 4 procesos compiten por menos de 4 núcleos. Se nota en que
`f` salta de 0.025 a 0.32: Karp–Flatt creciente con `p` indica sobrecarga o contención creciente, no código
secuencial. No es correcto: el programa tiene una fracción secuencial real cercana a 0 (arranque + 3 mensajes
de un `double`, microsegundos frente a 1.4 s). La fracción secuencial se mide en tiempo y en condiciones
controladas, no se lee de un número contaminado.
**2(d)** Predicción razonable: `S(4)` entre 3.6 y 3.9 (`E ≥ 0.9`), porque el trabajo es perfectamente
divisible y la comunicación es despreciable; lo que quede por debajo de 4 será arranque de procesos, barrera y
variación entre núcleos. Vale cualquier predicción justificada con estos argumentos.

**3** `MPI_Send(buf, count, datatype, dest, tag, comm)`: dirección del dato, cuántos, de qué tipo, a quién,
etiqueta, comunicador. `MPI_Recv(buf, count, datatype, source, tag, comm, status)`: lo mismo más `status`
(de dónde llegó, con qué etiqueta, cuántos elementos). **(a)** No siempre. **(b)** De si la biblioteca puede
guardar el mensaje en un *buffer* intermedio: con mensajes pequeños suele hacerlo y los dos `Send` regresan;
con mensajes grandes cada `Send` espera a que el otro lado ejecute `Recv`, y como ambos están en `Send`, nadie
llega al `Recv`: interbloqueo (idea errónea 17; se demuestra el lunes). **(c)** El `Recv` del rango 0 espera
para siempre un mensaje con etiqueta 1 que nunca llega; el mensaje con etiqueta 0 queda pendiente. El programa
se cuelga sin error.

</details>
