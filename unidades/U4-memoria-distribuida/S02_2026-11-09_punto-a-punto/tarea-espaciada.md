> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S02 · lunes 9 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S02 · Tarea espaciada (20–40 minutos)

Tres ejercicios cortos: uno del tema de hoy, uno intercalado de la Unidad III, uno de preparación para la
siguiente sesión. Se hace individualmente, sin IA en los ejercicios 2 y 3 (son del tipo que aparece en el
Examen 3, martes 8 de diciembre); en el ejercicio 1 aplica el semáforo de `docs/metodo/05-politica-ia.md`.

**Entrega.** Individual, en el repositorio del equipo: `tareas/<usuario-github>/U4-S02.md` y el código del
ejercicio 1 en `tareas/<usuario-github>/U4-S02/ring_laps.c`, antes del **martes 10 de noviembre de 2026, 08:30**
(inicio de S03, Lab LS4). La autocalificas con las claves en los minutos 5–10 de S03 (2 min); el profesor
registra la entrega, no el acierto, y revisa 3 al azar por parcial. **Esta tarea no tiene peso propio; el examen
de práctica del jueves 3 de diciembre y el 10–20 % acumulativo del Examen 3 toman ítems de aquí.** Si faltaste
hoy, entregarla en esa misma fecha sustituye tu recuperación y tu *exit ticket* de S02
(`docs/metodo/04-evaluacion.md` §5).

**Nota:** el pre-laboratorio de la Práctica 5 es aparte y vence a la misma hora: antes de las **08:30 del martes
10 de noviembre**, en el repositorio del equipo (ver `practicas/P5-mpi/README.md`).

---

## Ejercicio 1 · Tema de hoy: el anillo da k vueltas (15 min)

Copia `practica-guiada/ring_token.c` a `ring_laps.c` y modifícalo para que el token dé **k vueltas**
completas al anillo (k por línea de comandos, segundo argumento; el primero sigue siendo el valor inicial).
En cada vuelta cada rango r ≥ 1 suma su rango. El rango 0 imprime solo el valor final.

Criterio de verificación (ejecutado en la máquina de autoría):

```
$ mpirun -np 5 ./ring_laps 0 3
rango 0: token final = 30 tras 3 vueltas
$ mpirun -np 4 ./ring_laps 10 2
rango 0: token final = 22 tras 2 vueltas
```

Escribe debajo del código, en dos líneas: ¿por qué el rango 0 debe seguir enviando primero en **cada**
vuelta, y qué pasaría con k = 2 si en la segunda vuelta recibiera primero?

<details><summary>Pista (ábrela solo si llevas más de 10 minutos atorado)</summary>
El rango 0 ejecuta <code>for (lap) { Send; Recv; }</code>; los demás, <code>for (lap) { Recv; sumar; Send; }</code>.
El valor final es <code>inicial + k · (size − 1) · size / 2</code>.
</details>

<details><summary>Clave del ejercicio 1 (para autocalificarte)</summary>
Correcto si reproduce las dos salidas de arriba. Las dos líneas: en cada vuelta alguien tiene que inyectar el
token, y solo el rango 0 lo tiene al empezar la vuelta. Si en la segunda vuelta recibiera primero, todos los
rangos quedarían en <code>MPI_Recv</code> esperando al anterior y nadie enviaría: interbloqueo con cualquier tamaño
de mensaje (es el caso E1 de la práctica guiada), no por el <i>buffering</i>.
</details>

## Ejercicio 2 · Intercalado (Unidad III): leer una tabla de rendimiento (10 min)

Una versión OpenMP de un programa, medida con el protocolo del curso (mediana de 5, `-O2`, tamaño fijo),
dio estos tiempos en 4 núcleos físicos:

| hilos p | mediana (s) |
|---|---|
| 1 (secuencial) | 4.00 |
| 2 | 2.10 |
| 4 | 1.20 |

a) Calcula *speedup* S(p) y eficiencia E(p) para p = 2 y p = 4.
b) Calcula la fracción secuencial estimada de Karp–Flatt, f = (1/S − 1/p) / (1 − 1/p), para p = 2 y p = 4.
c) ¿Crece f con p? ¿Qué te dice eso sobre la causa de la pérdida de eficiencia (fracción secuencial fija
vs. sobrecarga que crece)? Una línea.
d) Si esta misma descomposición se llevara a MPI con 4 procesos, ¿qué término nuevo aparecería en el tiempo
que Karp–Flatt agruparía dentro de f? Una línea.

<details><summary>Respuestas</summary>
a) S(2) = 4.00/2.10 = 1.90; E(2) = 0.95. S(4) = 4.00/1.20 = 3.33; E(4) = 0.83.<br>
b) f(2) = (1/1.90 − 1/2)/(1 − 1/2) = (0.525 − 0.500)/0.500 = 0.050. f(4) = (1/3.33 − 1/4)/(1 − 1/4) =
(0.300 − 0.250)/0.750 = 0.067.<br>
c) Sí, crece (0.050 → 0.067). Si la pérdida fuera solo una fracción secuencial fija (Amdahl puro), f sería
constante; que crezca indica sobrecarga que aumenta con p: sincronización, creación de hilos, falso
compartido o ancho de banda de memoria.<br>
d) El tiempo de comunicación (α + m/β por mensaje, multiplicado por el número de mensajes), que crece con
el número de procesos y que Karp–Flatt no distingue de la parte secuencial.
</details>

## Ejercicio 3 · Preparación para mañana, S03 (martes 10 de noviembre, 08:30): una predicción (5–10 min)

Mañana se ven las **colectivas** (`MPI_Bcast`, `MPI_Scatter`, `MPI_Gather`, `MPI_Reduce`). Antes de verlas,
predice con lo de hoy:

El rango 0 tiene un arreglo de 1 MiB que los otros 7 procesos (8 en total) necesitan completo.

- **Opción A.** El rango 0 hace 7 `MPI_Send` seguidos, uno a cada rango.
- **Opción B.** Árbol: paso 1, 0→4; paso 2, 0→2 y 4→6; paso 3, 0→1, 2→3, 4→5, 6→7.

a) Con la tabla del *ping-pong* (1 MiB ≈ 0.46 ms de ida en la máquina de autoría), ¿cuánto tarda cada opción
en el **peor** proceso, aproximadamente?
b) ¿Cuántos mensajes se envían en total en cada opción? ¿Entonces de dónde sale la ganancia de B?
c) Escribe una línea: ¿qué esperas que haga `MPI_Bcast` por dentro, y por qué crees que **todos** los
procesos (no solo el 0) tienen que llamarla?

<details><summary>Respuestas</summary>
a) A: 7 envíos en serie desde el rango 0 ≈ 7 × 0.46 ≈ 3.2 ms para el último. B: 3 pasos ≈ 3 × 0.46 ≈ 1.4 ms
(log₂ 8 = 3). Con más procesos la diferencia crece: p − 1 contra log₂ p.<br>
b) Siete mensajes en ambos casos. La ganancia viene de que en B varios envíos ocurren <strong>al mismo
tiempo</strong> desde distintos emisores; en A el rango 0 es el cuello de botella.<br>
c) Algo parecido a B (un árbol), elegido por la implementación. Todos la llaman porque cada proceso tiene
que recibir (y a veces reenviar) su parte: la llamada describe la operación completa, no solo el papel del
emisor. Mañana se confirma; apunta tu predicción para compararla.
</details>
