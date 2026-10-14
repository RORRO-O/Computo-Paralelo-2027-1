# Plantillas del proyecto integrador

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Plantillas · versión 1.0 · 14 de octubre de 2026

Archivos que tu equipo copia a su repositorio `cp-6bm1-equipoNN` y llena. No son ejemplos: son el formato
que el profesor espera encontrar.

| Archivo | Va en tu repositorio como | Para qué |
|---|---|---|
| `bitacora-errores.md` | `bitacora-errores.md` (raíz) | Registro de fallas: qué pasó, cómo se detectó, qué se cambió. Se revisa en H1, H2 y la entrega final |
| `declaracion-ia.md` | `declaracion-ia.md` (raíz) | Declaración de uso de IA por entrega, según `docs/metodo/05-politica-ia.md` |
| `run_all.sh` | `run_all.sh` (raíz) | Aplica el protocolo de medición (calentamiento + 5 repeticiones, mediana, speedup, eficiencia, entorno) y llena `resultados/mediciones.csv` |
| `graficar_proyecto.py` | `herramientas/` o raíz | Tabla en Markdown y gráficas (`speedup.png`, `eficiencia.png`, `comparacion.png`) a partir del CSV |
| `plantilla_main.c` | base de `src/v1/main.c` y `src/v2/main.c` | Esqueleto que cronometra solo la región de interés e imprime `RESULTADO` y `TIEMPO_S` en el formato que `run_all.sh` lee |
| `Makefile` | referencia para `src/v1/Makefile`, `src/v2/Makefile` | Objetivos `all`, `run`, `test`, `clean` como exige `docs/CONVENCIONES.md` §3 |
| `tests/run_tests.sh` | referencia para `src/vN/tests/run_tests.sh` | Patrón de prueba automática: `PASS`/`FAIL` por caso, código 0 solo si todo pasa |

## Cómo copiarlas

Desde la raíz del repositorio del curso:

```bash
cp proyecto/plantillas/bitacora-errores.md proyecto/plantillas/declaracion-ia.md proyecto/plantillas/run_all.sh  ../cp-6bm1-equipoNN/
cp proyecto/plantillas/graficar_proyecto.py ../cp-6bm1-equipoNN/herramientas/
cp proyecto/plantillas/plantilla_main.c ../cp-6bm1-equipoNN/src/v1/main.c
```

## Cómo verificar que las herramientas funcionan en tu máquina

```bash
cd proyecto/plantillas
make            # compila plantilla_main.out
make test       # 17 verificaciones: resultado, run_all.sh, graficar_proyecto.py
make clean
```

`make test` tarda menos de un minuto. Si falla en tu máquina, anota la salida en tu bitácora y llévala a asesoría.

## Contrato entre tu programa y `run_all.sh`

1. El tamaño del problema es el **último argumento** de la línea de comandos.
2. El programa imprime `TIEMPO_S <segundos>` con el tiempo de la región de interés (sin lectura de archivos ni impresión).
3. Opcional en V3: imprime `TIEMPO_KERNEL_S <segundos>` con el tiempo sin transferencias; `run_all.sh` genera una fila `V3-kernel`.
4. Termina con código 0. Imprime `RESULTADO <valor>` para que las pruebas comparen contra V1.

Cómo usar cada herramienta, con ejemplos ejecutables, está en la cabecera de cada archivo (`./run_all.sh -h`,
`python3 graficar_proyecto.py --help`). La guía completa de medición es `proyecto/medicion-en-el-proyecto.md`.
