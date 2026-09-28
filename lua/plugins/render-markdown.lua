return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    -- 只在 markdown 文件里加载：它做的是「把缓冲区渲染出样式」，
    -- 对其他文件类型没有意义，也不该占启动时间。
    -- 加载是懒的（ft），不是启动时加载，所以对 nvim 启动速度零影响。
    ft = { 'markdown' },

    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-mini/mini.icons',
    },

    -- 渲染默认就是开着的。加这个键位是为了「临时看原文」——
    -- 比如要精确对齐表格、或核对语法时。insert 模式本来就会自动回原文，
    -- 所以日常写作其实用不到它。
    keys = {
      {
        '<leader>mt',
        '<cmd>RenderMarkdown toggle<CR>',
        ft = 'markdown',
        desc = 'Toggle Markdown render',
      },
    },

    opts = {
      -- ── 渲染模式 ────────────────────────────────────────────────
      -- n=普通 / c=命令行 / t=终端模式下渲染，insert 模式自动回原文。
      -- 这是插件默认值，显式写出来是因为它正是「渲染不干扰编辑」的关键：
      -- 只有不去动 insert 模式的显示，写起来才不会有输入延迟或错位感。
      render_modes = { 'n', 'c', 't' },

      -- ── anti-conceal ────────────────────────────────────────────
      -- 光标所在行的渲染内容自动隐藏，恢复成原始 markdown 文本。
      -- 不做这个的话，光标行会被虚拟文本盖住、根本没法改字。
      -- （上面 render_modes 已经挡住了 insert 模式，这里是额外一层保护：
      --   在 normal 模式下移动光标时，当前行也始终是干净的。）
      anti_conceal = { enabled = true },

      -- ── LaTeX 公式 ──────────────────────────────────────────────
      -- 关闭行内公式渲染。
      --
      -- 试过 utftex 方案（brew install utftex，转换质量本身不错），但实测在
      -- 多行环境里表现不可靠，最典型的是 $$...\begin{align}...\end{align}...$$：
      --   x_M 的下标被拆成两行，align 环境也没被正确处理，
      --   渲染结果反而比原文更难读。
      -- 公式的正确性检查交给 treesitter（见 lua/config/latex-check.lua），
      -- 那里能给出真正的语法错误位置，比「好看的近似排版」有用。
      --
      -- 注：utftex 仍装在系统里、converter 也保留着，
      --     想临时试回渲染只需把 enabled 改成 true。
      latex = {
        enabled = false,
        converter = { 'utftex', 'latex2text' },
      },

      -- ── 高亮 ────────────────────────────────────────────────────
      -- 这里刻意不写任何颜色。
      -- 插件的所有高亮组都是 link 到 treesitter / 标准组，且 default = true：
      --   RenderMarkdownH1    -> @markup.heading.1.markdown
      --   RenderMarkdownH1Bg  -> DiffText      （各级标题的底纹来自 Diff*）
      --   RenderMarkdownMath  -> @markup.math
      --   RenderMarkdownQuote -> @markup.quote
      --   RenderMarkdownSuccess -> DiagnosticOk（callout 用诊断色）
      -- p3-blue 已经定义了上面这些组，所以配色自动跟随主题。
      -- 换主题时这套渲染会一起变，不需要维护第二份色板。

      -- ── 标题底纹：关掉 ──────────────────────────────────────────
      -- 默认 backgrounds 是 { 'RenderMarkdownH1Bg' ... 'H6Bg' }，
      -- 它会给标题铺一条横贯整行的实心色带（H1..H6 分别取
      -- DiffText/DiffAdd/DiffChange/DiffDelete/Visual/CursorColumn 的底色，
      -- 也就是蓝/绿/蓝/红…）。这个列表就是官方的开关，清空即关闭。
      --
      -- 为什么关掉：
      -- ① 与透明背景的整套风格冲突——配置里 set_transparent() 特意清掉了
      --    Normal / CursorLine / SignColumn / StatusLine 的底色，让壁纸透出来，
      --    而标题色带是唯一几处不透明的大色块，非常突兀；
      -- ② 更要紧的是它**必然接不上行号列**：色带是 buffer 内的 extmark
      --    （hl_eol=true），而行号/符号列在 buffer 之外，extmark 覆盖不到，
      --    于是行号列透明、正文区突然一条实色，中间是一道硬缝。
      --    这是几何限制，插件层面无法让色带延伸到行号列。
      --
      -- 关掉之后标题靠「图标 + 主题里的 @markup.heading.N 前景色 + 加粗」
      -- 区分层级，完全透明，和行号列连成一片。
      --
      -- 想改回色带：删掉这个 heading 段即可（或只留部分层级，例如
      -- backgrounds = { 'RenderMarkdownH1Bg', 'RenderMarkdownH2Bg' }，
      -- 列表按层级 clamp，只影响前两级）。
      heading = {
        backgrounds = {},
      },

      -- ── 其余组件 ────────────────────────────────────────────────
      -- bullet / checkbox / code / pipe_table / quote / callout / link /
      -- dash / indent / html / yaml 都保持插件默认。
      -- 默认已经覆盖写作常用元素，先不预先调参，用一段时间再按需微调。
    },
  },
}
