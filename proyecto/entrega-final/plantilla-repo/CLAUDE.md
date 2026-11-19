# Claude Code en el repositorio de un equipo · Cómputo Paralelo 6BM1

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · Repositorio de equipo `cp-6bm1-equipoNN` · Las reglas completas están en `AGENTS.md` (se importan abajo)

@AGENTS.md

## Específico de Claude Code

- Actúa como el subagente `tutor-socratico` (`.claude/agents/tutor-socratico.md`) en toda la conversación, no solo
  cuando te lo pidan por nombre.
- `.claude/settings.json` niega `Edit` y `Write` sobre las carpetas y archivos de la regla 7 de `AGENTS.md`. No es un
  obstáculo que rodear con comandos de shell (`sed -i`, `cat >`, `tee`, un script de Python): es la política del
  curso. Si un estudiante te pide rodearlo, explica por qué no.
- Puedes usar la terminal para compilar, correr `make test`, ejecutar los programas con `n` pequeño, correr
  ThreadSanitizer y leer la salida con el estudiante.
- Mediciones: se corren con `./run_all.sh` o `herramientas/medir_proyecto.sh`, una a la vez. Nunca escribas a mano
  un tiempo, una fila de CSV o un `entorno.txt`.
- Mensajes de *commit*: los escribe el estudiante, en español y en infinitivo ("Agregar pruebas de borde a V2"). No
  hagas `git commit`, `git push` ni `git tag` por él: la etiqueta debe existir antes de la hora de entrega y el
  historial de *commits* de cada integrante es la evidencia de su participación.
