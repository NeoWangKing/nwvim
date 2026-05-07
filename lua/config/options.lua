-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- ============================================================================
-- 基本外观
-- ============================================================================
vim.g.have_nerd_font = true
vim.opt.termguicolors = true

-- 透明背景函数（原样保留）
local function set_transparent()
  local groups = {
    "Normal", "NormalNC", "EndOfBuffer", "NormalFloat",
    "FloatBorder", "SignColumn", "StatusLine", "StatusLineNC",
    "TabLine", "TabLineFill", "TabLineSel", "ColorColumn",
  }
  for _, g in ipairs(groups) do
    pcall(vim.api.nvim_set_hl, 0, g, { bg = "none" })
  end
  pcall(vim.api.nvim_set_hl, 0, "TabLineFill", { bg = "none", fg = "#767676" })
end

-- 仅在非 Neovide 环境（即终端）下启用透明
if not vim.g.neovide then
  set_transparent()
else
  vim.api.nvim_set_hl(0, "Normal", { bg = "#181818", fg = "#bbbbbb" })

  vim.api.nvim_set_hl(0, "NormalNC", { bg = "#181818" })
  vim.api.nvim_set_hl(0, "SignColumn", { bg = "#181818" })
  vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "#181818" })
  vim.api.nvim_set_hl(0, "StatusLine", { bg = "#2a2a2a", fg = "#c0c0c0" })
  vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "#1e1e1e", fg = "#808080" })
end

-- ============================================================================
-- Leader 键
-- ============================================================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ============================================================================
-- 行号 / 光标 / 滚动
-- ============================================================================
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.scrolloff = 10          -- 上下保留 10 行
vim.opt.sidescrolloff = 10      -- 左右保留 10 列

-- ============================================================================
-- 缩进（默认 2 空格，个别文件类型在 autocmds 中覆盖）
-- ============================================================================
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true        -- 用空格代替制表符
vim.opt.smartindent = true
vim.opt.autoindent = true

-- ============================================================================
-- 搜索
-- ============================================================================
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- ============================================================================
-- 界面细节
-- ============================================================================
vim.opt.showmatch = true        -- 高亮匹配的括号
vim.opt.cmdheight = 1
vim.opt.completeopt = "menuone,noinsert,noselect"
vim.opt.showmode = false        -- 不在命令行显示模式，交给状态栏
vim.opt.pumheight = 10          -- 补全菜单最大高度
vim.opt.pumblend = 10           -- 补全菜单透明度
vim.opt.winblend = 0            -- 浮动窗口透明度
vim.opt.conceallevel = 0        -- 不隐藏标记（方便 Markdown 编辑）
vim.opt.concealcursor = ""
vim.opt.lazyredraw = true       -- 执行宏时不重绘（提升性能）
vim.opt.synmaxcol = 300         -- 语法高亮最大列数，避免长行卡顿
vim.opt.fillchars = { eob = " " } -- 用空格代替行尾 ~

-- ============================================================================
-- 撤销与交换文件（使用 undofile 而非 swap）
-- ============================================================================
local undodir = vim.fn.stdpath("state") .. "/undodir" -- ~/.local/state/nvim/undodir
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end
vim.opt.undodir = undodir
vim.opt.undofile = true

-- 关闭备份与交换文件，避免 WSL 下跨文件系统造成干扰
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false

-- ============================================================================
-- 性能/响应
-- ============================================================================
vim.opt.updatetime = 300        -- 更快写入 swap（若开启）和 CursorHold 事件
vim.opt.timeoutlen = 500        -- 按键序列等待时间
vim.opt.ttimeoutlen = 50
vim.opt.redrawtime = 10000      -- 增加宏执行时的重绘容忍时间
vim.opt.maxmempattern = 20000   -- 增加模式匹配内存上限

-- ============================================================================
-- 编辑行为
-- ============================================================================
vim.opt.autoread = true         -- 文件在外部被修改时自动重读
vim.opt.autowrite = false
vim.opt.hidden = true           -- 允许切换未保存的缓冲区
vim.opt.errorbells = false      -- 关闭错误响铃
vim.opt.backspace = "indent,eol,start"
vim.opt.iskeyword:append("-")   -- 连字符视为单词的一部分
vim.opt.path:append("**")       -- :find 等命令递归搜索子目录
vim.opt.selection = "inclusive"
vim.opt.mouse = "a"             -- 启用鼠标
vim.opt.mousemodel = "popup"

-- 系统剪贴板（WSL 下访问 Windows 剪贴板）
vim.opt.clipboard:append("unnamedplus")

-- 允许左右方向键在行首/行尾跨行
vim.opt.whichwrap:append("<>,h,l")

-- ============================================================================
-- 拆分窗口
-- ============================================================================
vim.opt.splitbelow = true
vim.opt.splitright = true

-- ============================================================================
-- 命令补全
-- ============================================================================
vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"
vim.opt.wildignorecase = true

-- ============================================================================
-- 差异模式优化
-- ============================================================================
vim.opt.diffopt:append("linematch:60")

-- ============================================================================
-- 折叠（Treesitter 可用时才启用 expr 折叠，否则安全回退）
-- ============================================================================
local has_ts, _ = pcall(require, "nvim-treesitter")
if has_ts then
  vim.opt.foldmethod = "expr"
  vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
else
  vim.opt.foldmethod = "indent" -- 安全的备选方案
end
vim.opt.foldlevel = 99

