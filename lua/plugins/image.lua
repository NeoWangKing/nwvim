return {
  "3rd/image.nvim",
  -- enabled = false,
  event = "VeryLazy",
  config = function()
    require("image").setup({
      backend = "kitty",        -- Neovide / WezTerm 都支持 kitty 图形协议
      processor = "magick_cli", -- 使用 ImageMagick 命令行处理
      -- 指定自动渲染的图片文件扩展名（即 Neovim 的 filetype）
      filetypes = {
        "png",
        "jpg",
        "jpeg",
        "gif",
        "bmp",
        "webp",
        "ppm",
        "pgm",
        "pbm",
        "tiff",
        "tif",
        "svg",
        "ico",
        "heic",
        "heif",
      },
      integrations = {
        markdown = { enabled = true },
        html = { enabled = false },
      },
    })
  end,
}
