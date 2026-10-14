> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S11 · lunes 26 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S11 · Tarea espaciada (20–40 minutos)

**Entrega:** un archivo `tareas/S11.md` en tu repositorio del curso (texto y una tabla; sin capturas
de pantalla) antes del **jueves 29 de octubre de 2026, 10:30**. Cuenta en "Tareas espaciadas y ejercicios"
(5 % del 2º parcial; se revisan 3 al azar por estudiante). Trabajo individual; IA en verde para
explicaciones, en rojo para inventar números: las mediciones son tuyas y se te puede pedir que las repitas.

## Ejercicio 1 · Del tema (15–20 min): Jacobi con el protocolo completo

En la clase mediste `jacobi1d` con un tamaño reducido para que cupiera en la sesión. Ahora hazlo con el
protocolo de `herramientas/protocolo-medicion.md` (la versión secuencial debe tardar ≥ 1 s):

```bash
cd unidades/U3-memoria-compartida/S11_2026-10-26_patrones-simd/practica-guiada && make
for t in 1 2 4; do ./jacobi1d 1000000 1000 1e-9 par $t; done
```

Si tu máquina tiene 2 núcleos físicos, usa 1 y 2 hilos y declara el hardware. Si la versión secuencial
tarda menos de 1 s, sube `max_iter` hasta que llegue (anótalo).

Llena la tabla (la mediana la imprime el programa):

| hilos | mediana seq (s) | mediana par (s) | *speedup* | eficiencia | Karp–Flatt f |
|---|---|---|---|---|---|
| 1 | | | | | — |
| 2 | | | | | |
| 4 | | | | | |

Después contesta en 3–6 líneas: ¿dónde deja de escalar? ¿La `f` de Karp–Flatt crece con los hilos? ¿Qué
limita aquí: la fracción secuencial, la memoria o la sincronización por iteración? Compara con lo que viste
en clase con `n = 100000`: con `n = 1000000` cada arreglo ocupa 8 MB y hay dos; piensa en qué nivel de la
jerarquía de memoria caben en cada caso (`lscpu` muestra L2 y L3).

## Ejercicio 2 · Intercalado (10 min): Foster y Amdahl sobre el histograma

Aplica las cuatro etapas del método de Foster (Unidad II) al histograma de `array_reduction.c` con `n = 2·10^7`
valores y 16 casillas. Escribe una línea por etapa:

- **Partición**: ¿cuáles son las tareas primitivas, un valor de entrada o una casilla del histograma? ¿Cuántas
  son en cada opción y cuál da más paralelismo?
- **Comunicación**: con la partición por valores, ¿qué tienen que "comunicar" las tareas para obtener el
  histograma final?
- **Aglomeración**: ¿por qué conviene que cada hilo procese un bloque de millones de valores y vuelque 16
  números una sola vez, en lugar de actualizar la casilla compartida valor por valor?
- **Mapeo**: ¿bloques contiguos (`schedule(static)`) o `dynamic`? Justifica con lo que sabes del costo de las
  iteraciones (S08).

Cierra con Amdahl: la inicialización de los datos (no paralelizada) toma el 6 % del tiempo secuencial. ¿Cuál es
el *speedup* máximo con 4 hilos y con infinitos? ¿Es consistente con la eficiencia que viste en clase?

## Ejercicio 3 · Preparación para mañana (5–10 min): S12, martes 27 de octubre, 08:30, Lab LS4

Mañana es el Laboratorio 2 de la Práctica 4 (Partes C y D) y el taller "cómo paralelizar la V1 del proyecto".

1. Lee las Partes C y D de `practicas/P4-openmp/README.md` y escribe tu **predicción** para la Parte D:
   "con 4 hilos espero un *speedup* de ___ porque ___" (dos líneas; se compara con tu medición).
2. Del proyecto: identifica en tu V1 el ciclo que consume más tiempo según tu perfil (Unidad II) y clasifícalo
   con los patrones de hoy: ¿es una reducción (escalar o sobre arreglo), un *stencil*, un *scan*, un *pipeline*
   o un ciclo independiente (*map*)? ¿Tiene alguna dependencia acarreada? Trae la respuesta escrita: es la
   primera pregunta del taller.

Recuerda: **H1 · Avance 1 del proyecto** se presenta en clase el **jueves 29 de octubre de 2026, 10:30**
(12 % del 2º parcial) y la **Práctica 4** se entrega el **domingo 1 de noviembre de 2026, 23:59** (40 %).

<details><summary>Guía de respuesta del ejercicio 2 (consúltala después de escribir la tuya)</summary>

Partición: por valores hay 2·10^7 tareas; por casillas solo 16 (y cada casilla tendría que recorrer todo el
arreglo: 16 lecturas completas). Comunicación: cada tarea aporta un +1 a una casilla; las aportaciones a la
misma casilla deben sumarse (es una reducción). Aglomeración: bloques grandes por hilo con un arreglo local
reducen la comunicación a 16 sumas por hilo y eliminan el tráfico de líneas de caché compartidas (falso
compartido y contención de `atomic`). Mapeo: `static`, porque todas las iteraciones cuestan lo mismo. Amdahl
con s = 0.06: S(4) = 1 / (0.06 + 0.94/4) ≈ 3.39; S(∞) = 1 / 0.06 ≈ 16.7. En clase la eficiencia del histograma
con 4 hilos fue menor que 3.39/4 = 85 %: además de la parte secuencial pesa el ancho de banda de memoria (el
histograma lee 160 MB y casi no calcula).
</details>
