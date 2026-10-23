> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S12 · martes 27 de octubre de 2026 · 08:30–10:00 · Lab LS4

# Recuperación de inicio · S12

Individual, por escrito, sin apuntes ni dispositivos. Cuatro minutos. Cada respuesta es una línea o una letra.
Después se muestran las respuestas y se cuenta a mano alzada quién acertó cada una. En la pregunta 5, "no sé"
es una respuesta válida y no cuenta en contra.

**1. (S11, *stencil*)** En un Jacobi 1D con `parallel for`, cada punto nuevo se calcula con sus vecinos. ¿Por qué
se escribe en un arreglo `u_new` distinto de `u_old`? (una línea)

**2. (S11, SIMD)** Elige: `#pragma omp simd` reparte las iteraciones entre…
A) varios hilos del equipo · B) los carriles vectoriales de **un** núcleo · C) varios procesos · D) la GPU

**3. (Unidad II, método de Foster)** Elige: *aglomerar* significa…
A) juntar todas las tareas en un solo hilo o proceso · B) agrupar tareas finas en tareas más grandes para
reducir comunicación y sobrecarga sin perder paralelismo útil · C) asignar cada tarea a un núcleo · D) dividir
los datos en pedazos iguales

**4. (Práctica 4, Parte D)** Completa con un número o una palabra: repeticiones mínimas ____ ; estadístico que se
reporta ________ ; nivel de optimización ____ ; T(1) es el mejor programa ____________.

**5. (Conjetura sobre el tema de hoy; Unidad I, Amdahl)** Un programa tarda 10 s: 2 s leyendo datos, 7 s en un
ciclo y 1 s escribiendo resultados. Si el ciclo se paraleliza perfecto con 4 hilos, ¿cuánto crees que tarde el
programa completo? ____ s

<details>
<summary>Respuestas</summary>

1. Porque si se actualiza en el lugar, la iteración `i` leería `u[i−1]` ya actualizado (por otra iteración u otro
   hilo): dependencia entre iteraciones y resultado distinto al secuencial. Con dos arreglos cada iteración solo
   escribe `u_new[i]` y las iteraciones son independientes; al final se intercambian los apuntadores.
2. **B.** `simd` vectoriza dentro de un hilo (una instrucción, varios datos); `parallel for` reparte entre hilos.
   Se combinan: `parallel for simd`.
3. **B.** A es la idea errónea 28 del Anexo A; C es el mapeo; D es la partición.
4. **5** repeticiones (más 1 de calentamiento que no cuenta); **mediana** (y se anotan mín y máx); **`-O2`**
   (nunca `-O0` ni con *sanitizers*); el mejor programa **secuencial** (no la versión paralela con un hilo, salvo
   que se declare).
5. **4.75 s**: 2 + 7/4 + 1. La fracción paralelizable es 0.7 (en tiempo); S(4) = 10/4.75 ≈ 2.1 y aunque el ciclo
   tardara cero, 3 s siguen ahí (S máximo ≈ 3.3). Es el tema del taller de hoy.

</details>

**Para el profesor.** Si en S11 alguna pregunta de su sesión quedó bajo 60 %, se repite aquí con pista en lugar
de la 1 o la 2 (`07-guia-de-autoria.md`, §A.8). Si menos del 60 % acierta la 4, en la demostración (5–12) se
recorre la tabla del protocolo renglón por renglón. Si menos del 60 % acierta la 5, el cálculo de Amdahl del
ejemplo se hace en el pizarrón antes de votar CT1 (bloque 60–65).
