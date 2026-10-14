# resultados/ · formato de los archivos de medición

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Formato según `herramientas/protocolo-medicion.md` §4

Esta carpeta la llenan `run_all.sh` (CPU) y el notebook de la V3 (GPU). No se edita a mano. Si una
medición se repite, se sobrescribe y se anota en `bitacora.md` por qué.

| Archivo | Quién lo escribe | Contenido |
|---|---|---|
| `entorno.txt` | `run_all.sh` | CPU, núcleos físicos/lógicos, RAM, SO, compilador, banderas, fecha, commit, n, semilla, hilos |
| `mediciones.csv` | `run_all.sh` | Filas `v1` y `v2` con la cabecera del protocolo (abajo) |
| `entorno_gpu.txt` | notebook, celda 1 | Modelo de GPU, driver, memoria, capacidad de cómputo, fecha UTC, nvcc, CPU del anfitrión |
| `mediciones_v3.csv` | notebook, celda 5 | Filas `v1` (medida en Colab), `v3_kernel` (sin transferencias) y `v3_total` (con transferencias) |
| `tabla.md` | `herramientas/resumen_csv.py` | Tabla Markdown con mediana, mín, máx, speedup, eficiencia y Karp–Flatt para pegar en el reporte |
| `speedup.png` | `herramientas/resumen_csv.py` | Speedup vs hilos con la línea ideal `S = p` y, si existe el CSV de V3, sus líneas horizontales |

## Cabecera obligatoria del CSV

```
config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia
```

- `config`: `v1`, `v2`, `v3_kernel`, `v3_total`. En filas de GPU `hilos` vale `0` y `eficiencia` va vacía.
- `rep1..rep5`: tiempos en segundos de la región de interés, **después** de 1 ejecución de calentamiento que
  no se registra. Pueden ser más de 5 (`--reps 7` produce `rep1..rep7`); nunca menos.
- `mediana_s`: mediana de las repeticiones. `speedup = T(1)/T(p)` donde `T(1)` es la fila `v1` **del mismo
  archivo** (misma máquina). `eficiencia = speedup / hilos`.
- `n` y la semilla son los mismos en todas las filas del archivo; si cambian, es otro archivo y se declara
  (escalabilidad débil, protocolo §3).
