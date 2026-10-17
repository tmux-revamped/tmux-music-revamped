#!/usr/bin/env bash

# Mock every media-player binary the seams might shell out to. Defining them as
# exported shell functions guarantees that no real player is ever launched or
# controlled by a test, even when a seam is exercised directly. Each mock is a
# silent no-op that succeeds, so seam wrappers stay callable without side effects.
osascript() { return 0; }
playerctl() { return 0; }
nowplaying-cli() { return 0; }
cmus-remote() { return 0; }

export -f osascript
export -f playerctl
export -f cmus-remote
export -f nowplaying-cli
