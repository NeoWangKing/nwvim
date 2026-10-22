-- mason 装的可执行文件（lua-language-server 等）必须赶在「第一个文件的 LSP 启动」
-- 之前进入 PATH。mason 自己也会在 setup() 里做这件事，但它被挪到了 VeryLazy，
-- 那时候 `nvim foo.py` 的文件早就读过、服务器已经尝试启动过了 —— 结果就是
-- 找不到可执行文件、静默不附着。所以这里先把目录补上（幂等，mason 之后重复插一次无害）。
require("config.platform").prepend_path(
  vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin")
)

-- lspconfig.lua - LSP 服务器配置与启用；Mason 只负责「安装」。
--
-- 分成两个 spec，是按「什么时候必须就绪」拆的：
--   1) nvim-lspconfig  —— 启动期执行。capabilities 和各服务器的设置必须在
--      任何服务器启动之前生效，所以不能延后（延后会导致先启动的 client 拿到
--      默认能力集，blink 的补全能力就丢了）。
--   2) mason-lspconfig —— 只做安装。挂 VeryLazy，不进启动关键路径；
--      需要时 :Mason 也能立刻拉起来。
--
-- 「启用哪些服务器」的唯一出处是下面 config 里的 enabled 列表：
-- mason 侧已设 automatic_enable = false，不要两处同时管。
return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- blink 必须先就绪：下面要取它的能力集
      "saghen/blink.cmp",
    },
    config = function()
      -- blink.cmp 的能力集合并进原生能力
      vim.lsp.config("*", {
        capabilities = vim.tbl_deep_extend(
          "force",
          vim.lsp.protocol.make_client_capabilities(),
          require("blink.cmp").get_lsp_capabilities()
        ),
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
      vim.lsp.config("clangd", {
        filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
      })

      -- 去掉默认的 markdown.mdx 未知文件类型
      vim.lsp.config("marksman", {
        filetypes = { "markdown" },
      })

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

      vim.lsp.config("julials", { settings = {} })

      -- 启用列表。显式写死而不是靠 mason 的 automatic_enable：
      -- 后者要等 registry 刷新成功才触发，离线/网络受限时会一个都不启用。
      local enabled = { "astro", "clangd", "cssls", "lua_ls", "marksman", "pyright", "rust_analyzer", "texlab", "ts_ls" }
      if vim.fn.executable("julia") == 1 then
        -- Julia 未安装的平台（如当前 Linux）跳过，避免 vim.lsp 健康检查报警
        enabled[#enabled + 1] = "julials"
      end
      vim.lsp.enable(enabled)

      -- LSP 键位和诊断显示统一在 config/keymaps.lua，这里只配服务器
    end,
  },

  {
    -- Mason 已迁到 mason-org 组织
    "mason-org/mason-lspconfig.nvim",
    event = "VeryLazy",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUninstallAll", "MasonLog", "MasonUpdate" },
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        -- 只列出要装的；开哪些见上面的 enabled 列表
        ensure_installed = {
          "lua_ls",
          "clangd",
          "pyright",
          "astro",
          "texlab",
          "marksman",
          "ts_ls",
          "cssls",
        },
        -- v2 里才有的开关；「装好就自动启用」交给上面的列表，
        -- 免得两套机制抢着 vim.lsp.enable（v1 的 handlers / automatic_installation
        -- 在 v2 里已经完全不被读取，写了也是死配置）
        automatic_enable = false,
      })
    end,
  },
}
