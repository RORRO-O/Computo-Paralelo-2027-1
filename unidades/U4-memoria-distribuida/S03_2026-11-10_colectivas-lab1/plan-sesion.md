> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S03 · martes 10 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# S03 · Operaciones colectivas (`Bcast`, `Scatter`, `Gather`, `Reduce`, `Allreduce`, `Allgather`, `Barrier`) y producto matriz-vector distribuido · Práctica 5 · Laboratorio 1 (Partes A y B)

Tipo: **laboratorio** (variante 2.1 adaptada; caso "constructo nuevo en Lab 1" de `02-plantilla-sesion.md` §2.1):
recuperación 5 min · objetivos 3 min · mini-lección 22 min (ejemplo resuelto corto con pausas, ConcepTest 1 y
la variante que falla) · bloque de laboratorio 48 min (= PRIMM corto de 20 min con `practica-guiada/` +
Práctica 5 Partes A y B de 28 min con mini-defensas) · punto de control 7 min con ConcepTest 2 · *exit ticket*
5 min. Suma 90. Este plan debe poder darlo otro profesor sin hablar con el autor: trae las frases clave, las
salidas reales y las soluciones de referencia.

## Objetivos (al terminar, el estudiante podrá…)

1. **Elegir** la colectiva adecuada entre `Bcast`, `Scatter`/`Scatterv`, `Gather`/`Gatherv`, `Reduce`, `Allreduce`,
   `Allgather` y `Barrier` para una situación dada, contestando "¿quién tiene el dato antes y quién lo necesita
   después?", y **escribir** la llamada completa con cuentas por rango en elementos. (aplicar) → *exit ticket* P2,
   tarea 1(a), ConcepTest 3.
2. **Explicar** por qué una colectiva la llaman todos los procesos del comunicador y **predecir** los dos síntomas
   de una colectiva dentro de `if (rank == 0)` (cuelgue o resultado incorrecto silencioso), relacionándolos con
   el límite *eager* de S02. (comprender / analizar) → ConcepTest 1, *exit ticket* P1, fases I3–I4.
3. **Rastrear**, dados `n` y `p`, qué filas de `A` y qué bloque de `y` corresponden a cada rango en el producto
   matriz-vector por filas, y **verificar** la versión MPI contra la secuencial con `make test`. (aplicar) →
   predicción P1, tabla I1, M1, punto de control.
4. **Leer** un desglose de tiempos (`scatter`/`bcast`/`calcular`/`gather`) y **decidir** si la comunicación domina
   y cuándo se amortiza, como preparación de la Parte D de la Práctica 5. (analizar / evaluar) → ConcepTest 2,
   medición de la práctica guiada, tarea 2.

## Prerrequisitos y vínculo

- **Viene de:** S02 (lunes 9 de noviembre): `Send`/`Recv`, etiquetas, semántica de `MPI_Send`, límite *eager*
  (4 096 bytes en la máquina de autoría), interbloqueo, *ping-pong*. La tarea de S02 (ejercicio 3) ya les pidió
  conjeturar por qué `Bcast` la llaman todos y cuánto gana un árbol frente a `p − 1` envíos. S01: SPMD,
  `Comm_rank`/`Comm_size`, reparto por bloques con residuo. U3 S07 (15 de octubre): `reduction` (la recuperación
  lo usa como puente a `Reduce`). U2: método de Foster (partición por filas, comunicación, aglomeración, mapeo).
- **Va hacia:** S04 (jueves 12 de noviembre, 10:30, Salón 3208): descomposición de dominio y halos en Jacobi 1D,
  `Isend`/`Irecv`/`Wait`, paro global con `Allreduce(MPI_MAX)`; ahí también se da la retroalimentación del
  Examen 2. S05 (martes 17 de noviembre, 08:30, Lab LS4): Lab 2 de la Práctica 5 (Partes C y D, mediciones,
  mini-defensas pendientes), modelo latencia + ancho de banda. Práctica 5: domingo 22 de noviembre, 23:59, 15 %
  del 3er parcial. H2 (V2 con *speedup*): lunes 23 de noviembre. Examen 3: martes 8 de diciembre.
- **Ideas erróneas que esta sesión ataca** (Anexo A): **18** ("solo el proceso raíz llama a `MPI_Bcast`") →
  ConcepTest 1 (A), `matvec_bcast_buggy` (P6–P7, I3–I4), *exit ticket* P1 (B/D), ConcepTest 3 (C), pausas 3, 5 y 6;
  **16** ("los procesos MPI comparten memoria") → ConcepTest 1 (B), pausa 1, I5, *exit ticket* P1 (C), ConcepTest
  3 (D); **21** ("la comunicación es gratis") → ConcepTest 2 (A), pausa 7, sección Medición, tarea 2. De paso:
  **19** (el 0 no tiene que ser el maestro) → M2; **1** (más procesos siempre es más rápido) → ConcepTest 2 (D);
  **17** → recuperación 2; **20** → tarea 2(c); **10** → tolerancia de `make test`.
- **Nivel de andamiaje** (07 §A.5 y 02 §2.1, constructo nuevo en Lab 1): **completo**. Ejemplo resuelto completo
  con 7 pausas de autoexplicación; PRIMM con las cinco fases comprimido a 20 min (Modificar es un cambio de una
  línea con `TODO(1)`; Crear da la especificación y el criterio, no la estructura). Las colectivas entran en la
  Parte A de la Práctica 5 como código completo para leer y predecir, nunca como `TODO` en la Parte B de hoy.

## Materiales

- Esta carpeta completa, compilada **antes** de la sesión en la máquina del laboratorio:
  `cd practica-guiada && make clean && make && make test` → `15 PASS, 0 FAIL, 3 SKIP` (~25 s; los SKIP son
  `matvec_allgather` ×2 y `norma_allreduce`). Dos terminales abiertas en `practica-guiada/`.
- Comprobar en esa máquina que `make run-buggy N=8` termina con `checksum = 372.000000` y que
  `make run-buggy N=1024` da `codigo de salida: 124`. Si con 1 024 **no** se cuelga, subir a `N=8192`; si
  tampoco, esa implementación copió el mensaje: decirlo tal cual en el minuto 28 y usar la salida real de
  `ejemplo-resuelto.md` §7.
- Anotar el límite *eager* local: `ompi_info --param btl vader --level 4 | grep eager_limit` (autoría: 4096).
  Con MPICH el comando no existe; se omite I4 y se queda el umbral que encuentren.
- Como root (contenedor): `export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1`; `--oversubscribe`
  ya va en el `Makefile`.
- Proyector; cronómetro visible; tarjetas con números de lista; tarjetas A/B/C/D; caja para los pre-lab en la
  entrada; media hoja por estudiante para el *exit ticket*.
- `practicas/P5-mpi/README.md` abierto y su rúbrica impresa (para las mini-defensas). Si hay más de 12 equipos,
  la lista de quién se defiende hoy y quién el martes 17.
- *Exit tickets* de S02 clasificados; el error más frecuente anotado aquí: ______________________ (si no hay
  datos, el anclaje por defecto es la idea 17: "con mensajes chicos sí está bien").
- Calificación y clave del Examen 2: `04-evaluacion.md` §2.3 fija "a más tardar el martes 10 de noviembre";
  confirmar que están publicadas para anunciarlo en el cierre.

## Guion minuto a minuto

### 0–5 · Recuperación (y recogida del pre-lab)

Los pre-lab van a la caja al entrar; no se recibe después del minuto 5 (se entregaron también en el repositorio
del equipo, `practicas/P5/prelab/`, antes de las 08:30: eso es lo que cuenta). Proyectar `retrieval-inicio.md`
(5 preguntas). Individual, sin apuntes, 4 minutos. Al minuto 4, respuestas; manos por pregunta; anotar el conteo
de la 2 y la 4.

- Respuestas esperadas: 1) su propia predicción (se registra sí/no, no se lee); 2) (b): solo garantiza que el
  búfer es reutilizable; 3) el mensaje único, ≈ 30 veces más barato; 4) cinco copias, se combinan al final;
  5) conteo de manos por opción (1/1 · 1/4 · 4/4 · no sé), sin corregir.
- Si la 2 queda < 60 %: **no** se reexplica hoy (no hay tiempo en la variante de laboratorio); se repite con
  pista en la recuperación de S04 y se anota en "Notas post-sesión".
- La 4 es el gancho: "quien escribió que se combinan al final: eso, entre procesos, se llama `MPI_Reduce`; en diez
  minutos lo ven correr".
- La 5 se deja en el pizarrón con el conteo: quien escribió 1/1 trae la idea 18; se retoma en el ConcepTest 1.

### 5–8 · Objetivos y anclaje

Frase de arranque: "Ayer un proceso le mandó algo a otro. Hoy un proceso le manda algo a **todos**, o todos a
uno, o todos a todos, con una sola línea. El error más frecuente del *exit ticket* de ayer fue ______ [o: creer
que si el programa funcionó con mensajes chicos está bien]. Hoy ese mismo límite de 4 096 bytes decide si un
error de hoy se ve como cuelgue o como basura silenciosa."

Proyectar los cuatro objetivos. Vínculo con la práctica y el proyecto: "La Parte A de la Práctica 5 usa las colectivas
de hoy sobre un arreglo y la Parte B es el matriz-vector de hoy con filas desiguales; la Parte D va a medir exactamente lo que vamos a leer en el punto de control: cuánto cuesta repartir los datos.
En la V2 del proyecto la pregunta es la misma con hilos: ¿cuánto trabajo hay por cada dato que se mueve?"

### 8–30 · Mini-lección: colectivas y la regla de oro (ejemplo resuelto corto + ConcepTest 1 + variante que falla)

Seguir `ejemplo-resuelto.md`. El profesor **piensa en voz alta**: qué mira, qué descarta, por qué. En cada pausa,
30 s en parejas y una tarjeta al azar ("¿qué concluyó tu pareja?").

| Minuto | Qué se hace | Qué se dice |
|---|---|---|
| 8–11 | Pizarrón: la pregunta "**¿quién tiene el dato antes y quién lo necesita después?**" y, debajo, la tabla de las siete colectivas (`notas-estudiante.md` §2), fila por fila: uno → todos (`Bcast`, `Scatter`), todos → uno (`Gather`, `Reduce`), todos → todos (`Allgather`, `Allreduce`), nadie avanza (`Barrier`). | "Una colectiva no es un `Send` con destino 'todos'. Es una cita: la llamada describe la operación completa y **cada** proceso ejecuta su parte. Se escribe una vez, fuera de cualquier `if (rank == …)`." Señalar `sendcount`: "por rango, en elementos". |
| 11–15 | Correr en vivo `mpirun -np 4 ./colectivas_demo` dos veces. Las líneas salen mezcladas: decirlo. Leer agrupado por rango (§4 del ejemplo). **Pausa 1** (`squares = {-1,-1,-1,-1}` tras `Gather` en el rango 1). | "Hay cuatro `squares`, uno por proceso. `Gather` y `Reduce` dejan el resultado **solo** en la raíz; `All…` lo deja en todos. Que todos la llamen es la condición para que ocurra; dónde queda el resultado lo define cada colectiva." |
| 15–21 | Proyectar `matvec_collectives.c` líneas 54–85 (solo las colectivas). Correr `mpirun -np 4 ./matvec_collectives 8 1 filas`. Señalar "empieza: 4 5 6" en el rango 2 y `x[0] = 1` en los cuatro. **Pausa 2** (`sendcount = local_n * n`), **Pausa 3** (la línea del `Bcast` en el rango 2: ¿envío o recepción?), **Pausa 4** (`MPI_MAX`). Una pantalla con el bloque de `Send`/`Recv` de `matvec_p2p.c` al lado; **Pausa 5** en una frase. | "Misma línea, dos papeles: en la raíz es la fuente; en los demás, el destino. El rango 2 **tiene** que ejecutarla: nadie más va a escribir en su `x`." Sobre p2p: "tres llamadas por rango contra seis envíos y tres recepciones en el 0; y aquí el `if` es normal porque cada lado hace algo distinto; en una colectiva el `if` quita la recepción." |
| 21–27 | **ConcepTest 1** (`conceptests.md`): voto → parejas → revoto → explicación. Esperado 45–55 % en el primer voto; A es el distractor fuerte (idea 18), B la idea 16, D "MPI lo detecta". Si el primer voto > 80 %, saltar la discusión y ganar 3 min para la práctica. | Guion de discusión de CT1: "Quien votó A: señala la línea que ejecuta el rango 2 para *recibir* `x`." (No hay.) "Quien votó D: ¿cómo sabría el rango 0 que los otros tres no van a llamar nunca?" |
| 27–30 | **Variante que falla, en vivo**: `make run-buggy N=8` (termina: `y[2..7] = 0.0`, `checksum = 372`) y `make run-buggy N=1024` (10 segundos de silencio hasta `codigo de salida: 124`: vale la pena). Mencionar el umbral (4 032 termina, 4 064 se cuelga) y el `eager_limit` de ayer. **Pausa 6**. Escribir la regla y dejarla todo el día. | Regla en el pizarrón: **"Una colectiva la llaman TODOS los procesos del comunicador. Si uno falta, no hay aviso: los demás esperan para siempre o siguen con datos que no son."** Cerrar: "El cuelgue es el síntoma bueno: se nota. El resultado incorrecto llega al reporte. La medición (Paso 5 del ejemplo) la leemos en el punto de control." |

Qué **no** hacer: no teclear código nuevo en vivo (solo correr el que existe); no explicar `Sendrecv`,
`Isend`/`Irecv` ni halos aunque pregunten ("el jueves 12"); no entrar en `Scatterv` más allá de "existe, y
`matvec_scatterv.c` lo muestra" (es M3, opcional).

### 30–50 · Práctica guiada PRIMM corto (`practica-guiada/README.md`)

**Arranque (30–31).** Parejas (por nivel adyacente del diagnóstico, como se reformaron en S01); conductor
y navegante; `make` ya corrido. "Fase 1, Predecir, por escrito, 3 minutos, sin correr nada. Siete filas.
El navegante escribe." Cambio de roles al minuto 40 (anunciarlo en voz alta).

- **31–34 Predecir** (P1–P7). El profesor circula y lee predicciones; no corrige. Si una pareja escribe en P2
  "1 / 1" o en P4 "ocho", anotarlo para la puesta en común.
- **34–38 Ejecutar.** Los siete comandos en orden; llenar "Observado" y "¿Coincide?". Las dos corridas de
  `matvec_bcast_buggy` **siempre** con `timeout`.
- **38–43 Investigar.** Orden: I1 (tabla de reparto, incluida la columna de `-np 2`) → I3 (regla de oro línea por
  línea) → I5 (qué deja cada colectiva). I2 e I4 si alcanza; si nadie llegó a I4, el profesor muestra el ciclo
  del umbral en el punto de control (20 s).
- **43–47 Modificar.** M1 obligatorio (`TODO(1)` → `MPI_Allgather`; `make test` debe pasar los dos casos de
  `matvec_allgather`). M2 y M3 solo para quien termina.
- **47–50 Crear (arranque).** Leer la especificación de `norma_allreduce.c` y escribir al menos la llamada a
  `MPI_Allreduce`. Al minuto 49, en voz alta: "Lo que no terminen de Crear es el ejercicio 1(b) de la tarea;
  `make test` les dice cuándo está (tres `PASS` de `norma_allreduce`)."

**Lista de errores esperados.** El profesor circula con esta tabla; ante cada error, **una pregunta**, no la
respuesta:

| # | Error esperado | Pregunta socrática |
|---|---|---|
| 1 | P2: "`MPI_Scatter` aparece una vez y la ejecuta un proceso" (idea 18) | "¿Cuántos procesos corren este archivo con `-np 4`? ¿Cuál de ellos se salta esa línea? Señala el `if`." |
| 2 | P4: "el rango 3 tiene los 8 elementos de `y`" (idea 16) | "¿Qué vale el puntero `y` en el rango 3? Busca el `alloc`. ¿Quién es la raíz del `Gather`?" |
| 3 | P6: "con 8 también se cuelga" o P7: "con 1 024 también termina" | "¿Qué tamaño tenía el mensaje que ayer hizo que `MPI_Send` regresara sin receptor? ¿Cuántos bytes son 8 `double`? ¿Y 1 024?" |
| 4 | Corren `matvec_bcast_buggy` sin `timeout` y creen que la máquina se trabó | "¿En qué llamada está **cada** proceso ahora mismo? Dibújalos. ¿Qué código regresa `timeout` cuando lo mata?" |
| 5 | I1: ponen en "bloque de `y`" el mismo rango para `-np 2` que para `-np 4` | "¿Cuántas filas le tocan a cada rango con `p = 2`? ¿Dónde cae el bloque del rango 1 dentro de `y`?" |
| 6 | I3: clasifican los `Send`/`Recv` de `matvec_p2p.c` como "error: están dentro de un `if`" | "¿Los dos lados de un `Send`/`Recv` hacen lo mismo? ¿Y los dos lados de un `Bcast`? ¿Cuál de las dos llamadas ya trae los dos papeles dentro?" |
| 7 | I5: "la `Barrier` ordena las líneas impresas" | "Mira las cuatro líneas `Barrier:` de tu salida: ¿salieron en orden? ¿Qué sincroniza una barrera: el avance o la pantalla?" |
| 8 | M1: dejan `root` como séptimo argumento de `MPI_Allgather` (no compila) o ponen `MPI_COMM_WORLD` en el lugar del `recvcount` | "Lee la firma en el comentario del archivo: ¿cuántos argumentos tiene? ¿Cuál desapareció respecto a `Gather`?" |
| 9 | M1: `make test` dice *se colgó: ¿todos los rangos llaman a la misma colectiva?* | "¿Dejaste el `Gather` y agregaste el `Allgather` solo en algunos rangos? ¿Cuántas colectivas ejecuta ahora el rango 0 y cuántas el rango 1?" |
| 10 | M1: olvidan `todo_pending = 0`; el programa sigue imprimiendo `TODO pendiente` | "¿Qué imprime el programa y en qué línea decide imprimirlo?" |
| 11 | Crear: `MPI_Allreduce(local_sq, total_sq, …)` con valores en vez de direcciones, o `count = local_n` | "¿Qué tipo esperan `sendbuf` y `recvbuf`? ¿Cuántos `double` estás combinando: uno por rango o `local_n`?" |
| 12 | Crear: `if (rank == 0) printf("norma = …")` y `make test` falla con "rangos con la norma correcta: 1 de 4" | "¿Dónde quedó el total después de `Allreduce`? ¿Qué pide la especificación: quién imprime?" |
| 13 | Crear: hacen `Gather` de `y_local` y la suma de cuadrados en el rango 0, luego `Bcast` | "Funciona; ¿cuántas colectivas usaste y cuántos bytes mueve cada una? ¿Cuál dice la restricción?" |
| 14 | Con `n = 4096` y 40 productos el *speedup* sale < 1 "entonces MPI es más lento" | "¿Qué dice `uptime`? ¿Quién más corre algo en esta máquina? Lee el desglose: ¿qué parte creció y cuál no?" |

### 50–78 · Práctica 5 · Laboratorio 1: Partes A y B (28 min)

Enunciado: `practicas/P5-mpi/README.md` (publicado el jueves 5 de noviembre). Flujo del Lab 1:

- **Parte A (guiada, 50–62).** Código **completo** para leer, predecir y verificar: `a1_hello_rank` (`Gather` de
  rangos) y `a2_stats_mpi` (estadísticos de un arreglo con `Scatter`/`Scatterv` según `n % p`, `Reduce`, `Bcast` y
  `Allreduce`). Cada equipo llena la tabla de predicción P1–P6 y la de rastreo del enunciado (quién tiene el dato
  antes y después de cada colectiva, cuántos bytes viajan) y lo verifica con `make test-a`. Son las colectivas que
  acaban de rastrear en la práctica guiada, sobre un arreglo; se les dice así. Entran aquí como código para leer y
  predecir (03 §1, 07 §B), no como `TODO`.
- **Parte B (semi-guiada, 62–78).** El producto matriz-vector por filas. Hoy solo el `TODO(1)`: cuentas y
  desplazamientos del reparto con residuo de S01 (en filas y en elementos), que se verifica solo con los dos casos
  `reparto con residuo (TODO 1)` de `bash tests/run_tests.sh b` (`4 PASS, 0 FAIL, 5 PEND` al minuto 78). Los
  `TODO(2)`–`(5)` (`Scatterv`, `Bcast`, `Gatherv` y el `Reduce(MAX)` del tiempo) se escriben en casa: una colectiva
  no se pide como `TODO` en la sesión en que aparece (03 §1). Quien termina el `TODO(1)` antes regresa a M1–M3 de
  la Parte A.

Si la Práctica 5 aún no estuviera publicada al llegar la sesión, el bloque se cubre con M2, M3, la fase Crear y
la sección "Medición" de la práctica guiada (`./medir.sh` con `n = 4096`, 40 productos, `-np 1, 2, 4`), que
producen la misma evidencia (tabla de reparto, `norma_allreduce` con `make test` en `PASS`, tabla de medianas
con desglose) y se reportan en la Parte D.

El profesor circula con la rúbrica. **Mini-defensas** (02 §2.1): 2 min por equipo, al azar con tarjetas; **una**
pregunta por integrante sobre el código que tengan en pantalla ("¿qué hace esta línea?"); la segunda ("¿qué
pasaría si la quito?") solo si la primera falla, y cuenta la mejor de las dos. Líneas preferidas hoy: el
`sendcount` del `Scatter`, el `MPI_Bcast` ("¿quién la ejecuta?"), el `Reduce` con `MPI_MAX`, el `MPI_Barrier`
antes de `MPI_Wtime`, el reparto con residuo. Con más de 12 equipos, hoy se defiende la mitad y la otra mitad el
martes 17 de noviembre (lista publicada al cerrar esta sesión). Quien pide responder por escrito lo hace en el
momento (5 min, papel). Una respuesta que muestre que no se entiende el código propio se anota (criterio
"Proceso e integridad" de ese integrante en la P5). Cambio de roles conductor/navegante al minuto 65.

Errores de entorno frecuentes en este bloque y la pregunta que se hace:

| Síntoma | Pregunta socrática |
|---|---|
| *not enough slots* con `-np 4` en una laptop de 2 núcleos | "¿Cuántos *slots* detecta `mpirun`? ¿Qué bandera declara que sabes que estás sobre-suscribiendo? ¿Qué le pasa a tus tiempos con ella?" |
| `n = 10 no es multiplo de p = 4` | "¿Qué exige `Scatter` de los bloques? ¿Qué par de llamadas acepta bloques distintos? ¿Quién lee sus arreglos de cuentas?" |
| El programa se cuelga al agregar el cronómetro | "¿Pusiste el `MPI_Barrier` dentro de un `if`? ¿Cuántos rangos llegan a él?" |
| `checksum` distinto al secuencial en la última cifra con `n` grande | "¿Qué tolerancia usa `tests/run_tests.sh` y por qué? ¿En qué orden suma cada versión?" |

### 78–85 · Punto de control y ConcepTest 2

**78–83.** Cinco equipos al azar (tarjetas) muestran en 1 minuto la salida de `bash tests/run_tests.sh b` (o, si no
llegaron, el `PASS` de `matvec_allgather` de la práctica guiada) y dicen qué colectiva de la Parte A mueve qué dato.
Los demás anotan su propia salida (`PASS`/`FAIL`/`PEND`) en la cabecera del *exit ticket* (02 §2.1). Mostrar sin nombres
dos hallazgos de la ronda (los más probables: #1/#2 y #11/#12 de la lista).

**83–85 · ConcepTest 2** (`conceptests.md`, desglose de tiempos con un producto): **voto único** (proyectado
mientras el último equipo se sienta); discusión de 90 s en parejas y revoto solo si el acierto queda entre 30 %
y 80 % **y** el reloj no pasó del minuto 84; fuera de ese rango se pasa a la explicación de una frase. Si no hay
tiempo ni para el voto, pasa como pregunta 1 de la recuperación de S04. Proyectar al lado la tabla de medición de
`ejemplo-resuelto.md` §8 (un producto: *speedup* 0.37; cuarenta: 3.03).

**Regla general en una frase** (escribirla debajo de la de las 08:58): *"El costo de repartir los datos se
cuenta: se paga una vez y se amortiza, o se evita generando los datos donde se usan."*

### 85–90 · Cierre

`exit-ticket.md` en media hoja, individual, número de lista. Mientras escriben, anunciar textualmente:

1. "Tarea espaciada (`tarea-espaciada.md`): 20–30 minutos; se trae resuelta el **jueves 12 de noviembre, 10:30,
   Salón 3208**, junto con la de S02, y se autocalifica ahí con la clave (2 min). No tiene peso propio; el examen
   de práctica del jueves 3 de diciembre y el 10–20 % acumulativo del Examen 3 toman ítems de aquí. Quien no
   terminó `norma_allreduce.c`, ese es su ejercicio 1(b)."
2. "Siguiente sesión: **jueves 12 de noviembre, 10:30, Salón 3208**: descomposición de dominio y celdas fantasma,
   y la **retroalimentación del Examen 2** [si ya se publicó la calificación y la clave: decir dónde]. El
   ejercicio 3 de la tarea es la entrada a ese tema."
3. "Práctica 5: la Parte C se hace entre hoy y el **martes 17 de noviembre, 08:30, Lab LS4** (Lab 2: Partes C y D,
   punto de control y las mini-defensas que faltan). Entrega: **domingo 22 de noviembre, 23:59**, 15 % del 3er
   parcial. El lunes 16 no hay clase."
4. Si hay más de 12 equipos: publicar la lista de quién se defendió hoy y quién el martes 17.

## Diferenciación

- **Apoyo (quien no arranca en PRIMM):** entregarle impresa la tabla I1 con las filas de los rangos 0 y 1 ya
  llenas y pedir las de 2 y 3; después, solo Ejecutar + I3 + M1. Para M1, darle la llamada con huecos:
  `MPI_Allgather(y_local, ____, MPI_DOUBLE, y, ____, MPI_DOUBLE, ____);` y preguntar qué argumento de `Gather`
  desapareció. Para Crear, la Pista 3 del README impresa (es el mismo problema con un hueco menos).
- **Ampliación (quien termina M1 antes del minuto 47):** M2 (la raíz es el último rango: idea 19), M3
  (`Scatterv` con `n = 10` y `n = 3`), Crear con `MPI_IN_PLACE`, y la versión `Reduce` + `Bcast` de la norma
  cronometrada contra `Allreduce` con `n = 4096`. Si también termina: **ConcepTest 3** en su mesa, explicado a la
  pareja de al lado.

## Soluciones de referencia (solo para el profesor)

Verificadas en la máquina de autoría: con las dos completas, `make test` → `20 PASS, 0 FAIL, 0 SKIP`.

<details><summary>M1 · <code>TODO(1)</code> de <code>matvec_allgather.c</code></summary>

```c
int todo_pending = 0;
MPI_Allgather(y_local, (int)local_n, MPI_DOUBLE,
              y, (int)local_n, MPI_DOUBLE, MPI_COMM_WORLD);
```

Salida con `-np 4 n=8`: cuatro líneas `[rango k] y completo: y[0] = 168.0, y[7] = 420.0, checksum = 2352.000000`.
</details>

<details><summary>Crear · <code>norma_allreduce.c</code></summary>

```c
/* norma_allreduce.c — norma ||y|| de y = A·x en TODOS los rangos con una MPI_Allreduce.
 * Uso: mpirun -np p ./norma_allreduce [n]   (n múltiplo de p) */
#include <math.h>
#include <mpi.h>
#include "matvec_data.h"

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    long long n;
    int reps;
    if (parse_args(argc, argv, &n, &reps) != 0) { MPI_Finalize(); return 1; }
    if (n % size != 0) {
        if (rank == 0) printf("n = %lld no es multiplo de p = %d.\n", n, size);
        MPI_Finalize();
        return 1;
    }
    long long local_n = n / size;

    double *A = NULL;
    if (rank == 0) {
        A = alloc_doubles(n * n);
        fill_rows(A, 0, n, n);
    }
    double *x = alloc_doubles(n);
    if (rank == 0) fill_vector(x, n);
    double *A_local = alloc_doubles(local_n * n);
    double *y_local = alloc_doubles(local_n);

    MPI_Scatter(A, (int)(local_n * n), MPI_DOUBLE,
                A_local, (int)(local_n * n), MPI_DOUBLE, 0, MPI_COMM_WORLD);
    MPI_Bcast(x, (int)n, MPI_DOUBLE, 0, MPI_COMM_WORLD);

    local_matvec(A_local, x, y_local, local_n, n);

    /* Cada rango suma los cuadrados de SU bloque; Allreduce combina y deja el total en todos. */
    double local_sq = vector_sum_squares(y_local, local_n);
    double total_sq = 0.0;
    MPI_Allreduce(&local_sq, &total_sq, 1, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);

    printf("[rango %d] suma local de cuadrados = %.6f, norma = %.6f\n", rank, local_sq, sqrt(total_sq));

    free(A); free(x); free(A_local); free(y_local);
    MPI_Finalize();
    return 0;
}
```

Salida real con `-np 4 n=8` (orden variable): los cuatro rangos imprimen `norma = 863.666602`; las sumas locales
son 69840, 133776, 218448 y 323856. `make test`: `PASS norma_allreduce -np 4 n=8`, `-np 3 n=12` (3590.824975),
`-np 4 n=1024` (20648777785.594250).
</details>

## Evaluación formativa de la sesión

| Objetivo | Qué mira el profesor | Umbral de alerta |
|---|---|---|
| 1 (elegir y escribir la colectiva) | *Exit ticket* P2 (`Allreduce` + `MPI_MAX`, sin `root`, fuera de `if`); Crear con `make test` en `PASS`; ConcepTest 3 si se usó | > 30 % en "mal" en P2 (`Bcast`/`Gather`/`Send` o dentro de `if`) |
| 2 (todos la llaman; dos síntomas) | Revoto del ConcepTest 1; P6–P7 comparadas con lo observado; *exit ticket* P1 | Revoto CT1 < 70 % o > 30 % en "mal" en P1 |
| 3 (rastrear el reparto y verificar) | Tabla I1 llena para `-np 4` y `-np 2`; M1 en `PASS`; punto de control con `tests/run_tests.sh b` (reparto de la Parte B) | Más de un tercio de los equipos sin M1 en `PASS` al minuto 50 |
| 4 (leer el desglose de tiempos) | ConcepTest 2 (voto único); tabla de medición propia si la hicieron; tarea 2 el jueves | CT2 < 60 % en el voto único |

Datos que se registran hoy en `herramientas/seguimiento-grupo.csv`: % aciertos de la recuperación 2 y 4, conteo
de la 5 por opción, % CT1 (primer voto y revoto), % CT2, montones del *exit ticket* (bien/parcial/mal), entrega
del pre-lab (sí/no por número de lista).

Registro del punto de control (llenar en clase):

| Equipo | Parte B, `tests/run_tests.sh b` (PASS/FAIL/PEND) | Dice qué colectiva mueve qué dato | M1 en PASS | Mini-defensa: quién no explicó su línea |
|---|---|---|---|---|
| | | | | |

## Notas post-sesión

Se llenan el mismo martes 10 de noviembre, después de clasificar los *exit tickets* (10 min):

- Qué falló en el tiempo (¿se recortó Crear? ¿cuántos equipos llegaron a la Parte B?):
- ConcepTest que falló y por qué (opción más votada entre los errados):
- Error más frecuente del *exit ticket* (abre la recuperación del jueves 12 de noviembre; si fue "solo la raíz
  llama a la colectiva", S04 lo tiene previsto en su minuto 0–5):
- Pre-labs no entregados (número de lista) y equipos pendientes de mini-defensa para el martes 17:
- Incoherencias detectadas en `practicas/P5-mpi/README.md` (si una colectiva venía como `TODO` en la Parte B):
- Cambio concreto para la próxima vez que se dé esta sesión:
