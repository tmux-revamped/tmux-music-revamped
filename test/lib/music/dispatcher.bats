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

@test "music.sh dispatcher - the track is wrapped when set" {
  set_tmux_option "@music_revamped_before" "<<"
  set_tmux_option "@music_revamped_after" ">>"

  run music_wrap "Song - Band"

  [[ "${output}" == "<<Song - Band>>" ]]
}

@test "music.sh dispatcher - nothing playing is not wrapped" {
  set_tmux_option "@music_revamped_before" "<<"

  run music_wrap ""

  [ -z "${output}" ]
}

@test "music.sh dispatcher - the track is unwrapped by default" {
  run music_wrap "Song - Band"

  [[ "${output}" == "Song - Band" ]]
}

@test "music.sh dispatcher - publish writes every published metric in one batch" {
  export PUBLISH_LOG="${TEST_TMPDIR}/publish.log"
  _publish_tmux() { [[ "${1}" == "list-clients" ]] && return 0; printf '%s\n' "$@" > "${PUBLISH_LOG}"; }
  set_tmux_option "@music_revamped_published" "title artist"

  music_publish

  [[ "$(paste -sd'|' "${PUBLISH_LOG}")" == "set-option|-gq|@music_revamped_out_title|Song|;|set-option|-gq|@music_revamped_out_artist|Band" ]]
}

@test "music.sh dispatcher - a control key publishes at once in options mode" {
  music_control() { return 0; }
  music_publish() { echo "published" > "${TEST_TMPDIR}/published"; }
  set_tmux_option "@music_revamped_render" "options"

  main next

  [[ "$(cat "${TEST_TMPDIR}/published")" == "published" ]]
}

@test "music.sh dispatcher - a control key does not publish in jobs mode" {
  music_control() { return 0; }
  music_publish() { echo "published" > "${TEST_TMPDIR}/published"; }

  main next

  [ ! -f "${TEST_TMPDIR}/published" ]
}

@test "music.sh dispatcher - the daemon re-executes after the tick limit" {
  ticker_run() { return 0; }
  _music_reexec() { echo "reexec" > "${TEST_TMPDIR}/reexec"; }

  music_daemon

  [[ "$(cat "${TEST_TMPDIR}/reexec")" == "reexec" ]]
}

@test "music.sh dispatcher - the daemon stops when it loses ownership" {
  ticker_run() { return 1; }
  _music_reexec() { echo "reexec" > "${TEST_TMPDIR}/reexec"; }

  music_daemon

  [ ! -f "${TEST_TMPDIR}/reexec" ]
}

@test "music.sh dispatcher - main daemon runs the ticker" {
  music_daemon() { echo "daemon" > "${TEST_TMPDIR}/daemon"; }

  main daemon

  [[ "$(cat "${TEST_TMPDIR}/daemon")" == "daemon" ]]
}

@test "music.sh dispatcher - main start spawns the daemon" {
  _ticker_spawn() { printf '%s' "${1}" > "${TEST_TMPDIR}/spawn"; }

  main start

  [[ "$(cat "${TEST_TMPDIR}/spawn")" == *"/src/music.sh" ]]
}
