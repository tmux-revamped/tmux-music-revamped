#!/usr/bin/env bash

[[ -n "${_MUSIC_REVAMPED_CONTROL_LOADED:-}" ]] && return 0
_MUSIC_REVAMPED_CONTROL_LOADED=1

_MUSIC_CONTROL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_MUSIC_CONTROL_DIR}/../utils/platform.sh"
# shellcheck source=/dev/null
source "${_MUSIC_CONTROL_DIR}/../utils/has-command.sh"
# shellcheck source=/dev/null
source "${_MUSIC_CONTROL_DIR}/music.sh"

_control_playerctl_arg() {
  case "${1:-}" in
    play-pause) echo "play-pause" ;;
    next)       echo "next" ;;
    prev)       echo "previous" ;;
    *)          return 1 ;;
  esac
}

_control_cmus_arg() {
  case "${1:-}" in
    play-pause) printf '%s\n' "-u" ;;
    next)       printf '%s\n' "-n" ;;
    prev)       printf '%s\n' "-r" ;;
    *)          return 1 ;;
  esac
}

_control_osascript_cmd() {
  case "${1:-}" in
    play-pause) echo "playpause" ;;
    next)       echo "next track" ;;
    prev)       echo "previous track" ;;
    *)          return 1 ;;
  esac
}

_control_playerctl() {
  if [[ -n "${2:-}" ]]; then
    playerctl -p "${2}" "${1}" 2>/dev/null
  else
    playerctl "${1}" 2>/dev/null
  fi
}
_control_cmus() { cmus-remote "${1}" 2>/dev/null; }
_control_osascript() { osascript -e "tell application \"Spotify\" to ${1}" 2>/dev/null; }

music_control_backend() {
  if has_command playerctl; then
    echo "playerctl"
  elif has_command cmus-remote; then
    echo "cmus"
  elif is_macos && has_command osascript; then
    echo "osascript"
  else
    echo "none"
  fi
}

music_control() {
  local verb="${1:-}" arg
  case "$(music_control_backend)" in
    playerctl)
      arg=$(_control_playerctl_arg "${verb}") || return 0
      _control_playerctl "${arg}" "$(music_active_player)"
      ;;
    cmus)
      arg=$(_control_cmus_arg "${verb}") || return 0
      _control_cmus "${arg}"
      ;;
    osascript)
      arg=$(_control_osascript_cmd "${verb}") || return 0
      _control_osascript "${arg}"
      ;;
    *)
      return 0
      ;;
  esac
}

export -f _control_playerctl_arg
export -f _control_cmus_arg
export -f _control_osascript_cmd
export -f _control_playerctl
export -f _control_cmus
export -f _control_osascript
export -f music_control_backend
export -f music_control
