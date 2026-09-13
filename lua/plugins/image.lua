return {
  "3rd/image.nvim",
  -- enabled = false,
  event = "VeryLazy",
  config = function()
    require("image").setup({
      backend = "kitty",        -- Neovide / WezTerm 都支持 kitty 图形协议
      processor = "magick_cli", -- 使用 ImageMagick 命令行处理
      max_width_window_percentage = 50,
      integrations = {
        markdown = {
          enabled = true,
          -- 性能优化：只渲染光标所在的图片，避免滚动时批量调用 ImageMagick
          only_render_image_at_cursor = true,
        },
        html = { enabled = false },
      },
    })
  end,
}
