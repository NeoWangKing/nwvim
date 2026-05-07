return {
  "NvChad/nvim-colorizer.lua",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("colorizer").setup({
      filetypes = {
        -- 你原先启用的所有文件类型
        "css", "scss", "sass", "less",
        "html", "javascript", "javascriptreact",
        "typescript", "typescriptreact", "vue",
        "lua", "vim", "toml", "yaml", "json",
        "markdown",
      },
      user_default_options = {
        tailwind = false,
        virtualtext = true,
        mode = "background",
        always_update = true,
        css = true,
        css_fn = true,
        hsl = true,
        names = true,
        rgb_fn = true,
        rrggbbaa = true,
      },
      buftypes = {},
    })

    -- 强制禁止 C/C++ 文件的颜色渲染
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("colorizer_disable_c", { clear = true }),
      pattern = { "c", "cpp", "h", "hpp" },
      callback = function()
        pcall(vim.cmd, "ColorizerDetachFromBuffer")
      end,
    })
  end,
}
