# Proyecto integrador · V1 secuencial → V2 memoria compartida → V3 GPU

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · versión 1.1 · 20 de octubre de 2026 · Profesor: Rodrigo Ojeda Santillán

## 1. Qué es el proyecto

Es la pieza donde transfieres lo aprendido en las Unidades II a V a un problema que tu equipo eligió: el mismo
problema, con los mismos datos y el mismo tamaño declarado, resuelto en tres versiones que viven en un solo
repositorio. Llega al final porque antes van los fundamentos (`docs/metodo/01-marco-pedagogico.md`, P1 y P7).

- Equipos de 2 o 3 integrantes. Repositorio privado en GitHub llamado `cp-6bm1-equipoNN`; el profesor es colaborador.
- La propuesta (H0, lunes 14 de septiembre de 2026) ya se entregó: problema, datos, por qué es paralelizable y
  qué versiones harán. Es el punto de partida; cualquier cambio sigue la regla de §5.
- Vale **40 % del 3.er parcial** (100 puntos de proyecto). Además, el avance H1 vale **12 % del 2.º parcial**.
- Toda medición sigue `herramientas/protocolo-medicion.md`; cómo aplicarlo a tres versiones y dos máquinas está en
  `proyecto/medicion-en-el-proyecto.md`. Un *speedup* sin protocolo no es evidencia.
- La calificación es por equipo con ajustes individuales escritos (§6). Cualquier integrante debe poder explicar
  cualquier línea del repositorio ("prueba de propiedad", `docs/metodo/05-politica-ia.md`).

## 2. Las tres versiones y qué cuenta como cada una

| Versión | Qué es | Cuenta como entregada si… | No cuenta si… |
|---|---|---|---|
| **V1 · Secuencial** | El mejor programa secuencial que puedas escribir en C (C11), compilado con `-O2`. Es la línea base `T(1)` de todo el proyecto. Incluye el diseño por el método de Foster y el perfil de línea base | Compila sin *warnings* con `-std=c11 -O2 -Wall -Wextra`; `make test` pasa con casos de tres tipos (pequeño verificable a mano, con referencia externa, invariante; `hitos/H1-avance-1.md` §2.1); acepta `[n] [semilla]` e imprime `tiempo_s=` y `checksum=`; al tamaño declarado `T(1) ≥ 1 s`; el documento de Foster y el perfil por secciones existen y corresponden al código | Las pruebas solo verifican que "no truena"; el tamaño está fijo en el código o corre en milisegundos; se midió con `-O0`; es la versión paralela con un hilo presentada como secuencial; el algoritmo se hizo lento a propósito para inflar el *speedup* |
| **V2 · Memoria compartida** | V1 paralelizada con OpenMP, mismo algoritmo y mismos resultados dentro de una tolerancia declarada | `make test` compara contra V1 con 1, 2, 4 y 8 hilos y repite cada caso; respeta `OMP_NUM_THREADS` cuando no recibe `[hilos]`; hay evidencia de búsqueda de carreras (ThreadSanitizer en tamaño pequeño o análisis de accesos por variable); tabla de *speedup* y eficiencia con el protocolo; Karp–Flatt comparado con la fracción estimada en H1; decisiones de `schedule` y sincronización justificadas con mediciones | Los resultados cambian entre corridas sin explicación; el *speedup* se calculó contra V2 con un hilo sin decirlo; se paralelizó una sección marginal cuando el perfil de H1 muestra otra dominante, sin explicar por qué; hay `critical` en el ciclo interno sin discutirlo |
| **V3 · GPU** | La parte dominante del cómputo en GPU con CUDA C, Numba CUDA o CuPy, ejecutada en Colab o Kaggle (o en una GPU propia, declarada) | Correcta frente a V1 con la misma tolerancia (si cambias a `float32` lo declaras y justificas la tolerancia), verificada sin GPU (Numba con `NUMBA_ENABLE_CUDASIM=1`, o el espejo en CPU del cómputo por elemento) y además en la misma sesión de Colab/Kaggle; imprime `tiempo_total_s=` **y** `tiempo_kernel_s=` (con y sin transferencias); *notebook* ejecutado con verificación de GPU, compilación, ejecución y medición; entorno declarado (modelo de GPU, fecha); el equipo explica qué hace cada hilo del *kernel* y qué datos se mueven | El núcleo del cómputo es una sola llamada a una función de biblioteca que el equipo no puede explicar en términos de lo que corre en la GPU (con CuPy se espera `RawKernel`, `ElementwiseKernel`/`ReductionKernel` o una composición explicada); se compara solo el *kernel* contra el total de V1; no se sincroniza la GPU antes de leer el reloj; no hay forma de volver a correrlo |

Las tres versiones resuelven el **mismo problema, con la misma entrada y el mismo tamaño declarado**. Si una
versión necesita otro tamaño (por memoria de la GPU, por ejemplo), se reporta en una tabla aparte, nunca
mezclado.

## 3. Calendario de hitos

Fechas y pesos tomados de `planeacion/mapa-evaluacion.md` y `planeacion/calendario-27-1.md`.

| Hito | Fecha y hora | Qué se evalúa | Peso | Rúbrica |
|---|---|---|---|---|
| H0 · Propuesta | lunes 14 de septiembre de 2026 | Problema, datos, por qué es paralelizable, versiones | Ya entregado (no forma parte del mapa del 2.º y 3.er parcial) | — |
| **H1 · Avance 1** | **jueves 29 de octubre, 10:30–12:00, en clase** (S13, salón 3208) | V1 con pruebas, diseño por Foster, perfil de línea base, plan de V2 | **12 % del 2.º parcial** | `proyecto/hitos/H1-avance-1.md` |
| **H2 · Avance 2** | **lunes 23 de noviembre, 10:30–12:00, en clase** (U5·S01, salón 3208) | V2 correcta, *speedup*/eficiencia, Karp–Flatt, decisiones justificadas | **15 puntos** del proyecto | `proyecto/hitos/H2-avance-2.md` |
| **Entrega final · repositorio** | **lunes 7 de diciembre, 10:30** (etiqueta `entrega-final` antes de esa hora) | V1 · V2 · V3 completas, reproducibles, con mediciones | **40 puntos** | `proyecto/entrega-final/rubrica-codigo.md` |
| **Entrega final · reporte** | **lunes 7 de diciembre, 10:30** | `reporte/reporte.pdf` (8–12 páginas) | **30 puntos** | `proyecto/entrega-final/rubrica-reporte.md` |
| **Defensa oral** | **jueves 10 de diciembre, 10:30–12:00** | 12 min por equipo + demo en vivo + preguntas individuales | **15 puntos** (ajusta la calificación individual) | `proyecto/defensa/rubrica-defensa.md` |

Suma del proyecto: 15 + 40 + 30 + 15 = **100 puntos = 40 % del 3.er parcial**. Todas las rúbricas están publicadas
en las carpetas indicadas antes de su entrega, como pide `planeacion/mapa-evaluacion.md` (versión vigente: 20 de
octubre de 2026).

Sesiones de clase dedicadas al proyecto (además de las recepciones): taller "cómo paralelizar la V1" el
martes 27 de octubre (U3·S12), taller hacia H2 el jueves 19 de noviembre (U4·S06), taller de V3 el martes
1 de diciembre (U5·S05), lista de cotejo de la entrega final entre equipos el jueves 3 de diciembre (U5·S06) y
ensayo de defensa el lunes 7 de diciembre (C1). En los talleres se trabaja con la lista de cotejo del hito
siguiente y el profesor pasa por cada equipo con dos preguntas fijas: "¿qué midieron?" y "¿qué no entienden
todavía?".

Fechas vecinas que debes tener en el calendario del equipo: Práctica 4 domingo 1 de noviembre 23:59; Examen 2
martes 3 de noviembre 08:30; Práctica 5 **domingo 22 de noviembre 23:59** (la noche anterior a H2); Práctica 6
**domingo 6 de diciembre 23:59** (la noche anterior a la entrega final); Examen 3 martes 8 de diciembre 08:30
(el día siguiente a la entrega final). Por eso:

- Las secciones de V1 y V2 del reporte final son las de H1 y H2 **corregidas** con su retroalimentación; el reporte
  final solo agrega la V3 y la integración (`docs/metodo/04-evaluacion.md` §5). Corrige la de V1 en cuanto llegue la
  retroalimentación de H1 (a más tardar el jueves 5 de noviembre) y la de V2 en la semana en que llega la de H2 (a
  más tardar el lunes 30 de noviembre), no el fin de semana del 5–6 de diciembre.
- La V3 se mide en la semana del 30 de noviembre (taller del martes 1 de diciembre), no el fin de semana del 5–6
  de diciembre (`docs/metodo/04-evaluacion.md` §5).

### Logística de la defensa (decisión pendiente del profesor)

Con ~35 estudiantes hay ~12 equipos. La sesión del jueves 10 de diciembre dura 90 min (80 útiles, descontando
apertura y cierre) y solo la exposición ya pide 12 × 12 = 144 min. Con las preguntas individuales y el cambio de
equipo, el formato completo ocupa unos 17 min por equipo de 3. Los números completos, el sorteo del orden y el
plan B de la demo están en `proyecto/defensa/logistica-defensa.md`. Las opciones:

| Opción | Cómo queda | Costo |
|---|---|---|
| (a) Formato completo en más sesiones | 12 min + 2 preguntas por integrante + 1 min de cambio: caben 4 equipos por sesión. Con 12 equipos: jueves 10, lunes 14 (reserva) y martes 15 08:30 (reserva); con ≤ 8 equipos bastan el jueves y el lunes | Ocupa las reservas previstas para la retroalimentación del Examen 3 y del proyecto (lunes 14) y para defensas pendientes y segunda entrega de P6 (martes 15), que pasan al jueves 17; los equipos defienden con hasta 5 días de diferencia |
| (b) Formato corto | 7 min de exposición + 3 min de preguntas (2 por integrante, 30 s) + 1 min de cambio = 11 min: 12 equipos = 132 min, caben en el jueves 10 (6) y el lunes 14 (6); en una sola sesión solo con ≤ 7 equipos | Una decisión medida en lugar de dos y menos tiempo para resultados; el ensayo del 7 de diciembre ya debe hacerse con 7 min; el lunes 14 sigue ocupado |
| (c) Mixta | En clase, 2 min de demo + preguntas individuales (≈ 6.5 min por equipo de 3 con el cambio, 5.5 con uno de 2: once equipos de 3 y uno de 2 = 77 min, cabe en el jueves 10 con 3 min de holgura; doce de 3 = 78 min, 2 de holgura); la exposición va en video. Así se planteó al principio: video de 12 min antes del jueves 10 de diciembre 10:30. `docs/metodo/04-evaluacion.md` §3.2 la recomienda con dos ajustes: video de ≤ 8 min, enlazado en el repositorio antes del lunes 7 de diciembre 10:30, junto con la entrega final; esa es la versión que desarrolla `logistica-defensa.md` | La exposición no es en vivo; una pregunta individual por integrante (la segunda solo como rescate); poca holgura; el video se suma a la carga del fin de semana del 5–6 de diciembre, salvo que se anuncie desde el 23 de noviembre |

El profesor elige y lo anuncia a más tardar el jueves 3 de diciembre (U5·S06), de preferencia desde el lunes 23
de noviembre (H2), para que el ensayo del lunes 7 de diciembre se haga con el formato real. Con cualquier opción:
el orden se sortea con semilla publicada el lunes 7 de diciembre; la demo corre desde un clon de la etiqueta
`entrega-final`; cada equipo graba, entre la etiqueta y el miércoles 9 de diciembre 20:00, un video de plan B de
≤ 3 min por si falla la demo en vivo (`logistica-defensa.md` §8); la defensa pendiente por causa justificada se
recibe el martes 15 de diciembre 08:30.

## 4. Estructura obligatoria del repositorio del equipo

Es la estructura de la entrega final (`proyecto/entrega-final/README.md` §3), la que revisa
`proyecto/entrega-final/scripts/verificar_entrega.sh`. Se adopta **desde H1**: así no se reorganiza nada en
diciembre. El camino más corto es copiar `proyecto/entrega-final/plantilla-repo/` (compila, prueba y mide desde el
primer *commit*; su cómputo es un marcador de posición que se sustituye por el problema del equipo) y agregar las
plantillas de `proyecto/plantillas/` (ver su `README.md`).

```
cp-6bm1-equipoNN/
├── README.md              Problema, datos y semilla, integrantes y reparto, tamaño declarado, cómo compilar,
│                          probar y medir, hardware, uso de IA
├── Makefile               all · run · test · clean; llama a v1/ y v2/; `make test` corre tests/run_tests.sh
├── run_all.sh             Reproduce las mediciones de resultados/ en un comando; acepta --rapido (entrega final)
├── comun/                 (opcional) lo que comparten V1, V2 y V3: datos con semilla, checksum, cómputo por elemento
├── v1/                    C secuencial · main.c · Makefile (all/run/test/clean)                       desde H1
├── v2/                    C + OpenMP · main.c · Makefile                                               desde H2
├── v3/                    .cu o .py · Makefile · notebook_colab.ipynb EJECUTADO                        entrega final
├── tests/run_tests.sh     V2 y V3 contra V1 con tolerancia; casos de los tres tipos; casos propios del equipo
├── herramientas/          medir_proyecto.sh y graficar_proyecto.py (de proyecto/plantillas/); otros scripts
├── datos/                 Entrada o script que la genera o descarga (nada > 10 MB en git)
├── resultados/            mediciones.csv · experimentos.csv · perfil-v1.csv · entorno.txt · *.png · tabla.md
│                          (entrega final, además: mediciones_v3.csv y entorno_gpu.txt del notebook)
├── reporte/               diseno-foster.md · H1.md · H2.md · reporte.pdf (y su fuente .md o .tex)
├── bitacora.md            Plantilla: proyecto/plantillas/bitacora-errores.md
└── declaracion-ia.md      Plantilla: proyecto/plantillas/declaracion-ia.md
```

| Elemento | Regla |
|---|---|
| `README.md` | Alguien que no es del equipo debe poder clonar, compilar, probar y medir siguiendo solo el README. Incluye la tabla "tamaño de prueba / tamaño declarado" (`hitos/H1-avance-1.md` §2.1) y el hardware. En la entrega final sigue las secciones de `proyecto/entrega-final/plantilla-repo/README.md` |
| `Makefile`, `v1/`, `v2/`, `v3/` | Cada carpeta de versión compila sola con su `Makefile` (`all`, `run`, `test`, `clean`); el `Makefile` raíz las llama. `make test` en la raíz termina con código 0 si pasa y distinto de 0 si falla. Sin *warnings* con `-Wall -Wextra`. Identificadores en inglés, comentarios y mensajes en español (`docs/CONVENCIONES.md` §3) |
| Programas | Contrato de la entrega final desde H1: argumentos `[n] [semilla] [hilos]`; salida `clave=valor` con `tiempo_s=` (solo la región de interés) y `checksum=`; la V3 además `tiempo_kernel_s=` y `tiempo_total_s=`. Esqueletos: `proyecto/plantillas/plantilla_main.c` o `plantilla-repo/v1/main.c` |
| `run_all.sh` (raíz) | Un comando que regenera las mediciones de `resultados/`. El de `plantilla-repo/` hace entorno → `make` → `make test` → V1 y V2 → CSV → tabla y gráfica, y con `--rapido` prueba el flujo en segundos sin tocar `resultados/`. Para medir una configuración a la vez (perfil, experimentos, Colab) se usa `herramientas/medir_proyecto.sh` |
| `resultados/` | CSV con las columnas del protocolo, el entorno de cada máquina y las gráficas. Nada que no se pueda regenerar con los comandos escritos en el README o en `reporte/H1.md` y `reporte/H2.md`. Un CSV por máquina. Qué archivo produce cada herramienta y cuál revisa cada entrega: `proyecto/medicion-en-el-proyecto.md` §7.4 |
| `reporte/` | Los documentos de los hitos se quedan: el reporte final los cita y los corrige, no los reescribe |
| `bitacora.md` | Una entrada por falla que costó más de 15 minutos, con fecha `AAAA-MM-DD` en la primera columna; también mediciones descartadas y predicciones vs. resultados |
| `declaracion-ia.md` | Una sección por entrega con las cuatro líneas de la política de IA; la última ("qué nos dijo mal") no es opcional |
| `.gitignore` | Binarios (`v1/v1`, `v2/v2`, `v3/v3`, `*.out`, `*.o`) y sus variantes de perfil y de experimento (`v1/v1_perfil`, `v2/v2_static`…), `resultados/rapido/`, `__pycache__/`. Ningún binario versionado |
| Etiquetas de git | `H1`, `H2` y `entrega-final`, creadas y empujadas antes de la hora de cada entrega. El profesor califica lo que está en la etiqueta |

## 5. Políticas de equipo e integridad

| Tema | Regla | Razón |
|---|---|---|
| *Commits* | Cada integrante trabaja con su propio usuario de GitHub. `main` siempre compila. No se aceptan repositorios donde un integrante sube el trabajo de todos al final | El historial es la evidencia de participación individual (`docs/metodo/01-marco-pedagogico.md`, P11) |
| Reparto de trabajo | Se declara en el `README.md` (quién hizo qué, por archivo y sección) y se actualiza en cada hito. Es la base de las preguntas individuales: a cada quien se le pregunta primero por la parte que firmó. El reparto no exime: todos deben poder explicar todo | Prueba de propiedad |
| Uso de IA | Semáforo de `docs/metodo/05-politica-ia.md`. Verde: explicar, generar preguntas, depurar con pistas. Amarillo: fragmentos ≤ 10 líneas reescritos y declarados, revisión de carreras, gráficas con tus datos. Rojo: pedir una versión completa o una función completa, inventar o "mejorar" mediciones, entregar texto sin revisar | Quien usa la IA para no pensar rinde peor en el examen sin ayuda (`05`, Bastani et al., 2025) |
| Código idéntico entre equipos | Sin explicación: 0 en la entrega para todos los involucrados y reporte según reglamento; el equipo de origen conserva su calificación si el historial de su repositorio privado muestra que no lo compartió (`docs/metodo/04-evaluacion.md` §6) | Integridad académica |
| Mediciones | Inventar, seleccionar o alterar mediciones tiene la misma consecuencia que el plagio. Las corridas descartadas se anotan en la bitácora, no se borran | Mediciones reproducibles o no cuentan |
| Entregas tardías | Los hitos se reciben en clase con la etiqueta creada antes de las 10:30. Etiqueta creada hasta 72 h después: máximo 80 %. Después de 72 h no se recibe salvo justificante institucional. Un hito no entregado no bloquea el siguiente, pero su porcentaje se pierde (`docs/metodo/04-evaluacion.md` §5) | Fechas firmes con ventana definida |
| Recepción en clase | Si un integrante no está en la sesión de recepción, su pregunta individual se hace en asesoría dentro de las mismas 72 h, con tope de 80 % en su criterio individual; con justificante institucional, en la siguiente sesión y sin tope | Responsabilidad individual |
| Respuesta por escrito | Quien lo pida, sin dar razones, responde su pregunta individual por escrito en el momento (5 min, papel, sin dispositivos); vale igual (`docs/metodo/05-politica-ia.md`) | Que la evaluación mida lo que sabes, no los nervios |
| Cambios al problema | Antes de H2 (lunes 23 de noviembre): solo con acuerdo del profesor (asesoría o *issue* en el repositorio) y la razón técnica escrita en la bitácora y en el `README.md`; si el cambio llega después de H1, se rehace el perfil de H1 con el problema nuevo. Después de H2: no. El tamaño `n` y los datos sí pueden ajustarse en cualquier momento si quedan declarados y las tres versiones usan los mismos (`proyecto/entrega-final/faq-entrega.md` §5) | H1 fija la línea base; cambiar el problema después invalida el perfil y la comparación |
| Cambios en el equipo | Si un integrante deja de participar, el equipo lo informa por escrito al profesor en la semana en que ocurre. El alcance se renegocia; el historial de *commits* decide la calificación de quien se retiró | Equidad |
| V3 y la cuota de GPU | La correctitud de V3 se verifica sin GPU y nunca depende de la cuota. Si Colab y Kaggle niegan GPU en las 48 h previas a la entrega final, el equipo entrega a tiempo con la captura fechada del aviso de cuota y la medición marcada como pendiente, y la completa a más tardar el martes 15 de diciembre 08:30, sin penalización. Antes del martes 24 de noviembre cada integrante verifica que obtiene GPU en Colab y en Kaggle (pre-laboratorio de P6) | `docs/metodo/04-evaluacion.md` §5: nadie depende de una cuota que no controla |
| Datos | Si los datos son de terceros, se cita la fuente y la licencia en el `README.md`. Datos personales: no | Reproducibilidad y legalidad |

## 6. Cómo se califica individualmente

La calificación del proyecto de cada integrante parte de la del equipo y se mueve solo por estos mecanismos:

1. **Calificación del equipo.** Cada pieza (H1, H2, repositorio final, reporte, defensa) se califica con su rúbrica
   y produce un puntaje para el equipo.
2. **Proceso e integridad en H1 y H2 (por integrante).** El criterio 5 de cada hito (15 de los 100 puntos de su
   rúbrica) se asigna por persona: en la recepción cada quien responde una pregunta sobre la parte que firmó en el
   reparto; si falla, una segunda sobre otra línea, y cuenta la mejor de las dos. Quien no puede explicar su parte
   queda en Insuficiente en ese criterio, aunque el equipo quede en Ejemplar en los demás. H1 cuenta en el 2.º
   parcial; H2, en el proyecto.
3. **Proceso en el repositorio final (por integrante).** El criterio C6 de `proyecto/entrega-final/rubrica-codigo.md`
   (historial de *commits* y bitácora, 4 puntos) baja a Insuficiente para quien tenga participación marginal sin
   explicación en el reparto o no pueda explicar en la defensa una línea que el equipo entregó.
4. **Respuestas individuales en la defensa (por integrante).** El criterio D4 de
   `proyecto/defensa/rubrica-defensa.md` (30 de los 100 puntos de esa rúbrica = 4.5 puntos del proyecto) se asigna
   a cada persona con dos preguntas sin ayuda del equipo; la primera es sobre la parte que firmó.
5. **Ajuste por desconocimiento del código propio.** Cada respuesta individual de la defensa en nivel Insuficiente
   resta **10 %** de los 100 puntos del proyecto de esa persona, con un máximo de dos (**−20 %**). Una respuesta En
   desarrollo no lo activa: solo baja D4 (`rubrica-defensa.md` §4.1). El cálculo aplica además el tope de
   `docs/metodo/04-evaluacion.md` §3.2: estos ajustes nunca dejan a una persona más de 20 puntos por debajo de la
   referencia del equipo (`defensa/logistica-defensa.md` §7).

La calificación de una persona nunca baja por las respuestas de otro integrante. No hay ajustes no escritos. Si
crees que la calificación individual no refleja tu trabajo, el canal es la retroalimentación escrita de cada pieza
(≤ 7 días) y la asesoría.

## 7. Preguntas frecuentes

**¿Podemos cambiar de problema después de H0?** Antes de H2, solo con acuerdo del profesor y una razón técnica
escrita; después de H2, no (§5). El tamaño y los datos sí pueden ajustarse si quedan declarados.

**¿Tenemos que usar `entrega-final/plantilla-repo/`?** No. Lo obligatorio es la estructura de §4 y el contrato de
los programas. La plantilla es el camino más corto porque ya los cumple: compila, prueba, mide y pasa
`verificar_entrega.sh` con un cómputo de relleno que ustedes sustituyen.

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
medición, porque el hardware asignado cambia. Guarda en el repositorio el *notebook* ejecutado, el CSV y el entorno
antes de cerrar la sesión: el sistema de archivos de Colab se borra.

**¿Y si Colab y Kaggle no nos dan GPU?** La correctitud de V3 no depende de la cuota (se prueba sin GPU). Si se
niega la GPU en las 48 h previas a la entrega final, entregas a tiempo con la captura fechada y completas la
medición a más tardar el martes 15 de diciembre 08:30, sin penalización (§5). Por eso conviene medir la V3 en la
semana del 30 de noviembre.

**¿CUDA C, Numba o CuPy?** El que el equipo pueda explicar línea por línea en la defensa. CUDA C es lo que se ve en
clase; Numba te deja escribir el *kernel* en Python con el mismo modelo de hilos/bloques y probarlo sin GPU con
`NUMBA_ENABLE_CUDASIM=1`; CuPy sirve si escribes el núcleo con `RawKernel`/`ElementwiseKernel` o puedes explicar
qué corre en la GPU en cada operación.

**¿Cómo comparo la GPU de Colab con mi CPU si son máquinas distintas?** Lo honesto es correr también V1 en la CPU
de Colab y reportar ese *speedup* como el principal; la comparación con tu laptop va aparte y se llama
"comparación entre máquinas". Detalle en `proyecto/medicion-en-el-proyecto.md` §6.

**¿Puedo usar IA para escribir el reporte?** Para organizarlo y revisarlo, sí (verde). Para generar secciones que
nadie del equipo revisó, no (rojo). En la defensa se pregunta sobre el texto.

**¿Cuánto cuenta H1 en el 3.er parcial?** Nada: H1 es 12 % del 2.º parcial. En el 3.er parcial cuentan H2 (15),
repositorio (40), reporte (30) y defensa (15).

**¿Se entrega un video?** Sí, uno en cualquier opción: el video de plan B de la demo (≤ 3 min, grabado entre la
etiqueta `entrega-final` y el miércoles 9 de diciembre 20:00; `defensa/logistica-defensa.md` §8). Si el profesor
elige la opción (c) de §3, además la exposición en video (≤ 8 min, con la entrega final).

**¿Qué hago si un integrante no responde ni hace *commits*?** Avisa por escrito al profesor la misma semana. El
alcance del equipo se renegocia y el historial decide la calificación de esa persona. No cargues con su parte en
silencio: eso perjudica a los que sí trabajan.

**¿Dónde pido ayuda?** En asesoría, siguiendo el protocolo del curso: primero escribes qué intentaste y qué
observaste (la bitácora sirve para eso); después se atiende.

## 8. Dónde está cada cosa en esta carpeta

| Archivo | Contenido |
|---|---|
| `README.md` | Este documento |
| `hitos/H1-avance-1.md` | H1: qué se entrega, rúbrica de 100 puntos (× 0.12 = 12 % del 2.º parcial), lista de cotejo, preguntas de la recepción, errores típicos, logística de S13 |
| `hitos/H2-avance-2.md` | H2: qué se entrega, rúbrica de 100 puntos (× 0.15 = 15 puntos del proyecto), lista de cotejo, preguntas, errores típicos, logística de U5·S01 |
| `medicion-en-el-proyecto.md` | Cómo aplicar el protocolo de medición a tu problema: tamaños, corridas, V1 vs V2 vs V3, transferencias, Colab vs CPU propia, qué archivo produce cada herramienta, plantillas de tabla y gráfica, errores que invalidan |
| `plantillas/` | Bitácora, declaración de IA, `run_all.sh` (se copia como `herramientas/medir_proyecto.sh`), `graficar_proyecto.py`, esqueleto de programa medible, `Makefile` y pruebas (`make test`) |
| `entrega-final/` | Rúbricas del repositorio (40 puntos, `rubrica-codigo.md`) y del reporte (30 puntos, `rubrica-reporte.md`), `plantilla-reporte.md`, `reproducibilidad.md`, `lista-cotejo-entrega.md`, `faq-entrega.md`, repositorio plantilla (`plantilla-repo/`) y `scripts/verificar_entrega.sh` |
| `defensa/` | `rubrica-defensa.md` (15 puntos; D4 y el ajuste individual), `guion-defensa.md` (los 12 minutos por bloques), `logistica-defensa.md` (opciones, sorteo del orden, plan B), `banco-preguntas-individuales.md`, `lista-cotejo-pares.md` (ensayo del 7 de diciembre) y `scripts/` (`sortear_orden.py`, `calificar_defensa.py`) |
