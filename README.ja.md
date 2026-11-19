<div align="center">

# tmux-music-revamped

<strong>再生中の曲をステータスバーに表示し、ステータスの描画を止めません。</strong>

[English](README.md) &nbsp;|&nbsp; 日本語 &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-music-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-music-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-music-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-music-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-music-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-music-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-music-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#クイックスタート"><strong>クイックスタート</strong></a> &nbsp;|&nbsp;
  <a href="#使い方">使い方</a> &nbsp;|&nbsp;
  <a href="#仕組み">仕組み</a> &nbsp;|&nbsp;
  <a href="#画面">画面</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="ステータスラインに曲を表示し、メニューとキーで曲送りや一時停止を行い、長い名前を切り詰め、options 描画モードに切り替える music-revamped" width="800">
</p>

```console
$ music-revamped refresh
Refreshed. So What is playing.
$ music-revamped status now
So What - Miles Davis
```

**7** 個のプレースホルダー、**4** つのプレーヤーバックエンド、既定で割り当てるキーは **1** つ、tmux **3.2** 以降に対応します。

---

## クイックスタート

### 前提条件

| ツール | バージョン | 用途 |
|:-----|:--------|:---------|
| tmux | 3.2 以降 | ファミリー共通の最低バージョン |
| プレーヤー | 4 種類のいずれか | macOS の `nowplaying-cli`、`playerctl`、`cmus-remote`、または macOS で `osascript` 経由の Spotify |
| gum | 任意 | `music-revamped` のメニュー、表、色。なくてもすべてのコマンドがプレーンテキストで動きます |

### インストール

[TPM](https://github.com/tmux-plugins/tpm) を使う場合は、`~/.tmux.conf` にプラグインを追加して `prefix + I` を押します。

```tmux
set -g @plugin 'tmux-revamped/tmux-music-revamped'
```

手動でインストールする場合は、リポジトリをクローンし、`~/.tmux.conf` からエントリポイントを実行します。

```bash
git clone https://github.com/tmux-revamped/tmux-music-revamped ~/.tmux/plugins/tmux-music-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-music-revamped/music-revamped.tmux
```

クローンで `make install` を実行すると、`music-revamped` が `~/.local/bin` に、manページと補完が `~/.local/share` の下に入ります。

### 確認

```bash
~/.tmux/plugins/tmux-music-revamped/bin/music-revamped doctor
```

## 使い方

再生中の曲、再生状態、プログレスバー、経過時間と全体の時間をステータスラインに表示します。プレーヤーへの問い合わせはバックグラウンドで行うため、ステータスラインはキャッシュされた値を読むだけで、プレーヤーを待つことはありません。キャッシュは tmux のオプションに保存され、一時ファイルは作りません。

`prefix + M-m` のメニューから、再生、一時停止、曲の送りと戻しができます。

| バックエンド | プラットフォーム | 読み取り | 操作 |
|:-------------|:-----------------|:--------:|:----:|
| `nowplaying-cli` | macOS | Yes | No |
| `playerctl` | Linux | Yes | Yes |
| `cmus-remote` | Linux と macOS | Yes | Yes |
| `osascript` 経由の Spotify | macOS | Yes | Yes |

プラグインを読み込む前に、`status-left` または `status-right` にプレースホルダーを書きます。

```tmux
set -g @music_revamped_max_len '25'
set -g status-left '#{music_icon} #{music} '
```

| プレースホルダー | 出力 |
|:-----------------|:-----|
| `#{music}` | 曲名とアーティスト。例：`Song - Band` |
| `#{music_icon}` | 再生中、一時停止、停止を表すアイコン |
| `#{music_status}` | `playing`、`paused`、`stopped`、`unknown` のいずれか |
| `#{music_title}` | 曲名 |
| `#{music_artist}` | アーティスト |
| `#{music_progress}` | 曲の長さに対する経過時間のバー |
| `#{music_time}` | 経過時間と全体の時間。例：`0:30/3:20` |

プレーヤーが見つからないときは、すべてのプレースホルダーが空になります。完全な例は [`examples/status-left.tmux.conf`](examples/status-left.tmux.conf) にあります。

| コマンド | 動作 |
|:--------|:-------------|
| `music-revamped apply` | キーを割り当て、プレースホルダーを今すぐ置き換えます。プラグインの読み込み時にエントリーポイントが実行します |
| `music-revamped list` | `apply` が送るコマンドをすべて表示し、何も変更しません。`--json` で 1 つのオブジェクトを出力します |
| `music-revamped status NAME` | プレースホルダーを 1 つ出力します。`now`、`icon`、`status`、`title`、`artist`、`progress`、`time` のいずれかで、ステータスラインが実行します |
| `music-revamped refresh` | プレーヤーを今すぐ読み、再生中の内容を表示します |
| `music-revamped play-pause` | 再生または一時停止します |
| `music-revamped next` | 次の曲に進みます |
| `music-revamped prev` | 前の曲に戻ります |
| `music-revamped daemon` | `options` 描画モードのために、ティックごとにプレースホルダーを公開します。`apply` が起動します |
| `music-revamped doctor` | 依存関係ごとに 1 行。読み取るプレーヤー、操作するプレーヤー、触れなかったキーも含みます |
| `music-revamped version` | バージョンと tmux のバージョン |
| `music-revamped help` | ヘルプ。`man music-revamped` にも同じコマンドと設定があります |
| `music-revamped` | 端末ではメニュー |

## 設定

どのオプションも、ダッシュ区切りのコマンドオプション（例 `--max-len 25`）と環境変数（例 `MUSIC_REVAMPED_MAX_LEN`）で指定できます。優先順位はコマンドライン、環境変数、tmux オプションの順です。空の tmux オプションは既定値を意味します。`doctor` は、プラグインが認識できない値を持つ設定の名前を表示します。`apply` に渡したものは、すべての割り当て、メニュー項目、ステータスの呼び出しに引き継がれます。

### 表示のオプション

| オプション | 既定値 | 意味 |
|:-----------|:-------|:-----|
| `@music_revamped_interval` | `5` | プレーヤーに再び問い合わせるまで、読み取った値を新しいとみなす秒数 |
| `@music_revamped_format` | `%s - %s` | `#{music}` の曲名とアーティストの `printf` 形式 |
| `@music_revamped_max_len` | `0` | `#{music}` の曲名とアーティストをこの文字数で切り、`...` を付けます。`0` なら切りません |
| `@music_revamped_before` | 空 | 表示する曲があるときに `#{music}` の前に置く文字列 |
| `@music_revamped_after` | 空 | 表示する曲があるときに `#{music}` の後ろに置く文字列 |
| `@music_revamped_auto_hide` | `1` | `1` なら再生中か一時停止中以外はアイコンを隠します。`0` なら常に表示します |
| `@music_revamped_playing_icon` | `>` | 再生中のアイコン |
| `@music_revamped_paused_icon` | `\|\|` | 一時停止中のアイコン |
| `@music_revamped_stopped_icon` | `[]` | 停止中のアイコン |
| `@music_revamped_unknown_icon` | 空 | 状態が不明なときのアイコン |
| `@music_revamped_progress_width` | `10` | プログレスバーのマス数 |
| `@music_revamped_progress_full` | U+2588、塗りつぶしのブロック | 進んだ部分のマス |
| `@music_revamped_progress_empty` | U+2591、薄い網掛け | 残りの部分のマス |
| `@music_revamped_time_format` | `%s/%s` | 経過時間と全体の時間の `printf` 形式 |

### キーのオプション

| オプション | 既定値 | 意味 |
|:-----------|:-------|:-----|
| `@music_revamped_menu_key` | `M-m` | 再生メニューを開く prefix キー。`off` で割り当てを解除します |
| `@music_revamped_playpause_key` | 空 | 再生と一時停止を切り替える prefix キー |
| `@music_revamped_next_key` | 空 | 次の曲に進む prefix キー |
| `@music_revamped_prev_key` | 空 | 前の曲に戻る prefix キー |

### 描画モード

| オプション | 既定値 | 意味 |
|:-----------|:-------|:-----|
| `@music_revamped_render` | `jobs` | `jobs` は各プレースホルダーを `#()` の呼び出しに、`options` は tmux オプションの読み取りに置き換えます |

`jobs` モードでは、tmux はステータスを再描画するたびにスクリプトを実行します。`options` モードでは、各プレースホルダーが `#{E:@music_revamped_out_title}` のような読み取りになり、サーバーごとに 1 つのバックグラウンドプロセスが、ステータスラインで使うすべての値を 1 回の tmux 呼び出しで書き込みます。操作キーを押すと、新しい状態をすぐに反映します。

```tmux
set -g @music_revamped_render 'options'
```

### 内部状態

以下のオプションはプラグイン自身が書き込みます。設定しないでください。

| オプション | 保持する内容 |
|:-----------|:-------------|
| `@music_revamped_published` | ステータスラインで使う項目をスペースで区切った一覧。読み込み時に書き込み、`options` モードではこの項目だけを反映します |
| `@music_revamped_out_<metric>` | `options` モードで反映する各項目の描画結果 |
| `@music_revamped_ticker_pid` | 反映を担当するバックグラウンドプロセスのプロセス ID |

## キーバインド

| キー | 動作 | 既定 |
|:-----|:-----|:-----|
| `prefix + M-m` | 再生メニュー：`p` 再生または一時停止、`n` 次の曲、`b` 前の曲 | 割り当て済み |
| `@music_revamped_playpause_key` | 再生または一時停止 | 未割り当て |
| `@music_revamped_next_key` | 次の曲 | 未割り当て |
| `@music_revamped_prev_key` | 前の曲 | 未割り当て |

各操作に専用のキーを割り当てるには、次のように設定します。

```tmux
set -g @music_revamped_playpause_key 'M-p'
set -g @music_revamped_next_key 'M-n'
set -g @music_revamped_prev_key 'M-b'
```

<a id="仕組み"></a>

## 仕組み

[`music-revamped.tmux`](music-revamped.tmux) は、`status-left` と `status-right` の各プレースホルダーを [`bin/music-revamped`](bin/music-revamped) の呼び出し、または `options` モードではオプションの読み取りに置き換えます。その後、キーを割り当てます。

スクリプトは、最初に見つかったバックエンドから読み取ります。順番は、macOS の `nowplaying-cli`、プレーヤーを報告した場合の `playerctl`、`cmus-remote`、macOS で `osascript` 経由の Spotify です。`playerctl` では再生中のプレーヤーがほかより優先され、操作も同じプレーヤーに対して行います。`nowplaying-cli` は読み取り専用なので、操作は `playerctl`、`cmus-remote`、Spotify の順に使います。

読み取った値は tmux のオプションに保存され、`@music_revamped_interval` 秒のあいだ再利用されます。値が古くなると切り離された更新を 1 つ起動し、その呼び出しはキャッシュの値を返します。`options` モードのバックグラウンドプロセスは、読み取りのあいだ同じ間隔だけ待機し、tmux サーバーが止まるか新しいプロセスが引き継ぐと終了します。

曲名とアーティストは、ステータスラインに届く前にすべての `#` が二重化されるため、曲名から tmux の書式を注入することはできません。

<a id="画面"></a>

## 画面

<details>
<summary>すべての画面。本物の tmux の中で <code>make screens</code> で録画し、押したキーをステータスラインに表示しています</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/playing.png" alt="music-revamped: ステータスラインの曲、進捗、時間"><br><sub>ステータスラインの曲、進捗、時間。<code>hero.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/menu.png" alt="music-revamped: prefix M-m で再生メニューを開く"><br><sub><code>prefix M-m</code> で再生メニューを開く。<code>hero.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/next.png" alt="music-revamped: メニューの n で次の曲に進む"><br><sub>メニューの <code>n</code> で次の曲に進む。<code>hero.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/paused.png" alt="music-revamped: 再生と一時停止のキー prefix M-p で一時停止する"><br><sub>再生と一時停止のキー <code>prefix M-p</code> で一時停止する。<code>hero.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/previous.png" alt="music-revamped: 前の曲のキー prefix M-b で 1 曲戻る"><br><sub>前の曲のキー <code>prefix M-b</code> で 1 曲戻る。<code>hero.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/cut.png" alt="music-revamped: @music_revamped_max_len が曲名とアーティスト名を切り詰める"><br><sub><code>@music_revamped_max_len</code> が曲名とアーティスト名を切り詰める。<code>hero.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/options.png" alt="music-revamped: options 描画モードでは各プレースホルダーが tmux オプションを読む"><br><sub><code>options</code> 描画モードでは各プレースホルダーが tmux オプションを読む。<code>hero.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/options-next.png" alt="music-revamped: そのモードでは、次の曲のキー prefix M-n の結果がすぐに表示される"><br><sub>そのモードでは、次の曲のキー <code>prefix M-n</code> の結果がすぐに表示される。<code>hero.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/list.png" alt="music-revamped: list がすべての割り当てを表示する"><br><sub><code>list</code> がすべての割り当てを表示する。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/status.png" alt="music-revamped: status now が曲を出力する"><br><sub><code>status now</code> が曲を出力する。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="music-revamped: doctor"><br><sub><code>doctor</code>。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="music-revamped: gum なしのメニュー"><br><sub>gum なしのメニュー。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="music-revamped: メニューからの doctor"><br><sub>メニューからの <code>doctor</code>。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/version.png" alt="music-revamped: バージョン"><br><sub>バージョン。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/error.png" alt="music-revamped: 不明なコマンド"><br><sub>不明なコマンド。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/accent.png" alt="music-revamped: MUSIC_REVAMPED_ACCENT によるアクセント"><br><sub><code>MUSIC_REVAMPED_ACCENT</code> によるアクセント。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/themes.png" alt="music-revamped: 6 つのテーマのヘッダー"><br><sub>6 つのテーマのヘッダー。<code>themes.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/help.png" alt="music-revamped: ヘルプ"><br><sub>ヘルプ。<code>help.tape</code>より</sub></td>
</tr>
</table>

録画では本物のプラグインと tmux を動かしています。プレーヤーの代わりに小さなスクリプトを使い、キーは実際にそれを操作します。

</details>

## 移植性

プラグインは POSIX `sh` です。CI は下の各行ですべてのテストを実行します。

| シェル | 状態 |
|:------|:-------|
| `dash`、macOS の `/bin/sh` | 対応 |
| `bash` 3.2 と 5.x、システムの `zsh` と Homebrew の `zsh` | 対応 |

| システム | 状態 |
|:-------|:-------|
| macOS | Apple Silicon と Intel の Tahoe。付属のツール、Homebrew の GNU ツール、Homebrew の uutils で確認 |
| Linux | x86_64 と arm64 の Ubuntu 26.04。GNU coreutils、uutils、BusyBox で確認 |

## 開発

| コマンド | 実行内容 |
|:--------|:-------------|
| `make fmt` | すべてのスクリプトに shfmt `-i 2` をかけます |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint、actionlint を、指摘ゼロで通します |
| `make test` | システムの `sh` で bats のテスト |
| `make test-all` | インストール済みのすべてのシェルでテスト。macOS では bash と zsh の両方のビルドを含みます |
| `make test-linux` | Ubuntu のコンテナでテスト |
| `make coverage` | この Mac と Ubuntu のコンテナで bashcov を実行し、合算して 100 パーセントで判定します |
| `make screens` | 上の画面を、本物のプラグインから tmux の中で VHS で録画します。macOS で実行します |
| `make install` | コマンド、manページ、補完を `PREFIX` の下に置きます |

macOS では、`brew bundle` を実行すると、これらのターゲットが使うツールがすべて [`Brewfile`](Brewfile) からインストールされます。

コミットは Conventional Commits の形式に従い、そのまま `main` に入ります。`main` で `ci` が成功すると、`release.yml` が semantic-release を実行します。前回のタグ以降に `feat` か `fix` があればリリースを公開し、バージョン定数を更新し、変更内容を [`CHANGELOG.md`](CHANGELOG.md) に追加します。

## ライセンス

[MIT](LICENSE)、copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped ファミリー

このプラグインは tmux-revamped ファミリーの一員です。すべてのメンバーが [`FAMILY.md`](FAMILY.md) の同じ規約と同じ共有ライブラリを持ちます。メンバーは一緒にインストールする前提で作られており、ほかのメンバーが使うキーや tmux オプションを使うメンバーはありません。

あるメンバーで見つかった不具合は、修正完了とする前に全メンバーで同じ不具合を探します。

| メンバー | 機能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | tmuxの設定を編集して保存するだけで、キーもコマンドも使わずに自動で再読み込みされます |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | tmuxのステータスバーに電池の状態を表示し、ステータスの描画を一切止めません |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 接続中のすべてのBluetooth機器とその電池残量をtmuxのステータスバーに表示し、描画を止めません |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | CPUの負荷、温度、周波数をtmuxのステータスバーに表示し、描画を一切止めません |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | tmuxのステータスバーにディスク使用量を表示し、ステータスの描画を一切止めません |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 画面上の URL、パス、ハッシュなどのトークンを fzf で選び、カーソル位置に入力します。純粋なシェルだけで動きます |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | ポップアップ内の fzf ピッカーから、tmux のセッション、ウィンドウ、ペインの切り替え、終了、名前変更、作成を行います |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | アクティブなペインのgitブランチ、変更、プロバイダーの件数を、描画を止めずにtmuxのステータスバーに表示します |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | NVIDIA、AMD、Intel、Apple の GPU の負荷、温度、クロック、電力、メモリを tmux のステータスバーに表示します |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 現在の Kubernetes コンテキストと名前空間を、kubectl を使わずに kubeconfig から解析して tmux のステータスバーに表示します |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 任意の TUI アプリを、現在のペインのディレクトリでポップアップまたはウィンドウとして起動します。アプリごとにキーを設定できます |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 任意のペインをファイルに保存します。ライブのログ記録、スクロールバック全体、1 回限りのスクリーンショットに対応します |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | **このプラグイン**、再生中の曲をステータスバーに表示し、ステータスの描画を止めません |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | ネットワークのスループットをステータスバーに表示し、描画を止めません |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux のペインとウィンドウの操作キー。tmux のバージョンに対応し、vim と共存でき、どの prefix キーも無効にできます |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | tmuxのすべてのセッション、ウィンドウ、ペインを保存し、タイマーで自動保存して、再起動後にすべて復元します |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revampedプラグインの出発点です。共有ライブラリ、batsハーネス、CIを含みます |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | すべての状態をtmuxオプションに保持し、一時ファイルを使わない、tmuxステータスバーのポモドーロタイマーです |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM、スワップ、メモリプレッシャーをtmuxのステータスバーに表示します。計測はバックグラウンドで行うため描画を待たせません |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | tmuxのステータスバー上でウィンドウのタブをマウスでドラッグして、そのウィンドウを移動します |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 自分でスクロールできるアプリにはマウスホイールを渡し、それ以外ではtmuxのコピーモードに入ります |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | tmuxのバージョンと端末に合わせて適用され、ユーザーが設定したオプションには触れない、妥当な初期設定です |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmuxのタイル型ウィンドウ管理です。BSPのdwindleとspiralを含む8つのレイアウトと、レイアウトの取り消しがあります |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | ステータスバーにローカル時計と世界時計を時間帯ごとの色で表示し、カウントダウンと夏時間の警告も出します |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | wttr.inの天気をバックグラウンドで取得し、ステータスバーを待たせずに表示します |

<!-- family:end -->
