> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S06 · jueves 19 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S06 · Recuperación de inicio (5 minutos, individual, sin apuntes ni dispositivos)

Escribe las respuestas en una hoja con tu número de lista (es la misma hoja del *exit ticket*). A los 4 minutos se
muestran las respuestas; cuenta tus aciertos. En el 3er parcial la recuperación no tiene peso propio: es la
preparación del Examen 3 (martes 8 de diciembre) y del examen de práctica (jueves 3 de diciembre). Zona sin IA.

**1. (S05, martes 17 de noviembre)** Escalabilidad fuerte y escalabilidad débil: ¿qué se mantiene **fijo** en
cada una y qué se **reporta** en cada una? (una línea para cada una)

**2. (S05)** Tu programa híbrido llama `MPI_Init_thread(&argc, &argv, MPI_THREAD_FUNNELED, &provided)`. ¿Qué
le está prometiendo tu programa a MPI con ese nivel? ¿Qué debes revisar justo después? (una línea)

**3. (Unidad I; U3·S10)** Un equipo mide `S(4) = 3.0` en su V2. ¿Cuál es su eficiencia con 4 hilos? Si en H1
estimaron una fracción secuencial de 0.05, ¿qué `S(4)` predecía Amdahl? (dos números)

**4. (U3·S07 y tarea de S05, ejercicio 2)** ¿Qué orden de magnitud te dio una barrera de OpenMP con 4 hilos
(nanosegundos, microsegundos o milisegundos)? ¿Y `2α`, el costo de los dos halos de 8 bytes en MPI? (una línea)

**5. (Tema de hoy; conjetura, "no sé" es válida)** Una matriz de `1000 × 1000` `double` está guardada por filas.
¿Cuántos mensajes crees que hacen falta para enviar una **columna** con los tipos básicos de MPI? ¿Y con
`MPI_Type_vector`?

<details><summary>Respuestas</summary>

1. **Fuerte:** `n` fijo, crece `p`; se reporta *speedup* `S = T_seq(n)/T(p, n)` y eficiencia `S/p` (marco de
   Amdahl). **Débil:** `n/p` fijo, crecen `p` y `n`; se reporta la eficiencia débil `T_seq(n/p)/T(p, n)` o el
   *speedup* escalado (marco de Gustafson). No son sinónimos (idea errónea 6) y van en tablas distintas, etiquetadas.
2. Que **solo el hilo principal** de cada proceso llamará a MPI (los demás hilos de OpenMP solo calculan). Justo
   después se revisa `provided >= MPI_THREAD_FUNNELED`: la biblioteca puede dar menos de lo pedido.
3. `E(4) = 3.0 / 4 = 0.75`. Amdahl con `f = 0.05`: `S(4) = 1 / (0.05 + 0.95/4) = 1 / 0.2875 ≈ 3.48`. Medir 3.0 en
   vez de 3.48 significa que hay sobrecarga que el perfil de H1 no vio; Karp–Flatt la cuantifica: `f(4) =
   (1/3 − 1/4)/(1 − 1/4) = 0.111`, más del doble de la estimada. Eficiencia y *speedup* no son lo mismo (idea 3).
4. Barrera de OpenMP con 4 hilos: **del orden de 1 µs** (en la máquina de autoría, 100 000 barreras vacías
   tardaron 0.07–0.11 s: 0.7–1.1 µs cada una, el mismo rango que la clave de la tarea de S05; con 2 hilos, 0.4–0.5 µs). `2α` con α entre 0.2 y 0.5 µs (S02):
   **0.4–1 µs**. Mismo orden de magnitud: "MPI dentro de un nodo siempre pierde contra OpenMP" no se sostiene con
   estos números; lo que pesa es cuántas veces por iteración se paga cada cosa.
5. Con tipos básicos: **1000 mensajes** de 1 `double` (uno por fila; cada uno paga la latencia α), o 1 mensaje
   después de **copiar** la columna a un arreglo auxiliar. Con `MPI_Type_vector(1000, 1, 1000, MPI_DOUBLE, …)`:
   **1 mensaje** y sin copia. Hoy lo ves funcionar en el ejemplo resuelto.
</details>

**Para el profesor.** Conteo de manos por pregunta; anotar el de las preguntas 1 y 2. Si la pregunta 1 queda
bajo 60 %, al arrancar el taller (minuto 30) se proyectan las dos definiciones junto al encabezado del CSV y se
repite el ítem con pista en la recuperación del lunes 23 de noviembre. La pregunta 3 anticipa la tabla de
Karp–Flatt de H2 §2.3: quien no obtiene 0.75 y ≈ 3.5 necesita la fila "Apoyo" del plan en el taller. La
pregunta 4 verifica la tarea de S05 (ejercicio 2): basta el orden de magnitud. La 5 no cuenta.
