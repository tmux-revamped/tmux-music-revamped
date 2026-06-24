# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
