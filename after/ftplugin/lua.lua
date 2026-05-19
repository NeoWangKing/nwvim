local set = vim.opt_local

set.shiftwidth = 2
set.number = true

-- 行号 / 光标 / 滚动
set.number = true
set.relativenumber = true
set.cursorline = true
set.scrolloff = 10
set.sidescrolloff = 10

-- 缩进（默认 2 空格）
set.tabstop = 2
set.shiftwidth = 2
set.softtabstop = 2
set.expandtab = true
set.smartindent = true
set.autoindent = true

-- 搜索
set.ignorecase = true
set.smartcase = true
set.hlsearch = true
set.incsearch = true

-- 界面
set.showmatch = true
set.cmdheight = 1
set.completeopt = "menuone,noinsert,noselect"
set.showmode = false
set.pumheight = 10
set.pumblend = 10
set.winblend = 0
set.conceallevel = 0
set.concealcursor = ""
set.lazyredraw = false
set.synmaxcol = 300
set.fillchars = { eob = " " }

-- 撤销与交换文件
local undodir = vim.fn.stdpath("state") .. "/undodir"
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end
set.undodir = undodir
set.undofile = true
set.backup = false
set.writebackup = false
set.swapfile = false

-- 性能/响应
set.updatetime = 300
set.timeoutlen = 500
set.ttimeoutlen = 50
set.redrawtime = 10000
set.maxmempattern = 20000

-- 编辑行为
set.autoread = true
set.autowrite = false
set.hidden = true
set.errorbells = false
set.backspace = "indent,eol,start"
set.iskeyword:append("-")
set.path:append("**")
set.selection = "inclusive"
set.mouse = "a"
set.mousemodel = "popup"
set.clipboard:append("unnamedplus")
set.whichwrap:append("<>,h,l")

-- 拆分窗口
set.splitbelow = true
set.splitright = true

-- 命令补全
set.wildmenu = true
set.wildmode = "longest:full,full"
set.wildignorecase = true

