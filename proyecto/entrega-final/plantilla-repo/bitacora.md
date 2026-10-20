# Bitácora de errores y decisiones · Equipo NN

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Plantilla que el equipo llena · se copia a la raíz de `cp-6bm1-equipoNN/` como `bitacora.md`

**Para qué sirve.** Registrar cada falla que les costó más de 15 minutos: qué se observó, cómo se detectó, cuál fue
la causa y qué se cambió. También las mediciones descartadas y las predicciones hechas antes de medir. Se revisa
en H1 (jueves 29 de octubre), H2 (lunes 23 de noviembre) y la entrega final (lunes 7 de diciembre, 10:30), y se
resume en la sección 10 del reporte. Una bitácora con "no tuvimos errores" cuenta como ausente.

| Entrega | Mínimo que se revisa | Dónde se exige |
|---|---|---|
| H1 | ≥ 3 entradas de errores | `proyecto/hitos/H1-avance-1.md`, criterio 5 |
| H2 | ≥ 3 entradas nuevas desde H1 (una carrera, un resultado inestable o una medición descartada) | `proyecto/hitos/H2-avance-2.md`, criterio 5 |
| Entrega final | ≥ 5 entradas, ≥ 1 medición descartada, ≥ 1 predicción comparada con el resultado | `proyecto/entrega-final/rubrica-codigo.md`, C6 |

**Reglas.**
- Una fila por falla, en orden cronológico, escrita el mismo día.
- La primera columna es la fecha en formato `AAAA-MM-DD`: `proyecto/entrega-final/scripts/verificar_entrega.sh`
  cuenta las filas que empiezan así. Las filas de ejemplo con `AAAA-MM-DD` no cuentan; bórralas al llenar.
- "Cómo lo detectamos" nombra la herramienta o la prueba (`make test`, ThreadSanitizer, comparación con V1,
  `cudaGetLastError`, gráfica que no tenía sentido…). "Salió mal" no es una detección.
- Si el error vino de una sugerencia de IA, se marca en la columna *Origen* y también va en `declaracion-ia.md`.
- El *commit* que corrige la falla se cita por su *hash* corto.

## Errores (qué falló, cómo lo detectamos, qué cambiamos)

| Fecha | Versión | Síntoma observado | Cómo lo detectamos | Causa | Qué cambiamos (commit) | Qué aprendimos (una línea) | Origen (propio / IA / biblioteca) |
|---|---|---|---|---|---|---|---|
| AAAA-MM-DD | V1 / V2 / V3 |  |  |  |  |  |  |
| AAAA-MM-DD |  |  |  |  |  |  |  |
| AAAA-MM-DD |  |  |  |  |  |  |  |

## Mediciones descartadas

Toda corrida que se descartó se anota aquí; nunca se borra en silencio (`proyecto/medicion-en-el-proyecto.md` §3).

| Fecha | Configuración (versión, hilos, n, máquina) | Qué se observó | Por qué se descartó | Qué se hizo después |
|---|---|---|---|---|
| AAAA-MM-DD |  |  |  |  |

## Búsqueda del tamaño declarado (H1)

| Fecha | n probado | T(1) mediana de 5 (s) | ¿≥ 1 s? | Decisión |
|---|---|---|---|---|
| AAAA-MM-DD |  |  |  |  |

## Predicciones vs. resultados (se escribe la predicción ANTES de medir)

| Fecha de la predicción | Qué esperábamos (p. ej. S(4) ≈ 3.2) | Por qué (fracción secuencial, memoria, sincronización) | Resultado medido | Diferencia y explicación (sección del reporte) |
|---|---|---|---|---|
| AAAA-MM-DD |  |  |  |  |

## Qué no entendemos todavía

- (se actualiza en cada hito; se lee en la defensa: es mejor escribirlo aquí que descubrirlo en las preguntas individuales)

## Resumen para el reporte final (se llena al final)

- Error que más tiempo costó y por qué:
- Error que habríamos evitado con una prueba que no teníamos:
- Qué prueba agregamos a raíz de la bitácora:
