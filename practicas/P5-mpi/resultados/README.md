> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Práctica 5 · Simulación distribuida con MPI · Parte D · entrega domingo 22 de noviembre de 2026, 23:59

# `resultados/` · Evidencia de la Parte D

Esta carpeta está vacía en el repositorio del curso; en el repositorio de tu equipo contiene las mediciones de la
Parte D. Todo lo que hay aquí debe poder regenerarse con un comando; nada se edita a mano.

## Qué debe haber y de dónde sale

| Archivo | Lo produce | Contenido |
|---|---|---|
| `entorno.txt` | `./escalado.sh` (o `make run-d`) | Fecha, CPU, núcleos **físicos** y lógicos, RAM, compilador, MPI, banderas, `cpu_ociosa_antes_de_medir`, carga promedio, tamaños usados. Sin esto la Parte D no cuenta (protocolo §1.4) |
| `fuerte.csv` | `./escalado.sh` | Escalabilidad **fuerte**: tamaño fijo, p = 1, 2, 4, … hasta los núcleos físicos (+ 2 × núcleos sobre-suscrito: 8 en 4 núcleos). `speedup = T_seq / T(p)`, `eficiencia = speedup / p` |
| `debil.csv` | `./escalado.sh` | Escalabilidad **débil**: tamaño por proceso fijo, n = p × NLOCAL. Aquí `eficiencia` es la **eficiencia débil** `T_seq(n_local) / T(p, p·n_local)` y `speedup` es el *speedup* escalado `p × eficiencia` |
| `pingpong.txt` | `make pingpong > resultados/pingpong.txt` | Tabla de latencia y ancho de banda por tamaño, α y β, línea `RESULT,d_pingpong,...`. **Misma máquina** que los CSV |
| `fuerte.png`, `debil.png` | `graficar.py` (lo llama `escalado.sh`; vuelve a dibujar con `make graficas`) | *Speedup* vs p con la línea ideal `S = p` y, con `--modelo α β t_c`, la curva del modelo; eficiencia débil vs p con `E = 1`. El punto sobre-suscrito va hueco y anotado "p > núcleos" |

Formato de los CSV (el del protocolo, `herramientas/protocolo-medicion.md` §4; la columna se llama `hilos` por el
formato fijo, en MPI son procesos):

```
config,hilos,n,rep1,rep2,rep3,rep4,rep5,mediana_s,speedup,eficiencia
seq,1,1000000,...
mpi,1,1000000,...
mpi,2,1000000,...
mpi,4,1000000,...
mpi_oversub,8,1000000,...
```

- `rep1..rep5`: segundos de la región de interés en cada repetición, **después** de una ejecución de calentamiento
  que no se cuenta; `mediana_s`: mediana de las cinco. Los programas también imprimen mín y máx.
- `seq`: el programa secuencial (`c_heat_seq`, `b_matvec_seq` o `c_primes_seq`). Es el T(1) del protocolo. La fila
  `mpi,1` es el programa MPI con un proceso y se reporta para ver cuánto cuesta el arnés (barrera, relojes, `Waitall`
  con vecinos nulos, `Allreduce` de uno).
- `mpi_oversub`: p mayor que el número de núcleos físicos (`escalado.sh` lo decide con `lscpu`). Se reporta, pero
  **aparte**: no forma parte de la curva de escalabilidad y se explica en el reporte (idea errónea 20).

## Cómo se generan

```bash
make run-d                                    # calor 1D: N=1000000 ITERS=1200; débil NLOCAL=250000; p = 1 2 4 + 8 (en 4 núcleos); luego el ping-pong
make pingpong > resultados/pingpong.txt       # guarda el ping-pong (make run-d lo imprime pero no lo guarda)
PROG=matvec OUT=resultados/matvec ./escalado.sh   # Parte B (M = 2000, 400 productos): cierra la predicción del pre-lab
PROG=primes MODO=ciclico ./escalado.sh        # si tu Parte C es la alternativa de primos ([2, 6 000 000])
PROG=primes MODO=bloques OUT=resultados/bloques ./escalado.sh   # ...y el reparto por bloques, para comparar
python3 graficar.py resultados/fuerte.csv resultados/debil.csv resultados --modelo <alpha_us> <beta_gbps> <tc_ns>
```

Antes de medir: `make test-entrega` en verde (un programa incorrecto no tiene *speedup*), cierra lo demás, y comprueba
que `T_seq ≥ 1 s` en `fuerte.csv` (si no, sube `ITERS` o `N`). Si `escalado.sh` avisa que la CPU ociosa es < 85 %, hay
otro programa usando la máquina: ciérralo y repite; si no puedes (laboratorio compartido), déjalo escrito en el reporte.
`WAIT_IDLE=60 ./escalado.sh` espera hasta 60 s antes de cada corrida a que la CPU esté ≥ 90 % ociosa.

## Lo que no va aquí

Binarios, salidas de `make test` (`tests/out/`), corridas de prueba (`resultados-prueba/`). Están en `.gitignore`.
