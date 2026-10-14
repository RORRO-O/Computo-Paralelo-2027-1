> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S01 · jueves 5 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S01 · Exit ticket

Individual, 5 minutos, en papel o en el formulario del grupo. Escribe tu número de lista, no tu nombre.
Se revisa el mismo día; el error más frecuente abre la sesión del lunes 9 de noviembre.

## Pregunta 1 (conceptual)

Dos procesos MPI corren en la **misma laptop**. El rango 1 ejecuta `a[0] = 5;` sobre su arreglo `a`. Después,
ambos pasan por `MPI_Barrier(MPI_COMM_WORLD)`. ¿Qué valor tiene `a[0]` en el rango 0? ¿Qué tendría que
pasar para que el rango 0 se enterara del `5`? (2–3 líneas)

## Pregunta 2 (aplicación)

Un arreglo de `n = 23` elementos (índices 0 a 22) se reparte entre `p = 5` procesos.

- (a) Por **bloques con residuo** (los primeros `n % p` rangos reciben un elemento extra): ¿qué índices toma
  el rango 3?
- (b) Por **reparto cíclico**: ¿qué índices toma el rango 3?
- (c) Escribe el comando para ejecutar `./suma_distribuida 23` con 5 procesos en una laptop de 4 núcleos.

## Confianza

¿Qué tan seguro estás de tus respuestas? (1 = adiviné · 2 = dudo · 3 = casi seguro · 4 = seguro) ______

¿Qué te quedó menos claro de la sesión de hoy? (una línea) _______________________________________

## Clave

<details>
<summary>Mostrar clave</summary>

**1.** `a[0]` en el rango 0 tiene el valor que tenía antes (el que el rango 0 le haya dado; si no lo inicializó,
basura). Cada proceso tiene su propio arreglo `a` en su propio espacio de direcciones, aunque corran en la misma
máquina; la barrera solo hace que ambos esperen a que el otro llegue, no copia datos. Para que el rango 0 se
entere, el rango 1 tiene que **enviarle** el valor (`MPI_Send`) y el rango 0 **recibirlo** (`MPI_Recv`). Ataca
la idea errónea 16 (y 16b: "la barrera sincroniza memoria").

**2.** `q = 23 / 5 = 4`, `r = 23 % 5 = 3`. Rangos 0, 1 y 2 toman 5 elementos; rangos 3 y 4 toman 4.

- (a) `start = 3·4 + min(3, 3) = 15`, `count = 4` → índices **15, 16, 17, 18**.
  (Comprobación: rango 0: 0–4, rango 1: 5–9, rango 2: 10–14, rango 3: 15–18, rango 4: 19–22. Suman 23.)
- (b) `3, 3+5, 3+10, 3+15` → **3, 8, 13, 18** (el siguiente, 23, ya no existe).
- (c) `mpirun -np 5 ./suma_distribuida 23`. Como hay más procesos que núcleos, Open MPI exige
  `--oversubscribe`: `mpirun --oversubscribe -np 5 ./suma_distribuida 23`. Se acepta cualquiera de las dos si
  se menciona la sobre-suscripción.

**Clasificación rápida (montones):** *bien* = 1 correcta con la palabra "enviar/mensaje" y 2(a) y 2(b)
correctas; *parcial* = falla solo 2(a) o solo 2(b); *mal* = cree que el rango 0 ve el 5, o falla 2(a) y 2(b).

</details>
