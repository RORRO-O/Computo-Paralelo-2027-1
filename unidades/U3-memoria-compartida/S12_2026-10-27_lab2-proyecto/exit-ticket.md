> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S12 · martes 27 de octubre de 2026 · 08:30–10:00 · Lab LS4

# Exit ticket · S12

Individual, en papel, cinco minutos. Se entrega al salir. Cuenta como participación (3 % del 2.º parcial:
proporción de sesiones con *exit ticket* entregado), no por acierto. Quien faltó lo sustituye entregando la
`tarea-espaciada.md` de hoy antes del jueves 29 de octubre.

**1. (Conceptual, elige una)** Un equipo escribe en su plan: "El ciclo principal es el 80 % del código, así que
con 4 hilos esperamos un *speedup* cercano a 3.3". ¿Qué les falta para que esa predicción valga?

- A) Nada: 1 / (0.2 + 0.8/4) = 3.3 y el cálculo está bien hecho.
- B) El tiempo de cada sección en la versión secuencial (mediana de 5 corridas con `-O2`), para calcular la
  fracción con tiempos.
- C) Contar las líneas con exactitud (`wc -l`) en lugar de estimar el 80 % a ojo.
- D) Repetir la medición con `-O0`, porque con `-O2` el compilador esconde el tiempo real del ciclo.

**2. (Aplicación corta)** Perfil de una V1 (mediana de 5 corridas, `-O2`): lectura 0.4 s, construcción de la
estructura 0.6 s, ciclo principal 3.0 s, escritura 0.2 s. Dentro del ciclo cada iteración ejecuta
`acum += f(i);` y `out[i] = g(i);`. Si solo se paraleliza el ciclo:

- a) f = ______ (dos decimales) · S_max(4) = ______ (un decimal)
- b) Escribe la línea `#pragma` completa para ese ciclo: `#pragma omp ______________________________`

**3. (Confianza)** ¿Qué tan seguro estás de tus respuestas? (1 = nada, 4 = mucho).
Opcional: ¿qué te quedó menos claro de la sesión de hoy (laboratorio o taller)?

<details>
<summary>Clave</summary>

1. **B.** La fracción de Amdahl se mide en **tiempo** de la versión secuencial, no en líneas (idea errónea 2);
   el dato que falta es el perfil por secciones. A y C son la idea errónea 2 (líneas en vez de tiempo; C con
   más precisión en el dato equivocado); D es la idea errónea 5 (`-O0` no es un programa que alguien use y
   no estabiliza nada).

2. a) Total = 4.2 s; **f = 3.0 / 4.2 = 0.71**; S_max(4) = 1 / (0.29 + 0.71/4) = 1 / 0.464 ≈ **2.2** (se acepta
   2.1–2.2). Clasificación: bien = f y S_max correctas; parcial = f correcta y S_max mal (o S_max de la fase,
   4.0, en vez del total); mal = f calculada con otra cosa que no sea 3.0/4.2.
   b) **`#pragma omp parallel for reduction(+:acum)`**. `acum += f(i)` es una reducción (todas las iteraciones
   escriben la misma variable con `+`); `out[i] = g(i)` es independiente (cada iteración escribe su índice) y no
   necesita cláusula. Bien = aparece `reduction(+:acum)`; parcial = `parallel for` con `critical`/`atomic` sobre
   `acum` (correcto pero caro) o `private(out)` (incorrecto pero muestra que buscó la dependencia); mal = sin
   nada sobre `acum`.

3. Sin clave. Los tickets se clasifican en bien / parcial / mal por la pregunta 1; la 2 se lee en el montón
   "mal" y en 5 al azar. El error más frecuente abre la sesión S13 (jueves 29 de octubre).

</details>
