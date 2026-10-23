#!/bin/bash
# guard-bash.sh — Hook PreToolUse(Bash) de Claude Code · Cómputo Paralelo · 6BM1 · ESCOM-IPN
# Bloquea los comandos que destruyen trabajo sin posibilidad de recuperarlo y pide confirmación para los que
# descartan cambios locales. Entrada: JSON por stdin con .tool_input.command. Salida: JSON con permissionDecision
# (deny | ask) o nada (= permitir). Si no puede analizar la entrada, bloquea con exit 2: un guardia que falla
# abierto no es guardia. Es un guardarraíl, no un sandbox: no cubre borrados desde Python ni `find -delete`.
set -uo pipefail
set -f   # sin expansión de comodines al partir el comando en palabras ("rm -rf *" no debe expandirse aquí)

entrada=$(cat)
if ! command -v jq >/dev/null 2>&1; then
  echo "guard-bash.sh: falta jq y no puedo analizar el comando. Instala jq (apt-get install -y jq)." >&2
  exit 2
fi
if ! printf '%s' "$entrada" | jq -e . >/dev/null 2>&1; then
  echo "guard-bash.sh: la entrada del hook no es JSON válido; comando bloqueado por precaución." >&2
  exit 2
fi
cmd=$(printf '%s' "$entrada" | jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

decidir() { # $1 = deny | ask · $2 = razón (se muestra a Claude en deny y al usuario en ask)
  jq -n --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:$d,permissionDecisionReason:$r}}'
  exit 0
}

# Parte un texto de shell en comandos simples (separadores ; & | saltos de línea, $( ) y ` `) y revisa cada uno.
analizar() {
  local seg
  while IFS= read -r seg; do
    seg=$(printf '%s' "$seg" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
    [ -z "$seg" ] && continue
    revisar_simple "$seg"
  done < <(printf '%s\n' "$1" | sed -E 's/\$\(/\n/g; s/`/\n/g; s/[;&|]+/\n/g')
}

# Revisa un comando simple: salta prefijos (VAR=valor, sudo, env, time…), identifica el programa y sus argumentos.
revisar_simple() {
  local seg=$1
  local -a tok
  # shellcheck disable=SC2206
  tok=($seg)
  local i=0 n=${#tok[@]} t
  while [ "$i" -lt "$n" ]; do
    t=${tok[$i]}
    if [[ $t =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then i=$((i+1)); continue; fi
    case "$t" in
      sudo|doas|env|nohup|time|exec|command|builtin|nice|ionice|stdbuf|timeout)
        local prefijo=$t; i=$((i+1))
        while [ "$i" -lt "$n" ]; do
          if [[ ${tok[$i]} == -* ]]; then i=$((i+1)); continue; fi
          if [ "$prefijo" = timeout ] && [[ ${tok[$i]} =~ ^[0-9] ]]; then i=$((i+1)); prefijo=""; continue; fi
          break
        done
        continue ;;
    esac
    break
  done
  [ "$i" -ge "$n" ] && return 0
  local nombre=${tok[$i]#\\}; nombre=${nombre##*/}
  local -a resto=("${tok[@]:$((i+1))}")
  local a

  case "$nombre" in
    rm)
      local rec=0 force=0
      for a in "${resto[@]}"; do
        case "$a" in
          --) break ;;
          --recursive) rec=1 ;;
          --force) force=1 ;;
          --*) ;;
          -*) [[ $a == *[rR]* ]] && rec=1; [[ $a == *f* ]] && force=1 ;;
        esac
      done
      if [ "$rec" = 1 ] && [ "$force" = 1 ]; then
        decidir deny "guard-bash.sh: 'rm' recursivo y forzado bloqueado ($seg). Usa 'make clean', borra rutas concretas sin -rf, o pide al usuario que lo haga."
      fi ;;
    git)
      local j=0 sub=""
      while [ "$j" -lt "${#resto[@]}" ]; do
        a=${resto[$j]}
        case "$a" in
          -C|-c|--git-dir|--work-tree|--namespace|--exec-path) j=$((j+2)); continue ;;
          -*) j=$((j+1)); continue ;;
          *) sub=$a; break ;;
        esac
      done
      local -a args=()
      [ "$j" -lt "${#resto[@]}" ] && args=("${resto[@]:$((j+1))}")
      case "$sub" in
        push)
          for a in "${args[@]}"; do
            case "$a" in
              --force|--force=*|--force-with-lease*|--force-if-includes|-f)
                decidir deny "guard-bash.sh: 'git push --force' está prohibido en este repositorio (CLAUDE.md). Haz un commit nuevo o abre un PR." ;;
              -[!-]*) [[ $a == *f* ]] && decidir deny "guard-bash.sh: 'git push -f' está prohibido en este repositorio (CLAUDE.md)." ;;
              +[A-Za-z]*) decidir deny "guard-bash.sh: refspec con '+' equivale a push forzado; prohibido en este repositorio." ;;
            esac
          done ;;
        reset)
          for a in "${args[@]}"; do [ "$a" = --hard ] && decidir ask "guard-bash.sh: 'git reset --hard' descarta cambios locales sin recuperación. ¿Confirmas?"; done ;;
        clean)
          for a in "${args[@]}"; do
            if [ "$a" = --force ] || { [[ $a == -[!-]* ]] && [[ $a == *[fdx]* ]]; }; then
              decidir ask "guard-bash.sh: 'git clean' borra archivos no versionados sin recuperación. ¿Confirmas?"
            fi
          done ;;
        branch)
          for a in "${args[@]}"; do [[ $a == -[!-]* && $a == *D* ]] && decidir ask "guard-bash.sh: 'git branch -D' borra una rama aunque no esté fusionada. ¿Confirmas?"; done ;;
        checkout|restore)
          for a in "${args[@]}"; do [ "$a" = . ] && decidir ask "guard-bash.sh: '$sub .' descarta los cambios de todo el árbol de trabajo. ¿Confirmas?"; done ;;
        stash)
          case "${args[0]:-}" in drop|clear) decidir ask "guard-bash.sh: 'git stash ${args[0]}' borra cambios guardados. ¿Confirmas?" ;; esac ;;
      esac ;;
    bash|sh|zsh|dash|ksh)
      local k=0
      for a in "${resto[@]}"; do
        if [ "$a" = -c ] && [ "$((k+1))" -lt "${#resto[@]}" ]; then
          local interior="${resto[*]:$((k+1))}"
          interior=$(printf '%s' "$interior" | tr -d "\"'")
          analizar "$interior"; break
        fi
        k=$((k+1))
      done ;;
    xargs|find)
      local resto_txt="${resto[*]:-}"
      if [[ $resto_txt == *rm* ]]; then
        [[ $resto_txt == *-exec* ]] && resto_txt=${resto_txt#*-exec }
        [[ $resto_txt == *-execdir* ]] && resto_txt=${resto_txt#*-execdir }
        revisar_simple "$resto_txt"
      fi ;;
  esac
  return 0
}

analizar "$cmd"
exit 0
