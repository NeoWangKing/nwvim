-- noice.lua - 通知和 LSP 提示；命令行交给 Neovim 原生。
-- noice 的 messages/cmdline 会启用 ext_messages，把 cmdheight 压成 0，
-- 状态栏下面就没有输入行；这里关掉它们，保留 popupmenu 等其余功能。
return {
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = {
      cmdline = { enabled = false },
      messages = { enabled = false },
      popupmenu = {
        backend = "nui",   -- 补全菜单交给 nui 渲染
      },
      notify = {
        view = "notify",
        -- 通知底色不在这里设：noice 不读 background_colour（它只是把消息转给 nvim-notify），
        -- 真正生效的是 lua/plugins/notify.lua 里给 nvim-notify 的那一份。
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
      views = {},   -- 留空用默认，想自定义再填
    },
  }
}
