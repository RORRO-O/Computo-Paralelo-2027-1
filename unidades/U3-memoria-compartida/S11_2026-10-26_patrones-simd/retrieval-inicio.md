> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S11 · lunes 26 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S11 · Recuperación de inicio (5 minutos, individual, sin apuntes)

Responde por escrito en tu cuaderno. A los 4 minutos se proyectan las respuestas y se cuenta a mano alzada
cuántas acertaste. No cuenta para calificación por acierto, sí por participación (3 % del parcial).

## 1. (S10, 22 de octubre) *Speedup* y eficiencia

Mediste tu Parte B de la Práctica 4 con el protocolo del curso: mediana de 5 corridas, `-O2`. Obtuviste
T(1) = 8.0 s y T(4) = 2.5 s. ¿Cuánto valen el *speedup* y la eficiencia con 4 hilos? ¿Qué fracción secuencial
estima Karp–Flatt con esos datos?

<details><summary>Respuesta</summary>

S(4) = 8.0 / 2.5 = 3.2. E(4) = 3.2 / 4 = 0.80 (80 %). Karp–Flatt: f = (1/S − 1/p) / (1 − 1/p) =
(0.3125 − 0.25) / 0.75 ≈ 0.083, es decir, el programa se comporta como si ~8 % de su tiempo fuera
secuencial (incluye la sobrecarga de hilos, no solo el código fuera de la región paralela).
</details>

## 2. (S10) Dos hilos, dos contadores, un problema

Dos hilos incrementan millones de veces, cada uno, su propio elemento de `long cuenta[2]`: el hilo 0 hace
`cuenta[0]++` y el hilo 1 hace `cuenta[1]++`. No hay condición de carrera y aun así tarda más que con un solo
hilo. ¿Cómo se llama el fenómeno y cuáles son las dos formas de arreglarlo que viste?

<details><summary>Respuesta</summary>

Falso compartido (*false sharing*): `cuenta[0]` y `cuenta[1]` viven en la misma línea de caché (64 bytes), y
cada escritura de un hilo invalida la copia de la línea en el núcleo del otro. Arreglos: (a) acumular en una
variable local del hilo (registro o pila) y escribir al arreglo compartido una sola vez al final; (b) separar
los contadores con relleno (*padding*) para que cada uno ocupe su propia línea de caché. Hoy se usa (a) en
el histograma y lo hace por ti `reduction`.
</details>

## 3. (Unidad I) Amdahl y las líneas de código

Un compañero argumenta: "mi programa tiene 1 000 líneas y 900 están dentro del ciclo que paralelicé; por Amdahl
la fracción paralela es 0.9, así que con 4 hilos debo llegar a un *speedup* de 3.08". ¿Qué está mal en el
razonamiento?

<details><summary>Respuesta</summary>

La fracción de Amdahl se mide en **tiempo** de la versión secuencial, no en líneas. Diez líneas de
lectura de archivo pueden tardar más que 900 de cómputo, o al revés. Hay que perfilar (Unidad II) o medir
el tiempo de la parte que se paraleliza y el tiempo total; la fórmula 1 / (0.1 + 0.9/4) = 3.08 es correcta
solo si 0.9 es una fracción de tiempo.
</details>

## 4. (Unidad II, método de Foster) Vecinos en una barra

Una barra de `n` puntos se reparte en bloques contiguos entre `p` hilos (descomposición de dominio). Cada
punto se actualiza con el promedio de sus dos vecinos. En la etapa de **comunicación** de Foster, ¿qué datos
necesita el bloque del hilo `t` que no son suyos?

<details><summary>Respuesta</summary>

Solo dos valores: el último punto del bloque `t−1` y el primero del bloque `t+1` (los extremos del bloque los
necesitan). En memoria compartida esa "comunicación" es una lectura del arreglo compartido; en la Unidad IV,
con procesos MPI, serán mensajes explícitos (intercambio de halos). Cuanto más grande el bloque, menor es la
proporción comunicación/cómputo (aglomeración).
</details>

## 5. (Anticipa el tema de hoy) ¿Se puede repartir este ciclo?

```c
for (long i = 1; i < n; i++)
    y[i] = y[i - 1] + x[i];
```

¿Puedes ponerle `#pragma omp parallel for` tal cual? Responde sí o no y da la razón en una línea.

<details><summary>Respuesta</summary>

No. La iteración `i` lee `y[i−1]`, que escribe la iteración `i−1`: hay una dependencia acarreada por el ciclo
(*loop-carried dependence*). Si dos hilos ejecutan iteraciones consecutivas en paralelo, uno lee un valor que
el otro aún no escribió (carrera y resultado incorrecto). Hoy verás cómo sí se paraleliza: en dos fases, con
sumas por bloque y una corrección. El mismo tipo de dependencia impide que el compilador lo vectorice.
</details>

---

**Para el profesor.** Si menos del 60 % acierta la pregunta 1, se repite en el pizarrón el cálculo de S, E y
Karp–Flatt antes de seguir (2 minutos); la sesión de hoy mide Jacobi con 1, 2 y 4 hilos y vuelve a usarlos. Si
falla la 5, no se corrige todavía: es el gancho del ejemplo resuelto (minuto 10).
