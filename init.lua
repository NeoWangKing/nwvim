require('vim._core.ui2').enable({})

-- leader 必须在定义任何 <leader> 键位之前设置
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require('config.options')
require('config.keymaps')
require('config.autocmds')
require('config.commands')
require('config.lazy')

-- 剪贴板统一由 config/options.lua 处理（那里带平台探测：Linux 缺 xclip/wl-copy
-- 时会自动跳过）。此处不要再无条件设置，否则会把那边的探测结果覆盖掉。

-- 让 .gp 文件被识别为 gnuplot 类型
vim.filetype.add({ extension = { gp = 'gnuplot' } })

-- vim.cmd.colorscheme("gruber-darker")
-- vim.cmd.colorscheme("tokyonight")
-- vim.cmd.colorscheme("catppuccin")
-- vim.cmd.colorscheme("gruvbox")
vim.cmd.colorscheme("p3-blue")

-- 透明背景（仅对终端有效）
--
-- ⚠ 注意：nvim_set_hl 是「整体替换」而不是合并。原来的写法只传
--   { bg = "none" }，会把下面这些组原本的 fg / bold / italic 一并抹掉，
--   导致 StatusLine、FloatBorder、TabLineSel、NormalFloat 等丢失配色
--   （对任何配色方案都成立，不是某个主题的问题）。
--   改为：先取出当前定义，只清掉背景，再整体写回。
local function set_transparent()
  local groups = {
    "Normal", "NormalNC", "CursorLine",
    "StatusLine", "StatusLineNC", "EndOfBuffer",
    "NormalFloat", "FloatBorder", "SignColumn",
    "TabLine", "TabLineFill", "TabLineSel", "ColorColumn",
    "NvimTreeWinSeparator", "NvimTreeNormal", "NvimTreeNormalNC", "NvimTreeEndOfBuffer",
    "NvimTreeCursorLine", "NvimTreeSignColumn", "NvimTreeStatusLine",
    "BufferLineFill",
  }

  -- 顶部标签栏（bufferline）整体透明。
  -- bufferline 一共派生 60+ 个高亮组（BufferLineBackground / BufferLineBuffer /
  -- BufferLineNumbers / BufferLineError* / BufferLineOffsetSeparator ...），
  -- 手写容易漏、它升级后新增的组名也覆盖不到，所以这里动态匹配前缀。
  -- 注意：bufferline 在 ColorScheme 时会重新派生整套颜色，而本函数注册得比它晚，
  -- 因此能盖住它的实心底色。
  local ok, all = pcall(vim.api.nvim_get_hl, 0, {})
  if ok then
    for name in pairs(all) do
      if name:match("^BufferLine") then groups[#groups + 1] = name end
    end
  end

  for _, g in ipairs(groups) do
    local ok2, cur = pcall(vim.api.nvim_get_hl, 0, { name = g, link = false })
    if ok2 and type(cur) == "table" and not vim.tbl_isempty(cur) then
      cur.bg = nil
      cur.cterm = nil
      cur.ctermbg = nil
      pcall(vim.api.nvim_set_hl, 0, g, cur)
    end
  end
end

if not vim.g.neovide then
  vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = set_transparent,
  })
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      if not vim.g.neovide then
        vim.defer_fn(set_transparent, 0)
      end
    end,
  })
end

vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

vim.lsp.config("julials", { settings = {} })
vim.lsp.enable("julials")
vim.lsp.enable('astro')
vim.lsp.enable('clangd')
vim.lsp.enable('cssls')
vim.lsp.enable('lua_ls')
vim.lsp.enable('marksman')
vim.lsp.enable('pyright')
vim.lsp.enable('texlab')
vim.lsp.enable('ts_ls')
