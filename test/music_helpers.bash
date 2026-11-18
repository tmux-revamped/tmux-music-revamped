#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  for name in $(compgen -v MUSIC_REVAMPED_); do
    unset "${name}"
  done
  FAKE="${BATS_TEST_TMPDIR}/fake"
  export HOME="${BATS_TEST_TMPDIR}/home" FAKE
  mkdir -p "${HOME}" "${FAKE}" "${BATS_TEST_TMPDIR}/stubs"
  UNTRACED='{ set +x; } 2>/dev/null'
  printf '3.6\n' >"${FAKE}/version"
  : >"${FAKE}/vars"
  : >"${FAKE}/log"
  : >"${FAKE}/asked"
  now 1000000
  fake_tmux
  fake_date
  linux
  harness_hide nowplaying-cli playerctl cmus-remote osascript
}

quiet() {
  printf '#!/bin/sh\n%s\n%s\n' "${UNTRACED}" "$2" >"${BATS_TEST_TMPDIR}/stubs/$1"
  chmod +x "${BATS_TEST_TMPDIR}/stubs/$1"
}

var() {
  local kept
  kept=$(grep -v "^$1	" "${FAKE}/vars" || :)
  printf '%s\n%s\t%s\n' "${kept}" "$1" "$2" | grep -v '^$' >"${FAKE}/vars.tmp"
  mv -f "${FAKE}/vars.tmp" "${FAKE}/vars"
}

value() {
  awk -F '\t' -v want="$1" '$1 == want { print $2 }' "${FAKE}/vars"
}

option() {
  var "@music_revamped_$1" "$2"
}

held() {
  value "@music_revamped_$1"
}

now() {
  printf '%s\n' "$1" >"${FAKE}/now"
}

fake_date() {
  quiet date 'cat "'"${FAKE}"'/now"'
}

macos() {
  export REVAMPED_TEST_UNAME_S=Darwin
}

linux() {
  export REVAMPED_TEST_UNAME_S=Linux
}

nowplaying() {
  printf '%s\n' "$@" >"${FAKE}/nowplaying"
  quiet nowplaying-cli 'printf "%s\n" "$*" >>"'"${FAKE}"'/asked"; cat "'"${FAKE}"'/nowplaying"'
}

playerctl_player() {
  mkdir -p "${FAKE}/players/$1"
  printf '%s\n' "$2" >"${FAKE}/players/$1/status"
  printf '%s\n' "$3" >"${FAKE}/players/$1/title"
  printf '%s\n' "$4" >"${FAKE}/players/$1/artist"
  printf '%s\n' "$5" >"${FAKE}/players/$1/position"
  printf '%s\n' "$6" >"${FAKE}/players/$1/mpris:length"
  printf '%s\n' "$1" >>"${FAKE}/players/list"
  quiet playerctl 'printf "%s\n" "$*" >>"'"${FAKE}"'/asked"
root="'"${FAKE}"'/players"
player=$(head -n 1 "${root}/list")
if [ "$1" = -p ]; then
  player="$2"
  shift 2
fi
case "$1" in
--list-all) cat "${root}/list" ;;
status | position) cat "${root}/${player}/$1" ;;
metadata) cat "${root}/${player}/$2" ;;
*) : ;;
esac'
}

cmus() {
  printf '%s\n' "$@" >"${FAKE}/cmus"
  quiet cmus-remote 'printf "%s\n" "$*" >>"'"${FAKE}"'/asked"
[ "$1" != -Q ] || cat "'"${FAKE}"'/cmus"'
}

spotify() {
  printf '%s\n' "$@" >"${FAKE}/spotify"
  quiet osascript 'printf "%s\n" "$*" >>"'"${FAKE}"'/asked"
[ "$#" -gt 0 ] || cat "'"${FAKE}"'/spotify"'
}

playing() {
  option status "${1:-playing}"
  option status_ts "${5:-1000000}"
  option title "${2:-Blue Train}"
  option artist "${3-John Coltrane}"
  option position 75
  option duration "${4:-643}"
}

asked() {
  cat "${FAKE}/asked"
}

fake_tmux() {
  cat >"${BATS_TEST_TMPDIR}/stubs/tmux" <<EOF
#!/bin/sh
${UNTRACED}
printf '%s\n' "\$*" >>"${FAKE}/log"
expanded() {
  printf '%s\n' "\$1" | awk -v vars="${FAKE}/vars" '
    BEGIN { while ((getline row < vars) > 0) { at = index(row, "\t"); value[substr(row, 1, at - 1)] = substr(row, at + 1) } }
    {
      line = \$0
      out = ""
      while ((at = index(line, "#{")) > 0) {
        stop = index(substr(line, at), "}")
        name = substr(line, at + 2, stop - 3)
        out = out substr(line, 1, at - 1) value[name]
        line = substr(line, at + stop)
      }
      print out line
    }
  '
}
looked() {
  awk -F '\t' -v want="\$1" '\$1 == want { print \$2 }' "${FAKE}/vars"
}
put() {
  kept=\$(grep -v "^\$1	" "${FAKE}/vars" || :)
  printf '%s\n%s\t%s\n' "\${kept}" "\$1" "\$2" | grep -v '^\$' >"${FAKE}/vars.tmp"
  mv -f "${FAKE}/vars.tmp" "${FAKE}/vars"
}
written() {
  while [ "\$#" -gt 0 ]; do
    if [ "\$1" = set-option ] && [ "\${2:-}" = -gq ] && [ "\$#" -ge 4 ]; then
      put "\$3" "\$4"
      shift 4
      continue
    fi
    shift
  done
}
case "\$1" in
-V)
  IFS= read -r version <"${FAKE}/version"
  printf 'tmux %s\n' "\${version}"
  ;;
display-message)
  [ "\$2" != -p ] || expanded "\$3"
  ;;
show-option)
  looked "\$3"
  ;;
list-keys)
  [ ! -f "${FAKE}/keys" ] || cat "${FAKE}/keys"
  ;;
list-clients)
  [ ! -f "${FAKE}/clients" ] || cat "${FAKE}/clients"
  ;;
*)
  case "\$*" in
  *" ; "*) [ ! -f "${FAKE}/refused" ] || exit 1 ;;
  *) [ ! -f "${FAKE}/refused" ] || ! grep -qF -- "\$*" "${FAKE}/refused" || exit 1 ;;
  esac
  written "\$@"
  ;;
esac
exit 0
EOF
  chmod +x "${BATS_TEST_TMPDIR}/stubs/tmux"
}

tmux_is() {
  printf '%s\n' "$1" >"${FAKE}/version"
}

planned() {
  lib_run music "${1:-}"'music_revamped_plan; music_revamped_lines'
}

sends() {
  grep -v -e '^display-message -p' -e '^-V' -e '^list-' -e '^show-option' "${FAKE}/log" || :
}

sent() {
  grep -c -- "$1" "${FAKE}/log" || :
}

tool() {
  # shellcheck disable=SC2086
  run ${REVAMPED_TEST_SHELL:-sh} "${REVAMPED_TESTS_DIR}/../bin/music-revamped" "$@"
}

tool_path() {
  printf "'%s'" "${REVAMPED_TESTS_DIR}/../bin/music-revamped"
}

bin_path() {
  printf "'%s'" "${REVAMPED_TESTS_DIR%/test}/bin/music-revamped"
}

has_line() {
  local line
  for line in "${lines[@]}"; do
    [[ "${line}" == "$1" ]] && return 0
  done
  return 1
}

answers() {
  export REVAMPED_TEST_GUM_ANSWERS="${BATS_TEST_TMPDIR}/answers"
  printf '%s\n' "$@" >"${REVAMPED_TEST_GUM_ANSWERS}"
}

said() {
  grep -qxF -- "display-message music-revamped: $1" "${FAKE}/log"
}

eventually() {
  local delay
  for delay in 0.01 0.02 0.05 0.1 0.1 0.2 0.2 0.5 0.5 1 1 1 2 2; do
    "$@" && return 0
    sleep "${delay}"
  done
  "$@"
}

holds() {
  local now
  now=$(held "$1")
  [[ "${now}" == "$2" ]]
}
