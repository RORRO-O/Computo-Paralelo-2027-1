# Marco pedagógico del curso

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Documento base del método · versión 1.0 · 14 de octubre de 2026

## 1. Punto de partida: qué tomamos del debate sobre "la escuela-fábrica"

La conversación de origen (varios asistentes de IA discutiendo el mito de Rockefeller y la "escuela ideal")
deja seis conclusiones útiles y tres advertencias. Las conclusiones:

1. **Memorizar y pensar no son enemigos.** El criterio se construye sobre conocimiento almacenado. Un estudiante
   que no sabe qué es una condición de carrera no puede detectar que la IA le entregó código con una.
2. **El orden importa**: adquisición guiada → práctica variada → aplicación autónoma. Pedir "proyectos abiertos"
   a novatos amplía la brecha entre quien tiene apoyo en casa y quien no.
3. **La obediencia ciega perdió valor; la disciplina no.** Protocolos, fechas, *commits* legibles y mediciones
   reproducibles siguen siendo parte del oficio. La meta es subordinar la disciplina al criterio, no eliminarla.
4. **La IA es tutor, no reemplazo.** Personaliza la práctica y libera tiempo del profesor para lo que la máquina no
   hace: diagnosticar, conectar, motivar, decidir.
5. **El cuello de botella es la escala.** 35 estudiantes, un profesor, 4.5 horas por semana. Lo que no cabe en
   ese presupuesto no es un método; es un deseo.
6. **Se mide.** Si un cambio no deja rastro en los datos del curso (recuperación, entregas, exámenes), se revisa.

Las advertencias: (a) no citar cifras no verificadas (varias de las que circularon en esa conversación no
tienen fuente localizable; ver `06-evidencia-y-bibliografia.md`, §2); (b) la evidencia de preescolar y secundaria
no se traslada automáticamente a ingeniería; (c) ningún principio sustituye a la observación del grupo real.

El mito de Rockefeller en sí no forma parte del curso. La frase que se le atribuye no tiene fuente primaria
(Snopes, 2023: *Unproven*); el texto auténtico que se le parece es de Gates (1913). Lo que sí forma parte es su
lección metodológica: verificar fuentes antes de repetir una afirmación. Eso es exactamente lo que se les pide a
los estudiantes con las salidas de la IA.

## 2. Once principios y cómo se ven en este curso

Cada principio tiene tres partes: la idea, la evidencia que la sostiene y la **regla operativa** que la convierte
en algo que se puede ver en el salón 3208 o en el laboratorio LS4. Las fuentes completas y el grado de certeza de
cada principio están en `06-evidencia-y-bibliografia.md`, §1.

### P1. Fundamentos antes que proyectos (guiar → practicar → aplicar)

- **Idea.** Los novatos aprenden más con instrucción explícita y ejemplos resueltos que con descubrimiento;
  conforme ganan pericia, la guía debe retirarse (reversión por pericia, *expertise reversal*).
- **Evidencia.** Kirschner, Sweller y Clark (2006); Rosenshine (2012; evidencia sobre todo de educación básica,
  se toma como heurística); carga cognitiva y ejemplo resuelto (Sweller, 1988; Sweller y Cooper, 1985); reversión
  por pericia (Kalyuga et al., 2003). La "falla productiva" (Kapur) funciona cuando el problema previo está
  diseñado y lo sigue instrucción explícita y contrastiva: Sinha y Kapur (2021), g = 0.36 [0.20, 0.51], mayor en
  conceptos que en procedimientos; con alta interactividad de elementos gana instrucción-explícita-primero
  (Ashman, Kalyuga y Sweller, 2020). No es excusa para soltar al grupo sin base.
- **Regla operativa.** Ningún concepto nuevo se pide en una práctica antes de haber sido modelado con un
  ejemplo resuelto en clase. El andamiaje se desvanece dentro de la misma unidad: ejemplo completo → ejemplo
  por completar → problema con pistas → problema libre (el proyecto). El nivel de andamiaje se declara en cada
  `plan-sesion.md` y sigue la posición de la sesión en la unidad (`07-guia-de-autoria.md`, §A.5). Un constructo
  que aparece por primera vez en una sesión de laboratorio (tareas en U3 S09, colectivas en U4 S03, memoria
  compartida y *tiling* en U5 S02) se modela ahí con un ejemplo resuelto corto antes de pedirlo
  (`02-plantilla-sesion.md`, §2.1).

### P2. Recuperar, espaciar, intercalar

- **Idea.** Traer algo de la memoria lo fortalece más que volver a leerlo. Repartir la práctica en el tiempo y
  mezclar temas cuesta más en el momento y rinde más después ("dificultades deseables", Bjork).
- **Evidencia.** Roediger y Karpicke (2006); Karpicke y Blunt (2011); Dunlosky et al. (2013) califican la
  práctica de recuperación y la práctica distribuida como las dos técnicas de utilidad alta, y la práctica
  intercalada como de utilidad moderada; Cepeda et al. (2006) sobre espaciado.
- **Regla operativa.** Cinco minutos de recuperación al inicio de **toda** sesión, individual y sin apuntes.
  Composición fija (`docs/CONVENCIONES.md`, §1): 2 preguntas de la sesión anterior, 1–2 de unidades previas y
  1 que anticipa el tema. Cada pregunta se contesta en una línea o eligiendo una opción; el rastreo largo y
  "explica con tus palabras" van al *exit ticket*, a PRIMM o a la tarea. La pregunta que anticipa no es práctica
  de recuperación: se contesta con una conjetura de una línea, "no sé" es válida y no cuenta. Es una decisión de
  diseño (su respaldo como *pretesting* está pendiente de verificación en `06`, §5). Las tareas son cortas
  (20–40 min) y siempre incluyen un ejercicio intercalado. Intercalar aquí significa obligar a elegir entre
  primitivas o estrategias parecidas vistas en sesiones distintas (`atomic`, `critical` o `reduction`; `static` o
  `dynamic`; `Reduce` o `Allreduce`; `Send` o `Isend`), no solo repasar otra unidad; el ejercicio de unidades
  previas aporta el espaciado. Los exámenes 2 y 3 reservan entre 10 % y 20 % a unidades previas, integrado en
  problemas de la unidad evaluada (`04-evaluacion.md`, §2.1).

### P3. Ejemplos resueltos con autoexplicación y desvanecimiento

- **Idea.** Estudiar un ejemplo resuelto bien construido enseña más a un novato que resolver el problema a ciegas,
  siempre que el estudiante se explique a sí mismo cada paso.
- **Evidencia.** Efecto del ejemplo resuelto (Sweller y Cooper, 1985); el desvanecimiento se justifica por la
  reversión por pericia (Kalyuga et al., 2003; Kalyuga, 2007); la autoexplicación es de utilidad moderada en
  Dunlosky et al. (2013).
- **Regla operativa.** Cada sesión tiene un `ejemplo-resuelto.md` con pausas marcadas ("¿Por qué aquí va
  `firstprivate` y no `private`?"). En clase el profesor piensa en voz alta: dice lo que mira, lo que descarta
  y por qué. La práctica guiada de la misma sesión parte de ese ejemplo y quita una pieza a la vez.

### P4. Leer y predecir antes de escribir

- **Idea.** Escribir código desde cero exige sostener demasiadas cosas en la memoria de trabajo. Leer,
  predecir la salida, rastrear y modificar código ajeno construye los esquemas necesarios con menos carga.
- **Evidencia.** PRIMM (Sentance, Waite y Kallia, 2019; evidencia cuasiexperimental en secundaria, sin evaluación
  universitaria publicada); problemas de Parsons (Parsons y Haden, 2006; Ericson et al., 2017: menos tiempo con
  aprendizaje equivalente); correlación entre rastrear/explicar código y saber escribirlo (Lopez et al., 2008;
  Lister et al., 2009; Murphy et al., 2012).
- **Regla operativa.** Toda práctica guiada sigue PRIMM: **P**redecir la salida por escrito antes de correr,
  **R**un (ejecutar) y comparar, **I**nvestigar (tablas de rastreo, preguntas dirigidas), **M**odificar con un
  objetivo concreto, y **M**ake (crear) una variante propia. Antes de escribir un `#pragma` nuevo, el estudiante
  predice qué hilo ejecuta qué iteración.

### P5. Hacer pensar a todos, todo el tiempo

- **Idea.** La clase magistral sin verificación produce sensación de aprendizaje, no aprendizaje. Las
  estructuras que obligan a cada estudiante a comprometerse con una respuesta (votar, explicar a un par,
  escribir) sí producen aprendizaje.
- **Evidencia.** Freeman et al. (2014), metaanálisis de aprendizaje activo en STEM (+0.47 DE; reprobación
  33.8 % → 21.8 %); Deslauriers et al. (2019): más aprendizaje y menos sensación de aprender; Crouch y Mazur
  (2001) y Porter, Bailey Lee y Simon (2013), instrucción entre pares (en cuatro cursos de computación, ≈61 %
  menos reprobación; observacional); McDowell et al. (2006), programación en parejas en CS1 (más terminación y
  permanencia, mismo examen individual).
- **Regla operativa.** Dos ConcepTests por sesión con la secuencia voto individual → discusión en parejas →
  revoto → explicación del profesor. Si el primer voto supera 80 % de aciertos, se salta la discusión y se
  sigue; si queda por debajo de 30 %, se vuelve a explicar antes de discutir. Práctica guiada en parejas con
  roles *conductor* y *navegante* que se intercambian cada 15 minutos. El profesor elige al azar quién
  responde (tarjetas con números de lista), nunca "¿alguien quiere…?"; tras una discusión en parejas pregunta
  "¿qué concluyó tu pareja?" y no "¿qué piensas tú?": baja el costo para quien va atrás sin perder la
  participación obligatoria. En el ConcepTest 2 (minuto 65–75) la discusión en parejas y el revoto ocurren
  solo si el primer voto queda entre 30 % y 80 %; fuera de ese rango se pasa a la explicación. Si no hay tiempo,
  pasa como pregunta 1 de la recuperación siguiente.

### P6. Evaluación formativa continua con retroalimentación rápida

- **Idea.** Saber hoy quién no entendió qué cambia la sesión de mañana. Una calificación sin retroalimentación
  no enseña nada.
- **Evidencia.** Black y Wiliam (1998a, 1998b) es una revisión narrativa: su "0.4–0.7" no es un promedio
  metaanalítico; Kingston y Nash (2011) estiman ≈0.20. El *exit ticket* no tiene evidencia experimental propia: es
  una herramienta de evaluación formativa de bajo costo que se justifica por la práctica de recuperación (P2) y
  por el uso de la información para ajustar la siguiente sesión. La calificación por especificaciones (Nilson,
  2015) es una propuesta de diseño sin evaluación experimental (Howitz et al., 2025).
- **Regla operativa.** *Exit ticket* de 2 preguntas + 1 de confianza al cierre, con clave literal que permite
  clasificar cada ticket en ≤ 20 segundos (`07-guia-de-autoria.md`, §A.9). El profesor las revisa el mismo día
  o antes de la siguiente sesión (10 minutos, procedimiento en §4) y abre la siguiente sesión con el error más
  frecuente. Toda rúbrica se publica antes de la entrega. Toda entrega recibe retroalimentación en ≤ 7 días, con
  el formato mínimo de `04-evaluacion.md`, §3. Una semana antes de cada examen hay examen de práctica con clave.

### P7. Proyecto auténtico como culminación, no como punto de partida

- **Idea.** El proyecto integrador es donde se transfiere lo aprendido a un problema propio, con datos reales y
  decisiones de diseño. Funciona porque llega después de los fundamentos y porque tiene hitos.
- **Evidencia.** Las réplicas a Kirschner et al. (Hmelo-Silver, Duncan y Chinn, 2007) precisan que el ABP bien
  andamiado no es guía mínima; de Jong et al. (2023) sobre combinar indagación e instrucción directa. La rendición
  de cuentas individual en equipos es una decisión de diseño; no se verificó fuente (`06`, §1).
- **Regla operativa.** Tres versiones (V1 secuencial con diseño de Foster y perfilado; V2 memoria compartida con
  *speedup*; V3 GPU) con hitos fechados y rúbrica analítica. Defensa oral con preguntas **individuales** que
  pueden mover la calificación de cada integrante. Cada versión exige el protocolo de medición del curso.

### P8. La IA como tutor socrático, no como oráculo

- **Idea.** Un estudiante con base sólida usa la IA para ir más rápido y más profundo. Uno sin base la usa
  para no pensar, y aprende menos que sin ella.
- **Evidencia.** Bastani et al. (2025), ECA con ≈1,000 estudiantes de preparatoria: el acceso a GPT sin
  guardarraíles mejoró la práctica (+48 %) y empeoró 17 % el examen sin ayuda; con diseño de tutor (pistas, sin
  respuestas directas) el grupo quedó igual al control. Kestin et al. (2025), ECA cruzado (n = 194) en física: un
  tutor de IA diseñado ad hoc con principios pedagógicos superó a la clase activa en dos lecciones con posprueba
  inmediata; no equivale a "usar ChatGPT". Prather et al. (2024): entre novatos con IA se abre una brecha; quienes
  luchan muestran una falsa sensación de avance (*false sense of progress*) y dificultades metacognitivas.
  Bassner et al. (2025) y Lehmann et al. (2025): la IA mejora el desempeño inmediato; el aprendizaje depende de
  usarla como tutor y no como sustituto.
- **Regla operativa.** Política de semáforo (`05-politica-ia.md`): verde para explicar, generar preguntas y
  depurar con pistas; amarillo para fragmentos pequeños con declaración; rojo para entregar sin comprender.
  Zonas sin IA: recuperación, exámenes, defensa oral. "Prueba de propiedad": cualquier línea entregada debe
  poder explicarse en voz alta. Se enseña a verificar las salidas de la IA con los mismos criterios con que se
  verifica cualquier fuente: compilar, medir, contrastar con la documentación oficial.

### P9. Metacognición y hábitos de ingeniería

- **Idea.** Saber qué sabes y qué no, y tener rutinas que no dependan de la motivación del día.
- **Evidencia.** Los estudiantes juzgan mal su aprendizaje: Deslauriers et al. (2019); Roediger y Karpicke
  (2006) y Karpicke y Blunt (2011) muestran más confianza en la técnica que menos enseña. La bitácora de errores
  y el pre-mortem son hábitos de ingeniería adoptados por diseño, sin fuente verificada (`06`, §1).
- **Regla operativa.** Al recibir el examen, el estudiante anota la calificación que espera (predicción); al
  entregarlo, la que cree haber obtenido (postdicción); después compara ambas con la real. Cada
  equipo lleva una **bitácora de errores** (qué falló, por qué, cómo se detectó) que forma parte del reporte del
  proyecto. Las prácticas incluyen "pre-mortem": antes de medir, escribe qué *speedup* esperas y por qué.

### P10. Equidad y escala

- **Idea.** El método tiene que funcionar para los 35, con un profesor, sin ayudantes, en 4.5 horas semanales y
  con laptops desiguales.
- **Evidencia.** La guía importa más para quien tiene menos conocimiento previo (Kirschner et al., 2006); con
  IA, la brecha se abre entre quienes aceleran y quienes luchan (Prather et al., 2024). Herramientas gratuitas en
  la nube (Colab/Kaggle) acercan el acceso a GPU, con cuotas que el estudiante no controla.
- **Regla operativa.** Todo el material es reutilizable y autocontenido (un estudiante que faltó puede
  recuperar la sesión con `notas-estudiante.md`, el ejemplo resuelto y la práctica guiada). La asesoría se
  da por protocolo: primero el estudiante escribe qué intentó y qué observó; después se atiende. La
  retroalimentación entre pares se estructura con listas de cotejo, no se improvisa. La GPU se usa desde la
  nube para que nadie dependa de su hardware; como la cuota no es controlable, la correctitud de P6 y V3 nunca
  depende de ella (`04-evaluacion.md`, §5). El diagnóstico de agosto se usa, no solo se reporta: las parejas de
  PRIMM se forman por nivel adyacente en ese diagnóstico (nunca extremos juntos) y se reconforman al inicio de
  cada unidad. "Apoyo" en todo plan de sesión es el mismo ejemplo resuelto con un hueco menos o una pista
  sellada en `<details>`; "Ampliación" es el problema sin ejemplo. Si la recuperación de inicio cae bajo 60 % en
  las preguntas de la sesión anterior, la siguiente recuperación repite ese ítem con pista en lugar de uno nuevo.
  Quien faltó sustituye el *exit ticket* y la recuperación de ese día con la `tarea-espaciada.md` de la sesión
  (`04-evaluacion.md`, §5).

### P11. Disciplina al servicio del criterio

- **Idea.** Las reglas del curso existen para producir ingenieros confiables, no para medir obediencia.
- **Regla operativa.** Fechas firmes con una ventana de segunda entrega definida en `04-evaluacion.md`.
  Repositorios con historial de *commits* por integrante. Mediciones reproducibles o no cuentan. Cada regla
  viene con su razón escrita; si la razón deja de valer, la regla se cambia.

## 3. Arquitectura del curso a partir de hoy

### 3.1 La semana

| Día | Hora | Papel en la semana |
|---|---|---|
| Lunes | 10:30–12:00 | Contenido nuevo: instrucción explícita + práctica guiada |
| Martes | 08:30–10:00 | Consolidación: laboratorio, práctica semi-guiada, avances del proyecto (horario temprano: menos teoría, más manos) |
| Jueves | 10:30–12:00 | Aplicación y rendimiento: medir, comparar, transferir; hitos del proyecto |

### 3.2 La unidad

Cada unidad recorre el mismo arco: **concepto → herramienta → rendimiento → proyecto**. Primero el modelo
mental (qué es memoria distribuida), luego la herramienta (MPI), luego cómo medirla y mejorarla, y al final cómo
se usa en la versión correspondiente del proyecto.

### 3.3 El semestre (resumen; detalle en `planeacion/calendario-27-1.md`)

| Bloque | Fechas | Sesiones | Evaluación |
|---|---|---|---|
| Unidad III · memoria compartida (segunda mitad) | 15–29 oct | 7 | Práctica 4; H1 (29 oct); Examen 2 (3 nov) |
| Unidad IV · memoria distribuida (MPI) | 5–19 nov | 6 | Práctica 5 |
| Unidad V · GPU (CUDA) | 23 nov – 3 dic | 6 | Práctica 6; H2 (23 nov) |
| Cierre | 7–10 dic | 3 | Entrega final (7 dic); Examen 3 (8 dic); defensa (10 dic) |
| Reserva | 14–17 dic | 3 | Contingencias, retroalimentación, cierre de actas |

### 3.4 Cómo arranca el jueves 15 de octubre (S07)

El grupo lleva seis sesiones de la Unidad III y dos semanas del 2º parcial con otras reglas. El cambio se anuncia
una vez, en 10 minutos, y después se sostiene con la rutina; no se vuelve a "vender".

**Antes del jueves.** Confirmar la ponderación del 2º parcial. Publicar en el repositorio `05-politica-ia.md`, la
política de entregas (`04-evaluacion.md`, §5) y `08-carta-al-grupo.md`. Imprimir las tarjetas de números de lista.

**S07, minutos 0–5: recuperación-diagnóstico.** Cinco preguntas de una línea sobre S01–S06 (región paralela;
`shared`/`private`/`firstprivate`; `reduction`; qué es el *speedup*; cómo se midió el tiempo). Cuenta por
participación. Si menos del 60 % acierta tres o más, la instrucción explícita de S07 repasa esos puntos y el
ConcepTest 2 se omite (el calendario ya prevé usar S07–S09 como repaso si hace falta).

**S07, minutos 5–15: qué cambia, por qué y qué se espera.** Sustituye al bloque de objetivos; el resto de la
sesión sigue la plantilla con Transferencia recortada. Texto que el profesor puede decir:

> "A partir de hoy la clase tiene tres rutinas nuevas. Una: abrimos con cinco minutos de preguntas sin apuntes
> y cerramos con un *ticket* de salida. No cuentan por acierto; cuentan por entregarse. Lo hacemos porque
> recordar algo enseña más que volver a leerlo; releer se siente mejor y rinde menos. Dos: la práctica es en
> parejas con roles que se cambian cada 15 minutos, y antes de que yo explique una pregunta, votan y la discuten
> con su pareja. Lo hacemos porque la clase que se siente más clara no es la que más enseña; está medido. Tres:
> la IA se usa con semáforo: verde para que les explique, amarillo para fragmentos pequeños que declaran y
> reescriben, rojo para entregar lo que no pueden explicar. Todo lo que entreguen lo tienen que poder explicar
> en voz alta, y en el laboratorio se los voy a preguntar. Lo hacemos porque quien usa la IA para no pensar rinde
> peor en el examen sin ayuda; eso también está medido.
>
> Lo que no cambia: los mismos equipos de P1–P3 para la Práctica 4 y el proyecto, las fechas que ya conocen y las
> ponderaciones. Nada cuenta hacia atrás: *tickets* y tareas suman desde hoy.
>
> Lo que pueden exigirme: la rúbrica antes de cada entrega, retroalimentación en siete días y una razón escrita
> para cada regla. Si la razón deja de valer, la regla se cambia."

Las tres afirmaciones de "está medido" remiten a Roediger y Karpicke (2006), Deslauriers et al. (2019) y
Bastani et al. (2025), todas en `06`, §1. Al terminar se entrega o proyecta `08-carta-al-grupo.md`.

## 4. Lista de cotejo del profesor

**Antes de la sesión (20 min; revisión mínima del material generado).** Leer completos `plan-sesion.md` y
`conceptests.md`. Correr `make test` de la práctica guiada en la máquina del salón. Leer la clave de
`exit-ticket.md`. El resto se revisa por muestreo (un archivo al azar); lo que falle se anota en "Notas
post-sesión" y se corrige después. Tener a mano el error más frecuente de los *exit tickets* anteriores y las
tarjetas de números de lista. En la Unidad V, comprobar ese día que Colab asigna GPU; si no, usar el Plan B
(`02-plantilla-sesion.md`, §2.7).

**Durante.** Cronómetro visible. Respetar los bloques; si la práctica guiada se alarga, se recorta el reto de
transferencia, nunca la recuperación ni el *exit ticket*. Anotar en el plan qué ConcepTest falló y por qué.

**Después (10 min, el mismo día o antes de la siguiente sesión).** Clasificar los *exit tickets* en tres
montones (bien / parcial / mal) por la clave literal de la pregunta 1; leer la pregunta 2 solo en el montón
"mal" y en 5 tickets al azar del resto. La participación se registra una vez por semana a partir de los montones,
no por sesión. Escribir dos líneas en "Notas post-sesión". Ajustar la recuperación de la siguiente sesión (si la
pregunta 1 quedó bajo 60 %, se repite con pista).

## 5. Cómo sabremos si funciona

| Indicador | Fuente | Umbral de alerta |
|---|---|---|
| Aciertos en recuperación de inicio | Conteo rápido por sesión | < 60 % en preguntas de la sesión anterior |
| Aciertos en *exit ticket* | Montones bien/parcial/mal | > 30 % en "mal" |
| Entregas a tiempo | Repositorios | < 80 % del grupo |
| Avance del proyecto por hito | Rúbricas H1/H2 | Equipos con < 60 % en un hito |
| Brecha de calibración | Postdicción (al entregar el examen) vs. calificación real; la predicción (al recibirlo) se reporta aparte | Promedio > 1.5 puntos de sobreestimación |
| Mejora de examen 1 → 2 → 3 | Calificaciones | Sin mejora en los estudiantes que estaban en "requiere refuerzo" |

Estos datos se registran en una hoja de cálculo sencilla. La plantilla vacía está en
`herramientas/seguimiento-grupo.csv` e incluye la columna `nivel_diagnostico_ago` (refuerzo / medio / alto), sin
la cual el último indicador no se puede calcular. La hoja llena contiene datos personales: vive en
`docente/seguimiento-grupo.csv` o fuera del repositorio y nunca se versiona en `main`.

## 6. Límites

La mayor parte de la evidencia viene de otros contextos (educación básica, física universitaria, CS1 en EE. UU.,
secundaria y preparatoria). Se adopta porque los mecanismos (memoria, carga cognitiva, recuperación) son
generales, no porque garantice resultados aquí. El grado de certeza de cada principio está en
`06-evidencia-y-bibliografia.md`, §1. Por eso el punto 5 existe: el método se corrige con los datos del grupo
6BM1, no con la fe.

---

## Anexo A. Catálogo de ideas erróneas del curso

Sirve para construir distractores de ConcepTests y de exámenes, y para anticipar errores en la práctica guiada.
Cada entrada: **la idea errónea** → la idea correcta → dónde se trabaja.

### Rendimiento y métricas (Unidades I–II, se reciclan en todas)

1. **"Más hilos siempre es más rápido."** → El *speedup* lo limitan la fracción secuencial (Amdahl), el ancho de
   banda de memoria, la sincronización y la creación de hilos. → U3 S10, U4 S5, U5 S4.
2. **"La fracción paralelizable de Amdahl se mide en líneas de código."** → Se mide en **tiempo** de la versión
   secuencial. → U3 S10, Examen 2.
3. **"Eficiencia y *speedup* son lo mismo."** → Eficiencia = *speedup* / p. Un *speedup* de 6 con 8 hilos es 75 %. → U3 S10.
4. **"El *speedup* superlineal es un error de medición."** → Puede ser real por efectos de caché; pero debe
   explicarse, no celebrarse sin más. → U3 S10.
5. **"Medir una vez basta" / "se mide con -O0".** → Mediana de ≥ 5 repeticiones, con calentamiento, con -O2. → Protocolo.
6. **"Escalabilidad fuerte y débil son sinónimos."** → Fuerte: mismo problema, más procesadores. Débil: problema
   crece con los procesadores. → U3 S10, U4 S5.

### Memoria compartida / OpenMP (Unidad III)

7. **"Si el resultado salió bien una vez, no hay condición de carrera."** → Una carrera es no determinista;
   "salió bien" no es evidencia. Se usa ThreadSanitizer y se razona sobre accesos. → U3 S07.
8. **"`critical` y `atomic` son equivalentes."** → `atomic` protege una operación simple sobre una variable y es
   más barata; `critical` protege una región arbitraria. → U3 S07.
9. **"`private` copia el valor inicial de la variable."** → No: queda indefinida. Para copiar se usa `firstprivate`. → U3 S07.
10. **"`reduction` da exactamente el mismo resultado que la suma secuencial."** → En punto flotante el orden
    cambia el redondeo; se compara con tolerancia. → U3 S07, Práctica 4.
11. **"`schedule(dynamic)` siempre gana."** → Tiene costo por *chunk*; gana cuando las iteraciones son
    desiguales. `static` gana cuando son uniformes. → U3 S08.
12. **"Al final de `omp for` no hay barrera."** → Sí la hay, salvo `nowait`. → U3 S07–S08.
13. **"Las tareas (`task`) se ejecutan en el momento en que se crean."** → Se encolan; `taskwait` espera a las
    hijas directas, no a todas. → U3 S09.
14. **"El falso compartido no existe / se arregla con más hilos."** → Dos hilos escribiendo variables distintas
    en la misma línea de caché se estorban; se arregla con acomodo de datos (*padding*) o acumuladores locales. → U3 S10.
15. **"Las variables declaradas dentro de la región paralela son compartidas."** → Son privadas por alcance. → U3 S07.

### Memoria distribuida / MPI (Unidad IV)

16. **"Los procesos MPI comparten memoria."** → Cada proceso tiene su espacio; todo intercambio es un mensaje. → U4 S1.
17. **"`MPI_Send` siempre regresa de inmediato" / "siempre bloquea hasta que el otro recibe".** → Depende del
    tamaño y del *buffering*; por eso dos `Send` cruzados pueden producir interbloqueo. → U4 S2.
18. **"Solo el proceso raíz llama a `MPI_Bcast`."** → Todas las colectivas las llaman **todos** los procesos del
    comunicador. → U4 S3.
19. **"El rango 0 tiene que ser el maestro."** → Es una convención, no una regla. → U4 S1.
20. **"Más procesos que núcleos siempre está bien."** → Sobre-suscripción cambia las mediciones; se declara. → U4 S5.
21. **"La comunicación es gratis comparada con el cómputo."** → Modelo latencia + tamaño/ancho de banda; a
    veces domina. → U4 S5.

### GPU / CUDA (Unidad V)

22. **"Un hilo de CUDA equivale a un núcleo de CPU."** → Miles de hilos ligeros en *warps* de 32; el modelo es SIMT. → U5 S1.
23. **"La memoria global es tan rápida como la compartida."** → Diferencias de uno a dos órdenes de magnitud;
    por eso existe el *tiling*. → U5 S2.
24. **"Las transferencias `cudaMemcpy` no cuentan en el tiempo."** → Cuentan y a menudo dominan en problemas
    pequeños. → U5 S4.
25. **"`__syncthreads()` sincroniza toda la GPU."** → Solo el bloque. Entre bloques se sincroniza al terminar el *kernel*. → U5 S3.
26. **"Cualquier tamaño de bloque funciona igual."** → Múltiplos de 32, límites por recursos, ocupación. → U5 S4.
27. **"Si el *kernel* no da error, el resultado es correcto."** → Hay que revisar `cudaGetLastError` y comparar
    con la CPU. → U5 S1–S3.

### Diseño (método de Foster, Unidad II; se usa en el proyecto)

28. **"Aglomerar es juntar todo en un solo proceso."** → Es agrupar tareas para reducir comunicación sin
    perder paralelismo útil. → Proyecto H1.
29. **"Primero se programa y luego se diseña la descomposición."** → Primero partición, comunicación,
    aglomeración y mapeo; después código. → Proyecto H1.

### Adiciones (14 de octubre de 2026; se anexan al final, no se renumera)

30. **"Cualquier `for` se paraleliza con `parallel for`."** → Solo si no hay dependencias entre iteraciones
    (`a[i] = a[i-1] + x`, *scan*, Jacobi sobre el mismo arreglo); primero se identifican lecturas y escrituras
    cruzadas. → U3 S07, S11; P4 Parte C; V2.
31. **"`clock()` mide tiempo de pared" / "el *speedup* se calcula contra la versión paralela con 1 hilo".** →
    `clock()` suma el tiempo de CPU de todos los hilos; el denominador es el mejor secuencial
    (`herramientas/protocolo-medicion.md`, §2–§3). → U3 S10; H2.
32. **"Un `barrier` dentro de un `if` está bien si lo ejecuta algún hilo."** → Todos los hilos del equipo deben
    encontrar la misma barrera o hay interbloqueo. → U3 S07.
33. **"El *kernel* terminó cuando regresa la llamada."** → El lanzamiento es asíncrono; sin
    `cudaDeviceSynchronize` o eventos, el tiempo medido es ≈ 0 y los errores aparecen después. → U5 S01, S04.
34. **"No hace falta comprobar `idx < n`."** → La malla casi siempre excede `n`; sin guarda hay accesos fuera de
    rango que "a veces funcionan". → U5 S01–S02.
