# Seguimiento del grupo: cómo llenar la hoja en 5 minutos y leer los indicadores

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Herramienta del profesor · versión 1.1 · 20 de octubre de 2026

`seguimiento-grupo.csv` es la plantilla vacía de la hoja que pide `docs/metodo/01-marco-pedagogico.md` §5: los
seis indicadores que deciden si el método funciona o se corrige. `seguimiento.py` lee la hoja llena y dice qué
umbral se cruzó. La hoja llena contiene números de lista y calificaciones: vive en `docente/seguimiento-grupo.csv`
(la carpeta `docente/` está en `.gitignore`) y nunca se versiona en `main`. Nombres y correos no entran ni ahí.

```bash
cp herramientas/seguimiento-grupo.csv docente/seguimiento-grupo.csv     # una sola vez
python3 herramientas/seguimiento.py docente/seguimiento-grupo.csv       # informe completo
python3 herramientas/seguimiento.py docente/seguimiento-grupo.csv --alertas
```

Los datos que pide cada plan de sesión ("Datos que se registran hoy") van en `docente/seguimiento-grupo.csv`, con
las columnas de esta plantilla. `herramientas/seguimiento-grupo.csv` se queda vacía: solo es la plantilla.

## 1. Una hoja, tres tipos de fila

Cada fila tiene un `ambito` y llena solo sus columnas; las demás quedan vacías. Así cabe en una hoja de cálculo y
en un solo CSV.

| `ambito` | Una fila por… | `evento` | `id` | Columnas que llena |
|---|---|---|---|---|
| `grupo` | sesión | `U3-S07`, `U4-S01`, `U5-S03`… | vacío | `retrieval_ant1_pct`, `retrieval_ant2_pct`, `ct1_voto_pct`, `ct1_revoto_pct`, `ct2_voto_pct`, `ct2_revoto_pct`, `exit_bien`, `exit_parcial`, `exit_mal`, `entregas_a_tiempo_pct`, `notas` |
| `equipo` | equipo y hito | `H1`, `H2` | `equipoNN` (como en `cp-6bm1-equipoNN`) | `hito_pct`, `notas` |
| `estudiante` | estudiante y examen | `E1`, `EP2` (examen de práctica, S13), `E2`, `EP3` (examen de práctica, S06 de U5), `E3` | número de lista | `nivel_diagnostico_ago`, `prediccion`, `postdiccion`, `calificacion`, `escala`, `notas` |

## 2. Columnas

| Columna | Qué va | De dónde sale | Umbral (`01` §5) |
|---|---|---|---|
| `fecha` | `AAAA-MM-DD` | `planeacion/calendario-27-1.md` | — |
| `retrieval_ant1_pct`, `retrieval_ant2_pct` | % de aciertos de cada una de las **dos preguntas de la sesión anterior** de `retrieval-inicio.md` (normalmente la 1 y la 2; si la sesión usó otras, di cuáles en `notas`) | Manos por pregunta al mostrar las respuestas (minuto 4), entre la asistencia | **< 60** en cualquiera |
| `ct1_voto_pct` … `ct2_revoto_pct` | % de acierto en el primer voto y en el revoto de cada ConcepTest. Si no hubo revoto (primer voto < 30 % o > 80 %), deja vacío el revoto | Conteo de tarjetas | Sin umbral en `01` §5; el plan de sesión fija el suyo |
| `exit_bien`, `exit_parcial`, `exit_mal` | Número de *exit tickets* en cada montón; la suma es la asistencia del día | Regla "Clasificación rápida" de `exit-ticket.md` (por defecto, la clave literal de la pregunta 1, `01` §4) | **`exit_mal` > 30 %** de la suma |
| `entregas_a_tiempo_pct` | % de estudiantes o equipos que entregaron a tiempo lo que vencía ese día (pre-lab, práctica, hito). Vacío si no vencía nada (no pongas 0) | Repositorios en GitHub | **< 80** |
| `hito_pct` | Calificación del equipo en el hito, en % de la rúbrica | `proyecto/hitos/H1-avance-1.md`, `H2-avance-2.md` | **< 60** en algún equipo |
| `nivel_diagnostico_ago` | `refuerzo`, `medio` o `alto`, del diagnóstico de agosto. Basta en una fila por estudiante; si lo repites, que coincida | Diagnóstico de agosto | Lo usa el indicador 6 |
| `prediccion`, `postdiccion` | Casillas de la hoja de calibración: la calificación que espera al **recibir** el examen y la que cree haber obtenido al **entregarlo** (`04` §2.3) | Hoja de calibración | Indicador 5 |
| `calificacion` | Calificación real del examen | Examen calificado | Indicadores 5 y 6 |
| `escala` | Puntos máximos del examen: `100` en E2 y E3, `60` en los exámenes de práctica (S13 y S06 de U5) (`04` §2.3). Vacía = 10 (p. ej., E1 cargado desde el sistema institucional). Predicción, postdicción y calificación de la fila van en esta misma escala, la del instrumento: 0–100 en los departamentales, 0–60 en los de práctica | Examen | — |
| `notas` | Una línea: error más frecuente del *exit ticket* (con el número del Anexo A), qué se reexplica, y los datos que el plan de sesión pide y no tienen columna (equipos sin pre-lab, mini-defensas hechas, conteo por opción de una pregunta). Sin comas: usa punto y coma | Plan de sesión | — |

## 3. Los 5 minutos después de cada sesión

Dentro de los 10 minutos de "después" de la lista de cotejo del profesor (`01` §4), con los montones en la mano.

1. **Minuto 0–1.** Copia la última fila de `grupo` y cambia `fecha` y `evento`.
2. **Minuto 1–2.** `retrieval_ant1_pct` y `retrieval_ant2_pct`: los dos números que anotaste en el margen del
   `plan-sesion.md` al minuto 4, convertidos a % de la asistencia, sin decimales.
3. **Minuto 2–3.** Los % de los ConcepTests (primer voto y revoto) que anotaste durante la sesión.
4. **Minuto 3–4.** Clasifica los *exit tickets* con la regla de su clave y anota los tres conteos.
5. **Minuto 4–5.** `entregas_a_tiempo_pct` solo si ese día vencía algo; `notas` con el error más repetido del
   montón "mal" y qué harás con él. Esa misma frase va a "Notas post-sesión" del `plan-sesion.md`.

Ejemplo de fila de sesión (valores inventados para mostrar el formato):

```
2026-10-19,U3-S08,grupo,,,56,70,40,72,,,14,10,11,,,,,,,reexplicar schedule(dynamic) con el ejemplo de S08 (A.11)
```

## 4. Hitos y exámenes

- **H1 (jueves 29 de octubre) y H2 (lunes 23 de noviembre).** Al aplicar la rúbrica fuera de clase (≤ 7 días),
  una fila `equipo` por equipo con `hito_pct`.
- **Exámenes.** Una fila `estudiante` por estudiante y examen, al calificar: E2 (martes 3 de noviembre) y E3
  (martes 8 de diciembre), y los exámenes de práctica del jueves 29 de octubre (S13) y del jueves 3 de diciembre
  (S06 de U5). Las calificaciones de E1 se cargan una vez, con el nivel del diagnóstico de agosto, para que el
  indicador 6 tenga punto de partida.

```
2026-11-03,E2,estudiante,17,refuerzo,,,,,,,,,,,,80,72,64,100,
```

La participación individual (3 % del 2.º parcial, `04` §1) no se lleva en esta hoja: sale de la lista semanal de
*exit tickets* del profesor.

## 5. Qué calcula `seguimiento.py` y qué se decide

| Indicador (`01` §5) | Cálculo | Alerta | Qué se decide |
|---|---|---|---|
| 1. Recuperación de inicio | Cada pregunta de la sesión anterior por sesión | < 60 % | La siguiente recuperación repite ese ítem con pista en lugar de uno nuevo (`01`, P10) |
| 2. *Exit ticket* | `exit_mal` / (bien + parcial + mal) | > 30 % | La siguiente sesión abre con el error más frecuente y el ejemplo resuelto se repite con otro caso |
| 3. Entregas a tiempo | `entregas_a_tiempo_pct` | < 80 % | Se revisa la carga de esa semana en `calendario-27-1.md` antes de añadir nada |
| 4. Avance por hito | `hito_pct` por equipo | algún equipo < 60 % | Revisión con ese equipo antes del siguiente hito |
| 5. Brecha de calibración | Promedio de (postdicción − calificación), llevado a 0–10; la predicción se reporta aparte | > 1.5 de sobreestimación: el 15 % del puntaje total (15/100 o 9/60) | Al grupo se le muestra el promedio y cada quien recibe su propia brecha (`04` §2.3) |
| 6. Mejora de examen 1 → 2 → 3 | Mediana del cambio de calificación (0–10) de E1 a E2 y de E2 a E3, por nivel del diagnóstico | Mediana ≤ 0 en `refuerzo` | Se revisan los apoyos de la unidad para ese grupo (`01`, P10) |

La salida solo trae agregados y claves de equipo: se puede pegar en las notas del curso sin exponer a nadie. Con
`--alertas` imprime solo las líneas `ALERTA ...` (o "Sin alertas."); es la revisión semanal de los jueves después
de clase (2 minutos). Los datos que no son números (`abc` en una columna numérica, un nivel que no es de la lista)
se avisan por la salida de error con el número de fila y se ignoran; el script no se detiene por una errata.

## 6. Qué no se registra aquí

- Nombres ni correos, en ninguna copia.
- Calificaciones de prácticas: van en el sistema institucional y en `docente/`.
- Comentarios sobre estudiantes concretos.
