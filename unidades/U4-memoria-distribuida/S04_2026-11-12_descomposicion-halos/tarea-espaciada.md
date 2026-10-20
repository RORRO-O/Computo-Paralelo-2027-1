> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S04 · jueves 12 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S04 · Tarea espaciada (20–40 min)

**Entrega.** Individual, en el repositorio del equipo: `tareas/<usuario-github>/U4-S04.md` (tus respuestas) y el código del
ejercicio 1 en `tareas/<usuario-github>/U4-S04/`, antes del **martes 17 de noviembre de 2026, 08:30** (inicio de S05, Lab 2 de
la Práctica 5). El lunes 16 de noviembre no hay clase. Si faltaste hoy, entregarla en esa misma fecha sustituye tu recuperación
y tu *exit ticket* de S04 (`docs/metodo/04-evaluacion.md` §5).

**Qué cuenta.** Esta tarea no tiene peso propio; el examen de práctica del jueves 3 de diciembre y el 10–20 % acumulativo del
Examen 3 toman ítems de aquí. Ponderaciones del 3er parcial en `planeacion/mapa-evaluacion.md`: Examen 3 30 %, P5 15 %, P6 15 %,
proyecto 40 %. La autocalificas con la clave en los minutos 5–10 de S05 (2 min); el profesor registra la entrega, no el
acierto, y revisa 3 al azar por parcial. El ejercicio 3 es tu predicción obligatoria para la Parte D de la Práctica 5 (15 % del
parcial), que se mide ese día.

## 1. Del tema (15 min) · Fuente de calor en el centro

Termina la opción A de la fase Crear de la práctica guiada: fronteras en 0, celda global `src = (n + 1) / 2` fija en 100, en
`jacobi1d_seq.c` y `jacobi1d_mpi.c` (usa una bandera `--source` o una constante nueva; los valores por defecto no cambian y
`make test` sigue pasando).

Verificación: `./jacobi1d_seq 15 1e-3 100000 --source` debe dar `iteraciones=117` y `checksum=7.999401682787e+02`; con
`mpirun -np 4 ./jacobi1d_mpi 15 1e-3 100000 --source` exactamente lo mismo (verificado con la solución del profesor con 3 y 4
procesos). Descomenta la línea `run_case "fuente n=15 p=4 ..."` de `tests/run_tests.sh`: debe salir `PASS`.

En `U4-S04.md`: (a) ¿en qué rango cae la fuente con `n = 15, p = 4` y qué índice local tiene? (b) Un compañero fijó la celda
`local_n / 2` en cada rango: ¿cuántas fuentes tiene su programa con `p = 4`? ¿Cómo lo delata la salida sin leer su código?

<details><summary>Respuestas</summary>
Código: la secuencial fija `u[src] = u_new[src] = 100` con `src = (n + 1) / 2` y salta esa celda en el ciclo (`if (i == src) continue;`);
la MPI convierte `src_local = src - offset` y la fija solo si `1 <= src_local <= local_n`, en ambos arreglos.
(a) Con `n = 15, p = 4` el reparto es 4, 4, 4, 3 (`offset` = 0, 4, 8, 12). La fuente `src = 8` cae en el rango 1 (celdas 5–8), índice local
`8 − 4 = 4`. (b) Cuatro fuentes, una por rango (globales 2, 6, 10 y 13). Lo delata `--print`: cuatro celdas exactamente en 100 en vez de
una, perfil con cuatro picos, `checksum` mucho mayor que 799.94 y otro número de iteraciones; `make test` con el caso `--source` da FAIL.
</details>

## 2. Intercalado (Unidades I y III, 10 min) · Leer un speedup

Un equipo midió su Jacobi 1D con OpenMP (Práctica 4) con `n = 2·10^7`, 500 iteraciones, mediana de 5 corridas:

| Hilos | T (s) |
|---|---|
| 1 (secuencial) | 4.00 |
| 2 | 2.10 |
| 4 | 1.25 |
| 8 (4 núcleos físicos, HT) | 1.20 |

(a) Calcula *speedup* y eficiencia para 2, 4 y 8 hilos.
(b) Calcula la fracción secuencial de Karp–Flatt `f = (1/S − 1/p) / (1 − 1/p)` para 2 y 4 hilos. ¿Crece? ¿Qué indica?
(c) ¿La fila de 8 hilos es evidencia a favor o en contra de "más hilos siempre es más rápido"? ¿Qué parte del protocolo de
medición obliga a reportar esa fila aparte?
(d) Según Amdahl, con la `f` que obtuviste para 4 hilos, ¿qué *speedup* máximo tendrías con infinitos núcleos?

<details><summary>Respuestas</summary>
(a) S(2)=4.00/2.10=1.905, E=0.95; S(4)=4.00/1.25=3.20, E=0.80; S(8)=4.00/1.20=3.33, E=0.42.
(b) f(2) = (1/1.905 − 1/2)/(1 − 1/2) = (0.525 − 0.5)/0.5 ≈ 0.050; f(4) = (1/3.20 − 1/4)/(1 − 1/4) = (0.3125 − 0.25)/0.75 ≈ 0.083.
Crece: hay sobrecarga que aumenta con los hilos (sincronización al final de cada iteración, ancho de banda de memoria), no solo
una fracción secuencial fija.
(c) En contra (idea errónea 1): 8 hilos sobre 4 núcleos físicos casi no mejoran. El protocolo pide medir hasta el número de núcleos
físicos "y uno más allá, declarado": *hyper-threading* y sobre-suscripción se reportan aparte.
(d) 1/f ≈ 1/0.083 ≈ 12.
</details>

## 3. Preparación de S05 (10 min) · Predicción del costo de comunicación

Lee `herramientas/protocolo-medicion.md` §2 y §3. Con tus valores del *ping-pong* de S02 (latencia α en µs y ancho de banda β en
MB/s de **tu** máquina; si no los tienes, usa α = 2 µs, β = 2000 MB/s), estima para Jacobi 1D con `p = 4`:

| `n` | `local_n` | Tiempo de cómputo por iteración (supón 1 ns por celda) | Comunicación por iteración (2 mensajes de 8 B + 1 `Allreduce` ≈ 3 mensajes de latencia α) | ¿Qué domina? |
|---|---|---|---|---|
| 1 000 | | | | |
| 1 000 000 | | | | |

Escribe tu predicción para la Parte D de la Práctica 5: "Con `n = 10^6` y 4 procesos espero un *speedup* de ___ porque ___".
Se compara con la medición del martes 17 de noviembre. Va en tu `U4-S04.md`.

<details><summary>Orientación</summary>
`n = 1000`: `local_n = 250` → 0.25 µs de cómputo contra ~6 µs de comunicación: la comunicación domina 20 a 1; el *speedup* será
menor que 1. `n = 10^6`: 250 µs contra ~6 µs: el cómputo domina; el límite estará en el ancho de banda de memoria, no en MPI.
La predicción "razonable" para `n = 10^6` está entre 2.5 y 3.5 con 4 núcleos físicos sin sobre-suscripción.
</details>
