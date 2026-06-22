#!/usr/bin/env bash
#
# music-revamped.tmux: TPM entry point.
#
# Replaces the #{music*} placeholders in status-left and status-right with calls
# to the dispatcher, which reads cached values and never blocks the render.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MUSIC_CMD="${PLUGIN_DIR}/src/music.sh"

placeholders=(
  "\#{music}"
  "\#{music_icon}"
  "\#{music_status}"
  "\#{music_title}"
  "\#{music_artist}"
  "\#{music_progress}"
  "\#{music_time}"
)

commands=(
  "#(${MUSIC_CMD} now)"
  "#(${MUSIC_CMD} icon)"
  "#(${MUSIC_CMD} status)"
  "#(${MUSIC_CMD} title)"
  "#(${MUSIC_CMD} artist)"
  "#(${MUSIC_CMD} progress)"
  "#(${MUSIC_CMD} time)"
)

interpolate() {
  local value="${1}"
  local i
  for (( i = 0; i < ${#placeholders[@]}; i++ )); do
    value="${value//${placeholders[i]}/${commands[i]}}"
  done
  echo "${value}"
}

update_option() {
  local option="${1}"
  local current
  current=$(tmux show-option -gqv "${option}")
  tmux set-option -gq "${option}" "$(interpolate "${current}")"
}

chmod +x "${MUSIC_CMD}" 2>/dev/null || true

update_option "status-left"
update_option "status-right"
