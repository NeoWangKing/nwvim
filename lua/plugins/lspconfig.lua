-- lspconfig.lua - Mason 安装 LSP 服务器并按需启用。
return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- Mason 已迁到 mason-org 组织
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      -- 初始化 Mason
      require("mason").setup()

      -- 新装好的服务器自动 vim.lsp.enable
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

      -- blink.cmp 的能力集合并进原生能力
      local capabilities = vim.tbl_deep_extend(
        "force",
        vim.lsp.protocol.make_client_capabilities(),
        require("blink.cmp").get_lsp_capabilities()
      )

      -- 全局能力集
      vim.lsp.config("*", {
        capabilities = capabilities,
      })

      -- lua_ls 额外设置
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { library = vim.api.nvim_get_runtime_file("", true) },
          },
        },
      })

      -- 去掉默认的 c.doxygen / cpp.doxygen 未知文件类型
      vim.lsp.config('clangd', {
        filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
      })
      vim.lsp.config('pyright', {})
      -- astro 动态找项目里的 TypeScript 路径
      vim.lsp.config("astro", {
        init_options = {
          typescript = {
            tsdk = vim.fs.joinpath(
              vim.fs.root(0, { "package.json", "node_modules" }) or vim.fn.getcwd(),
              "node_modules",
              "typescript",
              "lib"
            ),
          },
        },
      })

      -- 显式启用 astro
      vim.lsp.enable("astro")
      vim.lsp.config('texlab', {})
      -- 去掉默认的 markdown.mdx 未知文件类型
      vim.lsp.config('marksman', {
        filetypes = { "markdown" },
      })
      vim.lsp.config('ts_ls', {})
      vim.lsp.config('cssls', {})

      -- LSP 键位和诊断显示统一在 config/keymaps.lua，这里只配服务器
    end,
  }
}
