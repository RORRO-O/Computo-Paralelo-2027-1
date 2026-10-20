# Preguntas frecuentes sobre la entrega final

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Entrega final · lunes 7 de diciembre de 2026, 10:30 · Defensa: jueves 10 de diciembre de 2026 · versión 1.1 · 20 de octubre de 2026

Las respuestas citan las rúbricas (`rubrica-codigo.md` = C, `rubrica-reporte.md` = R) y el protocolo de medición
(`herramientas/protocolo-medicion.md`). Las preguntas generales del proyecto (lenguaje de V1, bibliotecas, laptop de 2
núcleos, Colab o Kaggle) están en `proyecto/README.md` §7. Lo que no esté en ninguno de los dos se pregunta en clase antes
del jueves 3 de diciembre.

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
  con y sin transferencias. Basta `time.perf_counter()` con sincronización explícita (`cuda.synchronize()` o
  `cp.cuda.Device().synchronize()`) antes de detener el reloj; los eventos de CUDA (`cuda.event()`, `cupy.cuda.Event`) son
  opcionales (`docs/metodo/04-evaluacion.md` §5). En CUDA C, eventos.
- El *notebook* se genera igual (`generar_notebook_v3.py --fuente v3/main_gpu.py`; incluye `comun/problema.h` porque la V1
  lo necesita) y se sube ejecutado.
- Para probar la lógica sin GPU: `NUMBA_ENABLE_CUDASIM=1`. No sirve para medir.

## 3. ¿Qué pasa si un integrante no trabajó?

La calificación de una persona nunca baja por lo que hizo o dejó de hacer otra (`proyecto/README.md` §6). Tres mecanismos:

1. **El historial.** `git shortlog -sn` y las fechas de los *commits* son la evidencia primaria. C6 se asigna **por
   integrante**: quien tiene participación marginal sin explicación en el reparto queda en Insuficiente en C6; los demás
   integrantes no. Un volcado de archivos el último día a nombre de alguien no sustituye al historial.
2. **El README §6 y §8, antes de la hora límite.** Si el reparto real no es el acordado, el equipo lo escribe ahí: quién
   hizo qué y qué pasó. Decirlo a tiempo es lo honesto y no le cuesta nada a quien sí trabajó. Lo que sí cuesta al equipo
   es un reparto en el README y en el reporte (§11) que no coincide con el historial y no se explica: baja R7.
3. **La defensa individual** (jueves 10 de diciembre, 15 puntos, `proyecto/defensa/`). Las preguntas son por integrante y
   pueden mover la calificación de cada uno respecto a la del equipo. La primera es sobre una línea de la parte que firmó;
   si falla, la segunda es de rescate sobre otra línea de esa parte y cuenta la mejor (`docs/metodo/05-politica-ia.md`).
   Quien no explica ninguna de las dos queda en C6 Insuficiente, y cada respuesta en Insuficiente resta además 10 % de
   sus 100 puntos del proyecto (`proyecto/defensa/rubrica-defensa.md` §4.1).

Si el problema aparece antes, se avisa por escrito al profesor la semana en que ocurre, no la semana de la entrega.

## 4. Colab me da una GPU distinta cada día (o se acabó la cuota). ¿Cómo mido la V3?

Todas las mediciones de la V3 (incluida la V1 compilada en Colab para tener `T(1)` de la misma máquina) se hacen **en una
sola sesión**; la celda 1 del *notebook* guarda modelo, driver y fecha en `entorno_gpu.txt`. Si otro día te toca otra GPU
y vuelves a medir, es otra tabla con su propia fecha: no se mezclan filas ni se promedian. Si se agota la cuota de Colab,
Kaggle tiene su propia cuota semanal de GPU con el mismo flujo; dilo en el README. Mide la V3 en la semana del 30 de
noviembre (taller del martes 1 de diciembre): el domingo 6 de diciembre a las 23:59 vence la Práctica 6 y el Examen 3 es el
martes 8. Si Colab y Kaggle niegan GPU en las 48 h previas a la entrega, entregas a tiempo con la captura fechada del aviso
de cuota y la medición marcada como pendiente, y la completas a más tardar el martes 15 de diciembre 08:30, sin
penalización (`docs/metodo/04-evaluacion.md` §5).

## 5. ¿Puedo cambiar de problema o de datos respecto a lo que propusimos en H0/H1?

Es la regla de `proyecto/README.md` §5. Después del H2 (lunes 23 de noviembre), no. Antes, solo con acuerdo del profesor
(asesoría o *issue* en el repositorio) y con la razón técnica escrita en la bitácora y en el README (p. ej. "la V1 tarda
40 s con el tamaño mínimo útil y no cabe en Colab"); si el cambio llega después de H1, se rehace el perfil de H1 con el
problema nuevo. Cambiar el **tamaño** del problema o ajustar los datos sí se puede en cualquier momento, siempre que `n` y
la semilla queden declarados y todas las versiones usen los mismos. Lo que no se puede es reportar V2 con un `n` y V3 con
otro sin decirlo (protocolo §5).

## 6. ¿Qué pasa si no llegamos a las 10:30 del lunes 7 de diciembre?

Se califica lo que tenga la etiqueta `entrega-final` a las 10:30 (hora de GitHub) o, sin etiqueta, el último *commit* de
`main` anterior a esa hora. Si crean o mueven la etiqueta después, se califica esa versión como entrega tardía: hasta 72 h
(jueves 10 de diciembre, 10:30) con máximo 80 % en las dos piezas; después no se recibe salvo justificante institucional.
Subir *commits* después de las 10:30 sin tocar la etiqueta no cambia lo que se califica.
Dos consecuencias prácticas: el martes 8 a las 08:30 es el Examen 3, y la defensa del jueves usa lo que esté en la etiqueta
a las 10:30. Un repositorio incompleto pero honesto (README §8 "lo que no funciona") a tiempo suele valer más que uno
"completo" 48 horas tarde con el 80 % de tope.

## 7. ¿Cuánto código puede venir de la IA y cómo lo declaro?

Según `docs/metodo/05-politica-ia.md`: fragmentos de ≤ 10 líneas que **reescribes y explicas** (amarillo), declarados con
archivo y líneas; pedir una versión completa (V1, V2 o V3) o "mejorar" mediciones es rojo y se trata como integridad
académica. La declaración va en el README §7 (o en `declaracion-ia.md`, sección "Entrega final") y en el reporte §12 con
las cuatro líneas, incluida "qué nos dijo la IA que resultó estar mal" con un ejemplo concreto. Si no encontraron nada mal,
escriban qué verificaron y cómo; si no usaron IA, "No usamos IA en esta entrega", firmado por todos. En la defensa se
aplica la prueba de propiedad: cualquier integrante explica cualquier línea. Usos recomendados: que critique tu diseño de
Foster con preguntas, que proponga casos de prueba para `tests/run_tests.sh`, que te explique un error de `nvcc`.

## 8. Nuestro repositorio no es una copia de `plantilla-repo/`. ¿El verificador lo va a rechazar?

No, si cumple el contrato de `README.md` §3 de esta carpeta. El verificador no compara con la plantilla: busca un `Makefile`
raíz con `all/run/test/clean`, un `run_all.sh` ejecutable que acepte `--rapido`, las carpetas de las tres versiones (en la
raíz o bajo `src/`), pruebas, los CSV con la cabecera del protocolo (con o sin `min_s,max_s`; etiquetas `v1`/`V1`,
`v3_kernel`/`V3-kernel`, `v3_total`/`V3`), el entorno de CPU y de GPU, el *notebook* ejecutado, el PDF, la bitácora
(`bitacora.md` o `bitacora-errores.md`) y la declaración de IA (README o `declaracion-ia.md`). Lo más común que falta en un
repositorio propio es el `--rapido`: debe correr el flujo completo en ≤ 3 minutos y escribir en `resultados/rapido/`, nunca
encima de `resultados/mediciones.csv`. Corre primero `verificar_entrega.sh RUTA_AL_CLON --sin-ejecutar` (segundos) y
después sin esa opción.

## 9. ¿Qué pasa si `make` no compila en la máquina del profesor?

Aplica la regla de los 10 minutos (`reproducibilidad.md` §1): C5 Insuficiente y C1–C4 se evalúan solo con lo que se pueda
verificar en la demo en vivo de la defensa. Casi siempre la causa es una de estas: ruta absoluta a los datos, archivo que no
está en git, `-lm` faltante, `Makefile` que asume otra versión de compilador, `run_all.sh` sin `chmod +x`, dependencia de
Python no declarada. Todas se detectan clonando tu repositorio en una carpeta nueva y corriendo
`scripts/verificar_entrega.sh` antes de etiquetar. Hazlo a más tardar el jueves 3 de diciembre (la sesión de lista de
cotejo entre equipos) y otra vez después del último *commit*, no el lunes a las 10:00.

## 10. ¿Cuándo y cuánto tiempo defiende mi equipo?

El calendario fija la defensa el jueves 10 de diciembre de 2026, 10:30–12:00: 12 minutos por equipo con demo en vivo y
preguntas individuales, 15 puntos (`proyecto/defensa/`). Con alrededor de 12 equipos, solo la exposición pide
12 × 12 = 144 minutos, y la sesión dura 90 (80 útiles). La decisión es del profesor y la anuncia a más tardar el jueves 3 de
diciembre; el orden se sortea con semilla publicada el lunes 7 de diciembre. Las opciones (`proyecto/README.md` §3 y
`proyecto/defensa/logistica-defensa.md` §2–§3, donde están las cuentas completas):

| Opción | Cómo queda |
|---|---|
| (a) Formato completo en más sesiones | 12 min + preguntas: 4 equipos por sesión; jueves 10, lunes 14 de diciembre 10:30 (reserva) y, con más de 8 equipos, martes 15 de diciembre 08:30 |
| (b) Formato corto | 7 min de exposición + 3 de preguntas por equipo, en dos sesiones: jueves 10 (6 equipos) y lunes 14 de diciembre (6) |
| (c) Mixta | La exposición (≤ 8 min) va en video enlazado en el README con la entrega final; en clase, el jueves 10, solo demo de 2 min y preguntas individuales |

En cualquier caso: la demo corre desde un clon de la etiqueta `entrega-final` (no desde la carpeta de trabajo), el
repositorio no cambia entre la entrega y la defensa, cada integrante responde por separado, y el equipo graba antes del
miércoles 9 de diciembre a las 20:00 un video de plan B de la demo (≤ 3 min, enlazado en un *issue*). Las defensas
pendientes por causa justificada y la segunda entrega de P6 son el martes 15 de diciembre, 08:30, con cualquier opción
(con la opción (a) y más de 8 equipos esa sesión también tiene defensas, y las pendientes ocupan su holgura). Faltar
sin justificante cuenta como fallar las dos preguntas individuales (`proyecto/README.md` §6).
