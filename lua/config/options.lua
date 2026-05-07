-- lua/config/options.lua
-- 通用 Vim/Neovim 选项，包含终端透明处理

vim.g.have_nerd_font = true
vim.opt.termguicolors = true

-- 透明背景（仅对终端有效）
local function set_transparent()
  local groups = {
    "Normal", "NormalNC", "EndOfBuffer", "NormalFloat",
    "FloatBorder", "SignColumn", "StatusLine", "StatusLineNC",
    "TabLine", "TabLineFill", "TabLineSel", "ColorColumn",
    "CursorLine",
  }
  for _, g in ipairs(groups) do
    pcall(vim.api.nvim_set_hl, 0, g, { bg = "none" })
  end
  pcall(vim.api.nvim_set_hl, 0, "TabLineFill", { bg = "none", fg = "#767676" })
end

-- if not vim.g.neovide then
--   set_transparent()
-- end

-- 确保在非 Neovide 环境下透明
if not vim.g.neovide then
  -- 当颜色主题改变时重新应用透明
  vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = set_transparent,
  })
  -- 启动完成后也应用一次，防止主题加载滞后
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      if not vim.g.neovide then
        vim.defer_fn(set_transparent, 0) -- 稍微延迟，确保主题已加载
      end
    end,
  })
end

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
vim.opt.lazyredraw = true
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
vim.opt.timeoutlen = 500
vim.opt.ttimeoutlen = 50
vim.opt.redrawtime = 10000
vim.opt.maxmempattern = 20000

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

-- 折叠（优先使用 Treesitter，否则用 indent）
local has_ts, _ = pcall(require, "nvim-treesitter")
if has_ts then
  vim.opt.foldmethod = "expr"
  vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
else
  vim.opt.foldmethod = "indent"
end
vim.opt.foldlevel = 99
