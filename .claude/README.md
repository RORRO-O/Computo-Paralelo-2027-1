# Configuración de Claude Code para este repositorio

> **Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1** · `.claude/` · qué hace cada pieza y qué hay que activar fuera del repositorio

Todo lo que está en esta carpeta se carga solo al abrir el repositorio con Claude Code (terminal, app o sesión
cloud de un solo repositorio). Lo que **no** vive en el repositorio y hay que configurar una vez en claude.ai está en
la sección "Fuera del repositorio".

## Qué hay aquí

| Archivo | Qué hace | Cuándo actúa |
|---|---|---|
| `../CLAUDE.md` | Contexto del curso: estructura, banderas, protocolo de medición, reglas de código, privacidad, tabla de agentes y skills | Siempre, al inicio de cada sesión |
| `settings.json` | Variables de entorno para MPI como root (`OMPI_ALLOW_RUN_AS_ROOT*`, `MPIRUN_FLAGS=--oversubscribe`), permisos del toolchain, registro de los tres hooks | Siempre. En una máquina local los `allow` aplican tras aceptar el diálogo de confianza de la carpeta |
| `hooks/session-start.sh` | Solo en sesiones cloud: comprueba e instala lo que falte (MPI, Archer, hyperfine, numba, mpi4py, nbformat…), exporta variables y resume el hardware al contexto | Al iniciar o reanudar una sesión cloud |
| `hooks/guard-bash.sh` | Bloquea `rm -rf` (en todas sus formas) y `git push --force`; pide confirmación para `git reset --hard`, `git clean -f`, `git checkout -- .`, `git branch -D`, `git stash drop` | Antes de cada comando de shell |
| `hooks/check-source.sh` | Compila con `-std=c11 -O2 -Wall -Wextra -fopenmp -fsyntax-only` cada `.c/.cpp/.cu/.py` editado y devuelve errores y warnings a Claude | Después de cada edición |
| `agents/*.md` | Subagentes: `openmp-reviewer`, `mpi-reviewer`, `cuda-reviewer`, `perf-analyst`, `revisor-material`, `calificador`, `tutor-socratico` | Cuando Claude delega o se le pide por nombre |
| `skills/*/SKILL.md` | Skills: `/medir`, `/graficar`, `/race-check`, `/revisar-practica` | Al invocarlas con `/nombre` o cuando aplican |
| `cloud-setup-script.sh` | Texto para pegar en el *setup script* del entorno cloud (no se ejecuta desde aquí) | Una vez, en claude.ai |

Las skills `/medir` y `/graficar` usan `herramientas/medir.sh` y `herramientas/graficar_speedup.py` cuando existen (son
los oficiales del curso). Si no existen en la rama, usan sus propios scripts de respaldo, que escriben y leen **el
mismo CSV del protocolo**, así que los resultados son intercambiables.

## Comprobar que todo está bien

```bash
jq . .claude/settings.json > /dev/null && echo "settings OK"
bash -n .claude/hooks/*.sh .claude/skills/*/scripts/*.sh && echo "scripts OK"
python3 - <<'PY'
import glob, yaml
for f in glob.glob(".claude/agents/*.md") + glob.glob(".claude/skills/*/SKILL.md"):
    fm = open(f, encoding="utf-8").read().split("---")[1]
    d = yaml.safe_load(fm); assert d["name"] and d["description"], f
print("frontmatter OK")
PY
printf '{"tool_input":{"command":"rm -rf build"}}' | .claude/hooks/guard-bash.sh      # debe devolver deny
printf '{"tool_input":{"command":"git push --force"}}' | .claude/hooks/guard-bash.sh # debe devolver deny
```

## Fuera del repositorio (configurar una vez en claude.ai)

1. **Setup script del entorno cloud.** Pega `cloud-setup-script.sh` en el entorno (menú del entorno → Edit → Setup
   script). Así cada sesión nueva ya trae MPI, Archer, hyperfine, numba y mpi4py sin esperar al hook. Red del
   entorno: la política por defecto ("Trusted") ya permite apt y pip.
2. **GitHub App de Claude** en el repositorio, para que las sesiones cloud puedan abrir PRs y para activar
   el auto-fix de CI y las revisiones con `@claude` (`/install-github-app` desde una terminal local).
3. **Remote Control** en la PC del laboratorio con GPU: `claude remote-control` dentro del clon del repositorio.
   La máquina aparece en la app de Claude Code con las mismas skills y agentes, pero con `nvcc`, `compute-sanitizer`
   y los núcleos reales. Ahí se hacen las mediciones finales y la P6.
4. **Conectores** ya conectados (GitHub, Google Calendar, Drive, Notion, Slack, Claude Docs, Canva): sirven para la
   planeación (eventos de sesiones y entregas), la retroalimentación (documentos compartidos) y las diapositivas.
5. **Tareas programadas** (desde una sesión cloud): por ejemplo, el lunes de cada semana correr `./verificar.sh`
   sobre `main` y abrir un issue si algo falla; la víspera de cada entrega, listar los PRs sin revisar.

## Límites conocidos

- Los hooks del repositorio solo corren en sesiones cloud de **un** repositorio (no en sesiones multirepo ni en
  hilos de Projects) y solo cuando la rama clonada ya contiene estos archivos (es decir, tras fusionar a `main`).
- `guard-bash.sh` es un guardarraíl, no un sandbox: no detecta borrados hechos desde Python o con `find -delete`.
  Si falta `jq`, bloquea todo comando hasta que se instale.
- `permissions.deny` de lectura no detiene a un programa que lea archivos por su cuenta (`grep -r`, un script).
- El contenedor cloud no expone contadores de hardware: `perf stat -e cycles` devuelve `not supported`. Para caché
  y false sharing usa `valgrind --tool=cachegrind --cache-sim=yes` con un tamaño pequeño.
