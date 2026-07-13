require('vim._core.ui2').enable({})

require('config.options')
require('config.keymaps')
require('config.autocmds')
require('config.commands')
require('config.lazy')

vim.opt.clipboard = "unnamedplus"

-- 让 .gp 文件被识别为 gnuplot 类型
vim.filetype.add({ extension = { gp = 'gnuplot' } })

-- vim.cmd.colorscheme("gruber-darker")
-- vim.cmd.colorscheme("tokyonight")
vim.cmd.colorscheme("catppuccin")
-- vim.cmd.colorscheme("gruvbox")

-- 透明背景（仅对终端有效）
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
  for _, g in ipairs(groups) do
    pcall(vim.api.nvim_set_hl, 0, g, { bg = "none" })
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
vim.lsp.enable('lua-ls')
vim.lsp.enable('marksman')
vim.lsp.enable('pyright')
vim.lsp.enable('texlab')
vim.lsp.enable('ts-ls')
