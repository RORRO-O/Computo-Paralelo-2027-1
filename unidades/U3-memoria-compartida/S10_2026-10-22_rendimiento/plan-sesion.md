> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S10 · jueves 22 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S10 · Rendimiento: protocolo de medición, *speedup*/eficiencia/escalabilidad, Amdahl con datos medidos, Karp–Flatt, falso compartido, afinidad, sobrecarga

Tipo: contenido (estructura base de 90 min). Tercera sesión de contenido de la unidad: el ejemplo resuelto es un
problema **por completar** (tres huecos) y la práctica guiada abrevia Predecir e Investigar para dar ≥ 10 min a
Crear. Este plan está escrito para que lo pueda dar otro profesor sin hablar con el autor.

## Objetivos (al terminar, el estudiante podrá…)

1. **Aplicar** el protocolo de medición del curso a un programa OpenMP (`-O2`, calentamiento, 5 repeticiones,
   mediana, mejor secuencial como `T(1)`, tamaño y afinidad declarados) y **producir** el CSV y la gráfica de
   *speedup* vs. hilos con la línea ideal (nivel: aplicar).
2. **Calcular e interpretar** *speedup*, eficiencia, eficiencia débil y la fracción secuencial de Karp–Flatt a
   partir de medianas medidas, distinguiendo escalabilidad fuerte de débil (nivel: aplicar/analizar).
3. **Predecir** con Amdahl el *speedup* de un programa a partir de su fracción secuencial **medida** por secciones
   con `omp_get_wtime()`, y **explicar** la diferencia con el *speedup* medido usando Karp–Flatt (nivel:
   analizar/evaluar).
4. **Diagnosticar** con una medición cuál de cuatro causas limita la escalabilidad de un ciclo (fracción
   secuencial, ancho de banda de memoria, sobrecarga de regiones/barreras, falso compartido) y **proponer** la
   corrección correspondiente (acumulador local o relleno, una región, tamaño mayor) (nivel: analizar).

El objetivo 2 se evalúa en las dos preguntas del *exit ticket*; el 3 en CT1 y el Hueco 3 del ejemplo; el 4 en CT2
y en la tabla de PRIMM; el 1 en la fase Crear y en la tarea.

## Prerrequisitos y vínculo

- **Viene de:** S09, martes 20 de octubre (Lab 1 de P4: tareas, `taskwait`, `cutoff`; Partes A y B). De S07
  (`atomic`/`critical`/`reduction`, costo medido) y S08 (`schedule`, Karp–Flatt como diagnóstico de desbalance en
  la tarea). De las Unidades I (*speedup*, eficiencia, Amdahl, Gustafson) y II (perfilado, Foster).
- **Va hacia:** S11, lunes 26 de octubre, 10:30, Salón 3208 (patrones, Jacobi 1D, `simd`: la pregunta 1 de su
  recuperación es el cálculo de `S`, `E` y `f` de hoy); S12, martes 27 de octubre, 08:30, Lab LS4 (Práctica 4 ·
  Lab 2, Partes C y D: la Parte D es este protocolo); H1, jueves 29 de octubre (perfilado de la V1); H2, lunes 23 de
  noviembre (*speedup* de la V2 con este protocolo).
- **Ideas erróneas que esta sesión ataca** (Anexo A): **1** ("más hilos siempre es más rápido": `region_overhead`,
  CT1-C, CT2-C), **2** (Amdahl en líneas: Hueco 1, CT1, retrieval 4), **3** (eficiencia = *speedup*: retrieval 3,
  CT1-D, *exit ticket* 1-D y 2), **4** (superlineal = error: CT3, notas §2), **5** (medir una vez / con `-O0`:
  tabla del protocolo, CT2-D, CT3-C, variante que falla del ejemplo), **6** (fuerte = débil: `weak_scaling`,
  *exit ticket* 1), **14** (falso compartido: `false_sharing`, CT2, retrieval 5); además **31** (`clock()`, `T(1)`
  paralelo: Pausa 4, *exit ticket* 2). Nuevas para el catálogo: 2b ("el *speedup* del núcleo es el del programa",
  CT1-A), 14b (confundir falso compartido con carrera, CT2-A), 4b (`f` de Karp–Flatt negativa "demuestra" algo,
  CT3-D).
- **Nivel de andamiaje:** por completar / con pistas (`07-guia-de-autoria.md`, §A.5): ejemplo con tres huecos,
  PRIMM con Predecir e Investigar abreviadas y Crear ≥ 10 min.

## Materiales

- Esta carpeta completa, compilada **antes** de la sesión en la máquina del salón: `cd practica-guiada && make &&
  make test` (27 PASS, ~8 s) y `make medir && make grafica` (~40 s) para tener los CSV y los PNG listos por si la
  red o las laptops fallan. Comprobar `uptime` < 1 antes de proyectar una medición en vivo; si la máquina del salón
  tiene 2 núcleos físicos, proyectar las salidas de este material y decirlo.
- Proyector; cronómetro visible; tarjetas con números de lista y tarjetas A/B/C/D; pizarrón con dos fórmulas
  escritas desde el inicio: `E = S/p` y `f_KF = (1/S − 1/p)/(1 − 1/p)`.
- Estudiantes: una laptop por pareja con `gcc -fopenmp` y, de preferencia, `python3` con `matplotlib`. Quien no
  tenga `matplotlib` hace la gráfica a mano con la tabla que imprime el programa.
- Anuncios preparados: Lab 2 de P4 (martes 27 de octubre, 08:30, Partes C y D), H1 (jueves 29 de octubre).

## Guion minuto a minuto

### 0–5 · Recuperación

Proyectar las 5 preguntas de `retrieval-inicio.md`. Individual, sin apuntes, 4 minutos. Al minuto 4 mostrar las
respuestas y pedir manos por pregunta; anotar el conteo de la 1, la 2 y la 3.

- Si < 60 % acierta la 1 (`taskwait` espera a las hijas directas): dibujar el árbol de tareas en el pizarrón en
  el bloque siguiente (2 min, se descuentan de Transferencia).
- Si < 60 % acierta la 3 (`E = S/p`): el Hueco 1 del ejemplo no se abre hasta que cada estudiante tenga escrito
  `E = 0.75` en su hoja; la fórmula se queda en el pizarrón toda la sesión.
- La 5 **no se corrige**: "guarden su conjetura; en 40 minutos la van a medir".

### 5–10 · Objetivos y anclaje

Autocalificación con su clave (2 min; se registra entrega) de lo que vence hoy a las 10:30: la tarea de S09
(`tareas/<usuario-github>/U3-S09.md`; su ejercicio 3 fue la preparación de hoy: *speedup*, eficiencia y Karp–Flatt
del mergesort y la conjetura del falso compartido). Si falta tiempo, solo el ejercicio 3 y el resto con la clave en
casa. Si rige la opción por defecto del pre-lab de P4 (S09 `plan-sesion.md`, Materiales), hoy a las 10:30 vence
también el pre-lab (`practicas/P4/prelab/`): se registra la entrega igual. Proyectar los cuatro objetivos.
Frase de anclaje: "El martes en el Lab 1 el error más frecuente del *exit ticket* fue [sustituir por el error
real registrado en las notas post-sesión de S09; si no se tiene, usar: *reportar el speedup de la parte con
tareas como si fuera el del programa*]. Hoy la sesión entera es sobre cómo medir sin engañarse: lo que entreguen
en la Parte D de la Práctica 4 el martes, en H1 el jueves 29 y en H2 el 23 de noviembre se califica con el
protocolo que vamos a aplicar ahora." Vínculo con el proyecto: "La V1 que entregan en H1 trae un perfil por
secciones; con ese perfil, hoy aprenden a predecir cuánto puede acelerar su V2 antes de escribir una sola línea
paralela."

### 10–35 · Instrucción explícita I (ejemplo por completar + CT1)

Seguir `ejemplo-resuelto.md`. El profesor **piensa en voz alta** y deja los huecos al grupo.

| Minuto | Qué se hace | Qué se dice |
|---|---|---|
| 10–13 | Proyectar las tres secciones de `profile_amdahl.c` (solo `run_pipeline`). No correr `make run` (tarda); correr solo `OMP_PROC_BIND=close OMP_PLACES=cores OMP_NUM_THREADS=1 ./profile_amdahl` y proyectar la tabla del perfil. | "Tres cronómetros, uno por sección, en la versión **secuencial**. Antes de paralelizar nada ya sabemos cuánto podemos ganar. ¿Cuántas líneas tiene B? ¿Y cuánto tiempo?" |
| 13–17 | **Hueco 1** (f medida) y **Hueco 2** (Amdahl S(2), S(4), S(8), S(∞)) en silencio, 2 min, con la tabla de `ejemplo-resuelto.md` (las claves usan esos números; la corrida en vivo da otros parecidos: en la revisión, `f` = 0.096–0.108). Elegir al azar dos números de lista para dictarlos. Escribir en el pizarrón `f = 0.101`, techo `9.88`. | "Alguien calculó `f` con líneas de código: ¿cuánto le dio? Esa es la idea errónea más cara del examen. `f` es tiempo." |
| 17–22 | Correr con 4 hilos, proyectar. **Hueco 3** (S medido, E, Karp–Flatt) en parejas, 2 min, con los números del documento; "¿qué concluyó tu pareja?" a dos parejas. Si la corrida en vivo da otros (en la revisión: S = 2.02–2.62, `f_KF` = 0.18–0.33), decirlo: la conclusión `f_KF ≫ f` se repite. | "Amdahl dijo 3.07; medimos 2.58. Karp–Flatt dice `f_KF = 0.184`, pero la f medida es 0.101: la diferencia no está en A ni en C. ¿Dónde está?" Cerrar: "`f_KF ≫ f` → el problema está **dentro** de la región paralela: sobrecarga, memoria o competencia por el procesador." |
| 22–25 | Pausa 4 (`clock()`) y Pausa 5 (qué sección atacar). Señalar la línea `clock()` de la salida. | "`clock()` sumó la CPU de los 4 hilos: con él el *speedup* sale al revés. Por eso el protocolo dice `omp_get_wtime`." |
| 25–28 | Las seis reglas del protocolo (`notas-estudiante.md`, §1) en una pantalla, señalando dónde está cada una en el código que acaban de ver. Mencionar afinidad en una frase: "hoy medimos con un hilo por núcleo y lo declaramos; en M4 van a ver qué cambia y qué no". | Una regla por frase. No leer la tabla completa. |
| 28–35 | **CT1** (`conceptests.md`): voto → parejas → revoto → explicación con la salida de `profile_amdahl` a la vista. | Guion de discusión de CT1. Si el primer voto > 80 %, saltar la discusión y preguntar "¿y si B fuera el 99 % del tiempo?" |

Qué **no** hacer: no entrar en `simd` ni en patrones (es S11); no teclear código nuevo en vivo; no discutir la
afinidad más de una frase aquí (va en M4).

### 35–65 · Práctica guiada PRIMM (parejas: conductor/navegante, cambio al minuto 50)

**Arranque (1 min).** "Abran `practica-guiada/README.md`. Fase 1, Predecir, por escrito, 3 minutos: cuatro
predicciones, una línea cada una. El navegante escribe. P1 parte de su conjetura de la tarea de S09 (ejercicio 3b)
y de la pregunta 5 de hoy: ahora pongan un número." Al minuto 39: "`make && make run`; mientras corre,
lean la salida de `false_sharing` y compárenla con P1. Después `make medir && make grafica`." Al minuto 47:
"Investigar: preguntas 1, 2, 4 y 5 obligatorias; 3 y 6 si alcanzan." Al minuto 50: cambio de roles. Al minuto 53:
"Modificar: M1 y M2 obligatorios; M3 y M4 si alcanzan. Cada cambio con `make test`."

**El profesor circula** con esta lista. Ante cada error, **una pregunta**, no la respuesta:

| # | Error esperado | Pregunta socrática |
|---|---|---|
| 1 | "`contiguo` y `relleno` dan lo mismo; el falso compartido no existe en mi máquina." | "¿Cuántos núcleos físicos tienes (`lscpu`)? ¿Con qué `n` corriste? ¿Qué dice la columna `min`? Sube `n` diez veces y vuelve a mirar." |
| 2 | Leen `speedup=3.6` de la sección B y lo anotan como *speedup* del programa. | "¿Qué tiempo ve el usuario cuando corre el programa: el de B o el total? ¿Qué fila dice `total`?" (idea 2b) |
| 3 | Calculan `E` dividiendo entre el número de hilos lógicos u olvidan dividir. | "¿Qué significa una eficiencia de 2.6? ¿Puede un núcleo rendir más del 100 %? ¿Entre cuántos núcleos repartiste?" |
| 4 | En `weak_scaling`, comparan `debil` con 4 hilos contra `secuencial` y concluyen "*speedup* 0.9, no escala". | "¿Cuánto trabajo hizo cada hilo en la fila `debil`? ¿Y en la `secuencial`? ¿Qué pregunta responde la escalabilidad débil?" (idea 6) |
| 5 | Corren `make medir` con el navegador abierto o dos parejas en la misma laptop; todas las eficiencias < 0.4. | "¿Qué dice `uptime`? ¿Con quién compite tu programa por los 4 núcleos? ¿Qué regla del protocolo §1 es?" |
| 6 | En M1 agregan el nombre de la variante a `names` (y suben el `3` del ciclo a `4`) pero no la rama `else if`: la cuarta fila vuelve a medir `local` y sale idéntica a ella. | "¿Qué función llama tu programa cuando `v == 3`? ¿Por qué tu variante tarda lo mismo que `local` y no algo entre `contiguo` y `relleno`?" |
| 7 | Concluyen de `region_overhead 2000 20000` que "OpenMP es más lento que secuencial". | "¿Cuántas operaciones hace cada pasada? ¿Cuánto cuesta abrir una región según la última línea? Corre `2000000 20`: mismo total de operaciones, ¿qué cambió?" (idea 1) |
| 8 | `saxpy` escala casi perfecto y lo dan por "limitado por cómputo". | "¿Cuántos flop hace por byte? ¿Cuántos GB/s alcanzó con 1, 2 y 4 hilos: siguen creciendo o se estancaron? ¿Cuánta L3 tiene tu CPU (`lscpu`)? ¿Qué pasa con `50000000`?" (M3) |
| 9 | Toman `f_KF` negativa (de un *speedup* superlineal) como error del script. | "¿Qué supone Amdahl sobre la caché? Si `S > p`, ¿qué entró en caché que antes no cabía? ¿Está bien el resultado (`status=OK`)?" (idea 4) |
| 10 | Reportan el tiempo mínimo en lugar de la mediana "porque es el más limpio". | "¿Qué repite el usuario cuando corre tu programa: el mejor caso o el típico? ¿Qué estadístico pide el protocolo y por qué no el promedio?" (idea 5) |
| 11 | `make afinidad` da igual con y sin `BIND` (como en la máquina de autoría) y concluyen que la afinidad "no sirve". | "¿Qué hace el sistema operativo con tus hilos cuando los cuatro núcleos son iguales y nadie más usa la máquina? ¿Y si dos hilos caen en el mismo núcleo físico con *hyper-threading*, o en un núcleo eficiente de un procesador híbrido? ¿Qué dice el protocolo: que ayuda o que se **declara**?" |

Si una pareja termina M1–M4 antes del minuto 65, pasa a Crear (Fase 5).

### 65–75 · Puesta en común + CT2

Proyectar las tablas de **dos parejas** (una con laptop de 2 núcleos, otra de 4) junto a la de autoría
(`practica-guiada/README.md`, Fase 2; resumen en `notas-estudiante.md`, §3). Mostrar sin nombres dos o tres hallazgos de la ronda (los más probables: #2, #4 y
#7 de la lista) y pedir a la pareja correspondiente que diga qué pregunta la destrabó.

**CT2** (`conceptests.md`): voto; discusión en parejas y revoto solo si el primer voto queda entre 30 % y 80 %;
explicación con la salida de `false_sharing` a la vista.

**Regla general en una frase** (escribirla en el pizarrón y dejarla): *"Una medición es: `-O2`, mediana de 5 tras
calentar, contra el mejor secuencial, con tamaño y afinidad declarados; y un speedup que no escala se explica con
uno de cuatro datos: la f medida, los GB/s, el costo por región o la línea de caché."*

Dos frases más antes de pasar: "Fuerte: mismo problema, más hilos. Débil: más problema, mismo tiempo por hilo"
y "`f_KF ≈ f` → ataca el código secuencial; `f_KF ≫ f` → el problema está dentro de la región".

### 75–85 · Transferencia (Fase 5 · Crear)

**Reto:** CSV + gráfica + Karp–Flatt del núcleo propio (Parte B de P4 o histograma de S07) con predicción previa.
**Criterio de listo:** el CSV abre en `graficar.py`, el PNG tiene la línea ideal, la tabla trae `f`, y hay tres
líneas que citan un número.

- **Quien no arranca:** "Abre `false_sharing.c`, copia el `main` hasta la primera llamada a `csv_append` y
  sustituye `count_seq`/`count_shared` por tus dos funciones. ¿Qué dos cosas necesita `csv_append`: el tiempo de
  referencia y qué más?" Dejar la pregunta y volver en 3 minutos. Pista sellada en `README.md`, Fase 5, paso 2.
- **Quien termina:** una `config` adicional (`schedule(dynamic,64)` o `relleno` vs. `local`) y explicar con
  Karp–Flatt cuál tiene más sobrecarga al crecer `p`. Si también termina: **CT3** en su mesa, explicado a la
  pareja de al lado.
- Si la práctica se alargó, este bloque se recorta (nunca Recuperación ni Cierre) y la Fase 5 pasa íntegra a la
  tarea espaciada (ya está escrita así: ejercicio 1 de `tarea-espaciada.md`).

### 85–90 · Cierre

1. **Exit ticket** (`exit-ticket.md`): 2 preguntas + confianza, individual, en hoja con número de lista. Se recoge
   al salir.
2. **Tarea espaciada** (`tarea-espaciada.md`): 20–40 min, individual; se entrega en
   `tareas/<usuario-github>/U3-S10.md` (CSV y PNG en `tareas/<usuario-github>/U3-S10/`) del repositorio del equipo
   antes del **lunes 26 de octubre de 2026, 10:30** (inicio de S11) y se autocalifica en los minutos 5–10 de S11.
3. **Anuncios**, con estas palabras: "El **martes 27 de octubre a las 08:30, en LS4**, es el Lab 2 de la Práctica
   4: traigan las **Partes C y D** avanzadas; la Parte D es exactamente este protocolo, con CSV y gráfica, y hay
   mini-defensas. El **jueves 29 de octubre** se recibe **H1** en clase: V1 secuencial, diseño de Foster y perfil
   por secciones como el de hoy. La Práctica 4 completa se entrega el **domingo 1 de noviembre a las 23:59**."
4. "Siguiente sesión: lunes 26 de octubre, 10:30, Salón 3208: patrones y `simd`. La pregunta 3 de la tarea es la
   entrada a ese tema."

## Diferenciación

- **Apoyo (quien no arranca en PRIMM):** entregarle impresa la tabla de la Fase 2 ya llena con los datos de
  autoría y pedirle que calcule a mano `E(4)` y `f_KF(4)` de `contiguo` y `relleno` antes de volver a la
  computadora; después hacer solo Ejecutar + Investigar 1, 2 y 5 (no requieren escribir código). En el ejemplo
  resuelto, el Hueco 1 se le da resuelto (`f = 0.101`) y resuelve solo los Huecos 2 y 3.
- **Ampliación (quien termina):** el problema sin ejemplo: medir `histogram_atomic` de S07 con `nbins = 4`, `64`
  y `4096`, explicar con Karp–Flatt y con la línea de caché por qué cambia la escalabilidad con el número de
  casillas (contención + falso compartido entre casillas vecinas), y proponer el relleno que lo corrige. CT3
  explicado a otra pareja.

## Evaluación formativa de la sesión

| Objetivo | Qué mira el profesor | Umbral de alerta |
|---|---|---|
| 1 (aplicar el protocolo) | CSV de `make medir` abierto en `graficar.py` en ≥ 80 % de las parejas; Fase 5 con CSV propio | < 60 % de las parejas con PNG al minuto 75 |
| 2 (S, E, E_w, Karp–Flatt) | Hueco 3; tabla de PRIMM; *exit ticket* 2 | > 30 % en "mal" en el *exit ticket* |
| 3 (Amdahl con f medida) | Huecos 1–2 dictados; CT1 revoto | Revoto CT1 < 70 % o > 20 % calcula `f` en líneas |
| 4 (diagnosticar la causa) | Respuestas a las preguntas socráticas #1, #7 y #8; CT2 | Revoto CT2 < 70 % o > 30 % votan A (carrera) |

Datos que se registran hoy en `docente/seguimiento-grupo.csv` (la hoja llena, que no se versiona;
`herramientas/seguimiento-grupo.csv` es solo la plantilla vacía): % aciertos retrieval 1, 2 y 3; % CT1 y CT2
(primer voto y revoto); montones del *exit ticket* (bien/parcial/mal).

## Notas post-sesión

Se llenan el mismo jueves 22 de octubre, después de clasificar los *exit tickets* (10 min):

- Qué falló en el tiempo (¿se recortó Transferencia? ¿cuánto? ¿Crear pasó a la tarea?):
- ConcepTest que falló y por qué (opción más votada entre los errados):
- Error más frecuente del *exit ticket* (abre la recuperación del lunes 26 de octubre):
- Máquinas del grupo: cuántas parejas con 2 núcleos físicos, cuántas sin `matplotlib`, cuántas sin afinidad, en cuántas `make afinidad` sí cambió el resultado (híbridos / *hyper-threading*):
- Cambio concreto para la próxima vez que se dé esta sesión:
