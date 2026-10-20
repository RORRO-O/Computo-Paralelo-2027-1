# Guion de la defensa oral · 12 minutos + preguntas individuales

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Defensa oral · jueves 10 de diciembre de 2026 · 10:30–12:00 · Salón 3208 · 15 de los 100 puntos del proyecto (`rubrica-defensa.md`) · versión 1.1 · 20 de octubre de 2026

## 1. En una tabla

| Qué | Detalle |
|---|---|
| Fecha y hora | **Jueves 10 de diciembre de 2026, 10:30–12:00** (sesión C2, salón 3208). Según la opción de `logistica-defensa.md` §3 que elija el profesor (anuncio a más tardar el jueves 3 de diciembre), una parte de los equipos defiende el **lunes 14 de diciembre, 10:30–12:00** y, con la opción (a) y más de 8 equipos, el **martes 15 de diciembre, 08:30–10:00** (sesiones de reserva). El orden y la sesión de cada equipo salen del sorteo con semilla publicada, que se corre en clase el lunes 7 de diciembre |
| Peso | **15 de los 100 puntos del proyecto** (el proyecto es 40 % del 3.er parcial, `planeacion/mapa-evaluacion.md`). Rúbrica de 100 puntos × 0.15. El criterio de respuestas individuales (D4) se asigna **por integrante**, y cada respuesta tuya en Insuficiente baja 10 % tu calificación individual del proyecto, hasta 20 % (`rubrica-defensa.md` §4.1) |
| Formato | **12 minutos** cronometrados de exposición con demo en vivo (1 + 3 + 4 + 2 + 2); el profesor corta a los 12:00. Después, **preguntas individuales: 2 por integrante**, sin ayuda del equipo. Si el profesor elige la opción (b) o (c), los tiempos cambian como dice §2 |
| Qué se defiende | Lo que está en la etiqueta `entrega-final` (lunes 7 de diciembre, 10:30; una etiqueta tardía vale hasta el jueves 10 de diciembre 10:30, con tope de 80 % en repositorio y reporte). El código no cambia entre la entrega y la defensa; la demo corre desde un **clon de esa etiqueta**, no desde la carpeta de trabajo |
| Zona sin IA | `docs/metodo/05-politica-ia.md`: sin teléfonos, sin asistentes, sin notas. La única máquina encendida del equipo es la de la demo. Las preguntas se responden con el código del repositorio en pantalla |
| Ensayo | **Lunes 7 de diciembre, 10:30–12:00** (sesión C1), por parejas de equipos, con `lista-cotejo-pares.md` |
| Plan B de la demo | Video de ≤ 3 minutos grabado entre la creación de la etiqueta y el **miércoles 9 de diciembre, 20:00**, enlazado en un *issue* del repositorio (`logistica-defensa.md` §8). Solo se usa si la demo en vivo falla y el profesor lo pide |
| Banco de preguntas | `banco-preguntas-individuales.md`: público. Prepárate con él sobre **tu** repositorio, no memorizando respuestas |

## 2. Los 12 minutos, bloque por bloque

Reglas de tiempo: el cronómetro arranca cuando el primer integrante empieza a hablar. Si un bloque se alarga, se
recorta el siguiente, nunca la demo. A los 12:00 el profesor dice "tiempo" y pasa a las preguntas con lo que se haya
mostrado. Cada integrante habla **al menos 2 minutos**; quién teclea la demo lo decide el profesor al llegar al
minuto 10 (cualquier integrante debe poder hacerlo).

| Minuto | Bloque | Qué se ve en pantalla | Qué se dice (mínimo) | Qué NO | Criterio |
|---|---|---|---|---|---|
| 0:00–1:00 | **Problema** | 1 diapositiva: nombre del problema, entrada (origen, `n`, semilla), salida, `T(1)` de V1 | Qué se calcula, en una frase. Por qué es paralelizable (qué tareas son independientes y qué dependencia queda). Cuánto tarda V1 con el `n` declarado y en qué CPU | Historia del algoritmo; motivación; repetir la propuesta H0 | D1 |
| 1:00–4:00 | **Diseño y decisiones** | Diagrama **propio** de Foster + tabla "tarea → datos que toca → dependencias"; 1 diapositiva con el mapeo V2 (hilos) vs V3 (bloques e hilos CUDA); la tabla de decisiones con medianas; 1 fragmento clave de ≤ 15 líneas por versión paralela (texto, no captura) | Partición: qué es una tarea y cuántas hay. Comunicación: qué patrón y dónde aparece como sincronización. Aglomeración: cuántas tareas junta cada hilo o cada bloque y por qué ese tamaño. Mapeo: qué cambió entre V2 y V3. **Dos decisiones con alternativas medidas** (p. ej. `schedule`, reducción vs `atomic`, tamaño de bloque): opción elegida, mediana de cada opción, costo de la descartada | Definiciones de libro; "usamos `parallel for`" sin razón; listados completos de código | D1 |
| 4:00–8:00 | **Resultados V2/V3 y análisis honesto** | Figura 1: *speedup* vs hilos con línea ideal `S = p` y barras mín–máx. Tabla 1 (V1, V2 por hilos: mediana, mín, máx, *speedup*, eficiencia, Karp–Flatt). Tabla 2 (V3 sin y con transferencias contra la V1 **de la misma máquina**, GPU y fecha) | `T(1)` = V1 y cuánto. `S(p)`, `E(p)` y `f(p)` para cada `p`; tendencia de `f`. *Speedup* máximo según Amdahl con la fracción **medida** en V1 contra el obtenido. Dónde deja de escalar V2 y **una causa verificable** (experimento o número, no "la laptop"). V3: *speedup* sin y con transferencias; porcentaje del tiempo que son transferencias; a partir de qué `n` conviene la GPU. Predicción escrita antes de medir vs resultado. Lo que no saben explicar, dicho como tal | Mostrar solo la mejor corrida; comparar contra V2 con 1 hilo; celebrar *speedup* superlineal sin explicarlo; esconder que V3 es más lenta que V2; números que no están en `resultados/*.csv` | D2 |
| 8:00–10:00 | **Qué falló y qué aprendieron** | 2–3 entradas de `bitacora.md` (síntoma, cómo se detectó, causa, cambio); la lista "qué no entendemos todavía"; la línea "qué nos dijo la IA que resultó estar mal" | Para cada entrada: qué herramienta o prueba la detectó (`make test`, TSan, comparación con V1, `cudaGetLastError`, una gráfica sin sentido) y qué prueba agregaron. Una medición descartada y por qué. **Al menos dos preguntas concretas** que siguen abiertas y qué experimento las respondería | Errores de compilación triviales; "todo salió bien"; "aprendimos mucho" | D2 |
| 10:00–12:00 | **Demo en vivo** | Terminal en el clon de `entrega-final`; pestaña del navegador con el *notebook* ejecutado en GitHub | Ver §3. Lo que corre tiene que coincidir con la Tabla 1 en orden de magnitud y forma | Correr desde la carpeta de trabajo; tamaños que tardan minutos; "en mi máquina sí corría" | D3 |

**Qué significa "análisis honesto" en este curso.** Cada afirmación tiene detrás un número de `resultados/*.csv` que
el profesor puede abrir en ese momento. Lo que no se sabe se dice ("no sabemos por qué `f` sube de 0.08 a 0.21 entre
4 y 8 hilos; lo que probamos fue X y descartó Y"). Un resultado malo bien explicado vale más que uno bueno sin
explicación (`proyecto/entrega-final/faq-entrega.md` §1).

**Si el profesor elige otro formato** (`logistica-defensa.md` §3; se anuncia a más tardar el jueves 3 de diciembre y se
ensaya así el lunes 7):

| Bloque | Completo (este guion) | Opción (b): 7 min | Opción (c): video ≤ 8 min + clase |
|---|---|---|---|
| Problema | 0:00–1:00 | 0:00–0:30 | En el video, con los mismos contenidos de los bloques 1–4 |
| Diseño y decisiones | 1:00–4:00, dos decisiones medidas | 0:30–2:00, **una** decisión medida | En el video |
| Resultados V2/V3 | 4:00–8:00 | 2:00–4:30 | En el video |
| Qué falló | 8:00–10:00 | 4:30–5:30 | En el video |
| Demo | 10:00–12:00 | 5:30–7:00; el *notebook* solo si sobra tiempo | En clase, 2:00 |
| Preguntas individuales | 2 por integrante, ≤ 40 s cada una | 2 por integrante, ≤ 30 s cada una | 1 por integrante; la segunda solo como rescate |

La rúbrica es la misma en los tres formatos: lo que no se alcanza a mostrar no se evalúa.

## 3. La demo en vivo (minuto 10:00–12:00)

Prepara **antes de la sesión** un clon limpio en la laptop de la demo (o en la máquina del salón, si el profesor lo
indica en `logistica-defensa.md`):

```bash
git clone https://github.com/<organizacion-o-usuario>/cp-6bm1-equipoNN cp-6bm1-equipoNN-defensa
cd cp-6bm1-equipoNN-defensa
git checkout entrega-final
make            # compila V1 y V2 (y verifica V3 con nvcc -c si hay nvcc); sin warnings
make test       # una vez, para que la segunda corrida no sea en frío
```

Durante la demo, en este orden y con este presupuesto:

| Segundos | Comando | Qué debe verse | Si no se ve |
|---|---|---|---|
| 0–20 | `git describe --tags --exact-match` y `git status --short` | `entrega-final` y ninguna línea de cambios | D3 baja a En desarrollo: la demo no corresponde a la entrega |
| 20–60 | `make test` y después `echo $?` | Líneas `PASS` de V2 contra V1 (y de V3, si se puede verificar en la laptop: espejo en CPU o `NUMBA_ENABLE_CUDASIM=1`) y `0`, en ≤ 40 s (tamaño de prueba) | Explica qué falla y por qué; sigue con el resto |
| 60–100 | `./v1/v1 <n_demo> <semilla>`, `./v2/v2 <n_demo> <semilla> 1` y `./v2/v2 <n_demo> <semilla> <p>` (`p` = núcleos físicos de la laptop; contrato `[n] [semilla] [hilos]` de `proyecto/README.md` §4) | `tiempo_s=` en las tres corridas y `checksum=` igual en las tres (dentro de la tolerancia declarada); tiempos con la misma forma que la Tabla 1 (V2 con `p` hilos claramente menor que V1) | Di qué tamaño usas y por qué los tiempos difieren de la tabla (otra máquina, tamaño de demo) |
| 100–120 | Pestaña de GitHub con `v3/notebook_colab.ipynb` **ejecutado** | Salida de `!nvidia-smi` con el modelo de GPU y la fecha; celda de verificación con `PASS v3 == v1`; celda de medición con `tiempo_kernel_s` y `tiempo_total_s` | Sin *notebook* ejecutado no hay evidencia de V3: D3 no pasa de En desarrollo |

**Tamaño de demo.** El que haga que V1 tarde entre 1 y 5 s en la máquina de la demo (`proyecto/medicion-en-el-proyecto.md`
§2: "segundos, no minutos"). Si el tamaño declarado cumple eso, úsalo; si no, declara el tamaño de demo en el guion y dilo.
No se corre Colab en vivo: la evidencia de V3 es el *notebook* ejecutado y guardado en el repositorio.

**Si la demo falla.** Tienes 60 segundos para recuperarla. Si no, el profesor pide el video del plan B (≤ 3 min, ya
abierto en la laptop) y la rúbrica aplica el tope de D3 (`rubrica-defensa.md` §4.2). Si la falla es de la sala (proyector,
corriente), no del equipo, la demo se repite al final de la sesión sin penalización.

## 4. Las preguntas individuales (después del minuto 12)

| Qué | Cómo |
|---|---|
| Cuántas | **2 por integrante**. Formato completo: hasta 40 s por respuesta. Formato corto (opción b de la logística): hasta 30 s. Opción (c): 1 por integrante y la segunda solo como rescate |
| Quién responde | La persona a la que se dirige la pregunta. El equipo no ayuda, no completa, no corrige. Si otro integrante interviene, la respuesta se califica como la dio la persona antes de la intervención |
| Pregunta 1 | Sobre la parte que **esa persona firmó** en el reparto (`README.md` §6 del repositorio y §11 del reporte). El profesor pone una línea, un `#pragma`, una función o un *kernel* en pantalla y usa uno de los tres patrones de línea del banco (`banco-preguntas-individuales.md` §1): "¿qué hace y qué pasa si la quito?", "¿por qué así y no de otra forma?", "¿dónde se mide y qué queda fuera?" |
| Pregunta 2 | Del banco, con el tema sorteado para esa posición del equipo (Foster, OpenMP, medición, MPI, CUDA o decisiones del equipo). El sorteo de temas se publica junto con el orden (`logistica-defensa.md` §4). La pregunta exacta la elige el profesor sobre tu proyecto. **Rescate:** si tu pregunta 1 quedó en Insuficiente, la pregunta 2 es otra línea de tu parte firmada, no el tema (`docs/metodo/05-politica-ia.md`) |
| Con qué | Con el repositorio en pantalla. Sin notas, sin teléfono, sin consultar al equipo. Puedes abrir el archivo que haga falta |
| Reformulación | Si la pregunta no se entendió, el profesor la reformula **una vez**. La respuesta que cuenta es la que das después |
| Por escrito | Puedes pedir, sin dar razones, responder tus dos preguntas por escrito en el momento: 5 minutos, papel, sin dispositivos, en una mesa aparte mientras sigue la sesión. Vale igual (`docs/metodo/05-politica-ia.md`) |
| Qué se evalúa | Que puedas explicar código, mediciones y decisiones de tu propio repositorio: qué hace, por qué está ahí, qué pasaría si cambia. No se evalúa fluidez ni vocabulario |
| Qué cuenta como desconocimiento | No poder decir qué hace la línea o el *kernel* que firmaste; contradecir el código que está en pantalla; describir código que no está en el repositorio; atribuir la línea a otro integrante o a "la IA" sin poder explicarla; responder con generalidades ("paraleliza"); o no responder. Cada respuesta así (también la de rescate) baja tu calificación individual del proyecto 10 %, hasta 20 % con dos (`rubrica-defensa.md` §4.1). Si además fallas la pregunta 1 y la de rescate, el criterio C6 del repositorio baja a Insuficiente para ti. Una respuesta incompleta (En desarrollo) solo baja D4 |

## 5. Qué llevar

**El equipo (una sola laptop):**
- [ ] Clon limpio de `entrega-final` ya compilado y con `make test` corrido una vez (§3). Verificado con
      `bash proyecto/entrega-final/scripts/verificar_entrega.sh <clon>` en el ensayo del lunes 7 de diciembre.
- [ ] Diapositivas (≤ 8, legibles desde la última fila: nada menor a 18 pt; una figura o tabla por diapositiva) en PDF
      **local**, no en la nube.
- [ ] `reporte/reporte.pdf` abierto en la Tabla 1, la Tabla 2 y la Figura 1.
- [ ] Pestaña de GitHub con el *notebook* ejecutado y `resultados/` del repositorio.
- [ ] `bitacora.md` abierto.
- [ ] Video del plan B (≤ 3 min, formato mp4) **en la laptop**, y su enlace en el *issue* del repositorio
      (`logistica-defensa.md` §8).
- [ ] Adaptador a HDMI de la laptop y cargador. Si la laptop no tiene salida de video, avísalo en el ensayo del lunes 7
      de diciembre para usar la máquina del salón.
- [ ] Este guion impreso o en una hoja, con los números de §7 llenos.

**Cada integrante:**
- [ ] Haber corrido, él o ella misma, `make test` y la demo completa en la laptop del equipo al menos una vez.
- [ ] Haber respondido en voz alta, sin notas, las preguntas del banco de **todos** los temas sobre este repositorio.
- [ ] Saber dónde está en el repositorio cada archivo que se nombra en la exposición.

## 6. Qué no hacer

| No | Por qué (y qué pasa) |
|---|---|
| Leer las diapositivas o un papel | D1 En desarrollo. La exposición demuestra comprensión; la lectura no |
| Pegar listados completos de código o capturas de terminal como evidencia | Nadie los lee en 12 minutos; la evidencia es el CSV y la demo. D2 baja si los números no son de `resultados/` |
| Comparar contra V2 con 1 hilo sin decirlo, o cambiar `n` entre versiones | Invalida la medición (`herramientas/protocolo-medicion.md` §5). D2 Insuficiente |
| Decir "funciona" o "es más rápido" sin número | D2 En desarrollo. Todo adjetivo lleva un número |
| Culpar a "la laptop", "Colab" o "el compilador" sin un dato | Es una hipótesis, no una causa. Se dice qué experimento la confirmaría |
| Celebrar un *speedup* superlineal o esconder que V3 es más lenta que V2 | Ambas cosas se explican (caché; transferencias). Ocultarlas baja D2; explicarlas puede dar Ejemplar |
| Correr la demo desde la carpeta de trabajo o con un *commit* posterior a la etiqueta | D3 En desarrollo. Lo que se defiende es la entrega |
| Usar un tamaño que tarda minutos "para que se note el *speedup*" | El cronómetro no se detiene. Usa el tamaño de demo de §3 |
| Responder por un compañero, soplar, completar | La respuesta se califica como estaba antes de la intervención; la persona que intervino pierde su turno de reformulación |
| Consultar el teléfono, un asistente de IA o notas durante las preguntas | Zona sin IA. La pregunta se califica como Insuficiente y se trata como integridad académica (`docs/metodo/04-evaluacion.md` §6) |
| Hablar solo uno o dos integrantes | Con un integrante que habla menos de 2 minutos, D1 queda en En desarrollo; si habla uno solo, en Insuficiente (`rubrica-defensa.md` §3.1) |
| Pasarse de 12:00 | El profesor corta. Lo que no se mostró no existe para la rúbrica |
| Agregar diapositivas de "agradecimientos", índice o portada animada | Consumen tiempo que la rúbrica no paga |

## 7. Plantilla de guion (la llena el equipo; no va al repositorio)

Copia esta sección a una hoja o archivo local. Ensaya tres veces con cronómetro y anota los tiempos reales. Si un bloque
se pasa dos veces, recorta contenido, no hables más rápido.

```
GUION DE DEFENSA · Equipo NN · <problema en ≤ 8 palabras>
Fecha asignada por sorteo: [ ] jue 10 dic  [ ] lun 14 dic  [ ] mar 15 dic   Posición: __   Hora estimada de inicio: __:__
Laptop de la demo: <modelo> · Salida de video: [ ] HDMI [ ] USB-C+adaptador [ ] máquina del salón
Tamaño de demo n_demo = ______ (V1 tarda ____ s en la laptop de la demo) · semilla = ______

BLOQUE 1 · Problema (0:00–1:00) · Habla: ________ · Diapositiva: 1
  Qué se calcula (una frase): ____________________________________________
  Entrada: origen ________ · n = ________ · semilla ________ · Salida: ________
  Por qué es paralelizable (tareas independientes / dependencia que queda): ____________________
  T(1) de V1 con n declarado = ______ s en <CPU, núcleos físicos>
  Tiempo real en ensayos: __:__ / __:__ / __:__

BLOQUE 2 · Diseño y decisiones (1:00–4:00) · Habla: ________ · Diapositivas: 2–4
  Tarea = ____________ · número de tareas ≈ ______
  Patrón de comunicación: ________ → en V2 aparece como: ________ (línea/pragma: ________)
  Aglomeración: cada hilo (V2) junta ______ tareas porque ______ · cada bloque (V3) junta ______ porque ______
  Mapeo V2 → V3, qué cambió: ______________________________________________
  Decisión 1: ________ · opciones medidas: ________ · medianas (s): ____ / ____ / ____ · elegida: ____ · costo de la descartada: ____
  Decisión 2: ________ · opciones medidas: ________ · medianas (s): ____ / ____ / ____ · elegida: ____ · costo de la descartada: ____
  Fragmento clave V2 (archivo:líneas): ________ · Fragmento clave V3 (archivo:líneas): ________
  Tiempo real en ensayos: __:__ / __:__ / __:__

BLOQUE 3 · Resultados y análisis (4:00–8:00) · Habla: ________ · Diapositivas: 5–6
  T(1) = V1 = ______ s · V2 con 1 hilo = ______ s (sobrecarga ____ %)
  S(2) = ____  E(2) = ____  f(2) = ____
  S(4) = ____  E(4) = ____  f(4) = ____
  S(8) = ____  E(8) = ____  f(8) = ____   [ ] la fila de 8 es sobre-suscripción (núcleos físicos: __)
  Tendencia de f: [ ] constante  [ ] crece  [ ] baja  → significa: ______________________
  Fracción secuencial medida en V1 = ____ → S_max Amdahl(p = __) = ____ · obtenido = ____
  Deja de escalar en p = __ · causa verificable: ______________ · experimento/número que la apoya: ______________
  V3 (GPU ________, fecha ________): sin transferencias S = ____ · con transferencias S = ____ · transferencias = ____ % del total
  La GPU conviene a partir de n ≈ ______ porque ______
  Predicción (bitácora, fecha ______): S(4) ≈ ____ · obtenido ____ · diferencia por: ______
  Lo que NO sabemos explicar (se dice tal cual): ______________________________
  Tiempo real en ensayos: __:__ / __:__ / __:__

BLOQUE 4 · Qué falló y qué aprendimos (8:00–10:00) · Habla: ________ · Diapositiva: 7
  Entrada de bitácora A: síntoma ______ · detección ______ · causa ______ · cambio ______ · prueba agregada ______
  Entrada de bitácora B: síntoma ______ · detección ______ · causa ______ · cambio ______ · prueba agregada ______
  Medición descartada: configuración ______ · por qué ______
  Qué no entendemos todavía: 1) ______________ → experimento: ______  2) ______________ → experimento: ______
  Qué nos dijo la IA que resultó estar mal: ______________ · cómo lo descubrimos: ______
  Tiempo real en ensayos: __:__ / __:__ / __:__

BLOQUE 5 · Demo (10:00–12:00) · Teclea: quien designe el profesor (los tres ensayaron: [ ] A [ ] B [ ] C)
  Ruta del clon: ./cp-6bm1-equipoNN-defensa · git describe → entrega-final · make test tarda ____ s
  Comando V1: ______________________ · Comando V2 (1 hilo): ______________________ · Comando V2 (__ hilos): ______________________
  Pestaña del notebook: ______________________ (celdas: nvidia-smi, PASS, medición)
  Plan B: ruta local del video ______________________ · issue #__ del repositorio
  Tiempo real en ensayos: __:__ / __:__ / __:__

PREGUNTAS INDIVIDUALES · tema sorteado para la pregunta 2: A: ________ B: ________ C: ________
  Cada quien practicó en voz alta, sin notas, las preguntas del banco sobre este repositorio: [ ] A [ ] B [ ] C
```
