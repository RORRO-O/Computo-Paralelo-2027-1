> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Sesión S02 · martes 24 de noviembre de 2026 · 08:30–10:00 · Lab LS4

# S02 · Jerarquía de memoria de la GPU, acceso coalescido y multiplicación por mosaicos · Práctica 6 · Laboratorio 1

Tipo: laboratorio (variante 2.1 adaptada; caso "constructo nuevo en Lab 1" de `02-plantilla-sesion.md` §2.1):
recuperación 5 min · mini-lección 25 min · bloque de laboratorio 50 min (= PRIMM corto de 20 min con el código
de esta carpeta + Práctica 6 Partes A/B de 30 min) · punto de control 5 min · *exit ticket* 5 min. Suma 90.

## Objetivos (al terminar, el estudiante podrá…)

1. Clasificar los espacios de memoria de la GPU (registros, compartida, global, constante, cachés) por
   alcance, vida y latencia relativa, y elegir cuál usar para un dato dado. (comprender)
2. Decidir, leyendo la expresión de indexación de un *kernel*, si el acceso de un *warp* a memoria global es
   coalescido, y reescribirlo para que lo sea. (analizar / aplicar)
3. Calcular las lecturas a memoria global de la multiplicación ingenua y por mosaicos para `n` y `TILE`
   dados, y explicar el papel de cada `__syncthreads()` y del manejo de bordes. (aplicar / analizar)
4. Verificar un *kernel* contra la CPU y distinguir "no dio error de CUDA" de "el resultado es correcto",
   usando `cudaGetLastError()` y comparación con tolerancia. (evaluar)

Evaluación de cada objetivo: 1 → recuperación Q5, CT1, *exit ticket* Q1(b) (nombra la memoria compartida) y
tarea 1(d); 2 → *exit ticket* Q1(c), CT1 y fase
Crear; 3 → *exit ticket* Q1(a–b), CT2, tabla de rastreo I1; 4 → *exit ticket* Q2, I3 y CT3.

## Prerrequisitos y vínculo

- Viene de: S01 (lunes 23 de noviembre): arquitectura GPU vs. CPU, SIMT, anfitrión/dispositivo, *kernels*,
  hilos/bloques/malla, suma de vectores en Colab. También U3 S10 (falso compartido, línea de caché) y U4 S05
  (modelo de costo latencia + tamaño/ancho de banda), que hoy se reciclan como analogías.
- Va hacia: S03 (jueves 26 de noviembre, 10:30, salón 3208): `__syncthreads`, atómicas, reducción en árbol,
  divergencia de *warps*. S04 (lunes 30): transferencias, ocupación, tamaño de bloque (cierra la pregunta de
  por qué `TILE=32` no es 2× más rápido). Práctica 6 Lab 2 (martes 1 de diciembre). V3 del proyecto.
- Ideas erróneas que esta sesión ataca: **23** (global tan rápida como compartida) → CT1(d), mini-lección,
  I2.4; **26** (cualquier tamaño de bloque funciona igual) → CT1(c), Modificar `TILE=64`, *exit ticket* Q2;
  **27** (sin error ⇒ correcto) → I3, CT3(a), *exit ticket* Q2. De paso: 7, 24, 25 y 34 (malla truncada y
  guardia de escritura: I2.3, I3, P4).
- Nivel de andamiaje (07 §A.5): **completo**. Ejemplo resuelto completo y PRIMM con las cinco fases
  (Predecir–Investigar en clase; Modificar y Crear en casa y en el Lab 2 del martes 1 de diciembre).

## Materiales

- Esta carpeta completa. Compilada la noche anterior en la máquina del profesor: `make test` en
  `practica-guiada/` (≈ 30 s, sin GPU) y el notebook ejecutado una vez en Colab para tener la tabla de
  tiempos del día (la GPU asignada cambia).
- Proyector, cronómetro visible, tarjetas con números de lista, lista de equipos para registrar el pre-lab
  (vive en el repositorio de cada equipo, `practicas/P6/prelab/`).
- Cada pareja: una laptop con cuenta de Colab/Kaggle (de la Práctica 1) y el repositorio clonado.
- `practicas/P6-gpu/README.md` y su rúbrica impresa (para las mini-defensas). Si el README no está en el
  repositorio la víspera, hoy se aplica la alternativa del bloque 50–80 (Modificar + Crear de la práctica guiada).
- Pizarrón: dibujar antes de empezar la matriz 4×4 dividida en mosaicos 2×2 y una fila de 32 puntos.

## Guion minuto a minuto

### 0–5 · Recuperación (y registro del pre-lab)

Proyectar `retrieval-inicio.md`. El pre-lab está en el repositorio de cada equipo (`practicas/P6/prelab/<alias>.md`,
antes de las 08:30; `03-plantilla-practica.md` §1); Q1 retoma su pregunta 1 y el `git log` se revisa al cerrar. El
pre-lab incluye la comprobación de que se obtiene GPU en Colab y en Kaggle (07 §B): anotar quién reportó que
no la obtuvo, para emparejarlo en el minuto 30 con un equipo que sí la tenga.
Al minuto 4, respuestas; manos por pregunta; anotar el conteo de Q1 y Q5.
Respuestas esperadas: Q1 4 bloques y `if (i < n)`; Q5 4 bytes frente a 4096 bytes.
Si Q1 < 60 %: reconstruir la fórmula del índice global en el pizarrón (3 min) dentro del bloque 5–7 antes
de pasar a la malla 2D; recortar 3 min de la Práctica 6.

### 5–30 · Mini-lección: jerarquía de memoria y *tiling*

**5–7 · Objetivos y anclaje.** Leer los cuatro objetivos. Conectar con el *exit ticket* de S01 según el error
más frecuente que se anotó anoche. Si fue el índice global: "Ayer la mitad del grupo calculó mal qué hilo
toca qué elemento; hoy ese índice decide además si la lectura es rápida o 32 veces más lenta". Si fue
"hilo = núcleo": "Ayer varios escribieron que un hilo de CUDA es como un núcleo; hoy van a ver que 32 hilos
comparten una sola instrucción y una sola petición de memoria, y eso cambia cómo se escribe el código".
Proyecto: "La V3 es portar su V2 a GPU; la primera decisión será qué va a memoria compartida".
La autocalificación de la tarea de S01 (2 min, clave en su `<details>`) se hace al minuto 30, no aquí: su
ejercicio 3.2 (cuántas veces se lee cada `A[i][k]` con `N = 1024`) es la predicción P1 de hoy.

**7–13 · Jerarquía de memoria.** Tabla de `notas-estudiante.md` §1 en el proyector, fila por fila. Pensar
en voz alta: "Si tengo un valor que solo usa este hilo, registro. Si lo usan los 256 hilos de mi bloque en
esta fase, compartida. Si lo usan todos los bloques, global: y voy a pagar ~500 ciclos cada vez, así que
quiero leerlo lo menos posible y de la forma más barata". Dar las latencias como órdenes de magnitud y
decir explícitamente que la diferencia global/compartida es de uno a dos órdenes (idea 23). Alcance en una
línea: registros → hilo; compartida → bloque; global y constante → malla y anfitrión.

**13–18 · Coalescencia.** Fila de 32 puntos en el pizarrón: 32 hilos del *warp*. Caso A: leen
`M[fila*n + tx]`: 128 bytes contiguos, una transacción. Caso B: `M[tx*n + col]`: 32 segmentos. Regla:
"`threadIdx.x` recorre el índice que cambia más rápido en memoria". Transposición: leer por filas y escribir
por columnas; algo tiene que ser saltado *en global*… salvo que el cambio de índices ocurra en compartida.
Dejar la pregunta abierta: es la fase Crear.

**18–22 · CT1** (`conceptests.md`). Voto → discusión → revoto → explicación. Si > 80 % al primer voto, se
explica en 1 min y se gana tiempo para la práctica.

**22–30 · Ingenua vs. mosaicos (ejemplo resuelto).** Proyectar el *kernel* por mosaicos. Pensar en voz alta
con `n = 64, TILE = 16`: contar lecturas (Paso 1 de `ejemplo-resuelto.md`): "cada elemento de A lo leen
los 64 hilos de su fila; con mosaicos lo lee un bloque de cada bloque-columna: 4". Mostrar la tabla de
rastreo con `n = 4, TILE = 2` y la Pausa 2 ("¿quién trajo `B[0][2]`?"): de ahí sale la primera barrera.
Pausa 3: la segunda barrera. Pausa 4: la guardia va en la escritura y los hilos sobrantes cargan ceros.
Mostrar las salidas reales de CPU y simulador (mismo *checksum* `54987.442763`). Última frase: "En la GPU
la de mosaicos tarda entre la mitad y la cuarta parte, no la dieciseisava; ustedes van a averiguar por qué".

### 30–50 · Práctica guiada PRIMM corto (`practica-guiada/README.md`)

Arranque (1 min): parejas; conductor abre el notebook en Colab y activa la GPU; navegante abre
`matmul_tiled.cu` en el repositorio. Cambio de roles al minuto 40. Quien no tenga GPU disponible trabaja
con `make test` y el simulador (`NUMBA_ENABLE_CUDASIM=1 python3 matmul_numba.py --n 64 --tile 16`).

- **30–35 Predecir.** Primero 2 min: autocalificar la tarea de S01 con su clave; el profesor registra entrega.
  Su ejercicio 3.2 ya es P1 con `N = 1024`, así que P1 se contesta en 30 s y el tiempo va a P2–P4. Por
  escrito; no se corre nada. El profesor circula y lee predicciones; no corrige.
- **35–40 Ejecutar.** Pasos 2–3 del notebook (o CPU + simulador). Comparar con P1 y P3.
- **40–50 Investigar.** I1 (tabla de rastreo del segundo hilo), I2 (preguntas 1–4), I3 (los dos programas
  sin error que fallan), I4 si da tiempo. Modificar y Crear quedan para casa y para el Lab 2 (martes 1 de
  diciembre); se dicen en voz alta al minuto 49.

Lista de errores esperados y la pregunta que se hace ante cada uno:

| Error observado | Pregunta socrática |
|---|---|
| Predice que la de mosaicos lee cada elemento 1 vez (o `n²` lecturas en total) | "¿Cuántos bloques necesitan `A[0][0]`? Señálalos en el dibujo de la malla." |
| Espera 16× de aceleración y se decepciona con 2–4× | "¿Cómo leen `B[k*n + col]` los 16 hilos de una fila del bloque ingenuo: juntos o saltados? ¿Qué hace la L2 con la segunda vez que alguien pide esa línea?" |
| Corre `--sin-sync1`, le sale PASS una vez y concluye que la barrera sobra | "¿Cuántas veces lo corriste? ¿Qué pasó la vez que dio `inf`? ¿Qué dice el Anexo A sobre 'salió bien una vez'?" |
| Propone `if (row >= n \|\| col >= n) return;` al inicio del *kernel* | "¿Cuántos hilos tienen que llegar a `__syncthreads()`? ¿Qué le pasa a los que esperan a uno que ya regresó?" |
| Malla con `n / TILE` (división entera) | "¿Cuántos bloques cubren 100 columnas con mosaicos de 16? ¿Qué hilo calcula la columna 99?" |
| "`TILE=64` compila, así que funciona" | "¿Cuántos hilos tiene ese bloque? ¿Cuál es el máximo? ¿Qué línea del programa lo va a decir?" |
| En I1 confunde `s_A[ty][k] * s_B[k][tx]` y escribe `s_A[k][tx]` | "¿Qué fila de A necesita `C[row][col]`? ¿En qué fila del mosaico quedó?" |
| `nvidia-smi` no muestra GPU / "command not found" | "¿Qué tipo de entorno de ejecución está seleccionado?" |
| `CudaSupportError` al correr el espejo en la laptop | "¿Qué variable de entorno activa el simulador? Mírala en el README." |
| Compara GPU con transferencias contra CPU sin decirlo (aparece en P6 Parte A) | "¿Qué incluye tu tiempo? ¿Qué pide el protocolo: con y sin copias?" |
| Verifica con `==` y reporta FALLA por `1e-5` de diferencia | "¿La CPU usa FMA? ¿Las dos suman en el mismo orden? ¿Qué tolerancia usa `common.cuh` y por qué es proporcional a `n`?" |

### 50–80 · Práctica 6 · Laboratorio 1: Partes A y B

Enunciado: `practicas/P6-gpu/README.md` (publicado el lunes 23 de noviembre). Flujo del Lab 1:

- **Parte A (guiada, 50–67).** Suma de vectores y SAXPY completos (50–62): compilar, ejecutar con
  `n ∈ {10⁵, 10⁶, 10⁷}`, medir con `cudaEvent` el *kernel* solo y el total con copias H2D/D2H, llenar la tabla
  A.3 y escribir la predicción del pre-lab al lado. Después (62–67), el *kernel* por mosaicos **completo**
  (`src/a_matmul_tiled.cu`, el mismo que rastrearon en I1; se les dice así): llenar la tabla de predicción A.7
  (lecturas, fases, bloques, hilos que cargan ceros, qué protege cada barrera) y contrastarla con
  `a_matmul_cpu 1000 16`. Es código completo para leer y predecir (07 §B: el constructo nuevo no va como `TODO`
  el mismo día). Verificación automática con `make test`.
- **Parte B (semi-guiada, 67–80).** Variante rectangular `C = A(M×K)·B(K×N)` (`src/b_matmul_rect.cu` y su
  espejo): memoria compartida, barreras y ciclo de productos vienen escritos; `TODO(1)`–`TODO(4)` son índices,
  dimensiones y guardias (constructos de la S01). Criterio: `make test-b` en verde con `32×32×32` **y**
  `20×40×12`. El código sin corregir pasa la cuadrada y falla la rectangular (ideas 27 y 34): ese contraste es
  la pregunta de la mini-defensa. Lo que no quede al minuto 80 se termina en casa antes del Lab 2 (martes 1 de
  diciembre); el criterio no cambia. En 13 min lo realista es corregir `TODO(1)` y `TODO(2)`.

El profesor circula con la rúbrica. **Mini-defensas** (02 §2.1): 2 min por equipo, al azar con tarjetas; una
pregunta por integrante sobre el código que tengan en pantalla ("¿qué hace esta línea?"); la segunda ("¿qué
pasaría si la quito?") solo si la primera falla, y cuenta la mejor de las dos. Con más de 12 equipos, hoy se
defiende la mitad y la otra mitad el martes 1 de diciembre (lista publicada al cerrar esta sesión). Las
líneas preferidas hoy: cada `__syncthreads()`, el `? … : 0.0f` de la carga, la guardia de escritura y el
`cudaGetLastError()` tras el lanzamiento. Una respuesta que muestre que no se entiende el código propio se
anota (afecta "Proceso e integridad" de ese integrante en la P6); quien pide responder por escrito lo hace
en el momento (5 min, papel).

Si la Práctica 6 aún no estuviera publicada en el repositorio al llegar la sesión, el bloque se cubre con
las fases Modificar (pasos 5–6 del notebook) y Crear de la práctica guiada, que producen la misma evidencia
(tabla `n × TILE`, CSV, transposición) y se reportan en la Parte D de la P6.

### 80–85 · Punto de control y CT2

Tres equipos al azar (tarjetas) muestran **una** medición en 1 minuto cada uno: "naive vs. tiled con
`n = 512` en esta GPU: tiempos, cociente, ¿coincide con tu predicción?". Los demás equipos anotan la suya en
la cabecera del *exit ticket* (02 §2.1). Enseguida **CT2** con voto rápido
(1 min); si < 80 %, discusión de 2 min y revoto. Regla general en una frase: **una carga a compartida,
`TILE` usos; el cociente de lecturas es `TILE`, el de tiempos lo deciden las cachés y la ocupación**.
Si CT2 sale > 80 % al primer voto, se lanza CT3 en su lugar; si no, CT3 abre la recuperación de S03.

### 85–90 · Cierre

`exit-ticket.md` en papel, individual. Mientras escriben, anunciar:

- Tarea espaciada (`tarea-espaciada.md`): tabla `n × TILE` y "dónde vive cada dato" + intercalado +
  preparación de S03. Sin peso propio; se autocalifica con la clave al inicio de S03 (jueves 26 de noviembre,
  10:30; 2 min del bloque 5–10) y el profesor registra la entrega (07 §A.10).
- S03: jueves 26 de noviembre, 10:30–12:00, salón 3208: sincronización y reducción en GPU. Traer la
  predicción del ejercicio 3 de la tarea.
- Práctica 6: Lab 2 el martes 1 de diciembre 08:30 (mediciones, punto de control, mini-defensas); fecha
  límite **domingo 6 de diciembre, 23:59** (15 % del 3er parcial). La transposición con compartida (fase
  Crear) se reconoce en la defensa pero no suma puntos.

## Diferenciación

- **Apoyo (quien no arranca en PRIMM).** Darle la tabla I1 con la fase `t=0` ya llena y pedir solo la fase
  `t=1`; correr `NUMBA_ENABLE_CUDASIM=1 python3 matmul_numba.py --n 4 --tile 2` y seguir el *checksum*
  `13.832168` con `./matmul_cpu 4 2`. Si el problema es el entorno (sin GPU, sin Numba), emparejar con un
  equipo que ya tenga el notebook corriendo y asignarle el rol de navegante con la hoja de predicciones.
- **Ampliación (quien termina I1–I3 antes del minuto 50).** Fase Crear: `transpose_shared`. Reto adicional:
  quitar el `+1` de `tile[TILE][TILE + 1]`, medir en `n = 4096` y explicar la diferencia (conflictos de banco;
  se formaliza en S04). Otro: `TILE=32` con `n = 2048` y calcular cuántos bloques caben por SM con 64 KB de
  compartida y 1024 hilos máximos por bloque.

<details><summary>Solución de referencia de la fase Crear (solo para el profesor; compilada con nvcc y verificada con el simulador en n = 17, 20, 24, 32)</summary>

```c
__global__ void transpose_shared(const float *in, float *out, int n) {
    __shared__ float tile[TILE][TILE + 1];
    int x = blockIdx.x * TILE + threadIdx.x;          // columna global en `in`
    int y = blockIdx.y * TILE + threadIdx.y;          // fila global en `in`
    if (x < n && y < n) {
        tile[threadIdx.y][threadIdx.x] = in[y * n + x];   // lectura por filas: coalescida
    }
    __syncthreads();                                  // el mosaico completo está en compartida
    x = blockIdx.y * TILE + threadIdx.x;              // el mosaico (by, bx) de in va a (bx, by) de out
    y = blockIdx.x * TILE + threadIdx.y;
    if (x < n && y < n) {
        out[y * n + x] = tile[threadIdx.x][threadIdx.y];  // escritura por filas: coalescida
    }
}
```

Espejo en Numba (mismos índices con `cuda.blockIdx`, `cuda.threadIdx` y `tile_sh[ty, tx]` / `tile_sh[tx, ty]`).
Errores típicos: escribir `out[x * n + y]` (vuelve a la escritura saltada), olvidar el segundo cálculo de
`x, y` (escribe el mosaico en su posición original: resultado incorrecto), o poner la guardia con `return`
antes de la barrera.
</details>

## Evaluación formativa de la sesión

| Objetivo | Qué mira el profesor | Umbral de alerta |
|---|---|---|
| 1 Jerarquía | Recuperación Q5 (bytes entre accesos) y CT1(d) casi vacío en el revoto | > 15 % en CT1(d) tras discusión |
| 2 Coalescencia | CT1 revoto; en Crear, que `threadIdx.x` recorra la columna en los dos accesos | < 80 % en el revoto de CT1 |
| 3 Lecturas y barreras | *Exit ticket* Q1 con los dos números explicados; I1 segunda fila correcta; CT2 | > 30 % "mal" en Q1 |
| 4 Verificación | *Exit ticket* Q2(b) nombra `cudaGetLastError`; I3 reconocido como "sin error y mal" | > 30 % cree que `TILE=64` corre |

Mini-defensas: anotar por equipo si explican las dos barreras sin leer el comentario.

## Notas post-sesión

- Conteos: recuperación Q1 __ / Q5 __; CT1 primer voto __ % → revoto __ %; CT2 __ % → __ %.
- Montones del *exit ticket*: bien __ · parcial __ · mal __. Error más frecuente: ______ (abre S03).
- ¿Se llegó a I3 antes del minuto 50? ¿Cuántos equipos terminaron la Parte A de la P6? ¿Qué pregunta de
  mini-defensa falló más?
- Qué cambiar la próxima vez que se dé esta sesión.
