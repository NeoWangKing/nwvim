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
init.lua                 启动入口：装载各模块、设定配色、透明背景、启用 LSP
colors/p3-blue.lua       自研配色方案（调色板 + 高亮组映射）
dictionary/              拼写补全词库（英文 / 物理 / C 与计算机）
scripts/                 仓库自检脚本（见第 2 节）
lua/config/
  options.lua            编辑器选项（含剪贴板平台探测）
  keymaps.lua            全局键位 + LSP 键位（LspAttach 集中在一处）
  autocmds.lua           自动命令
  commands.lua           自定义命令（:OpenPDF :OpenImage :Run :Xelatex …）
  lazy.lua               lazy.nvim 引导（含 git 协议探测）
  platform.lua           ★ 跨平台抽象层，三端兼容的核心
  oil-dired.lua          ★ oil.nvim 的 dired 行为扩展层
  telescope/             Telescope 相关拆分配置
lua/plugins/*.lua        每个插件一个文件，按功能命名
```

### 改配置时的约定

- **一个插件一个文件**，文件名与用途对应，不要塞进大杂烩。
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
| 平台判定 | `is_mac` / `is_linux` / `is_windows` / `is_wsl` / `pathsep` |
| 打开方式 | `open_path` / `open_with_app` / `supports_app_named_open` / `has_exe` |
| 外部程序 | `VIEWERS`（表）/ `pick_viewer(kind)` / `open_with_viewer` |
| 剪贴板 | `clipboard_available` |
| 执行 | `run_capture(cmd, opts)` |
| Git | `detect_git_protocol` / `git_url_format` |
| 词库 | `dictionary_dirs` |

### 各平台默认外部程序

- **PDF**：macOS → Skim / Preview；Linux → **evince**（首选）、zathura、mupdf、
  llpp、okular、xpdf；Windows → SumatraPDF、Edge
- **图片**：macOS → Preview；Linux → **feh**、nsxiv、sxiv、imv、qiv、eog；
  Windows → nomacs、mspaint

`git_url_format()` 会探测 `git@github.com` 是否可用，不可用时返回 `nil`；
`config/lazy.lua` 只在非 nil 时才设置 `lazy_opts.git.url_format`——
**不要无条件设置**，否则 https 环境会拉不到插件。

---

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
| `<leader>M` | chmod | `M` |
| `<leader>T` | touch | `T` |
| `<leader>Z` | `gzip -k` 压缩（保留原文件） | `Z` |
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

### 当前未提交 / 未跟踪

```
 M init.lua                         M lua/plugins/blink.lua
 M lazy-lock.json                   M lua/plugins/bufferline.lua
 M lua/config/commands.lua          D lua/plugins/lsp.lua
 M lua/config/keymaps.lua           M lua/plugins/lspconfig.lua
 M lua/config/lazy.lua              M lua/plugins/lualine.lua
 M lua/config/options.lua           M lua/plugins/oil-nvim.lua
?? AGENT.md  ?? colors/  ?? dictionary/  ?? scripts/
?? lua/config/oil-dired.lua  ?? lua/config/platform.lua
```

---

## 9. 待办 / 已知欠债

- **README.md 第 10 行已过期**：写着「默认 `catppuccin`」，实际是 `p3-blue`。
- `~/.config/yazi/yazi.toml` 里的 opener 仍硬编码 macOS
  （`open -a skim` / `open %s`），未走平台抽象。
- `lua/plugins/image.lua` 硬编码 `backend = "kitty"` + `processor = "magick_cli"`，
  是终端相关的，换终端可能失效。
- `colors/p3-blue.lua` 有 3 个未被引用的调色板键：`bg_hover`、`blue_br`、`teal`。
- `:checkhealth` 未系统跑过。

---

## 10. 系统层面的背景（供参考）

- macOS 27.0，Apple A18 Pro，6 核 / 8 GB RAM，主机 `NeoMac.local`
- 完整系统基线快照在 `~/SYSTEM-BASELINE.md`
- 已知未处理项：**Time Machine 未配置**、应用防火墙未配置、
  Homebrew 有 7 个过期包、`~/.zprofile` 里 `brew shellenv` 重复、
  UURemote 系统守护进程存在
