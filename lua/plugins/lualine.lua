-- lualine.lua - 状态栏，lualine 默认布局 + nord 配色。
return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = {
    options = { theme = 'nord' },
  },
}
