# Plantillas del proyecto integrador

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Plantillas · versión 1.1 · 20 de octubre de 2026

Archivos que tu equipo copia a su repositorio `cp-6bm1-equipoNN` y llena. No son ejemplos: son el formato
que el profesor espera encontrar en H1 (jueves 29 de octubre), H2 (lunes 23 de noviembre) y la entrega final
(lunes 7 de diciembre, 10:30). La estructura del repositorio está en `proyecto/README.md` §4; es la misma que
revisa la entrega final, así que no hay que reorganizar nada en diciembre.

| Archivo | Va en tu repositorio como | Para qué |
|---|---|---|
| `bitacora-errores.md` | `bitacora.md` (raíz) | Fallas (qué pasó, cómo se detectó, qué se cambió), mediciones descartadas, búsqueda del tamaño declarado, predicciones vs. resultados. Primera columna = fecha `AAAA-MM-DD` |
| `declaracion-ia.md` | `declaracion-ia.md` (raíz) | Declaración de uso de IA por entrega, según `docs/metodo/05-politica-ia.md` |
| `run_all.sh` | `herramientas/medir_proyecto.sh` | Mide **una** configuración con el protocolo (calentamiento + 5 repeticiones, mediana, mín, máx, *speedup*, eficiencia, entorno) y agrega filas a un CSV. Para el perfil de H1, la tabla de hilos de H2, los experimentos de `schedule` y la V3 en Colab |
| `graficar_proyecto.py` | `herramientas/graficar_proyecto.py` | Tabla en Markdown (mediana, mín, máx, *speedup*, eficiencia, Karp–Flatt) y gráficas `speedup.png` (línea ideal y barras mín–máx), `eficiencia.png`, `comparacion.png` |
| `plantilla_main.c` | base de `v1/main.c` y `v2/main.c` | Esqueleto que cumple el contrato de los programas: `[n] [semilla] [hilos]`, cronometra solo la región de interés, imprime `tiempo_s=` y `checksum=` |
| `Makefile` | referencia para `v1/Makefile` y `v2/Makefile` | Objetivos `all`, `run`, `test`, `clean` (`docs/CONVENCIONES.md` §3); compila la misma fuente sin y con OpenMP |
| `tests/run_tests.sh` | referencia para `tests/run_tests.sh` (raíz) | Patrón de prueba automática: `PASS`/`FAIL` por caso, código 0 solo si todo pasa |

El `run_all.sh` de la **raíz** de tu repositorio es otro: el que reproduce todas las mediciones de `resultados/` y
acepta `--rapido`, porque así lo ejecuta `proyecto/entrega-final/scripts/verificar_entrega.sh`. El de
`proyecto/entrega-final/plantilla-repo/` ya lo cumple; por eso este se copia como `herramientas/medir_proyecto.sh`.

## Cómo copiarlas

Desde la raíz del repositorio del curso, con tu repositorio en `../cp-6bm1-equipoNN` y sus carpetas `v1/`, `v2/`
y `herramientas/` ya creadas:

```bash
cp proyecto/plantillas/bitacora-errores.md ../cp-6bm1-equipoNN/bitacora.md
cp proyecto/plantillas/declaracion-ia.md   ../cp-6bm1-equipoNN/declaracion-ia.md
cp proyecto/plantillas/run_all.sh          ../cp-6bm1-equipoNN/herramientas/medir_proyecto.sh
cp proyecto/plantillas/graficar_proyecto.py ../cp-6bm1-equipoNN/herramientas/
cp proyecto/plantillas/plantilla_main.c    ../cp-6bm1-equipoNN/v1/main.c     # solo si no partes de plantilla-repo
```

Si partes de `proyecto/entrega-final/plantilla-repo/` (recomendado), ya tienes `v1/main.c`, `v2/main.c`, el
`Makefile` raíz, `tests/run_tests.sh`, `run_all.sh` con el mismo contrato y `bitacora.md` (idéntica a
`bitacora-errores.md`); de aquí copias solo la declaración de IA, `medir_proyecto.sh` y `graficar_proyecto.py`.

## Cómo verificar que las herramientas funcionan en tu máquina

```bash
cd proyecto/plantillas
make            # compila plantilla_main.out (con OpenMP) y plantilla_sec.out (sin OpenMP)
make test       # 33 verificaciones: esqueleto, medir_proyecto.sh (run_all.sh) y graficar_proyecto.py
make clean
```

`make test` tarda menos de 10 s (3 s en la máquina de autoría). Si falla en tu máquina, anota la salida en tu
bitácora y llévala a asesoría.

## Contrato entre tu programa y los scripts de medición

Es el de la entrega final (`proyecto/entrega-final/README.md` §3 y `reproducibilidad.md` §2.3):

1. Argumentos `[n] [semilla] [hilos]`, opcionales y en ese orden. Sin `hilos`, la V2 toma `OMP_NUM_THREADS`.
2. Salida `clave=valor`, una por línea: al menos `tiempo_s=<segundos>` (solo la región de interés: sin lectura de
   archivos, sin creación del equipo de hilos, sin impresión) y `checksum=<valor>` (lo que las pruebas comparan
   contra V1 con tolerancia).
3. V3: además `tiempo_kernel_s=` (sin transferencias) y `tiempo_total_s=` (con transferencias);
   `medir_proyecto.sh` toma `tiempo_total_s=` como tiempo de la fila `V3` y genera la fila `V3-kernel`.
4. Código 0 si todo bien; distinto de 0 (2 en la plantilla) si un argumento no es válido, con mensaje en `stderr`.

`medir_proyecto.sh` pasa `n` como último argumento: llámalo con `-- ./v2/v2`, sin más argumentos, y el programa
usará su semilla por defecto. Acepta también líneas `TIEMPO_S <s>` y `TIEMPO_KERNEL_S <s>` de programas escritos
con la versión anterior de esta plantilla.

El `entorno.txt` que escribe incluye núcleos físicos y lógicos y las banderas de compilación, que piden las rúbricas
de H1 (criterio 3) y H2 (criterio 2). Las banderas las toma de las líneas `CFLAGS`/`NVFLAGS`/`LDLIBS` del `Makefile`
de la carpeta del programa (`./v2/v2` → `v2/Makefile`); si compilaste de otra forma, decláralas al medir:
`BANDERAS="-std=c11 -O2 -fopenmp" ./herramientas/medir_proyecto.sh …`.

Cómo usar cada herramienta, con ejemplos ejecutables, está en su cabecera (`./run_all.sh -h`,
`python3 graficar_proyecto.py --help`). La guía completa de medición es `proyecto/medicion-en-el-proyecto.md`.
