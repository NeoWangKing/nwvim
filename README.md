# nwvim

我的个人 Neovim 配置，基于 [lazy.nvim](https://github.com/folke/lazy.nvim) 管理插件，
**macOS / Linux / Windows 三端共用同一套配置**：平台差异全部收在 `lua/config/platform.lua`。

开箱即用：首次启动会自动安装 lazy.nvim、插件、Treesitter 解析器和 LSP 服务器（都需要网络；
解析器还需要 `make` 和 C 编译器）。大部分插件是懒加载的 —— 启动时只加载必要的那些，
其余在第一次真正用到时才加载。

> 此说明部分由 AI 参与编写，我尽量人工核查以防出现问题，不过难免出现纰漏，请见谅

## ✨ 特性

- **插件管理**：lazy.nvim，插件按功能拆分在 `lua/plugins/`，并通过 `lazy-lock.json` 锁定版本
- **主题**：自研 P3 Blue（`colors/p3-blue.lua`，与 Ghostty / yazi / Zed / Starship 共用同一套调色板）；
  `gruber-darker`、`tokyonight`、`catppuccin`、`gruvbox` 作为备选（懒加载，不占启动时间）
- **补全**：blink.cmp（`super-tab` 键位预设）+ friendly-snippets
- **写作**：散文文件不弹候选框，改成光标后的暗色虚影补全；37 万词的词表按词频排序
  （见 `dictionary/README.md`）；markdown 里的 LaTeX 公式有实时语法检查（不渲染，直接报在行内）
- **LSP**：mason 负责安装，启用清单写在 `lua/plugins/lspconfig.lua`（`lua_ls`、`clangd`、`pyright`、
  `astro`、`texlab`、`marksman`、`ts_ls`、`cssls`；装了 Julia 时额外启用 `julials`）
- **搜索**：Telescope（fzf-native）+ 自定义 multi-grep（`rg` 模式 + glob 过滤）
- **文件管理**：nvim-tree（浏览）+ oil.nvim（直接改目录，按 `-` 打开）。oil 上还补了一层
  dired 的标记 / 批量操作（chmod、touch、gzip、shell 命令），三端都可用
- **界面**：bufferline、lualine（bubbles 主题）、dashboard、noice + nvim-notify、indent-blankline、image.nvim
- **编辑体验**：Treesitter 高亮（Neovim 内置）+ `indent` 折叠、nvim-autopairs、nvim-surround、mini.ai
- **工具集成**：lazygit、ghostty、自适应分屏终端
- **LaTeX 支持**：`:Pdflatex` / `:Xelatex` / `:Lualatex` 异步编译，保存自动重编译，`:OpenPDF` 打开 PDF
- **终端透明背景**：仅在终端生效，Neovide 下保持不透明

## 📂 目录结构

```
.
├── init.lua                 # 入口（顺序：leader → 关内置功能 → 各模块 → lazy → 配色）
├── lazy-lock.json           # 插件版本锁定
├── colors/                  # 自研配色 p3-blue.lua
├── dictionary/              # 写作补全词库（英文 / 物理 / C 与计算机）
├── ftdetect/                # 文件类型识别（.gp → gnuplot、.opf → xml）
├── scripts/                 # 调色板自检脚本、词库重建脚本
└── lua/
    ├── config/              # 通用配置
    │   ├── options.lua      # 编辑器基础选项
    │   ├── keymaps.lua      # 快捷键（全局键位只写在这里）
    │   ├── autocmds.lua     # 自动命令
    │   ├── commands.lua     # 自定义命令（LaTeX、Run 等）
    │   ├── platform.lua     # ★ 跨平台抽象层（打开方式 / 剪贴板 / 文件属性 / PATH）
    │   ├── oil-dired.lua    # ★ oil 的 dired 层（标记 + 批量操作）
    │   ├── terminal.lua     # <leader>st 的自适应分屏终端
    │   ├── latex-check.lua  # markdown 里 LaTeX 公式的语法检查
    │   ├── lazy.lua         # lazy.nvim 引导
    │   └── telescope/       # 自定义 Telescope picker
    └── plugins/             # 各插件独立配置文件
```

## 🚀 安装

### 环境要求

- Neovim ≥ 0.11
- [Nerd Font](https://www.nerdfonts.com/)（图标显示）
- `git`、`ripgrep`（Telescope 的 live grep / multi-grep）
- `make` 和 C 编译器（编译 telescope-fzf-native；首次安装 Treesitter 解析器也要用）
- `fzf`：**建议装**。词典补全靠它做前缀过滤与词频排序；缺了会退回插件自带的模糊打分，
  表现为「候选顺序变差」（详见 `dictionary/README.md`）
- 可选：ImageMagick（image.nvim 渲染图片；该插件只在支持 kitty 图形协议的终端里加载）、
  LaTeX 发行版（texlab / `:Xelatex` 等命令）

### Linux / macOS

```bash
# 备份旧配置（如有）
mv ~/.config/nvim ~/.config/nvim.bak

git clone https://github.com/NeoWangKing/nwvim.git ~/.config/nvim
nvim
```

### Windows (PowerShell)

```powershell
git clone https://github.com/NeoWangKing/nwvim.git "$env:LOCALAPPDATA\nvim"
nvim
```

### 运行验证

首次启动会自动克隆 lazy.nvim 并安装所有插件；Mason 会自动安装 LSP 服务器；Treesitter 会把
本配置用到的解析器补齐（都是后台进行，首次要下不少东西）。请确保网络通畅（至少要能访问
GitHub），并给它几分钟。

然后可以运行命令：

```lua
:checkhealth
```

并根据输出结果自行判断并修复一些环境的具体问题。

## ⌨️ 常用快捷键

`<leader>` 为空格键。

| 按键 | 功能 |
| --- | --- |
| `jk` | 插入模式下返回 Normal 模式 |
| `<leader>;` | 进入命令行（替代直接按空格） |
| `<leader>ff` / `<leader>fg` | 查找文件 / 全文搜索 |
| `<leader>mg` | Multi Grep（用**两个空格**分隔关键词和 glob，如 `func  *.lua`） |
| `<leader>fb` / `<leader>fh` | 切换 buffer / 查找帮助 |
| `<leader>en` / `<leader>ep` | 打开配置目录 / 插件目录中的文件 |
| `<leader>e` | 切换 nvim-tree 文件树 |
| `-` | 打开 oil.nvim 文件管理器 |
| `<leader>m` / `<leader>d` / `<leader>M` / `<leader>T` / `<leader>Z` | oil 缓冲区里的 dired 操作：标记 / 暂存删除 / chmod / touch / gzip（按 `g?` 看全部，含 `<leader>!` 执行 shell 命令） |
| `<leader>gg` | 打开 LazyGit |
| `<leader>st` | 自适应分屏终端 |
| `<leader>sv` / `<leader>sh` | 垂直 / 水平分屏 |
| `<leader>bn` / `<leader>bp` | 上一个 / 下一个 buffer |
| `<leader>bc` / `<leader>bch` / `<leader>bcl` | 关闭 buffer（选择 / 左侧 / 右侧） |
| `gd` / `K` | LSP 定义 / 悬浮文档（内置没有这两个，由本配置提供） |
| `grn` / `gra` / `grr` | 重命名 / 代码操作 / 引用（Neovim 内置） |
| `gri` / `grt` / `gO` / `grx` | 实现 / 类型定义 / 文档符号 / 运行 codelens（同上，`gra` 在可视模式下也可用） |
| `<leader>ee` / `<leader>f` | 诊断详情 / 格式化 |
| `[d` / `]d` | 上一个 / 下一个诊断 |
| `<leader>td` / `<leader>tw` | 开关诊断 / 开关自动换行 |
| `<leader>mt` | 开关 markdown 渲染（行内渲染 / 看原文） |
| `<leader>gf` | 打开光标下的文件（支持 `file:line:col`） |
| `<A-j>` / `<A-k>` | 上移 / 下移当前行或选中块 |
| `<A-Up>` / `<A-Down>` / `<A-Left>` / `<A-Right>` | 调整分屏大小 |
| `<leader>re` | 重新加载 Neovim（`restart` 命令） |
| `]q` / `[q` | quickfix 下一条 / 上一条（Neovim 内置；`:Run` 解析出的报错位置就在这个列表里） |
| `<leader>x` / `<leader><leader>x` | 执行当前行 / 重新 source 当前文件 |

## 🎨 主题切换

默认主题是自研的 P3 Blue（`colors/p3-blue.lua`，不依赖任何插件），在 `init.lua` 里设置。
四个备选主题是**懒加载**的，切之前先把插件加载进来：

```lua
:Lazy load gruvbox     " gruber-darker / tokyonight / catppuccin / gruvbox
:colorscheme gruvbox   " 先试，满意了再改 init.lua 里那行
```

## 🛠 自定义命令

| 命令 | 说明 |
| --- | --- |
| `:OpenPDF [-skim\|-preview] [文件]` | 打开 PDF（macOS，默认 Skim） |
| `:Pdflatex [文件]` | 异步编译 LaTeX，保存时自动重编译 |
| `:Xelatex [文件]` | 同上，使用 XeLaTeX |
| `:Lualatex [文件]` | 同上，使用 LuaLaTeX |
| `:Run <命令>` | 异步执行命令，输出**实时**显示在底部独立窗口里（`q` 关掉）。报错位置会**着色**（文件名 / `:行:列` / 消息按 error·warning 分色，编译器给的 `^~~~` 标记也跟着变色），并解析进 quickfix：在该窗口里按 `<CR>` 跳到本行的出错处，`]q` / `[q` 逐条跳 |
| `:SayHello [语言]` | 在**空文件**里写入对应语言的 Hello, world! 模板，并在通知里给出该语言的**最小编译/运行命令**（语言按文件类型自动判断，认不出时可显式指定，如 `:SayHello python`） |

## 📝 其他细节

- 默认 2 空格缩进；C / C++ / Python / JSON 自动切换为 4 空格，Markdown 为 3 空格
- `.gp` 文件识别为 gnuplot，`.opf` 文件识别为 xml
- 粘贴 `p` / `P` 保持光标列；搜索跳转自动居中
- 终端窗口不显示行号（只影响那个窗口，不动全局设置）；背景透明仅对终端生效，Neovide 下不透明
- 折叠用 `indent`（比 treesitter 折叠快），高亮用 Neovim 内置的 treesitter
- 目录缓冲区交给 oil 接管，netrw 已在 `init.lua` 里关掉

## 🔄 更新

```bash
cd ~/.config/nvim
git pull
```

或在 Neovim 中执行 `:Lazy update` / `:Lazy sync` 更新插件。
