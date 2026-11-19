# Changelog

# [3.1.0](https://github.com/tmux-revamped/tmux-music-revamped/compare/v3.0.0...v3.1.0) (2026-11-19)


### Bug Fixes

* double the percent sign in a status job ([6a7ec98](https://github.com/tmux-revamped/tmux-music-revamped/commit/6a7ec98c19976950034d3fb3ad974df2245238b0))
* fold a table wider than the terminal ([cc17007](https://github.com/tmux-revamped/tmux-music-revamped/commit/cc170074cad50d8da38969c9fd42c63f58c622a2))
* read the grep of macOS as bsd in doctor ([5d7c39e](https://github.com/tmux-revamped/tmux-music-revamped/commit/5d7c39ef64e978e714f6dbd34d7c3335fc9554d4))
* stop a recording that hangs ([b71180b](https://github.com/tmux-revamped/tmux-music-revamped/commit/b71180b14765366b1f8ad2acedc00288f9ce4524))


### Features

* name unknown setting values in doctor ([138191d](https://github.com/tmux-revamped/tmux-music-revamped/commit/138191dad8a5306353f2976b3d7a67605bd7806e))

# [3.0.0](https://github.com/tmux-revamped/tmux-music-revamped/compare/v2.0.0...v3.0.0) (2026-11-18)


* feat!: rewrite the plugin in POSIX sh ([ad9453a](https://github.com/tmux-revamped/tmux-music-revamped/commit/ad9453a86f828872ee7608f7babafc0e261510fc))


### Bug Fixes

* **family:** fail when git cannot read a mode ([564ec95](https://github.com/tmux-revamped/tmux-music-revamped/commit/564ec954c9ef6f29775020d3577a70d8fe4ce8b7))
* **family:** honor only active exceptions ([e0cd638](https://github.com/tmux-revamped/tmux-music-revamped/commit/e0cd638357e206076316de8f65cf429eba701407))
* **family:** reject unquoted replacements ([945e752](https://github.com/tmux-revamped/tmux-music-revamped/commit/945e752ad91adbb99f0863a97395ebaa16aed668))
* **family:** require executable entry points ([c8f664e](https://github.com/tmux-revamped/tmux-music-revamped/commit/c8f664ef2342115a95590c10f407c28fdd22a1fd))
* say so when there is no player ([359a157](https://github.com/tmux-revamped/tmux-music-revamped/commit/359a157d9f330880286b8fc42b3059fab7a7621f))


### Features

* add a shared desktop notifier ([8bd45cd](https://github.com/tmux-revamped/tmux-music-revamped/commit/8bd45cd1a8cbfaf75724f341a214d65d84179a85))
* **family:** accept bot updates in the audit ([94c1503](https://github.com/tmux-revamped/tmux-music-revamped/commit/94c1503f7ffcabd9a833468bf4428ff26d8b69e7))


### BREAKING CHANGES

* the script moved from src/music.sh to
bin/music-revamped, so a status line or a binding that calls
src/music.sh by hand must call bin/music-revamped status NAME, where
NAME is now, icon, status, title, artist, progress or time, or the
matching command. The menu command is gone: the menu key opens the menu.
The stored title and artist no longer carry doubled hashes, and the
options that held the time of each cached value,
@music_revamped_title_ts, _artist_ts, _position_ts and _duration_ts, are
no longer written; @music_revamped_status_ts holds the time of the
reading. bash is no longer required. A tmux option set to nothing now
means its default, where it used to stay empty.

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- A control key or menu item did nothing, in silence, on a machine with no player
  to control. It now says so in a message.

## [2.0.0] - 2026-10-17

### Added

- `@music_revamped_render 'options'` replaces the `#()` calls with tmux option
  reads, written by one background process per server every
  `@music_revamped_interval` seconds, 5 by default,; a play, pause, next or previous key publishes at
  once.
- `@music_revamped_before` and `@music_revamped_after`, placed around
  `#{music}` only while a track is playing or paused, so a theme pill
  disappears when nothing plays.

### Changed

- **Breaking:** `prefix + M-m` opens a new playback menu with play / pause,
  next and previous, set by `@music_revamped_menu_key`. Play / pause `M-p`,
  next `M-n` and previous `M-b` are unbound by default; set
  `@music_revamped_playpause_key`, `@music_revamped_next_key` and
  `@music_revamped_prev_key` to bring them back.
- The options-mode background process reads every option it needs in one tmux
  call per tick, sends its cache writes and published values in a second, and
  keeps its functions out of the environment of the commands it runs. Options
  mode ticks every `@music_revamped_interval` seconds.

### Fixed

- In options mode, running the entry point a second time, as two overlapping
  config reloads do, found no placeholders left in the status line and
  published nothing, which froze every value. A metric whose option read is
  already on the status line now counts as used.
- A song title or artist containing `#` reached the status line unescaped, so
  track metadata could inject a tmux format, including a `#()` command. Title
  and artist now have every `#` doubled before they are cached, and truncation
  never splits a doubled pair.
- Switching `@music_revamped_render` from `options` back to jobs and reloading
  left the background ticker running forever, still publishing options nothing
  read. The entry point now releases the ticker in jobs mode, and the running
  ticker exits on its next tick.
- A plugin directory whose path held a space or a `'` broke every `#()` status
  call and the playback keys, because the path went into the shell command
  unquoted. The path is now shell-quoted, with any `#` doubled for tmux.
- The README documented `@music_revamped_enable_logging`, but no code path
  ever wrote a log, so setting it did nothing. The option is no longer
  documented.
- With several MPRIS players open, the playback keys went to playerctl's
  default player while the status line showed the playing one, so next could
  skip a track in a paused player. The keys now target the player the status
  line shows.
- With `nowplaying-cli`, a track playing at any speed other than exactly 1,
  such as a podcast at 1.5x, showed as paused. Any playback rate above zero
  now counts as playing.
- The README said `playerctl` is preferred everywhere and that the keys pick a
  player the same way as the readout. On macOS `nowplaying-cli` is read first,
  and it cannot send commands; the README now gives the real order for each.

## [1.3.0] - 2026-06-29

### Added

- Playback control: `play-pause`, `next`, and `prev` verbs on the dispatcher,
  wired to configurable prefix key bindings (`@music_revamped_playpause_key`,
  `@music_revamped_next_key`, `@music_revamped_prev_key`). Controls route to
  playerctl, cmus, or Spotify via AppleScript by feature-detection.
- When several players are present, reads now prefer the one that is actually
  playing instead of the first one listed.
- Auto-hide: the icon renders empty when nothing is playing, so the bar shows
  nothing instead of a lone stop glyph. Toggle with `@music_revamped_auto_hide`.

## [1.2.1] - 2026-06-23

### Changed

- Self-audit for the family hardening pass. Title, artist, playback state,
  elapsed time, and progress are all exposed, and the default colors are named
  colors safe under tmux 3.7 format expansion. No code change needed.

## [1.2.0] - 2026-06-20

### Added

- The macOS Spotify AppleScript backend now reads player position and track
  duration, so `#{music_progress}` and `#{music_time}` work without
  `nowplaying-cli`.

### Fixed

- Progress bar and elapsed time no longer render blank when Spotify is read via
  AppleScript. Spotify's millisecond duration is converted to seconds.

## [1.1.0] - 2026-06-20

### Added

- `nowplaying-cli` backend on macOS (works on Apple Silicon, reads any app) and a
  `cmus-remote` backend.
- Elapsed and total time with a progress bar: `#{music_progress}` and
  `#{music_time}`, sourced from the player position and duration.

## [1.0.0] - 2026-06-19

### Added

- Now-playing placeholders: `#{music}`, `#{music_icon}`, `#{music_status}`,
  `#{music_title}`, `#{music_artist}`.
- Non-blocking design: the player query runs in a background worker and values
  are read from tmux user-options, with no temp files.
- `playerctl` backend with an AppleScript Spotify fallback on macOS.
- Configurable format, truncation length, and status icons.
