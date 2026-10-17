<div align="center">

# tmux-music-revamped

<strong>在 tmux 状态栏显示正在播放的曲目，从不阻塞状态栏渲染。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; 简体中文 &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![Tests](https://github.com/tmux-revamped/tmux-music-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-music-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#what-it-does">功能</a> &nbsp;|&nbsp;
  <a href="#installation">安装</a> &nbsp;|&nbsp;
  <a href="#usage">用法</a> &nbsp;|&nbsp;
  <a href="#configuration">配置</a> &nbsp;|&nbsp;
  <a href="#key-bindings">按键绑定</a> &nbsp;|&nbsp;
  <a href="#how-it-works">工作原理</a>
</p>

</div>

**7** 个占位符，**4** 种播放器后端，默认只绑定 **1** 个按键，支持 tmux **3.2** 及以上版本。

---

<a id="what-it-does"></a>

## 功能

插件在状态栏显示当前曲目、播放状态、进度条以及已播放时间和总时长。播放器在后台查询，所以状态栏只读取缓存的值，从不等待播放器。缓存值保存在 tmux 选项中，不写入任何临时文件。

`prefix + M-m` 打开的菜单可以播放、暂停和切换曲目。

| 后端 | 平台 | 读取 | 控制 |
|:-----|:-----|:----:|:----:|
| `nowplaying-cli` | macOS | Yes | No |
| `playerctl` | Linux | Yes | Yes |
| `cmus-remote` | Linux 和 macOS | Yes | Yes |
| 通过 `osascript` 控制的 Spotify | macOS | Yes | Yes |

<a id="requirements"></a>

## 环境要求

| 依赖 | 版本 |
|:-----|:-----|
| tmux | 3.2 及以上 |
| bash | 3.2 及以上 |
| 播放器后端 | 上表中的任意一个 |

可在 Linux 和 macOS 上运行，支持 BSD、GNU 或 uutils coreutils。在 macOS 上，Spotify 无需额外安装软件包，安装 `nowplaying-cli` 后可支持其他所有播放器。

<a id="installation"></a>

## 安装

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

<a id="usage"></a>

## 用法

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

<a id="configuration"></a>

## 配置

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

<a id="key-bindings"></a>

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

<a id="how-it-works"></a>

## 工作原理

[`music-revamped.tmux`](music-revamped.tmux) 把 `status-left` 和 `status-right` 中的每个占位符替换为对 [`src/music.sh`](src/music.sh) 的调用，在 `options` 模式下则替换为选项读取。然后绑定按键。

脚本从第一个可用的后端读取：先是 macOS 上的 `nowplaying-cli`，然后是报告了播放器的 `playerctl`，再是 `cmus-remote`，最后是 macOS 上通过 `osascript` 控制的 Spotify。使用 `playerctl` 时，正在播放的播放器优先于其他播放器，控制操作也作用于同一个播放器。由于 `nowplaying-cli` 只能读取，控制依次使用 `playerctl`、`cmus-remote` 和 Spotify。

读取结果保存为 tmux 选项，并在 `@music_revamped_interval` 秒内重复使用。结果过期时会启动一次独立的刷新，当前调用返回缓存的值。在 `options` 模式下，后台进程在两次读取之间等待同样的间隔，并在 tmux 服务器停止或有更新的进程接管时退出。

标题和艺术家中的每个 `#` 在到达状态栏之前都会被加倍，所以曲目名称无法注入 tmux 格式。

<a id="development"></a>

## 开发

| 命令 | 作用 |
|:-----|:-----|
| `make test` | 运行 bats 测试套件 |
| `make lint` | 对所有 shell 文件运行 shellcheck |
| `make coverage` | 在 Linux 上用 kcov 测量行覆盖率，低于 95% 时失败 |

变更记录见 [CHANGELOG.md](CHANGELOG.md)。

<a id="license"></a>

## 许可证

[MIT](LICENSE)

<!-- family:begin -->

## tmux-revamped 插件家族

本插件是 tmux-revamped 插件家族的一员。每个成员都带有 [`FAMILY.md`](FAMILY.md) 中的同一份约定、`family/` 下的同一套工具和同一个共享库，并由校验和清单保证逐字节一致。这些成员可以一起安装：任何成员都不会占用其他成员使用的按键或 tmux 选项。

在一个成员中发现的缺陷，要在全部成员中排查之后才算修复完成。这项义务写在约定里，而不是靠记忆，`family/bin/sweep` 负责执行它。

| 成员 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 编辑并保存 tmux 配置后自动重新加载，无需按键或命令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 状态栏显示电池状态，从不阻塞状态栏渲染 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 在 tmux 状态栏显示每个已连接的蓝牙设备及其电量，不阻塞渲染 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | 在 tmux 状态栏显示 CPU 负载、温度和频率，从不阻塞渲染 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在 tmux 状态栏显示磁盘使用情况，从不阻塞状态栏渲染 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 选取屏幕上的 URL、路径、哈希或其他任意词元，并在光标处输入，纯 shell 实现 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在弹出窗口的 fzf 选择器中切换、关闭、重命名或创建 tmux 会话、窗口和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 状态栏显示当前窗格的 Git 分支、改动和代码托管平台计数，不阻塞状态栏 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 状态栏显示 NVIDIA、AMD、Intel 和 Apple GPU 的负载、温度、频率、功耗和显存 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 在 tmux 状态栏显示当前 Kubernetes 上下文和命名空间，直接解析 kubeconfig，无需 kubectl |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在弹出窗口或新窗口中启动任意 TUI 应用，从当前窗格的目录开始，每个应用可配置一个按键 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 将任意窗格保存到文件：实时日志、完整回滚缓冲区或一次性截图 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | **本插件**，在 tmux 状态栏显示正在播放的曲目，从不阻塞状态栏渲染 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在 tmux 状态栏显示网络吞吐量，从不阻塞渲染 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的标准窗格和窗口管理按键，适配 tmux 版本，兼容 vim，全部可配置 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 保存所有 tmux 会话、窗口和窗格，按定时器自动保存，并在重启后全部恢复 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | 用于构建不阻塞的 tmux 状态栏插件的模板 |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 状态栏中的番茄钟，所有状态都保存在 tmux 选项中，不使用临时文件 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 状态栏显示内存、交换空间和内存压力，在后台采样，渲染从不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用鼠标沿 tmux 状态栏拖动窗口标签来移动该窗口 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 把鼠标滚轮交给能自行滚动的应用，其他地方进入 tmux 复制模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和终端启用的合理默认值，不改动你设置过的选项 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平铺窗口管理：8 种布局，包括 BSP dwindle 和 spiral，支持撤销布局 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 用于 tmux 状态栏的本地时钟和世界时钟，按一天中的时段着色，带倒计时和夏令时提醒 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在 tmux 状态栏显示来自 wttr.in 的天气，在后台获取，状态栏从不等待 |

### 检查安装

所有成员都在磁盘上时，一条命令即可报告它们之间的任何冲突：

```sh
family/bin/doctor --live
```

它读取每个成员和正在运行的 tmux 服务器，报告重复的按键、重复的状态占位符、不符合命名规则的选项，以及约定版本落后的成员。

<!-- family:end -->
