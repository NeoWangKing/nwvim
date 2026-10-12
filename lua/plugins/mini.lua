-- mini.lua - 目前只启用 mini.ai 文本对象，其余按需开启。
return {
  {
    'nvim-mini/mini.nvim',
    version = false,
    config = function()
      require('mini.ai').setup({})
      -- require('mini.align').setup({})
      -- require('mini.comment').setup({})
      -- require('mini.cursorword').setup({})
      -- require('mini.notify').setup({})
      -- require('mini.pairs').setup({
      --   skip_ts = { 'string', 'comment' },
      --   skip_unbalanced = true,
      -- })
      -- require('mini.starter').setup({})
      -- require('mini.statusline').setup({})
      -- require('mini.tabline').setup({})
    end,
  },
}
