> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S08 · lunes 19 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S08 · Recuperación de inicio (5 minutos, individual, sin apuntes)

Responde por escrito en tu cuaderno. A los 4 minutos se muestran las respuestas; cuenta tus aciertos.
Esta actividad no se califica por acierto, sino por participación (3 % del parcial: *exit tickets* y recuperación).

## Preguntas

**1. (S07, jueves 15 de octubre)** ¿Qué diferencia hay entre `#pragma omp atomic` y `#pragma omp critical`?
Da un caso donde `atomic` **no** sirve.

**2. (S07)** Dentro de una región `parallel`, ¿qué pasa al final de un `#pragma omp for` si no se escribe nada
más? ¿Con qué cláusula se cambia ese comportamiento y qué riesgo introduce?

**3. (Unidad I, Amdahl)** Un programa secuencial tarda 10 s; 1 s de ese tiempo no se puede paralelizar.
¿Cuál es el *speedup* máximo con 4 hilos? ¿Y con hilos ilimitados?

**4. (Unidad II, Foster)** ¿En cuál de las cuatro etapas de Foster se decide **qué tarea ejecuta qué
procesador**, y qué dos cosas busca equilibrar esa etapa?

**5. (Anticipa el tema de hoy)** Considera el ciclo
```c
for (int i = 0; i < n; i++)
    for (int j = 0; j < i; j++)
        trabajo(i, j);
```
Si las `n` iteraciones de `i` se reparten entre 4 hilos en **4 bloques contiguos** de igual tamaño,
¿qué hilo termina al último? Aproximadamente, ¿cuántas veces más trabajo hace que el hilo 0?

## Respuestas

<details>
<summary>Mostrar respuestas (después de los 4 minutos)</summary>

1. `atomic` protege **una sola operación simple** sobre **una variable** (`x += v`, `x++`, lectura o escritura)
   y suele compilarse a una instrucción atómica del procesador: barata. `critical` protege una **región
   arbitraria** de código con exclusión mutua: más cara, pero sirve para cualquier cosa. Caso donde `atomic` no
   sirve: actualizar dos variables que deben cambiar juntas (`total += v; cuenta++;`), insertar en una lista,
   llamar a `printf`. (Idea errónea 8 del Anexo A.)

2. Hay una **barrera implícita**: ningún hilo pasa de ahí hasta que todos terminaron sus iteraciones. Se quita
   con `nowait`. El riesgo: el siguiente bloque de código puede leer datos que otro hilo todavía no escribió
   (carrera de datos). Hoy veremos un caso donde `nowait` es seguro y otro donde no. (Idea errónea 12.)

3. Fracción secuencial f = 1/10 = 0.1. Con p = 4: S = 1 / (0.1 + 0.9/4) = 1 / 0.325 ≈ **3.08**.
   Con p → ∞: S → 1/f = **10**.

4. En el **mapeo** (partición → comunicación → aglomeración → mapeo). Busca equilibrar la **carga de
   trabajo** entre procesadores y minimizar la **comunicación** entre ellos. Hoy el "mapeo" lo hace la cláusula
   `schedule`: decide qué iteración ejecuta qué hilo.

5. La iteración `i` cuesta `i` unidades. El bloque k (k = 0..3) de n/4 iteraciones tiene un costo proporcional
   a (2k + 1): los bloques pesan 1, 3, 5 y 7 unidades relativas. El **hilo 3** termina al último y hace
   **~7 veces** el trabajo del hilo 0. Con esos 4 hilos el *speedup* no pasa de 16/7 ≈ 2.3 aunque el trabajo
   esté "repartido".

</details>

## Para el profesor

- Umbral de alerta: si menos del 60 % acierta la pregunta 2, reexplicar la barrera implícita antes del ejemplo
  resuelto (2 minutos, con el dibujo de los cuatro hilos llegando a la línea).
- La pregunta 5 es el puente: su respuesta es exactamente el mapa `static` que se mostrará a los 12 minutos.
