# Bitácora de errores · Equipo NN

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Proyecto integrador · Plantilla que el equipo llena · copia este archivo a la raíz de `cp-6bm1-equipoNN/`

**Para qué sirve.** Registrar cada falla que les costó más de 15 minutos: qué se observó, cómo se detectó, cuál fue
la causa y qué se cambió. Es parte del reporte final y se revisa en H1 (jueves 29 de octubre), H2 (lunes 23 de
noviembre) y la entrega final (lunes 7 de diciembre, 10:30). Una bitácora con "no tuvimos errores" cuenta como
ausente: en un proyecto de tres versiones siempre hay errores.

**Reglas.**
- Una entrada por falla, en orden cronológico. Se escribe el mismo día.
- "Cómo lo detectamos" nombra la herramienta o la prueba (`make test`, ThreadSanitizer, comparación con V1,
  `cudaGetLastError`, gráfica que no tenía sentido…). "Salió mal" no es una detección.
- Si el error vino de una sugerencia de IA, se marca en la columna *Origen* y también va en `declaracion-ia.md`.
- El *commit* que corrige la falla se cita por su *hash* corto.

## Entradas

| # | Fecha | Versión | Síntoma observado | Cómo lo detectamos | Causa | Qué cambiamos | Qué aprendimos (una línea) | Origen (propio / IA / biblioteca) | Commit |
|---|---|---|---|---|---|---|---|---|---|
| 1 | AAAA-MM-DD | V1 / V2 / V3 |  |  |  |  |  |  |  |
| 2 |  |  |  |  |  |  |  |  |  |
| 3 |  |  |  |  |  |  |  |  |  |

## Mediciones descartadas

Toda corrida que se descartó se anota aquí; nunca se borra en silencio.

| Fecha | Configuración (versión, hilos, n) | Qué se observó | Por qué se descartó | Qué se hizo después |
|---|---|---|---|---|
|  |  |  |  |  |

## Resumen para el reporte final (se llena al final)

- Error que más tiempo costó y por qué:
- Error que habríamos evitado con una prueba que no teníamos:
- Qué prueba agregamos a raíz de la bitácora:
