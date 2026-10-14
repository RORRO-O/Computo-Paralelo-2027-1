> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S02 · lunes 9 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S02 · Práctica guiada PRIMM: anillo, *ping-pong* e intercambio cruzado

Trabajo en parejas. **Conductor** (teclado) y **navegante** (lee, predice, anota). Se cambian los roles a
los 15 minutos, cuando el profesor lo anuncie. Regla de PRIMM: todo lo que predigas se escribe **antes** de
ejecutar; después se compara. Lo que no coincide es lo que vale la pena entender.

## 0. Qué hay en esta carpeta

| Archivo | Qué es | Fase |
|---|---|---|
| `status_demo.c` | Ejemplo resuelto: `MPI_ANY_SOURCE`, `MPI_ANY_TAG`, `MPI_Status`, `MPI_Get_count` | Ejecutar, Investigar |
| `ring_token.c` | Anillo: el token sale del rango 0, cada rango le suma su número, regresa al 0 | Predecir, Investigar |
| `ping_pong.c` | Mide latencia y ancho de banda entre dos procesos (protocolo del curso) | Predecir, Investigar |
| `cross_exchange_buggy.c` | Intercambio cruzado **inseguro**: termina con mensajes chicos, se cuelga con grandes | Predecir, Investigar |
| `cross_exchange_fixed.c` | Dos correcciones: orden por paridad y `Isend`/`Irecv`/`Wait` (adelanto de S04) | Investigar |
| `cross_exchange_sendrecv.c` | `TODO(1)`: la tercera corrección, con `MPI_Sendrecv` | **Modificar** |
| `ring_neighbors.c` | `TODO(2)`, `TODO(3)`: intercambio con los dos vecinos del anillo | **Crear** |
| `Makefile`, `tests/run_tests.sh` | `make`, `make run`, `make test`, `make clean` | — |

### Compilar y correr

```bash
make                 # compila los 7 programas con mpicc -std=c11 -O2 -Wall -Wextra
make test            # pruebas automáticas: PASS / FAIL / SKIP por caso
mpirun -np 5 ./ring_token        # cualquier programa se corre así
make clean
```

- Si `mpirun` dice *not enough slots*, agrega `--oversubscribe` (el `Makefile` ya lo hace con `MPIRUN_FLAGS`).
  Con MPICH ese *flag* no existe: `make MPIRUN_FLAGS="" test`.
- Si ejecutas como root (contenedor), exporta `OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1`.
  `tests/run_tests.sh` lo hace solo.
- Un programa colgado se mata con `Ctrl+C`. Para no tener que vigilarlo:
  `timeout 10 mpirun -np 2 ./cross_exchange_buggy 1000000; echo "codigo $?"` (124 = lo mató `timeout`).

---

## 1. Predecir (minutos 35–40) · escribe antes de ejecutar

Copia esta tabla en tu cuaderno (o en un archivo `predicciones.md`) y llena la columna "predicción".

| # | Comando | Pregunta | Predicción | Observado | ¿Coincide? |
|---|---|---|---|---|---|
| P1a | `mpirun -np 5 ./ring_token` | ¿Qué valor imprime el rango 0 como `token final`? | | | |
| P1b | ídem | ¿Cuántas líneas se imprimen en total? | | | |
| P1c | ídem | El rango 0 pone `token = -1` justo después de su `MPI_Send`. ¿El rango 1 recibe 0 o −1? | | | |
| P2 | `mpirun -np 5 ./ring_token 100` y `mpirun -np 8 ./ring_token` | `token final` en cada caso | | | |
| P3a | `mpirun -np 2 ./cross_exchange_buggy 10` | ¿Termina? Justifica en una línea con lo que **promete** `MPI_Send` | | | |
| P3b | `mpirun -np 2 ./cross_exchange_buggy 1000000` | ¿Termina? Misma justificación | | | |
| P4a | `mpirun -np 4 ./status_demo` | ¿En qué orden aparecen las fuentes (1, 2, 3)? ¿Será el mismo si lo corres dos veces? | | | |
| P4b | ídem | ¿Qué devuelve `MPI_Get_count` para el mensaje del rango 3? (Capacidad del búfer: 64) | | | |
| P5a | `mpirun -np 2 ./ping_pong` | ¿Cuántas veces más tarda la ida de 1 MiB que la de 8 bytes? Elige: ×10, ×100, ×1 000, ×10 000 | | | |
| P5b | ídem | ¿La latencia de un mensaje de **0 bytes** será 0? Si no, ¿de qué orden: ns, µs, ms? | | | |

En una máquina de 4 núcleos, `-np 5` y `-np 8` necesitan `mpirun --oversubscribe -np 5 ...` (si no, *not
enough slots*). Los valores no cambian; solo se reparten los procesos entre los núcleos.

---

## 2. Ejecutar (minutos 40–48)

Corre los comandos de la tabla en ese orden y llena "Observado" y "¿Coincide?". Salidas de referencia
(corridas reales en la máquina de autoría: 4 núcleos, Open MPI 4.1.6; en la tuya cambian los tiempos y el
orden de las líneas, no los valores):

```
$ mpirun -np 5 ./ring_token
rango 0: envie 0 al rango 1; mi copia local ahora vale -1
rango 1: recibi 0 del rango 0, sume 1 y envie 1 al rango 2
rango 2: recibi 1 del rango 1, sume 2 y envie 3 al rango 3
rango 3: recibi 3 del rango 2, sume 3 y envie 6 al rango 4
rango 4: recibi 6 del rango 3, sume 4 y envie 10 al rango 0
rango 0: recibi 10 del rango 4 -> token final = 10
```

```
$ mpirun -np 2 ./cross_exchange_buggy 10
rango 0: intercambio correcto con rango 1 (n=10, recibidos=10)
rango 1: intercambio correcto con rango 0 (n=10, recibidos=10)
$ timeout 10 mpirun -np 2 ./cross_exchange_buggy 1000000; echo "codigo $?"
codigo 124
```

```
$ mpirun -np 4 ./status_demo
rango 0: mensaje 1 de 3 -> fuente=3 etiqueta=30 elementos=5 (capacidad=64) primero=300 ultimo=304
rango 0: mensaje 2 de 3 -> fuente=2 etiqueta=20 elementos=4 (capacidad=64) primero=200 ultimo=203
rango 0: mensaje 3 de 3 -> fuente=1 etiqueta=10 elementos=3 (capacidad=64) primero=100 ultimo=102
```

El orden de llegada en `status_demo` **no es determinista**: en esta corrida llegó primero el rango 3; en
otra, el 1. Lo mismo pasa con las líneas de `ring_token` con 8 procesos: los mensajes sí viajan en orden
(cada rango espera al anterior), pero `mpirun` mezcla lo que cada proceso imprime.

```
$ mpirun -np 2 ./ping_pong
# ping-pong entre rango 0 y rango 1, repeticiones=5 (mediana), 1 calentamiento
#      bytes   viajes rtt_mediana_us   rtt_min_us   rtt_max_us  latencia_us ancho_banda_MB_s
           0     5000           0.39         0.38         0.41         0.19              0.0
           8     5000           0.41         0.40         2.07         0.21             38.8
          64     5000           2.20         0.52         3.00         1.10             58.3
         512     2000           3.02         0.93         5.09         1.51            338.7
        4096     1000          12.19         8.23        33.10         6.09            672.1
       32768      300          25.04        11.81        88.99        12.52           2617.3
      262144       40          59.05        54.41       160.90        29.53           8878.5
     1048576       40         921.11       555.09      2677.01       460.56           2276.8
     4194304       10        1746.65      1033.87      3292.51       873.32           4802.7
```

`rtt` = ida y vuelta; `latencia` = rtt/2; ancho de banda = 2·bytes/rtt. En cuatro corridas en la misma
máquina la latencia de 0 bytes estuvo entre 0.19 y 0.48 µs y el ancho de banda a 4 MiB entre 1.0 y
4.8 GB/s: la máquina de autoría es una VM compartida y el ruido es grande. Por eso el protocolo pide
mediana de 5 y reportar mín/máx. Entre dos máquinas conectadas por red, la latencia sube uno o dos órdenes
de magnitud (decenas de µs en Ethernet) y el ancho de banda baja.

---

## 3. Investigar (minutos 48–58)

Orden sugerido: **I1 → I2 (tabla y E1) → I4**. I3 se contesta con la salida que ya está impresa abajo
(correrlo es opcional). E2 solo si sobra tiempo: si nadie lo corrió, el profesor lo muestra en la puesta en
común.

### I1. ¿Dónde está el umbral del cuelgue?

Busca el `n` (número de enteros) a partir del cual `cross_exchange_buggy` deja de terminar. Usa `timeout 5`;
la tabla completa se llena con un solo ciclo (124 = se colgó):

```bash
for n in 500 1000 1010 1015 1020 2000; do
    timeout 5 mpirun -np 2 ./cross_exchange_buggy $n > /dev/null; echo "n=$n codigo=$?"
done
```

| n | bytes (= 4·n) | ¿Terminó? |
|---|---|---|
| 500 | 2 000 | |
| 1 000 | 4 000 | |
| 1 010 | 4 040 | |
| 1 015 | 4 060 | |
| 1 020 | 4 080 | |
| 2 000 | 8 000 | |

Luego pregunta a tu Open MPI cuál es su límite *eager* para memoria compartida:

```bash
ompi_info --param btl vader --level 4 | grep eager_limit
```

En la máquina de autoría: `btl_vader_eager_limit` = **4096** bytes (incluye encabezado), y el programa
terminó con n = 1 010 (4 040 bytes) y se colgó con n = 1 015 (4 060 bytes).

- ¿Por qué el umbral queda unos bytes **debajo** de 4 096?
- ¿Es el mismo umbral entre dos máquinas en red? (Pista: `ompi_info --param btl tcp --level 4 | grep eager_limit`.)
- Escribe en una línea: ¿por qué un programa cuya corrección depende de este número está mal aunque hoy
  funcione?

### I2. Rastreo del anillo y dos experimentos

Llena la tabla para `mpirun -np 5 ./ring_token 100` **sin** volver a correrlo:

| rango | recibe de | valor recibido | suma | envía a | valor enviado |
|---|---|---|---|---|---|
| 0 | — (inicia) | — | 0 | 1 | |
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |
| 4 | | | | | |
| 0 (al final) | | | | — | — |

Ahora dos experimentos sobre `ring_token.c` (haz una copia antes: `cp ring_token.c ring_token_exp.c` y
compila con `mpicc -std=c11 -O2 -Wall -Wextra -o ring_token_exp ring_token_exp.c`):

- **E1.** Haz que el rango 0 también reciba primero y envíe después (igual que los demás). Predice: ¿termina?
  ¿Depende del tamaño del token? Corre con `timeout 5`. Explica quién espera a quién.
- **E2.** Haz que **todos** envíen primero (`token + rank`) y reciban después. Predice el `token final` con
  `-np 5`. Corre. Resultado real en la máquina de autoría: termina (el mensaje es de 4 bytes, hubo copia) y
  el rango 0 imprime `token final = 4`, no 10. ¿Por qué 4? ¿Cuál de los dos errores (E1 o E2) es más
  peligroso en un programa real y por qué?

### I3. Capacidad del búfer y `MPI_Get_count`

En `status_demo.c`, cambia la cuenta de `MPI_Recv` de `CAPACITY` a `4` (deja `CAPACITY` en 64) y corre con
`-np 4`. Salida real (recortada: Open MPI antepone `[nodo:pid]` a cada línea de error):

```
rango 0: mensaje 1 de 3 -> fuente=2 etiqueta=20 elementos=4 (capacidad=64) primero=200 ultimo=203
rango 0: mensaje 2 de 3 -> fuente=1 etiqueta=10 elementos=3 (capacidad=64) primero=100 ultimo=102
*** An error occurred in MPI_Recv
*** MPI_ERR_TRUNCATE: message truncated
*** MPI_ERRORS_ARE_FATAL (processes in this communicator will now abort,
```

- ¿Por qué los mensajes de 3 y 4 elementos sí pasaron y el de 5 abortó el programa?
- En la versión original, ¿`MPI_Get_count` devuelve la capacidad (64) o lo que llegó? ¿Para qué sirve
  entonces el argumento `count` de `MPI_Recv`?
- Restaura el archivo (`git checkout status_demo.c` o vuelve a poner `CAPACITY`).

### I4. El modelo de costo con tus números

Con **tu** tabla del *ping-pong*:

1. α (latencia) ≈ latencia de 0 bytes. β (ancho de banda) ≈ el de 4 MiB. Anótalos.
2. Modelo: `T(m) = α + m / β`. Predice `T(32 768)` y compáralo con la fila medida. ¿Qué tan lejos quedó?
3. Localiza el salto entre 512 y 4 096 bytes (en la máquina de autoría el rtt pasa de 3.0 µs a 12.2 µs).
   Relaciónalo con el umbral de I1: ¿qué cambió en el protocolo de Open MPI ahí?
4. ¿Cuántos mensajes de 8 bytes cuestan lo mismo que **uno** de 1 MiB? (Divide las latencias de ida.)

---

## 4. Modificar (minutos 58–65)

### M1. `cross_exchange_sendrecv.c` → `TODO(1)`

1. Abre el archivo. Localiza la zona marcada `>>> reemplaza estas dos llamadas por MPI_Sendrecv <<<`.
2. Sustituye `MPI_Send` + `MPI_Recv` por **una** llamada a `MPI_Sendrecv`. Los argumentos salen de las dos
   llamadas que quitas: primero los seis del envío (búfer, cuenta, tipo, destino, etiqueta), luego los del
   recibo (búfer, cuenta, tipo, fuente, etiqueta), luego el comunicador y el `status`.
3. Cambia `todo_pending = 1` por `0`.
4. Verifica:

```bash
make
mpirun -np 2 ./cross_exchange_sendrecv 1000000     # debe terminar con "intercambio correcto" x2
make test                                          # el caso cross_exchange_sendrecv debe pasar a PASS
```

Criterio de "listo": `PASS cross_exchange_sendrecv -np 2 n=1000000` y también funciona con `-np 4`.

### M2. (si terminaste) Etiquetas que no casan

En tu `MPI_Sendrecv`, cambia **solo** la etiqueta de recepción a `TAG_DATA + 1`. Predice qué pasa con
`n = 10`. Corre con `timeout 5`. (Resultado real: se cuelga; código 124.) ¿Por qué no importa que el
mensaje sea pequeño? ¿Qué tres cosas tienen que coincidir para que una recepción acepte un mensaje?
Restaura la etiqueta.

### M3. (si terminaste) Mide el intercambio

Rodea tu `MPI_Sendrecv` con `MPI_Wtime()` e imprime el tiempo en el rango 0 para `n = 1 000 000`
(4 MB por dirección). Compáralo con la fila de 4 MiB del *ping-pong*. ¿Es parecido a una ida, a una ida y
vuelta, o a ninguna? ¿Por qué?

---

## 5. Crear (minutos 75–85)

### `ring_neighbors.c` → `TODO(2)` y `TODO(3)`

Cada rango tiene `send_buf` (n enteros, todos iguales a su rango). Debe enviarlo a sus dos vecinos del anillo
y recibir el de cada uno: lo del izquierdo en `from_left`, lo del derecho en `from_right`. La verificación ya
está escrita; no la toques.

Restricciones:

- Debe terminar con `n = 1 000 000` y con `-np 2`, `3`, `4` y `5`. Sin cuelgues.
- Solo `MPI_Send`, `MPI_Recv`, `MPI_Sendrecv` (las colectivas son mañana). Sin búferes extra.

Pistas, de más general a más concreta (usa la que necesites):

1. Son dos "corrimientos" independientes del anillo: uno hacia la derecha y otro hacia la izquierda.
2. En un corrimiento, **cada** rango envía a un lado y recibe del otro. Eso es exactamente lo que hace una
   sola llamada que ya conoces.
3. Usa una etiqueta distinta por dirección (`TAG_RIGHT`, `TAG_LEFT`): con `-np 2` el vecino izquierdo y el
   derecho son el mismo proceso.

Criterio de "listo":

```bash
make test      # PASS en ring_neighbors -np 2, -np 4 y -np 5
```

Extensión (si terminas antes): escribe la versión con orden por paridad en lugar de `MPI_Sendrecv`. Hay dos
maneras de organizarla y **no** se comportan igual; predice qué pasa con cada una con `-np 5` y
`n = 1 000 000` **antes** de correrla:

- **Por corrimientos:** en cada dirección, los pares hacen `Send` → `Recv` y los impares `Recv` → `Send`.
- **Por parejas:** los pares envían y reciben todo con su vecino **derecho** mientras los impares reciben y
  envían con su **izquierdo**; después cada quien hace lo mismo con el otro vecino.

Pista: ¿de qué paridad son el rango 4 y el rango 0? ¿En cuál de las dos organizaciones se envían primero el
uno al otro **al mismo tiempo**? Resultado real en la máquina de autoría: por corrimientos termina con
`-np 2`, `3`, `4` y `5`; por parejas termina con `-np 2` y `4`, se cuelga con `-np 3` y `5` (código 124) y
con `n = 10` termina en todos los casos. Explica las tres observaciones y por qué `MPI_Sendrecv` no necesita
este análisis.

---

## 6. Antes de irte

- [ ] Tabla de predicciones llena, con la columna "¿Coincide?".
- [ ] Umbral de I1 anotado (tu `n` y tu `eager_limit`).
- [ ] `make test` con `PASS` en `cross_exchange_sendrecv`.
- [ ] Una frase propia que empiece con "Un programa MPI es correcto solo si…".

## Errores frecuentes en esta práctica

| Síntoma | Primera pregunta que hacerte |
|---|---|
| Se queda colgado sin mensaje de error | ¿En qué llamada está **cada** proceso? ¿Quién espera a quién? |
| `MPI_ERR_TRUNCATE` | ¿La cuenta de `MPI_Recv` es mayor o igual que lo que mandó el emisor? |
| Recibe ceros o basura | ¿Pasaste el arreglo (`buf`) o su dirección (`&buf`)? ¿Cuenta en elementos, no en bytes? |
| `MPI_Sendrecv` se cuelga con n chico | ¿Coinciden etiqueta, fuente/destino y comunicador entre los dos lados? |
| Con `-np 5` se cuelga y con `-np 4` no | ¿Tu orden por paridad deja a dos pares vecinos (4 y 0) enviándose primero el uno al otro al mismo tiempo? (Pasa con el intercambio por parejas, no con el de corrimientos.) |
| `token final` incorrecto pero sin cuelgue | ¿Enviaste antes de recibir el valor acumulado? |
