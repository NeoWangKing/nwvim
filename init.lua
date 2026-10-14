-- init.lua - 启动入口。
-- 顺序有讲究：leader → 关掉用不到的内置功能 → 各模块 → 插件管理器 → 配色 / 透明背景。
-- 文件类型识别统一放 ftdetect/（.gp → gnuplot、.opf → xml）。

-- 不要启用 vim._core.ui2：那是私有的实验 API（消息 / 命令行渲染层），和 noice.nvim
-- 职责重叠，升级 Neovim 时可能无声无息地改变行为。真想试就取消下面这行注释，
-- 同时把 noice 的命令行弹窗关掉 —— 别让两套渲染层共存。
-- require('vim._core.ui2').enable({})

-- ── 1. leader：必须在定义任何 <leader> 键位之前设好 ──────────────────
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ── 2. 关掉用不到的内置功能 ────────────────────────────────────────
-- netrw：目录交给 oil（default_file_explorer）和 nvim-tree。
-- 必须在这里设：$VIMRUNTIME/plugin/netrwPlugin.vim 是在 init.lua 之后才被 source 的。
-- （这两个开关以前写在 nvim-tree 的 config 里，但 nvim-tree 现在是懒加载，那两行不再保证执行。）
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Perl / Python / Ruby / Node provider 都不用，关掉省得启动时探测。
-- Node 那条是看了 :checkhealth 之后加的：本配置没有任何 rplugin / denops 插件，
-- 而开着它会因为全局装的 `neovim` npm 包版本落后一直报一条警告。
-- 将来真要用 node 远程插件，删掉对应的那行即可。
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0

-- ── 3. 各模块（选项 → 键位 → autocmd → 命令 → 只注册 autocmd 的检查器）──
require('config.options')
require('config.keymaps')
require('config.autocmds')
require('config.commands')
-- markdown 里 LaTeX 公式的语法检查，只注册 FileType autocmd，不占启动时间。
require('config.latex-check')

-- ── 4. 插件管理器 ─────────────────────────────────────────────────
-- 剪贴板统一由 config/options.lua 按平台探测处理，这里不要再无条件设置。
require('config.lazy')

-- ── 5. 配色 + 透明背景 ────────────────────────────────────────────
-- 自研配色在上面这行之后由 colors/p3-blue.lua 载入；备选主题见 lua/plugins/theme.lua。
-- 换主题：把下面的名字改成 gruber-darker / tokyonight / catppuccin / gruvbox 之一，
-- 那四个是懒加载的，改完先 :Lazy load <名字> 再 :colorscheme <名字> 试。

-- 透明背景：清掉 UI 装饰组的实心底色，让终端壁纸透出来（Neovide 下保持不透明）。
-- nvim_set_hl 是整体替换：只传 { bg = "none" } 会抹掉该组原有的 fg/bold，先取出当前定义再写回。
-- 时机：必须在 bufferline 启动时解析颜色之前清一次，再广播 ColorScheme 让它按透明状态重建图标高亮。
--
-- 只清界面装饰层（状态栏、标签栏、浮窗、符号列等）；内容类高亮（Pmenu、Diff、Visual、搜索）保留底色。
local function set_transparent()
  local groups = {
    "Normal", "NormalNC", "CursorLine",
    "StatusLine", "StatusLineNC", "EndOfBuffer",
    "NormalFloat", "FloatBorder", "SignColumn",
    "TabLine", "TabLineFill", "TabLineSel", "ColorColumn",
    -- 光标行上的符号列 / 折叠列：漏了它们会在光标处出现一块实底方块
    "CursorLineSign", "CursorLineFold", "FoldColumn",
    -- NvimTree* 这些组是主题（colors/p3-blue.lua）定义的，文件树插件本身不重新设置它们，
    -- 所以即使 nvim-tree 是懒加载、晚于这里加载，清掉的颜色也不会被覆盖。
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

  -- 之后换主题时兜底。挂进带 clear = true 的 augroup，
  -- 否则 :source init.lua 会再注册一遍，每次换主题就多跑一次。
  local transparent_augroup = vim.api.nvim_create_augroup("UserTransparentBg", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = transparent_augroup,
    pattern = "*",
    callback = set_transparent,
  })
  vim.api.nvim_create_autocmd("VimEnter", {
    group = transparent_augroup,
    callback = function()
      vim.defer_fn(set_transparent, 0)
    end,
  })
end

-- LSP 服务器「装哪些、开哪些」全部收在 lua/plugins/lspconfig.lua，
-- 这里不再重复 vim.lsp.enable（两处同时管会出现「到底谁生效」的问题）。
