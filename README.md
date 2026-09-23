<div align="center">

<h1>tmux-music-revamped</h1>

**Now playing in your tmux status bar, without ever blocking the status render.**

[![Tests](https://github.com/tmux-revamped/tmux-music-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-music-revamped/actions/workflows/tests.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![Version](https://img.shields.io/badge/version-1.3.0-blue.svg)](CHANGELOG.md)

</div>

**7** placeholders · **4** backends · **126** tests · **95%+** coverage

Show the current track, a progress bar, and elapsed and total time across multiple media backends. Players are queried in a detached background worker, so the status line reads a cached value and returns instantly with no temp files.

Built from
[tmux-plugin-template](https://github.com/tmux-revamped/tmux-plugin-template).

<table>
<tr>
<td><b>Non-blocking</b><br/>The status line reads a cached tmux user-option and never waits on a player probe.</td>
<td><b>No temp files</b><br/>Cached values live in tmux server options, so nothing is written to disk.</td>
</tr>
<tr>
<td><b>Multiple players</b><br/>nowplaying-cli on macOS, playerctl and cmus on Linux, plus Spotify via AppleScript.</td>
<td><b>Tested</b><br/>126 bats tests hold coverage at 95%+ across the shell sources.</td>
</tr>
</table>

## Placeholders

| Placeholder | Output |
|-------------|--------|
| `#{music}` | the current track, for example `Song - Band` |
| `#{music_icon}` | a play, pause, or stop icon |
| `#{music_status}` | `playing`, `paused`, `stopped`, or `unknown` |
| `#{music_title}` | the track title |
| `#{music_artist}` | the track artist |
| `#{music_progress}` | a progress bar from elapsed and total time |
| `#{music_time}` | elapsed and total time, for example `0:30/3:20` |

## Install

With [TPM](https://github.com/tmux-plugins/tpm):

```tmux
set -g @plugin 'tmux-revamped/tmux-music-revamped'
set -g status-left '#{music_icon} #{music}'
```

Press `prefix + I` to install.

## Configuration

| Option | Default | Meaning |
|--------|---------|---------|
| `@music_revamped_interval` | `5` | seconds a reading stays fresh |
| `@music_revamped_format` | `%s - %s` | format for title and artist |
| `@music_revamped_max_len` | `0` | truncate title and artist to this length, `0` disables |
| `@music_revamped_playing_icon` | `>` | icon while playing |
| `@music_revamped_paused_icon` | `\|\|` | icon while paused |
| `@music_revamped_stopped_icon` | `[]` | icon while stopped |
| `@music_revamped_unknown_icon` | empty | icon when no player is found |
| `@music_revamped_progress_width` | `10` | cells in the progress bar |
| `@music_revamped_progress_full` | `█` | filled progress cell |
| `@music_revamped_progress_empty` | `░` | empty progress cell |
| `@music_revamped_time_format` | `%s/%s` | format for elapsed and total time |
| `@music_revamped_auto_hide` | `1` | set to `0` to keep showing the stop icon when nothing plays |
| `@music_revamped_playpause_key` | `M-p` | prefix key that toggles play/pause |
| `@music_revamped_next_key` | `M-n` | prefix key that skips to the next track |
| `@music_revamped_prev_key` | `M-b` | prefix key that skips to the previous track |
| `@music_revamped_enable_logging` | `0` | set to `1` to log under `~/.tmux/music-revamped-logs` |

## Support by platform and architecture

| Platform | Supported |
|----------|-----------|
| Linux (x86_64 and arm64) | yes, with `playerctl` installed |
| macOS (Intel and Apple Silicon) | yes, Spotify via built-in AppleScript, or any player when `playerctl` is installed |

`playerctl` is preferred wherever it is present. On macOS without `playerctl`,
Spotify is read through AppleScript with no extra package, including the player
position and track duration, so the progress bar and elapsed time work on that
path too. When no player is active the placeholders render empty.

## Controls

Three prefix key bindings control playback through whichever player is active,
chosen the same way as the now-playing readout: playerctl, cmus, or Spotify via
AppleScript.

| Key | Action |
|-----|--------|
| `prefix + M-p` | play / pause |
| `prefix + M-n` | next track |
| `prefix + M-b` | previous track |

Rebind any of them, for example:

```tmux
set -g @music_revamped_playpause_key 'C-Space'
```

When several players run at once, every reading and control targets the one that
is actually playing.

## Development

Run the tests, lint, and coverage:

```sh
make test
make lint
make coverage
```

## License

[MIT](LICENSE), copyright Gustavo Franco.

<!-- family:begin -->

## The tmux-revamped family

This plugin is one member of the tmux-revamped family. Every member carries the
same contract in [`FAMILY.md`](FAMILY.md), the same tooling under `family/`, and
the same shared library, all held byte-identical by a checksum manifest. They are
built to be installed together: no member claims a key or a tmux option that
another member claims.

A defect found in one member is hunted across all of them before the fix is
called done. That obligation is written into the contract rather than left to
memory, and `family/bin/sweep` is how it is discharged.

| Member | What it does |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | Edit your tmux config, save, and watch it reload itself, no key, no command |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | Battery status for your tmux status bar, without ever blocking the status render |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | Every connected Bluetooth device and its battery in your tmux status bar, without blocking the render |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | CPU load, temperature, and frequency in your tmux status bar, without ever blocking the render |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | Disk usage for your tmux status bar, without ever blocking the status render |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | Fuzzy-grab any URL, path, or word off the screen and paste it, pure shell, no Python |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | Jump to any session, window, or pane, or kill it, from one fzf popup |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | Git repository status in your tmux status bar, without ever blocking the render |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | GPU load, temperature, frequency, and memory for your tmux status bar |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | Current Kubernetes context and namespace in your tmux status bar, async, kubectl-free, never blocking |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | Launch any TUI app in a popup or a window, scoped to the current pane's directory, with one configurable bindi |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | **this plugin**, Now playing in your tmux status bar, without ever blocking the status render |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | Network throughput in your tmux status bar, without ever blocking the render |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | Standard pane and window management bindings for tmux, version aware, vim friendly, and fully configurable |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | One plugin that captures every session, window, pane, layout, and working |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | A template for building non-blocking tmux status plugins |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | A Pomodoro timer in your tmux status bar, with zero temp files: all state lives in tmux options |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM usage for your tmux status bar, without ever blocking the status render |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | Mouse wheel that does the right thing: scroll the app directly, copy-mode everywhere else. No app names to con |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | Sensible tmux defaults that normalize behavior across every tmux version, OS, and terminal, without clobbering |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | --- |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | Local clock and world clocks in your tmux status bar, without ever blocking the render |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | Weather in your tmux status bar, fetched in the background so the render never waits on the network |

### Checking an installation

With every member on disk, one command reports any conflict between them:

```sh
family/bin/doctor --live
```

It reads each member and the running tmux server, and reports duplicate keys,
duplicate status placeholders, options outside the naming grammar, and any
member whose contract version has fallen behind.

<!-- family:end -->
