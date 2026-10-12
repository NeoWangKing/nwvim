-- surround.lua - 环绕编辑（ys/cs/ds）。
return {
  {
    "kylechui/nvim-surround",
    version = "^4.0.0", -- 锁 v4 稳定版
    event = "VeryLazy",
    -- 配置项见 :h nvim-surround.configuration
    config = function()
      require("nvim-surround").setup({
        -- 暂无自定义
      })
    end,
  }
}
