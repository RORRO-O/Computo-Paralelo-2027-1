> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S06 · jueves 3 de diciembre de 2026 · 10:30–12:00 · Salón 3208

# Ejemplo resuelto · Dos habilidades del Examen 3: predecir la salida y cazar un error

Es la última sesión de la unidad, así que este ejemplo está **por completar**: tiene huecos (`___`) que llenas
antes de abrir cada respuesta. Modela los dos tipos de ítem que más puntos cuestan en el examen: **II · Predecir la
salida** (parte A, MPI) y **III · Encontrar y corregir el error** (parte B, CUDA). El código completo está en
`practica-guiada/ejemplo_predict_mpi.c`, `practica-guiada/ejemplo_grid.cu` y `ejemplo_grid_numba.py`. Si faltaste:
léelo con lápiz (15 min), corre los dos programas (5 min) y después haz la práctica guiada.

## Parte A · Predecir la salida de un programa MPI corto

### Problema

`mpirun -np 4 ./ejemplo_predict_mpi`. ¿Qué imprime cada rango y qué imprime la raíz como `result`?

```c
int data[8] = {1, 2, 3, 4, 5, 6, 7, 8};  /* solo la raíz lo usa como fuente */
int local[2], result[8], local_sum, total;

MPI_Scatter(data, 2, MPI_INT, local, 2, MPI_INT, 0, MPI_COMM_WORLD);   /* rango r recibe data[2r], data[2r+1] */
local_sum = local[0] + local[1];
local[0] *= rank;
local[1] *= rank;
MPI_Allreduce(&local_sum, &total, 1, MPI_INT, MPI_SUM, MPI_COMM_WORLD); /* todos obtienen la suma global */
MPI_Gather(local, 2, MPI_INT, result, 2, MPI_INT, 0, MPI_COMM_WORLD);  /* la raíz junta los bloques */

printf("rango %d: local_sum=%d total=%d\n", rank, local_sum, total);
if (rank == 0) {
    printf("result=");
    for (int i = 0; i < 8; i++) printf("%d%s", result[i], i < 7 ? " " : "\n");
}
```

### Plan en 3 líneas (el método)

1. Una **tabla con una fila por rango** y una columna por variable; se llena colectiva por colectiva, en el orden
   del código, preguntando en cada una *quién tiene el dato antes y quién lo tiene después*.
2. Las variables que una colectiva **no toca** en un rango conservan lo que tenían (aquí `result` solo existe
   lleno en la raíz).
3. El **orden de las líneas** entre procesos no se predice; solo el contenido de cada línea y el orden dentro de
   un mismo proceso.

### Tabla de rastreo (llena los huecos)

| Rango | `local` tras `Scatter` | `local_sum` | `local` tras `*= rank` | `total` tras `Allreduce` | Aporta a `result[2r..2r+1]` |
|---|---|---|---|---|---|
| 0 | `1 2` | 3 | `0 0` | 36 | `0 0` |
| 1 | `3 4` | 7 | `3 4` | 36 | `3 4` |
| 2 | `5 6` | ___ | ___ | ___ | ___ |
| 3 | ___ | ___ | ___ | ___ | ___ |

<details><summary>Tabla completa</summary>
Rango 2: <code>local_sum = 11</code>, <code>local = 10 12</code>, <code>total = 36</code>, aporta <code>10 12</code>.
Rango 3: <code>local = 7 8</code>, <code>local_sum = 15</code>, <code>local = 21 24</code>, <code>total = 36</code>,
aporta <code>21 24</code>. <code>total = 3 + 7 + 11 + 15 = 36</code> en los cuatro.
</details>

### Salida real (`mpirun --oversubscribe -np 4`, una corrida en la máquina de autoría)

```
rango 1: local_sum=7 total=36
rango 3: local_sum=15 total=36
rango 0: local_sum=3 total=36
result=0 0 3 4 10 12 21 24
rango 2: local_sum=11 total=36
```

En otra corrida las líneas `rango r` salen en otro orden; `result=` siempre va después de `rango 0: …` porque las
imprime el mismo proceso, en ese orden.

### Pausas de autoexplicación

**(1) ¿Por qué `total` vale 36 en los cuatro rangos pero `result` solo tiene sentido en el rango 0?**
<details><summary>Respuesta</summary>
<code>MPI_Allreduce</code> deja el resultado combinado en <strong>todos</strong>; <code>MPI_Gather</code> deja los
bloques solo en la raíz. En los rangos 1–3, <code>result</code> nunca se escribe: si lo imprimieran saldría
basura, sin ningún error. Es la pregunta que decide la colectiva: ¿quién necesita el dato después? (idea errónea
16: cada proceso tiene su memoria).
</details>

**(2) El rango 2 recibe `5 6` y no `3 4`. ¿De dónde sale eso?**
<details><summary>Respuesta</summary>
<code>sendcount = 2</code> es <strong>por rango</strong>: el rango <em>r</em> recibe <code>data[2r]</code> y
<code>data[2r+1]</code>. Con <code>r = 2</code>: <code>data[4], data[5] = 5, 6</code>. El error típico es contar
desde 1 o repartir por bloques de 4.
</details>

**(3) Si se quitara la comprobación `size != 4` y se corriera con `-np 2`, ¿qué pasaría?**
<details><summary>Respuesta</summary>
<code>Scatter</code> repartiría solo <code>data[0..3]</code> (2 rangos × 2) y <code>Gather</code> llenaría solo
<code>result[0..3]</code>; <code>result[4..7]</code> quedaría sin escribir y la raíz imprimiría basura en esas
posiciones, <strong>sin error de MPI</strong>. Con <code>-np 8</code>, en cambio, <code>Scatter</code> leería
<code>data[8..15]</code>, fuera del arreglo. Por eso el programa real comprueba <code>size</code> (salida real con
<code>-np 2</code>: <code>este ejemplo requiere exactamente 4 procesos (hay 2)</code> y código 1).
</details>

**(4) ¿Cuántas de las cinco líneas puedes predecir en orden?**
<details><summary>Respuesta</summary>
Ninguna entre procesos distintos; solo la posición relativa de las dos líneas del rango 0 (<code>rango 0</code>
antes de <code>result</code>). En el examen, "en cualquier orden" es parte de la respuesta correcta; dar un orden
fijo como si estuviera garantizado resta el punto.
</details>

## Parte B · Encontrar y corregir un error que no da error

### Síntoma

`y = 0.5·x` con `x[i] = (i % 7) + 1`, `n = 1000`, `block = 256`. El *kernel* tiene guardia. Salida real (CUDASIM;
en la GPU se espera lo mismo más `cudaGetLastError=no error cudaDeviceSynchronize=no error`):

```
$ NUMBA_ENABLE_CUDASIM=1 python3 practica-guiada/ejemplo_grid_numba.py 1000 256
ejemplo_grid: n=1000 block=256 grid=3 hilos_lanzados=768 modo=CUDASIM
checksum=1533.5 elementos_incorrectos=0 elementos_sin_procesar=232
verificacion=FALLA
```

La referencia: `./caza_cpu grid 1000 → checksum=1998.5`.

### Plan en 3 líneas (el método de caza)

1. **Reproducir y cuantificar** el síntoma con una referencia independiente: no "sale mal", sino *232 elementos
   sin procesar, 0 incorrectos, checksum 465.0 menor*.
2. **Hipótesis por el número**: 232 = 1000 − 768 y 768 = 3 × 256 → faltó un bloque. Los elementos procesados están
   bien → el *kernel* está bien; el error está en **cuántos hilos se lanzaron**: el anfitrión.
3. **Localizar, corregir una línea, re-verificar** con el caso que expuso el error **y** con uno nuevo.

### El código (anfitrión) con los huecos

```c
__global__ void scale(const float *x, float *y, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) y[i] = 0.5f * x[i];                   /* guardia presente: este kernel está bien */
}
/* anfitrión */
int grid = n / block;                                /* <-- ¿qué vale con n = 1000, block = 256?  ___ */
…
scale<<<grid, block>>>(d_x, d_y, n);
cudaError_t launch_err = cudaGetLastError();         /* ¿se queja?  ___ */
cudaError_t exec_err = cudaDeviceSynchronize();      /* ¿se queja?  ___ */
```

Hueco 1: `grid = ___` y `hilos lanzados = ___`. Hueco 2: ¿en qué línea está el error: el `if (i < n)`, el cálculo
de `i`, o `grid`? Hueco 3: la corrección es `grid = ___`.

<details><summary>Huecos</summary>
<code>grid = 1000 / 256 = 3</code> (división entera), 768 hilos. Ninguna de las dos verificaciones de CUDA se
queja: 3 bloques de 256 es una configuración válida y ningún hilo toca memoria ajena. El error está en
<code>grid</code>: <code>grid = (n + block − 1) / block = 4</code>. Salida real corregida (<code>--corregido</code>):
<code>grid=4 hilos_lanzados=1024 … checksum=1998.5 elementos_incorrectos=0 elementos_sin_procesar=0
verificacion=OK</code>.
</details>

### Pausas de autoexplicación

**(5) El detector distingue "sin procesar" de "incorrecto". ¿Cómo, y por qué importa para la hipótesis?**
<details><summary>Respuesta</summary>
<code>y</code> se inicializa en 0 y la referencia es <code>0.5·x ≥ 0.5</code>: un 0 en <code>y</code> solo puede
significar "ningún hilo lo escribió". Que los 768 procesados sean <strong>correctos</strong> descarta el
<em>kernel</em> (índice y aritmética) y apunta al anfitrión. Diseñar la verificación para que el síntoma diga
<em>dónde</em> mirar es la mitad de la caza.
</details>

**(6) ¿Por qué `cudaGetLastError()` no reporta nada si faltan 232 elementos?**
<details><summary>Respuesta</summary>
Reporta errores de <strong>lanzamiento</strong> (configuración inválida: bloque > 1 024, malla de 0 bloques) y
<code>cudaDeviceSynchronize()</code> errores de <strong>ejecución</strong> (acceso ilegal). Lanzar menos hilos de
los necesarios no es ninguna de las dos cosas: CUDA no sabe cuánto trabajo querías hacer (idea errónea 27). La
única evidencia es la referencia.
</details>

**(7) Variante que falla distinto: `n = 100` con el código sin corregir.**
<details><summary>Respuesta</summary>
<code>grid = 100 / 256 = 0</code>. Salida real (CUDASIM, el espejo no lanza nada si <code>grid = 0</code>):
<code>grid=0 hilos_lanzados=0 … elementos_sin_procesar=100 verificacion=FALLA</code>. En CUDA C,
<code>scale&lt;&lt;&lt;0, 256&gt;&gt;&gt;</code> sí es un lanzamiento inválido: se espera
<code>cudaGetLastError=invalid configuration argument</code>. El mismo error de una línea produce un síntoma
silencioso con <code>n = 1000</code> y uno ruidoso con <code>n = 100</code>: por eso la re-verificación incluye un
tamaño nuevo.
</details>

**(8) Transferencia al examen: en el ítem III.2 (histograma sin `atomicAdd`) el síntoma es `total_gpu` mucho
menor que `n` y distinto en cada corrida. Aplica los pasos 1–2 del método: ¿qué número cuantifica el síntoma y
qué hipótesis descarta?**
<details><summary>Respuesta</summary>
El número es <code>total_gpu &lt; n</code> (se <em>pierden</em> cuentas, nunca se inventan) y que
<strong>cambia entre corridas</strong>. Un error de índice o de malla daría un faltante <strong>fijo</strong>
(como los 232 de aquí). Un faltante variable con índices correctos solo lo produce una carrera: varios hilos
hacen lectura-suma-escritura sobre la misma dirección. Corrección: <code>atomicAdd</code>. En CUDASIM la carrera
casi nunca se manifiesta: una plataforma que no la muestra no la corrige.
</details>

## Qué te llevas al examen

- **Predecir**: tabla por rango (MPI) o por hilo (CUDA); colectiva por colectiva; lo que no se toca se queda; el
  orden entre procesos no se promete.
- **Cazar**: cuantificar el síntoma contra una referencia → hipótesis por el número (¿faltante fijo o variable?
  ¿procesados correctos?) → ¿*kernel* o anfitrión? ¿quién llama a la colectiva? → una línea → re-verificar con dos
  tamaños.
- **Ninguno de los errores de esta sesión imprime un mensaje**: ni `grid = n / block`, ni `Reduce` leído en todos,
  ni la falta de guardia, ni la falta de barrera, ni la falta de atómica. "Sin error" solo significa que CUDA o
  MPI hicieron lo que les pediste.
