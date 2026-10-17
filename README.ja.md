<div align="center">

# tmux-music-revamped

<strong>再生中の曲をステータスバーに表示し、ステータスの描画を止めません。</strong>

[English](README.md) &nbsp;|&nbsp; 日本語 &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![Tests](https://github.com/tmux-revamped/tmux-music-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-music-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#what-it-does">機能</a> &nbsp;|&nbsp;
  <a href="#installation">インストール</a> &nbsp;|&nbsp;
  <a href="#usage">使い方</a> &nbsp;|&nbsp;
  <a href="#configuration">設定</a> &nbsp;|&nbsp;
  <a href="#key-bindings">キーバインド</a> &nbsp;|&nbsp;
  <a href="#how-it-works">仕組み</a>
</p>

</div>

**7** 個のプレースホルダー、**4** つのプレーヤーバックエンド、既定で割り当てるキーは **1** つ、tmux **3.2** 以降に対応します。

---

<a id="what-it-does"></a>

## 機能

再生中の曲、再生状態、プログレスバー、経過時間と全体の時間をステータスラインに表示します。プレーヤーへの問い合わせはバックグラウンドで行うため、ステータスラインはキャッシュされた値を読むだけで、プレーヤーを待つことはありません。キャッシュは tmux のオプションに保存され、一時ファイルは作りません。

`prefix + M-m` のメニューから、再生、一時停止、曲の送りと戻しができます。

| バックエンド | プラットフォーム | 読み取り | 操作 |
|:-------------|:-----------------|:--------:|:----:|
| `nowplaying-cli` | macOS | Yes | No |
| `playerctl` | Linux | Yes | Yes |
| `cmus-remote` | Linux と macOS | Yes | Yes |
| `osascript` 経由の Spotify | macOS | Yes | Yes |

<a id="requirements"></a>

## 動作要件

| 要件 | バージョン |
|:-----|:-----------|
| tmux | 3.2 以降 |
| bash | 3.2 以降 |
| プレーヤーのバックエンド | 上の表のいずれか |

Linux と macOS で、BSD、GNU、uutils のいずれの coreutils でも動作します。macOS では追加のパッケージなしで Spotify に対応し、`nowplaying-cli` を入れるとほかのすべてのプレーヤーに対応します。

<a id="installation"></a>

## インストール

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

<a id="usage"></a>

## 使い方

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

<a id="configuration"></a>

## 設定

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

<a id="key-bindings"></a>

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

<a id="how-it-works"></a>

## 仕組み

[`music-revamped.tmux`](music-revamped.tmux) は、`status-left` と `status-right` の各プレースホルダーを [`src/music.sh`](src/music.sh) の呼び出し、または `options` モードではオプションの読み取りに置き換えます。その後、キーを割り当てます。

スクリプトは、最初に見つかったバックエンドから読み取ります。順番は、macOS の `nowplaying-cli`、プレーヤーを報告した場合の `playerctl`、`cmus-remote`、macOS で `osascript` 経由の Spotify です。`playerctl` では再生中のプレーヤーがほかより優先され、操作も同じプレーヤーに対して行います。`nowplaying-cli` は読み取り専用なので、操作は `playerctl`、`cmus-remote`、Spotify の順に使います。

読み取った値は tmux のオプションに保存され、`@music_revamped_interval` 秒のあいだ再利用されます。値が古くなると切り離された更新を 1 つ起動し、その呼び出しはキャッシュの値を返します。`options` モードのバックグラウンドプロセスは、読み取りのあいだ同じ間隔だけ待機し、tmux サーバーが止まるか新しいプロセスが引き継ぐと終了します。

曲名とアーティストは、ステータスラインに届く前にすべての `#` が二重化されるため、曲名から tmux の書式を注入することはできません。

<a id="development"></a>

## 開発

| コマンド | 内容 |
|:---------|:-----|
| `make test` | bats のテストスイートを実行します |
| `make lint` | すべてのシェルファイルに shellcheck を実行します |
| `make coverage` | Linux で kcov を使って行カバレッジを測定し、95% 未満なら失敗します |

変更点は [CHANGELOG.md](CHANGELOG.md) にあります。

<a id="license"></a>

## ライセンス

[MIT](LICENSE)

<!-- family:begin -->

## tmux-revamped ファミリー

このプラグインは tmux-revamped ファミリーの一員です。すべてのメンバーが [`FAMILY.md`](FAMILY.md) の同じ規約、`family/` 配下の同じツール、同じ共有ライブラリを持ち、チェックサムの一覧によってバイト単位で同一に保たれています。メンバーは一緒にインストールする前提で作られており、ほかのメンバーが使うキーや tmux オプションを使うメンバーはありません。

あるメンバーで見つかった不具合は、修正完了とする前に全メンバーで同じ不具合を探します。この義務は記憶に頼らず規約に書かれており、`family/bin/sweep` がその作業を行います。

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
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revampedプラグインの出発点です。共有ライブラリ、batsハーネス、CI、ファミリーのツールを含みます |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | すべての状態をtmuxオプションに保持し、一時ファイルを使わない、tmuxステータスバーのポモドーロタイマーです |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM、スワップ、メモリプレッシャーをtmuxのステータスバーに表示します。計測はバックグラウンドで行うため描画を待たせません |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | tmuxのステータスバー上でウィンドウのタブをマウスでドラッグして、そのウィンドウを移動します |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 自分でスクロールできるアプリにはマウスホイールを渡し、それ以外ではtmuxのコピーモードに入ります |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | tmuxのバージョンと端末に合わせて適用され、ユーザーが設定したオプションには触れない、妥当な初期設定です |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmuxのタイル型ウィンドウ管理です。BSPのdwindleとspiralを含む8つのレイアウトと、レイアウトの取り消しがあります |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | ステータスバーにローカル時計と世界時計を時間帯ごとの色で表示し、カウントダウンと夏時間の警告も出します |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | wttr.inの天気をバックグラウンドで取得し、ステータスバーを待たせずに表示します |

### インストールの確認

全メンバーがディスク上にあれば、1 つのコマンドでメンバー間の衝突を報告できます。

```sh
family/bin/doctor --live
```

各メンバーと実行中の tmux サーバーを読み取り、重複したキー、重複したステータスのプレースホルダー、命名規則に合わないオプション、規約のバージョンが古いメンバーを報告します。

<!-- family:end -->
