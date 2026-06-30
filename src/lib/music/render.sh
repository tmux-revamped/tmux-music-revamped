#!/usr/bin/env bash
#
# render.sh: map cached now-playing values to text and an icon.

[[ -n "${_MUSIC_REVAMPED_RENDER_LOADED:-}" ]] && return 0
_MUSIC_REVAMPED_RENDER_LOADED=1

_MUSIC_RENDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_MUSIC_RENDER_DIR}/../tmux/tmux-ops.sh"

# _music_truncate TEXT MAX -> TEXT shortened to MAX characters with an ellipsis.
_music_truncate() {
  local text="${1}" max="${2}"
  [[ "${max}" =~ ^[0-9]+$ ]] || { echo "${text}"; return 0; }
  (( max <= 0 )) && { echo "${text}"; return 0; }
  if (( ${#text} > max )); then
    echo "${text:0:max}..."
  else
    echo "${text}"
  fi
}

music_render_now() {
  local title="${1}" artist="${2}"
  [[ -z "${title}" ]] && { echo ""; return 0; }
  local max
  max=$(get_tmux_option "@music_revamped_max_len" "0")
  title=$(_music_truncate "${title}" "${max}")
  if [[ -z "${artist}" ]]; then
    echo "${title}"
    return 0
  fi
  artist=$(_music_truncate "${artist}" "${max}")
  local fmt
  fmt=$(get_tmux_option "@music_revamped_format" "%s - %s")
  # shellcheck disable=SC2059
  printf "${fmt}" "${title}" "${artist}"
}

# music_is_active STATUS -> 0 when STATUS means a track is loaded (playing or
# paused), non-zero when nothing is playing (stopped, unknown, or empty).
music_is_active() {
  case "${1:-}" in
    playing|paused) return 0 ;;
    *) return 1 ;;
  esac
}

music_render_icon() {
  local status="${1:-unknown}"
  if [[ "$(get_tmux_option "@music_revamped_auto_hide" "1")" == "1" ]] \
    && ! music_is_active "${status}"; then
    echo ""
    return 0
  fi
  case "${status}" in
    playing) get_tmux_option "@music_revamped_playing_icon" ">" ;;
    paused)  get_tmux_option "@music_revamped_paused_icon" "||" ;;
    stopped) get_tmux_option "@music_revamped_stopped_icon" "[]" ;;
    *)       get_tmux_option "@music_revamped_unknown_icon" "" ;;
  esac
}

music_render_text() {
  echo "${1}"
}

# music_format_time SECONDS -> "M:SS".
music_format_time() {
  local s="${1%%.*}"
  [[ "${s}" =~ ^[0-9]+$ ]] || s=0
  printf '%d:%02d' $(( s / 60 )) $(( s % 60 ))
}

# music_build_progress POS DUR WIDTH FULL EMPTY -> a progress bar string.
music_build_progress() {
  local pos="${1%%.*}" dur="${2%%.*}" width="${3:-10}" full="${4:-#}" empty="${5:--}"
  [[ "${pos}" =~ ^[0-9]+$ ]] || pos=0
  [[ "${dur}" =~ ^[0-9]+$ ]] || dur=0
  [[ "${width}" =~ ^[0-9]+$ ]] || width=10
  local filled=0
  (( dur > 0 )) && filled=$(( (pos * width) / dur ))
  (( filled > width )) && filled=width
  (( filled < 0 )) && filled=0
  local out="" i
  for (( i = 0; i < filled; i++ )); do out+="${full}"; done
  for (( i = filled; i < width; i++ )); do out+="${empty}"; done
  echo "${out}"
}

music_render_progress() {
  [[ -z "${2}" || "${2}" == "0" ]] && { echo ""; return 0; }
  local width full empty
  width=$(get_tmux_option "@music_revamped_progress_width" "10")
  full=$(get_tmux_option "@music_revamped_progress_full" "█")
  empty=$(get_tmux_option "@music_revamped_progress_empty" "░")
  music_build_progress "${1}" "${2}" "${width}" "${full}" "${empty}"
}

music_render_time() {
  [[ -z "${2}" || "${2}" == "0" ]] && { echo ""; return 0; }
  local fmt
  fmt=$(get_tmux_option "@music_revamped_time_format" "%s/%s")
  # shellcheck disable=SC2059
  printf "${fmt}" "$(music_format_time "${1}")" "$(music_format_time "${2}")"
}

export -f _music_truncate
export -f music_render_now
export -f music_is_active
export -f music_render_icon
export -f music_render_text
export -f music_format_time
export -f music_build_progress
export -f music_render_progress
export -f music_render_time
