> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Práctica 4 · Procesamiento paralelo de datos con OpenMP · publicada jueves 15 de octubre de 2026 · entrega domingo 1 de noviembre de 2026, 23:59 · 40 % del 2.º parcial

# Práctica 4 · Entrega: qué, cómo y cuándo

## 1. Cuándo

| Momento | Fecha y hora | Qué debe estar en el repositorio del equipo |
|---|---|---|
| Pre-laboratorio (individual) | antes del **martes 20 de octubre, 08:30** | `practicas/P4/prelab/prelab-<tu alias>.md`, uno por integrante, falte o no a la sesión |
| Laboratorio 1 (S09, Lab LS4) | martes 20 de octubre, 08:30–10:00 | Se trabajan las Partes A y B; mini-defensas de la mitad de los equipos si hay más de 12 (lista publicada ese día) |
| Partes A y B terminadas | antes del **martes 27 de octubre, 08:30** | `make test-a` y `make test-b` en `0 FAIL`; tu línea `resumen:` del mergesort |
| Laboratorio 2 (S12, Lab LS4) | martes 27 de octubre, 08:30–10:00 | Parte C con `make test-c` en `0 FAIL`; se mide la Parte D; punto de control (una medición explicada en 1 minuto); mini-defensas |
| **Fecha límite** | **domingo 1 de noviembre de 2026, 23:59** | Todo lo de §2, con la etiqueta `P4-entrega` |
| Entrega tardía | hasta el miércoles 4 de noviembre, 23:59 (72 h) | Máximo 80 %; sin segunda entrega |
| Retroalimentación | a más tardar el domingo 8 de noviembre (≤ 7 días) | Salida de `tests/run_tests.sh`, nivel por criterio, ≤ 2 líneas por criterio y un documento grupal con los tres errores más frecuentes |
| Segunda entrega (solo si la primera obtuvo < 70 %) | dentro de los 7 días siguientes a la retroalimentación | Correcciones + `CAMBIOS.md` ("qué corregimos y por qué"); tope 80 %; cuenta la mayor |
| Pregunta posterior | jueves 5 de noviembre, 10:30 (U4 S01; el martes 3 es el Examen 2) | 5 min: un integrante al azar de 2–3 equipos explica qué cambió desde el Laboratorio 2 |

Ponderación: **40 % del 2.º parcial** (`planeacion/mapa-evaluacion.md`). Las reglas de tardía y segunda entrega son
las de ese mapa y de `docs/metodo/04-evaluacion.md` §5.

## 2. Qué se entrega

En el repositorio **privado** del equipo (el de P1–P3 y del proyecto, con el profesor como colaborador), la
carpeta `practicas/P4/` con esta estructura:

```
practicas/P4/
├── Makefile                  el de esta carpeta (puedes agregar objetivos; no quites all, run, test, clean)
├── medir.sh  graficar.py     los de esta carpeta, sin cambios o con cambios declarados en el reporte
├── src/                      todos los .c y .h; sin TODO pendiente en las Partes B y la opción elegida de C
├── tests/run_tests.sh        el público + al menos 1 caso propio (marcado con un comentario "# caso propio")
├── resultados/
│   ├── p4.csv                CSV del protocolo (make medir)
│   ├── entorno.txt           lo escribe medir.sh: CPU, núcleos, compilador, carga
│   ├── salidas/              lo escribe medir.sh: la salida completa de cada corrida medida
│   ├── p4_speedup.png        speedup vs. hilos con la línea ideal
│   ├── p4_eficiencia.png     eficiencia vs. hilos con E = 1 y E = 0.5
│   └── mandelbrot.png        (opción Mandelbrot) la imagen de make imagen
├── prelab/prelab-<alias>.md  uno por integrante
└── REPORTE.md                ≤ 3 páginas (estructura en §3)
```

No se versionan binarios ni salidas de prueba: `bin/`, `tests/out/` y `*.pgm` ya están en `.gitignore`.

## 3. `REPORTE.md` (≤ 3 páginas; las tablas y gráficas cuentan)

1. **Equipo y reparto de trabajo.** Alias de cada integrante y qué **firmó**: archivo y funciones o líneas
   (p. ej., "alias1: `merge` y `TODO(3)`; alias2: `render_omp` y la Parte D"). Sobre eso se pregunta en la
   mini-defensa.
2. **Decisiones de diseño.** Para cada una: qué elegiste, qué alternativa descartaste y el dato que lo decidió
   (corte de la Parte B con la tabla de `make cortes`; política y *chunk* de la Parte C con mediana y
   `max/promedio`; en calor, cada cuántos pasos revisar). Declara qué opción de la Parte C entregaste.
3. **Parte A.** Tu tabla de 1, 2 y 4 hilos (ns/elemento y *speedup*), la salida de `make speedup-a` y tu
   predicción del pre-lab copiada **tal cual**, con la comparación.
4. **Parte B.** Tu línea `resumen:` con 4 hilos y la tabla de `make cortes`; el experimento `<` contra `<=`.
5. **Parte D.** La tabla Markdown que imprime `graficar.py`, las dos gráficas, `entorno.txt` resumido (CPU, núcleos
   físicos, carga) y la interpretación (las preguntas de la Parte D del README, 3–6 líneas cada una).
6. **Reflexión individual.** Cada integrante, firmada con su alias: una pregunta de autoexplicación (1 o 2) y la de
   transferencia (3), 5–8 líneas cada una.
7. **Bitácora de errores.** ≥ 3 entradas con: síntoma, causa, cómo se detectó (prueba, ThreadSanitizer, medición) y
   el *commit* que lo corrigió. Al menos una de concurrencia.
8. **Declaración de uso de IA** (formato de `docs/metodo/05-politica-ia.md`), firmada por todos:

```
Uso de IA en esta entrega:
- Herramienta(s): …
- Para qué la usamos (verde/amarillo): …
- Qué fragmento(s) de código vinieron de la IA (archivo y líneas) y cómo los verificamos: …
- Qué nos dijo la IA que resultó estar mal: …
```

## 4. Cómo se entrega

1. Copia esta carpeta del repositorio del curso a `practicas/P4/` del repositorio del equipo (una sola vez, en el
   Laboratorio 1).
2. Trabajen con *commits* pequeños y con autor real: un *commit* por `TODO` resuelto, con el nombre de quien lo hizo.
   El historial es evidencia del criterio "Proceso e integridad" (≥ 3 *commits* con cambios de código por integrante).
3. Antes de la fecha límite, en una copia limpia del repositorio:

```bash
cd practicas/P4
make clean && make            # sin warnings
make test                     # Resumen: N PASS, 0 FAIL
make medir SCHED="<política> <chunk>"   # solo si cambiaste algo después de medir (o PARTE_C=calor);
                                        # regenera el CSV, entorno.txt, salidas/ y las dos PNG
git add -A && git commit -m "Entregar Práctica 4"
git tag P4-entrega && git push && git push --tags
```

4. Si corriges algo después de etiquetar y antes de la fecha límite: `git tag -f P4-entrega && git push -f --tags`.
   Se califica lo que apunta la etiqueta al cierre (domingo 1 de noviembre, 23:59).

## 5. Mini-defensa y video

La mini-defensa es en el Laboratorio 2 (martes 27 de octubre) sobre el código de ese momento; con más de 12
equipos, la mitad (equipos con número impar) se defiende en el Laboratorio 1. Quien no estuvo en su mini-defensa
tiene dos caminos: hacerla en el siguiente laboratorio (martes 10 de noviembre, 08:30, Lab LS4) o en la reserva del
martes 15 de diciembre, o grabar un video de **≤ 3 minutos** (no listado o privado, enlazado en `REPORTE.md`)
explicando la parte que firmó y respondiendo "¿qué hace esta línea?" sobre una línea que elija el profesor por
correo. Solo graba video quien no estuvo en su mini-defensa.
