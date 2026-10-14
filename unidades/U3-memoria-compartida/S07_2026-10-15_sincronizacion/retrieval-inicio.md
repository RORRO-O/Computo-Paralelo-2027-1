> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S07 · jueves 15 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S07 · Recuperación de inicio (5 minutos, individual, sin apuntes ni dispositivos)

Escribe las respuestas en una hoja o en tu cuaderno. A los 4 minutos se muestran las respuestas; cuenta tus
aciertos. Esto no se califica por acierto: cuenta por participación (3 % del parcial, con los *exit tickets*).

**1. (Sesión del martes 13 de octubre)** En `#pragma omp parallel for reduction(+:s)`, ¿qué hace OpenMP con
`s` **durante** el ciclo y **al final**?

**2. (Sesiones del 8 al 12 de octubre)** Antes de la región, `t = 5`. Dentro de `#pragma omp parallel for
private(t)`, ¿qué vale `t` al entrar cada hilo? ¿Y si la cláusula fuera `firstprivate(t)`?

**3. (Unidad I)** Un programa tarda 10 s en serie; 2 s de ese tiempo no se pueden paralelizar. Según Amdahl,
¿cuál es el *speedup* máximo con 4 hilos? ¿Y con infinitos hilos?

**4. (Unidad II, método de Foster)** Quieres calcular el histograma de un arreglo grande en paralelo. ¿Cuál es la
partición natural (por dominio o funcional, y de qué)? ¿Qué comunicación aparece entre las tareas al final?

**5. (Tema de hoy)** Dos hilos ejecutan `c++` una vez cada uno sobre la misma variable compartida `c`, que vale
5. ¿Qué valores finales son posibles? Explica uno de ellos paso a paso.

<details><summary>Respuestas</summary>

1. Durante el ciclo cada hilo acumula en una **copia privada** de `s`, inicializada en 0 (la identidad de `+`).
   Al final de la región OpenMP **combina** las copias con `+` sobre la `s` original. El orden de combinación no
   está definido; en punto flotante el redondeo puede diferir del secuencial.
2. Con `private(t)`, `t` es una copia nueva **sin inicializar** en cada hilo (valor indefinido; no es 5 ni 0).
   Con `firstprivate(t)`, cada hilo recibe una copia inicializada con 5. En ambos casos la `t` de afuera sigue
   valiendo 5 al terminar.
3. Fracción secuencial `f = 2/10 = 0.2`. Con `p = 4`: `S = 1 / (0.2 + 0.8/4) = 1 / 0.4 = 2.5`. Con `p → ∞`:
   `S → 1/0.2 = 5`. Más hilos no ayudan más allá de eso (idea errónea 1).
4. Partición por **dominio**: cada tarea toma un bloque de elementos del arreglo y cuenta en su propio
   histograma parcial. Comunicación al final: **combinar** (reducir) los histogramas parciales en uno, bin a
   bin. Aglomeración: un bloque grande por hilo. Esa combinación final es exactamente lo que hoy se protege.
5. Posibles: **7** (si los accesos no se traslapan) y **6** (si se traslapan). Ejemplo de 6: hilo A lee 5; hilo B
   lee 5; A escribe 6; B escribe 6. Se perdió una actualización. Nunca sale 8 ni 5.
</details>

**Para el profesor.** Si menos del 60 % acierta la pregunta 1, dedicar 2 minutos del bloque siguiente a
redibujar `reduction` (copias privadas → combinación) antes de empezar el ejemplo resuelto: todo el tema de
hoy se apoya en esa imagen. La pregunta 2 anticipa la idea errónea 9; anotar cuántos contestaron "5" para
`private`: ese número decide si CT3 se usa hoy o se guarda para el lunes 19 de octubre.
