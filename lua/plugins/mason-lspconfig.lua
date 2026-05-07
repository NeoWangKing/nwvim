return {
  "williamboman/mason-lspconfig.nvim",
  dependencies = { "mason.nvim" },
  opts = {
    ensure_installed = { "lua_ls", "pyright", "rust_analyzer", "ts_ls" }, -- 按需添加
    automatic_installation = true,
  },
}
