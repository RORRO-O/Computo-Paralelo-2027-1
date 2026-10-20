> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Guía de estudio del Examen 3 · martes 8 de diciembre de 2026 · 08:30–10:00 · Salón 3208 (o Lab LS4 con los equipos apagados)

# Guía de estudio · Examen departamental 3 (Unidades IV–V: MPI y GPU)

Esta guía es pública y no contiene ítems del examen. Te dice qué entra y cuánto pesa cada tema, te da 30
preguntas para practicar recuperación (con respuesta escondida), un plan de 5 días, los errores que más cuestan
puntos, lo que no entra, cómo será el día del examen y la hoja de calibración. Índice de la unidad:
[`README.md`](README.md).

| | |
|---|---|
| Fecha y lugar | **martes 8 de diciembre de 2026, 08:30–10:00**, Salón 3208 o Lab LS4 con los equipos apagados, filas alternas (el aula se confirma el lunes 7 de diciembre en la sesión C1) |
| Duración y puntaje | **80 minutos efectivos · 100 puntos · 16 ítems en seis secciones** |
| Versiones | A y B, alternadas por fila; mismo temario, misma dificultad, mismos tipos de ítem |
| Material permitido | Pluma o lápiz. **Nada más**: sin apuntes, sin IA y sin dispositivos (celular, **calculadora**, computadora y reloj inteligente apagados y en la mochila). **No hay hoja de fórmulas**: las de *speedup*, eficiencia, Amdahl, índice global, número de bloques y ocupación se escriben de memoria ([S06 notas §4](S06_2026-12-03_repaso-E3/notas-estudiante.md)); los modelos propios de cada problema (costo de un mensaje, copias por PCIe, Karp–Flatt) y los datos de la GPU vienen en su enunciado |
| Alcance | Unidad IV (5–19 de noviembre, Práctica 5) y Unidad V (23 de noviembre – 3 de diciembre, Práctica 6). Entre 10 % y 20 % de unidades previas, **dentro** de problemas de las Unidades IV–V |
| Peso | 30 % del 3.er parcial ([`planeacion/mapa-evaluacion.md`](../../planeacion/mapa-evaluacion.md)) |
| Devolución | Calificación y clave en ≤ 7 días ([`docs/metodo/04-evaluacion.md`](../../docs/metodo/04-evaluacion.md) §2.3); la retroalimentación en clase está prevista en la reserva del **lunes 14 de diciembre** |

## 1. Temario con peso orientativo

Los pesos salen de la tabla de especificaciones del examen, que el profesor escribió antes que los ítems
(`docs/metodo/04-evaluacion.md` §2.1). Son puntos de 100. Úsalos para repartir tu tiempo, no para dejar temas
fuera: un tema de 4 puntos mal estudiado es un 4 que regalas.

| # | Tema (sesiones) | Peso | Debes poder… | Dónde repasar | Banco (§3) |
|---|---|---|---|---|---|
| 1 | Memoria distribuida, SPMD y colectivas (U4 S01, S03) | **11** | Decir qué tiene cada rango antes y después de cada llamada; elegir la colectiva; repartir `n` no múltiplo de `p` | [U4 S01 notas](../U4-memoria-distribuida/S01_2026-11-05_modelo-spmd/notas-estudiante.md) · [U4 S03 notas](../U4-memoria-distribuida/S03_2026-11-10_colectivas-lab1/notas-estudiante.md) | 1–3 |
| 2 | Punto a punto: semántica de bloqueo, interbloqueo, no bloqueantes (U4 S02, S04) | **12** | Decir qué promete `MPI_Send`, predecir cuándo un intercambio se cuelga y corregirlo de tres formas | [U4 S02 notas](../U4-memoria-distribuida/S02_2026-11-09_punto-a-punto/notas-estudiante.md) · [U4 S04 notas](../U4-memoria-distribuida/S04_2026-11-12_descomposicion-halos/notas-estudiante.md) | 4–6 |
| 3 | Descomposición de dominio y halos (U4 S04) | **4** | Llenar celdas fantasma con `MPI_PROC_NULL` en las orillas; paro global con `Allreduce` | [U4 S04 notas](../U4-memoria-distribuida/S04_2026-11-12_descomposicion-halos/notas-estudiante.md) | 7–8 |
| 4 | Modelo de costo `α + m/β`; escalabilidad fuerte y débil (U4 S05) | **8** | Calcular el costo de un mensaje, el `n*` a partir del cual conviene repartir y distinguir fuerte de débil | [U4 S05 notas](../U4-memoria-distribuida/S05_2026-11-17_rendimiento-lab2/notas-estudiante.md) | 9–11 |
| 5 | SIMT y modelo CUDA: hilos, bloques, malla, índice global, guardia (S01, S05) | **11** | Calcular bloques con redondeo hacia arriba, índice global, hilos ociosos e índice 2D aplanado; escribir la guardia | [S01 notas](S01_2026-11-23_H2-modelo-cuda/notas-estudiante.md) §2–3 · [S05 notas](S05_2026-12-01_lab2-taller-V3/notas-estudiante.md) §2 | 12–14 |
| 6 | Jerarquía de memoria, coalescencia, *tiling* con compartida y `__syncthreads` (S02) | **7** | Elegir memoria; decidir si un acceso es coalescido; contar lecturas globales y explicar cada barrera | [S02 notas](S02_2026-11-24_memoria-tiling-lab1/notas-estudiante.md) | 15–17 |
| 7 | Atómicas, reducción y divergencia (S03) | **11** | Rastrear un árbol; contar atómicas, niveles y *warps* divergidos; elegir la versión; ver el error que no avisa | [S03 notas](S03_2026-11-26_sincronizacion-reduccion/notas-estudiante.md) | 18–21 |
| 8 | Medición: eventos, transferencias, bloque y ocupación, *memory-bound* vs. *compute-bound* (S04) | **12** | Calcular `S` con y sin copias, detectar un tiempo imposible, ocupación de un bloque e intensidad aritmética | [S04 notas](S04_2026-11-30_rendimiento-gpu/notas-estudiante.md) | 22–24 |
| 9 | Diseño: elegir plataforma con números (U4–U5, proyecto) | **8** | Elegir MPI, OpenMP o GPU con dos datos numéricos y descartar una alternativa con un número | [S05 notas](S05_2026-12-01_lab2-taller-V3/notas-estudiante.md) §1–4 · [S06 notas](S06_2026-12-03_repaso-E3/notas-estudiante.md) §5 | 25–26 |
| 10 | Unidad III integrada: *speedup*, eficiencia, Amdahl, Karp–Flatt; carreras y su corrección | **16** | Calcular a mano con dos decimales; nombrar la carrera y la corrección más barata que sea correcta | [U3 S10 notas](../U3-memoria-compartida/S10_2026-10-22_rendimiento/notas-estudiante.md) §1–2 · [U3 S07 notas](../U3-memoria-compartida/S07_2026-10-15_sincronizacion/notas-estudiante.md) §1–3 · [S06 notas](S06_2026-12-03_repaso-E3/notas-estudiante.md) §4 | 27–30 |
| | **Total** | **100** | | | |

Por unidad: 35 puntos de la Unidad IV (temas 1–4), 41 de la Unidad V (temas 5–8), 8 de diseño integrador y 16 de la
Unidad III, que van **dentro** de problemas de MPI y GPU, no en una sección aparte. Por nivel cognitivo: 30 puntos de
recordar/comprender, 50 de aplicar/analizar y 20 de evaluar/crear.

**Estructura** (la misma del [examen de práctica](S06_2026-12-03_repaso-E3/examen-practica-U4-U5.md) de S06; el tiempo
sugerido viene impreso en la portada):

| Sección | Tipo de ítem | Ítems | Puntos | Minutos sugeridos |
|---|---|---|---|---|
| I | Opción múltiple (una sola correcta; no hay puntos parciales) | 6 | 18 | 10 |
| II | Predecir la salida (un programa MPI corto y un *kernel* CUDA corto) | 2 | 17 | 12 |
| III | Encontrar y corregir el error (uno MPI, uno CUDA) | 2 | 15 | 12 |
| IV | Completar código | 2 | 12 | 8 |
| V | Problemas numéricos | 2 | 22 | 15 |
| VI | Diseño breve (10 líneas como máximo por ítem) | 2 | 16 | 13 |
| — | Revisión final | — | — | 10 |
| | **Total** | **16** | **100** | **80** |

## 2. Cómo usar esta guía

- **Recupera, no releas.** Contesta cada pregunta **por escrito y sin apuntes** antes de abrir su respuesta.
  Releer se siente mejor y rinde menos (`docs/metodo/01-marco-pedagogico.md`, P2).
- **Espacia y mezcla.** El plan de §4 reparte las 30 preguntas en cinco días, mezcla MPI y GPU en cada sesión y
  regresa a las que fallaste uno y dos días después. Mezclar obliga a **elegir** la herramienta, que es lo que pide
  el examen.
- **Marca cada respuesta** con ✓ (completa), ~ (parcial) o ✗. Las ~ y ✗ vuelven al día siguiente.
- **Zona sin IA para contestar.** Puedes pedirle a un asistente que te genere preguntas nuevas del mismo tipo (uso
  verde, [`docs/metodo/05-politica-ia.md`](../../docs/metodo/05-politica-ia.md)), pero contéstalas tú y verifica su
  clave compilando y ejecutando: la IA también se equivoca al predecir la salida de un programa paralelo.

**Supuestos del código** (los de la portada del examen): C11; los programas MPI se compilan con `mpicc -std=c11
-O2` y corren en **una** máquina con Open MPI; los *kernels* se compilan con `nvcc -O2 -arch=sm_75` y la GPU es una
Tesla T4 de Colab. Las cuentas están pensadas para hacerse a mano: redondea a dos o tres cifras (se acepta ±5 %) y
escribe siempre la cuenta y las unidades. Los fragmentos de **esta guía** omiten `#include`, `main`,
`MPI_Init`/`MPI_Finalize` y la obtención de `rank` y `size`.

**Cómo se verificó el banco.** Cada fragmento marcado **[código]** se compiló sin *warnings* y se ejecutó para fijar
la respuesta: MPI con `mpicc -std=c11 -O2 -Wall -Wextra` y Open MPI 4.1.6 (`mpirun --oversubscribe` con el número de
procesos indicado, varias corridas); OpenMP con gcc 13.3 `-O2 -fopenmp` con 1 y 4 hilos, cinco corridas; CUDA con
`nvcc -c -O2 -arch=sm_75` (`nvcc` 12.0) y ejecutado con su espejo en Numba bajo `NUMBA_ENABLE_CUDASIM=1`, como en las
prácticas guiadas, en una máquina virtual de 4 núcleos sin GPU. La salida obtenida está en la clave. Si quieres
comprobarlo tú, envuelve el fragmento en un `main` **después** de contestar.

## 3. Banco de 30 preguntas de recuperación

Las 9 marcadas **[código]** traen el fragmento y piden predecir la salida o encontrar el error.

### A · Memoria distribuida, SPMD y colectivas (tema 1)

**1. [código · predecir]** Se ejecuta con `mpirun -np 3`. Escribe la línea que imprime cada rango. ¿Está garantizado
el orden de las líneas?

```c
int visitas = 0;                        /* variable global, fuera de main */
/* … en main, después de obtener rank y size: */
visitas++;
int x = 10 * rank;
if (rank == 2) x = 99;
MPI_Bcast(&x, 1, MPI_INT, 2, MPI_COMM_WORLD);
int y = x + rank;
int s = 0;
MPI_Allreduce(&y, &s, 1, MPI_INT, MPI_SUM, MPI_COMM_WORLD);
printf("rango %d: visitas=%d x=%d y=%d s=%d\n", rank, visitas, x, y, s);
```

<details><summary>Respuesta 1</summary>

Salida real (ordenada por rango; el orden entre procesos **no** está garantizado):

```
rango 0: visitas=1 x=99 y=99 s=300
rango 1: visitas=1 x=99 y=100 s=300
rango 2: visitas=1 x=99 y=101 s=300
```

`visitas=1` en los tres: cada proceso tiene su **propia** copia de la variable global (idea errónea 16). La raíz del
`Bcast` es el rango 2: cualquier rango puede serlo (19), y los tres llaman a `MPI_Bcast` (18). Después del `Bcast`,
`y = 99 + rank`; `Allreduce` deja la suma `99 + 100 + 101 = 300` en **todos**. Repasa: U4 S01 notas; U4 S03 notas.
</details>

**2. [elección]** ¿Qué colectiva usas en cada caso? Pregúntate "¿quién tiene el dato antes y quién lo necesita
después?". Una línea por caso.

- (a) La raíz leyó `n` de un archivo y todos lo necesitan.
- (b) La raíz tiene 4 000 `double` y cada uno de 4 procesos debe procesar 1 000 distintos.
- (c) Cada proceso tiene su suma parcial y **todos** necesitan el total para normalizar su trozo.
- (d) Cada proceso tiene su trozo del resultado y solo el rango 0 escribe el archivo.
- (e) Cada proceso sabe cuántos elementos le tocan y todos necesitan la lista completa para calcular desplazamientos.

<details><summary>Respuesta 2</summary>

(a) `MPI_Bcast`. (b) `MPI_Scatter` (`MPI_Scatterv` si `n` no es múltiplo de `p`). (c) `MPI_Allreduce` con `MPI_SUM`;
`Reduce` + `Bcast` también funciona, pero son dos llamadas donde basta una. (d) `MPI_Gather` (o `Gatherv`) a la raíz 0.
(e) `MPI_Allgather`. En los cinco casos llaman **todos** los procesos del comunicador (idea 18). Repasa: U4 S03 notas.
</details>

**3. [código · encontrar el error]** Con `mpirun -np 2` imprime `media=5.50`, que es correcto. Con `-np 4` imprime
otra cosa sin ningún error de MPI. ¿Qué imprime con 4 procesos y con 3, por qué, y cómo lo corriges?

```c
int n = 10;                                   /* x = {1, 2, …, 10}: la media es 5.5 */
double *x = NULL;
if (rank == 0) {
    x = malloc(n * sizeof(double));
    for (int i = 0; i < n; i++) x[i] = i + 1;
}
int local_n = n / size;
double *xl = malloc(local_n * sizeof(double));
MPI_Scatter(x, local_n, MPI_DOUBLE, xl, local_n, MPI_DOUBLE, 0, MPI_COMM_WORLD);
double s = 0.0;
for (int i = 0; i < local_n; i++) s += xl[i];
double total = 0.0;
MPI_Reduce(&s, &total, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
if (rank == 0) printf("media=%.2f\n", total / n);
```

<details><summary>Respuesta 3</summary>

Salidas reales: `-np 4` → `media=3.60`; `-np 3` → `media=4.50`; `-np 2` y `-np 5` → `media=5.50`. Con 4 procesos
`local_n = 10/4 = 2`: se reparten 8 elementos y `x[8]`, `x[9]` nunca salen de la raíz (suma 36 en vez de 55). Con 3,
se reparten 9 (suma 45). "Funciona con 2" no prueba nada: solo es un caso en que `p` divide a `n` (es la variante
"`n/p` reparte todo el arreglo" de U4 S01). Corrección: reparto por bloques con residuo y `MPI_Scatterv`:
`counts[r] = n/size + (r < n % size ? 1 : 0)`, `displs[r]` = suma de los `counts` anteriores, `local_n = counts[rank]`.
Así da `media=5.50` con 2, 3, 4 y 5 procesos (verificado). Repasa: U4 S01 notas (reparto con residuo); U4 S03 notas.
</details>

### B · Punto a punto: semántica de bloqueo e interbloqueo (tema 2)

**4. [código · predecir]** Anillo con `mpirun -np 4` en una sola máquina con Open MPI. ¿Termina con `n = 10`? ¿Y con
`n = 1 000 000`? Si termina, ¿qué imprime cada rango?

```c
int n = atoi(argv[1]);                         /* double por mensaje */
double *out = malloc(n * sizeof(double)), *in = malloc(n * sizeof(double));
for (int i = 0; i < n; i++) out[i] = rank;
int right = (rank + 1) % size, left = (rank - 1 + size) % size;
MPI_Send(out, n, MPI_DOUBLE, right, 0, MPI_COMM_WORLD);
MPI_Recv(in, n, MPI_DOUBLE, left, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
printf("rango %d recibio %.0f\n", rank, in[0]);
```

<details><summary>Respuesta 4</summary>

Con `n = 10` (80 bytes) **termina**; cada rango imprime el número de su vecino izquierdo: `rango 0 recibio 3`, `rango 1
recibio 0`, `rango 2 recibio 1`, `rango 3 recibio 2`, en cualquier orden (salida real; también terminó con `n = 500`,
4 000 bytes). Con `n = 1 000 000` (8 MB) **se cuelga**: `timeout 10` lo mató con código 124. Los cuatro están en
`MPI_Send` esperando un `MPI_Recv` que nadie llega a hacer. Con mensajes chicos Open MPI copia el mensaje a un búfer
interno y `Send` regresa (protocolo *eager*); con grandes espera al receptor. Las dos conductas son válidas, así que
el programa es **incorrecto en los dos casos** (idea 17). Corrección: `MPI_Sendrecv(out, n, MPI_DOUBLE, right, 0, in,
n, MPI_DOUBLE, left, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE)` (verificado: termina con `n = 1 000 000`), o el orden por
paridad, o `Isend`/`Irecv` + `Waitall`. Repasa: U4 S02 notas.
</details>

**5. [recuperación]** (a) Completa: "`MPI_Send` regresa cuando ______". (b) Da tres formas de hacer seguro un
intercambio entre dos procesos que se mandan datos mutuamente. (c) ¿Qué quiere decir que un programa MPI es "seguro"?

<details><summary>Respuesta 5</summary>

(a) …cuando **tu búfer de envío se puede reutilizar**; no dice nada de si el otro proceso ya recibió. (b) `MPI_Sendrecv`;
orden por paridad (los pares envían y luego reciben, los impares al revés); `MPI_Isend` + `MPI_Irecv` + `MPI_Waitall`.
(c) Que termina aunque **todos** sus `MPI_Send` esperen al receptor: no depende del búfer interno (idea 17). Repasa:
U4 S02 notas.
</details>

**6. [recuperación]** El rango 0 recibe con `MPI_Recv(buf, 100, MPI_DOUBLE, MPI_ANY_SOURCE, MPI_ANY_TAG,
MPI_COMM_WORLD, &st)`. (a) ¿Cómo sabe quién envió y con qué etiqueta? (b) ¿Cómo sabe cuántos `double` llegaron?
(c) ¿Qué significa el `100`? (d) Si el emisor usa la etiqueta 7 y el receptor espera la 5 (sin `MPI_ANY_TAG`), ¿qué
pasa?

<details><summary>Respuesta 6</summary>

(a) `st.MPI_SOURCE` y `st.MPI_TAG`. (b) `MPI_Get_count(&st, MPI_DOUBLE, &cuenta)`. (c) La **capacidad** del búfer, en
elementos (no en bytes); si llega un mensaje más grande, es un error de truncamiento. (d) No se emparejan: el receptor
espera para siempre y no aparece ningún mensaje de error. Repasa: U4 S02 notas (tabla de argumentos).
</details>

### C · Descomposición de dominio y halos (tema 3)

**7. [código · predecir]** `mpirun -np 3`. Cada proceso tiene `u[0..3]`: `u[1]` y `u[2]` son sus celdas; `u[0]` y
`u[3]`, sus celdas fantasma. Escribe la línea de cada rango. ¿Qué imprime con `-np 1`?

```c
double u[4] = {-1.0, 10.0 * rank + 1, 10.0 * rank + 2, -1.0};
int left  = (rank > 0)        ? rank - 1 : MPI_PROC_NULL;
int right = (rank < size - 1) ? rank + 1 : MPI_PROC_NULL;
MPI_Sendrecv(&u[2], 1, MPI_DOUBLE, right, 0, &u[0], 1, MPI_DOUBLE, left, 0,
             MPI_COMM_WORLD, MPI_STATUS_IGNORE);
MPI_Sendrecv(&u[1], 1, MPI_DOUBLE, left, 1, &u[3], 1, MPI_DOUBLE, right, 1,
             MPI_COMM_WORLD, MPI_STATUS_IGNORE);
printf("rango %d: %.0f | %.0f %.0f | %.0f\n", rank, u[0], u[1], u[2], u[3]);
```

<details><summary>Respuesta 7</summary>

Salida real (ordenada por rango):

```
rango 0: -1 | 1 2 | 11
rango 1: 2 | 11 12 | 21
rango 2: 12 | 21 22 | -1
```

Con `-np 1`: `rango 0: -1 | 1 2 | -1`. El primer `Sendrecv` corre los datos a la derecha (mi última celda llena el
fantasma izquierdo del vecino); el segundo, a la izquierda. **Recibir de `MPI_PROC_NULL` no toca el búfer** (el `-1`
se queda: es la frontera física) y enviar a `MPI_PROC_NULL` no hace nada; por eso las orillas usan el mismo código.
`Sendrecv` no se interbloquea aunque los mensajes fueran grandes. Repasa: U4 S04 notas.
</details>

**8. [recuperación]** Jacobi 1D con 4 procesos: cada uno calcula `local_diff`, el cambio máximo de sus celdas en la
iteración. (a) Escribe la llamada que deja en **todos** el máximo global. (b) ¿Por qué no sirve `MPI_Reduce` a la raíz
0? (c) ¿Cuántos halos envía por iteración un proceso interior y cuántos uno de la orilla?

<details><summary>Respuesta 8</summary>

(a) `MPI_Allreduce(&local_diff, &global_diff, 1, MPI_DOUBLE, MPI_MAX, MPI_COMM_WORLD);`, llamada por todos en cada
iteración. (b) `Reduce` deja el máximo **solo en la raíz** (idea 16): los demás no pueden decidir cuándo parar; si la
raíz sale del ciclo y los demás no, se quedan esperando halos que nadie manda. (c) Interior: 2 envíos y 2
recepciones. Orilla: 1 real; el otro va a `MPI_PROC_NULL`, que no hace nada, con el mismo código. Repasa: U4 S04
notas.
</details>

### D · Modelo de costo y escalabilidad (tema 4)

**9. [numérico]** Con `α = 5 µs` y `β = 1 GB/s` (1 GB = 10⁹ bytes): (a) ¿cuánto cuesta un mensaje de 8 bytes y uno de
1 MB (10⁶ bytes)? (b) ¿Cuántos mensajes de 8 bytes cuestan lo mismo que uno de 1 MB? (c) Un programa manda 100 halos
de 8 bytes por iteración, uno por uno. ¿Cuánto ahorra por iteración si los junta en un mensaje de 800 bytes?

<details><summary>Respuesta 9</summary>

(a) `T = α + m/β`. 8 B: `5 µs + 0.008 µs ≈ 5.0 µs` (manda la latencia). 1 MB: `5 µs + 1 000 µs = 1 005 µs ≈ 1 ms`
(manda el ancho de banda). (b) `1 005 / 5.008 ≈ 200` mensajes. (c) Separados: `100 × 5.008 ≈ 501 µs`; juntos:
`5 + 0.8 = 5.8 µs`; ahorra ≈ 495 µs por iteración. Cada mensaje paga α (idea 21). Repasa: U4 S05 notas; S06 notas §4.
</details>

**10. [numérico]** Jacobi 1D: `T_1 = n·t_c` y `T_p = (n/p)·t_c + 2α`, con `t_c = 2 ns`, `α = 1 µs` y `p = 8`.
(a) ¿A partir de qué `n` conviene usar 8 procesos (`S > 1`)? (b) Calcula `S(8)` y la eficiencia para `n = 2 000` y para
`n = 10⁶`.

<details><summary>Respuesta 10</summary>

(a) `S > 1 ⇔ n·t_c·(1 − 1/p) > 2α ⇔ n > 2α / (t_c·(1 − 1/p)) = 2 000 ns / (2 ns × 0.875) ≈ 1 143`. (b) `n = 2 000`:
`T_1 = 4 µs`, `T_8 = 0.5 + 2 = 2.5 µs`, `S = 1.6`, `E = 1.6/8 = 20 %`. `n = 10⁶`: `T_1 = 2 000 µs`, `T_8 = 250 + 2 =
252 µs`, `S ≈ 7.94`, `E ≈ 99 %`. Con `n` chico la comunicación domina (ideas 1 y 21); con `n` grande, el cómputo.
Repasa: U4 S05 notas; S06 notas §4.
</details>

**11. [recuperación]** (a) Completa para escalabilidad **fuerte** y **débil**: qué se fija, qué crece con `p`, qué se
reporta y qué ley la describe. (b) ¿Por qué la fila de 8 procesos en una laptop de 4 núcleos va aparte y etiquetada?

<details><summary>Respuesta 11</summary>

(a) **Fuerte**: `n` fijo; crece `p`; se reportan `S = T(1)/T(p)` y `E = S/p`; Amdahl. **Débil**: `n/p` fijo; crecen `p`
y `n`; se reporta la eficiencia débil `E_w = T_seq(n/p) / T(p, n)` (ideal 1); Gustafson. No son sinónimos (idea 6).
(b) Es sobre-suscripción: dos procesos comparten núcleo y los tiempos salen altos y erráticos; sirve para probar
correctitud, no para medir (idea 20). Repasa: U4 S05 notas §3.
</details>

### E · Modelo CUDA: hilos, bloques, malla, índice y guardia (tema 5)

**12. [código · predecir]** El anfitrión pone en cero `d_out` (10 enteros), lanza `etiqueta<<<4, 3>>>(d_out, 10)`,
copia el arreglo de regreso e imprime `out[0..9]`. (a) ¿Qué imprime? (b) ¿Cuántos hilos se lanzan, cuántos no
escriben y cuáles son? (c) ¿Qué pasaría sin la guardia?

```c
__global__ void etiqueta(int *out, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) out[i] = 10 * blockIdx.x + threadIdx.x;
}
```

<details><summary>Respuesta 12</summary>

(a) `0 1 2 10 11 12 20 21 22 30` (salida real en el simulador). El orden lo pone el anfitrión al imprimir el arreglo;
los hilos no tienen orden entre sí. (b) `4 × 3 = 12` hilos; 2 no escriben: los hilos 1 y 2 del bloque 3 (`i = 10` y
`11`). (c) Escribirían `out[10]` y `out[11]`, fuera del arreglo. El simulador lo detecta (`IndexError … index 10 is out
of bounds`, real); en la GPU puede no pasar nada visible, corromper otro arreglo o dar `illegal memory access` (ideas
34 y 27). Repasa: S01 notas §3.
</details>

**13. [código · encontrar el error]** `n = 1000`, `block = 256`, `grid = (n + 255) / 256 = 4`, `a[i] = 1`, `b[i] = i` y
`c` en cero. `cudaGetLastError()` y `cudaDeviceSynchronize()` regresan `no error`, pero la verificación contra la CPU
falla. ¿Cuántos elementos están mal, cuáles, y cuál es la corrección?

```c
__global__ void suma(const float *a, const float *b, float *c, int n) {
    int i = threadIdx.x;
    if (i < n) c[i] = a[i] + b[i];
}
```

<details><summary>Respuesta 13</summary>

`threadIdx.x` es la posición **dentro del bloque**, no el índice global: los cuatro bloques calculan `c[0..255]` y
`c[256..999]` se quedan en 0. Salida real (espejo en el simulador): `grid=4 errores=744 c[255]=256 c[256]=0`. No hay
error de CUDA porque ningún acceso es ilegal: "sin error" no es "correcto" (idea 27). Corrección: `int i = blockIdx.x *
blockDim.x + threadIdx.x;` → `errores=0`. Repasa: S01 notas §3 y CT2.
</details>

**14. [numérico]** (a) `n = 3 000 000` y `block = 512`: bloques, hilos lanzados y ociosos. (b) Índice global del hilo
100 del bloque 5 000. (c) ¿Qué hace el hilo 400 del bloque 5 859? (d) Una malla de ancho 50 está aplanada por filas:
índice lineal de (fila 7, columna 12), y fila y columna de `idx = 1 234`.

<details><summary>Respuesta 14</summary>

(a) `⌈3 000 000 / 512⌉ = 5 860` bloques (`5 859 × 512 = 2 999 808` no alcanza); `5 860 × 512 = 3 000 320` hilos; 320
ociosos. (b) `5 000 × 512 + 100 = 2 560 100`. (c) `i = 5 859 × 512 + 400 = 3 000 208 ≥ n`: la guardia lo detiene y no
escribe (idea 34). (d) `7 × 50 + 12 = 362`; `1 234 / 50 = 24` (fila) y `1 234 % 50 = 34` (columna). Repasa: S01
notas §3; S05 notas §2; S06 notas §4.
</details>

### F · Jerarquía de memoria, coalescencia y mosaicos (tema 6)

**15. [recuperación]** ¿En qué memoria pones cada dato? (a) Un acumulador que usa un solo hilo. (b) El mosaico de 16 ×
16 que leen los 256 hilos de un bloque durante una fase. (c) La matriz de entrada que leen todos los bloques y que
copió el anfitrión. (d) Los 9 coeficientes de un filtro que **todos** los hilos leen en la misma dirección al mismo
tiempo. Ordena (a)–(c) de menor a mayor latencia.

<details><summary>Respuesta 15</summary>

(a) Registro (alcance: el hilo; ~1 ciclo). (b) Compartida, `__shared__` (alcance: el bloque; decenas de ciclos).
(c) Global, `cudaMalloc` + `cudaMemcpy` (alcance: toda la malla y el anfitrión; ~400–800 ciclos). (d) Constante,
`__constant__` (caché propia; rápida cuando todo el *warp* lee la misma dirección). Latencia: registro < compartida <
global; entre compartida y global hay uno o dos órdenes de magnitud (idea 23). Repasa: S02 notas §1.
</details>

**16. [recuperación]** `M` es una matriz de 2 048 × 2 048 `float` guardada por filas. Dentro de un *warp* solo cambia
`threadIdx.x` (0 a 31). Para cada lectura, ¿cuántos bytes separan a dos hilos consecutivos y es coalescida?
(a) `M[row * 2048 + threadIdx.x]` (b) `M[threadIdx.x * 2048 + col]` (c) `v[2 * threadIdx.x]`, con `v` de `float`.

<details><summary>Respuesta 16</summary>

(a) 4 bytes: 32 `float` contiguos, 128 bytes, una transacción: **coalescida**. (b) 8 192 bytes: cada hilo cae en un
segmento distinto; 32 segmentos de 32 bytes (1 024 bytes movidos para usar 128): **no coalescida**. (c) 8 bytes: el
*warp* abarca 256 bytes y usa la mitad: parcialmente coalescida, mueve el doble de bytes. Regla: `threadIdx.x` recorre
el índice que cambia más rápido en memoria. Repasa: S02 notas §2 y CT1.
</details>

**17. [numérico]** Multiplicación `n × n` con `n = 1 536` y `TILE = 16`. (a) ¿Cuántas veces se lee `A[3][5]` de memoria
global en la versión ingenua y en la de mosaicos? (b) Lecturas globales totales de cada versión y su cociente.
(c) Memoria compartida por bloque. (d) ¿Qué protege cada una de las dos `__syncthreads()` del ciclo de fases? (e) ¿Por
qué en la GPU la de mosaicos no resulta 16 veces más rápida?

<details><summary>Respuesta 17</summary>

(a) Ingenua: `n = 1 536` veces (una por hilo de la fila 3). Mosaicos: `n/TILE = 96` (una por bloque de la fila de
bloques). (b) Ingenua: `2n³ = 2 × 1 536³ ≈ 7.25 × 10⁹`; mosaicos: `2n² × (n/TILE) = 2 × 1 536² × 96 ≈ 4.53 × 10⁸`;
cociente `TILE = 16`. (c) `2 × 16 × 16 × 4 B = 2 KB` (`s_A` y `s_B`). (d) La primera: nadie multiplica antes de que
**todos** hayan cargado el mosaico. La segunda: nadie carga el mosaico siguiente mientras otros todavía leen el actual.
(e) Las cachés L1/L2 ya absorben parte de las lecturas repetidas de la ingenua, y la de mosaicos paga barreras y queda
más limitada por cómputo y ocupación: en una T4 se espera 2–4×. Repasa: S02 notas §3–§5 y CT2.
</details>

### G · Atómicas, reducción y divergencia (tema 7)

**18. [código · predecir]** Reducción en árbol con `BLOCK = 8`, `n = 10`, `x[i] = i + 1` y `grid = 2`. (a) Escribe
`s[0..3]` del bloque 0 después del nivel `stride = 4`, `s[0..1]` después de `stride = 2` y `s[0]` al final. (b) ¿Qué
valores quedan en `partial`? (c) ¿Cuántas `__syncthreads()` ejecuta cada hilo? (d) ¿Por qué la barrera va fuera del
`if`?

```c
__global__ void reduce_tree(const float *x, float *partial, int n) {
    __shared__ float s[BLOCK];
    int tid = threadIdx.x, i = blockIdx.x * blockDim.x + tid;
    s[tid] = (i < n) ? x[i] : 0.0f;
    __syncthreads();
    for (int stride = blockDim.x / 2; stride > 0; stride >>= 1) {
        if (tid < stride) s[tid] += s[tid + stride];
        __syncthreads();
    }
    if (tid == 0) partial[blockIdx.x] = s[0];
}
```

<details><summary>Respuesta 18</summary>

(a) Tras `stride = 4`: `6 8 10 12`; tras `stride = 2`: `16 20`; tras `stride = 1`: `36` (rastreo real en el
simulador). (b) `partial = {36, 19}`: el bloque 1 carga `9, 10` y seis ceros, porque los hilos con `i ≥ n` cargan el
neutro de la suma en lugar de hacer `return`. La etapa 2 suma `36 + 19 = 55`. (c) 4: una después de la carga y una
por nivel (`log₂ 8 = 3`). (d) Todos los hilos del bloque deben llegar a la **misma** barrera; dentro del `if`, los
`tid ≥ stride` nunca llegan: comportamiento indefinido o cuelgue (idea 32). Repasa: S03 notas §1 y §3.
</details>

**19. [código · encontrar el error]** El árbol del 18, ahora con memoria compartida de tamaño variable, se lanza así
con `n = 12`, `x[i] = 1` y `grid = (n + block − 1) / block = 2`. `cudaGetLastError()` regresa `no error` y el
anfitrión suma los parciales. ¿Qué suma da, qué fracción se pierde y por qué? ¿Qué pasa con `block = 8` y con
`block = 4`?

```c
__global__ void reduce_tree(const float *x, float *partial, int n) {
    extern __shared__ float s[];                      /* blockDim.x floats, se fija al lanzar */
    int tid = threadIdx.x, i = blockIdx.x * blockDim.x + tid;
    s[tid] = (i < n) ? x[i] : 0.0f;
    __syncthreads();
    for (int stride = blockDim.x / 2; stride > 0; stride >>= 1) {
        if (tid < stride) s[tid] += s[tid + stride];
        __syncthreads();
    }
    if (tid == 0) partial[blockIdx.x] = s[0];
}
/* anfitrión: */  reduce_tree<<<grid, 6, 6 * sizeof(float)>>>(d_x, d_partial, n);
```

<details><summary>Respuesta 19</summary>

Con `block = 6`: `stride = 3` suma `s[0]+=s[3]`, `s[1]+=s[4]`, `s[2]+=s[5]`; `stride = 1` suma `s[0]+=s[1]`; `s[2]`
nunca se agrega. Salida real (simulador): `partial = {4, 4} suma=8 referencia=12`: se pierde **un tercio**. Con
`block = 8` (`{8, 4}`) y `block = 4` (`{4, 4, 4}`) la suma es 12. El árbol supone `blockDim.x` potencia de 2; sin error
de CUDA y mal (idea 27). Corrección: usar potencias de 2 o un primer nivel que pliegue el bloque a la potencia de 2
inferior. Repasa: S03 notas §3 y §9; práctica guiada de S03, I4.
</details>

**20. [numérico]** Suma de `n = 2^22` `float` con bloques de 1 024 hilos. (a) Atómicas globales de `atomicAdd(out,
x[i])` por hilo. (b) Atómicas globales del árbol con `atomicAdd(out, s[0])` por bloque. (c) Atómicas y bytes copiados
con el árbol y segunda etapa en el anfitrión. (d) Niveles del árbol y sumas por bloque. (e) En el primer nivel,
¿cuántos *warps* trabajan y cuántos divergen con `if (tid % 2 == 0)` (paso creciente) y con `if (tid < 512)` (paso
decreciente)? (f) ¿Cuál de las tres versiones da siempre el mismo número?

<details><summary>Respuesta 20</summary>

(a) `4 194 304` atómicas sobre **una** dirección: se serializan (contención; idea 8b). (b) `2^22 / 1 024 = 4 096`
bloques → 4 096 atómicas. (c) 0 atómicas; se copian `4 096 × 4 B = 16 KB` al anfitrión (una copia chica que sí cuesta
decenas de µs: ≈ 0.03 ms en el CT3 de S03; idea 24). (d) `log₂ 1 024 = 10` niveles; 1 023 sumas por bloque. (e) El
bloque tiene 32 *warps*. Con `tid % 2 == 0`: los 32 trabajan con 16 carriles cada uno, todos divergidos. Con
`tid < 512`: 16 *warps* completos, 16 apagados, ninguno divergido. (f) La (c): el orden de las sumas es fijo. Las atómicas de `float` suman en el orden en
que llegan y cambian en los últimos dígitos; son correctas dentro de la tolerancia (idea 7e). Repasa: S03 notas §2–§4.
</details>

**21. [opción múltiple]** Jacobi 2D en GPU, 100 iteraciones, bloques de 16 × 16. Para no relanzar 100 veces, un
compañero mete el ciclo de iteraciones **dentro** del *kernel* con un `__syncthreads()` al final de cada iteración. ¿Qué
pasa?

- **A.** Funciona: la barrera espera a todos los hilos antes de pasar a la iteración siguiente.
- **B.** Es incorrecto: la barrera solo espera a los hilos de su bloque, y las celdas del borde de un mosaico las
  escribe otro bloque, que puede ir en otra iteración. Lo correcto es un lanzamiento por iteración (el fin del *kernel*
  sincroniza) con dos búferes que se intercambian.
- **C.** Funciona si la malla completa cabe a la vez en la GPU, porque entonces todos los bloques avanzan juntos.
- **D.** Funciona si al final de cada iteración el *kernel* llama a `cudaDeviceSynchronize()`.

<details><summary>Respuesta 21</summary>

**B.** A es la idea 25 ("`__syncthreads()` sincroniza toda la GPU"); C, la 25b ("simultáneo = sincronizado"); D, la
25c (`cudaDeviceSynchronize()` es una función del anfitrión: con `nvcc` 12 no compila dentro de un *kernel*). Entre
bloques solo sincroniza el fin del *kernel*; entre iteraciones se intercambian punteros, sin `cudaMemcpy`. Repasa: S03
notas §1 y CT1; S05 notas §2.
</details>

### H · Medición en GPU (tema 8)

**22. [numérico · encontrar el error]** En Numba, con los datos ya en la GPU y `n = 2^24`:

```python
t0 = time.perf_counter()
saxpy[grid, 256](a, d_x, d_y)          # y = a·x + y
t1 = time.perf_counter()
print((t1 - t0) * 1e3, "ms")           # en la segunda llamada imprime 0.05 ms
```

El equipo concluye "*speedup* de 360× contra los 18 ms de la CPU". (a) ¿Cuántos bytes mueve el *kernel* y qué ancho de
banda implicarían 0.05 ms? ¿Es posible en una T4 (≈ 320 GB/s)? (b) ¿Qué línea falta y dónde? (c) ¿Qué otras dos reglas
del protocolo faltan?

<details><summary>Respuesta 22</summary>

(a) Lee `x` y `y` y escribe `y`: `3 × 4 B × 2^24 ≈ 201 MB`; en 0.05 ms serían ≈ 4 TB/s, más de 12 veces el pico de la
T4: **físicamente imposible**. (b) `cuda.synchronize()` antes de `t1` (o eventos): el lanzamiento es asíncrono y se
midió el encolado (idea 33). (c) Calentamiento y mediana de 5 (la primera llamada incluye la compilación JIT y la
creación del contexto; idea 5), y reportar también el tiempo **con** copias, porque los 18 ms de la CPU incluyen
tener los datos donde se usan (idea 24). Repasa: S04 notas §1 y CT1.
</details>

**23. [numérico]** Medianas de 5 en una T4: H2D 40 ms, *kernel* 2.0 ms, D2H 20 ms. La referencia en CPU (`-O2`, mejor
secuencial) tarda 50 ms. (a) Calcula `S_kernel` y `S_total`. (b) ¿Qué fracción del tiempo en GPU son copias? (c) ¿Cuál
de los dos *speedups* se reporta? (d) ¿En qué situación esta GPU sí convendría sin cambiar el *kernel*?

<details><summary>Respuesta 23</summary>

(a) `S_kernel = 50 / 2 = 25×`; `S_total = 50 / (40 + 2 + 20) = 50 / 62 ≈ 0.81×`: la GPU **pierde**. (b) `60 / 62 ≈ 97 %`.
(c) Los dos, en la misma tabla (protocolo del curso); el que vive el usuario es el total (idea 24). (d) Si los datos
se quedan en la GPU para muchos *kernels* antes de volver a la CPU (las copias se pagan una vez) o se generan en la
propia GPU. Repasa: S04 notas §2–§3.
</details>

**24. [numérico]** (a) Un *kernel* evalúa `y[i] = ((a·x[i]) + b)·x[i] + c` en `float` (2 multiplicaciones y 2 sumas;
lee `x[i]` y escribe `y[i]`). Calcula su intensidad aritmética. En una T4 (≈ 8 TFLOP/s, 320 GB/s), ¿es *memory-bound* o
*compute-bound*, y cuántos GFLOP/s alcanza como máximo? (b) Una T4 admite hasta 16 bloques y 1 024 hilos residentes por
SM (32 *warps*). ¿Qué ocupación tiene un bloque de 32 hilos y uno de 128? ¿Por qué 1 024 no gana necesariamente?

<details><summary>Respuesta 24</summary>

(a) `I = 4 FLOP / 8 B = 0.5 FLOP/byte`. Balance de la T4: `8 000 / 320 = 25 FLOP/byte`. Como `0.5 < 25`, es
***memory-bound***: alcanza a lo más `0.5 × 320 = 160 GFLOP/s` (2 % del pico). Lo acelera mover menos bytes, no un
bloque más grande. (b) 32 hilos: 16 bloques × 1 *warp* = 16 de 32 → **50 %**. 128 hilos: el límite de 1 024 hilos deja
8 bloques × 4 *warps* = 32 de 32 → **100 %**. Con 1 024 la ocupación ya no sube, cabe un solo bloque por SM (cola final
peor balanceada), cada hilo queda limitado a 64 registros y con `n` chico hay menos bloques que SM (ideas 26 y 1): se
decide con el barrido. Repasa: S04 notas §4 y §6.
</details>

### I · Diseño: elegir plataforma con números (tema 9)

**25. [diseño breve]** Elige secuencial/OpenMP, MPI o GPU para cada caso y justifícalo con **un dato numérico** (3 líneas
como máximo por caso): (a) estimar π con 10¹⁰ puntos aleatorios, cada hilo genera los suyos y al final solo importa
un conteo; (b) sumar **una vez** 10⁶ `float` que ya están en la RAM de la laptop (4 MB); (c) una malla de 200 GB por paso
de tiempo durante 10 000 pasos.

<details><summary>Respuesta 25</summary>

Respuestas modelo (vale otra elección si el dato la justifica): (a) **GPU**: no hay datos de entrada (H2D ≈ 0) y
regresan 8 bytes; son 10¹⁰ operaciones independientes para millones de hilos, con reducción por bloque y una atómica
por bloque. (b) **CPU** (secuencial u OpenMP): copiar 4 MB a ≈ 5 GB/s cuesta ≈ 0.8 ms más ≈ 5–10 µs de lanzamiento,
más de lo que la CPU tarda en leerlos (≈ 0.2 ms a ≈ 20 GB/s); la GPU pierde (idea 24). (c) **MPI**: 200 GB no caben ni
en una máquina ni en los 16 GB de una T4; descomposición de dominio con halos en varios nodos. Criterio del examen:
la plataforma, **dos** datos numéricos del problema y una alternativa descartada con un número (S06 notas §5, punto 8).
</details>

**26. [diseño · ordenar]** Ordena los pasos para portar la V2 a GPU y di qué falla si se omite cada uno: (a) aplanar las
estructuras 2D a un arreglo 1D contiguo; (b) medir con eventos, dos tiempos, mediana de 5; (c) identificar con el
perfil de la V1 el ciclo que domina; (d) mover los datos una sola vez y alternar dos búferes entre iteraciones;
(e) comparar contra la V1 con tolerancia declarada; (f) un hilo por elemento, bloque múltiplo de 32, malla con
redondeo hacia arriba y guardia. ¿Cuenta como V3 una llamada a `cupy.matmul` sin *kernel* propio?

<details><summary>Respuesta 26</summary>

**c → a → f → d → e → b.** Sin (c) portas un ciclo que quizá es el 10 % del tiempo y Amdahl limita el total a
`1/0.9 ≈ 1.11`. Sin (a), un `float **` exige una copia por fila (una latencia de PCIe cada una). Sin (f) faltan celdas
o hay escrituras fuera del arreglo (idea 34). Sin (d) el PCIe domina (idea 24). Sin (e), "no dio error" pasa por
correcto (idea 27). Sin (b) salen *speedups* imposibles (ideas 5 y 33). `cupy.matmul` solo no es diseño paralelo
propio: la rúbrica de código deja C3 en "En desarrollo" como máximo; un `RawKernel` escrito por el equipo sí cuenta.
Repasa: S05 notas §2 y §4.
</details>

### J · Unidad III integrada: rendimiento y carreras (tema 10)

**27. [código · encontrar el error]** OpenMP con `n = 10 000 000` y `x[i] = 1.0`, compilado con `gcc -O2 -fopenmp`.
(a) ¿Qué imprime con `OMP_NUM_THREADS=1`? ¿Y con 4? (b) ¿Cuál es el error? (c) Corrígelo y di por qué `critical` sería
correcto, pero mala elección.

```c
double sum = 0.0;
#pragma omp parallel for
for (int i = 0; i < n; i++)
    sum += x[i];
printf("sum=%.0f\n", sum);
```

<details><summary>Respuesta 27</summary>

(a) Con 1 hilo, `sum=10000000`. Con 4, un número menor: en la autoría salió `sum=2500000` en cinco corridas seguidas
(con `-O2` cada hilo acumula en un registro y al final escribe; gana la última escritura). Compilado con `-O0` salió
distinto en cada corrida (`3561386`, `3033519`, `3033612`). (b) Condición de carrera sobre `sum`: leer-sumar-escribir
sobre una variable compartida sin protección. Que el número equivocado se repita **no** prueba que no haya carrera
(idea 7). (c) `#pragma omp parallel for reduction(+:sum)` → `sum=10000000` (real). `critical` serializa 10⁷
actualizaciones: correcto, pero más lento que el secuencial. En la GPU pasa lo mismo: una atómica por hilo sobre una
dirección serializa; privatizar y combinar una sola vez, no (idea 8b). Repasa: U3 S07 notas §1–3.
</details>

**28. [numérico]** Jacobi con MPI en una máquina de 8 núcleos físicos, `n` fijo. Mejor secuencial: 12.0 s. Con MPI:
`T(2) = 6.4 s`, `T(4) = 3.6 s`, `T(8) = 2.4 s`. (a) *Speedup* y eficiencia para cada `p`. (b) Karp–Flatt
`f = (1/S − 1/p) / (1 − 1/p)` para cada `p`. (c) ¿Qué dice la tendencia de `f`? (d) Un compañero toma `T(1)` de la
versión MPI con `mpirun -np 1` (12.6 s). ¿Qué está mal?

<details><summary>Respuesta 28</summary>

(a) `S = 1.88, 3.33, 5.00`; `E = 94 %, 83 %, 63 %` (eficiencia es `S/p`, no `S`: idea 3). (b) `f(2) = (0.533 − 0.5)/0.5
≈ 0.067`; `f(4) = (0.300 − 0.25)/0.75 ≈ 0.067`; `f(8) = (0.200 − 0.125)/0.875 ≈ 0.086`. (c) Hasta 4 procesos `f` es
constante (parte secuencial); con 8 crece: aparece una sobrecarga que aumenta con `p` (halos, `Allreduce`), por eso más
procesos no siempre rinden igual (idea 1). (d) `T(1)` es el **mejor secuencial**, no la versión paralela con un proceso
(idea 31); con 12.6 s todos los *speedups* salen inflados. Repasa: U3 S10 notas §2; S06 notas §4.
</details>

**29. [numérico]** Perfil de la V1 de un equipo (`n` fijo, mediana de 5): lectura de datos 0.6 s, cómputo 5.0 s,
escritura 0.4 s. Solo el cómputo se paraleliza. (a) Fracción secuencial en tiempo y techo del *speedup*. (b) *Speedup*
con 4 hilos si el cómputo escala perfecto. (c) Un integrante dice que la parte paralelizable es el 10 % porque el
cómputo son 40 de 400 líneas. ¿Qué está mal? (d) ¿Qué *speedup* se reporta: el de la sección de cómputo (4×) o el del
programa?

<details><summary>Respuesta 29</summary>

(a) `f = (0.6 + 0.4) / 6.0 ≈ 0.17`; techo `1/f = 6`. (b) `T = 1.0 + 5.0/4 = 2.25 s` → `S = 6.0 / 2.25 ≈ 2.67`.
(c) La fracción de Amdahl se mide en **tiempo** de la versión secuencial, no en líneas: aquí lo paralelizable es
`5.0/6.0 ≈ 83 %` (idea 2). (d) El del programa completo, 2.67: es el que vive el usuario; el de la sección va aparte si
ayuda a explicar (idea 2b). Repasa: U3 S10 notas §2; S05 notas §1.
</details>

**30. [opción múltiple]** La V3 suma `2^24` `float` con un árbol por bloque y una `atomicAdd` por bloque. Entre corridas
la suma cambia en el séptimo dígito. ¿Qué concluyes?

- **A.** Hay una carrera en la `atomicAdd`; se corrige con un `__syncthreads()` después de la atómica.
- **B.** Es redondeo que depende del orden en que llegan las atómicas; se compara contra una referencia en `double`
  con tolerancia relativa declarada (por ejemplo `1e-4`). Con datos enteros la comparación sería exacta.
- **C.** La referencia correcta es la suma secuencial en `float`, porque la GPU también suma en `float`.
- **D.** La V3 está mal: un programa correcto da siempre el mismo número, idéntico al de la V1.

<details><summary>Respuesta 30</summary>

**B.** A es la idea 7e (tomar el orden arbitrario por carrera) mezclada con la 25; C, la 10c (con `2^24` elementos el
acumulador `float` secuencial se equivoca alrededor de 10 %: la referencia debe ser **más** precisa que lo que se
verifica); D, la 10 (esperar igualdad exacta en punto flotante). Repasa: S03 notas §6 y CT2.
</details>

## 4. Plan de estudio de 5 días (sesiones de 40 minutos)

Cada sesión es individual, sin apuntes mientras contestas y con el cronómetro a la vista. Estructura fija:
**5 min de vaciado** (escribe en una hoja en blanco todo lo que recuerdes del tema indicado y compáralo después con el
archivo que se cita) → **25 min de preguntas** del banco, por escrito → **10 min de corrección**: abre las respuestas,
marca ✓/~/✗ y anota en tu bitácora (abajo) las que vuelven. Si no terminas, lo pendiente pasa al día siguiente. Este
plan sirve de base para el que escribiste en la pregunta 2 del *exit ticket* de S06.

| Día | Fecha | Vaciado (5 min) | Preguntas (25 min) | Qué vuelve |
|---|---|---|---|---|
| 1 | martes 1 de diciembre (tarde, después del Lab 2) | Las tres reglas del modelo CUDA: bloques, índice y guardia, verificación ([S01 notas](S01_2026-11-23_H2-modelo-cuda/notas-estudiante.md) §3) | 1, 4, 9, 12, 15, 18, 22, 27 | — |
| 2 | miércoles 2 de diciembre | "¿Quién tiene el dato antes y quién después?" para las siete colectivas ([U4 S03 notas](../U4-memoria-distribuida/S03_2026-11-10_colectivas-lab1/notas-estudiante.md)) | 2, 5, 7, 10, 13, 16, 19, 28 | Las ~ y ✗ del día 1 |
| 3 | jueves 3 de diciembre (tarde, después de S06) | Las fórmulas de [S06 notas](S06_2026-12-03_repaso-E3/notas-estudiante.md) §4 | 3, 6, 8, 11, 14, 20 | Los ítems del examen de práctica de hoy en que perdiste más de la mitad: busca en su clave el número de idea errónea y contesta otra vez las preguntas del banco que §5 asocia a esa idea |
| — | viernes 4 de diciembre | Sin sesión de esta guía: haz la [tarea de S06](S06_2026-12-03_repaso-E3/tarea-espaciada.md) (40 min; es estudio del Examen 3: elección entre técnicas, cazadores y la parte de la Unidad III) | — | — |
| 4 | sábado 5 de diciembre | Los seis pasos del porte y la tabla "qué cuenta como V3" ([S05 notas](S05_2026-12-01_lab2-taller-V3/notas-estudiante.md) §2 y §4) | 17, 21, 23, 24, 25, 26, 29 | Las ~ y ✗ del día 3 y dos ✓ de los días 1–2 elegidas al azar |
| — | domingo 6 de diciembre | Sin sesión de estudio: la **Práctica 6 vence a las 23:59** | — | — |
| 5 | lunes 7 de diciembre (tarde, después de C1 y de la entrega final) | Las ideas erróneas de §5 que más fallaste | 30 | Todas las ~ y ✗ pendientes, y rehacer sin apuntes el ítem peor contestado del examen de práctica |
| Examen | martes 8 de diciembre, antes de salir de casa | 5 min: escribe de memoria las fórmulas de S06 notas §4 y compáralas. Nada nuevo | — | — |

Cada día mezcla temas a propósito: el día 1 tiene preguntas de ocho de los diez temas; los días 1–3 alternan MPI y
GPU, y el día 4 junta GPU, diseño y Unidad III. Si una pregunta te sale ✗ dos días seguidos, vuelve a hacer la práctica guiada de su sesión (§1,
columna "Dónde repasar") antes de intentarla otra vez.

**Bitácora de calibración** (cópiala en tu cuaderno). Antes de cada sesión anota cuántas esperas contestar bien; al
corregir, cuántas fueron.

| Día | Preguntas | Espero acertar | Acerté (✓) | Vuelven (~ y ✗) |
|---|---|---|---|---|
| 1 | 8 | | | |
| 2 | 8 + las del día 1 | | | |
| 3 | 6 + ítems del examen de práctica | | | |
| 4 | 7 + las del día 3 | | | |
| 5 | 1 + pendientes | | | |

Si cada día esperas más de lo que aciertas, te pasará lo mismo el martes: dedica el día 5 a tus ✗, no a lo que ya
sabes.

## 5. Errores frecuentes (Anexo A) y qué pregunta los entrena

Catálogo completo en [`docs/metodo/01-marco-pedagogico.md`](../../docs/metodo/01-marco-pedagogico.md), Anexo A.
Los distractores de la opción múltiple del examen salen de aquí.

| # | Idea errónea | Lo correcto | Preguntas |
|---|---|---|---|
| 16 | "Los procesos MPI comparten memoria" | Cada proceso tiene su espacio; tras `Reduce`/`Gather` el resultado solo está en la raíz | 1, 8 |
| 17 | "`MPI_Send` siempre regresa de inmediato" / "siempre espera al receptor" | Promete solo que el búfer se puede reutilizar; depende del tamaño: un programa seguro no depende del búfer interno | 4, 5 |
| 18 | "Solo la raíz llama a `MPI_Bcast`" | Todas las colectivas las llaman **todos** los procesos del comunicador | 1, 2, 8 |
| 19 | "El rango 0 tiene que ser el maestro" | Cualquier rango puede ser raíz | 1 |
| 20 | "Más procesos que núcleos siempre está bien" | La sobre-suscripción sirve para probar, no para medir; se declara aparte | 11 |
| 21 | "La comunicación es gratis comparada con el cómputo" | `α + m/β`: cada mensaje paga α; con `n` chico domina | 9, 10 |
| 22 | "Un hilo de CUDA equivale a un núcleo de CPU" | Miles de hilos ligeros en *warps* de 32 (SIMT) | 12, 25 |
| 23 | "La memoria global es tan rápida como la compartida" | Uno o dos órdenes de magnitud; por eso existe el *tiling* | 15, 16, 17 |
| 24 | "Las transferencias no cuentan en el tiempo" | Cuentan y a menudo dominan: dos tiempos, siempre | 20, 22, 23, 25, 26 |
| 25 · 25b · 25c | "`__syncthreads()` sincroniza toda la GPU" · "si la malla cabe, sincroniza todo" · "`cudaDeviceSynchronize()` dentro del *kernel*" | Solo el bloque; entre bloques, el fin del *kernel* | 21, 30 |
| 26 | "Cualquier tamaño de bloque funciona igual" | Múltiplos de 32, ≤ 1 024, ocupación; decide el barrido | 24 |
| 27 | "Si el *kernel* no da error, el resultado es correcto" | Se compara contra la CPU con tolerancia, en más de un tamaño | 3 (su versión MPI), 13, 19, 26 |
| 33 | "El *kernel* terminó cuando regresa la llamada" | Lanzamiento asíncrono: sin sincronizar se mide ≈ 0 | 22, 26 |
| 34 | "No hace falta comprobar `idx < n`" | La malla casi siempre excede `n` | 12, 14, 26 |
| 1 | "Más hilos (procesos) siempre es más rápido" | Lo limitan la comunicación, las copias, la ocupación y la parte secuencial | 10, 24, 28 |
| 2 · 2b | "Amdahl se mide en líneas" · "el *speedup* de la sección es el del programa" | Tiempo de la versión secuencial; se reporta el total | 26, 29 |
| 3 | "Eficiencia y *speedup* son lo mismo" | `E = S/p` | 10, 28 |
| 5 | "Medir una vez basta" / "con `-O0`" | Calentamiento, mediana de ≥ 5, `-O2` | 22, 26 |
| 6 | "Fuerte y débil son sinónimos" | Fuerte: `n` fijo; débil: `n/p` fijo | 11 |
| 7 · 7e | "Si salió bien, no hay carrera" · "si cambia entre corridas, hay carrera" | La carrera se razona por accesos; una atómica de `float` varía por orden | 27, 30 |
| 8b | "Las atómicas son gratis" | Sobre una dirección se serializan: se reduce en el bloque primero | 20, 27 |
| 10 · 10c | "La reducción da exactamente lo mismo" · "la referencia es la suma en `float`" | Tolerancia contra una referencia más precisa (`double`) | 30 |
| 31 | "`T(1)` es la versión paralela con 1 proceso" | `T(1)` es el mejor secuencial | 28 |
| 32 | "Una barrera dentro de un `if` está bien si algún hilo la ejecuta" | Todos los hilos del bloque llegan a la misma barrera | 18 |

Errores de forma que también cuestan puntos ([S06 notas](S06_2026-12-03_repaso-E3/notas-estudiante.md) §5): un número
sin la cuenta o sin unidades vale la mitad; predecir un **orden** de líneas entre procesos como si estuviera
garantizado; escribir el resultado de un `Reduce` en todos los rangos; `i = threadIdx.x` como índice global o `grid = n
/ block`; leer memoria compartida que ningún hilo cargó; "corregir" una carrera con una barrera dentro de un `if`; en
diseño, elegir plataforma sin dos datos numéricos.

## 6. Qué no entra

- **Sin computadora.** Nada se compila ni se ejecuta; lo que sí puede venir en un enunciado es la salida de un
  programa o una tabla de tiempos, para que la interpretes.
- **El examen está en C con MPI y en CUDA C.** Numba y CuPy son para practicar sin GPU y para la V3; no se piden en el
  examen.
- **Solo panorama, no se piden en código:** memoria *pinned* y *streams* (S04 §5; sí debes saber que cambian las
  copias, no el *kernel*); tipos derivados (`MPI_Type_vector`), comunicadores (`MPI_Comm_split`) y MPI+OpenMP híbrido
  (U4 S05–S06); `__shfl_down_sync`, `__syncwarp` y conflictos de banco (ampliaciones de S02 y S03).
- **Herramientas:** `nsys`, `ncu` y `compute-sanitizer` no se evalúan; los eventos `cudaEvent_t` sí.
- **Unidades I–III sin sección propia:** entran 10–20 % dentro de problemas de MPI y GPU (*speedup*, eficiencia, Amdahl,
  Karp–Flatt, carreras y su corrección), no como preguntas aisladas de OpenMP.
- **Tu proyecto** no se evalúa en el examen (eso es la entrega final y la defensa), pero el diseño breve usa el mismo
  razonamiento que la V3.
- **Hoja de fórmulas y calculadora:** no hay. Practica las divisiones a mano con dos o tres cifras.

## 7. El día del examen (martes 8 de diciembre)

**Antes de entrar**

- La víspera vencen la entrega final del proyecto (lunes 7, 10:30) y la tarea de S06 (misma hora); la Práctica 6
  venció el domingo a las 23:59. No dejes nada de eso para la noche del lunes: duerme.
- Llega antes de las 08:30 al aula que se confirmó el lunes 7 (Salón 3208 o Lab LS4 con los equipos apagados). Te
  sentarás en filas alternas con versiones A y B.
- Lleva pluma o lápiz y goma. Mochilas al frente; celular, reloj inteligente, calculadora y audífonos **apagados y
  dentro de la mochila**.

**Al recibir el examen**

1. Llena la **casilla A de la hoja de calibración** (§8) **antes** de voltear el examen.
2. Escribe tu nombre, número de lista y fila.
3. Lee las instrucciones de la portada: 80 minutos, 100 puntos, 16 ítems, el tiempo sugerido por sección (§1), los
   supuestos del código (§2) y que no hay hoja de fórmulas.

**Mientras contestas**

- Orden sugerido: la opción múltiple (I) primero; después los problemas numéricos (V, la sección con más tiempo
  sugerido); luego completar (IV), predecir (II), encontrar el error (III) y al final el diseño (VI).
- Opción múltiple: una sola respuesta correcta; encierra la letra. No hay puntos parciales en esa sección.
- Escribe el procedimiento: un número sin la cuenta que lo produce, o sin unidades, vale la mitad.
- En "predecir la salida", haz primero la tabla con una fila por rango (o por hilo) y una columna por variable, y
  llénala llamada por llamada; si el orden de las líneas entre procesos no está garantizado, dilo.
- En "encontrar el error", sigue el método de [S06 notas](S06_2026-12-03_repaso-E3/notas-estudiante.md) §3: síntoma
  cuantificado → hipótesis por el número → ¿*kernel* o anfitrión? ¿quién llama a la colectiva? → corrección en una
  línea → con qué tamaño la verificarías.
- En diseño: plataforma, **dos** datos numéricos del problema y una alternativa descartada con un número, en 10 líneas
  o menos.
- Si un enunciado te parece ambiguo, levanta la mano: solo se aclaran enunciados, no respuestas. Si la aclaración vale
  para todos, se escribe en el pizarrón. Si aun así dudas, escribe el supuesto que tomaste y contesta con él.

**Al entregar**

- Cuando el profesor avise que faltan 5 minutos, llena la **casilla B de la hoja de calibración**. Al terminar, el
  examen y la hoja se entregan en **montones separados**.

**Después**

- Calificación y clave en ≤ 7 días; la retroalimentación en clase está prevista el lunes 14 de diciembre (reserva del
  calendario), con los tres ítems peor contestados.
- Tu hoja de calibración se abre después de calificar y te regresa con tu brecha; al grupo solo se le muestra el
  promedio. No afecta tu calificación. Ese mismo lunes se compara con la predicción que escribiste en la tarea de S05
  (ejercicio 3b).
- La política para quien no pueda presentarse por causa justificada no está escrita en el material del curso: si es
  tu caso, avísale al profesor con tu justificante institucional lo antes posible.

## 8. Hoja de calibración

El profesor la entrega impresa el día del examen; este es el modelo. Se llena en dos momentos, se entrega aparte y
**no afecta la calificación** (`docs/metodo/04-evaluacion.md` §2.3).

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Examen 3 · martes 8 de diciembre de 2026 · Hoja de calibración · se entrega **aparte** del examen
>
> Nombre: `______________________________`  Número de lista: `____`  Versión: A / B (encierra)
>
> | A · Al recibir el examen, **antes** de leer los ítems: ¿qué calificación esperas? (0–100) | B · Al entregar: ¿qué calificación crees haber obtenido? (0–100) |
> |---|---|
> | | |
>
> Los tres temas que menos dominas hoy (marca tres): ☐ Colectivas: quién llama, quién recibe, raíz · ☐ `Send`/`Recv`,
> bloqueo e interbloqueo · ☐ No bloqueantes y halos · ☐ Modelo `α + m/β`, escalabilidad fuerte/débil · ☐ *Speedup*,
> Amdahl, Karp–Flatt · ☐ Índice global, malla, guardia (CUDA) · ☐ Memoria compartida, `__syncthreads`, coalescencia ·
> ☐ Atómicas, reducción, divergencia · ☐ Eventos, copias, bloque y ocupación · ☐ Elegir plataforma (diseño) ·
> Otro: `__________`
>
> *Para el profesor, después de calificar:* real **C** = `____` · postdicción **B − C** = `____` · predicción
> **A − C** = `____`

**Cómo leer tu brecha.** La que importa es la de la postdicción, **B − C**. Si supera 15 puntos (1.5 sobre 10),
sobreestimaste: estudiaste con la sensación de saber y no con la prueba de saber. Compárala con la brecha del examen
de práctica de S06 (que es sobre 60: multiplícala por 100/60), con tu predicción de la tarea de S05 y con tu bitácora
de §4. Si todas apuntan al mismo lado, ya sabes qué ajustar para el siguiente curso: más preguntas de recuperación y
menos relectura, desde la primera semana.
