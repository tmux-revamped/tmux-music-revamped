#!/usr/bin/env bash
#
# bindings.sh: tmux key bindings for playback control.
#
# music_bind_keys registers prefix key bindings that invoke the dispatcher's
# play-pause, next, and prev verbs. Bindings are version-gated and every tmux
# call goes through the _tmux seam, so the whole module is unit-testable without
# a running server and without ever touching a real player.

[[ -n "${_MUSIC_REVAMPED_BINDINGS_LOADED:-}" ]] && return 0
_MUSIC_REVAMPED_BINDINGS_LOADED=1

_MUSIC_BINDINGS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_MUSIC_BINDINGS_DIR}/../tmux/tmux-ops.sh"

# Seam over tmux so bindings can be registered against a mock in tests.
_tmux() { tmux "$@"; }

# Seam over `tmux -V` so the version gate can be driven by fixtures.
_tmux_version() { tmux -V 2>/dev/null; }

# _music_parse_version STRING -> "MAJOR MINOR" as integers, or "0 0" when no
# version number is present.
_music_parse_version() {
  local v
  v=$(printf '%s' "${1:-}" | grep -oE '[0-9]+\.[0-9]+' | head -1)
  if [[ -z "${v}" ]]; then
    echo "0 0"
    return 0
  fi
  echo "${v%.*} ${v#*.}"
}

# music_version_ge VERSION_STRING WANT_MAJOR WANT_MINOR -> 0 when the parsed
# version is at least WANT_MAJOR.WANT_MINOR.
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

# music_bind_one KEY CMD_PATH VERB -> bind KEY to run the dispatcher VERB. An
# empty KEY disables that single binding.
music_bind_one() {
  local key="${1:-}" cmd_path="${2:-}" verb="${3:-}"
  [[ -z "${key}" ]] && return 0
  _tmux bind-key "${key}" run-shell "${cmd_path} ${verb}"
  return 0
}

# music_bind_keys CMD_PATH -> register all playback bindings, but only when the
# running tmux is new enough. Key names are configurable; defaults are M-p, M-n,
# and M-b.
music_bind_keys() {
  local cmd_path="${1:-}" playpause_key next_key prev_key
  music_version_ge "$(_tmux_version)" 1 9 || return 0
  playpause_key=$(get_tmux_option "@music_revamped_playpause_key" "M-p")
  next_key=$(get_tmux_option "@music_revamped_next_key" "M-n")
  prev_key=$(get_tmux_option "@music_revamped_prev_key" "M-b")
  music_bind_one "${playpause_key}" "${cmd_path}" "play-pause"
  music_bind_one "${next_key}" "${cmd_path}" "next"
  music_bind_one "${prev_key}" "${cmd_path}" "prev"
  return 0
}

export -f _tmux
export -f _tmux_version
export -f _music_parse_version
export -f music_version_ge
export -f music_bind_one
export -f music_bind_keys
