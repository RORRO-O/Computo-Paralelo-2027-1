> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S06 · jueves 3 de diciembre de 2026 · 10:30–12:00 · Salón 3208

# S06 · Repaso de Unidades IV–V: examen de práctica, corrección entre pares, cazador de errores, calibración; lista de cotejo de la entrega final

**Tipo:** repaso previo a examen (variante 2.2 de `docs/metodo/02-plantilla-sesion.md`) con un bloque de 10 min de
lista de cotejo de la entrega final y logística (75–85). Los bloques de la variante se comprimen así: recuperación
larga 0–10 · examen de práctica 10–50 · corrección entre pares 50–60 · los tres ítems peor contestados, como
cazador de errores PRIMM con ConcepTests, 60–72 · calibración 72–75 · lista de cotejo y logística 75–85 · *exit
ticket* 85–90. Recuperación y cierre no se recortan.

## Objetivos (al terminar, el estudiante podrá…)

1. **Resolver** en 40 minutos un examen con la estructura del Examen 3 y **calcular** la brecha entre la
   calificación que creyó obtener y la real (nivel: evaluar). Se mide en la hoja de calibración del examen de
   práctica (casillas A, B, C) y en la pregunta 3 del *exit ticket*.
2. **Localizar y corregir** en código real tres errores que no producen mensaje de error (colectiva llamada solo
   por la raíz; *kernel* sin guardia; reducción sin barrera) y **enunciar** la regla general de cada uno (nivel:
   analizar/aplicar). Se mide con `make cazar` (≥ 1/3 en clase, 3/3 en la tarea), los revotos de CT1–CT3 y la
   pregunta 1 del *exit ticket*.
3. **Predecir** la salida de un programa MPI corto y de un *kernel* CUDA corto con una tabla por rango o por hilo
   (nivel: aplicar). Se mide en los ítems II.1 y II.2 del examen de práctica.
4. **Verificar** con la lista de cotejo el repositorio de otro equipo y **nombrar** los pendientes del propio antes
   del lunes 7 de diciembre, 10:30 (nivel: evaluar). Se mide con la boleta de cotejo entre equipos (75–81).

## Prerrequisitos y vínculo

- **Viene de:** S05 (martes 1 de diciembre, Lab LS4): Lab 2 de P6 (tabla con/sin transferencias) y taller V3
  (`plan-V3.md`). La tarea de S05 pidió tres preguntas tipo examen por estudiante (se intercambian hoy al cierre),
  una predicción de calificación del Examen 3 (se usa en la calibración) y leer la lista de cotejo de la entrega
  final (se aplica hoy entre equipos). De las Unidades I–IV se recuperan: Flynn/SIMT, *speedup*/eficiencia/Amdahl y
  Karp–Flatt, protocolo de medición, falso compartido e histograma de P4, SPMD, `Send`/`Recv`, colectivas, halos,
  modelo de costo, escalabilidad fuerte/débil. De la Unidad V: S01 (modelo CUDA, índices, guardia), S02 (memoria,
  *tiling*), S03 (`__syncthreads`, atómicas, reducción), S04 (eventos, transferencias, bloque), S05 (índices 2D, V3).
- **Va hacia:** Práctica 6 (domingo 6 de diciembre, 23:59) · entrega final del proyecto (lunes 7 de diciembre, 10:30,
  sesión C1 de ensayo de defensa) · Examen 3 (martes 8 de diciembre, 08:30–10:00) · defensa oral (jueves 10 de
  diciembre, 10:30).
- **Ideas erróneas que ataca (Anexo A):** 16–27 completas (una por ítem del examen de práctica: ver su tabla de
  especificaciones) y 1, 5 (ítems I.2, I.5, V.a; recuperación 9 y 10). Las tres que concentran la sesión: 18
  (CT1, cazador 1, III.1/I.1), 34/27 (CT2, cazador 2, II.2/IV.b) y 25/7 (CT3, cazador 3, I.6/III.2). Cada una
  aparece en un distractor, en un paso de la práctica guiada y en el *exit ticket* o la recuperación.
- **Nivel de andamiaje:** última sesión de la unidad → ejemplo resuelto **por completar** (huecos en la tabla de
  rastreo y en el diagnóstico) y PRIMM abreviado: Predecir lo hace el examen de práctica, Ejecutar lo proyecta el
  profesor, Investigar y Modificar en parejas con las preguntas del README, Crear íntegro a la tarea.

## Materiales

- Esta carpeta: `retrieval-inicio.md` (10 preguntas), `examen-practica-U4-U5.md` (impreso: 35 exámenes de 4 páginas
  **sin** la clave; 18 claves de 3 páginas, una por pareja, en sobre cerrado hasta el minuto 50),
  `conceptests.md` (CT1–CT3 proyectables), `practica-guiada/` con `make test` pasado esa mañana en la máquina del
  salón, `ejemplo-resuelto.md`, `exit-ticket.md`, `tarea-espaciada.md`.
- Laptop del profesor con Colab abierto y **GPU asignada desde las 10:15**, `notebook_colab.ipynb` cargado y una
  terminal con `practica-guiada/` compilado (`make`). Plan B si Colab no da GPU: todo Ejecutar sale igual con
  `make run-mpi` y CUDASIM; solo se pierde la observación "en la GPU `caza3` a veces sale bien", que se cuenta.
- Proyector, cronómetro visible, tarjetas con números de lista, tarjetas A/B/C/D de votación.
- Boleta de cotejo entre equipos (abajo, §"Boleta"), 18 copias. Hoja por estudiante: lado A recuperación, lado B
  *exit ticket*.
- `proyecto/entrega-final/lista-cotejo-entrega.md` y `proyecto/defensa/logistica-defensa.md` §3 a la mano.
- Anotar aquí antes de empezar: error más frecuente del *exit ticket* de S05 (martes 1 de diciembre): ________;
  "qué no entienden todavía" más repetido en el taller V3: ________; **opción de defensa elegida (a/b/c):** ____.
- Una laptop por pareja con `mpicc`, `python3 -c "import numba"` y el repositorio clonado (verificado en la tarea de
  S05); quien no tenga forma trío.

## Guion minuto a minuto

### 0–10 · Recuperación larga

Proyectar `retrieval-inicio.md` (10 preguntas, 8 min, sin apuntes). Minuto 8: respuestas; manos por pregunta;
anotar el conteo:

| Pregunta | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Aciertos (de ~35) | | | | | | | | | | |

Mientras contestan, registrar la entrega de la tarea de S05 (`tareas/U5-S05.md`) con la lista. **Si alguna pregunta
queda por debajo de 60 %**, se anota como candidata del bloque 60–72 aunque el examen no la confirme, y se repite
con pista en la recuperación del lunes 7 de diciembre. Frase de enlace (30 s): "Estas diez preguntas son las
cuatro primeras secciones del Examen 3 en miniatura; lo que sigue son 40 minutos de examen de práctica, 60
puntos, la misma estructura que el martes 8. Es para ustedes: no se califica, se corrige".

### 10–50 · Examen de práctica individual

- **10–11.** Repartir el examen. Instrucción literal: "Antes de leer nada, en la casilla **A** escriban la
  calificación de 0 a 60 que creen que van a sacar. Sin dispositivos, sin apuntes; es zona sin IA. A las 10:50
  dejan de escribir y llenan la casilla **B**: la que creen haber sacado. Cada sección trae sus puntos: administren
  el tiempo: I y II en 15 minutos, III y IV en 12, V y VI en 13".
- **11–50.** El profesor no responde dudas de contenido; solo de formato ("¿en cualquier orden?" → "escríbanlo si
  lo creen"). A los 30 y a los 35 minutos se dice el tiempo restante. Mientras tanto, en la laptop: preparar la
  terminal con `make run-mpi` listo y el notebook en la celda de `caza2`.
- **49–50.** "Casilla B. Dejen el lápiz".

### 50–60 · Corrección entre pares con clave

- **50–51.** Intercambiar el examen con el compañero de la pareja PRIMM (misma mesa). Abrir el sobre de la clave
  (una por pareja). Instrucción literal: "Corrigen con la clave, no con su opinión: los puntos parciales están
  escritos en cada ítem. Escriben los puntos por sección en la tabla de la portada y la suma en la casilla **C** del
  dueño. Si no están de acuerdo con la clave, lo anotan al margen y lo vemos en el minuto 60".
- **51–59.** Corrección. El profesor proyecta la tabla de puntos por sección y circula atendiendo dudas de la clave
  (no del contenido). Dudas típicas y la respuesta en una línea: "puso `Reduce + Bcast` en III.1" → vale 1 de 2
  (dos llamadas donde una basta); "en II.1 dio el orden fijo" → pierde el punto del orden; "en V.b iv eligió solo
  uno" → 0 en ese inciso; "en VI eligió MPI con números correctos" → vale completo si descartó la GPU con un dato.
- **59–60.** Devolver el examen. Cada quien escribe `B − C`. Manos por sección: "¿quién perdió **más de la mitad**
  de los puntos en I? ¿en II.1? ¿II.2? ¿III.1? ¿III.2? ¿IV? ¿V.a? ¿V.b? ¿VI?". Anotar los tres ítems con más manos:
  ________, ________, ________. Predicción del autor: III.1, II.2 y V.b.

### 60–72 · Los tres ítems peor contestados = cazador de errores PRIMM (CT1–CT3)

Cuatro minutos por ítem. Para cada uno: voto A/B/C/D del ConcepTest correspondiente (1 min; discusión en parejas
y revoto solo si el primer voto queda entre 30 % y 80 %) → el profesor **ejecuta** el cazador en el proyector
(1 min) → una pregunta de Investigar a las parejas (1 min) → regla general en una frase y las parejas arrancan
Modificar en su laptop con `make cazar` (lo que no termine va a la tarea).

| Ítem fallado | ConcepTest | Qué se ejecuta (salida real en `practica-guiada/README.md`, sección R) | Pregunta de Investigar | Regla general |
|---|---|---|---|---|
| III.1, I.1 o IV.a (colectivas) | CT1 | `make run-mpi` → `codigo: 124`; `make run-mpi NP=1` → `media=3.497000`; después `make run-examen` para ver III.1 con y sin error | I1: "¿qué llamada hace el rango 1 y qué espera? ¿por qué la raíz sí sale del `Bcast`?" | Toda colectiva la llaman todos los procesos del comunicador; el resultado de `Reduce`/`Gather` solo existe en la raíz |
| II.2 o IV.b (índices, guardia) | CT2 | `NUMBA_ENABLE_CUDASIM=1 python3 caza2_guard_numba.py 1000 256` → 24 centinelas, `FALLA`; `1024 256` → `OK`; en Colab, `./item_II2_reverse` → `3 2 1 0 7 6 5 4 8 9` | I2: "hilos 231, 232 y 255 del bloque 3: ¿cuál es el primer `i` que no debe escribir? ¿sobre qué memoria escribiría en tu V3?" | `grid = ⌈n/block⌉` y `if (i < n)` van juntos; "¿quién cargó `s[j]`?" antes de leer memoria compartida |
| I.6 o III.2 (sincronización) | CT3 | tres corridas de `caza3_reduce_numba.py 1000` → 460, 612, 892 (cambia); en Colab `./caza3_reduce_buggy 1000 32` repetido: a veces `5500.0` | I3: "si el hilo 0 lee `s[2]` antes de que el hilo 2 sume, ¿qué lee? ¿puede dar más de 36?" | Una barrera por nivel, fuera del `if`; la carrera se prueba con varias corridas y una referencia, no con una corrida afortunada |
| V.b (transferencias; sin cazador) | — (voto directo del ítem) | Pizarrón: `90/1.5 = 60×`; `90/37.5 = 2.4×`; 100 iteraciones: `9000/186 ≈ 48×` | "¿Cuántas veces cruza tu arreglo el PCIe en tu V3? ¿Cuántas necesita?" | Se reportan los dos tiempos; lo que gana el usuario es el total; copia una vez, calcula muchas |

Si los tres ítems fallados son los tres primeros renglones, el bloque es exactamente CT1 → CT2 → CT3. Si uno es
V.b, se resuelve en el pizarrón (3 min) y el cazador que se desplaza pasa íntegro a la tarea (1b). Si falla VI, se
lee en voz alta la clave de VI(a) con sus dos números y se pregunta por tarjeta "¿qué número usó tu pareja?".

**Errores esperados en Modificar y la pregunta que se hace** (no se da la respuesta):

| Error observado | Pregunta socrática |
|---|---|
| Mueven `MPI_Bcast` fuera del `if` pero dejan el `MPI_Recv` en el `else` | "¿Cuántas veces recibe `n` el rango 1 ahora? ¿Quién le manda la segunda?" |
| Sustituyen el `Bcast` por `MPI_Send` desde la raíz a cada rango (en ciclo) | "Funciona. ¿Cuántos mensajes son con `p = 64`? ¿Cuántos pasos hace `Bcast` por dentro (S03)?" |
| Ponen la guardia en el anfitrión (`cap = n`) en lugar del *kernel* | "¿Cuántos hilos lanzaste? ¿Dónde escribe el hilo 1000 ahora?" |
| Corrigen el `.cu` y no el espejo Numba (o al revés) y `make cazar` sigue en FAIL | "¿Qué archivo ejecuta `make cazar` sin GPU? ¿Están iguales los dos *kernels*?" |
| Barrera dentro del `if (tid < stride)` | "El hilo 5 con `stride = 4`: ¿entra al `if`? ¿Llega a la barrera? ¿Qué le pasa al hilo 0?" |
| Barrera solo al final del ciclo (fuera del `for`) | "¿Entre el nivel 128 y el 64 quién protege a `s[tid + 64]`?" |
| Declaran "ya funciona" tras una corrida de `caza3` | "¿Cuántas corridas pide `make cazar` y por qué dos iguales?" |
| `make cazar` falla por `mpirun` como root o sin `--oversubscribe` | "¿Qué dice el primer renglón del README en 'Cómo ejecutar'?" |
| Corrigen copiando `soluciones/` | "Explícame la línea que cambió y qué prueba la expone. Si puedes, cuenta; si no, no" (prueba de propiedad) |

### 72–75 · Calibración

Instrucción literal: "Tres datos en la portada de su examen: la brecha `B − C` (positiva = se sintieron mejor de lo
que salió); la predicción del Examen 3 que escribieron en la tarea de S05 (3b); y la sección donde perdieron más
puntos. Con esos tres datos van a llenar la pregunta 2 del *exit ticket*". El profesor pide manos: "¿a quién le dio
`B − C` mayor que +6?" (10 % del examen; es el umbral de sobreestimación del curso escalado) y anota el número. El
promedio del grupo se dice el lunes 7; la brecha individual no se comenta en público.

### 75–85 · Lista de cotejo de la entrega final y logística

**75–81 · Cotejo entre equipos (6 min).** Equipos en pares (A↔B, por tarjeta). Cada equipo abre en GitHub el
repositorio del otro (teléfono o laptop, sin clonar) y llena la boleta:

| # | Ítem (número de `lista-cotejo-entrega.md`) | Cómo se ve en GitHub en 30 s | Sí/No |
|---|---|---|---|
| 1 | README con problema, datos/semillas, cómo compilar, `run_all`, hardware, integrantes y reparto, uso de IA (1) | Abrir `README.md`; buscar las siete palabras | |
| 2 | `Makefile` raíz con `all`, `run`, `test`, `clean` (2) y `run_all.sh` presente (3) | Abrir los dos archivos | |
| 3 | Carpetas `v1*/`, `v2*/`, `v3*/` con `Makefile` cada una (4) | Árbol del repositorio | |
| 4 | `v3*/notebook_colab.ipynb` **ejecutado**: se ve la salida de `!nvidia-smi` y `PASS v3 == v1` (16, 17) | GitHub renderiza el *notebook* con salidas | |
| 5 | `bitacora.md` con ≥ 3 entradas fechadas (19) | Contar líneas que empiezan con `| 2026-` | |
| 6 | Declaración de IA con la línea "qué nos dijo la IA que resultó estar mal" (20) | Buscar "resultó estar mal" en el README | |
| 7 | *Commits* de todos los integrantes (21) y ningún binario ni `.o` versionado (22) | *Insights → Contributors*; buscar `.o`/ejecutables en el árbol | |
| 8 | Saben el comando de la etiqueta (24): `git tag -a entrega-final && git push origin entrega-final` antes del lunes 10:30 | Preguntar al equipo | |

La boleta se entrega al equipo revisado, firmada por el revisor. Frase: "Cada **No** es un criterio de rúbrica que
baja el lunes; el ítem 25 (números del PDF en los CSV) lo revisa otro equipo el lunes en el ensayo. El script
`proyecto/entrega-final/scripts/verificar_entrega.sh` hace los ítems 1–24 en segundos sobre un clon limpio: es el
ejercicio 3a de la tarea".

**81–85 · Logística (4 min; decir fechas completas, proyectar).**

1. **Práctica 6:** domingo 6 de diciembre, 23:59. Sin cuota de GPU en las 48 h previas: captura fechada del aviso,
   medición marcada como pendiente y se completa a más tardar el martes 15 de diciembre, 08:30, sin penalización.
2. **Entrega final:** lunes 7 de diciembre, 10:30: etiqueta `entrega-final` empujada antes de esa hora;
   `reporte/reporte.pdf` de 8–12 páginas dentro del repositorio; tardía hasta el jueves 10 de diciembre 10:30 con
   tope de 80 %. La sesión del lunes es ensayo de defensa con lista de cotejo entre equipos.
3. **Examen 3:** martes 8 de diciembre, 08:30–10:00; Unidades IV–V con 10–20 % acumulativo integrado; versiones A y
   B alternadas por fila; 80 minutos efectivos más 10 de margen; sin dispositivos; hoja de calibración aparte con
   dos casillas (al recibir y al entregar), como hoy; hoja de fórmulas solo si el examen lo indica (no cuenten con
   ella). Lugar: salón 3208 o LS4 con los equipos apagados; se confirma el lunes 7. Calificación y clave a más
   tardar el martes 15 de diciembre; análisis de los tres ítems peor contestados el lunes 14.
4. **Defensa oral, jueves 10 de diciembre, 10:30.** El profesor anuncia la opción elegida (`logistica-defensa.md`
   §3) con una de estas tres frases y la publica hoy en un *issue* del repositorio del curso:
   - (a) "Formato completo: 12 min + 2 preguntas por integrante; 4 equipos el jueves 10, 4 el lunes 14 y 4 el
     martes 15 a las 08:30; el orden sale del sorteo con semilla `20261210` el lunes 7".
   - (b) "Formato corto: 7 min de exposición + 3 de preguntas; 6 equipos el jueves 10 y 6 el lunes 14; el ensayo
     del lunes ya es de 7 minutos".
   - (c) "Mixta: video de ≤ 8 min enlazado en el repositorio antes del lunes 7 a las 10:30; en clase 2 min de demo
     y una pregunta por integrante; todos el jueves 10".
   En cualquier opción: la demo corre desde el clon de la etiqueta; preguntas individuales; prueba de propiedad.

### 85–90 · Cierre

*Exit ticket* (`exit-ticket.md`, lado B): pregunta 1 de opción múltiple, pregunta 2 = plan concreto para hoy y mañana
(sección perdida + archivo + hora), pregunta 3 = confianza y predicción del Examen 3. Mientras escriben, proyectar:

- Tarea (`tarea-espaciada.md`): `tareas/U5-S06.md` antes del lunes 7 de diciembre, 10:30; `make cazar` 3/3; el
  verificador de la entrega sobre un clon limpio. Sin peso propio; es el estudio del Examen 3.
- "Antes de salir, intercambien con su pareja las tres preguntas tipo examen de la tarea de S05: son material de
  estudio para hoy y mañana".
- Recoger exámenes **no** (se los llevan con su clave); recoger hojas de recuperación/*exit ticket* y boletas.

## Diferenciación

- **Apoyo (quien no arranca en Modificar):** entregarle la tabla I1 con las filas de los rangos 0 y 1 ya llenas y
  pedir solo la del rango 3; para `caza2`, la pista sellada del README (hilos 231/232/255) y la instrucción "la
  corrección es una línea dentro del *kernel*"; para `caza3`, el rastreo I3 con `block = 8` hecho hasta `stride = 4`
  y la pregunta "¿quién protege la lectura de `s[tid + 2]`?". Permitir todo Modificar con CUDASIM y `n = 1000`.
  Quien perdió más de la mitad en II: resolver con el ejemplo resuelto parte A (tabla por rango) antes de la tarea.
- **Ampliación (quien termina 3/3 antes del minuto 72):** (a) `caza3` con `block = 32` en Colab, 10 corridas, y una
  frase sobre `__syncwarp()` y la planificación independiente de hilos; (b) sustituir `MPI_Bcast` de `caza1` por
  `MPI_Send`/`MPI_Recv` en ciclo y medir con `MPI_Wtime` la diferencia con `p = 8` (sobre-suscrito, declarado);
  (c) empezar el `caza4` de la tarea con el tema `tiempo` y mostrar el *speedup* "imposible" en el notebook.

## Evaluación formativa de la sesión

| Objetivo | Qué mira el profesor |
|---|---|
| 1 | Casillas A, B, C llenas en ≥ 90 % de los exámenes; proporción con `B − C > +6` (alerta si > 30 %); predicción del Examen 3 en el *exit ticket* 3 |
| 2 | Revoto de CT1–CT3 ≥ 80 %; parejas con `make cazar` ≥ 1/3 al minuto 72 (meta ≥ 70 %); *exit ticket* 1 = C en ≥ 70 % |
| 3 | Puntos de II.1 y II.2 en la tabla de la portada (meta: mediana ≥ 9 de 13); errores "orden fijo" y "`max_root` en todos" contados en la corrección |
| 4 | Boletas entregadas por todos los equipos; número de **No** por ítem (los ítems 4 y 6 suelen concentrarlos); cada equipo nombra ≥ 2 pendientes propios |

Umbrales de alerta (marco §5): > 30 % de *exit tickets* en "mal" → la recuperación del lunes 7 repite la pregunta 1
con pista; recuperación < 60 % en 2, 4 u 8 → se repiten con pista el lunes 7; `B − C` promedio > +6 → la
retroalimentación del Examen 3 (lunes 14 de diciembre) abre con la brecha de calibración del grupo.

## Notas post-sesión

- (se llenan después) Conteo de la recuperación: ____. Tres ítems peor contestados: ____, ____, ____ (¿coincidieron
  con la predicción III.1, II.2, V.b?).
- CT1 ___ % / ___ %. CT2 ___ % / ___ %. CT3 ___ % / ___ %. ¿Se usó el renglón V.b en lugar de un cazador? ____.
- Parejas con `make cazar` ≥ 1/3 al minuto 72: ____ de ____. ¿Hubo GPU en Colab a las 10:15? ____.
- Promedio de `B − C`: ____. Promedio de la predicción del Examen 3: ____ (se compara el lunes 14 de diciembre).
- **No** más frecuente en la boleta de cotejo: ítem ____. Opción de defensa anunciada: ____. *Issue* publicado: ____.
- Error más frecuente del *exit ticket*: ____. Cambio para la retroalimentación del lunes 14: ____.
