return {
  "rcarriga/nvim-notify",
  config = function()
    vim.notify = require("notify")
    require("notify").setup({
      timeout = 3000,
      max_width = 60,
      render = "compact",
      stages = "fade_in_slide_out",
      -- 指定背景色，消除警告（建议用你当前主题的背景色，这里用深灰）
      background_colour = "#181818",
    })
  end,
}
