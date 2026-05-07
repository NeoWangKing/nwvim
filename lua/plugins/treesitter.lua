return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  cmd = { "TSInstallSync", "TSInstall", "TSUpdate", "TSUpdateSync" },
  opts = {
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
  },
  config = function(_, opts)
    -- 确保 tree-sitter CLI 可以被找到
    vim.env.PATH = vim.env.PATH .. ":/opt/homebrew/bin:/usr/local/bin"
    require("nvim-treesitter.configs").setup(opts)
  end,
}
