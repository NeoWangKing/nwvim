return {
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    config = function()

      require('nvim-treesitter').setup {
        -- Directory to install parsers and queries to (prepended to `runtimepath` to have priority)
        install_dir = vim.fn.stdpath('data') .. '/site',
        ensure_installed = {
          "markdown",
          "markdown_inline",
          "latex",
          "lua",
          "vim",
          "vimdoc",
          "python",
          "c",
          "cpp",
          "bash",
          "json",
        },
        auto_install = true,
        highlight = {
          enable = true,
        },
        incremental_selection = {
          enable = true,
        },
        indent = {
          enable = true,
        },
        context_commentstring = {
          enable = true,
        }
      }
    end,
  }
}
