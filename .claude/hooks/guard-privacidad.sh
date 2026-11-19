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
command -v jq >/dev/null 2>&1 || { echo "guard-privacidad.sh: falta jq (apt-get install -y jq)." >&2; exit 2; }
cmd=$(printf '%s' "$entrada" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 2
[ -z "$cmd" ] && exit 0

# ¿El comando hace commit o push? (git [-C dir | -c k=v | --opción]... commit|push)
RE_GIT='(^|[;&|(`[:space:]])git([[:space:]]+(-[Cc][[:space:]]+[^[:space:]]+|--?[A-Za-z][^[:space:]]*))*[[:space:]]+'
accion=""
if printf '%s' "$cmd" | grep -Eq "${RE_GIT}commit([[:space:]]|$)"; then accion=commit; fi
if printf '%s' "$cmd" | grep -Eq "${RE_GIT}push([[:space:]]|$)"; then accion="${accion:+$accion+}push"; fi
[ -z "$accion" ] && exit 0

negar() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

proyecto=${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}
auditor="$proyecto/herramientas/auditar_privacidad.py"
[ -f "$auditor" ] || exit 0   # rama sin el auditor: no hay con qué revisar
command -v python3 >/dev/null 2>&1 || negar "guard-privacidad.sh: falta python3; no puedo auditar la privacidad antes de 'git $accion'."

# Solo se audita el repositorio del curso; un clon de equipo en otra carpeta no es público ni sigue estas reglas.
cwd=$(printf '%s' "$entrada" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$cwd" ] && [ -d "$cwd" ] || cwd=$proyecto
raiz_cwd=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || exit 0
raiz_proyecto=$(git -C "$proyecto" rev-parse --show-toplevel 2>/dev/null) || exit 0
[ "$raiz_cwd" = "$raiz_proyecto" ] || exit 0

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
      || base=$(git -C "$raiz_proyecto" merge-base HEAD origin/main 2>/dev/null) || base=""
    if [ -n "$base" ]; then auditar --rango "$base..HEAD"; else auditar --todo; fi ;;
esac

case "$rc" in
  0) exit 0 ;;
  1) negar "guard-privacidad.sh: 'git $accion' detenido; el repositorio es público (CONVENCIONES §5).
$(printf '%s' "$informe" | grep -E '^(BLOQUEANTE|AVISO|Resumen)' | head -15)
Corrige los archivos y vuelve a intentar. Si es un falso positivo comprobado, agrega la excepción a herramientas/privacidad-permitidos.txt y dilo en el mensaje del commit. Para lo que requiere juicio, usa el subagente auditor-privacidad." ;;
  *) negar "guard-privacidad.sh: el auditor de privacidad no pudo correr antes de 'git $accion' (código $rc): $(printf '%s' "$informe" | head -3)" ;;
esac
