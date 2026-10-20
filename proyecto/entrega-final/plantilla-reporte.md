# Plantilla del reporte final (PDF, 8–12 páginas)

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Entrega final · lunes 7 de diciembre de 2026, 10:30 · 30 puntos (`rubrica-reporte.md`) · versión 1.1 · 20 de octubre de 2026

## 1. Reglas de formato

| Regla | Valor |
|---|---|
| Extensión | **8 a 12 páginas en total**, portada y referencias incluidas. Sin anexos. Más de 12: se leen solo las primeras 12; R1 baja a En desarrollo con 7 o 13 páginas y a Insuficiente con menos de 7 o más de 13 |
| Archivo | `reporte/reporte.pdf` en el repositorio. Fuente (Markdown, LaTeX, Word) opcional, junto al PDF |
| Tipografía y página | 11 pt, interlineado sencillo, márgenes de 2.5 cm, carta. Columnas: una |
| Secciones | Las 13 de abajo, **en este orden y con estos títulos**. Se pueden agregar subsecciones; no se quitan secciones |
| Tablas y figuras | Numeradas (Tabla 1, Figura 1…), con pie que dice **qué comando y qué archivo** las generan. Ejes con unidades. Legibles en blanco y negro |
| Código | Solo fragmentos clave, ≤ 15 líneas cada uno, como texto con fuente monoespaciada (nunca capturas de pantalla), con ruta y líneas del archivo original |
| Números | Todos salen de `resultados/*.csv`. Tres decimales para *speedup* y eficiencia; segundos con cuatro |
| Idioma | Español. Términos técnicos con el inglés entre paréntesis la primera vez |
| Nombres | Los integrantes aparecen en la portada y en la sección 11, nunca en nombres de archivo |

## 2. Qué va y qué no va en cada sección

La columna "Extensión" suma entre 9¼ y 11 páginas; es una guía, no un requisito por sección. La columna "Rúbrica" dice qué criterio
de `rubrica-reporte.md` la califica.

| # | Sección (título obligatorio) | Qué va | Qué NO va | De dónde sale | Extensión | Rúbrica |
|---|---|---|---|---|---|---|
| 0 | **Portada** | Título del problema; "Proyecto integrador · Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1"; número de equipo y URL del repositorio; integrantes (nombre completo y usuario de GitHub); *commit* etiquetado `entrega-final`; fecha | Logotipos grandes, índice, dedicatorias | README §6 y §8 | 1 p. | R1 |
| 1 | **Resumen** | ≤ 10 líneas: problema en una frase; `n` y tipo de datos; hardware de CPU y GPU; mejor *speedup* de V2 y con cuántos hilos; *speedup* de V3 con y sin transferencias; qué lo limita (una frase) | Motivación histórica, definiciones, "aprendimos mucho" | Tabla 1, Tabla 2, `entorno*.txt` | ¼ p. | R1 |
| 2 | **Problema y datos** | Qué se calcula y para qué sirve; entrada (origen, tamaño, formato, semilla, cómo obtenerla o regenerarla); salida y **cómo se verifica** que es correcta (checksum, comparación con V1, solución conocida, tolerancia); por qué es paralelizable (dependencias, 3–5 líneas); tiempo de V1 con el `n` de trabajo | Historia del algoritmo, copiar la propuesta H0 completa, datos sin semilla | README §1, `comun/problema.h` | ¾ p. | R2 |
| 3 | **Diseño por el método de Foster** | Partición (qué es una tarea, cuántas hay); comunicación (qué datos comparten, patrón: local/global, estructurado/no); aglomeración (cómo se agrupan y por qué ese tamaño); mapeo (a hilos en V2; a bloques e hilos CUDA en V3; qué cambió entre ambos). Un diagrama **propio** y una tabla "tarea → datos que toca → dependencias" | Definiciones de libro sin aplicar; "aglomerar = juntar todo"; diagramas tomados de Internet | H1 corregido, código de V2 y V3 | 1 p. | R2 |
| 4 | **V1: versión secuencial y línea base** | Estructura del programa; **perfilado**: qué fracción del tiempo va a qué parte y con qué se midió (`gprof`, `perf`, cronómetros por sección); fracción secuencial que se deriva (lo que no se va a paralelizar); tamaño por defecto y por qué `T(1)` ≥ 1 s | El código completo; "se implementó en C" sin más | `v1/main.c`, bitácora | ¾ p. | R3 |
| 5 | **V2: memoria compartida (OpenMP)** | Qué región se paraleliza y por qué esa; alcance de variables; `schedule` y su razón (medición o carácter de las iteraciones); reducciones y sincronización; cómo se verificó que no hay carreras (ThreadSanitizer, razonamiento); fragmento clave comentado | Listado completo, explicación de qué es OpenMP, capturas de terminal | `v2/main.c`, bitácora | ¾–1 p. | R3 |
| 6 | **V3: GPU** | Tecnología (CUDA C, Numba CUDA o CuPy) y por qué; mapeo hilo→dato; tamaño de bloque y la comparación que lo justifica; memoria (global, compartida, coalescencia: qué se hizo o por qué no aplica); transferencias (cuándo suben y bajan los datos); comprobación de errores; fragmento del *kernel*; cómo se verificó contra V1 **en la misma sesión** | Explicar la arquitectura de la GPU en general; omitir qué GPU se usó | `v3/kernel.cu` (o `.py`), *notebook* | ¾–1 p. | R3 |
| 7 | **Metodología de medición** | Hardware de CPU (modelo, núcleos físicos/lógicos, RAM, SO) y GPU (modelo, memoria, driver, **fecha**); compiladores, versiones y banderas; protocolo: calentamiento, repeticiones, mediana con mín/máx, qué región se cronometra, reloj; `n`, semilla, lista de hilos; comandos exactos que reproducen cada tabla; **predicción previa** citada de la bitácora con fecha | "Se midió varias veces en una laptop"; promedios; medir con `-O0` | `resultados/entorno.txt`, `entorno_gpu.txt`, README §2–§3 | ¾ p. | R4 |
| 8 | **Resultados** | **Tabla 1**: V1 y V2 por hilos (mediana, mín, máx, *speedup*, eficiencia, Karp–Flatt). **Tabla 2**: V3 sin y con transferencias (mediana, mín, máx, *speedup* contra la V1 de la misma máquina). **Figura 1**: *speedup* vs hilos con línea ideal `S = p` y barras mín–máx. Opcional: Figura 2 eficiencia vs hilos; Tabla 3 tamaño de bloque. Cada tabla declara `n` y semilla | Interpretación (va en 9); gráficas sin línea ideal ni unidades; números que no están en los CSV; capturas de terminal como evidencia | `resultados/tabla.md`, `speedup.png`, `mediciones*.csv` | 1–1½ p. | R5 |
| 9 | **Análisis** | Amdahl con la fracción secuencial **medida** en la sección 4: *speedup* máximo teórico vs obtenido. Karp–Flatt: tendencia de `f` con `p` y qué sobrecarga la explica. Memoria vs cómputo: intensidad aritmética estimada (operaciones por byte) o experimento; dónde y por qué deja de escalar V2 (ancho de banda, sincronización, falso compartido, núcleos lógicos). V3: porcentaje del tiempo total que son transferencias; a partir de qué `n` conviene la GPU; qué limita el *kernel*. Predicción vs resultado: diferencia y causa. Superlineal: explicado si ocurrió | Repetir las tablas en prosa; "más hilos fue más rápido"; culpar a "la laptop" sin dato | Tablas 1–2, sección 4, bitácora | 1–1½ p. | R6 |
| 10 | **Qué falló y qué aprendimos (bitácora)** | 3–5 entradas elegidas de `bitacora.md`: qué falló, cómo se detectó, causa, cambio, aprendizaje; al menos una medición descartada; **qué no entendemos todavía** (se lee en la defensa) | Lista de errores de compilación triviales; "todo salió bien" | `bitacora.md` | ½–¾ p. | R7 |
| 11 | **Reparto de trabajo** | Tabla integrante → archivos y secciones → porcentaje acordado; coincidencia con `git shortlog -sn` (pegar la salida) y explicación si no coincide | Porcentajes iguales por costumbre si el historial dice otra cosa | README §6, `git shortlog` | ¼ p. | R7 |
| 12 | **Declaración de uso de IA** | Las cuatro líneas de `docs/metodo/05-politica-ia.md`: herramientas; para qué (verde/amarillo); qué fragmentos vinieron de la IA (archivo y líneas) y cómo se verificaron; **qué nos dijo la IA que resultó estar mal** (ejemplo concreto) | "No usamos IA" sin más si el historial o el estilo dicen lo contrario; omitir la última línea | README §7 o `declaracion-ia.md` (sección "Entrega final") | ¼ p. | R7 |
| 13 | **Referencias** | Documentación oficial citada en el texto: especificación de OpenMP, guía de programación de CUDA, documentación de Numba/CuPy si aplica, fuente de los datos, material del curso que se usó (protocolo de medición). Formato libre pero consistente | Blogs y videos como única fuente; referencias que no se citan | — | ¼ p. | R7 |

## 3. Esqueleto para copiar

Copia el bloque a `reporte/reporte.md` (o la estructura equivalente en LaTeX/Word), sustituye lo que está entre «» y
genera el PDF (p. ej. `pandoc reporte.md -o reporte.pdf`). Borra los comentarios `<!-- -->` antes de generar.

````markdown
<!-- PORTADA -->
# «Título del problema»
**Proyecto integrador · Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1**
Equipo «NN» · «https://github.com/.../cp-6bm1-equipoNN» · commit `entrega-final` = «hash corto»
«Nombre completo 1» («usuario GitHub») · «Nombre completo 2» («usuario») · «Nombre completo 3» («usuario»)
Entregado el «lunes 7 de diciembre de 2026»

## 1. Resumen
<!-- ≤ 10 líneas. Debe contener: problema, n, hardware CPU/GPU, mejor speedup V2 (p), speedup V3 sin/con transferencias, limitante -->
«…»

## 2. Problema y datos
### 2.1 Qué se calcula y para qué
### 2.2 Entrada: origen, tamaño, formato, semilla
### 2.3 Salida y verificación de correctitud (tolerancia)
### 2.4 Por qué es paralelizable
### 2.5 Tiempo de la V1 con n = «…»

## 3. Diseño por el método de Foster
### 3.1 Partición
### 3.2 Comunicación
### 3.3 Aglomeración
### 3.4 Mapeo (V2: hilos · V3: bloques e hilos CUDA)
| Tarea | Datos que toca | Depende de |
|---|---|---|
| «…» | «…» | «…» |
**Figura 0.** Diagrama de descomposición. «elaboración propia»

## 4. V1: versión secuencial y línea base
### 4.1 Estructura
### 4.2 Perfilado («herramienta») — Tabla: parte → tiempo → %
### 4.3 Fracción secuencial medida: f = «…»

## 5. V2: memoria compartida (OpenMP)
### 5.1 Región paralelizada y por qué
### 5.2 Alcance de variables, schedule, reducciones, sincronización
### 5.3 Verificación de ausencia de carreras
```c
// «v2/main.c», líneas «a–b»
«fragmento ≤ 15 líneas»
```

## 6. V3: GPU («CUDA C | Numba CUDA | CuPy»)
### 6.1 Mapeo hilo→dato y tamaño de bloque (justificación medida)
### 6.2 Memoria y transferencias
### 6.3 Comprobación de errores y verificación contra V1 (misma sesión, «fecha»)
```c
// «v3/kernel.cu», líneas «a–b»
«fragmento del kernel»
```

## 7. Metodología de medición
### 7.1 Hardware: CPU «…» · GPU «modelo, memoria, driver, fecha»
### 7.2 Software: «gcc X.Y», «nvcc X.Y», banderas «…»
### 7.3 Protocolo: calentamiento 1 · repeticiones «5» · mediana (mín/máx) · región cronometrada «…» · reloj «…»
### 7.4 Tamaños, semilla e hilos: n = «…», semilla = «…», hilos = «1 2 4 …»
### 7.5 Comandos que reproducen cada tabla
### 7.6 Predicción previa (bitácora, «fecha»): «speedup esperado y por qué»

## 8. Resultados
**Tabla 1.** V1 y V2 (n = «…», semilla = «…»). Generada con `./run_all.sh --hilos "…"` → `resultados/tabla.md`.
«pegar resultados/tabla.md»
**Tabla 2.** V3 sin y con transferencias (n = «…», GPU «…», «fecha»). Generada con `v3/notebook_colab.ipynb` celda 5 → `resultados/mediciones_v3.csv`.
«…»
**Figura 1.** Speedup vs hilos con línea ideal y barras mín–máx. `resultados/speedup.png`.

## 9. Análisis
### 9.1 Amdahl: con f = «…», S_max = «…»; obtuvimos S(«p») = «…» porque «…»
### 9.2 Karp–Flatt: f(2) = «…», f(4) = «…», f(8) = «…» → «crece/estable» porque «…»
### 9.3 Memoria vs cómputo: intensidad aritmética ≈ «…» op/byte → «…»
### 9.4 Transferencias en V3: «…» % del tiempo total; la GPU conviene a partir de n ≈ «…»
### 9.5 Predicción vs resultado: esperábamos «…», obtuvimos «…», porque «…»

## 10. Qué falló y qué aprendimos
| Fecha | Qué falló | Cómo lo detectamos | Causa | Qué cambiamos | Qué aprendimos |
|---|---|---|---|---|---|
| «…» | «…» | «…» | «…» | «…» | «…» |
**Qué no entendemos todavía:** «…»

## 11. Reparto de trabajo
| Integrante | Archivos y secciones | % |
|---|---|---|
| «…» | «…» | «…» |
Salida de `git shortlog -sn`: «pegar». «Explicación si no coincide».

## 12. Declaración de uso de IA
- Herramienta(s): «…»
- Para qué la usamos (verde/amarillo): «…»
- Qué fragmento(s) de código vinieron de la IA (archivo y líneas) y cómo los verificamos: «…»
- Qué nos dijo la IA que resultó estar mal: «…»

## 13. Referencias
1. OpenMP Architecture Review Board. *OpenMP Application Programming Interface*, versión «…». «URL»
2. NVIDIA. *CUDA C++ Programming Guide*, versión «…». «URL»
3. «Fuente de los datos»
4. «Protocolo de medición del curso, herramientas/protocolo-medicion.md»
````

## 4. Antes de generar el PDF

- Cuenta las páginas: 8–12. Si sobran, recorta las secciones 4–6 (fragmentos, no decisiones) antes que 8–9.
- Cada número de las tablas se puede encontrar con `grep` en `resultados/*.csv`.
- El resumen se escribe al final, con las tablas ya hechas.
- Corre `lista-cotejo-entrega.md` (ítems 18, 20 y 25 son de este PDF).
