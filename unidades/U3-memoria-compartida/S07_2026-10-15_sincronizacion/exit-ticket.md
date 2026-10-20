> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S07 · jueves 15 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S07 · Exit ticket (5 minutos, individual)

Escribe tu número de lista. Entrega la hoja al salir (o el formulario, si el profesor lo indica). Cuenta por
participación; el profesor lo revisa hoy y abre la sesión del lunes 19 de octubre con el error más frecuente.

**1. (Conceptual)** Un compañero te dice: "Corrí mi histograma paralelo tres veces y las tres dio igual que el
secuencial; no tiene condición de carrera". En dos o tres líneas: ¿qué le respondes y qué **dos** evidencias le
pedirías en su lugar?

**2. (Aplicación)** ¿Hay condición de carrera en este fragmento? Si la hay, escribe el pragma o la cláusula
**más barata** que conozcas que lo corrija y di en una línea por qué `#pragma omp atomic` no sirve aquí.

```c
double max_val = x[0];
#pragma omp parallel for
for (long i = 1; i < n; i++)
    if (x[i] > max_val) max_val = x[i];
```

**3. (Confianza)** ¿Qué tan seguro estás de tus dos respuestas? 1 = adivinando · 2 = poco · 3 = bastante ·
4 = podría explicárselo a alguien. ¿Qué te quedó **menos** claro hoy? (una línea)

<details><summary>Clave</summary>

1. "Salió bien" no es evidencia: una carrera es no determinista y puede no manifestarse con ese `n`, esos
   hilos o esa optimización (idea errónea 7). Evidencias que sí valen: (a) razonar sobre cada variable
   compartida que se escribe dentro de la región: quién la escribe, quién la lee y qué construcción ordena esos
   accesos; (b) ThreadSanitizer sobre la versión sin sincronizar (señala la línea). Como complemento: comparar
   contra la secuencial con `n` grande, más hilos y varias corridas (`make test`). Se acepta también "muéstrame
   el `hist[bin]++` y dime qué lo protege".
2. Sí hay carrera: todos los hilos leen y escriben `max_val` sin protección (leer-comparar-escribir). La
   corrección más barata es `#pragma omp parallel for reduction(max:max_val)`. También es correcto
   `#pragma omp critical` alrededor del `if` (más caro) o un candado. `atomic` no sirve porque solo cubre una
   actualización simple de una variable (`x++`, `x += e`, `x = x op e`); un `if` con lectura y escritura
   condicional no es una de esas formas (idea errónea 8). Nota: poner `atomic` solo en `max_val = x[i]` deja
   la carrera entre la comparación y la asignación.
3. Sin clave. Para el profesor: la brecha entre confianza 4 y respuestas incorrectas en la pregunta 2 es el
   dato de calibración de la sesión.

**Clasificación rápida (profesor, 10 min después de clase).** Bien: pregunta 1 menciona razonamiento sobre
accesos o ThreadSanitizer, y pregunta 2 da `reduction(max:…)` o `critical` con la razón de `atomic`. Parcial:
una de las dos. Mal: pregunta 1 acepta las tres corridas como evidencia, o pregunta 2 dice "no hay carrera" o
propone `atomic`. Si "mal" supera 30 %, la recuperación del lunes 19 de octubre abre con el `if`/`max`.

</details>
