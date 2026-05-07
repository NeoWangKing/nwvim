-- lua/plugins/mason.lua
return {
  "williamboman/mason.nvim",
  build = function() require("mason").setup() end,
  cmd = "Mason",
  -- 可以在这里添加一些默认配置
  config = true,
}
