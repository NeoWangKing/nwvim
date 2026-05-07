-- lua/plugins/lualine.lua

return {
  -- 插件地址
  'nvim-lualine/lualine.nvim',
  -- enabled = false,
  -- 可选：启用或禁用状态栏图标，推荐设置为 true 并搭配 Nerd Font 使用
  -- 依赖插件，用于提供文件类型图标
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  -- 配置入口
  config = function()
    require('lualine').setup {
      options = {
        -- 主题：'auto'(自动), 'onedark', 'dracula', 'gruvbox', 'tokyonight' 等
        theme = 'auto',
        -- 组件分隔符（左右）
        -- component_separators = { left = '', right = '' },
        componemt_separators = '|',
        -- 区域分隔符（左右）
        -- section_separators = { left = '', right = '' },
        section_separators = '',
        -- 是否禁用某些文件类型下的状态栏
        -- disabled_filetypes = {
          --     statusline = {}, -- 针对状态栏
          --     winbar = {},     -- 针对窗口栏
          -- },
          -- -- 是否总是将中间部分隔开
          -- always_divide_middle = true,
          -- -- 是否启用全局状态栏（Neovim 0.7+ 可用）
          -- globalstatus = false,
          -- -- 刷新率相关配置
          -- refresh = {
            --     statusline = 1000, -- 状态栏刷新间隔 (ms)
            --     tabline = 1000,    -- 标签栏刷新间隔
            --     winbar = 1000,     -- 窗口栏刷新间隔
            -- }
          },
          -- 定义状态栏不同区域显示的内容
          sections = {
            -- 左侧区域 (A, B, C)
            lualine_a = {'mode'},                        -- 显示当前模式 (NORMAL, INSERT 等)
            lualine_b = {'branch', 'diff', 'diagnostics'}, -- Git分支、差异和LSP诊断信息
            lualine_c = {'filename'},                    -- 文件名

            -- 右侧区域 (X, Y, Z)
            lualine_x = {'encoding', 'fileformat', 'filetype'}, -- 编码、格式和文件类型
            lualine_y = {'progress'},                    -- 文件进度 (%)
            lualine_z = {'location'}                     -- 光标位置 (行:列)
          },
          -- 非活跃窗口的状态栏
          inactive_sections = {
            lualine_a = {},
            lualine_c = {'filename'},
            lualine_b = {},
            lualine_y = {'location'},
            lualine_x = {},
            lualine_z = {}
          },
          -- 标签页栏配置
          tabline = {},
          -- 窗口栏配置 (Neovim 0.8+)
          winbar = {},
          inactive_winbar = {},
          -- 为其他插件启用扩展支持 (例如 nvim-tree)
          extensions = { 'nvim-tree' }
        }
      end,
    }
