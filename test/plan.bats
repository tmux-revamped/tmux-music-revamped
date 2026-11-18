#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/music_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/music_helpers.bash"

logged() {
  grep -qF -- "$1" "${FAKE}/log"
}

control() {
  lib_run music 'music_revamped_control '"$1"
}

settled() {
  local tries=0
  until "$@"; do
    tries=$((tries + 1))
    [[ "${tries}" -lt 200 ]] || return 1
    /bin/sleep 0.05
  done
}

other_owner() {
  quiet sleep 'kept=$(grep -v "^@music_revamped_ticker_pid	" "'"${FAKE}"'/vars" || :)
printf "%s\n@music_revamped_ticker_pid\tsomeone-else\n" "${kept}" | grep -v "^$" >"'"${FAKE}"'/vars.next"
mv -f "'"${FAKE}"'/vars.next" "'"${FAKE}"'/vars"'
}

@test "plan - a fresh install binds the playback menu to M-m, with an item and a key for each control" {
  # Arrange
  local tool
  tool=$(tool_path)

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key -N Music menu M-m display-menu -T Music Play/Pause p run-shell \"${tool} play-pause\" Next n run-shell \"${tool} next\" Previous b run-shell \"${tool} prev\"" ]]
}

@test "plan - each control key is bound when it is set" {
  # Arrange
  local tool
  tool=$(tool_path)
  option menu_key off
  option playpause_key F5
  option next_key F6
  option prev_key F7

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "bind-key -N Play or pause F5 run-shell ${tool} play-pause" ]]
  [[ "${lines[1]}" == "bind-key -N Next track F6 run-shell ${tool} next" ]]
  [[ "${lines[2]}" == "bind-key -N Previous track F7 run-shell ${tool} prev" ]]
  [[ "${#lines[@]}" -eq 3 ]]
}

@test "plan - a tmux older than 3.1 gets its keys without notes" {
  # Arrange
  option menu_key off
  option next_key F6
  tmux_is 3.0

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key F6 run-shell "*" next" ]]
}

@test "plan - the default menu key is left alone when something else holds it, and bound again when the binding is the plugin's own" {
  # Arrange
  printf 'bind-key    -T prefix M-m     display-menu -T mine\n' >"${FAKE}/keys"
  planned 'music_revamped_plan; printf "[%s]\n" "${MUSIC_REVAMPED_SKIPPED}"; '
  [[ "${output}" == "[M-m]" ]]
  printf 'bind-key    -T prefix M-m     display-menu -T Music x "" "run-shell /old/bin/music-revamped next"\n' >"${FAKE}/keys"

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key -N Music menu M-m display-menu -T Music "* ]]
}

@test "plan - one key given to two actions goes to the first, and the clash is named" {
  # Arrange
  option next_key M-m

  # Act
  planned 'music_revamped_plan; printf "[%s]\n" "${MUSIC_REVAMPED_SKIPPED}"; '

  # Assert
  [[ "${lines[0]}" == "[M-m]" ]]
  [[ "${#lines[@]}" -eq 2 ]]
}

@test "plan - each placeholder becomes a job that prints it, and the metrics in use are recorded" {
  # Arrange
  local tool
  tool=$(tool_path)
  option menu_key off
  var status-right '#{music_icon} #{music} #{music_progress} #{music_time}'
  var status-left '#{music_status}/#{music_title}/#{music_artist} #S'

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "set-option -gq status-left #(${tool} status status)/#(${tool} status title)/#(${tool} status artist) #S" ]]
  [[ "${lines[1]}" == "set-option -gq status-right #(${tool} status icon) #(${tool} status now) #(${tool} status progress) #(${tool} status time)" ]]
  [[ "${lines[2]}" == "set-option -gq @music_revamped_published now icon status title artist progress time" ]]
}

@test "plan - in options mode each placeholder becomes a read of the option the daemon fills" {
  # Arrange
  option menu_key off
  option render options
  var status-right '#{music_icon} #{music} | #{music_time}'

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "set-option -gq status-right #{E:@music_revamped_out_icon} #{E:@music_revamped_out_now} | #{E:@music_revamped_out_time}" ]]
  [[ "${lines[1]}" == "set-option -gq @music_revamped_published now icon time" ]]
}

@test "plan - a status line already rewritten is left as it is, and its metrics stay recorded" {
  # Arrange
  local tool
  tool=$(tool_path)
  option menu_key off
  option render options
  option published "now time"
  var status-right '#{E:@music_revamped_out_now} | #{E:@music_revamped_out_time}'
  planned
  [[ -z "${output}" ]]
  option render jobs
  option published "icon title"
  var status-right "#(${tool} status icon) #(${tool} status title)"

  # Act
  planned

  # Assert
  [[ -z "${output}" ]]
}

@test "plan - a setting given in the environment rides on every key, every menu item and every job" {
  # Arrange
  var status-right '#{music}'
  option next_key F6

  # Act
  planned 'export MUSIC_REVAMPED_MAX_LEN=20; '

  # Assert
  [[ "${lines[0]}" == *"music-revamped' --max-len '20' play-pause\""* ]]
  [[ "${lines[1]}" == *"music-revamped' --max-len '20' next" ]]
  [[ "${lines[2]}" == *"music-revamped' --max-len '20' status now)" ]]
}

@test "plan - apply sends everything in one tmux call and clears a daemon's claim in jobs mode" {
  # Arrange
  option next_key F6
  var status-right '#{music}'

  # Act
  lib_run music 'music_revamped_apply'

  # Assert
  [[ "${status}" -eq 0 ]]
  run sends
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "${lines[0]}" == "bind-key -N Music menu M-m "*" ; bind-key -N Next track F6 run-shell "*" next ; set-option -gq status-right #("*" status now) ; set-option -gq @music_revamped_published now" ]]
  [[ "${lines[1]}" == "set-option -gqu @music_revamped_ticker_pid" ]]
}

@test "plan - when tmux refuses the batch each command is sent alone, and the bad one fails the run" {
  # Arrange
  local tool
  tool=$(tool_path)
  option next_key F99
  printf '%s\n' "bind-key -N Next track F99 run-shell ${tool} next" >"${FAKE}/refused"

  # Act
  lib_run music 'music_revamped_apply'

  # Assert
  [[ "${status}" -eq 1 ]]
  run sent '^bind-key -N Music menu M-m display-menu -T Music .* prev"$'
  [[ "${output}" == "1" ]]
}

@test "plan - in options mode apply starts the daemon, which claims the ticker and publishes until another takes over" {
  # Arrange
  cmus "status playing" "tag title So What" "tag artist Miles Davis"
  option menu_key off
  option render options
  option interval 1
  var status-right '#{music}'
  other_owner

  # Act
  lib_run music 'music_revamped_apply'

  # Assert
  [[ "${status}" -eq 0 ]]
  settled holds out_now "So What - Miles Davis"
  settled holds ticker_pid someone-else
  run sent '^set-option -gq @music_revamped_ticker_pid [0-9][0-9]*$'
  [[ "${output}" == "1" ]]
}

@test "plan - the daemon ends when another process owns the ticker" {
  # Arrange
  cmus "status playing" "tag title So What"
  option published "title"
  other_owner

  # Act
  tool daemon

  # Assert
  [[ "${status}" -eq 0 ]]
  holds out_title "So What"
  holds ticker_pid someone-else
}

@test "plan - the controls go to the player that is playing, through playerctl" {
  # Arrange
  playerctl_player firefox Paused "A Video" "A Channel" 3 60000000
  playerctl_player spotify Playing "Blue Train" "John Coltrane" 75 643000000
  control play-pause
  control next

  # Act
  control prev

  # Assert
  [[ "${status}" -eq 0 ]]
  run asked
  [[ "${output}" == *"-p spotify play-pause"*"-p spotify next"*"-p spotify previous"* ]]
}

@test "plan - with no player listed playerctl is called without one" {
  # Arrange
  quiet playerctl 'printf "%s\n" "$*" >>"'"${FAKE}"'/asked"'

  # Act
  control next

  # Assert
  run asked
  [[ "${lines[1]}" == "next" ]]
}

@test "plan - without playerctl the controls go to cmus" {
  # Arrange
  cmus "status playing" "tag title So What"
  control play-pause
  control next

  # Act
  control prev

  # Assert
  run asked
  [[ "${output}" == $'-u\n-n\n-r' ]]
}

@test "plan - on macOS with neither, the controls go to Spotify" {
  # Arrange
  macos
  spotify playing "So What" "Miles Davis" 10 545
  control play-pause
  control next

  # Act
  control prev

  # Assert
  run asked
  [[ "${lines[0]}" == '-e tell application "Spotify" to playpause' ]]
  [[ "${lines[1]}" == '-e tell application "Spotify" to next track' ]]
  [[ "${lines[2]}" == '-e tell application "Spotify" to previous track' ]]
}

@test "plan - with no player to control the key says so, on Linux even where osascript exists" {
  # Arrange
  spotify playing "So What" "Miles Davis" 10 545

  # Act
  control next

  # Assert
  [[ "${status}" -eq 0 ]]
  said "no player to control. install playerctl or cmus"
  run asked
  [[ -z "${output}" ]]
}

@test "plan - in options mode a control publishes the new reading at once, and in jobs mode it does not" {
  # Arrange
  cmus "status paused" "tag title So What"
  option published "icon"
  control play-pause
  run sent '@music_revamped_out_icon'
  [[ "${output}" == "0" ]]
  option render options

  # Act
  control play-pause

  # Assert
  holds out_icon "||"
}

@test "plan - a path is quoted for a job with each hash doubled, and for a key with none left" {
  # Arrange
  local script='music_revamped_job_quote "/a b/it'"'"'s#1"; music_revamped_literal "/a b/it'"'"'s#1"'

  # Act
  lib_run music "${script}"

  # Assert
  [[ "${lines[0]}" == "'/a b/it'\\''s##1'" ]]
  [[ "${lines[1]}" == "'/a b/it'\\''s'\"\$(printf '%b' '\\0043')\"'1'" ]]
}
