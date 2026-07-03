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
