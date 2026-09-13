-- lua/config/options.lua

vim.g.have_nerd_font = true
vim.opt.termguicolors = true

-- 行号 / 光标 / 滚动
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 10

-- 缩进（默认 2 空格）
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true

-- 搜索
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- 界面
vim.opt.showmatch = true
vim.opt.cmdheight = 1
vim.opt.completeopt = "menuone,noinsert,noselect"
vim.opt.showmode = false
vim.opt.pumheight = 10
vim.opt.pumblend = 10
vim.opt.winblend = 0
vim.opt.conceallevel = 0
vim.opt.concealcursor = ""
vim.opt.lazyredraw = false -- 保持默认：永久开启会与 noice.nvim 冲突
vim.opt.synmaxcol = 300
vim.opt.fillchars = { eob = " " }

-- 撤销与交换文件
local undodir = vim.fn.stdpath("state") .. "/undodir"
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end
vim.opt.undodir = undodir
vim.opt.undofile = true
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false

-- 性能/响应
vim.opt.updatetime = 300
vim.opt.timeoutlen = 300
vim.opt.ttimeoutlen = 50
vim.opt.redrawtime = 1000
vim.opt.maxmempattern = 1000

-- 编辑行为
vim.opt.autoread = true
vim.opt.autowrite = false
vim.opt.hidden = true
vim.opt.errorbells = false
vim.opt.backspace = "indent,eol,start"
vim.opt.iskeyword:append("-")
vim.opt.path:append("**")
vim.opt.selection = "inclusive"
vim.opt.mouse = "a"
vim.opt.mousemodel = "popup"
vim.opt.clipboard:append("unnamedplus")
vim.opt.whichwrap:append("<>,h,l")

-- 拆分窗口
vim.opt.splitbelow = true
vim.opt.splitright = true

-- 命令补全
vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"
vim.opt.wildignorecase = true

-- 差异模式
vim.opt.diffopt:append("linematch:60")

-- 折叠：使用 indent，简单且性能更好
-- 如需 Treesitter 折叠，需要在 lazy.nvim 加载插件之后再设置
-- vim.opt.foldmethod = "expr"
-- vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldmethod = "indent"
vim.opt.foldlevel = 99
