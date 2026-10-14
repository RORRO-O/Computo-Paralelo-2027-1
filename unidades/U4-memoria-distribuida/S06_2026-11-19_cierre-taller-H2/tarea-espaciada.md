> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad IV · Sesión S06 · jueves 19 de noviembre de 2026 · 10:30–12:00 · Salón 3208

# S06 · Tarea espaciada (20–40 minutos)

**Entrega.** Carpeta `tareas/U4-S06/` en el repositorio de tu equipo, con `respuestas.md` (una sección por
integrante, con tu usuario de Git) y los `.c` del ejercicio 1, antes del **lunes 23 de noviembre de 2026, 10:30**
(inicio de U5·S01). Ese mismo lunes a las 10:30 cierra la etiqueta `H2` y el domingo 22 a las 23:59 vence la
Práctica 5: el ejercicio 3 de esta tarea **es** la última revisión de H2, no trabajo adicional. Se autocalifica con
las claves en `<details>` al inicio de la sesión del lunes (2 min); el profesor registra entrega, no acierto.

Esta tarea no tiene peso propio; el examen de práctica del jueves 3 de diciembre y el 10–20 % acumulativo del
Examen 3 toman ítems de aquí.

IA: verde para que te explique un mensaje de `mpirun` o la semántica de `MPI_Send`; amarillo (declarado) para que
revise tu `caza4_*_buggy.c` y te diga si el síntoma es reproducible; rojo para que corrija los cazadores por ti.

## 1. Del tema de hoy (20–25 min) · Terminar el cazador de errores: Investigar, Modificar y Crear

En clase hiciste Predecir y Ejecutar con los tres programas de `practica-guiada/`. Termina las tres fases que
faltan siguiendo `practica-guiada/README.md`, Parte 1:

a) **Investigar (I1–I4).** Escribe en `respuestas.md` el umbral de `n` en el que `caza1` empieza a colgarse y a qué
   cantidad de S02 corresponde; de dónde sale `suma=1200` en `caza2` con `n = 100`; la tabla de I3 para `caza3`
   con `n = 10`; y la asignación de los tres cazadores a las filas de la tabla de `notas-estudiante.md` §4, con el
   síntoma de las cuatro filas que no tienen cazador.

b) **Modificar (M1–M3), como elección justificada.** Para `caza1` hay tres correcciones válidas vistas en
   sesiones distintas: orden por paridad (S02), `MPI_Sendrecv` (S02/S04) y `MPI_Isend`/`MPI_Irecv` + `MPI_Wait`
   (S04). Elige **una**, escribe en el comentario del archivo por qué funciona para **cualquier** `n` y en una línea
   cuándo preferirías cada una de las otras dos (pista: ¿cuál sirve en un anillo con `p` impar sin tratar al rango 0
   distinto? ¿cuál deja hueco para calcular mientras viaja el mensaje?). Para `caza2` y `caza3` la corrección es
   única en espíritu; escribe la regla general en el comentario. Verifica con `make listo` (debe quedar `0 FAIL`
   salvo por la fase Crear).

c) **Crear.** Escribe `caza4_<tema>_buggy.c` con **uno** de los cuatro errores clásicos sin cazador (README, Fase
   5: etiquetas cruzadas, `Finalize` con mensajes pendientes, rango como índice sin verificar `p`, imprimir desde
   todos los rangos con verificación), ≤ 60 líneas, con la ficha sellada en el encabezado. Tu pareja lo caza y
   escribe `caza4_<tema>.c`. Si no coincidieron fuera de clase, cázalo tú mismo y dilo en `respuestas.md`.

Criterio de "listo": `make listo` termina con `0 FAIL` y la línea `LISTO:`; los tres comentarios citan la regla
(no solo el cambio); la ficha del `caza4` coincide con lo que la pareja encontró.

<details><summary>Para autoverificar</summary>

a) Umbral en la máquina de autoría: `n = 505` (4 040 bytes) termina y `n = 508` (4 064 bytes) se cuelga; es el
límite *eager* de 4 096 bytes (con cabecera) de S02 §4. `caza2`: los rangos 1–3 tienen `x` en ceros, así que solo
cuenta lo que suma el rango 0 con reparto cíclico: `0 + 4 + 8 + … + 96 = 4·(0 + 1 + … + 24) = 1200`; con `n = 8`,
`0 + 4 = 4`. `caza3` con `n = 10, p = 4`: tamaños enviados 3, 3, 2, 2 (rango 0 se queda con 3); el receptor espera
`n/p = 2` de cada uno; los rangos 1 y 2 mandan 3 → `MPI_ERR_TRUNCATE`; con `n = 8` todos mandan 2; con `n = 5`
el residuo entero se queda en el rango 0 (2, 1, 1, 1) y "funciona". Asignación: `caza1` → fila 1, `caza2` → fila 4,
`caza3` → fila 3. Sin cazador: fila 2 (cuelgue con cualquier `n`, sin error), fila 5 (cuelgue o pérdida silenciosa
al cerrar), fila 6 (fallo de segmentación o resultado equivocado con un `-np` distinto al previsto), fila 7 (orden
distinto entre corridas; `FAIL` de la comparación).

b) Las tres pasan `make listo` con `n = 10⁶` y `-np 4` y `-np 2`. Paridad: exige `p` par por parejas; en un anillo
impar falla (S02 §5) salvo que se organice por corrimientos. `MPI_Sendrecv`: la misma línea para todos, sin casos,
sirve en anillos de cualquier `p`; no deja hueco de cómputo. `Isend`/`Irecv` + `Wait`: deja hueco entre publicar y
esperar (S05: calcular el interior mientras viajan los halos); exige no tocar los búferes hasta el `Wait`. `caza2`:
el `MPI_Bcast` sale del `if`; regla: todos los procesos del comunicador llaman a la colectiva. `caza3`: `count =
block_size(n, size, r)` (misma fórmula que el emisor) o capacidad `n` + `MPI_Get_count` para avanzar `offset`.

c) La referencia de autoría (etiquetas cruzadas: `Send` con `tag 5`, `Recv` con `tag 6`) se cuelga 3 de 3 con
cualquier `n` y `-np`; corregido, `VERIFICACION OK`. `make listo` con las tres correcciones y un `caza4` dio
`37 PASS, 0 FAIL, 0 SKIP` y la línea `LISTO:`.
</details>

## 2. Intercalado, Unidades I y III (8 min) · Leer una tabla de *speedup* a mano

Con la tabla de `practica-guiada/ejemplo_mediciones_ok.csv` (`V1,1 = 2.405 s`; `V2`: 1 hilo 2.489 s, 2 hilos
1.288 s, 4 hilos 0.712 s, 8 hilos 0.715 s; máquina de 4 núcleos físicos), **sin correr el revisor**:

a) Calcula `S(p)` y `E(p)` para `p = 2, 4` y `f(p)` de Karp–Flatt para los dos. ¿`f` crece con `p`?
b) La fila `V2,1` es más lenta que `V1`. ¿Qué es esa diferencia y qué decisión de la V2 de tu proyecto podría
   explicar una diferencia mayor que 5 %?
c) Supón que el H1 de ese equipo estimó fracción secuencial `f_H1 = 0.03`. De las cuatro lecturas de H2 §2.3
   (Amdahl explica / sobrecarga creciente / perfil sobreestimó / superlineal), ¿cuál aplica y con qué número lo
   argumentas? Escribe la frase tal como iría en `reporte/H2.md`.

<details><summary>Para autoverificar</summary>

a) `S(2) = 2.405/1.288 = 1.867`, `E(2) = 0.934`, `f(2) = (1/1.867 − 1/2)/(1 − 1/2) = 0.071`. `S(4) = 3.378`,
`E(4) = 0.844`, `f(4) = (1/3.378 − 1/4)/(3/4) = 0.061`. `f` **no** crece (0.071 → 0.061): no hay sobrecarga que
crezca con los hilos hasta 4. (La fila de 8 da `f = 0.197`, pero es sobre-suscripción y no se usa para concluir.)
b) Es la **sobrecarga de OpenMP** con un hilo (crear el equipo, el `reduction`, la planificación): aquí 3.5 %. Más
de 5 % suele venir de `schedule(dynamic)` con *chunk* pequeño, de `atomic`/`critical` en el ciclo interno o de
haber cambiado el algoritmo respecto a V1 (en ese caso V1 debe actualizarse: protocolo §3).
c) `f(2) ≈ f(4) ≈ 0.06–0.07`, constante en `p` pero **el doble** de `f_H1 = 0.03`: la lectura es "Amdahl explica la
forma (f constante), pero el perfil de H1 subestimó la parte secuencial". Frase: "La fracción secuencial efectiva
es 0.06–0.07 para p = 2 y 4, estable, contra 0.03 estimada en H1; el perfil no contó la inicialización de los
arreglos y la reducción final, que medimos en 0.08 s de los 2.4 s (3.3 %), lo que cierra la diferencia." (Los
0.08 s son el dato que tu equipo tiene que medir; aquí ilustra el formato.)
</details>

## 3. Preparación de U5·S01, lunes 23 de noviembre (7 min) · Cerrar H2 y asomarse a la GPU

a) Pasa la lista de cotejo de autoevaluación de `proyecto/hitos/H2-avance-2.md` §5 con tu equipo y marca en
   `respuestas.md` qué ítems quedaron sin ✓ el jueves y quién los cierra antes del domingo. Corre
   `python3 practica-guiada/revisar_mediciones.py resultados/mediciones.csv --nucleos <físicos>` sobre tu CSV real y
   pega el `Resumen:`; cada `ERROR` debe desaparecer antes de la etiqueta y cada `AVISO` debe estar explicado en
   `reporte/H2.md`. La etiqueta se crea con `git tag -a H2 -m "Avance 2" && git push origin H2` antes de las 10:30.

b) Abre Google Colab con tu cuenta, crea un *notebook*, cambia el entorno de ejecución a GPU y ejecuta
   `!nvidia-smi`. Anota el modelo de GPU que te asignaron y la fecha. Si no obtienes GPU, anótalo también: el
   pre-laboratorio de la Práctica 6 (que se publica el lunes 23) exige verificar GPU en Colab **y** en Kaggle antes
   del martes 24 de noviembre, 08:30.

c) Conjetura de una línea: la hoja de datos de esa GPU dice que tiene miles de "núcleos CUDA" (la Tesla T4,
   2 560). ¿Crees que uno de esos núcleos equivale a un núcleo de tu laptop? Sí o no y una razón. Es la pregunta 5
   de la recuperación del lunes; "no sé" es válido.

<details><summary>Para autoverificar</summary>

a) Sin clave: el criterio es `0 errores` en el revisor y ningún ítem de H2 §5 sin dueño. Si el revisor marca `E1`
el lunes, el criterio 2 de la rúbrica de H2 baja a "En desarrollo" aunque todo lo demás esté bien.
b) En noviembre de 2026 Colab suele asignar Tesla T4 (16 GB) en la capa gratuita; Kaggle, T4 ×2 o P100. Lo que
importa es tener la captura con fecha: el hardware asignado cambia.
c) No: un "núcleo CUDA" es una unidad aritmética que ejecuta, con otras 31, la misma instrucción de un *warp*;
no tiene control de flujo propio ni caché grande. La GPU compensa con miles de hilos ligeros (modelo SIMT). Es la
idea errónea 22 del Anexo A; se trabaja el lunes.
</details>
