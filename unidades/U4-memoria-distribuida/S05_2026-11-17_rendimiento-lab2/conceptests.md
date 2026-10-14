> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S05 · martes 17 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# S05 · ConcepTests (instrucción entre pares)

Secuencia fija: voto individual (1 min) → discusión en parejas (2 min) → revoto → explicación. Si el primer
voto supera 80 % de aciertos se salta la discusión; si queda por debajo de 30 % se reexplica antes de discutir.
Los porcentajes esperados son estimaciones para decidir el ritmo; se anotan los reales en `plan-sesion.md`.

## CT1 · ¿Más procesos para un problema pequeño? (minuto ~25, al cerrar el modelo de costo)

Jacobi 1D con **n = 1 000 puntos**. El cómputo cuesta t_c = 1 ns por punto por iteración. Cada mensaje de halo
(8 bytes) cuesta α = 0.5 µs; cada proceso interior envía y recibe de dos vecinos (cuenta 2α por iteración).
¿Qué *speedup* esperas con **p = 4** procesos respecto a la versión secuencial?

- **A.** ≈ 4: el trabajo se reparte entre 4 y los mensajes son de solo 8 bytes.
- **B.** ≈ 3.3, igual que con n = 1 000 000: el *speedup* es una propiedad del programa, no del tamaño.
- **C.** < 1: con 4 procesos tarda **más** que con 1.
- **D.** Exactamente 1: la comunicación no cuenta en el tiempo porque la hacen las tarjetas de red, no la CPU.

<details><summary>Respuesta y origen de los distractores</summary>

**Respuesta: C.** Por iteración: T₁ = 1 000 × 1 ns = 1.0 µs. T₄ = 250 × 1 ns + 2 × 0.5 µs = 0.25 + 1.0 =
1.25 µs. S = 1.0 / 1.25 = **0.8**. La comunicación (1 µs) es cuatro veces el cómputo local (0.25 µs).

- A → idea errónea **1** ("más hilos/procesos siempre es más rápido") y **21** ("la comunicación es gratis
  comparada con el cómputo": "solo son 8 bytes" olvida que el costo de un mensaje pequeño es la latencia).
- B → variante de **21/6**: el *speedup* depende de n porque la razón cómputo/comunicación depende de n.
  (Idea nueva para el catálogo: "el *speedup* es una constante del programa".)
- D → idea **21** en su forma literal: la comunicación sí consume tiempo de pared; el proceso espera en
  `Waitall`.

**Porcentaje esperado en el primer voto:** 40–50 % (B es el distractor fuerte: quien acaba de ver la gráfica
con n grande generaliza).

**Guion de discusión (3 líneas).** "Calculen T₁ y T₄ por iteración con los números dados; escriban los dos
sumandos de T₄ por separado." Después: "¿Cuál de los dos sumandos de T₄ cambia si n pasa a 1 000 000? ¿Cuál no
cambia?" Cierre: "La comunicación por iteración es constante; el cómputo es n/p. Por eso hay un n mínimo a
partir del cual conviene paralelizar: lo van a calcular en la fase Crear."
</details>

## CT2 · Leer una tabla de escalabilidad (minuto ~30, antes de arrancar la práctica)

Un equipo entrega esta tabla de Jacobi 1D:

| p | n | mediana (s) |
|---|---|---|
| 1 | 1 000 000 | 1.00 |
| 2 | 2 000 000 | 1.05 |
| 4 | 4 000 000 | 1.10 |

¿Cuál es la conclusión correcta?

- **A.** Escalabilidad fuerte mala: el *speedup* es 1.00/1.10 ≈ 0.9 con 4 procesos.
- **B.** Escalabilidad débil buena: eficiencia débil 1.00/1.10 ≈ 0.91 con 4 procesos.
- **C.** No se puede concluir nada porque cambiaron n entre configuraciones.
- **D.** El *speedup* es 4 × 1.00 / 1.10 ≈ 3.6, así que la escalabilidad **fuerte** es casi perfecta.

<details><summary>Respuesta y origen de los distractores</summary>

**Respuesta: B.** n/p es constante (1 000 000 por proceso): es un experimento de escalabilidad **débil**. La
métrica es la eficiencia débil `T(1, n) / T(p, p·n)` = 1.00/1.10 ≈ 0.91; el *speedup* escalado (Gustafson)
es p × 0.91 ≈ 3.6.

- A → idea **6** ("fuerte y débil son sinónimos"): aplica la fórmula de escalabilidad fuerte a datos con n
  variable.
- C → el protocolo prohíbe cambiar n **sin declararlo**; aquí está declarado en la tabla. Confunde la regla
  con la definición de escalabilidad débil (idea 6).
- D → el número es correcto (es el *speedup* escalado) pero llamarlo "fuerte" es la idea **6**: en
  escalabilidad fuerte el problema no crece.

**Porcentaje esperado en el primer voto:** 55–65 %.

**Guion de discusión.** "Miren la columna n: ¿qué se mantuvo fijo, n o n/p?" "¿Qué pregunta responde este
experimento: 'cuánto más rápido resuelvo el mismo problema' o 'qué tan grande puedo resolver en el mismo
tiempo'?" Cierre: "Fuerte: n fijo, se reporta *speedup*. Débil: n/p fijo, se reporta eficiencia débil. Las dos
tablas van en la Parte D de la P5, con la etiqueta correcta."
</details>

## CT3 · El dato con 8 procesos (minuto ~75, en el punto de control)

En una laptop de **4 núcleos físicos**, un equipo mide Jacobi 1D con n fijo: T(4) = 1.2 s y, con
`mpirun --oversubscribe -np 8`, T(8) = 2.1 s. ¿Qué concluye?

- **A.** MPI escala mal más allá de 4 procesos; conviene usar OpenMP a partir de ahí.
- **B.** A partir de p = 8 la comunicación domina sobre el cómputo.
- **C.** Nada sobre la escalabilidad del programa: 8 procesos compiten por 4 núcleos. El dato se reporta
  aparte, etiquetado como sobre-suscrito.
- **D.** El dato es válido como cualquier otro y va en la curva de *speedup* junto con p = 1, 2, 4.

<details><summary>Respuesta y origen de los distractores</summary>

**Respuesta: C.** Con 8 procesos en 4 núcleos cada proceso recibe la mitad de un núcleo; además, los procesos
MPI esperan haciendo sondeo activo (*busy polling*), así que un proceso que espera un halo le quita CPU al
que debería producirlo. El tiempo sube por la **sobre-suscripción**, no por el algoritmo. Se mide, se
etiqueta (`mpi_oversub` en el CSV) y se discute aparte; no entra en la conclusión sobre escalabilidad.

- A → generaliza desde un dato distorsionado; además mezcla con la idea de que el híbrido "arregla" la
  escalabilidad (no se ha medido nada que lo sustente).
- B → idea **21** mal aplicada: la comunicación por iteración no cambió (sigue siendo 2 mensajes de 8
  bytes); lo que cambió es cuánta CPU tiene cada proceso.
- D → idea **20** ("más procesos que núcleos siempre está bien"): el protocolo exige reportarlo aparte.

**Porcentaje esperado en el primer voto:** 60–70 % (ya lo vieron en su propio script).

**Guion de discusión.** "¿Cuántos núcleos tiene cada proceso con p = 8? ¿Qué hace un proceso MPI mientras
espera en `Waitall`?" "Si el programa fuera perfecto, ¿cuánto esperarían que tardara con 8 procesos en 4
núcleos?" Cierre: "Sobre-suscribir sirve para probar correctitud con más rangos de los que tienes; no sirve
para medir. Y si lo reportan, lo etiquetan."
</details>

---

## Registro de la sesión (llenar en clase)

| ConcepTest | % primer voto | % revoto | Distractor más votado | Nota |
|---|---|---|---|---|
| CT1 | | | | |
| CT2 | | | | |
| CT3 | | | | |
