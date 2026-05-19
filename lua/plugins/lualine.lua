return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      -- Bubbles config for lualine
      -- Author: lokesh-krishna
      -- MIT license, see LICENSE for more details.

      -- stylua: ignore
      local bubbles_theme = {
        normal = {
          a = { fg = '#080808', bg = '#89B4F9' },
          b = { fg = '#c6c6c9', bg = '#606982' },
          c = { fg = '#c6c6c9' },
        },

        insert = { a = { fg = '#080808', bg = '#A6E2A1' } },
        visual = { a = { fg = '#080808', bg = '#CBA5F7' } },
        replace = { a = { fg = '#080808', bg = '#F9B387' } },

        inactive = {
          a = { fg = '#c6c6c9', bg = '#080808' },
          b = { fg = '#c6c6c9', bg = '#080808' },

        },
      }

      require('lualine').setup {
        options = {
          theme = bubbles_theme,
          component_separators = '',
          section_separators = { left = '', right = '' },
        },
        sections = {
          lualine_a = { { 'mode', separator = { left = '' }, right_padding = 2 } },
          lualine_b = { 'filename', 'branch' },
          lualine_c = {
            '%=', --[[ add your center components here in place of this comment ]]
          },
          lualine_x = {},
          lualine_y = { 'filetype', 'progress' },
          lualine_z = {
            { 'location', separator = { right = '' }, left_padding = 2 },
          },
        },
        inactive_sections = {
          lualine_a = { 'filename' },
          lualine_b = {},
          lualine_c = {},
          lualine_x = {},
          lualine_y = {},
          lualine_z = { 'location' },
        },
        tabline = {},
        extensions = {},
      }
    end,
  }
}
