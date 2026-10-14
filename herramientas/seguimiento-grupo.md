# Seguimiento del grupo: cómo llenar `seguimiento-grupo.csv` en 5 minutos

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Herramienta del profesor · versión 1.0 · 14 de octubre de 2026

`seguimiento-grupo.csv` es la hoja sencilla que pide `docs/metodo/01-marco-pedagogico.md` §5: una fila por
sesión con los indicadores que deciden si el método funciona o se corrige. Se llena en los 10 minutos de
"después" de la lista de cotejo del profesor (`01` §4), con los montones de *exit tickets* en la mano. No lleva
nombres de estudiantes: solo conteos y porcentajes.

## 1. Columnas

| Columna | Qué va | De dónde sale | Umbral de alerta (`01` §5) |
|---|---|---|---|
| `fecha` | `AAAA-MM-DD` de la sesión | `planeacion/calendario-27-1.md` | — |
| `sesion` | Unidad y número: `U3-S07`, `U4-S01`, `U5-S03`; para hitos y exámenes `H1`, `E2`, `H2`, `E3`, `FINAL`, `DEFENSA` | Calendario | — |
| `aciertos_retrieval_pct` | Porcentaje de aciertos en las preguntas **de la sesión anterior** de la recuperación de inicio (las 2 primeras de `retrieval-inicio.md`) | Conteo de manos al mostrar las respuestas, minuto 4 | **< 60** |
| `exit_bien`, `exit_parcial`, `exit_mal` | Número de *exit tickets* en cada montón (bien / parcial / mal). La suma es la asistencia del día | Los tres montones | **`exit_mal` > 30 %** de la suma |
| `entregas_a_tiempo_pct` | Porcentaje de equipos o estudiantes que entregaron a tiempo lo que vencía ese día (pre-lab, práctica, tarea revisada, hito). Vacío si no vencía nada | Repositorios en GitHub | **< 80** |
| `notas` | Una línea: el error más frecuente del *exit ticket* (con el número del Anexo A si aplica), qué se reexplica, y los indicadores que no son por sesión (ver §3). Sin comas dentro del texto (rompen el CSV); usa punto y coma | Montones + plan de sesión | — |

Las tres filas que trae el archivo son de ejemplo (dicen "fila de ejemplo (borrar)"). Bórralas al registrar la
primera sesión real.

## 2. Los 5 minutos, paso a paso

1. **Minuto 0–1.** Abre el CSV y agrega la fila con `fecha` y `sesion`.
2. **Minuto 1–2.** `aciertos_retrieval_pct`: en clase, al mostrar las respuestas (minuto 4 de la sesión),
   pediste manos por pregunta y anotaste dos números en el margen del `plan-sesion.md` (aciertos de la
   pregunta 1 y de la 2). Promedia y divide entre la asistencia. Un número, sin decimales.
3. **Minuto 2–4.** Clasifica los *exit tickets* en tres montones (bien: las dos preguntas correctas; parcial:
   una; mal: ninguna). Cuenta y anota `exit_bien`, `exit_parcial`, `exit_mal`.
4. **Minuto 4.** `entregas_a_tiempo_pct` solo si ese día vencía algo: cuenta en GitHub cuántos repositorios
   tienen el archivo antes de la hora límite. Si no vencía nada, deja la celda vacía (no pongas 0).
5. **Minuto 4–5.** `notas`: el error más repetido del montón "mal" y qué harás con él en la siguiente
   recuperación ("reexplicar schedule(dynamic) con el ejemplo del S08"). Esa misma frase va a "Notas
   post-sesión" del `plan-sesion.md`.

Si un umbral se cruza, escribe `ALERTA <indicador>` al final de `notas`; así se encuentra con `grep ALERTA`.

## 3. Indicadores que no son por sesión

Van en la columna `notas` de la fila del día en que se obtienen, con esta sintaxis fija (clave=valor,
separados por punto y coma) para poder extraerlos después:

| Indicador (`01` §5) | Cuándo | Qué escribir en `notas` | Alerta |
|---|---|---|---|
| Avance del proyecto por hito | H1 jueves 29 de octubre; H2 lunes 23 de noviembre | `hito=H1; equipos=12; equipos_menor_60=2` | Cualquier equipo con < 60 % del hito |
| Brecha de calibración | Al calificar E2 (martes 3 de noviembre) y E3 (martes 8 de diciembre) | `examen=E2; brecha_media=+1.8` (predicción − calificación, en puntos sobre 10) | Promedio > 1.5 de sobreestimación |
| Mejora de examen 1 → 2 → 3 | Al calificar E2 y E3 | `examen=E2; refuerzo_mejoran=5/9` (estudiantes del grupo "requiere refuerzo" que subieron / total) | Sin mejora en ese grupo |

## 4. Revisión semanal (2 minutos, jueves después de clase)

```
# Filas con alerta y promedio de retrieval de las últimas 5 sesiones
grep -n ALERTA herramientas/seguimiento-grupo.csv
tail -n 5 herramientas/seguimiento-grupo.csv | awk -F, 'NR>0 && $3 != "" { s += $3; c++ } END { if (c) printf "retrieval promedio: %.0f %%\n", s / c }'
# Porcentaje de "mal" por sesión
awk -F, 'NR > 1 && ($4+$5+$6) > 0 { printf "%s %s mal=%.0f %%\n", $1, $2, 100*$6/($4+$5+$6) }' herramientas/seguimiento-grupo.csv
```

Qué se decide con eso: dos sesiones seguidas con `retrieval < 60` en el mismo tema → la tarea espaciada de la
semana siguiente intercala ese tema; `exit_mal > 30 %` → la siguiente sesión abre con el error más frecuente
(ya está en la plantilla) y el ejemplo resuelto se repite con otro caso; `entregas < 80` → se revisa la carga
de la semana en `calendario-27-1.md` antes de añadir nada.

## 5. Qué no se registra aquí

- Nombres, números de lista ni calificaciones individuales: el archivo vive en un repositorio público.
- Calificaciones de prácticas y exámenes: van en el sistema institucional y en `docente/` (fuera del repositorio).
- Comentarios sobre estudiantes concretos.
