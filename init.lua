require('vim._core.ui2').enable({})

-- leader 必须在定义任何 <leader> 键位之前设置
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require('config.options')
require('config.keymaps')
require('config.autocmds')
require('config.commands')
-- markdown 里 LaTeX 公式的语法检查，只注册 FileType autocmd，不占启动时间。
require('config.latex-check')
require('config.lazy')

-- 剪贴板统一由 config/options.lua 按平台探测处理，这里不要再无条件设置。

-- 让 .gp 文件被识别为 gnuplot 类型
vim.filetype.add({ extension = { gp = 'gnuplot' } })

-- vim.cmd.colorscheme("gruber-darker")
-- vim.cmd.colorscheme("tokyonight")
-- vim.cmd.colorscheme("catppuccin")
-- vim.cmd.colorscheme("gruvbox")

-- 透明背景：清掉 UI 装饰组的实心底色，让终端壁纸透出来。
-- nvim_set_hl 是整体替换：只传 { bg = "none" } 会抹掉该组原有的 fg/bold，先取出当前定义再写回。
-- 时机：必须在 bufferline 启动时解析颜色之前清一次，再广播 ColorScheme 让它按透明状态重建图标高亮。

-- 只清界面装饰层（状态栏、标签栏、浮窗、符号列等）；内容类高亮（Pmenu、Diff、Visual、搜索）保留底色。
local function set_transparent()
  local groups = {
    "Normal", "NormalNC", "CursorLine",
    "StatusLine", "StatusLineNC", "EndOfBuffer",
    "NormalFloat", "FloatBorder", "SignColumn",
    "TabLine", "TabLineFill", "TabLineSel", "ColorColumn",
    -- 光标行上的符号列 / 折叠列：漏了它们会在光标处出现一块实底方块
    "CursorLineSign", "CursorLineFold", "FoldColumn",
    "NvimTreeWinSeparator", "NvimTreeNormal", "NvimTreeNormalNC", "NvimTreeEndOfBuffer",
    "NvimTreeCursorLine", "NvimTreeSignColumn", "NvimTreeStatusLine",
    "BufferLineFill",
  }

  -- bufferline 的 60+ 高亮组按前缀动态匹配，手写会漏掉新增的组。
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

vim.cmd.colorscheme("p3-blue")

if not vim.g.neovide then
  -- 先同步清一次：必须赶在 bufferline 解析颜色之前
  set_transparent()

  -- 再广播 ColorScheme，让 bufferline 按透明状态重建图标高亮；否则它缓存的实底会一直用到下次换主题。
  pcall(vim.cmd, "doautocmd ColorScheme")

  -- 之后换主题时兜底
  vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = set_transparent,
  })
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      vim.defer_fn(set_transparent, 0)
    end,
  })
end

vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

vim.lsp.config("julials", { settings = {} })
-- Julia 未安装的平台（如当前 Linux）自动跳过，避免 vim.lsp 健康检查报警
if vim.fn.executable("julia") == 1 then
  vim.lsp.enable("julials")
end
vim.lsp.enable('astro')
vim.lsp.enable('clangd')
vim.lsp.enable('cssls')
vim.lsp.enable('lua_ls')
vim.lsp.enable('marksman')
vim.lsp.enable('pyright')
vim.lsp.enable('texlab')
vim.lsp.enable('ts_ls')
