return {
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').setup {
        install_dir = vim.fn.stdpath('data') .. '/site',
      }
      -- 需要新语言的 parser 时手动执行：:TSInstall <lang>，批量更新用 :TSUpdate
    end,
  },
}
