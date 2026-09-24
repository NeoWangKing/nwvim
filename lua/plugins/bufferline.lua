return {
  {
    'akinsho/bufferline.nvim',
    version = "*",
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
      require('bufferline').setup({
        options = {
          mode = "buffers",
          themable = true,
          numbers = "ordinal",

          max_name_length = 18,
          max_prefix_length = 15,
          tab_size = 18,

          diagnostics = false, -- LSP 诊断不再实时刷新 tabline，减少重绘
          diagnostics_indicator = function(count, level)
            local icon = level:match("error") and " " or " "
            return " " .. icon .. count
          end,

          separator_style = "thin",
          always_show_bufferline = true,
          show_buffer_icons = true,
          show_buffer_close_icons = true,
          show_close_icon = true,

          hover = {
            enabled = false, -- 关闭 tabline 悬停弹窗，减少 CursorHold 处理
            delay = 200,
            reveal = {'close'}
          },

          sort_by = 'insert_at_end',
          offsets = {
            {
              filetype = "NvimTree",
              text = "File Explorer",
              highlight = "Directory",
              text_align = "left",
              separator = true,
            }
          },
          color_icons = true,

          highlights = {
            buffer_selected = { bold = true, italic = false, },
            -- 分隔线：淡钢蓝（原来是 catppuccin 的 lavender #B4BEFE，已换成 P3 色）
            separator = { fg = "#414549", },
          },
        }
      })
    end,
  }
}
