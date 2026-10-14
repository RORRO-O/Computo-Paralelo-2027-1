> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S01 · lunes 23 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# Recuperación de inicio · S01

Cuatro minutos, individual, sin apuntes ni dispositivos. Escribe en tu cuaderno o en la hoja de *exit ticket* (lado
A). Al minuto 4 se muestran las respuestas y se piden manos por pregunta. No se califica por acierto: cuenta la
entrega.

**1. (Sesión anterior, jueves 19 de noviembre).** Dos procesos MPI ejecutan, en ese orden, `MPI_Send` al otro y
luego `MPI_Recv` del otro. Un equipo dice que "a veces funciona y a veces se queda colgado". Explica por qué pasan
ambas cosas y da una corrección.

<details><summary>Respuesta</summary>
<code>MPI_Send</code> puede regresar en cuanto el mensaje se copia a un <em>buffer</em> interno (mensajes pequeños)
o bloquearse hasta que el receptor llegue a su <code>MPI_Recv</code> (mensajes grandes). Con mensajes pequeños los
dos <code>Send</code> regresan y el programa sigue; con mensajes grandes los dos esperan al <code>Recv</code> del
otro: interbloqueo. Corrección: invertir el orden en uno de los procesos (pares envían, impares reciben), usar
<code>MPI_Sendrecv</code>, o <code>MPI_Isend</code>/<code>MPI_Irecv</code> + <code>MPI_Wait</code>.
</details>

**2. (Sesión anterior / H2).** En tu tabla de *speedup* de la V2, ¿qué tiempo va en el numerador `T(1)`? Nombra
tres cosas que invalidan la medición según el protocolo del curso.

<details><summary>Respuesta</summary>
<code>T(1)</code> es el tiempo del <strong>mejor programa secuencial</strong> disponible (la V1 optimizada con
<code>-O2</code>), no la versión paralela con un hilo, salvo que se declare y se reporten ambas. Invalidan: medir con
<code>-O0</code>; una sola repetición (o promedio con picos en lugar de mediana de ≥ 5); problema tan pequeño que
<code>T(1) &lt; 0.1 s</code>; cambiar el tamaño entre configuraciones sin declararlo; omitir el hardware; no
verificar correctitud antes de medir.
</details>

**3. (Unidad I).** En la taxonomía de Flynn, ¿qué significa SIMD? Da un ejemplo que hayas usado en este curso.

<details><summary>Respuesta</summary>
<em>Single Instruction, Multiple Data</em>: una instrucción opera sobre varios datos a la vez. Ejemplo del curso:
<code>#pragma omp simd</code> y la vectorización AVX de la S11 de la Unidad III (una suma de 8 <code>float</code>
por instrucción). Hoy: la GPU es SIMT, la misma idea vista desde el hilo.
</details>

**4. (Unidad III, S10).** Un equipo midió su V2: con 4 hilos obtuvo *speedup* 3.1; con 8 hilos, 2.4. Da dos causas
posibles y una forma de distinguirlas.

<details><summary>Respuesta</summary>
Más hilos no es siempre más rápido (idea errónea 1). Causas: (a) la laptop tiene 4 núcleos físicos y 8 lógicos:
los hilos 5–8 compiten por las mismas unidades (sobre-suscripción); (b) falso compartido o contención en
sincronización que crece con los hilos; (c) el ancho de banda de memoria ya estaba saturado con 4. Distinguir:
<code>lscpu</code>/<code>nproc</code> para contar núcleos físicos; Karp–Flatt (<code>f</code> creciente con
<code>p</code> indica sobrecarga creciente); probar acomodo de datos (<em>padding</em>) o acumuladores locales y
volver a medir.
</details>

**5. (Tema de hoy, predicción).** La hoja de datos de la GPU que asigna Colab (Tesla T4) dice "2560 núcleos CUDA".
¿Crees que equivalen a 2560 núcleos como los de tu laptop? Escribe sí o no y una razón; hoy lo comprobamos.

<details><summary>Respuesta</summary>
No. Un "núcleo CUDA" es una unidad aritmética que ejecuta, junto con otras 31, la misma instrucción de un
<em>warp</em>; no tiene su propio control de flujo, predicción de saltos ni caché grande. Un núcleo de CPU sí. La GPU
compensa con miles de hilos ligeros que se turnan para ocultar la latencia de memoria. Cualquier respuesta razonada
vale: es una predicción.
</details>

**Para el profesor.** Si la pregunta 1 queda por debajo de 60 % de aciertos, se dedica un minuto del anclaje a
reexplicar la semántica de bloqueo de `MPI_Send` (idea errónea 17) antes de pasar a GPU, porque la V3 del proyecto
puede combinar MPI con CUDA en su panorama. Las preguntas 3 y 5 se retoman de forma explícita en el bloque SIMT.
