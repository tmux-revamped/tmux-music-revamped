#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/music_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/music_helpers.bash"

@test "commands - status prints one placeholder from the stored reading" {
  # Arrange
  playing
  tool status now
  [[ "${output}" == "Blue Train - John Coltrane" ]]
  tool status icon
  [[ "${output}" == ">" ]]
  tool status progress
  [[ "${output}" == "█░░░░░░░░░" ]]

  # Act
  tool status time

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "1:15/10:43" ]]
}

@test "commands - status without a name is a usage error, and an unknown name a bad value" {
  # Arrange
  tool status
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "music-revamped: no placeholder given. run 'music-revamped help' for usage." ]]

  # Act
  tool status album

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "music-revamped: status must be now, icon, status, title, artist, progress or time, got: album" ]]
}

@test "commands - refresh reads the player now and says what is playing" {
  # Arrange
  cmus "status paused" "tag title So What" "tag artist Miles Davis"

  # Act
  tool refresh

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "Refreshed. So What is paused." ]]
  holds title "So What"
}

@test "commands - refresh says when nothing is playing, and fails when no tmux server takes the reading" {
  # Arrange
  tool refresh
  [[ "${output}" == "Refreshed. Nothing is playing." ]]
  : >"${FAKE}/refused"

  # Act
  tool refresh

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "music-revamped: no tmux server is running, so the reading has nowhere to go" ]]
}

@test "commands - play-pause, next and prev act on the player and print nothing" {
  # Arrange
  cmus "status playing" "tag title So What"
  tool play-pause
  [[ -z "${output}" ]]
  tool next
  [[ -z "${output}" ]]

  # Act
  tool prev

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
  run asked
  [[ "${output}" == $'-u\n-n\n-r' ]]
}

@test "commands - apply binds the menu key and prints nothing" {
  # Arrange
  local started='^bind-key -N Music menu M-m display-menu'

  # Act
  tool apply

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
  run sent "${started}"
  [[ "${output}" == "1" ]]
}

@test "commands - list prints what apply would send, and --json the same plan as one object" {
  # Arrange
  local path
  path=$(bin_path)
  option menu_key off
  option next_key 'C-"'
  tool list
  [[ "${output}" == "bind-key -N Next track C-\" run-shell ${path} next" ]]

  # Act
  tool list --json

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == '{"bindings":[["bind-key","-N","Next track","C-\"","run-shell","'*' next"]]}' ]]
  run sends
  [[ -z "${output}" ]]
}

@test "commands - --json with any command but list is a usage error" {
  # Arrange
  playing

  # Act
  tool --json refresh

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "music-revamped: option '--json' works only with list. run 'music-revamped help' for usage." ]]
}

@test "commands - the command line wins over the environment, and the environment over the tmux option" {
  # Arrange
  playing
  option before "T:"
  export MUSIC_REVAMPED_BEFORE="E:"
  tool status now
  [[ "${output}" == "E:Blue Train - John Coltrane" ]]

  # Act
  tool --before=C: --max-len 4 status now

  # Assert
  [[ "${output}" == "C:Blue... - John..." ]]
}

@test "commands - an unknown option, one without its value and a word after a double dash are usage errors" {
  # Arrange
  local hint="run 'music-revamped help' for usage."
  tool --bogus list
  [[ "${output}" == "music-revamped: unknown option '--bogus'. ${hint}" ]]
  tool --bogus=1 list
  [[ "${output}" == "music-revamped: unknown option '--bogus'. ${hint}" ]]
  tool -x list
  [[ "${output}" == "music-revamped: unknown option '-x'. ${hint}" ]]
  tool status --interval
  [[ "${output}" == "music-revamped: option '--interval' needs a value. ${hint}" ]]

  # Act
  tool -- --weird

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "music-revamped: unknown command '--weird'. ${hint}" ]]
}

@test "commands - a number, a switch and the render mode are checked before anything runs" {
  # Arrange
  playing
  tool --interval 1.5 status now
  [[ "${output}" == "music-revamped: --interval must be a whole number, got: 1.5" ]]
  tool --max-len x status now
  [[ "${output}" == "music-revamped: --max-len must be a whole number, got: x" ]]
  tool --progress-width -3 status now
  [[ "${output}" == "music-revamped: --progress-width must be a whole number, got: -3" ]]
  export MUSIC_REVAMPED_AUTO_HIDE=yes
  tool status now
  [[ "${output}" == "music-revamped: --auto-hide must be 0 or 1, got: yes" ]]
  unset MUSIC_REVAMPED_AUTO_HIDE

  # Act
  tool --render threads status now

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "music-revamped: --render must be jobs or options, got: threads" ]]
}

@test "commands - doctor names the player it reads and the one it controls, and a default key someone else holds" {
  # Arrange
  local player='player +ok +.*/stubs/playerctl, reads the active MPRIS player' controls='controls +ok +.*/stubs/playerctl, plays, pauses and skips' held='keys +warn +already bound and left alone: M-m'
  playerctl_player spotify Playing "Blue Train" "John Coltrane" 75 643000000
  printf 'bind-key    -T prefix M-m     display-menu -T mine\n' >"${FAKE}/keys"

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ ${player} ]]
  [[ "${output}" =~ ${controls} ]]
  [[ "${output}" =~ ${held} ]]
}

@test "commands - doctor names cmus, and on macOS nowplaying-cli and Spotify" {
  # Arrange
  local reads='player +ok +.*/stubs/cmus-remote, reads cmus' skips='controls +ok +.*/stubs/cmus-remote, plays, pauses and skips cmus'
  cmus "status playing" "tag title So What"
  tool doctor
  [[ "${output}" =~ ${reads} ]]
  [[ "${output}" =~ ${skips} ]]
  rm -f "${BATS_TEST_TMPDIR}/stubs/cmus-remote"
  macos
  spotify playing "So What" "Miles Davis" 10 545
  tool doctor
  [[ "${output}" =~ player\ +ok\ +.*/stubs/osascript,\ reads\ Spotify ]]
  [[ "${output}" =~ controls\ +ok\ +.*/stubs/osascript,\ plays,\ pauses\ and\ skips\ Spotify ]]
  nowplaying "So What" "Miles Davis" 1 10 545

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ player\ +ok\ +.*/stubs/nowplaying-cli,\ reads\ what\ macOS\ is\ playing ]]
}

@test "commands - doctor warns when there is no player to read or to control" {
  # Arrange
  local reads='player +warn +no player to read' skips='controls +warn +no player to control' free='keys +ok +every key it binds is free or its own'

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ ${reads} ]]
  [[ "${output}" =~ ${skips} ]]
  [[ "${output}" =~ ${free} ]]
}

@test "commands - doctor names a tmux option whose value it does not know" {
  # Arrange
  option progress_width 500

  # Act
  tool doctor

  # Assert
  run grep '^settings' <<<"${output}"
  [[ "${output}" == "settings           warn     unknown values: progress_width=500" ]]
}
