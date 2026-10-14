# AGENT.md

> 给 AI 助手（以及未来的我自己）的操作手册。
>
> 这是一份「改这个仓库之前必须先读」的文档。里面记的大多是**踩过的坑**，
> 每一条都是实际验证出来的，不是推测。跳过它们会重复付学费。

---

## 0. 这是什么

`~/.config/nvim` 是我的个人 Neovim 配置，git 仓库 `git@github.com:NeoWangKing/nwvim.git`。

- 插件管理：[lazy.nvim](https://github.com/folke/lazy.nvim)
- 版本锁定：`lazy-lock.json`
- 配色方案：自研 `colors/p3-blue.lua`（**不是** README 里写的 catppuccin，README 那段已过期）
- 目标平台：**macOS / Linux / Windows(WSL) 三端共用同一套配置**

---

## 1. 目录地图

```
init.lua                 启动入口。顺序：leader → 关内置功能 → 各模块 → lazy → 配色/透明背景
colors/p3-blue.lua       自研配色方案（调色板 + 高亮组映射）
dictionary/              拼写补全词库（英文 / 物理 / C 与计算机）
ftdetect/                文件类型识别（gnuplot.lua: .gp；opf.lua: .opf → xml）
scripts/                 仓库自检脚本（见第 2 节）+ 词库重建脚本
lua/config/
  options.lua            编辑器选项（含剪贴板平台探测）
  keymaps.lua            全局键位 + LSP 键位（LspAttach 集中在一处）
  autocmds.lua           自动命令（全部挂同一个 augroup）
  commands.lua           自定义命令（:OpenPDF :OpenImage :Run :Xelatex …）
  hello.lua              :SayHello 的模板表 + 「空文件 / 认得语言」判断
  run.lua                :Run 的实现：输出流式写进独立 scratch 窗口 + 报错位置着色 + 从报错行跳转
  terminal.lua           <leader>st 的自适应分屏终端
  lazy.lua               lazy.nvim 引导（含 git 协议探测）
  platform.lua           ★ 跨平台抽象层，三端兼容的核心
  oil-dired.lua          ★ oil.nvim 的 dired 行为扩展层
  latex-check.lua        markdown 里 LaTeX 公式的语法检查（treesitter）
  telescope/             Telescope 相关拆分配置
lua/plugins/*.lua        每个插件一个文件，按功能命名
```

### 改配置时的约定

- **一个插件一个文件**，文件名与用途对应，不要塞进大杂烩。
- **全局键位只写 `lua/config/keymaps.lua`**（插件自己缓冲区里的键位除外，例如 oil 的
  keymaps 表）。统一写 `<leader>` 而不是 `<space>`，两者等价但前者一眼可读。
- **不要抄插件默认值**。配置里只保留「和默认值不同」的选项：抄一遍的坏处是后来的人
  以为这里改过东西，而且插件升级改了默认值之后，配置会把旧行为钉死。
  判断方法：去 `~/.local/share/nvim/lazy/<插件>/lua/.../config.lua` 里读 default 表。
- **新增插件时先想清楚要不要懒加载**：见第 10 节（启动路径）。
- **平台相关的判断一律走 `config/platform.lua`**，不要在插件文件里写
  `if vim.fn.has("mac") == 1`。新增平台差异时先往 `platform.lua` 里加函数。
- **注释写中文**，并且解释「为什么」而不是「是什么」。这个仓库的注释密度
  是刻意保持的，改代码时请延续。

---

## 2. 主题系统（`colors/p3-blue.lua`）

整套配色由壁纸 `~/Pictures/wallpaper/结城理.jpg`（Persona 3）提取，蓝色为主，
后续为降低眼疲劳把背景改成了中性灰（`#1F2124`）。

### 结构

文件顶部是 `local p = { ... }` 调色板，下面全部高亮组都引用 `p.xxx`。
**调色板是唯一改动点**，不要去改下面的高亮组字面量。

以前有 9 处例外（5 个 `DiagnosticVirtualText*` 和 4 个 `Diff*` 直接写死了十六进制底色），
现在都收进了调色板：`bg_vtext_error/warn/info/hint/ok`、`bg_diff_add/change/delete/text`。
顺手删掉了 3 个没人引用的键（`bg_hover`、`blue_br`、`teal`）—— 当前是
**定义 36 个键、引用 36 个键、0 未定义、0 未引用**。加色 / 删色之后跑一次检查脚本即可确认。

### 关键约束

| 键 | 值 | 说明 |
|---|---|---|
| `bg` | `#1F2124` | 主背景 |
| `fg` | `#C3D3E6` | 正文 |
| `fg_muted` | `#8D95A1` | 次要文字，对比度 4.50:1 |
| `ghost` | `#8D95A1` | blink 虚影补全文字 |
| `linenr` | `#8D95A1` | 行号 |
| `blue` | `#6A96D8` | 关键字 |

字号、对比度都按「最坏情况合成底色」核算过。改颜色时请一并核对对比度，
**正文类目标 ≥ 4.5:1，装饰类 ≥ 3:1**。

### ⚠️ 两个必须知道的陷阱

1. **`p.X or p.Y` 会掩盖漏定义的键。**
   本仓库出现过两次真实事故：`BlinkCmpGhostText = { fg = p.fg_ghost or p.border }`
   而 `fg_ghost` 从未定义 → 静默退化成边框色 `#3E434A`（对比度 1.37:1），
   虚影几乎不可见；`WinBarNC` 同理。
   **改完主题后务必跑一次检查脚本：**

   ```bash
   nvim --headless -u NONE -c "luafile ~/.config/nvim/scripts/check-palette.lua" -c "qa!" 2>&1
   ```

   全部正常时输出 `✓ 没有未定义的调色板键` 并返回退出码 0；
   有漏定义的键时列出键名并返回非 0（可以直接挂进 git hook 或 CI）。

   > **不要用 `grep` 手搓这个检查**，macOS 上会连踩两个坑：
   > ① BSD `grep` 不支持 `\s`，`'^\s+[a-z_]+'` 会匹配不到任何东西；
   > ② `grep -o 'p\.[a-z_]*'` 会把 treesitter 捕获名 `@markup.heading`
   > 里的 `p.heading` 也算进来，产生一堆误报。
   > `scripts/check-palette.lua` 已经处理了去注释和词边界，是可靠版本。

2. **`nvim_set_hl` 是整体替换，不是合并。**
   `nvim_set_hl(0, g, { bg = "none" })` 会把该组原有的 `fg` / `bold` / `italic`
   全部抹掉。`init.lua` 里的 `set_transparent()` 曾因此让 StatusLine、
   FloatBorder、TabLineSel、NormalFloat 等 20 个组丢配色。
   正确做法是**先读出现有定义，改掉 bg，再整体写回**（现有实现已修正，别再改回去）。

`set_transparent()` 会用 `^BufferLine` 前缀**动态匹配** bufferline 派生出的 60+
个高亮组，不要退回手写列表——它升级后新增组名会漏。

### 相关文件

- Ghostty 终端：`~/.config/ghostty/config`（16 色 P3 调色板，亮度已单调对齐）
- yazi：`~/.config/yazi/theme.toml`（做过一轮降饱和，蓝色系平均饱和度 43% → 29%）
- Zed：`~/.config/zed/themes/p3-blue.json`
- Starship：`~/.config/starship.toml`（调色板名 `p3_blue`，token 名保持不变，
  以免动到字形行）

---

## 3. 跨平台层（`lua/config/platform.lua`）

三端兼容的**唯一**入口。已导出：

| 类别 | 接口 |
|---|---|
| 平台判定 | `is_mac` / `is_linux` / `is_windows` / `is_wsl` |
| 打开方式 | `open_path` / `open_with_app` / `supports_app_named_open` |
| 外部程序 | `VIEWERS`（表）/ `pick_viewer(kind)` / `open_with_viewer` |
| 剪贴板 | `clipboard_available` |
| 执行 | ——（原来的 `run_capture` 已删：`:Run` 改成流式输出窗口后没人用了，实现见 `config/run.lua`） |
| 文件属性 | `chmod(paths, mode, on_done)` / `touch(paths, on_done)` / `compress(paths, on_done)` |
| PATH | `prepend_path(dir)` |
| 命令片段 | `CMD`（`bin_prefix` / `exe_suffix` / `python` / `opener`，给「最小可运行命令」用） |
| Git | `detect_git_protocol` / `git_url_format` |
| 词库 | `dictionary_dirs` |

`chmod` / `touch` / `compress` 是给 dired 层的 `<leader>M` / `<leader>T` / `<leader>Z` 用的：
**Windows 上根本没有 `chmod` / `touch` / `gzip` 命令**，以前直接调命令，在那边三个键等于坏的。
现在八进制权限走 `vim.uv.fs_chmod`、touch 走 `vim.uv.fs_open` + `fs_utime`（三端一致），
符号权限（`+x`）和 gzip 才需要外部命令，缺了就**明确报错**而不是静默什么都不做。
三个函数统一用 `on_done(ok, err)` 回调收尾，调用方不用关心同步还是异步。

### 各平台默认外部程序

- **PDF**：macOS → Skim / Preview；Linux → **evince**（首选）、zathura、mupdf、
  llpp、okular、xpdf；Windows → SumatraPDF、Edge
- **图片**：macOS → Preview；Linux → **feh**、nsxiv、sxiv、imv、qiv、eog；
  Windows → nomacs、mspaint

`git_url_format()` 会探测 `git@github.com` 是否可用，不可用时返回 `nil`；
`config/lazy.lua` 只在非 nil 时才设置 `lazy_opts.git.url_format`——
**不要无条件设置**，否则 https 环境会拉不到插件。

---

### 换机器要做的事（清单）

配置本身是跨平台的（平台差异都收在 `platform.lua`），但有几样东西
**不在仓库里**，换机器必须手动补。漏掉的表现往往是**静默不工作**：

| 项目 | 怎么补 | 漏了会怎样 |
|---|---|---|
| treesitter parser | `:TSInstall markdown markdown_inline latex` | 标题渲染与 LaTeX 语法检查全不工作。`latex-check.lua` 检测到会 notify 一次并给出确切命令（实测过） |
| `fzf` | 发行版包管理器 | 词典补全的**词频排序失效**——插件在 `cmd ~= "fzf"` 分支里会用自己的模糊分重排，`--tiebreak=index` 那套白做 |
| `rg` | 同上 | Telescope 的 live_grep / multi-grep 不可用 |
| ImageMagick（`magick`） | 同上 | image.nvim 行内图片不渲染（`processor = "magick_cli"`） |
| Nerd Font | 装字体 + 改 Ghostty 配置 | 图标变方块或回退字形。**Ghostty 配置是独立仓库**（`~/.config/ghostty`），换机器要一并带走 |
| `utftex` | `brew install utftex`（Linux 用发行版包管理器） | **当前不需要**：公式渲染已关。仅当把 `latex.enabled` 改回 true 才要装 |
| `python3` | 系统自带即可 | 仅 `scripts/build-dictionary.py`（重建词库顺序）需要，一次性 |

**平台的判断一律走 `platform.lua`**，不要在插件文件里写 `has("mac")`。

> ⚠ **Ghostty 字体**（独立仓库，最容易漏）：
> 用的是 `JetBrainsMono Nerd Font Mono`，**不是**普通 `JetBrains Mono`——
> 后者只含 powerline 区（U+E0B0 起），不含 nf-md / nf-dev 等区间，
> 图标会靠系统字体回退显示。家族名/样式名要用 `ghostty +list-fonts` 查，
> 不能照抄 `fc-list` 的写法（两者命名规则不同）。

## 4. 补全系统（`lua/plugins/blink.lua`）

按**文件类型**分成两套行为：

- **散文**（`markdown` / `text` / `tex` / `gitcommit` / `rst` / `asciidoc` / `org` …，
  见 `PROSE_FILETYPES`）：不要候选框，只在光标后显示**暗色虚影**补全单词；
  候选源 = `dictionary` + `buffer` + `path`
- **代码**：正常弹候选框；候选源 = `lsp` + `path` + `snippets` + `buffer`

### ⚠️ 陷阱

1. **绝对不要设 `menu.enabled = false`。**
   它控制的是整个菜单模块的装配；ghost text 的代码会引用 `menu.context`，
   关掉菜单会让虚影一起崩掉。要「不自动弹窗」请用 `menu.auto_show` 函数。
2. 虚影由 `list.show_emitter` 驱动，**与菜单是否显示无关**，
   所以 `show_without_menu = true` 是虚影能出现的必要条件。
3. 词典使用 fzf 过滤，默认是**模糊匹配**，`malloc` 会淹没在一堆
   `small`/`shallow` 里。已在 `get_command_args` 里注入 `^` 锚点改为前缀匹配。
4. **`dictionary/` 里的多个 .txt 是直接拼接的，没有任何去重。**
   同一个词出现在两个文件里会产生两条重复候选。
   优先级约定：`english-words > c-computing > physics`。
   新增词条前先查重：

   ```bash
   grep -x "word" ~/.config/nvim/dictionary/*.txt
   ```

### 词库现状

| 文件 | 条目 | 来源 / 许可 |
|---|---|---|
| `english-words.txt` | 370,105 | dwyl/english-words，Unlicense |
| `physics.txt` | 318 | 自建 |
| `c-computing.txt` | 481 | 自建 |

合计 370,904 条，跨文件 0 重复。生成脚本曾是 `/tmp/dictgen/*.py`（易失，
需要重做时按 `dictionary/README.md` 的规则重建）。

---

## 5. oil.nvim + dired 层

### 设计思路

Emacs dired 有两块核心：

- **A. 可编辑的目录缓冲区**（即 wdired）——「改名 = 编辑那一行、
  删除 = 删掉那一行、`:w` 提交」。**oil 天生就是这个**，而且更安全：
  `:w` 之前随时可以反悔。**`:w` 就是 dired 的 `x`。**
- **B. 标记 + 批量执行**——「`m` 标记、`%m` 按正则标记、`d` 标记删除、`x` 执行」。

`lua/config/oil-dired.lua` 补的是 **B**。配置入口在 `lua/plugins/oil-nvim.lua`
的 `keymaps` 表里（每个键都通过 `require("config.oil-dired")` 延迟加载）。

### 键位

**分配原则：dired 的全部键位统一挂在 `<leader>`（空格）下，第二段沿用 dired 原字母。**

为什么不照搬 dired 的单字母键位：dired 能把 `m/u/t/T/M/Z/D/s/^` 全用掉，
是因为**dired 缓冲区不是文本编辑缓冲区**，文件操作不经过文本。而 oil 的
缓冲区**就是**操作模型本身，编辑类按键是它的命脉。照搬会直接破坏编辑器
（详见第 7 节陷阱 17）。

统一加 `<leader>` 前缀后冲突就消失了，而且第二段还能原样沿用 dired 的字母，
所以还原度反而最高——`<leader>M` 就是 dired 的 `M`。空格在 oil 缓冲区里
原本完全空闲。

| 键 | 作用 | 对应 dired |
|---|---|---|
| `<leader>m` | 标记 / 取消标记光标项 | `m` |
| `<leader>U` | 清除全部标记 | `U` |
| `<leader>t` | 反转标记 | `t` |
| `<leader>%m` | 按正则标记（**Lua 正则**） | `% m` |
| `<leader>d` | **暂存**删除，按 `:w` 提交 | `d`（`:w` 即 `x`） |
| `<leader>M` | chmod（八进制；`+x` 这类符号模式只在 POSIX 可用） | `M` |
| `<leader>T` | touch（新建 / 刷新时间戳） | `T` |
| `<leader>Z` | `gzip -k` 压缩（保留原文件；没装 gzip 会明确报错） | `Z` |
| `<leader>!` | shell 命令（`{}` = 文件名） | `!` |

> **删除是两步确认的**（oil 的安全设计，别当成 bug）：
> `<leader>d` 只把行从列表里删掉（暂存，磁盘不动）；`:w` 提交时 oil 会弹
> `DELETE xxx` 的 `[Y]es/[N]o` 确认框，**按 `y` 才真正删除**。
> `skip_confirm_for_simple_edits = true` 只跳过**改名**这类简单编辑，
> 不覆盖删除。暂存阶段随时 `u` 可撤销。

**代价**（仅在 oil 缓冲区内）：会盖住 4 个全局 `<leader>` 映射 ——
`<leader>d`（delete without yank）、`<leader>mg`（multi grep）、
`<leader>td` / `<leader>tw`（toggle diagnostics / wrap）。
都是在目录列表里不会用到的操作，可以接受。

**全部归还给 vim 的原生键**（曾被误占，别改回去）：
`u` `s` `^` `t` `T` `D` `M` `Z` `q` `m` `U` `!` `%` `?`

**文件操作一律走 `config/platform.lua`**（见第 3 节）。`<leader>M` / `<leader>T` /
`<leader>Z` 以前直接调 `chmod` / `touch` / `gzip`，在 Windows 上静默失败；
现在实现在平台层，oil 侧只负责「取目标 → 报告结果 → 刷新目录」
（`oil-dired.lua` 的 `reporter()` 统一做后两步）。

**`lua/plugins/oil-nvim.lua` 里只写和 oil 默认值不同的选项。** 原来那张表里的 14 个
默认键位、`view_options` 里的 `natural_order`/`case_insensitive`/`sort`/`is_always_hidden`/
`highlight_filename`、以及 `float`/`preview_win`/`confirmation`/`progress`/`ssh`/
`keymaps_help` 整块，逐项比对后确认全是插件默认值，已删除（查全部选项用 `:h oil.SetupOpts`）。

**查看全部键位：按 `g?`**

oil 的帮助窗口直接渲染 `config.keymaps` 这张表，所以**上面这些自定义键位
会自动出现在里面**，不需要另外维护一份清单——新增键位时只要写 `desc` 就会
自动列进去。帮助窗口内按 `q` 或 `<C-c>` 关闭。

> ⚠ 帮助只绑 `g?`，**不要另绑单键 `?`**。oil 缓冲区里 `?` 仍要用于
> 反向搜索，夺走它只省一次按键，不划算。

**按下 `<leader>` 会弹出 which-key 面板**列出所有可选键位（已安装，见
`lua/plugins/which-key.lua`）。因为 dired 键位全部挂在 `<leader>` 下，
按一次空格就能看到这 9 个操作各是什么，不用去翻 `g?`。

> ⚠ **`<space>` 绝对不能再单独映射成 `:`**（曾经映射过，已移除）。
> 两个原因：
> ① Vim 每次按空格都要等 `timeoutlen`(500ms) 才能判断你是要执行那个命令
>    还是要按某个 `<space>x`，leader 菜单因此迟钝；
> ② which-key 注册自动触发器前会先查该键是否已被映射
>    （`which-key/triggers.lua` 的 `is_mapped`），发现已映射就**跳过注册**，
>    于是按空格永远弹不出面板。
> 要进命令行直接按 `:` 就行。

**操作目标的优先级**：有标记 → 用标记；无标记 → 用可视选区；
都没有 → 只用光标所在行。**所有操作都遵循这一条，包括删除**
（dired 的 `d` 在未标记行上也是对当前行生效），保持一致。
标记以**绝对路径**为键，所以刷新、改排序、增删行之后标记依然跟着文件走。

### 做不到的部分（oil 架构决定，别浪费时间）

- dired 的 `i`（把子目录列表插进同一个 buffer）—— oil 是一 buffer 一目录
- dired 的 `(` / `)`（在多目录间跳转）—— 同上
- dired 的 `k`（隐藏某行）—— 需要改全局 `view_options`

**刻意没做的**：`w`（dired 的复制文件名）—— oil 里 `w` 是编辑文件名时
最常用的词移动；`g` 前缀已被 `g?` `gs` `gx` `g.` `g\` 占满。

### ⚠️ oil API 的三个事实（都实测过）

1. **`oil.get_current_dir(buf)` 返回的路径带尾斜杠**，且已解析符号链接
   （`/tmp/x` → `/private/tmp/x`）。拼接时直接 `dir .. name`。
2. **缓冲区第 1 行是父目录 `..`**，`entry.name == ".."`。
   批量操作必须排除它，否则会把父目录也一起算进去。
3. **`oil.get_entry_on_line` 内部用 `strict_indexing = true`**，
   行号越界会**直接报错**而不是返回 nil。
   一律用 `vim.api.nvim_buf_line_count(buf)` 定界，不要硬编码行数。

---

## 6. 怎么验证改动（**最重要的一节**）

这个仓库的历史上，多次出现「看起来对、实际错」的改动。
**请一律实测，不要靠推理下结论。** 下面是可以直接用的方法。

### 6.1 纯逻辑 / 加载性检查（无头）

```bash
nvim --headless -u ~/.config/nvim/init.lua -c "luafile /tmp/test.lua" -c "qa!" 2>&1
```

- 用 `io.stdout:write(...)` 输出，**不要用 `print`**：
  一旦中途报错，缓冲的 `print` 内容会全部丢失，你会什么都看不到。
- 结尾必须自己 `vim.cmd("qa!")`，并且命令行再加一个 `-c "qa!"` 兜底，
  否则报错后进程会挂死到超时。
- 收集启动报错：

  ```lua
  local msgs = vim.api.nvim_exec2("messages", { output = true }).output
  ```

### 6.2 交互行为（TUI、映射、可视模式）—— 用真实 pty + RPC

**headless 下 `nvim_feedkeys` 的嵌套调用不可信**，`nvim_input` 也不驱动映射。
测「按键真的按下去了会怎样」必须上 pty：

```bash
script -q /tmp/pty.log nvim --listen /tmp/nvim.sock -u ~/.config/nvim/init.lua \
  /tmp/somedir >/dev/null 2>&1 &
sleep 4

# 发按键
nvim --server /tmp/nvim.sock --remote-send 'Vj'         # 注意：控制键写 <CR> <Esc>，不要写 \r
# 查状态（这是最可靠的断言手段）
nvim --server /tmp/nvim.sock --remote-expr 'mode(1)'
nvim --server /tmp/nvim.sock --remote-expr 'join(getline(1,"$"), "|")'
nvim --server /tmp/nvim.sock --remote-expr '&modified'
# 跑一段 lua 并写结果到文件（比远程 expr 好写）
nvim --server /tmp/nvim.sock --remote-send ':luafile /tmp/step.lua<CR>'
```

排查报错时把 pty 输出留下来，然后剥 ANSI：

```bash
script -q /tmp/pty.log ...            # 而不是 /dev/null
python3 -c "
import re,sys
raw=open('/tmp/pty.log','rb').read().decode('utf-8','replace')
txt=re.sub(r'\x1b\[[0-9;?]*[a-zA-Z]','',raw).replace('\r','\n')
for l in txt.split('\n'):
    if 'E5113' in l or 'traceback' in l: print(l)
"
```

### 6.3 需要弹输入框的操作 —— 用桩，不要模拟打字

`vim.ui.input` 是异步的，模拟输入很脆。直接替换掉：

```lua
vim.ui.input = function(_, on_confirm) on_confirm("600") end
require("config.oil-dired").chmod()
```

### 6.4 验证时的常见自伤

- **测试脚本自己越界**：`get_entry_on_line` 越界会报错，而报错发生在
  `vim.fn.writefile` 之前，于是结果文件不生成，看起来像"功能没生效"。
  务必先用 `nvim_buf_line_count` 定界，或整段包 `pcall`。
- **把按键排进输入队列去回答确认框**（如 `nvim_input("y")`），
  它会漏进后续的 `:w` 命令行，变成 `:wy`，导致你以为 `:w` 坏了。
- **测试里硬编码行号**：oil 目录内容会随操作变化而行号位移。
  按**文件名**定位，别按行号。
- **`--startuptime` 是「追加写」，不是覆盖。** 同一个文件名跑第二次，文件里会有两份
  记录，`grep -m1` 读到的是**上一次**的值 —— 于是所有计时看起来一模一样、还特别稳定。
  每次测量用唯一文件名（带时间戳），这是本仓库踩过的坑。
- **TUI 模式下 `--startuptime` 里有两条 `--- NVIM STARTED ---`**（第一条来自早期阶段）。
  取最后一条：`grep -- '--- NVIM STARTED ---' f | tail -1`。
- **懒加载后的插件要测「按下去真的会加载」**：headless 下 `nvim_feedkeys` 不可信，
  但可以取映射里的回调直接调 —— `vim.fn.maparg("<Space>ff", "n", false, true).callback()`，
  然后断言 `require("lazy.core.config").plugins["telescope.nvim"]._.loaded ~= nil`。
- **测脚本一定要以 `-c 'qa!'` 收尾**：脚本中途报错时进程会挂到超时（本仓库踩过两次）。
  稳妥写法：整段 `pcall` + 结果先 `flush` 到文件，命令行再加 `-c 'qa!'` 兜底。

---

## 7. 已知陷阱清单

踩过一次的，别再踩第二次。

| # | 陷阱 | 正确做法 |
|---|---|---|
| 1 | **`vim.b[bufnr]` 的嵌套写入静默丢失**。每次访问返回新副本（`rawequal` 为 false），`vim.b[b].t[k]=v` 直接无效 | 用模块级 Lua 表存状态 |
| 2 | `nvim_set_hl` 是替换不是合并 | 读出→改→写回 |
| 3 | 逐行可视模式的 `mode()` 返回**大写 `"V"`** | 判断 `"v"`/`"V"`/`"\22"` 三种 |
| 4 | Lua 回调形式的可视模式映射**不会**自动退出可视模式 | 回调里 `nvim_feedkeys(<Esc>)` |
| 5 | `oil.get_entry_on_line` 越界报错（`strict_indexing`） | 用 `nvim_buf_line_count` 定界 |
| 6 | oil 缓冲区首行是 `..` | 按 `entry.name == ".."` 排除 |
| 7 | `oil.get_current_dir` 带尾斜杠且解析了符号链接 | 直接 `dir .. name`，别再加 `/` |
| 8 | `jobstart(..., { detach = true, on_exit = ... })` 的 `on_exit` **永不触发** | 不要 `detach` |
| 9 | blink `menu.enabled = false` 会连带废掉 ghost text | 用 `menu.auto_show` |
| 10 | `dictionary/` 多文件直接拼接，不去重 | 新增词条前 `grep -x` 查重 |
| 11 | Ghostty 配置**不支持行内注释**，`palette = 1=#x  # 说明` 整行会被静默丢弃 | 说明写在独立的注释行 |
| 12 | macOS `ps -o comm=` 会截断到 16 字符（`/usr/bin/osascri`） | 用 `-o ucomm=` |
| 13 | macOS 没有 `cat -n -v`、没有 `timeout`、`ls` 没有 `--time-style` | 用 `ls -lT` |
| 14 | `--remote-send` 里 `'\r'` 不是回车 | 写 `<CR>` |
| 15 | `nvim_input` / `feedkeys` 在 headless 下不能可靠驱动映射 | 用 pty + `--listen` |
| 16 | 主题里 `p.X or p.Y` 会掩盖漏定义的键 | 改完主题跑未定义键扫描 |
| 17 | **把 dired 的单字母键位照搬进 oil 缓冲区**。dired 缓冲区不是文本编辑缓冲区，oil 的缓冲区**就是**操作模型本身。实测后果：`u` 夺走后无法撤销（只能 `:undo`）、`Z` 夺走后 `ZZ` 保存退出失效（变成触发两次 Z）、`t/T/D/s/^/M` 夺走常用编辑与导航动作 | 全部挂 `<leader>` 前缀，第二段沿用 dired 字母（`<leader>M` = dired 的 `M`） |
| 18 | 把 `?` 绑成帮助键会夺走反向搜索 | 帮助只绑 `g?`；oil 帮助窗口会自动收录自定义键位，不需要额外快捷键 |
| 19 | 以为 `skip_confirm_for_simple_edits = true` 会让删除也不再确认。实测 oil 对**删除**仍弹 `DELETE xxx [Y]es/[N]o`，`:w` 后必须按 `y`，否则看起来像「`:w` 没生效」 | `<leader>d` 暂存后 `:w`，再按 `y` 确认；改名不需要确认 |
| 20 | 把 leader（`<space>`）本身也映射成一个完整命令。副作用不只是 `timeoutlen` 延迟——which-key 的 `Triggers.add` 会先跑 `is_mapped()`，**该键已被映射就不注册触发器**，导致提示面板永远弹不出来 | leader 键不要另作他用；本仓库已移除 `map("n", "<space>", ":")` |
| 21 | `blink-cmp-dictionary` 内部用 `items[match] = {...}` 建字典、再 `vim.tbl_values()` 取出，**候选项顺序在这一步被销毁**。所以任何依赖「provider 返回顺序」的排序方案都会在 blink 层失效。实测：fzf 返回的顺序完全正确，但 blink 显示的是 `physicianless`/`importunate` 这类生僻词 | 用插件的 `separate_output`（有序）记录排名，经 `data.documentation` 透传，在 `transform_items` 里写成 `sortText`，并把 `fuzzy.sorts` 改成 `{ 'sort_text', 'score' }` |
| 22 | **`mason-lspconfig` v2 里 `handlers` / `automatic_installation` 是死配置**（v1 遗留）。实测读 `mason-lspconfig/settings.lua`：v2 只认 `ensure_installed` 和 `automatic_enable`，那个 `handlers` 函数从来没被调用过 | 要「装好的服务器自动启用」用 `automatic_enable`；本仓库改成 `automatic_enable = false`，启用清单只在 `lua/plugins/lspconfig.lua` 的 `enabled` 列表里写一处 |
| 23 | **`mason.setup()` 会把自己的 bin 目录**prepend** 进 PATH**，而 LSP 服务器是靠 PATH 找到 `lua-language-server` 的。把 mason 挪到 `VeryLazy` 之后，`nvim foo.py` 读文件、起服务器都早于 mason 加载 → 找不到可执行文件、静默不附着 | 用 `platform.prepend_path(stdpath("data")/mason/bin)` 在启动期先补上（`lspconfig.lua` 顶部），mason 之后重复插一次无害（幂等） |
| 24 | **插件改成懒加载后，原来写在它 `config` 里的全局副作用会一起消失**。实测：`vim.g.loaded_netrw = 1` 原本写在 nvim-tree 的 config 里，nvim-tree 变懒后那两行不再保证执行，netrw 会和 oil 抢目录缓冲区 | 全局开关搬到 `init.lua`（第 2 节），注释说明为什么放那里 |
| 25 | **lazy spec 里的 `opt = {}`、`priority = 1000 + lazy = false` 这类写法**：`opt` 不是 lazy 的字段（应为 `opts`，或直接删）；`priority` 只决定「加载顺序」，不会让插件变懒，所以四个备选主题以前都在启动期加载 | 只留必要字段；备选主题全部 `lazy = true`（用前 `:Lazy load <名字>`） |
| 26 | **`cond = false` 的插件会从 lazy 里整个消失**（`require("lazy.core.config").plugins[name]` 变成 nil）。测 image.nvim 的终端能力判断时，脚本直接索引 nil 报错、又因为没写 `-c 'qa!'` 挂在超时 | 读 spec 前先判空；这也是 `cond` 的正常语义（该插件在这台机器上不存在） |
| 27 | 想靠「窗口局部选项」的 `vim.opt` 与 `vim.wo` 区分行为 —— 实测两者对 `number` 落到同一处（都只改当前窗口），从终端窗口分屏出来仍然没行号。**别把 `vim.opt` 当成「改全局」的证据**，也别据此写"修好了一个 bug" | 用 `vim.wo` 表达意图即可；要判断真实行为就实测（第 6 节），别推理 |
| 28 | **按扩展名猜 filetype 会猜错**（写 `:SayHello` 这种按类型分发的东西时最容易踩）。实测：`.tex` → `plaintex`（不是 `tex`）、`.cs` → `cs`（不是 `csharp`）、空的 `.bashrc` → `sh`（shell 文件的类型按**内容里的 shebang** 判，空文件没有 shebang 就退化成 sh） | 用 `vim.bo.filetype` 的实际值当键名，别用语言名；两者不一致时用别名表（见 `lua/config/hello.lua` 的 `M.aliases`） |
| 29 | **`setqflist` / `getqflist` 解析一批行的两个坑**（`:Run` 的 quickfix 用到了，都实测过）：① 文档推荐的「不改 'errorformat' 就解析」写法 `getqflist({efm=…, lines=…})` 在 0.12.6 上**连文档自带例子都返回 0 条**，不可用；② 能用的 `setqflist({}, ' ', {efm=…, lines=…})` 会把**匹配不上的行也塞成 `valid=0` 的条目**，于是 `echo hello` 这种纯文本输出会被数成「有 N 条错误」 | 用 `setqflist(...)` 解析后**只保留 `valid == 1` 的条目**，再用 `setqflist({}, ' ', {items = …})` 写回（见 `lua/config/run.lua`） |
| 30 | **别让 `errorformat` 去解析相对路径**：`setqflist` 的 `lines` 解析用的是 **nvim 的工作目录**，而 `:Run` 是在**文件所在目录**里跑命令的（Emacs 的 `M-!` 也这样）—— 实测把 `cwd` 键传进去对解析**无效**，于是 `main.c:3:7:` 会跳到 nvim 工作目录下的同名文件 | 自己按行认位置并按本次运行的目录拼绝对路径（`config/run.lua` 的 `split_location` / `resolve_path`） |
| 31 | **缓冲区名字非空 ≠ 它是文件**：输出缓冲区叫 `[Run]`，`fnamemodify(name, ":p:h")` 会把它算成「nvim 工作目录」而不是报错 —— 于是「焦点在输出窗口时再 `:Run`」就悄悄用了错的目录 | 判目录前先看 `buftype == ""`（只认真正的文件缓冲区）；另外把源缓冲区号记下来，焦点在输出窗口时回退到它的目录 |
| 32 | **又差点抄了一遍内置映射**：想给 quickfix 加 `]q`/`[q`，实测 Neovim 0.12 在 `_core/defaults.lua` 里**已经内置了**（`]q`/`[q` = `:cnext`/`:cprev`，还有 `[Q`/`]Q`、`[<C-Q>` 等一整套 vim-unimpaired 风格） | 加键位前先 `:verbose map ]q` 或读 `runtime/lua/vim/_core/defaults.lua`，别照抄自己以为的默认值（同第 10 节「只写与默认不同的选项」） |

---

## 8. 备份与回滚

以下目录都是 git 仓库，改动前建议先确认工作区状态：

```bash
git -C ~/.config/nvim status
git -C ~/.config/nvim diff
git -C ~/.config/nvim checkout .          # 丢弃全部未提交改动
```

- `~/.config/nvim` → `git@github.com:NeoWangKing/nwvim.git`
- `~/.config/yazi` → `git@github.com:NeoWangKing/neo-yazi.git`
- `~/.config/zed` → `git@github.com:NeoWangKing/zed-config`
- `~/.config/ghostty` → 本地 git 仓库，**无 remote**

另有一些一次性备份：`~/.config/starship.toml.bak-*`、`~/.zshrc.bak-*`、
`~/.config/zed/settings.json.bak-*`。

已删除但可恢复：`lua/plugins/lsp.lua` → `git show HEAD:lua/plugins/lsp.lua`

> 别再往下写死「当前未提交清单」—— 这种清单必然会过期（曾经就过期过一轮，
> 让人以为 `colors/`、`dictionary/` 还是未跟踪文件）。要判断状态直接 `git status`。

---

## 9. 待办 / 已知欠债

- `~/.config/yazi/yazi.toml` 里的 opener 仍硬编码 macOS
  （`open -a skim` / `open %s`），未走平台抽象。
- `lua/plugins/image.lua` 的 `backend = "kitty"` + `processor = "magick_cli"` 仍是硬编码，
  现在只加了 `cond`（终端不支持图形协议就不加载）。要换后端（如 ueberzug）得改这里。
- 三端只在 Linux 上实测过。Windows(WSL) 那边的三处平台差异（剪贴板、`Viewers`、
  文件属性三件套）是按 uv API 写的，**还没在真机验过**；换到 Windows 时优先看这几个。
- `:checkhealth` 已跑过 `lazy` / `vim.treesitter`（均 ✅）；`vim.lsp` / `mason` 在
  无写权限的沙箱里跑不了（mason 会 EPERM），换机器时建议手动跑一次。

### `:checkhealth` 现状（2026-10-15 全量跑过一次）

> **插件更新后要复核什么**（2026-10-15 做过一次全量 `:Lazy update`，20 个插件有更新）：
>
> 1. `build = ":TSUpdate"` 会跟着更新自动跑。**nvim-treesitter 的 `!` 提交是「parser 与
>    queries 一起升级」，必须重编**；证据看 `stdpath("data")/site/parser/*.so` 的 mtime。
>    这次 22 个 parser 全部重编且加载无 ABI 报错。
> 2. 复核用 §6 那套：headless 载入 + 选项/键位 dump diff + oil dired 三件套 +
>    markdown/LaTeX + `vim.lsp._enabled_configs`（或 `vim.lsp.is_enabled(name)`）看启用清单。
> 3. 最脆的三处，升级后优先验：
>    - **blink.cmp / blink-cmp-dictionary**：引擎或词典源一动，`separate_output` →
>       `sortText` → `fuzzy.sorts` 这条链子就可能失效，表现为「虚影候选全是生僻词」。
>       （2026-10-15 这两个正好没更新。）
>    - **mini.ai**：`feat(ai)!: use mode based default reference region` 改了
>      **可视模式**下文本对象的搜索范围（普通/操作模式不受影响）。
>    - **mason-lspconfig**：只认 `ensure_installed` / `automatic_enable`。升级后回读
>      `mason-lspconfig/settings.lua` 确认键名没变，否则 `automatic_enable = false` 会静默失效。

除了下面这些，其余全绿（`lazy` / `lspconfig` / `mason-lspconfig` / `noice` /
`nvim-treesitter` / `vim.lsp` / `vim.pack` / `vim.treesitter` / `vim.health` 都是 ✅）：

| 项 | 状态 | 说明 |
|---|---|---|
| `vim.provider` Node | 已处理 | 全局 npm 包 `neovim` 版本落后会一直警告；本配置没有任何 node 远程插件，已在 init.lua 里 `loaded_node_provider = 0` |
| `mason` 版本警告 | 待更新 | 锁的是 v2.2.1，上游 v2.3.1，`:Lazy update mason.nvim` 即可 |
| `mason` 的 luarocks / Ruby / Composer / julia | 无需处理 | 都是「某些包需要这些工具链」的可选提示；`ensure_installed` 里没有需要它们的服务器 |
| `vim.deprecated` | 改不了 | noice.nvim 内部用了已弃用的 `vim.str_utfindex`（`noice/view/backend/notify.lua`）。不是本仓库的代码，等上游修；`:Lazy update noice.nvim` 后复查 |
| `which-key` 的 11 条 overlap | 见下 | 7 条来自上游（nvim 内置 `gc`、nvim-surround 的 `ys`/`yS`、内置文本对象 `an`/`in` + mini.ai），与配置无关；4 条是本仓库的 |

本仓库自己的 4 条 overlap（都是「前缀本身也是映射」，代价是按下前缀后要等
`timeoutlen` = 300ms 才出结果，功能都正常）：

```
<leader>e   文件树      vs  <leader>en / <leader>ep / <leader>ee(诊断)
<leader>f   LSP 格式化  vs  <leader>ff / fg / fb / fh（telescope）
<leader>bc  关闭 buffer vs  <leader>bch / <leader>bcl
```

原来还有第 4 条 `gr`（引用）与内置 `grn`/`gra`/`grr`/`gri`/`grt` 重叠 —— 那条已经处理掉了：
**援引内置**，删掉本仓库的 `gr` / `<leader>rn` / `<leader>ca`。内置那套是全局无条件设置的
（不依赖 LspAttach，见 `runtime/lua/vim/_core/defaults.lua`），而 `gd` / `K` 内置没有、
仍由 `config/keymaps.lua` 提供。以后想再动这类按键，先问清楚（第 7 节陷阱 20 的同类判断）。

---

## 10. 启动路径与懒加载（加插件前的首要判断）

### 现状（实测：同一台机器上 A/B 交替跑 24 轮，取中位数）

| | 无参数启动 | 带文件启动（`nvim x.py`） |
|---|---|---|
| 懒加载改造前 | 67.3 ms | 67.6 ms |
| 现在 | 49.2 ms | 49.9 ms |
| 变化 | **-27%** | **-26%**（另两轮独立测量为 -25% / -27%） |

省下来的时间全部来自「把不需要在启动期存在的插件挪出去」：启动期加载的插件从
**25 个降到 13 个**。功能没少（都验证过按下去会加载），只是没在启动时付钱。
绝对值和机器负载关系很大（同一份配置在不同轮次能差 40ms），**只看同一轮里的比例**。

### 必须启动期加载的（`lazy = false`，别改成懒加载）

| 插件 | 为什么 |
|---|---|
| `blink.cmp` | 要在任何 LSP 服务器启动前把能力集合并进去（`lspconfig.lua` 取它的 `get_lsp_capabilities()`） |
| `nvim-lspconfig` | 同上：`vim.lsp.config("*", {...})` 必须早于服务器启动 |
| `nvim-treesitter` | 高亮依赖它的 filetype → parser 映射（`plugin/filetypes.lua`） |
| `oil.nvim` | 目录缓冲区的接管者（`vim .` / `:e src/` 要立刻生效） |
| `bufferline` / `lualine` / `indent-blankline` | 界面常驻，没有更晚的加载时机 |
| `mini.nvim` | 只 setup 一个 `mini.ai`，代价很小 |

### 已懒加载的（以及触发方式）

| 插件 | 触发 |
|---|---|
| 4 个备选主题 | `lazy = true`；换主题前 `:Lazy load <名字>` |
| `telescope.nvim`（连带 plenary / fzf-native） | `cmd = "Telescope"`；键位在 keymaps.lua 写成 `<cmd>Telescope find_files<CR>` |
| `nvim-tree` | `cmd = { "NvimTreeToggle", … }`；键位在 keymaps.lua |
| `lazygit.nvim` | `cmd = "LazyGit"` |
| `ghostty.nvim` | `cond = is_mac`（只有 macOS 有意义） |
| `image.nvim` | `cond` = 终端支持 kitty 图形协议 |
| `mason` + `mason-lspconfig` | `event = "VeryLazy"` + `cmd = { "Mason", … }`；PATH 由 `platform.prepend_path` 兜住（陷阱 23） |
| `render-markdown` | `ft = "markdown"` |
| `noice` / `notify` / `which-key` / `surround` / `dashboard` / `autopairs` | `VeryLazy` / `VimEnter` / `InsertEnter` |

### 加新插件时的判断顺序

1. 它是否必须在「打开第一个文件之前」就绪（能力集、目录接管、常驻 UI）？是 → `lazy = false`。
2. 否则找自然触发点：能对到命令就 `cmd`，能对到文件类型就 `ft`，能对到按键就把键位
   写进 spec 的 `keys`，或写 `<cmd>…<CR>` 配 `cmd`。
3. 都没有，用 `event = "VeryLazy"`（启动之后、空闲时）。
4. 只在某个平台 / 某种终端才成立，加 `cond`（注意：`cond = false` 时插件会从 lazy 里消失）。

### 测量方法（**别只看一次结果**）

这台机器上单次启动的波动有 ±15 ms，**只测一次会得出相反的结论**。做法：

- 准备一份对照副本（`rsync` 到 /tmp），A/B 交替跑 12–20 轮；
- 取中位数和最小值，不看某一次；
- `--startuptime` 每次换唯一文件名（追加写，见 6.4）；TUI 模式取最后一条 `NVIM STARTED`。

---

## 11. 系统层面的背景（供参考）

- macOS 27.0，Apple A18 Pro，6 核 / 8 GB RAM，主机 `NeoMac.local`
- 完整系统基线快照在 `~/SYSTEM-BASELINE.md`
- 已知未处理项：**Time Machine 未配置**、应用防火墙未配置、
  Homebrew 有 7 个过期包、`~/.zprofile` 里 `brew shellenv` 重复、
  UURemote 系统守护进程存在
