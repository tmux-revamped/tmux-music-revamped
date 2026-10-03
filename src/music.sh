#!/usr/bin/env bash
#
# music.sh: command dispatcher for tmux-music-revamped.
#
# Usage: music.sh now | icon | status | title | artist | refresh

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export CACHE_PREFIX="music_revamped"
export PLUGIN_LOG_NS="music-revamped"

# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/has-command.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/platform.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/cache.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/publish.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/ticker.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/music/music.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/music/render.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/music/control.sh"

music_max_age() {
  get_tmux_option "@music_revamped_interval" "5"
}

music_refresh() {
  local lines=() line
  while IFS= read -r line; do
    lines+=("${line}")
  done < <(read_music)
  cache_set status "$(music_norm_status "${lines[0]:-}")"
  cache_set title "${lines[1]:-}"
  cache_set artist "${lines[2]:-}"
  cache_set position "${lines[3]:-0}"
  cache_set duration "${lines[4]:-0}"
}

music_tick() {
  cache_refresh_if_stale status "$(music_max_age)" music_refresh
}

music_wrap() {
  local out="${1}"
  [[ -n "${out}" ]] || return 0
  printf '%s%s%s\n' "$(get_tmux_option "@music_revamped_before" "")" "${out}" "$(get_tmux_option "@music_revamped_after" "")"
}

music_publish() {
  local metric
  music_refresh
  for metric in $(get_tmux_option "@music_revamped_published" ""); do
    publish_add "@music_revamped_out_${metric}" "$(main "${metric}")"
  done
  publish_commit
}

music_publish_if_options() {
  if [[ "$(get_tmux_option "@music_revamped_render" "jobs")" == "options" ]]; then
    music_publish
  fi
  return 0
}

_music_reexec() { exec "${PLUGIN_DIR}/src/music.sh" daemon; }

music_daemon() {
  if ticker_run music_revamped music_publish "$$"; then
    _music_reexec
  fi
}

main() {
  local cmd="${1:-}"

  if [[ "${cmd}" == "refresh" ]]; then
    music_refresh
    return 0
  fi

  case "${cmd}" in
    play-pause|next|prev)
      music_control "${cmd}"
      music_publish_if_options
      return 0
      ;;
    start)
      ticker_start "${PLUGIN_DIR}/src/music.sh"
      return 0
      ;;
    daemon)
      music_daemon
      return 0
      ;;
  esac

  music_tick

  case "${cmd}" in
    now)    music_wrap "$(music_render_now "$(cache_get title)" "$(cache_get artist)")" ;;
    icon)   music_render_icon "$(cache_get status)" ;;
    status) music_render_text "$(cache_get status)" ;;
    title)  music_render_text "$(cache_get title)" ;;
    artist) music_render_text "$(cache_get artist)" ;;
    progress) music_render_progress "$(cache_get position)" "$(cache_get duration)" ;;
    time)   music_render_time "$(cache_get position)" "$(cache_get duration)" ;;
    *)      return 0 ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
