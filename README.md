# nwvim

我的个人 Neovim 配置，基于 [lazy.nvim](https://github.com/folke/lazy.nvim) 管理插件，开箱即用：首次启动会自动安装 lazy.nvim、全部插件、Treesitter 解析器和 LSP 服务器。

## ✨ 特性

- **插件管理**：lazy.nvim，插件按功能拆分在 `lua/plugins/`，并通过 `lazy-lock.json` 锁定版本
- **主题**：默认 `catppuccin`，内置 `gruber-darker`、`tokyonight`、`gruvbox` 备选
- **补全**：blink.cmp（`super-tab` 键位预设）+ friendly-snippets
- **LSP**：mason 自动安装/启用 `lua_ls`、`clangd`、`pyright`、`astro`、`texlab`、`marksman`、`ts_ls`、`cssls` 等服务器
- **搜索**：Telescope（fzf-native）+ 自定义 multi-grep（`rg` 模式 + glob 过滤）
- **文件管理**：nvim-tree + oil.nvim 双文件管理器
- **界面**：bufferline、lualine（bubbles 主题）、dashboard、noice + nvim-notify、indent-blankline、image.nvim
- **编辑体验**：Treesitter 高亮/折叠、nvim-autopairs、nvim-surround、mini.ai
- **工具集成**：lazygit、ghostty、自适应分屏终端
- **LaTeX 支持**：`:Pdflatex` / `:Xelatex` / `:Lualatex` 异步编译，保存自动重编译，`:OpenPDF` 打开 PDF
- **终端透明背景**：仅在终端生效，Neovide 下保持不透明

## 📂 目录结构

```
.
├── init.lua                 # 入口文件
├── lazy-lock.json           # 插件版本锁定
├── ftdetect/                # 文件类型识别（.opf → xml）
└── lua/
    ├── config/              # 通用配置
    │   ├── options.lua      # 编辑器基础选项
    │   ├── keymaps.lua      # 快捷键
    │   ├── autocmds.lua     # 自动命令
    │   ├── commands.lua     # 自定义命令（LaTeX、Run 等）
    │   ├── lazy.lua         # lazy.nvim 引导
    │   └── telescope/       # 自定义 Telescope picker
    └── plugins/             # 各插件独立配置文件
```

## 🚀 安装

### 环境要求

- Neovim ≥ 0.11
- [Nerd Font](https://www.nerdfonts.com/)（图标显示）
- `git`、`ripgrep`
- `make` 和 C 编译器（编译 telescope-fzf-native）
- 可选：ImageMagick（image.nvim 渲染图片）、LaTeX 发行版（texlab / LaTeX 命令）

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

首次启动会自动克隆 lazy.nvim 并安装所有插件，Mason 会自动安装 LSP 服务器，Treesitter 会自动安装解析器，请耐心等待。

## ⌨️ 常用快捷键

`<leader>` 为空格键。

| 按键 | 功能 |
| --- | --- |
| `jk` | 插入模式下返回 Normal 模式 |
| `<leader>ff` / `<leader>fg` | 查找文件 / 全文搜索 |
| `<leader>mg` | Multi Grep（用**两个空格**分隔关键词和 glob，如 `func  *.lua`） |
| `<leader>fb` / `<leader>fh` | 切换 buffer / 查找帮助 |
| `<leader>en` / `<leader>ep` | 打开配置目录 / 插件目录中的文件 |
| `<leader>e` | 切换 nvim-tree 文件树 |
| `-` | 打开 oil.nvim 文件管理器 |
| `<leader>gg` | 打开 LazyGit |
| `<leader>st` | 自适应分屏终端 |
| `<leader>sv` / `<leader>sh` | 垂直 / 水平分屏 |
| `<leader>bn` / `<leader>bp` | 上一个 / 下一个 buffer |
| `<leader>bc` / `<leader>bch` / `<leader>bcl` | 关闭 buffer（选择 / 左侧 / 右侧） |
| `gd` / `K` / `gr` | LSP 定义 / 悬浮文档 / 引用 |
| `<leader>rn` / `<leader>ca` | 重命名 / 代码操作 |
| `<leader>ee` / `<leader>f` | 诊断详情 / 格式化 |
| `[d` / `]d` | 上一个 / 下一个诊断 |
| `<leader>td` / `<leader>tw` | 开关诊断 / 开关自动换行 |
| `<leader>gf` | 打开光标下的文件（支持 `file:line:col`） |
| `<A-j>` / `<A-k>` | 上移 / 下移当前行或选中块 |
| `<A-Up>` / `<A-Down>` / `<A-Left>` / `<A-Right>` | 调整分屏大小 |
| `<leader>re` | 重新加载 Neovim（`restart` 命令） |
| `<leader>x` / `<leader><leader>x` | 执行当前行 / 重新 source 当前文件 |

## 🎨 主题切换

默认主题在 `init.lua` 中设置，取消注释对应行即可切换：

```lua
-- vim.cmd.colorscheme("gruber-darker")
-- vim.cmd.colorscheme("tokyonight")
vim.cmd.colorscheme("catppuccin")
-- vim.cmd.colorscheme("gruvbox")
```

## 🛠 自定义命令

| 命令 | 说明 |
| --- | --- |
| `:OpenPDF [-skim\|-preview] [文件]` | 打开 PDF（macOS，默认 Skim） |
| `:Pdflatex [文件]` | 异步编译 LaTeX，保存时自动重编译 |
| `:Xelatex [文件]` | 同上，使用 XeLaTeX |
| `:Lualatex [文件]` | 同上，使用 LuaLaTeX |
| `:Run <命令>` | 异步执行命令，输出解析进 quickfix |

## 📝 其他细节

- 默认 2 空格缩进；C / C++ / Python / JSON 自动切换为 4 空格，Markdown 为 3 空格
- `.gp` 文件识别为 gnuplot，`.opf` 文件识别为 xml
- 粘贴 `p` / `P` 保持光标列；搜索跳转自动居中
- 终端自动关闭行号，背景透明仅对终端生效

## 🔄 更新

```bash
cd ~/.config/nvim
git pull
```

或在 Neovim 中执行 `:Lazy update` / `:Lazy sync` 更新插件。

## 🙏 致谢

感谢 Neovim 社区和所有用到的插件作者：lazy.nvim、blink.cmp、telescope.nvim、nvim-treesitter、mason.nvim、nvim-lspconfig、catppuccin、nvim-tree、oil.nvim、noice.nvim 等。
