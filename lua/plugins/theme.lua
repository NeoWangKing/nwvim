-- theme.lua - 备选主题插件；当前用 nord，由 init.lua 加载。
--
-- 当前主题必须启动时加载，否则 lualine 找不到对应 theme 文件。
-- 其余主题 lazy = true，不占启动时间。
-- 想换：把 init.lua 里的名字改成 catppuccin / gruber-darker / tokyonight / gruvbox / p3-blue。
return {
  { "shaunsingh/nord.nvim", lazy = false, priority = 1000 },
  { "blazkowolf/gruber-darker.nvim", lazy = true },
  { "folke/tokyonight.nvim", lazy = true },
  { "catppuccin/nvim", name = "catppuccin", lazy = true, opts = { flavour = "mocha" } },
  { "ellisonleao/gruvbox.nvim", lazy = true },
}
