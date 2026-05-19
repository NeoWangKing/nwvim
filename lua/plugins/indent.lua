return {
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    ---@module "ibl"
    ---@type ibl.config
    config = function()
      local highlight = {
        "IndentColor",
      }

      local hooks = require "ibl.hooks"

      hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
        vim.api.nvim_set_hl(0, "IndentColor", { fg = "#383838" })
      end)

      require("ibl").setup({
        scope = {
          enabled = true,
          show_start = false,
          show_end = false,
        },
        indent = {
          highlight = highlight,
          char = "│",
        },
        exclude = {
          filetypes = {
            "dashboard",
            "lazy",
            "help",
            "man",
            "checkhealth",
            "qf",
          },
        },
      })
    end,
  }
}
