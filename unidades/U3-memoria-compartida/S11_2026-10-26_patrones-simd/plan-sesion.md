> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S11 · lunes 26 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S11 · Patrones de paralelismo (reducción sobre arreglos, *scan*, *stencil* de Jacobi, *pipeline*) y vectorización con `omp simd`

Tipo: Contenido (estructura base de 90 min). Viene de S10 (jueves 22 de octubre: protocolo de medición,
Amdahl medido, Karp–Flatt, falso compartido). Va hacia S12 (martes 27 de octubre, 08:30, Lab LS4: Práctica 4
Lab 2, Partes C y D, y taller "cómo paralelizar la V1 del proyecto").

## Objetivos (al terminar, el estudiante podrá…)

1. Implementar una reducción sobre un arreglo con `reduction(+:arr[:n])` y con acumuladores locales, y
   explicar por qué `atomic`/`critical` por elemento es peor (contención y falso compartido). (aplicar)
2. Explicar por qué un ciclo con dependencia acarreada (`y[i] = y[i-1] + x[i]`) no se reparte con
   `parallel for` ni se vectoriza, y reescribirlo con el patrón de dos fases verificando contra la versión
   secuencial con tolerancia. (analizar / aplicar)
3. Implementar un *stencil* 1D de Jacobi con doble búfer, intercambio de punteros y convergencia con
   `reduction(max:…)`; predecir el número de iteraciones y el resultado con 1, 2 y 4 hilos, y medirlo con el
   protocolo del curso. (aplicar / analizar)
4. Usar `#pragma omp simd` / `parallel for simd` y los reportes `-fopt-info-vec-optimized/-missed` para
   decir qué vectorizó el compilador, por qué no vectorizó lo demás (aliasing, dependencia, modelo de costo) y
   si la medición de saxpy con y sin `simd` es consistente con un ciclo limitado por memoria. (evaluar)

Los objetivos 2 y 4 se evalúan en el *exit ticket*; el 1 en el ConcepTest 3 y la tarea; el 3 en la tabla de la
práctica guiada y la tarea.

## Prerrequisitos y vínculo

- Viene de: S07 (carreras, `critical`/`atomic`, `barrier`, TSan), S08 (`schedule`), S10 (protocolo, Karp–Flatt,
  falso compartido). De unidades previas: Foster (descomposición de dominio), Amdahl.
- Va hacia: S12 (P4 Partes C–D; patrones para la V2 del proyecto), Práctica 5 (Jacobi 1D con halos en MPI),
  Unidad V (reducción en árbol y *stencil* en GPU). El Jacobi de hoy es la base de la P5 y de la V2 de varios
  proyectos.
- Ideas erróneas que ataca (Anexo A): **10** (`reduction` = resultado secuencial exacto) en CT1, pausa 4 del
  ejemplo, *exit ticket* P1 y pruebas con tolerancia; **1** (más hilos = más rápido) en PRIMM P1(d), I2–I3 y
  CT2; **14** (falso compartido) en recuperación 2, pausa 2 del ejemplo y CT2/CT3; **2** (Amdahl en líneas) en
  recuperación 3. Nueva para el Anexo: "`reduction` serializa el ciclo" (distractor C de CT2).
- Nivel de andamiaje: con pistas (07 §A.5: tercera sesión de contenido de la unidad). El ejemplo resuelto está
  escrito completo, así que el desvanecimiento va en la práctica guiada: Predecir y Ejecutar en 5 min cada uno,
  `TODO(1)` con la pista en el código, M3 y Crear sin ejemplo y con ≥ 10 min.

## Materiales

- Archivos de esta carpeta; proyector; cronómetro visible; tarjetas con números de lista; máquina del salón con
  gcc 13 + OpenMP (`make` en `practica-guiada/` antes de la sesión: debe dar 9 PASS y 1 SKIP en `make test`).
- Tener abiertas dos terminales: una en `practica-guiada/` y otra con la salida de `make report` ya generada.
- Hojas para el *exit ticket*.

## Guion minuto a minuto

### 0–5 Recuperación

Proyectar `retrieval-inicio.md` (5 preguntas). A los 4 min, mostrar respuestas; manos por pregunta y anotar
porcentajes. Respuestas esperadas: (1) S = 3.2, E = 0.80, f ≈ 0.083; (2) falso compartido; acumulador local
o *padding*; (3) la fracción se mide en tiempo; (4) el último punto del bloque anterior y el primero del
siguiente; (5) no: dependencia acarreada. Si < 60 % acierta la 1, rehacer S/E/Karp–Flatt en el pizarrón (2 min,
se descuentan de Transferencia). Si falla la 5, **no corregir aún**: es el gancho del Problema B.

### 5–10 Objetivos y anclaje

Frase de apertura: "El jueves el error más frecuente del *exit ticket* fue ___ (tomar de las notas de S10).
Hoy lo vamos a volver a ver, pero desde el código: cuatro formas de ciclo que aparecen en casi todos sus
proyectos, y cómo saber si el compilador está usando las instrucciones vectoriales de su procesador."
Proyectar la tabla de los cuatro patrones (`notas-estudiante.md` §1) y pedir a tres números de lista al azar
que digan a cuál patrón se parece el ciclo principal de la V1 de su proyecto. Anunciar: mañana martes 27 de
octubre, 08:30, Lab 2 de la P4 (Partes C y D); jueves 29 de octubre, H1 en clase.

### 10–35 Instrucción explícita I (ejemplo resuelto + ConcepTest 1)

Pensar en voz alta con `ejemplo-resuelto.md` proyectado y la terminal al lado.

- **10–16 Problema A (histograma).** Mostrar `hist_redarr` y `hist_local`. Decir lo que se mira: "escriben
  muchos en pocas casillas → cada quien su copia → combinar una vez". Correr `./array_reduction 20000000 16 4`.
  Pausa 1 (número de lista al azar): "¿por qué `hist[:nbins]` y no `hist`?". Pausa 2: "¿por qué el `critical`
  está fuera del ciclo?" → conectar con la pregunta 2 de recuperación (falso compartido).
- **16–26 Problema B (*scan*).** Volver a la pregunta 5 de recuperación: "no se puede tal cual; entonces
  cambiamos el algoritmo, no la directiva". Dibujar en el pizarrón los 4 bloques y las tres fases. Mostrar
  el código; pausa 3 ("¿y si quito la barrera?"). Correr `./scan 8388608 4` y `./scan 8388608 1`. Señalar la
  línea `identicos bit a bit: no` y pasar directo al ConcepTest 1.
- **26–31 ConcepTest 1** (`conceptests.md`): voto → parejas → revoto → explicación. Regla en una frase:
  "enteros y max/min exactos; sumas flotantes con tolerancia; una carrera no es 'un poquito distinto'".
  Correr `./scan_buggy 1000000 4` y `./scan_buggy 1000000 2` para mostrar la diferencia entre redondeo y carrera
  (enorme y depende del reparto; aquí sale igual entre corridas y aun así es carrera: lo confirma `make tsan`).
- **31–35 Problema C (vectorizador).** Mostrar `make report` (salida ya generada). Leer: "línea 34 vectorizada;
  18, 25 y 41 no". Pausa 6 en voz alta (no preguntar, explicar): *very-cheap*, aliasing, epílogo, dependencia.
  Mostrar la tabla de `./saxpy_simd` y decir: "guarden esta pregunta: ¿por qué gana más en L1 que en RAM? La
  responden en la fase Investigar".

### 35–65 Práctica guiada PRIMM (`practica-guiada/README.md`)

Arranque (1 min): "Parejas. Conductor y navegante; cambio a las 10:50 (yo aviso). Primero la tabla de
Predecir, **por escrito**, sin correr nada. Después Ejecutar y comparar. No vengan a preguntar si su
predicción estuvo mal: eso es lo que buscamos". A los 15 min, cambio de roles; quien no haya pasado de
Investigar I3, salta a Modificar M1 (es el objetivo mínimo).

Lista de errores esperados y la pregunta que se hace ante cada uno:

| Error observado | Pregunta socrática |
|---|---|
| Predicen que `par` con 4 hilos gana con `n = 64` ("más hilos, más rápido") | "¿Cuántas regiones paralelas abre el programa? ¿Qué cuesta más: abrir una región o promediar 62 números?" |
| Predicen diferencias pequeñas de redondeo entre `u_par` y `u_seq` (generalizan el *scan*) | "¿Qué operación combina los hilos aquí, suma o máximo? ¿El máximo depende del orden?" |
| Creen que el `swap` copia el arreglo | "Señala la línea del intercambio. ¿Cuántos elementos toca?" |
| En I1 escriben que el hilo 1 lee `u_new` del hilo 0 | "¿De qué arreglo lee el ciclo y en cuál escribe? ¿Alguien escribe en `u` dentro del ciclo?" |
| En M1 ponen `simd` pero quitan `reduction(max:…)` → `make report` no vectoriza o resultado incorrecto | "Sin la cláusula, ¿quién es dueño de `max_diff` entre carriles del vector? ¿Qué prometiste con `simd`?" |
| En M1 escriben `#pragma omp simd` en una línea y `#pragma omp parallel for` en otra, al revés | "¿Qué se reparte primero, el ciclo entre hilos o las iteraciones entre carriles? Lee la sintaxis de `parallel for simd` en las notas" |
| Usan más hilos que núcleos (laptop de 2 núcleos con 4 hilos) y obtienen tiempos absurdos | "¿Cuántos núcleos físicos tienes (`nproc`)? ¿Qué hace un hilo en una barrera si no tiene núcleo?" |
| Comparan con `-O0` "para que coincida" o con `-fsanitize=thread` activado al medir | "¿Qué dice el protocolo sobre -O0 y sanitizers al medir?" |
| En M2 concluyen "dynamic es malo" | "¿Cuánto cuesta cada iteración aquí? ¿Cuándo ganó `dynamic` en S08?" |
| En I4 concluyen "este ciclo no se puede vectorizar" porque `-O2` no lo hizo | "¿Qué diferencia hay entre 'no se puede' y 'no le convino al modelo de costo'? ¿Qué dice la línea de `step_simd` después del TODO?" |
| Tras M1 concluyen "simd no sirve" o "el reporte miente" | "¿Qué afirma exactamente el reporte? ¿Qué instrucción aparece con `(%rsp)` en el ciclo? ¿Qué cambia con `check_every = 10`?" |
| Cambian solo una de las dos directivas de `step_simd` | "¿Cuántos ciclos tiene la función? ¿Cuál corre con `check_every = 1` y cuál con 10?" |

Solución del `TODO(1)` (solo para el profesor): en `step_simd`, la primera directiva queda
`#pragma omp parallel for simd` y la segunda `#pragma omp parallel for simd reduction(max:max_diff)`; se
borran las dos líneas marcadas `/* quitar */`. `make report` debe mostrar dos líneas
`optimized: loop vectorized using 16 byte vectors` en `step_simd` (líneas 91 y 97 una vez borradas las
`quitar`; 93 y 99 si siguen ahí) y `make test` pasa 10 casos sin SKIP.

Resultado esperado de M1, que sorprende: `simd` **no** gana nada sobre `par` (1 hilo: 0.2766 s frente a
0.3067 s). No es un error de los estudiantes. La causa (M1b): GCC 13 implementa la reducción `max` de
`simd` con el acumulador en la pila (`objdump -d jacobi1d | grep -B2 -A2 maxpd` muestra `maxpd (%rsp)` y
`movaps %xmm0,(%rsp)`), así que la cadena de dependencia del máximo cuesta lo mismo que en escalar. Con
`check_every = 10` el ciclo de actualización puro sí gana: ×1.23 con 1 hilo, ×1.98 con 4. Mensaje
para la puesta en común: "vectorizado" lo dice el compilador; "más rápido" lo dice el cronómetro.

### 65–75 Puesta en común (+ ConcepTest 2)

Mostrar (sin nombres) tres hallazgos recogidos al circular: una predicción P1(d) equivocada y su corrección;
una tabla I3 con el cruce `n` donde el paralelo empieza a ganar; un `make report` con la línea de `step_simd`
vectorizada. Números de referencia de la máquina de autoría: con `n = 64`, 9626 iteraciones en ambos
modos, `seq` 0.0006 s frente a `par` (4 hilos) 0.0330 s; con `n = 100000`, *speedup* 1.80 con 2
hilos y 3.28 con 4. **ConcepTest 2** (`conceptests.md`): voto → parejas → revoto. Regla general: "más hilos
no es más rápido si el trabajo por región no amortiza su costo fijo; el *stencil* escala cuando `n` es grande
hasta que lo frena la memoria". Segundo hallazgo obligatorio: la tabla de M1/M1b de alguna pareja (`simd` sin
ganancia con la reducción, con ganancia con `check_every = 10`): "el reporte dice qué código generó; el tiempo
lo decide la dependencia más larga o la memoria". Cerrar con el *pipeline* en 2 min: diagrama de texto de las notas §1.4, "lo
reconocen; lo programarán en MPI". Si sobra tiempo (voto 2 > 80 %), ConcepTest 3.

### 75–85 Transferencia

Reto: fase Crear del README (C1 Poisson con fuente o C2 *scan* de máximos). Criterio de "listo": lo que dice
el README (prueba agregada a `run_tests.sh`, mismas iteraciones `seq`/`par`, tabla 1-2-4 hilos). Quien no
arranca: empieza por C1 con el código de `jacobi1d.c` copiado y solo cambia la línea de actualización (el
`+ h*h`) y la verificación contra `x(1−x)/2`. Quien termina: una sola región `parallel` fuera del `while`
con `omp for reduction` adentro y `single` para el intercambio de punteros; medir cuánto baja el costo por
iteración con `n = 64` (y por qué no desaparece: la barrera sigue ahí). Segunda ampliación: `-march=native` en
`CFLAGS` y volver a leer `make report` (32 bytes = AVX2) y a medir saxpy.

### 85–90 Cierre

*Exit ticket* (`exit-ticket.md`): 2 preguntas + confianza; se recoge en papel. Anunciar la tarea espaciada
(`tarea-espaciada.md`, entrega jueves 29 de octubre, 10:30, en `tareas/S11.md`). Recordar: **mañana martes 27 de
octubre, 08:30, Lab LS4: Lab 2 de la Práctica 4 (Partes C y D)**, traer la Parte C avanzada y la predicción de
la Parte D; **jueves 29 de octubre, 10:30: H1 · Avance 1 del proyecto en clase (12 % del parcial)**; **Práctica
4: domingo 1 de noviembre, 23:59 (40 %)**.

## Diferenciación

- **Apoyo (quien no arranca en PRIMM):** entregar la tabla I1 ya llena para el hilo 0 y pedir solo el hilo 1;
  en M1 darle la sintaxis `#pragma omp parallel for simd` sin la cláusula y preguntar qué falta; en Crear,
  C1 con las tres líneas a cambiar señaladas.
- **Ampliación (quien termina):** región paralela persistente (arriba); `-march=native`; cambiar la
  convergencia a norma 2 (`reduction(+:sum)` y `sqrt`) y comprobar si el número de iteraciones cambia entre 1 y
  4 hilos y por qué casi nunca lo hace aunque la suma ya no sea exacta; *scan* con `schedule` desbalanceado a
  propósito para ver que la fase 2 sigue costando O(p).

## Evaluación formativa de la sesión

| Objetivo | Qué mira el profesor |
|---|---|
| 1 (reducción sobre arreglo) | Pausas 1–2 contestadas por números de lista al azar; CT3 si se aplica; ejercicio 2 de la tarea |
| 2 (*scan* / dependencia) | CT1 ≥ 80 % en el revoto; *exit ticket* P2 con "no queda correcto" y la razón (promesa falsa) |
| 3 (Jacobi) | Tabla de la fase Ejecutar con P1(a)–(c) acertadas; I2–I3 con el cruce localizado; M1 con `make test` sin SKIP |
| 4 (vectorización) | P3 e I4 contestadas; I5 explica L1 vs RAM; *exit ticket* P1 distingue max de suma |

Montones del *exit ticket*: bien / parcial / mal según la clave. Umbral de alerta: > 30 % en "mal" en P2 →
abrir la S12 con el ciclo de P2 en el pizarrón antes del laboratorio.

## Notas post-sesión

- Porcentajes reales: recuperación (1–5): ___ · CT1 voto 1/2: ___/___ · CT2: ___/___ · CT3: ___/___.
- Error más frecuente del *exit ticket*: ___
- Qué recortar o mover la próxima vez: ___
- Qué falló en la máquina del salón (compilador, núcleos, tiempos): ___
