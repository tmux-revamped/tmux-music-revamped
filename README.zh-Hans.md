<div align="center">

# tmux-music-revamped

<strong>在 tmux 状态栏显示正在播放的曲目，从不阻塞状态栏渲染。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; 简体中文 &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-music-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-music-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-music-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-music-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-music-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-music-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-music-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#快速开始"><strong>快速开始</strong></a> &nbsp;|&nbsp;
  <a href="#用法">用法</a> &nbsp;|&nbsp;
  <a href="#工作原理">工作原理</a> &nbsp;|&nbsp;
  <a href="#界面">界面</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="music-revamped 在状态栏中显示曲目，通过菜单和按键切歌与暂停，截断过长的名称，并切换到 options 渲染模式" width="800">
</p>

```console
$ music-revamped refresh
Refreshed. So What is playing.
$ music-revamped status now
So What - Miles Davis
```

**7** 个占位符，**4** 种播放器后端，默认只绑定 **1** 个按键，支持 tmux **3.2** 及以上版本。

---

## 快速开始

### 前提条件

| 工具 | 版本 | 用途 |
|:-----|:--------|:---------|
| tmux | 3.2 或更高 | 家族的最低版本 |
| 播放器 | 四种之一 | macOS 上的 `nowplaying-cli`、`playerctl`、`cmus-remote`，或 macOS 上通过 `osascript` 控制的 Spotify |
| gum | 可选 | `music-revamped` 的菜单、表格和颜色；没有它，所有命令都输出纯文本 |

### 安装

使用 [TPM](https://github.com/tmux-plugins/tpm) 时，把插件加入 `~/.tmux.conf`，然后按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-music-revamped'
```

手动安装时，克隆仓库，并在 `~/.tmux.conf` 中运行入口脚本：

```bash
git clone https://github.com/tmux-revamped/tmux-music-revamped ~/.tmux/plugins/tmux-music-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-music-revamped/music-revamped.tmux
```

在克隆的目录中运行 `make install`，还会把 `music-revamped` 放进 `~/.local/bin`，把它的 man 手册和补全放在 `~/.local/share` 下。

### 验证

```bash
~/.tmux/plugins/tmux-music-revamped/bin/music-revamped doctor
```

## 用法

插件在状态栏显示当前曲目、播放状态、进度条以及已播放时间和总时长。播放器在后台查询，所以状态栏只读取缓存的值，从不等待播放器。缓存值保存在 tmux 选项中，不写入任何临时文件。

`prefix + M-m` 打开的菜单可以播放、暂停和切换曲目。

| 后端 | 平台 | 读取 | 控制 |
|:-----|:-----|:----:|:----:|
| `nowplaying-cli` | macOS | Yes | No |
| `playerctl` | Linux | Yes | Yes |
| `cmus-remote` | Linux 和 macOS | Yes | Yes |
| 通过 `osascript` 控制的 Spotify | macOS | Yes | Yes |

在插件加载之前，把占位符写进 `status-left` 或 `status-right`：

```tmux
set -g @music_revamped_max_len '25'
set -g status-left '#{music_icon} #{music} '
```

| 占位符 | 输出 |
|:-------|:-----|
| `#{music}` | 标题和艺术家，例如 `Song - Band` |
| `#{music_icon}` | 表示播放、暂停或停止的图标 |
| `#{music_status}` | `playing`、`paused`、`stopped` 或 `unknown` |
| `#{music_title}` | 曲目标题 |
| `#{music_artist}` | 曲目艺术家 |
| `#{music_progress}` | 已播放时间相对曲目时长的进度条 |
| `#{music_time}` | 已播放时间和总时长，例如 `0:30/3:20` |

找不到播放器时，所有占位符都显示为空。完整示例见 [`examples/status-left.tmux.conf`](examples/status-left.tmux.conf)。

| 命令 | 作用 |
|:--------|:-------------|
| `music-revamped apply` | 立即绑定按键并替换占位符；插件加载时入口点会运行它 |
| `music-revamped list` | 打印 `apply` 会发送的每条命令，不做任何修改；`--json` 输出一个对象 |
| `music-revamped status NAME` | 打印一个占位符：`now`、`icon`、`status`、`title`、`artist`、`progress` 或 `time`；状态栏会运行它 |
| `music-revamped refresh` | 立即读取播放器，并说明正在播放的内容 |
| `music-revamped play-pause` | 播放或暂停 |
| `music-revamped next` | 跳到下一首 |
| `music-revamped prev` | 回到上一首 |
| `music-revamped daemon` | 为 `options` 渲染模式在每个周期发布占位符；由 `apply` 启动 |
| `music-revamped doctor` | 每个依赖一行，包括读取的播放器、控制的播放器和保持不动的按键 |
| `music-revamped version` | 版本，然后是 tmux 版本 |
| `music-revamped help` | 帮助页；`man music-revamped` 记录相同的命令和设置 |
| `music-revamped` | 在终端上显示菜单 |

## 配置

每个选项也可以用带连字符的命令选项（例如 `--max-len 25`）和环境变量（例如 `MUSIC_REVAMPED_MAX_LEN`）设置；命令行优先于环境变量，环境变量优先于 tmux 选项。空的 tmux 选项表示使用默认值。传给 `apply` 的选项会随每个绑定、每个菜单项和每次状态调用一起生效。

### 显示选项

| 选项 | 默认值 | 含义 |
|:-----|:-------|:-----|
| `@music_revamped_interval` | `5` | 读取结果保持有效的秒数，过期后重新查询播放器 |
| `@music_revamped_format` | `%s - %s` | `#{music}` 中标题和艺术家的 `printf` 格式 |
| `@music_revamped_max_len` | `0` | 把 `#{music}` 中的标题和艺术家截断到该字符数并加上 `...`；`0` 表示不截断 |
| `@music_revamped_before` | 空 | 有曲目可显示时放在 `#{music}` 前面的文字 |
| `@music_revamped_after` | 空 | 有曲目可显示时放在 `#{music}` 后面的文字 |
| `@music_revamped_auto_hide` | `1` | `1` 表示除播放或暂停外隐藏图标；`0` 表示始终显示 |
| `@music_revamped_playing_icon` | `>` | 播放时的图标 |
| `@music_revamped_paused_icon` | `\|\|` | 暂停时的图标 |
| `@music_revamped_stopped_icon` | `[]` | 停止时的图标 |
| `@music_revamped_unknown_icon` | 空 | 状态未知时的图标 |
| `@music_revamped_progress_width` | `10` | 进度条的格数 |
| `@music_revamped_progress_full` | U+2588，实心方块 | 已播放部分的格子 |
| `@music_revamped_progress_empty` | U+2591，浅色阴影 | 未播放部分的格子 |
| `@music_revamped_time_format` | `%s/%s` | 已播放时间和总时长的 `printf` 格式 |

### 按键选项

| 选项 | 默认值 | 含义 |
|:-----|:-------|:-----|
| `@music_revamped_menu_key` | `M-m` | 打开播放菜单的 prefix 按键；设为 `off` 则取消绑定 |
| `@music_revamped_playpause_key` | 空 | 切换播放和暂停的 prefix 按键 |
| `@music_revamped_next_key` | 空 | 跳到下一首的 prefix 按键 |
| `@music_revamped_prev_key` | 空 | 回到上一首的 prefix 按键 |

### 渲染模式

| 选项 | 默认值 | 含义 |
|:-----|:-------|:-----|
| `@music_revamped_render` | `jobs` | `jobs` 把每个占位符变成 `#()` 调用；`options` 把它变成对 tmux 选项的读取 |

在 `jobs` 模式下，tmux 每次重绘状态栏都会运行脚本。在 `options` 模式下，每个占位符变成 `#{E:@music_revamped_out_title}` 这样的读取，每个服务器只有一个后台进程，用一次 tmux 调用写入状态栏用到的所有值。按下控制键会立即发布新状态。

```tmux
set -g @music_revamped_render 'options'
```

### 内部状态

以下选项由插件自己写入，请勿设置。

| 选项 | 保存内容 |
|:-----|:---------|
| `@music_revamped_published` | 状态栏用到的指标，以空格分隔，加载时写入，`options` 模式只发布这些指标 |
| `@music_revamped_out_<metric>` | `options` 模式下每个已发布指标的渲染结果 |
| `@music_revamped_ticker_pid` | 负责发布的后台进程的进程 ID |

## 按键绑定

| 按键 | 操作 | 默认 |
|:-----|:-----|:-----|
| `prefix + M-m` | 播放菜单：`p` 播放或暂停，`n` 下一首，`b` 上一首 | 已绑定 |
| `@music_revamped_playpause_key` | 播放或暂停 | 未绑定 |
| `@music_revamped_next_key` | 下一首 | 未绑定 |
| `@music_revamped_prev_key` | 上一首 | 未绑定 |

为每个控制分配专用按键：

```tmux
set -g @music_revamped_playpause_key 'M-p'
set -g @music_revamped_next_key 'M-n'
set -g @music_revamped_prev_key 'M-b'
```

<a id="工作原理"></a>

## 工作原理

[`music-revamped.tmux`](music-revamped.tmux) 把 `status-left` 和 `status-right` 中的每个占位符替换为对 [`bin/music-revamped`](bin/music-revamped) 的调用，在 `options` 模式下则替换为选项读取。然后绑定按键。

脚本从第一个可用的后端读取：先是 macOS 上的 `nowplaying-cli`，然后是报告了播放器的 `playerctl`，再是 `cmus-remote`，最后是 macOS 上通过 `osascript` 控制的 Spotify。使用 `playerctl` 时，正在播放的播放器优先于其他播放器，控制操作也作用于同一个播放器。由于 `nowplaying-cli` 只能读取，控制依次使用 `playerctl`、`cmus-remote` 和 Spotify。

读取结果保存为 tmux 选项，并在 `@music_revamped_interval` 秒内重复使用。结果过期时会启动一次独立的刷新，当前调用返回缓存的值。在 `options` 模式下，后台进程在两次读取之间等待同样的间隔，并在 tmux 服务器停止或有更新的进程接管时退出。

标题和艺术家中的每个 `#` 在到达状态栏之前都会被加倍，所以曲目名称无法注入 tmux 格式。

<a id="界面"></a>

## 界面

<details>
<summary>所有界面，在真实的 tmux 中用 <code>make screens</code> 录制，每个按键显示在状态栏上</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/playing.png" alt="music-revamped：状态栏中的曲目、进度和时间"><br><sub>状态栏中的曲目、进度和时间，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/menu.png" alt="music-revamped：prefix M-m 打开播放菜单"><br><sub><code>prefix M-m</code> 打开播放菜单，来自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/next.png" alt="music-revamped：菜单中的 n 跳到下一首"><br><sub>菜单中的 <code>n</code> 跳到下一首，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/paused.png" alt="music-revamped：播放或暂停键 prefix M-p 暂停播放"><br><sub>播放或暂停键 <code>prefix M-p</code> 暂停播放，来自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/previous.png" alt="music-revamped：上一首键 prefix M-b 回到上一首"><br><sub>上一首键 <code>prefix M-b</code> 回到上一首，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/cut.png" alt="music-revamped：@music_revamped_max_len 截断标题和艺术家"><br><sub><code>@music_revamped_max_len</code> 截断标题和艺术家，来自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/options.png" alt="music-revamped：在 options 渲染模式下，每个占位符读取一个 tmux 选项"><br><sub>在 <code>options</code> 渲染模式下，每个占位符读取一个 tmux 选项，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/options-next.png" alt="music-revamped：在该模式下，下一首键 prefix M-n 的效果立即显示"><br><sub>在该模式下，下一首键 <code>prefix M-n</code> 的效果立即显示，来自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/list.png" alt="music-revamped：list 打印每个绑定"><br><sub><code>list</code> 打印每个绑定，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/status.png" alt="music-revamped：status now 打印曲目"><br><sub><code>status now</code> 打印曲目，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="music-revamped：doctor"><br><sub><code>doctor</code>，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="music-revamped：没有 gum 的菜单"><br><sub>没有 gum 的菜单，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="music-revamped：从菜单运行 doctor"><br><sub>从菜单运行 <code>doctor</code>，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/version.png" alt="music-revamped：版本"><br><sub>版本，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/error.png" alt="music-revamped：未知命令"><br><sub>未知命令，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/accent.png" alt="music-revamped：来自 MUSIC_REVAMPED_ACCENT 的强调色"><br><sub>来自 <code>MUSIC_REVAMPED_ACCENT</code> 的强调色，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/themes.png" alt="music-revamped：六种主题下的标题"><br><sub>六种主题下的标题，来自 <code>themes.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/help.png" alt="music-revamped：帮助页"><br><sub>帮助页，来自 <code>help.tape</code></sub></td>
</tr>
</table>

录制时运行的是真实的插件和 tmux。播放器由一个小脚本代替，按键确实在操作它。

</details>

## 可移植性

插件是 POSIX `sh`。CI 在下面每一行上运行全部测试。

| Shell | 状态 |
|:------|:-------|
| `dash`、macOS 上的 `/bin/sh` | 支持 |
| `bash` 3.2 和 5.x、系统自带的 `zsh` 和 Homebrew 的 `zsh` | 支持 |

| 系统 | 状态 |
|:-------|:-------|
| macOS | Apple Silicon 和 Intel 上的 Tahoe，使用系统自带的工具、Homebrew 的 GNU 工具和 Homebrew 的 uutils |
| Linux | x86_64 和 arm64 上的 Ubuntu 26.04，使用 GNU coreutils、uutils 和 BusyBox |

## 开发

| 命令 | 运行内容 |
|:--------|:-------------|
| `make fmt` | 对每个脚本运行 shfmt `-i 2` |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint 和 actionlint，零告警 |
| `make test` | 在系统 `sh` 下运行 bats 测试 |
| `make test-all` | 在每个已安装的 shell 下运行测试，macOS 上包括 bash 和 zsh 的两种构建 |
| `make test-linux` | 在 Ubuntu 容器中运行测试 |
| `make coverage` | 在这台 Mac 和 Ubuntu 容器中运行 bashcov，合并后以 100% 为门槛 |
| `make screens` | 用 VHS 在 tmux 中从真实插件录制上面的界面，在 macOS 上运行 |
| `make install` | 把命令、man 手册和补全安装到 `PREFIX` 下 |

在 macOS 上，运行 `brew bundle` 会根据 [`Brewfile`](Brewfile) 安装这些目标用到的所有工具。

提交遵循 Conventional Commits 格式，直接进入 `main`。`main` 上的 `ci` 通过后，`release.yml` 运行 semantic-release：自上一个标签以来的每个 `feat` 或 `fix` 都会发布新版本，更新版本常量，并把说明写进 [`CHANGELOG.md`](CHANGELOG.md)。

## 许可证

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 插件家族

这个插件是 tmux-revamped 插件家族的一员。每个成员都带有 [`FAMILY.md`](FAMILY.md) 中相同的约定和相同的共享库，并且设计为一起安装：没有成员占用另一个成员占用的按键或 tmux 选项。

在一个成员中发现的缺陷，要在全部成员中排查之后才算修复完成。

| 成员 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 编辑并保存 tmux 配置后，它会自动重新加载，无需按键，也无需命令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 状态栏显示电池状态，从不阻塞状态栏渲染 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 在 tmux 状态栏显示每个已连接的蓝牙设备及其电量，不阻塞渲染 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | 在 tmux 状态栏显示 CPU 负载、温度和频率，从不阻塞渲染 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在 tmux 状态栏显示磁盘用量，从不阻塞状态栏渲染 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 从屏幕上挑选 URL、路径、哈希或任意其他词元，并输入到光标处，全部用纯 shell 实现 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在弹出窗口中的 fzf 选择器里切换、关闭、重命名或创建 tmux 会话、窗口和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 状态栏中显示活动窗格的 git 分支、改动和托管平台计数，且不阻塞渲染 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 状态栏中显示 NVIDIA、AMD、Intel 和 Apple GPU 的负载、温度、频率、功耗和显存 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 在 tmux 状态栏中显示当前的 Kubernetes 上下文和命名空间，不依赖 kubectl，直接解析 kubeconfig |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在弹出窗口或新窗口中启动任意 TUI 应用，从当前窗格的目录开始，每个应用可配置一个按键 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 将任意窗格保存到文件：实时日志、完整回滚缓冲区或一次性截图 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | **本插件**，在 tmux 状态栏显示正在播放的曲目，从不阻塞状态栏渲染 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在 tmux 状态栏显示网络吞吐量，从不阻塞渲染 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的窗格和窗口管理按键，适配 tmux 版本，兼容 vim，每个 prefix 按键都可禁用 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 保存 tmux 的所有会话、窗口和窗格，按定时器自动保存，并在重启后全部恢复 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起点：共享库、bats 测试框架和 CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 状态栏中的番茄钟计时器，所有状态都保存在 tmux 选项中，不使用临时文件 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 状态栏显示内存、交换空间和内存压力，在后台采样，渲染从不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用鼠标在 tmux 状态栏上拖动窗口标签来移动该窗口 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 将鼠标滚轮交给能自行滚动的应用，其他情况下进入 tmux 复制模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和终端区分的合理默认设置，不改动你自己设置的选项 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平铺窗口管理：八种布局，包括 BSP dwindle 和 spiral，并支持撤销布局 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 状态栏中的本地时钟和世界时钟，按一天中的时段着色，并提供倒计时和夏令时提醒 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在后台从 wttr.in 获取天气并显示在状态栏，状态栏无需等待 |

<!-- family:end -->
