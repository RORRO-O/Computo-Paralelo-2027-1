# Plantilla de `REPORTE.md` para prácticas (P4, P5, P6)

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Plantilla que el equipo llena · versión 1.1 · 20 de octubre de 2026

Copia desde la línea `---` hasta el final a `practicas/Pn/REPORTE.md` en el repositorio de tu equipo y llena
cada sección. Borra las instrucciones en cursiva. Límite: **3 páginas** (≈ 1,300 palabras más la tabla y dos
gráficas); los límites por sección están pensados para que quepa. Las secciones son las que exige
`docs/metodo/03-plantilla-practica.md` ("Entregables y formato"): decisiones, tabla, gráfica, interpretación,
reflexión, bitácora de errores, declaración de uso de IA y reparto de trabajo; se añade "qué no entendemos
todavía" porque es la pregunta fija de las rondas del profesor. Este es el orden que piden P5 y P6. Si el
`entrega.md` de tu práctica fija otro orden o secciones propias (P4 pide el reparto primero y una sección por
parte), manda el de la práctica.

Fechas límite (de `planeacion/mapa-evaluacion.md`): P4 domingo 1 de noviembre 23:59 · P5 domingo 22 de noviembre
23:59 · P6 domingo 6 de diciembre 23:59. Entrega tardía ≤ 72 h: máximo 80 %.

---

# Práctica Pn · <título de la práctica>

> Equipo cp-6bm1-equipoNN · Integrantes: <número de lista o alias usado en los *commits*, sin nombres completos>
> · Fecha de entrega: <día, fecha y hora> · *Commit* evaluado: `<hash corto>`

## 1. Entorno de medición

*Pega aquí el contenido de `resultados/entorno.txt` que escribe `medir.sh` (o `nvidia-smi` y la fecha, en P6).
Sin esto la Parte D no cuenta (protocolo §1.4).*

| Dato | Valor |
|---|---|
| CPU (modelo, núcleos físicos / lógicos) | |
| RAM | |
| Sistema operativo y compilador (versión) | |
| Banderas de compilación | `-std=c11 -O2 -Wall -Wextra -fopenmp` (ajusta si cambió) |
| GPU y fecha de la sesión (solo P6) | |
| Tamaño del problema declarado y por qué (T(1) ≥ 1 s) | |

## 2. Decisiones de diseño (≤ 200 palabras + tabla)

*Una fila por decisión que cambió el código o el rendimiento: qué eligieron, qué descartaron y qué dato lo
sostiene. "Porque es más rápido" no es evidencia; "porque con `schedule(dynamic,64)` la mediana bajó de 1.92 a
1.41 s" sí. Incluye la decisión que corrige la idea errónea que la práctica expone (Parte B).*

| Decisión | Alternativa descartada | Razón con dato | Dónde está en el código (archivo:línea) |
|---|---|---|---|
| | | | |
| | | | |

## 3. Predicción y resultado (≤ 80 palabras)

*Copia la predicción del pre-laboratorio tal cual la escribieron y, al lado, lo que salió.*

- Predicción (antes de medir): "Con 4 hilos esperamos un *speedup* de ___ porque ___."
- Resultado: *speedup* con 4 hilos = ___ (eficiencia ___). Coincide / no coincide porque ___.

## 4. Tabla de mediciones

*Protocolo del curso: 1 calentamiento + ≥ 5 repeticiones, mediana, lista de hilos 1, 2, 4, 8 (hasta núcleos
físicos + 1). Pega la tabla Markdown que imprime `python3 graficar_speedup.py resultados/mediciones.csv`. El CSV
completo va en `resultados/mediciones.csv` con las columnas del protocolo.*

Tamaño del problema n = ___; línea base T(1) = ___ s (versión secuencial, no la paralela con un hilo).

*P5: dos tablas, escalabilidad fuerte (n fijo, p crece) y débil (n/p fijo; eficiencia débil T(1, n) / T(p, p·n)),
con procesos en lugar de hilos. P6: por cada configuración de GPU, el tiempo con transferencias y sin ellas, con
las columnas del CSV de la práctica (`practicas/P6-gpu/resultados/README.md`), y la línea base medida en la misma
máquina de Colab o Kaggle.*

| Config | Hilos | Mediana (s) | Mín (s) | Máx (s) | Speedup | Eficiencia | f Karp–Flatt |
|---|---|---|---|---|---|---|---|
| secuencial | 1 | | | | 1.00 | 1.00 | — |
| | 1 | | | | | | — |
| | 2 | | | | | | |
| | 4 | | | | | | |
| | 8 | | | | | | |

## 5. Gráficas

*`speedup.png` (con la línea ideal S = p) y `eficiencia.png`, generadas desde el CSV anterior. Ejes rotulados con
unidades. Una línea de pie de figura cada una.*

![Speedup frente a hilos](resultados/speedup.png)

*Figura 1. ___*

![Eficiencia frente a hilos](resultados/eficiencia.png)

*Figura 2. ___*

## 6. Interpretación (≤ 250 palabras)

*Responde las tres preguntas con un dato cada una.*

1. **¿Dónde deja de escalar?** A partir de ___ hilos la eficiencia cae por debajo de 50 % (E(___) = ___).
2. **¿Por qué?** *Elige y sostén con un número: fracción secuencial (f de Karp–Flatt = ___ y crece/no crece con
   p), ancho de banda de memoria (bytes movidos por iteración = ___), sincronización (número de `critical`/
   `atomic`/barreras por iteración = ___), comunicación (mensajes × tamaño = ___, en P5), transferencias
   anfitrión↔dispositivo (___ s de ___ s totales, en P6), falso compartido, sobre-suscripción (hilos > núcleos
   físicos).*
3. **¿Coincide con la predicción de la sección 3?** Sí / no, y qué aprendieron del desajuste.

## 7. Reflexión individual (una por integrante, 5–8 líneas cada una)

*Cada integrante escribe la suya y la firma con su alias. Al menos una pregunta de autoexplicación ("explica con
tus palabras por qué…") y una de transferencia ("¿cómo aplicarías esto en la V2/V3 de tu proyecto?"), según
las pida el README de la práctica.*

- **<alias 1>:**
- **<alias 2>:**
- **<alias 3>:**

## 8. Bitácora de errores (≥ 3 entradas)

*Qué falló, por qué, cómo lo detectaron y cómo lo corrigieron. Incluye los errores "que a veces salían bien"
(carreras) y cómo los confirmaron (ThreadSanitizer, salidas distintas entre corridas, comparación con la
secuencial). Un error del que no se aprendió nada no es una entrada.*

| # | Síntoma observado | Causa | Cómo se detectó | Corrección (*commit*) |
|---|---|---|---|---|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |

## 9. Qué no entendemos todavía (≤ 80 palabras)

*La pregunta fija de las rondas del profesor. Una o dos dudas concretas sobre el comportamiento observado, no
sobre el enunciado. Si no hay ninguna, escriban qué verificaron para estar seguros.*

## 10. Reparto de trabajo

*Debe coincidir con el historial de `git log --author`. Cada integrante necesita ≥ 3 *commits* con cambios de
código (rúbrica, criterio "Proceso e integridad"). Si alguien tiene menos, explíquenlo aquí. En la mini-defensa
se pregunta a cada quien sobre lo que firmó (`docs/metodo/05-politica-ia.md`, "Prueba de propiedad").*

| Integrante (alias) | Qué firmó (archivo y funciones o líneas) | *Commits* con código | Pregunta individual de su mini-defensa (Laboratorio 2, o Laboratorio 1 si así se publicó) |
|---|---|---|---|
| | | | |
| | | | |
| | | | |

## 11. Declaración de uso de IA

*Las cuatro líneas son obligatorias (`docs/metodo/05-politica-ia.md`). Si no usaron IA, escriban "No usamos IA en
esta entrega" en la primera línea y dejen las demás.*

```
Uso de IA en esta entrega:
- Herramienta(s): …
- Para qué la usamos (verde/amarillo): …
- Qué fragmento(s) de código vinieron de la IA (archivo y líneas) y cómo los verificamos: …
- Qué nos dijo la IA que resultó estar mal: …
```

---

## Lista de cotejo antes de entregar (no se entrega; úsala)

Criterios y pesos de la rúbrica genérica de `docs/metodo/03-plantilla-practica.md` §2 (la rúbrica específica de
cada práctica está en `practicas/Pn/rubrica.md`; los pesos pueden variar, la suma siempre es 100).

| Criterio (peso) | Verifica que… | ✓ |
|---|---|---|
| Correctitud y pruebas (25) | `make clean && make && make test` termina con código 0 y sin *warnings*; agregaron ≥ 1 caso propio en `tests/` | |
| Diseño paralelo (20) | Cada decisión de la sección 2 tiene alternativa descartada y dato; no hay sincronización dentro del ciclo interno sin justificar | |
| Medición (20) | CSV con ≥ 5 repeticiones por fila, mediana, lista de hilos del protocolo y T(1) de la versión secuencial; `entorno.txt`; dos gráficas con ejes rotulados; la sección 6 señala dónde E cae de 50 % y por qué, con un número | |
| Interpretación y reflexión (20) | Las tres preguntas de la sección 6 responden con datos; comparan con la predicción; una reflexión por integrante | |
| Proceso e integridad (15) | ≥ 3 *commits* de código por integrante; bitácora con ≥ 3 entradas; declaración de IA con las cuatro líneas; cada integrante explica en voz alta cualquier línea de lo que firmó y qué hace cada función del resto (prueba de propiedad, `05`) | |
| Formato (requisito, sin peso) | ≤ 3 páginas; sin nombres completos ni correos; rutas relativas; el Markdown se lee en GitHub sin imágenes rotas | |
