#!/bin/sh
set -eu

: "${SCREENS_REPO:?}"
demo=/Users/Shared/demo
rm -rf "${demo}"
mkdir -p "${demo}/home" "${demo}/bin" "${demo}/player" "${demo}/tmux-music-revamped"
cp -Rpf "${SCREENS_REPO}/bin" "${SCREENS_REPO}/lib" "${SCREENS_REPO}/music-revamped.tmux" "${demo}/tmux-music-revamped/"
tmux_path=$(command -v tmux)
ln -s "${tmux_path}" "${demo}/bin/tmux"

printf '%s\n' 'So What|Miles Davis|545' 'Blue Train|John Coltrane|643' 'Naima|John Coltrane|261' >"${demo}/player/tracks"
printf '1\n' >"${demo}/player/track"
printf 'playing\n' >"${demo}/player/state"

cat >"${demo}/bin/cmus-remote" <<'PLAYER'
#!/bin/sh
folder=/Users/Shared/demo/player
read -r track <"${folder}/track"
read -r state <"${folder}/state"
case "${1:-}" in
-Q)
  line=$(sed -n "${track}p" "${folder}/tracks")
  title="${line%%|*}"
  rest="${line#*|}"
  printf 'status %s\ntag title %s\ntag artist %s\nposition 95\nduration %s\n' "${state}" "${title}" "${rest%%|*}" "${rest#*|}"
  ;;
-u)
  if [ "${state}" = playing ]; then
    printf 'paused\n' >"${folder}/state"
  else
    printf 'playing\n' >"${folder}/state"
  fi
  ;;
-n) printf '%s\n' "$((track % 3 + 1))" >"${folder}/track" ;;
-r) printf '%s\n' "$(((track + 1) % 3 + 1))" >"${folder}/track" ;;
*) : ;;
esac
PLAYER

cat >"${demo}/bin/nowplaying-cli" <<'READER'
#!/bin/sh
folder=/Users/Shared/demo/player
read -r track <"${folder}/track"
read -r state <"${folder}/state"
line=$(sed -n "${track}p" "${folder}/tracks")
title="${line%%|*}"
rest="${line#*|}"
rate=1
[ "${state}" = playing ] || rate=0
printf '%s\n%s\n%s\n95\n%s\n' "${title}" "${rest%%|*}" "${rate}" "${rest#*|}"
READER
chmod +x "${demo}/bin/cmus-remote" "${demo}/bin/nowplaying-cli"
