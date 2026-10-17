#!/usr/bin/env bash

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MUSIC_CMD="${PLUGIN_DIR}/src/music.sh"
HASH="#"
MUSIC_CMD_QUOTED="$(printf '%q' "${MUSIC_CMD}")"
MUSIC_CMD_QUOTED="${MUSIC_CMD_QUOTED//"${HASH}"/${HASH}${HASH}}"

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
  "#(${MUSIC_CMD_QUOTED} now)"
  "#(${MUSIC_CMD_QUOTED} icon)"
  "#(${MUSIC_CMD_QUOTED} status)"
  "#(${MUSIC_CMD_QUOTED} title)"
  "#(${MUSIC_CMD_QUOTED} artist)"
  "#(${MUSIC_CMD_QUOTED} progress)"
  "#(${MUSIC_CMD_QUOTED} time)"
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
  local value="${1}" i placeholder out rest
  for (( i = 0; i < ${#placeholders[@]}; i++ )); do
    placeholder="${placeholders[i]#\\}"
    out=""
    rest="${value}"
    while [[ "${rest}" == *"${placeholder}"* ]]; do
      out="${out}${rest%%"${placeholder}"*}$(target_for "${commands[i]}")"
      rest="${rest#*"${placeholder}"}"
    done
    value="${out}${rest}"
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
else
  tmux set-option -gqu "@music_revamped_ticker_pid"
fi

music_bind_keys "${MUSIC_CMD}"
