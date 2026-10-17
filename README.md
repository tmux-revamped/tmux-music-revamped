<div align="center">

# tmux-music-revamped

<strong>Now playing in your tmux status bar, without ever blocking the status render.</strong>

English | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | [繁體中文（香港）](README.zh-HK.md)

[![Tests](https://github.com/tmux-revamped/tmux-music-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-music-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#what-it-does">What it does</a> |
  <a href="#installation">Installation</a> |
  <a href="#usage">Usage</a> |
  <a href="#configuration">Configuration</a> |
  <a href="#key-bindings">Key bindings</a> |
  <a href="#how-it-works">How it works</a>
</p>

</div>

**7** placeholders, **4** player backends, **1** key bound by default, tmux **3.2** or later.

---

## What it does

The plugin shows the current track, its play state, a progress bar and the elapsed and total time in the status line. A player is queried in the background, so the status line reads a cached value and never waits on the player. Cached values live in tmux options, and no temp file is written.

A menu on `prefix + M-m` plays, pauses and skips tracks.

| Backend | Platform | Reads | Controls |
|:--------|:---------|:-----:|:--------:|
| `nowplaying-cli` | macOS | Yes | No |
| `playerctl` | Linux | Yes | Yes |
| `cmus-remote` | Linux and macOS | Yes | Yes |
| Spotify through `osascript` | macOS | Yes | Yes |

## Requirements

| Requirement | Version |
|:------------|:--------|
| tmux | 3.2 or later |
| bash | 3.2 or later |
| A player backend | one from the table above |

It runs on Linux and macOS with BSD, GNU or uutils coreutils. On macOS, Spotify works with no extra package, and `nowplaying-cli` adds every other player.

## Installation

With [TPM](https://github.com/tmux-plugins/tpm), add the plugin to `~/.tmux.conf` and press `prefix + I`:

```tmux
set -g @plugin 'tmux-revamped/tmux-music-revamped'
```

To install by hand, clone the repository and run the entrypoint from `~/.tmux.conf`:

```bash
git clone https://github.com/tmux-revamped/tmux-music-revamped ~/.tmux/plugins/tmux-music-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-music-revamped/music-revamped.tmux
```

## Usage

Put placeholders in `status-left` or `status-right` before the plugin loads:

```tmux
set -g @music_revamped_max_len '25'
set -g status-left '#{music_icon} #{music} '
```

| Placeholder | Output |
|:------------|:-------|
| `#{music}` | Title and artist, such as `Song - Band` |
| `#{music_icon}` | An icon for playing, paused or stopped |
| `#{music_status}` | `playing`, `paused`, `stopped` or `unknown` |
| `#{music_title}` | Track title |
| `#{music_artist}` | Track artist |
| `#{music_progress}` | A bar of elapsed time against track length |
| `#{music_time}` | Elapsed and total time, such as `0:30/3:20` |

When no player is found, every placeholder renders empty. [`examples/status-left.tmux.conf`](examples/status-left.tmux.conf) holds a complete example.

## Configuration

### Display options

| Option | Default | Meaning |
|:-------|:--------|:--------|
| `@music_revamped_interval` | `5` | Seconds a reading stays fresh before the player is queried again |
| `@music_revamped_format` | `%s - %s` | `printf` format for title and artist in `#{music}` |
| `@music_revamped_max_len` | `0` | Cut title and artist in `#{music}` to this many characters and add `...`; `0` keeps them whole |
| `@music_revamped_before` | empty | Text placed before `#{music}` when there is a track to show |
| `@music_revamped_after` | empty | Text placed after `#{music}` when there is a track to show |
| `@music_revamped_auto_hide` | `1` | `1` hides the icon unless a track is playing or paused; `0` always shows it |
| `@music_revamped_playing_icon` | `>` | Icon while playing |
| `@music_revamped_paused_icon` | `\|\|` | Icon while paused |
| `@music_revamped_stopped_icon` | `[]` | Icon while stopped |
| `@music_revamped_unknown_icon` | empty | Icon when the state is unknown |
| `@music_revamped_progress_width` | `10` | Cells in the progress bar |
| `@music_revamped_progress_full` | U+2588, full block | Filled progress cell |
| `@music_revamped_progress_empty` | U+2591, light shade | Empty progress cell |
| `@music_revamped_time_format` | `%s/%s` | `printf` format for elapsed and total time |

### Key options

| Option | Default | Meaning |
|:-------|:--------|:--------|
| `@music_revamped_menu_key` | `M-m` | Prefix key that opens the playback menu; `off` unbinds it |
| `@music_revamped_playpause_key` | empty | Prefix key that toggles play and pause |
| `@music_revamped_next_key` | empty | Prefix key that skips to the next track |
| `@music_revamped_prev_key` | empty | Prefix key that goes back to the previous track |

### Render mode

| Option | Default | Meaning |
|:-------|:--------|:--------|
| `@music_revamped_render` | `jobs` | `jobs` turns each placeholder into a `#()` call; `options` turns it into a read of a tmux option |

In `jobs` mode, tmux runs the script on every status redraw. In `options` mode, each placeholder becomes a read such as `#{E:@music_revamped_out_title}`, and one background process per server writes every value the status line uses in a single tmux call. A control key publishes the new state at once.

```tmux
set -g @music_revamped_render 'options'
```

### Internal state

The plugin writes these options itself. Do not set them.

| Option | Holds |
|:-------|:------|
| `@music_revamped_published` | Space-separated metrics the status line uses, written at load so `options` mode publishes only those |
| `@music_revamped_out_<metric>` | The rendered value of each published metric in `options` mode |
| `@music_revamped_ticker_pid` | The process id of the background process that owns publishing |

## Key bindings

| Key | Action | Default |
|:----|:-------|:--------|
| `prefix + M-m` | Playback menu: `p` play or pause, `n` next, `b` previous | Bound |
| `@music_revamped_playpause_key` | Play or pause | Unbound |
| `@music_revamped_next_key` | Next track | Unbound |
| `@music_revamped_prev_key` | Previous track | Unbound |

To give each control its own key:

```tmux
set -g @music_revamped_playpause_key 'M-p'
set -g @music_revamped_next_key 'M-n'
set -g @music_revamped_prev_key 'M-b'
```

## How it works

[`music-revamped.tmux`](music-revamped.tmux) replaces each placeholder in `status-left` and `status-right` with a call to [`src/music.sh`](src/music.sh), or with an option read in `options` mode. It then binds the keys.

The script reads from the first backend present: `nowplaying-cli` on macOS, then `playerctl` when it reports a player, then `cmus-remote`, then Spotify through `osascript` on macOS. With `playerctl`, the player that is playing wins over the others, and the controls act on that same player. Controls go through `playerctl`, then `cmus-remote`, then Spotify, because `nowplaying-cli` only reads.

Readings are stored as tmux options and reused for `@music_revamped_interval` seconds. A stale reading starts one detached refresh and the current call returns the cached value. In `options` mode the background process sleeps for the same interval between readings and exits when the tmux server stops or a newer process takes over.

Titles and artists have every `#` doubled before they reach the status line, so a track name cannot inject a tmux format.

## Development

| Command | What it does |
|:--------|:-------------|
| `make test` | Runs the bats suite |
| `make lint` | Runs shellcheck on every shell file |
| `make coverage` | Measures line coverage with kcov on Linux and fails below 95% |

Changes are listed in [CHANGELOG.md](CHANGELOG.md).

## License

[MIT](LICENSE)

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
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | Pick a URL, path, hash or any other token off the screen with fzf and type it at the cursor, in pure shell |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | Switch to, kill, rename or create tmux sessions, windows and panes from fzf pickers in a popup |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | Show the active pane's git branch, changes and provider counts in the tmux status bar without blocking it |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | GPU load, temperature, clock, power and memory in the tmux status bar, from NVIDIA, AMD, Intel and Apple GPUs |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | Current Kubernetes context and namespace in the tmux status bar, parsed from kubeconfig without kubectl |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | Launch any TUI app in a popup or a window, scoped to the current pane's directory, with one configurable bindi |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | **this plugin**, Now playing in your tmux status bar, without ever blocking the status render |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | Network throughput in your tmux status bar, without ever blocking the render |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | Pane and window management bindings for tmux, version aware, vim friendly, every prefix key can be disabled |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | Save every tmux session, window and pane, auto-save on a timer, and restore it all after a reboot |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | The starting point for a tmux-revamped plugin: shared library, bats harness, CI and family tooling |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | A Pomodoro timer in the tmux status bar that keeps all of its state in tmux options, with no temp files |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM, swap and memory pressure in the tmux status bar, sampled in the background so the render never waits |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | Drag a window tab along the tmux status bar with the mouse to move that window |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | Send the mouse wheel to apps that scroll themselves and into tmux copy-mode everywhere else |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | Sensible tmux defaults, gated by tmux version and terminal, that leave the options you set alone |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | Tiling window management for tmux: eight layouts including BSP dwindle and spiral, with layout undo |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | Local and world clocks for the tmux status bar, colored by time of day, with countdowns and a DST warning |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | Weather for the tmux status bar from wttr.in, fetched in the background so the status line never waits |

### Checking an installation

With every member on disk, one command reports any conflict between them:

```sh
family/bin/doctor --live
```

It reads each member and the running tmux server, and reports duplicate keys,
duplicate status placeholders, options outside the naming grammar, and any
member whose contract version has fallen behind.

<!-- family:end -->
