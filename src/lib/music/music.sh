#!/usr/bin/env bash
#
# music.sh: now-playing acquisition across backends.
#
# read_music returns three lines: status, title, artist. playerctl is preferred
# where present, with an AppleScript Spotify fallback on macOS. Each probe sits
# behind a seam tests override. music_norm_status is pure.

[[ -n "${_MUSIC_REVAMPED_MUSIC_LOADED:-}" ]] && return 0
_MUSIC_REVAMPED_MUSIC_LOADED=1

_MUSIC_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_MUSIC_LIB_DIR}/../utils/platform.sh"
# shellcheck source=/dev/null
source "${_MUSIC_LIB_DIR}/../utils/has-command.sh"

# music_norm_status RAW -> playing|paused|stopped|unknown.
music_norm_status() {
  case "$(printf '%s' "${1}" | tr '[:upper:]' '[:lower:]')" in
    *playing*) echo "playing" ;;
    *paused*)  echo "paused" ;;
    *stopped*) echo "stopped" ;;
    *)         echo "unknown" ;;
  esac
}

# parse_nowplaying TEXT -> five lines (status, title, artist, position, duration)
# from `nowplaying-cli get title artist playbackRate elapsedTime duration`.
parse_nowplaying() {
  local title artist rate elapsed dur
  title=$(sed -n '1p' <<< "${1}"); artist=$(sed -n '2p' <<< "${1}")
  rate=$(sed -n '3p' <<< "${1}"); elapsed=$(sed -n '4p' <<< "${1}"); dur=$(sed -n '5p' <<< "${1}")
  [[ -z "${title}" || "${title}" == "null" ]] && { echo ""; return 0; }
  local status="paused"
  [[ "${rate}" == "1" || "${rate}" == "1.0" ]] && status="playing"
  printf '%s\n%s\n%s\n%s\n%s\n' "${status}" "${title}" "${artist}" "${elapsed%%.*}" "${dur%%.*}"
}

# parse_osascript TEXT -> five lines (status, title, artist, position, duration)
# from the Spotify AppleScript probe. Position is float seconds; duration is
# milliseconds when it looks like ms (value > 10000), divided by 1000.
parse_osascript() {
  local status title artist pos dur
  status=$(sed -n '1p' <<< "${1}"); title=$(sed -n '2p' <<< "${1}")
  artist=$(sed -n '3p' <<< "${1}"); pos=$(sed -n '4p' <<< "${1}"); dur=$(sed -n '5p' <<< "${1}")
  [[ -z "${title}" ]] && { echo ""; return 0; }
  pos="${pos%%.*}"; dur="${dur%%.*}"
  [[ "${dur}" =~ ^[0-9]+$ && "${dur}" -gt 10000 ]] && dur=$(( dur / 1000 ))
  printf '%s\n%s\n%s\n%s\n%s\n' "${status}" "${title}" "${artist}" "${pos:-0}" "${dur:-0}"
}

# parse_cmus TEXT -> five lines from `cmus-remote -Q`.
parse_cmus() {
  local st status title artist pos dur
  st=$(printf '%s\n' "${1}" | grep '^status ' | head -1 | cut -d' ' -f2-)
  case "${st}" in
    playing) status="playing" ;;
    paused)  status="paused" ;;
    *)       echo ""; return 0 ;;
  esac
  title=$(printf '%s\n' "${1}" | grep '^tag title ' | head -1 | cut -d' ' -f3-)
  artist=$(printf '%s\n' "${1}" | grep '^tag artist ' | head -1 | cut -d' ' -f3-)
  pos=$(printf '%s\n' "${1}" | grep '^position ' | head -1 | cut -d' ' -f2)
  dur=$(printf '%s\n' "${1}" | grep '^duration ' | head -1 | cut -d' ' -f2)
  [[ -z "${title}" ]] && { echo ""; return 0; }
  printf '%s\n%s\n%s\n%s\n%s\n' "${status}" "${title}" "${artist}" "${pos:-0}" "${dur:-0}"
}

# Host-probe seams. The playerctl probes honor _MUSIC_PLAYERCTL_PLAYER when set,
# so read_music can target the player it selected as active.
_read_playerctl_status() {
  if [[ -n "${_MUSIC_PLAYERCTL_PLAYER:-}" ]]; then
    playerctl -p "${_MUSIC_PLAYERCTL_PLAYER}" status 2>/dev/null
  else
    playerctl status 2>/dev/null
  fi
}
_read_playerctl_meta() {
  if [[ -n "${_MUSIC_PLAYERCTL_PLAYER:-}" ]]; then
    playerctl -p "${_MUSIC_PLAYERCTL_PLAYER}" metadata "${1}" 2>/dev/null
  else
    playerctl metadata "${1}" 2>/dev/null
  fi
}
_read_playerctl_position() {
  if [[ -n "${_MUSIC_PLAYERCTL_PLAYER:-}" ]]; then
    playerctl -p "${_MUSIC_PLAYERCTL_PLAYER}" position 2>/dev/null
  else
    playerctl position 2>/dev/null
  fi
}
_read_playerctl_list() { playerctl --list-all 2>/dev/null; }
_read_playerctl_status_of() { playerctl -p "${1}" status 2>/dev/null; }
_read_nowplaying() { nowplaying-cli get title artist playbackRate elapsedTime duration 2>/dev/null; }
_read_cmus() { cmus-remote -Q 2>/dev/null; }
_read_osascript() {
  osascript 2>/dev/null <<'APPLESCRIPT'
on run
  if application "Spotify" is running then
    tell application "Spotify"
      set st to player state as string
      set tt to name of current track
      set ar to artist of current track
      set pp to player position as string
      set du to duration of current track as string
      return st & linefeed & tt & linefeed & ar & linefeed & pp & linefeed & du
    end tell
  end if
end run
APPLESCRIPT
}

# music_pick_player LINES -> choose a player from a newline-separated list of
# "NAME STATUS" pairs. Returns the first NAME whose STATUS is Playing, else the
# first NAME, else empty. Pure: every input is an argument.
music_pick_player() {
  local first="" name status line
  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    name="${line%% *}"
    status="${line#* }"
    [[ -z "${first}" ]] && first="${name}"
    case "$(printf '%s' "${status}" | tr '[:upper:]' '[:lower:]')" in
      *playing*) echo "${name}"; return 0 ;;
    esac
  done <<< "${1:-}"
  echo "${first}"
  return 0
}

# music_active_player -> the playerctl player to query, preferring the one that
# is Playing when several are present. Empty when no player is listed. The player
# list and per-player status come from seams, so tests drive it with fixtures.
music_active_player() {
  local players lines="" name
  players=$(_read_playerctl_list)
  [[ -z "${players}" ]] && { echo ""; return 0; }
  while IFS= read -r name; do
    [[ -z "${name}" ]] && continue
    lines+="${name} $(_read_playerctl_status_of "${name}")"$'\n'
  done <<< "${players}"
  music_pick_player "${lines}"
}

# read_music -> up to five lines (status, title, artist, position, duration), or
# nothing when idle. Backends are tried in order of richness.
read_music() {
  if is_macos && has_command nowplaying-cli; then
    parse_nowplaying "$(_read_nowplaying)"
  elif has_command playerctl && [[ -n "$(_read_playerctl_status)" ]]; then
    local status dur dur_us _MUSIC_PLAYERCTL_PLAYER
    _MUSIC_PLAYERCTL_PLAYER=$(music_active_player)
    status=$(_read_playerctl_status)
    dur_us=$(_read_playerctl_meta mpris:length)
    [[ "${dur_us}" =~ ^[0-9]+$ ]] && dur=$(( dur_us / 1000000 )) || dur=0
    printf '%s\n%s\n%s\n%s\n%s\n' "${status}" \
      "$(_read_playerctl_meta title)" "$(_read_playerctl_meta artist)" \
      "$(_read_playerctl_position | cut -d. -f1)" "${dur}"
  elif has_command cmus-remote; then
    parse_cmus "$(_read_cmus)"
  elif is_macos && has_command osascript; then
    parse_osascript "$(_read_osascript)"
  fi
}

export -f music_norm_status
export -f parse_nowplaying
export -f parse_osascript
export -f parse_cmus
export -f _read_playerctl_status
export -f _read_playerctl_meta
export -f _read_playerctl_position
export -f _read_playerctl_list
export -f _read_playerctl_status_of
export -f music_pick_player
export -f music_active_player
export -f _read_nowplaying
export -f _read_cmus
export -f _read_osascript
export -f read_music
