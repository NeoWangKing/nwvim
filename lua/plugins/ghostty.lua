-- ghostty.lua - Ghostty 终端集成。
return {
  {
    "isak102/ghostty.nvim",
    config = function()
      require("ghostty").setup()
    end,
  }
}
