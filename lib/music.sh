#!/bin/sh

[ -n "${MUSIC_REVAMPED_MUSIC_LOADED:-}" ] && return 0
MUSIC_REVAMPED_MUSIC_LOADED=1

# shellcheck source=SCRIPTDIR/state.sh
. "${REVAMPED_LIB:?}/state.sh"
# shellcheck source=SCRIPTDIR/platform.sh
. "${REVAMPED_LIB}/platform.sh"
# shellcheck source=SCRIPTDIR/command.sh
. "${REVAMPED_LIB}/command.sh"
# shellcheck source=SCRIPTDIR/cache.sh
. "${REVAMPED_LIB}/cache.sh"
# shellcheck source=SCRIPTDIR/publish.sh
. "${REVAMPED_LIB}/publish.sh"
# shellcheck source=SCRIPTDIR/ticker.sh
. "${REVAMPED_LIB}/ticker.sh"

music_revamped_format() {
  printf '%s\n' "${MUSIC_REVAMPED_SETTINGS}" | awk -F '\t' -v live="${MUSIC_REVAMPED_LIVE}" '{ printf "%s#{@music_revamped_%s}", (NR > 1 ? "\t" : ""), $1 } END { count = split(live, name, " "); for (i = 1; i <= count; i++) { printf "\t#{@music_revamped_%s}", name[i] } }'
}

music_revamped_resolve() {
  env | MUSIC_REVAMPED_ROWS="${MUSIC_REVAMPED_SETTINGS}" MUSIC_REVAMPED_VALUES="$1" awk -v live="${MUSIC_REVAMPED_LIVE}" '
    BEGIN {
      count = split(ENVIRON["MUSIC_REVAMPED_ROWS"], rows, "\n")
      split(ENVIRON["MUSIC_REVAMPED_VALUES"], given, "\t")
      for (i = 1; i <= count; i++) {
        at = index(rows[i], "\t")
        if (at == 0) { at = length(rows[i]) + 1 }
        name[i] = substr(rows[i], 1, at - 1)
        value[i] = (given[i] != "") ? given[i] : substr(rows[i], at + 1)
        want["MUSIC_REVAMPED_" toupper(name[i])] = i
      }
    }
    {
      at = index($0, "=")
      key = substr($0, 1, at - 1)
      if (key in want) { value[want[key]] = substr($0, at + 1) }
    }
    END {
      for (i = 1; i <= count; i++) { print name[i] "\t" value[i] }
      extra = split(live, state, " ")
      for (i = 1; i <= extra; i++) { print state[i] "\t" given[count + i] }
    }
  '
}

music_revamped_load() {
  music_revamped_load_format=$(music_revamped_format)
  music_revamped_load_live=$(tmux display-message -p "${music_revamped_load_format}" 2>/dev/null) || music_revamped_load_live=""
  music_revamped_load_values=$(music_revamped_resolve "${music_revamped_load_live}")
  while IFS='	' read -r music_revamped_load_name music_revamped_load_value; do
    IFS= read -r "MUSIC_REVAMPED_S_${music_revamped_load_name}" <<EOF
${music_revamped_load_value}
EOF
  done <<EOF
${music_revamped_load_values}
EOF
}

music_revamped_parse_version() {
  printf '%s\n' "$1" | sed -En 's/^tmux[ -]([a-z]+-)?([0-9]+\.[0-9]+).*/\2/p'
}

music_revamped_version_ge() {
  case "$1:$2" in
  *[!0-9.:]* | :* | *:) return 1 ;;
  *) ;;
  esac
  music_revamped_version_ge_have="${1%%.*}"
  music_revamped_version_ge_want="${2%%.*}"
  [ "${music_revamped_version_ge_have}" -gt "${music_revamped_version_ge_want}" ] && return 0
  [ "${music_revamped_version_ge_have}" -eq "${music_revamped_version_ge_want}" ] || return 1
  music_revamped_version_ge_have="${1#*.}"
  music_revamped_version_ge_want="${2#*.}"
  [ "${music_revamped_version_ge_have%%.*}" -ge "${music_revamped_version_ge_want%%.*}" ]
}

music_revamped_emit() {
  for music_revamped_emit_arg in "$@"; do
    case "${music_revamped_emit_arg}" in
    *\;) music_revamped_emit_arg="${music_revamped_emit_arg%;}\\;" ;;
    *) ;;
    esac
    MUSIC_REVAMPED_PLAN="${MUSIC_REVAMPED_PLAN}${music_revamped_emit_arg:-${MUSIC_REVAMPED_EMPTY}}
"
  done
  MUSIC_REVAMPED_PLAN="${MUSIC_REVAMPED_PLAN}
"
}

music_revamped_literal() {
  printf '%s\n' "$1" | sed -e "s/'/'\\\\''/g" -e "s/#/'\"\$(printf '%b' '\\\\0043')\"'/g" -e "1s/^/'/" -e "\$s/\$/'/"
}

music_revamped_tmux_string() {
  printf '%s\n' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\$/\\$/g'
}

music_revamped_send() {
  set --
  music_revamped_send_sep=""
  while IFS= read -r music_revamped_send_line; do
    if [ -z "${music_revamped_send_line}" ]; then
      [ "$#" -eq 0 ] || music_revamped_send_sep=";"
      continue
    fi
    [ -z "${music_revamped_send_sep}" ] || set -- "$@" "${music_revamped_send_sep}"
    music_revamped_send_sep=""
    [ "${music_revamped_send_line}" != "${MUSIC_REVAMPED_EMPTY}" ] || music_revamped_send_line=""
    set -- "$@" "${music_revamped_send_line}"
  done <<PLAN
${MUSIC_REVAMPED_PLAN}
PLAN
  [ "$#" -gt 0 ] || return 0
  tmux "$@" 2>/dev/null
}

music_revamped_send_each() {
  music_revamped_send_each_status=0
  set --
  while IFS= read -r music_revamped_send_each_line; do
    if [ -n "${music_revamped_send_each_line}" ]; then
      [ "${music_revamped_send_each_line}" != "${MUSIC_REVAMPED_EMPTY}" ] || music_revamped_send_each_line=""
      set -- "$@" "${music_revamped_send_each_line}"
      continue
    fi
    [ "$#" -gt 0 ] || continue
    tmux "$@" || music_revamped_send_each_status=1
    set --
  done <<PLAN
${MUSIC_REVAMPED_PLAN}
PLAN
  return "${music_revamped_send_each_status}"
}

music_revamped_deliver() {
  ! music_revamped_send || return 0
  music_revamped_send_each
}

music_revamped_lines() {
  printf '%s' "${MUSIC_REVAMPED_PLAN}" | awk -v empty="${MUSIC_REVAMPED_EMPTY}" '$0 == empty { $0 = "\"\"" } $0 == "" && line != "" { print line; line = ""; next } $0 == "" { next } { line = (line == "" ? $0 : line " " $0) } END { if (line != "") { print line } }'
}

music_revamped_json() {
  printf '%s' "${MUSIC_REVAMPED_PLAN}" | awk -v empty="${MUSIC_REVAMPED_EMPTY}" '
    function quote(s,    out, i, c) {
      out = ""
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == "\\") { out = out "\\\\" } else if (c == "\"") { out = out "\\\"" } else { out = out c }
      }
      return "\"" out "\""
    }
    /^$/ { if (args != "") { rows = rows (rows == "" ? "" : ",") "[" args "]" } args = ""; next }
    $0 == empty { $0 = "" }
    { args = args (args == "" ? "" : ",") quote($0) }
    END {
      if (args != "") { rows = rows (rows == "" ? "" : ",") "[" args "]" }
      print "{\"bindings\":[" rows "]}"
    }
  '
}

music_revamped_bindings() {
  printf '%s' "${MUSIC_REVAMPED_PLAN}" | awk 'previous == "" && $0 == "bind-key" { count++ } { previous = $0 } END { print count + 0 }'
}

music_revamped_setting_name() {
  music_revamped_setting_name_raw=$(printf '%s\n' "${1#--}" | tr '-' '_')
  case " ${MUSIC_REVAMPED_NAMES} " in
  *" ${music_revamped_setting_name_raw} "*) printf '%s\n' "${music_revamped_setting_name_raw}" ;;
  *) printf '\n' ;;
  esac
}

music_revamped_bind() {
  case "$1" in
  "" | off) return 0 ;;
  *) ;;
  esac
  case " ${MUSIC_REVAMPED_BOUND} " in
  *" $1 "*)
    MUSIC_REVAMPED_SKIPPED="${MUSIC_REVAMPED_SKIPPED}${MUSIC_REVAMPED_SKIPPED:+ }$1"
    return 0
    ;;
  *) ;;
  esac
  MUSIC_REVAMPED_BOUND="${MUSIC_REVAMPED_BOUND} $1"
  music_revamped_bind_key="$1" music_revamped_bind_note="$2"
  shift 2
  set -- "${music_revamped_bind_key}" "$@"
  [ "${MUSIC_REVAMPED_NOTES}" != 1 ] || set -- -N "${music_revamped_bind_note}" "$@"
  music_revamped_emit bind-key "$@"
}

music_revamped_job_quote() {
  printf '%s\n' "$1" | sed -e "s/'/'\\\\''/g" -e 's/#/##/g' -e 's/%/%%/g' -e "1s/^/'/" -e "\$s/\$/'/"
}

music_revamped_carried() {
  music_revamped_carried_set=$(env | sed -n 's/^MUSIC_REVAMPED_\([A-Z_]*\)=\(.*\)$/\1 \2/p')
  [ -n "${music_revamped_carried_set}" ] || return 0
  printf '%s\n' "${music_revamped_carried_set}" | MUSIC_REVAMPED_WANTED="${MUSIC_REVAMPED_CARRIED}" awk '
    BEGIN { count = split(ENVIRON["MUSIC_REVAMPED_WANTED"], name, " "); for (i = 1; i <= count; i++) { wanted[toupper(name[i])] = i } }
    {
      key = $1
      if (!(key in wanted)) { next }
      given[wanted[key]] = 1
      value[wanted[key]] = substr($0, length(key) + 2)
    }
    END {
      for (i = 1; i <= count; i++) {
        if (!given[i]) { continue }
        flag = name[i]
        gsub(/_/, "-", flag)
        print flag "\t" value[i]
      }
    }
  '
}

music_revamped_tools() {
  music_revamped_tools_path="${REVAMPED_LIB%/lib}/bin/music-revamped"
  MUSIC_REVAMPED_TOOL=$(music_revamped_literal "${music_revamped_tools_path}")
  MUSIC_REVAMPED_JOB=$(music_revamped_job_quote "${music_revamped_tools_path}")
  music_revamped_tools_rows=$(music_revamped_carried)
  while IFS='	' read -r music_revamped_tools_flag music_revamped_tools_value; do
    [ -n "${music_revamped_tools_flag}" ] || continue
    MUSIC_REVAMPED_TOOL="${MUSIC_REVAMPED_TOOL} --${music_revamped_tools_flag} $(music_revamped_literal "${music_revamped_tools_value}")"
    MUSIC_REVAMPED_JOB="${MUSIC_REVAMPED_JOB} --${music_revamped_tools_flag} $(music_revamped_job_quote "${music_revamped_tools_value}")"
  done <<EOF
${music_revamped_tools_rows}
EOF
}

music_revamped_held() {
  tmux list-keys -T prefix 2>/dev/null | awk '
    {
      at = 2
      if ($at == "-r") { at++ }
      if ($at == "-T") { at += 2 }
      key = $at
      if (key ~ /^\\./) { key = substr(key, 2) }
      rest = ""
      for (i = at + 1; i <= NF; i++) { rest = rest " " $i }
      if (index(rest, "music-revamped") == 0) { printf "%s ", key }
    }
  '
}

music_revamped_doubled() {
  music_revamped_doubled_rest="$1" music_revamped_doubled_hash='#' MUSIC_REVAMPED_DOUBLED=""
  while [ "${music_revamped_doubled_rest}" != "${music_revamped_doubled_rest#*"${music_revamped_doubled_hash}"}" ]; do
    MUSIC_REVAMPED_DOUBLED="${MUSIC_REVAMPED_DOUBLED}${music_revamped_doubled_rest%%"${music_revamped_doubled_hash}"*}${music_revamped_doubled_hash}${music_revamped_doubled_hash}"
    music_revamped_doubled_rest="${music_revamped_doubled_rest#*"${music_revamped_doubled_hash}"}"
  done
  MUSIC_REVAMPED_DOUBLED="${MUSIC_REVAMPED_DOUBLED}${music_revamped_doubled_rest}"
}

music_revamped_say() {
  music_revamped_doubled "$1"
  tmux display-message "music-revamped: ${MUSIC_REVAMPED_DOUBLED}" 2>/dev/null || :
}

music_revamped_now() {
  MUSIC_REVAMPED_NOW=$(date +%s 2>/dev/null) || MUSIC_REVAMPED_NOW=0
}

music_revamped_version() {
  music_revamped_version_raw=$(tmux -V 2>/dev/null) || music_revamped_version_raw=""
  MUSIC_REVAMPED_TMUX=$(music_revamped_parse_version "${music_revamped_version_raw}")
}

music_revamped_cut() {
  MUSIC_REVAMPED_CUT="$1"
  case "$2" in
  '' | *[!0-9]* | 0) return 0 ;;
  *) revamped_publish_count "$1" ;;
  esac
  [ "${revamped_publish_count_out}" -gt "$2" ] || return 0
  music_revamped_cut_locale="${LC_ALL-}"
  music_revamped_cut_locale_set="${LC_ALL+set}"
  LC_ALL=C
  music_revamped_cut_rest="$1" music_revamped_cut_out="" music_revamped_cut_kept=0
  while [ -n "${music_revamped_cut_rest}" ]; do
    music_revamped_cut_tail="${music_revamped_cut_rest#?}"
    music_revamped_cut_byte="${music_revamped_cut_rest%"${music_revamped_cut_tail}"}"
    case "${REVAMPED_PUBLISH_CONTINUATION}" in
    *"${music_revamped_cut_byte}"*) : ;;
    *)
      [ "${music_revamped_cut_kept}" -lt "$2" ] || break
      music_revamped_cut_kept=$((music_revamped_cut_kept + 1))
      ;;
    esac
    music_revamped_cut_out="${music_revamped_cut_out}${music_revamped_cut_byte}"
    music_revamped_cut_rest="${music_revamped_cut_tail}"
  done
  if [ "${music_revamped_cut_locale_set}" = set ]; then
    LC_ALL="${music_revamped_cut_locale}"
  else
    unset LC_ALL
  fi
  MUSIC_REVAMPED_CUT="${music_revamped_cut_out}..."
}

music_revamped_source() {
  if revamped_is_macos && revamped_has_command nowplaying-cli; then
    MUSIC_REVAMPED_SOURCE=nowplaying
  elif revamped_has_command playerctl && music_revamped_playerctl_answers; then
    MUSIC_REVAMPED_SOURCE=playerctl
  elif revamped_has_command cmus-remote; then
    MUSIC_REVAMPED_SOURCE=cmus
  elif revamped_is_macos && revamped_has_command osascript; then
    MUSIC_REVAMPED_SOURCE=osascript
  else
    MUSIC_REVAMPED_SOURCE=none
  fi
}

music_revamped_playerctl_answers() {
  music_revamped_playerctl_answers_status=$(playerctl status 2>/dev/null) || music_revamped_playerctl_answers_status=""
  [ -n "${music_revamped_playerctl_answers_status}" ]
}

music_revamped_read_nowplaying() {
  music_revamped_read_nowplaying_raw=$(nowplaying-cli get title artist playbackRate elapsedTime duration 2>/dev/null) || music_revamped_read_nowplaying_raw=""
  printf '%s\n' "${music_revamped_read_nowplaying_raw}" | awk '
    NR <= 5 { value[NR] = $0 }
    END {
      if (value[1] == "" || value[1] == "null") { exit }
      state = (value[3] ~ /^[0-9]*\.?[0-9]*$/ && value[3] ~ /[1-9]/) ? "playing" : "paused"
      sub(/\..*/, "", value[4])
      sub(/\..*/, "", value[5])
      print state
      print value[1]
      print value[2]
      print value[4]
      print value[5]
    }
  '
}

music_revamped_pick() {
  MUSIC_REVAMPED_PLAYER=""
  music_revamped_pick_names=$(playerctl --list-all 2>/dev/null) || music_revamped_pick_names=""
  while IFS= read -r music_revamped_pick_name; do
    [ -n "${music_revamped_pick_name}" ] || continue
    [ -n "${MUSIC_REVAMPED_PLAYER}" ] || MUSIC_REVAMPED_PLAYER="${music_revamped_pick_name}"
    music_revamped_pick_status=$(playerctl -p "${music_revamped_pick_name}" status 2>/dev/null) || music_revamped_pick_status=""
    case "${music_revamped_pick_status}" in
    *[Pp][Ll][Aa][Yy][Ii][Nn][Gg]*)
      MUSIC_REVAMPED_PLAYER="${music_revamped_pick_name}"
      return 0
      ;;
    *) continue ;;
    esac
  done <<EOF
${music_revamped_pick_names}
EOF
}

music_revamped_playerctl() {
  if [ -n "${MUSIC_REVAMPED_PLAYER}" ]; then
    playerctl -p "${MUSIC_REVAMPED_PLAYER}" "$@" 2>/dev/null
    return 0
  fi
  playerctl "$@" 2>/dev/null
}

music_revamped_read_playerctl() {
  music_revamped_pick
  music_revamped_read_playerctl_status=$(music_revamped_playerctl status) || music_revamped_read_playerctl_status=""
  music_revamped_read_playerctl_length=$(music_revamped_playerctl metadata mpris:length) || music_revamped_read_playerctl_length=""
  music_revamped_read_playerctl_title=$(music_revamped_playerctl metadata title) || music_revamped_read_playerctl_title=""
  music_revamped_read_playerctl_artist=$(music_revamped_playerctl metadata artist) || music_revamped_read_playerctl_artist=""
  music_revamped_read_playerctl_position=$(music_revamped_playerctl position) || music_revamped_read_playerctl_position=""
  music_revamped_read_playerctl_duration=0
  ! revamped_cache_is_number "${music_revamped_read_playerctl_length}" || music_revamped_read_playerctl_duration=$((music_revamped_read_playerctl_length / 1000000))
  printf '%s\n%s\n%s\n%s\n%s\n' "${music_revamped_read_playerctl_status}" "${music_revamped_read_playerctl_title}" "${music_revamped_read_playerctl_artist}" "${music_revamped_read_playerctl_position%%.*}" "${music_revamped_read_playerctl_duration}"
}

music_revamped_read_cmus() {
  music_revamped_read_cmus_raw=$(cmus-remote -Q 2>/dev/null) || music_revamped_read_cmus_raw=""
  printf '%s\n' "${music_revamped_read_cmus_raw}" | awk '
    function rest(from, text, i) {
      text = $from
      for (i = from + 1; i <= NF; i++) { text = text " " $i }
      return text
    }
    $1 == "status" && state == "" { state = $2 }
    $1 == "tag" && $2 == "title" && !have_title { title = rest(3); have_title = 1 }
    $1 == "tag" && $2 == "artist" && !have_artist { artist = rest(3); have_artist = 1 }
    $1 == "position" && position == "" { position = $2 }
    $1 == "duration" && duration == "" { duration = $2 }
    END {
      if ((state != "playing" && state != "paused") || title == "") { exit }
      print state
      print title
      print artist
      print (position == "" ? 0 : position)
      print (duration == "" ? 0 : duration)
    }
  '
}

music_revamped_spotify() {
  osascript 2>/dev/null <<'APPLESCRIPT'
on run
  if application "Spotify" is running then
    tell application "Spotify"
      set st to player state as string
      set tt to name of current track
      set ar to artist of current track
      set pp to player position as string
      set du to duration of current track as string
      return st & linefeed & tt & linefeed & ar & linefeed & pp & linefeed & du
    end tell
  end if
end run
APPLESCRIPT
}

music_revamped_read_osascript() {
  music_revamped_read_osascript_raw=$(music_revamped_spotify) || music_revamped_read_osascript_raw=""
  printf '%s\n' "${music_revamped_read_osascript_raw}" | awk -v above="${MUSIC_REVAMPED_MILLISECONDS_ABOVE}" '
    NR <= 5 { value[NR] = $0 }
    END {
      if (value[2] == "") { exit }
      sub(/\..*/, "", value[4])
      sub(/\..*/, "", value[5])
      if (value[5] ~ /^[0-9]+$/ && value[5] + 0 > above + 0) { value[5] = int(value[5] / 1000) }
      print value[1]
      print value[2]
      print value[3]
      print (value[4] == "" ? 0 : value[4])
      print (value[5] == "" ? 0 : value[5])
    }
  '
}

music_revamped_read() {
  music_revamped_source
  case "${MUSIC_REVAMPED_SOURCE}" in
  nowplaying) music_revamped_read_nowplaying ;;
  playerctl) music_revamped_read_playerctl ;;
  cmus) music_revamped_read_cmus ;;
  osascript) music_revamped_read_osascript ;;
  *) return 0 ;;
  esac
}

music_revamped_take() {
  IFS= read -r MUSIC_REVAMPED_S_status || MUSIC_REVAMPED_S_status=""
  IFS= read -r MUSIC_REVAMPED_S_title || MUSIC_REVAMPED_S_title=""
  IFS= read -r MUSIC_REVAMPED_S_artist || MUSIC_REVAMPED_S_artist=""
  IFS= read -r MUSIC_REVAMPED_S_position || MUSIC_REVAMPED_S_position=""
  IFS= read -r MUSIC_REVAMPED_S_duration || MUSIC_REVAMPED_S_duration=""
}

music_revamped_normal() {
  case "${MUSIC_REVAMPED_S_status}" in
  *[Pp][Ll][Aa][Yy][Ii][Nn][Gg]*) MUSIC_REVAMPED_S_status=playing ;;
  *[Pp][Aa][Uu][Ss][Ee][Dd]*) MUSIC_REVAMPED_S_status=paused ;;
  *[Ss][Tt][Oo][Pp][Pp][Ee][Dd]*) MUSIC_REVAMPED_S_status=stopped ;;
  *) MUSIC_REVAMPED_S_status=unknown ;;
  esac
  [ -n "${MUSIC_REVAMPED_S_position}" ] || MUSIC_REVAMPED_S_position=0
  [ -n "${MUSIC_REVAMPED_S_duration}" ] || MUSIC_REVAMPED_S_duration=0
}

music_revamped_refresh() {
  music_revamped_refresh_reading=$(music_revamped_read) || music_revamped_refresh_reading=""
  music_revamped_take <<EOF
${music_revamped_refresh_reading}
EOF
  music_revamped_normal
  music_revamped_now
  MUSIC_REVAMPED_PLAN=""
  music_revamped_emit set-option -gq @music_revamped_status "${MUSIC_REVAMPED_S_status}"
  music_revamped_emit set-option -gq @music_revamped_status_ts "${MUSIC_REVAMPED_NOW}"
  music_revamped_emit set-option -gq @music_revamped_title "${MUSIC_REVAMPED_S_title}"
  music_revamped_emit set-option -gq @music_revamped_artist "${MUSIC_REVAMPED_S_artist}"
  music_revamped_emit set-option -gq @music_revamped_position "${MUSIC_REVAMPED_S_position}"
  music_revamped_emit set-option -gq @music_revamped_duration "${MUSIC_REVAMPED_S_duration}"
  MUSIC_REVAMPED_STORED=1
  music_revamped_send || MUSIC_REVAMPED_STORED=0
}

music_revamped_limit() {
  MUSIC_REVAMPED_LIMIT="${MUSIC_REVAMPED_S_interval}"
  revamped_cache_is_number "${MUSIC_REVAMPED_LIMIT}" || MUSIC_REVAMPED_LIMIT="${MUSIC_REVAMPED_DEFAULT_INTERVAL}"
}

music_revamped_stale() {
  revamped_cache_is_number "${MUSIC_REVAMPED_S_status_ts}" || return 0
  [ "$((MUSIC_REVAMPED_NOW - MUSIC_REVAMPED_S_status_ts))" -gt "${MUSIC_REVAMPED_LIMIT}" ]
}

music_revamped_locked() {
  [ "${MUSIC_REVAMPED_S_status_lock}" = 1 ] || return 1
  revamped_cache_is_number "${MUSIC_REVAMPED_S_status_lock_ts}" || return 1
  [ "$((MUSIC_REVAMPED_NOW - MUSIC_REVAMPED_S_status_lock_ts))" -lt "${REVAMPED_CACHE_MAX_RUN_DEFAULT}" ]
}

music_revamped_print() {
  [ -z "$1" ] || printf '%s\n' "$1"
}

music_revamped_show_now() {
  [ -n "${MUSIC_REVAMPED_S_title}" ] || return 0
  music_revamped_cut "${MUSIC_REVAMPED_S_title}" "${MUSIC_REVAMPED_S_max_len}"
  music_revamped_doubled "${MUSIC_REVAMPED_CUT}"
  music_revamped_show_now_text="${MUSIC_REVAMPED_DOUBLED}"
  if [ -n "${MUSIC_REVAMPED_S_artist}" ]; then
    music_revamped_cut "${MUSIC_REVAMPED_S_artist}" "${MUSIC_REVAMPED_S_max_len}"
    music_revamped_doubled "${MUSIC_REVAMPED_CUT}"
    # shellcheck disable=SC2059
    music_revamped_show_now_text=$(printf "${MUSIC_REVAMPED_S_format}" "${music_revamped_show_now_text}" "${MUSIC_REVAMPED_DOUBLED}")
  fi
  music_revamped_print "${MUSIC_REVAMPED_S_before}${music_revamped_show_now_text}${MUSIC_REVAMPED_S_after}"
}

music_revamped_show_icon() {
  case "${MUSIC_REVAMPED_S_auto_hide}:${MUSIC_REVAMPED_S_status}" in
  *:playing) music_revamped_print "${MUSIC_REVAMPED_S_playing_icon}" ;;
  *:paused) music_revamped_print "${MUSIC_REVAMPED_S_paused_icon}" ;;
  1:*) return 0 ;;
  *:stopped) music_revamped_print "${MUSIC_REVAMPED_S_stopped_icon}" ;;
  *) music_revamped_print "${MUSIC_REVAMPED_S_unknown_icon}" ;;
  esac
}

music_revamped_whole() {
  MUSIC_REVAMPED_WHOLE="${1%%.*}"
  revamped_cache_is_number "${MUSIC_REVAMPED_WHOLE}" || MUSIC_REVAMPED_WHOLE=0
  while [ "${MUSIC_REVAMPED_WHOLE}" != "${MUSIC_REVAMPED_WHOLE#0}" ] && [ "${#MUSIC_REVAMPED_WHOLE}" -gt 1 ]; do
    MUSIC_REVAMPED_WHOLE="${MUSIC_REVAMPED_WHOLE#0}"
  done
}

music_revamped_show_progress() {
  music_revamped_whole "${MUSIC_REVAMPED_S_duration}"
  music_revamped_show_progress_duration="${MUSIC_REVAMPED_WHOLE}"
  [ "${music_revamped_show_progress_duration}" -gt 0 ] || return 0
  music_revamped_whole "${MUSIC_REVAMPED_S_position}"
  music_revamped_show_progress_position="${MUSIC_REVAMPED_WHOLE}"
  music_revamped_whole "${MUSIC_REVAMPED_S_progress_width}"
  music_revamped_show_progress_width="${MUSIC_REVAMPED_WHOLE}"
  revamped_cache_is_number "${MUSIC_REVAMPED_S_progress_width}" || music_revamped_show_progress_width="${MUSIC_REVAMPED_DEFAULT_WIDTH}"
  [ "${music_revamped_show_progress_width}" -le "${MUSIC_REVAMPED_MAX_WIDTH}" ] || music_revamped_show_progress_width="${MUSIC_REVAMPED_MAX_WIDTH}"
  music_revamped_show_progress_filled=$((music_revamped_show_progress_position * music_revamped_show_progress_width / music_revamped_show_progress_duration))
  [ "${music_revamped_show_progress_filled}" -le "${music_revamped_show_progress_width}" ] || music_revamped_show_progress_filled="${music_revamped_show_progress_width}"
  MUSIC_REVAMPED_BAR="" music_revamped_show_progress_cell=0
  while [ "${music_revamped_show_progress_cell}" -lt "${music_revamped_show_progress_width}" ]; do
    if [ "${music_revamped_show_progress_cell}" -lt "${music_revamped_show_progress_filled}" ]; then
      MUSIC_REVAMPED_BAR="${MUSIC_REVAMPED_BAR}${MUSIC_REVAMPED_S_progress_full}"
    else
      MUSIC_REVAMPED_BAR="${MUSIC_REVAMPED_BAR}${MUSIC_REVAMPED_S_progress_empty}"
    fi
    music_revamped_show_progress_cell=$((music_revamped_show_progress_cell + 1))
  done
  music_revamped_print "${MUSIC_REVAMPED_BAR}"
}

music_revamped_clock() {
  music_revamped_whole "$1"
  music_revamped_clock_seconds=$((MUSIC_REVAMPED_WHOLE % 60))
  [ "${music_revamped_clock_seconds}" -ge 10 ] || music_revamped_clock_seconds="0${music_revamped_clock_seconds}"
  MUSIC_REVAMPED_CLOCK="$((MUSIC_REVAMPED_WHOLE / 60)):${music_revamped_clock_seconds}"
}

music_revamped_show_time() {
  music_revamped_whole "${MUSIC_REVAMPED_S_duration}"
  [ "${MUSIC_REVAMPED_WHOLE}" -gt 0 ] || return 0
  music_revamped_clock "${MUSIC_REVAMPED_S_duration}"
  music_revamped_show_time_total="${MUSIC_REVAMPED_CLOCK}"
  music_revamped_clock "${MUSIC_REVAMPED_S_position}"
  # shellcheck disable=SC2059
  printf "${MUSIC_REVAMPED_S_time_format}\n" "${MUSIC_REVAMPED_CLOCK}" "${music_revamped_show_time_total}"
}

music_revamped_show() {
  case "$1" in
  now) music_revamped_show_now ;;
  icon) music_revamped_show_icon ;;
  status) music_revamped_print "${MUSIC_REVAMPED_S_status}" ;;
  title)
    music_revamped_doubled "${MUSIC_REVAMPED_S_title}"
    music_revamped_print "${MUSIC_REVAMPED_DOUBLED}"
    ;;
  artist)
    music_revamped_doubled "${MUSIC_REVAMPED_S_artist}"
    music_revamped_print "${MUSIC_REVAMPED_DOUBLED}"
    ;;
  progress) music_revamped_show_progress ;;
  *) music_revamped_show_time ;;
  esac
}

music_revamped_status() {
  music_revamped_load
  music_revamped_now
  music_revamped_limit
  if music_revamped_stale && ! music_revamped_locked; then
    revamped_cache_refresh_if_stale status "${MUSIC_REVAMPED_LIMIT}" music_revamped_refresh || :
  fi
  music_revamped_show "$1"
}

music_revamped_publish() {
  music_revamped_refresh
  [ "${MUSIC_REVAMPED_STORED}" = 1 ] || return 0
  for music_revamped_publish_metric in ${MUSIC_REVAMPED_S_published}; do
    music_revamped_publish_value=$(music_revamped_show "${music_revamped_publish_metric}")
    revamped_publish_add "@music_revamped_out_${music_revamped_publish_metric}" "${music_revamped_publish_value}"
  done
  revamped_publish_commit || :
}

music_revamped_tick() {
  music_revamped_load
  music_revamped_publish
}

music_revamped_daemon() {
  revamped_ticker_run music_revamped music_revamped_tick "$$" "${MUSIC_REVAMPED_DEFAULT_INTERVAL}"
}

music_revamped_backend() {
  if revamped_has_command playerctl; then
    MUSIC_REVAMPED_BACKEND=playerctl
  elif revamped_has_command cmus-remote; then
    MUSIC_REVAMPED_BACKEND=cmus
  elif revamped_is_macos && revamped_has_command osascript; then
    MUSIC_REVAMPED_BACKEND=osascript
  else
    MUSIC_REVAMPED_BACKEND=none
  fi
}

music_revamped_control_playerctl() {
  music_revamped_pick
  case "$1" in
  play-pause) music_revamped_playerctl play-pause ;;
  next) music_revamped_playerctl next ;;
  *) music_revamped_playerctl previous ;;
  esac
}

music_revamped_control_cmus() {
  case "$1" in
  play-pause) cmus-remote -u 2>/dev/null ;;
  next) cmus-remote -n 2>/dev/null ;;
  *) cmus-remote -r 2>/dev/null ;;
  esac
}

music_revamped_control_osascript() {
  case "$1" in
  play-pause) osascript -e 'tell application "Spotify" to playpause' 2>/dev/null ;;
  next) osascript -e 'tell application "Spotify" to next track' 2>/dev/null ;;
  *) osascript -e 'tell application "Spotify" to previous track' 2>/dev/null ;;
  esac
}

music_revamped_control() {
  music_revamped_backend
  case "${MUSIC_REVAMPED_BACKEND}" in
  playerctl) music_revamped_control_playerctl "$1" || : ;;
  cmus) music_revamped_control_cmus "$1" || : ;;
  osascript) music_revamped_control_osascript "$1" || : ;;
  *)
    music_revamped_say "no player to control. install playerctl or cmus"
    return 0
    ;;
  esac
  music_revamped_load
  [ "${MUSIC_REVAMPED_S_render}" = options ] || return 0
  music_revamped_publish
}

music_revamped_plan_keys() {
  music_revamped_plan_keys_tool=$(music_revamped_tmux_string "${MUSIC_REVAMPED_TOOL}")
  case "${MUSIC_REVAMPED_S_menu_key}: ${MUSIC_REVAMPED_KEYS} " in
  "${MUSIC_REVAMPED_DEFAULT_MENU_KEY}:"*" ${MUSIC_REVAMPED_DEFAULT_MENU_KEY} "*) MUSIC_REVAMPED_SKIPPED="${MUSIC_REVAMPED_DEFAULT_MENU_KEY}" ;;
  *) music_revamped_bind "${MUSIC_REVAMPED_S_menu_key}" "Music menu" display-menu -T "${MUSIC_REVAMPED_TITLE}" "Play/Pause" p "run-shell \"${music_revamped_plan_keys_tool} play-pause\"" Next n "run-shell \"${music_revamped_plan_keys_tool} next\"" Previous b "run-shell \"${music_revamped_plan_keys_tool} prev\"" ;;
  esac
  music_revamped_bind "${MUSIC_REVAMPED_S_playpause_key}" "Play or pause" run-shell "${MUSIC_REVAMPED_TOOL} play-pause"
  music_revamped_bind "${MUSIC_REVAMPED_S_next_key}" "Next track" run-shell "${MUSIC_REVAMPED_TOOL} next"
  music_revamped_bind "${MUSIC_REVAMPED_S_prev_key}" "Previous track" run-shell "${MUSIC_REVAMPED_TOOL} prev"
}

music_revamped_replaced() {
  printf '%s\n' "$1" | MUSIC_REVAMPED_PUT="${MUSIC_REVAMPED_JOB}" awk -v mode="${MUSIC_REVAMPED_S_render}" '
    BEGIN {
      command = ENVIRON["MUSIC_REVAMPED_PUT"]
      split("music_icon music_status music_title music_artist music_progress music_time music", names, " ")
      split("icon status title artist progress time now", kinds, " ")
    }
    {
      line = $0
      for (i = 1; i <= 7; i++) {
        holder = "#{" names[i] "}"
        target = (mode == "options") ? "#{E:@music_revamped_out_" kinds[i] "}" : "#(" command " status " kinds[i] ")"
        done = ""
        while ((at = index(line, holder)) > 0) {
          done = done substr(line, 1, at - 1) target
          line = substr(line, at + length(holder))
        }
        line = done line
      }
      print line
    }
  '
}

music_revamped_used() {
  printf '%s\n' "$1" | awk '
    BEGIN {
      split("now icon status title artist progress time", kinds, " ")
      split("music music_icon music_status music_title music_artist music_progress music_time", names, " ")
    }
    { text = text $0 " " }
    END {
      out = ""
      for (i = 1; i <= 7; i++) {
        if (index(text, "#{" names[i] "}") > 0 || index(text, "@music_revamped_out_" kinds[i] "}") > 0 || index(text, " status " kinds[i] ")") > 0) { out = out (out == "" ? "" : " ") kinds[i] }
      }
      print out
    }
  '
}

music_revamped_plan_status() {
  music_revamped_plan_status_all=""
  for music_revamped_plan_status_option in status-left status-right; do
    music_revamped_plan_status_now=$(tmux show-option -gqv "${music_revamped_plan_status_option}" 2>/dev/null) || music_revamped_plan_status_now=""
    music_revamped_plan_status_all="${music_revamped_plan_status_all} ${music_revamped_plan_status_now}"
    case "${music_revamped_plan_status_now}" in
    *"#{music"*"}"*) music_revamped_plan_status_new=$(music_revamped_replaced "${music_revamped_plan_status_now}") ;;
    *) continue ;;
    esac
    [ "${music_revamped_plan_status_new}" != "${music_revamped_plan_status_now}" ] || continue
    music_revamped_emit set-option -gq "${music_revamped_plan_status_option}" "${music_revamped_plan_status_new}"
  done
  music_revamped_plan_status_used=$(music_revamped_used "${music_revamped_plan_status_all}")
  [ "${music_revamped_plan_status_used}" = "${MUSIC_REVAMPED_S_published}" ] || music_revamped_emit set-option -gq @music_revamped_published "${music_revamped_plan_status_used}"
  MUSIC_REVAMPED_S_published="${music_revamped_plan_status_used}"
}

music_revamped_plan() {
  music_revamped_load
  music_revamped_version
  MUSIC_REVAMPED_NOTES=0
  ! music_revamped_version_ge "${MUSIC_REVAMPED_TMUX}" "${MUSIC_REVAMPED_NOTES_SINCE}" || MUSIC_REVAMPED_NOTES=1
  music_revamped_tools
  MUSIC_REVAMPED_KEYS=$(music_revamped_held)
  MUSIC_REVAMPED_PLAN="" MUSIC_REVAMPED_SKIPPED="" MUSIC_REVAMPED_BOUND=""
  music_revamped_plan_keys
  music_revamped_plan_status
}

music_revamped_apply() {
  music_revamped_plan
  music_revamped_apply_status=0
  music_revamped_deliver || music_revamped_apply_status=1
  if [ "${MUSIC_REVAMPED_S_render}" = options ]; then
    revamped_ticker_start "${REVAMPED_LIB%/lib}/bin/music-revamped"
  else
    tmux set-option -gqu @music_revamped_ticker_pid 2>/dev/null || :
  fi
  return "${music_revamped_apply_status}"
}
