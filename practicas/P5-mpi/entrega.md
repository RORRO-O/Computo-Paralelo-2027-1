> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Práctica 5 · Simulación distribuida con MPI · publicada jueves 5 de noviembre de 2026 · Lab 1 martes 10 de noviembre 08:30 · Lab 2 martes 17 de noviembre 08:30 · Lab LS4 (Edificio 3) · entrega domingo 22 de noviembre de 2026, 23:59

# Práctica 5 · Qué se entrega, cómo y cuándo

Ponderación: **15 % del 3.er parcial** (`planeacion/mapa-evaluacion.md`). Equipos de 2–3 integrantes (los mismos
del proyecto) con responsabilidad individual. El enunciado completo está en `README.md`; la rúbrica en `rubrica.md`.

## 1. Fechas

| Momento | Fecha y hora | Qué pasa |
|---|---|---|
| Publicación | jueves 5 de noviembre de 2026, 10:30 (U4·S01, salón 3208) | Enunciado, código base y rúbrica disponibles; se asigna el pre-laboratorio |
| **Pre-laboratorio** | **martes 10 de noviembre, antes de las 08:30** | Un archivo por integrante en el repositorio del equipo (`practicas/P5/prelab/`), falte o no el estudiante |
| Laboratorio 1 | martes 10 de noviembre, 08:30–10:00, Lab LS4 (U4·S03) | Partes A y B; mini-defensas de la mitad de los equipos si hay más de 12 |
| Entre sesiones | 10–16 de noviembre | Parte C (el lunes 16 de noviembre no hay clase) |
| Laboratorio 2 | martes 17 de noviembre, 08:30–10:00, Lab LS4 (U4·S05) | Parte D (mediciones), punto de control, mini-defensas restantes |
| **Fecha límite** | **domingo 22 de noviembre de 2026, 23:59** | Etiqueta `P5-entrega` en el repositorio del equipo |
| Primera sesión posterior | lunes 23 de noviembre, 10:30 (U5·S01, día de H2) | 5 min: un integrante al azar de 2–3 equipos explica qué cambió desde el laboratorio |
| Retroalimentación | a más tardar domingo 29 de noviembre | Salida de `tests/run_tests.sh` + nivel por criterio + ≤ 2 líneas por criterio (`docs/metodo/04-evaluacion.md` §3.1) |

Entrega tardía dentro de las 72 h siguientes (hasta el miércoles 25 de noviembre, 23:59): máximo 80 %. Después no se
recibe salvo justificante institucional. Si la calificación es < 70 %, el equipo puede corregir y reentregar **una**
vez dentro de los 7 días siguientes a la retroalimentación, con nota de cambios ("qué corregimos y por qué"); la
segunda entrega tiene tope de 80 % y la calificación final es la mayor de las dos (`04-evaluacion.md` §5).

## 2. Dónde

En el repositorio **privado** del equipo (`cp-6bm1-equipoNN`, el mismo del proyecto, con el profesor como
colaborador), carpeta `practicas/P5/`:

```
practicas/P5/
├── prelab/
│   ├── prelab-<alias1>.md          un archivo por integrante (README §Pre-laboratorio), antes del martes 10, 08:30
│   └── prelab-<alias2>.md
├── Makefile                        el de esta carpeta, con MPIRUN_FLAGS (ajusta NP y tamaños si hace falta)
├── escalado.sh  graficar.py  modelo.py
├── src/                            todo el código; las Partes B y C completas (sin "TODO pendiente")
├── tests/run_tests.sh              el de esta carpeta + al menos un caso propio
├── resultados/
│   ├── entorno.txt                 lo escribe escalado.sh (CPU, núcleos, compilador, CPU ociosa antes de medir)
│   ├── fuerte.csv  debil.csv       formato del protocolo, 5 repeticiones, fila seq, p = 1, 2, 4 y 8 (mpi_oversub)
│   ├── pingpong.txt                salida completa de mpirun -np 2 ./src/d_pingpong en la misma máquina
│   └── fuerte.png  debil.png       graficar.py (con la curva del modelo en fuerte.png)
└── REPORTE.md                      ≤ 3 páginas; plantilla: herramientas/plantilla-reporte-practica.md
```

`REPORTE.md` contiene, en este orden: entorno de medición · decisiones de diseño (tabla con alternativa descartada
y dato) · predicción del pre-lab y resultado · tablas fuerte y débil · gráficas · interpretación (las tres preguntas
de la Parte D) · reflexión individual (una por integrante) · bitácora de errores (≥ 3 entradas) · qué no entienden
todavía · **reparto de trabajo** (quién firmó qué archivo o función) · **declaración de uso de IA** (las cuatro
líneas de `docs/metodo/05-politica-ia.md`).

Nada de nombres completos ni correos en el repositorio: usa el alias de tus *commits*. Nada de rutas absolutas.

## 3. Cómo se entrega y cómo se califica

1. Antes de etiquetar, en una máquina limpia (o tras `make clean`):

   ```bash
   cd practicas/P5
   make clean && make                      # cero warnings
   make test-entrega PARTE_C=heat          # o PARTE_C=primes, según la alternativa que eligió el equipo
   ```

   `make test-entrega` es exactamente lo que corre el profesor al calificar: todas las partes en modo estricto
   (un `TODO pendiente` cuenta como FAIL). Debe terminar en `0 FAIL`. Si tu MPI es MPICH, agrega `MPIRUN_FLAGS=`.
2. `git tag P5-entrega && git push --tags` antes del domingo 22 de noviembre, 23:59. Cuenta la hora del *commit*
   etiquetado. Si vuelven a etiquetar después de la hora, aplica la regla de entrega tardía.
3. El profesor clona, corre lo de arriba con `PARTE_C` según su `REPORTE.md`, aplica `rubrica.md` y responde en
   ≤ 7 días con la salida de las pruebas y el nivel por criterio.
4. Mini-defensa: en el Laboratorio 1 o 2 (lista publicada al cerrar el Lab 1 si hay más de 12 equipos), una pregunta
   por integrante sobre la parte que firmó ("¿qué hace esta línea?"); la segunda ("¿qué pasaría si la quito?") solo si
   la primera falla, y cuenta la mejor de las dos. Quien lo pida responde por escrito en el momento (5 min, papel).
   **Solo quien no estuvo en su mini-defensa** graba un video de ≤ 3 minutos (no listado o privado) en el que
   compila, corre `make test-entrega` y explica una función suya; el enlace va en `REPORTE.md`.

## 4. Lista de cotejo antes de etiquetar

- [ ] `prelab/` tiene un archivo por integrante con las 4 respuestas y la predicción, subido antes del martes 10, 08:30.
- [ ] `make` sin warnings; `make test-entrega PARTE_C=...` termina en `0 FAIL` (y ningún `PEND`).
- [ ] Agregaron ≥ 1 caso propio a `tests/run_tests.sh` (con `EXTRA` o en su propia sección) y pasa.
- [ ] `resultados/fuerte.csv` y `debil.csv`: cabecera del protocolo, 5 repeticiones por fila, fila `seq`, filas
      `mpi` con p = 1, 2, 4 y la fila `mpi_oversub,8` (o declaran por qué no la incluyen); `T_seq ≥ 1 s`.
- [ ] `resultados/entorno.txt` con `cpu_ociosa_antes_de_medir >= 85 %`; si no se pudo, lo dicen en el reporte.
- [ ] `resultados/pingpong.txt` medido en la **misma** máquina que los CSV; α y β usados en `modelo.py` y en `graficar.py --modelo`.
- [ ] `fuerte.png` con línea ideal, puntos medidos, p = 8 hueco y aparte, y la curva del modelo; `debil.png` con E = 1.
- [ ] `REPORTE.md` ≤ 3 páginas con las secciones de arriba; la predicción del pre-lab copiada **tal cual**.
- [ ] Declaración de IA con las cuatro líneas; reparto de trabajo que coincide con `git log`; ≥ 3 *commits* con código por integrante.
- [ ] Cualquier integrante puede explicar en voz alta cualquier línea de `src/` (prueba de propiedad, `05-politica-ia.md`).
