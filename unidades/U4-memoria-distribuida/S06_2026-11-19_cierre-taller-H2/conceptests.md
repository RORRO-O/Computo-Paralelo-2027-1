> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S06 · jueves 19 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S06 · ConcepTests (instrucción entre pares)

Secuencia fija: voto individual (1 min, tarjetas A/B/C/D) → discusión en parejas (2 min: "convence a tu par") →
revoto → explicación (2 min). Si el primer voto supera 80 % de aciertos se salta la discusión; si queda por
debajo de 30 % se reexplica el punto antes de discutir. Tras la discusión se pregunta por tarjeta de lista "¿qué
concluyó tu pareja?". En esta sesión (taller) el **CT2 se vota una sola vez** y se discute solo si el acierto
queda entre 30 % y 80 %. El CT3 es reserva: la recuperación de U5·S01 (lunes 23 de noviembre) ya lo pregunta
como ítem 1, o va al examen de práctica del jueves 3 de diciembre. Cada distractor nace de una idea errónea del
Anexo A de `docs/metodo/01-marco-pedagogico.md` o de una nueva que aquí se documenta.

## CT1 · ¿Quién tiene que ir a la cita? (minuto ~16, al cerrar la Parte B del ejemplo resuelto)

Se ejecuta con `mpirun -np 4`. Todos los procesos corren este código:

```c
int color = rank / 2, key = rank % 2;          /* rangos 0,1 -> color 0; rangos 2,3 -> color 1 */
MPI_Comm row_comm;
MPI_Comm_split(MPI_COMM_WORLD, color, key, &row_comm);
int s;
MPI_Allreduce(&rank, &s, 1, MPI_INT, MPI_SUM, row_comm);
```

Fíjate en el `MPI_Allreduce` que ejecuta el **rango 3**. ¿Qué otros procesos tienen que ejecutar su
`MPI_Allreduce` para que el del rango 3 termine?

- **A)** Los otros tres (0, 1 y 2): una colectiva la llaman todos los procesos que lanzó `mpirun`.
- **B)** Solo el rango 2, que tiene el mismo color; los rangos 0 y 1 tienen su propia cita en otro comunicador.
- **C)** Ninguno: `MPI_Allreduce` no tiene raíz, así que cada proceso la llama cuando quiere y recibe la suma de
  los que ya llamaron.
- **D)** Solo la raíz de `row_comm` (el rango 2, que es el rango 0 de esa fila); el rango 3 recibe por debajo.

| Opción | Origen |
|---|---|
| A | Nueva (18b): "una colectiva es sobre todos los procesos del programa". Confunde `MPI_COMM_WORLD` con "el comunicador sobre el que se llama". Se agrega al catálogo. |
| **B** | **Correcta.** `s` vale 1 en los rangos 0 y 1 y 5 en los rangos 2 y 3 (salida real del ejemplo). |
| C | Nueva (18c): "sin raíz no hay espera". Toda colectiva es un punto de encuentro de todos los procesos del comunicador, tenga raíz o no. |
| D | Idea errónea 18: "solo el proceso raíz llama a la colectiva", trasladada a un comunicador derivado. |

**Acierto esperado en el primer voto:** 50–60 % (A es el distractor fuerte: en S03 aprendieron "todos llaman a la
colectiva" y lo generalizan a "todos los de `mpirun`").

**Guion de discusión (3 líneas).** "Quien votó A: ¿sobre qué comunicador está llamando el rango 3? ¿Quiénes
están dentro de ese comunicador? Quien votó D: en S03 vimos qué pasa cuando solo la raíz llama a `Bcast`; ¿por
qué sería distinto aquí?" Cerrar con el Hueco 3 del ejemplo resuelto: si se cambia `row_comm` por
`MPI_COMM_WORLD`, los cuatro imprimen 6 y `VERIFICACION FAIL`, sin cuelgue ni aborto. Regla: **una colectiva la
llaman todos los procesos del comunicador sobre el que se llama, ni más ni menos.**

## CT2 · La tabla que "escala hasta 8" (minuto ~76, puesta en común del taller; voto único)

Un equipo trae esta tabla de su V2, medida en una laptop con **4 núcleos físicos**, una corrida por configuración:

| Versión | Hilos | Tiempo (s) | *Speedup* |
|---|---|---|---|
| V2 | 1 | 2.49 | 1.00 |
| V2 | 2 | 1.29 | 1.93 |
| V2 | 4 | 0.71 | 3.51 |
| V2 | 8 | 0.715 | 3.48 |

Su interpretación: "la V2 escala hasta 8 hilos con *speedup* 3.48". ¿Qué le dices?

- **A)** La conclusión es válida: 3.48 con 8 hilos es un buen *speedup* y la tabla tiene las cuatro
  configuraciones que pide el protocolo.
- **B)** Ninguno de los números de la conclusión está respaldado: falta V1 como `T(1)` (la columna *speedup* está
  normalizada contra V2 con un hilo), falta la mediana de ≥ 5 repeticiones, y la fila de 8 está sobre-suscrita y
  no sirve para concluir escalabilidad.
- **C)** El único problema es que con 8 hilos debería ser más rápido que con 4; si no lo es, la V2 tiene una
  condición de carrera.
- **D)** Falta promediar varias corridas y reportar el promedio; con eso la tabla cumple el protocolo.

| Opción | Origen |
|---|---|
| A | Idea errónea 5 ("medir una vez basta") + 31 ("el *speedup* se calcula contra la versión paralela con 1 hilo"). |
| **B** | **Correcta.** Con `V1 = 2.405 s` (CSV de ejemplo de la práctica) el *speedup* real con 4 hilos es 3.38, no 3.51; la fila de 8 tiene `E = 0.42` y `f = 0.197`: no es escalabilidad, es sobre-suscripción. |
| C | Idea errónea 1 ("más hilos siempre es más rápido") + 20 (ignora que 8 hilos en 4 núcleos físicos no son 8 núcleos). Una carrera se detecta comparando resultados, no mirando tiempos. |
| D | Idea errónea 5, variante "promedio": el protocolo pide **mediana** (robusta ante picos) y además `T(1)` sigue estando mal. |

**Acierto esperado en el primer voto:** 65–75 % (ya revisaron una tabla ajena con la lista 2.3). Si supera 80 %
se pasa directo a la regla; si queda entre 30 % y 80 % se discute en parejas y se revota; por debajo de 30 % se
proyecta `make revisar` otra vez antes de discutir.

**Guion de discusión (3 líneas).** "Quien votó A o D: ¿qué número va en el numerador del *speedup* según el
protocolo? ¿Está en esa tabla? Quien votó C: ¿cuántos núcleos físicos tiene la laptop? ¿Qué hacen los hilos 5 a 8
mientras los 4 núcleos están ocupados?" Regla general: **sin `T(1)` = V1, sin mediana de 5 y sin marcar la fila
sobre-suscrita, la tabla no es evidencia; es una anécdota.** Enlace con H2: criterio 2 de la rúbrica cae a "En
desarrollo" por cualquiera de las tres cosas.

## CT3 · "Funcionó con n = 100" (reserva: recuperación de U5·S01 o examen de práctica)

`caza1_orden_send_buggy` (los dos procesos de cada pareja hacen `MPI_Send` y después `MPI_Recv`) terminó con
`VERIFICACION OK` con `n = 100` y se colgó con `n = 1 000 000`. ¿Qué concluyes?

- **A)** El programa es correcto: `MPI_Send` es asíncrono y regresa de inmediato; el cuelgue con `n` grande es un
  problema de memoria de la máquina.
- **B)** El programa es incorrecto y Open MPI no cumple el estándar: `MPI_Send` debe esperar siempre al `MPI_Recv`
  del otro lado, así que también debió colgarse con `n = 100`.
- **C)** El programa es incorrecto en los dos casos: `MPI_Send` puede regresar al copiar el mensaje a un búfer
  interno (chico) o esperar al receptor (grande), y las dos conductas son válidas. Un programa que depende de
  eso es inseguro; se corrige con `MPI_Sendrecv`, orden por paridad o `Isend`/`Irecv` + `Wait`.
- **D)** Funciona porque son 4 procesos; con 2 procesos se colgaría con cualquier `n`.

| Opción | Origen |
|---|---|
| A | Idea errónea 17, mitad "siempre regresa de inmediato". |
| B | Idea errónea 17, mitad "siempre bloquea hasta que el otro recibe". |
| **C** | **Correcta.** Umbral real en la máquina de autoría: 505 `double` (4 040 bytes) termina; 508 (4 064 bytes) se cuelga; límite *eager* de Open MPI: 4 096 bytes con cabecera. |
| D | Nueva (17b): confunde el número de parejas con la condición de interbloqueo; cada pareja es independiente y las dos partes de cada pareja hacen lo mismo. Se agrega al catálogo. |

**Acierto esperado en el primer voto:** 60–70 % (S02 CT1 ya atacó la 17; aquí se mide si quedó).

**Guion de discusión.** "Quien votó A: ¿qué promete `MPI_Send` según S02 §4? Si fuera asíncrono siempre, ¿para
qué existiría `MPI_Isend`? Quien votó B: entonces, ¿cómo terminó con `n = 100`?" Mostrar la corrida real del
barrido: `n = 505` termina, `n = 508` no. Regla: **el programa debe terminar aunque todos los `Send` esperen al
`Recv`; si solo funciona hasta cierto `n`, está mal.**

## Registro para el profesor (llenar en la sesión)

| ConcepTest | % 1er voto | % revoto | Opción más votada entre los errados | Nota |
|---|---|---|---|---|
| CT1 | | | | |
| CT2 | | — (voto único salvo 30–80 %) | | |
| CT3 | (si se usa) | | | |
