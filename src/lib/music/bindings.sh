#!/usr/bin/env bash

[[ -n "${_MUSIC_REVAMPED_BINDINGS_LOADED:-}" ]] && return 0
_MUSIC_REVAMPED_BINDINGS_LOADED=1

_MUSIC_BINDINGS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_MUSIC_BINDINGS_DIR}/../tmux/tmux-ops.sh"

_tmux() { tmux "$@"; }

_tmux_version() { tmux -V 2>/dev/null; }

_music_parse_version() {
  local v
  v=$(printf '%s' "${1:-}" | grep -oE '[0-9]+\.[0-9]+' | head -1)
  if [[ -z "${v}" ]]; then
    echo "0 0"
    return 0
  fi
  echo "${v%.*} ${v#*.}"
}

music_version_ge() {
  local parts have_major have_minor want_major want_minor
  parts=$(_music_parse_version "${1:-}")
  have_major="${parts%% *}"
  have_minor="${parts##* }"
  want_major="${2:-0}"
  want_minor="${3:-0}"
  if (( have_major > want_major )); then
    return 0
  fi
  if (( have_major < want_major )); then
    return 1
  fi
  if (( have_minor >= want_minor )); then
    return 0
  fi
  return 1
}

music_bind_one() {
  local key="${1:-}" cmd_path="${2:-}" verb="${3:-}" hash="#"
  [[ -z "${key}" ]] && return 0
  cmd_path="$(printf '%q' "${cmd_path}")"
  _tmux bind-key "${key}" run-shell "${cmd_path//"${hash}"/${hash}${hash}} ${verb}"
  return 0
}

music_bind_keys() {
  local cmd_path="${1:-}" menu_key playpause_key next_key prev_key
  music_version_ge "$(_tmux_version)" 1 9 || return 0
  menu_key=$(get_tmux_option "@music_revamped_menu_key" "M-m")
  playpause_key=$(get_tmux_option "@music_revamped_playpause_key" "")
  next_key=$(get_tmux_option "@music_revamped_next_key" "")
  prev_key=$(get_tmux_option "@music_revamped_prev_key" "")
  [[ "${menu_key}" == "off" ]] && menu_key=""
  music_bind_one "${menu_key}" "${cmd_path}" "menu"
  music_bind_one "${playpause_key}" "${cmd_path}" "play-pause"
  music_bind_one "${next_key}" "${cmd_path}" "next"
  music_bind_one "${prev_key}" "${cmd_path}" "prev"
  return 0
}

_music_tmux_quote() {
  local quote="'" escaped="'\"'\"'"
  printf "'%s'" "${1//"${quote}"/${escaped}}"
}

music_menu_command() {
  local cmd_path hash="#"
  cmd_path="$(printf '%q' "${1:-}")"
  printf 'run-shell %s' "$(_music_tmux_quote "${cmd_path//"${hash}"/${hash}${hash}} ${2:-}")"
}

music_menu() {
  local cmd_path="${1:-}"
  _tmux display-menu -T "Music" \
    "Play/Pause" p "$(music_menu_command "${cmd_path}" play-pause)" \
    "Next" n "$(music_menu_command "${cmd_path}" next)" \
    "Previous" b "$(music_menu_command "${cmd_path}" prev)"
}

export -f _tmux
export -f _tmux_version
export -f _music_parse_version
export -f music_version_ge
export -f music_bind_one
export -f music_bind_keys
export -f _music_tmux_quote
export -f music_menu_command
export -f music_menu
