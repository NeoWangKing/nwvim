return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      -- Bubbles config for lualine
      -- Author: lokesh-krishna
      -- MIT license, see LICENSE for more details.

      -- stylua: ignore
      -- P3 Blue 泡泡主题（与 colors/p3-blue.lua 同一套调色板）
      local bubbles_theme = {
        normal = {
          a = { fg = '#1F2124', bg = '#5CB5DD' },  -- 模式徽章：P3 冰蓝
          b = { fg = '#C3D3E6', bg = '#2E3136' },
          c = { fg = '#C3D3E6' },
        },

        insert  = { a = { fg = '#1F2124', bg = '#7FD8C4' } },  -- 绿
        visual  = { a = { fg = '#1F2124', bg = '#B79AD4' } },  -- 冷紫
        replace = { a = { fg = '#1F2124', bg = '#CDA253' } },  -- 琥珀
        command = { a = { fg = '#1F2124', bg = '#93CBF2' } },  -- 亮冰蓝
        terminal= { a = { fg = '#1F2124', bg = '#7FA9E8' } },

        inactive = {
          a = { fg = '#7C828A', bg = '#191B1E' },
          b = { fg = '#7C828A', bg = '#191B1E' },
          c = { fg = '#7C828A' },
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
