# Cómputo Paralelo · Grupo 6BM1 · ESCOM-IPN · Semestre 27/1

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Índice del curso · Profesor: Rodrigo Ojeda Santillán

Planeación, material de clase, prácticas y proyecto integrador del curso (agosto–diciembre de 2026).
Horario: lunes 10:30–12:00 · martes 08:30–10:00 · jueves 10:30–12:00 · Salón 3208 / Laboratorio LS4 (Edificio 3).

A partir del **jueves 15 de octubre de 2026** el curso sigue el método descrito en `docs/metodo/`: fundamentos
primero, práctica deliberada después, proyecto real al final, con la IA generativa como tutor y no como oráculo.

## Si eres estudiante

| Quieres… | Ve a… |
|---|---|
| Saber qué cambia desde el 15 de octubre y qué cuenta | [`docs/metodo/08-carta-al-grupo.md`](docs/metodo/08-carta-al-grupo.md) |
| Ver fechas de clases, entregas y exámenes | [`planeacion/calendario-27-1.md`](planeacion/calendario-27-1.md) · [`planeacion/mapa-evaluacion.md`](planeacion/mapa-evaluacion.md) |
| Prepararte para una sesión o recuperar una que faltaste | `unidades/<unidad>/<sesión>/notas-estudiante.md`, `ejemplo-resuelto.md`, `practica-guiada/`, `tarea-espaciada.md` |
| Hacer una práctica | [`practicas/P4-openmp/`](practicas/P4-openmp/) · [`practicas/P5-mpi/`](practicas/P5-mpi/) · [`practicas/P6-gpu/`](practicas/P6-gpu/) |
| Trabajar en el proyecto integrador | [`proyecto/README.md`](proyecto/README.md) → hitos, entrega final y defensa |
| Medir rendimiento sin engañarte | [`herramientas/protocolo-medicion.md`](herramientas/protocolo-medicion.md) y [`herramientas/`](herramientas/) |
| Saber qué puedes hacer con la IA | [`docs/metodo/05-politica-ia.md`](docs/metodo/05-politica-ia.md) |
| Estudiar para un examen | `unidades/U3-memoria-compartida/guia-estudio-E2.md` · `unidades/U5-gpu/guia-estudio-E3.md` |

## Si eres el profesor (o das esta clase)

| Quieres… | Ve a… |
|---|---|
| El método en una página | [`docs/metodo/00-resumen-ejecutivo.md`](docs/metodo/00-resumen-ejecutivo.md) |
| Principios, evidencia y catálogo de ideas erróneas | [`docs/metodo/01-marco-pedagogico.md`](docs/metodo/01-marco-pedagogico.md) · [`docs/metodo/06-evidencia-y-bibliografia.md`](docs/metodo/06-evidencia-y-bibliografia.md) |
| Plantillas (sesión de 90 min, práctica, exámenes) | [`docs/metodo/02-plantilla-sesion.md`](docs/metodo/02-plantilla-sesion.md) · [`03-plantilla-practica.md`](docs/metodo/03-plantilla-practica.md) · [`04-evaluacion.md`](docs/metodo/04-evaluacion.md) |
| Dar una sesión | `unidades/<unidad>/<sesión>/plan-sesion.md` (guion minuto a minuto) + `conceptests.md` |
| Escribir material nuevo con el mismo método | [`docs/metodo/07-guia-de-autoria.md`](docs/metodo/07-guia-de-autoria.md) · [`docs/CONVENCIONES.md`](docs/CONVENCIONES.md) |
| Exámenes, claves y soluciones | Carpeta `docente/` (no se publica; ver `docente/README.md`) |
| Comprobar que todo el código compila y pasa pruebas | `./verificar.sh` (`PEND`: esqueleto de práctica cuyas únicas pruebas en FAIL son `TODO` del estudiante) |

## Estructura

```
docs/metodo/        Marco pedagógico, plantillas, evaluación, política de IA, evidencia, carta al grupo
planeacion/         Calendario sesión por sesión (15 oct – 17 dic) y mapa de evaluación
unidades/
  U3-memoria-compartida/   S07–S13 (15–29 oct): OpenMP · Práctica 4 · repaso del Examen 2
  U4-memoria-distribuida/  S01–S06 (5–19 nov): MPI · Práctica 5
  U5-gpu/                  S01–S06 (23 nov – 3 dic): CUDA en Colab/Kaggle · Práctica 6 · repaso del Examen 3
practicas/          P4 (OpenMP), P5 (MPI), P6 (GPU): enunciado, código base, pruebas, rúbrica
proyecto/           Hitos H1/H2, entrega final, defensa, plantillas y medición
herramientas/       Protocolo de medición, cronómetro, medir.sh, gráficas de speedup, guía de Colab/Kaggle
docente/            Solo profesor (en .gitignore): exámenes A/B con claves, soluciones de prácticas
```

Cada carpeta de sesión contiene: `plan-sesion.md`, `retrieval-inicio.md`, `notas-estudiante.md`,
`ejemplo-resuelto.md`, `conceptests.md`, `practica-guiada/` (código + `Makefile` + `tests/`), `exit-ticket.md`
y `tarea-espaciada.md`.

## Requisitos de software

- C con OpenMP: `gcc` ≥ 11 (`-fopenmp`), `make`.
- MPI: Open MPI o MPICH (`mpicc`, `mpirun`).
- GPU: cuenta de Google Colab o Kaggle (CUDA C con `nvcc`); localmente, `numba` para simular *kernels* con `NUMBA_ENABLE_CUDASIM=1`.
- Python 3 con `numpy` y `matplotlib` para gráficas.

## Licencia

Código bajo licencia MIT (ver `LICENSE`).
