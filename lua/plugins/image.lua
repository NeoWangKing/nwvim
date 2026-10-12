-- image.lua - 终端内嵌图片，kitty 协议 + ImageMagick 处理。
return {
  "3rd/image.nvim",
  -- enabled = false,
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
