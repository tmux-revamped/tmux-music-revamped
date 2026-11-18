# tmux-music-revamped

Guidance for anyone, human or agent, changing tmux-music-revamped. What it is and how to use it lives in [README.md](README.md).

[FAMILY.md](FAMILY.md) holds everything this plugin shares with the rest of the tmux-revamped family, and it is the same in every member. This file holds only what is exclusive to tmux-music-revamped, under the same headings as the agent guide of every member. Read both before changing anything; a rule that would serve the other members goes into [`FAMILY.md`](FAMILY.md) instead of here.

## Layout

| Path | Holds |
|:-----|:------|
| [`music-revamped.tmux`](music-revamped.tmux) | The entry point TPM runs: it runs `bin/music-revamped apply` |
| [`bin/music-revamped`](bin/music-revamped) | The command: `apply`, `list`, `status`, `refresh`, `play-pause`, `next`, `prev`, `daemon`, `doctor`, `version`, `help` and the menu. `apply`, `status`, `refresh`, the controls and `daemon` run without loading the interface modules |
| [`lib/music.sh`](lib/music.sh) | Reading the settings and the stored reading, the four player readers, the refresh, the placeholders, the publisher's tick, the controls and the bindings |
| [`lib/state.sh`](lib/state.sh) | Every global, including `MUSIC_REVAMPED_SETTINGS`, the table of setting names and defaults, and `MUSIC_REVAMPED_LIVE`, the names of the options that hold the reading |
| [`lib/core.sh`](lib/core.sh) | The version |
| [`lib/`](lib) | Every other file is the shared library, identical in every member |
| [`test/readers.bats`](test/readers.bats), [`test/music.bats`](test/music.bats), [`test/plan.bats`](test/plan.bats), [`test/commands.bats`](test/commands.bats) | The readers, the placeholders with staleness and the tick, the bindings with both render modes, the daemon and the controls, and every command, against a stand-in tmux from [`test/music_helpers.bash`](test/music_helpers.bash) that keeps options in a file, with stand-ins for the four players and the shared `uname` stand-in to choose the system |
| [`test/entrypoint.bats`](test/entrypoint.bats), [`test/keys.bats`](test/keys.bats) | The plugin on a private tmux server, with the menu, each of its items and each control key pressed through a second tmux attached to it, in both render modes; both share [`test/server_helpers.bash`](test/server_helpers.bash), whose `cmus-remote` stand-in keeps a state the keys change |
| [`screens/`](screens) | The tapes and the recording's tmux config. `prepare.sh` copies the plugin to a neutral folder and writes stand-ins for `cmus-remote` and `nowplaying-cli` over one small playlist |
| [`examples/`](examples) | A status line to copy |

## Names

- Settings are the tmux options `@music_revamped_<setting>` listed in `MUSIC_REVAMPED_SETTINGS`, the long options with dashes, such as `--max-len`, and the environment variables `MUSIC_REVAMPED_<SETTING>`.
- The stored reading is `@music_revamped_status`, `_status_ts`, `_status_lock`, `_status_lock_ts`, `_title`, `_artist`, `_position` and `_duration`. `apply` writes `@music_revamped_published`, the daemon `@music_revamped_out_<name>` and `@music_revamped_ticker_pid`. None of them is a setting.
- The placeholders are `#{music}`, `#{music_icon}`, `#{music_status}`, `#{music_title}`, `#{music_artist}`, `#{music_progress}` and `#{music_time}`; `status` names them `now`, `icon`, `status`, `title`, `artist`, `progress` and `time`.
- The version constant is `MUSIC_REVAMPED_VERSION`.
- The command's own functions and the library's never share a name, because the command is sourced after the library and would replace it.

## Behaviour

- `apply` reads every setting and the stored reading with one `tmux display-message` call and one `env` read, reads the prefix table once, and sends every binding and the replaced status strings in one tmux call. When that call fails, it sends each command alone, so one invalid key leaves the others bound and `apply` exits 1.
- In `jobs` mode each placeholder in `status-left` or `status-right` becomes `#(<tool> status <name>)`, with the tool's path quoted for a shell and every `#` doubled. In `options` mode it becomes `#{E:@music_revamped_out_<name>}`, `apply` starts the daemon, and a status refresh starts no process. A string already rewritten is not written again, and the names it uses stay in `@music_revamped_published`, so loading twice changes nothing.
- `status` makes one tmux read and one `date` call, and prints the stored reading at once. Only when that reading is older than `@music_revamped_interval`, and no reading is under way, does it start one in the background through the shared cache module.
- The daemon is the shared ticker: it claims `@music_revamped_ticker_pid`, reads the player and publishes every name in `@music_revamped_published` in one tmux call per tick, sleeps for the interval, and ends when another process holds the claim or the server is gone. At the ticker's tick cap it starts itself again.
- `M-m` opens the playback menu, bound to `display-menu` itself, with `p`, `n` and `b` on its items; the three control keys are opt-in. A key set to `off` binds nothing. Only the default key is skipped when someone else holds it, and `doctor` names it; a key the person names is bound whoever holds it.
- A control with no player says so in a tmux message and exits 0, since a `run-shell` that fails or prints opens tmux's own output screen. In `options` mode a control publishes the new reading at once.
- A setting `apply` got from the command line or the environment rides, as an option, on every binding, every menu item and every status call; `MUSIC_REVAMPED_CARRIED` lists the ones that ride. The daemon inherits the environment of the `apply` that started it.

## Domain rules

- The first source present is read: `nowplaying-cli` on macOS, `playerctl` when it reports a status, `cmus-remote`, then Spotify through `osascript` on macOS. With `playerctl`, the first player that is playing wins, else the first listed, and the controls act on that same player. Controls go through `playerctl`, then `cmus-remote`, then Spotify, because `nowplaying-cli` only reads.
- Each reader prints five lines: status, title, artist, position and duration in whole seconds. A reading with no title is no reading. A Spotify duration above 10000 is in milliseconds.
- The status is stored as `playing`, `paused`, `stopped` or `unknown`. The title and the artist are stored as read; tmux expands formats in a job's output and in an option read with `E:`, so each `#` in them is doubled when a placeholder prints them.
- A title or an artist is cut by characters, never bytes, with the shared publisher's byte class, and the cut text ends in three dots.
- The progress bar is capped at 200 cells, so a setting cannot make a refresh loop without bound. A number read from an option has its leading zeros dropped, since the shell would read `08` as octal.
- An argument that ends in `;` is sent as `\;`: tmux reads a bare trailing semicolon in an argument as a command separator. The command list keeps an empty argument as the marker in `MUSIC_REVAMPED_EMPTY`; only an empty line ends a command.

## Release

- `MUSIC_REVAMPED_VERSION` in [`lib/core.sh`](lib/core.sh) holds the version. Nobody edits it by hand.
- After a green `ci` run on `main`, [`release.yml`](.github/workflows/release.yml) runs semantic-release: a `feat` or `fix` since the last tag publishes a release, [`set-version.sh`](.github/scripts/set-version.sh) stamps the constant, and the notes go into [`CHANGELOG.md`](CHANGELOG.md).

## Gaps against FAMILY.md

As of 2026-11-17, none.
