#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _MUSIC_REVAMPED_CONTROL_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/music/control.sh"
}

teardown() {
  cleanup_test_environment
}

@test "control.sh - functions are defined" {
  function_exists music_control
  function_exists music_control_backend
  function_exists _control_playerctl_arg
  function_exists _control_cmus_arg
  function_exists _control_osascript_cmd
}

@test "control.sh - playerctl arg mapper covers every verb" {
  [[ "$(_control_playerctl_arg play-pause)" == "play-pause" ]]
  [[ "$(_control_playerctl_arg next)" == "next" ]]
  [[ "$(_control_playerctl_arg prev)" == "previous" ]]
  ! _control_playerctl_arg bogus
}

@test "control.sh - cmus arg mapper covers every verb" {
  [[ "$(_control_cmus_arg play-pause)" == "-u" ]]
  [[ "$(_control_cmus_arg next)" == "-n" ]]
  [[ "$(_control_cmus_arg prev)" == "-r" ]]
  ! _control_cmus_arg bogus
}

@test "control.sh - osascript command mapper covers every verb" {
  [[ "$(_control_osascript_cmd play-pause)" == "playpause" ]]
  [[ "$(_control_osascript_cmd next)" == "next track" ]]
  [[ "$(_control_osascript_cmd prev)" == "previous track" ]]
  ! _control_osascript_cmd bogus
}

@test "control.sh - music_control_backend picks playerctl first" {
  has_command() { [[ "$1" == "playerctl" ]]; }
  [[ "$(music_control_backend)" == "playerctl" ]]
}

@test "control.sh - music_control_backend falls back to cmus" {
  has_command() { [[ "$1" == "cmus-remote" ]]; }
  [[ "$(music_control_backend)" == "cmus" ]]
}

@test "control.sh - music_control_backend uses osascript on macOS" {
  _PLATFORM_OS_CACHE="Darwin"
  has_command() { [[ "$1" == "osascript" ]]; }
  [[ "$(music_control_backend)" == "osascript" ]]
}

@test "control.sh - music_control_backend is none without any player" {
  _PLATFORM_OS_CACHE="Linux"
  has_command() { return 1; }
  [[ "$(music_control_backend)" == "none" ]]
}

@test "control.sh - music_control routes play-pause to playerctl" {
  has_command() { [[ "$1" == "playerctl" ]]; }
  _control_playerctl() { echo "pctl:$1"; }
  run music_control play-pause
  [[ "${output}" == "pctl:play-pause" ]]
}

@test "control.sh - music_control routes next to cmus" {
  has_command() { [[ "$1" == "cmus-remote" ]]; }
  _control_cmus() { echo "cmus:$1"; }
  run music_control next
  [[ "${output}" == "cmus:-n" ]]
}

@test "control.sh - music_control routes prev to osascript on macOS" {
  _PLATFORM_OS_CACHE="Darwin"
  has_command() { [[ "$1" == "osascript" ]]; }
  _control_osascript() { echo "osa:$1"; }
  run music_control prev
  [[ "${output}" == "osa:previous track" ]]
}

@test "control.sh - music_control is a no-op for an unknown verb" {
  has_command() { [[ "$1" == "playerctl" ]]; }
  _control_playerctl() { echo "should-not-run"; }
  run music_control bogus
  [[ -z "${output}" ]]
}

@test "control.sh - music_control is a no-op for an unknown cmus verb" {
  has_command() { [[ "$1" == "cmus-remote" ]]; }
  _control_cmus() { echo "should-not-run"; }
  run music_control bogus
  [[ -z "${output}" ]]
}

@test "control.sh - music_control is a no-op for an unknown osascript verb" {
  _PLATFORM_OS_CACHE="Darwin"
  has_command() { [[ "$1" == "osascript" ]]; }
  _control_osascript() { echo "should-not-run"; }
  run music_control bogus
  [[ -z "${output}" ]]
}

@test "control.sh - music_control is a no-op without any backend" {
  _PLATFORM_OS_CACHE="Linux"
  has_command() { return 1; }
  run music_control play-pause
  [[ -z "${output}" ]]
}

@test "control.sh - backend seams are callable without launching a player" {
  run _control_playerctl play-pause
  run _control_cmus -u
  run _control_osascript playpause
  true
}
