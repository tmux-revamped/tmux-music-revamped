#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/server_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/server_helpers.bash"

bats_require_minimum_version 1.5.0

everything() {
  local options
  options=$(tmux show-options -g)
  grep -vE '@music_revamped_(status|title|artist|position|duration)' <<<"${options}"
  tmux list-keys
}

@test "entrypoint - git tracks the entry point and the tool as executable" {
  # Arrange
  local modes

  # Act
  modes=$(git -C "${ROOT}" ls-files --stage -- music-revamped.tmux bin/music-revamped)

  # Assert
  run awk '$1 != "100755" { bad++ } END { print NR ":" bad + 0 }' <<<"${modes}"
  [[ "${output}" == "2:0" ]]
}

@test "entrypoint - loading binds the menu on M-m and turns each placeholder into its job" {
  # Arrange
  local keys
  tmux set-option -g status-right '#{music_icon} #{music} | #{music_time} end'

  # Act
  load_plugin

  # Assert
  keys=$(prefix_keys)
  run grep -c -x 'M-m' <<<"${keys}"
  [[ "${output}" == "1" ]]
  run tmux show-option -gqv status-right
  [[ "${output}" == "#('${ROOT}/bin/music-revamped' status icon) #('${ROOT}/bin/music-revamped' status now) | #('${ROOT}/bin/music-revamped' status time) end" ]]
  wait_for host_shows "> So #S What - Miles Davis | 0:30/1:00 end"
}

@test "entrypoint - loading twice changes nothing" {
  # Arrange
  local before after
  tmux set-option -g status-right '#{music} end'
  load_plugin
  before=$(everything)

  # Act
  load_plugin

  # Assert
  after=$(everything)
  [[ "${before}" == "${after}" ]]
}

@test "entrypoint - a checkout whose path holds a space, a quote and a hash loads, shows the track and takes its key" {
  # Arrange
  local copy="${BATS_TEST_TMPDIR}/it's #1 plug in"
  mkdir -p "${copy}"
  cp -R "${ROOT}/bin" "${ROOT}/lib" "${ROOT}/music-revamped.tmux" "${copy}/"
  tmux set-option -g status-right '#{music} end'
  load_plugin "${copy}"
  wait_for host_shows "So #S What - Miles Davis end"
  press C-b M-m
  wait_for host_shows "Play/Pause"

  # Act
  press n

  # Assert
  wait_for asked "-n"
  wait_for host_shows "Next Song - Miles Davis end"
}

@test "entrypoint - a default key someone else holds is left alone, and one the person names is bound" {
  # Arrange
  local table
  tmux bind-key -T prefix M-m display-message taken
  tmux bind-key -T prefix x display-message taken-too
  setting next_key x

  # Act
  load_plugin

  # Assert
  table=$(tmux list-keys -T prefix)
  run grep -c 'M-m  *display-message taken' <<<"${table}"
  [[ "${output}" == "1" ]]
  run grep -c 'music-revamped. next' <<<"${table}"
  [[ "${output}" == "1" ]]
}

@test "entrypoint - a key set to off binds nothing" {
  # Arrange
  local table
  setting menu_key off

  # Act
  load_plugin

  # Assert
  table=$(tmux list-keys -T prefix)
  run grep -c 'music-revamped' <<<"${table}"
  [[ "${output}" == "0" ]]
}
