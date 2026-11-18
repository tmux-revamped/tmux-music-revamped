#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/tmux_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/tmux_helpers.bash"

screens() {
  printf 'host screen:\n'
  command tmux -S "${HOST}" capture-pane -p -t host || :
  printf 'options:\n'
  tmux show-options -g | grep music || :
  printf 'messages:\n'
  tmux show-messages | tail -n 5 || :
}

wait_for() {
  local delay
  for delay in 0.01 0.02 0.05 0.1 0.1 0.2 0.2 0.5 0.5 1 1 1 2 2; do
    "$@" && return 0
    sleep "${delay}"
  done
  "$@" && return 0
  screens
  return 1
}

attached() {
  local clients
  clients=$(tmux list-clients -F x 2>/dev/null)
  [[ -n "${clients}" ]]
}

holds() {
  local now
  now=$(tmux show-option -gqv "@music_revamped_$1")
  [[ "${now}" == "$2" ]]
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
  [[ "${messages}" == *"music-revamped: $1"* ]]
}

asked() {
  grep -qxF -- "$1" "${BATS_TEST_TMPDIR}/player.calls" 2>/dev/null
}

track() {
  printf '%s\n' "$1" >"${BATS_TEST_TMPDIR}/player.status"
  printf '%s\n' "$2" >"${BATS_TEST_TMPDIR}/player.title"
}

player() {
  cat >"${STUBS}/cmus-remote" <<STUB
#!/bin/sh
printf '%s\n' "\$1" >>'${BATS_TEST_TMPDIR}/player.calls'
state=\$(cat '${BATS_TEST_TMPDIR}/player.status')
case "\$1" in
-Q) printf 'status %s\ntag title %s\ntag artist Miles Davis\nposition 30\nduration 60\n' "\${state}" "\$(cat '${BATS_TEST_TMPDIR}/player.title')" ;;
-u)
  if [ "\${state}" = playing ]; then
    printf 'paused\n' >'${BATS_TEST_TMPDIR}/player.status'
  else
    printf 'playing\n' >'${BATS_TEST_TMPDIR}/player.status'
  fi
  ;;
-n) printf 'Next Song\n' >'${BATS_TEST_TMPDIR}/player.title' ;;
*) printf 'Previous Song\n' >'${BATS_TEST_TMPDIR}/player.title' ;;
esac
STUB
  chmod +x "${STUBS}/cmus-remote"
}

without_players() {
  local farm="${BATS_TEST_TMPDIR}/farm" folder
  mkdir -p "${farm}"
  local IFS=:
  for folder in ${PATH}; do
    [[ -d "${folder}" ]] || continue
    ln -s "${folder}"/* "${farm}/" 2>/dev/null || :
  done
  unset IFS
  rm -f "${farm}/nowplaying-cli" "${farm}/playerctl" "${farm}/cmus-remote" "${farm}/osascript"
  PATH="${STUBS}:${farm}"
}

setup() {
  unset BASH_ENV
  ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  STUBS="${BATS_TEST_TMPDIR}/stubs"
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}" "${STUBS}"
  track playing "So #S What"
  player
  without_players
  setup_tmux_server
  HOST="${TMUX_SOCKET}-host"
  tmux set-option -g default-command "env PS1='$ ' sh"
  tmux respawn-pane -k -t test:0.0 "env PS1='$ ' sh"
  tmux set-option -g status-interval 1
  tmux set-option -g status-left ''
  tmux set-option -g status-right-length 120
  tmux set-option -g @music_revamped_interval 1
  command tmux -S "${HOST}" -f /dev/null new-session -d -s host -x 120 -y 30 \
    "env -u TMUX TERM=xterm-256color tmux -S '${TMUX_SOCKET}' attach-session -t test"
  wait_for attached
}

teardown() {
  local daemon
  daemon=$(tmux show-option -gqv @music_revamped_ticker_pid 2>/dev/null) || daemon=""
  if [[ "${daemon}" =~ ^[0-9]+$ ]]; then
    pkill -P "${daemon}" 2>/dev/null || :
    kill "${daemon}" 2>/dev/null || :
  fi
  command tmux -S "${HOST}" kill-server 2>/dev/null || :
  rm -f "${HOST}"
  teardown_tmux_server
}

load_plugin() {
  local quoted
  quoted=$(printf '%s' "${1:-${ROOT}}" | sed "s/'/'\\\\''/g")
  tmux run-shell "'${quoted}/music-revamped.tmux'"
}

setting() {
  set_option "@music_revamped_$1" "$2"
}

press() {
  local key
  for key in "$@"; do
    command tmux -S "${HOST}" send-keys -t host "${key}"
  done
}

prefix_keys() {
  local table
  table=$(tmux list-keys -T prefix)
  awk '{ for (i = 1; i < NF; i++) { if ($i == "-T") { print $(i + 2); break } } }' <<<"${table}"
}
