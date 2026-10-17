#!/usr/bin/env bash

osascript() { return 0; }
playerctl() { return 0; }
nowplaying-cli() { return 0; }
cmus-remote() { return 0; }

export -f osascript
export -f playerctl
export -f cmus-remote
export -f nowplaying-cli
