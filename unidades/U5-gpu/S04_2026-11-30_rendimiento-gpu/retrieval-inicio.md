> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S04 · lunes 30 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# Recuperación de inicio · S04

Individual, por escrito, sin apuntes ni dispositivos. Cuatro minutos. Después se muestran las respuestas y se
cuenta a mano alzada quién acertó cada una.

1. **(S03, jueves 26 de noviembre)** En la reducción en árbol dentro de un bloque hay un `__syncthreads()` en cada
   nivel. ¿Qué garantiza esa barrera y qué **no** sincroniza?

2. **(S03)** En el histograma, la primera versión hacía `atomicAdd` directo sobre los 256 contadores en memoria
   global desde todos los hilos. ¿Por qué era lenta y cuál fue el arreglo?

3. **(Unidad I)** Un programa tarda 20 s en su mejor versión secuencial y 5 s con 8 hilos. Calcula el *speedup*
   y la eficiencia.

4. **(Unidad IV, S05 del martes 17 de noviembre)** Con el modelo `T = latencia + tamaño / ancho_de_banda`:
   ¿cuánto tarda mover 64 MB si la latencia es 10 µs y el ancho de banda 4 GB/s? ¿Qué término domina?

5. **(Tema de hoy)** Un kernel tarda 1 ms. Copiar sus datos a la GPU y traer el resultado tarda 48 ms. La CPU
   hace el mismo cálculo en 20 ms. ¿Quién gana si los datos empiezan en la CPU? ¿Y si ya estaban en la GPU?

<details>
<summary>Respuestas</summary>

1. Garantiza que **todos los hilos del bloque** terminaron de escribir sus sumas parciales del nivel `s` antes
   de que cualquiera lea en el nivel `s/2`. No sincroniza hilos de **otros bloques** ni "toda la GPU"
   (idea errónea 25); entre bloques se sincroniza al terminar el kernel (o con una segunda pasada).

2. Miles de hilos hacían atómicas sobre las **mismas** 256 direcciones de memoria global: las operaciones se
   serializan y el tiempo crece con la contención. Arreglo: histograma parcial por bloque en memoria
   compartida (atómicas baratas y repartidas), y al final una sola `atomicAdd` por bin y por bloque a la global.

3. `S = 20 / 5 = 4`. `E = S / p = 4 / 8 = 0.5` (50 %). No son lo mismo (idea errónea 3).

4. `64 × 10^6 B / 4 × 10^9 B/s = 16 ms`, más 0.01 ms de latencia ≈ **16 ms**. Domina el término de tamaño /
   ancho de banda; la latencia solo importa para mensajes pequeños. (Si tomas 64 MiB = 67.1 MB, salen 16.8 ms;
   cualquiera de los dos vale.) Hoy ese mismo modelo describe las copias por PCIe.

5. Datos en la CPU: GPU = 1 + 48 = **49 ms contra 20 ms de la CPU: gana la CPU**. Datos ya en la GPU:
   1 ms contra 20 ms: **gana la GPU 20×**. El número honesto depende de dónde viven los datos; por eso el
   protocolo exige reportar con y sin copias (idea errónea 24).

</details>

**Para el profesor.** Si menos del 60 % acierta la pregunta 1, dedicar dos minutos a redibujar el árbol de
reducción en el pizarrón antes de los objetivos (hoy se vuelve a usar la idea de "qué sincroniza qué" al hablar
de eventos y `cudaDeviceSynchronize`). Si falla la 5, no corregir aún: es exactamente lo que el ejemplo resuelto
va a mostrar con números medidos.
