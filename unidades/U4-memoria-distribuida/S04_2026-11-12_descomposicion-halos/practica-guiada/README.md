> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S04 · jueves 12 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# Práctica guiada S04 · Jacobi 1D con celdas fantasma (PRIMM)

Trabajo en parejas: **conductor** (teclado) y **navegante** (lee, predice, anota). Cambian de rol a los 12 minutos.
Antes de correr nada, escribe tus predicciones. Una predicción equivocada vale más que una ejecución sin predicción.

## Qué hay en esta carpeta

| Archivo | Qué es |
|---|---|
| `jacobi1d_seq.c` | Versión secuencial de referencia (la de U3-S11, sin OpenMP). Contra ella se verifica todo. |
| `jacobi1d_mpi.c` | Versión MPI: reparto por bloques, halos con `MPI_Sendrecv`, convergencia con `MPI_Allreduce`, reconstrucción con `MPI_Gatherv`. Incluye `exchange_halos_isend` con `TODO(1)`–`TODO(4)` para la fase Modificar. |
| `jacobi1d_mpi_buggy.c` | Versión con un error a propósito: nunca llena el halo izquierdo. |
| `graficar_perfil.py` | Grafica el perfil de temperatura de una o varias salidas con `--print`. |
| `Makefile` | `make`, `make run`, `make test`, `make clean`. |
| `tests/run_tests.sh` | Compara MPI contra secuencial con tolerancia 1e-12; los casos `isend` quedan en `SKIP` hasta que completes los TODO. |

El problema: ecuación de calor estacionaria en una barra de `n` celdas. Frontera izquierda fija en 100, derecha en 0,
interior inicial en 0. Jacobi: `u_new[i] = 0.5 * (u[i-1] + u[i+1])` hasta que `max |u_new - u| < tol`.
La solución exacta es una recta de 100 a 0.

Compila una vez:

```bash
make            # gcc / mpicc -std=c11 -O2 -Wall -Wextra; no debe salir ningún warning
```

Si `mpirun` se queja de "not enough slots", agrega `--oversubscribe` (ya está en `MPIRUN_FLAGS` del Makefile).

## P · Predecir (6 min, sin ejecutar)

Lee `block_partition` y `exchange_halos_sendrecv` en `jacobi1d_mpi.c`. Escribe tus respuestas antes de pasar a R.

**P1. Reparto.** Con `n = 12` y `p = 3`, completa la tabla (índices globales de 1 a 12; la frontera izquierda es la celda 0 y la derecha la 13):

| Rango | `local_n` | Celdas globales | Vecino izq. | Vecino der. |
|---|---|---|---|---|
| 0 | | | | |
| 1 | | | | |
| 2 | | | | |

**P2. Halos del rango 1.** En cada iteración, ¿qué celda global envía el rango 1 al rango 0? ¿Cuál al rango 2?
¿Qué celda global recibe en su halo izquierdo `u[0]` y de quién? ¿Y en su halo derecho `u[local_n+1]`?

Envía: ______ a rango 0 y ______ a rango 2. Recibe: `u[0]` ← celda ______ (de rango ___); `u[local_n+1]` ← celda ______ (de rango ___).

**P3. Rango 0.** Su vecino izquierdo es `MPI_PROC_NULL`. Después del intercambio, ¿qué valor tiene `u[0]` en el rango 0? ¿Por qué?

**P4. Iteraciones.** Corre primero **solo la secuencial**: `./jacobi1d_seq 12 1e-3 100000`. Anota `iteraciones=______`.
Ahora predice: la versión MPI con 3 procesos, ¿termina en el mismo número de iteraciones, en más o en menos? Justifica
en una línea pensando en qué operaciones hace cada celda y cómo se calcula la diferencia máxima.

**P5. Sin halo izquierdo.** `jacobi1d_mpi_buggy.c` nunca ejecuta el intercambio que llena `u[0]`. Marca una y justifica:
(a) se interbloquea, (b) termina con error de MPI, (c) termina sin error pero con resultado incorrecto, (d) termina con el resultado correcto porque el halo derecho basta.
Si elegiste (c): ¿qué valor usan los rangos 1 y 2 como vecino izquierdo durante toda la ejecución? ¿Qué perfil esperas en las celdas 5 a 12?

## R · Ejecutar (4 min)

```bash
./jacobi1d_seq 12 1e-3 100000 --print                      > perfil_seq.txt
mpirun --oversubscribe -np 3 ./jacobi1d_mpi 12 1e-3 100000 --trace 2 --print  > perfil_mpi.txt
mpirun --oversubscribe -np 3 ./jacobi1d_mpi_buggy 12 1e-3 100000 --print      > perfil_buggy.txt
head -5 perfil_seq.txt perfil_mpi.txt perfil_buggy.txt
```

Compara con P1–P5. La traza (`--trace 2`) imprime, por rango y en orden, qué envía y qué recibe en las dos primeras iteraciones.
Salida real del entorno de autoría (los `tiempo_s` cambian en cada corrida; lo demás no):

```
reparto: rango 1 tiene local_n=4 (celdas globales 5..8); vecino izq: rango 0; vecino der: rango 2
[it 1] rango 1: celdas 5..8 | envia u[5] a rango 0 y u[8] a rango 2 | recibe halo izq u[4]=0.0000, halo der u[9]=0.0000
...
iteraciones=280 convergio=1
checksum=5.998646183794e+02
```

Secuencial: `iteraciones=280`, `checksum=5.998646183794e+02`. Buggy con 3 procesos: `iteraciones=49`, `checksum=1.999941466768e+02`.

Gráfica (opcional, 1 min): `python3 graficar_perfil.py perfil_seq.txt perfil_mpi.txt perfil_buggy.txt` y abre `perfil.png`.
Las curvas secuencial y MPI se encimaran; la buggy baja a 0 desde la celda 5.

## I · Investigar (7 min)

**I1. Tabla de rastreo del rango 1 (iteración 1).** Llena con lo que imprimió `--trace`:

| Dato | Valor | ¿De dónde salió? |
|---|---|---|
| `u[0]` (halo izq.) antes de la iteración 1 | | |
| Celda que el rango 0 envía al rango 1 | | ¿qué índice local tiene en el rango 0? |
| `u[local_n+1]` (halo der.) en la iteración 1 | | |
| `u[0]` del rango 0 | | ¿por qué no es 0.0? |

**I2.** En la iteración 1 todos los halos recibidos valen `0.0000`. ¿Está fallando el intercambio? ¿Cómo lo compruebas con `--trace 6`
sin cambiar el código? (pista: el calor entra por la celda 1; ¿en qué iteración deja de ser 0 la celda 4 del rango 0, y en cuál
la ve el rango 1 en su halo?)

**I3.** Reparto desigual: `mpirun --oversubscribe -np 5 ./jacobi1d_mpi 13 1e-2 100000 --trace 1`. Anota `local_n` de cada rango. ¿Qué
rangos reciben la celda extra? Verifica contra la fórmula de `block_partition`: `base = n / p`, `rem = n % p`.

**I4. ¿Por qué el buggy termina en 49 iteraciones y no en 280?** Mira su perfil: celdas 1–4 en recta de 80 a 20, celdas 5–12 en 0.
¿Qué "frontera" cree ver cada rango a su izquierda? ¿Por qué converge *más rápido* un resultado incorrecto?

**I5. Convergencia global.** Localiza el `MPI_Allreduce`. ¿Qué pasaría si cada rango comparara solo su `local_diff` con `tol`?
Piensa en el rango 2 del buggy: sus celdas valen 0 desde el inicio; su `local_diff` es 0 en la iteración 1.

**I6. Un vistazo al tiempo (sin sacar conclusiones todavía).** `make run NP=1`, `make run NP=4` y `make run NP=8` imprimen
`tiempo_s` para `n = 1 000 000` y 1 000 iteraciones. Anota los tres y cuántos núcleos tiene tu laptop (`nproc`).
En el entorno de autoría (4 núcleos, máquina en reposo) salió: secuencial 1.63 s; MPI con 1 proceso 1.68–1.78 s; con 2, 1.01 s;
con 4, 0.55 s; con **8**, 0.77–0.80 s: más lento que con 4. Eso último es la sobre-suscripción (idea errónea 20): con más procesos
que núcleos, cada `Sendrecv` y cada `Allreduce` espera a un proceso que no está corriendo. En la misma máquina, pero con otros
4 procesos MPI corriendo a la vez (8 para 4 núcleos), el caso `n = 100, tol = 1e-4` (13 276 iteraciones; 1.1 s en reposo) tardó
22 s en una corrida y 79 s en otra: el mismo efecto, disparado por la carga ajena. Nada de esto es una medición (ni calentamiento, ni 5 repeticiones); cómo medirlo bien es el tema del martes 17 de noviembre (S05).

## M · Modificar (10 min): de `Sendrecv` a `Isend`/`Irecv`/`Waitall`

Objetivo verificable: `mpirun --oversubscribe -np 3 ./jacobi1d_mpi 12 1e-3 100000 --exchange isend` debe dar `iteraciones=280` y el
mismo `checksum` que la secuencial, y `make test` debe pasar los tres casos `isend` (hoy salen `SKIP`).

1. Abre `exchange_halos_isend` en `jacobi1d_mpi.c`. Hay cuatro `TODO`.
2. `TODO(1)`: dos `MPI_Irecv`. El halo izquierdo `u[0]` recibe lo que el vecino izquierdo mandó **hacia la derecha** (etiqueta `TAG_TO_RIGHT`).
   El halo derecho recibe lo que el vecino derecho mandó hacia la izquierda (`TAG_TO_LEFT`).
3. `TODO(2)`: dos `MPI_Isend`: `&u[local_n]` hacia `right` con `TAG_TO_RIGHT`; `&u[1]` hacia `left` con `TAG_TO_LEFT`.
4. `TODO(3)`: `MPI_Waitall(4, reqs, MPI_STATUSES_IGNORE)`. Antes de esa línea no puedes leer los halos ni escribir `u[1]` ni `u[local_n]`.
5. `TODO(4)`: `done = 1`, borra la línea de `(void)` y compila. **Cero warnings.**
6. Corre con `--exchange isend --trace 1` y compara con la traza de `sendrecv`: debe ser idéntica.

Firmas (del estándar MPI): `MPI_Irecv(buf, count, datatype, source, tag, comm, &request)`, `MPI_Isend(buf, count, datatype, dest, tag, comm, &request)`,
`MPI_Waitall(count, array_of_requests, array_of_statuses)`.

Preguntas al terminar: ¿por qué conviene publicar las recepciones antes que los envíos? ¿Qué cambiaría si `MPI_Waitall` estuviera *antes* de los `MPI_Isend`?
¿Qué pasa si intercambias las etiquetas de un `Irecv`? (pruébalo con `timeout 10 mpirun ...`; termina con `Ctrl+C` si no regresa).

## C · Crear (transferencia, 7 min en clase + tarea)

Elige una variante. Implémentala en **las dos** versiones (secuencial y MPI); el criterio de "listo" es que coincidan.

**Opción A · Fuente de calor en el centro.** Fronteras izquierda y derecha en 0; la celda global `src = (n + 1) / 2` se fija en 100 y
nunca se actualiza. Trampa prevista: en MPI la fuente se localiza con el índice **global**; conviértelo a local con `src - offset` y
fíjala solo en el rango donde cae (`1 <= src_local <= local_n`), en **ambos** arreglos. Valores de referencia obtenidos con la
solución del profesor (bandera `--source` en los dos programas): `./jacobi1d_seq 15 1e-3 100000 --source` → `iteraciones=117`,
`checksum=7.999401682787e+02`, perfil simétrico con máximo 100 en la celda 8; `mpirun -np 4 ./jacobi1d_mpi 15 1e-3 100000 --source`
debe dar exactamente lo mismo (también con 3 procesos).

**Opción B · Otra condición de frontera.** Izquierda 0, derecha 50 (`T_LEFT`/`T_RIGHT` en ambos archivos). Predice primero el perfil
final y el efecto sobre el número de iteraciones con `n = 12, tol = 1e-3`; después verifica.

Listo cuando:
- [ ] `make` sin warnings; `make test` pasa (los casos originales no deben romperse: usa una bandera o una constante nueva, no cambies los valores por defecto).
- [ ] Agregaste un caso a `tests/run_tests.sh` para tu variante: ya hay una línea comentada `run_case "fuente n=15 p=4 ..." ... --source`; `run_case` pasa las banderas extra a los dos programas.
- [ ] Puedes explicar en voz alta qué línea garantiza que la fuente (o la frontera) no se "pierde" al intercambiar `u` y `u_new`.

## Para el reporte de tu bitácora (2 líneas)

Qué predicción falló (P1–P5), por qué, y cómo lo detectaste. Eso va a la bitácora de errores del equipo del proyecto.
