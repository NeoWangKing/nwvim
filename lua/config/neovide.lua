-- lua/config/neovide.lua
-- Neovide GUI 专属配置

local g = vim.g

-- 刷新率 / 动画
g.neovide_refresh_rate = 320
g.neovide_refresh_rate_idle = 30
g.neovide_scroll_animation_length = 0.05

-- 光标拖尾
g.neovide_cursor_trail_size = 0.8
g.neovide_cursor_animation_length = 0.1
g.neovide_cursor_vfx_mode = ""

-- 窗口透明度（1.0 完全不透明，0.0 全透明）
g.neovide_opacity = 0.95

-- 性能
g.neovide_floating_blur_amount_x = 0.0
g.neovide_floating_blur_amount_y = 0.0

-- 启动全屏
g.neovide_fullscreen = true

-- GUI 字体
vim.opt.guifont = "JetBrainsMono_NFM:h15"

-- 动态字体大小调整
g.gui_font_default_size = 15
g.gui_font_face = "JetBrainsMono_NFM"

local function refresh_gui_font()
  vim.opt.guifont = string.format("%s:h%s", g.gui_font_face, g.gui_font_size)
end

local function resize_gui_font(delta)
  g.gui_font_size = g.gui_font_size + delta
  refresh_gui_font()
end

g.gui_font_size = g.gui_font_default_size
refresh_gui_font()

local opts = { noremap = true, silent = true }
vim.keymap.set({ "n", "i" }, "<C-=>", function() resize_gui_font(1) end, opts)
vim.keymap.set({ "n", "i" }, "<C-->", function() resize_gui_font(-1) end, opts)
vim.keymap.set({ "n", "i" }, "<C-0>", function()
  g.gui_font_size = g.gui_font_default_size
  refresh_gui_font()
end, { noremap = true, silent = true, desc = "Reset font size" })

-- Neovide 中的背景色（覆盖终端透明，改用深色背景）
vim.api.nvim_set_hl(0, "Normal", { bg = "#181818", fg = "#bbbbbb" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "#181818" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "#181818" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "#181818" })
vim.api.nvim_set_hl(0, "StatusLine", { bg = "#2a2a2a", fg = "#c0c0c0" })
vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "#1e1e1e", fg = "#808080" })

-- 右键复制
vim.keymap.set("v", "<LeftMouse>", '"+y', { silent = true, desc = "Copy to system clipboard" })

-- 支持的图片文件类型
g.neovide_image_filetypes = {
  "png", "jpg", "jpeg", "gif", "bmp", "webp",
  "ppm", "pgm", "pbm", "tiff", "tif", "svg", "ico", "heic", "heif",
}
