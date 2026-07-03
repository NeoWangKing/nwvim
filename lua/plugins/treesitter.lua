return {
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').setup {
        install_dir = vim.fn.stdpath('data') .. '/site',
        ensure_installed = {
          "markdown",
          "markdown_inline",
          "latex",          -- 数学公式解析
          "regex",          -- 高亮公式必需
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
          -- 启用额外的 vim 正则高亮（对公式高亮有帮助）
          additional_vim_regex_highlighting = { "markdown" },
        },
        incremental_selection = {
          enable = true,
        },
        indent = {
          enable = true,
        },
        context_commentstring = {
          enable = true,
        },
        -- 明确启用 math 高亮
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["aM"] = "@math.outer",
              ["iM"] = "@math.inner",
            },
          },
        },
      }
    end,
  },
}
