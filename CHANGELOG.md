# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
