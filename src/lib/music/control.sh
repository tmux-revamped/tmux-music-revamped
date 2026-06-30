#!/usr/bin/env bash
#
# control.sh: playback control across backends.
#
# music_control routes a canonical verb (play-pause, next, prev) to the player
# present on the host, chosen by feature-detection. Each backend exposes a pure
# verb-to-argument mapper and a thin seam that, in production, execs the player.
# Tests override the seams, so no real player is ever launched.

[[ -n "${_MUSIC_REVAMPED_CONTROL_LOADED:-}" ]] && return 0
_MUSIC_REVAMPED_CONTROL_LOADED=1

_MUSIC_CONTROL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_MUSIC_CONTROL_DIR}/../utils/platform.sh"
# shellcheck source=/dev/null
source "${_MUSIC_CONTROL_DIR}/../utils/has-command.sh"

# _control_playerctl_arg VERB -> the playerctl subcommand, non-zero if unknown.
_control_playerctl_arg() {
  case "${1:-}" in
    play-pause) echo "play-pause" ;;
    next)       echo "next" ;;
    prev)       echo "previous" ;;
    *)          return 1 ;;
  esac
}

# _control_cmus_arg VERB -> the cmus-remote flag, non-zero if unknown.
_control_cmus_arg() {
  case "${1:-}" in
    play-pause) printf '%s\n' "-u" ;;
    next)       printf '%s\n' "-n" ;;
    prev)       printf '%s\n' "-r" ;;
    *)          return 1 ;;
  esac
}

# _control_osascript_cmd VERB -> the Spotify AppleScript verb, non-zero if unknown.
_control_osascript_cmd() {
  case "${1:-}" in
    play-pause) echo "playpause" ;;
    next)       echo "next track" ;;
    prev)       echo "previous track" ;;
    *)          return 1 ;;
  esac
}

# Backend seams. Thin wrappers over the player command, overridden in tests so
# no real player is ever invoked.
_control_playerctl() { playerctl "${1}" 2>/dev/null; }
_control_cmus() { cmus-remote "${1}" 2>/dev/null; }
_control_osascript() { osascript -e "tell application \"Spotify\" to ${1}" 2>/dev/null; }

# music_control_backend -> the control backend to use, by feature-detection:
# playerctl, then cmus, then Spotify via AppleScript on macOS, else none.
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

# music_control VERB -> send VERB to the active backend. Unknown verbs and the
# absence of any backend are silent no-ops.
music_control() {
  local verb="${1:-}" arg
  case "$(music_control_backend)" in
    playerctl)
      arg=$(_control_playerctl_arg "${verb}") || return 0
      _control_playerctl "${arg}"
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
