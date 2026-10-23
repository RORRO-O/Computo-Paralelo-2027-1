> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad III · Sesión S08 · lunes 19 de octubre de 2026 · 10:30–12:00 · Salón 3208

# S08 · Exit ticket (5 minutos, individual)

Escribe tu número de lista. Se recoge al salir. Cuenta por participación (3 % del parcial junto con la
recuperación); el profesor lo revisa hoy mismo y abre la sesión del martes 20 de octubre con el error más
frecuente.

## 1. Conceptual

Un compañero te dice: *"Yo siempre pongo `schedule(dynamic)`; reparte mejor y nunca pierde."*
Describe **un caso concreto en el que pierde** y explica en ≤ 3 líneas **por qué** pierde.

## 2. Aplicación corta

Un ciclo recorre las 1000 filas de una imagen. Las filas del centro tardan unas 10 veces más que las de los
bordes. Hay 4 hilos.

a) Escribe la cláusula `schedule(...)` que usarías (con *chunk*, si aplica) y una razón de una línea.

b) Si en lugar de eso el ciclo llevara `schedule(static, 3)` con n = 16 iteraciones y 4 hilos, ¿qué hilo
ejecuta la iteración `i = 13`?

## 3. Confianza y duda

- ¿Qué tan seguro estás de tus respuestas? (1 = nada, 4 = muy seguro): ____
- ¿Qué te quedó **menos** claro hoy? (una frase):

---

<details>
<summary>Clave (para el profesor; se publica después de la sesión)</summary>

**1.** Cualquier ciclo con iteraciones **uniformes y baratas**: p. ej. el núcleo `uniform` de la práctica
(8 000 000 iteraciones de ~50 ns). `dynamic` sin *chunk* equivale a `dynamic,1`: cada iteración exige una
operación atómica sobre un contador compartido, con un costo comparable al de la iteración misma, de modo que
el tiempo total se dispara (en la tabla de la sesión, `dynamic` quedó más lento que la versión secuencial).
`static` reparte una sola vez y no paga nada en ejecución. Se acepta también: "con *chunk* muy pequeño en
cualquier ciclo barato". No se acepta: "porque `static` siempre es mejor" (es la idea errónea opuesta).
Ataca la idea errónea 11. Clasificación literal: **bien** = nombra una carga uniforme o barata **y** el costo
por pedido (contador compartido / operación atómica por *chunk*); **parcial** = solo una de las dos cosas, o un
caso correcto sin la causa; **mal** = ninguna, o "`static` siempre es mejor".

**2a.** Carga concentrada en el centro → `schedule(dynamic, c)` con *chunk* pequeño (2–8 filas) o
`schedule(static, 1)` (cíclico: cada hilo recibe filas de todas las zonas). Razón: con `static` en bloques,
los dos hilos del centro cargan casi todo el trabajo y los otros dos esperan en la barrera. `guided` es
discutible: sus primeros *chunks* son grandes (~n/4 filas) y pueden caer completos en la zona pesada; se
acepta si se justifica con *chunk* pequeño y se reconoce ese riesgo. Nivel "bien": nombra la política **y** la
conecta con la forma de la carga. Nivel "parcial": política razonable sin razón, o `dynamic` "porque sí".

**2b.** Con `static,3` los bloques son {0,1,2}, {3,4,5}, {6,7,8}, {9,10,11}, {12,13,14}, {15} y se reparten
cíclicamente: bloques 0–3 a los hilos 0–3, bloque 4 otra vez al hilo 0, bloque 5 al hilo 1. La iteración 13
está en el bloque 4 → **hilo 0**. Errores típicos y qué revelan: "hilo 3" = pensó en `static` sin *chunk*
(bloques contiguos de 16/4 = 4); "hilo 1" = pensó en `static,1` (13 mod 4). Cada respuesta equivocada
apunta a una confusión distinta: anotarla para la recuperación de S09.

**3.** Se usa para la calibración: comparar la confianza declarada con el resultado de 1 y 2. Clasificar
en tres montones (bien / parcial / mal); umbral de alerta: > 30 % en "mal".

</details>
