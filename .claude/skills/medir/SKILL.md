---
name: medir
description: "Aplica el protocolo de medición del curso (calentamiento + 5 repeticiones, mediana, speedup, eficiencia) a un programa OpenMP, MPI o Python y deja el CSV del protocolo y entorno.txt en resultados/. Úsalo cuando se pida medir tiempos, obtener speedup o eficiencia, comparar configuraciones (schedule, cutoff, -O2 frente a -O3) o preparar la Parte D de una práctica."
argument-hint: "[-c CONFIG] [-t \"1 2 4 8\"] [-n N] [-r 5] [-o resultados/mediciones.csv] [--mpi] -- ./programa [args]"
allowed-tools: Bash(herramientas/medir.sh:*), Bash(./herramientas/medir.sh:*), Bash(./medir.sh:*), Bash(${CLAUDE_SKILL_DIR}/scripts/bench.sh:*), Bash(make:*), Bash(nproc), Bash(lscpu:*), Bash(uptime), Read, Glob
---
# /medir — medición según el protocolo del curso

Argumentos recibidos: `$ARGUMENTS`

## Qué herramienta usar
1. Si existe `herramientas/medir.sh` (o `./medir.sh` en la carpeta de la práctica), **úsalo**: es el oficial del
   curso y lo que los estudiantes usan.
2. Si no existe en esta rama, usa `${CLAUDE_SKILL_DIR}/scripts/bench.sh`, que acepta las mismas opciones y escribe el
   mismo CSV (`config,hilos,n,rep1..repR,mediana_s,speedup,eficiencia`) y el mismo `entorno.txt`.
3. Si la práctica tiene `make medir` (P4–P6 lo tienen), prefiérelo: ya fija la configuración correcta.

## Antes de medir (protocolo §1)
- Compilado con `-O2`, sin warnings, y `make test` en verde. No se mide un programa incorrecto ni un binario de TSan.
- El programa imprime `tiempo_s=<segundos>` de la región de interés (ver `herramientas/cronometro.h`) y acepta `n`
  como último argumento. Si imprime otra clave, usa `--clave`.
- `uptime`: carga < 0.5. **Nunca** corras dos mediciones a la vez ni en segundo plano con otra carga.
- Elige `n` de modo que la versión secuencial tarde >= 1 s (si tarda menos, el script avisa y la fila no es evidencia).

## Orden de las corridas
```bash
# 1) línea base: la MEJOR versión secuencial (no la paralela con 1 hilo)
herramientas/medir.sh -c secuencial -t 1 -n N -o resultados/mediciones.csv -- ./programa_seq
# 2) la versión paralela con la lista de hilos (hasta núcleos físicos + 1; en el contenedor cloud: 1 2 4 8)
herramientas/medir.sh -c openmp -t "1 2 4 8" -n N -o resultados/mediciones.csv -- ./programa
# MPI: procesos en lugar de hilos
MPIRUN_FLAGS=--oversubscribe herramientas/medir.sh --mpi -c mpi -t "1 2 4" -n N -o resultados/mediciones.csv -- ./programa_mpi
# Variantes: una etiqueta -c por variante en el MISMO CSV (static, dynamic-64, cutoff-4096, O3…)
```
Si el usuario pasó argumentos, respétalos; si falta `-c secuencial`, hazlo primero y explica por qué (idea errónea 31:
comparar contra la paralela con 1 hilo infla el speedup).

## Después de medir
1. Revisa el ruido: si en alguna fila `(máx - mín)/mediana > 0.15`, repite esa configuración con `-r 9` en otro CSV.
2. Grafica con `/graficar resultados/mediciones.csv` y pide la interpretación a `perf-analyst`.
3. Deja `entorno.txt` junto al CSV (lo escribe el script) y cita la fila exacta en el reporte. Nunca edites un CSV a mano.
