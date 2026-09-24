return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- mason 已从 williamboman 迁移到 mason-org 组织，用新名避免依赖旧重定向。
      -- 注意要和 lua/plugins/mason.lua 里写的名字一致，否则会被当成两个插件。
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      -- 1. 初始化 Mason
      require("mason").setup()

      -- 2. 初始化 mason-lspconfig
      --    automatic_enable 会自动为新安装的服务器调用 vim.lsp.enable()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "clangd",
          "pyright",
          "astro",
          "texlab",
          "marksman",
          "ts_ls",
          "cssls"
        },
        automatic_installation = true,
        handlers = {
          function(server_name)
            vim.lsp.enable(server_name)
          end,
        },
      })

      -- 3. 获取 blink.cmp 的能力集，并合并 Neovim 原生能力
      local capabilities = vim.tbl_deep_extend(
        "force",
        vim.lsp.protocol.make_client_capabilities(),
        require("blink.cmp").get_lsp_capabilities()
      )

      -- 4. 为所有服务器配置一个全局的能力集
      vim.lsp.config("*", {
        capabilities = capabilities,
      })

      -- 5. 为特定的服务器（如 lua_ls）进行额外配置
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { library = vim.api.nvim_get_runtime_file("", true) },
          },
        },
      })

      vim.lsp.config('clangd', {})
      vim.lsp.config('pyright', {})
      -- 为 astro 服务器定义配置
      vim.lsp.config("astro", {
        init_options = {
          typescript = {
            -- 动态获取项目内的 TypeScript 路径
            tsdk = vim.fs.joinpath(
              vim.fs.root(0, { "package.json", "node_modules" }) or vim.fn.getcwd(),
              "node_modules",
              "typescript",
              "lib"
            ),
          },
        },
      })

      -- 显式启用 astro 服务器（确保它被启动）
      vim.lsp.enable("astro")
      vim.lsp.config('texlab', {})
      vim.lsp.config('marksman', {})
      vim.lsp.config('ts_ls', {})
      vim.lsp.config('cssls', {})

      -- 注意：LSP 的键位绑定与诊断显示配置已统一移到 lua/config/keymaps.lua。
      -- 原先这里有第二个 LspAttach 回调，和 keymaps.lua 里的那个重复定义了
      -- gd / K / gr / 重命名 / 代码操作，且把 vim.diagnostic.config 放在回调里
      -- （每次附加服务器都会重跑一遍）。现在只保留服务器本身的配置。
    end,
  }
}
