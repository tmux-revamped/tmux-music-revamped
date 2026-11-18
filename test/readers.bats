#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/music_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/music_helpers.bash"

reading() {
  lib_run music 'music_revamped_read | tr "\n" "|"'
}

source_is() {
  lib_run music 'music_revamped_source; printf "%s\n" "${MUSIC_REVAMPED_SOURCE}"'
}

@test "readers - with no player the source is none and nothing is read" {
  # Arrange
  local script='music_revamped_source; printf "[%s]" "${MUSIC_REVAMPED_SOURCE}"; music_revamped_read; printf "[end]\n"'

  # Act
  lib_run music "${script}"

  # Assert
  [[ "${output}" == "[none][end]" ]]
}

@test "readers - on macOS nowplaying-cli comes first, and on Linux it is not asked" {
  # Arrange
  nowplaying "Blue Train" "John Coltrane" 1 75.4 643.9
  cmus "status playing" "tag title So What"
  macos
  source_is
  [[ "${output}" == "nowplaying" ]]
  linux

  # Act
  source_is

  # Assert
  [[ "${output}" == "cmus" ]]
}

@test "readers - playerctl is the source only while a player answers it, then cmus, then Spotify on macOS" {
  # Arrange
  quiet playerctl ':'
  spotify playing "So What" "Miles Davis" 10 545000
  macos
  source_is
  [[ "${output}" == "osascript" ]]
  cmus "status playing" "tag title So What"
  source_is
  [[ "${output}" == "cmus" ]]
  playerctl_player spotify Playing "Blue Train" "John Coltrane" 75.2 643000000

  # Act
  source_is

  # Assert
  [[ "${output}" == "playerctl" ]]
}

@test "readers - nowplaying-cli gives the track with whole seconds, playing when its rate is above zero" {
  # Arrange
  macos
  nowplaying "Blue Train" "John Coltrane" 1 75.4 643.9
  reading
  [[ "${output}" == "playing|Blue Train|John Coltrane|75|643|" ]]
  nowplaying "Blue Train" "John Coltrane" 0 75.4 643.9

  # Act
  reading

  # Assert
  [[ "${output}" == "paused|Blue Train|John Coltrane|75|643|" ]]
  run asked
  [[ "${lines[0]}" == "get title artist playbackRate elapsedTime duration" ]]
}

@test "readers - nowplaying-cli with no title, or the word null, reads as nothing" {
  # Arrange
  macos
  nowplaying null null null null null
  reading
  [[ -z "${output}" ]]
  nowplaying "" "" 0 0 0

  # Act
  reading

  # Assert
  [[ -z "${output}" ]]
}

@test "readers - playerctl reads the player that is playing, with its length in seconds" {
  # Arrange
  playerctl_player firefox Paused "A Video" "A Channel" 3.9 60000000
  playerctl_player spotify Playing "Blue Train" "John Coltrane" 75.2 643000000

  # Act
  reading

  # Assert
  [[ "${output}" == "Playing|Blue Train|John Coltrane|75|643|" ]]
  run asked
  [[ "${output}" == *"-p spotify metadata mpris:length"* ]]
}

@test "readers - with no player playing playerctl reads the first one, and a length that is no number is zero" {
  # Arrange
  playerctl_player firefox Paused "A Video" "A Channel" 3.9 unknown
  playerctl_player vlc Stopped "A Film" "" 0 0

  # Act
  reading

  # Assert
  [[ "${output}" == "Paused|A Video|A Channel|3|0|" ]]
}

@test "readers - cmus gives its first status, title, artist, position and duration, words and all" {
  # Arrange
  cmus "status playing" "file /music/kind of blue/01.flac" "duration 545" "position 10" "tag artist Miles Davis" "tag title So What Now" "tag title ignored" "set repeat false"

  # Act
  reading

  # Assert
  [[ "${output}" == "playing|So What Now|Miles Davis|10|545|" ]]
  run asked
  [[ "${output}" == "-Q" ]]
}

@test "readers - a stopped cmus, or a track with no title, reads as nothing, and a paused one without times reads zeros" {
  # Arrange
  cmus "status stopped" "tag title So What"
  reading
  [[ -z "${output}" ]]
  cmus "status playing" "tag artist Miles Davis"
  reading
  [[ -z "${output}" ]]
  cmus "status paused" "tag title So What"

  # Act
  reading

  # Assert
  [[ "${output}" == "paused|So What||0|0|" ]]
}

@test "readers - Spotify through osascript gives whole seconds, with a length in milliseconds brought down" {
  # Arrange
  macos
  spotify playing "So What" "Miles Davis" 10.75 545000
  reading
  [[ "${output}" == "playing|So What|Miles Davis|10|545|" ]]
  spotify paused "Short" "Someone" "" 95

  # Act
  reading

  # Assert
  [[ "${output}" == "paused|Short|Someone|0|95|" ]]
}

@test "readers - Spotify not running, or with no track, reads as nothing" {
  # Arrange
  macos
  spotify ""
  reading
  [[ -z "${output}" ]]
  spotify stopped "" "" 0 0

  # Act
  reading

  # Assert
  [[ -z "${output}" ]]
}

@test "readers - a refresh stores the reading in one tmux call, with the status in lowercase" {
  # Arrange
  playerctl_player spotify Playing "Blue #1 Train;" "John Coltrane" 75.2 643000000

  # Act
  lib_run music 'music_revamped_refresh; printf "[%s]" "${MUSIC_REVAMPED_STORED}"'

  # Assert
  [[ "${output}" == "[1]" ]]
  run sends
  [[ "${output}" == "set-option -gq @music_revamped_status playing ; set-option -gq @music_revamped_status_ts 1000000 ; set-option -gq @music_revamped_title Blue #1 Train\\; ; set-option -gq @music_revamped_artist John Coltrane ; set-option -gq @music_revamped_position 75 ; set-option -gq @music_revamped_duration 643" ]]
}

@test "readers - a refresh with nothing playing stores an unknown status, no track and zeros" {
  # Arrange
  playing

  # Act
  lib_run music 'music_revamped_refresh'

  # Assert
  holds status unknown
  holds title ""
  holds artist ""
  holds position 0
  holds duration 0
}

@test "readers - every status a player can say is stored as playing, paused, stopped or unknown" {
  # Arrange
  local script='for MUSIC_REVAMPED_S_status in Playing PAUSED Stopped "Now playing" weird ""; do music_revamped_normal; printf "%s " "${MUSIC_REVAMPED_S_status}"; done'

  # Act
  lib_run music "${script}"

  # Assert
  [[ "${output}" == "playing paused stopped playing unknown unknown " ]]
}

@test "readers - a refresh tmux refuses is reported as not stored" {
  # Arrange
  : >"${FAKE}/refused"

  # Act
  lib_run music 'music_revamped_refresh; printf "[%s]" "${MUSIC_REVAMPED_STORED}"'

  # Assert
  [[ "${output}" == "[0]" ]]
}
