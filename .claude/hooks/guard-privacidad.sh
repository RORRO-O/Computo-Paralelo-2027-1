#!/bin/bash
# guard-privacidad.sh — Hook PreToolUse(Bash) de Claude Code · Cómputo Paralelo · 6BM1 · ESCOM-IPN
# Antes de un `git commit` o `git push` corre herramientas/auditar_privacidad.py y niega el comando si hay un
# hallazgo BLOQUEANTE (docs/CONVENCIONES.md §5: el repositorio es público; docente/, nombres, correos, boletas y
# calificaciones no entran). Con `git commit` audita todo lo que difiere de HEAD (el comando puede traer su propio
# `git add`); con `git push`, los commits que todavía no están en el remoto.
# Entrada: JSON por stdin con .tool_input.command y .cwd. Salida: JSON con permissionDecision=deny, o nada (permitir).
# Si no puede auditar (falta jq o python3, el script falla), bloquea: un guardia que falla abierto no es guardia.
# Es un guardarraíl mecánico; el juicio (¿esto es una solución?, ¿esto identifica a alguien?) es del subagente
# auditor-privacidad. No cubre commits hechos fuera de Claude Code: para esos, `git config core.hooksPath .githooks`.
set -uo pipefail

entrada=$(cat)
# Sin jq no se puede leer el comando con precisión: se deja pasar lo que ni menciona git (p. ej. instalar jq).
if ! command -v jq >/dev/null 2>&1; then
  printf '%s' "$entrada" | grep -qw git || exit 0
  echo "guard-privacidad.sh: falta jq (apt-get install -y jq) y el comando menciona git." >&2; exit 2
fi
cmd=$(printf '%s' "$entrada" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 2
[ -z "$cmd" ] && exit 0

# ¿El comando hace commit o push? Criterio amplio a propósito: basta que aparezcan las palabras `git` y `commit` o
# `push` en cualquier forma (/usr/bin/git, git -c k=v commit, bash -c '...', commit;). Auditar de más cuesta un
# segundo; auditar de menos publica un dato.
printf '%s' "$cmd" | grep -qw git || exit 0
accion=""
if printf '%s' "$cmd" | grep -qw commit; then accion=commit; fi
if printf '%s' "$cmd" | grep -qw push; then accion="${accion:+$accion+}push"; fi
[ -z "$accion" ] && exit 0

negar() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

# El guardia audita el estado ANTES de que corra el comando: no ve lo que el mismo comando agregue a la fuerza.
if printf '%s' "$cmd" | grep -qw add && printf '%s' "$cmd" | grep -Eq -e '(^|[[:space:]])(-[A-Za-z]*f[A-Za-z]*|--force)([[:space:]]|$)' -e 'docente'; then
  negar "guard-privacidad.sh: 'git add' forzado o sobre docente/ en el mismo comando que 'git $accion'. Haz el 'git add' en un comando aparte (sin -f sobre rutas ignoradas) para que la auditoría vea el índice."
fi

proyecto=${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}
auditor="$proyecto/herramientas/auditar_privacidad.py"
[ -f "$auditor" ] || exit 0   # rama sin el auditor: no hay con qué revisar
command -v python3 >/dev/null 2>&1 || negar "guard-privacidad.sh: falta python3; no puedo auditar la privacidad antes de 'git $accion'."

cwd=$(printf '%s' "$entrada" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$cwd" ] && [ -d "$cwd" ] || cwd=$proyecto
raiz_proyecto=$(git -C "$proyecto" rev-parse --show-toplevel 2>/dev/null) || exit 0
comun() { (cd "$1" 2>/dev/null && cd "$(git rev-parse --git-common-dir 2>/dev/null)" 2>/dev/null && pwd -P); }
# Un worktree del mismo repositorio se audita en su propia carpeta; desde cualquier otro lugar (el comando puede
# traer su `cd`), se audita el repositorio del curso.
raiz_cwd=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || raiz_cwd=""
if [ -n "$raiz_cwd" ] && [ "$(comun "$raiz_cwd")" = "$(comun "$raiz_proyecto")" ]; then raiz_proyecto=$raiz_cwd; fi

auditar() { # $@ = modo del auditor; acumula la salida en $informe y deja $rc
  local salida
  salida=$(python3 "$auditor" --repo "$raiz_proyecto" "$@" 2>&1); local r=$?
  informe+="$salida"$'\n'
  [ "$r" -gt "$rc" ] && rc=$r
}

rc=0; informe=""
case "$accion" in
  *commit*) auditar --arbol ;;
esac
case "$accion" in
  *push*)
    base=$(git -C "$raiz_proyecto" rev-parse -q --verify '@{upstream}' 2>/dev/null) \
      || base=$(git -C "$raiz_proyecto" rev-parse -q --verify origin/main 2>/dev/null) || base=""
    if [ -n "$base" ]; then auditar --rango "$base..HEAD"; else auditar --todo; fi ;;
esac

case "$rc" in
  0) exit 0 ;;
  1) negar "guard-privacidad.sh: 'git $accion' detenido; el repositorio es público (CONVENCIONES §5).
$(printf '%s' "$informe" | grep -E '^(BLOQUEANTE|AVISO|Resumen)' | head -15)
Corrige los archivos y vuelve a intentar. Si es un falso positivo comprobado, agrega la excepción a herramientas/privacidad-permitidos.txt y dilo en el mensaje del commit. Para lo que requiere juicio, usa el subagente auditor-privacidad." ;;
  *) negar "guard-privacidad.sh: el auditor de privacidad no pudo correr antes de 'git $accion' (código $rc): $(printf '%s' "$informe" | head -3)" ;;
esac
