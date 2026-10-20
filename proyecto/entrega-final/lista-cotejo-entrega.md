# Lista de cotejo de la entrega final (25 ítems sí/no)

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Entrega final · lunes 7 de diciembre de 2026, 10:30 · Autoevaluación del equipo; se usa también entre equipos en la sesión del jueves 3 de diciembre · versión 1.1 · 20 de octubre de 2026

## Cómo usarla

1. Clona tu propio repositorio en una carpeta nueva (lo que tienes en tu disco no es lo que verá el profesor), junto a
   la carpeta de trabajo: `git clone <URL de cp-6bm1-equipoNN> ../prueba-entrega`.
2. Corre el verificador del curso sobre ese clon. Revisa los ítems 1–24 en segundos y ejecuta `make`, `make test` y
   `./run_all.sh --rapido` en una copia temporal, sin tocar tus archivos:
   `bash RUTA_CURSO/proyecto/entrega-final/scripts/verificar_entrega.sh ../prueba-entrega`
   (`RUTA_CURSO` es donde clonaste el repositorio del curso; `--help` muestra las opciones).
3. Marca cada ítem **sí** o **no**. "Casi" es **no**. Un `FAIL` del verificador es un **no**; un `AVISO` señala algo que
   baja un nivel de la rúbrica aunque el ítem se cumpla. El ítem 25 y lo que el verificador revisa "en parte" se revisa a
   mano, de preferencia por otro equipo (sesión del jueves 3 de diciembre).
4. Cada **no** señala el criterio de rúbrica que va a bajar. Arréglalo o escríbelo en el README §8 ("lo que no funciona").
5. Repite desde el paso 1 después del último *commit*. Luego `git tag entrega-final && git push origin entrega-final`.

Columnas: **Auto** = lo verifica el script con ese número; **Rúbrica** = criterio de `rubrica-codigo.md` (C) o
`rubrica-reporte.md` (R) afectado.

## A. Estructura del repositorio

| # | ¿Sí o no? | Cómo se verifica | Auto | Rúbrica |
|---|---|---|---|---|
| 1 | `README.md` en la raíz dice: problema, datos y semillas, cómo compilar, cómo reproducir cada figura (`run_all`), hardware/entorno, integrantes y reparto, uso de IA | Abrirlo; el script busca esas palabras y cuenta los marcadores «…» sin llenar | 1 | C5 |
| 2 | `Makefile` en la raíz con los objetivos `all`, `run`, `test`, `clean` | `grep -E '^(all\|run\|test\|clean):' Makefile` | 2 | C5 |
| 3 | `run_all.sh` existe y es ejecutable | `ls -l run_all.sh` muestra `x`; si no: `chmod +x run_all.sh` y *commit* | 3 | C5 |
| 4 | Hay carpetas `v1/`, `v2/`, `v3/` (o `src/v1`, `src/v2`, `src/v3`) con una versión cada una y su `Makefile` (la V3 puede tener `run_colab.sh`) | `ls -d v1* v2* v3*` | 4 | C5 |
| 5 | `tests/run_tests.sh` existe y su sección "Casos del equipo" tiene al menos **dos casos propios**, cada uno con un comentario de por qué importa | Abrir la sección; el script cuenta las líneas de prueba, no lee los comentarios | 5 (en parte) | C1 |

## B. Compila, prueba y corre

| # | ¿Sí o no? | Cómo se verifica | Auto | Rúbrica |
|---|---|---|---|---|
| 6 | `make all` compila sin un solo *warning* con `-Wall -Wextra` | `make clean && make all 2>&1 \| grep -i warning` no imprime nada | 6 | C5 |
| 7 | `make test` termina con código 0 y todos los casos imprimen `PASS` | `make test; echo $?` → `0` | 7 | C1 |
| 8 | `./run_all.sh --rapido` termina sin error en ≤ 3 minutos en un clon limpio y escribe en `resultados/rapido/`, sin tocar `resultados/mediciones.csv` | Cronometrar; código 0; `git status` no muestra `resultados/mediciones.csv` modificado | 8 | C5 |

## C. Mediciones (protocolo)

| # | ¿Sí o no? | Cómo se verifica | Auto | Rúbrica |
|---|---|---|---|---|
| 9 | `resultados/mediciones.csv` tiene la cabecera `config,hilos,n,rep1,…,rep5,mediana_s,speedup,eficiencia` (≥ 5 repeticiones; `,min_s,max_s` al final también vale) | `head -1 resultados/mediciones.csv` | 9 | C4 |
| 10 | El CSV tiene una fila `v1` y filas `v2` con al menos tres valores de hilos (1, 2, 4, …) | `cut -d, -f1,2 resultados/mediciones.csv` | 10 | C4 |
| 11 | `T(1)` de la fila `v1` es ≥ 1 s y `resultados/entorno.txt` no dice `modo_rapido=1` (no es el CSV de `--rapido`) | Columna `mediana_s` de la fila `v1` | 11 | C4 |
| 12 | Un CSV de la sesión de GPU (`resultados/mediciones_v3.csv` del *notebook*, o el de `medir_proyecto.sh` en Colab) tiene filas `v1`, `v3_kernel` (sin transferencias) y `v3_total` (con transferencias), o `V1`, `V3-kernel` y `V3`, medidas en la misma sesión | `cut -d, -f1 resultados/mediciones_v3.csv` | 12 | C4 |
| 13 | `resultados/entorno.txt` describe CPU (núcleos físicos y lógicos), RAM, SO, compilador y banderas | `cat resultados/entorno.txt` | 13 | C4 |
| 14 | `resultados/entorno_gpu.txt` tiene el modelo de GPU, driver, memoria y la **fecha** de la sesión | `cat resultados/entorno_gpu.txt` | 14 | C4 |
| 15 | Hay una gráfica `resultados/speedup.png` de *speedup* vs hilos **con la línea ideal `S = p`** y barras mín–máx | Abrir el PNG; el script solo revisa que haya un PNG | 15 (en parte) | R5 |

## D. V3 en Colab/Kaggle

| # | ¿Sí o no? | Cómo se verifica | Auto | Rúbrica |
|---|---|---|---|---|
| 16 | `v3/notebook_colab.ipynb` está **ejecutado** (tiene salidas, incluye `!nvidia-smi` y su salida muestra la GPU) y sus celdas `%%writefile` son copias exactas del código del repositorio | Abrirlo en GitHub: se ven las salidas sin ejecutar nada. Si cambiaste el código, regenera el *notebook* y vuelve a ejecutarlo | 16 | C5 |
| 17 | La celda de verificación del *notebook* muestra `PASS v3 == v1` (misma `n` y semilla, misma sesión) | Buscar `PASS v3 == v1` en las salidas | 17 | C1 |

## E. Reporte, bitácora y proceso

| # | ¿Sí o no? | Cómo se verifica | Auto | Rúbrica |
|---|---|---|---|---|
| 18 | `reporte/reporte.pdf` existe y tiene entre 8 y 12 páginas | `pdfinfo reporte/reporte.pdf \| grep Pages` (o abrirlo) | 18 | R1 |
| 19 | `bitacora.md` tiene ≥ 3 entradas de errores fechadas (primera columna `AAAA-MM-DD`) con qué falló, cómo se detectó, causa, cambio y aprendizaje; para C6 Ejemplar, ≥ 5, una medición descartada y una predicción comparada | `grep -c '^\| 20' bitacora.md` cuenta todas las filas fechadas; el script las cuenta por sección | 19 | C6 |
| 20 | La declaración de uso de IA está en el README §7 (o en `declaracion-ia.md`, sección "Entrega final") y en el PDF §12, con la línea "qué nos dijo la IA que resultó estar mal" llena | `grep -n 'resultó estar mal' README.md declaracion-ia.md` y leer el PDF §12 | 20 (en parte: no lee el PDF) | R7 |
| 21 | `git shortlog -sn HEAD` muestra *commits* de **todos** los integrantes; para C6 Ejemplar, cada uno con ≥ 3 *commits* de código en ≥ 3 semanas distintas (C6 es por integrante) | `git log --format='%an %ad' --date=short \| sort \| uniq -c`; el script avisa por autor | 21 | C6 |
| 22 | No hay binarios ni objetos versionados (`v1/v1`, `*.o`, `*.out`) ni datos > 10 MB sin script de descarga | `git ls-files \| xargs ls -l \| sort -k5 -n \| tail` | 22 | C5 |
| 23 | Todo está en GitHub: el árbol de trabajo está limpio y no hay *commits* sin subir | `git status` → "nothing to commit"; `git log origin/main..main` vacío | 23 | C5 |
| 24 | Existe la etiqueta `entrega-final` en el *commit* que se quiere calificar y está en GitHub | `git describe --tags --exact-match` imprime `entrega-final`; `git ls-remote --tags origin` la muestra | 24 | — |
| 25 | Cada número de las tablas y gráficas del PDF se encuentra en `resultados/*.csv` (misma `n`, misma semilla, misma fecha de GPU) | Tomar 5 números al azar del PDF y buscarlos con `grep` en los CSV | manual | R5, C4 |

## Lo que el verificador revisa además (líneas `P`)

- **FAIL P** si el cómputo de marcador de posición de la plantilla (`elemento()` de `comun/problema.h`) sigue en V1, V2 o
  V3: entregarlo tal cual vale 0 en C1.
- **AVISO P** si `README.md` o `bitacora.md` conservan marcadores «…» de la plantilla sin llenar.

## Recordatorios que ningún script revisa

- La predicción de *speedup* está escrita en la bitácora con fecha **anterior** a las mediciones.
- Las tablas del PDF declaran `n`, semilla y máquina; las de la V3, además, el modelo de GPU y la fecha.
- Cualquier integrante puede explicar cualquier línea del repositorio: en la defensa del jueves 10 de diciembre se pregunta
  a cada uno por separado.
- Lo que no funciona está dicho en el README §8 y en el reporte §10, no escondido.
