-- render-markdown.lua - Markdown 行内渲染，只在 markdown 文件里懒加载。
return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    -- 只在 markdown 加载，不占启动时间
    ft = { 'markdown' },
    -- :RenderMarkdown 在没有 markdown 缓冲区时也能用（否则会报命令不存在）
    cmd = "RenderMarkdown",

    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-mini/mini.icons',
    },

    config = function(_, opts)
      require('render-markdown').setup(opts)
      -- 只给背景，不设前景，避免覆盖 treesitter 的语法色
      vim.api.nvim_set_hl(0, 'RenderMarkdownCode', { bg = '#2E3440' })
    end,

    -- 临时看原文用；insert 模式本来就会自动回原文
    keys = {
      {
        '<leader>mt',
        '<cmd>RenderMarkdown toggle<CR>',
        ft = 'markdown',
        desc = 'Toggle Markdown render',
      },
    },

    opts = {
      -- n/c/t 模式渲染，insert 回原文；这是渲染不干扰编辑的关键
      render_modes = { 'n', 'c', 't' },

      -- 光标行自动回原文，避免虚拟文本盖住没法改
      anti_conceal = { enabled = true },

      -- 公式渲染关闭（utftex 在多行环境不可靠），语法检查交给 latex-check
      latex = {
        enabled = false,
        converter = { 'utftex', 'latex2text' },
      },

      -- 不启用 conceal：保留 _text_、[text](url) 等原始标记，避免宽度变化
      win_options = {
        conceallevel = { default = 0, rendered = 0 },
        concealcursor = { default = '', rendered = '' },
      },

      -- 代码块只加背景色，保留 ``` 围栏；不加边框/语言标签/sign，避免布局变化
      code = {
        enabled = true,
        conceal_delimiters = false,
        border = 'none',
        sign = false,
        language = false,
        language_icon = false,
        language_name = false,
        highlight = 'RenderMarkdownCode', -- 只带背景，保留 treesitter 语法色
      },

      -- 不写颜色：高亮组都 link 到 treesitter/标准组，自动跟随主题
      -- 关掉标题色带和 sign：sign 会临时占用 signcolumn，导致普通/插入模式文字左右跳
      heading = {
        backgrounds = {},
        sign = false,
      },

      -- 其余组件保持插件默认
    },
  },
}
