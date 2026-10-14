> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S09 · martes 20 de octubre de 2026 · 08:30–10:00 · Lab LS4

# S09 · Exit ticket (5 minutos, individual)

Escribe tu número de lista y entrega la hoja al salir, junto con la de la recuperación. Cuenta por
participación; el profesor lo revisa hoy y abre la sesión del jueves 22 de octubre con el error más frecuente.
Si no pudiste mostrar tu medición en el punto de control, anota aquí mismo la línea `resumen:` de tu
`mergesort_tasks` con 4 hilos (n, cutoff, t_seq, t_tareas, speedup).

**1. (Conceptual)** Este fragmento corre con 4 hilos; `s1`, `s2` y `total` están declaradas antes de la región.
Un compañero dice que en su laptop `total` salió bien 5 de 5 veces, así que "está correcto".

```c
#pragma omp parallel
#pragma omp single
{
    #pragma omp task shared(s1)
    s1 = sum_range(a, 0, n / 2);
    #pragma omp task shared(s2)
    s2 = sum_range(a, n / 2, n);
    total = s1 + s2;                 /* línea X */
}
```

Elige **una**:

- **A)** Está correcto: una tarea se ejecuta en el momento en que se crea, así que al llegar a la línea X ya
  terminaron las dos.
- **B)** Falta `#pragma omp taskwait` antes de la línea X: `task` encola la tarea y el hilo sigue de largo;
  que saliera bien 5 veces no prueba nada.
- **C)** Falta `shared(total)` en las dos tareas; por eso a veces podría salir mal.
- **D)** Está correcto porque la barrera implícita al final del `single` espera a todas las tareas.

**2. (Aplicación corta)**

a) En `mergesort_tasks` (cada llamada con más de `cutoff` elementos crea dos tareas, una por mitad), con
`n = 32` y `cutoff = 4`: ¿cuántas tareas se crean en total? ¿Cambia ese número si se corre con 2 hilos en vez
de 4? (un número y sí/no)

b) Completa la cláusula que falta para que el padre pueda leer el resultado de la hija:

```c
long x;
#pragma omp task ________
x = fib(n - 1);
#pragma omp taskwait
```

**3. (Confianza)** ¿Qué tan seguro estás de tus respuestas? 1 = adivinando · 2 = poco · 3 = bastante ·
4 = podría explicárselo a alguien. ¿Qué te quedó **menos** claro hoy? (una línea, opcional)

<details><summary>Clave</summary>

1. **B.** `task` encola; nada garantiza que las tareas hayan empezado, y menos terminado, cuando el hilo del
   `single` ejecuta la línea X. En la máquina de autoría `taskwait_buggy.c` imprime 0 en esa lectura en todas
   las corridas; "salió bien 5 veces" solo dice que en esa laptop las tareas fueron rápidas o el hilo lento
   (idea errónea 7). Distractores: A es la idea errónea 13; C es irrelevante (`total` está declarada afuera:
   es compartida en la región y en las tareas; la falta de `shared` sería problema si fuera local de una
   función, como en `fib_buggy.c`); D ubica mal la barrera: existe, pero **después** de la línea X, por eso
   la segunda lectura de `taskwait_buggy.c` sí sale bien.
2. a) **14** tareas: 32 → 2 tareas de 16; 16 → 4 de 8; 8 → 8 de 4; 4 ≤ cutoff, ya no se crean. 2 + 4 + 8 = 14
   (= 2·(32/4 − 1)). **No** cambia con 2 hilos: el número de tareas lo fija la recursión y el corte, no el
   número de hilos (los hilos deciden quién las ejecuta, no cuántas hay). b) **`shared(x)`**. Sin ella `x`,
   que es local de la función, entra a la tarea como `firstprivate` y la hija escribe en una copia; el padre
   leería su `x` sin inicializar. (`taskwait` es necesario pero ya está; la cláusula que falta es la de datos.)
3. Sin clave. Para el profesor: comparar la confianza 4 con errores en 2a (el "cambia con los hilos") y 2b:
   es el dato de calibración de la sesión.
</details>

**Clasificación rápida (profesor, 10 min después de clase).** Bien: 1 = B **y** 2a = 14 / no **y** 2b =
`shared(x)`. Parcial: 1 = B y falla una de 2a/2b, o 1 ≠ B con 2a y 2b correctas. Mal: 1 ≠ B y además falla 2a o
2b. Si "mal" supera 30 %, la recuperación del jueves 22 de octubre abre con CT3 de `conceptests.md` (taskwait y
las nietas) y la pregunta 2b se repite con pista ("¿es `x` compartida donde se crea la tarea?"). Anotar aparte
cuántos contestaron "sí cambia con 2 hilos" en 2a: es la confusión tareas = hilos, que reaparece en la Parte B
de la Práctica 4.
