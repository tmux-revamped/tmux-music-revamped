#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031,SC2154

# shellcheck source=test/tmux_helpers.bash
source "${BATS_TEST_DIRNAME}/../tmux_helpers.bash"

wait_for() {
  local delay
  for delay in 0.01 0.02 0.05 0.1 0.1 0.2 0.2 0.5 0.5 1 1 1 2 2; do
    "$@" && return 0
    sleep "${delay}"
  done
  "$@" && return 0
  command tmux -S "${HOST}" capture-pane -p -t host || :
  return 1
}

attached() {
  local clients
  clients=$(tmux list-clients -F x 2>/dev/null)
  [[ -n "${clients}" ]]
}

host_shows() {
  local screen
  screen=$(command tmux -S "${HOST}" capture-pane -p -t host)
  [[ "${screen}" == *"$1"* ]]
}

host_lacks() {
  ! host_shows "$1"
}

said() {
  local messages
  messages=$(tmux show-messages)
  [[ "${messages}" == *"$1"* ]]
}

asked() {
  grep -qxF -- "$1" "${BATS_TEST_TMPDIR}/playerctl.calls" 2>/dev/null
}

player() {
  printf '#!/bin/sh\nprintf "%%s\\n" "$*" >>"%s"\ncase "$*" in\n--list-all) printf "spotify\\n" ;;\n*status) printf "Playing\\n" ;;\n*) : ;;\nesac\n' "${BATS_TEST_TMPDIR}/playerctl.calls" >"${STUBS}/playerctl"
  chmod +x "${STUBS}/playerctl"
}

without_players() {
  local folder old_ifs="${IFS}"
  FARM="${BATS_TEST_TMPDIR}/farm"
  mkdir -p "${FARM}"
  IFS=:
  for folder in ${PATH}; do
    [[ -d "${folder}" ]] || continue
    ln -s "${folder}"/* "${FARM}/" 2>/dev/null || :
  done
  IFS="${old_ifs}"
  rm -f "${FARM}/playerctl" "${FARM}/cmus-remote" "${FARM}/osascript" "${FARM}/nowplaying-cli"
  PATH="${STUBS}:${FARM}"
}

setup() {
  unset BASH_ENV
  ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  STUBS="${BATS_TEST_TMPDIR}/stubs"
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}" "${STUBS}"
  HOST="${TMUX_SOCKET}-host"
  without_players
}

serve() {
  setup_tmux_server
  tmux set-option -g default-command "env PS1='$ ' sh"
  tmux set-option -g @music_revamped_playpause_key F2
  tmux set-option -g @music_revamped_next_key F3
  tmux set-option -g @music_revamped_prev_key F4
  command tmux -S "${HOST}" -f /dev/null new-session -d -s host -x 120 -y 40 \
    "env -u TMUX TERM=xterm-256color tmux -S '${TMUX_SOCKET}' attach-session -t test"
  wait_for attached
  tmux run-shell "'${ROOT}/music-revamped.tmux'"
}

teardown() {
  command tmux -S "${HOST}" kill-server 2>/dev/null || :
  rm -f "${HOST}"
  teardown_tmux_server
}

press() {
  local key
  for key in "$@"; do
    command tmux -S "${HOST}" send-keys -t host "${key}"
  done
}

menu() {
  press C-b M-m
  wait_for host_shows "Play/Pause"
}

@test "keys - prefix M-m opens the menu, and its three items reach the player" {
  # Arrange
  player
  serve
  menu
  press p
  wait_for asked "-p spotify play-pause"
  menu
  press n
  wait_for asked "-p spotify next"
  menu

  # Act
  press b

  # Assert
  wait_for asked "-p spotify previous"
}

@test "keys - the play, next and previous keys reach the player when set" {
  # Arrange
  player
  serve
  press C-b F2
  wait_for asked "-p spotify play-pause"
  press C-b F3
  wait_for asked "-p spotify next"

  # Act
  press C-b F4

  # Assert
  wait_for asked "-p spotify previous"
}

@test "keys - a control key without any player says so" {
  # Arrange
  serve

  # Act
  press C-b F2

  # Assert
  wait_for said "music-revamped: no player to control. install playerctl or cmus"
}
