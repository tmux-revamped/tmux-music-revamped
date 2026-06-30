#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _MUSIC_REVAMPED_RENDER_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/music/render.sh"
}

teardown() {
  cleanup_test_environment
}

@test "render.sh - _music_truncate shortens long text" {
  [[ "$(_music_truncate "Hello World" 5)" == "Hello..." ]]
}

@test "render.sh - _music_truncate leaves short text" {
  [[ "$(_music_truncate "Hi" 5)" == "Hi" ]]
}

@test "render.sh - _music_truncate is a no-op for max zero" {
  [[ "$(_music_truncate "anything" 0)" == "anything" ]]
}

@test "render.sh - _music_truncate is a no-op for non-numeric max" {
  [[ "$(_music_truncate "anything" zz)" == "anything" ]]
}

@test "render.sh - music_render_now is empty without a title" {
  [[ -z "$(music_render_now "" "")" ]]
}

@test "render.sh - music_render_now joins title and artist" {
  [[ "$(music_render_now "Song" "Band")" == "Song - Band" ]]
}

@test "render.sh - music_render_now shows the title alone without an artist" {
  [[ "$(music_render_now "Song" "")" == "Song" ]]
}

@test "render.sh - music_render_now honors a custom format" {
  set_tmux_option "@music_revamped_format" "%s by %s"
  [[ "$(music_render_now "Song" "Band")" == "Song by Band" ]]
}

@test "render.sh - music_render_now truncates with max_len" {
  set_tmux_option "@music_revamped_max_len" "4"
  [[ "$(music_render_now "LongTitle" "LongArtist")" == "Long... - Long..." ]]
}

@test "render.sh - music_is_active is true while playing or paused" {
  music_is_active playing
  music_is_active paused
}

@test "render.sh - music_is_active is false when stopped, unknown, or empty" {
  ! music_is_active stopped
  ! music_is_active unknown
  ! music_is_active ""
}

@test "render.sh - music_render_icon returns defaults per status with auto-hide off" {
  set_tmux_option "@music_revamped_auto_hide" "0"
  [[ "$(music_render_icon playing)" == ">" ]]
  [[ "$(music_render_icon paused)" == "||" ]]
  [[ "$(music_render_icon stopped)" == "[]" ]]
  [[ -z "$(music_render_icon unknown)" ]]
}

@test "render.sh - music_render_icon hides the icon when stopped by default" {
  [[ -z "$(music_render_icon stopped)" ]]
}

@test "render.sh - music_render_icon hides the icon on a cold start by default" {
  [[ -z "$(music_render_icon)" ]]
}

@test "render.sh - music_render_icon shows the stop glyph when auto-hide is off" {
  set_tmux_option "@music_revamped_auto_hide" "0"
  [[ "$(music_render_icon stopped)" == "[]" ]]
}

@test "render.sh - music_render_icon honors a custom icon" {
  set_tmux_option "@music_revamped_playing_icon" "PLAY"
  [[ "$(music_render_icon playing)" == "PLAY" ]]
}

@test "render.sh - music_render_text echoes its input" {
  [[ "$(music_render_text "hello")" == "hello" ]]
}

@test "render.sh - music_format_time formats seconds" {
  [[ "$(music_format_time 83)" == "1:23" ]]
  [[ "$(music_format_time 5)" == "0:05" ]]
  [[ "$(music_format_time xx)" == "0:00" ]]
}

@test "render.sh - music_build_progress draws a proportional bar" {
  [[ "$(music_build_progress 30 200 10 '#' '-')" == "#---------" ]]
  [[ "$(music_build_progress 100 100 4 '#' '-')" == "####" ]]
  [[ "$(music_build_progress 0 0 4 '#' '-')" == "----" ]]
}

@test "render.sh - music_render_progress is empty without a duration" {
  [[ -z "$(music_render_progress 0 0)" ]]
}

@test "render.sh - music_render_progress honors options" {
  set_tmux_option "@music_revamped_progress_width" "4"
  set_tmux_option "@music_revamped_progress_full" "#"
  set_tmux_option "@music_revamped_progress_empty" "-"
  [[ "$(music_render_progress 50 100)" == "##--" ]]
}

@test "render.sh - music_render_time formats elapsed and duration" {
  [[ -z "$(music_render_time 0 0)" ]]
  [[ "$(music_render_time 30 200)" == "0:30/3:20" ]]
  set_tmux_option "@music_revamped_time_format" "%s of %s"
  [[ "$(music_render_time 30 200)" == "0:30 of 3:20" ]]
}
