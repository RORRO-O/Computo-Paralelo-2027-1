# Entrega final del proyecto integrador

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Entrega final · **lunes 7 de diciembre de 2026, 10:30** · 40 puntos (repositorio V1·V2·V3) + 30 puntos (reporte PDF) de los 100 del proyecto · versión 1.0 · 14 de octubre de 2026

## 1. Qué se entrega y cuánto vale

| Pieza | Puntos | Dónde se entrega | Con qué se califica |
|---|---:|---|---|
| Repositorio `cp-6bm1-equipoNN` con V1 (secuencial), V2 (OpenMP), V3 (GPU), pruebas, mediciones, `run_all.sh` y bitácora | 40 | GitHub, rama `main`, etiqueta `entrega-final` | `rubrica-codigo.md` |
| Reporte final en PDF, 8–12 páginas, con la estructura de `plantilla-reporte.md` | 30 | `reporte/reporte.pdf` dentro del mismo repositorio | `rubrica-reporte.md` |

Contexto completo del proyecto (`planeacion/mapa-evaluacion.md`): el proyecto integrador vale **40 % del 3er parcial** y se
expresa en 100 puntos: H2 (15 puntos, lunes 23 de noviembre, en clase) + repositorio (40) + reporte (30) + defensa oral
(15 puntos, jueves 10 de diciembre; 12 min + demo en vivo + preguntas individuales; ajusta la calificación individual).
H1 (jueves 29 de octubre) cuenta en el 2º parcial (12 %), no aquí.

## 2. Cuándo y cómo

- **Fecha y hora límite:** lunes 7 de diciembre de 2026, 10:30, inicio de la sesión C1.
- **Qué se califica:** el último *commit* en la rama `main` del repositorio del equipo anterior a esa hora, según la hora de
  GitHub. El equipo lo marca con `git tag entrega-final && git push --tags`. Si no hay etiqueta se toma el último *commit*
  anterior a las 10:30.
- **No se recibe** por correo, memoria USB ni enlaces a Drive. El profesor es colaborador del repositorio desde H0; no hace
  falta enviar nada más.
- **El PDF va dentro del repositorio** en `reporte/reporte.pdf`. No se reciben versiones posteriores por otro medio.
- **Entrega tardía:** hasta 72 h después (jueves 10 de diciembre, 10:30) con calificación máxima de 80 % en las dos piezas
  (regla transversal del mapa de evaluación). Después no se recibe salvo justificante institucional. La ventana termina en
  el momento en que empieza la defensa: la defensa se hace con lo que haya en el repositorio a esa hora.
- **La sesión del lunes 7 de diciembre (10:30–12:00)** es taller de ensayo de defensa con lista de cotejo entre equipos. Se
  asume que el repositorio ya está cerrado; el martes 8 de diciembre a las 08:30 es el Examen 3 (Unidades IV–V).

## 3. Qué debe tener el repositorio

La carpeta `plantilla-repo/` es una plantilla **funcional**: compila, pasa `make test`, mide y grafica. El cómputo que trae
es un marcador de posición (`comun/problema.h`, función `elemento()`): entregarlo tal cual vale 0 en correctitud. Lo que
sí se conserva es la infraestructura, porque es lo que el profesor va a ejecutar.

```
README.md               problema, datos, semillas, cómo compilar, cómo reproducir cada figura, integrantes, uso de IA
Makefile                all · run · test · clean   (make test termina con código 0 solo si todo pasa)
run_all.sh              entorno → make → make test → mediciones V1 y V2 → resultados/mediciones.csv → gráfica
comun/problema.h        datos con semilla, checksum, cómputo compartido por V1/V2/V3
v1/  v2/  v3/           una carpeta por versión, cada una con su Makefile; v3/ incluye notebook_colab.ipynb EJECUTADO
tests/run_tests.sh      V2 y V3 contra V1 con tolerancia; casos borde; casos propios del equipo
herramientas/           resumen_csv.py (tabla + gráfica), generar_notebook_v3.py
resultados/             mediciones.csv · mediciones_v3.csv · entorno.txt · entorno_gpu.txt · speedup.png · tabla.md
reporte/reporte.pdf     el reporte (8–12 páginas)
bitacora.md             qué falló, cómo se detectó, qué se cambió; mediciones descartadas; predicciones vs. resultados
```

**Cómo adoptar la plantilla** (desde la raíz del repositorio del equipo, creado en H0; no se hace *fork* del repositorio del
curso):

```bash
cp -r /ruta/al/repositorio/del/curso/proyecto/entrega-final/plantilla-repo/. .
make && make test && ./run_all.sh --rapido
```

Si el equipo ya tiene una estructura desde H1/H2 puede conservarla, siempre que cumpla el contrato que revisa
`scripts/verificar_entrega.sh`: `Makefile` raíz con `all/run/test/clean`, `run_all.sh` ejecutable, carpetas `v1*/ v2*/ v3*/`,
programas que aceptan `[n] [semilla] [hilos]` e imprimen `clave=valor` (al menos `tiempo_s=` y `checksum=`; la V3 además
`tiempo_kernel_s=` y `tiempo_total_s=`), `tests/run_tests.sh`, y `resultados/` con el formato del protocolo.

## 4. Reproducibilidad exigida

"Mediciones reproducibles o no cuentan" (`docs/metodo/01-marco-pedagogico.md`, P11). En concreto: el profesor clona el
repositorio en una máquina limpia y le da **10 minutos** para `make`, `make test` y `./run_all.sh --rapido`, abre el PDF y
compara sus tablas con `resultados/*.csv`, y abre el *notebook* de la V3 para ver la salida de `nvidia-smi` y la verificación
contra V1. Lo que no se logre en ese tiempo se califica como si no estuviera. El detalle, incluido cómo documentar la GPU de
Colab y cómo incluir el *notebook* ejecutado, está en `reproducibilidad.md`. El equipo corre antes de entregar:

```bash
bash /ruta/al/repositorio/del/curso/proyecto/entrega-final/scripts/verificar_entrega.sh /ruta/al/repo/del/equipo
```

## 5. Archivos de esta carpeta

| Archivo | Para quién | Qué contiene |
|---|---|---|
| `README.md` | Equipo y profesor | Este documento: qué, cuándo, cómo, cuánto vale |
| `rubrica-codigo.md` | Ambos | Rúbrica analítica del repositorio: 6 criterios, 4 niveles, 40 puntos |
| `rubrica-reporte.md` | Ambos | Rúbrica analítica del PDF: 7 criterios, 4 niveles, 30 puntos |
| `plantilla-reporte.md` | Equipo | Estructura obligatoria del PDF, sección por sección: qué va, qué no va, de dónde sale; esqueleto para copiar |
| `lista-cotejo-entrega.md` | Equipo | 25 ítems sí/no para correr antes de entregar; 24 los verifica el script |
| `reproducibilidad.md` | Ambos | Qué hace el profesor en 10 minutos; contrato de `run_all.sh`; GPU de Colab; *notebook* ejecutado |
| `faq-entrega.md` | Equipo | 10 preguntas frecuentes con respuesta |
| `scripts/verificar_entrega.sh` | Ambos | Verificación automática de los ítems 1–24 de la lista de cotejo sobre cualquier repositorio |
| `plantilla-repo/` | Equipo | Repositorio plantilla funcional (V1, V2, V3, pruebas, `run_all.sh`, *notebook*, bitácora) |

## 6. Calendario de cierre

| Fecha | Hora | Qué |
|---|---|---|
| jueves 3 de diciembre | 10:30–12:00 | S06 (U5): repaso para el Examen 3 y **lista de cotejo de la entrega final** entre equipos |
| domingo 6 de diciembre | 23:59 | Fecha límite de la Práctica 6 (GPU) |
| **lunes 7 de diciembre** | **10:30** | **Entrega final: repositorio V1·V2·V3 (40) + reporte PDF (30)**; después, taller de ensayo de defensa |
| martes 8 de diciembre | 08:30–10:00 | Examen departamental 3 (Unidades IV–V) |
| jueves 10 de diciembre | 10:30–12:00 | Defensa oral (15 puntos; ajusta la calificación individual); fin de la ventana de entrega tardía |
| lunes 14 de diciembre | 10:30 | Reserva: retroalimentación del Examen 3 y del proyecto; calificaciones preliminares |
| martes 15 de diciembre | 08:30 | Reserva: defensas pendientes por causa justificada |

## 7. Uso de IA en esta entrega

Aplica `docs/metodo/05-politica-ia.md` completa. En resumen: verde para explicar, criticar el diseño de Foster con preguntas,
sugerir casos de prueba y generar gráficas a partir de **sus** datos; amarillo para fragmentos de ≤ 10 líneas que se
reescriben, se explican y se declaran con archivo y líneas; rojo para pedir una versión completa, "mejorar" mediciones o
entregar texto del reporte sin revisar. La declaración de uso va en el README del repositorio y en la sección 12 del PDF, con
la línea "qué nos dijo la IA que resultó estar mal". La defensa oral es zona sin IA y ahí se aplica la prueba de propiedad.

## 8. Después de la entrega

Retroalimentación con las dos rúbricas en ≤ 7 días: se publica en la sesión de reserva del lunes 14 de diciembre junto con las
calificaciones preliminares. La defensa del jueves 10 de diciembre puede mover la calificación individual (ver
`proyecto/defensa/`). Las dudas que no resuelve `faq-entrega.md` se plantean en clase antes del jueves 3 de diciembre.
