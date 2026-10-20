# Banco de preguntas individuales para la defensa

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Defensa oral · jueves 10 de diciembre de 2026 · 10:30–12:00 · Salón 3208 (y las reservas del lunes 14 y martes 15 de diciembre si aplica la opción a o b de `logistica-defensa.md` §3) · Público: sirve para preparar la defensa · versión 1.1 · 20 de octubre de 2026

## 1. Cómo se usa

**Para ti, estudiante.** Este banco es público a propósito: la defensa no evalúa si adivinas la pregunta, sino si
entiendes tu repositorio. Cada integrante responde **dos preguntas** sin ayuda (`guion-defensa.md` §4):

- **Pregunta 1 · de línea.** El profesor pone en pantalla una línea, un `#pragma`, una función o un *kernel* de la parte
  que **tú firmaste** en el reparto y usa uno de estos tres patrones:

| Patrón | Pregunta | Una buena respuesta contiene |
|---|---|---|
| L1 | "¿Qué hace esta línea y qué pasaría si la quito?" | Qué calcula o controla; el síntoma concreto al quitarla (resultado incorrecto, carrera, acceso fuera de rango, interbloqueo, tiempo que se dispara) y cómo lo detectaría `make test`, TSan o `cudaGetLastError` |
| L2 | "¿Por qué está escrita así y no de otra forma?" | La alternativa que se descartó y el dato (medición, prueba, dependencia de datos) que decidió |
| L3 | "¿Dónde se mide el tiempo aquí y qué queda fuera?" | El reloj (`omp_get_wtime`, `cudaEvent`, `perf_counter`), el inicio y fin de la región de interés, y qué se excluye (lectura de datos, impresión, transferencias si es la medición de *kernel*) |

- **Pregunta 2 · de tema.** Del tema sorteado para tu posición en el equipo (§3 a §8), elegida por el profesor sobre
  **tu** proyecto. Los temas se sortean con la misma semilla que el orden (`logistica-defensa.md` §4) para que en cada
  equipo salgan temas distintos.
- **Rescate.** Si la pregunta 1 queda en Insuficiente, la pregunta 2 no es de tema: es otra pregunta de línea (L1–L3)
  sobre otra parte de lo que firmaste (`docs/metodo/05-politica-ia.md`). Las dos respuestas cuentan para D4 y para el
  ajuste de `rubrica-defensa.md` §4.1; para C6 cuenta la mejor de las dos.
- **Por escrito.** Puedes pedir, sin dar razones, responder las dos por escrito en el momento (5 min, papel, sin
  dispositivos). Vale igual.

Prepárate respondiendo **en voz alta, sin notas y con el repositorio abierto** todas las preguntas de todos los temas.
Pide a tus compañeros que te hagan las de línea sobre archivos que no escribiste: la prueba de propiedad aplica a
cualquier línea del repositorio.

**Para el profesor.** Columnas: nivel cognitivo (N1 recordar/comprender · N2 aplicar/analizar sobre su código y sus
datos · N3 evaluar/crear), lo que debe contener una buena respuesta (nivel Ejemplar de `rubrica-defensa.md` §3.4) y la señal
que ubica la respuesta en **Insuficiente** (activa el ajuste individual de §4.1). Reformular una sola vez; cronómetro de 40 s
(30 s en formato corto). Se sugiere alternar niveles: a quien ya respondió una N1 correcta, hacerle la segunda de N2 o N3.

Resumen: 50 preguntas de tema + 3 patrones de línea.

| Tema | IDs | N1 | N2 | N3 | Total |
|---|---|---|---|---|---|
| Método de Foster | F1–F8 | 2 | 4 | 2 | 8 |
| OpenMP (V2) | O1–O10 | 4 | 5 | 1 | 10 |
| Medición y rendimiento | M1–M10 | 4 | 5 | 1 | 10 |
| MPI (transferencia desde la Unidad IV) | MP1–MP6 | 2 | 3 | 1 | 6 |
| CUDA / GPU (V3) | G1–G10 | 3 | 5 | 2 | 10 |
| Decisiones del equipo | DE1–DE6 | 1 | 4 | 1 | 6 |
| **Total** | | 16 | 26 | 8 | **50** |

## 2. Qué cuenta como desconocimiento (resumen)

Cualquiera de estas señales ubica la respuesta en Insuficiente, sin importar el tema: no poder decir qué hace el elemento
que está en pantalla; contradecir el código visible; describir código que no está en el repositorio; atribuir la línea a otro
integrante o a "la IA" sin explicarla; responder con generalidades ("paraleliza", "optimiza", "la GPU es más rápida"); no
responder; consultar teléfono, notas o a un compañero. Decir "no lo sé, pero lo averiguaría así…" con un método correcto
**no** es desconocimiento: es En desarrollo o Competente según lo que sí explique.

## 3. Método de Foster (F)

| ID | Nivel | Pregunta | Una buena respuesta contiene | Señal de Insuficiente |
|---|---|---|---|---|
| F1 | N1 | Enuncia las cuatro etapas del método de Foster y di qué es **una tarea** en la partición de tu problema y cuántas hay | Partición, comunicación, aglomeración, mapeo. Tarea = la unidad mínima de cómputo con sus datos en este problema (una celda, una fila, un par de elementos, una iteración externa…), con el número aproximado de tareas en función de `n` | Define tarea como "un hilo" o "una función"; no sabe las etapas |
| F2 | N2 | Señala en tu código dónde quedó la **aglomeración**: ¿cuántas tareas junta cada hilo en V2 y cada bloque en V3, y por qué ese tamaño? | Relaciona el `schedule`/*chunk* o el reparto de iteraciones con tareas por hilo, y `blockDim` con tareas por bloque; justifica con sobrecarga por *chunk* vs balance, o con ocupación/múltiplos de 32; cita la línea | "Aglomerar es juntar todo en un solo hilo/proceso" (idea errónea 28); no encuentra dónde está en el código |
| F3 | N2 | ¿Qué **patrón de comunicación** tiene tu problema (local o global; estructurado o no; estático o dinámico) y dónde aparece en V2 como sincronización? | Nombra el patrón (p. ej. reducción global → `reduction`; vecinos locales → barrera entre iteraciones; independiente → ninguna) y la línea o `#pragma` donde se materializa | No distingue comunicación de cómputo; dice que "no hay comunicación porque es memoria compartida" |
| F4 | N2 | ¿Qué cambió en el **mapeo** entre V2 (hilos de CPU) y V3 (bloques e hilos CUDA)? | V2: pocos hilos pesados, cada uno con muchas tareas; V3: miles de hilos ligeros, ≈ una tarea por hilo, índice global `blockIdx.x*blockDim.x + threadIdx.x`, guarda de límites; qué pasó con la aglomeración | Cree que un hilo CUDA equivale a un hilo de CPU (idea errónea 22); no sabe cómo obtiene su índice un hilo |
| F5 | N1 | ¿Qué **dependencia de datos** impide paralelizar alguna parte de tu problema y qué fracción del tiempo de V1 es esa parte? | Nombra la parte (lectura, inicialización, reducción final, dependencia entre iteraciones) y da la fracción medida en el perfil de H1 (no estimada en líneas) | No identifica ninguna parte secuencial, o da una fracción "a ojo" sin perfil |
| F6 | N3 | Si rehicieras el diseño, ¿qué **partición alternativa** considerarías y qué costo de comunicación tendría comparado con la actual? | Una alternativa concreta (por bloques 2D vs por filas; por tareas vs por datos), estima el volumen de comunicación o sincronización (relación superficie/volumen, número de barreras) y dice por qué no se eligió | No propone nada o propone una alternativa que no cambia la comunicación y no lo nota |
| F7 | N2 | Elige una tarea concreta de tu diagrama y di **qué datos toca** (lee/escribe) y **de qué depende** | Nombra arreglos e índices leídos y escritos por esa tarea, y de qué tarea o iteración anterior depende; coincide con la tabla del reporte | La tabla del reporte y la respuesta no coinciden; no sabe qué escribe la tarea |
| F8 | N3 | ¿Por qué el perfil de V1 se hizo **antes** de escribir V2? ¿Qué habría pasado si hubieran paralelizado otra sección? | Amdahl: paralelizar lo que no domina el tiempo acota el *speedup* a `1/f`; cita la fracción de la sección dominante y la de la alternativa; idea errónea 29 ("primero programar, luego diseñar") | Cree que cualquier sección paralelizada da el mismo beneficio; no conoce el perfil de su V1 |

## 4. OpenMP (O)

| ID | Nivel | Pregunta | Una buena respuesta contiene | Señal de Insuficiente |
|---|---|---|---|---|
| O1 | N1 | En esta directiva (en pantalla), ¿qué variables son **compartidas** y cuáles **privadas**, y por qué cada una? | Lista cada variable con su alcance: índices de ciclo privados por defecto, acumuladores en `reduction`, arreglos compartidos con índices disjuntos, temporales privados; menciona `default(none)` si lo usan | "Todas son privadas/compartidas"; no sabe qué hace una variable que está en la cláusula |
| O2 | N1 | ¿Qué pasa si quito este `reduction(+:x)` y dejo `x += …`? | Carrera de datos sobre `x`: resultado incorrecto y no determinista; "salió bien una vez" no es evidencia (idea errónea 7); TSan lo señala; `atomic` lo arreglaría más lento; `reduction` usa copias privadas y combina al final | Dice que el resultado sería igual o solo "más lento"; no sabe qué es una carrera |
| O3 | N2 | ¿Por qué `schedule(static)` (o `dynamic`/`guided`) **aquí**? ¿Qué medición lo respalda y cuánto costó la alternativa? | Carácter de las iteraciones (uniformes → `static`; irregulares → `dynamic` con *chunk*); medianas de la tabla de decisiones; costo por *chunk* de `dynamic`; idea errónea 11 | "`dynamic` siempre es mejor"; no tiene medición o no recuerda el orden de magnitud |
| O4 | N1 | ¿Hay una **barrera** al final de este `omp for`? ¿La necesitan? ¿Qué pasaría con `nowait`? | Barrera implícita salvo `nowait` (idea errónea 12); la necesitan si lo que sigue lee lo que escribió el ciclo; con `nowait` habría carrera o resultado parcial; si no hay dependencia, `nowait` ahorra tiempo | Cree que no hay barrera; o pone `nowait` sin saber qué lee la sección siguiente |
| O5 | N2 | ¿Cuánto difieren V1 y **V2 con un hilo** en tu tabla y qué causa la diferencia? | Da el número (segundos y porcentaje); causas: creación de la región, planificación, combinación de `reduction`, variables privadas; si es > 10 %, qué lo explica; por eso `T(1)` es V1 | No sabe que midió V2 con 1 hilo; o cree que V2 con 1 hilo es la línea base |
| O6 | N2 | ¿Cómo verificaron que **no hay condiciones de carrera**? Muestra la evidencia | Comando de ThreadSanitizer con tamaño de prueba y cómo separaron los avisos de `libgomp` de los propios; o la tabla de accesos por variable (quién lee, quién escribe, qué la protege); pruebas repetidas con 1, 2, 4, 8 hilos | "No hay carreras porque `make test` pasó una vez"; no sabe dónde está la evidencia |
| O7 | N2 | ¿Qué es el **falso compartido** y hay riesgo de él en tu código? ¿Dónde? | Dos hilos escriben variables distintas en la misma línea de caché y se invalidan mutuamente; señala el candidato (arreglo de parciales por hilo, contadores vecinos) y qué hicieron (acumulador local, *padding*, `reduction`); idea errónea 14 | Cree que no existe o que se arregla con más hilos; no identifica ninguna escritura por hilo |
| O8 | N3 | Si te doy una máquina con **16 núcleos físicos**, ¿qué *speedup* predices para tu V2 y por qué? | Usa `f` de Karp–Flatt medida: `S(16) ≈ 1/(f + (1−f)/16)`; advierte que si `f` crece con `p` la predicción es optimista; menciona ancho de banda de memoria como techo; da un rango con su razón | Dice "16" o "el doble que con 8" sin modelo; no conoce su `f` |
| O9 | N1 | `atomic` o `critical` en esta línea: ¿cuál usaste (o usarías) y por qué? | `atomic` protege una actualización simple de una variable escalar y es más barata; `critical` protege una región arbitraria y serializa; idea errónea 8; mide o estima el costo | Cree que son equivalentes; no sabe qué protege cada una |
| O10 | N2 | ¿Por qué esta variable es `firstprivate` y no `private` (o al revés)? ¿Qué valor tendría dentro de la región? | `private` no copia el valor inicial (queda indefinido, idea errónea 9); `firstprivate` copia el valor de fuera; dice qué valor necesita dentro y qué síntoma tendría el error | Cree que `private` copia el valor; no sabe qué valor debe tener dentro |

## 5. Medición y rendimiento (M)

| ID | Nivel | Pregunta | Una buena respuesta contiene | Señal de Insuficiente |
|---|---|---|---|---|
| M1 | N1 | ¿Qué es `T(1)` en tu tabla y por qué **no** es V2 con un hilo? | `T(1)` = mejor programa secuencial (V1 con `-O2`); V2 con 1 hilo carga la sobrecarga de OpenMP y se reporta aparte; protocolo §3; da los dos números | Usó V2 con 1 hilo como base sin decirlo; no sabe qué fila es la base |
| M2 | N1 | Di tu *speedup* y tu **eficiencia** con 4 hilos y qué significa la eficiencia | Números de la Tabla 1; `E = S/p`; interpreta: fracción del tiempo que cada hilo hace trabajo útil; idea errónea 3 | Confunde eficiencia con *speedup* y no lo corrige; no conoce sus números |
| M3 | N2 | ¿Cuánto vale `f` de **Karp–Flatt** con 2, 4 y 8 hilos y qué dice su tendencia? | Números; fórmula `f = (1/S − 1/p)/(1 − 1/p)`; constante → Amdahl explica; crece → sobrecarga creciente (sincronización, memoria, falso compartido); negativa → superlineal por caché, verificar correctitud | No sabe qué es `f` o la calculó con `S` respecto a V2 con 1 hilo |
| M4 | N2 | ¿Por qué **mediana** y no promedio? ¿Cuál fue tu mín y máx con 4 hilos y qué dice esa dispersión? | Robusta ante picos del sistema; da mín, máx y mediana; dispersión grande → ruido (otros procesos, frecuencia variable) o algo no controlado; qué hicieron (cerrar programas, repetir) | No sabe por qué mediana; no tiene mín y máx o no sabe dónde están |
| M5 | N1 | ¿Por qué una ejecución de **calentamiento** que no se cuenta? ¿Qué cambia entre la primera corrida y la segunda? | Cachés frías, creación del *pool* de hilos, fallos de página, carga de módulos (CUDA: contexto); la primera corrida mide eso además del trabajo | Cree que es "por costumbre"; no sabe qué cambia |
| M6 | N2 | ¿Qué **región** cronometras exactamente en V1/V2 y qué queda fuera? ¿Con qué reloj y por qué no con `clock()`? | Inicio y fin alrededor del cómputo; fuera: lectura de datos, impresión, generación con semilla; `omp_get_wtime()` mide tiempo de pared; `clock()` suma CPU de todos los hilos; en V3, `cudaEvent` con sincronización | Cronometra el programa completo sin saberlo; no sabe qué reloj usa |
| M7 | N2 | Tu curva deja de escalar en `p = __`. Da **una causa verificable** y el experimento que la apoya | Causa concreta: núcleos físicos vs lógicos (entorno), ancho de banda de memoria (intensidad aritmética baja; experimento con tamaño que cabe en caché), sincronización (medir sección sola), falso compartido (acumuladores locales); cita el experimento hecho o propone uno con resultado esperado | "Por la laptop" o "por la sobrecarga" sin especificar ni proponer prueba |
| M8 | N3 | Si en una laptop de 4 núcleos físicos el *speedup* con 8 hilos fuera 7.5, ¿qué sospecharías y cómo lo **verificarías**? | Sospecha: base incorrecta (V2 con 1 hilo o `-O0`), tamaño distinto entre configuraciones, V1 artificialmente lenta, o efecto de caché; verifica: recompilar V1 con `-O2`, revisar `entorno.txt`, comparar `checksum`, repetir con tamaño mayor | Lo aceptaría como válido; no propone ninguna verificación |
| M9 | N2 | ¿Qué *speedup* **predijeron antes de medir** (bitácora, fecha) y qué obtuvieron? ¿Qué explica la diferencia? | Cita la predicción con fecha y su razón (fracción secuencial de H1), el número obtenido, y una causa de la diferencia ligada a `f` o al experimento | No hay predicción previa o no sabe cuál fue; explica la diferencia con generalidades |
| M10 | N1 | ¿Por qué el protocolo exige `T(1) ≥ 1 s`? ¿Cuánto tarda tu V1 con el `n` declarado? | Con milisegundos se mide la sobrecarga (crear hilos, lanzar *kernel*) y no el trabajo; resolución del reloj; da su `T(1)` y su `n` | No conoce su `T(1)`; cree que cualquier tamaño sirve |

## 6. MPI · transferencia desde la Unidad IV (MP)

El proyecto no tiene versión MPI; estas preguntas evalúan si puedes razonar tu problema en memoria distribuida con lo que
se vio en la Unidad IV y en la Práctica 5.

| ID | Nivel | Pregunta | Una buena respuesta contiene | Señal de Insuficiente |
|---|---|---|---|---|
| MP1 | N1 | Si V2 fuera con **MPI** en lugar de OpenMP, ¿qué cambia en cómo comparten datos los trabajadores? | Cada proceso tiene su memoria; todo intercambio es un mensaje (idea errónea 16); habría que repartir los datos al inicio (`Scatter`/`Bcast`) y juntar al final (`Gather`/`Reduce`); el costo de comunicación aparece explícito | Cree que los procesos comparten los arreglos; no distingue proceso de hilo |
| MP2 | N2 | ¿Qué **colectiva** usarías para la parte que en V2 resolviste con `reduction`, y **quién** la llama? | `MPI_Reduce` (o `Allreduce` si todos necesitan el resultado); la llaman **todos** los procesos del comunicador (idea errónea 18); el raíz recibe; mismo tipo y operación en todos | Cree que solo el raíz la llama; no sabe qué colectiva corresponde a una suma |
| MP3 | N2 | ¿Qué datos tendrían que **viajar entre procesos** en cada iteración de tu problema y de qué tamaño? Estima el costo con latencia + tamaño/ancho de banda | Identifica fronteras/halos o que no hay intercambio por iteración; tamaño en bytes en función de `n` y `p`; modelo `t = α + m/β`; compara con el cómputo por iteración para decir si la comunicación dominaría (idea errónea 21) | No sabe qué datos necesita un proceso de otro; dice que "la comunicación es gratis" |
| MP4 | N3 | ¿Tu problema escalaría mejor en **escalabilidad fuerte o débil** con MPI? ¿Por qué? | Define ambas (idea errónea 6); si el volumen de comunicación por proceso crece despacio con `p` y el tamaño por proceso se mantiene, la débil se sostiene; la fuerte la limitan la fracción secuencial y la comunicación relativa creciente; lo aplica a su patrón | No distingue fuerte de débil; responde sin referirse a su patrón de comunicación |
| MP5 | N2 | Si dos procesos intercambian fronteras con `MPI_Send` seguido de `MPI_Recv` **en el mismo orden** en ambos, ¿qué puede pasar y cómo lo evitarías? | Interbloqueo posible según el tamaño y el *buffering* (idea errónea 17); se evita con `MPI_Sendrecv`, con `Isend`/`Irecv` + `Wait`, o alternando el orden por paridad del rango | Cree que `Send` siempre regresa de inmediato o siempre bloquea; no conoce ninguna solución |
| MP6 | N1 | ¿Qué significa **SPMD** y en qué se diferencia del modelo de tu V2? | Un solo programa, cada proceso con su rango decide qué hace (`if (rank == 0)`); en OpenMP el modelo es *fork-join* dentro de un proceso con memoria compartida; en MPI no hay regiones paralelas, todo el programa es paralelo desde `MPI_Init` | No sabe qué es un rango; confunde SPMD con "varios programas distintos" |

## 7. CUDA / GPU (G)

| ID | Nivel | Pregunta | Una buena respuesta contiene | Señal de Insuficiente |
|---|---|---|---|---|
| G1 | N1 | En tu *kernel*, ¿qué calcula **un hilo** y cómo obtiene su índice? | Un elemento o tarea por hilo (o un *stride* declarado); `i = blockIdx.x*blockDim.x + threadIdx.x` (o su equivalente 2D / Numba `cuda.grid(1)`); guarda `if (i < n)` | No sabe qué hace un hilo; cree que un hilo recorre todo el arreglo |
| G2 | N1 | ¿Qué pasa si quitas la guarda `if (i < n)`? | Cuando `n` no es múltiplo del tamaño de bloque, los hilos sobrantes acceden fuera de rango: resultado corrupto o `illegal memory access`; se detecta con `cudaGetLastError`/`cudaDeviceSynchronize` y comparando con V1 | Cree que no pasa nada; no sabe por qué hay hilos de más |
| G3 | N2 | ¿Qué **tamaño de bloque** usaste y qué comparación lo respalda? ¿Por qué múltiplo de 32? | Número y medianas de la comparación (p. ej. 128/256/512) en el CSV o la bitácora; *warps* de 32 hilos; ocupación y límites de registros/memoria compartida; idea errónea 26 | Tamaño elegido "porque así venía"; no sabe qué es un *warp* |
| G4 | N2 | ¿Qué porcentaje del **tiempo total** de V3 son transferencias y cuántas veces suben y bajan los datos? | Porcentaje de la Tabla 2 (`total − kernel`); H2D una vez al inicio, D2H una vez al final; si hay copias dentro de un ciclo, por qué no se pudo evitar; idea errónea 24 | Cree que las transferencias no cuentan; no sabe cuántas copias hace su programa |
| G5 | N2 | ¿Cómo verificaste que el *kernel* **terminó sin error** y que el resultado **coincide con V1**? | `cudaGetLastError()` tras el lanzamiento y `cudaDeviceSynchronize()` (o la excepción de Numba/CuPy); comparación de `checksum` con V1 compilada **en la misma sesión** de Colab, con tolerancia declarada (y justificada si usan `float32`); idea errónea 27 | "Si no da error, está bien"; comparó con la V1 de su laptop de otro día |
| G6 | N1 | ¿`__syncthreads()` sincroniza toda la GPU? ¿Dónde lo usaste o por qué no lo necesitas? | Solo los hilos del bloque (idea errónea 25); entre bloques se sincroniza al terminar el *kernel*; lo usan entre fases de memoria compartida, o no lo necesitan porque cada hilo escribe su propia salida | Cree que sincroniza todos los bloques; lo usa "por seguridad" sin saber qué protege |
| G7 | N2 | ¿Tus accesos a memoria global son **coalescidos**? Muestra el patrón de índices | Hilos consecutivos de un *warp* leen direcciones consecutivas (índice interno = `threadIdx.x`); muestra el índice en el código; si el acceso es con paso (*stride*) o por columnas, dice qué costo tiene y si lo midió o por qué no aplica | No sabe qué es coalescencia; no puede decir qué dirección lee el hilo `i` |
| G8 | N3 | ¿A partir de qué `n` **conviene la GPU** en tu problema y cómo lo estimaste? | Punto de cruce entre V3 con transferencias y V1/V2 de la misma máquina; costo fijo (transferencias, lanzamiento) frente a costo variable; medido con varios `n` o extrapolado con la Tabla 2 y dicho así | Dice "siempre conviene la GPU" sin número; no distingue costo fijo de variable |
| G9 | N2 | ¿Qué mides con `cudaEvent` y por qué no basta el reloj del anfitrión sin sincronizar? | El lanzamiento del *kernel* es asíncrono; sin `cudaDeviceSynchronize` o eventos el reloj del anfitrión mide solo el lanzamiento; dos mediciones: solo *kernel* y total con copias; los eventos se registran en el *stream* | Mide con el reloj del anfitrión sin sincronizar y no lo nota; no sabe que el lanzamiento no bloquea |
| G10 | N3 | ¿Usarías **memoria compartida** en tu *kernel*? ¿Para qué datos y qué ganarías? | Datos que varios hilos del bloque reutilizan (vecinos de un *stencil*, mosaicos de una matriz, parciales de una reducción); reduce tráfico a memoria global (uno a dos órdenes de magnitud más lenta, idea errónea 23); o "no aplica" porque cada dato se lee una vez, con esa razón | No sabe la diferencia entre memoria global y compartida; propone usarla sin decir para qué dato |

## 8. Decisiones del equipo (DE)

| ID | Nivel | Pregunta | Una buena respuesta contiene | Señal de Insuficiente |
|---|---|---|---|---|
| DE1 | N2 | Abre un *commit* **tuyo** de las últimas dos semanas y explica qué cambió y por qué | Localiza el *commit* (`git log --author`), describe el cambio en términos del problema o de la medición, lo liga a una entrada de bitácora o a una decisión | No encuentra ningún *commit* propio reciente; describe un cambio que el *diff* no muestra |
| DE2 | N2 | Elige una entrada de la bitácora que escribiste tú: ¿cómo detectaron la falla y qué **prueba agregaron** para que no vuelva? | Herramienta o prueba de detección, causa raíz, cambio, y el caso de prueba o la verificación que se agregó a `tests/run_tests.sh` o al flujo de medición | "Salió mal y lo arreglamos"; no hay prueba agregada y no sabe por qué |
| DE3 | N1 | ¿Qué les dijo la IA que **resultó estar mal** y cómo lo descubrieron? | Ejemplo concreto (una cláusula, una afirmación de rendimiento, un tamaño de bloque, una "optimización") y el método de verificación: compilar con `-Wall -Wextra`, medir con el protocolo, contrastar con la especificación o la guía oficial | "Nunca se equivocó" o no recuerda ningún caso; no verificaron nada |
| DE4 | N3 | Si empezaran hoy, ¿qué harían distinto? Nombra **una decisión** y el dato que la cambiaría | Decisión concreta (partición, tamaño declarado, tecnología de V3, orden de trabajo) y el número o experimento que la motivaría | Generalidades ("organizarnos mejor"); ninguna decisión técnica |
| DE5 | N2 | ¿Por qué eligieron **CUDA C / Numba CUDA / CuPy** y qué perdieron con esa elección? | Razones (lo que pueden explicar línea por línea, herramientas, tiempo) y el costo (control sobre memoria, visibilidad del *kernel*, depuración, rendimiento) con un ejemplo de su V3 | No sabe por qué; cree que no hay diferencia; no puede explicar qué corre en la GPU en su V3 |
| DE6 | N2 | De su lista "qué no entendemos todavía", elige una pregunta y di qué **experimento** la respondería | Pregunta concreta de la lista, el experimento con qué se varía, qué se mide, qué resultado esperarían en cada hipótesis | No conoce la lista; propone "investigar más" sin experimento |

## 9. Cómo prepararte (equipo, semana del 7 al 10 de diciembre)

1. Cada integrante responde en voz alta, con cronómetro de 40 s, las 50 preguntas sobre **este** repositorio. Las que no
   salen se anotan y se trabajan con el código abierto, no con un resumen.
2. Intercambio de archivos: cada quien recibe de un compañero tres preguntas de línea (L1, L2, L3) sobre archivos que
   **no** escribió.
3. En el ensayo del lunes 7 de diciembre, el equipo observador hace una pregunta del banco a cada integrante
   (`lista-cotejo-pares.md`, ítem 12).
4. Ninguna respuesta se memoriza como texto. Si el profesor cambia la línea o el número, la respuesta debe cambiar con él.
