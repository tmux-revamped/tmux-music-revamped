#!/bin/sh
# shellcheck disable=SC2034

[ -n "${MUSIC_REVAMPED_CORE_LOADED:-}" ] && return 0
MUSIC_REVAMPED_CORE_LOADED=1

readonly MUSIC_REVAMPED_VERSION="3.1.0"
