-- lua/plugins/numbertoggle.lua

return {
  "sitiom/nvim-numbertoggle",
  -- enabled = false,
  event = "VeryLazy", -- 延迟加载
  config = function()
    -- 插件会自动工作，无需额外配置
    -- 但你需要确保你的 Neovim 基础配置中启用了行号
    -- 可选：创建自动命令来精细控制
    vim.api.nvim_create_augroup("NumberToggleCustom", { clear = true })
    
    -- 例如：在可视化模式下也显示相对行号
    vim.api.nvim_create_autocmd("ModeChanged", {
      group = "NumberToggleCustom",
      pattern = "*:[vV\x16]*",
      callback = function()
        vim.opt.relativenumber = true
        vim.opt.number = true
      end,
    })
  end,
}
