require('vim._core.ui2').enable({})

-- leader 必须在定义任何 <leader> 键位之前设置
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require('config.options')
require('config.keymaps')
require('config.autocmds')
require('config.commands')
-- markdown 里 LaTeX 公式的语法检查（纯 treesitter，无外部依赖）。
-- 加载时只是注册一个 FileType autocmd，几乎不占启动时间。
require('config.latex-check')
require('config.lazy')

-- 剪贴板统一由 config/options.lua 处理（那里带平台探测：Linux 缺 xclip/wl-copy
-- 时会自动跳过）。此处不要再无条件设置，否则会把那边的探测结果覆盖掉。

-- 让 .gp 文件被识别为 gnuplot 类型
vim.filetype.add({ extension = { gp = 'gnuplot' } })

-- vim.cmd.colorscheme("gruber-darker")
-- vim.cmd.colorscheme("tokyonight")
-- vim.cmd.colorscheme("catppuccin")
-- vim.cmd.colorscheme("gruvbox")

-- ═══════════════════════════════════════════════════════════════════════
--  透明背景（仅对终端有效）
--
--  ⚠ nvim_set_hl 是「整体替换」而不是合并。只传 { bg = "none" } 会把该组
--    原有的 fg / bold / italic 一并抹掉（StatusLine、FloatBorder、
--    TabLineSel、NormalFloat 等 20 个组都中过招）。所以这里先取出当前定义、
--    只清掉背景、再整体写回。
--
--  ⚠⚠ **执行时机比清哪些组更要紧。** 踩过的坑：
--    bufferline 在启动阶段就把它内部那份颜色表（hls.buffer_selected 等）
--    解析好了；图标高亮组 BufferLineDevIcon* 则是首次用到时**按需创建**，
--    并把 parent 的 bg 直接抄过去（bufferline/highlights.lua 的
--    set_icon_highlight：vim.tbl_extend("force", parent, {...})）。
--    所以只在 VimEnter 里清是**没用的**——那时 bufferline 早已把实底缓存下来，
--    之后再清它的组也不生效（实测：set 完立刻查仍是原值）。
--    现象就是「打开 markdown 后，标签栏里那个文件图标带着一块实色底」。
--
--    正确顺序：设置配色方案 → **同步**清一次透明 → 再广播一次 ColorScheme
--    让 bufferline 按「已经透明」的状态重新解析颜色。
--    下面的 autocmd 只是为后续真正的 ColorScheme 变化兜底。
-- ═══════════════════════════════════════════════════════════════════════

--- 清掉 UI 装饰类高亮组的实心底色，让终端壁纸透出来
---
--- 只清「界面装饰」这一层（状态栏、标签栏、浮窗、符号列、行号、光标行……）。
--- 内容类高亮（Pmenu、Diff*、Visual、搜索）**保留底色**——那些是有意为之的，
--- 清掉反而看不清。
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

  -- bufferline 会派生 60+ 个高亮组（BufferLineBackground / BufferLineBuffer /
  -- BufferLineNumbers / BufferLineError* / BufferLineDevIcon* ...），
  -- 手写容易漏、它升级后新增的组名也覆盖不到，所以动态匹配前缀。
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
  -- 立刻清一次：必须在 bufferline 解析颜色之前完成
  set_transparent()

  -- 再广播一次 ColorScheme：bufferline 收到后会 reset_icon_hl_cache()
  -- 并按当前（已透明的）高亮重新解析内部颜色表。
  -- 少了这一步，它在启动早期缓存的那份实底会一直用到下次换主题。
  pcall(vim.cmd, "doautocmd ColorScheme")

  -- 后续真正的换主题时兜底
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
