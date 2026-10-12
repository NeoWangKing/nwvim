-- nvim-tree.lua - 文件树。
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
      auto_reload_on_write = false, -- 有 filesystem watcher，不用保存时整树重载
      git = {
        enable = true,
        ignore = false,
      },
      update_focused_file = {
        -- 大工程里每次 BufEnter 定位文件会卡，关掉
        enable = false,
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
