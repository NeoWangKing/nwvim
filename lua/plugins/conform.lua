return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function(_, opts)
    local conform = require("conform")
    conform.setup(opts)

    -- 注册 :Format 命令（LazyVim 风格的函数式格式化）
    vim.api.nvim_create_user_command("Format", function()
      conform.format({ async = true, lsp_fallback = true })
    end, { desc = "Format current buffer" })

    -- 注册快捷键：普通模式下 <leader>f
    vim.keymap.set({ "n", "v" }, "<leader>f", function()
      conform.format({ async = true, lsp_fallback = true })
    end, { desc = "Format file / selection" })
  end,
  opts = {
    -- 为 Markdown 指定格式化器（Prettier）
    formatters_by_ft = {
      markdown = { "prettier" },
    },
  },
}
