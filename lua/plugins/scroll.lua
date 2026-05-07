return {
  -- 平滑滚动动画插件
  {
    "karb94/neoscroll.nvim",
    config = function()
      require("neoscroll").setup({})
    end,
  },
  -- 装饰性滚动条插件（推荐）
  {
    -- 请注意，由于 Neovim API 限制，此插件使用了非理想的变通方案
    -- 但通常不会影响使用，功能上目前是同类最佳
    "lewis6991/satellite.nvim",
    config = function()
      require("satellite").setup({
        -- 这里可以粘贴你的自定义配置
      })
    end,
  },
  -- 轻量级滚动条插件（备选）
  -- { "petertriho/nvim-scrollbar", config = true },
  -- 即插即用滚动条插件（备选）
  -- { "dstein64/nvim-scrollview", config = true },
}
