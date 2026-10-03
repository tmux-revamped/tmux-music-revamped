#!/usr/bin/env bash
#
# music-revamped.tmux: TPM entry point.
#
# Replaces the #{music*} placeholders in status-left and status-right with calls
# to the dispatcher, which reads cached values and never blocks the render.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MUSIC_CMD="${PLUGIN_DIR}/src/music.sh"

# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/music/bindings.sh"

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

render_mode="$(tmux show-option -gqv "@music_revamped_render")"

target_for() {
  local command="${1}" metric
  metric="${command##* }"
  metric="${metric%)}"
  if [[ "${render_mode}" == "options" ]]; then
    printf '#{E:@music_revamped_out_%s}' "${metric}"
  else
    printf '%s' "${command}"
  fi
}

interpolate() {
  local value="${1}"
  local i
  for (( i = 0; i < ${#placeholders[@]}; i++ )); do
    value="${value//${placeholders[i]}/$(target_for "${commands[i]}")}"
  done
  echo "${value}"
}

used_metrics() {
  local text="${1}" used="" i metric
  for (( i = 0; i < ${#placeholders[@]}; i++ )); do
    metric="${commands[i]##* }"
    metric="${metric%)}"
    if [[ "${text}" == *${placeholders[i]}* || "${text}" == *"@music_revamped_out_${metric}}"* ]]; then
      used="${used:+${used} }${metric}"
    fi
  done
  echo "${used}"
}

update_option() {
  local option="${1}"
  local current
  current=$(tmux show-option -gqv "${option}")
  tmux set-option -gq "${option}" "$(interpolate "${current}")"
}

chmod +x "${MUSIC_CMD}" 2>/dev/null || true

status_text="$(tmux show-option -gqv status-left) $(tmux show-option -gqv status-right)"
tmux set-option -gq "@music_revamped_published" "$(used_metrics "${status_text}")"

update_option "status-left"
update_option "status-right"

if [[ "${render_mode}" == "options" ]]; then
  "${MUSIC_CMD}" start 2>/dev/null || true
fi

music_bind_keys "${MUSIC_CMD}"
