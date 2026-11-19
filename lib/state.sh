#!/bin/sh
# shellcheck disable=SC2034

[ -n "${MUSIC_REVAMPED_STATE_LOADED:-}" ] && return 0
MUSIC_REVAMPED_STATE_LOADED=1

MUSIC_REVAMPED_SETTINGS='menu_key	M-m
playpause_key
next_key
prev_key
interval	5
format	%s - %s
max_len	0
before
after
auto_hide	1
playing_icon	>
paused_icon	||
stopped_icon	[]
unknown_icon
progress_width	10
progress_full	█
progress_empty	░
time_format	%s/%s
render	jobs'
MUSIC_REVAMPED_NAMES='menu_key playpause_key next_key prev_key interval format max_len before after auto_hide playing_icon paused_icon stopped_icon unknown_icon progress_width progress_full progress_empty time_format render'
MUSIC_REVAMPED_CARRIED='interval format max_len before after auto_hide playing_icon paused_icon stopped_icon unknown_icon progress_width progress_full progress_empty time_format render'
MUSIC_REVAMPED_LIVE='status status_ts status_lock status_lock_ts title artist position duration published'
MUSIC_REVAMPED_S_menu_key='M-m'
MUSIC_REVAMPED_S_playpause_key=''
MUSIC_REVAMPED_S_next_key=''
MUSIC_REVAMPED_S_prev_key=''
MUSIC_REVAMPED_S_interval='5'
MUSIC_REVAMPED_S_format='%s - %s'
MUSIC_REVAMPED_S_max_len='0'
MUSIC_REVAMPED_S_before=''
MUSIC_REVAMPED_S_after=''
MUSIC_REVAMPED_S_auto_hide='1'
MUSIC_REVAMPED_S_playing_icon='>'
MUSIC_REVAMPED_S_paused_icon='||'
MUSIC_REVAMPED_S_stopped_icon='[]'
MUSIC_REVAMPED_S_unknown_icon=''
MUSIC_REVAMPED_S_progress_width='10'
MUSIC_REVAMPED_S_progress_full='█'
MUSIC_REVAMPED_S_progress_empty='░'
MUSIC_REVAMPED_S_time_format='%s/%s'
MUSIC_REVAMPED_S_render='jobs'
MUSIC_REVAMPED_S_status=''
MUSIC_REVAMPED_S_status_ts=''
MUSIC_REVAMPED_S_status_lock=''
MUSIC_REVAMPED_S_status_lock_ts=''
MUSIC_REVAMPED_S_title=''
MUSIC_REVAMPED_S_artist=''
MUSIC_REVAMPED_S_position=''
MUSIC_REVAMPED_S_duration=''
MUSIC_REVAMPED_S_published=''
MUSIC_REVAMPED_METRICS='now icon status title artist progress time'
MUSIC_REVAMPED_DEFAULT_MENU_KEY='M-m'
MUSIC_REVAMPED_DEFAULT_INTERVAL=5
MUSIC_REVAMPED_DEFAULT_WIDTH=10
MUSIC_REVAMPED_MAX_WIDTH=200
MUSIC_REVAMPED_MILLISECONDS_ABOVE=10000
MUSIC_REVAMPED_NOTES_SINCE=3.1
MUSIC_REVAMPED_EMPTY='music-revamped-empty-argument'
MUSIC_REVAMPED_TITLE='Music'
MUSIC_REVAMPED_TMUX=''
MUSIC_REVAMPED_NOTES=0
MUSIC_REVAMPED_TOOL=''
MUSIC_REVAMPED_JOB=''
MUSIC_REVAMPED_KEYS=''
MUSIC_REVAMPED_BOUND=''
MUSIC_REVAMPED_SKIPPED=''
MUSIC_REVAMPED_PLAN=''
MUSIC_REVAMPED_NOW=0
MUSIC_REVAMPED_LIMIT=5
MUSIC_REVAMPED_DOUBLED=''
MUSIC_REVAMPED_CUT=''
MUSIC_REVAMPED_SOURCE=''
MUSIC_REVAMPED_BACKEND=''
MUSIC_REVAMPED_PLAYER=''
MUSIC_REVAMPED_STORED=0
MUSIC_REVAMPED_BAR=''
MUSIC_REVAMPED_CLOCK=''
MUSIC_REVAMPED_WHOLE=0
REVAMPED_CACHE_PREFIX=music_revamped
REVAMPED_LOG_NS=music-revamped
MUSIC_REVAMPED_KINDS='interval	number
max_len	number
progress_width	number 0 200
auto_hide	1 0
render	jobs options'
