return {
  {
    'echasnovski/mini.nvim',
    -- enabled = false,
    version = '*',
    event = "VeryLazy",
    config = function()
      require("mini.surround").setup()

      require("mini.ai").setup()

      require("mini.comment").setup()
    end,
  }
}
