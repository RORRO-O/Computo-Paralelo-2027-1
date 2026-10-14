# Lista de cotejo de la entrega final (25 ítems sí/no)

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Entrega final · lunes 7 de diciembre de 2026, 10:30 · Autoevaluación del equipo; se usa también entre equipos en la sesión del jueves 3 de diciembre · versión 1.0 · 14 de octubre de 2026

## Cómo usarla

1. Clona tu propio repositorio en una carpeta nueva (lo que tienes en tu disco no es lo que verá el profesor):
   `git clone https://github.com/.../cp-6bm1-equipoNN /tmp/prueba && cd /tmp/prueba`.
2. Corre el verificador del curso sobre ese clon. Revisa los ítems 1–24 en segundos y ejecuta `make`, `make test` y
   `run_all.sh --rapido` en una copia temporal:
   `bash /ruta/al/curso/proyecto/entrega-final/scripts/verificar_entrega.sh /tmp/prueba`
3. Marca cada ítem **sí** o **no**. "Casi" es **no**. El ítem 25 y los recordatorios finales se revisan a mano, de
   preferencia por otro equipo (sesión del jueves 3 de diciembre).
4. Cada **no** señala el criterio de rúbrica que va a bajar. Arréglalo o escríbelo en el README §8 ("lo que no funciona").
5. Repite desde el paso 1 después del último *commit*. Luego `git tag entrega-final && git push --tags`.

Columnas: **Auto** = lo verifica el script con ese número; **Rúbrica** = criterio de `rubrica-codigo.md` (C) o
`rubrica-reporte.md` (R) afectado.

## A. Estructura del repositorio

| # | ¿Sí o no? | Cómo se verifica | Auto | Rúbrica |
|---|---|---|---|---|
| 1 | `README.md` en la raíz dice: problema, datos y semillas, cómo compilar, cómo reproducir cada figura (`run_all`), hardware/entorno, integrantes y reparto, uso de IA | Abrirlo; el script busca esas palabras | 1 | C5 |
| 2 | `Makefile` en la raíz con los objetivos `all`, `run`, `test`, `clean` | `grep -E '^(all|run|test|clean):' Makefile` | 2 | C5 |
| 3 | `run_all.sh` existe y es ejecutable | `ls -l run_all.sh` muestra `x`; si no: `chmod +x run_all.sh` y *commit* | 3 | C5 |
| 4 | Hay carpetas `v1*/`, `v2*/`, `v3*/` con una versión cada una y su `Makefile` | `ls -d v1* v2* v3*` | 4 | C5 |
| 5 | `tests/run_tests.sh` existe y tiene al menos **dos casos propios** del equipo con comentario de por qué importan | Abrirlo; sección "Casos del equipo" | 5 (solo existencia) | C1 |

## B. Compila, prueba y corre

| # | ¿Sí o no? | Cómo se verifica | Auto | Rúbrica |
|---|---|---|---|---|
| 6 | `make all` compila sin un solo *warning* con `-Wall -Wextra` | `make clean && make all 2>&1 \| grep -i warning` no imprime nada | 6 | C5 |
| 7 | `make test` termina con código 0 y todos los casos imprimen `PASS` | `make test; echo $?` → `0` | 7 | C1 |
| 8 | `./run_all.sh --rapido` termina sin error en menos de 15 minutos en un clon limpio | Cronometrar; código 0 | 8 | C5 |

## C. Mediciones (protocolo)

| # | ¿Sí o no? | Cómo se verifica | Auto | Rúbrica |
|---|---|---|---|---|
| 9 | `resultados/mediciones.csv` tiene la cabecera `config,hilos,n,rep1,…,rep5,mediana_s,speedup,eficiencia` (≥ 5 repeticiones) | `head -1 resultados/mediciones.csv` | 9 | C4 |
| 10 | El CSV tiene una fila `v1` y al menos tres filas `v2` con hilos distintos (1, 2, 4, …) | `cut -d, -f1,2 resultados/mediciones.csv` | 10 | C4 |
| 11 | `T(1)` de la fila `v1` es ≥ 1 s (no es el CSV de `--rapido`) | Columna `mediana_s` de la fila `v1` | 11 | C4 |
| 12 | `resultados/mediciones_v3.csv` tiene filas `v1`, `v3_kernel` (sin transferencias) y `v3_total` (con transferencias) medidas en la misma sesión | `cut -d, -f1 resultados/mediciones_v3.csv` | 12 | C4 |
| 13 | `resultados/entorno.txt` describe CPU (núcleos físicos y lógicos), RAM, SO, compilador y banderas | `cat resultados/entorno.txt` | 13 | C4 |
| 14 | `resultados/entorno_gpu.txt` tiene el modelo de GPU, driver, memoria y la **fecha** de la sesión | `cat resultados/entorno_gpu.txt` | 14 | C4 |
| 15 | Hay una gráfica `resultados/speedup.png` de *speedup* vs hilos **con la línea ideal `S = p`** | Abrir el PNG; el script solo revisa que exista | 15 (solo existencia) | R5 |

## D. V3 en Colab/Kaggle

| # | ¿Sí o no? | Cómo se verifica | Auto | Rúbrica |
|---|---|---|---|---|
| 16 | `v3*/notebook_colab.ipynb` está **ejecutado**: tiene salidas, incluye `!nvidia-smi` y su salida muestra la GPU | Abrirlo en GitHub: se ven las salidas sin ejecutar nada | 16 | C5 |
| 17 | La celda de verificación del *notebook* muestra `PASS` de V3 contra V1 (misma `n` y semilla, misma sesión) | Buscar `PASS v3 == v1` en las salidas | 17 | C1 |

## E. Reporte, bitácora y proceso

| # | ¿Sí o no? | Cómo se verifica | Auto | Rúbrica |
|---|---|---|---|---|
| 18 | `reporte/reporte.pdf` existe y tiene entre 8 y 12 páginas | `pdfinfo reporte/reporte.pdf \| grep Pages` (o abrirlo) | 18 | R1 |
| 19 | `bitacora.md` tiene ≥ 3 entradas fechadas (`\| AAAA-MM-DD \| …`) con qué falló, cómo se detectó, causa, cambio y aprendizaje | `grep -c '^| 20' bitacora.md` | 19 | C6 |
| 20 | La declaración de uso de IA está en el README y en el PDF, con la línea "qué nos dijo la IA que resultó estar mal" | `grep -n 'resultó estar mal' README.md` y leer el PDF §12 | 20 (solo README) | R7 |
| 21 | `git shortlog -sn` muestra *commits* de **todos** los integrantes, repartidos en el semestre | `git shortlog -sn --all`; `git log --format='%an %ad' --date=short \| sort \| uniq -c` | 21 | C6 |
| 22 | No hay binarios ni objetos versionados (`v1/v1`, `*.o`, `*.out`) ni datos > 10 MB sin script de descarga | `git ls-files \| xargs ls -l \| sort -k5 -n \| tail` | 22 | C5 |
| 23 | Todo está en GitHub: el árbol de trabajo está limpio y `git status` no muestra cambios ni *commits* sin subir | `git status` → "nothing to commit"; `git log origin/main..main` vacío | 23 | C5 |
| 24 | Existe la etiqueta `entrega-final` en el *commit* que se quiere calificar y está en GitHub | `git tag` y `git ls-remote --tags origin` | 24 | — |
| 25 | Cada número de las tablas y gráficas del PDF se encuentra en `resultados/*.csv` (misma `n`, misma semilla, misma fecha de GPU) | Tomar 5 números al azar del PDF y buscarlos con `grep` en los CSV | manual | R5, C4 |

## Recordatorios que ningún script revisa

- El cómputo de la plantilla (`elemento()` en `comun/problema.h`) fue sustituido por el problema del equipo en V1, V2 y V3.
- La predicción de *speedup* está escrita en la bitácora con fecha **anterior** a las mediciones.
- Cualquier integrante puede explicar cualquier línea del repositorio: en la defensa del jueves 10 de diciembre se pregunta
  a cada uno por separado.
- Lo que no funciona está dicho en el README §8 y en el reporte §10, no escondido.
