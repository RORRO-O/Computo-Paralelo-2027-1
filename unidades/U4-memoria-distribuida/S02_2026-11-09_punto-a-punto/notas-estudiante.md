> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S02 · lunes 9 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S02 · Notas: comunicación punto a punto con MPI

## 1. La idea

En memoria distribuida nada se comparte: cada proceso tiene sus variables y la única forma de que un dato
pase de un proceso a otro es un **mensaje**. Un mensaje es una **copia**: lo que el emisor haga después con
su variable no afecta al receptor. La comunicación **punto a punto** (*point-to-point*) es entre dos procesos:
uno envía (`MPI_Send`), otro recibe (`MPI_Recv`).

## 2. Firma completa

```c
int MPI_Send(const void *buf, int count, MPI_Datatype datatype, int dest,   int tag, MPI_Comm comm);
int MPI_Recv(void *buf,       int count, MPI_Datatype datatype, int source, int tag, MPI_Comm comm,
             MPI_Status *status);
```

| Parte | Argumentos | Notas |
|---|---|---|
| Contenido | `buf`, `count`, `datatype` | `count` en **elementos**, no bytes. En `MPI_Recv` es la **capacidad** del búfer |
| Sobre | `dest`/`source`, `tag`, `comm` | `tag`: entero ≥ 0 que elige tu programa para distinguir mensajes |
| Resultado | `status` (solo en `Recv`) | `status.MPI_SOURCE`, `status.MPI_TAG`; la cuenta se obtiene con `MPI_Get_count` |

Tipos básicos: `MPI_CHAR`, `MPI_INT`, `MPI_LONG`, `MPI_UNSIGNED`, `MPI_FLOAT`, `MPI_DOUBLE`, `MPI_BYTE`.
El tipo de C y el tipo MPI deben corresponder (`double` ↔ `MPI_DOUBLE`).

## 3. Emparejamiento (*matching*)

Una recepción acepta un mensaje cuando coinciden **comunicador**, **fuente** y **etiqueta**. Los comodines
`MPI_ANY_SOURCE` y `MPI_ANY_TAG` aceptan cualquiera; después se averigua cuál fue con `status`. Si no te
importa el `status`, pasa `MPI_STATUS_IGNORE`.

- La cuenta y el tipo **no** se usan para emparejar. Si llega más de lo que cabe: error `MPI_ERR_TRUNCATE`
  (Open MPI aborta). Si llega menos: normal; `MPI_Get_count(&status, MPI_INT, &n)` dice cuántos llegaron.
- Entre el mismo par (emisor, receptor), mismo comunicador, los mensajes que casan con la misma recepción
  llegan en el orden en que se enviaron (no se adelantan). Entre emisores **distintos** no hay orden.

## 4. Qué promete `MPI_Send` (y qué no)

`MPI_Send` regresa cuando **tu búfer se puede reutilizar**. Nada más. Eso puede ocurrir:

- **antes** de que el receptor llame a `MPI_Recv`, si la implementación copió el mensaje a un búfer interno
  (protocolo *eager*; Open MPI lo hace con mensajes chicos: en la máquina de autoría, menos de 4 096 bytes
  entre procesos de la misma máquina), o
- **después**, cuando el receptor ya está listo, si la implementación decidió no copiar (*rendezvous*;
  mensajes grandes).

Las dos conductas son válidas según el estándar. `MPI_Recv`, en cambio, siempre espera a que el mensaje
completo esté en tu búfer. Un programa es **seguro** si termina aun cuando todos sus `MPI_Send` bloqueen
hasta que exista la recepción. Un programa que solo funciona con mensajes chicos está **mal**, aunque hoy
funcione.

## 5. Interbloqueo (*deadlock*): tres patrones y tres soluciones

| Patrón | Qué pasa | Resultado real (Open MPI 4.1.6) |
|---|---|---|
| Intercambio cruzado: ambos `Send`, luego `Recv` | Con mensaje chico termina; con grande, los dos esperan en `Send` | n = 10 enteros termina; n = 1 000 000 se cuelga |
| Anillo donde **todos** hacen `Recv` primero | Nadie envía; no depende del tamaño | Se cuelga con 1 entero |
| Etiquetas (o fuente, o comunicador) que no coinciden | La recepción espera un mensaje que nadie manda | Se cuelga aun con n = 10 |

Soluciones al intercambio entre parejas:

```c
/* 1. Orden por paridad: siempre hay un receptor listo para cada emisor. */
if (rank % 2 == 0) { MPI_Send(...); MPI_Recv(...); } else { MPI_Recv(...); MPI_Send(...); }

/* 2. MPI_Sendrecv: envía y recibe en una sola llamada; MPI evita la espera circular. */
MPI_Sendrecv(send_buf, n, MPI_INT, partner, tag,
             recv_buf, n, MPI_INT, partner, tag, MPI_COMM_WORLD, &status);

/* 3. No bloqueante (detalle el jueves 12 de noviembre, S04): iniciar ambas, esperar ambas. */
MPI_Irecv(recv_buf, n, MPI_INT, partner, tag, MPI_COMM_WORLD, &rreq);
MPI_Isend(send_buf, n, MPI_INT, partner, tag, MPI_COMM_WORLD, &sreq);
MPI_Wait(&rreq, &status);  MPI_Wait(&sreq, MPI_STATUS_IGNORE);
```

En un anillo, alguien debe romper la simetría: el rango 0 envía primero y los demás reciben primero. Con
`MPI_Sendrecv` todos pueden ejecutar la misma línea y no hace falta tratar al 0 distinto. La paridad **por
parejas** (cada par intercambia todo con un vecino a la vez) falla cuando dos vecinos tienen la misma paridad
(anillo con número impar de procesos: el 4 y el 0; comprobado con `-np 5` y n = 10⁶). Organizada **por
corrimientos** (todos envían a la derecha y reciben de la izquierda; pares `Send→Recv`, impares `Recv→Send`)
termina con cualquier número de procesos ≥ 2.

## 6. Cuánto cuesta un mensaje

Modelo: **T(m) ≈ α + m / β**, con α la latencia (costo fijo por mensaje) y β el ancho de banda. Medido con
`ping_pong` entre dos procesos de la misma máquina (mediana de 5, una pasada de calentamiento; VM compartida
de 4 núcleos):

| bytes | latencia de ida (µs) | ancho de banda (MB/s) |
|---|---|---|
| 0 | 0.19 | — |
| 8 | 0.21 | 39 |
| 512 | 1.51 | 339 |
| 4 096 | 6.09 | 672 |
| 32 768 | 12.5 | 2 617 |
| 1 048 576 | 461 | 2 277 |
| 4 194 304 | 873 | 4 803 |

Lo que importa no son los dígitos (en otra corrida la latencia de 0 bytes fue 0.48 µs y el ancho de banda a
4 MiB bajó a 1.0 GB/s) sino los órdenes de magnitud: un mensaje de 8 bytes cuesta décimas de microsegundo;
uno de 1 MiB, cientos de microsegundos; es decir, **un** mensaje de 1 MiB cuesta lo mismo que unos 2 000
mensajes de 8 bytes, y 8 bytes enviados en 2 000 mensajes mueven 16 KB, no 1 MiB. Entre máquinas conectadas
por red, α sube a decenas de microsegundos (Ethernet) y β baja: uno o dos órdenes de magnitud peor.
Consecuencia de diseño: **agrupa** datos en pocos mensajes grandes; la comunicación no es gratis (idea
errónea 21).

## 7. Ejemplo resuelto en ocho líneas (`status_demo.c`)

Cada rango *r* ≥ 1 envía *r* + 2 enteros con etiqueta 10·*r* al rango 0. El rango 0 recibe `size − 1` veces con
`MPI_ANY_SOURCE`, `MPI_ANY_TAG` y capacidad 64, y por cada mensaje imprime `status.MPI_SOURCE`,
`status.MPI_TAG` y `MPI_Get_count`. Con `-np 4` una corrida real dio el orden 3, 2, 1 (otra puede dar
1, 2, 3). Si la capacidad se baja a 4, el mensaje de 5 elementos aborta con `MPI_ERR_TRUNCATE`. Si el
emisor escribe `buf[0] = -1` después de su `MPI_Send`, el rango 0 sigue recibiendo el valor original: el
mensaje ya era una copia.

## 8. Errores frecuentes

1. Creer que el otro proceso "ve" una variable que modificaste (idea errónea 16). Solo ve lo que le enviaste.
2. Creer que `MPI_Send` siempre regresa de inmediato, o que siempre espera al receptor (idea errónea 17).
   Ninguna de las dos; diseña para que funcione en ambos casos.
3. `count` de `MPI_Recv` menor que lo enviado → `MPI_ERR_TRUNCATE`. Capacidad ≥ lo que puede llegar.
4. Pasar bytes en `count` (`sizeof(buf)`) en lugar de elementos, o `&buf` en lugar de `buf` para un arreglo.
5. Etiquetas que no coinciden entre `Send` y `Recv`: el receptor espera para siempre, sin mensaje de error.
6. Dos `Send` cruzados "que funcionaron en la prueba" con datos chicos. Se cuelgan con los datos reales.
7. Medir latencia con una sola corrida o sin calentamiento. Protocolo: mediana de ≥ 5, reportar mín/máx.
8. Muchos mensajes pequeños en un ciclo interno. Cada uno paga α; agrúpalos.

## 9. Para saber más

- MPI Forum, *MPI: A Message-Passing Interface Standard*, versión 4.1 (mpi-forum.org/docs), capítulo 3
  "Point-to-Point Communication": 3.4 *Communication Modes*, 3.5 *Semantics of Point-to-Point
  Communication* y 3.10 *Send-Receive*.
- Documentación de Open MPI (www.open-mpi.org/doc): páginas `MPI_Send(3)`, `MPI_Recv(3)`, `MPI_Sendrecv(3)`,
  `MPI_Get_count(3)`; y `ompi_info --param btl vader --level 4` para ver el límite *eager* de tu instalación.
- P. Pacheco y M. Malensek, *An Introduction to Parallel Programming*, 2.ª ed., capítulo 3
  (*Distributed-Memory Programming with MPI*): secciones sobre `MPI_Send`/`MPI_Recv`, semántica y seguridad
  de los programas MPI, y medición de tiempos.
