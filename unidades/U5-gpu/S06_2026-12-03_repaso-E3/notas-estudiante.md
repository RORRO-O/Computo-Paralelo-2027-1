> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S06 · jueves 3 de diciembre de 2026 · 10:30–12:00 · Salón 3208

# Notas · Guía de repaso de las Unidades IV–V para el Examen 3

Palabras clave: colectiva, raíz, comunicador, semántica de bloqueo, modelo `α + m/β`, escalabilidad fuerte y
débil, *kernel*, malla, bloque, *warp*, guardia, memoria compartida, barrera de bloque, atómica, transferencias
H2D/D2H, ocupación, *speedup* con y sin copias.

## 1. Qué evalúa el Examen 3 (martes 8 de diciembre de 2026, 08:30–10:00) y cómo

Seis secciones, 100 puntos, 80 minutos, versiones A/B, sin dispositivos: opción múltiple (distractores de ideas
erróneas) · predecir la salida (un programa MPI corto y un *kernel* CUDA corto) · encontrar y corregir el error
(uno MPI, uno CUDA) · completar código · problema numérico (modelo de costo; tiempo con/sin transferencias;
*speedup*) · diseño breve (elegir MPI, OpenMP o GPU y justificar). El 10–20 % acumulativo de las Unidades I–III va
dentro de los problemas (eficiencia, Amdahl, protocolo de medición). El examen de práctica de hoy
(`examen-practica-U4-U5.md`, 60 puntos, 40 min) es la versión corta de esa misma estructura.

## 2. Las catorce ideas erróneas que atacan los ítems

| Si piensas… | En realidad… | Cómo lo verificas |
|---|---|---|
| 16. "Los procesos MPI comparten memoria" | Cada proceso tiene su espacio; tras `Reduce`/`Gather` el resultado **solo** está en la raíz; los demás conservan lo que tenían | Imprime la variable en un rango ≠ raíz |
| 17. "`MPI_Send` siempre regresa de inmediato" / "siempre espera al receptor" | Depende del tamaño y del *buffering* (envío inmediato ≈ < 4 KB en Open MPI local). Un programa seguro termina aunque todos los `Send` esperen | Prueba con un mensaje grande (10⁶ `double`) |
| 18. "Solo la raíz llama a `MPI_Bcast`" | Todas las colectivas las llaman **todos** los procesos del comunicador, con la misma raíz y argumentos compatibles | `-np 4` con `timeout`: código 124 = cuelgue |
| 19. "El rango 0 tiene que ser el maestro" | Es una convención; cualquier rango puede ser raíz | Cambia `root` y mira dónde queda el resultado |
| 20. "Más procesos que núcleos está bien" | Sobre-suscripción: tiempos altos y erráticos; sirve para correctitud, no para medir | `nproc`; etiqueta la fila como sobre-suscrita |
| 21. "La comunicación es gratis" | `T = α + m/β`; con mensajes chicos manda α (≈ µs); un halo de 8 bytes cuesta lo mismo que miles de operaciones | Calcula `n*` con `T_p = (n/p)·t_c + 2α` |
| 22. "Un hilo CUDA es un núcleo de CPU" | Miles de hilos ligeros en *warps* de 32 (SIMT); los SM cambian de *warp* para ocultar latencia | `kernel<<<65536, 256>>>` es normal, no un error |
| 23. "La memoria global es tan rápida como la compartida" | Uno o dos órdenes de magnitud de diferencia; por eso el *tiling* reutiliza datos del bloque | Cuenta lecturas globales: `n` vs. `n/TILE` |
| 24. "Las transferencias no cuentan" | Cuentan y a menudo dominan; se reporta **con y sin** copias | Dos pares de eventos: *kernel* y total |
| 25. "`__syncthreads()` sincroniza la GPU" | Solo el bloque; entre bloques se sincroniza al terminar el *kernel* | Segunda etapa en el anfitrión o en otro *kernel* |
| 26. "Cualquier tamaño de bloque funciona igual" | Múltiplos de 32; ocupación; ≤ 1 024 hilos; se mide el barrido | `invalid configuration argument` con 2 000 |
| 27. "Sin error = correcto" | `cudaGetLastError` y `cudaDeviceSynchronize` solo ven lanzamientos inválidos y accesos ilegales | Compara contra la CPU con tolerancia, en dos tamaños |
| 1. "Más hilos siempre es más rápido" | Lo limitan la fracción secuencial, el ancho de banda, la sincronización y la sobre-suscripción | Karp–Flatt: si `f` crece con `p`, hay sobrecarga |
| 5. "Medir una vez basta" / "con `-O0`" | Calentamiento + ≥ 5 repeticiones + mediana + `-O2` + hardware declarado | Protocolo de `herramientas/protocolo-medicion.md` |

Las cuatro variantes de "sin error = correcto" que salen hoy: `grid = n / block` (faltan elementos), `Reduce` leído
en todos (ceros), sin guardia (escribe fuera, "a veces nada"), sin barrera o sin atómica (resultado distinto cada
vez). Ninguna imprime nada.

## 3. Dos métodos que valen puntos

**Predecir la salida.** Tabla con una fila por rango (o por hilo) y una columna por variable; se llena llamada por
llamada preguntando *quién tiene el dato antes y quién después*; lo que una llamada no toca se queda; el orden de
las líneas entre procesos no se promete, el orden dentro de un proceso sí. En CUDA: `i = blockIdx.x·blockDim.x +
threadIdx.x`, guardia, y para memoria compartida "¿quién cargó `s[j]`?" antes de leerla.

**Cazar un error.** (1) Reproducir y **cuantificar** el síntoma contra una referencia (¿cuántos faltan? ¿fijo o
variable entre corridas?). (2) Hipótesis por el número: faltante fijo → malla o índices; faltante variable con
índices correctos → carrera; cuelgue → alguien espera un mensaje que nadie manda. (3) ¿*Kernel* o anfitrión?
¿Quién llama a la colectiva? (4) Una línea. (5) Re-verificar con el tamaño que expuso el error y con uno nuevo.
Detalle y huecos en `ejemplo-resuelto.md`.

## 4. Fórmulas que debes reproducir sin apuntes

| Qué | Fórmula | Ejemplo del curso |
|---|---|---|
| Costo de un mensaje | `T = α + m/β` | 8 bytes con α = 0.5 µs ≈ 0.5 µs; 1 MiB a 2 GB/s ≈ 0.5 ms |
| Jacobi 1D con `p` procesos | `T_1 = n·t_c`; `T_p = (n/p)·t_c + 2α`; `S > 1 ⇔ n > 2α / (t_c·(1 − 1/p))` | α = 2 µs, `t_c` = 1 ns, `p` = 4 → `n* ≈ 5 300` |
| *Speedup*, eficiencia, Karp–Flatt | `S = T(1)/T(p)`; `E = S/p`; `f = (1/S − 1/p)/(1 − 1/p)`; `T(1)` = mejor secuencial | `S = 6` con 8 hilos → `E = 75 %` |
| Bloques e índice | `grid = ⌈n/block⌉ = (n + block − 1)/block`; `i = blockIdx.x·blockDim.x + threadIdx.x`; ociosos = `grid·block − n` | `n = 1000, block = 256` → 4 bloques, 24 ociosos |
| Índice lineal 2D | `idx = fila·ancho + col`; `col = idx % ancho`, `fila = idx / ancho` | 480 × 640, (100, 33) → 64 033 |
| *Speedup* con y sin copias | `S_kernel = T_cpu / t_kernel`; `S_total = T_cpu / (t_H2D + t_kernel + t_D2H)`; con `k` iteraciones sobre los mismos datos las copias se pagan una vez | 90 / 1.5 = 60×; 90 / 37.5 = 2.4× |
| Ocupación (T4) | *warps* residentes / 32; bloques de 32 hilos → 16 bloques × 1 *warp* = 50 % | Barrido: 32 peor; 128–256 mejor; 1 024 no mejora |
| Transferencia | `t = latencia + bytes / ancho_de_banda` (paginable 3–6 GB/s; *pinned* 10–12 GB/s) | 64 MB a 6 GB/s ≈ 11 ms |

## 5. Errores frecuentes al contestar (de la corrección de exámenes anteriores y del examen de práctica)

1. Dar el número sin la fórmula ni las unidades: medio punto. `S = 3.94` sin decir `1 000 / 254` no se puede revisar.
2. Predecir un **orden** de impresión entre procesos como si estuviera garantizado.
3. Escribir `max_root = 4` en todos los rangos (idea 16) o `total` solo en la raíz tras `Allreduce`.
4. `i = threadIdx.x` como índice global; `grid = n / block`; guardia olvidada en el último bloque.
5. Leer memoria compartida que ningún hilo cargó (ítem II.2 del examen de práctica) sin notarlo.
6. "Corregir" una carrera con `__syncthreads()` dentro de un `if` (idea 32) o con `cudaDeviceSynchronize()`
   dentro del *kernel*.
7. Reportar solo el *speedup* del *kernel* (idea 24), o elegir "más hilos por bloque" sin el barrido (ideas 1, 26).
8. En diseño: elegir plataforma por gusto; se piden **dos datos numéricos** del problema (memoria, bytes, α,
   cómputo por iteración) y una alternativa descartada con un número.

## 6. Logística que debes saber

- **Práctica 6**: domingo 6 de diciembre, 23:59 (15 % del 3.er parcial). Sin cuota de GPU en las 48 h previas:
  captura fechada del aviso + medición marcada pendiente, se completa a más tardar el martes 15 de diciembre 08:30.
- **Entrega final del proyecto** (repositorio V1·V2·V3 con etiqueta `entrega-final` + `reporte/reporte.pdf`):
  lunes 7 de diciembre, 10:30; 40 + 30 puntos del proyecto. Lista de cotejo: `proyecto/entrega-final/lista-cotejo-entrega.md`.
- **Examen 3**: martes 8 de diciembre, 08:30–10:00, 30 % del 3.er parcial; versiones A/B por fila; 80 min efectivos;
  sin dispositivos; hoja de calibración aparte (predicción al recibir, postdicción al entregar).
- **Defensa oral**: jueves 10 de diciembre, 10:30 (15 puntos del proyecto; preguntas individuales). El formato lo
  anuncia el profesor hoy.

## 7. Para saber más

- MPI Forum, *MPI: A Message-Passing Interface Standard*, v4.1: "Point-to-Point Communication" (modos y semántica)
  y "Collective Communication" (qué procesos llaman y con qué argumentos).
- NVIDIA, *CUDA C++ Programming Guide*: "Thread Hierarchy", "Memory Hierarchy", "Shared Memory",
  "Synchronization Functions", "Atomic Functions", "Error Checking"; *CUDA C++ Best Practices Guide*: "Timing",
  "Data Transfer Between Host and Device", "Occupancy".
- Numba, *CUDA Python*: "Writing CUDA Kernels", "Synchronization and atomic operations", "Debugging CUDA Python
  with the simulator".
- Kirk y Hwu, *Programming Massively Parallel Processors*, 4.ª ed., cap. 3–6 y 10; Pacheco y Malensek, *An
  Introduction to Parallel Programming*, 2.ª ed., cap. 3 (MPI).
