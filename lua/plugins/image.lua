-- image.lua - 终端内嵌图片，kitty 协议 + ImageMagick 处理。
-- 依赖终端实现 kitty 图形协议；不支持的终端（Windows Terminal 的多数场景、
-- 没图形协议的老终端）直接不加载，省得白占内存、还被动弹一堆后端警告。
local function graphics_capable()
  if vim.g.neovide ~= nil then return true end     -- Neovide
  if vim.env.KITTY_WINDOW_ID ~= nil then return true end -- kitty

  local term_program = (vim.env.TERM_PROGRAM or ""):lower()
  return term_program:find("wezterm") ~= nil       -- WezTerm
    or term_program:find("ghostty") ~= nil         -- Ghostty
    or vim.env.GHOSTTY_RESOURCES_DIR ~= nil        -- Ghostty（备用判据）
end

return {
  "3rd/image.nvim",
  cond = graphics_capable,
  event = "VeryLazy",
  config = function()
    require("image").setup({
      backend = "kitty",        -- kitty 图形协议（Neovide/WezTerm 也支持）
      processor = "magick_cli", -- 用 ImageMagick 命令行处理
      max_width_window_percentage = 50,
      integrations = {
        markdown = {
          enabled = true,
          -- 只渲染光标处的图片，滚动时不会批量调用 ImageMagick
          only_render_image_at_cursor = true,
        },
        html = { enabled = false },
      },
    })
  end,
}
