#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

ENTRY="${BATS_TEST_DIRNAME}/../../music-revamped.tmux"

setup() {
  setup_test_environment
  export SPAWN_LOG="${TEST_TMPDIR}/spawn.log"
  nohup() { printf '%s\n' "$*" >> "${SPAWN_LOG}"; }
  export -f nohup
}

teardown() {
  cleanup_test_environment
}

@test "entry - jobs mode turns a placeholder into a dispatcher call" {
  tmux set-option -gq "status-right" "[#{music_title}]"

  bash "${ENTRY}"

  [[ "$(cat "$(_mock_opt_file status-right)")" == "[#($(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/src/music.sh title)]" ]]
}

@test "entry - options mode turns a placeholder into an option read" {
  tmux set-option -gq "@music_revamped_render" "options"
  tmux set-option -gq "status-right" "[#{music_title}]"

  bash "${ENTRY}"

  [[ "$(cat "$(_mock_opt_file status-right)")" == "[#{E:@music_revamped_out_title}]" ]]
}

@test "entry - options mode starts the ticker" {
  tmux set-option -gq "@music_revamped_render" "options"
  tmux set-option -gq "status-right" "[#{music_title}]"

  bash "${ENTRY}"

  [[ "$(cat "${SPAWN_LOG}")" == *"/src/music.sh daemon" ]]
}

@test "entry - jobs mode starts no ticker" {
  tmux set-option -gq "status-right" "[#{music_title}]"

  bash "${ENTRY}"

  [ ! -f "${SPAWN_LOG}" ]
}

@test "entry - only metrics on the status line are published" {
  tmux set-option -gq "status-right" "#{music_title}"

  bash "${ENTRY}"

  [[ "$(cat "$(_mock_opt_file @music_revamped_published)")" == "title" ]]
}

@test "entry - a second run keeps metrics already turned into option reads" {
  tmux set-option -gq "@music_revamped_render" "options"
  tmux set-option -gq "status-right" "[#{E:@music_revamped_out_title}]"

  bash "${ENTRY}"

  [[ "$(cat "$(_mock_opt_file @music_revamped_published)")" == "title" ]]
}

@test "entry - jobs mode releases a ticker left from options mode" {
  # Arrange
  tmux set-option -gq "@music_revamped_ticker_pid" "4242"
  tmux set-option -gq "status-right" "[#{music}]"

  # Act
  bash "${ENTRY}"

  # Assert
  [ ! -f "$(_mock_opt_file @music_revamped_ticker_pid)" ]
}

@test "entry - jobs mode quotes a plugin path with a space and a quote" {
  # Arrange
  local dir="${TEST_TMPDIR}/it's a&b dir"
  mkdir -p "${dir}/src/lib/music" "${dir}/src/lib/tmux"
  cp -f "${ENTRY}" "${dir}/music-revamped.tmux"
  cp -f "${BATS_TEST_DIRNAME}/../../src/lib/music/bindings.sh" "${dir}/src/lib/music/bindings.sh"
  cp -f "${BATS_TEST_DIRNAME}/../../src/lib/tmux/tmux-ops.sh" "${dir}/src/lib/tmux/tmux-ops.sh"
  tmux set-option -gq "status-right" "[#{music_title}]"

  # Act
  bash "${dir}/music-revamped.tmux"

  # Assert
  [[ "$(cat "$(_mock_opt_file status-right)")" == "[#($(cd "${TEST_TMPDIR}" && pwd)/it\\'s\\ a\\&b\\ dir/src/music.sh title)]" ]]
}
