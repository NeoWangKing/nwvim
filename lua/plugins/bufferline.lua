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

          diagnostics = "nvim_lsp",
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
            enabled = true,
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
            separator = { fg = "#B4BEFE", },
          },
        }
      })
    end,
  }
}
