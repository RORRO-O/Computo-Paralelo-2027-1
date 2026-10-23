> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S02 · lunes 9 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S02 · Ejemplo resuelto: recibir sin saber quién ni cuánto (y la variante que se cuelga)

Código: `practica-guiada/status_demo.c` (ejemplo) y `practica-guiada/cross_exchange_buggy.c`,
`practica-guiada/cross_exchange_fixed.c` (variante que falla y correcciones). Todas las salidas de este
documento son corridas reales con Open MPI 4.1.6 en una máquina de 4 núcleos.

## 1. Problema

El rango 0 debe recolectar un mensaje de cada uno de los demás rangos. No sabe en qué orden llegarán ni
cuántos elementos trae cada uno: el rango *r* envía *r* + 2 enteros con etiqueta 10·*r*. Por cada mensaje, el
rango 0 imprime quién lo envió, con qué etiqueta, cuántos elementos llegaron y el primero y el último.

## 2. Plan (tres líneas)

1. Emisores (*r* ≥ 1): llenar un arreglo y llamar a `MPI_Send` con cuenta, tipo, destino 0 y etiqueta.
2. Receptor (rango 0): `size − 1` llamadas a `MPI_Recv` con `MPI_ANY_SOURCE` y `MPI_ANY_TAG`, en un búfer con
   capacidad de sobra.
3. Después de cada `MPI_Recv`, leer `status.MPI_SOURCE`, `status.MPI_TAG` y `MPI_Get_count`.

## 3. El sobre y el contenido

Un mensaje tiene **contenido** (dónde empieza, cuántos elementos, de qué tipo) y **sobre** (quién lo manda,
a quién, con qué etiqueta, en qué comunicador).

```c
int MPI_Send(const void *buf, int count, MPI_Datatype datatype,
             int dest, int tag, MPI_Comm comm);
int MPI_Recv(void *buf, int count, MPI_Datatype datatype,
             int source, int tag, MPI_Comm comm, MPI_Status *status);
```

| Argumento | En `MPI_Send` | En `MPI_Recv` |
|---|---|---|
| `buf` | Dirección del primer elemento a enviar | Dónde dejar lo que llegue |
| `count` | Cuántos elementos se envían | **Capacidad** del búfer (máximo que cabe), no lo que llega |
| `datatype` | Tipo MPI de cada elemento | Igual; debe corresponder al tipo enviado |
| `dest` / `source` | Rango destino | Rango emisor, o `MPI_ANY_SOURCE` |
| `tag` | Entero ≥ 0 que elige el programa | El mismo entero, o `MPI_ANY_TAG` |
| `comm` | Comunicador (`MPI_COMM_WORLD`) | El mismo |
| `status` | — | Quién, qué etiqueta y cuánto llegó en realidad |

Tipos básicos que usarás esta unidad: `MPI_CHAR`, `MPI_INT`, `MPI_LONG`, `MPI_UNSIGNED`, `MPI_FLOAT`,
`MPI_DOUBLE`, `MPI_BYTE` (bytes crudos, sin interpretación). El tipo de C del búfer y el tipo MPI deben
corresponder: `int` ↔ `MPI_INT`, `double` ↔ `MPI_DOUBLE`.

Una recepción **acepta** un mensaje cuando coinciden tres cosas: el comunicador, la fuente (o comodín) y la
etiqueta (o comodín). El tipo y la cuenta no forman parte del emparejamiento: si llega más de lo que cabe, es
un error (`MPI_ERR_TRUNCATE`); si llega menos, `MPI_Get_count` te dice cuánto.

## 4. Código comentado

```c
#include <mpi.h>
#include <stdio.h>

#define CAPACITY 64 /* capacidad del búfer de recepción, en elementos */

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    int buf[CAPACITY]; /* cada proceso tiene SU PROPIO buf: no se comparte */

    if (rank != 0) {
        int count = rank + 2;  /* cuántos elementos envía este rango */
        int tag = 10 * rank;   /* etiqueta elegida por el programa   */
        for (int i = 0; i < count; i++)
            buf[i] = rank * 100 + i;

        MPI_Send(buf, count, MPI_INT, 0, tag, MPI_COMM_WORLD);

        /* Cuando MPI_Send regresa, buf ya se puede reutilizar. Eso NO quiere
         * decir que el rango 0 ya recibió el mensaje.                       */
        buf[0] = -1; /* no afecta lo que recibe el rango 0 */
    } else {
        for (int k = 0; k < size - 1; k++) {
            MPI_Status status;
            MPI_Recv(buf, CAPACITY, MPI_INT, MPI_ANY_SOURCE, MPI_ANY_TAG,
                     MPI_COMM_WORLD, &status);

            int received; /* cuántos elementos llegaron en realidad */
            MPI_Get_count(&status, MPI_INT, &received);

            printf("rango 0: mensaje %d de %d -> fuente=%d etiqueta=%d "
                   "elementos=%d (capacidad=%d) primero=%d ultimo=%d\n",
                   k + 1, size - 1, status.MPI_SOURCE, status.MPI_TAG,
                   received, CAPACITY, buf[0], buf[received - 1]);
        }
    }
    MPI_Finalize();
    return 0;
}
```

## 5. Salida real

```
$ mpirun -np 3 ./status_demo
rango 0: mensaje 1 de 2 -> fuente=1 etiqueta=10 elementos=3 (capacidad=64) primero=100 ultimo=102
rango 0: mensaje 2 de 2 -> fuente=2 etiqueta=20 elementos=4 (capacidad=64) primero=200 ultimo=203

$ mpirun -np 4 ./status_demo
rango 0: mensaje 1 de 3 -> fuente=3 etiqueta=30 elementos=5 (capacidad=64) primero=300 ultimo=304
rango 0: mensaje 2 de 3 -> fuente=2 etiqueta=20 elementos=4 (capacidad=64) primero=200 ultimo=203
rango 0: mensaje 3 de 3 -> fuente=1 etiqueta=10 elementos=3 (capacidad=64) primero=100 ultimo=102
```

Con 4 procesos llegó primero el rango 3. En otra corrida puede llegar primero el 1: el orden de llegada
entre **emisores distintos** no está garantizado. Lo que sí garantiza MPI es que dos mensajes del **mismo**
emisor al **mismo** receptor, en el mismo comunicador y que casen con la misma recepción, no se adelantan
entre sí.

## 6. Pausas de autoexplicación

Responde cada pausa antes de abrir la respuesta.

**Pausa 1.** ¿Por qué el rango 0 pasa `CAPACITY` (64) a `MPI_Recv` y no `rank + 2`, que es lo que de verdad
envía cada rango?

<details><summary>Respuesta</summary>
Porque no sabe de quién es el mensaje que va a llegar (usa <code>MPI_ANY_SOURCE</code>) y por tanto no sabe
cuántos elementos trae. <code>count</code> en <code>MPI_Recv</code> es una capacidad: "aquí caben hasta 64".
Lo que llegó de verdad se consulta con <code>MPI_Get_count</code>. Pedir menos de lo que llega es error;
pedir más es normal.
</details>

**Pausa 2.** ¿Qué pasaría si el rango 0 recibiera con un ciclo de fuente fija,
`for (src = 1; src < size; src++) MPI_Recv(buf, CAPACITY, MPI_INT, src, MPI_ANY_TAG, ...)`?

<details><summary>Respuesta</summary>
También funciona. Si el mensaje del rango 3 llega antes de que el rango 0 pida el del 1, MPI lo guarda y lo
entrega cuando toque. El costo es que impones un orden: si el rango 1 tarda, el 0 espera aunque ya tenga
el del 3 disponible. <code>MPI_ANY_SOURCE</code> atiende en orden de llegada; la fuente fija, en el orden
que tú decidas. Ninguna de las dos produce interbloqueo aquí porque los emisores no esperan nada.
</details>

**Pausa 3.** El emisor hace `buf[0] = -1` después de `MPI_Send`. ¿El rango 0 imprime `primero=-1`?

<details><summary>Respuesta</summary>
No. La salida real muestra <code>primero=100</code>, <code>200</code>, <code>300</code>. El mensaje es una
<strong>copia</strong> que salió del proceso emisor; lo que el emisor haga después con su memoria no toca
la memoria del rango 0. Cada proceso tiene su propio <code>buf</code> (idea errónea 16: "los procesos MPI
comparten memoria"). Además, el estándar garantiza que al regresar <code>MPI_Send</code> el búfer ya es
tuyo otra vez.
</details>

**Pausa 4.** ¿`MPI_Send` del rango 2 regresa cuando el rango 0 ya recibió su mensaje?

<details><summary>Respuesta</summary>
No necesariamente. Regresa cuando MPI ya no necesita tu búfer. Si el mensaje es pequeño, Open MPI lo copia
a un búfer interno y <code>MPI_Send</code> regresa aunque el rango 0 todavía esté ocupado; si es grande,
espera hasta que el receptor esté listo. Las dos conductas están permitidas por el estándar (idea errónea
17). La sección 7 muestra qué pasa cuando un programa asume una sola de ellas.
</details>

**Pausa 5.** Cambia la cuenta de `MPI_Recv` de `CAPACITY` a `4`. ¿Qué pasa con `-np 4`?

<details><summary>Respuesta</summary>
Los mensajes de 3 y 4 elementos pasan; el de 5 (rango 3) no cabe y Open MPI aborta el programa. Salida real
(recortada: Open MPI antepone <code>[nodo:pid]</code> a cada línea de error y agrega otras dos de contexto):

<pre>
rango 0: mensaje 1 de 3 -> fuente=2 etiqueta=20 elementos=4 (capacidad=64) primero=200 ultimo=203
rango 0: mensaje 2 de 3 -> fuente=1 etiqueta=10 elementos=3 (capacidad=64) primero=100 ultimo=102
*** An error occurred in MPI_Recv
*** MPI_ERR_TRUNCATE: message truncated
*** MPI_ERRORS_ARE_FATAL (processes in this communicator will now abort,
</pre>

Regla: la capacidad del receptor debe ser ≥ lo que envía el emisor. Cuando no sabes cuánto llegará, usa
una capacidad máxima conocida (como aquí) o, más adelante, <code>MPI_Probe</code> + <code>MPI_Get_count</code>
antes de recibir.
</details>

## 7. Variante que falla: el intercambio cruzado

Dos procesos quieren intercambiar arreglos de `n` enteros. Lo más natural es que cada uno envíe el suyo y
luego reciba el del otro (`cross_exchange_buggy.c`, fragmento):

```c
int partner = rank ^ 1;                       /* 0<->1 */
MPI_Send(send_buf, n, MPI_INT, partner, TAG_DATA, MPI_COMM_WORLD);
MPI_Recv(recv_buf, n, MPI_INT, partner, TAG_DATA, MPI_COMM_WORLD, &status);
```

```
$ mpirun -np 2 ./cross_exchange_buggy 10
rango 0: intercambio correcto con rango 1 (n=10, recibidos=10)
rango 1: intercambio correcto con rango 0 (n=10, recibidos=10)

$ timeout 10 mpirun -np 2 ./cross_exchange_buggy 1000000; echo "codigo $?"
codigo 124
```

Con 10 enteros termina. Con un millón, `timeout` lo mata a los 10 segundos (código 124): **interbloqueo**.
Los dos procesos están dentro de `MPI_Send`, cada uno esperando a que el otro llegue a `MPI_Recv`, y
ninguno llega.

**Por qué los dos resultados son consistentes.** `MPI_Send` es el envío *estándar*: el estándar MPI deja a la
implementación decidir si copia el mensaje a un búfer interno (entonces regresa pronto) o si espera al
receptor (entonces bloquea). Open MPI copia los mensajes chicos (protocolo *eager*) y no los grandes
(*rendezvous*). En la máquina de autoría el umbral está en `btl_vader_eager_limit` = 4 096 bytes: el programa
terminó con n = 1 010 (4 040 bytes) y se colgó con n = 1 015 (4 060 bytes). Ese número cambia con la versión,
el transporte (en red TCP el límite es otro) y la configuración. Un programa que depende de él es
**inseguro**: hoy funciona, mañana no.

**Regla.** Un programa MPI es correcto solo si termina aun cuando *todos* sus `MPI_Send` bloqueen hasta que
exista la recepción correspondiente.

### Tres correcciones

| Corrección | Idea | Código (en cada rango) |
|---|---|---|
| Orden por paridad | Que nunca estén los dos en `Send` a la vez | `if (rank % 2 == 0) { Send; Recv; } else { Recv; Send; }` |
| `MPI_Sendrecv` | Una llamada que envía y recibe; MPI la implementa sin espera circular | `MPI_Sendrecv(send_buf, n, MPI_INT, partner, TAG, recv_buf, n, MPI_INT, partner, TAG, comm, &status)` |
| No bloqueante (S04) | Iniciar las dos operaciones y esperar después | `MPI_Irecv(...,&rr); MPI_Isend(...,&sr); MPI_Wait(&rr,&st); MPI_Wait(&sr, MPI_STATUS_IGNORE);` |

La primera y la tercera están en `cross_exchange_fixed.c` (modos `paridad` y `noblock`); la segunda,
`MPI_Sendrecv`, la escribes tú en la práctica guiada.

```
$ mpirun -np 2 ./cross_exchange_fixed paridad 1000000
rango 1: intercambio correcto con rango 0 (n=1000000, recibidos=1000000, modo=paridad)
rango 0: intercambio correcto con rango 1 (n=1000000, recibidos=1000000, modo=paridad)

$ mpirun -np 2 ./cross_exchange_fixed noblock 1000000
rango 1: intercambio correcto con rango 0 (n=1000000, recibidos=1000000, modo=noblock)
rango 0: intercambio correcto con rango 1 (n=1000000, recibidos=1000000, modo=noblock)
```

**Pausa 6.** En la corrección por paridad, ¿qué pasa si el número de procesos es impar y las parejas son
vecinos en un anillo (rango 4 con rango 0, por ejemplo)?

<details><summary>Respuesta</summary>
Depende de cómo se organice el intercambio. Si cada <strong>pareja</strong> intercambia en las dos
direcciones a la vez (par: <code>Send</code> y <code>Recv</code> con su vecino derecho; impar:
<code>Recv</code> y <code>Send</code> con su izquierdo), el 4 y el 0 son ambos pares: los dos hacen
<code>Send</code> primero el uno hacia el otro y vuelve el problema. Comprobado: con <code>-np 5</code> y
n = 10⁶ se cuelga; con <code>-np 4</code> termina. La paridad por parejas solo funciona cuando toda pareja
es (par, impar). Si en cambio se organiza por <strong>corrimientos</strong> (todos envían a la derecha y
reciben de la izquierda; los pares hacen <code>Send→Recv</code> y los impares <code>Recv→Send</code>), sí
termina con cualquier número de procesos: el 0 envía al 1 (impar, que ya está recibiendo) y solo después
recibe del 4, así que el 0 y el 4 nunca se envían el uno al otro al mismo tiempo.
<code>MPI_Sendrecv</code> te ahorra ese análisis. Lo compruebas en la fase Crear.
</details>

## 8. Qué llevarte

1. `count` en `MPI_Recv` es capacidad; lo recibido se pregunta con `MPI_Get_count`. Recibir de más es error.
2. `MPI_Send` promete que tu búfer es reutilizable al regresar; **no** promete que el otro ya recibió, ni
   que regresa antes de que el otro reciba. Diseña para el peor caso.
3. Dos `Send` cruzados son un interbloqueo en potencia. Paridad, `MPI_Sendrecv` o no bloqueantes.
