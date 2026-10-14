# Proyecto integrador · V1 secuencial → V2 memoria compartida → V3 GPU

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · versión 1.0 · 14 de octubre de 2026 · Profesor: Rodrigo Ojeda Santillán

## 1. Qué es el proyecto

Es la pieza donde transfieres lo aprendido en las Unidades II a V a un problema que tu equipo eligió: el mismo
problema, con los mismos datos y el mismo tamaño declarado, resuelto en tres versiones que viven en un solo
repositorio. Llega al final porque antes van los fundamentos (`docs/metodo/01-marco-pedagogico.md`, P1 y P7).

- Equipos de 2 o 3 integrantes. Repositorio en GitHub llamado `cp-6bm1-equipoNN`; el profesor es colaborador.
- La propuesta (H0, lunes 14 de septiembre de 2026) ya se entregó: problema, datos, por qué es paralelizable y
  qué versiones harán. Es el punto de partida; cualquier cambio se declara (sección 5).
- Vale **40 % del 3.er parcial** (100 puntos de proyecto). Además, el avance H1 vale **12 % del 2.º parcial**.
- Toda medición sigue `herramientas/protocolo-medicion.md`. Un *speedup* sin protocolo no es evidencia.
- La calificación es por equipo con ajustes individuales (sección 6). Cualquier integrante debe poder explicar
  cualquier línea del repositorio ("prueba de propiedad", `docs/metodo/05-politica-ia.md`).

## 2. Las tres versiones y qué cuenta como cada una

| Versión | Qué es | Cuenta como entregada si… | No cuenta si… |
|---|---|---|---|
| **V1 · Secuencial** | El mejor programa secuencial que puedas escribir en C (C11), compilado con `-O2`. Es la línea base `T(1)` de todo el proyecto. Incluye el diseño por el método de Foster y el perfil de línea base | Compila sin *warnings* con `-std=c11 -O2 -Wall -Wextra`; tiene `Makefile` con `all`, `run`, `test`, `clean`; `make test` pasa con casos de tres tipos (caso pequeño verificable a mano, caso con referencia externa, invariante); recibe el tamaño por línea de comandos; al tamaño declarado `T(1) ≥ 1 s`; el documento de Foster y el perfil por secciones existen y corresponden al código | Las pruebas solo verifican que "no truena"; el tamaño está fijo en el código o corre en milisegundos; se midió con `-O0`; es la versión paralela con un hilo presentada como secuencial; el algoritmo se hizo lento a propósito para inflar el *speedup* |
| **V2 · Memoria compartida** | V1 paralelizada con OpenMP, mismo algoritmo y mismos resultados dentro de una tolerancia declarada | `make test` compara contra V1 con 1, 2, 4 y 8 hilos y repite cada caso; hay evidencia de búsqueda de carreras (ThreadSanitizer en tamaño pequeño o análisis de accesos por variable); tabla de *speedup* y eficiencia con el protocolo; Karp–Flatt comparado con la fracción estimada en H1; decisiones de `schedule` y sincronización justificadas con mediciones | Los resultados cambian entre corridas sin explicación; el *speedup* se calculó contra V2 con un hilo sin decirlo; se paralelizó una sección marginal cuando el perfil de H1 muestra otra dominante, sin explicar por qué; hay `critical` en el ciclo interno sin discutirlo |
| **V3 · GPU** | La parte dominante del cómputo en GPU con CUDA C, Numba CUDA o CuPy, ejecutada en Colab o Kaggle (o en una GPU propia, declarada) | Correcta frente a V1 con la misma tolerancia (si cambias a `float32` lo declaras y justificas la tolerancia); tiempos **con y sin** transferencias anfitrión↔dispositivo; *notebook* o *scripts* reproducibles (verificación de GPU, compilación, ejecución, medición); entorno declarado (modelo de GPU, fecha); el equipo explica qué hace cada hilo del *kernel* y qué datos se mueven | El núcleo del cómputo es una sola llamada a una función de biblioteca que el equipo no puede explicar en términos de lo que corre en la GPU (con CuPy se espera `RawKernel`, `ElementwiseKernel`/`ReductionKernel` o una composición explicada); se compara solo el *kernel* contra el total de V1; no se sincroniza la GPU antes de leer el reloj; no hay forma de volver a correrlo |

Las tres versiones resuelven el **mismo problema, con la misma entrada y el mismo tamaño declarado**. Si una
versión necesita otro tamaño (por memoria de la GPU, por ejemplo), se reporta en una tabla aparte, nunca
mezclado. Cómo medir cada versión está en `proyecto/medicion-en-el-proyecto.md`.

## 3. Calendario de hitos

Fechas y pesos tomados de `planeacion/mapa-evaluacion.md` y `planeacion/calendario-27-1.md`.

| Hito | Fecha y hora | Qué se evalúa | Peso | Rúbrica |
|---|---|---|---|---|
| H0 · Propuesta | lunes 14 de septiembre de 2026 | Problema, datos, por qué es paralelizable, versiones | Ya entregado (no forma parte del mapa del 2.º y 3.er parcial) | — |
| **H1 · Avance 1** | **jueves 29 de octubre, 10:30–12:00, en clase** (S13, salón 3208) | V1 con pruebas, diseño por Foster, perfil de línea base, plan de V2 | **12 % del 2.º parcial** | `proyecto/hitos/H1-avance-1.md` |
| **H2 · Avance 2** | **lunes 23 de noviembre, 10:30–12:00, en clase** (U5·S01, salón 3208) | V2 correcta, *speedup*/eficiencia, Karp–Flatt, decisiones justificadas | **15 puntos** del proyecto | `proyecto/hitos/H2-avance-2.md` |
| **Entrega final · repositorio** | **lunes 7 de diciembre, 10:30** (etiqueta `entrega-final` antes de esa hora) | V1 · V2 · V3 completas, reproducibles, con mediciones | **40 puntos** | `proyecto/entrega-final/rubrica-codigo.md` |
| **Entrega final · reporte** | **lunes 7 de diciembre, 10:30** | `reporte/reporte.pdf` | **30 puntos** | `proyecto/entrega-final/rubrica-reporte.md` |
| **Defensa oral** | **jueves 10 de diciembre, 10:30–12:00** | 12 min por equipo + demo en vivo + preguntas individuales | **15 puntos** (ajusta la calificación individual) | `proyecto/defensa/rubrica-defensa.md` |

Suma del proyecto: 15 + 40 + 30 + 15 = **100 puntos = 40 % del 3.er parcial**. Las rúbricas de la entrega
final y de la defensa se publican en las carpetas indicadas antes de la fecha de cada pieza.

Sesiones de clase dedicadas al proyecto (además de las recepciones): taller "cómo paralelizar la V1" el
martes 27 de octubre (U3·S12), taller hacia H2 el jueves 19 de noviembre (U4·S06), taller de V3 el martes
1 de diciembre (U5·S05) y ensayo de defensa el lunes 7 de diciembre (C1). En todas se trabaja con la lista de
cotejo del hito siguiente y el profesor pasa por cada equipo con dos preguntas fijas: "¿qué midieron?" y
"¿qué no entienden todavía?".

Fechas vecinas que debes tener en el calendario del equipo: Práctica 4 domingo 1 de noviembre 23:59; Examen 2
martes 3 de noviembre 08:30; Práctica 5 **domingo 22 de noviembre 23:59** (la noche anterior a H2); Práctica 6
**domingo 6 de diciembre 23:59** (la noche anterior a la entrega final); Examen 3 martes 8 de diciembre 08:30
(el día siguiente a la entrega final). Planeen la V3 y el reporte para terminarlos antes de la semana del 30 de
noviembre.

### Logística de la defensa (decisión pendiente del profesor)

Con ~35 estudiantes hay ~12 equipos. 12 equipos × 12 min = 144 min, y la sesión del jueves 10 de diciembre dura
90 min. Opciones sobre la mesa, que el profesor anunciará a más tardar el jueves 3 de diciembre (S06 de la Unidad V):

| Opción | Cómo queda | Costo |
|---|---|---|
| A. Dos sesiones | 6 equipos el jueves 10 de diciembre y 6 el lunes 14 de diciembre 10:30–12:00 (sesión de reserva); orden por sorteo el 7 de diciembre | La reserva del 14 estaba prevista para retroalimentación del Examen 3 y del proyecto |
| B. Formato corto | 7 min de exposición + 3 min de preguntas = 10 min por equipo; 12 equipos = 120 min: aun así no cabe en 90 min, por lo que B solo funciona con ≤ 9 equipos o combinada con A | Menos tiempo de demo; las preguntas individuales se concentran |
| C. Mixta | Demo + preguntas individuales en clase (6 min por equipo = 72 min); la exposición de 12 min se entrega como video enlazado en el repositorio antes del 10 de diciembre 10:30 | La exposición no es en vivo |

La defensa pendiente por causa justificada se recibe el martes 15 de diciembre 08:30 (calendario, reserva).

## 4. Estructura obligatoria del repositorio del equipo

```
cp-6bm1-equipoNN/
├── README.md               Problema, datos, integrantes y reparto, tamaño declarado, cómo compilar/correr/probar
│                           cada versión en una sola secuencia de comandos, hardware usado
├── src/
│   ├── v1/                 C secuencial · Makefile (all/run/test/clean) · tests/run_tests.sh
│   ├── v2/                 C + OpenMP   · Makefile · tests/run_tests.sh (compara contra V1 con tolerancia)
│   └── v3/                 .cu o .py · notebook_colab.ipynb (o scripts) · Makefile o run_colab.sh · tests/
├── datos/                  Datos de entrada o script que los genera/descarga (nada > 10 MB en git)
├── resultados/             mediciones.csv · entorno.txt · perfil-v1.csv · speedup.png · comparacion.png · …
├── reporte/                diseno-foster.md · H1.md · H2.md · reporte.pdf (y su fuente .md o .tex)
├── run_all.sh              Reproduce TODAS las mediciones del CSV (o `make medir` en un Makefile raíz)
├── bitacora-errores.md     Qué falló, cómo se detectó, qué se cambió (plantilla en proyecto/plantillas/)
└── declaracion-ia.md       Declaración de uso de IA por entrega (plantilla en proyecto/plantillas/)
```

| Elemento | Regla |
|---|---|
| `README.md` | Alguien que no es del equipo debe poder clonar, compilar, probar y medir siguiendo solo el README. Incluye la tabla "tamaño de prueba / tamaño declarado" y el hardware |
| `src/v1`, `src/v2`, `src/v3` | Cada carpeta compila sola. `make test` termina con código 0 si pasa y distinto de 0 si falla. Identificadores en inglés, comentarios y mensajes en español (`docs/CONVENCIONES.md` §3) |
| `resultados/` | CSV con las columnas del protocolo (`config,hilos,n,rep1..rep5,mediana_s,speedup,eficiencia`), el entorno de cada máquina usada y las gráficas. Nada que no se pueda regenerar con `run_all.sh` |
| `reporte/` | Los documentos de los hitos se quedan: el reporte final los cita, no los repite |
| `run_all.sh` | Plantilla en `proyecto/plantillas/run_all.sh`. Calentamiento, 5 repeticiones, mediana, entorno |
| `bitacora-errores.md` | Mínimo una entrada por falla que costó más de 15 minutos; también registra mediciones descartadas |
| `declaracion-ia.md` | Una sección por entrega con las cuatro líneas de la política de IA; la última ("qué nos dijo mal") no es opcional |
| Etiquetas de git | `H1`, `H2` y `entrega-final`, creadas antes de la hora de cada entrega. El profesor califica lo que está en la etiqueta |

Las plantillas y un esqueleto de programa medible están en `proyecto/plantillas/` (ver su `README.md`).

## 5. Políticas de equipo e integridad

| Tema | Regla | Razón |
|---|---|---|
| *Commits* | Cada integrante trabaja con su propio usuario de GitHub. `main` siempre compila. No se aceptan repositorios donde un integrante sube el trabajo de todos al final | El historial es la evidencia de participación individual (`docs/metodo/01-marco-pedagogico.md`, P11) |
| Reparto de trabajo | Se declara en el `README.md` (quién hizo qué) y se actualiza en cada hito. El reparto no exime: todos deben poder explicar todo | Prueba de propiedad |
| Uso de IA | Semáforo de `docs/metodo/05-politica-ia.md`. Verde: explicar, generar preguntas, depurar con pistas. Amarillo: fragmentos ≤ 10 líneas reescritos y declarados, revisión de carreras, gráficas con tus datos. Rojo: pedir una versión completa, inventar o "mejorar" mediciones, entregar texto sin revisar | Un asistente usado como oráculo deja el examen y la defensa en blanco |
| Código idéntico entre equipos | Sin explicación: 0 en la entrega para todos los involucrados y reporte según reglamento (`docs/metodo/04-evaluacion.md` §6) | Integridad académica |
| Mediciones | Inventar, seleccionar o alterar mediciones tiene la misma consecuencia que el plagio. Las corridas descartadas se anotan en la bitácora, no se borran | Mediciones reproducibles o no cuentan |
| Entregas tardías | Los hitos se reciben en clase con la etiqueta creada antes de las 10:30. Etiqueta creada hasta 72 h después: máximo 80 % de la parte evaluable en el repositorio. Después de 72 h no se recibe salvo justificante institucional. Un hito no entregado no bloquea el siguiente, pero su porcentaje se pierde (`docs/metodo/04-evaluacion.md` §5) | Fechas firmes con ventana definida |
| Recepción en clase | Si el equipo (o un integrante) no está en la sesión de recepción, su parte individual de "Proceso e integridad" se evalúa en asesoría dentro de las mismas 72 h, con el mismo tope de 80 %; con justificante institucional, sin tope | Responsabilidad individual |
| Cambios al problema | Hasta H1: permitidos, declarados en el `README.md` con la razón. Después de H1: solo con acuerdo escrito del profesor (asesoría o *issue* en el repositorio) | H1 fija la línea base; cambiar el problema después invalida el perfil |
| Cambios en el equipo | Si un integrante deja de participar, el equipo lo informa por escrito al profesor en la semana en que ocurre. El alcance se renegocia; el historial de *commits* decide la calificación de quien se retiró | Equidad |
| Datos | Si los datos son de terceros, se cita la fuente y la licencia en el `README.md`. Datos personales: no | Reproducibilidad y legalidad |

## 6. Cómo se califica individualmente

1. **Punto de partida: calificación del equipo.** Cada pieza (H1, H2, repositorio final, reporte, defensa) se
   califica con su rúbrica y produce un puntaje para el equipo.
2. **Criterio individual en H1 y H2.** El criterio "Proceso e integridad" (15 de 100 puntos en cada hito) se asigna
   **por integrante**: en la recepción cada quien responde una pregunta sobre el código o las mediciones que firmó.
   Quien no puede explicar su parte queda en el nivel Insuficiente de ese criterio, aunque el equipo quede en
   Ejemplar en los demás.
3. **Preguntas individuales en la defensa.** La rúbrica de defensa (`proyecto/defensa/rubrica-defensa.md`) asigna
   los 15 puntos con un componente individual: las preguntas se dirigen a una persona a la vez, sin ayuda del
   equipo, y pueden mover la calificación de cada integrante respecto a la del equipo.
4. **Historial de *commits*.** Participación nula o marginal sin explicación en el reparto se refleja en el
   criterio de proceso de la rúbrica del repositorio final (`proyecto/entrega-final/rubrica-codigo.md`) para
   ese integrante.
5. **Nada es sorpresa.** Los mecanismos son estos cuatro; no hay ajustes no escritos. Si crees que la calificación
   individual no refleja tu trabajo, el canal es la retroalimentación escrita de cada pieza (≤ 7 días) y la asesoría.

## 7. Preguntas frecuentes

**¿Podemos cambiar de problema después de H0?** Hasta H1 sí, declarándolo en el `README.md`. Después solo con
acuerdo del profesor, porque H1 fija la línea base contra la que se mide todo lo demás.

**¿V1 puede ser en Python?** No. V1 es la línea base en C con `-O2`: comparar OpenMP o GPU contra Python infla el
*speedup* por el intérprete, no por el paralelismo. Puedes usar Python para generar datos, verificar resultados y
graficar.

**¿Podemos usar bibliotecas (BLAS, FFTW) en V1?** Solo como *referencia* para las pruebas. El núcleo que vas a
paralelizar lo escribes tú; si V1 ya es una llamada a una biblioteca optimizada, no hay nada que paralelizar en V2
ni que portar en V3.

**Mi laptop tiene 2 núcleos físicos. ¿Cómo reporto 1, 2, 4, 8 hilos?** Mides hasta los núcleos físicos y uno más
allá, declarándolo (protocolo §2). Con 2 núcleos: 1, 2 y 4 hilos, con 4 marcado como sobre-suscripción. Para la
tabla completa puedes medir en la máquina del laboratorio LS4 o en la de otro integrante; declaras en qué máquina
se midió cada tabla. Nunca mezclas máquinas en una misma tabla.

**¿Qué pasa si V2 no da *speedup*?** No pierdes el hito por eso. Pierdes puntos si no explicas por qué con
evidencia (perfil, Karp–Flatt, experimentos). Un "no escala y aquí está la causa medida" vale más que un
*speedup* que no se puede reproducir.

**¿Colab o Kaggle para V3?** Cualquiera de los dos. Declaras el modelo de GPU (`!nvidia-smi`) y la fecha en cada
medición, porque el hardware asignado cambia. Guarda el CSV y `entorno.txt` en el repositorio: el sistema de
archivos de Colab se borra al cerrar la sesión.

**¿CUDA C, Numba o CuPy?** El que el equipo pueda explicar línea por línea en la defensa. CUDA C es lo que se ve en
clase; Numba te deja escribir el *kernel* en Python con el mismo modelo de hilos/bloques; CuPy sirve si escribes el
núcleo con `RawKernel`/`ElementwiseKernel` o puedes explicar qué corre en la GPU en cada operación.

**¿Cómo comparo la GPU de Colab con mi CPU si son máquinas distintas?** Lo honesto es correr también V1 en la CPU
de Colab y reportar ese *speedup* como el principal; la comparación con tu laptop va aparte y se llama
"comparación entre máquinas". Detalle en `proyecto/medicion-en-el-proyecto.md` §6.

**¿Puedo usar IA para escribir el reporte?** Para organizarlo y revisarlo, sí (verde). Para generar secciones que
nadie del equipo revisó, no (rojo). En la defensa se pregunta sobre el texto.

**¿Cuánto cuenta H1 en el 3.er parcial?** Nada: H1 es 12 % del 2.º parcial. En el 3.er parcial cuentan H2 (15),
repositorio (40), reporte (30) y defensa (15).

**¿Se entrega un video?** Solo si el profesor elige la opción C de la logística de defensa (sección 3). En las
otras opciones la demo es en vivo.

**¿Qué hago si un integrante no responde ni hace *commits*?** Avisa por escrito al profesor la misma semana. El
alcance del equipo se renegocia y el historial decide la calificación de esa persona. No cargues con su parte en
silencio: eso perjudica a los que sí trabajan.

**¿Dónde pido ayuda?** En asesoría, siguiendo el protocolo del curso: primero escribes qué intentaste y qué
observaste (la bitácora sirve para eso); después se atiende.

## 8. Dónde está cada cosa en esta carpeta

| Archivo | Contenido |
|---|---|
| `README.md` | Este documento |
| `hitos/H1-avance-1.md` | H1: qué se entrega, rúbrica de 100 puntos (12 % del 2.º parcial), lista de cotejo, preguntas de la recepción, errores típicos |
| `hitos/H2-avance-2.md` | H2: qué se entrega, rúbrica de 100 puntos escalada a 15, lista de cotejo, preguntas, errores típicos |
| `medicion-en-el-proyecto.md` | Cómo aplicar el protocolo de medición a tu problema: tamaños, corridas, V1 vs V2 vs V3, transferencias, Colab vs CPU propia, plantillas de tabla y gráfica, errores que invalidan |
| `plantillas/` | Bitácora, declaración de IA, `run_all.sh`, `graficar_proyecto.py`, esqueleto de programa medible, `Makefile` y pruebas de referencia |
| `entrega-final/` | Rúbricas del repositorio (40 puntos, `rubrica-codigo.md`) y del reporte (30 puntos, `rubrica-reporte.md`), `plantilla-reporte.md`, `reproducibilidad.md`, `lista-cotejo-entrega.md`, `faq-entrega.md`, repositorio plantilla (`plantilla-repo/`) y `scripts/verificar_entrega.sh` |
| `defensa/` | Rúbrica de la defensa (15 puntos), formato y orden (se publica antes del 3 de diciembre) |
