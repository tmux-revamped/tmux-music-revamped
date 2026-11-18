#!/bin/sh

music_revamped_dir=$(cd "$(dirname "$0")" && pwd)
"${music_revamped_dir}/bin/music-revamped" apply
