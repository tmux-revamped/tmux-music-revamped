#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/music_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/music_helpers.bash"

shown() {
  lib_run music "$1"'; music_revamped_show '"$2"
}

status_of() {
  lib_run music 'music_revamped_status '"$1"
}

@test "music - a text longer than the limit is cut at whole characters and marked, and a limit of zero or junk keeps it whole" {
  # Arrange
  local script='for limit in 4 0 x 99; do music_revamped_cut "Größe é ok" "${limit}"; printf "[%s]" "${MUSIC_REVAMPED_CUT}"; done'

  # Act
  lib_run music "${script}"

  # Assert
  [[ "${output}" == "[Größ...][Größe é ok][Größe é ok][Größe é ok]" ]]
}

@test "music - a cut leaves the locale as it found it, set or unset" {
  # Arrange
  local script='LC_ALL=POSIX; music_revamped_cut "abcdef" 2; printf "[%s]" "${LC_ALL}"; unset LC_ALL; music_revamped_cut "abcdef" 2; printf "[%s]" "${LC_ALL-unset}"'

  # Act
  lib_run music "${script}"

  # Assert
  [[ "${output}" == "[POSIX][unset]" ]]
}

@test "music - the track is the title and the artist in the format, each hash doubled" {
  # Arrange
  local given='MUSIC_REVAMPED_S_title="Blue #1 Train" MUSIC_REVAMPED_S_artist="John #S Coltrane"'

  # Act
  shown "${given}" now

  # Assert
  [[ "${output}" == "Blue ##1 Train - John ##S Coltrane" ]]
}

@test "music - a track with no artist is its title alone, and no title prints nothing" {
  # Arrange
  shown 'MUSIC_REVAMPED_S_title="So What" MUSIC_REVAMPED_S_artist=""' now
  [[ "${output}" == "So What" ]]

  # Act
  shown 'MUSIC_REVAMPED_S_title="" MUSIC_REVAMPED_S_artist="Miles Davis" MUSIC_REVAMPED_S_before="["' now

  # Assert
  [[ -z "${output}" ]]
}

@test "music - the format, the limit, and the text before and after shape the track" {
  # Arrange
  local given='MUSIC_REVAMPED_S_title="Blue Train" MUSIC_REVAMPED_S_artist="John Coltrane" MUSIC_REVAMPED_S_format="%s by %s" MUSIC_REVAMPED_S_max_len=4 MUSIC_REVAMPED_S_before="#[fg=green]" MUSIC_REVAMPED_S_after="#[default]"'

  # Act
  shown "${given}" now

  # Assert
  [[ "${output}" == "#[fg=green]Blue... by John...#[default]" ]]
}

@test "music - the icon follows the state, and auto hide keeps it only while a track plays or is paused" {
  # Arrange
  local script='for MUSIC_REVAMPED_S_auto_hide in 1 0; do for MUSIC_REVAMPED_S_status in playing paused stopped unknown; do printf "[%s]" "$(music_revamped_show icon)"; done; done'

  # Act
  lib_run music 'MUSIC_REVAMPED_S_unknown_icon="?"; '"${script}"

  # Assert
  [[ "${output}" == "[>][||][][][>][||][[]][?]" ]]
}

@test "music - status, title and artist print the stored reading, the names with each hash doubled" {
  # Arrange
  local script='MUSIC_REVAMPED_S_status=paused MUSIC_REVAMPED_S_title="A #1" MUSIC_REVAMPED_S_artist="B #2"; music_revamped_show status; music_revamped_show title; music_revamped_show artist'

  # Act
  lib_run music "${script}"

  # Assert
  [[ "${lines[0]}" == "paused" ]]
  [[ "${lines[1]}" == "A ##1" ]]
  [[ "${lines[2]}" == "B ##2" ]]
}

@test "music - the progress bar fills in step with the position" {
  # Arrange
  local script='MUSIC_REVAMPED_S_duration=200 MUSIC_REVAMPED_S_progress_full="#" MUSIC_REVAMPED_S_progress_empty="-"; for MUSIC_REVAMPED_S_position in 0 50.9 100 200 900; do music_revamped_show progress; done'

  # Act
  lib_run music "${script}"

  # Assert
  [[ "${lines[0]}" == "----------" ]]
  [[ "${lines[1]}" == "##--------" ]]
  [[ "${lines[2]}" == "#####-----" ]]
  [[ "${lines[3]}" == "##########" ]]
  [[ "${lines[4]}" == "##########" ]]
}

@test "music - the bar's width comes from its setting, junk means ten cells and a huge width is capped" {
  # Arrange
  local script='MUSIC_REVAMPED_S_duration=100 MUSIC_REVAMPED_S_position=50 MUSIC_REVAMPED_S_progress_full="#" MUSIC_REVAMPED_S_progress_empty="-"; for MUSIC_REVAMPED_S_progress_width in 4 wide 008 5000; do bar=$(music_revamped_show progress); printf "%s " "${#bar}"; done'

  # Act
  lib_run music "${script}"

  # Assert
  [[ "${output}" == "4 10 8 200 " ]]
}

@test "music - with no duration the bar and the time print nothing" {
  # Arrange
  local script='MUSIC_REVAMPED_S_position=5; for MUSIC_REVAMPED_S_duration in 0 "" junk; do music_revamped_show progress; music_revamped_show time; done; printf "end\n"'

  # Act
  lib_run music "${script}"

  # Assert
  [[ "${output}" == "end" ]]
}

@test "music - the time is elapsed over total in minutes and two-digit seconds, in its format" {
  # Arrange
  shown 'MUSIC_REVAMPED_S_position=75.4 MUSIC_REVAMPED_S_duration=643' time
  [[ "${output}" == "1:15/10:43" ]]

  # Act
  shown 'MUSIC_REVAMPED_S_position=009 MUSIC_REVAMPED_S_duration=3600 MUSIC_REVAMPED_S_time_format="%s of %s"' time

  # Assert
  [[ "${output}" == "0:09 of 60:00" ]]
}

@test "music - a fresh reading is printed with one tmux read and no write" {
  # Arrange
  playing playing "Blue Train" "John Coltrane" 643 999998

  # Act
  status_of now

  # Assert
  [[ "${output}" == "Blue Train - John Coltrane" ]]
  run sends
  [[ -z "${output}" ]]
  run sent '^display-message -p'
  [[ "${output}" == "1" ]]
}

@test "music - a reading older than the interval is printed at once while the player is read behind it" {
  # Arrange
  playing playing "Old Song" "Old Band" 100 999990
  cmus "status paused" "tag title So What" "tag artist Miles Davis" "position 10" "duration 545"

  # Act
  status_of title

  # Assert
  [[ "${output}" == "Old Song" ]]
  eventually holds title "So What"
  eventually holds status_lock 0
  holds status paused
  holds status_ts 1000000
}

@test "music - with nothing stored yet the placeholders are empty and the first reading starts" {
  # Arrange
  cmus "status playing" "tag title So What"

  # Act
  status_of now

  # Assert
  [[ -z "${output}" ]]
  eventually holds title "So What"
}

@test "music - a reading under way is left to finish, and one whose lock is old or has no time is started again" {
  # Arrange
  cmus "status playing" "tag title So What"
  playing playing "Old Song" "Old Band" 100 999900
  option status_lock 1
  option status_lock_ts 999995
  status_of title
  run sends
  [[ -z "${output}" ]]
  option status_lock_ts 999970
  status_of title
  eventually holds title "So What"
  eventually holds status_lock 0
  playing playing "Old Song" "Old Band" 100 999900
  option status_lock 1
  option status_lock_ts ""

  # Act
  status_of title

  # Assert
  eventually holds title "So What"
}

@test "music - the interval comes from its setting, and junk there means five seconds" {
  # Arrange
  cmus "status playing" "tag title So What"
  playing playing "Old Song" "Old Band" 100 999960
  option interval 60
  status_of title
  run sends
  [[ -z "${output}" ]]
  option interval soon

  # Act
  status_of title

  # Assert
  eventually holds title "So What"
}

@test "music - a tick reads the player and publishes every metric the status line uses in one tmux call" {
  # Arrange
  cmus "status playing" "tag title 50% #1" "tag artist Miles" "position 30" "duration 60"
  option published "now icon time"
  printf 'client-a\n' >"${FAKE}/clients"

  # Act
  lib_run music 'music_revamped_tick'

  # Assert
  [[ "${status}" -eq 0 ]]
  holds out_now "50%% ##1 - Miles"
  holds out_icon ">"
  holds out_time "0:30/1:00"
  run sent 'set-option -gq @music_revamped_out_now .* ; set-option -gq @music_revamped_out_icon > ; set-option -gq @music_revamped_out_time 0:30/1:00 ; refresh-client -S -t client-a'
  [[ "${output}" == "1" ]]
}

@test "music - a tick publishes nothing when the status line uses no metric, or when tmux takes no write" {
  # Arrange
  cmus "status playing" "tag title So What"
  lib_run music 'music_revamped_tick'
  run sent '@music_revamped_out_'
  [[ "${output}" == "0" ]]
  option published "now"
  : >"${FAKE}/refused"

  # Act
  lib_run music 'music_revamped_tick'

  # Assert
  [[ "${status}" -eq 0 ]]
  run sent '@music_revamped_out_'
  [[ "${output}" == "0" ]]
}

@test "music - a tmux version is read out of its banner and compared part by part" {
  # Arrange
  local script='for banner in "tmux 3.6a" "tmux next-3.7" "nonsense"; do printf "[%s]" "$(music_revamped_parse_version "${banner}")"; done; for pair in "3.6 3.2" "3.2 3.2" "3.1 3.2" "4.0 3.2" "2.9 3.2" " 3.2" "x 3.2"; do if music_revamped_version_ge ${pair}; then printf y; else printf n; fi; done'

  # Act
  lib_run music "${script}"

  # Assert
  [[ "${output}" == "[3.6][3.7][]yynynnn" ]]
}
