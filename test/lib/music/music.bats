#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _MUSIC_REVAMPED_MUSIC_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/music/music.sh"
}

teardown() {
  cleanup_test_environment
}

@test "music.sh - music_norm_status normalizes states" {
  [[ "$(music_norm_status Playing)" == "playing" ]]
  [[ "$(music_norm_status Paused)" == "paused" ]]
  [[ "$(music_norm_status Stopped)" == "stopped" ]]
  [[ "$(music_norm_status weird)" == "unknown" ]]
}

@test "music.sh - parse_nowplaying builds a five-field record" {
  local txt=$'Song\nBand\n1\n83.5\n240.0'
  run parse_nowplaying "${txt}"
  [[ "${lines[0]}" == "playing" ]]
  [[ "${lines[1]}" == "Song" ]]
  [[ "${lines[2]}" == "Band" ]]
  [[ "${lines[3]}" == "83" ]]
  [[ "${lines[4]}" == "240" ]]
}

@test "music.sh - parse_nowplaying is empty for a null title" {
  [[ -z "$(parse_nowplaying $'null\n\n0\n0\n0')" ]]
}

@test "music.sh - parse_osascript builds a five-field record" {
  local txt=$'playing\nSong\nBand\n83.5\n240000'
  run parse_osascript "${txt}"
  [[ "${lines[0]}" == "playing" ]]
  [[ "${lines[1]}" == "Song" ]]
  [[ "${lines[2]}" == "Band" ]]
  [[ "${lines[3]}" == "83" ]]
  [[ "${lines[4]}" == "240" ]]
}

@test "music.sh - parse_osascript keeps seconds-scale duration" {
  local txt=$'paused\nSong\nBand\n5.0\n200'
  run parse_osascript "${txt}"
  [[ "${lines[3]}" == "5" ]]
  [[ "${lines[4]}" == "200" ]]
}

@test "music.sh - parse_osascript is empty for an empty title" {
  [[ -z "$(parse_osascript $'playing\n\n\n0\n0')" ]]
}

@test "music.sh - parse_cmus builds a record" {
  local txt=$'status playing\ntag title Song\ntag artist Band\nposition 30\nduration 200'
  run parse_cmus "${txt}"
  [[ "${lines[0]}" == "playing" ]]
  [[ "${lines[1]}" == "Song" ]]
  [[ "${lines[3]}" == "30" ]]
  [[ "${lines[4]}" == "200" ]]
}

@test "music.sh - parse_cmus is empty when stopped" {
  [[ -z "$(parse_cmus 'status stopped')" ]]
}

@test "music.sh - read_music uses nowplaying-cli on macOS" {
  _PLATFORM_OS_CACHE="Darwin"
  has_command() { [[ "$1" == "nowplaying-cli" ]]; }
  _read_nowplaying() { printf 'Song\nBand\n1\n10.0\n200.0\n'; }
  run read_music
  [[ "${lines[0]}" == "playing" ]]
  [[ "${lines[3]}" == "10" ]]
}

@test "music.sh - read_music uses playerctl when present" {
  _PLATFORM_OS_CACHE="Linux"
  has_command() { [[ "$1" == "playerctl" ]]; }
  _read_playerctl_status() { echo "Playing"; }
  _read_playerctl_meta() { case "$1" in title) echo "Song" ;; artist) echo "Band" ;; mpris:length) echo "200000000" ;; esac; }
  _read_playerctl_position() { echo "30.5"; }
  run read_music
  [[ "${lines[0]}" == "Playing" ]]
  [[ "${lines[1]}" == "Song" ]]
  [[ "${lines[3]}" == "30" ]]
  [[ "${lines[4]}" == "200" ]]
}

@test "music.sh - read_music uses cmus when present" {
  _PLATFORM_OS_CACHE="Linux"
  has_command() { [[ "$1" == "cmus-remote" ]]; }
  _read_cmus() { printf 'status paused\ntag title S\ntag artist A\nposition 5\nduration 100\n'; }
  run read_music
  [[ "${lines[0]}" == "paused" ]]
  [[ "${lines[1]}" == "S" ]]
}

@test "music.sh - read_music is empty when playerctl has no player" {
  _PLATFORM_OS_CACHE="Linux"
  has_command() { [[ "$1" == "playerctl" ]]; }
  _read_playerctl_status() { echo ""; }
  run read_music
  [[ -z "${output}" ]]
}

@test "music.sh - read_music falls back to osascript on macOS" {
  _PLATFORM_OS_CACHE="Darwin"
  has_command() { [[ "$1" == "osascript" ]]; }
  _read_osascript() { printf 'playing\nSong\nBand\n83.5\n240000\n'; }
  run read_music
  [[ "${lines[0]}" == "playing" ]]
  [[ "${lines[1]}" == "Song" ]]
  [[ "${lines[3]}" == "83" ]]
  [[ "${lines[4]}" == "240" ]]
}

@test "music.sh - read_music is empty when Spotify is not running" {
  _PLATFORM_OS_CACHE="Darwin"
  has_command() { [[ "$1" == "osascript" ]]; }
  _read_osascript() { printf ''; }
  run read_music
  [[ -z "${output}" ]]
}

@test "music.sh - read_music is empty with no backend" {
  _PLATFORM_OS_CACHE="Linux"
  has_command() { return 1; }
  run read_music
  [[ -z "${output}" ]]
}

@test "music.sh - host-probe seams are callable" {
  run _read_playerctl_status
  run _read_playerctl_meta title
  run _read_playerctl_position
  run _read_nowplaying
  run _read_cmus
  run _read_osascript
  true
}

@test "music.sh - playerctl list seams are callable without a real player" {
  run _read_playerctl_list
  run _read_playerctl_status_of spotify
  true
}

@test "music.sh - music_pick_player prefers the playing player" {
  run music_pick_player $'spotify Paused\nvlc Playing\nmpv Stopped'
  [[ "${output}" == "vlc" ]]
}

@test "music.sh - music_pick_player falls back to the first when none play" {
  run music_pick_player $'spotify Paused\nvlc Stopped'
  [[ "${output}" == "spotify" ]]
}

@test "music.sh - music_pick_player is empty for no players" {
  [[ -z "$(music_pick_player "")" ]]
}

@test "music.sh - music_active_player picks the playing player from the seams" {
  _read_playerctl_list() { printf 'spotify\nvlc\n'; }
  _read_playerctl_status_of() { case "$1" in spotify) echo "Paused" ;; vlc) echo "Playing" ;; esac; }
  run music_active_player
  [[ "${output}" == "vlc" ]]
}

@test "music.sh - music_active_player is empty when no player is listed" {
  _read_playerctl_list() { printf ''; }
  run music_active_player
  [[ -z "${output}" ]]
}

@test "music.sh - playerctl seams target the selected player" {
  playerctl() { echo "$*"; }
  _MUSIC_PLAYERCTL_PLAYER="vlc"
  run _read_playerctl_status
  [[ "${output}" == "-p vlc status" ]]
  run _read_playerctl_meta title
  [[ "${output}" == "-p vlc metadata title" ]]
  run _read_playerctl_position
  [[ "${output}" == "-p vlc position" ]]
}
