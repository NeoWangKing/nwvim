return {
  "glepnir/dashboard-nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VimEnter",
  opts = {
    theme = "hyper",
    config = {
      header = {
        "                                   ",
        "   ⣴⣶⣤⡤⠦⠴⠶⠶⠶⠶⠶⠶⠤⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄   ",
        "   ⠙⠻⣿⣶⣦⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤   ",
        "     ⠈⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿   ",
        "      ⠈⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿   ",
        "       ⠈⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿   ",
        "        ⠈⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿   ",
        "         ⠈⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿   ",
        "          ⠈⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿   ",
        "           ⠈⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿   ",
        "            ⠈⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿   ",
        "             ⠈⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿   ",
        "              ⠈⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿   ",
        "               ⠈⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿   ",
        "                ⠈⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿   ",
        "                 ⠈⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿   ",
        "                  ⠈⠛⠿⣿⣿⣿⣿⣿⣿⣿   ",
        "                   ⠈⠛⠿⣿⣿⣿⣿⣿⣿   ",
        "                    ⠈⠛⠿⣿⣿⣿⣿⣿   ",
        "                     ⠈⠛⠿⣿⣿⣿⣿   ",
        "                      ⠈⠛⠿⣿⣿⣿   ",
        "                       ⠈⠛⠿⣿⣿   ",
        "                        ⠈⠛⠿⣿   ",
        "                         ⠈⠛⠿   ",
      },
      week_header = {
        enable = true,
      },
      shortcut = {
        { desc = "󰊳 Update", group = "@property", action = "Lazy update", key = "u" },
        { desc = "󰳽 Files", group = "Label", action = "Telescope find_files", key = "f" },
        { desc = "󰛏 Word", group = "Label", action = "Telescope live_grep", key = "g" },
        { desc = "󰈚 Recent", group = "Label", action = "Telescope oldfiles", key = "r" },
        { desc = "󰒲 Quit", group = "DiagnosticHint", action = "qall", key = "q" },
      },
      mru = {
        limit = 10,
        cwd = true,
      },
      -- 最近项目自定义显示格式 (结构类似，如果有需要)
      projects = {
        limit = 10,
        cwd = true,
      },
    },

    cache_folder = "",
  },
}
