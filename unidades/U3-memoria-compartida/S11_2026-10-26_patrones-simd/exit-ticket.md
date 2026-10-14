> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S11 · lunes 26 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S11 · Exit ticket (5 minutos, individual)

Escribe tu número de lista en la hoja. Se revisa hoy mismo y mañana martes 27 de octubre, 08:30, la
sesión abre con el error más frecuente. Cuenta por participación (3 % del parcial), no por acierto.

## Pregunta 1 (conceptual)

Tu compañero dice: "Mi Jacobi paralelo da **exactamente** el mismo resultado que el secuencial con 1, 2 y 4
hilos. Entonces cualquier `reduction` de OpenMP da exactamente lo mismo que la versión secuencial."
¿Qué parte de la afirmación es cierta y cuál no? Justifica en 2–3 líneas.

## Pregunta 2 (aplicación corta)

El compilador reporta `missed: couldn't vectorize loop` para este ciclo:

```c
for (long i = 1; i < n; i++)
    a[i] = 0.5 * a[i - 1] + b[i];
```

(a) ¿Cuál es la razón, en una línea? (b) Si le pones `#pragma omp simd`, ¿se arregla, no cambia nada, o se
rompe? ¿Por qué?

## Confianza

¿Qué tan seguro estás de tus dos respuestas? (1 = adiviné · 2 = dudo · 3 = casi seguro · 4 = seguro)
¿Qué te quedó **menos** claro de hoy? (una frase)

<details><summary>Clave (para después de entregar)</summary>

**P1.** Lo cierto: en su Jacobi la combinación es `reduction(max:…)` y el máximo no depende del orden en que
se compare, así que el resultado es idéntico; además cada punto se calcula con la misma aritmética sin
importar qué hilo lo haga. Lo falso: la generalización. Con `reduction(+:…)` sobre `float`/`double` el orden
de las sumas cambia con el número de hilos y el redondeo también; el resultado difiere en los últimos
dígitos (lo viste en el *scan*: max|dif| = 2.873e-07 con 4 hilos, 6.850e-14 relativo). Por eso las pruebas comparan con
tolerancia. Con enteros (histograma) la suma sí es exacta. (Ataca la idea errónea 10 del Anexo A.)

**P2.** (a) Dependencia acarreada por el ciclo: la iteración `i` lee `a[i−1]`, que escribió la iteración
`i−1` (distancia 1). (b) **Se rompe.** `#pragma omp simd` no es una petición, es una promesa del programador de
que las iteraciones son independientes; el compilador la cree, calcula varias iteraciones a la vez con el
valor viejo de `a[i−1]` y el resultado queda mal sin ningún aviso. Para paralelizar o vectorizar un ciclo así
hay que cambiar el algoritmo (como el *scan* en dos fases), no la directiva.

**Clasificación rápida.** Bien: P1 distingue max/enteros de sumas flotantes y P2 dice "se rompe" con la
razón. Parcial: P1 correcta pero P2 dice "no cambia nada". Mal: P1 acepta la generalización o P2 dice
"se arregla".
</details>
