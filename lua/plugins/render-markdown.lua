return {
  "MeanderingProgrammer/markdown.nvim",
  enabled = false,
  name = "render-markdown",
  ft = "markdown",
  opts = {
    -- 启用代码块语法高亮
    code = {
      enabled = true,
      -- 代码块内使用 Treesitter 高亮
      -- sign = false,          -- 不显示行号（可选）
      -- style = "normal",      -- 正常模式
      -- 你也可以设置最小宽度等
    },
    -- 启用数学公式渲染（LaTeX）
    latex = {
      enabled = true,
      -- 渲染器使用 wezterm 或默认
      -- converter = "text",    -- 使用 Unicode 文本近似渲染，WSL 下最稳定
      -- top_pad = 0,
      -- bottom_pad = 0,
    },
    -- 链接、图片、列表等其它增强（可按需开关）
    link = { enabled = false },
    image = { enabled = false },
    heading = { enabled = false, },
    bullet = { enabled = false },
    -- 表格自动格式化
    table = { enabled = false },
    -- 复选框增强
    checkbox = { enabled = false },
    -- 水平线美化
    dash = { enabled = false },
    -- 引用块样式
    quote = { enabled = false },
    -- 脚注/列表等
    pipe_table = { enabled = false },
  },
}
