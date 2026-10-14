> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S03 · martes 10 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# S03 · Exit ticket (5 minutos, individual)

Escribe tu número de lista (no tu nombre). Media hoja. Se entrega al salir; cuenta como participación y
decide cómo empieza la sesión del jueves 12 de noviembre.

## Pregunta 1 (conceptual; elige una opción)

Hoy viste `matvec_bcast_buggy`, que tiene `MPI_Bcast` dentro de `if (rank == 0)`. Con `x` de 8 `double`
terminó y dio `y[2..7] = 0.0`; con `x` de 1 024 `double` se colgó. ¿Qué afirmación es correcta?

- **A.** Con 8 elementos funcionó porque `x` es chico; el error aparece solo con tamaños grandes.
- **B.** El programa es incorrecto en los dos casos: una colectiva la llaman todos los procesos del
  comunicador. Con el mensaje chico Open MPI lo copió a un búfer y el rango 0 salió de `Bcast` (resultado
  incorrecto); con el grande esperó a receptores que nunca llamaron (cuelgue).
- **C.** Los rangos 1–3 deberían haber visto `x` porque corren en la misma máquina; el error está en Open MPI.
- **D.** MPI debió abortar con un mensaje de error; que no lo hiciera es un defecto de la instalación.

## Pregunta 2 (aplicación corta; una línea de código)

Cada rango tiene `double local_max` con el máximo de **su** bloque. Escribe la **única** llamada MPI necesaria
para que **todos** los rangos terminen con el máximo global en `double global_max`.

```c
double local_max = ..., global_max;
/* tu línea aquí */
```

## Pregunta 3 (confianza)

¿Qué tan seguro estás de tus respuestas? (1 = adivinando, 4 = podría explicárselo a alguien).
Opcional: ¿qué te quedó menos claro de hoy? (una frase)

## Punto de control (solo si tu equipo no pasó al frente)

Salida de `make test` de la Parte B de la Práctica 5 en tu equipo al minuto 78 (inicio del punto de control): ____ PASS, ____ FAIL, ____ SKIP.

---

<details>
<summary>Clave (para el profesor; se publica después de la sesión)</summary>

**Pregunta 1: B.** Clasificación en ≤ 20 s:
- *bien*: B.
- *parcial*: A (sabe que falló, pero cree que el tamaño es la causa y no el síntoma: idea errónea 17 mal
  transferida; no ha generalizado la regla).
- *mal*: C (idea errónea 16: memoria compartida) o D (cree que MPI valida las colectivas; variante de la idea
  18: no entendió que el rango 0 no tiene forma de saber que los demás no llamarán).

**Pregunta 2.** Clave literal:

```c
MPI_Allreduce(&local_max, &global_max, 1, MPI_DOUBLE, MPI_MAX, MPI_COMM_WORLD);
```

- *bien*: `MPI_Allreduce` con `MPI_MAX`, `MPI_DOUBLE`, cuenta 1, sin `root`, fuera de cualquier `if`. Se acepta
  `MPI_IN_PLACE` como primer argumento si `global_max` se inicializa con `local_max`.
- *parcial*: `MPI_Reduce(..., MPI_MAX, 0, ...)` (solo el rango 0 la tendría; confunde `Reduce`/`Allreduce`), o
  `Allreduce` con `MPI_SUM`, o con un argumento `root` de más (no compila, pero la idea es la correcta).
- *mal*: `MPI_Bcast`, `MPI_Gather`, `MPI_Send`, o cualquier llamada dentro de `if (rank == 0)` (idea 18).

**Pregunta 3.** Registrar la distribución de confianza junto con el montón de la pregunta 1: quien está en *mal*
con confianza 4 es prioridad en la recuperación de S04.

**Umbral de alerta.** Más de 30 % en *mal* en la pregunta 1 → S04 (jueves 12 de noviembre) abre con la regla
"colectiva = la llaman todos" en el pizarrón antes del ejemplo resuelto (su plan ya lo prevé) y el ConcepTest 3 de
hoy se usa como recuperación en S05.

</details>
