-- theme.lua - 备选主题插件；默认 p3-blue 在 init.lua 里设置。
return {
  {
    "blazkowolf/gruber-darker.nvim",
    priority = 1000,
    opt = {},
  },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
  },
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000 ,
    opts = {},
  }
}
