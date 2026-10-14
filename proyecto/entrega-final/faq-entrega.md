# Preguntas frecuentes sobre la entrega final

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Entrega final · lunes 7 de diciembre de 2026, 10:30 · Defensa: jueves 10 de diciembre de 2026 · versión 1.0 · 14 de octubre de 2026

Las respuestas citan las rúbricas (`rubrica-codigo.md` = C, `rubrica-reporte.md` = R) y el protocolo de medición
(`herramientas/protocolo-medicion.md`). Lo que no esté aquí se pregunta en clase antes del jueves 3 de diciembre.

## 1. ¿Qué pasa si la V3 no supera a la V2 (o ni siquiera a la V1)?

No se penaliza el número; se penaliza no explicarlo. Pasa con frecuencia y por razones que el curso enseña: el problema es
pequeño y las transferencias anfitrión↔dispositivo dominan (por eso se reporta con **y** sin transferencias), el *kernel*
está limitado por memoria y no por cómputo, el tamaño de bloque es malo, o la V1 en la CPU de Colab es lenta y la
comparación cambia respecto a tu laptop. Lo que se exige: V3 correcta (`PASS` contra V1, C1), mediciones con el protocolo
(C4) y un análisis que diga **por qué** con datos: porcentaje del tiempo en transferencias, intensidad aritmética, a partir
de qué `n` la GPU conviene (R6). Un equipo con V3 más lenta y análisis correcto puede sacar Ejemplar en C3 y R6; un equipo
con V3 más rápida y sin explicación, no. Lo mismo aplica si el *speedup* de V2 es superlineal: se verifica correctitud, se
explica (caché) y se reporta; no se oculta ni se celebra sin más.

## 2. ¿Puedo usar CuPy o Numba CUDA en lugar de CUDA C?

Sí: la V3 admite CUDA C, Numba CUDA o CuPy en Colab/Kaggle. Condiciones:

- Debe haber un **kernel propio**: `@cuda.jit` en Numba, o `RawKernel`/`ElementwiseKernel` en CuPy. Una V3 hecha solo con
  llamadas de biblioteca (`cupy.sum`, `cupy.dot`) sin explicar qué *kernel* corre debajo queda en C3 En desarrollo como
  máximo, porque no hay diseño paralelo que evaluar.
- El programa imprime las mismas claves que la V3 en C (`gpu=`, `tiempo_kernel_s=`, `tiempo_total_s=`, `checksum=`) y se mide
  con eventos de CUDA (`cuda.event()`, `cupy.cuda.Event`), con y sin transferencias.
- El *notebook* se genera igual (`generar_notebook_v3.py --fuente v3/main_gpu.py`) y se sube ejecutado.
- Para probar la lógica sin GPU: `NUMBA_ENABLE_CUDASIM=1`. No sirve para medir.

## 3. ¿Qué pasa si un integrante no trabajó?

Tres mecanismos, en este orden:

1. **El historial.** `git shortlog -sn` y las fechas de los *commits* son la evidencia primaria (C6). Un volcado de archivos
   el último día a nombre de alguien no lo sustituye.
2. **El README §6 y §8, antes de la hora límite.** Si el reparto real no es el acordado, el equipo lo escribe ahí: quién hizo
   qué y qué pasó. Decirlo antes de las 10:30 del lunes 7 de diciembre no penaliza al resto; descubrirlo en la defensa, sí
   afecta al equipo completo en C6 (reparto que no coincide con los *commits* sin explicación).
3. **La defensa individual** (jueves 10 de diciembre, 15 puntos, `proyecto/defensa/`). Las preguntas son por integrante y
   pueden mover la calificación de cada uno respecto a la del equipo; C6 de la rúbrica de código también se aplica por
   integrante. Quien no puede explicar el código no recibe los puntos del código.

Si el problema aparece antes, se habla con el profesor en cuanto ocurre, no la semana de la entrega.

## 4. Colab me da una GPU distinta cada día (o se acabó la cuota). ¿Cómo mido la V3?

Todas las mediciones de la V3 (incluida la V1 compilada en Colab para tener `T(1)` de la misma máquina) se hacen **en una
sola sesión**; la celda 1 del *notebook* guarda modelo, driver y fecha en `entorno_gpu.txt`. Si otro día te toca otra GPU
y vuelves a medir, es otra tabla con su propia fecha: no se mezclan filas ni se promedian. Si se agota la cuota de Colab,
Kaggle ofrece GPU T4 (hasta 30 h por semana) con el mismo flujo; dilo en el README. Mide la V3 con tiempo: la semana del 30
de noviembre al 6 de diciembre también tiene la Práctica 6 (domingo 6 de diciembre, 23:59) y el Examen 3 es el martes 8.

## 5. ¿Puedo cambiar de problema o de datos respecto a lo que propusimos en H0/H1?

Después del H2 (lunes 23 de noviembre) no. Antes, solo con acuerdo del profesor y por una razón técnica escrita en la
bitácora (p. ej. "la V1 tarda 40 s con el tamaño mínimo útil y no cabe en Colab"). Cambiar el **tamaño** del problema o
ajustar los datos sí se puede en cualquier momento, siempre que `n` y la semilla queden declarados y todas las versiones
usen los mismos. Lo que no se puede es reportar V2 con un `n` y V3 con otro sin decirlo (protocolo §5).

## 6. ¿Qué pasa si no llegamos a las 10:30 del lunes 7 de diciembre?

Se califica el último *commit* anterior a esa hora. Si siguen subiendo cambios después, aplica la entrega tardía: hasta 72 h
(jueves 10 de diciembre, 10:30) con máximo 80 % en las dos piezas; después no se recibe salvo justificante institucional.
Dos consecuencias prácticas: el martes 8 a las 08:30 es el Examen 3, y la defensa del jueves usa lo que esté en el repositorio
a las 10:30. Un repositorio incompleto pero honesto (README §8 "lo que no funciona") a tiempo suele valer más que uno
"completo" 48 horas tarde con el 80 % de tope.

## 7. ¿Cuánto código puede venir de la IA y cómo lo declaro?

Según `docs/metodo/05-politica-ia.md`: fragmentos de ≤ 10 líneas que **reescribes y explicas** (amarillo), declarados con
archivo y líneas; pedir una versión completa (V1, V2 o V3) o "mejorar" mediciones es rojo y se trata como integridad
académica. La declaración va en el README §7 y en el reporte §12 con las cuatro líneas, incluida "qué nos dijo la IA que
resultó estar mal" con un ejemplo concreto (si no encontraste nada mal, no verificaste). En la defensa se aplica la prueba
de propiedad: cualquier integrante explica cualquier línea. Usos recomendados: que critique tu diseño de Foster con
preguntas, que proponga casos de prueba para `tests/run_tests.sh`, que te explique un error de `nvcc`.

## 8. Mi laptop tiene 2 núcleos (o es una Mac sin OpenMP). ¿En qué máquina mido la V2?

En la máquina que puedas declarar completa en `entorno.txt`, con V1 y V2 medidas **en la misma**. Con 2 núcleos físicos se
mide 1, 2 y "uno más allá" (4, declarado como sobre-suscripción o *hyper-threading*); el análisis con Amdahl y Karp–Flatt
funciona igual, y es mejor una curva corta y honesta que una larga en una máquina que no puedes describir. Alternativas: la
máquina de un integrante con más núcleos, el laboratorio LS4 en horario de práctica, o el entorno de Colab sin GPU (CPU de
2–4 núcleos, se declara). Nunca mezcles máquinas en un mismo `mediciones.csv`. En macOS, `gcc` suele ser `clang` sin OpenMP:
instala `gcc` real o `libomp` y declara la versión.

## 9. ¿Qué pasa si `make` no compila en la máquina del profesor?

Aplica la regla de los 10 minutos (`reproducibilidad.md` §1): C5 Insuficiente y C1–C4 se evalúan solo con lo que se pueda
verificar en la demo en vivo de la defensa. Casi siempre la causa es una de estas: ruta absoluta a los datos, archivo que no
está en git, `-lm` faltante, `Makefile` que asume otra versión de compilador, `run_all.sh` sin `chmod +x`, dependencia de
Python no declarada. Todas se detectan clonando tu repositorio en una carpeta nueva y corriendo
`scripts/verificar_entrega.sh` antes de etiquetar. Hazlo el fin de semana del 5–6 de diciembre, no el lunes a las 10:00.

## 10. ¿Cuándo y cuánto tiempo defiende mi equipo?

La defensa es el jueves 10 de diciembre de 2026, 10:30–12:00: 12 minutos por equipo con demo en vivo y preguntas
individuales, 15 puntos (`proyecto/defensa/`). Con alrededor de 12 equipos, 12 × 12 minutos no caben en 90 minutos. Hay
dos opciones sobre la mesa y la decisión es del profesor, que la anunciará junto con el orden de exposición: (a) usar también
la sesión de reserva del lunes 14 de diciembre, 10:30, para la segunda mitad de los equipos; o (b) acortar a 7 minutos de
exposición + 3 de preguntas por equipo en una sola sesión. En cualquier caso: la demo corre desde un clon del *commit*
`entrega-final` (no desde la carpeta de trabajo), el repositorio no cambia entre la entrega y la defensa, y cada integrante
responde preguntas por separado. Las defensas pendientes por causa justificada se atienden el martes 15 de diciembre, 08:30.
