> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S02 · lunes 9 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S02 · Recuperación de inicio (5 minutos, individual, sin apuntes ni dispositivos)

Responde por escrito en tu cuaderno. A los 4 minutos se muestran las respuestas; levanta la mano por cada
pregunta que hayas acertado. No se califica por acierto: cuenta como participación.

## Preguntas

**1. (S01, jueves 5 de noviembre)** Un programa MPI tiene esta línea fuera de cualquier `if`:
`printf("hola desde %d de %d\n", rank, size);`. Se ejecuta con `mpirun -np 4 ./hola`.
¿Cuántas líneas se imprimen y qué valores toma `size`? ¿Está garantizado el orden en que aparecen?

**2. (S01)** En el mismo programa, cada proceso declara `int counter = 0;` y el rango 2 ejecuta `counter = 99;`.
Justo después, ¿cuánto vale `counter` en el rango 3? ¿Por qué?

**3. (Unidad I)** Un programa tarda 8.0 s en secuencial y 2.5 s con 4 procesos. Calcula el *speedup* y la
eficiencia. Si solo pudieras mejorar una cosa para subir la eficiencia, ¿qué te dice Amdahl que mires primero?

**4. (Unidad II)** En el método de Foster, ¿en cuál de las cuatro etapas se decide qué datos tiene que
recibir cada tarea de otras tareas? ¿Y en cuál se agrupan tareas para que esos intercambios sean menos?

**5. (Anticipa el tema de hoy)** Los rangos 0 y 1 ejecutan exactamente este código, cada uno con `partner`
igual al otro:

```c
MPI_Send(out, n, MPI_INT, partner, 0, MPI_COMM_WORLD);
MPI_Recv(in,  n, MPI_INT, partner, 0, MPI_COMM_WORLD, &status);
```

Escribe tu apuesta: ¿termina siempre, nunca, o depende de algo? ¿De qué?

## Respuestas

<details>
<summary>Mostrar respuestas</summary>

**1.** Se imprimen 4 líneas (una por proceso: modelo SPMD, el mismo programa corre en los 4). `size` vale 4
en todas; `rank` toma 0, 1, 2 y 3. El orden **no** está garantizado: cada proceso escribe por su cuenta y
`mpirun` mezcla las salidas.

**2.** Sigue valiendo 0. Cada proceso tiene su propio espacio de direcciones; `counter` del rango 2 y
`counter` del rango 3 son variables distintas en memorias distintas. Para que el rango 3 se entere hay que
enviarle un mensaje (tema de hoy). (Idea errónea 16 del Anexo A.)

**3.** *Speedup* S = 8.0 / 2.5 = 3.2. Eficiencia E = 3.2 / 4 = 0.80 (80 %). Amdahl: mide primero la fracción
del **tiempo** secuencial que no se paraleliza (no las líneas de código); esa fracción acota el *speedup*
sin importar cuántos procesos agregues.

**4.** La **comunicación** (segunda etapa) decide qué datos fluyen entre tareas. La **aglomeración**
(tercera) agrupa tareas para reducir el número y el volumen de esos intercambios sin perder paralelismo
útil. (El mapeo asigna las tareas aglomeradas a procesos.)

**5.** Depende. Depende del tamaño del mensaje y de si la implementación de MPI copia el mensaje a un
búfer interno. Con `n` pequeño suele terminar; con `n` grande suele colgarse. Hoy se demuestra con un
programa real y se ve cómo escribirlo para que termine **siempre**.

</details>

## Para el profesor

- Umbral de alerta: si menos del 60 % acierta la pregunta 2, dedicar 2 minutos extra en "Objetivos y
  anclaje" a dibujar en el pizarrón dos procesos con dos copias de `counter`, antes de hablar de mensajes.
- La pregunta 5 no se "corrige" aquí: se recoge la distribución de apuestas (siempre / nunca / depende) a
  mano alzada y se retoma en el minuto 20, cuando el programa se cuelga en vivo.
