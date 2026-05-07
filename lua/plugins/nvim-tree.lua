-- lua/plugins/nvim-tree.lua
return {
  "nvim-tree/nvim-tree.lua",
  dependencies = {
    "nvim-tree/nvim-web-devicons", -- 图标支持（你已经安装）
  },
  config = function()
    -- 强烈建议：禁用 netrw，避免冲突
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    -- 设置快捷键（在你自己的 maps 部分定义，这里也可以先定义）
    vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file explorer" })

    -- 配置 nvim-tree
    require("nvim-tree").setup({
      -- 自动刷新
      auto_reload_on_write = true,
      -- 禁用 git 集成（如果不需要，可加速）
      git = {
        enable = true,
        ignore = false,
      },
      -- 更新焦点文件
      update_focused_file = {
        enable = true,
        update_cwd = true,
        ignore_list = {},
      },
      -- 渲染器设置
      renderer = {
        group_empty = true,      -- 空文件夹显示为组
        highlight_git = true,    -- 高亮 git 状态
        root_folder_label = ": ~/projects",  -- 根目录显示标签
        indent_markers = {
          enable = true,         -- 显示缩进引导线
        },
        icons = {
          show = {
            git = true,
            folder = true,
            file = true,
            folder_arrow = true,
          },
          glyphs = {
            default = "",
            symlink = "",
            folder = {
              default = "",
              open = "",
              empty = "",
              empty_open = "",
              symlink = "",
            },
            git = {
              unstaged = "",
              staged = "S",
              unmerged = "",
              renamed = "➜",
              untracked = "U",
              deleted = "",
              ignored = "◌",
            },
          },
        },
      },
      -- 禁用窗口快捷键（避免与全局冲突）
      view = {
        width = 30,
        side = "left",
        preserve_window_proportions = true,
        number = false,
        relativenumber = false,
      },
      -- 文件操作（删除、重命名等）确认
      actions = {
        open_file = {
          quit_on_open = false,
          resize_window = false,
        },
      },
      -- 过滤文件（不显示某些文件）
      filters = {
        dotfiles = false,        -- 是否显示隐藏文件
        custom = { "^.git$" },   -- 额外忽略的目录/文件
      },
    })
  end,
}
