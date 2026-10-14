-- theme.lua - 备选主题插件；实际用的 p3-blue 是自研的（colors/p3-blue.lua），
-- 由 init.lua 直接 colorscheme 加载，和这些插件无关。
--
-- 全部 lazy = true：以前四个主题都在启动期加载（priority = 1000 只会让它们更早加载，
-- 不会让它们变懒），为一个用不到的主题付启动时间不划算。
-- 想换成其中之一：先 :Lazy load gruvbox，再 :colorscheme gruvbox 改 init.lua 那行。
return {
  { "blazkowolf/gruber-darker.nvim", lazy = true },
  { "folke/tokyonight.nvim", lazy = true },
  { "catppuccin/nvim", name = "catppuccin", lazy = true },
  { "ellisonleao/gruvbox.nvim", lazy = true },
}
