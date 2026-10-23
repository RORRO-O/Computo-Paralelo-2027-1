# Logística de la defensa oral

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Defensa oral · jueves 10 de diciembre de 2026 · 10:30–12:00 · Salón 3208 · reservas: lunes 14 de diciembre 10:30–12:00 y martes 15 de diciembre 08:30–10:00 · para el profesor (los equipos leen §3, §4, §8 y §9) · versión 1.1 · 20 de octubre de 2026

## 1. En una tabla

| Qué | Detalle |
|---|---|
| Sesión principal | **Jueves 10 de diciembre de 2026, 10:30–12:00**, sesión C2 del calendario, salón 3208 (último día del curso) |
| Sesiones de reserva del calendario | Lunes 14 de diciembre 10:30–12:00 (prevista para retroalimentación de E3 y del proyecto) · Martes 15 de diciembre 08:30–10:00 (prevista para defensas pendientes por causa justificada y segunda entrega de P6) · Jueves 17 de diciembre 10:30 (cierre administrativo) |
| Formato base | 12 min por equipo (`guion-defensa.md`) + preguntas individuales (2 por integrante) + cambio de equipo |
| Equipos | ~12 (35 estudiantes en equipos de 2–3). La lista real se cierra con las etiquetas `entrega-final` del lunes 7 de diciembre 10:30 |
| Qué se califica | `rubrica-defensa.md`: 15 puntos del proyecto; D4 y el ajuste de §4.1 son por integrante |
| Decisión pendiente | El formato y las sesiones (§3). La toma el profesor y la anuncia **a más tardar el jueves 3 de diciembre** (U5·S06), de preferencia desde el lunes 23 de noviembre (H2), como pide `docs/metodo/04-evaluacion.md` §3.2 |
| Orden | Sorteo con semilla publicada, ejecutado en clase el lunes 7 de diciembre (§4) |
| Plan B de la demo | Video de ≤ 3 min grabado antes (§8) |
| Sesión de pendientes | Martes 15 de diciembre 08:30, con cualquier opción (ausencias justificadas, demo repetida por falla de la sala, V3 pendiente por cuota; ese día vence también la segunda entrega de P6). Con la opción (a) y más de 8 equipos ese martes también tiene defensas: los pendientes se atienden en su holgura (12 min, §2) |
| Inasistencia sin justificante | Se califica como si se hubieran fallado las dos preguntas individuales: D4 = 0, factor 0.80 y C6 Insuficiente (`rubrica-defensa.md` §4.2; `04-evaluacion.md` §3.2). Faltar nunca conviene más que presentarse |

## 2. El problema de tiempo, con números

La sesión dura 90 minutos. Se reservan 5 minutos de apertura (lista, reglas, primer equipo conectado) y 5 de
cierre (anuncios): quedan **80 minutos útiles**. Por equipo se necesita exposición + preguntas individuales + cambio.

**Solo la exposición ya no cabe:** 12 equipos × 12 min = **144 min > 90 min**.

Con preguntas y cambios (modelo que usa `scripts/sortear_orden.py`; equipos de 3 salvo uno de 2):

| Formato | Exposición | Preguntas individuales | Cambio | Por equipo | 12 equipos | Sesiones de 80 min útiles | Cómo quedan |
|---|---|---|---|---|---|---|---|
| **Completo** (`guion-defensa.md`) | 12:00 | 2 por integrante × 40 s = 4:00 (2:40 con 2 integrantes) | 1:00 | 17:00 | **≈ 203 min** | 2.5 → **3** | 4 + 4 + 4 (68, 68 y 66.7 min usados; sobran 12–13 por sesión) |
| **Corto** (opción b) | 7:00 | 3:00 por equipo (2 por integrante, 30 s) | 1:00 | 11:00 | **132 min** | 1.65 → **2** | 6 + 6 (66 min por sesión, sobran 14) |
| **Mixto** (opción c, `04-evaluacion.md` §3.2) | 2:00 de demo (la exposición va en video) | 1 min por integrante (pregunta y posible rescate) + 1 min de margen = 4:00 (3:00 con 2 integrantes) | 0:30 (una sola máquina) | 6:30 | **77 min** (11 × 6:30 + 5:30) | 0.96 → **1** | 12 en el jueves 10 (sobran 3 min en total) |

Lectura: **ningún formato con 12 equipos cabe en una sola sesión salvo el mixto, y ese cabe con 3 min de holgura.** El
formato corto tampoco cabe en una sesión (132 > 80): solo cabría con ≤ 7 equipos. Si el número real de equipos es
distinto, el *script* recalcula (§4).

## 3. Opciones

Son las tres de `proyecto/README.md` §3 y `proyecto/entrega-final/faq-entrega.md` §10, con los números de §2. Las opciones
(a) y (b) conservan la exposición en vivo; la (c) es la que recomienda `docs/metodo/04-evaluacion.md` §3.2. **La decisión es
del profesor.**

### Opción (a) · Formato completo usando también la reserva del lunes 14 (y la del martes 15 con más de 8 equipos)

| | |
|---|---|
| Cómo queda | 12 min + 2 preguntas por integrante + 1 min de cambio = 17 min por equipo de 3. **Caben 4 equipos por sesión** (68 de 80 min). Con 12 equipos: jueves 10 (4), lunes 14 (4), martes 15 08:30 (4). Con ≤ 8 equipos bastan jueves y lunes. Orden por sorteo (§4): posiciones 1–4 el jueves, 5–8 el lunes, 9–12 el martes |
| A favor | Es el formato del calendario y del guion que los equipos ensayan el lunes 7 de diciembre; 4 minutos de resultados y análisis (el bloque de mayor peso) y 2 minutos de demo sin recortes; dos preguntas de 40 s por integrante dan evidencia individual suficiente y margen para la reformulación; 12 minutos de holgura por sesión absorben una demo repetida por falla de la sala; el profesor califica 4 equipos por sesión con atención |
| En contra | Consume **las tres sesiones de reserva**: la sesión de análisis de errores del E3 y de retroalimentación del proyecto, fijada para el lunes 14 (`04-evaluacion.md` §2.4), tendría que moverse (la calificación y la retroalimentación escrita pueden publicarse igual el 14, dentro de los 7 días); el martes 15 queda compartido: las defensas pendientes por causa justificada siguen ese día y se atienden en los 12 min de holgura, y la segunda entrega de P6 (martes 15 de diciembre 08:30, `04-evaluacion.md` §5) no cambia: es un *push* al repositorio y no ocupa la sesión; los equipos del martes defienden 5 días después que los del jueves, a las 08:30, con el Examen 3 en medio (el código no cambia: la etiqueta está congelada desde el 7 de diciembre; cambia el tiempo de ensayo); tres sesiones con el mismo nivel de exigencia para el profesor |

### Opción (b) · Formato corto: 7 min de exposición + 3 min de preguntas, en dos sesiones

| | |
|---|---|
| Cómo queda | 7 + 3 + 1 = 11 min por equipo. 12 equipos = 132 min: **no cabe en una sesión** (80 útiles); cabe en **jueves 10 (6) + lunes 14 (6)** con 14 min de holgura por sesión. Cabría en una sola sesión únicamente con ≤ 7 equipos. Las preguntas individuales son las mismas 2 por integrante, a 30 s cada una (6 preguntas en 3 min con 3 integrantes) |
| Los 7 minutos | 0:00–0:30 problema · 0:30–2:00 diseño y **una** decisión medida · 2:00–4:30 resultados (Figura 1, Tabla 1 con `f(p)`, Tabla 2 de V3, una causa verificable, predicción vs resultado) · 4:30–5:30 qué falló y qué no entienden · 5:30–7:00 demo (etiqueta, `make test`, 1 vs `p` hilos; el *notebook* se muestra solo si sobra tiempo). La rúbrica no cambia; lo que no se alcanza a mostrar no se evalúa |
| A favor | Dos sesiones bastan y el martes 15 queda libre para su uso previsto; 14 min de holgura por sesión; todos defienden en la misma semana lectiva; la demo sigue siendo en vivo |
| En contra | El bloque de resultados y análisis (25 % del peso) baja de 4 a 2.5 min y el de diseño de 3 a 1.5: los equipos muestran una decisión medida, no dos; 30 s por pregunta dificulta distinguir nervios de desconocimiento (la reformulación casi no cabe) y empuja a los estudiantes a pedir la respuesta por escrito (`05-politica-ia.md`), que corre en paralelo pero exige corrección después; el ensayo del 7 de diciembre debe hacerse ya con el formato de 7 min, así que la decisión tiene que estar anunciada el 3 de diciembre sin falta; el lunes 14 sigue ocupado (ahí estaba la sesión de análisis del E3, `04-evaluacion.md` §2.4) |

### Opción (c) · Mixta: exposición en video + demo y preguntas en clase (recomendada en `04-evaluacion.md` §3.2)

| | |
|---|---|
| Cómo queda | Exposición de ≤ 8 min en video (no listado o privado) enlazado en el repositorio antes del lunes 7 de diciembre 10:30, calificada con D1 y D2 de la rúbrica; en clase, por equipo: 2 min de demo + 1 pregunta individual por integrante (la segunda solo como rescate) + 1 min de margen ≈ 6 min + 0.5 de cambio con una sola máquina. 11 equipos de 3 × 6.5 + 1 de 2 × 5.5 = **77 min: cabe en el jueves 10 con 3 min de holgura total** |
| A favor | Una sola sesión; lunes 14 y martes 15 conservan su uso previsto; el profesor revisa los videos con los CSV abiertos y a su ritmo (verificación de números más rigurosa que en vivo); condiciones idénticas para todos |
| En contra | La exposición no es en vivo: no hay preguntas sobre el diseño ni sobre el análisis en el momento, y D2 ("análisis honesto") se evalúa sobre un material editado; una sola pregunta por integrante da menos evidencia individual; 3 min de holgura: cualquier tropiezo manda equipos al martes 15; el video se debe en la misma hora que la entrega final (más carga en el fin de semana del 5–6 de diciembre, que `04-evaluacion.md` §5 quiere descargar), salvo que la opción se anuncie el 23 de noviembre; el formato del calendario ("12 min + demo + preguntas") y el guion que los equipos ya conocen cambian |

### Lo que el profesor anuncia (a más tardar el jueves 3 de diciembre)

1. La opción elegida y, con ella, el formato que se ensaya el lunes 7 de diciembre.
2. Las sesiones que se usarán (jueves 10; lunes 14; martes 15) y cuántos equipos van en cada una.
3. La semilla del sorteo si cambia la preinscrita en §4.
4. Dónde: en clase, en un *issue* del repositorio del curso y actualizando `proyecto/defensa/orden-defensa.md` el 7 de
   diciembre con la salida del *script*.

Con cualquier opción se mantienen: la ventana de entrega tardía cierra el jueves 10 de diciembre 10:30 para todos; la
demo corre desde el clon de `entrega-final`; las reglas de la prueba de propiedad de `05-politica-ia.md`; la
retroalimentación escrita a más tardar el jueves 17 de diciembre.

## 4. Orden por sorteo con semilla publicada

**Método.** Para cada equipo se calcula la clave `SHA-256("<semilla>-equipoNN")` (texto UTF-8, sin salto de
línea; `NN` con dos dígitos, como en `cp-6bm1-equipoNN`). El orden de defensa es el orden ascendente de las claves en
hexadecimal. No depende de versión de Python ni de ninguna biblioteca: cualquiera lo verifica con `sha256sum`.

**Semilla preinscrita:** `20261210`. Está publicada desde la versión 1.0 de este documento (14 de octubre de 2026); el
profesor puede sustituirla hasta el jueves 3 de diciembre publicando la nueva en el *issue* del anuncio. Como la lista de
equipos se conoce desde H0, cualquier equipo puede calcular su posición en cuanto se publica la semilla; eso es
deliberado: el sorteo es transparente, no secreto.

**Posiciones A, B y C dentro del equipo** (para el tema de la pregunta 2): los integrantes en orden alfabético de su
usuario de GitHub, sin distinguir mayúsculas: un orden fijo que el equipo no elige.

**Verificación a mano (un equipo, en el pizarrón el 7 de diciembre):**

```bash
printf '%s' '20261210-equipo07' | sha256sum        # → d53dcd1ca602…  (posición según el orden de todas las claves)
```

**Ejecución (lunes 7 de diciembre, en clase, sesión C1, con la lista real de equipos):**

```bash
cd proyecto/defensa/scripts
# Opción (a): formato completo; tres sesiones por defecto (jue 10, lun 14, mar 15)
python3 sortear_orden.py --semilla 20261210 --equipos ejemplo/equipos.csv --formato completo --salida ../orden-defensa.md
# Opción (b): formato corto, 6 y 6
python3 sortear_orden.py --semilla 20261210 --equipos ejemplo/equipos.csv --formato corto \
    --sesiones "2026-12-10 10:30 90" "2026-12-14 10:30 90" --max-por-sesion 6 --salida ../orden-defensa.md
# Opción (c): mixto, una sesión
python3 sortear_orden.py --semilla 20261210 --equipos ejemplo/equipos.csv --formato mixto \
    --sesiones "2026-12-10 10:30 90" --salida ../orden-defensa.md
```

`ejemplo/equipos.csv` tiene columnas `equipo,integrantes`; se sustituye por la lista real (los equipos con 2
integrantes necesitan menos tiempo de preguntas). El *script* termina con código 3 y marca **SIN HORARIO** a los equipos
que no caben, para que el problema se vea antes de la sesión, no durante. También sortea, con la misma semilla, el
**tema de la pregunta 2** de cada posición del equipo (A, B, C), distintos entre sí (`banco-preguntas-individuales.md` §1).

**Ejemplo con la semilla preinscrita, 12 equipos (once de 3 y el 11 de 2) y opción (b) 6 + 6** (salida literal del
*script*; el orden de la columna "Equipo" es el mismo para cualquier opción, solo cambian sesión y horas):

| Pos. | Equipo | Clave (12 hex) | Integ. | Sesión | Inicio | Fin exposición | Fin preguntas | Tema pregunta 2: A | B | C |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | cp-6bm1-equipo03 | `0ccba1fe6742` | 3 | jueves 10 de diciembre de 2026 | 10:35 | 10:42 | 10:45 | CUDA | Medición | Decisiones del equipo |
| 2 | cp-6bm1-equipo08 | `224ccd740bff` | 3 | jueves 10 de diciembre de 2026 | 10:46 | 10:53 | 10:56 | CUDA | OpenMP | Medición |
| 3 | cp-6bm1-equipo12 | `2310e8cd35d8` | 3 | jueves 10 de diciembre de 2026 | 10:57 | 11:04 | 11:07 | Medición | CUDA | MPI |
| 4 | cp-6bm1-equipo10 | `23515a93a2c4` | 3 | jueves 10 de diciembre de 2026 | 11:08 | 11:15 | 11:18 | Decisiones del equipo | CUDA | MPI |
| 5 | cp-6bm1-equipo06 | `2a9e194ec230` | 3 | jueves 10 de diciembre de 2026 | 11:19 | 11:26 | 11:29 | OpenMP | MPI | Foster |
| 6 | cp-6bm1-equipo04 | `3dfb09101fbc` | 3 | jueves 10 de diciembre de 2026 | 11:30 | 11:37 | 11:40 | CUDA | Foster | Decisiones del equipo |
| 7 | cp-6bm1-equipo02 | `6658524d95f8` | 3 | lunes 14 de diciembre de 2026 | 10:35 | 10:42 | 10:45 | MPI | CUDA | Foster |
| 8 | cp-6bm1-equipo01 | `96e34e5a5277` | 3 | lunes 14 de diciembre de 2026 | 10:46 | 10:53 | 10:56 | MPI | OpenMP | CUDA |
| 9 | cp-6bm1-equipo11 | `9cdf787d32e7` | 2 | lunes 14 de diciembre de 2026 | 10:57 | 11:04 | 11:07 | OpenMP | Medición | — |
| 10 | cp-6bm1-equipo05 | `ac43343a99cc` | 3 | lunes 14 de diciembre de 2026 | 11:08 | 11:15 | 11:18 | OpenMP | MPI | Decisiones del equipo |
| 11 | cp-6bm1-equipo07 | `d53dcd1ca602` | 3 | lunes 14 de diciembre de 2026 | 11:19 | 11:26 | 11:29 | Foster | OpenMP | Decisiones del equipo |
| 12 | cp-6bm1-equipo09 | `f3a56b7d7cd9` | 3 | lunes 14 de diciembre de 2026 | 11:30 | 11:37 | 11:40 | CUDA | Medición | OpenMP |

**Intercambios.** Dos equipos pueden intercambiar posición de común acuerdo, por escrito (*issue* en el repositorio del
curso con el visto bueno de ambos) antes de las 20:00 del miércoles 9 de diciembre. No se intercambia el día de la sesión.

## 5. Desarrollo de la sesión (opciones a y b; la c sustituye la exposición por la demo)

| Hora | Qué pasa | Quién |
|---|---|---|
| 10:30–10:35 | Apertura: lista; se proyecta `orden-defensa.md`; se leen las tres reglas (zona sin IA: teléfonos guardados y solo la laptop de la demo encendida; cronómetro visible, corte a los 12:00; plan B a los 60 s de falla); el primer equipo ya está conectado al proyector | Profesor |
| Por equipo | Exposición (12:00 o 7:00) con la hoja de registro de `rubrica-defensa.md` §6 en mano; al minuto 10 (o 5:30) el profesor nombra quién teclea la demo; preguntas individuales: pregunta 1 de línea sobre la parte firmada, pregunta 2 del tema sorteado (o rescate si la 1 falló); quien pida responder por escrito recibe la hoja y escribe en una mesa aparte (5 min) mientras continúa la sesión | Profesor evalúa; un integrante del **equipo siguiente** lleva el cronómetro visible (reloj del salón o cronómetro del profesor proyectado en una esquina) |
| Cambio (1:00) | El equipo que termina desconecta; el siguiente, que ya tenía su laptop lista en la mesa lateral con el clon compilado, conecta y muestra `git describe` | Equipos |
| 11:55–12:00 | Cierre: fecha de la retroalimentación escrita (jueves 17 de diciembre a más tardar), casos pendientes para la sesión de pendientes (§1), entrega de hojas de respuesta escrita | Profesor |

Reglas durante la sesión:

- La hora de inicio de cada equipo es la del orden publicado; si la sesión va adelantada, el equipo siguiente puede
  empezar antes solo si está listo. Si va atrasada, no se recorta a nadie el tiempo: los últimos pasan a la siguiente
  sesión de reserva y se anuncia en el momento.
- Las preguntas individuales se hacen **con el repositorio del equipo en pantalla**, en el clon de la demo. El
  profesor abre el archivo; el integrante explica.
- La respuesta por escrito (`05-politica-ia.md`): hoja con tres espacios (línea firmada; segunda línea de rescate, que
  solo se califica si la primera falla; tema sorteado), 5 minutos, sin dispositivos, en una mesa visible. Se califica
  con los mismos niveles después de la sesión.
- Nadie del público interrumpe. Las preguntas de otros equipos no forman parte de la evaluación.

## 6. Sala y equipo (lista del profesor para el miércoles 9 de diciembre)

- [ ] Proyector del salón 3208 probado; cable HDMI; adaptadores USB-C→HDMI y mini-DisplayPort→HDMI; extensión eléctrica.
- [ ] Máquina del salón (o laptop del profesor) con `gcc` + OpenMP, `make`, `git` y `python3`, y **un clon de cada
      repositorio en la etiqueta `entrega-final`** hecho la tarde anterior (el profesor es colaborador): es el respaldo
      si la laptop de un equipo no da video. Comando por equipo: `git clone <url> && cd <repo> && git checkout entrega-final && make`.
- [ ] `orden-defensa.md` generado y proyectable; una copia impresa.
- [ ] Hojas de registro impresas (`rubrica-defensa.md` §6), una por equipo, con el usuario de GitHub de cada integrante
      ya escrito (sin nombres en lo que se publique).
- [ ] `banco-preguntas-individuales.md` impreso o abierto en una segunda pantalla.
- [ ] 10 hojas en blanco para respuestas escritas; 2 bolígrafos.
- [ ] Cronómetro visible (reloj grande o ventana de cronómetro proyectada en una esquina).
- [ ] Archivo `registro-defensa.csv` vacío con el encabezado de §7, para capturar al terminar cada sesión.

## 7. Hoja de registro por integrante y cálculo

**En la sesión.** El profesor llena a mano la hoja de `rubrica-defensa.md` §6, una por equipo, con **una fila por
integrante**: usuario de GitHub (nunca el nombre), pregunta 1 (archivo:línea de la parte firmada) y su nivel; pregunta 2
(tema sorteado e ID del banco, o archivo:línea si fue rescate) y su nivel; si hubo reformulación o respuesta por escrito.
Las hojas llenas y el CSV contienen calificaciones con usuarios de GitHub: se guardan en `docente/` (está en `.gitignore`)
o fuera del repositorio, nunca en `proyecto/` (`docs/CONVENCIONES.md` §5).

**Al terminar cada sesión.** Se captura `docente/proyecto/registro-defensa.csv`, una fila por integrante, con este
encabezado (el archivo de ejemplo es `scripts/ejemplo/registro-defensa.csv`):

```
equipo,integrante,D1,D2,D3,P1,P2,h2,repo,reporte
07,usuario-a,E,E,E,E,E,13.5,34.0,25.5
07,usuario-b,E,E,E,I,C,13.5,34.0,25.5
```

| Columna | Qué va |
|---|---|
| `equipo` | Número del repositorio `cp-6bm1-equipoNN` |
| `integrante` | Usuario de GitHub (nunca el nombre) |
| `D1`, `D2`, `D3` | Nivel del **equipo** en cada criterio: `E` Ejemplar, `C` Competente, `D` En desarrollo, `I` Insuficiente, `A` ausente. Iguales en todas las filas del equipo (el *script* lo verifica) |
| `P1` | Nivel de la pregunta 1 (línea de la parte firmada). Una pregunta sin respuesta es `I`. `A` solo si el integrante faltó **sin justificante**, y entonces `P2` también es `A`: cuenta como dos Insuficientes (factor 0.80, `c6_insuficiente` = sí). Con justificante, la fila se captura después de su defensa individual del martes 15 de diciembre, con los niveles reales |
| `P2` | Nivel de la pregunta 2: de tema si `P1` ≥ `D`; de **rescate** (otra línea) si `P1` = `I`; `-` si no se hizo (opción c sin rescate) |
| `h2`, `repo`, `reporte` | Puntos ya calificados de H2 (/15), repositorio (/40, con C6 ya asignado por integrante) y reporte (/30). Se dejan vacíos si todavía no están: el *script* calcula entonces solo la defensa |

```bash
cd proyecto/defensa/scripts
python3 calificar_defensa.py ../../../docente/proyecto/registro-defensa.csv \
    --salida ../../../docente/proyecto/calificaciones-defensa.csv
```

El *script* aplica `rubrica-defensa.md` §2–§4: D4 = 30 × promedio de las dos respuestas (o de la única, en la opción c);
defensa = rúbrica × 0.15; **−10 % por cada respuesta en Insuficiente**, también la de rescate, hasta dos (factor 1.00 /
0.90 / 0.80; §4.1; la ausencia sin justificante, `A`, cuenta como dos); proyecto individual = (H2 + repositorio +
reporte + defensa) × factor, con el tope de §4.1: **nunca más de 20 puntos por debajo de la referencia del equipo** (la
columna `tope_aplicado` dice cuándo actuó). La columna `c6_insuficiente` marca a quien falló la pregunta 1 y la de
rescate o faltó sin justificante: a esa persona le corresponde C6 Insuficiente en
`proyecto/entrega-final/rubrica-codigo.md` antes de capturar `repo` (el *script* no cambia `repo`). Termina con código 1 y
dice fila y columna si el CSV tiene un nivel o un número inválido. Ejemplo sin datos reales: `make run` en `scripts/`
produce `salida/calificaciones.csv` a partir de `ejemplo/registro-defensa.csv`; la tabla de §4.1 de la rúbrica sale de ahí.

## 8. Plan B si falla la demo: video de ≤ 3 minutos

| Qué | Detalle |
|---|---|
| Cuándo se usa | Cuando la demo en vivo no se recupera en **60 segundos** por causa del equipo (laptop, clon, dependencia). El profesor lo pide; el equipo no decide saltarse la demo |
| Qué muestra | Grabación de pantalla, sin edición, con audio o subtítulos breves: (1) `git describe --tags --exact-match` → `entrega-final` y `git status --short` vacío; (2) `make test` completo con las líneas `PASS` y el código de salida; (3) V1 y V2 con 1 y con `p` hilos al tamaño de demo, con `tiempo_s`/`checksum`; (4) el *notebook* ejecutado en GitHub (`nvidia-smi`, `PASS v3 == v1`, medición). Duración ≤ 3:00 |
| Cuándo se graba | Después de crear la etiqueta (lunes 7 de diciembre) y antes del **miércoles 9 de diciembre, 20:00** |
| Dónde está | (1) archivo `.mp4` **en la laptop de la demo** y en una USB; (2) enlace (no listado o privado, visible para el profesor) en un *issue* del repositorio del equipo titulado "Video plan B de la defensa". El árbol del repositorio no se modifica: la etiqueta `entrega-final` sigue siendo lo que se califica |
| Cómo se califica | D3 máximo En desarrollo si el video muestra los cuatro elementos; Insuficiente si no los muestra o no hay video (`rubrica-defensa.md` §4.2). Las preguntas individuales se hacen igual, con el repositorio en pantalla |
| Falla de la sala | Si falla el proyector, la corriente o la máquina del salón, no se usa el video: la demo se repite al final de la sesión o en la sesión de pendientes (§1), sin penalización |

En la opción (c) el video de exposición (≤ 8 min) es otro archivo y tiene otra función; el plan B de la demo sigue siendo
este video de ≤ 3 min.

## 9. Casos especiales

| Caso | Qué se hace |
|---|---|
| Integrante ausente con justificante institucional | Defensa individual (sus 2 preguntas) en la sesión de pendientes: martes 15 de diciembre 08:30, con cualquier opción (con la a, en la holgura de esa sesión), sin tope. D1–D3 son los del equipo |
| Integrante ausente sin justificante | Como si hubiera fallado las dos preguntas individuales: `P1` y `P2` = `A`, D4 = 0, factor 0.80 y C6 Insuficiente (`rubrica-defensa.md` §4.2); el tope de §4.1 aplica igual. Sin justificante no hay reposición: faltar nunca conviene más que presentarse |
| Equipo completo ausente | Con justificante: defensa en la sesión de pendientes (martes 15 de diciembre 08:30). Sin justificante: 0 en los 15 puntos y, para cada integrante, factor 0.80 y C6 Insuficiente (fila anterior) |
| Equipo de 2 integrantes | Mismo formato; las preguntas duran 2:40 en vez de 4:00 en el completo y 3:00 en vez de 4:00 en el mixto (el *script* lo contempla con `equipos.csv`); en el corto se conservan los 3:00 por equipo como margen |
| Integrante que se retiró del equipo (avisado por escrito, `proyecto/README.md` §5) | No defiende; su calificación la decide el historial de *commits* según lo renegociado |
| Repositorio con etiqueta tardía (después del lunes 7 de diciembre 10:30) | Se defiende lo que haya en la etiqueta a las 10:30 del jueves 10 de diciembre; aplica el tope de 80 % de la entrega tardía en repositorio y reporte, no en la defensa |
| Medición de V3 pendiente por cuota de GPU, con captura fechada (`04-evaluacion.md` §5) | D2 se evalúa sobre V2 y sobre lo que el equipo espera medir y por qué; D3 no exige el *notebook* ejecutado; la medición se completa a más tardar el martes 15 de diciembre 08:30 |
| Petición de responder por escrito | Se concede sin pedir razones; hoja de §5; mismos niveles |
| La sesión se atrasa | Los equipos que no alcanzan pasan a la siguiente sesión de reserva en el mismo orden; se anuncia en el momento y en el *issue* |
| Demo imposible en la laptop del equipo (sin salida de video) | Se usa el clon preparado en la máquina del salón (§6); el equipo lo avisa en el ensayo del lunes 7 de diciembre |

## 10. Después de la defensa

1. Capturar el CSV de cada sesión el mismo día y correr `calificar_defensa.py`.
2. Retroalimentación escrita por equipo (3 líneas: lo mejor, lo que faltó, qué habría cambiado la calificación) y una
   línea por integrante, publicada a más tardar el **jueves 17 de diciembre** (≤ 7 días para el jueves 10, el lunes 14 y
   el martes 15) en el *issue* de retroalimentación del repositorio del equipo, junto con las hojas de las rúbricas
   de repositorio y reporte.
3. Calificación individual del proyecto (100 puntos) con el factor y el tope de §7; se publica con las calificaciones
   preliminares del 3.er parcial (lunes 14 de diciembre si la defensa cabe en una sesión; jueves 17 en otro caso).
4. Casos de la sesión de pendientes (§1: justificantes, repeticiones por falla de la sala, V3 pendiente) se cierran
   ese día y se incorporan antes del jueves 17 de diciembre.
