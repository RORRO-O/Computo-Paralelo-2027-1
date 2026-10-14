# Guía paso a paso: CUDA en Google Colab y en Kaggle

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Unidad V · Herramienta para la Práctica 6 y la V3 del proyecto · versión 1.0 · 14 de octubre de 2026

La GPU del curso vive en la nube para que nadie dependa de su laptop (`01-marco-pedagogico.md`, P10). Esta
guía te lleva de cero a un CSV del protocolo medido en GPU. Las "capturas" van descritas en texto para que
puedas seguirlas aunque la interfaz cambie de idioma o de color; los nombres de menú se dan en español y en
inglés. Las salidas marcadas como *salida esperada* se obtuvieron en una sesión de Colab con T4; los números de
tiempo cambian con la GPU y con la fecha.

## 0. Fechas que dependen de esta guía

| Qué | Cuándo | Fuente |
|---|---|---|
| Verificar que obtienes GPU en Colab **y** en Kaggle (pre-laboratorio de P6, individual) | antes del martes 24 de noviembre, 08:30 | `03-plantilla-practica.md`, Pre-laboratorio; `04-evaluacion.md` §5 |
| Mediciones de V3 | semana del lunes 30 de noviembre (no el fin de semana del 5–6 de diciembre) | `04-evaluacion.md` §5 |
| Práctica 6 | domingo 6 de diciembre, 23:59 | `planeacion/mapa-evaluacion.md` |
| Entrega final del proyecto (V1·V2·V3 + reporte PDF) | lunes 7 de diciembre, 10:30 | `planeacion/mapa-evaluacion.md` |
| Medición en GPU pendiente por falta de cuota (ver §9) | a más tardar el martes 15 de diciembre, 08:30 | `04-evaluacion.md` §5 |

## 1. Qué necesitas

- Una cuenta de Google (Colab) y una cuenta de Kaggle con **teléfono verificado** (sin eso Kaggle no da GPU).
- Tu código `.cu` (o `.py` con Numba/CuPy) en el repositorio del equipo, y la versión CPU (V1 o la secuencial
  de la práctica) para compararla **en la misma máquina**.
- `herramientas/medir.sh` y `herramientas/graficar_speedup.py` de este repositorio (se usan igual que en tu laptop).
- Nada se instala: Colab y Kaggle traen `nvcc`, `gcc`, `numba` y `cupy`. Si `nvcc` no está en el PATH, usa
  `/usr/local/cuda/bin/nvcc`.

## 2. Activar la GPU

### 2.1 Colab

1. Entra a colab.research.google.com y crea un cuaderno ("Archivo → Nuevo cuaderno" / "File → New notebook").
2. Menú **Entorno de ejecución → Cambiar tipo de entorno de ejecución** ("Runtime → Change runtime type").
3. En **Acelerador de hardware** ("Hardware accelerator") elige **T4 GPU** y pulsa **Guardar**.
4. Pulsa **Conectar** (arriba a la derecha). Cuando conecta, el botón se convierte en un indicador de RAM y disco.

> **Captura 1 (descrita).** Ventana emergente "Cambiar tipo de entorno de ejecución". Arriba, "Tipo de entorno
> de ejecución: Python 3". Debajo, el título "Acelerador de hardware" con botones de opción: "CPU", "T4 GPU"
> (seleccionado) y, atenuadas o marcadas como de pago, "A100 GPU", "L4 GPU", "TPU". Abajo a la derecha, los
> botones "Cancelar" y "Guardar".

> **Captura 2 (descrita).** Esquina superior derecha del cuaderno después de conectar: un recuadro con dos
> barras pequeñas, "RAM" y "Disco", y la palabra "T4" junto a una marca verde. Si en lugar de "T4" no aparece
> ningún nombre de GPU, el acelerador no quedó activo: repite el paso 2.

### 2.2 Kaggle

1. Entra a kaggle.com → **Create → New Notebook**. Si es tu primera vez: **Settings → Phone verification** y
   verifica el teléfono (los aceleradores quedan bloqueados hasta hacerlo).
2. En el panel derecho, sección **Session options**, despliega **Accelerator** y elige **GPU T4 x2** o
   **GPU P100** (cualquiera sirve; apunta cuál).
3. La sesión con GPU arranca al ejecutar la primera celda. El mismo panel muestra la cuota restante
   ("GPU quota: … hrs remaining this week").

> **Captura 3 (descrida).** Panel lateral derecho del cuaderno de Kaggle, pestaña con el icono de engrane.
> Secciones: "Session options" con los campos "Accelerator: GPU T4 x2" (desplegable), "Language: Python",
> "Persistence", "Environment", "Internet: Off". Debajo, una barra con el texto "GPU: 29h 40m / 30h" que indica
> la cuota semanal restante.

## 3. Celda 1: verificar y documentar la GPU asignada

La GPU que te asignan **cambia entre sesiones** (T4, a veces otra en Kaggle: P100). Por eso el protocolo pide
anotar modelo y fecha (`protocolo-medicion.md` §1.4). Ejecuta esta celda al inicio de **cada** sesión de medición
y guarda su salida:

```bash
!mkdir -p resultados
!{ date -u '+fecha_utc: %Y-%m-%d %H:%M'; echo "plataforma: Colab"; \
   nvidia-smi --query-gpu=name,driver_version,memory.total,compute_cap --format=csv; \
   nvcc --version | tail -n 2; } | tee resultados/entorno_gpu.txt
```

*Salida esperada (Colab, T4):*

```
fecha_utc: 2026-11-30 16:05
plataforma: Colab
name, driver_version, memory.total [MiB], compute_cap
Tesla T4, 550.54.15, 15360 MiB, 7.5
Cuda compilation tools, release 12.5, V12.5.82
Build cuda_12.5.r12.5/compiler.34385749_0
```

Si `nvidia-smi` falla con "command not found" o "No devices were found", no tienes GPU: vuelve a §2 o ve a §9.
Para un `nvidia-smi` completo (uso de memoria, procesos) ejecuta `!nvidia-smi` sin argumentos.

> **Captura 4 (descrita).** Salida de `!nvidia-smi`: una tabla ASCII con el encabezado "NVIDIA-SMI 550.54.15
> Driver Version: 550.54.15 CUDA Version: 12.4"; una fila "0 Tesla T4 Off" con temperatura, consumo
> ("9W / 70W"), memoria ("0MiB / 15360MiB") y utilización "0 %". El "CUDA Version" de esta tabla es el máximo
> que admite el controlador, no el de `nvcc`; en el reporte cita los dos.

`compute_cap` te dice la bandera de arquitectura para `nvcc`:

| GPU (dónde aparece) | `compute_cap` | Bandera `-arch` |
|---|---|---|
| Tesla T4 (Colab gratuito, Kaggle) | 7.5 | `sm_75` |
| Tesla P100 (Kaggle) | 6.0 | `sm_60` |
| L4 (Colab de pago) | 8.9 | `sm_89` |
| A100 (Colab de pago) | 8.0 | `sm_80` |

Compilar para una arquitectura distinta de la asignada produce `no kernel image is available for execution on
the device` al lanzar el *kernel* (lo atrapa `cudaGetLastError`, por eso se revisa siempre).

## 4. Celda 2: escribir el código con `%%writefile`

La celda mágica `%%writefile nombre.cu` guarda el contenido de la celda como archivo en el disco de la sesión.
Pega ahí tu `.cu`. Para probar el flujo usa `herramientas/ejemplo_gpu.cu` (suma de vectores con medición con y
sin transferencias; imprime `tiempo_s=` y `tiempo_kernel_s=`):

```
%%writefile ejemplo_gpu.cu
<contenido de herramientas/ejemplo_gpu.cu>
```

Alternativas para no pegar a mano: `!git clone <URL del repositorio del curso>` y trabajar dentro de la
carpeta clonada, o subir archivos con el icono de carpeta del panel izquierdo (Colab) → "Subir" (se pierden al
cerrar la sesión). El código del equipo debe seguir viviendo en **su** repositorio: lo que edites en Colab,
cópialo de vuelta y haz *commit* desde tu laptop.

> **Captura 5 (descrita).** Celda de código cuya primera línea es `%%writefile ejemplo_gpu.cu` seguida del
> código C. Debajo de la celda, la única salida: "Writing ejemplo_gpu.cu" (o "Overwriting ejemplo_gpu.cu" si ya
> existía).

## 5. Celdas 3 y 4: compilar y ejecutar

```bash
!nvcc -O2 -arch=sm_75 -Xcompiler -Wall,-Wextra ejemplo_gpu.cu -o ejemplo_gpu
!./ejemplo_gpu 50000000 256
```

`-O2` es obligatorio (protocolo §1.1); `-Xcompiler -Wall,-Wextra` pasa las banderas del curso al compilador del
código de anfitrión. Sin *warnings*. Ajusta `-arch` según la tabla de §3.

*Salida esperada (T4; los tiempos varían):*

```
gpu=Tesla T4
n=50000000
bloque=256
checksum=350000000.0
ok=1
tiempo_kernel_s=0.004731
tiempo_s=0.118902
```

Qué mirar: `ok=1` (el resultado coincide con la CPU), y que `tiempo_s` (con copias anfitrión↔dispositivo) es
mucho mayor que `tiempo_kernel_s`: en una suma de vectores las transferencias dominan (idea errónea 24 del
Anexo A). En el reporte se dan **los dos** tiempos (protocolo §2).

## 6. Celda 5: medir con el protocolo (`medir.sh`)

`medir.sh` funciona igual que en tu laptop; en modo GPU usa `-t gpu` (no fija hilos, escribe `gpu` en la columna
`hilos` y deja la eficiencia en `NA`). La comparación honesta de V3 es contra la V1 **corrida en la misma máquina
de Colab**, no contra tu laptop (`proyecto/medicion-en-el-proyecto.md` §1). Primero la línea base, luego las dos
filas de GPU:

```bash
!cp <ruta>/herramientas/medir.sh . && chmod +x medir.sh
!gcc -std=c11 -O2 -Wall -Wextra v1.c -o v1            # tu V1 o la versión CPU de la práctica
!./medir.sh -c secuencial-colab -t 1   -n 50000000 -o resultados/mediciones_gpu.csv -- ./v1
!./medir.sh -c V3        -t gpu -n 50000000 -o resultados/mediciones_gpu.csv -- ./ejemplo_gpu
!./medir.sh -c V3-kernel -t gpu -n 50000000 --clave tiempo_kernel_s -o resultados/mediciones_gpu.csv -- ./ejemplo_gpu
!python3 graficar_speedup.py resultados/mediciones_gpu.csv --salida resultados
```

Cada llamada hace 1 calentamiento + 5 repeticiones y agrega una fila
`config,hilos,n,rep1..rep5,mediana_s,speedup,eficiencia`; el *speedup* de las filas `V3` y `V3-kernel` se calcula
contra la fila `secuencial-colab` con el mismo `n`. Si tu CSV de laptop usa el formato de
`proyecto/plantillas/run_all.sh` (con `min_s,max_s`), ese script también produce las filas `V3` y `V3-kernel`
(lee `TIEMPO_KERNEL_S`/`tiempo_kernel_s=`): usa uno u otro, no mezcles archivos con distinto encabezado.

Reglas que aplican igual en la nube (protocolo §2 y §5):

- `n` tal que la versión secuencial tarde ≥ 1 s **en Colab**; el mismo `n` para la fila GPU. Si la GPU necesita
  otro tamaño por memoria, es otra tabla con su propia línea base.
- Las 5 repeticiones en la **misma sesión** (misma GPU). Nunca combines corridas de sesiones distintas en una fila.
- Variabilidad alta (`(máx − mín)/mediana > 0.20`): repite la configuración completa y anótalo en la bitácora.
  La GPU es compartida; eso es un dato, no un defecto tuyo.
- La tabla de tu laptop (V1, V2) y la de Colab (V1-colab, V3) se presentan por separado; la comparación entre
  máquinas se declara como tal.

## 7. Guardar el CSV: Drive, descarga o Kaggle

El disco de la sesión se borra al desconectarse. Guarda **antes** de que eso ocurra.

**Colab → descargar a tu laptop** (lo más simple):

```python
from google.colab import files
files.download('resultados/mediciones_gpu.csv')
files.download('resultados/entorno_gpu.txt')
```

**Colab → Google Drive** (si vas a volver en otra sesión):

```python
from google.colab import drive
drive.mount('/content/drive')              # pide autorizar la cuenta; acepta
!mkdir -p /content/drive/MyDrive/cp-6bm1/resultados
!cp resultados/* /content/drive/MyDrive/cp-6bm1/resultados/
```

> **Captura 6 (descrita).** Panel izquierdo de Colab con el explorador de archivos: carpetas "drive" (con
> "MyDrive" dentro), "sample_data" y "resultados"; dentro de "resultados", los archivos "mediciones_gpu.csv",
> "entorno_gpu.txt", "speedup.png" y "eficiencia.png". Al pasar el cursor por un archivo aparece un menú de
> tres puntos con la opción "Descargar".

**Kaggle:** todo lo que escribas en `/kaggle/working/` aparece en la pestaña **Output** del panel derecho,
desde donde se descarga archivo por archivo; para que persista entre sesiones pulsa **Save Version → Save &
Run All**. Escribe tus resultados con ruta absoluta: `-o /kaggle/working/resultados/mediciones_gpu.csv`.

Después, en tu laptop: copia los archivos a `resultados/` del repositorio del equipo y haz *commit* ("Agregar
mediciones de V3 en Colab (T4, 30 nov)").

## 8. Límites de cuota y desconexiones (lo que te va a pasar)

| Plataforma | Límite | Consecuencia práctica |
|---|---|---|
| Colab gratuito | Cuota de GPU **dinámica y no publicada**: suelen ser unas horas al día y baja si usas la GPU muchas horas seguidas; la sesión se cierra tras ~90 min sin actividad y a las 12 h como máximo | Mide en una sesión corta y concentrada; no dejes el cuaderno conectado "por si acaso" (gasta cuota) |
| Kaggle | **30 h de GPU por semana** por cuenta (se ve en el panel); sesión máxima de 12 h; el disco se borra salvo con "Save Version" | Desactiva el acelerador ("Accelerator: None") mientras solo editas código; actívalo para compilar y medir |
| Ambas | Al desconectarse se pierden los archivos y las variables | Celda 1 al inicio de cada sesión; guarda el CSV al terminar cada bloque de mediciones |

Reparto recomendado para un equipo de 3: una cuenta mide, las otras dos quedan de reserva para el día de la
entrega; nadie comparte su cuenta ni crea cuentas adicionales (viola los términos de las plataformas y la
integridad académica del curso).

## 9. Si no hay GPU

1. **Cambia de plataforma.** Colab y Kaggle no comparten cuota: si una te niega la GPU, prueba la otra.
2. **Reintenta en otro horario.** La disponibilidad gratuita es menor en horas pico (tarde-noche de América).
   Madrugada u hora de comida en la Ciudad de México suelen funcionar mejor.
3. **Sigue trabajando en la correctitud sin GPU.** Es lo que vale más puntos y no depende de la cuota
   (`04-evaluacion.md` §5):
   - CUDA C: `nvcc -c -arch=sm_75 archivo.cu` compila (detecta errores de sintaxis y *warnings*) en Colab con
     entorno de CPU y en cualquier máquina con el *toolkit* instalado; la ejecución espera a la GPU.
   - Numba CUDA: `NUMBA_ENABLE_CUDASIM=1 python3 archivo.py` ejecuta el *kernel* en el simulador de CPU (lento:
     usa tamaños pequeños) y permite correr `make test`.
   - CuPy no tiene simulador: escribe la versión NumPy equivalente y compara contra ella.
4. **Documenta y entrega a tiempo.** Si Colab **y** Kaggle niegan la GPU en las 48 h previas a la fecha límite,
   entrega en la fecha con: una captura **con fecha visible** del aviso de cuota (ver abajo), la medición de V3
   marcada como "pendiente" en el reporte y el CSV con las filas de GPU vacías. Completa la medición en cuanto
   haya cuota y a más tardar el **martes 15 de diciembre, 08:30**, sin penalización. Avisa al profesor el mismo
   día por el canal del curso.

> **Captura 7 (descrita; la que debes guardar como evidencia).** Colab: cuadro de diálogo con el título "No se
> puede conectar a un backend de GPU" ("Cannot connect to GPU backend") y el texto "Actualmente no puedes
> conectarte a una GPU debido a los límites de uso de Colab" con los botones "Cerrar" y "Conectar sin GPU"; en
> la misma captura debe verse el reloj del sistema o la fecha. Kaggle: el panel "Session options" con
> "GPU quota: 0h 0m / 30h" o el mensaje "You have exhausted your GPU quota".

## 10. Cómo documentar la GPU en el reporte

En `resultados/entorno_gpu.txt` (lo escribe la Celda 1) y en la tabla "Entorno de medición" del reporte:

| Dato | De dónde | Ejemplo |
|---|---|---|
| Plataforma y fecha/hora (UTC o CDMX, dilo) | Celda 1 | Colab, 2026-11-30 10:05 CDMX |
| GPU, memoria, `compute_cap` | `nvidia-smi --query-gpu=...` | Tesla T4, 15360 MiB, 7.5 |
| Versión del controlador y "CUDA Version" | `nvidia-smi` | 550.54.15 / 12.4 |
| Versión de `nvcc` y banderas | `nvcc --version`; tu celda de compilación | 12.5; `-O2 -arch=sm_75` |
| CPU de la máquina de Colab (para la fila `secuencial-colab`) | `!lscpu \| grep 'Model name'`; `medir.sh` lo guarda en `entorno.txt` | Intel Xeon @ 2.20GHz, 2 vCPU |
| Una fila por sesión si mediste en varias | Bitácora | "sesión 2 (1 dic): P100 en Kaggle, `-arch=sm_60`" |

Sin modelo de GPU y fecha, la medición no cuenta como evidencia (protocolo §5: "omitir el hardware").

## 11. Si tu V3 es Numba CUDA o CuPy

Las reglas son las mismas (calentamiento, 5 repeticiones, mediana, con y sin transferencias). El reloj es
`time.perf_counter()` y **hay que sincronizar antes de detenerlo**: los lanzamientos son asíncronos y, sin
`cuda.synchronize()` (Numba) o `cp.cuda.Device().synchronize()` (CuPy), medirás microsegundos de un *kernel* que
aún no terminó. Esqueleto (fragmento; adáptalo e imprime `clave=valor` para `medir.sh`):

```python
import sys, time
import numpy as np
from numba import cuda

@cuda.jit
def suma(a, b, c):
    i = cuda.grid(1)
    if i < a.size:
        c[i] = a[i] + b[i]

n = int(sys.argv[1]) if len(sys.argv) > 1 else 50_000_000
a = (np.arange(n) % 7).astype(np.float32); b = (2 * (np.arange(n) % 5)).astype(np.float32)
bloque = 256; bloques = (n + bloque - 1) // bloque

t0 = time.perf_counter()                       # con transferencias
d_a = cuda.to_device(a); d_b = cuda.to_device(b); d_c = cuda.device_array_like(a)
suma[bloques, bloque](d_a, d_b, d_c); cuda.synchronize()
c = d_c.copy_to_host()
t_total = time.perf_counter() - t0

suma[bloques, bloque](d_a, d_b, d_c); cuda.synchronize()   # calentamiento del kernel ya compilado
t0 = time.perf_counter()                       # sin transferencias
suma[bloques, bloque](d_a, d_b, d_c); cuda.synchronize()
t_kernel = time.perf_counter() - t0

print(f"n={n}\nchecksum={c.sum(dtype=np.float64):.1f}\ntiempo_kernel_s={t_kernel:.6f}\ntiempo_s={t_total:.6f}")
```

Se mide con `./medir.sh -c V3 -t gpu -n 50000000 -o ... -- python3 v3_numba.py` y
`--clave tiempo_kernel_s` para la fila sin transferencias. La primera llamada a un *kernel* de Numba incluye la
compilación JIT: por eso el calentamiento no se cuenta. Para `make test` sin GPU: `NUMBA_ENABLE_CUDASIM=1`.

## 12. Errores frecuentes

| Síntoma | Causa probable | Primera pregunta |
|---|---|---|
| `no kernel image is available for execution on the device` | `-arch` no coincide con la GPU asignada | ¿Qué dijo `compute_cap` en la Celda 1 de **esta** sesión? |
| `tiempo_kernel_s` ≈ 0.000005 con n = 5·10⁷ | Falta sincronizar antes de detener el reloj | ¿Hay `cudaEventSynchronize`/`cudaDeviceSynchronize` (o `cuda.synchronize()`) antes de leer el tiempo? |
| `ok=0` o `checksum` distinto de la CPU | Índice fuera de rango sin `if (i < n)`, o se copió antes de que terminara el *kernel* | ¿Cuántos hilos lanzas y cuántos elementos hay? |
| El *speedup* de V3 es enorme comparado con tu laptop | Comparas máquinas distintas | ¿Mediste la V1 en Colab? |
| El *speedup* de V3 es < 1 | Problema pequeño: dominan las copias | ¿Qué fracción de `tiempo_s` es `tiempo_kernel_s`? ¿Qué pasa con n 10× mayor? |
| `nvidia-smi: command not found` | Entorno sin GPU | §2 y §9 |
| El cuaderno "se murió" y el CSV desapareció | Desconexión por inactividad o cuota | ¿Descargaste el CSV al terminar cada bloque (§7)? |
| `Writing ejemplo_gpu.cu` pero `nvcc` dice "No such file" | La celda `%%writefile` se ejecutó en otra sesión o en otro directorio | ¿Qué muestra `!pwd && ls`? |
