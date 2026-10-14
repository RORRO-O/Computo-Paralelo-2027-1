> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S01 · jueves 5 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# Práctica guiada S01 · Hola con rangos y suma distribuida (PRIMM)

En parejas: **conductor** (teclado) y **navegante** (lee esto, escribe las predicciones, vigila). Cambio de
roles a los 15 minutos. Las predicciones se escriben **antes** de ejecutar: el valor de la actividad está en
comparar lo que creías con lo que pasó. Esta carpeta es autocontenida: solo necesitas `mpicc`, `mpirun` y `make`.

## Archivos

| Archivo | Qué es |
|---|---|
| `hello_rank.c` | Un "Hola" por proceso, una variable global `counter`, ramas por rango |
| `suma_distribuida.c` | Suma de `n` elementos repartidos por bloques (completo) o cíclico (`TODO(1)`, lo completas tú) |
| `suma_distribuida_buggy.c` | Variante que falla: reparte `n/p` y olvida el residuo |
| `referencia_secuencial.c` | Suma, promedio y máximo en un solo proceso; contra esto se compara todo |
| `Makefile` | `make`, `make run`, `make test`, `make clean`. Variables: `NP=4`, `N=10`, `MPIRUN_FLAGS=--oversubscribe` |
| `tests/run_tests.sh` | Verificación automática; termina con código 0 solo si no hay `FAIL` |

## 0. Preparación (2 min)

```bash
cd practica-guiada
make            # compila con mpicc -std=c11 -O2 -Wall -Wextra; no debe salir ningún warning
make test       # esperado al inicio: 15 PASS, 0 FAIL, 2 SKIP (los SKIP son lo que completas hoy)
```

Problemas de entorno frecuentes:

- `mpicc: command not found` → Ubuntu/Debian/WSL: `sudo apt install openmpi-bin libopenmpi-dev`; macOS: `brew install open-mpi`.
- `There are not enough slots available` → pediste más procesos que núcleos. El `Makefile` ya pasa
  `--oversubscribe`; en la terminal escríbelo tú: `mpirun --oversubscribe -np 6 ./hello_rank`.
- Open MPI se niega a correr como root (contenedores): `export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1`.
- `mpi.h: No such file or directory` (o `undefined reference to MPI_Init`) → compilaste con `gcc`; usa `mpicc` (o simplemente `make`).

## 1. Predecir (7 min, por escrito, sin ejecutar nada)

Lee `hello_rank.c` completo y responde:

| # | Pregunta | Tu predicción |
|---|---|---|
| P1 | Con `mpirun -np 4 ./hello_rank`, ¿cuántas líneas se imprimen en total? ¿Y con `-np 1`? | |
| P2 | ¿Las líneas "Hola desde el proceso…" salen siempre en el orden 0, 1, 2, 3? ¿Por qué? | |
| P3 | ¿Qué número imprime la línea `[rango 3] counter = ___`? (`counter` es global y todos los rangos le suman) | |
| P4 | ¿Los cuatro `pid` son iguales o distintos? ¿Qué te dice eso sobre procesos frente a hilos? | |

Lee `suma_distribuida.c` (`element`, `block_range` y `main`) y responde:

| # | Pregunta | Tu predicción |
|---|---|---|
| P5 | `n = 10`, `-np 4`, reparto por bloques: ¿qué índices toma el rango 2? ¿Y el rango 0? | |
| P6 | `n = 10`, `-np 4`, reparto cíclico: ¿qué índices toma el rango 2? | |
| P7 | Al terminar el programa, ¿cuánto vale la variable `total` en el rango 2? ¿Y en el rango 0? | |
| P8 | ¿Cuántos mensajes se envían en total con `-np 4`? ¿Quién envía y quién recibe? | |

## 2. Ejecutar (5 min)

```bash
mpirun -np 4 ./hello_rank
mpirun -np 4 ./hello_rank            # otra vez: compara el orden con la corrida anterior
mpirun -np 1 ./hello_rank
mpirun -np 4 ./suma_distribuida 10 bloques
./referencia_secuencial 10
```

Marca cada predicción con ✓ o ✗ y, si fallaste, escribe lo que pasó. Para referencia, dos corridas reales
seguidas en la máquina de autoría (los `pid` y el orden cambian en cada corrida y en cada máquina):

```
$ mpirun -np 4 ./hello_rank                         $ mpirun -np 4 ./hello_rank
Hola desde el proceso 0 de 4 (pid 23276, nodo vm)   Hola desde el proceso 3 de 4 (pid 23295, nodo vm)
Hola desde el proceso 1 de 4 (pid 23277, nodo vm)   [rango 3] counter = 4
[rango 1] counter = 2                               [rango 3] soy el ultimo rango; tambien puedo ...
Hola desde el proceso 2 de 4 (pid 23278, nodo vm)   Hola desde el proceso 0 de 4 (pid 23292, nodo vm)
[rango 2] counter = 3                               [rango 0] counter = 1
Hola desde el proceso 3 de 4 (pid 23282, nodo vm)   [rango 0] soy el rango 0; nada me obliga a ser ...
[rango 0] counter = 1                               Hola desde el proceso 1 de 4 (pid 23293, nodo vm)
[rango 0] soy el rango 0; nada me obliga a ser ...  [rango 1] counter = 2
[rango 3] counter = 4                               Hola desde el proceso 2 de 4 (pid 23294, nodo vm)
[rango 3] soy el ultimo rango; tambien puedo ...    [rango 2] counter = 3
```

```
$ mpirun -np 4 ./suma_distribuida 10 bloques
[rango 0] bloques: 3 elementos {0, 1, 2}, suma parcial = 179.600
[rango 1] bloques: 3 elementos {3, 4, 5}, suma parcial = 206.700
[rango 2] bloques: 2 elementos {6, 7}, suma parcial = 97.300
[rango 3] bloques: 2 elementos {8, 9}, suma parcial = 64.900
suma total = 548.500 (n = 10, p = 4, reparto = bloques)
tiempo = 0.004264 s
```

## 3. Investigar (10 min)

**I1.** Corre `mpirun -np 4 ./hello_rank` tres veces más. ¿En cuántas cambió el orden? Escribe en una frase
quién decide ese orden. ¿Serviría poner `MPI_Barrier` antes del `printf` para ordenarlo? ¿Por qué no?

**I2.** Corre con `-np 2` y con `--oversubscribe -np 6`. Llena la tabla y escribe la fórmula del total en
función de `p`.

| `-np` | Líneas "Hola" | Líneas "counter" | Líneas del rango 0 | Líneas del último rango | Total |
|---|---|---|---|---|---|
| 1 | | | | | |
| 2 | | | | | |
| 4 | | | | | |
| 6 | | | | | |

**I3.** Tabla de rastreo de `block_range` (a mano, sin correr). Después verifica con `mpirun -np 3 ./suma_distribuida 10`.

| `n` | `size` | `rank` | `q = n/size` | `r = n%size` | `count` | `start` | `end` |
|---|---|---|---|---|---|---|---|
| 10 | 4 | 0 | | | | | |
| 10 | 4 | 1 | | | | | |
| 10 | 4 | 2 | | | | | |
| 10 | 4 | 3 | | | | | |
| 10 | 3 | 0 | | | | | |
| 10 | 3 | 1 | | | | | |
| 10 | 3 | 2 | | | | | |

**I4.** En `suma_distribuida.c`, justo después de `double t_end = MPI_Wtime();`, agrega
`printf("[rango %d] total = %.3f\n", rank, total);`. Recompila con `make` y corre con `-np 4`. ¿Qué imprimen los
rangos 1, 2 y 3? ¿Por qué no 548.500, si "ya se sumó todo"? Compara con tu P7. (Puedes dejar la línea: las
pruebas la ignoran.)

**I5.** Corre `mpirun -np 4 ./suma_distribuida_buggy 10` y `mpirun --oversubscribe -np 5 ./suma_distribuida_buggy 10`.
¿Cuál da 548.500? Localiza la línea del error en el `.c`. ¿Por qué "con 5 salió bien" no demuestra que el
programa esté bien? ¿Qué `n` usarías para atrapar este error con **cualquier** `p`? (Mira qué `n` usa `tests/run_tests.sh`.)

**I6.** Medir (una corrida de cada una; el protocolo completo con 5 repeticiones es parte de la tarea):

```bash
./referencia_secuencial 1000000000
mpirun -np 1 ./suma_distribuida 1000000000
mpirun -np 2 ./suma_distribuida 1000000000
mpirun -np 4 ./suma_distribuida 1000000000
mpirun -np 4 ./suma_distribuida 10
```

| Configuración | Tiempo (s) | `S = T_seq / T_p` | `E = S / p` |
|---|---|---|---|
| secuencial, `n = 10⁹` | | — | — |
| `-np 1`, `n = 10⁹` | | | |
| `-np 2`, `n = 10⁹` | | | |
| `-np 4`, `n = 10⁹` | | | |
| `-np 4`, `n = 10` | | ¿tiene sentido calcularlo? | |

Para comparar, medianas de 5 repeticiones (con calentamiento) en la máquina de autoría: una máquina virtual de
4 núcleos **compartida con otros procesos** (carga del sistema entre 5 y 7 durante la medición, es decir, el
protocolo se violó en su regla 1.5 "cierra lo demás"):

| Configuración (`n = 10⁹`) | Mediana (s) | Mín (s) | Máx (s) | `S` | `E` |
|---|---|---|---|---|---|
| `referencia_secuencial` | 1.473 | 1.373 | 1.623 | — | — |
| `suma_distribuida -np 1` | 1.464 | 1.359 | 1.583 | 1.01 | 1.01 |
| `suma_distribuida -np 2` | 0.755 | 0.728 | 0.888 | 1.95 | 0.98 |
| `suma_distribuida -np 4` | 0.723 | 0.663 | 0.740 | 2.04 | 0.51 |

Con 2 procesos escala casi perfecto; con 4 no, porque los otros dos núcleos estaban ocupados por procesos
ajenos. Tu laptop sin carga debería dar `S(4)` mucho mayor. Anota tu número y guárdalo: en la tarea calculas
qué dice Karp–Flatt de ambos casos.

## 4. Modificar (8 min) · `TODO(1)`: reparto cíclico

En `suma_distribuida.c`, rama `else` del reparto (busca `TODO(1)`). El rango `rank` debe sumar los elementos
`rank, rank + size, rank + 2·size, …` mientras el índice sea menor que `n`, actualizando `local_sum`,
`local_count`, `first`, `last` y `step`. Borra las tres líneas de `TODO pendiente` al terminar.

Criterio de "listo":

```bash
make && mpirun -np 4 ./suma_distribuida 10 ciclico
#   esperado: [rango 2] ciclico: 2 elementos {2, 6}, suma parcial = 137.800   (y suma total = 548.500)
make test
#   esperado: 24 PASS, 0 FAIL, 1 SKIP  (los 9 PASS nuevos comparan tu reparto cíclico con la secuencial,
#   con n = 10 y n = 1 000 003 y 1 a 4 procesos)
```

Compara con tu P6. Si tu primera versión usó `i += rank`, explica qué hace el rango 0 con ese paso.

**M2 (si terminas antes).** Haz que combine el **último** rango (`size − 1`) en lugar del 0: cambia el destino
del `MPI_Send`, la condición del `if` y el rango que recorre el ciclo de `MPI_Recv` (`src` de `0` a `size − 2`).
`make test` debe seguir pasando (lee la línea `suma total` sin importar quién la imprime). ¿Qué tuviste que
cambiar y qué no? Eso es todo lo "especial" que tiene el rango 0.

## 5. Crear (10 min) · `promedio_maximo.c`

Escribe `promedio_maximo.c` en esta carpeta (el `Makefile` lo detecta y lo compila con `make`). Especificación:

- **Entrada:** `n` como primer argumento (por defecto 10). Mismos elementos que los demás programas: copia `element(i)`.
- **Trabajo:** cada proceso calcula **solo** sus elementos (reparto por bloques con residuo), y de ellos la suma
  parcial y el máximo parcial. Ningún proceso recorre los `n` elementos.
- **Comunicación:** un solo mensaje por proceso que no combina (pista: `double stats[2]` enviado con `count = 2`).
- **Salida** del rango que combina, exactamente en este formato (`%.3f`):

  ```
  promedio = 54.850
  maximo = 93.200
  ```

- **Casos límite:** debe funcionar con 1 a 4 procesos, con `n` no múltiplo de `p` y con `n < p` (un rango sin
  elementos no debe "ganar" el máximo: inicia su máximo parcial en un valor menor que cualquier elemento, por
  ejemplo `-1.0`, o no lo tomes en cuenta).

Criterio de "listo": `make test` muestra **8 líneas `PASS` de `promedio_maximo`** (n = 10 y n = 1 000 003,
con 1, 2, 3 y 4 procesos) y **0 FAIL**. Con TODO(1) y este programa, el total es 32 PASS.

Extensiones (sin puntos, con reconocimiento): (a) que el máximo lo combine el último rango y el promedio el
rango 0, en el mismo programa; (b) versión con reparto cíclico; (c) protocolo completo de medición con
`n = 10⁹` y Karp–Flatt para `p = 2, 3, 4`.

## Qué te llevas

- Tu hoja de predicciones con ✓/✗: guárdala, el pre-laboratorio de la Práctica 5 pide el mismo razonamiento.
- `TODO(1)` resuelto y, de ser posible, `promedio_maximo.c` pasando `make test`. Si no lo terminaste, termínalo
  antes del martes 10 de noviembre: el Lab 1 de la Práctica 5 da por hecho que sabes escribirlo.
