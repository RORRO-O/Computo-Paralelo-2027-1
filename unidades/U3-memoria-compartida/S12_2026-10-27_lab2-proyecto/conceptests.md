> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S12 · martes 27 de octubre de 2026 · 08:30–10:00 · Lab LS4

# ConcepTests · S12

Secuencia fija: voto individual (1 min) → discusión en parejas (2 min) → revoto → explicación. Si el primer
voto supera 80 % de aciertos se salta la discusión; si queda por debajo de 30 % se vuelve a explicar antes
de discutir. La sesión usa dos: **CT1** en la mini-lección del taller (bloque 60–65) y **CT2** al cerrar el
taller (83–85), este último con un solo voto y discusión solo si el acierto queda entre 30 % y 80 %
(`07-guia-de-autoria.md`, §A.7). **CT3 es reserva**: sirve para la recuperación de S13 (jueves 29 de octubre)
o para el examen de práctica; también puede votarse en el bloque 5–12 si la pregunta 4 de la recuperación
quedó bajo 60 %.

## CT1 · ¿Cuánto *speedup* total da paralelizar la fase caliente? (idea errónea 2)

Un programa de tres fases, compilado con `-O2`, da este perfil (mediana de 5 corridas, 1 hilo):

| Fase | Tiempo (s) | Líneas de código |
|---|---|---|
| carga | 0.25 | 12 |
| cómputo | 1.20 | 190 (95 % del archivo) |
| salida | 0.05 | 8 |

Se paraleliza **solo** la fase de cómputo y escala perfectamente en 4 hilos. ¿Qué *speedup* del **programa
completo** se obtiene con 4 hilos?

- A) 4.0
- B) 2.5
- C) 3.5
- D) 0.63

**Respuesta: B.** Tiempo nuevo = 0.25 + 1.20/4 + 0.05 = 0.60 s; S = 1.50 / 0.60 = 2.5.

| Distractor | Origen |
|---|---|
| A | Idea errónea 1: "más hilos siempre es más rápido": 4 hilos → 4×. Ignora las fases secuenciales. |
| C | Idea errónea 2: calcula la fracción paralelizable con **líneas** (95 %): 1/(0.05 + 0.95/4) ≈ 3.5. |
| D | Idea errónea 3: confunde eficiencia con *speedup*: 2.5/4 = 0.63. |

**Primer voto esperado: ~50 % en B** (C es muy atractiva porque la tabla trae las líneas a propósito).

Guion de discusión (3 líneas): "Quien votó C: ¿en qué unidad está la fracción de Amdahl, en líneas o en
segundos? Quien votó A: ¿cuánto tarda la carga con 4 hilos? Todos: escriban el tiempo nuevo fase por fase
y súmenlo; después dividan."

## CT2 · ¿Cuál es el primer paso para pasar de la V1 a la V2? (ideas erróneas 29 y 28)

La V1 de un equipo lee un archivo, construye una estructura y corre un ciclo principal donde aparece
`hist[bin]++`. El equipo tiene una tarde para empezar la V2. ¿Cuál es el **primer** paso correcto?

- A) Poner `#pragma omp parallel for` en el ciclo más largo del archivo y revisar si el resultado sale bien.
- B) Cronometrar cada sección con `omp_get_wtime()` (5 repeticiones, mediana) y, para el ciclo que domine,
  listar qué variables lee y escribe cada iteración.
- C) Juntar lectura, construcción y ciclo en una sola función para "aglomerar" y que una sola región
  `parallel` cubra todo el programa.
- D) Cambiar el ciclo a `schedule(dynamic)`, que siempre reparte mejor el trabajo.

**Respuesta: B.** Primero medir dónde está el tiempo y después analizar dependencias (`hist[bin]++` es una
carrera potencial); el `#pragma` viene al final, con `schedule` elegido por evidencia.

| Distractor | Origen |
|---|---|
| A | Idea errónea 29: "primero se programa y luego se diseña"; además "salió bien una vez" no es evidencia (idea 7) y elige el ciclo por longitud (idea 2). |
| C | Idea errónea 28: "aglomerar es juntar todo en un solo proceso/región". Aglomerar es agrupar tareas para reducir sobrecarga sin perder paralelismo. |
| D | Idea errónea 11: "`schedule(dynamic)` siempre gana". |

**Primer voto esperado: ~60 % en B** (A atrae a quien ya "sabe OpenMP"; C a quien recuerda la palabra
"aglomerar" sin su definición).

Guion de discusión: "Quien votó A: ¿qué pasa con `hist[bin]++` cuando dos hilos caen en el mismo `bin`? ¿Lo
sabrías antes de correrlo? Quien votó C: según Foster, ¿aglomerar reduce comunicación o elimina el
paralelismo? Todos: ¿qué número necesitan antes de decidir qué ciclo tocar?"

## CT3 (reserva) · ¿Qué *speedup* se reporta? (idea errónea 5)

Fase caliente, mismo tamaño del problema, `-O2`. Con 1 hilo la mediana de 5 corridas es 1.20 s. Con 4 hilos
las 5 corridas dan: 0.41, 0.39, 0.95, 0.40 y 0.40 s. ¿Qué *speedup* se reporta para 4 hilos?

- A) 3.0
- B) 2.4
- C) 3.1
- D) Ninguno todavía: hay que repetir con `-O0` para que las corridas sean estables.

**Respuesta: A.** La mediana de {0.39, 0.40, 0.40, 0.41, 0.95} es 0.40 s; S = 1.20 / 0.40 = 3.0. El 0.95 se
reporta como máximo (y se investiga si se repite), pero no arrastra el estadístico.

| Distractor | Origen |
|---|---|
| B | Idea errónea 5 (variante "promedio"): la media es 0.51 s → 2.35. El pico de 0.95 contamina el promedio; por eso el protocolo pide mediana. |
| C | Idea errónea 5 (variante "medir una vez / quedarse con la mejor"): usa el mínimo 0.39 s → 3.08. Elegir la mejor corrida es escoger el dato que conviene. |
| D | Idea errónea 5 ("se mide con -O0"): `-O0` no estabiliza nada y mide un programa que nadie usaría. |

**Primer voto esperado: ~65 % en A.**

Guion de discusión: "Quien votó B: si el pico fuera 9.5 s en vez de 0.95, ¿seguirías promediando? Quien votó
C: ¿por qué el protocolo pide reportar mín y máx además de la mediana? Todos: ¿qué harías con la corrida de
0.95 s antes de entregar la tabla?"
