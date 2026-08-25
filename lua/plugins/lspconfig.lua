return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
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

      -- 6. 设置 LSP 附加时的行为
      --    NeoVim 0.11+ 推荐使用 LspAttach 自动命令，而不是 on_attach 回调
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          local bufnr = args.buf
          -- 这里可以放置你之前 on_attach 里的逻辑，比如设置快捷键
          local bufopts = { noremap = true, silent = true, buffer = bufnr }
          -- 跳转到定义
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
          -- 显示悬浮文档
          vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
          -- 查找引用
          vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
          -- 重命名符号
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
          -- 代码操作
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
          vim.keymap.set('n', '<leader>ee', vim.diagnostic.open_float, { desc = '显示当前行的诊断信息' })
          -- ... 其他快捷键 ...
          if client.server_capabilities.documentFormattingProvider then
            vim.keymap.set("n", "<leader>f", function()
              vim.lsp.buf.format({ async = true })
            end, bufopts)
          end

          vim.diagnostic.config({
            virtual_text = false, -- 关闭行内显示，让界面更清爽
            float = {
              border = 'rounded',  -- 可选，为窗口添加圆角边框
              source = 'always',   -- 可选，显示诊断来源（如 LSP 服务器名）
              prefix = '',         -- 可选，自定义每条信息的前缀
            },
            -- 可选：设置延迟后自动弹出（单位：毫秒）
            -- 注意：这可能需要配合 CursorHold 自动命令实现，下方有示例
          })
        end,
      })
    end,
  }
}
