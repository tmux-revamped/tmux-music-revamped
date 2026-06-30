#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _MUSIC_REVAMPED_MUSIC_LOADED _MUSIC_REVAMPED_RENDER_LOADED
  export CACHE_SYNC=1
  source "${BATS_TEST_DIRNAME}/../../../src/music.sh"
  read_music() { printf 'Playing\nSong\nBand\n30\n200\n'; }
}

teardown() {
  cleanup_test_environment
}

@test "music.sh dispatcher - functions are defined" {
  function_exists main
  function_exists music_refresh
  function_exists music_tick
  function_exists music_max_age
}

@test "music.sh dispatcher - music_max_age default is 5" {
  [[ "$(music_max_age)" == "5" ]]
}

@test "music.sh dispatcher - music_max_age honors the interval option" {
  set_tmux_option "@music_revamped_interval" "3"
  [[ "$(music_max_age)" == "3" ]]
}

@test "music.sh dispatcher - music_refresh caches every field" {
  music_refresh
  [[ "$(cache_get status)" == "playing" ]]
  [[ "$(cache_get title)" == "Song" ]]
  [[ "$(cache_get artist)" == "Band" ]]
  [[ "$(cache_get position)" == "30" ]]
  [[ "$(cache_get duration)" == "200" ]]
}

@test "music.sh dispatcher - progress and time render from the cache" {
  set_tmux_option "@music_revamped_progress_full" "#"
  set_tmux_option "@music_revamped_progress_empty" "-"
  run main progress
  [[ "${output}" == "#---------" ]]
  run main time
  [[ "${output}" == "0:30/3:20" ]]
}

@test "music.sh dispatcher - refresh subcommand caches values" {
  main refresh
  [[ "$(cache_get title)" == "Song" ]]
}

@test "music.sh dispatcher - now renders the cached track" {
  run main now
  [[ "${output}" == "Song - Band" ]]
}

@test "music.sh dispatcher - icon maps the cached status" {
  run main icon
  [[ "${output}" == ">" ]]
}

@test "music.sh dispatcher - status, title, artist echo cached values" {
  run main status
  [[ "${output}" == "playing" ]]
  run main title
  [[ "${output}" == "Song" ]]
  run main artist
  [[ "${output}" == "Band" ]]
}

@test "music.sh dispatcher - now is empty when idle" {
  read_music() { return 0; }
  run main now
  [[ -z "${output}" ]]
}

@test "music.sh dispatcher - unknown subcommand produces no output" {
  run main bogus
  [[ -z "${output}" ]]
}

@test "music.sh dispatcher - play-pause routes to music_control" {
  music_control() { echo "ctl:$1"; }
  run main play-pause
  [[ "${output}" == "ctl:play-pause" ]]
}

@test "music.sh dispatcher - next and prev route to music_control" {
  music_control() { echo "ctl:$1"; }
  run main next
  [[ "${output}" == "ctl:next" ]]
  run main prev
  [[ "${output}" == "ctl:prev" ]]
}
