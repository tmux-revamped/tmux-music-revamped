<div align="center">

# tmux-music-revamped

<strong>在 tmux 狀態列顯示正在播放的歌曲，從不阻塞狀態列的繪製。</strong>

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | 繁體中文（香港）

[![Tests](https://github.com/tmux-revamped/tmux-music-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-music-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#what-it-does">功能</a> |
  <a href="#installation">安裝</a> |
  <a href="#usage">用法</a> |
  <a href="#configuration">設定</a> |
  <a href="#key-bindings">按鍵綁定</a> |
  <a href="#how-it-works">運作原理</a>
</p>

</div>

**7** 個佔位符，**4** 種播放器後端，預設只綁定 **1** 個按鍵，支援 tmux **3.2** 或以上版本。

---

<a id="what-it-does"></a>

## 功能

插件在狀態列顯示目前歌曲、播放狀態、進度列，以及已播放時間和總長度。播放器在背景查詢，所以狀態列只讀取快取的值，從不等待播放器。快取值存放在 tmux 選項中，不會寫入任何暫存檔。

`prefix + M-m` 開啟的選單可以播放、暫停和切換歌曲。

| 後端 | 平台 | 讀取 | 控制 |
|:-----|:-----|:----:|:----:|
| `nowplaying-cli` | macOS | Yes | No |
| `playerctl` | Linux | Yes | Yes |
| `cmus-remote` | Linux 和 macOS | Yes | Yes |
| 透過 `osascript` 控制的 Spotify | macOS | Yes | Yes |

<a id="requirements"></a>

## 系統要求

| 要求 | 版本 |
|:-----|:-----|
| tmux | 3.2 或以上 |
| bash | 3.2 或以上 |
| 播放器後端 | 上表中任何一個 |

可在 Linux 和 macOS 上執行，支援 BSD、GNU 或 uutils coreutils。在 macOS 上，Spotify 毋須額外套件，安裝 `nowplaying-cli` 後可支援其他所有播放器。

<a id="installation"></a>

## 安裝

使用 [TPM](https://github.com/tmux-plugins/tpm) 時，將插件加入 `~/.tmux.conf`，然後按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-music-revamped'
```

手動安裝時，複製儲存庫，並在 `~/.tmux.conf` 中執行入口腳本：

```bash
git clone https://github.com/tmux-revamped/tmux-music-revamped ~/.tmux/plugins/tmux-music-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-music-revamped/music-revamped.tmux
```

<a id="usage"></a>

## 用法

在插件載入之前，將佔位符寫進 `status-left` 或 `status-right`：

```tmux
set -g @music_revamped_max_len '25'
set -g status-left '#{music_icon} #{music} '
```

| 佔位符 | 輸出 |
|:-------|:-----|
| `#{music}` | 歌名和歌手，例如 `Song - Band` |
| `#{music_icon}` | 代表播放、暫停或停止的圖示 |
| `#{music_status}` | `playing`、`paused`、`stopped` 或 `unknown` |
| `#{music_title}` | 歌名 |
| `#{music_artist}` | 歌手 |
| `#{music_progress}` | 已播放時間相對歌曲長度的進度列 |
| `#{music_time}` | 已播放時間和總長度，例如 `0:30/3:20` |

找不到播放器時，所有佔位符都顯示為空。完整例子見 [`examples/status-left.tmux.conf`](examples/status-left.tmux.conf)。

<a id="configuration"></a>

## 設定

### 顯示選項

| 選項 | 預設值 | 意思 |
|:-----|:-------|:-----|
| `@music_revamped_interval` | `5` | 讀取結果保持有效的秒數，過期後重新查詢播放器 |
| `@music_revamped_format` | `%s - %s` | `#{music}` 中歌名和歌手的 `printf` 格式 |
| `@music_revamped_max_len` | `0` | 將 `#{music}` 中的歌名和歌手截短至此字元數並加上 `...`；`0` 表示不截短 |
| `@music_revamped_before` | 空 | 有歌曲可顯示時放在 `#{music}` 前面的文字 |
| `@music_revamped_after` | 空 | 有歌曲可顯示時放在 `#{music}` 後面的文字 |
| `@music_revamped_auto_hide` | `1` | `1` 表示除播放或暫停外隱藏圖示；`0` 表示一直顯示 |
| `@music_revamped_playing_icon` | `>` | 播放時的圖示 |
| `@music_revamped_paused_icon` | `\|\|` | 暫停時的圖示 |
| `@music_revamped_stopped_icon` | `[]` | 停止時的圖示 |
| `@music_revamped_unknown_icon` | 空 | 狀態不明時的圖示 |
| `@music_revamped_progress_width` | `10` | 進度列的格數 |
| `@music_revamped_progress_full` | U+2588，實心方塊 | 已播放部分的格子 |
| `@music_revamped_progress_empty` | U+2591，淺色陰影 | 未播放部分的格子 |
| `@music_revamped_time_format` | `%s/%s` | 已播放時間和總長度的 `printf` 格式 |

### 按鍵選項

| 選項 | 預設值 | 意思 |
|:-----|:-------|:-----|
| `@music_revamped_menu_key` | `M-m` | 開啟播放選單的 prefix 按鍵；設為 `off` 即取消綁定 |
| `@music_revamped_playpause_key` | 空 | 切換播放和暫停的 prefix 按鍵 |
| `@music_revamped_next_key` | 空 | 跳到下一首的 prefix 按鍵 |
| `@music_revamped_prev_key` | 空 | 返回上一首的 prefix 按鍵 |

### 繪製模式

| 選項 | 預設值 | 意思 |
|:-----|:-------|:-----|
| `@music_revamped_render` | `jobs` | `jobs` 將每個佔位符變成 `#()` 呼叫；`options` 將它變成讀取 tmux 選項 |

在 `jobs` 模式下，tmux 每次重繪狀態列都會執行腳本。在 `options` 模式下，每個佔位符變成 `#{E:@music_revamped_out_title}` 這類讀取，每部伺服器只有一個背景程序，以一次 tmux 呼叫寫入狀態列用到的所有值。按下控制鍵會即時發佈新狀態。

```tmux
set -g @music_revamped_render 'options'
```

### 內部狀態

以下選項由插件自行寫入，請勿設定。

| 選項 | 存放內容 |
|:-----|:---------|
| `@music_revamped_published` | 狀態列用到的指標，以空格分隔，載入時寫入，`options` 模式只發佈這些指標 |
| `@music_revamped_out_<metric>` | `options` 模式下每個已發佈指標的繪製結果 |
| `@music_revamped_ticker_pid` | 負責發佈的背景程序的程序 ID |

<a id="key-bindings"></a>

## 按鍵綁定

| 按鍵 | 動作 | 預設 |
|:-----|:-----|:-----|
| `prefix + M-m` | 播放選單：`p` 播放或暫停，`n` 下一首，`b` 上一首 | 已綁定 |
| `@music_revamped_playpause_key` | 播放或暫停 | 未綁定 |
| `@music_revamped_next_key` | 下一首 | 未綁定 |
| `@music_revamped_prev_key` | 上一首 | 未綁定 |

為每個控制指定專用按鍵：

```tmux
set -g @music_revamped_playpause_key 'M-p'
set -g @music_revamped_next_key 'M-n'
set -g @music_revamped_prev_key 'M-b'
```

<a id="how-it-works"></a>

## 運作原理

[`music-revamped.tmux`](music-revamped.tmux) 將 `status-left` 和 `status-right` 中的每個佔位符換成對 [`src/music.sh`](src/music.sh) 的呼叫，在 `options` 模式下則換成選項讀取，然後綁定按鍵。

腳本從第一個可用的後端讀取：先是 macOS 上的 `nowplaying-cli`，然後是有回報播放器的 `playerctl`，再是 `cmus-remote`，最後是 macOS 上透過 `osascript` 控制的 Spotify。使用 `playerctl` 時，正在播放的播放器優先於其他播放器，控制操作亦作用於同一個播放器。由於 `nowplaying-cli` 只能讀取，控制依次使用 `playerctl`、`cmus-remote` 和 Spotify。

讀取結果存放為 tmux 選項，並在 `@music_revamped_interval` 秒內重複使用。結果過期時會啟動一次獨立的更新，目前的呼叫則傳回快取的值。在 `options` 模式下，背景程序在兩次讀取之間等候同樣的間隔，並在 tmux 伺服器停止或有較新的程序接手時結束。

歌名和歌手中的每個 `#` 在到達狀態列之前都會加倍，所以歌曲名稱無法注入 tmux 格式。

<a id="development"></a>

## 開發

| 指令 | 作用 |
|:-----|:-----|
| `make test` | 執行 bats 測試套件 |
| `make lint` | 對所有 shell 檔案執行 shellcheck |
| `make coverage` | 在 Linux 上用 kcov 量度行覆蓋率，低於 95% 時失敗 |

變更紀錄見 [CHANGELOG.md](CHANGELOG.md)。

<a id="license"></a>

## 授權

[MIT](LICENSE)

<!-- family:begin -->

## tmux-revamped 插件家族

本插件是 tmux-revamped 插件家族的成員。每個成員都帶有 [`FAMILY.md`](FAMILY.md) 中的同一份約定、`family/` 下的同一套工具和同一個共用程式庫，並由校驗和清單確保逐位元組一致。這些成員可以一併安裝：任何成員都不會佔用其他成員使用的按鍵或 tmux 選項。

在一個成員中發現的缺陷，要在全部成員中排查後才算修正完成。這項責任寫在約定之中，而不是依靠記憶，`family/bin/sweep` 負責執行。

| 成員 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 編輯並儲存 tmux 設定後，它會自動重新載入，毋須按鍵，也毋須指令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 狀態列顯示電池狀態，從不阻塞狀態列繪製 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 在 tmux 狀態列顯示每部已連接的藍牙裝置及其電量，不阻塞繪製 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | 在 tmux 狀態列顯示 CPU 負載、溫度及頻率，從不阻塞繪製 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在 tmux 狀態列顯示磁碟用量，從不阻塞狀態列繪製 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 從畫面上揀選 URL、路徑、雜湊值或任何其他字詞，並輸入到游標位置，全部以純 shell 實現 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在彈出視窗的 fzf 選擇器中切換、關閉、重新命名或建立 tmux 工作階段、視窗和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 狀態列顯示當前窗格的 git 分支、改動和託管平台數目，而不會阻塞顯示 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 狀態列顯示 NVIDIA、AMD、Intel 及 Apple GPU 的負載、溫度、時脈、功耗及記憶體 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 在 tmux 狀態列顯示目前的 Kubernetes 上下文及命名空間，毋須 kubectl，直接解析 kubeconfig |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在彈出視窗或新視窗中啟動任何 TUI 應用程式，從目前窗格的目錄開始，每個應用程式可設定一個按鍵 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 將任何窗格儲存到檔案：即時記錄、完整捲動緩衝區或一次性截圖 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | **本插件**，在 tmux 狀態列顯示正在播放的歌曲，從不阻塞狀態列的繪製 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在 tmux 狀態列顯示網絡傳輸量，從不阻塞繪製 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的窗格和視窗管理按鍵，配合 tmux 版本，與 vim 相容，每個 prefix 按鍵都可停用 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 儲存 tmux 的所有工作階段、視窗及窗格，按計時器自動儲存，並在重新開機後全部還原 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起點：共用程式庫、bats 測試框架、CI 和系列工具 |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 狀態列中的番茄鐘計時器，所有狀態都儲存在 tmux 選項中，不使用暫存檔 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 狀態列顯示記憶體、交換空間及記憶體壓力，在背景取樣，繪製從不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用滑鼠在 tmux 狀態列上拖動視窗標籤來移動該視窗 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 將滑鼠滾輪交給能自行捲動的應用程式，其他情況下進入 tmux 複製模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和終端機區分的合理預設設定，不會改動你自己設定的選項 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平鋪視窗管理：八種版面，包括 BSP dwindle 和 spiral，並支援復原版面 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 狀態列中的本地時鐘和世界時鐘，按一天中的時段著色，並提供倒數和夏令時間提示 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在背景從 wttr.in 取得天氣並顯示在狀態列，狀態列毋須等待 |

### 檢查安裝

所有成員都在磁碟上時，一個指令即可報告它們之間的任何衝突：

```sh
family/bin/doctor --live
```

它讀取每個成員和正在運行的 tmux 伺服器，報告重複的按鍵、重複的狀態佔位符、不符合命名規則的選項，以及約定版本落後的成員。

<!-- family:end -->
