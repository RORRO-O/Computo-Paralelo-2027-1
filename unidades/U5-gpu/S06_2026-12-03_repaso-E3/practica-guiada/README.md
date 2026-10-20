> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S06 · jueves 3 de diciembre de 2026 · 10:30–12:00 · Salón 3208

# Práctica guiada S06 · Cazador de errores de Unidades IV–V (PRIMM)

Tres programas, **un** error cada uno, ninguno avisa. Los tres errores son los que más puntos cuestan en el
Examen 3: una colectiva MPI que no llaman todos (idea errónea 18), un *kernel* sin guardia de rango (34, 27) y una
reducción en árbol sin barrera (25, 7). El objetivo no es "arreglarlos" (cada corrección es una línea): es
**predecir el síntoma antes de correr, explicar por qué la plataforma no se queja y verificar la corrección con
una prueba que falla mientras el error siga ahí** (`make cazar`).

Trabajas en pareja: **conductor** (teclea) y **navegante** (lee, predice, anota). En clase se hacen Predecir,
Ejecutar e Investigar y se arranca Modificar (minutos 60–72); lo que falte de Modificar y todo Crear van en la
tarea. Un estudiante que faltó puede hacer la práctica completa en casa en 40 minutos sin GPU.

## Archivos

| Archivo | Qué es | Dónde corre |
|---|---|---|
| `caza1_bcast_buggy.c` | Media de un arreglo repartido con `MPI_Scatterv` + `MPI_Reduce`; la raíz "anuncia" `n` | Cualquier máquina con `mpicc`/`mpirun` (Colab también, instalando OpenMPI) |
| `caza2_guard_buggy.cu`, `caza2_guard_numba.py` | `y = 2·x + 1`, un hilo por elemento; el programa reserva `grid·block` elementos y pone centinelas `-1` en `y[n..cap)` para que se note si alguien escribe ahí | GPU (Colab/Kaggle) / CPU con `NUMBA_ENABLE_CUDASIM=1` |
| `caza3_reduce_buggy.cu`, `caza3_reduce_numba.py` | Suma con reducción en árbol en memoria compartida (S03); segunda etapa en el anfitrión | GPU / CUDASIM |
| `caza_cpu.c` | Referencia secuencial de los cuatro cálculos (`media`, `axpb`, `suma`, `grid`) con tiempo (mediana de 5) | `gcc` |
| `ejemplo_predict_mpi.c`, `ejemplo_grid.cu`, `ejemplo_grid_numba.py` | Código del `ejemplo-resuelto.md` (predecir salida MPI; cazar un error de anfitrión en CUDA) | `mpirun` / GPU / CUDASIM |
| `examen_items/` | Código de los ítems II.1, II.2, III.1, III.2 y IV.a de `../examen-practica-U4-U5.md` (con sus espejos Numba) | `mpirun` / GPU / CUDASIM |
| `soluciones/` | Los tres cazadores corregidos (`*_fixed.*`). **No los abras antes de terminar Modificar** | — |
| `notebook_colab.ipynb` | Todo en celdas: `!nvidia-smi`, `%%writefile`, `!nvcc`, ejecución, `make cazar` en Colab, medición, CSV, y los ítems del examen | Colab o Kaggle con GPU |
| `Makefile`, `tests/run_tests.sh` | `make test` (todo, sin GPU, ≈ 35 s), `make cazar` (tus tres archivos), `make run-mpi`, `make run-examen`, `make run` (GPU), `make notebook`, `make clean` | Laptop |

Valores de referencia (`./caza_cpu todo 1000`, salida real):

```
caza_cpu media: n=1000 media=3.497000 t_cpu_ms=0.0006 (mediana de 5)
caza_cpu axpb: n=1000 checksum=6994.0 t_cpu_ms=0.0008 (mediana de 5)
caza_cpu suma: n=1000 suma=5500.0 t_cpu_ms=0.0006 (mediana de 5)
caza_cpu grid: n=1000 checksum=1998.5 t_cpu_ms=0.0007 (mediana de 5)
```

Los datos son enteros pequeños (`i % 7`, `i % 10`): las sumas son exactas en `float` y los resultados deben
coincidir **exactamente** con la CPU. Si algo difiere, es un error de lógica, no de redondeo.

## Cómo ejecutar

**En la laptop (sin GPU).** Es suficiente para toda la práctica salvo las dos observaciones marcadas "solo GPU":

```bash
make                       # compila: .cu a objeto con nvcc -c, MPI con mpicc, referencia con gcc
make run-mpi               # caza1 con 4 procesos y timeout de 5 s (NP=1 para compararlo)
NUMBA_ENABLE_CUDASIM=1 python3 caza2_guard_numba.py 1000 256
NUMBA_ENABLE_CUDASIM=1 python3 caza3_reduce_numba.py 1000
make cazar                 # pasa solo cuando los tres errores están corregidos (en el .cu Y en su espejo Numba)
make test                  # el material completo, ≈ 35 s
```

Si `mpirun` se niega a correr como `root` (máquina virtual, Colab): `export OMPI_ALLOW_RUN_AS_ROOT=1
OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1`. El `Makefile` ya pasa `--oversubscribe` para que 4 procesos corran en 2 núcleos.

**En Colab (lo que proyecta el profesor).** Sube `notebook_colab.ipynb` → *Entorno de ejecución → Cambiar tipo de
entorno → GPU (T4)*; ejecuta en orden. Con una P100 de Kaggle cambia `-arch=sm_75` por `-arch=sm_60`. Cuando
corrijas un error, edita la celda `%%writefile`, vuelve a ejecutarla **y** vuelve a compilar.

---

## P · Predecir (en clase: hecho en el examen de práctica; en casa: 6 min, por escrito, sin ejecutar)

Lee los tres programas (el *kernel* o el bloque marcado "1." en `caza1`, y el `main` solo para saber qué
imprimen). Contesta antes de correr nada:

| # | Pregunta | Tu predicción | Observado |
|---|---|---|---|
| P1 | `timeout 5 mpirun -np 4 ./caza1_bcast_buggy 1000`: ¿termina? Si no, ¿qué código de salida deja `timeout`? ¿Qué proceso se queda esperando y en qué llamada? | | |
| P2 | El mismo programa con `-np 1`: ¿termina? ¿Qué media imprime? ¿Eso demuestra que está bien? | | |
| P3 | `caza2_guard_buggy 1000 256`: ¿cuántos hilos se lanzan? ¿Cuántos sobran? ¿Qué posiciones de `y` tocan los sobrantes? ¿Habrá error de CUDA? | | |
| P4 | `caza2_guard_buggy 1024 256`: ¿cambia algo? ¿`verificacion=OK` o `FALLA`? | | |
| P5 | `caza3_reduce_buggy 1000`: ¿`suma_gpu` será 5500.0? Si no, ¿mayor o menor? ¿Por qué? | | |
| P6 | Cinco corridas seguidas de `caza3_reduce_buggy 1000`: ¿saldrá el mismo número cada vez? | | |
| P7 | `caza3_reduce_buggy 1000 32` (un *warp* por bloque): ¿crees que "se arregle" en la GPU? ¿Y en CUDASIM? | | |
| P8 | ¿Cuál de los tres errores imprime un mensaje de error (de MPI o de CUDA)? | | |

<details><summary>Respuestas (ábrelas solo después de Ejecutar)</summary>

- **P1.** No termina; `timeout` lo mata con código **124**. Los rangos 1–3 esperan en `MPI_Recv` un mensaje que
  nadie envía (un `MPI_Bcast` no se empareja con `MPI_Recv`); la raíz sale del `Bcast` (mensaje pequeño, envío
  inmediato) y se queda esperando en `MPI_Scatterv` a procesos que nunca llegan.
- **P2.** Termina e imprime `media=3.497000`: con un solo proceso no hay nadie a quien esperar. No demuestra nada:
  la prueba que importa es con `p > 1` (ideas erróneas 18 y 7).
- **P3.** `grid = 4`, 1024 hilos, 24 sobrantes (`i = 1000…1023`); escriben `y[1000…1023]`, que aquí son los
  centinelas. Sin error de CUDA: esa memoria está reservada (`cap = 1024`).
- **P4.** Con `n = 1024` no sobra ningún hilo: `verificacion=OK`. El error sigue en el código; el tamaño lo enmascara.
- **P5.** Menor (en la práctica, mucho menor): los hilos leen `s[tid + stride]` antes de que su dueño termine de
  sumar el nivel anterior y se pierden sumandos. En CUDASIM, en la autoría, dio entre ≈ 5 % y ≈ 20 % del valor
  (de 272 a 946 en catorce corridas con bloque 256).
- **P6.** No: cambia en cada corrida (carrera). En la GPU a veces sale 5500.0.
- **P7.** En la GPU con bloques de 32 "suele" salir bien más seguido (los 32 hilos de un *warp* avanzan casi en
  bloque), pero no está garantizado desde Volta (planificación independiente de hilos): sigue siendo
  comportamiento indefinido. En CUDASIM sigue saliendo mal (los hilos son hilos de Python sin *lockstep*).
- **P8.** Ninguno. Los tres terminan "limpios" o se cuelgan sin mensaje. La única evidencia es comparar con la
  referencia y, para el cuelgue, el `timeout` (idea errónea 27).
</details>

## R · Ejecutar (4 min; el profesor proyecta, la pareja anota "Observado")

```bash
make && make run-mpi                                   # caza1
NUMBA_ENABLE_CUDASIM=1 python3 caza2_guard_numba.py 1000 256 ; echo "codigo: $?"
NUMBA_ENABLE_CUDASIM=1 python3 caza2_guard_numba.py 1024 256 ; echo "codigo: $?"
for i in 1 2 3; do NUMBA_ENABLE_CUDASIM=1 python3 caza3_reduce_numba.py 1000 | grep -E 'parciales|suma_gpu'; done
```

Salida real **sin GPU** (CUDASIM y MPI en la máquina de autoría, este mismo código):

```
$ timeout 5 mpirun --oversubscribe -np 4 ./caza1_bcast_buggy 1000 ; echo "codigo: $?"
codigo: 124
$ timeout 5 mpirun --oversubscribe -np 1 ./caza1_bcast_buggy 1000
caza1: n=1000 procesos=1 media=3.497000

$ NUMBA_ENABLE_CUDASIM=1 python3 caza2_guard_numba.py 1000 256
caza2: n=1000 block=256 grid=4 hilos_lanzados=1024 sobrantes=24 modo=CUDASIM
checksum=6994.0 elementos_incorrectos=0 centinelas_alterados=24 (de 24)
t_kernel_ms=219.8552 (mediana de 1, solo kernel)          <- tiempo del simulador: NO es una medición
verificacion=FALLA                                        <- código de salida 2
$ NUMBA_ENABLE_CUDASIM=1 python3 caza2_guard_numba.py 1024 256
caza2: n=1024 block=256 grid=4 hilos_lanzados=1024 sobrantes=0 modo=CUDASIM
checksum=7158.0 elementos_incorrectos=0 centinelas_alterados=0 (de 0)
t_kernel_ms=178.6199 (mediana de 1, solo kernel)
verificacion=OK                                           <- el mismo error, enmascarado por el tamaño

$ for i in 1 2 3; do NUMBA_ENABLE_CUDASIM=1 python3 caza3_reduce_numba.py 1000 | grep -E 'parciales|suma_gpu'; done
parciales_gpu=144.0,137.0,170.0,136.0
suma_gpu=587.0 suma_cpu=5500.0
parciales_gpu=451.0,87.0,81.0,166.0
suma_gpu=785.0 suma_cpu=5500.0
parciales_gpu=200.0,68.0,66.0,65.0
suma_gpu=399.0 suma_cpu=5500.0                            <- tus números serán otros: cambian en cada corrida
$ NUMBA_ENABLE_CUDASIM=1 python3 caza3_reduce_numba.py 1000 32
caza3: n=1000 block=32 grid=32 modo=CUDASIM
suma_gpu=2034.0 suma_cpu=5500.0
t_kernel_ms=1082.1603 (mediana de 1, solo kernel)
verificacion=FALLA
```

Salida **esperada en la GPU** (no ejecutada en el entorno de autoría; T4 de Colab; los tiempos son órdenes de
magnitud): `caza2_guard_buggy 1000 256` → mismas cuatro primeras líneas que CUDASIM más
`cudaGetLastError=no error cudaDeviceSynchronize=no error`, `t_kernel_ms≈0.003–0.01`, `verificacion=FALLA`;
`caza3_reduce_buggy 1000` → `suma_gpu` distinta en cada corrida y **a veces** `5500.0 … verificacion=OK`; con
bloque 32, `OK` más seguido. Lo que **sí** coincide exactamente entre CUDASIM y GPU: `grid`, `hilos_lanzados`,
`sobrantes`, `centinelas_alterados`, `checksum` de los `n` válidos y `suma_cpu`.

## I · Investigar (4 min en parejas; el resto en casa)

**I1 (caza1).** Marca en el código las llamadas que ejecuta **cada** rango, en orden:

| Rango | Llamada 1 | Llamada 2 | ¿Con quién se empareja la llamada 1? | ¿Dónde se queda? |
|---|---|---|---|---|
| 0 | `MPI_Bcast` | `MPI_Scatterv` | con los `Bcast` de 1–3, que no existen | |
| 1 | `MPI_Recv(…, 0, 0, …)` | — | | |
| 3 | | | | |

¿Por qué la raíz **sí** sale del `Bcast`? (pista: U4 S02, notas §4, mensaje chico, envío inmediato). ¿Qué pasaría si `n`
fuera un arreglo de 1 MiB en lugar de un `int`?

**I2 (caza2).** Con `n = 1000`, `block = 256`: llena la tabla para los hilos 231, 232 y 255 del bloque 3.
¿Cuál es el primer `i` que no debería escribir? En tu V3 no hay centinelas: ¿sobre qué memoria escribirían esos
hilos? ¿Qué dos cosas tienen que ir siempre juntas en el anfitrión y en el *kernel*?

**I3 (caza3).** Con `block = 8` y `s = {1,2,3,4,5,6,7,8}` a mano: escribe `s` después del nivel `stride = 4` si
todos los hilos van en orden (`s = {6,8,10,12,…}`). Ahora supón que el hilo 0 ya hizo el nivel `stride = 2` (leyó
`s[2]`) **antes** de que el hilo 2 terminara el nivel `stride = 4`. ¿Qué valor leyó el hilo 0? ¿La suma final
puede dar más que 36 o solo menos? ¿Por qué `parciales_gpu` cambia aunque el bloque sea el mismo?

**I4 (los tres).** ¿Qué prueba detecta cada error y cuál no? Marca ✓/✗:

| Prueba | caza1 | caza2 | caza3 |
|---|---|---|---|
| "Compiló sin *warnings*" | | | |
| "Corrió sin mensaje de error" | | | |
| `-np 1` / `n` múltiplo del bloque / una sola corrida | | | |
| Comparar contra la CPU con `p = 4` / `n = 1000` / 3 corridas | | | |

<details><summary>Respuestas de Investigar</summary>

- **I1.** Rango 1: `MPI_Recv(&n, 1, MPI_INT, 0, 0, …)`, se empareja con nada (una colectiva no genera mensajes
  punto a punto visibles), se queda ahí. Rango 3: igual. La raíz sale del `Bcast` porque Open MPI copia el `int` a
  un búfer interno (envío inmediato, U4 S02, notas §4) y no necesita que nadie "reciba"; con un mensaje de 1 MiB la raíz
  también se quedaría dentro del `Bcast`. En ambos casos: cuelgue, sin mensaje.
- **I2.** Hilo 231 → `i = 999`, escribe `y[999]` (válido). Hilo 232 → `i = 1000`: el primero que no debe escribir.
  Hilo 255 → `i = 1023`. Sin centinelas, `y[1000…1023]` es el siguiente arreglo de `cudaMalloc` o memoria fuera de
  tu reserva: a veces "nada visible", a veces `illegal memory access`, a veces un resultado ajeno corrompido. Van
  juntos: `grid = (n + block − 1) / block` **y** `if (i < n)`.
- **I3.** En orden: tras `stride = 4`, `s = {6, 8, 10, 12, 5, 6, 7, 8}`; tras `stride = 2`, `s[0] = 16, s[1] = 20`;
  tras `stride = 1`, `s[0] = 36`. Si el hilo 0 lee `s[2]` antes de que el hilo 2 sume, lee `3` en vez de `10` y
  `s[0]` acaba en 29 (o menos). Solo puede dar **menos**: cada carrera pierde sumandos, nunca los duplica. Cambia
  porque el orden de los hilos de Python (y de los *warps* en la GPU) cambia en cada corrida.
- **I4.** Las dos primeras filas: ✗ en los tres (ninguno avisa). Tercera fila: ✗ en los tres (cada una enmascara
  justo ese error: sin procesos que esperar; sin hilos sobrantes; una corrida afortunada). Cuarta fila: ✓ en los
  tres. Regla: la evidencia es una referencia independiente **en las condiciones que exponen el error**.
</details>

## M · Modificar (8 min en clase; el resto en casa)

Una línea por programa, **en el `.cu` y en su espejo `_numba.py`**. No cambies la salida ni los nombres: `make
cazar` compara contra los valores de referencia.

- **M1 · caza1.** Haz que `n` llegue a todos con **una** colectiva llamada por todos. Verificación:
  `make cazar` → `caza1 con 4 procesos termina y da media=3.497000` y `caza1 con 3 procesos y n=10007 … media=3.499400`.
- **M2 · caza2.** Impide que los hilos sobrantes toquen memoria. Verificación: `caza2_guard_numba.py 1000 256 …
  verificacion=OK` (centinelas intactos) y `37 8` (`sobrantes=3`, `OK`).
- **M3 · caza3.** Haz que ningún hilo lea el siguiente nivel del árbol antes de que todos terminaron el anterior.
  La barrera va **fuera** del `if`: una barrera dentro de una rama que no todos toman también es incorrecta
  (idea errónea 32). Verificación: `suma_gpu=5500.0` dos veces seguidas con bloque 256 y una con 64.

Criterio de "listo": `make cazar` imprime `bichos cazados: 3/3` y termina con código 0. Salida real con las tres
correcciones aplicadas (es la que obtienes al copiar `soluciones/` encima, cosa que no debes hacer antes):

```
== make cazar: tus tres archivos (sin GPU: MPI con timeout, CUDA en CUDASIM)
PASS  caza1_bcast_buggy.c compila sin warnings
PASS  caza1 con 4 procesos termina y da media=3.497000
PASS  caza1 con 3 procesos y n=10007 (residuo) da media=3.499400
PASS  caza2_guard_numba.py 1000 256 en CUDASIM: verificacion=OK
PASS  caza2_guard_numba.py 37 8 en CUDASIM: verificacion=OK
PASS  caza3_reduce_numba.py 1000 256 en CUDASIM: verificacion=OK
PASS  caza3_reduce_numba.py 1000 256 en CUDASIM: verificacion=OK
PASS  caza3_reduce_numba.py 1000 64 en CUDASIM: verificacion=OK
PASS  caza2_guard_buggy.cu: el kernel axpb tiene guardia de rango (igual que el espejo)
PASS  caza3_reduce_buggy.cu: el kernel block_sum tiene barrera en el ciclo del árbol (igual que el espejo)
PASS  caza2_guard_buggy.cu y caza3_reduce_buggy.cu compilan con nvcc -c
---- bichos cazados: 3/3   (11 PASS, 0 FAIL, 0 SKIP)
```

Y mientras no corrijas nada (salida real del material tal como se entrega): `bichos cazados: 0/3 (2 PASS, 9 FAIL)`,
con la pista `sigue interbloqueado: ¿quién llama a MPI_Bcast?` en `caza1`. Si corriges solo el espejo Numba, la
revisión del `.cu` falla con `¿corregiste solo el espejo Numba?` y ese bicho no cuenta.

Después de corregir, escribe en el comentario de cabecera de cada archivo **la regla general**, no el cambio:
"todas las colectivas las llaman todos los procesos del comunicador", "`grid = ceil(n/block)` y guardia van juntos",
"una barrera entre cada nivel del árbol, fuera de cualquier `if`".

## C · Crear (tarea, ejercicio 1c; 10 min con `caza2` como plantilla)

Escribe tu propio cazador: `caza4_<tema>_buggy.cu` **y** `caza4_<tema>_numba.py` (≤ 60 líneas cada uno), con
**uno** de estos errores de la Unidad V que no tienen cazador en esta carpeta:

| Tema | El error | Síntoma esperado |
|---|---|---|
| `tiempo` | Medir el *kernel* con `perf_counter`/`omp_get_wtime` sin sincronizar (idea 33) | Tiempo de microsegundos; *speedup* imposible |
| `copias` | `cudaMemcpy` H2D/D2H **dentro** del ciclo de iteraciones (idea 24) | Resultado correcto; `t_total` 10–100× el `t_kernel` |
| `return` | `return` antes de `__syncthreads()` para los hilos de borde en un *kernel* con memoria compartida (S02) | Cuelgue o basura en el último bloque; a veces `OK` |
| `igualdad` | Verificar `float` con `==` contra la CPU (idea 10) | `FALLA` con resultado correcto |

Requisitos: ficha sellada en el encabezado (`<details>`: qué error, dónde, cómo se detecta), referencia CPU en el
mismo archivo, `verificacion=OK|FALLA` en la salida. Tu pareja lo caza y escribe la corrección. Criterio de "listo":
el espejo Numba reproduce el síntoma en CUDASIM **o** el encabezado explica por qué no puede (como en
`examen_items/item_III2_hist_numba.py`: una carrera que el simulador no intercala); corregido, `verificacion=OK`; la
ficha coincide con lo que la pareja encontró.

## Antes de cerrar

- [ ] La tabla de Predecir tiene las ocho predicciones **y** lo observado; cada diferencia tiene una línea en tu
  bitácora de errores.
- [ ] `make cazar` dice cuántos bichos llevas (en clase basta 1/3; 3/3 antes del lunes 7 de diciembre, 10:30).
- [ ] Puedes decir en voz alta, para cada cazador, qué prueba lo expone y cuál lo enmascara (tabla I4).

**Para saber más.** CUDA C Programming Guide: "Thread Hierarchy", "Shared Memory" y "Error Checking"; CUDA C
Best Practices Guide: "Timing" y "Data Transfer Between Host and Device"; Numba CUDA: "Debugging CUDA Python with
the simulator" y "Synchronization and atomic operations"; Kirk y Hwu, *Programming Massively Parallel Processors*,
4.ª ed., cap. 3 (organización de hilos) y cap. 10 (reducción). Para MPI: estándar MPI 4.1, capítulo "Collective
Communication" (qué procesos deben llamar y con qué argumentos).
