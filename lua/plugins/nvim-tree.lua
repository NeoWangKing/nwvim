return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    require("nvim-tree").setup({
      auto_reload_on_write = false, -- 已有 filesystem watcher，避免保存时整树重载
      git = {
        enable = true,
        ignore = false,
      },
      update_focused_file = {
        enable = false, -- 避免每次 BufEnter 都在大项目里定位文件、递归展开目录
      },
      renderer = {
        group_empty = false,
        highlight_git = true,
        root_folder_label = ": ~/projects",
        indent_markers = {
          enable = true,
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
      view = {
        width = 30,
        side = "left",
        preserve_window_proportions = true,
        number = false,
        relativenumber = false,
      },
      actions = {
        open_file = {
          quit_on_open = false,
          resize_window = false,
        },
      },
      filters = {
        dotfiles = false,
        custom = { "^.git$" },
      },
    })
  end,
}
