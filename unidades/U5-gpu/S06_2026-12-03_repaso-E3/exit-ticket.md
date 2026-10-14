> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S06 · jueves 3 de diciembre de 2026 · 10:30–12:00 · Salón 3208

# Exit ticket · S06

Cinco minutos, individual, en la misma hoja de la recuperación (lado B). Se entrega al salir. Cuenta la entrega, no
el acierto. El profesor la revisa hoy mismo: la pregunta 1 dice si la regla "sin error ≠ correcto" quedó; la
pregunta 2 es tu plan de estudio para el Examen 3 (martes 8 de diciembre, 08:30) y se te devuelve el lunes 7.

**1. (Conceptual · opción múltiple).** Hoy viste tres programas que "pasaron una prueba": (i) `caza1` con `-np 1`
imprimió la media correcta; (ii) `caza2` sin guardia con `n = 1024` dio `verificacion=OK`; (iii) `caza3` sin barrera
dio `suma_gpu=5500.0` en una corrida. ¿Cuántos de los tres programas son correctos?

- **A.** Los tres: cada uno pasó su prueba sin ningún mensaje de error.
- **B.** Solo (ii): con `n` múltiplo del bloque no sobran hilos, así que la guardia no hace falta.
- **C.** Ninguno: cada prueba se hizo justo en la condición que enmascara el error (sin procesos que esperar, sin
  hilos sobrantes, una corrida afortunada).
- **D.** (i) y (iii): un programa MPI con un proceso no puede colgarse, y una reducción que da el valor exacto es correcta.

**2. (Aplicación · tu plan).** Con tu examen de práctica corregido enfrente, escribe tres datos:
(a) la **sección** (I–VI) o el **ítem** donde perdiste más puntos y la idea errónea que lo explica (número o frase);
(b) el **archivo exacto** del repositorio del curso que vas a releer o correr para ese tema (ruta, por ejemplo
`unidades/U4-memoria-distribuida/S03_2026-11-10_colectivas-lab1/notas-estudiante.md` o
`unidades/U5-gpu/S06_2026-12-03_repaso-E3/practica-guiada/` con `make cazar`);
(c) **cuándo**: día y hora de hoy o mañana (viernes 4 de diciembre) en que lo vas a hacer, y cuántos minutos.

**3. (Confianza y calibración).** ¿Qué tan seguro estás de tu respuesta a la pregunta 1? (1 = nada · 4 = podría
explicarla a un compañero). Escribe tu **predicción de calificación del Examen 3** (0–100). ¿Qué te quedó menos
claro hoy? (una frase, opcional)

<details><summary>Clave</summary>

**1. C.** Las tres pruebas se hicieron en la condición que oculta el error: con un proceso nadie espera el
<code>MPI_Bcast</code> que falta (idea 18); con <code>n = 1024</code> no sobra ningún hilo (idea 34); una corrida
que coincide con la referencia no descarta una carrera (ideas 7 y 27). Origen de los distractores: A → 27 ("sin
error = correcto"); B → 34 ("no hace falta comprobar <code>idx &lt; n</code>"); D → 18 + 7.

**2.** No tiene respuesta única. Clave literal para clasificar: <em>bien</em> = (a) una sección o ítem concreto
<strong>con</strong> la idea errónea, (b) una ruta que existe en el repositorio, (c) día, hora y minutos; <em>parcial</em>
= dos de los tres datos concretos; <em>mal</em> = plan genérico ("repasar todo", "leer las notas", sin archivo ni
hora). Un plan de "bien" cabe en tres renglones.

**3.** Se registra la confianza y la predicción del Examen 3 en la hoja de calibración del grupo
(<code>herramientas/seguimiento-grupo.md</code>); se compara con la calificación real el lunes 14 de diciembre.

**Clasificación rápida.** <em>Bien</em>: 1 = C y plan "bien". <em>Parcial</em>: 1 = C con plan parcial, o 1 ≠ C con plan
"bien". <em>Mal</em>: 1 ≠ C y plan parcial o genérico. Si "mal" supera el 30 %, la recuperación del lunes 7 de
diciembre repite la pregunta 1 con pista y la retroalimentación del Examen 3 (lunes 14) abre con la tabla I4 de la
práctica guiada.
</details>
