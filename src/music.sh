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
source "${PLUGIN_DIR}/src/lib/music/music.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/music/render.sh"

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

main() {
  local cmd="${1:-}"

  if [[ "${cmd}" == "refresh" ]]; then
    music_refresh
    return 0
  fi

  music_tick

  case "${cmd}" in
    now)    music_render_now "$(cache_get title)" "$(cache_get artist)" ;;
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
