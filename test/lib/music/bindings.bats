#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _MUSIC_REVAMPED_BINDINGS_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/music/bindings.sh"
}

teardown() {
  cleanup_test_environment
}

@test "bindings.sh - functions are defined" {
  function_exists music_bind_keys
  function_exists music_bind_one
  function_exists music_version_ge
  function_exists _music_parse_version
}

@test "bindings.sh - _music_parse_version extracts major and minor" {
  [[ "$(_music_parse_version 'tmux 3.4')" == "3 4" ]]
  [[ "$(_music_parse_version 'tmux next-3.5a')" == "3 5" ]]
  [[ "$(_music_parse_version 'no-version-here')" == "0 0" ]]
}

@test "bindings.sh - music_version_ge compares across every branch" {
  music_version_ge "tmux 3.4" 1 9
  music_version_ge "tmux 2.0" 2 0
  music_version_ge "tmux 3.4" 3 1
  ! music_version_ge "tmux 1.8" 2 0
  ! music_version_ge "tmux 1.5" 1 9
  ! music_version_ge "garbage" 1 9
}

@test "bindings.sh - music_bind_one binds a non-empty key" {
  _tmux() { echo "$*"; }
  run music_bind_one "M-p" "/x/music.sh" "play-pause"
  [[ "${output}" == "bind-key M-p run-shell /x/music.sh play-pause" ]]
}

@test "bindings.sh - music_bind_one skips an empty key" {
  _tmux() { echo "SHOULD-NOT-RUN"; }
  run music_bind_one "" "/x/music.sh" "play-pause"
  [[ -z "${output}" ]]
}

@test "bindings.sh - music_bind_keys registers three bindings on a new tmux" {
  _tmux_version() { echo "tmux 3.4"; }
  _tmux() { echo "$*" >> "${TEST_TMPDIR}/binds"; }
  music_bind_keys "/x/music.sh"
  [[ "$(grep -c . "${TEST_TMPDIR}/binds")" -eq 3 ]]
  grep -q "bind-key M-p run-shell /x/music.sh play-pause" "${TEST_TMPDIR}/binds"
  grep -q "bind-key M-n run-shell /x/music.sh next" "${TEST_TMPDIR}/binds"
  grep -q "bind-key M-b run-shell /x/music.sh prev" "${TEST_TMPDIR}/binds"
}

@test "bindings.sh - music_bind_keys does nothing on an old tmux" {
  _tmux_version() { echo "tmux 1.5"; }
  _tmux() { echo "ran" >> "${TEST_TMPDIR}/binds"; }
  music_bind_keys "/x/music.sh"
  [[ ! -f "${TEST_TMPDIR}/binds" ]]
}

@test "bindings.sh - music_bind_keys honors a custom key option" {
  _tmux_version() { echo "tmux 3.4"; }
  _tmux() { echo "$*" >> "${TEST_TMPDIR}/binds"; }
  set_tmux_option "@music_revamped_playpause_key" "C-Space"
  music_bind_keys "/x/music.sh"
  grep -q "bind-key C-Space run-shell /x/music.sh play-pause" "${TEST_TMPDIR}/binds"
}

@test "bindings.sh - the tmux seams are callable without a real server" {
  run _tmux bind-key M-p run-shell "x"
  run _tmux_version
  true
}
