> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S01 · jueves 5 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S01 · Ejemplo resuelto: sumar un arreglo repartido entre procesos

Código completo: `practica-guiada/suma_distribuida.c`. Aquí se recorre paso a paso. En cada **pausa**,
responde por escrito antes de abrir la respuesta.

## Problema

Sumar `n` números con `p` procesos MPI. No hay un arreglo en memoria compartida: cada proceso debe calcular
**solo** los elementos que le tocan (`element(i)` los genera a partir de `i`) y al final un solo proceso debe
tener la suma total. Verificación: debe coincidir con `referencia_secuencial`, que suma los `n` elementos en
un solo proceso.

## Plan en tres líneas

1. Cada proceso pregunta quién es (`rank`) y cuántos son (`size`), y con eso calcula su bloque `[start, end)`.
2. Cada proceso suma su bloque en `local_sum`.
3. Los rangos 1..p−1 envían su `local_sum` al rango 0; el rango 0 las recibe una por una y las acumula.

En términos de Foster: partición = `n` tareas de un elemento; comunicación = `p − 1` mensajes hacia quien
combina; aglomeración = `p` bloques contiguos; mapeo = bloque `k` → rango `k`.

## Código comentado (núcleo del programa)

```c
/* Valor del elemento i: determinista, cualquier proceso lo calcula sin preguntar a nadie. */
static double element(long long i)
{
    return (double)((i * 7919LL + 13LL) % 1000LL) / 10.0;      /* valores en [0.0, 99.9] */
}

/* Reparto por bloques con residuo: intervalo [start, end) del rango 'rank'. */
static void block_range(long long n, int rank, int size, long long *start, long long *end)
{
    long long q = n / size;                     /* tamaño base */
    long long r = n % size;                     /* sobran r elementos: uno extra a los rangos 0..r-1 */
    long long count = q + (rank < r ? 1 : 0);
    *start = (long long)rank * q + (rank < r ? rank : r);   /* cuántos "extras" hay antes de mí */
    *end = *start + count;
}

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);                                   /* (1) arranca MPI */
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);                     /* (2) ¿quién soy? */
    MPI_Comm_size(MPI_COMM_WORLD, &size);                     /*     ¿cuántos somos? */

    long long n = (argc > 1) ? atoll(argv[1]) : 10;           /* todos leen el mismo argv */
    const char *mode = (argc > 2) ? argv[2] : "bloques";      /* "bloques" o "ciclico" (TODO(1)) */

    MPI_Barrier(MPI_COMM_WORLD);                              /* (3) alinear el arranque del cronómetro */
    double t_start = MPI_Wtime();

    long long start, end;
    block_range(n, rank, size, &start, &end);                 /* (4) aglomeración + mapeo */
    double local_sum = 0.0;
    for (long long i = start; i < end; i++)
        local_sum += element(i);                              /* (5) mi parte */

    double total = local_sum;                                 /* (6) cada rango tiene SU 'total' */
    if (rank != 0) {
        MPI_Send(&local_sum, 1, MPI_DOUBLE, 0, 0, MPI_COMM_WORLD);   /* (7) 1 double -> rango 0, etiqueta 0 */
    } else {
        for (int src = 1; src < size; src++) {
            double partial;
            MPI_Recv(&partial, 1, MPI_DOUBLE, src, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);  /* (8) */
            total += partial;
        }
    }
    double t_end = MPI_Wtime();

    if (rank == 0) {                                          /* (9) solo uno imprime el resultado */
        printf("suma total = %.3f (n = %lld, p = %d, reparto = %s)\n", total, n, size, mode);
        printf("tiempo = %.6f s\n", t_end - t_start);
    }
    MPI_Finalize();                                           /* (10) cierra MPI */
    return 0;
}
```

## Salida real

```
$ ./referencia_secuencial 10
n = 10
suma = 548.500
promedio = 54.850
maximo = 93.200
tiempo = 0.000001 s (solo la suma)

$ mpirun -np 4 ./suma_distribuida 10 bloques
[rango 0] bloques: 3 elementos {0, 1, 2}, suma parcial = 179.600
[rango 1] bloques: 3 elementos {3, 4, 5}, suma parcial = 206.700
[rango 2] bloques: 2 elementos {6, 7}, suma parcial = 97.300
[rango 3] bloques: 2 elementos {8, 9}, suma parcial = 64.900
suma total = 548.500 (n = 10, p = 4, reparto = bloques)
tiempo = 0.004264 s

$ mpirun -np 3 ./suma_distribuida 10 bloques
[rango 1] bloques: 3 elementos {4, 5, 6}, suma parcial = 182.400
[rango 2] bloques: 3 elementos {7, 8, 9}, suma parcial = 109.500
[rango 0] bloques: 4 elementos {0, 1, 2, 3}, suma parcial = 256.600
suma total = 548.500 (n = 10, p = 3, reparto = bloques)
tiempo = 0.000024 s
```

Observa: con `-np 3` las líneas de los rangos salieron en el orden 1, 2, 0. Con `-np 4` salieron 0, 1, 2, 3.
Ninguno de los dos órdenes está garantizado. El tiempo con `n = 10` es sobrecarga pura: no sirve para medir.

## Pausas de autoexplicación

**Pausa 1.** ¿Por qué `MPI_Comm_rank` va después de `MPI_Init` y no antes? ¿Qué valor tendría `rank` si lo
imprimieras antes de `MPI_Init`?

<details><summary>Respuesta</summary>
Antes de <code>MPI_Init</code> el proceso es un programa de C común: no sabe que forma parte de un grupo ni
cuál es su número. <code>MPI_Init</code> establece el comunicador <code>MPI_COMM_WORLD</code> y la identidad
de cada copia. Si imprimieras <code>rank</code> antes, verías basura (variable sin inicializar), y llamar a
<code>MPI_Comm_rank</code> antes de <code>MPI_Init</code> es un error del estándar (comportamiento indefinido;
Open MPI aborta con un mensaje).
</details>

**Pausa 2.** En `block_range`, ¿por qué los primeros `r` rangos reciben un elemento más? ¿Qué pasaría si
todos tomaran exactamente `n / size` elementos? Calcula con `n = 10`, `size = 4`.

<details><summary>Respuesta</summary>
Porque <code>n / size</code> trunca: 10 / 4 = 2, y 4 bloques de 2 cubren solo 8 índices (0..7). Sobran
<code>r = 10 % 4 = 2</code> elementos (los índices 8 y 9) que alguien tiene que tomar. Dárselos uno a uno a los
rangos 0 y 1 mantiene la diferencia máxima entre bloques en un elemento (balance). Con <code>n / size</code>
para todos, la suma pierde los últimos <code>r</code> elementos: es la variante que falla de abajo.
</details>

**Pausa 3.** Línea (6): `double total = local_sum;` se ejecuta en **todos** los rangos. Al terminar el
programa, ¿cuánto vale `total` en el rango 2? ¿Y en el rango 0?

<details><summary>Respuesta</summary>
En el rango 2 vale 97.300: su parcial y nada más, porque nadie le envió nada y nada se "comparte". En el rango
0 vale 548.500 porque solo él recibió las otras tres parciales. Se comprobó agregando
<code>printf("[rango %d] total = %.3f\n", rank, total);</code> después de la combinación:
<pre>
[rango 3] total = 64.900
[rango 1] total = 206.700
[rango 0] total = 548.500
[rango 2] total = 97.300
</pre>
Cuatro procesos, cuatro variables <code>total</code>, cuatro valores. Esta es la idea errónea 16 en acción:
los procesos MPI no comparten memoria, ni siquiera corriendo en la misma máquina.
</details>

**Pausa 4.** Línea (8): el rango 0 recibe primero del rango 1, luego del 2, luego del 3. ¿Qué pasa si el rango
3 termina su suma antes que el rango 1? ¿Se pierde su mensaje? ¿Se recibe fuera de orden?

<details><summary>Respuesta</summary>
No se pierde ni se recibe fuera de orden. <code>MPI_Recv(..., src = 1, ...)</code> solo acepta un mensaje
que venga del rango 1; el del rango 3 queda pendiente en el sistema MPI hasta que el ciclo llegue a
<code>src = 3</code>. El orden de <b>recepción</b> lo fija el programa, no el orden de llegada. El costo:
si el rango 1 es el más lento, el rango 0 espera aunque ya tenga los demás. En S02 verás
<code>MPI_ANY_SOURCE</code> para recibir "del primero que llegue".
</details>

**Pausa 5.** ¿Tiene que ser el rango 0 el que combine? ¿Qué cambiarías para que combine el rango `size − 1`?

<details><summary>Respuesta</summary>
No tiene que serlo (idea errónea 19). Dos cambios: en <code>MPI_Send</code> el destino pasa de <code>0</code>
a <code>size - 1</code>, y el <code>if</code> se invierte: <code>if (rank != size - 1) Send; else for (src = 0;
src &lt; size - 1; src++) Recv</code>. También cambia quién imprime. MPI solo exige que emisores y receptor se
pongan de acuerdo en destino, etiqueta y comunicador.
</details>

**Pausa 6.** ¿Para qué sirve la `MPI_Barrier` de la línea (3)? ¿Por qué el tiempo se toma en el rango 0
**después** del ciclo de recepción y no después de su propia suma?

<details><summary>Respuesta</summary>
Sin barrera, un proceso que arrancó tarde (los procesos no nacen en el mismo instante) empezaría su
cronómetro después y el tiempo reportado sería menor que el real. La barrera alinea el "inicio". El fin se
toma en el rango 0 tras recibir todo porque ese es el momento en que el resultado existe: incluye la espera
por el proceso más lento y el costo de los mensajes. Medir solo la suma local escondería ambos.
</details>

## Variante que falla: `suma_distribuida_buggy.c`

El único cambio respecto al programa correcto es el reparto:

```c
long long chunk = n / size;                 /* BUG: olvida el residuo n % size */
long long start = (long long)rank * chunk;
long long end = start + chunk;
```

Salida real:

```
$ mpirun -np 4 ./suma_distribuida_buggy 10
[rango 1] indices 2..3 (2 elementos), suma parcial = 162.100
[rango 3] indices 6..7 (2 elementos), suma parcial = 97.300
[rango 2] indices 4..5 (2 elementos), suma parcial = 129.700
[rango 0] indices 0..1 (2 elementos), suma parcial = 94.500
suma total = 483.600 (n = 10, p = 4, elementos sumados = 8)

$ mpirun --oversubscribe -np 5 ./suma_distribuida_buggy 10
[rango 4] indices 8..9 (2 elementos), suma parcial = 64.900
[rango 1] indices 2..3 (2 elementos), suma parcial = 162.100
[rango 2] indices 4..5 (2 elementos), suma parcial = 129.700
[rango 0] indices 0..1 (2 elementos), suma parcial = 94.500
[rango 3] indices 6..7 (2 elementos), suma parcial = 97.300
suma total = 548.500 (n = 10, p = 5, elementos sumados = 10)
```

Con `-np 4` faltan los índices 8 y 9 (548.500 − 483.600 = 64.900, exactamente la parcial del rango 3 del
programa correcto). Con `-np 5` el resultado es correcto porque `10 % 5 == 0`. Un programa que "sale bien" con
cierto `p` y mal con otro tiene un error de reparto; la prueba de un reparto es correr con `n` **no** múltiplo
de `p` (por eso `tests/run_tests.sh` usa `n = 1000003`, primo).

## Lo que debes poder explicar en voz alta

- Cuántas variables `total` existen cuando corres con `-np 4` y qué vale cada una al final.
- Por qué `block_range` suma `min(rank, r)` al inicio del bloque.
- Qué línea mueve datos entre procesos (solo hay una pareja: `MPI_Send`/`MPI_Recv`).
- Por qué el tiempo se mide con barrera al inicio y en el rango 0 al final.
- Qué `n` usarías para detectar el error de `suma_distribuida_buggy` con cualquier `p`.
