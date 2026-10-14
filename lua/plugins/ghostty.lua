-- ghostty.lua - Ghostty 终端集成。
return {
  {
    "isak102/ghostty.nvim",
    -- 只在 macOS 有意义：这个插件读的是 Ghostty 终端自己的配置文件
    cond = function()
      return require("config.platform").is_mac
    end,
    config = function()
      require("ghostty").setup()
    end,
  }
}
