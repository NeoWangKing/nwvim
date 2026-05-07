return {
  {
    'akinsho/bufferline.nvim',
    -- enabled = false,
    version = "*",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require("bufferline").setup({
        options = {
          -- 显示模式：buffers 显示所有缓冲区，tabs 只显示标签页
          mode = "buffers",

          -- 数字显示方式：ordinal 序号 / buffer_id 真实ID / both 两者都显示
          numbers = "ordinal",

          -- 标签页分隔符样式："slant", "padded_slant", "slope", "padded_slope", "thick", "thin"
          separator_style = "thin",

          -- 始终显示标签栏（即使只有一个缓冲区）
          always_show_bufferline = true,

          -- 显示关闭图标
          show_buffer_close_icons = true,
          show_close_icon = true,

          -- 彩色图标（需配合 nvim-web-devicons）
          color_icons = true,

          -- 鼠标左键点击行为
          hover = {
            enabled = true,
            delay = 200,
            reveal = {'close'}
          },

          -- 自定义排序
          sort_by = 'insert_at_end',

          -- 诊断信息集成（LSP）
          diagnostics = "nvim_lsp",
          diagnostics_indicator = function(count, level)
            local icon = level:match("error") and " " or " "
            return " " .. icon .. count
          end,

          -- 最大名称长度
          max_name_length = 18,
          max_prefix_length = 15,
          tab_size = 18,

          -- 左侧偏移（例如为 nvim-tree 预留空间）
          offsets = {
            {
              filetype = "NvimTree",
              text = "File Explorer",
              highlight = "Directory",
              text_align = "left",
            }
          },

          -- 自定义高亮
          highlights = {
            buffer_selected = {
              bold = true,
              italic = false,
            },
            separator = {
              fg = "#434C5E",
            },
          },
        }
      })
    end,
  }
}
