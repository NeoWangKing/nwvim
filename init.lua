-- bootstrap lazy.nvim, LazyVim and your plugins
vim.env.PATH = vim.fn.expand("$HOME/.nvm/version/node/v20.20.2/bin") .. ":" .. vim.env.PATH

vim.g.start_time = vim.loop.hrtime()
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.autocmds")
require("config.lazy")
require("config.keymaps")
require("config.commands")

-- 设置光标所在行的行号颜色
vim.api.nvim_set_hl(0, 'CursorLineNr', {
    fg = '#ffdb01',  -- 前景色（文字颜色），例如：紫色
    bold = true,     -- 是否加粗（可选）
})

-- init.lua 示例，将此部分添加到你的配置文件末尾
local g = vim.g -- 使用 g 指代 vim.g，简化代码

-- ==========================================
-- 1. 视觉舒适度的基石：刷新率与动画节奏
-- ==========================================
-- 核心配置：根据你的显示器刷新率调整，144Hz显示器就设为144
g.neovide_refresh_rate = 320
-- 空闲刷新率：编辑器无操作时降低刷新率，节省GPU功耗
g.neovide_refresh_rate_idle = 30
-- 滚动动画时长：单位秒。缩短时长让滚动更跟手
g.neovide_scroll_animation_length = 0.05

-- 自定义光标拖尾效果
-- 拖尾长度：0为无拖尾，1为超长拖尾
g.neovide_cursor_trail_size = 0.8
-- 光标动画速度：单位秒，数值越小瞬移感越强
g.neovide_cursor_animation_length = 0.1
-- 光标特效粒子：支持 'railgun', 'torpedo', 'pixiedust', 'sonic boom', 'ripple', 'wireframe'
-- 设为空字符串 '' 可禁用特效
g.neovide_cursor_vfx_mode = ''

-- ==========================================
-- 2. 打造沉浸式编码环境：窗口透明度与背景融合
-- ==========================================

-- 全局透明度：1.0为不透明，推荐0.95，既能看清代码又能感知桌面层次感
g.neovide_opacity = 1.0

-- ==========================================
-- 3. 基础视觉增强
-- ==========================================

-- 字体设置（关键！）
vim.opt.guifont = "JetBrainsMono_NFM:h11" -- 请确保你的Windows中已安装此字体
-- 备用字体配置示例
-- vim.opt.guifont = "FiraCode_Nerd_Font:h11,Hack_Nerd_Font:h11"

-- 字体缩放系数 (1.0为默认)
g.neovide_scale_factor = 1.0

-- ==========================================
-- 4. 性能配置
-- ==========================================

-- 窗口模糊效果：关闭可提升性能，低配电脑推荐关闭
g.neovide_floating_blur_amount_x = 0.0
g.neovide_floating_blur_amount_y = 0.0

-- ==========================================
-- 5. 动态调整字体大小的快捷键 (Ctrl + / -)
-- ==========================================
g.gui_font_default_size = 15
g.gui_font_face = "JetBrainsMono_NFM"

local function refresh_gui_font()
  vim.opt.guifont = string.format("%s:h%s", g.gui_font_face, g.gui_font_size)
end

local function resize_gui_font(delta)
  g.gui_font_size = g.gui_font_size + delta
  refresh_gui_font()
end

-- 初始化全屏
g.neovide_fullscreen = true

-- 初始化字体大小
g.gui_font_size = g.gui_font_default_size
refresh_gui_font()

-- 绑定快捷键
local opts = { noremap = true, silent = true }
vim.keymap.set({'n', 'i'}, "<C-=>", function() resize_gui_font(1) end, opts)
vim.keymap.set({'n', 'i'}, "<C-->", function() resize_gui_font(-1) end, opts)
vim.keymap.set({'n', 'i'}, "<C-0>", function()
  g.gui_font_size = g.gui_font_default_size
  refresh_gui_font()
end, { noremap = true, silent = true, desc = "Reset font size" })

if vim.g.neovide then
  vim.api.nvim_set_hl(0, "Normal", { bg = "#181818", fg = "#bbbbbb" })

  vim.api.nvim_set_hl(0, "NormalNC", { bg = "#181818" })
  vim.api.nvim_set_hl(0, "SignColumn", { bg = "#181818" })
  vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "#181818" })
  vim.api.nvim_set_hl(0, "StatusLine", { bg = "#2a2a2a", fg = "#c0c0c0" })
  vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "#1e1e1e", fg = "#808080" })

  vim.keymap.set('v', '<LeftMouse>', '"+y', { silent = true, desc = 'Copy to system clipboard' })

  vim.g.neovide_image_filetypes = {
    "png", "jpg", "jpeg", "gif", "bmp", "webp",
    "ppm", "pgm", "pbm", "tiff", "tif", "svg", "ico", "heic", "heif",
  }
end
