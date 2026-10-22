-- treesitter.lua - 高亮和缩进用 Neovim 内置（0.11+ 自带），这个插件只负责「装 parser」。
--
-- 为什么要在这里自动装：解析器不在仓库里（在 stdpath("data")/site 下），换机器后
-- 不装的话标题渲染和 LaTeX 语法检查都会静默失效 —— 这是「克隆下来就能用」的最后一环。
-- 首次启动会下载并编译（需要 make 和 C 编译器，README 的「环境要求」里已列），
-- 已经装好的会被跳过，所以之后的启动只是几次文件检查。
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({})

      -- markdown / markdown_inline / latex 是标题渲染与 latex-check 直接依赖的，
      -- 其余按日常会打开的文件类型来；gnuplot 对应 .gp。
      -- 没列 c / lua / query / vim / vimdoc：Neovim 0.11+ 自带这些 parser，
      -- 而且自带的那份跟随 Neovim 版本，比另外装一份更稳。
      require("nvim-treesitter").install({
        "astro",
        "bash",
        "cpp",
        "css",
        "diff",
        "gitcommit",
        "gnuplot",
        "html",
        "javascript",
        "json",
        "latex",
        "markdown",
        "markdown_inline",
        "python",
        "toml",
        "tsx",
        "typescript",
        "xml",
        "yaml",
      })
    end,
  },
}
