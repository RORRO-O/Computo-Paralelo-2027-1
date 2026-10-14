# Lista de cotejo entre pares para el ensayo de defensa

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Ensayo de defensa · lunes 7 de diciembre de 2026 · 10:30–12:00 · Salón 3208 · sesión C1 (taller) · 12 ítems sí/no · 5 minutos por equipo evaluado · versión 1.0 · 14 de octubre de 2026

## Cómo se usa

1. **Parejas de equipos.** El profesor forma las parejas al inicio de la sesión (equipos con número consecutivo en el
   orden sorteado, o como indique). Cada pareja trabaja en paralelo con las demás.
2. **Ronda completa (34 minutos por pareja).** El equipo A ensaya sus 12 minutos completos, con demo desde su clon de
   `entrega-final`, exactamente como el jueves 10 de diciembre; el equipo B observa con esta hoja y el cronómetro. Al terminar,
   B tiene **5 minutos**: 3 para hacer una pregunta del banco a cada integrante de A (ítem 12) y 2 para marcar lo que
   falte y leer en voz alta los ítems con **no**. Después se intercambian los papeles.
3. **Durante los 12 minutos** el equipo observador anota el tiempo real de cada bloque (tabla de tiempos) y va marcando
   los ítems 1–11. Solo se marca **sí** si se vio o se oyó; "casi" es **no**. No se opina sobre el gusto: se marca si está
   o no está.
4. **Después del ensayo** cada equipo se lleva su hoja marcada por el otro y corrige antes del jueves 10 de diciembre
   (o del lunes 14, según el sorteo). La hoja no se entrega ni se califica: es retroalimentación entre pares
   (`docs/metodo/01-marco-pedagogico.md`, P10).
5. Cada ítem dice qué criterio de `rubrica-defensa.md` baja si queda en **no**.

Equipo evaluado: `cp-6bm1-equipo__` · Equipo observador: `cp-6bm1-equipo__` · Hora de inicio del ensayo: `__:__`

## Tiempos por bloque (los anota el observador)

| Bloque | Previsto | Inició en | Terminó en | Duró | Dentro de ± 30 s |
|---|---|---|---|---|---|
| 1 Problema | 0:00–1:00 | | | | sí / no |
| 2 Diseño y decisiones | 1:00–4:00 | | | | sí / no |
| 3 Resultados y análisis | 4:00–8:00 | | | | sí / no |
| 4 Qué falló y qué aprendieron | 8:00–10:00 | | | | sí / no |
| 5 Demo en vivo | 10:00–12:00 | | | | sí / no |
| **Total** | **≤ 12:00** | | | | sí / no |

## Los 12 ítems

| # | ¿Sí o no? | Qué debe haberse visto u oído | Criterio |
|---|---|---|---|
| 1 | sí / no | En el primer minuto se dijo **qué se calcula** (una frase), `n` y semilla, y `T(1)` de V1 con la CPU | D1 |
| 2 | sí / no | El diagrama de Foster es **propio** y se mostró la tabla tarea → datos que toca → dependencias **para este problema**; se dijo qué cambió en el mapeo de V2 a V3 | D1 |
| 3 | sí / no | Se presentaron **dos decisiones con alternativas medidas** y las medianas estaban en pantalla (no solo "elegimos X") | D1 |
| 4 | sí / no | La gráfica de *speedup* tiene **línea ideal `S = p`**, ejes con unidades y barras mín–máx; de ella se leyeron `S(p)` y `E(p)` | D2 |
| 5 | sí / no | Se dijo que `T(1)` es **V1** (no V2 con 1 hilo), se dio `f` de Karp–Flatt por `p` y su tendencia, y el *speedup* máximo de Amdahl con la fracción **medida** | D2 |
| 6 | sí / no | V3 se presentó **sin y con transferencias**, contra la V1 **de la misma máquina**, con modelo de GPU y fecha, y con el porcentaje de transferencias | D2 |
| 7 | sí / no | Se dijo **dónde deja de escalar** V2 y una **causa verificable** con experimento o número (no "por la laptop"), y se comparó la predicción previa con el resultado | D2 |
| 8 | sí / no | Qué falló: ≥ 2 entradas de bitácora con **cómo se detectó** y la causa; una medición descartada; ≥ 2 preguntas concretas de "qué no entendemos todavía"; la línea "qué nos dijo la IA que resultó estar mal" | D2 |
| 9 | sí / no | La demo corrió desde un **clon con la etiqueta visible** (`git describe` → `entrega-final`, `git status` limpio), `make test` terminó con código 0, se corrió V1 y V2 con 1 y con `p` hilos con el mismo `checksum`, y se mostró el *notebook* ejecutado; todo en ≤ 2 minutos y tecleado por quien el observador designó al minuto 10 | D3 |
| 10 | sí / no | Cada bloque quedó dentro de ± 30 s de lo previsto y el total no pasó de 12:00 (tabla de tiempos) | D1 |
| 11 | sí / no | **Todos** hablaron ≥ 2 minutos; nadie leyó las diapositivas ni un papel; ≤ 8 diapositivas legibles desde el fondo del salón (≥ 18 pt) | D1 |
| 12 | sí / no | Preguntas: el observador hizo a **cada integrante** una pregunta del banco (`banco-preguntas-individuales.md`, una de línea sobre su parte firmada o una de tema) y la respondió **sin ayuda** en ≤ 40 s, nombrando el elemento concreto, qué hace, por qué y qué pasaría si cambia | D4 |

Total de **sí**: `__ / 12`

## Retroalimentación del equipo observador (se lee en voz alta, 2 minutos)

- Lo más claro de la exposición (una frase): ______________________________________________
- Lo que no entendimos o no vimos (ítems con **no**, por número): ______________________________________________
- Una pregunta que le haríamos al equipo el jueves y que hoy no supo responder: ______________________________________________
- El número que dijeron y que no encontramos en su tabla (si lo hubo): ______________________________________________

## Qué hace el equipo evaluado con esta hoja

| Ítem en **no** | Qué corregir antes de la defensa |
|---|---|
| 1, 2, 3, 11 | Reescribir las diapositivas 1–4: una idea por diapositiva, números en pantalla, repartir quién habla |
| 4, 5, 6, 7 | Regenerar la figura con `graficar_proyecto.py` (línea ideal y mín–máx); llenar el bloque 3 de la plantilla de `guion-defensa.md` §7 con los números del CSV |
| 8 | Elegir las entradas de bitácora con herramienta de detección; escribir las preguntas abiertas con su experimento |
| 9 | Rehacer el clon limpio, correr `verificar_entrega.sh` sobre él, ensayar la demo con cada integrante tecleando |
| 10 | Recortar contenido del bloque que se pasó; no hablar más rápido |
| 12 | Cada integrante practica el banco completo en voz alta con el repositorio abierto |
