return {
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = {
      cmdline = {
        view = "cmdline_popup",   -- 弹出式命令行，也可用 "cmdline"（传统底部）
        format = {
          cmdline = { pattern = "^:", icon = "", lang = "vim" },
          search_down = { kind = "search", pattern = "^/", icon = " ", lang = "regex" },
          search_up = { kind = "search", pattern = "^%?", icon = " ", lang = "regex" },
          filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
          lua = { pattern = "^:%s*lua%s+", icon = "", lang = "lua" },
          help = { pattern = "^:%s*he?l?p?%s+", icon = "" },
          input = { view = "cmdline_input", icon = "󰥻 " },
        },
      },
      messages = {
        view = "notify",
        view_error = "notify",
        view_warn = "notify",
      },
      popupmenu = {
        backend = "nui",   -- 或用 "cmp" 与 nvim-cmp 联动
      },
      notify = {
        view = "notify",
        background_colour = "#181818",   -- 你的背景色
      },
      lsp = {
        progress = {
          view = "mini",
        },
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
        message = {
          view = "notify",
        },
        documentation = {
          view = "hover",
          opts = { lang = "markdown", replace = true, render = "plain" },
        },
      },
      presets = {
        long_message_to_split = true,
        lsp_doc_border = true,
        command_palette = true,   -- 命令行和补全菜单联动
      },
      views = {},   -- 留空使用默认，想自定义再填
    },
  }
}
