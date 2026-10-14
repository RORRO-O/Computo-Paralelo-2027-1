> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S06 · jueves 19 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S06 · Cierre de la Unidad IV: tipos derivados y comunicadores (panorama), errores clásicos de MPI; taller del proyecto rumbo a H2 (V2 con *speedup*)

**Tipo:** taller de proyecto (`02-plantilla-sesion.md`, variante 2.4) con el bloque de mini-lección ampliado a 25 min
(cierre de unidad; minutos 5–30): recuperación 5 · objetivos y anclaje 3 · mini-lección 22 (ejemplo resuelto + CT1 +
cazador de errores PRIMM, fases Predecir y Ejecutar) · taller hacia H2 50 (lista de cotejo, protocolo aplicado, revisión por pares, rondas del
profesor, CT2) · dos equipos muestran 5 · *exit ticket* 5. Está escrito para que lo dé otro profesor sin hablar con
el autor.

## Objetivos (al terminar, el estudiante podrá…)

1. **Describir** qué problema resuelven `MPI_Type_vector` (con `MPI_Type_commit`/`MPI_Type_free`) y
   `MPI_Comm_split`, y **predecir** qué procesos deben llamar a una colectiva sobre un comunicador derivado
   (nivel: comprender/aplicar).
2. **Diagnosticar** en un programa MPI de ≤ 60 líneas cuál de los errores clásicos tiene (orden de `Send`,
   colectiva por un subconjunto, cuenta que no coincide, etiquetas cruzadas, `Finalize` con pendientes, rango como
   índice, imprimir desde todos), **predecir** su síntoma (cuelgue / aborto / `FAIL` / "funciona por suerte") y
   **corregirlo** citando la regla que violaba (nivel: analizar/aplicar).
3. **Aplicar** el protocolo de medición a la tabla de *speedup* de la V2 (`T(1)` = V1, mediana de 5, `n` fijo,
   fila sobre-suscrita aparte, Karp–Flatt) y **detectar** sus violaciones en una tabla ajena con el revisor y la
   lista de cotejo (nivel: aplicar/evaluar).
4. **Cerrar** la lista de cotejo de H2 del equipo: decir qué piezas faltan al salir del jueves, quién las cierra y
   formular ≥ 1 pregunta concreta para "qué no entendemos todavía" (nivel: evaluar).

Dónde se evalúa: objetivo 1 → CT1, pausa 4 del ejemplo, tarea ej. 1a (I4); objetivo 2 → *exit ticket* 1, hoja de
predicciones del cazador, tarea ej. 1; objetivo 3 → *exit ticket* 2, CT2, lista 2.3 de la revisión por pares;
objetivo 4 → rondas del profesor (tabla de registro) y tarea ej. 3a.

## Prerrequisitos y vínculo

- **Viene de:** S05 (martes 17 de noviembre, Lab 2 de P5): modelo de costo `α + m/β`, escalabilidad fuerte y
  débil, sobre-suscripción, híbrido; la tarea de S05 pidió leer `MPI_Type_vector` y traer la tabla de *speedup* de
  la V2 tal como esté. También S02 (semántica de `MPI_Send`, emparejamiento, `MPI_Get_count`), S03 (colectivas las
  llaman todos), S04 (`Isend`/`Irecv`), U3 S10 y S12 (protocolo, Karp–Flatt, taller V1→V2).
- **Va hacia:** U5·S01 (lunes 23 de noviembre, 10:30, Salón 3208): recepción de H2 + modelo CUDA; se publica la
  Práctica 6. Práctica 5: domingo 22 de noviembre, 23:59. Examen 3 (martes 8 de diciembre): lectura de código MPI
  con tipos derivados y comunicadores, errores clásicos, tablas de *speedup*.
- **Ideas erróneas que esta sesión ataca** (Anexo A): **17** (`MPI_Send` "siempre regresa" / "siempre
  bloquea") → `caza1`, CT3, *exit ticket* 1-D; **18** ("solo la raíz llama a la colectiva") → `caza2`, CT1, pausa 4
  del ejemplo; **5** ("medir una vez basta") → CT2, revisor `E2`/`E3`, lista 2.3 ítem 2; **1** ("más hilos siempre
  es más rápido") → CT2-C, revisor `A1`/`A6`, *exit ticket* 2c. De paso: **20** (sobre-suscripción), **31**
  (`T(1)` = V2 con un hilo) y **6** (fuerte/débil) en la recuperación y el revisor.
- **Nivel de andamiaje:** con pistas (`07-guia-de-autoria.md` §A.5; última sesión de la unidad). El ejemplo
  resuelto está completo porque presenta dos constructos nuevos de panorama; el desvanecimiento está en la
  práctica: los cazadores son problemas con pistas de lectura y sin solución, y el taller es el problema libre (el
  proyecto). Las cinco fases de PRIMM se reparten: Predecir y Ejecutar en clase, Investigar, Modificar y Crear en
  la tarea (lo declara el README).

## Materiales

- Esta carpeta, compilada **antes** de la sesión en la máquina del salón: `cd practica-guiada && make && make
  test` (22 PASS, 0 FAIL, 4 SKIP; ~35 s porque cuatro casos esperan el `timeout 10`; `make listo` con las
  correcciones hechas tarda ~55 s). Como root exportar
  `OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1` (el `Makefile` ya lo hace). Dejar corrido `make
  revisar` y tener `ejemplo_mediciones_mal.csv` abierto para proyectarlo.
- Dos terminales: una en `practica-guiada/` para el ejemplo y `make sintomas`; otra para los comandos cortos de
  la Fase 2 del README.
- Proyector, cronómetro visible, tarjetas con números de lista, pizarrón con tres cosas escritas desde el inicio:
  el encabezado del CSV del protocolo, "P5: dom 22 nov 23:59" y "H2: lun 23 nov, etiqueta antes de 10:30".
- `proyecto/hitos/H2-avance-2.md` abierto (§5 lista de cotejo, §6 preguntas de la recepción, §8 opciones de
  logística). **Decidir antes de la sesión** la opción A/B/C de H2 §8 para anunciarla hoy (lo pide ese documento).
- Estudiantes: una laptop por pareja con `mpicc` funcionando (la misma con la que corrieron la Práctica 5 en S05); cada equipo del proyecto con su repositorio
  de V2 y su CSV de mediciones tal como esté (lo pidió la tarea de S05, ej. 3.2). Hoja con los dos números de
  lista para las predicciones del cazador (se recoge con el *exit ticket*).

## Guion minuto a minuto

### 0–5 · Recuperación

Proyectar las 5 preguntas de `retrieval-inicio.md`. Individual, sin apuntes, 4 min. Al minuto 4, respuestas y
manos por pregunta; anotar el conteo de las preguntas 1 y 2.

- Si la pregunta 1 (fuerte/débil) queda bajo 60 %: al arrancar el taller (minuto 30) se proyectan las dos
  definiciones junto al CSV y el ítem se repite con pista el lunes 23.
- Pregunta 3 (eficiencia y Amdahl): quien no llega a 0.75 y ≈ 3.5 es candidato a la fila "Apoyo" en el taller.
- Pregunta 4 verifica la tarea de S05: basta el orden de magnitud (≈ 1 µs las dos cosas).

### 5–8 · Objetivos y anclaje

Autocalificación de la tarea de S05 con su clave (2 min; el profesor registra entrega). Proyectar los cuatro
objetivos. Frase de anclaje: "El martes el error más frecuente del *exit ticket* fue [sustituir por el error
registrado en las notas post-sesión de S05; si no se tiene: *calcular el speedup contra `mpi,1` en vez de contra
la secuencial*]. Hoy cerramos MPI con dos herramientas que van a leer en el examen y con los siete errores que
van a cometer en cualquier código MPI, y después usamos los 50 minutos que quedan para que el lunes la tabla de
H2 no tenga ese error." Vínculo con el proyecto: "la pregunta 1 de la recepción del lunes es '¿qué midieron?'; hoy
la ensayan con otro equipo antes que conmigo."

### 8–30 · Mini-lección de cierre (22 min)

| Minuto | Qué se hace | Qué se dice / pausa |
|---|---|---|
| 8–13 | Proyectar `ejemplo_columna_split.c` líneas 44–61 y 82–88. Correr `mpirun -np 4 ./ejemplo_columna_split` y leer la Parte A. Pensar en voz alta: "una columna son 4 bloques de 1, separados 4; eso es lo único que le digo a MPI". | Pausa 1 (fila y diagonal; al azar por tarjeta). Pausa 2 (firma vs. acomodo): "¿por qué recibir `4, MPI_DOUBLE` no es un error de tipos?" Correr `--sin-commit`: `MPI_ERR_TYPE`. "Este error avisa; apunten cuáles no avisan." |
| 13–16 | Proyectar líneas 103–114. Leer la Parte B de la misma salida (sumas 1 y 5) y correr `-np 6` (sumas 3 y 12). | "`color` junta, `key` ordena. `Comm_split` lo llaman los `p`; el `Allreduce` lo llaman los del comunicador." Pausa 4 solo si no se vota CT1 por tiempo. |
| 16–20 | **CT1** (`conceptests.md`): voto → parejas → revoto → explicación. | Guion de CT1. Cerrar con el Hueco 3: comunicador equivocado = `FAIL` sin cuelgue ni aborto. |
| 20–22 | Proyectar la tabla de `notas-estudiante.md` §4 (siete errores). Correr `-np 3`: el programa rechaza la malla. | "Tres de estos siete los van a cazar ahora; los otros cuatro los escriben ustedes para su pareja en la tarea. Los peores son los que no avisan: filas 4 con `n` chico, 6 y 7." |
| 22–30 | **Cazador de errores PRIMM, Parte 1 del README.** 22–26 Predecir: por escrito, en la hoja de la pareja, sin ejecutar; el navegante escribe. Si al minuto 25 no han leído los tres programas, marcan solo la casilla del síntoma de cada uno; la línea del error se completa en Investigar (tarea). 26–29 Ejecutar: `make sintomas` proyectado (10 s de espera por cada cuelgue, el `timeout 10`: usar ese tiempo para preguntar "¿quién predijo cuelgue?") y los cuatro comandos con `n` chico. 29–30 manos: "¿quién acertó los tres síntomas? ¿quién predijo que `caza1` con `n = 100` también se colgaba?" | Lo que se dice al final, una vez: "`caza1` y `caza3` *funcionan* con datos chicos. Eso es lo que su `make test` de la V2 tiene que atrapar: carreras que *salen bien una vez*. Investigar, Modificar y Crear son el ejercicio 1 de la tarea." |

Qué **no** hacer: no corregir los cazadores en vivo (es la tarea); no entrar en `MPI_Type_create_resized` salvo que
lo pregunten (es la pausa 3, en `<details>`); no explicar CUDA aunque pregunten por la tarea 3b ("el lunes").

### 30–80 · Taller del proyecto rumbo a H2 (50 min; Parte 2 del README)

**30–36 · Protocolo aplicado y revisor (6 min).** Proyectar el cuadro 2.2 del README ("en una pantalla") y
dejarlo visible el resto del taller. Proyectar `ejemplo_mediciones_mal.csv`: "dos minutos, en parejas, encuentren
los cinco errores a ojo" (sin ayuda del revisor). Pedir por tarjeta uno por pareja hasta juntar los cinco (E1 falta
V1; E6 normalizado contra `V2,1`; E2 tres repeticiones; E3 promedio con pico; E5 `n` cambia). Después `make
revisar`: el programa encuentra los mismos cinco y tres avisos. "Lo que el revisor **no** ve está en la lista 2.3:
eso lo revisa otro equipo."

**36–62 · Trabajo por equipos con la lista de cotejo 2.1 (26 min).** Instrucción: "Marquen en orden del 1 al 8;
cuando pase les pregunto en qué número van y las dos preguntas fijas." Cada equipo corre el revisor sobre **su**
CSV (ítem 3) en los primeros 5 minutos; los que no tienen CSV usan `ejemplo_mediciones_ok.csv` para llenar la
tabla de Karp–Flatt y pasan el resto del tiempo generando el suyo con `run_all.sh`. Roles conductor/navegante
dentro del equipo; cambio al minuto 50.

**Rondas del profesor, 3 min por equipo, en orden de tarjeta, del minuto 36 al 74** (con 12 equipos caben todos;
con más, los que falten se reciben en la ronda del lunes primero). Dos preguntas fijas, siempre las mismas:

1. **"¿Qué midieron?"** → gráfica o tabla en pantalla; `T(1)`, `S(4)`, `E(4)`, `f(4)` de memoria.
2. **"¿Qué no entienden todavía?"** → una pregunta concreta de `reporte/H2.md`. Si no hay ninguna escrita, se les
   dicta el primer pendiente: escribirla.

Se anota en la tabla de registro de abajo. No se corrige código en la ronda: se deja una pregunta y se sigue.

**62–72 · Revisión por pares de la tabla de *speedup* (lista 2.3; 10 min).** Intercambio con el equipo vecino: CSV
+ gráfica + las 3–6 líneas de interpretación. 8 min de revisión con los seis ítems (✓ / ✗ / "no se puede saber" y
una observación por ✗), 2 min de devolución. Las rondas del profesor continúan. Quien no tiene tabla propia revisa
la de otro equipo igual: es la parte que más enseña.

**72–76 · Atender observaciones (4 min).** Cada equipo anota en su bitácora qué cambia a raíz de la revisión (o
por qué no) y actualiza el número de la lista 2.1 en el que va. El profesor cierra las rondas pendientes.

**76–80 · CT2 (voto único).** `conceptests.md`, CT2: la tabla que "escala hasta 8". Discusión en parejas y revoto
solo si el primer voto queda entre 30 % y 80 %. Regla general en el pizarrón, debajo del CSV: *"Sin `T(1)` = V1,
sin mediana de 5 y sin marcar la fila sobre-suscrita, la tabla no es evidencia: es una anécdota."*

### 80–85 · Dos equipos muestran su avance

Dos equipos por tarjeta (de preferencia uno con revisor en `0 errores` y uno con un `ERROR` ya corregido hoy):
2 min cada uno con la gráfica en pantalla, respondiendo solo las dos preguntas fijas. El grupo marca en silencio
los ítems 1, 4 y 5 de la lista 2.3; el profesor pide un ✗ a una pareja al azar (1 min). Es el ensayo de la ronda
del lunes.

### 85–90 · Cierre

1. **Exit ticket** (`exit-ticket.md`): 2 preguntas + confianza, individual, en la misma hoja de la recuperación; se
   recoge con la hoja de predicciones de la pareja.
2. **Anuncios**, escritos en el pizarrón:
   - **Práctica 5**: vence el **domingo 22 de noviembre, 23:59**, en el repositorio del equipo (15 % del 3er
     parcial).
   - **H2**: etiqueta `H2` antes de las **10:30 del lunes 23 de noviembre**; recepción en clase (15 puntos del
     proyecto). Decir la opción elegida de H2 §8: "la recepción se hace así: ______" (A: ronda de 90 s en clase y
     pregunta individual en el laboratorio del martes 24; B: hoy quien ya tenga etiqueta; C: 35 min de recepción).
     Retroalimentación escrita a más tardar el lunes 30 de noviembre.
   - **Lunes 23 de noviembre, 10:30, Salón 3208, inicia la Unidad V** (GPU/CUDA): traer cuenta de Google con
     Colab probado (tarea, ej. 3b). Ese día se publica la **Práctica 6**; su pre-laboratorio exige GPU verificada
     en Colab y Kaggle antes del martes 24 de noviembre, 08:30.
   - **Tarea espaciada** (`tarea-espaciada.md`): 20–40 min; el ejercicio 3 es la última revisión de H2. Entrega
     en `tareas/U4-S06/` antes del lunes 23, 10:30. Sin peso propio; alimenta el examen de práctica del 3 de
     diciembre y el Examen 3.

## Lista de errores esperados (y la pregunta que se hace ante cada uno)

| # | Error esperado | Pregunta socrática |
|---|---|---|
| **Cazador de errores** | | |
| 1 | Predicen que `caza1` termina siempre "porque `Send` es asíncrono" (o que se cuelga siempre). | "¿Qué promete `MPI_Send` según S02 §4? Si el mensaje no cabe en el búfer interno, ¿quién está en `Recv` para recibirlo?" |
| 2 | "`caza1` con `n = 100` funcionó, entonces el error es de memoria con `n` grande." | "Describe la secuencia de eventos con `n = 100`. ¿Dónde está el mensaje mientras los dos están en `Send`? ¿Y con 8 MB?" |
| 3 | Predicen que `caza2` se cuelga siempre; les sorprende `suma=1200`. | "¿Qué contiene `x` en el rango 2 cuando llega al ciclo? ¿Qué índices suma el rango 0? ¿Por qué con `n = 2²⁰` sí se cuelga?" |
| 4 | "MPI debería dar error si falta una colectiva" (también para etiquetas cruzadas). | "¿Cómo sabría el rango 0 que los otros tres *nunca* van a llamar? ¿Cuánto tiempo tendría que esperar para estar seguro?" |
| 5 | En `caza3` concluyen "funciona si `n` es divisible entre `p`" y lo dan por regla. | "¿Y con `n = 5`? Corre. ¿Qué tienen en común 8 y 5 que no tiene 10? ¿Dónde queda el residuo?" |
| 6 | Quieren corregir `caza1` bajando `n` o `caza3` recibiendo con capacidad `n` "por si acaso". | "¿Es correcto un programa que funciona hasta cierto `n`? Si recibes con capacidad `n`, ¿cómo sabes cuántos llegaron para avanzar `offset`?" |
| 7 | En CT1 votan A: "la colectiva la llaman los cuatro". | "¿Sobre qué comunicador está la llamada del rango 3? ¿Quiénes están en él?" |
| **Taller** | | |
| 8 | La tabla está normalizada contra `V2,1`; "no tenemos V1 medida al mismo `n`". | "¿Qué dice el protocolo que va en el numerador? ¿Cuánto tarda correr V1 cinco veces con `run_all.sh -e V1`?" |
| 9 | Promedio en lugar de mediana; una corrida por configuración "porque tarda mucho". | "¿Qué hace un pico de 0.65 s con el promedio de cinco corridas de 0.22? ¿Cuánto tarda la tabla completa con `n` declarado?" |
| 10 | La fila de 8 hilos en la curva y "escala hasta 8" (o "la V2 está mal porque 8 no mejora a 4"). | "¿Cuántos núcleos físicos dice `lscpu`? ¿Qué hacen los hilos 5–8? ¿Cómo marca el protocolo esa fila?" |
| 11 | Cambian `n` respecto a H1 "porque así escala mejor". | "¿Lo declararon? ¿Repitieron el perfil de V1 al nuevo `n`? Si no, ¿contra qué comparan `f(p)` con `f_H1`?" |
| 12 | Interpretación: "deja de escalar por la sobrecarga". | "¿Qué sobrecarga? ¿Cuál número de tu tabla o qué experimento la muestra? ¿`f` crece con `p`?" |
| 13 | El revisor dice `0 errores` y lo toman por "ya está". | "¿Qué tres cosas dice el encabezado del revisor que no puede ver? ¿Quién las revisó?" |
| 14 | `make test` de V2 compara con un solo número de hilos o una sola repetición; `num_threads(4)` fijo en el código. | "¿Cómo va a medir `run_all.sh` con 1, 2 y 8? ¿Qué dice H2 §2.1 sobre repetir cada caso?" |
| 15 | `V2,1` más lenta que `V1` y lo esconden ("se ve mal"). | "¿Qué es esa diferencia? ¿Qué dice H2 §2.2 de la fila `V2,1`? ¿Qué decisión de la V2 la explica?" |
| 16 | Mediciones de dos máquinas en una tabla; `entorno.txt` sin núcleos físicos. | "¿La fila de 2 hilos y la de 4 se midieron en la misma máquina? ¿Qué dice `entorno.txt`?" |
| 17 | En la revisión por pares marcan todo ✓ en 2 minutos. | "¿Dónde está la frase 'antes de medir esperábamos…'? ¿Qué número respalda el ítem 4? Enséñame el `rep3` de la fila de 4." |
| 18 | "Qué no entendemos todavía" vacío o genérico ("optimizar más"). | "¿Qué número de su tabla no pueden explicar hoy? Esa es la pregunta. Escríbanla tal cual." |

## Diferenciación

- **Apoyo (quien no arranca).** Cazador: entregar `caza2_bcast_solo_raiz_buggy.c` impreso con la línea 31–35
  marcada y pedir solo la predicción del síntoma con `n = 100` y con `n = 2²⁰` (la pista sellada del README, "¿quién
  llama a la colectiva?", ya señala la línea). Taller: el equipo sin CSV propio llena la tabla de Karp–Flatt de H2
  §2.3 con `ejemplo_mediciones_ok.csv` (la tabla ya calculada por el revisor) y una `f_H1` supuesta de 0.03, con
  la lectura argumentada; después genera su CSV con `run_all.sh` siguiendo el cuadro 2.2 del README línea por línea.
- **Ampliación (quien termina).** Sin ejemplo: (a) escribir `caza4_*_buggy.c` en clase (fase Crear) y dárselo a
  la pareja vecina; (b) resolver la pausa 3 del ejemplo en código: enviar las columnas 1 y 2 con `count = 2` usando
  `MPI_Type_create_resized`, verificar contra la matriz; (c) revisar la tabla de un segundo equipo con la lista 2.3
  y comparar sus observaciones con las del primer revisor.

## Evaluación formativa de la sesión

| Objetivo | Qué mira el profesor | Umbral de alerta |
|---|---|---|
| 1 (tipos derivados y comunicadores) | Revoto de CT1; respuesta a la pausa 4; en la tarea, I4 y Hueco 3 | Revoto CT1 < 70 % |
| 2 (diagnosticar errores clásicos) | Hoja de predicciones: tres síntomas acertados (y "funciona por suerte" en `caza1` con `n = 100`); *exit ticket* 1 | Más de un tercio predice "MPI aborta" en `caza2` o en el *exit ticket* 1-A; > 30 % "mal" en el *exit ticket* |
| 3 (protocolo aplicado a la V2) | Los cinco errores del CSV encontrados a ojo antes del revisor; CT2; lista 2.3 con ✗ argumentados; *exit ticket* 2 | CT2 < 70 % en el primer voto; más de 3 equipos con `E1` o `E6` en su CSV al minuto 60 |
| 4 (cerrar la lista de H2) | Tabla de registro de las rondas: número de la lista 2.1 alcanzado y la pregunta concreta de "qué no entendemos" | Equipos en el ítem ≤ 3 al minuto 74, o sin pregunta escrita |

Registro de las rondas (llenar en clase):

| Equipo | Ítem de la lista 2.1 en que va | `T(1)`, `S(4)`, `E(4)`, `f(4)` dichos de memoria | Revisor: errores / avisos | Pregunta concreta de "qué no entendemos" | Pendiente para el lunes |
|---|---|---|---|---|---|
| | | | | | |

Datos que se registran hoy en `herramientas/seguimiento-grupo.csv`: % aciertos de recuperación 1 y 2, % CT1
(primer voto y revoto), % CT2, montones del *exit ticket* (bien/parcial/mal), equipos con revisor en `0 errores`
al salir.

## Notas post-sesión

Se llenan el mismo jueves 19 de noviembre, después de clasificar los *exit tickets* (10 min):

- Qué falló en el tiempo (¿se recortó la revisión por pares? ¿cuántos equipos quedaron sin ronda?):
- ConcepTest que falló y por qué (opción más votada entre los errados):
- Error más frecuente del *exit ticket* (abre la recuperación del lunes 23 de noviembre, U5·S01):
- Equipos con `ERROR` en el revisor al salir (seguimiento el lunes en la recepción):
- Opción de H2 §8 anunciada: ______ · Cambio concreto para la próxima vez que se dé esta sesión:
