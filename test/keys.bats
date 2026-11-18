#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/server_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/server_helpers.bash"

bats_require_minimum_version 1.5.0

loaded_with_status() {
  tmux set-option -g status-right '#{music_icon} #{music} end'
  load_plugin
  wait_for host_shows "> So #S What - Miles Davis end"
}

@test "keys - prefix M-m opens the menu, and its n item skips to the next track" {
  # Arrange
  loaded_with_status
  press C-b M-m
  wait_for host_shows "Play/Pause"
  wait_for host_shows "Previous"

  # Act
  press n

  # Assert
  wait_for asked "-n"
  wait_for host_shows "> Next Song - Miles Davis end"
}

@test "keys - the menu's p item pauses, and its b item goes back a track" {
  # Arrange
  loaded_with_status
  press C-b M-m
  wait_for host_shows "Play/Pause"
  press p
  wait_for asked "-u"
  wait_for host_shows "|| So #S What - Miles Davis end"
  press C-b M-m
  wait_for host_shows "Play/Pause"

  # Act
  press b

  # Assert
  wait_for asked "-r"
  wait_for host_shows "|| Previous Song - Miles Davis end"
}

@test "keys - Escape closes the menu and touches no player" {
  # Arrange
  loaded_with_status
  : >"${BATS_TEST_TMPDIR}/player.calls"
  tmux set-option -g @music_revamped_interval 3600
  press C-b M-m
  wait_for host_shows "Play/Pause"

  # Act
  press Escape

  # Assert
  wait_for host_lacks "Play/Pause"
  run grep -c -e '^-[unr]$' "${BATS_TEST_TMPDIR}/player.calls"
  [[ "${output}" == "0" ]]
}

@test "keys - the three control keys play or pause, skip and go back" {
  # Arrange
  setting playpause_key F5
  setting next_key F6
  setting prev_key F7
  loaded_with_status
  press C-b F5
  wait_for asked "-u"
  wait_for host_shows "|| So #S What"
  press C-b F6
  wait_for asked "-n"
  wait_for host_shows "Next Song"

  # Act
  press C-b F7

  # Assert
  wait_for asked "-r"
  wait_for host_shows "Previous Song"
}

@test "keys - a control key says so when there is no player to control" {
  # Arrange
  rm -f "${STUBS}/cmus-remote"
  setting next_key F6
  load_plugin

  # Act
  press C-b F6

  # Assert
  wait_for said "no player to control. install playerctl or cmus"
}

@test "keys - in options mode the status line reads options a daemon fills, and a key shows its effect at once" {
  # Arrange
  setting render options
  setting next_key F6
  tmux set-option -g @music_revamped_interval 3600
  tmux set-option -g status-right '#{music_icon} #{music} end'
  load_plugin
  run tmux show-option -gqv status-right
  [[ "${output}" == "#{E:@music_revamped_out_icon} #{E:@music_revamped_out_now} end" ]]
  wait_for host_shows "> So #S What - Miles Davis end"

  # Act
  press C-b F6

  # Assert
  wait_for asked "-n"
  wait_for host_shows "> Next Song - Miles Davis end"
  run tmux show-option -gqv @music_revamped_ticker_pid
  [[ "${output}" =~ ^[0-9]+$ ]]
}
